# SCA-PRODUCTION-CUTOVER — Persistent Edge Attachment Readiness Audit (READ-ONLY)

**Date:** 2026-09-30
**Deployed baseline:** `4095ad506e01458b5131523d4b0b9ca49ed97ac5` (unchanged). **No changes made — reads only.**
**Objective:** the smallest safe way to make kr-app's membership in the existing external `sca_edge` network
(172.20.0.0/24) persist across normal governed deployments, eliminating the post-deploy manual
`docker network connect sca_edge kr-app`.

**Verdict:** declare `sca_edge` as an **external network in the SCA Compose** and add it to the **app service only**.
Two-hunk Compose change, no static IP, no deploy-script change, no impact to Caddy / `TRUSTED_PROXIES` / ports /
DOCKER-USER / DNS / QR / schema / provenance / app behavior. It simply makes the *current* working dual-homed state
survive `docker compose up -d` / `--force-recreate`.

---

## 1. Why `sca_edge` isn't persisted today

The SCA Compose (`/opt/sca-platform/docker-compose.yml`, project `name: sca`) declares only `internal` for the `app`
service (`networks: [internal]` → `sca_internal`); `sca_edge` is attached out-of-band, live, via
`docker network connect sca_edge kr-app`. A `docker restart` reuses the same container object and keeps that live
attachment, but `docker compose up -d` (and `--force-recreate`, which the deploy triggers when the image/config
changes) builds a **fresh** container attached only to the **Compose-declared** networks — so the live-only `sca_edge`
membership is not reproduced and is dropped. That is exactly what happened during the last two deploys.

## 2. Should it be declared external in the SCA Compose? — YES

Mirror the proven precedent already in `/opt/smsrocket-stack/docker-compose.yml`, where `sr-caddy` uses
`networks: [internal, sca_edge]` with a top-level `sca_edge: {external: true}`. `external: true` means Compose
**neither creates nor owns/removes** the network — it only *attaches* to the pre-existing `sca_edge`.
`docker compose config` confirms the resolution: `sca_edge → name: sca_edge` (literal, no project prefix), while
`internal → smsrocket-stack_internal`. For the SCA stack the same holds: `internal → sca_internal`, external
`sca_edge → sca_edge` (the existing 172.20.0.0/24 network).

## 3. Exact minimal Compose diff (`/opt/sca-platform/docker-compose.yml`)

Two hunks; the `mariadb` service is deliberately untouched.

```diff
   app:
     ...
-    networks: [internal]
+    networks: [internal, sca_edge]
     ...
 volumes:
   db_data:

 networks:
   internal:
+  # SCA-PRODUCTION-CUTOVER Phase 2B edge — externally created (172.20.0.0/24). Declared external so this stack
+  # neither creates nor removes it; Compose attaches ONLY kr-app so sr-caddy reaches kr-app:80 for
+  # secondchanceauthenticators.com. kr-mariadb stays internal-only and never joins it.
+  sca_edge:
+    external: true
```

Nothing else changes: the `ports:` binding, image, volumes, healthcheck, `mem_limit`, and the `mariadb` service all
stay as-is.

## 4. Will container recreation auto-reattach kr-app? — YES

With `sca_edge` in the `app` service networks and declared external, `docker compose up -d` / `--force-recreate`
attaches the new `kr-app` container to **both** `sca_internal` and `sca_edge` automatically. No manual
`docker network connect` is needed afterward.

## 5. kr-app remains dual-homed — YES

`networks: [internal, sca_edge]` ⇒ `sca_internal` (172.19.x, for MariaDB/internal services) **and** `sca_edge`
(172.20.x, for the Caddy edge). This matches the current live state (`sca_edge` 172.20.0.3 + `sca_internal`
172.19.0.3); the change only makes it persistent.

## 6. kr-mariadb stays `sca_internal`-only — PROVEN

The `mariadb` service lists only `networks: [internal]` and is **not** modified by this diff. A top-level external
network declaration attaches nothing by itself — only services that *list* `sca_edge` join it. kr-mariadb never lists
it. Live state confirms: `kr-mariadb` on `sca_internal` only (172.19.0.2), no published host port
(`{}` in `.NetworkSettings.Ports` for 3306). Post-change it remains `sca_internal`-only.

## 7. Static IP? — NOT necessary (recommend none)

Caddy reaches the app by Docker embedded DNS (`reverse_proxy kr-app:80`), and `TRUSTED_PROXIES=172.20.0.0/24` trusts
the **entire** `/24`, so any dynamically-assigned `sca_edge` address (172.20.0.x) is trusted. A static
`ipv4_address` would add fragility (collision management, reserved-range coupling) with **no** benefit. Recommend
relying on Docker DNS + the `/24` trust range — no static IP.

## 8. No change to Caddy / TRUSTED_PROXIES / ports / DOCKER-USER / DNS / QR / schema / provenance / app behavior

The diff only adds a network attachment for kr-app + an external-network declaration:
- **Caddy/Caddyfile** — unchanged; Caddy still reaches `kr-app:80` by name over `sca_edge`.
- **TRUSTED_PROXIES** — unchanged (`172.20.0.0/24`); kr-app's `sca_edge` IP stays inside that range.
- **Ports / :8080** — unchanged; the loopback `ports:` line is untouched, and the public-bind stash is orthogonal (see §11).
- **DOCKER-USER** — host iptables, not touched by Compose networking.
- **DNS / QR identity / schema / provenance data / application behavior** — nothing DB/app-facing changes; a network
  attachment is transparent to Laravel.

## 9. deploy-preview.sh change? — NOT necessary

The script performs **no** docker network operations: it does `git fetch origin --prune` (git), `docker compose up -d`,
and composer **dev-dependency** pruning (`--no-dev`). Once the committed Compose declares `sca_edge` external,
`docker compose up -d` handles the attachment; the manual post-deploy `docker network connect sca_edge kr-app` is
eliminated with **no** script edit.

**Prerequisite / caveat (same as smsrocket already has):** an *external* network must **exist** before
`docker compose up -d`, or Compose fails with *"network sca_edge declared as external, but could not be found."*
`sca_edge` currently exists and survives daemon restarts/reboots; it would only vanish via an explicit
`docker network rm sca_edge` or a `docker network prune` (already forbidden for shared/`sr-*` nets by the host
CLAUDE.md). **Optional** hardening (not required): a one-line guard in the deploy script —
`docker network inspect sca_edge >/dev/null 2>&1 || docker network create --subnet 172.20.0.0/24 sca_edge` — would
self-heal a missing edge; recommend documenting the manual recreate command rather than adding auto-create, to keep
the deploy script free of network mutation.

## 10. Test proving up/recreate preserves the edge (for the future implementation — not run here)

On the merged tree with the Compose change, `sca_edge` pre-existing:
1. `docker compose up -d --force-recreate app` (or a full governed deploy).
2. `docker inspect kr-app --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}'` → **`sca_internal
   sca_edge`** (dual-homed, no manual connect).
3. `docker inspect kr-mariadb …Networks…` → **`sca_internal`** only (never `sca_edge`).
4. `docker inspect kr-app --format '{{(index .NetworkSettings.Networks "sca_edge").IPAddress}}'` → `172.20.0.x`
   (inside the pinned `/24`).
5. `docker exec sr-caddy wget -qO- -T5 http://kr-app:80/up` → reachable (Caddy→kr-app:80 over `sca_edge`).
6. `curl -k --resolve secondchanceauthenticators.com:443:127.0.0.1 -o /dev/null -w '%{http_code}'
   https://secondchanceauthenticators.com/p/{valid-token}` → **200** (SCA vhost end-to-end, no manual reconnect).
7. Repeat a second `--force-recreate` → same result (idempotent). Confirm `smsrocket.io` 200, `:8080` 200,
   DOCKER-USER byte-identical, production counts + QR fp `6bb119ee…` unchanged.

## 11. Interaction with the public-bind stash (note, not part of this fix)

The public `195.26.255.80:8080` bind still lives in `git stash@{0}` (the committed `ports:` is loopback by
SCA-PRODUCTION-HARDENING-020). This edge-persistence fix is **independent**: after it, the deploy dance reduces to
`git stash apply` (public bind) → `docker compose up -d app` (now auto-attaches `sca_edge` **and** applies the public
bind) → `git checkout -- docker-compose.yml`; the manual `docker network connect` step disappears, while the stash
step for the public bind remains a separate, pre-existing matter (out of scope here).

## 12. Rollback procedure (for the future implementation)

Revert the two-hunk Compose diff (remove `sca_edge` from the `app` service `networks` and remove the top-level
`sca_edge: {external: true}` block). Pre-fix behavior returns (post-deploy `docker network connect sca_edge kr-app`
needed again). The `sca_edge` network itself is untouched by the revert (external — Compose neither created nor
removes it); no container/data/provenance state changes beyond the next recreate's attachment behavior. Compose-file
only, fully reversible.

## 13. Baseline / zero-mutation confirmation (this audit)

`4095ad5`, tree CLEAN; SCA counts qr=2, certs=3, migrations=118, collectors=2; QR fp
`6bb119ee0b598222bfec58bb80c7a4cb`; `TRUSTED_PROXIES=172.20.0.0/24`; `APP_URL=http://195.26.255.80:8080`; kr-mariadb
private (no host port); Caddyfile `00f16788`; DOCKER-USER 6 lines; smsrocket.io 200; `:8080` 200; kr-app dual-homed
`sca_edge`(172.20.0.3)+`sca_internal`(172.19.0.3); sr-caddy `sca_edge`(172.20.0.2)+smsrocket. **Nothing was edited,
disconnected, or reconnected.**

---

**Recommendation:** implement the §3 two-hunk Compose change as **cutover infrastructure hardening** (a small governed
task, push → verify via §10 → merge/deploy). No deploy-script change, no static IP. **This audit is read-only; the fix
is NOT promoted or implemented.** `SCA-PRODUCTION-CUTOVER` remains OPEN; Phase 2C remains blocked on client DNS. Not
SCA-054 product development.

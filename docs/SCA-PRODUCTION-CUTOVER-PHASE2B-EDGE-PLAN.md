# SCA-PRODUCTION-CUTOVER — PHASE 2B: Edge/Caddy Pre-Cutover Planning Audit (READ-ONLY)

**Type:** READ-ONLY planning. **No** change to DNS, Caddy, Docker networks, `.env`, firewall, SMTP, QR, data,
containers, or certificates; the SCA domain is **not** made public. **Deployed baseline:** `main @
d089e7a27856d7aacc45ccb9fb3333dbf4d4ade0` (Phase 2A live — Laravel bounded `trustProxies` + Apache shim
removed). **Domain:** `secondchanceauthenticators.com`. **Host:** `195.26.255.80`.

---

## 1. Current Caddy topology (observed)

- **sr-caddy** = `caddy:2`, container `sr-caddy`, on network **`smsrocket-stack_internal`** (IP `172.18.0.2`)
  **only**; `restart: unless-stopped`; `depends_on: app`.
- **Ports:** owns `0.0.0.0:80`, `[::]:80`, `0.0.0.0:443`, `[::]:443`, `443/udp` (HTTP/3), `2019/tcp` (admin,
  unpublished). The sole host TLS terminator.
- **Mounts/volumes:** `/opt/smsrocket-stack/Caddyfile → /etc/caddy/Caddyfile` (**ro single-file**, 222 bytes);
  `smsrocket-stack_caddy_data → /data` (**Let's Encrypt account + certs — unrecoverable if deleted**);
  `smsrocket-stack_caddy_config → /config`.
- **Caddyfile:** global ACME email `admin@smsrocket.io`; one site `smsrocket.io { reverse_proxy app:80 }`.
- **How SMSRocket reaches its upstream:** `reverse_proxy app:80` → `app` = **sr-app** (`172.18.0.5`) resolved by
  Docker DNS **on `smsrocket-stack_internal`**. So sr-caddy must remain on that network to reach sr-app.
- **Recreate procedure:** the Caddyfile is a pinned single-file inode, so `caddy reload` reports "config
  unchanged"; a config change requires `docker compose up -d --force-recreate sr-caddy` (from
  `/opt/smsrocket-stack`), which **briefly interrupts smsrocket.io** (see §10). `docker network connect` is
  live (no recreate).
- **Disruption risks:** (a) recreating sr-caddy = a short 80/443 blip for smsrocket.io; (b) attaching sr-caddy
  to another network does **not** remove `smsrocket-stack_internal`, so sr-app reachability is preserved; (c)
  never prune/delete `smsrocket-stack_caddy_data` (LE certs) or `_mail_dkim`.

**Existing networks/subnets (overlap map):** `bridge 172.17.0.0/16`, `smsrocket-stack_internal 172.18.0.0/16`
(sr-caddy/app/mariadb/mail/wa), `sca_internal 172.19.0.0/16` (kr-app `172.19.0.3`, kr-mariadb `172.19.0.2`).
→ **`172.20.0.0/16` and below are free.**

---

## 2. SCA edge network design

**Dedicated `sca_edge` network** (do NOT attach sr-caddy to `sca_internal`, which would give it MariaDB
reachability). Target topology:

```
Internet → sr-caddy ─┬─ smsrocket-stack_internal ─ sr-app  (unchanged)
                     └─ sca_edge ─ kr-app:80
kr-app ─ sca_internal ─ kr-mariadb        (unchanged; MariaDB stays here only)
```

- **kr-app** becomes dual-homed (`sca_internal` + `sca_edge`); **sr-caddy** becomes dual-homed
  (`smsrocket-stack_internal` + `sca_edge`); **kr-mariadb** stays `sca_internal`-only → **sr-caddy can never
  reach MariaDB.**
- **Proposed subnet (not created yet): `172.20.0.0/24`** — non-overlapping with 172.17/172.18/172.19; /24 is
  ample for two containers. Pin it in the `docker network create` (`--subnet 172.20.0.0/24`) and in both
  services' compose `networks:` so it survives recreates.
- sr-caddy will reach the app by the container name **`kr-app`** via Docker DNS on `sca_edge` (like `app:80`
  today).

---

## 3. TRUSTED_PROXIES — HARD GATE

- **Source IP kr-app/Laravel will actually see** for `sr-caddy → sca_edge → kr-app`: sr-caddy's **`sca_edge`
  IP** (a `172.20.0.x` address). Apache no longer rewrites it (2A removed mod_remoteip), so Laravel's
  `trustProxies` evaluates that peer directly and reads the real client from Caddy's `X-Forwarded-For`.
- **Pin the SUBNET, not a container IP.** Docker assigns sr-caddy's `sca_edge` IP dynamically; it can change on
  recreation unless statically assigned. The **stable boundary is the dedicated `sca_edge` subnet** — and since
  only sr-caddy + kr-app live on `sca_edge`, the subnet is as tight as a single-IP pin in practice, without the
  fragility. (A `172.20.0.2/32` static-IP pin is possible via a compose `ipv4_address`, but it adds brittle
  static assignment for no real gain over the /24.)
- **Production value:** `TRUSTED_PROXIES=172.20.0.0/24`. This is **tighter** than the transitional RFC1918
  default deployed in 2A (which currently already covers 172.20.x, so the edge will function even before
  pinning — but the default is transitional only).
- **GATE:** public DNS/HTTPS activation is **blocked** until `TRUSTED_PROXIES=172.20.0.0/24` is set +
  deployed + verified (a request via the edge is recognized as `https` from the trusted edge peer, and an
  untrusted peer still cannot spoof — Phase 2A's `TrustedProxyReadinessTest` semantics).

---

## 4. Caddy access-control design (against the real route table)

Actual top-level route surface (from `route:list`): `admin` (282), `collector` (32), `p` (1), and the
**non-public** `install` (5, incl. `/install/api/run-migration|run-seeder|env-file-setup|admin-config-setup` —
**dangerous**), `web-forms` (4), `sca` (2 = `/sca/shopify/oauth/callback` + `/sca/shopify/webhook`, Shopify
**deferred/not live**), `api` (`/api/user`), `broadcasting`, `sanctum`, `cache`, `/` (root), `up`.

**Model = default-deny + explicit allowlist.**
- **Public (internet):** `/p/*` (passport) and `/collector/*` + `/collector`. The public passport and collector
  views are **fully self-contained** (no external stylesheet/script/asset references verified), so **no extra
  asset path** needs exposing.
- **Staff/admin (IP-restricted):** `/admin` + `/admin/*` → allowed only from the two authorized staff IPs
  (`103.225.137.242`, `103.200.35.2`); everyone else → 403.
- **Fail-closed (denied on the public domain):** `/install*` (installer), `/web-forms/*`, `/api/*`,
  `/broadcasting/*`, `/sanctum/*`, `/cache*`, `/sca/*` (Shopify, deferred), `/` root, and anything unmatched →
  404/403. (`/up` health may be allowed or denied; recommend deny on the public domain and rely on internal
  health.)
- **Client-IP matching:** Caddy is the TLS edge, so its `remote_ip` matcher sees the **real internet client
  IP** — the admin allowlist uses `remote_ip 103.225.137.242 103.200.35.2`. Caddy sets `X-Forwarded-For`, which
  Laravel (2A `trustProxies`, once pinned) reads to log/enforce the original client IP. (Use `remote_ip`, not
  `client_ip`, because there is no L4 proxy in front of Caddy.)

---

## 5. Proposed Caddyfile changes (DRAFT — do NOT install; no ACME triggered)

Append to `/opt/smsrocket-stack/Caddyfile` (the existing `smsrocket.io { … }` block stays untouched):

```
secondchanceauthenticators.com {
	# For the PRE-DNS private test use Caddy's internal CA so NO public ACME is triggered:
	#   tls internal
	# For production (post-DNS) REMOVE that line so Caddy auto-issues a public Let's Encrypt cert.

	# Public SCA surfaces
	@public path /p/* /collector /collector/*
	handle @public {
		reverse_proxy kr-app:80
	}

	# Staff/admin — only the two authorized staff source IPs
	@admin path /admin /admin/*
	handle @admin {
		@staff remote_ip 103.225.137.242 103.200.35.2
		handle @staff { reverse_proxy kr-app:80 }
		respond "Forbidden" 403
	}

	# Everything else (installer, web-forms, api, broadcasting, sanctum, cache, root, sca/shopify, up) → fail closed
	handle {
		respond "Not found" 404
	}
}

www.secondchanceauthenticators.com {
	# tls internal   # (pre-DNS test only)
	redir https://secondchanceauthenticators.com{uri} permanent
}
```

- Caddy automatically forwards `X-Forwarded-For/Proto/Host` to the upstream; no extra directive needed.
- `reverse_proxy kr-app:80` resolves over `sca_edge`.
- Coexistence: independent site blocks; smsrocket.io routing to `app:80` is unaffected.

---

## 6. Private pre-DNS testing strategy

Two stages, both without public ACME:

**A. Network reachability (no Caddy config change):** after `docker network connect sca_edge sr-caddy` and
`… kr-app`, run `docker exec sr-caddy wget -qO- http://kr-app:80/up` → proves sr-caddy resolves + reaches
kr-app over `sca_edge`, with **zero** smsrocket disruption.

**B. Full route test (SCA block with `tls internal`, one recreate in a quiet window):** add the draft block
with `tls internal`, `docker compose up -d --force-recreate sr-caddy`, then from the host:
`curl --resolve secondchanceauthenticators.com:443:195.26.255.80 -k https://secondchanceauthenticators.com/…`.
Prove:
- Caddy → kr-app reachable; correct **Host** reaches Laravel (via `X-Forwarded-Host`); **forwarded HTTPS
  trusted** (Laravel `isSecure()` true from the edge peer); **generated URLs are `https://…`**; **public
  passport** `/p/{token}` correct + bogus → constant 404; **collector login** GET works;
- **admin allowlist:** a request from a **non-allowlisted** source (the host itself) to `/admin/*` → **403**
  (deny path testable locally); the **allow path** requires a request from one of the two staff IPs (staff runs
  it during the window);
- **installer/api/etc. → 404** (fail closed);
- **smsrocket.io still healthy** (`curl -I https://smsrocket.io`).

**Cannot be tested before public DNS:** a **publicly-trusted certificate** (real LE cert needs public DNS +
ACME HTTP-01) and real browser trust — `tls internal` (`-k`) validates everything **except** public cert trust.

---

## 7. `:8080` fallback

`195.26.255.80:8080` and its DOCKER-USER two-IP allowlist stay **unchanged** throughout Phase 2B. It is the
rollback/admin fallback and is **not** retired here. (kr-app remains published on `:8080` while also joining
`sca_edge`.)

---

## 8. Application-environment sequencing (later; do NOT change `.env` now)

| Value | When | Why |
|---|---|---|
| `TRUSTED_PROXIES=172.20.0.0/24` | **Phase 2B, pre-DNS** (after `sca_edge` exists) | the edge boundary must be pinned + verified before public activation (§3) |
| `APP_URL=https://secondchanceauthenticators.com` | **at DNS/HTTPS cutover** | in-request URL gen already uses the forwarded host; APP_URL mainly drives CLI/email absolute URLs — set when the domain is the canonical entry |
| `PUBLIC_QR_BASE_URL=https://secondchanceauthenticators.com` | at DNS/HTTPS cutover | canonical QR base (currently unused by code; set alongside APP_URL) |
| `SCA_PUBLIC_PREVIEW=0` | **at/after DNS**, once the permanent domain is live | flipping it earlier would drop the "non-permanent" banner while the passport is still only on the temp `:8080`/internal test |
| `SESSION_SECURE_COOKIE=true` | **after HTTPS is the interactive path** (and before/at `:8080` retirement) | `Secure` cookies are dropped by browsers over the plain-HTTP `:8080` pilot → setting it too early **breaks `:8080` login** |

So Phase 2B applies **only `TRUSTED_PROXIES`** (pinned); the four HTTPS/URL/cookie values wait until the edge
route is verified and DNS is live.

---

## 9. Rollback (per step; no provenance DB rollback required)

| Step | Failure | Rollback |
|---|---|---|
| Caddyfile edit | bad block / smsrocket regression | restore the previous Caddyfile (keep a copy first) + `--force-recreate sr-caddy` → smsrocket.io returns; SCA simply not served |
| sr-caddy recreate | container won't start | `docker start sr-caddy` from the last-good image/config; certs intact in `caddy_data`; if persistent, revert Caddyfile and recreate |
| `sca_edge` network | misconfig / overlap | `docker network disconnect sca_edge sr-caddy && … kr-app`; `docker network rm sca_edge`; `sca_internal`/`:8080` untouched |
| trusted-proxy misconfig | edge request not recognized / spoofable | revert `TRUSTED_PROXIES` (env) + redeploy; the transitional RFC1918 default or `:8080` path still works; no data impact |
| SMSRocket regression | smsrocket.io down | restore Caddyfile + recreate sr-caddy (highest priority); it is the live co-tenant |
| Laravel 502/bad gateway | Caddy can't reach kr-app | verify `sca_edge` membership + `kr-app:80` health; revert Caddy block; fall back to `:8080` |

No step mutates provenance data → **no DB restore is ever required.**

---

## 10. USER INPUT for Phase 2B specifically

- **Staff allowlist:** the existing two IPs `103.225.137.242` and `103.200.35.2` **are sufficient for Phase
  2B** — the `/admin` restriction carries them over unchanged. (Confirm they are still the intended staff
  egress IPs; no new IP is required for 2B.)
- **Maintenance/quiet window:** required for the **one** `sr-caddy` `--force-recreate` (adding the SCA site
  block). The network `connect` step is live/zero-downtime; only the Caddy recreate interrupts smsrocket.io.
  **Estimated interruption boundary:** a single ~2–10-second unavailability of ports 80/443 for **smsrocket.io**
  while the Caddy container restarts (certs already in the volume → no re-issue; no data loss). Recommend a
  low-traffic window and a smsrocket health re-check immediately after.
- **Not required for 2B (later phases):** SMTP provider/credentials, off-site backup destination, and the QR
  `is_production` decision — 2B is not blocked on these.

---

## 11. Governance

Phase 2B **planning report only.** No implementation task promoted; no change to DNS, Caddy, Docker networks,
`.env`, firewall, SMTP, QR identities, production data, containers, or certificates. **SCA-PRODUCTION-CUTOVER
remains BLOCKED/DEFERRED**; **ACTIVE = NONE; NEXT_TASK = NONE.** Production and the pilot are exactly as found
(this audit made no mutating change). Full plan for review; execution awaits ChatGPT authorization + the short
maintenance window.

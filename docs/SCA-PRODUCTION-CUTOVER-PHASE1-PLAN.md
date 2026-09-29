# SCA-PRODUCTION-CUTOVER — PHASE 1: READ-ONLY CUTOVER PLANNING AUDIT

**Type:** READ-ONLY planning. **No** change was made to DNS, Caddy, Docker networking/ports, firewall,
`.env`, `APP_URL`, `PUBLIC_QR_BASE_URL`, SMTP, QR identities, production data, or containers; no deploy, no
SCA-054 promotion. **Domain:** `secondchanceauthenticators.com` (GoDaddy). **Server:** `195.26.255.80`.
**Deployed app:** `main @ 0e2e151b2023186ce18347c514903dce217c1685`. **Temp pilot:** `195.26.255.80:8080`
(IP-locked).

> ⚠️ Shared host. The public TLS edge (`sr-caddy`) and ports 80/443 belong to the **live co-tenant
> smsrocket.io**. The cutover **reuses** that edge; it must never take a second copy of 80/443, prune shared
> volumes, or recreate co-tenant containers except the one deliberate `sr-caddy` recreate (below), done in a
> quiet window.

---

## 1. Live production topology (observed, read-only)

- **kr-app** (`sca-app:krayin-2.2.6`): network `sca_internal` **only**; published `195.26.255.80:8080 → 80`;
  healthy. **Not** on any network `sr-caddy` can reach → today Caddy cannot proxy to it.
- **kr-mariadb**: `sca_internal` only; `3306` **not published** (private). ✓
- **sr-caddy** (`caddy:2`, co-tenant): network `smsrocket-stack_internal`; owns `0.0.0.0:80`, `0.0.0.0:443`
  (+ `443/udp` HTTP/3, `2019` admin). The **only** TLS terminator on the host. Caddyfile is a single-file
  **read-only bind mount** (`/opt/smsrocket-stack/Caddyfile`); current content: global ACME email
  `admin@smsrocket.io`, one site `smsrocket.io { reverse_proxy app:80 }`. **A plain `caddy reload` will NOT
  pick up edits** (pinned inode) — requires `docker compose up -d --force-recreate sr-caddy`, which briefly
  drops smsrocket.io.
- Other co-tenant containers: `sr-app`, `sr-mariadb`, `sr-wa`, `sr-mail` (587, unpublished) — do not touch.
- **Networks:** `bridge`, `host`, `none`, `sca_internal`, `smsrocket-stack_internal`. **No `edge` network
  exists yet.**
- **Host listeners:** `0.0.0.0:80` & `0.0.0.0:443` (sr-caddy, public); `195.26.255.80:8080` (kr-app, IP-locked).
- **DOCKER-USER firewall:** ESTABLISHED RETURN; ACCEPT `103.225.137.242` & `103.200.35.2` on `:8080`; DROP all
  else on `:8080`. Ports 80/443 are **unrestricted** (public, for smsrocket).
- **Application env (relevant; secrets shown only as SET/UNSET):** `APP_ENV=production`, `APP_DEBUG=false`,
  `APP_KEY=SET`, `DB_PASSWORD=SET`. `APP_URL=http://195.26.255.80:8080`. `PUBLIC_QR_BASE_URL=UNSET`,
  `SCA_PASSPORT_PATH=UNSET` (default `p`), `ASSET_URL=UNSET`. `SESSION_DRIVER=file`,
  `SESSION_SECURE_COOKIE=UNSET`, `SESSION_DOMAIN=UNSET`, `SESSION_SAME_SITE` default `lax`, `http_only=true`.
  `TRUSTED_PROXIES=UNSET` **and `bootstrap/app.php` configures no `trustProxies()`** (see §4 — a code change).
  `MAIL_MAILER=log`, `MAIL_HOST/PORT/ENCRYPTION=UNSET`, `MAIL_FROM_ADDRESS=no-reply@localhost`.
  `SCA_PUBLIC_PREVIEW` defaults to `1` (the "development/non-permanent" passport banner is ON).

---

## 2. DNS plan (GoDaddy — to be created LATER, not now)

Server is a single host reached directly at `195.26.255.80`; TLS terminates at Caddy on that IP. Correct records:

| Type | Host | Value | TTL |
|---|---|---|---|
| A | `@` (apex) | `195.26.255.80` | 600 (raise after validation) |
| A | `www` | `195.26.255.80` | 600 |

- Canonical = `https://secondchanceauthenticators.com`; `www` **redirects** to apex (redirect handled by Caddy,
  §3 — so `www` only needs to resolve to the host for ACME + the redirect).
- Prefer **A for `www`** over `CNAME www → @`: GoDaddy forbids CNAME at the apex, and an A record for `www`
  keeps both names on the same IP and lets Caddy issue one certificate covering both. (A `CNAME www → apex`
  also works; A is simpler and avoids CNAME-chain surprises.)
- **Conflict check (conceptual, do not modify):** before creating these, verify GoDaddy has no existing apex/www
  A, AAAA, CNAME, or GoDaddy "Parked"/forwarding records for this domain that would shadow the new values, and
  no AAAA (the host has no public IPv6 service here). Remove/September such conflicts only during execution.
- Low TTL (600s) during cutover enables fast rollback; raise to 1h+ after validation.
- ACME HTTP-01 (Caddy default) needs apex **and** www resolving to `195.26.255.80` with `:80` reachable (it is,
  via sr-caddy) before the cert can issue — so DNS must land and propagate **before** the TLS step.

---

## 3. HTTPS / edge plan (reuse sr-caddy; do NOT add a second proxy)

**Terminate TLS at the existing sr-caddy** (it already owns 80/443 and holds the LE account/`caddy_data`
volume). Steps (execution phase):
1. `docker network create edge`.
2. `docker network connect edge sr-caddy` (live, zero downtime) and add `edge` to `kr-app` so Caddy can resolve
   `kr-app` by name. Persist by adding `edge` to both services' `networks:` in their compose files (so it
   survives recreates).
3. Append an SCA site block to `/opt/smsrocket-stack/Caddyfile`:
   ```
   secondchanceauthenticators.com {
           @restricted path /admin* /install*
           handle @restricted {
                   @allowed remote_ip <STAFF_ALLOWLIST_IPS>
                   handle @allowed { reverse_proxy kr-app:80 }
                   respond 403
           }
           handle { reverse_proxy kr-app:80 }
   }
   www.secondchanceauthenticators.com {
           redir https://secondchanceauthenticators.com{uri} permanent
   }
   ```
4. `docker compose up -d --force-recreate sr-caddy` (⚠ briefly drops smsrocket.io — quiet window). Caddy
   auto-issues LE certs for apex + www.

- **Required exposure:** 80 + 443 already public via sr-caddy; **no new host port** — kr-app is reached over the
  internal `edge` network, so its `:8080` binding is untouched.
- **Internal upstream:** `kr-app:80` (Caddy sets `X-Forwarded-Proto: https`, `X-Forwarded-For`, `Host`
  automatically — consumed once Laravel trusts the proxy, §4).
- **Security boundary (critical — do NOT expose the whole app):**
  - **Public / internet:** `/p/{token}` (public passport — MUST be public) and `/collector/*` (collectors are
    internet users) and `/` , `/up` (health).
  - **Restricted:** `/admin/*` (all 282 staff/Krayin-admin routes) **and** `/install*` — kept to the staff
    `remote_ip` allowlist in Caddy (the `@restricted` matcher above), returning 403 otherwise. This preserves
    the current staff-only posture after the domain goes live.
  - Because domain traffic enters via Caddy on 443 (not `:8080`), the **DOCKER-USER `:8080` IP-lock no longer
    gates it** — the admin restriction MUST move into Caddy (path + `remote_ip`). Keep the `:8080` IP-locked
    entrypoint alive as a staff fallback during transition, then retire it (step 11).
  - Shopify OAuth/webhook public endpoints remain **deferred/not live**, so they are out of scope for the pilot
    boundary; revisit if/when Shopify is activated.

---

## 4. Permanent URL configuration (code + env)

**Usage traced:**
- The permanent **QR identity token** is `sca_qr_identifiers.public_token` = `Token::opaque()` (32 hex), stored
  once and **immutable** (append-only, `trg_sca_qr_identifiers_no_update`). The item-detail view states it
  explicitly: *"the permanent, host-independent SCA identity token — not a URL."* **Changing the base URL does
  NOT change the token.** ✓ (§5.)
- The public passport resolves via the named route `sca.passport.show` → `/p/{token}` (`SCA_PASSPORT_PATH`
  default `p`). Within an HTTP request, `route()`/`url()` build the absolute URL from the **request host+scheme**
  — correct **only if Laravel trusts the proxy** and Caddy forwards `X-Forwarded-Proto=https`. Outside a request
  (CLI, **queued/sent mail** such as the password-reset link) they use `APP_URL`.
- `PUBLIC_QR_BASE_URL` is currently **referenced only in a doc comment**, not consumed by code; the canonical
  shape `PUBLIC_QR_BASE_URL + "/p/" + token` is realized today via the route. Set it anyway at cutover as the
  documented canonical base for the (future) printable QR artifact.

**Required production values (execution phase):**
- `.env`: `APP_URL=https://secondchanceauthenticators.com`; `PUBLIC_QR_BASE_URL=https://secondchanceauthenticators.com`;
  `SESSION_SECURE_COOKIE=true`; `SCA_PUBLIC_PREVIEW=0` (removes the non-permanent banner); leave `SESSION_DOMAIN`
  unset (host-only cookie on the apex is fine); `SESSION_SAME_SITE=lax` (default OK). `ASSET_URL` may stay unset
  (assets are same-origin).
- **Code change (governed, via feature branch + `deploy-preview.sh`):** `bootstrap/app.php` must
  `->withMiddleware(fn ($m) => $m->trustProxies(at: '*'))` (or the specific Caddy/edge subnet) so
  `X-Forwarded-Proto`/`-For`/`Host` are honored — **without this, Laravel emits `http://` links and won't set
  secure cookies even over HTTPS.** This is the one part of the cutover that is NOT pure infra/env. It is small,
  read-model-neutral, and must go through the normal branch → pre-merge → merge → deploy pipeline.
- After the env change, clear/rebuild caches (`config:clear`/`route:clear`; the deploy script already does this).
- **Verify** (§9) that a passport link rendered behind Caddy is `https://secondchanceauthenticators.com/p/{token}`
  and that the QR **token values are byte-identical before/after** (host change ≠ token change).

---

## 5. Permanent QR boundary

Three distinct things — keep them separate:
- **QR identity/token** — permanent, host-independent, immutable; already exists for pilot items. **Never**
  regenerate/revoke/reissue during cutover.
- **QR destination URL** — derived: `https://secondchanceauthenticators.com/p/{token}`. Produced by setting the
  base/host (§4); the token is unchanged.
- **Printable/scannable QR artifact** — **not generated by the app today** (the item detail deliberately shows
  only the token and notes the scannable QR image is deferred until the permanent domain). Producing a
  scannable PNG that encodes `https://secondchanceauthenticators.com/p/{token}` is a **future, small, additive
  feature** (or an external encode step), separate from this infra cutover.

**⚠ Governance decision required (immutability constraint):** the 2 existing pilot QR identities are
`is_production = 0` (staging-flagged; "staging tokens never printed as lifetime IDs"), and QR rows are
**immutable** — the flag **cannot be flipped**. So:
- The 2 pilot tokens will *resolve* fine at the permanent domain (host-independent), but per their own
  `is_production=0` flag they were created as pilot/staging and are **not** marked for lifetime printing.
- If the 2 current items are throwaway pilot/test data → treat as such; **new** production intake (post-cutover)
  should create QR identities with `is_production = true`, and only those receive printed permanent tags.
- If either current item is real inventory that must carry a permanent printed tag → a **governed decision** is
  needed (accept the `is_production=0` token as-is by policy, or issue a fresh production QR via the QR
  lifecycle — which is a mutation that changes the item's active QR and retires the old token). This is a
  product/governance call, not resolvable in a read-only audit → see USER INPUT.

---

## 6. SMTP / password-recovery plan

- **Current:** `MAIL_MAILER=log` → the SCA-037 collector password-reset notification (`CollectorResetPassword`,
  channel `['mail']`) only writes to `storage/logs/laravel.log`. **Self-service password recovery is
  non-functional in production** until real SMTP is configured. (Collector register/login/change-password work;
  only the *reset-by-email* path is blocked.)
- **Required (execution):** set `MAIL_MAILER=smtp` + `MAIL_HOST`/`MAIL_PORT`/`MAIL_USERNAME`/`MAIL_PASSWORD`/
  `MAIL_ENCRYPTION` + a real `MAIL_FROM_ADDRESS` (e.g. `no-reply@secondchanceauthenticators.com`) and
  `MAIL_FROM_NAME`. Then send a real reset to a test inbox and confirm delivery + that the reset link is
  `https://secondchanceauthenticators.com/...` (depends on `APP_URL`, §4).
- **Deliverability DNS (GoDaddy, provider-dependent):** **SPF** TXT at apex (`v=spf1 include:<provider> -all`),
  **DKIM** CNAME/TXT selector(s) from the provider, **DMARC** TXT at `_dmarc` (start
  `v=DMARC1; p=none; rua=mailto:...` then tighten). Exact records depend on the chosen provider.
- **Provider not selected** — do NOT assume one. The co-tenant `sr-mail` (587, unpublished, on the smsrocket
  network) exists but is the *other tenant's* mail server; reusing it would couple the stacks and needs that
  owner's consent — not recommended. → see USER INPUT.

---

## 7. Backup / off-site readiness

- **Present & working:** daily encrypted backups via cron `/etc/cron.d/sca-backup` (03:17) → `backup-run.sh`;
  artifacts in `/opt/sca-platform/backups/*.tar.gz.gpg` (GPG-encrypted) + `.sha256`; recent dailies present
  (27/28/29 Sep); a **restore-proof** script (`backup-verify-restore.sh`) and `db-restore.sh` exist.
- **Gap:** `SCA_OFFSITE_UPLOADER` is **unset** → backups live **only on this host** (single point of loss).
  `lib-offsite.sh` supports an uploader hook but none is configured.
- **To do (execution):** choose an off-site destination (object store / rclone remote), set the uploader +
  credentials, run one backup, confirm the encrypted artifact + checksum land off-site, and **rehearse a
  restore from the off-site copy** into a disposable target before relying on it. Do not move/delete existing
  backups in planning. → destination/credentials: see USER INPUT.

---

## 8. Rollback plan (per mutable step; no DB restore needed)

The entire cutover mutates **no provenance data** (QR/identity untouched; only network/Caddy/env/DNS). So
rollback never requires a database restore.

| Step | Failure | Rollback |
|---|---|---|
| DNS | wrong/premature | revert the A records in GoDaddy; low TTL (600s) makes it fast; `:8080` IP-locked pilot keeps working throughout |
| `edge` network / connect | proxy can't reach kr-app | `docker network disconnect edge kr-app`/`sr-caddy`; `docker network rm edge`; no effect on `sca_internal`/`:8080` |
| Caddyfile edit | TLS issuance fails / bad block | restore the previous single-site Caddyfile (keep a copy first) + `docker compose up -d --force-recreate sr-caddy`; smsrocket.io returns; SCA simply not yet served over the domain |
| Caddy → kr-app unreachable | 502 | revert Caddy block; fall back to `:8080` IP-locked; fix edge membership |
| Laravel emits `http://` / secure-cookie/login breaks | trustProxies/APP_URL wrong | revert `.env` (`APP_URL` back to `:8080`, unset `SESSION_SECURE_COOKIE`) + redeploy previous `main` (the trustProxies code change is a normal revertible deploy); `:8080` path unaffected |
| Public passport fails over domain | resolver/host issue | same Caddy/`.env` revert; passport keeps working on `:8080/p/{token}` |
| Collector claim/transfer links fail | host/cookie issue | revert `.env`/Caddy; links regenerate from the current host; tokens unchanged |
| SMTP fails | bad creds/DNS | set `MAIL_MAILER=log` again (reversible env); no data impact; password-reset simply returns to the pre-cutover (non-functional) state |
| Permanent QR URL fails | base URL wrong | revert `PUBLIC_QR_BASE_URL`/`APP_URL`; **no tags printed until validated**, so nothing physical to recall |

**Golden rule:** do not print/distribute any permanent QR tag until §9 passport validation over the real domain
is GREEN — so a QR rollback never involves recalling physical artifacts.

---

## 9. Execution runbook (future; GO / NO-GO checkpoints)

0. **Pre-cutover backup** → run `backup-run.sh`, verify artifact + checksum, and a restore rehearsal. **NO-GO** if
   backup/restore fails.
1. **Edge prep** → `docker network create edge`; connect `sr-caddy` + `kr-app`; persist in both compose files.
   Checkpoint: `docker exec sr-caddy` can resolve/reach `kr-app:80`. **NO-GO** if unreachable.
2. **DNS** → create apex + www A → `195.26.255.80` (low TTL). Checkpoint: both names resolve to the IP from an
   external resolver. **NO-GO** until propagated.
3. **Caddy site block + TLS** → append the SCA block (with the `/admin*` `remote_ip` allowlist) + www redirect;
   `--force-recreate sr-caddy` in a quiet window. Checkpoint: `smsrocket.io` still serves; Caddy issued a valid
   cert for apex+www; `https://secondchanceauthenticators.com/up` (or `/admin/login`) responds. **NO-GO** if
   smsrocket.io breaks or the cert doesn't issue → rollback Caddyfile.
4. **Laravel URL/security config** → merge the `trustProxies` code change via the governed pipeline; set `.env`
   (`APP_URL`, `PUBLIC_QR_BASE_URL`, `SESSION_SECURE_COOKIE=true`, `SCA_PUBLIC_PREVIEW=0`); clear caches.
   Checkpoint: a rendered passport/collector link is `https://…`; secure cookie set; no mixed content.
5. **Public passport verification** → `https://secondchanceauthenticators.com/p/{existing token}` resolves and
   shows the certified passport; a bogus token → constant 404 (Option A); **preview banner gone**. **NO-GO**
   if passport fails.
6. **Collector + staff boundary verification** → collector login/claim/transfer work over the domain; `/admin/*`
   is reachable **only** from the staff allowlist (403 otherwise); `:8080` still works as fallback. **NO-GO** if
   admin is publicly reachable or collector flows break.
7. **SMTP / password-reset verification** → configure SMTP; send a real reset; confirm delivery + `https://` link.
   **NO-GO** (for the mail milestone) if it doesn't deliver — but this does not block the passport/collector
   go-live if sequenced after.
8. **Permanent QR artifact validation** → only after step 5 GREEN, produce a scannable artifact for a test token,
   scan it end-to-end to the live passport. **NO-GO** to printing real tags until this passes; respect the
   `is_production` decision (§5).
9. **Off-site backup validation** → enable uploader; back up; confirm off-site artifact + rehearse restore.
10. **Retire temporary `:8080` exposure** → only after 5–8 GREEN and stable: remove the `:8080` publish (or keep
    it purely as an internal admin fallback) and, if removed, the DOCKER-USER `:8080` rules. Raise DNS TTL.

---

## 10. USER INPUT REQUIRED BEFORE CUTOVER

(Only items genuinely unavailable from the server/repo. Domain, GoDaddy, and `195.26.255.80` are known.)

1. **Staff/admin allowlist IPs** for the Caddy `/admin*` (+`/install*`) restriction post-cutover. Confirm whether
   the two current DOCKER-USER IPs (`103.225.137.242`, `103.200.35.2`) are the staff/admin sources to carry over,
   or provide the correct staff egress IP(s).
2. **Maintenance window** approval for the one `sr-caddy` `--force-recreate` (briefly interrupts the live
   smsrocket.io co-tenant).
3. **SMTP provider + credentials** (host/port/username/password/encryption) and the desired `From` address/name
   (e.g. `no-reply@secondchanceauthenticators.com`), so the SPF/DKIM/DMARC records can be specified. Confirm we
   are NOT reusing the co-tenant `sr-mail`.
4. **Off-site backup destination** (provider/bucket/remote) + credentials for `SCA_OFFSITE_UPLOADER`.
5. **QR `is_production` decision (§5):** are the 2 current pilot items throwaway test data (→ new production
   intake gets `is_production=true` QRs; pilot tokens not printed as lifetime tags), or real inventory needing
   permanent printed tags (→ a governed QR-issuance decision, given row immutability)?
6. **`www` behavior confirmation:** redirect `www → apex` (assumed) is acceptable.
7. **ACME contact email** for the SCA cert: reuse the existing global `admin@smsrocket.io`, or use an
   SCA-specific address (e.g. `admin@secondchanceauthenticators.com`)?

---

## Governance

Recorded as **planning for SCA-PRODUCTION-CUTOVER**; the task remains **BLOCKED/DEFERRED** (execution pending the
USER INPUT above + a quiet window). **Not** marked complete; no implementation started; **SCA-054 not promoted**;
application feature development stays stopped. **ACTIVE = NONE; NEXT_TASK = NONE.** The audit made no change to
DNS, Caddy, networking, firewall, `.env`, QR identities, production data, or containers.

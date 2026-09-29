# SCA-PRODUCTION-CUTOVER — Phase 2B RETRY (Edge/Caddy Pre-DNS) — RESULT: **PASS (edge left LIVE)**

**Date:** 2026-09-29
**Production baseline:** `c568331f9eca01cd2eed068f3e0b6af3e9381665` (Phase 2A.1 / DEFECT-002 fixed — trusted proxies
resolved at request time from `config('trustedproxy.proxies')`). This is what made the Phase 2B hard gate achievable
after the first attempt (`62e1deb`) failed and was rolled back.
**Scope:** pre-DNS only. **No public DNS change, no public ACME/TLS, no Phase 2C.**

## Plan revalidation (matched the audit — proceeded)

Deployed HEAD `c568331`; `172.20.0.0/24` free (172.17 bridge / 172.18 smsrocket / 172.19 sca_internal taken);
sr-caddy owns `0.0.0.0:80`+`:443` (smsrocket_internal only); kr-app + kr-mariadb sca_internal only; Caddyfile
baseline `sha256 171f29c…` (0 SCA refs); DOCKER-USER = staff `103.225.137.242` + `103.200.35.2` + DROP on dport 8080;
`.env` `TRUSTED_PROXIES` unset, `APP_URL=http://195.26.255.80:8080`.

## Actions + gate results

1. **`sca_edge` = 172.20.0.0/24** created; connected **only** sr-caddy (`172.20.0.2`) + kr-app (`172.20.0.3`).
   kr-mariadb stays sca_internal-only; sr-caddy not on sca_internal; sr-caddy→kr-app:80 reachable.
2. **`TRUSTED_PROXIES=172.20.0.0/24`** set in production `.env` (0600 www-data; APP_URL / PUBLIC_QR_BASE_URL /
   SESSION_SECURE_COOKIE / SCA_PUBLIC_PREVIEW unchanged). Consumed at request time with **no restart** (config not
   cached): `config('trustedproxy.proxies')=["172.20.0.0/24"]`.
3. **HARD GATE (real deployed HTTP middleware) — PASS:**
   - Real request from **sr-caddy `172.20.0.2`** → kr-app:80 → form action `https://secondchanceauthenticators.com/…`
     (proto+host **honored**).
   - Probe: Caddy peer honored **with forwarded client IP `198.51.100.7`** (XFF honored).
   - Real request from **sca_internal `172.19.0.4`** → `http://kr-app/…` (**rejected**).
   - Public `203.0.113.9` → **rejected**. (No hidden RFC1918 fallback.)
4. **Caddy SCA block** appended (`tls internal`, default-deny) — smsrocket block preserved **byte-for-byte**;
   `caddy validate` = Valid; new Caddyfile `sha256 00f167883910bc05cf84e75e139b80eb69e17f809e4e9fbb48f2fb6b685bad39`.
   smsrocket compose: `sca_edge` added to sr-caddy networks (external) so it survives recreate.
5. **sr-caddy force-recreated** in the quiet window → smsrocket **recovered (http 308 → https 200)**; caddy_data (LE
   cert) volume intact; sr-caddy still owns 80/443; on `sca_edge`+`smsrocket_internal`.
6. **Pre-DNS verification (`curl --resolve …:443:127.0.0.1 -k`; internal/self-signed cert, NOT publicly trusted):**
   - SCA HTTPS vhost answers (cert issuer `Caddy Local Authority` — internal CA).
   - `/p/bee93d2b…` (valid) → **200**; bogus `/p/<32-zero>` → **404** (SCA-038 constant-shape, body 2863 B).
   - `/collector/login` → **200**; form action absolute `https://secondchanceauthenticators.com/…` (HTTPS recognized
     via trusted proxy).
   - `/admin`, `/admin/login` → **403** "Forbidden" at the edge (request not from a staff IP; allowlist **not
     weakened** — matcher is exactly `remote_ip 103.225.137.242 103.200.35.2`).
   - Blocked families → **404**: `/install`, `/install/api/run-migration`, `/sca/oauth/callback`,
     `/sca/webhooks/orders`, `/api/user`, `/up`, `/`, `/admin/../p`. (`/sca/*` Shopify/OAuth/webhook NOT exposed.)
   - smsrocket.io HTTPS → **200**.
7. **Fallback + non-mutation:** `:8080` pilot `/up`,`/admin/login`,`/collector/login` → **200** (public bind
   `195.26.255.80:8080`, plain HTTP unaffected by the pin); **DOCKER-USER byte-identical**; MariaDB private; SCA
   provenance counts unchanged (migrations=118, qr=2, certs=3, cert_events=4, ownership=4, auths=3, items=2); **QR
   identity fp `6bb119ee0b598222bfec58bb80c7a4cb` unchanged.**

## What remains LIVE (governed pre-DNS edge state)

- Docker network **`sca_edge` (172.20.0.0/24)** — members sr-caddy `172.20.0.2`, kr-app `172.20.0.3`.
- Production `.env` **`TRUSTED_PROXIES=172.20.0.0/24`** (effective at runtime).
- `/opt/smsrocket-stack/Caddyfile` with the **SCA `tls internal` vhost** (`sha256 00f16788…`) + `www→apex` redirect;
  smsrocket block byte-for-byte unchanged.
- `/opt/smsrocket-stack/docker-compose.yml` — sr-caddy `networks: [internal, sca_edge]` + external `sca_edge`.
- sr-caddy recreated and serving both smsrocket.io (public LE) and the SCA vhost (internal CA, **reachable only via
  SNI to 195.26.255.80:443 — no DNS points here yet, no public ACME**).
- `:8080` pilot + DOCKER-USER IP-lock unchanged = the rollback/fallback path.

## NOT done (still forbidden without further authorization)

Public DNS unchanged; no public ACME; `APP_URL`/`PUBLIC_QR_BASE_URL`/`SESSION_SECURE_COOKIE`/`SCA_PUBLIC_PREVIEW`
unchanged; no QR generation/printing; no SMTP; no off-site backup; `:8080` not retired; Phase 2C (DNS + public TLS)
NOT started. `SCA-PRODUCTION-CUTOVER` remains **OPEN**.

## Rollback procedure (if ever needed)

Restore `/opt/smsrocket-stack/Caddyfile` from `171f29c…` baseline; revert sr-caddy compose to `networks: [internal]`
(remove external `sca_edge`); `docker compose up -d --force-recreate caddy`; verify smsrocket; remove
`TRUSTED_PROXIES` from `.env`; `docker network disconnect sca_edge kr-app` + `… sr-caddy`; `docker network rm
sca_edge`; verify `:8080` + DOCKER-USER + zero mutation.

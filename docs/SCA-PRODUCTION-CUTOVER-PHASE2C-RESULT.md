# SCA-PRODUCTION-CUTOVER — Phase 2C (Public DNS + Trusted TLS) — RESULT: **PASS (LIVE)**

**Date:** 2026-09-30
**Deployed app baseline:** `bd9e3cd` (unchanged — Phase 2C is DNS/TLS/edge-routing only; no app deploy).
**Scope:** activate the public SCA registry edge at **`verify.secondchanceauthenticators.com`**. The apex
`secondchanceauthenticators.com` and `www` remain the live Shopify storefront and were **not touched**.

## Preconditions (verified)

- **DNS (client-configured, independently confirmed):** `verify.secondchanceauthenticators.com` → **195.26.255.80**
  via Google `8.8.8.8` and Cloudflare `1.1.1.1`. Apex → `23.227.38.32` (Shopify), `www` → `shops.myshopify.com` /
  `23.227.38.74` (Shopify) — unchanged.
- Baseline matched the audit: deployed `bd9e3cd`, Caddyfile `00f16788` (SCA vhost `tls internal`), `sca_edge`
  (kr-app 172.20.0.3 + sr-caddy 172.20.0.2), `TRUSTED_PROXIES=172.20.0.0/24`, smsrocket 200, `:8080` 200,
  DOCKER-USER 6, migrations=118/qr=2/certs=3, QR fp `6bb119ee…`.

## Change applied (Caddyfile only; smsrocket block byte-for-byte unchanged)

- Relabelled the SCA vhost `secondchanceauthenticators.com {` → **`verify.secondchanceauthenticators.com {`**.
- **Removed `tls internal`** → Caddy auto-issues a publicly-trusted Let's Encrypt certificate.
- **Deleted the `www.secondchanceauthenticators.com` block** (no `www` for the SCA app; `www` stays on Shopify).
- Default-deny routing preserved verbatim (public `/p/*` + `/collector`/`/collector/*`; `/admin*` → `remote_ip`
  `103.225.137.242` `103.200.35.2` else 403; everything else 404). New Caddyfile `sha256 0faece7a53afaca69cbba9b2b757cf830b7bf29bfbd20497ab0e35f9eeaca5bf`.
- `caddy validate` = Valid. sr-caddy force-recreated in the quiet window (caddy_data/LE volume preserved);
  **smsrocket recovered** (http 308 → https 200).

## HARD GATE — publicly-trusted TLS (no `-k`, no `--resolve`)

- Caddy ACME log: HTTP-01 challenge for `verify.secondchanceauthenticators.com` solved (served key auth to Let's
  Encrypt validators), authorization **valid**, **"certificate obtained successfully"** (issuer
  `acme-v02.api.letsencrypt.org`).
- `curl https://verify.secondchanceauthenticators.com/collector/login` (real public DNS + TLS, **no `-k`**) →
  **http=200, ssl_verify_result=0**.
- Certificate: **issuer Let's Encrypt (C=US, O=Let's Encrypt, CN=YE2)**, **subject CN=verify.secondchanceauthenticators.com**,
  valid **notBefore Sep 30 2026 → notAfter Dec 29 2026** (90-day LE).

## Internet-facing verification (real public hostname, trusted TLS)

- `/p/{valid}` → **200**; bogus `/p/<32-zero>` → **404** (SCA-038 constant shape, 2863 B).
- `/collector/login` → **200** (collector portal now public over HTTPS).
- `/admin` from a non-allowlisted source → **403** "Forbidden".
- `/install`, `/sca/oauth/callback`, `/api/user`, `/`, `/up` → **404** (default-deny; `/sca/*` Shopify/OAuth/webhook
  not exposed).
- `http://verify.…/` → **308** redirect to `https://verify.…/`.
- Generated form action absolute **`https://verify.secondchanceauthenticators.com/collector/login`** (HTTPS
  recognized through the trusted proxy).
- Apex `https://secondchanceauthenticators.com/` still served by **Shopify** (Cloudflare); `www` → Shopify. Untouched.
- `smsrocket.io` → **200** over its existing public LE cert.

## Proxy / security hard gate (re-proven after public TLS)

`TRUSTED_PROXIES=172.20.0.0/24` (unchanged, not broadened). Through the real middleware: the actual Caddy peer
`172.20.0.2` has forwarded proto/host **and client IP** honored (`X-Forwarded-For 198.51.100.7` → `request()->ip()`);
a `172.19.x` peer is **rejected**; an arbitrary public peer is **rejected**. Corroborated: `/admin` edge-restriction
acts on the real client IP (403 from a non-staff source).

## Non-mutation / isolation

Production `sca_krayin` unchanged: migrations=118, qr=2, certs=3; **QR fp `6bb119ee0b598222bfec58bb80c7a4cb`**.
kr-mariadb `sca_internal`-only, no host port (private). DOCKER-USER **byte-identical**. kr-app healthy, dual-homed
(`sca_edge`+`sca_internal`), still on the `195.26.255.80:8080` pilot bind.

## What is LIVE now

- Public DNS `verify.secondchanceauthenticators.com` → 195.26.255.80.
- Caddy vhost `verify.…` with a **publicly-trusted Let's Encrypt** certificate (Caddyfile `0faece7a`), default-deny
  routing to kr-app over `sca_edge`; HTTP→HTTPS redirect. smsrocket.io + `:8080` fallback + DOCKER-USER unchanged.

## NOT done (deliberately deferred — do NOT proceed without separate authorization)

- **Application URL / permanence config is a SEPARATE next gate** — `APP_URL` (still `http://195.26.255.80:8080`),
  `PUBLIC_QR_BASE_URL`, `SESSION_SECURE_COOKIE` (unset → the session cookie is not yet `Secure`; setting it true would
  break the plain-HTTP `:8080` login, so it is sequenced with `:8080` retirement), `SCA_PUBLIC_PREVIEW` (unset → the
  passport still shows the development-preview banner). None changed in Phase 2C.
- SMTP activation, permanent QR production/printing, `:8080` retirement, off-site backup — all still deferred.

## Rollback (if ever needed)

Restore `/opt/smsrocket-stack/Caddyfile` from the pre-2C backup (`sha256 00f16788…`, SCA vhost `tls internal` on the
apex label) — or minimally re-add `tls internal` to the `verify.` vhost to stop serving the public cert;
`caddy validate`; `docker compose up -d --force-recreate caddy`; verify smsrocket 200 and `:8080` 200. The issued LE
cert remains harmlessly in the `smsrocket-stack_caddy_data` volume. DNS is client-controlled. No DB restore needed
(no provenance mutation).

**`SCA-PRODUCTION-CUTOVER` remains OPEN. Phase 2C = DONE/LIVE. Next gate = application URL/permanence config (separate
authorization).**

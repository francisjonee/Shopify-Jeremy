# NEXT TASK

**STATUS: ACTIVE — `SCA-PRODUCTION-CUTOVER — Application URL / Permanence Configuration — PHASE A` (production `.env`).**

Promoted 2026-09-30 by ChatGPT. Implements only the audited Phase A (`docs/SCA-PRODUCTION-CUTOVER-APPURL-PERMANENCE-PLAN.md`).
Deployed baseline `bd9e3cd` (unchanged — `.env` only, no code/schema/DB). **Do NOT proceed to Phase B.**

## Executable contract

1. **Capture pre-mutation state:** back up `app/.env`; record QR identity fingerprint + production counts.
2. **Apply Phase A to `app/.env`** (preserve `0600` www-data):
   - `APP_URL=https://verify.secondchanceauthenticators.com`
   - `SCA_PUBLIC_PREVIEW=0`
   - Keep `SESSION_DOMAIN` unset; keep `SESSION_SECURE_COOKIE` unset; do **not** change `SCA_PASSPORT_PATH`; do
     **not** set `ASSET_URL`; do **not** add `PUBLIC_QR_BASE_URL` (proven inert); leave `SCA_PREVIEW_BANNER` unchanged.
3. **Clear config:** `docker compose exec -u 33:33 app php artisan config:clear` (config not cached; `.env` read fresh).
4. **No** change to code, Caddy, DNS, Docker networking, firewall, schema, QR rows/tokens, certification/provenance data.

## GO gates (all must pass)

`config('app.url')` = exactly `https://verify.secondchanceauthenticators.com`; public passport `/p/{valid}`→200,
`/p/{bogus}`→constant-shape 404; **no** "SCA DEVELOPMENT PREVIEW" banner; collector login + authenticated round-trip
over `https://verify.…`; claim/transfer/form/redirect URLs on the HTTPS verify. host; staff/admin + HTTPS admin
assets correct for an allowlisted source; **`:8080` still functional** (Secure not enabled); Shopify apex/www +
smsrocket healthy/unchanged; `TRUSTED_PROXIES=172.20.0.0/24`, `sca_edge`, admin allowlist, MariaDB privacy, DOCKER-USER
unchanged; QR fp + counts + provenance identical before/after.

## Hard STOP / rollback

If any public URL depends on the old IP/`:8080`, auth differs from the audit, the passport resolver changes behavior,
or any domain/provenance data changes → **restore `app/.env` from the backup + `config:clear`** and report.

If all gates pass, record Phase A **DONE**. **Do NOT** set `SESSION_SECURE_COOKIE=true`, retire `:8080`, activate SMTP,
change QR production flags/print QR, change DNS/Caddy, or start another phase. Return evidence and STOP.

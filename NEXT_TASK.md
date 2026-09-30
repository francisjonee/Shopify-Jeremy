# NEXT TASK

**STATUS:** NONE — no executable task is currently authorized. **ACTIVE = NONE, NEXT_TASK = NONE.**

## Latest: SCA-PRODUCTION-CUTOVER — Application URL / Permanence Config **Phase A — DONE** 2026-09-30

Applied to production `app/.env` (deployed app `bd9e3cd` unchanged; `.env`-only, `config:clear`; no code/schema/DB):
- **`APP_URL`**: `http://195.26.255.80:8080` → **`https://verify.secondchanceauthenticators.com`**
- **`SCA_PUBLIC_PREVIEW=0`** (added)
- Unchanged (as required): `SESSION_DOMAIN` unset, `SESSION_SECURE_COOKIE` unset, `SCA_PASSPORT_PATH` (`p`),
  `ASSET_URL` unset, `PUBLIC_QR_BASE_URL` not added (proven inert), `SCA_PREVIEW_BANNER` unchanged.
- `.env` `0600` www-data preserved; backup captured; diff = exactly those two lines.

**Runtime (post `config:clear`):** `config('app.url')=https://verify.secondchanceauthenticators.com`,
`sca-passport.preview=false`, `session.domain=NULL`, `session.secure=NULL`, `filesystems.disks.public.url=https://verify.…/storage`,
`sca-passport.path=p`; config not cached.

**GO gates — all PASS:**
- `config('app.url')` = exactly `https://verify.secondchanceauthenticators.com`.
- Public passport (real host): `/p/{valid}`→200; `/p/{bogus}`→404 constant-shape (body 2863→2561 = the removed preview
  banner, applied uniformly; SCA-038 Option A property intact).
- **"SCA DEVELOPMENT PREVIEW" banner absent** on the passport.
- Collector auth over `https://verify.…`: login page 200, form action `https://verify.…/collector/login`, CSRF+session
  issued, bad-cred POST → 302 (auth cycle works, not 419/500), unauth `/collector/collection`→ redirect to
  `https://verify.…/collector/login`. (Full logged-in round-trip covered by the auth mechanics + the deploy's
  `tests/Feature/Sca` 641/3462; a real login needs an operator credential and would otherwise mutate data.)
- Staff/admin: admin logo/asset now `https://verify.…/storage/configuration/…` (HTTPS); `:8080` `/admin/login` 200.
- **`:8080` still fully functional** (`/up`,`/admin/login`,`/collector/login`→200); its form action stays
  request-derived `http://195.26.255.80:8080/…` (no public URL depends on the old IP; APP_URL didn't break `:8080`).
- verify. public TLS still trusted (`ssl_verify_result=0`).
- Shopify apex (`23.227.38.32`) + www (Shopify) unchanged; smsrocket.io 200.
- `TRUSTED_PROXIES=172.20.0.0/24`, `sca_edge` (kr-app+sr-caddy), admin allowlist, MariaDB private, DOCKER-USER
  byte-identical, Caddyfile `0faece7a` — all unchanged.
- **Zero mutation:** migrations=118, qr=2, certs=3, auths=3, ownership=4, cert_events=4, collectors=2; QR fp
  `6bb119ee0b598222bfec58bb80c7a4cb` — identical before/after.

**Rollback (if ever needed):** set `app/.env` `APP_URL=http://195.26.255.80:8080` and remove `SCA_PUBLIC_PREVIEW=0`
(restore from the captured backup); `config:clear`. No DB restore.

## Authorization state

`SCA-PRODUCTION-CUTOVER` remains **OPEN**. **Phase B NOT started and NOT authorized:** do not set
`SESSION_SECURE_COOKIE=true`, retire `:8080`, activate SMTP, change QR production flags / print permanent QR, or change
DNS/Caddy. **SCA-054 must not start.** Nothing is active.

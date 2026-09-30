# NEXT TASK

**STATUS:** NONE — no executable task is currently authorized. **ACTIVE = NONE, NEXT_TASK = NONE.**

## Latest: SCA-PRODUCTION-CUTOVER Phase 2C (Public DNS + Trusted TLS) — **PASS / LIVE** 2026-09-30

The public SCA registry edge is live at **`https://verify.secondchanceauthenticators.com`** with a publicly-trusted
Let's Encrypt certificate. Apex + `www` remain the live Shopify storefront, untouched. Full evidence:
`docs/SCA-PRODUCTION-CUTOVER-PHASE2C-RESULT.md`.

- **DNS** (client-set, independently confirmed 8.8.8.8/1.1.1.1): `verify.` → `195.26.255.80`; apex/www still Shopify.
- **Caddyfile** (`sha256 0faece7a…`, smsrocket block byte-for-byte unchanged): SCA vhost relabelled to `verify.`,
  `tls internal` removed (public LE), `www` block deleted; default-deny preserved.
- **HARD GATE (no `-k`, no `--resolve`):** LE cert obtained (log "certificate obtained successfully"); `curl` →
  `http=200, ssl_verify_result=0`; issuer **Let's Encrypt**, subject **CN=verify.secondchanceauthenticators.com**,
  valid Sep 30 → Dec 29 2026.
- **Internet-facing:** `/p/{valid}`→200, bogus→404 (SCA-038), `/collector/login`→200, `/admin`→403 (non-staff),
  installer/`/sca/*`/api/root/`/up`→404, `http`→`https` 308, form action absolute `https://verify.…`; apex Shopify;
  smsrocket 200.
- **Proxy/security (re-proven):** `TRUSTED_PROXIES=172.20.0.0/24` (not broadened); real Caddy peer `172.20.0.2` →
  proto/host/client-IP honored, `172.19.x`+public rejected.
- **Non-mutation:** migrations=118, qr=2, certs=3, QR fp `6bb119ee0b598222bfec58bb80c7a4cb`; MariaDB private;
  DOCKER-USER byte-identical; `:8080` fallback 200; kr-app healthy dual-homed; deployed app `bd9e3cd` unchanged.

## Authorization state

`SCA-PRODUCTION-CUTOVER` remains **OPEN**. **Next gate = application URL / permanence configuration** (`APP_URL=https://verify.…`,
`PUBLIC_QR_BASE_URL`, `SESSION_SECURE_COOKIE=true` [sequenced with `:8080` retirement], `SCA_PUBLIC_PREVIEW=0`) — a
**separate** step, **NOT authorized here**; APP_URL/permanence config was deliberately left unchanged in Phase 2C.
SMTP, permanent QR production/printing, `:8080` retirement, and off-site backup remain deferred. **SCA-054 must not
start.** Nothing is active.

# NEXT TASK

**STATUS:** NONE — no executable task is currently authorized. **ACTIVE = NONE, NEXT_TASK = NONE.**

## Latest: SCA-PRODUCTION-CUTOVER Phase 2B RETRY (Edge/Caddy Pre-DNS) — **PASS — edge left LIVE** 2026-09-29

On production baseline `c568331` (DEFECT-002 fixed), the pre-DNS edge was built and **all hard gates passed**, so the
validated edge is left live (full evidence: `docs/SCA-PRODUCTION-CUTOVER-PHASE2B-RETRY-RESULT.md`).

**Live governed state:** `sca_edge` (172.20.0.0/24) joining sr-caddy `172.20.0.2` + kr-app `172.20.0.3` (kr-mariadb
stays sca_internal-only); production `.env` `TRUSTED_PROXIES=172.20.0.0/24` (effective at request time — proven);
`/opt/smsrocket-stack/Caddyfile` SCA vhost `tls internal` + `www→apex` (sha `00f16788…`, smsrocket block byte-for-byte
unchanged); sr-caddy recreated serving smsrocket.io (public LE) + SCA vhost (internal CA, **reachable only via SNI —
no DNS, no public ACME**). `:8080` pilot + DOCKER-USER IP-lock unchanged = rollback/fallback path.

**Hard gate (real deployed HTTP middleware):** Caddy peer `172.20.0.2` trusted (proto/host/client-IP honored),
`172.19.x` rejected, public rejected. **Pre-DNS checks (`curl --resolve`, internal cert):** vhost answers,
`/p/{valid}`→200, bogus→404 (SCA-038 constant-shape), `/collector/login`→200, `/admin*`→403 (staff allowlist intact),
installer/`/sca/*`/api/root/`/up`→404 (default-deny), HTTPS recognized; smsrocket 200. Zero SCA mutation (counts + QR
fp `6bb119ee…` unchanged); DOCKER-USER byte-identical; MariaDB private.

## Phase 2C (Public DNS + Trusted TLS) — **BLOCKED / NOT STARTED** 2026-09-29

Attempted under authorization but **stopped at the pre-change revalidation gate with zero changes** — the DNS
prerequisite is unmet in a way that needs a human decision (`docs/SCA-PRODUCTION-CUTOVER-PHASE2C-BLOCKED.md`).
**`secondchanceauthenticators.com` is a LIVE Shopify storefront** (apex → `23.227.38.32` Shopify; `www` →
`shops.myshopify.com`; `HTTP/2 200`, `powered-by: Shopify`), **not** pointed at `195.26.255.80`. Repointing the apex
would take the store offline; DNS is at an external registrar (no access here); and public ACME was NOT attempted
(the name resolves to Shopify → issuance would fail + risk LE rate limits, so `tls internal` was left untouched).
The 2B edge is fully intact (Caddyfile `00f16788`, pin, sca_edge, smsrocket 200, `:8080` 200, DOCKER-USER unchanged,
QR fp `6bb119ee…` unchanged).

**Recommended (needs human/registrar action):** put the SCA registry on a dedicated **subdomain** (e.g.
`verify.`/`registry.`/`app.secondchanceauthenticators.com`) → `195.26.255.80`, leaving the Shopify apex intact; then
a revised Phase 2C points the Caddy vhost at that subdomain with public TLS.

## Authorization state

`SCA-PRODUCTION-CUTOVER` remains **OPEN**. **Still forbidden without new authorization:** public DNS changes, public
ACME/TLS, `APP_URL`/`PUBLIC_QR_BASE_URL`/`SESSION_SECURE_COOKIE`/`SCA_PUBLIC_PREVIEW`, QR generation/printing, SMTP,
off-site backup, `:8080` retirement. **Phase 2C is BLOCKED on a human DNS (subdomain-vs-apex) decision.** Nothing is
promoted; **ACTIVE = NONE, NEXT_TASK = NONE. SCA-054 must not start.**

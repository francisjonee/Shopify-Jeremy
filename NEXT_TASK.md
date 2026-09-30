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

**Recommended (needs human/registrar action):** put the SCA registry on a dedicated **subdomain** (chosen:
`verify.secondchanceauthenticators.com`) → `195.26.255.80`, leaving the Shopify apex intact; then a revised Phase 2C
points the Caddy vhost at that subdomain with public TLS.

**Phase 2C.1 — waiting-for-DNS readiness audit DONE 2026-09-30 (read-only, zero changes;
`docs/SCA-PRODUCTION-CUTOVER-PHASE2C1-READINESS-AUDIT.md`).** Verdict: **READY** — the app is host-agnostic (all URLs
request-derived via trusted proxy; no global scheme/root forcing; **zero production hard-coding** of host/IP/:8080 —
all 7 hits are tests only; `PassportPresenter` builds no URLs; passport route has no host constraint; cert PDFs embed
the opaque token, no URL/host; QR token immutable + host-independent). The **only genuine blocker is external**: the
GoDaddy `verify` A record needs the client's domain-protection code. Key notes: `PUBLIC_QR_BASE_URL` is inert
(comment-only, unused by code); password-reset URL is request-derived (`QUEUE_CONNECTION=sync`, no `ShouldQueue`) so
correct under `verify.` with no APP_URL dependency; **keep `SESSION_DOMAIN` null** (a dot-domain would leak cookies to
the Shopify apex); sequence `SESSION_SECURE_COOKIE=true` only **after** `:8080` login is retired; `is_production` is an
immutable, behavior-inert print marker (2 pilot rows resolve fine — decision deferred to the printable-QR phase,
recommend "adopt existing tokens"). Minimal Caddy diff = relabel apex→`verify.` + delete the `www` block; at cutover
remove `tls internal` for public LE. Post-DNS checklist + rollback in the audit doc. When Shopify OAuth (`SHOPIFY-CONNECT-009`)
is later activated, the Caddy default-deny must add an explicit allow for `/sca/*` callback/webhook (denied now).

## Authorization state

`SCA-PRODUCTION-CUTOVER` remains **OPEN**. **Still forbidden without new authorization:** public DNS changes, public
ACME/TLS, `APP_URL`/`PUBLIC_QR_BASE_URL`/`SESSION_SECURE_COOKIE`/`SCA_PUBLIC_PREVIEW`, QR generation/printing, SMTP,
off-site backup, `:8080` retirement. **Phase 2C is BLOCKED on a human DNS (subdomain-vs-apex) decision.** Nothing is
promoted; **ACTIVE = NONE, NEXT_TASK = NONE. SCA-054 must not start.**

# NEXT TASK

**STATUS: ACTIVE — `SCA-PRODUCTION-CUTOVER Phase 2A.1 / DEFECT-002` — Runtime Trusted-Proxy Fix (PUSH ONLY).**

Promoted 2026-09-29 by ChatGPT. Base/deployed SHA `d089e7a27856d7aacc45ccb9fb3333dbf4d4ade0`. Accepted
architecture = the Phase 2A.1 audit at governance `51e281f`
(`docs/SCA-PRODUCTION-CUTOVER-PHASE2A1-DEFECT-002-PLAN.md`). **PUSH ONLY — do NOT merge, do NOT deploy, do NOT retry
Phase 2B.**

## Executable contract

1. **Add `config/trustedproxy.php`** deriving the proxy list from `TRUSTED_PROXIES` with the audited fail-safe policy:
   unset → trust none; empty → trust none; whitespace/empty comma entries removed; valid IP/CIDR retained;
   `*`/`**`/universal-trust values rejected/removed; malformed never broadens trust. **Do NOT restore the RFC1918
   default.**
2. **Edit `bootstrap/app.php`**: remove all `env('TRUSTED_PROXIES')` reads and the `at:` argument from
   `trustProxies()`; retain the explicit accepted forwarded-header mask; let the framework's `TrustProxies` middleware
   resolve `config('trustedproxy.proxies')` lazily at request time. Do NOT call `TrustProxies::at()` anywhere.
3. **Regression coverage** (extend `TrustedProxyReadinessTest`) with configured trust `172.20.0.0/24`, proven through
   the real HTTP kernel: `172.20.x` honored; **`172.19.x` rejected (mandatory discriminator)**; public rejected;
   loopback/untrusted rejected; untrusted cannot manufacture HTTPS/host/client-IP. Configure via the real config path —
   NOT `TrustProxies::at()`, NOT static mutation, NOT early env injection that bypasses the bootstrap-order defect.
4. **Default/failure tests:** no config → trust none; empty → trust none; malformed → not trusted; `*`/`**` → no
   universal trust; `:8080` plain-HTTP remains compatible with trust-none.
5. **Config-cache hard gate:** build production-style config cache, verify through a real web/runtime request that
   `TRUSTED_PROXIES=172.20.0.0/24` yields exactly `172.20.x`=trusted / `172.19.x`=untrusted, then clear/restore caches.
   Include a static gate proving `bootstrap/app.php` has no `env('TRUSTED_PROXIES')`.
6. **Existing behavior:** re-run passport, collector auth and the full `tests/Feature/Sca`; must not alter Phase-2A
   Apache behavior.

**Scope boundaries:** no migration/schema/route/ACL/domain mutation; do NOT change production `.env`; do NOT set
`TRUSTED_PROXIES` in production; do NOT change DNS/Caddy/Docker-networks/firewall/DOCKER-USER/`APP_URL`/
`PUBLIC_QR_BASE_URL`/`SESSION_SECURE_COOKIE`/`SCA_PUBLIC_PREVIEW`/SMTP/QR/provenance. Do NOT retry Phase 2B.

**Verification / restore:** report exact test totals; verify `TRUSTED_PROXIES` unset ⇒ trust-none and the
`195.26.255.80:8080` pilot unaffected; restore the pilot to deployed main `@ d089e7a`, clean tree, `--no-dev`, healthy
kr-app, private MariaDB, unchanged DOCKER-USER. **PUSH ONLY. STOP for ChatGPT audit.**

DEFECT-002 remains **OPEN** until merge/deploy + runtime verification. Phase 2B remains **BLOCKED**.
`SCA-PRODUCTION-CUTOVER` remains **OPEN**.

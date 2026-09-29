# NEXT TASK

**STATUS:** NONE — no executable task is currently authorized.

## Latest: SCA-PRODUCTION-CUTOVER Phase 2B edge/Caddy pre-DNS IMPLEMENTATION — **FAILED (hard gate) + ROLLED BACK** (2026-09-29)

The Phase 2B edge/Caddy pre-DNS path was built and validated against deployed baseline `d089e7a`
(created `sca_edge` 172.20.0.0/24 on sr-caddy + kr-app only; appended the default-deny Caddy SCA site with
`tls internal`; force-recreated sr-caddy with smsrocket.io staying healthy; pinned `TRUSTED_PROXIES=172.20.0.0/24`
in `.env`) — but the **hard verification gate (directive §2/§7) failed**: the running application's *effective*
trusted-proxy set is still the **transitional RFC1918 default, not the pinned `/24`**. A live spoof shows an
untrusted `172.19.x` peer's `X-Forwarded-*` **honored** (impossible under a true `/24` pin).

**Root cause = DEFECT-002 (a code bug in the deployed Phase 2A `d089e7a`), not a Phase-2B/config error.**
`bootstrap/app.php` evaluates `trustProxies(at: env('TRUSTED_PROXIES', <RFC1918 default>))` inside the
`withMiddleware()` closure, which runs at HTTP-kernel resolution **before** `LoadEnvironmentVariables`. At that
moment `env('TRUSTED_PROXIES')` is NULL, so the code falls back to the hardcoded RFC1918 default and the `.env`
pin is **inert at runtime** (proven in the web SAPI: PRE / AT-kernel-make `env=NULL`; POST-bootstrap
`=172.20.0.0/24`). No container restart/recreate fixes it — it requires a code change, which is outside Phase 2B's
scope. See `docs/PENDING-DEFECTS.md` (DEFECT-002) and `docs/SCA-PRODUCTION-CUTOVER-PHASE2B-IMPLEMENTATION-RESULT.md`.

**Per the directive, everything was rolled back to the audited baseline** and the smsrocket.io co-tenant preserved:
Caddyfile restored (`sha256 171f29c…`, `caddy validate` = Valid); smsrocket compose reverted; sr-caddy
force-recreated → smsrocket.io recovered (http 308 → https 200); SCA vhost removed (SNI → 000); `.env` pin removed
(0600 www-data; `APP_URL` still HTTP pilot; `PUBLIC_QR_BASE_URL`/`SESSION_SECURE_COOKIE`/`SCA_PUBLIC_PREVIEW`
absent); `sca_edge` torn down (kr-app → `sca_internal` only; kr-mariadb private); `:8080` pilot fallback intact
(`/up`, `/admin/login`, `/collector/login` = 200; DOCKER-USER byte-identical); **zero provenance mutation**
(counts + QR rows/`no_update`/`no_delete` triggers unchanged). **This is not a regression from `d089e7a`.**

**Prerequisite before Phase 2B can be retried:** a governed code slice (recommend "Phase 2A.1", DEFECT-002) that
resolves trusted proxies from a value available *after* env load. **Its planning/root-cause audit is now DONE**
(read-only, 2026-09-29 — `docs/SCA-PRODUCTION-CUTOVER-PHASE2A1-DEFECT-002-PLAN.md`; DEFECT-002 in
`docs/PENDING-DEFECTS.md`). Confirmed fix (empirically, through the real `TrustProxies` middleware): the framework
already lazily reads `config('trustedproxy.proxies')` at request time, but the closure's eager
`TrustProxies::at(<RFC1918 default>)` preempts it — so add a fail-safe `config/trustedproxy.php` (default **trust
none**) and drop the `at:`/`env()` from `bootstrap/app.php` (keep the explicit `headers:`). `config:cache`-safe.
Includes the runtime regression test with the **`172.19.x`-rejected** discriminator the original
`TrustedProxyReadinessTest` lacked. Deploy 2A.1 with `TRUSTED_PROXIES` UNSET (pilot-safe); pin `172.20.0.0/24` only
in the Phase 2B retry. **Implementation UNPROMOTED / not started.** Re-attempt Phase 2B only after the fix is merged
+ deployed and the runtime pin is proven effective.

## Authorization state

**No queued item has been promoted.** Per the authority rule, ChatGPT may promote exactly one queued item from
`TASK_QUEUE.md` (recommended: the Phase 2A.1 / DEFECT-002 code fix) into this file after reviewing these reports.
Until then there is no authorization to start any task. **Do NOT proceed to DNS / public TLS / Phase 2C.**

*Prior completed context: `SCA-COLLECTOR-AUTHENTICITY-BADGE-052` DONE (deployed `0e2e151`; DEFECT-001 FIXED);
`SCA-053` pilot-readiness audit DONE (functionally pilot-ready). `SCA-PRODUCTION-CUTOVER` remains OPEN /
BLOCKED — now gated on DEFECT-002, then a Jeremy-provided permanent HTTPS domain + a quiet maintenance window.*

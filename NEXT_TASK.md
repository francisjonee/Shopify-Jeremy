# NEXT TASK

**STATUS: `SCA-PRODUCTION-CUTOVER Phase 2A.1 / DEFECT-002` — IMPLEMENTED + PUSHED (push-only). Awaiting ChatGPT
pre-merge audit. NOT merged, NOT deployed.**

Base/deployed `d089e7a27856d7aacc45ccb9fb3333dbf4d4ade0`. Feature branch `sca-cutover-trusted-proxy-2a1` on
`github-sca-platform` — fix `acea325dc8bbfcab04f4f88ac842c329bd5c8861`, task report `75f9e9e`
(`docs/task-reports/SCA-CUTOVER-TRUSTED-PROXY-2A1.md`). Governance evidence:
`docs/SCA-PRODUCTION-CUTOVER-PHASE2A1-DEFECT-002-PLAN.md` + this entry.

## What was implemented (push only)

Fixes DEFECT-002 — trusted proxies are now resolved at request time from `config('trustedproxy.proxies')`, not
prematurely from `env()` in `bootstrap/app.php::withMiddleware()`:
- **`config/trustedproxy.php` (new):** sole reader of `TRUSTED_PROXIES`; fail-safe parse (unset/empty → trust none;
  whitespace/empty entries removed; valid IPv4/IPv6/CIDR retained; `*`/`**`/`REMOTE_ADDR`/malformed rejected); **no
  RFC1918 default**; `config:cache`-safe.
- **`bootstrap/app.php`:** dropped the `env()` read and the `at:` argument; kept the explicit forwarded-header mask;
  `TrustProxies` (default global middleware) resolves the config value lazily at handle time; no `TrustProxies::at()`.
- **`TrustedProxyReadinessTest`:** config-driven (no `TrustProxies::at`/static/pre-boot env) with the mandatory
  **`172.19.x`-rejected** discriminator, fail-safe/default matrix, plain-HTTP pilot compat, and a static gate that
  `bootstrap/app.php` performs no `env('TRUSTED_PROXIES')` read.

## Verification

- Focused `TrustedProxyReadinessTest`: **14 passed (57 assertions)**. Full `tests/Feature/Sca`: **635 passed
  (3432 assertions)**, exit 0.
- **Discriminator proven to catch DEFECT-002:** reverting `bootstrap/app.php` to base `d089e7a` makes the `172.19.x`
  and trust-none tests **FAIL**; the fix makes them pass.
- **config:cache hard gate passed:** baked `["172.20.0.0/24"]` (via a process-env only — production `.env` untouched);
  with config cached and `getenv=false`, the real middleware honored `172.20.x` / rejected `172.19.x`+public; cache cleared.
- **Trust-none default (TRUSTED_PROXIES unset):** `config('trustedproxy.proxies')=null`, spoofed forwarded proto
  ignored; `:8080` pilot `/up`,`/admin/login`,`/collector/login` all 200.
- **Pilot restored** to deployed main `@ d089e7a`: clean tree, `--no-dev` (phpunit pruned), kr-app healthy on
  `195.26.255.80:8080` (`sca_internal` only), MariaDB private, **DOCKER-USER byte-identical**, no probe leftovers.

## Boundaries honored

No migration/schema/route/ACL/domain mutation; production `.env` unchanged (`TRUSTED_PROXIES` stays unset); no
DNS/Caddy/Docker-net/firewall/`APP_URL`/`PUBLIC_QR_BASE_URL`/`SESSION_SECURE_COOKIE`/`SCA_PUBLIC_PREVIEW`/SMTP/QR
change; Phase-2A Apache behavior unchanged. **Phase 2B NOT retried.**

**DEFECT-002 remains OPEN** until merge/deploy + runtime verification. **Phase 2B remains BLOCKED.**
`SCA-PRODUCTION-CUTOVER` remains **OPEN**. **PUSH ONLY — stopped for ChatGPT audit; no merge, no deploy.** Deploy
sequencing when authorized: deploy with `TRUSTED_PROXIES` unset (trust-none, pilot-safe); pin `172.20.0.0/24` only in
the Phase 2B retry.

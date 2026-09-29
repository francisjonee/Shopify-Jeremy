# NEXT TASK

**STATUS:** NONE — no executable task is currently authorized. **ACTIVE = NONE, NEXT_TASK = NONE.**

## Latest: SCA-PRODUCTION-CUTOVER Phase 2A.1 / DEFECT-002 — **DONE (merged + deployed)** 2026-09-29

Merged `--no-ff` + deployed to production `main` at **`c568331f9eca01cd2eed068f3e0b6af3e9381665`**
(parents: base `d089e7a`, feature `75f9e9e`; fix `acea325`). **DEFECT-002 is FIXED/CLOSED**
(`docs/PENDING-DEFECTS.md`).

Trusted proxies now resolve at request time from `config('trustedproxy.proxies')` (new `config/trustedproxy.php`,
fail-safe, **no RFC1918 default**, `config:cache`-safe); `bootstrap/app.php` reads no `env('TRUSTED_PROXIES')` and
passes no `at:`/`TrustProxies::at()`. **Deployed in trust-none mode** — production `TRUSTED_PROXIES` left **UNSET**.
Deploy gate: focused 14/57 + full `tests/Feature/Sca` 635/3432; `migrate → Nothing to migrate` (migrations 118);
`DEPLOYED_HEAD == ORIGIN_MAIN == MERGE_SHA == c568331`. Deployed-runtime proof (real HTTP middleware):
`env`/`config`/boot-static all NULL (no hidden RFC1918 fallback); default rejects spoofed `X-Forwarded-*` from every
peer; with an in-memory `172.20.0.0/24` pin the **DEFECT-002 discriminator now rejects `172.19.x`** and honors
`172.20.x`. `:8080` pilot intact (`/up`,`/admin/login`,`/collector/login` = 200, no forced HTTPS redirect); deployed
Apache has no active forwarded-HTTPS path; MariaDB private; DOCKER-USER byte-identical; production provenance counts +
QR identity fp `6bb119ee…` unchanged (zero mutation). Pilot on the public `195.26.255.80:8080` bind, `--no-dev`, clean
tree, no config cache. Evidence: impl repo `docs/task-reports/SCA-CUTOVER-TRUSTED-PROXY-2A1.md`.

## Authorization state

`SCA-PRODUCTION-CUTOVER` remains **OPEN**. With DEFECT-002 fixed, **Phase 2B (edge/Caddy pre-DNS) is now eligible for
retry** — but it was **NOT** retried in this task and is not authorized to start. No queued item is promoted; per the
authority rule ChatGPT promotes exactly one item (the natural next candidate is the Phase 2B retry) after review.
**SCA-054 must not start.** Nothing is active.

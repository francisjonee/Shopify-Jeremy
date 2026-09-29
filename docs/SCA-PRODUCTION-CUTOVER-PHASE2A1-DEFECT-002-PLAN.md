# SCA-PRODUCTION-CUTOVER — Phase 2A.1 (DEFECT-002) — Trusted-Proxy Runtime Fix — **PLANNING / ROOT-CAUSE AUDIT (read-only)**

**Date:** 2026-09-29
**Deployed baseline:** `d089e7a27856d7aacc45ccb9fb3333dbf4d4ade0` (Laravel 12.66.0)
**Status:** PLANNING ONLY — no implementation, no branch, no `.env`/DNS/Caddy/Docker/firewall/schema change.
ACTIVE = NONE, NEXT_TASK = NONE, nothing promoted. Blocks Phase 2B retry.
**Prereq context:** Phase 2B failed + rolled back (`docs/SCA-PRODUCTION-CUTOVER-PHASE2B-IMPLEMENTATION-RESULT.md`); DEFECT-002 is the blocker.

---

## 1. Root cause — reproduced & confirmed against Laravel 12.66 code + runtime

`bootstrap/app.php` resolves the trusted-proxy list **eagerly inside the `withMiddleware()` closure**:

```php
$trustedProxies = ...explode(',', (string) env('TRUSTED_PROXIES', '10.0.0.0/8,172.16.0.0/12,192.168.0.0/16'));
$middleware->trustProxies(at: $trustedProxies, headers: …);
```

**Framework flow (verified in `vendor/laravel/framework`):**
- `Foundation/Configuration/ApplicationBuilder::withMiddleware()` registers the closure as
  `afterResolving(HttpKernel::class, …)` — it runs **when the HTTP kernel is resolved**, which in
  `public/index.php` happens at `$app->handleRequest()` → `make(Kernel)`, **before** `$kernel->handle()` runs the
  `LoadEnvironmentVariables` / `LoadConfiguration` bootstrappers.
- `Configuration/Middleware::trustProxies(at:)` calls **`TrustProxies::at($at)`**, storing the value in the
  **static** `TrustProxies::$alwaysTrustProxies`.
- At request time, `Http/Middleware/TrustProxies::handle()` → `setTrustedProxyIpAddresses()` resolves:
  ```php
  $trustedIps = $this->proxies() ?: config('trustedproxy.proxies');
  // proxies() === static::$alwaysTrustProxies ?: $this->proxies
  ```

**Therefore:** at closure time `env('TRUSTED_PROXIES')` is **NULL** (env not yet loaded), so the code falls back to
the hardcoded RFC1918 default and calls `TrustProxies::at(['10.0.0.0/8','172.16.0.0/12','192.168.0.0/16'])`. That
non-null static then **short-circuits** (`?:`) the framework's own `config('trustedproxy.proxies')` fallback at
request time. The `.env` pin is **inert at runtime**; trust silently stays RFC1918-wide.

**Empirical proof (web SAPI `apache2handler`, throwaway probe on the IP-locked `:8080`, deleted after):**

```
env(TRUSTED_PROXIES): PRE-bootstrap = NULL ; AT-kernel-make = NULL ; POST-bootstrap = 172.20.0.0/24
static $alwaysTrustProxies right after boot = ['10.0.0.0/8','172.16.0.0/12','192.168.0.0/16']

(A) BUGGY (static in force, config pin ignored):
    remote=172.19.0.4  -> scheme=https  (WRONGLY honored)   remote=172.20.0.5 -> scheme=https
(B) FIX (static null -> config('trustedproxy.proxies')='172.20.0.0/24'):
    172.20.0.5 -> https (honored)   172.19.0.4 -> http (REJECTED, ip/host unspoofed)   203.0.113.9 -> http (REJECTED)
(C) FAIL-SAFE (static null, config empty/malformed):
    null -> trust none   [] -> trust none   ['not-a-cidr'] -> no match (trust none)
```

This is a **code defect in `d089e7a`**, not a config/Caddy/network error, and **not a regression** — `d089e7a`
always behaved this way; Phase 2A's stated "Phase 2B pins the edge CIDR" was never runtime-effective.

---

## 2. Correct Laravel-12 mechanism (verified, not assumed)

`config()` is **also empty at closure time** (LoadConfiguration runs in the same post-kernel-resolve bootstrap phase
as LoadEnvironmentVariables), so a "read `config()` inside the closure" fix would hit the **same** timing bug and is
rejected. The correct, framework-native mechanism is the one the middleware already provides: **do not set the static
at all**, and let `TrustProxies::handle()` read **`config('trustedproxy.proxies')` at request time** (config loaded;
`config:cache`-safe because `env()` then lives only inside a config file). Proven working in probe section (B).

**Smallest fix (design, to be implemented in Phase 2A.1 — NOT done here):**
1. **Add `config/trustedproxy.php`** — the only place `env('TRUSTED_PROXIES')` is read:
   ```php
   <?php
   // Trusted reverse-proxy CIDRs/IPs, parsed fail-safe. Read at request time by
   // Illuminate\Http\Middleware\TrustProxies via config('trustedproxy.proxies'); config:cache-safe.
   $raw = array_values(array_filter(array_map('trim',
       explode(',', (string) env('TRUSTED_PROXIES', ''))),   // DEFAULT = '' => trust none (see §4)
       fn ($v) => $v !== '' && $v !== '*' && $v !== '**'      // never allow calling-IP / universal trust
   ));
   return ['proxies' => $raw === [] ? null : $raw];           // null => middleware trusts none
   ```
2. **Edit `bootstrap/app.php`** — remove the `env()` line and the `at:` argument; keep the explicit header set
   (a constant int — no env dependency, safe at closure time):
   ```php
   $middleware->trustProxies(headers: Request::HEADER_X_FORWARDED_FOR
       | Request::HEADER_X_FORWARDED_HOST | Request::HEADER_X_FORWARDED_PORT | Request::HEADER_X_FORWARDED_PROTO);
   ```
   With no `at:`, `TrustProxies::$alwaysTrustProxies` stays null → the `config('trustedproxy.proxies')` fallback
   governs, resolved at request time.

Scope: **one new config file + ~4 changed lines** in `bootstrap/app.php`. No other code.

---

## 3. `config:cache` safety

- Production deploy runs **`config:clear`** (not `config:cache`) — `scripts/deploy-preview.sh:67-68` — so
  `config/trustedproxy.php` is evaluated fresh each request (after `LoadEnvironmentVariables`); the fix works today.
- The fix is **also `config:cache`-safe**: `env()` appears **only** inside `config/trustedproxy.php` (baked into
  `bootstrap/cache/config.php` at cache time), and the middleware reads `config('trustedproxy.proxies')` at runtime —
  never `env()` outside config files. Standard caveat: if config is ever cached, it must be re-cached after changing
  `TRUSTED_PROXIES` (document in the Phase 2B retry runbook).

---

## 4. Fail-safe parsing + the RFC1918-default decision

**Fail-safe (proven, §1.C):** explicit CIDR/IP list accepted; empty/malformed → `null`/`[]` → **trust none**;
individual malformed entries (e.g. `not-a-cidr`) never match in Symfony `IpUtils` so cannot broaden trust; the parser
explicitly filters `*`/`**` so a stray value can never enable universal / calling-IP trust.

**Decision — change the default from RFC1918 to TRUST NONE (recommended).** The RFC1918 default is the exact
mechanism that let broad trust win silently. Recommended new default = **trust none unless `TRUSTED_PROXIES` is
explicitly configured.**
- **`:8080` pilot compatibility — no regression.** The pilot is direct plain HTTP (client → host `:8080` DNAT →
  kr-app); clients send **no** `X-Forwarded-*`, so trust is irrelevant to pilot correctness (scheme=http from the
  connection, host from the `Host` header, `APP_URL` is the http pilot URL). Verified behavior: with trust none, an
  ordinary request is unaffected; only forwarded-header *honoring* is disabled, which the pilot never uses.
- **Future Caddy path.** Phase 2B retry pins `TRUSTED_PROXIES=172.20.0.0/24`; only then is anything trusted, and only
  the edge `/24`. Until the edge exists, trust none is the strictly safer posture.
- **Consequence to accept:** if `TRUSTED_PROXIES` is unset/misconfigured behind a real proxy, the app emits `http://`
  links / no secure cookie (fails safe, visibly) rather than silently trusting a wide range. This is the desired
  direction. Documented here; do not change without recording a new decision.

---

## 5. Runtime regression test that would have caught DEFECT-002

**Why the current `TrustedProxyReadinessTest` passed while production was wrong (the coverage hole):**
- It **never pins** `TRUSTED_PROXIES` and only tests the *default* model, and its peers are chosen so buggy-default and
  a correct-pin are indistinguishable: `TRUSTED_PEER=172.20.0.9` is inside **both** `172.16.0.0/12` (default) and any
  `172.20.0.0/24` pin; `UNTRUSTED_PEER=203.0.113.9` and `127.0.0.1` are outside **both**. So every assertion yields the
  same result whether the pin is effective or not. It **never exercises a peer inside RFC1918 but outside the intended
  `/24`** (e.g. `172.19.x`) — the only discriminator.
- Trap to avoid: a pin test that sets the value via `putenv()`/process-env **before** app creation would *falsely pass*
  on the buggy code, because process-env IS visible to `env()` at closure time — masking the .env-file ordering that
  breaks production. Likewise a test that calls `TrustProxies::at(...)` or `setTrustedProxies()` directly bypasses the
  defect.

**Required new test (`Tp8`… in `TrustedProxyReadinessTest`, or a new `TrustedProxyPinTest`):** supply the pin the way
production does — **via config** (`config(['trustedproxy.proxies' => '172.20.0.0/24'])`, i.e. the value the config file
would yield), never via `TrustProxies::at()` or process-env — then drive **real requests through the HTTP kernel**
(global middleware stack incl. `TrustProxies`) with controlled `REMOTE_ADDR` + spoofed `X-Forwarded-*`, asserting the
resolved scheme/host/client-IP. Call `TrustProxies::flushState()` in `setUp()` so the boot-time static cannot leak.
Discriminating matrix (all through `$this->call(... server: [...])`):

| REMOTE_ADDR | config pin | expect | proves |
|---|---|---|---|
| `172.20.0.5` (in /24) | `172.20.0.0/24` | scheme=https, host=domain, ip=XFF | edge honored |
| **`172.19.0.4`** (RFC1918, not in /24) | `172.20.0.0/24` | scheme=http, host≠domain, ip=peer | **the discriminator DEFECT-002 missed** |
| `203.0.113.9` (public) | `172.20.0.0/24` | scheme=http, ip=peer | public rejected |
| `172.20.0.5` | `''`/null (unset) | scheme=http | trust-none default / fail-safe |
| `172.20.0.5` | `not-a-cidr` | scheme=http | malformed doesn't broaden |

On **buggy** `d089e7a` the `172.19.0.4` row FAILS (static RFC1918 preempts config → honored); on the **fixed** code it
passes. That single row is the regression guard. (Keep the existing `tp1/tp4/tp4b/tp5/tp6/tp7` and update their
narrative from "RFC1918 default" to the config-driven pin.)

**`config:cache` variant:** add a deploy/CI step (outside the unit suite) that runs `php artisan config:cache` then a
**runtime web probe** (curl through Apache/mod_php on `:8080`, controlled `REMOTE_ADDR`) asserting `172.20.x` honored /
`172.19.x` rejected — proving the cached-config path reads `config()` not `env()`. Plus a static assertion that
`bootstrap/app.php` contains **no** `env('TRUSTED_PROXIES')` (grep gate) so nothing reads env outside config files.

---

## 6. Non-impact confirmation

The fix requires **no** change to: Apache (`docker/apache-override.conf` stays as deployed — the header set is
preserved via the `headers:` arg; the removed 2A Apache shim stays removed), schema/migrations, routes, ACL/middleware
groups, provenance/QR/ownership data, DNS, Caddy, Docker networks, or firewall/DOCKER-USER. `TrustProxies` is a
**default global middleware** (`getGlobalMiddleware()`), so omitting `at:` does not remove it. Only bootstrap/app.php +
a new config file + tests change.

---

## 7. Deployment sequencing

1. **Phase 2A.1 deploy with `TRUSTED_PROXIES` UNSET** in production `.env` (default = trust none). Safe for the live
   `:8080` pilot (no forwarded headers in play), and it removes the silent broad-trust. Governed flow:
   feature branch (push only) → independent pre-merge verification (the new `172.19.x` discriminator must fail on base
   `d089e7a` and pass on the branch) → merge + `deploy-preview.sh` (mandatory `tests/Feature/Sca` gate) → post-deploy
   runtime check that `172.20.x`/`172.19.x` behave correctly and the pilot is intact.
2. **Only in the subsequent Phase 2B retry**: set `TRUSTED_PROXIES=172.20.0.0/24` (now runtime-effective) and build the
   edge, re-running Phase 2B's §5–§7 gates (now expected to pass).
   Rationale: pinning the `/24` earlier is pointless (no edge yet) and less safe than trust-none; deferring keeps each
   step minimal and reversible.

---

## 8. Smallest implementation plan + acceptance gates

**Change set:** `config/trustedproxy.php` (new) · `bootstrap/app.php` (drop env line + `at:`, keep `headers:`) ·
`tests/Feature/Sca/TrustedProxyReadinessTest.php` (add the config-driven discriminating matrix incl. the `172.19.x`
row + trust-none/malformed rows; `flushState()` in setUp; re-narrate existing cases).

**Acceptance gates:**
- On base `d089e7a`, the new `172.19.x`-rejected test **fails** (proves it catches DEFECT-002); on the branch it passes.
- Full `tests/Feature/Sca` green (deploy gate).
- Runtime web proof (curl through mod_php): with `TRUSTED_PROXIES=172.20.0.0/24` set, `172.20.x` honored + `172.19.x`
  rejected + public rejected; with it unset, trust none.
- `config:cache` variant proof (as §5).
- `grep 'env(' bootstrap/app.php` shows no `TRUSTED_PROXIES` read.
- Zero provenance mutation; `:8080` pilot + DOCKER-USER + MariaDB privacy unchanged; no schema (`migrate` → nothing).

**Boundaries honored:** no change to DNS, Caddy, Docker networks, production `.env`, `APP_URL`, `PUBLIC_QR_BASE_URL`,
`SESSION_SECURE_COOKIE`, `SCA_PUBLIC_PREVIEW`, SMTP, firewall/DOCKER-USER, QR identities, or provenance/domain data.
**Do not retry Phase 2B here.** ACTIVE = NONE, NEXT_TASK = NONE — return to ChatGPT for promotion.

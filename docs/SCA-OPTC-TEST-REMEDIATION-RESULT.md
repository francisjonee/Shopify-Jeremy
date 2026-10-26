# SCA-OPTC — Test-Only Release Remediation Result

**Status: TEST-ONLY remediation implemented + non-destructively verified; available for independent ChatGPT audit. NO focused/full/baseline DB test executed. No application logic changed.** Not merged / not deployed / no production migration / no restart / no integration activation / 139-140 untouched. Candidate `feat/sca-optc-secure-claim` advanced **`1df81d5` → `1361357`** (pushed). `main 6022b75` + `sca_krayin` untouched.

Changed files (6; all under `app/tests/` or `scripts/` — **zero application-logic change**):
- NEW `app/tests/Support/id_exposure.php` — pure, DB-free `sca_detect_id_exposure()`.
- `app/tests/TestCase.php` — `assertIdNotExposed()` helper (+ require the pure detector).
- `app/tests/Feature/Sca/CollectorHandleTest.php` — `h7` corrected.
- `app/tests/Feature/Sca/CertificateDocumentClassificationTest.php` — `d9` corrected.
- NEW `scripts/seed-test-admin.php` — idempotent, disposable-DB-guarded default-admin seeder.
- `scripts/run-optc-tests.sh` — APP_URL + file cache + admin-seed wiring, `assert` phase, selftest `[13]`/`[14]`.

## 1. Narrow h7/d9 assertion corrections (all genuine checks preserved)

`sca_detect_id_exposure($body,$id)` flags an internal id **only** when exposed AS AN IDENTIFIER:
(a) a quoted attribute/JSON value `"<id>"`, or (b) a URL path segment under an **alphabetic** route segment `/<route>/<id>`. It deliberately ignores bare numbers in CSS/px, viewport scale, dotted versions, and slash dates (whose preceding path segment is numeric, so (b) cannot match). `CollectorHandleTest::h7` and `CertificateDocumentClassificationTest::d9` now call `assertIdNotExposed()` for the numeric PKs; **all** genuine checks remain unchanged (opaque `$ref`, `email`, `public_ref`, `'catalog/'`, `storage_path`, `checksum_sha256`, `"subject_id"`, `qr_token`).

## 2. Positive/negative assertion controls (non-destructive)

selftest `[13]` runs the **real** detector in a `--network none`, no-DB container:
- **Positive (must be detected):** `data-id="4242"`, `/u/ada/items/4242/image`, `{"collector_id":"4242"}` → all flagged.
- **Negative (must pass):** `max-width:4242px`, `initial-scale=1`, `2026/10/26` (id 10), `v4.2.42`, `<style>.x{z-index:4242}</style>`, `padding:42 0` → none flagged.
Result: `CONTROLS-OK`.

## 3. Isolated-harness fixes (runner env/seed only — NO weakening of auth, rate limiting, privacy, or app logic)

- **Canonical test admin** (`scripts/seed-test-admin.php`, run post-migrate): creates the default admin (user id 1 + all-permission role) if absent — the same admin an installed app has. Idempotent; fail-closed against `sca_krayin` (and any non-disposable DB); random password (core tests use `actingAs`, not a login). Fixes `AuthenticationTest`×2 + `HelpTest` (`getDefaultAdmin()` = `User::find(1)`).
- **Persistent cache** (`CACHE_STORE=file`): the login/forgot-password RateLimiter now accumulates across requests so the throttle is observable. The limiter, its middleware, and its thresholds are **unchanged** — only the store is made persistent. Fixes the two `AuthenticationHardeningTest` rate-limit tests. (`AuthenticationHardeningTest` creates its own probe users, so it does not depend on the admin seed.)
- **Canonical `APP_URL`** (`https://verify.secondchanceauthenticators.com`): matches production URL generation. Fixes `TransactionalEmailHardeningTest::h8`. No app code changed.

## 4 & 5. No weakening; every disposable-DB safeguard preserved

Only `app/tests/*` and `scripts/*` changed — no `app/packages/Sca/*` (no auth/rate-limit/collector-privacy/application logic). The runner's create-not-drop ownership, `verify_effective` (effective host+schema), the XML-aware override validator, per-run unique naming, and `perRunDbName`/`sca_is_per_run_db` are untouched; `selftest` still exercises them (sections [1]-[12]).

## 6. Verification plan — corrected

`h7` (`CollectorHandleTest`) and `d9` (`CertificateDocumentClassificationTest`) are **not** in the 5-file focused set, so a dedicated **`assert`** runner phase runs exactly those two files on their own per-run unique DB. The sequence to run when DB tests are authorized:
1. `selftest` (no DB) — expect 63/0.
2. `focused` — the 5 Option-C files on a unique DB (expect 68/0).
3. `assert` — `CollectorHandleTest` + `CertificateDocumentClassificationTest` on a unique DB (expect `h7`/`d9` now PASS with the §3 admin seed + §1 assertions).
4. `full` — full suite on a unique DB (expect the 6 environment failures resolved and `h7`/`d9` resolved → 0 failures; residuals enumerated, not dismissed).
5. **Baseline comparison (safe):** the clean `6022b75` baseline still has the hardcoded `sca_domain_test` guards/concurrency and lacks this runner, so the baseline is run (as before) via a **manual isolated invocation** on a **freshly-created, exclusively-owned** `sca_domain_test` (confirmed absent → created → dropped; never dropping/overwriting an existing DB). Comparability: both runs use the same image, the same per-test `DatabaseTransactions` rollback, and dependency-identical vendor; they differ only in the DB **name** (candidate per-run unique vs baseline's required `sca_domain_test`) and in the candidate's test-safety changes — the failing-SET comparison remains valid because each runs its own code against a freshly-migrated disposable schema. (Note: the §3 harness fixes make the candidate's env failures resolve; the baseline, unchanged, will still show them — so after remediation the candidate is expected to be strictly better, and any candidate-only failure is investigated.)

## Non-destructive evidence

- `bash -n scripts/run-optc-tests.sh` — OK.
- `scripts/run-optc-tests.sh selftest` — **63 passed / 0 failed** (no DB/network/live mount; XML-override, per-run-guard, and id-exposure controls ran php in a throwaway `--network none` container). Includes `[13]` controls `CONTROLS-OK` and `[14]` wiring (h7/d9 corrected; genuine checks kept; runner sets APP_URL + file cache + admin seed).
- `php -l` — clean on all changed/new PHP files (`--network none`, read-only, no DB).
- **No focused/full/assert/baseline DB test executed.**

**STOP — test-only remediation + non-destructive evidence available for independent ChatGPT audit before database-test authorization. No merge/deploy/migrate/restart/activation; 139/140 untouched; backup/DR + operational readiness remain separate workstreams.**

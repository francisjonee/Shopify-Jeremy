# SCA-OPTC — Authorized Full-Regression + Clean Baseline Evidence

**Status: the owner-authorized full suite + clean `6022b75` baseline executed on isolated per-run disposable databases. No Option-C-attributable regression. Not merged / not deployed / no production migration / no restart / no Shopify/Stripe/SMTP activation.** `main 6022b75` + production `sca_krayin` untouched.

- **Candidate SHA:** `1df81d51827a93cb28e6a21229565f6982b4cfaf` (`feat/sca-optc-secure-claim`), isolated worktree.
- **Baseline:** clean `main` `6022b75`, isolated worktree, dependency-identical vendor (same `composer.lock`).
- **Date:** 2026-10-22.

## Isolation (both runs)

- **Candidate** full suite ran on a freshly-created unique DB **`sca_optcfull_test_e59e2e91`** via `scripts/run-optc-tests.sh full` (CREATE-not-drop, abort-on-collision, register-after-create). Effective-connection verified twice: host decision + in-container re-verify — both `db=sca_optcfull_test_e59e2e91 host=kr-mariadb live=sca_optcfull_test_e59e2e91`; `ok: no DB override in phpunit.xml`.
- **Baseline** full suite ran on a separate, freshly-created DB **`sca_domain_test`** (the baseline's unmodified inline guards + hardcoded concurrency require that name). It was confirmed absent beforehand (exclusive ownership by creation), created, used, and dropped. `kr-mariadb` = mariadb:10.11.18 on `sca_internal`; root creds verified.
- No pre-existing disposable database existed or was deleted. Each run owned only the DB it created.

## Results

| | Candidate `1df81d5` (`sca_optcfull_test_e59e2e91`) | Baseline `6022b75` (`sca_domain_test`) |
|---|---|---|
| Failed | **8** | 12 |
| Skipped | 0 | 0 |
| Assertions | 7573 | 7490 |
| Passed (incl. PHPUnit risky/deprecation warnings) | ~1450 (1449 warn + 1 clean) | ~1438 (1437 warn + 1 clean) |

The PHPUnit "warnings" counts (1449 / 1437) are passing tests that emit risky/deprecation warnings — a pre-existing harness characteristic present on both, not a regression. 0 tests skipped in either run.

### Failing-set comparison

- **Shared (fail on BOTH — pre-existing environment/fragility of this minimal harness, unrelated to Option C):** `AuthenticationTest` (dashboard, logout — TypeError), `HelpTest`, `CertificateDocumentClassificationTest::d9`, `TransactionalEmailHardeningTest::h8` (canonical-URL), `AuthenticationHardeningTest` ×2 (rate-limit 429). These depend on admin seed/config, the production canonical `APP_URL`, and a real throttle cache store — none configured in the ephemeral harness.
- **BASELINE-only (5) — candidate PASSES these (an improvement from the Option-C per-run parameterization):** `CollectorCollectionConcurrencyTest::cc1a/cc1b/cc2`, `MarketReferenceConcurrencyTest::cc mr1`, `ServiceCorrectionConcurrencyTest::cc sc1`. On the candidate these concurrency tests and their secondary connections + spawned workers correctly bound to the per-run unique DB and passed.
- **CANDIDATE-only (1): `CollectorHandleTest::h7`.** Investigated (not dismissed): the failure is `Not to contain: 220` at `CollectorHandleTest.php:285`, i.e. the test asserts a bare numeric DB id (`220`) is not a substring of the rendered HTML — but `220` appears in the injected dev-preview CSS `max-width:220px`. This is a pre-existing numeric-id-substring fragility: it also fails in isolation on id `1` (every page contains "1"), and the baseline only avoided it because its autoincrement id for that test landed on a non-colliding value. The candidate adds test rows (new `FulfillmentReleaseTest` + extra grant/claim tests) that shift the id reached by the time `CollectorHandleTest` runs to `220`. **Option C modifies no collector-handle / public-profile code** (verified across the candidate diff). It is a pre-existing test-hardening item, tracked separately, out of Option C scope.

### Secondary-connection / worker verification (authorization point 3)

On the candidate run the 7 concurrency tests (secondary `*_bar`/`*_racer` connections) and the 3 spawned workers (`cp6_worker`, `mre_worker`, `svc_correction_worker`) executed against the per-run unique DB `sca_optcfull_test_e59e2e91` and **passed** — demonstrating every secondary connection and worker bound only to the assigned disposable database (each worker's env carried that DB + host/creds, and each worker's `sca_is_per_run_db` guard would have failed closed otherwise).

## Cleanup

After both runs: `SHOW DATABASES LIKE 'sca%'` → **only `sca_krayin`**. Both disposable databases (`sca_optcfull_test_e59e2e91`, `sca_domain_test`) were dropped. No residual disposable database remains.

## Production untouched

Live app HEAD `6022b75`; loopback `302` (up); `sca_krayin.migrations` unchanged at `max_batch=27, total=140` — no migration or write hit production. No merge/deploy/restart/integration activation.

## Verdict

**No Option-C-attributable regression.** The candidate fixes 5 baseline concurrency failures and shares the 7 pre-existing env/fragility failures; the single candidate-only difference (`CollectorHandleTest::h7`) is a demonstrated pre-existing numeric-id-substring fragility in code Option C does not touch. Full regression is **not** declared a blanket PASS — failures remain and are enumerated/classified with evidence above.

**STOP — complete full-regression + baseline evidence delivered for independent ChatGPT review. No merge/deploy/migrate/restart/activation.**

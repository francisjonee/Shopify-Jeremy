# SCA-OPTC — Authorized Full Regression + Clean Baseline Evidence (post-remediation)

**Status: owner-authorized full candidate suite + clean `6022b75` baseline executed on separate per-run disposable databases. NO genuine Option-C application regression. Not merged/deployed/migrated/restarted/activated; 139-140 untouched.** `main 6022b75` + production `sca_krayin` unchanged.

- **Candidate:** `0f41e2e` (`feat/sca-optc-secure-claim`), isolated worktree, on unique DB `sca_optcfull_test_cb83eb4a` (created + verified + dropped by the runner).
- **Baseline:** clean `6022b75`, isolated worktree, on a separate **confirmed-absent, exclusively-created** `sca_domain_test` (created + dropped; never overwrote an existing DB), **equivalent harness** (same `APP_URL` + file cache + canonical admin seed + dependency-identical vendor) so only code/test differences — not harness config — show in the comparison.
- **Date:** 2026-10-26.

## Isolation (both runs)

- Candidate: effective Laravel connection verified twice (host decision + in-container re-verify) — `db=sca_optcfull_test_cb83eb4a host=kr-mariadb live=sca_optcfull_test_cb83eb4a`; XML override clean; admin seed verified `id=1 active role_id=1 permission_type=all`. Concurrency workers + secondary connections bound only to this DB (they passed — see below).
- Baseline: fresh exclusive `sca_domain_test` on `kr-mariadb`; dropped after.
- No pre-existing disposable DB existed or was deleted; each run owned only the DB it created.

## Results

| | Candidate `0f41e2e` (`sca_optcfull_test_cb83eb4a`) | Baseline `6022b75` (`sca_domain_test`) |
|---|---|---|
| Failed | **3** | 8 |
| Skipped | 0 | 0 |
| Assertions | 7595 | 7507 |
| Passed (incl. PHPUnit risky/deprecation warnings) | ~1455 | ~1442 |

(The "warnings" counts are passing tests that emit PHPUnit risky/deprecation warnings — a pre-existing harness characteristic on both runs; 0 skipped in either.)

### Failing-set comparison (harness held equivalent)

- **SHARED (fail on BOTH → pre-existing test-environment condition, NOT Option C):** `AuthenticationHardeningTest` ×2 (admin login + forgot-password rate-limit; expected 429, got 200). The admin-login throttle does not trip in this ephemeral harness even with a persistent file cache; it is unrelated to Option C (which changes no authentication/throttle code) and present on the clean baseline too.
- **BASELINE-only (6) — the candidate FIXES these:** `CertificateDocumentClassificationTest::d9` (now passes via the context-aware id-exposure assertion) and the 5 concurrency tests `CollectorCollectionConcurrency::cc1a/cc1b/cc2`, `MarketReferenceConcurrency::cc mr1`, `ServiceCorrectionConcurrency::cc sc1` (now pass via the per-run DB parameterization — on the candidate their secondary connections + spawned workers correctly bound to `sca_optcfull_test_cb83eb4a`).
- **CANDIDATE-only (1): `QrPrintLabelTest::ql3`** — failure is `DECODE_FAILED: checkAndNudgePoints 2, x: -16, y: 60, d: 456` (QrPrintLabelTest.php:202), an internal **QR-decoder** error, i.e. the known non-deterministic QR-decode flake (same class as the documented `QrArtifactTest::rg2`/`rg8` `DECODE_FAILED` flakes that clear on re-run). **It is NOT an Option-C regression:** the Option C diff (vs `6022b75`) touches **no QR production code** (verified: no non-test QR file changed — the 15 Option C files are claim/fulfillment/grant/views/acl/routes/migration only). Per the authorization ("no additional database runs beyond the approved full suite and baseline comparison") it was not re-run; it is classified as a pre-existing QR-decoder flake on the evidence above, not dismissed.

### Concurrency workers / secondary connections (authorization point 4)

On the candidate run the 7 concurrency tests and the 3 spawned workers (`cp6_worker`, `mre_worker`, `svc_correction_worker`) executed against the single per-run DB `sca_optcfull_test_cb83eb4a` and **passed** — each secondary connection and worker bound only to that assigned disposable database.

## Cleanup & production isolation

- After both runs: `SHOW DATABASES LIKE 'sca%'` → **only `sca_krayin`** (both `sca_optcfull_test_cb83eb4a` and `sca_domain_test` dropped). No residual disposable DB.
- **Production unchanged:** live app HEAD `6022b75`; loopback `302`; `sca_krayin.migrations` = `max_batch=27, total=140` (identical to the pre-run baseline — no migration/write touched production).

## Verdict

**No genuine Option-C application regression.** The candidate fixes 6 baseline failures (d9 + 5 concurrency), shares the 2 pre-existing rate-limit environment failures, and its single candidate-only difference (`QrPrintLabelTest::ql3`) is a known non-deterministic QR-decoder flake in code Option C does not touch. The full suite is NOT declared a blanket PASS — the remaining failures are enumerated and classified with evidence (2 environment + 1 flake).

**STOP — full-regression + baseline evidence delivered for independent ChatGPT review. No merge/deploy/migrate/restart/activation.**

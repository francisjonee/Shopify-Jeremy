# SCA-OPTC — Audit Remediation PLAN (candidate `7b41e8d`)

**Status: PLAN ONLY — awaiting owner + ChatGPT approval. Nothing implemented; no code changed; no test run executed.**
Per the restriction, **no further destructive test run** will be executed until the revised database-isolation safeguards are independently reviewed. Work will remain on the existing candidate branch `feat/sca-optc-secure-claim`. No merge, deploy, production migration, service restart, or integration activation.

Responds to the independent ChatGPT audit's 4 findings on `7b41e8d`.

---

## Finding 1 — Shared-database destruction (runner DROPs/recreates `sca_domain_test`)

**Accepted.** An allowed name is not exclusive ownership; the full-suite phase must not drop/recreate the shared `sca_domain_test` (a concurrent session could own it).

**Root cause of the constraint:** ~98 SCA test files inline `if (DB::connection()->getDatabaseName() !== 'sca_domain_test') { $this->fail(...); }` in `setUp()`, so the full suite could previously only run on that one shared name. The focused phase already uses a per-run unique DB; the full phase did not because of these inline guards.

**Proposed remediation (two parts, test-only + runner-only):**

1. **Runner (`scripts/run-optc-tests.sh`): remove every reference to `sca_domain_test`.** Both phases provision a per-run, uniquely-named disposable DB owned by the run and dropped on exit:
   - focused → `sca_optc_test_<rand>` (unchanged),
   - full → `sca_optcfull_test_<rand>` (new; replaces `sca_domain_test`).
   The existing `assert_disposable()` allowlist (`^sca_(domain_test|[a-z0-9]+_test[a-z0-9_]*)$`, and hard-reject `sca_krayin`) already accepts both unique names and rejects production/arbitrary targets; it runs **before** any destructive statement. An extra guard will assert the full-suite DB name is **not** literally `sca_domain_test`, so the runner can never target the shared DB again.

2. **Tests: migrate the inline guard to the existing fail-closed helper.** Replace each SCA test file's inline `sca_domain_test` check in `setUp()` with `$this->guardDisposableDb();` (already added to `tests/TestCase.php` in this candidate). The helper accepts the shared `sca_domain_test` **and** any per-run `sca_*_test` name, and **hard-rejects `sca_krayin` and any non-disposable name** — so protection is preserved, not weakened; this is the minimum change that lets the whole suite run on a per-run unique DB.
   - Scope: the ~98 SCA `tests/Feature/Sca/*` and any `tests/Unit` files that inline the guard. Mechanical, uniform, test-only; it **reduces** net lines (3-line inline → 1-line call). Non-SCA Krayin tests have no such guard and already run on any DB.
   - Verification (part of the change, not a DB run): `grep -rn "!== 'sca_domain_test'" app/tests` returns **zero**, and every migrated `setUp()` calls `guardDisposableDb()`.

**Rejected alternative (documented for the audit):** keep the full suite on `sca_domain_test` but guard it with a MySQL advisory lock + "abort if it already exists." This establishes runtime exclusivity and avoids clobbering a pre-existing DB, but it is **not a uniquely-named disposable database** as the finding requires, so it is not proposed.

**Protections explicitly NOT weakened:** `guardDisposableDb()` still fails closed on `sca_krayin`; `assert_disposable()` still rejects production/arbitrary/shared-prod names before any `docker`/`mysql` op; no destructive command runs against any pre-existing database.

---

## Finding 2 — Cleanup failure can still return success

**Accepted.** The EXIT trap warns on a failed DROP but can exit 0.

**Proposed remediation (runner-only):** make cleanup failures visible and fatal while preserving an existing test failure:
- `drop_db()` returns the real MariaDB exit status (remove the `|| echo WARN` that swallows it).
- The EXIT trap captures the incoming status first and decides the final code:
  ```sh
  cleanup() {
    local rc=$?                      # status that triggered the trap (e.g. test failure)
    local drop_failed=0
    for d in "${PROVISIONED[@]:-}"; do
      [ -n "$d" ] || continue
      if ! drop_db "$d"; then echo "FATAL: failed to drop disposable DB $d" >&2; drop_failed=1; fi
    done
    [ "$rc" -ne 0 ] && exit "$rc"     # tests already failed → preserve that status
    [ "$drop_failed" -ne 0 ] && exit 4  # tests passed but cleanup failed → fatal
    exit 0
  }
  ```
  Net effect: a DROP failure is loud (stderr `FATAL`) and fatal (exit 4) when tests passed, and never masks a prior non-zero test status.

---

## Finding 3 — Regression evidence (full suite 13 vs baseline 12)

**Accepted — will not declare "full regression PASS" while failures remain.** The deliverable is an evidence artifact, not a PASS claim.

**Proposed remediation (evidence doc, built from already-captured logs; one confirmatory re-run only AFTER safeguards are approved):**
- Publish the complete failing-test comparison: candidate 13 vs baseline (`6022b75`) 12, run in the identical harness. The sets are identical except one test — `CollectorHandleTest::h7`.
- Per-test classification of all 13 as **pre-existing environment/fragility**, not Option-C-attributable:
  - admin `AuthenticationTest`/`HelpTest` (TypeError), `CertificateDocumentClassificationTest::d9`, three real-connection concurrency suites, `TransactionalEmailHardeningTest::h8` (canonical-URL), two `AuthenticationHardeningTest` rate-limit — all driven by this minimal harness (no `APP_URL`/canonical config, array cache vs real throttle store, admin seed data, real-race timing); none touch claim/fulfillment/grant code.
  - `CollectorHandleTest::h7`: asserts a bare numeric DB id is not a substring of rendered HTML; **also fails in isolation on id `1`** (every page contains "1") and in the full run on id `220` (matches `max-width:220px` in the injected dev-preview CSS). Pass/fail is autoincrement-id luck + preview-banner CSS; the baseline merely drew a non-colliding id. Option C touches no collector-handle code.
- Stated verdict wording: *focused suite PASS (68/68); full suite shows **no Option-C-attributable failure**; residual failures are enumerated pre-existing env/fragility artifacts of the minimal harness.* No "full PASS" claim.
- Optional confirmatory step (deferred until the Finding-1/2 safeguards are independently reviewed): re-run the full suite on the new per-run unique DB and re-diff against baseline to show the same classification holds.

---

## Finding 4 — Fulfillment semantics (manual release ≠ purchase verification)

**Accepted — documentation only; manual release design preserved; no behavior change.**

**Proposed remediation (comments/copy/report, no logic change):** state explicitly, in `FulfillmentReleaseService`, `FulfillmentReleaseController`, the migration docblock, the confirm-view copy, and the governance report, that **fulfillment release records a STAFF AUTHORIZATION attestation that the item is sold and ready to ship — it is NOT an automated or independent verification of purchase or payment** (it performs no Shopify/Stripe/commerce check and is intentionally offline). The staff member is attesting; the system is not verifying the sale.

---

## Proposed test commands (to run ONLY after the revised safeguards are independently reviewed)

1. **Non-destructive validation first (no DB touched)** — add and run a `selftest` mode in `scripts/run-optc-tests.sh` that asserts: `assert_disposable` accepts the two per-run unique names and **rejects** `sca_krayin`, `sca_domain_test`-as-full-target, non-`_test`, bad identifiers, and injection; validation occurs before any `docker`/`mysql` call; the cleanup trap preserves prior status and is fatal on drop failure. Mirrors the Phase-2 runner's 17-check selftest.
   ```
   scripts/run-optc-tests.sh selftest      # no database, no container destructive op
   ```
2. **After independent review of (1):** focused pass on a per-run unique DB.
   ```
   scripts/run-optc-tests.sh focused        # sca_optc_test_<rand>, provisioned + dropped
   ```
3. **After (2):** full suite on a per-run unique DB (never `sca_domain_test`).
   ```
   scripts/run-optc-tests.sh full           # sca_optcfull_test_<rand>, provisioned + dropped
   ```
4. **Regression evidence:** repeat (3) against a clean `6022b75` baseline worktree in the identical harness; diff the failing-test sets; confirm the only delta is the pre-existing `CollectorHandleTest::h7` fragility.

All runs use the ephemeral `sca-app:krayin-2.2.6` container on `sca_internal`; production `sca_krayin` is never a target; every disposable DB is dropped on exit.

---

## Change inventory (when approved)

- `scripts/run-optc-tests.sh` — unique DB for both phases, remove `sca_domain_test`, add `selftest` mode, fatal cleanup (Findings 1, 2).
- `tests/**` SCA files with the inline guard → `$this->guardDisposableDb()` (Finding 1). Test-only.
- `FulfillmentReleaseService` / `FulfillmentReleaseController` / migration docblock / confirm view copy / governance report — semantics wording (Finding 4). No logic change.
- New gov evidence section/doc — failing-test comparison + classification (Finding 3).

No application claim/fulfillment/grant logic changes; no dependency changes; the additive migration is unchanged.

**STOP — awaiting owner + ChatGPT approval of this plan. No code changed, no tests run. On approval, implementation proceeds on `feat/sca-optc-secure-claim` in a fresh non-mounted worktree, starting with the non-destructive `selftest` for independent review of the DB-isolation safeguards before any DB-touching run.**

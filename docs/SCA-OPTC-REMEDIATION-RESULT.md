# SCA-OPTC — Audit Remediation Result (revised runner + non-destructive safety evidence)

**Status: revised source + non-destructive safety evidence available for ChatGPT audit. NO focused or full database test was executed.** Not merged / not deployed / no production migration / no restart / no integration activation. Candidate branch `feat/sca-optc-secure-claim` advanced to **`54c848e`** (on `7b41e8d`, pushed). `main 6022b75` + `sca_krayin` untouched.

Implements the ChatGPT-approved remediation of the `7b41e8d` audit. Per the boundary, this delivers the revised runner and its non-destructive self-tests first; it does not run DB tests.

---

## F1 — Database ownership by creation (runner)

`scripts/run-optc-tests.sh` (rewritten; +206/−69):
- **Never `DROP DATABASE` before `CREATE`.** `provision()` runs `CREATE DATABASE \`<name>\`` **without `IF NOT EXISTS`** and **aborts (exit 3) on a name collision** — proving the run owns the database because it created it.
- **Registers for cleanup only after a successful create** (`PROVISIONED+=` follows the `CREATE`), so the cleanup path can only ever drop a database this run created. A pre-existing/unowned database is never dropped.
- **Per-run unique databases for both phases:** focused → `sca_optc_test_<rand>`, full → `sca_optcfull_test_<rand>`. **`sca_domain_test` is never created, targeted, or dropped.**
- **Strict production/shared rejection preserved and tightened:** `assert_disposable()` refuses `sca_krayin` **and** `sca_domain_test` outright, refuses empty/non-identifier/injection strings, and requires the per-run disposable shape `^sca_[a-z0-9]+_test[a-z0-9_]*$` — before any `docker`/`mysql` call.
- **Connection target verified before migrate/tests (F1.5):** inside the container, a pre-migrate step asserts via PDO that the ACTUAL connected schema (`SELECT DATABASE()`) equals the expected per-run name, is on the expected host, and is not `sca_krayin`/`sca_domain_test`; otherwise it aborts (exit 3) before `artisan migrate`.

## F2 — Fatal cleanup (runner)

The `EXIT`/`INT`/`TERM` trap `cleanup()` captures the incoming status first (`local rc=$?`), then drops every owned database. `drop_db()` returns the real MariaDB status (the `|| echo` swallow is gone). If a drop fails it is loud (stderr `FATAL`) and **fatal** (`exit 4`) — unless tests had already failed, in which case the original non-zero status is preserved (`exit "$rc"`).

## F4 — Fulfillment semantics (documentation only, no behaviour change)

`FulfillmentReleaseService`, `FulfillmentReleaseController`, the migration docblock, and the confirm-view copy now state explicitly that release is a **staff authorization attestation** (staff asserting the item is sold and ready to ship) and **not** an automated or independent verification of purchase or payment — no Shopify/Stripe/commerce check is performed; the staff member is accountable for the attestation.

## F3 — Regression evidence

Documented in `docs/SCA-OPTC-REGRESSION-EVIDENCE.md`: the complete candidate-vs-baseline failing-test comparison (candidate 13 vs clean `6022b75` 12; sole delta `CollectorHandleTest::h7`, a pre-existing numeric-id-substring fragility that also fails in isolation on id `1`). The full suite is **not** declared PASS; the stated result is "no Option-C-attributable failure."

---

## Non-destructive safety evidence (`selftest`) — NO database or container touched

`bash scripts/run-optc-tests.sh selftest` → **26 passed, 0 failed**, exit 0. `bash -n` syntax check passes. Output:

```
[1] assert_disposable REJECTS protected / malformed targets
  PASS: rejected: 'sca_krayin'
  PASS: rejected: 'sca_domain_test'
  PASS: rejected: ''
  PASS: rejected: 'sca-bad'
  PASS: rejected: 'SCA_TEST_X'
  PASS: rejected: 'sca_optc'
  PASS: rejected: 'sca_xtest'
  PASS: rejected: 'sca_x_test; DROP DATABASE sca_krayin'
  PASS: rejected: 'sca_ _test'
  PASS: rejected: 'prod'
  PASS: rejected: 'mysql'
[2] assert_disposable ACCEPTS per-run disposable names
  PASS: accepted: 'sca_optc_test_ab12cd34'
  PASS: accepted: 'sca_optcfull_test_ab12cd34'
  PASS: accepted: 'sca_x_test'
[3] F1 source invariants (static audit)
  PASS: provision() creates the DB
  PASS: provision() CREATE has no IF NOT EXISTS
  PASS: provision() never drops
  PASS: provision() registers for cleanup AFTER create
[4] F1 run_suite verifies the connection target BEFORE migrate
  PASS: connection verify precedes migrate
  PASS: run_suite re-rejects prod/shared in-container
[5] F2 cleanup is fatal and status-preserving (static audit)
  PASS: cleanup captures incoming status first
  PASS: cleanup preserves original failing status
  PASS: cleanup exits fatal (4) on drop failure
[6] drop_db returns a real status and is guarded
  PASS: drop_db does not swallow failures
  PASS: drop_db is guarded by assert_disposable
[7] no phase/provision path targets the shared sca_domain_test
  PASS: phase/provision paths use only per-run unique databases

selftest: 26 passed, 0 failed (NO database or container was touched)
```

---

## Deferred (staged for the authorized DB-run task, not in this commit)

- Migrating the remaining ~93 SCA test files' inline `!== 'sca_domain_test'` `setUp()` guards to the fail-closed `guardDisposableDb()` helper. This is only exercised when the full suite actually runs on a per-run unique DB (not permitted yet). The 5 Option-C test files already use the helper, so the focused phase runs on a unique DB today.
- The confirmatory full-suite re-run on the remediated runner + baseline re-diff (per F3).

## Change inventory (candidate `54c848e`, 5 files, +206/−69)

`scripts/run-optc-tests.sh` (F1+F2+selftest), `FulfillmentReleaseService.php`, `FulfillmentReleaseController.php`, migration `2026_10_23_000001_*.php` docblock, `eyewear/fulfillment-release-confirm.blade.php` (F4 wording). No application claim/fulfillment/grant logic change; no dependency change; additive migration unchanged functionally.

**STOP — revised runner + non-destructive safety evidence are available for independent ChatGPT audit. No DB test run. On approval, the next task migrates the remaining inline guards and runs focused + full on per-run unique DBs with the baseline re-diff.**

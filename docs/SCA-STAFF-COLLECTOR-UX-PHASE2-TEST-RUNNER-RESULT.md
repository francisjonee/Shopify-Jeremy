# SCA UX Phase 2 — Reproducible, Fail-Closed Locking-Test Execution

**Status:** Addresses the sole remaining item from the `8656a40` re-audit ("durable test execution" —
confirm the disposable-DB concurrency tests run reproducibly and fail closed on skip). The three source
changes in `8656a40` were ACCEPTED by that review; this round adds a committed, reproducible test-runner
entry point and records execution evidence. **NOT merged, NOT deployed.** No production migration/rollback/
write, live-tree checkout, restart, backup/restore, Stripe/mail, pilot. `main 6022b75` + migrations 139/140
untouched. No production database was created, mutated, or dropped.

| | |
|---|---|
| Builds on | `8656a40af6a0eaada4928ac6bd63e3ec6a48304e` (source accepted) |
| **New candidate branch** | `fix/sca-ux-phase2-test-runner` |
| **New candidate head** | **`fbbfdebc3950ef083fb65f51862975bfd1a66355`** |
| Change vs `8656a40` | one new file: `scripts/run-sca-feature-tests.sh` (no app/source change) |

## The concern
`CollectorActivityLockingTest::k1/k2` require two real connections and must COMMIT append-only event rows,
so they run against a dedicated disposable database and `markTestSkipped()` when `SCA_LOCK_DB` is absent. A
silent skip would hide the critical concurrency coverage. There was no committed runner that provisioned
the disposable DB and failed closed on skip.

## Entry point (committed): `scripts/run-sca-feature-tests.sh`
Run from the implementation repo root: `scripts/run-sca-feature-tests.sh`. It:
1. **Provisions** a disposable database (default `sca_lock_test`; it REFUSES `sca_krayin` or the shared
   `sca_domain_test` as the disposable name), granting the app DB user (root creds read from `.env`,
   app user from `app/.env`).
2. **Migrates** it in `APP_ENV=testing` (no production prompt, no `--force`).
3. Runs `CollectorActivityLockingTest` with `SCA_LOCK_DB` set and **FAILS CLOSED** unless BOTH `k1` and
   `k2` executed and passed — any `skip` in that output, a non-zero rc, or a count other than exactly
   `2 passed` aborts with a non-zero exit.
4. Runs the full `tests/Feature/Sca` suite.
5. **Always drops** the disposable database on exit (`trap … EXIT`).
It never creates/mutates/drops `sca_domain_test` or any production database, and preserves the append-only
event model (the disposable DB is dropped whole; no event-row deletes). Behaviour is overridable via env
(`SCA_TEST_DB`, `SCA_LOCK_DB`, `DB_CONTAINER`, `APP_IMAGE`, `APP_NET`, `SCA_APP_DIR`) for CI.

## Evidence (executed on this host; auditor to independently re-run — NOT independently verified here)
- **Fail-closed verified:** running `CollectorActivityLockingTest` WITHOUT `SCA_LOCK_DB` →
  `Tests: 2 skipped` (k1, k2 each: "SCA_LOCK_DB not set — dedicated disposable database … not
  provisioned"). The runner's skip-grep turns exactly this into a hard failure.
- **Via the runner (`scripts/run-sca-feature-tests.sh`, exit 0):**
  - provisioned + `migrated` the disposable `sca_lock_test`;
  - locking phase: `✓ k1 …`, `✓ k2 …`, `Tests: 2 passed (12 assertions)` → "locking tests EXECUTED and
    passed (k1 + k2)";
  - full suite: `Tests: 1 skipped, 1442 passed (7620 assertions)` (the single skip is the pre-existing
    unrelated test; `k1`/`k2` also ran and passed inside the full suite);
  - disposable DB dropped on exit (`SHOW DATABASES LIKE 'sca_lock_test'` → 0 afterward).

## Notes
- The 1 skipped in the full suite is a long-standing unrelated skip (unchanged across rounds); the activity
  locking tests are NOT skipped when run via the runner.
- For CI, point the runner at the same container/image/network (defaults match this host) or override via
  env; it is self-contained and idempotent (drops + recreates the disposable DB each run).

## Disposition
**Candidate `fbbfdeb` is NOT merged / NOT deployed.** All Phase 2 unread-semantics findings are addressed
(id watermark, backfill, uniform account-lock invariant, accounts-first transfer lock) and the concurrency
coverage is now reproducibly executed and fail-closed on skip. Production release remains **NO-GO** (Phase 2
release-readiness, the 139/140 production-migration incident, and off-host DR remain separate open gates).

**STOP — awaiting ChatGPT independent review of `fbbfdeb` (test-runner + evidence) and the final release
gates.**

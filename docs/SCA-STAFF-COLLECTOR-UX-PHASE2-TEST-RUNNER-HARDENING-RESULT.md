# SCA UX Phase 2 — Test-Runner Hardening: Validated DB Targets + Visible Cleanup Failures

**Status:** Remediation of the `fbbfdeb` re-audit (CHANGES REQUIRED on the runner's database-target
safeguards). Developed + validated in an **isolated worktree + ephemeral container**. **NOT merged, NOT
deployed.** No production migration/rollback/write, live-tree checkout, restart, backup/restore, Stripe/mail,
pilot. `main 6022b75` + migrations 139/140 untouched. No production database was created, mutated, dropped,
or used as a test target.

| | |
|---|---|
| Re-audited candidate | `fbbfdebc3950ef083fb65f51862975bfd1a66355` |
| **New candidate branch** | `fix/sca-ux-phase2-test-runner-2` |
| **New candidate head** | **`0ba09faf9af1c6c56998b991912eeab40d9a10de`** |
| Change vs `fbbfdeb` | 1 file: `scripts/run-sca-feature-tests.sh` (+159/−49) |

## Findings (accepted) and remediation
### Finding 1 — full-suite target could be overridden to production
`SCA_TEST_DB` was env-overridable with no prohibition on `sca_krayin`, and `SCA_LOCK_DB` accepted arbitrary
names beyond the two it checked.

**Fix — `validate_targets()` runs BEFORE any docker/mysql command and aborts (exit 2, nothing touched)
unless both targets are safe:**
- **`SCA_TEST_DB`** must be a valid `^[A-Za-z0-9_]+$` identifier, must end in `_test`, and must **not** be
  the production database `sca_krayin` (rejected regardless of any environment override).
- **`SCA_LOCK_DB`** (the database this runner DROPs + CREATEs) must match the explicit disposable allowlist
  **`^sca_lock_test(_[A-Za-z0-9]+)?$`** — never production, never the shared `sca_domain_test`, never an
  arbitrary name — and must differ from `SCA_TEST_DB`.
- The strict identifier/allowlist patterns also close SQL-identifier injection (the names are interpolated
  into `CREATE/DROP DATABASE`).
- The drop-on-exit cleanup trap is armed **only after** validation passes, so an invalid configuration never
  triggers a drop/create/migrate/test.

### Finding 2 — cleanup failure could be hidden
The EXIT handler dropped the disposable DB with `|| true`, so a failed drop was silent and did not fail the
run.

**Fix — `resolve_cleanup()`** attempts the drop and, on failure, prints a visible `FAIL:` message to stderr
and resolves the process exit to non-zero **while preserving any original failure status** (original rc 0 →
1 on cleanup failure; a pre-existing non-zero rc, e.g. 2, is kept). The EXIT trap exits with that resolved
status.

## Negative safety tests (new `selftest` subcommand — no database touched)
`scripts/run-sca-feature-tests.sh selftest` runs 17 self-contained checks and exits non-zero on any
failure. It proves:
- **Accepted:** `sca_domain_test` / `sca_lock_test`, and a suffixed disposable `sca_lock_test_ci`.
- **Rejected:** `SCA_TEST_DB=sca_krayin` (production), `SCA_TEST_DB` not `*_test`, `SCA_TEST_DB` bad
  identifier; `SCA_LOCK_DB` = `sca_krayin` / `sca_domain_test` (shared) / an arbitrary name / an injection
  attempt (`sca_lock_test`+backtick/`;drop`) / equal to `SCA_TEST_DB`.
- **Rejection occurs BEFORE any destructive command:** re-invoking the runner with an unsafe target and a
  recording `docker` shim first on `PATH` → the runner exits 2 and the shim is **never invoked** (empty
  sentinel), for an unsafe `SCA_TEST_DB` and an unsafe `SCA_LOCK_DB`.
- **Cleanup failure handling:** with a failing drop, `resolve_cleanup 0` → `1` + visible `FAIL:` message;
  `resolve_cleanup 2` → `2` (original status preserved); with a succeeding drop, `resolve_cleanup 0` → `0`.

## Evidence (executed on this host; auditor to independently re-run)
- `scripts/run-sca-feature-tests.sh selftest` → `SELFTEST: 17 passed, 0 failed` / `RUN-SCA-FEATURE-TESTS
  SELFTEST PASS`, exit 0 (no database touched).
- Hardened end-to-end `scripts/run-sca-feature-tests.sh run` (default safe targets): provisioned + `migrated`
  the disposable `sca_lock_test`; locking phase `Tests: 2 passed (12 assertions)` with `✓ k1` and `✓ k2`
  ("locking tests EXECUTED and passed"); full `tests/Feature/Sca` `1 skipped, 1442 passed (7620 assertions)`;
  final line "OK — … disposable database dropped on exit"; runner exited 0; post-run
  `SHOW DATABASES LIKE 'sca_lock_test'` → 0 (dropped). `sca_domain_test` and production never created/
  mutated/dropped.

## Diff review
`git diff fbbfdeb` = exactly `scripts/run-sca-feature-tests.sh`. No app/source change, no secrets, no
production config. Seeded `.env`/`app.env`/`vendor`/`storage` are git-ignored and not committed.

## Disposition
**Candidate `0ba09fa` is NOT merged / NOT deployed.** The runner now validates both database targets before
any destructive operation (rejecting production and non-allowlisted names), surfaces cleanup failures as
non-zero exits preserving the original status, and proves all of this with negative safety tests. Production
release remains **NO-GO** (Phase 2 release-readiness, the 139/140 production-migration incident, and off-host
DR remain separate open gates).

**STOP — awaiting ChatGPT independent review of `0ba09fa`.**

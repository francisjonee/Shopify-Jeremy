# SCA UX Phase 2 — Unread-Lock Re-Audit: Evidence Strengthened + Accounts-First Transfer Lock

**Status:** Response to the re-audit of `7344d75` (CHANGES REQUESTED; Finding 1 accepted). Addresses the
three Finding-2 evidence/clarity items. Developed + tested in an **isolated worktree + ephemeral container**
against verified disposable `sca_domain_test` (plus a dedicated disposable `sca_lock_test` for the
concurrency test). **NOT merged, NOT deployed.** No production migration/rollback/write, live-tree checkout,
restart, backup/restore, Stripe/mail, pilot. `main 6022b75` and migrations 139/140 untouched.

| | |
|---|---|
| Re-audited candidate | `7344d7507559cbffcaa687a9e11150df230a5adb` |
| **New candidate branch** | `fix/sca-ux-phase2-unread-locking-2` |
| **New candidate head** | **`8656a40af6a0eaada4928ac6bd63e3ec6a48304e`** |
| Change vs `7344d75` | 3 files: `CollectorActivityService` docblock, `TransferService::accept` lock order, rewritten `CollectorActivityLockingTest` |

## Item 1 — stale comment reconciled
The `CollectorActivityService` CONCURRENCY docblock no longer says the out-of-order-commit limitation is
"KNOWN OPEN" or that writers "do NOT uniformly serialize." It now states the implemented invariant: every
feed-eligible writer holds the collector's `sca_collector_accounts` row lock before inserting and until
commit; `markSeen` takes the same lock before snapshotting `MAX(id)`; mark-seen is therefore serialized
behind every in-flight eligible writer and cannot advance past an uncommitted event; account locks precede
any item/submission/request lock (global order accounts(asc) → other rows) so no deadlock cycle is added.

## Item 2 — concurrency test strengthened (real writer, committed events, two connections)
`tests/Feature/Sca/CollectorActivityLockingTest` is rewritten to run against a **dedicated disposable
database** (`SCA_LOCK_DB`, created/migrated/dropped by the runner — see "Test setup" below), so it can
**commit real append-only event rows** through the **actual writer service** without polluting
`sca_domain_test`. It uses **two independent connections and real transactions**; it skips cleanly if the
disposable DB is not provisioned (never touching `sca_domain_test` data). Two cases, both passing:
- **k1 — the real writer serializes on the account lock.** Connection B holds the collector's account lock;
  a real `SubmissionService::create` on the default connection (which must `lockForUpdate` that account
  first) **blocks and times out** (1 s). After B releases, the real writer succeeds and commits an eligible
  event. Proves the writer itself acquires the lock — not a mock.
- **k2 — mark-seen cannot advance past an uncommitted event; correct after commit.** A real
  `SubmissionService::create` commits event *e1*; `markSeen` records the submission watermark. Then
  connection B holds the account lock with an **uncommitted** new submission event *e2*; `markSeen` on the
  default connection **blocks (times out) and the submission watermark is asserted UNCHANGED** (not just
  `activity_last_seen_at` — the actual source watermark). B commits; `markSeen` then captures *e2*
  (watermark advances; unread 0). A subsequent real `create` (*e3*) is **unread**, and the feed `is_new`
  flag and unread count agree. Real transactions, real writer, committed events, no mocked lock.

**Test setup / limitation (as required):** the three event tables are append-only (no DELETE), so
committing real events into the shared `sca_domain_test` would pollute it and the global-count tests. The
runner therefore provisions a throwaway database: as root, `CREATE DATABASE sca_lock_test` + `GRANT` to the
app user; `php artisan migrate` into it (through migration 141 `…_add_collector_activity_source_watermarks`);
run the suite with `SCA_LOCK_DB=sca_lock_test`; then `DROP DATABASE sca_lock_test`. The test points the
default connection at the disposable DB for its duration (so the real services/models/markSeen operate
there) and uses a second connection for contention; it restores the default connection and
`innodb_lock_wait_timeout` in `tearDown`. If `SCA_LOCK_DB` is unset the test skips.

## Item 3 — TransferService::accept lock order audited and made accounts-first
`accept` previously locked the transfer-request row (`lockForUpdate`) and *then* the sender/recipient
accounts (request → accounts). It now reads the **immutable** `from_collector_id` with an unlocked peek,
locks sender+recipient accounts **ascending**, and only then locks + authoritatively re-validates the
request (`accounts(asc) → request → item`). **Lock-order audit (evidence):**
- The ONLY path that locks a `sca_transfer_requests` row is `TransferService::accept`
  (`TransferWorkflow::accept` reads state with `->value()` — no lock; `initiate` inserts a new row;
  `cancel` locks the request only, no account).
- `CollectorPrivacyService::pseudonymize` locks `account → sca_item_current_state` and **never** touches
  `sca_transfer_requests` (no implicit or explicit lock), so there is no account↔request interaction there.
- Therefore no inverse (account→request vs request→account) order exists today; reordering `accept` to
  accounts-first makes the invariant uniform and robust against future code. No deadlock cycle exists.

## Item 4 — every eligible writer rechecked; prior semantics preserved
All eligible writers still hold the feed-collector account lock before their insert (Claim claimant;
Transfer sender+recipient ascending; Correction destination; the 4 Submission event methods; Custody owner;
markSeen reader). The Finding-1 backfill (b1–b4), first-visit behaviour, CAP+1 truncation disclosure, exact
unread count, privacy, ownership-acknowledgement, and the id-watermark unread tests (a14–a19) all still
pass. The lock additions change no domain outcome (ownership/transfer/submission results, rejection
precedence) — confirmed by the full green suite.

## Validation (exact)
Ephemeral container on `sca_internal`, uid 33, `DB_DATABASE=sca_domain_test`, `SCA_LOCK_DB=sca_lock_test`;
primary target verified `php artisan db:show` → `Database … sca_domain_test`; disposable DB migrated through
`2026_10_22_000001`; `php -l` clean on all changed PHP.
- `php artisan test …/CollectorActivityLockingTest.php …/CollectorActivityWatermarkBackfillTest.php …/StaffCollectorUxPhase2Test.php`
  → **35 passed (157 assertions)** (k1 + k2 + b1–b4 + 29 Phase 2).
- `php artisan test tests/Feature/Sca` → **1442 passed / 1 skipped / 0 failed (7620 assertions)**, exit 0,
  no deadlock/regression. (`sca_lock_test` dropped after the run.)

## Diff review
`git diff 7344d75` = exactly `CollectorActivityService` (comment), `TransferService` (accept lock order),
and the rewritten locking test. No secrets, debug (`dd/dump/var_dump`), production config, or unrelated
files. Seeded `.env`/`app.env`/`vendor`/`storage` are git-ignored and not committed.

## Disposition
**Candidate `8656a40` is NOT merged / NOT deployed.** Findings 1 and 2 are addressed; the out-of-order-commit
race is closed by a proven, uniform lock invariant, now evidenced by a real two-connection,
committed-event test, with the transfer lock order made uniformly accounts-first. Production release remains
**NO-GO** (Phase 2 release-readiness, the 139/140 production-migration incident, and off-host DR remain
separate open gates).

**STOP — awaiting ChatGPT independent re-audit of `8656a40`.**

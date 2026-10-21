# SCA UX Phase 2 — Unread Concurrency Closed via Uniform Collector-Account Lock (Option B)

**Status:** Implements the approved **Option B** (uniform collector-account locking) to close the
out-of-order-commit race on the per-source id watermark, plus the Finding 1 migration-docblock cleanup.
Developed + tested in an **isolated worktree + ephemeral container** against verified disposable
`sca_domain_test`. **NOT merged, NOT deployed.** No production migration/rollback/write, live-tree
checkout, restart, backup/restore, Stripe/mail, pilot. `main 6022b75` and migrations 139/140 untouched.

| | |
|---|---|
| Builds on | `1e3f2b705f6386a7edf715c8010ae76a4cea39dd` |
| **Candidate branch** | `fix/sca-ux-phase2-unread-locking` |
| **Candidate head** | **`7344d7507559cbffcaa687a9e11150df230a5adb`** |
| Change vs `1e3f2b7` | new `CollectorAccountLock`, 4 writer services, migration docblock, new `CollectorActivityLockingTest` |

## Finding 1 cleanup — DONE
The migration `2026_10_22_000001` docblock still read "no backfill … Every historic account keeps them
NULL." It now accurately describes the one-time transition backfill (`ActivityWatermarkBackfill::
backfillVisitedAccounts`): visited accounts (`activity_last_seen_at IS NOT NULL`) initialize each
per-source watermark to `COALESCE(MAX(eligible id),0)`; never-visited accounts stay NULL. The
implementation, the four migration tests (b1–b4), and the migration behavior are consistent and confirmed
(the backfill only touches non-NULL-marker accounts; first-visit stays NULL; existing visited history is
not resurfaced as unread).

## Finding 2 — the invariant (Option B)
**Invariant established:** *every transaction that appends an event eligible for a collector's activity
feed acquires that collector's `sca_collector_accounts` row lock BEFORE inserting the event and holds it
until commit; `CollectorActivityService::markSeen` takes the SAME lock before snapshotting `MAX(id)` per
source.* Consequently mark-seen is serialized behind every in-flight eligible writer: it cannot read
`MAX(id)` (and thus cannot advance a watermark) while a writer for that collector is mid-transaction, so it
can never advance past an event that is assigned-but-not-yet-committed. The lower-id-uncommitted /
higher-id-committed interleaving is structurally impossible because two eligible writers for the same
collector cannot overlap — they serialize on the account lock.

### Every eligible writer audited (evidence)
Helper: `Sca\Provenance\Support\CollectorAccountLock::lockAscending(?int ...$ids)` — locks each given
account `FOR UPDATE` in **ascending id order**, dropping NULL/≤0 and de-duplicating. Accounts are locked
BEFORE any item/submission/state lock (the pre-existing documented collector→item order), giving one global
order: **accounts(asc) → item/submission/state**.

| Writer | Eligible event → feed collector | Lock (this candidate) |
|---|---|---|
| `ClaimService::complete` | ownership `claim` → claimant | **already** locked claimant account before item (unchanged) |
| `TransferService::accept` | `accepted` transfer_event → **sender** (`from_collector_id`); `transfer_in` ownership → **recipient** | now `lockAscending(sender, recipient)` before item (was recipient-only) |
| `OwnershipCorrectionService::correct` | `admin_correction` ownership → destination collector | now locks destination account before the item (preliminary resolve for lock-order; NOT_FOUND/STALE/INVALID_COLLECTOR precedence preserved); a correction to "no owner" locks nothing (no eligible feed collector) |
| `SubmissionService::create` / `transition` / `submitDraft` / `staffAdvanceToAwaitingItem` | `sca_submission_status_events` → submission owner | now locks the owner account before the submission row (owner derived from the immutable `collector_account_id`); `updateDraft` appends no event and is not locked |
| `CustodyAcceptanceService::accept` | custody `received` status event → submission owner | now locks the owner account before the submission row / new item |
| `CollectorActivityService::markSeen` | (reader) | locks the account before snapshotting `MAX(id)` (unchanged) |
`TransferWorkflow::accept` delegates to `TransferService::accept` (covered). The non-eligible writes
(`initiated`/`cancelled` transfer events, the NULL-collector `transfer_out` ownership row) correctly need
no feed-collector lock.

### Deadlock review
- Single-account writers (claim, correction, submission, custody) + mark-seen lock one account → trivially
  ordered.
- The only multi-account writer is `TransferService::accept` (sender + recipient), locked **ascending**, so
  a concurrent reverse transfer of the same pair acquires the two locks in the same order — no cycle.
- All writers lock accounts BEFORE items/submissions; no path locks an item/submission before its account,
  so there is no account↔item or account↔submission cycle. The item-group and submission-group resources
  are disjoint. This matches the convention ClaimService/TransferService already documented ("collector row
  locked before the item row, the same order pseudonymization uses").
- Full suite (1441 tests, heavy on these services) ran with **no deadlock, lock-timeout, or ordering
  failure**.

## Required concurrency test (two real connections, real transactions)
`tests/Feature/Sca/CollectorActivityLockingTest::k1` (NOT `DatabaseTransactions` — real cross-connection
locking). A second independent connection **W** models an eligible writer mid-transaction: it holds the
collector's account row lock exactly as every writer above does around its (as-yet uncommitted) event
insert. While W holds the lock:
- **(a)** a `SELECT … FOR UPDATE NOWAIT` on the account from the default session fails immediately
  (deterministic proof the row is exclusively locked);
- **(b)** `markSeen` (which must `lockForUpdate` the same row before reading `MAX(id)`) blocks with
  `innodb_lock_wait_timeout=1` and **throws**, and the stored watermark is asserted **unchanged** — i.e. a
  blocked mark-seen advances no watermark.
After W releases, `markSeen` proceeds normally. No mocks, no single-connection simulation. The test commits
**no** event rows (W rolls back — the append-only event tables cannot be cleaned, so the test deliberately
avoids persisting events), touches only one throwaway (deletable) collector account which it removes, and
restores `innodb_lock_wait_timeout` in `tearDown`. **Post-commit correctness** (a committed event becomes
seen; a later event is unread) remains covered by the sequential `DatabaseTransactions` tests
(a5/a14/a15/a19/b4).

*Test-environment note:* a true "both transactions commit and interleave" assertion cannot persist its
events here because the three event tables are append-only (no DELETE), so a committing test would pollute
`sca_domain_test` and the global-count tests. The chosen setup proves the exact safety property (mark-seen
is strictly serialized behind the writer's account lock) with real connections and real locks, without
that pollution; the proposed heavier alternative (a dedicated throwaway database migrated per-run) was not
needed to establish the invariant and is noted only as a fallback.

## Validation (exact)
Ephemeral container on `sca_internal`, uid 33, `DB_DATABASE=sca_domain_test`; target verified via
`php artisan db:show` → `Database … sca_domain_test`; `php -l` clean on all changed PHP.
- `php artisan test …/CollectorActivityLockingTest.php …/CollectorActivityWatermarkBackfillTest.php …/StaffCollectorUxPhase2Test.php`
  → **34 passed (149 assertions)** (k1 + b1–b4 + 29 Phase 2).
- `php artisan test tests/Feature/Sca` → **1441 passed / 1 skipped / 0 failed (7612 assertions)**, exit 0,
  no deadlock/regression.

## Regression / safety preserved
CAP+1 truncation, exact unread counts, first-visit semantics, privacy, ownership acknowledgement, the
Finding 1 backfill + b1–b4, and the id-watermark unread tests (a14–a19) all still pass. The lock additions
do not change any domain outcome (ownership/transfer/submission results, rejection precedence) — only the
lock set/ordering — confirmed by the full green suite.

## Diff review
`git diff dae6072` = `CollectorActivityService`, new `CollectorAccountLock`, migration, four writer
services, and two test files (plus the Phase 2 test from `ece24f1`). No secrets, debug (`dd/dump/var_dump`),
production config, or unrelated files. Seeded `.env`/`app.env`/`vendor`/`storage` are git-ignored and not
committed.

## Disposition
**Candidate `7344d75` is NOT merged / NOT deployed.** Findings 1 and 2 are both addressed and tested; the
out-of-order-commit race is closed by a proven lock invariant. Production release remains **NO-GO** (Phase 2
release-readiness, the 139/140 production-migration incident, and off-host DR remain separate open gates).

**STOP — awaiting ChatGPT independent re-audit of `7344d75`.**

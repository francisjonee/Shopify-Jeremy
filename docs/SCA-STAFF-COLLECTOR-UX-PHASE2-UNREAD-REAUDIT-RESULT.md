# SCA UX Phase 2 — Unread Semantics Re-Audit Remediation (Finding 1 fixed; Finding 2 proposal)

**Status:** Response to the independent re-audit of `ece24f18aaf4608d167ed606f23907360ecd7c02` (CHANGES
REQUESTED, 2 findings). **Finding 1 fixed; Finding 2 is a design proposal pending approval** (the auditor
directed: stop and propose before a broader schema change if no narrow fix closes the race). Developed +
tested in an **isolated worktree + ephemeral container** against verified disposable `sca_domain_test`.
**NOT merged, NOT deployed.** No production migration/rollback/write, live-tree checkout, restart,
backup/restore, Stripe/mail, pilot. `main 6022b75` and migrations 139/140 untouched.

| | |
|---|---|
| Re-audited candidate | `ece24f18aaf4608d167ed606f23907360ecd7c02` |
| **New candidate branch** | `fix/sca-ux-phase2-unread-semantics-2` |
| **New candidate head** | **`1e3f2b705f6386a7edf715c8010ae76a4cea39dd`** |
| Change vs `ece24f1` | 4 files: service comment, migration (+backfill call), new `ActivityWatermarkBackfill`, new backfill test |
| Change vs `dae6072` (audited correction base) | service, migration, 2 new files, Phase 2 test |

## Finding 1 — existing-account watermark initialization — FIXED
**Problem:** the new per-source id watermark columns default NULL (treated as 0). For an account with a
pre-existing non-null `activity_last_seen_at`, every eligible historical event id would be counted unread
after deployment.

**Fix:** the additive migration (`2026_10_22_000001`) now, after adding the columns, runs a one-time
backfill — `Sca\Collector\Support\ActivityWatermarkBackfill::backfillVisitedAccounts()` (a single shared
method invoked by BOTH the migration and its test, so there is no SQL drift). For **visited accounts only**
(`activity_last_seen_at IS NOT NULL`) it sets each watermark to `COALESCE(MAX(eligible id), 0)` per source,
using the **exact** collector-scoped filters of `CollectorActivityService`:
- ownership: `collector_account_id = a.id AND event_type IN ('claim','transfer_in','admin_correction')`;
- transfer: accepted `sca_transfer_events` of a request with `from_collector_id = a.id`;
- submission: `sca_submission_status_events` joined to the collector's own submissions.

**Never-visited accounts** (`activity_last_seen_at IS NULL`) are left untouched (watermarks stay NULL ⇒
first-visit semantics preserved). **Empty sources** initialize to 0 (a future event's higher id is unread).
A **subsequently recorded** event (higher id) remains unread after initialization. Idempotent (recomputes
the same MAX). This matches the auditor's specified transition ("initialize ... to the highest eligible
existing event IDs"); a visited account is treated as having seen everything up to the migration.

**Deterministic migration tests** (`CollectorActivityWatermarkBackfillTest`, all pass):
- **b1** visited + events in all three sources → each watermark == that source's MAX id; 0 unread.
- **b2** first-visit NULL marker → watermarks stay NULL; 0 unread; nothing flagged new.
- **b3** visited + only one source populated → present source = MAX id, empty sources = 0; 0 unread.
- **b4** after initialization, a subsequently recorded event is unread (count 1, feed `is_new`).

## Finding 2 — out-of-order transaction commits — NOT closed; design proposal (per audit instruction)
**Confirmed real.** InnoDB assigns the auto-increment id at INSERT, but commit order is independent. For
`MAX(id)` at mark-seen to be race-free, all writers of a collector's feed events would have to serialize
such that id-order == commit-order for that collector. **They do not.** Writer inspection:
- `ClaimService::complete` — `lockForUpdate` on the **claimant** account (claims serialize per collector). ✓
- `TransferService::accept` — `lockForUpdate` on the **recipient** account; writes the `accepted`
  `transfer_event` that feeds the **sender's** "transferred" row while locking the **recipient**, not the
  sender. ✗ for the sender's feed.
- `OwnershipCorrectionService::correct` — locks `sca_item_current_state`, not the corrected collector. ✗
- `SubmissionService::transition` / `CustodyAcceptanceService::accept` — lock the **submission** row, not
  the collector account. ✗

So `MAX(id)` can be raced by, e.g., two of a collector's submissions advanced concurrently, an
`admin_correction` concurrent with a `claim`, or the sender-feed `transfer_event` concurrent with the
sender's other events: a lower, still-uncommitted id can commit *after* a mark-seen that already advanced
`MAX(id)` past it, leaving that event under the watermark (not flagged new). No scalar/boundary watermark
compared against an INSERT-time value (id or `created_at`) can close this, because commit time is not
recorded in any column. **`a19` exercises the "recorded after, higher id, older timestamps" case (which IS
handled); it does not and cannot simulate the out-of-order-commit interleaving in a single-connection
PHPUnit test.** The service doc comment now states this as a **KNOWN OPEN limitation**, not a closed
guarantee.

**Options (each a broader change → proposed, not implemented):**
- **Option A — per-event read-state.** A new table (e.g. `(collector_id, source, event_id)` seen-set, or a
  reads-ledger); mark-seen records the shown event ids; unread = eligible events not in the set. *Fully*
  closes the race (no boundary collapse). Cost: a new table + writes proportional to newly-seen events,
  pruning strategy, and the "new event system" the original task cautioned against.
- **Option B (recommended) — uniform collector-account lock in the feed-event writers.** Add
  `lockForUpdate` on the **feed collector's** account row in each writer so id-allocation order == commit
  order per collector-source, making the existing `MAX(id)` mark-seen race-free with **no new table** (keeps
  the 3 watermark columns). Requires: `OwnershipCorrectionService` lock the corrected collector;
  `SubmissionService`/`CustodyAcceptanceService` lock the submission's collector; `TransferService::accept`
  additionally lock the **sender** (`from_collector_id`) alongside the recipient. **Risk to manage:** new
  lock acquisitions in provenance-critical transactions require a consistent lock-ordering (e.g. always
  acquire account locks in ascending id order; `accept` locks sender+recipient in a fixed order) to avoid
  deadlocks, plus a concurrency test using two real DB connections (conn1 inserts a low id and holds the
  account lock; conn2 commits a higher id; mark-seen then blocks on conn1's lock and only reads `MAX` after
  conn1 commits ⇒ the low id is included and stays unread).
- **Option C — commit-ordered sequence/outbox** (trigger or app step assigns a per-collector monotonic
  "activity sequence" at commit). Heavier; essentially an Option A variant.

**Recommendation:** Option B — minimal schema footprint, keeps the id-watermark model, and closes the race
with a bounded, reviewable writer change plus lock-ordering discipline and a real-concurrency regression
test. Fall back to Option A if the lock-ordering review surfaces unacceptable deadlock risk. **Requesting
approval of the approach before implementing** (the change touches provenance-critical write paths).

## Validation (exact)
Ephemeral container on `sca_internal`, uid 33, `DB_DATABASE=sca_domain_test`; DB target verified via
`php artisan db:show` → `Database … sca_domain_test`; `php artisan migrate` → "Nothing to migrate" (columns
already present in the disposable DB from the prior task; backfill logic exercised directly by its tests).
- `php artisan test …/CollectorActivityWatermarkBackfillTest.php …/StaffCollectorUxPhase2Test.php` →
  **33 passed (145 assertions)** (4 backfill b1–b4 + 29 Phase 2).
- `php artisan test tests/Feature/Sca` → **1440 passed / 1 skipped / 0 failed (7608 assertions)**, exit 0.
- `php -l` clean on the new/changed PHP.

## Migration safety
New candidate migration only; **139/140 files untouched**; backfill runs ONLY within the migration's `up()`
against whatever DB it is applied to. Applied here ONLY to the disposable `sca_domain_test` (already
recorded; backfill tested directly). **No** production migrate, **no** `--force`, **no** `migrate:rollback`,
**no** production write. The production-migration incident (139/140 batch 27) remains a separate open gate.

## Diff review
`git diff dae6072` = service + migration + `ActivityWatermarkBackfill` + 2 test files; no secrets, debug
(`dd/dump/var_dump`), production config, or unrelated files. Seeded `.env`/`app.env`/`vendor`/`storage` are
git-ignored and not committed.

## Disposition
**Candidate `1e3f2b7` is NOT merged / NOT deployed.** Finding 1 fixed + tested; Finding 2 awaits approval of
Option B (or A). Production release remains **NO-GO** (Phase 2 readiness + off-host DR gates stand).

**STOP — awaiting ChatGPT review of Finding 1 and a decision on the Finding 2 design proposal.**

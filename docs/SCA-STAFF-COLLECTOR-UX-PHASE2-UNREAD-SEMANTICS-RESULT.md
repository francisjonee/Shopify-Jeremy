# SCA UX Phase 2 — Unread Activity Semantics Fix (candidate result)

**Status:** Blocking unread-semantics finding on `dae6072` (gov audit `5da1b65`) remediated on a clean
candidate branch, developed + tested in an **isolated worktree + ephemeral container** against the verified
disposable `sca_domain_test`. **NOT merged, NOT deployed.** No production migration/rollback/write, no
live-tree checkout, no service/backup/Stripe/mail action.

| | |
|---|---|
| Implementation repo | `francisjonee/francisjonee-sca-platform-private` |
| Production baseline | `6022b75c021069bde332b4a10cd5806ae9065aaf` |
| Built on | `dae60728312fa1238bc733eb671540a444dcd807` (`fix/sca-ux-phase2-correction`) |
| **Candidate branch** | `fix/sca-ux-phase2-unread-semantics` |
| **Candidate head** | **`ece24f18aaf4608d167ed606f23907360ecd7c02`** |
| Change vs `dae6072` | 3 files: `CollectorActivityService.php` (+124/−25), new migration, `StaffCollectorUxPhase2Test.php` (+98) |

## 1. Git state investigated (before any work)
- `fix/sca-ux-phase2-unread-id-watermarks` (named in the task as the audit's experimental branch): points at
  **exactly `dae6072`** — it contains **no commits and no changes**; empty/not-started.
- `fix/sca-ux-phase2-source-watermarks` (a second experimental branch, head `4fe1571`, 2 commits): an
  **incomplete** per-source `MAX(id)` attempt. It (a) used unguarded `MAX(id)` watermarks (the
  commit-ordering hazard the task flags), and (b) **gutted `collect()`**, removing the CAP+1/`window_capped`
  truncation logic, and **shrank the Phase 2 test by ~49 lines**. Rejected as a base; used only as reference.
- Chosen: a **clean branch off `dae6072`**, preserving the CAP+1 truncation, exact-COUNT, ownership
  acknowledgement, read-only GET / explicit POST mark-seen, and submission-label fixes.

## 2. Problem
`CollectorActivityService` decided "new" by comparing event timestamps to `activity_last_seen_at` with
strict `>`. Two defects:
1. **Same-second miss.** `effective_at`/`created_at`/`activity_last_seen_at` are **second-resolution
   `timestamp`** columns (confirmed in the migrations). An event recorded in the same second as mark-seen
   compares *equal*, so strict `>` dropped it from both the feed `is_new` flag and the unread count.
2. **Backdated effective_at.** Ownership unread used `effective_at`, which `admin_correction` (and transfer
   recording) can set to an **older business date** than when the row was recorded. An event *recorded after*
   mark-seen with an older `effective_at` stayed wrongly "read".

## 3. Investigation (schemas + write paths)
All four sources confirmed by reading the migrations and the writer services:
- `sca_ownership_events`, `sca_transfer_events`, `sca_submission_status_events`: **`bigIncrements('id')`**
  primary key (append-only, immutable), `created_at` = `useCurrent()`/app-stamped **recording** time
  (second resolution); ownership additionally has the **backdatable** `effective_at`.
- `sca_collector_accounts`: `bigIncrements('id')`; carries the `activity_last_seen_at` marker (migration 140).
- **Write paths:** each event is INSERTed inside its **domain `DB::transaction`** — `ClaimService`,
  `TransferService` (transfer_in + accepted transfer_event), `CustodyAcceptanceService` /
  `SubmissionService` (submission status), `OwnershipCorrectionService` (admin_correction),
  `TransferWorkflow` (accepted). Single-row inserts; id assigned at INSERT, immutable.
- **Monotonic identifier:** the per-source auto-increment `id` is the only immutable, recording-ordered,
  non-backdatable signal. `created_at` is second-resolution (ties); `effective_at` is backdatable.

## 4. Chosen design — unread keyed on RECORDING IDENTITY (per-source `id` watermark)
"New / unread" for a source = rows with **`id > seen_source_id`** (strict integer compare). This is immune
to same-second ties (defect 1) and to backdated `effective_at` (defect 2: a later-recorded row always has a
higher id regardless of its effective date). The feed `is_new` flag and the unread `COUNT` use the
**identical** rule, so feed, count and badge always agree (requirement 5).

- **Migration** `2026_10_22_000001_add_collector_activity_source_watermarks` (candidate; sequenced AFTER
  140): three **nullable** columns on `sca_collector_accounts` —
  `activity_seen_{ownership,transfer,submission}_event_id`. Additive, no backfill, no new table/trigger, no
  constraint change, reversible `down()`. No new index needed: the migration-140 indexes
  (`idx_oe_collector_effective` = `(collector_account_id, effective_at, id)`, `idx_tr_from_collector` =
  `(from_collector_id, id)`) and the submission indexes already lead with the collector/owner column and
  carry `id`, so the `id > watermark` range stays indexed.
- **`markSeen`** (the only write): in a transaction, `lockForUpdate` the account row, snapshot `MAX(id)` of
  the collector's committed rows per source, and advance each stored watermark **monotonically**
  (`max(existing, newMax)`); `activity_last_seen_at` is also advanced monotonically as the "has ever
  marked-seen" **first-visit marker** + display (no longer the unread boundary). Replay-safe (a repeat
  recomputes the same `MAX` ⇒ no change) and safe under concurrent mark-seen (row lock + every column only
  moves forward).
- **First visit:** `activity_last_seen_at = NULL` ⇒ `unreadCount = 0` and `is_new = false` for all rows
  (history never appears all-new). Unchanged.
- **CAP+1 / `window_capped` truncation preserved verbatim** (the experimental branch removed it; this
  candidate keeps it). Each source still fetches a CAP+1 probe and discloses truncation only when a source
  truly exceeds CAP.

### Why it handles the required cases
- **Same-second** (req 1): id compare has no tie — a same-second later event has a higher id ⇒ unread.
- **Backdated recorded-after** (req 2): unread is by recording `id`, not `effective_at` — a newly recorded
  admin_correction with an old effective date has a higher id ⇒ shown as new (it still *sorts* by its old
  effective date in the feed, but is correctly flagged new and counted).
- **Concurrent / delayed insertion** (req 8): `markSeen` snapshots `MAX(id)` of **committed** rows; a row
  still uncommitted at mark-seen is invisible to `MAX(id)` and, once it commits, has `id >` the stored
  watermark ⇒ remains unread. It is never marked seen without having been counted. The monotonic advance
  makes it safe in the "never silently lose unread" direction.
- **Replay / concurrent mark-seen** (req 7): monotonic `GREATEST` under the row lock ⇒ idempotent.
- **Collector isolation** (req 6): every query is scoped to the authenticated collector id / owner join;
  another collector's events never enter the count or feed.

### Honest concurrency limit (documented, not hidden)
A per-source scalar id watermark cannot be advanced *past* a lower id that is still uncommitted without a
residual window: if two rows are inserted into the **same** source for the **same** collector in overlapping
transactions and commit **out of id order**, a `markSeen` that runs between the two commits would advance to
the higher committed id and the lower-id row (committing later) would fall at/under the watermark. This is
the only residual and it is bounded: (a) it requires two concurrent writers to the *same* source for the
*same* collector — which these low-frequency, user/staff-driven per-collector ledgers do not normally
produce (each event is a distinct domain action in its own short transaction); (b) it is strictly narrower
than the timestamp scheme it replaces, which missed *every* same-second and *every* backdated event. A
fully race-proof guarantee would require per-event read tracking (a new read-state table), which the task
directed against ("prefer minimal, auditable; do not introduce a new event system"). The id-watermark design
therefore reliably satisfies requirements 1–7 and 9, and requirement 8 for all single-writer-per-source and
recorded-after orderings, with this one bounded, documented residual.

## 5. Migration safety
- New candidate migration only; **139 and 140 files are untouched** (not altered/renamed/deleted).
- The migration was applied **only to the disposable `sca_domain_test`** after positively verifying the
  effective connection database (`php artisan db:show` → `Database … sca_domain_test`). **No** production
  migrate, **no** `migrate --force`, **no** `migrate:rollback`, **no** production write. `APP_ENV=testing`
  in the ephemeral container means `migrate` runs without `--force` and without a production prompt.
- The production-migration incident (139/140 in batch 27) remains a separate, unresolved owner gate; this
  work does not touch it.

## 6. Tests (added, not weakened)
`StaffCollectorUxPhase2Test` extended with 6 new tests (all existing tests retained unchanged):
- **a14** same-second event recorded after mark-seen → unread + `is_new` (timestamp `>` would miss it).
- **a15** ownership `admin_correction` recorded after mark-seen with `effective_at` 10 days in the past →
  new + counted.
- **a16** feed `is_new` count == exact `unreadCount` == badge ("3 new activity").
- **a17** another collector's events never raise this collector's count; own event does.
- **a18** replayed `markSeen` leaves the id watermark unchanged and unread stays 0.
- **a19** delayed/clock-skewed insert (higher id, but `effective_at` **and** `created_at` stamped *before*
  the watermark) → still unread (a `created_at > last_seen` rule would lose it).
- Retained: a11 exact unread, a12a/b/c CAP boundary (99/100/101), a1/a4 first-visit, a6 monotonic/replay,
  a9 privacy, plus the c*/l* acknowledgement/label tests.

## 7. Exact commands + results (ephemeral container on `sca_internal`, uid 33, `DB_DATABASE=sca_domain_test`)
- DB target verified: `php artisan db:show --database=mysql` → `Database … sca_domain_test`.
- `php artisan migrate` (testing env, no `--force`) → applied `2026_10_22_000001_add_collector_activity_source_watermarks` (164 ms) to `sca_domain_test`.
- `php artisan test tests/Feature/Sca/StaffCollectorUxPhase2Test.php` → **29 passed (129 assertions)**.
- `php artisan test tests/Feature/Sca` → **1436 passed / 1 skipped / 0 failed (7592 assertions)**, 375 s, exit 0.
- `php artisan test tests/Feature/Sca/TransactionalEmailHardeningTest.php` ×3 → **9 passed each** (24 assertions).
- `php -l` clean on the service and migration.

## 8. Previously-reported password-reset failure — investigated (not dismissed)
Root cause (consistent with the prior incident note): the forgot/reset-password routes are `throttle:6,1`;
under a dense full-suite run the per-minute budget is shared across test processes and can 429, failing
`TransactionalEmailHardeningTest` (h1/h7/h8). The `dae6072` correction added a per-test limiter reset in
`setUp` (`cache.default=array` + flush) that isolates each test from that shared budget; this candidate
**preserves** that isolation and does not touch the throttle. Evidence here: h7/h8/h9 passed inside the full
1436 run, and the file passed **9/9 on three consecutive isolated runs**. No failure reproduced on this
candidate; production throttle unchanged.

## 9. Diff review
`git diff --stat dae6072` = exactly the 3 intended files; no secrets, debug (`dd/dump/var_dump`), production
config, or unrelated files. Seeded `.env`/`app/.env`/`vendor`/`storage` are git-ignored and were not
committed. Candidate migration and source are internally consistent (service reads exactly the columns the
migration adds).

## 10. Remaining risks / unresolved
- The one bounded same-source out-of-order-commit residual in §4 (documented; would need per-event tracking
  to fully close).
- One-time transitional over-count: an **already-visited** collector (pre-migration `activity_last_seen_at`
  set, new id columns NULL⇒0) would see their existing events flagged new once, until the next `markSeen`
  (safe direction — never hides new; self-heals). No production impact (not deployed; only pilot/test
  accounts exist).
- The production-migration incident (139/140) and off-host/DR recovery remain **separate, open release
  gates** — unchanged by this work.

## 11. Disposition
**Candidate `ece24f1` is NOT merged and NOT deployed.** Production `main 6022b75` and migrations 139/140 are
untouched. Production release remains **NO-GO** (Phase 2 release-readiness + off-host DR gates stand).

**STOP — awaiting ChatGPT independent re-audit of `ece24f1`.**

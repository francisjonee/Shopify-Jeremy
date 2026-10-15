# SCA Phase 2 — `window_capped` Off-by-One Remediation (pre-merge audit `4bf0fb2`)

**Status:** Narrow remediation of the single pre-merge audit finding applied to the candidate branch.
**Awaiting ChatGPT independent re-audit. No merge, deploy, production migration/rollback, or live DB
mutation.** Scope was NOT expanded.

| | |
|---|---|
| Audit governance commit | `4bf0fb2` (CHANGES REQUESTED) |
| Candidate branch | `fix/sca-ux-phase2-correction` |
| Previous head (audited) | `7272843a0f943a31a7489c6af1ba1ddc22bcf917` |
| **New candidate head** | **`dae60728312fa1238bc733eb671540a444dcd807`** |
| Change vs previous head | 2 files, +53 / −17 (1 source + 1 test) |
| Baseline main | `6022b75` (unmoved); built atop `4086ee5` |

## 0. Execution safety (unchanged discipline)
Live `kr-app` bind-mount stayed on `main 6022b75` the whole time (live app never served candidate code).
Development used a separate git worktree at a non-mounted path; all tests ran in an ephemeral
`sca-app:krayin-2.2.6` container on `sca_internal`. **Connection target verified = `sca_domain_test`
(TARGET_DB printed) before running.** Worktree removed afterward; loopback 200.

## 1. The finding and the fix
**Finding (correct):** `CollectorActivityService::collect()` set `window_capped = count(source) >= CAP`
while each source fetched `limit(CAP)`. A source holding **exactly 100** rows therefore returned 100 and
was wrongly flagged capped, so the view falsely asserted "older history isn't listed here." 100 rows cannot
establish that older rows exist.

**Fix (narrow):** each source query now fetches a **CAP+1 probe** (`->limit(self::CAP + 1)`). `collect()`
flags `capped` only when a source returned **more than CAP** (the extra probe row exists), then retains the
**newest CAP** per source for display via `array_slice(..., 0, CAP)` (rows arrive newest-first, so the
probe row dropped is the oldest). Stable sort (`_sort` key) and bounded queries are unchanged; the merged
display window is still ≤ 3×CAP.
- Exactly CAP (100) → `window_capped = false`, no truncation disclosure, all 100 shown.
- CAP+1 (101) → `window_capped = true`, newest 100 shown, final-page disclosure.

## 2. Regression tests (99 / exactly 100 / 101)
`StaffCollectorUxPhase2Test`: the prior single `a12` (101-only) was replaced by a shared
`assertBoundary($n, $expectCapped)` driving three explicit cases, each asserting `window_capped`, the
**exact** unread count, and the **final-page** UI disclosure:
- **a12a** — 99 events → `window_capped=false`; final page does **not** disclose truncation; unread 99.
- **a12b** — exactly 100 → `window_capped=false`; final page does **not** disclose truncation; unread 100. *(the regression that the fix resolves)*
- **a12c** — 101 → `window_capped=true`; final page **discloses** truncation; unread 101.
Plus the retained `a11` (exact unread beyond the "9+" display), `a13` (mark-seen POST-only; GET writes no
watermark), and `c1–c5` (all four ownership-acknowledgement paths; non-affirmative values rejected).

## 3. Additional audit verifications (no code change needed)
- **`unreadCount()` matches the feed sources exactly.** Per source, the unread COUNT uses the identical
  filters/joins and the identical time field as the displayed feed:
  - ownership: `collector_account_id = me` AND `event_type IN (claim, transfer_in, admin_correction)`,
    compared on `effective_at` (feed orders/flags on `effective_at`);
  - accepted transfer: `sca_transfer_requests.from_collector_id = me` JOIN `sca_transfer_events`
    (`event_type='accepted'`), compared on `te.created_at` (feed uses `te.created_at`);
  - submissions: JOIN `sca_authentication_submissions.collector_account_id = me`, compared on
    `sse.created_at` (feed uses `sse.created_at`).
  The feed's `is_new` flag and `unreadCount` therefore use the same predicate (`ts > last_seen`) over the
  same fields — consistent by construction.
- **Index usage:** the unread/feed per-source queries are served by the additive indexes
  `idx_oe_collector_effective (collector_account_id, effective_at, id)` and
  `idx_tr_from_collector (from_collector_id, id)`, plus the pre-existing
  `sca_authentication_submissions.collector_account_id` and `sca_submission_status_events (submission_id, id)`.
- **Acknowledgement paths** (QR claim, grant claim, submission claim, transfer accept) unchanged and still
  secure (c1–c5 green; missing/non-affirmative `acknowledge` → rejected before any mutation; prefilled
  hidden `confirm=1` not accepted).
- **Migration filenames `2026_10_20_000001` (139) / `2026_10_21_000001` (140) preserved** — no migration
  change in this remediation.

## 4. Test evidence (ephemeral container; target verified `sca_domain_test`)
- Focused `StaffCollectorUxPhase2Test`: **23 passed (114 assertions)** — incl. a12a/a12b/a12c.
- `TransactionalEmailHardeningTest`: **9 passed** on three consecutive back-to-back runs (determinism retained).
- Full `tests/Feature/Sca`: **1430 passed / 1 skipped / 0 failed (7577 assertions)**.

## 5. Residual / unchanged
- Production DB untouched (139/140 additive, empty columns); release remains **NO-GO**; off-host backup
  owner-deferred. Reconciliation on an eventual authorized merge is self-consistent (Laravel skips the
  already-recorded 139/140; filenames preserved).
- No scope expansion; CAP=100/source retained and honestly disclosed.

**STOP — awaiting ChatGPT independent re-audit of `dae6072`. No merge, deployment, production migration,
rollback, or live DB mutation was performed. Production release remains NO-GO.**

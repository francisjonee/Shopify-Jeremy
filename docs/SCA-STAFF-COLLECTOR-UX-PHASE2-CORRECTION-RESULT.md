# SCA Staff & Collector UX Phase 2 — Correction Candidate Result

**Status:** One corrective candidate prepared on top of `4086ee5` per gov auth `20b3dcd`. **Awaiting ChatGPT
independent pre-merge audit. No merge, deploy, production migration/rollback, or production DB mutation.**
Production migrations 139/140 left untouched (not rolled back), exactly as instructed.

| | |
|---|---|
| Governance authorization | `20b3dcd3f176cb6adf0e9cd5ee9cc4a75331000e` |
| Built on (prior candidate) | `4086ee536aa35fc3d0438f6d8996af2774f475e0` |
| **Correction candidate branch** | `fix/sca-ux-phase2-correction` |
| **Correction candidate SHA** | **`7272843a0f943a31a7489c6af1ba1ddc22bcf917`** |
| Files changed vs `4086ee5` | **5** (3 source + 2 test), +138 / −25 |
| Deploy / merge | not performed / not authorized |

## 0. Execution safety — live app never served candidate code
The hard prohibition "no branch checkout in the live bind-mounted app that affects production serving code"
was honored. `/opt/sca-platform/app` is bind-mounted to the live `kr-app`, so the live tree was kept on
`main 6022b75` the entire time. Development used a **separate git worktree** at a non-mounted path, and all
tests ran in an **ephemeral `sca-app:krayin-2.2.6` container** (on `sca_internal`, reaching `kr-mariadb`)
mounting that worktree. **Connection target was verified before running** (`TARGET_DB=sca_domain_test`,
not `sca_krayin`). The worktree was removed afterward; live loopback `/admin/login` → 200 throughout.

## 1. Honest recent-activity pagination & unread count
`CollectorActivityService`, `ActivityController`, `activity/index.blade.php`:
- **Exact unread count.** `unreadCount()` now runs precise, indexed `COUNT` queries over the same
  authoritative collector-scoped sources as the feed (ownership claim/transfer_in via
  `idx_oe_collector_effective`; initiated-then-accepted transfer via `idx_tr_from_collector`; own-submission
  status) — it is the **exact** count, replacing the previous scan that broke at 100 and could silently
  undercount. NULL watermark ⇒ 0 (unchanged). The shell badge still caps only the **display** ("9+"); the
  underlying number is exact (aria-label carries it).
- **Honest truncation disclosure.** `feed()` now returns `window_capped` (true when any source returned a
  full `CAP`=100 window, i.e. older events exist beyond what was fetched). The view heading is **"Recent
  activity"**, and when the last in-range page is reached with a capped window it shows: *"This shows only
  your most recent activity — older history isn't listed here."* The bounded per-source window (CAP=100) is
  retained but now **disclosed**, so pagination never implies an exhaustive history.

## 2. Deterministic password-reset test isolation (no production throttle change)
Root cause (from the incident assessment, re-confirmed): the forgot/reset routes are `throttle:6,1`; the
production default cache store is **`file`**, so the limiter budget **persists across test processes** and
within the 1-minute window — a dense/long suite saturates it → HTTP 429 → the (non-throttle) reset tests
(`h1`/`h7`/`h8`) flake. `TransactionalEmailHardeningTest::setUp` now gives each test its **own fresh
in-memory limiter** (`config(['cache.default' => 'array'])` + `Cache::store('array')->flush()`). This:
- **does not change production route throttling** (the routes still declare `throttle:6,1`; no app/route code touched);
- keeps the throttle middleware in the request path (baseline behavior preserved); only the limiter's
  backing store is isolated per test;
- does not flush any shared file/DB cache (array store is process-local), so it is safe when the live
  deploy-gate runs these tests.
**Reproduction & repeat runs:** before the fix, the file ran 9/9 on a fresh-minute run but **failed
`h1`/`h7`/`h8` on back-to-back same-minute runs**. After the fix: **9/9 on three consecutive back-to-back
runs**, and green within the full suite.

## 3. Edge-case regression tests (confirmation, privacy, activity)
Added to `StaffCollectorUxPhase2Test` (all pass):
- **a11** — unread count is the **exact** value beyond the "9+" display cap (12 unseen → 12).
- **a12** — a source exceeding CAP sets `window_capped`, the feed's last page **discloses truncation**, and
  unread is the **exact** count beyond the 100 window (101 → 101).
- **a13** — mark-seen is **POST-only**; a GET on the seen URI is rejected (404) and **never** advances the
  watermark (the `null`-watermark invariant holds).
- **c5** — the ownership acknowledgement **rejects non-affirmative values** (`0`, empty, `false`, `no` →
  422, no ownership created) and only an affirmative value proceeds.
Existing confirmation/privacy/attribution/mark-seen tests (c1–c4, a1–a10) remain and pass unchanged; no
unrelated changes were made (confirmation errors, privacy/event scoping, mark-seen GET/POST, and migration
file identity were reviewed — migration filenames `2026_10_20_000001` / `2026_10_21_000001` are preserved
exactly, never renamed/duplicated).

## 4. Exact changed-file diff (5 files, +138 / −25 vs `4086ee5`)
```
app/packages/Sca/Collector/src/Http/Controllers/ActivityController.php      | 9  +--
app/packages/Sca/Collector/src/Resources/views/activity/index.blade.php     | 8  ++-
app/packages/Sca/Collector/src/Services/CollectorActivityService.php        | 71 +++++--
app/tests/Feature/Sca/StaffCollectorUxPhase2Test.php                        | 64 ++++++
app/tests/Feature/Sca/TransactionalEmailHardeningTest.php                   | 11 ++
```

## 5. Test outputs (ephemeral container; `-e DB_DATABASE=sca_domain_test`, verified target)
- Focused `StaffCollectorUxPhase2Test`: **21 passed (104 assertions)**.
- `TransactionalEmailHardeningTest`: **9 passed** on run 1, run 2 (back-to-back), run 3 — deterministic.
- Full `tests/Feature/Sca`: **1428 passed / 1 skipped / 0 failed (7567 assertions)** — the previously
  observed `h8`/`h1`/`h7` full-suite flake is resolved.

## 6. Residual / unchanged
- Production DB unchanged (139/140 still applied, additive, empty columns); release remains **NO-GO**;
  off-host backup still owner-deferred. Reconciliation on an eventual authorized merge is self-consistent
  (Laravel skips the already-recorded 139/140; filenames preserved).
- CAP=100/source is retained by design (bounded) and now disclosed; a future initiative could raise/remove
  the bound if a fuller history view is desired — out of scope here.

**STOP — awaiting ChatGPT independent pre-merge audit of `7272843`. No merge, deployment, production
migration, rollback, or production DB mutation was performed. Production release remains NO-GO.**

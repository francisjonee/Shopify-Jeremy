# SCA Staff & Collector UX Hardening — Phase 1 — Merge Result (code-only; NOT deployed)

**Status:** Controlled code-only merge complete on `main`. Awaiting ChatGPT independent post-merge audit. **No deployment, no production migration, no production data change, no infrastructure change, no pilot.** This task added no migration; the pre-existing QR-reason migration 139 remains Pending/undeployed, unchanged.

| | |
|---|---|
| Governance pre-merge PASS | `55544de6c480441c01ba0d0b945ea5c803c66840` |
| Approved candidate | `63177b197511c35653f70d1577c7392728652997` |
| Baseline (confirmed unmoved pre-merge) | `62c5d8b7370b5c846a4adbc3c530f9800495bab1` |
| **MERGE_SHA** | **`73b6c22ff0b8397e2d6c7c06ea9cc325d7693732`** |
| **ORIGIN_MAIN** | **`73b6c22ff0b8397e2d6c7c06ea9cc325d7693732`** |
| Candidate → merge tree | **byte-identical** (`git diff --quiet 63177b1..73b6c22` ⇒ TREE_IDENTICAL) |
| Files changed vs base | **exactly 13** (the authorized set), 348 ins / 39 del |
| Deployment | **not performed / not authorized** |
| Production migration | none in this task; pre-existing QR-reason 139 still **Pending** (unchanged) |

## Procedure
1. Reconfirmed `origin/main` = local `main` = exact approved baseline `62c5d8b` immediately before merge (did NOT move).
2. `--no-ff` merge of the approved candidate `63177b1` into `main` → merge commit `73b6c22`.
3. Proved candidate → merge content identity: `git diff --quiet 63177b1..73b6c22` ⇒ empty (byte-identical).
4. Proved the baseline→merge delta is exactly the 13 authorized files (`git diff --name-only 62c5d8b..73b6c22`):
   - app (9): `Collector/.../SubmissionController.php`, `Collector/.../views/profile.blade.php`, `Collector/.../views/submissions/show.blade.php`, `Registry/.../AuthenticationController.php`, `Registry/.../InventoryImportController.php`, `Registry/.../SubmissionController.php`, `Registry/.../StoreEyewearItemRequest.php`, `Registry/.../views/eyewear/create.blade.php`, `Registry/.../views/submissions/show.blade.php`
   - tests (4): `CollectorHandleTest.php`, `CollectorUi3Test.php`, `EyewearRegistryTest.php`, `StaffCollectorUxPhase1Test.php`
5. Pushed `main`: `62c5d8b..73b6c22`.

## Deployment state
Code-only merge: the seven UX fixes are on `main` but not live. No deploy ran; the running production container is unchanged (serving previously deployed app code `3b30a0f`). This task introduced no migration; `migrate:status` against production still shows exactly one Pending migration — the earlier merged-but-undeployed QR-reason `2026_10_20_000001` (139) — unchanged by this merge. A future deploy requires separate owner authorization.

## Production untouched (non-mutating check)
Provenance FP `d15a5cbdfb8df52ba65628b276533cfe`, loopback `/admin/login` → 200, exactly one pending migration (the reason fix). Stripe dormant, `MAIL_MAILER=log`, `SHOPIFY_SCOPES=read_orders`; no Caddy/DNS/provider/infra change.

## Test evidence (Claude-reported pre-merge, on the byte-identical candidate tree)
New `StaffCollectorUxPhase1Test` (11) + adjusted `CollectorHandleTest` / `CollectorUi3Test` / `EyewearRegistryTest`; full `tests/Feature/Sca` **1407 passed / 1 skipped / 0 failed (7459 assertions)**. (ChatGPT did not independently execute tests.)

**STOP — awaiting ChatGPT independent post-merge audit of `73b6c22`. Do not deploy, run production migrations, modify production data, change infrastructure, conduct a pilot, or start another initiative.**

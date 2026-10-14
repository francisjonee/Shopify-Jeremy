# SCA QR Reissue Reason — Merge Result (code-only; NOT deployed)

**Status:** Controlled merge complete on `main`. Awaiting ChatGPT post-merge verification. **No deployment, no production migration, no production data change, no pilot.** The additive migration is now on `main` but **Pending** (unapplied) on production.

| | |
|---|---|
| Governance pre-merge PASS | `819b7bd6eb9caaee9321f9082cbcc0cf19184c74` |
| Approved candidate | `7848b58573c9702ad2f76f45795d882929b97a1f` |
| Baseline (confirmed unmoved pre-merge) | `1c6c1e6cc0167cf1fc1d87f2a12446a219664f55` |
| **MERGE_SHA** | **`0afc68b2d6a18688e367daa66e304c96c147dbf1`** |
| **ORIGIN_MAIN** | **`0afc68b2d6a18688e367daa66e304c96c147dbf1`** |
| Candidate → merge tree | **byte-identical** (`git diff --quiet 7848b58..0afc68b` ⇒ TREE_IDENTICAL) |
| Files changed vs base | **4** (exactly the authorized set), 172 ins / 3 del |
| Deployment | **not performed / not authorized** |
| Production migration | **Pending, not applied** (prod DB at migration 138, 0 applied from this change) |

## Procedure
1. Reconfirmed `origin/main` = local `main` = exact approved baseline `1c6c1e6` immediately before merge (did NOT move).
2. `--no-ff` merge of the approved candidate `7848b58` into `main` → merge commit `0afc68b`.
3. Proved candidate → merge content identity: `git diff --quiet 7848b58..0afc68b` ⇒ empty (byte-identical).
4. Proved the exact 4-file delta vs base (`git diff --name-only 1c6c1e6..0afc68b`):
   - `app/packages/Sca/Provenance/src/Database/Migrations/2026_10_20_000001_add_reason_to_sca_qr_lifecycle_events.php`
   - `app/packages/Sca/Provenance/src/Services/QrService.php`
   - `app/packages/Sca/Registry/src/Http/Controllers/QrReissueController.php`
   - `app/tests/Feature/Sca/QrReissueTest.php`
5. Pushed `main`: `1c6c1e6..0afc68b`.

## Deployment / migration state (important)
This merge is **code-only**. No deploy was run and the production migration was **not** executed:
- `php artisan migrate:status` against production now lists `2026_10_20_000001_add_reason_to_sca_qr_lifecycle_events` as **Pending** (1 pending). Production applied count stays **138**.
- The running production container is unchanged (still serving the previously deployed app code `3b30a0f…`); the new reason-persist behavior is **not live**.
- A future deploy that runs this migration (138 → 139) and ships the new service/controller code requires **separate explicit owner authorization**, per the task.

## Production untouched (non-mutating check)
Provenance FP `d15a5cbdfb8df52ba65628b276533cfe`, canonical counts `3/3/4/4/5/2/1/1/7`, loopback `/admin/login` → 200. Stripe dormant, `MAIL_MAILER=log`, `SHOPIFY_SCOPES=read_orders`; no Caddy/DNS/provider/infra change.

## Test evidence (Claude-reported pre-merge, on the byte-identical candidate tree)
Focused `QrReissueTest` 17 pass (rr1–rr6 new); full `tests/Feature/Sca` **1386 passed / 1 skipped / 0 failed (7342 assertions)**. (ChatGPT did not independently execute tests.)

**STOP — awaiting ChatGPT post-merge verification of `0afc68b`. Do not deploy, run the production migration, modify production data, execute a pilot, or start another initiative.**

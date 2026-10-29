# SCA — QR Packing-Readiness: Code-Only Release Candidate

**Authorized production-only RC prep. DONE: branch `release/sca-qr-packing-readiness` =
`4faf84d49b4a67823aff31ba0dc926bd91110c16`, built off production `eb137bf`, containing ONLY the tested
QR packing-readiness message correction.** The RC tree is byte-identical to the tested candidate
`a0bd8db` (regression 83/83). Display-only: the sole production change is the order-assignment QR
confirmation string. No migration, model, QR-token, or certification change; R0/R0b/R0c + Option C
excluded. `php -l` clean. **NOT deployed.** No Shopify access of any kind (pure git). 2026-10-29. **STOP.**

## [1][2] Baseline + candidate
- Production/live `eb137bf`, `main`, clean, loopback 200.
- Candidate `a0bd8db` diff vs `eb137bf` = exactly two files (`OrderAssignmentController.php`,
  `ShopifyOrderItemAssignmentTest.php`); candidate parent = `eb137bf`.

## [3][4] RC built off production
- Isolated worktree at **`eb137bf`**; `git cherry-pick a0bd8db` → **RC `4faf84d`** (parent `eb137bf`),
  2 files, integrating only the tested correction.

## [5] Production-code change — only the QR confirmation message
`OrderAssignmentController` assign-confirmation: the packing line changes from the `is_production`-based
`'QR ready for packing (staging — not for print)'` to an active-QR-based
`$result['qr_available'] ? 'QR ready for packing' : 'no active QR yet — authenticate/activate before
shipping'` (plus an explanatory comment). No other production code changes.

## [6][7] No migrations / model / QR / cert / R0c
- Changed files: the controller + its test only — **no** migration, model, `QrService`, certification,
  or `Token` change (grep clean).
- Diff scan for `presale`/`claimByPresaleGrant`/`BUYER_VERIFICATION`/`email_verified`/`order_email`/
  `fulfillment_released`/Option-C → **none**. R0/R0b/R0c + Option C excluded (RC is prod-based, not from
  `origin/main` `a397a7e`).

## [8] Byte-identical to the tested candidate
`git diff a0bd8db 4faf84d` is **empty** → the RC tree is exactly what passed the isolated regression
(83 tests / 523 assertions / 0 failures; active QR incl. `is_production=false` ⇒ ready; revoked/absent ⇒
never ready; no token exposed; no provenance created).

## [9] Non-destructive syntax checks
`php -l` clean on `OrderAssignmentController.php`.

## [10] Branch
`release/sca-qr-packing-readiness` → **`4faf84d49b4a67823aff31ba0dc926bd91110c16`** (parent `eb137bf`),
pushed to origin. `origin/main` (`a397a7e`) untouched; live checkout untouched (`eb137bf`, clean, 200);
RC worktree removed.

## [11] Deployment procedure + rollback (for the eventual, separately-authorized deploy)
**Deploy (code-only; NO migration; NO Docker recreate):**
1. (Optional) confirm the latest `sca_krayin` backup checksum — this change makes no DB write, so a
   pre-deploy snapshot is a convenience, not a dependency.
2. **No migration step** — `migrate:status` must show **0 pending** (this RC adds none); if anything is
   pending, STOP.
3. Fast-forward the live checkout to `4faf84d` (`git merge --ff-only`), preserving `app/.env` + `vendor/`.
4. `php artisan view:clear` (harmless; no Blade changed) + `apachectl -k graceful` (opcache
   `validate_timestamps=On` picks up the controller change). No Docker recreate.
5. Smoke (safe/local only): `/admin/login → 200`; `/admin/sca/shopify/order-assign → 302` unauth (not
   500). No Shopify API probe, no test assignment.

**Rollback (code-only):** fast-forward/checkout the live tree back to `eb137bf` + `view:clear` +
`apachectl graceful`. **No DB rollback** — the change is display-only and touches no schema or data.

## Safety (this task)
Pure git/release preparation. ZERO Shopify API requests / store / CLI / credential access / product /
order / inventory / webhook changes. No deployment, production merge, DB change/migration, container
restart, live order assignment, QR generation, claim, ownership change, or email setup. R0/R0b/R0c not
deployed.

**STOP — RC `4faf84d` prepared and pushed (prod-based, byte-identical to the tested `a0bd8db`; display-
only; no migration; R0/R0b/R0c + Option C excluded). NOT deployed. NEXT (separate authorization):
independent review → controlled production deployment per [11] (code-only, no migration). SEPARATE OPEN:
Phase-1 first genuine `products/*` webhook receipt verification.**

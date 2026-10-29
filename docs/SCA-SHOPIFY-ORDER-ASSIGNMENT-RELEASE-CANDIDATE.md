# SCA — Shopify Order Assignment: Controlled Release Candidate

**Authorized release-candidate preparation. DONE: a dedicated prod-based RC containing ONLY the three
approved changes.** Branch `release/sca-shopify-order-assignment` = **`eb137bf905758e7bfa2a9b13a2ce68384340c54f`**,
built off production `5bed316`, integrating assignment `5b29338` + Administrator permission fix
`e2470a6` + reconciliation rc21 test correction `d6e4b96`. **NOT deployed.** The RC tree is byte-identical
to the previously-tested combined integration tree. R0/R0b/R0c and Option C are fully excluded. No
Shopify access of any kind occurred (pure git). No production DB/deploy/migration. 2026-10-29. **STOP for
independent review.**

## [1][2] Baseline + approved commits verified
- Production/live `5bed316`, `main`, clean, loopback `/admin/login → 200`.
- Assignment `5b29338e75d8bd57d3a712526fca7938f0a25377`; perm-fix
  `e2470a64fae543b4ec111d7b833b6c8a55d7c6f0`; rc21-fix `d6e4b96324fe2d6063004f6704c012e8d988c51d`.

## [3][4] RC built off production
- Isolated worktree at **`5bed316`**; `--no-ff` merged the three approved branches (disjoint files, no
  conflicts) → **RC `eb137bf`** on branch `release/sca-shopify-order-assignment` (pushed to origin). The
  RC descends from production, NOT from `origin/main` (`a397a7e`), so the undeployed R0/R0b/R0c claiming
  code on main is excluded by construction.

## [5] RC diff vs `5bed316` — the three approved changes + exactly one additive migration
```
M app/packages/Sca/Shopify/src/Config/acl.php                     (+2 ACLs: order-assign, order-assign.override)
M app/packages/Sca/Shopify/src/Config/menu.php                    (+1 menu entry)
M app/packages/Sca/Shopify/src/Http/Controllers/OperationsController.php   (perm fix: bouncer())
M app/packages/Sca/Shopify/src/Routes/admin-routes.php            (+2 order-assign routes)
A app/packages/Sca/Shopify/src/Http/Controllers/OrderAssignmentController.php
A app/packages/Sca/Shopify/src/Models/OrderItemAssignment.php
A app/packages/Sca/Shopify/src/Resources/views/order-assign.blade.php
A app/packages/Sca/Shopify/src/Services/OrderItemAssignmentService.php
A app/packages/Sca/Shopify/src/Database/Migrations/2026_10_31_000001_create_sca_shopify_order_item_assignments.php   (ONLY migration)
M app/tests/Feature/Sca/ShopifyReconciliationTest.php             (rc21 correction)
A app/tests/Feature/Sca/ShopifyOperationsPermissionTest.php
A app/tests/Feature/Sca/ShopifyOrderItemAssignmentTest.php
```
12 files, 1205 insertions / 10 deletions. Exactly one additive migration.

## [6] R0/R0b/R0c + Option C excluded
Diff scan for `presale_claim`/`claimByPresaleGrant`/`BUYER_VERIFICATION`/`email_verified`/`order_email`/
`fulfillment_released`/Option-C → **none**. No R0c migrations present.

## [7] No Shopify store / OAuth / webhook / theme / app-config files
Changed-file scan for `OAuth`/`Webhook`/`shopify.php`/`oauth-routes`/`public-routes`/`theme`/`Credential`/
`AccessToken`/`ProductCatalog`/`Importer`/catalog commands → **none**. The only Shopify-package files
touched are the SCA app's own admin ACL/menu/routes and the new assignment controller/service/model/
view/migration — no store, OAuth, webhook-subscription, theme, or app-configuration change.

## [8] RC tree == previously tested integration tree
`git diff 86f1d13 eb137bf` is **empty** → the RC working tree is byte-identical to the combined
integration tree validated by the final regression (79 tests / 512 assertions / 0 failures; rc8 + rc21
green; rc21 N+1 detection proven). The RC is exactly what was tested.

## [9] Migration-before-code (required)
- The one additive migration creates `sca_shopify_order_item_assignments` (append-only audit + BEFORE
  UPDATE/DELETE triggers). It adds no column to any existing table and alters no existing schema.
- The new table is referenced ONLY by the new, route-gated `OrderAssignmentController` (its `index`
  lists recent audit rows; `assign` records them via `OrderItemAssignmentService`/`OrderItemAssignment`)
  and the migration itself — NOT by any always-on/boot/menu path. Still, because the order-assign
  screen/action query that table, the migration **must run before the new code is activated**, or the
  first visit to the order-assign route would error. **Deploy order: migrate → then activate code.**

## [10] Non-destructive syntax checks
`php -l` clean on all nine changed/new PHP files (controllers, model, service, migration, config, routes)
and both new tests + the reconciliation test.

## [11] RC branch
`release/sca-shopify-order-assignment` → **`eb137bf905758e7bfa2a9b13a2ce68384340c54f`** (parent
`5bed316`). Pushed to origin. `origin/main` (`a397a7e`) untouched; live checkout untouched (`5bed316`,
clean, 200). RC worktree removed.

## [12] Migration plan + rollback procedure (for the eventual, separately-authorized deploy)
**Deploy (code-only + 1 additive migration; NO Docker recreate):**
1. Back up `sca_krayin` (verify checksum) — pre-deploy snapshot.
2. **Migrate first** from a separate mount: apply `2026_10_31_000001_create_sca_shopify_order_item_assignments`
   to `sca_krayin` (additive; creates the audit table + triggers; batch 30).
3. Fast-forward the live checkout to `eb137bf` (`git merge --ff-only`), preserving `app/.env` + `vendor/`.
4. `php artisan view:clear` (blade added) + `apachectl graceful` (opcache `validate_timestamps=On`).
5. Smoke: `/admin/login → 200`; Administrator opens `/admin/sca/shopify/operations` (200, no 500) and
   `/admin/sca/shopify/order-assign` (200); no new ownership/QR/claim records created.

**Rollback:**
- Code: fast-forward/checkout the live tree back to `5bed316` + `view:clear` + `apachectl graceful`.
- DB: the migration is additive — rolling back the code needs NO DB rollback (the audit table simply
  goes unused). If full reversal is desired, the migration's `down()` drops the triggers + table; an
  erroneous individual binding is corrected via the existing sale-link revoke/cancel paths (the append-
  only audit is never edited).
- No email/claim/Shopify dependency — the feature is inert until staff use the new route.

## Shopify safety (this task)
Pure git/release preparation. ZERO live Shopify API requests; ZERO Shopify store modifications; no
Shopify CLI; no production Shopify credentials accessed; no production DB change; no live order
assignment. No tests were run in this task.

**STOP — RC `eb137bf` prepared and pushed (prod-based, tree-identical to the tested integration; R0/R0b/
R0c + Option C excluded; one additive migration; migrate-before-code). NOT deployed. NEXT (separate
authorization): independent review → controlled production deployment per [12]. SEPARATE OPEN: Phase-1
first genuine `products/*` webhook receipt verification.**

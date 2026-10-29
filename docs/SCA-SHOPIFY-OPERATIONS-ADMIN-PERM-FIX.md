# SCA — Shopify Operations Administrator Permission Fix

**Authorized narrow fix for the pre-existing Administrator (`permission_type=all`) permission crash in
`OperationsController` surfaced by the assignment regression (`ShopifyReconciliationTest` rc8/rc21).**
One call switched from the core `User::hasPermission()` (which `TypeError`s on an Administrator role's
null `permissions`) to the ACL middleware's `bouncer()->hasPermission()`. No reconciliation / order /
inventory / ownership logic changed; no migration. Static check PASS (`php -l` clean). Focused
regression tests added but NOT run (no disposable-DB authorization in this task). Dev branch off prod
`5bed316`; no merge/deploy. 2026-10-29. **STOP for review.**

## SHA & branch
- Branch `fix/sca-shopify-operations-admin-perm` off prod `5bed316` → head
  **`e2470a64fae543b4ec111d7b833b6c8a55d7c6f0`** (pushed to origin). Live checkout untouched
  (`5bed316`, `main`, clean; loopback 200).
- **2 files:** 1 modified (OperationsController), 1 new test. **No migration. No config/route change.**

## [2] Failing check identified
- `OperationsController::index` (line 81) computed the `canReconcile` view flag via
  `auth()->user()?->hasPermission('sca.shopify.reconcile')`. The core
  `Webkul\User\Models\User::hasPermission()` ends in `in_array($permission, $this->role->permissions)`;
  for an Administrator role (`permission_type=all`), `permissions` is `null`, so `in_array(..., null)`
  throws `TypeError` → HTTP 500 on `GET /admin/sca/shopify/operations`. (This was the ONLY occurrence
  of the `->hasPermission(` pattern across all `packages/Sca` code — verified by grep.)

## [3] Fix applied
- Changed that one call to **`(bool) bouncer()->hasPermission('sca.shopify.reconcile')`** — the same
  `all`-safe API the `sca.can` ACL middleware (`Sca\Registry\Http\Middleware\ScaAuthorize`) already
  uses to gate these routes. `bouncer()` resolves an Administrator role correctly and returns the
  precise permission for a `custom` role.

## [4][5] ACL preserved; no business-logic change
- The screen is still gated by the `sca.shopify.view` ACL (route middleware, unchanged) and the
  reconcile mutation still requires the separate `sca.shopify.reconcile` ACL (route middleware,
  unchanged). The change only affects how the view-flag boolean is computed — it does not widen or
  narrow who may access the page or run reconcile.
- No change to Shopify reconciliation, order processing, inventory sync, or any ownership/provenance
  logic. The reconcile action, `ShopifyReconciliationService`, and `SaleLinkService` are untouched.

## [6] Focused regression tests (written, NOT run)
`tests/Feature/Sca/ShopifyOperationsPermissionTest.php` (hard-guarded to `sca_domain_test`,
`DatabaseTransactions`):
- Administrator (`permission_type=all`) loads `/admin/sca/shopify/operations` → **200, not 500** (the
  regression) and can run reconcile (redirect).
- View-only staff loads the screen (200); staff without the view ACL → 403; unauthenticated →
  redirect; the reconcile mutation requires the separate reconcile ACL (view-only → 403, view+reconcile
  → redirect).
- These are DB-backed; they require a separately-authorized disposable-DB session to execute. With this
  fix, the existing `ShopifyReconciliationTest` rc8 + rc21 (which this change targets) are also expected
  to pass.

## [7] Static validation
- `php -l` clean: `OperationsController.php`, `ShopifyOperationsPermissionTest.php`.

## [9] Changed files
- MOD `app/packages/Sca/Shopify/src/Http/Controllers/OperationsController.php` (1 line: the
  `canReconcile` computation).
- NEW `app/tests/Feature/Sca/ShopifyOperationsPermissionTest.php`.

## Safety / scope
Dev branch only; prod `5bed316` + live bind-mount untouched; no migration; no Shopify change; no
reconciliation/order/inventory/ownership logic change; no customer claim/transfer; no email; no
R0/R0b/R0c; no Option-C. Independent of the assignment candidate (`5b29338`), which fixed the same bug
class in its own new controller.

**STOP — Administrator permission fix implemented (`e2470a6`). NEXT (separate auth): a disposable-DB
session to run `ShopifyOperationsPermissionTest` + confirm `ShopifyReconciliationTest` rc8/rc21 now
pass, then code-only merge review + deploy (code-only, no migration). SEPARATE OPEN: Phase-1 first
genuine `products/*` webhook receipt verification.**

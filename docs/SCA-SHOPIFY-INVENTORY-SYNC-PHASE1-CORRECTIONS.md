# SCA — Shopify Inventory Sync, Phase 1: Correctness Corrections

**Three reviewed corrections applied on `feat/sca-shopify-inventory-sync`. Non-destructive checks only (php -l + logic smokes); DB-changing tests written/extended but NOT run (await separate authorization). No production/merge/deploy/live-Shopify/OAuth-scope/webhook-registration. Order webhooks + sale-link logic unchanged. Option C + 139/140 untouched.** 2026-10-27. **STOP for independent review.**

## Updated SHA & changed files

- Branch `feat/sca-shopify-inventory-sync`: `312927d` → **`5f53bec1b30049d4272c1019831c38e8f781a45a`** (pushed `origin`). Worktree; live tree `main 6ebe968`, clean.
- **6 files changed:**

| File | Change |
|---|---|
| `…/Services/ProductCatalogService.php` | Rewritten: fail-closed freshness, trusted-snapshot variant handling, reversible `pending_delete`, new `archiveConfirmedDeletions()` |
| `…/Services/ProductReconciliationService.php` | Calls the authoritative confirm step; reports drift |
| `…/Services/WebhookAuditRecorder.php` | Recognizes new `revived`/`pending_delete` (actionable) + `indeterminate` (noop) outcomes |
| `…/Database/Migrations/2026_10_27_000001_create_sca_shopify_products.php` | `status` adds `pending_delete`; + nullable `delete_requested_at` (migration still unmerged/undeployed) |
| `…/Models/ShopifyProduct.php` | `delete_requested_at` fillable/cast |
| `app/tests/Feature/Sca/ShopifyProductCatalogSyncTest.php` | Delete test updated + 7 new targeted tests |

## Correction 1 — incomplete variant collections are never an authoritative empty list

`syncProduct` computes `trustedSnapshot = is_array($product['variants'])`. `syncVariants` archives a previously-known (removed) variant **only** when `trustedSnapshot && count($seen) > 0` — i.e. a present array that yielded at least one valid variant, on a fresh product event. A **missing / null / scalar / malformed / empty** `variants` collection upserts nothing to remove and **archives no existing variant**. "Unknown" is never interpreted as "all removed."

## Correction 2 — delayed / out-of-order `products/delete` cannot overwrite newer state

Shopify sends no deletion timestamp, so ordering a delete by time is impossible. `deleteProduct` therefore sets a **reversible** `pending_delete` (recording `delete_requested_at`) and **does not archive** the product or its variants. Recovery paths:
- A later **fresh** product event revives the row (`syncProduct` → `revived`, clears `delete_requested_at`, status back to the payload's).
- **Authoritative reconciliation** (`ProductReconciliationService::reconcile` → `ProductCatalogService::archiveConfirmedDeletions`) is the ONLY path that turns a deletion into `archived`: after a full live-store sweep, a product still in `pending_delete` **and absent** from the store is soft-archived (and its variants); one that reappeared was already revived during the sweep. Active-but-absent products are **reported as drift, not auto-archived** (a transient API gap can't destroy state).

So an old/out-of-order delete event, on its own, can never overwrite newer catalog state.

## Correction 3 — uncertain timestamps fail closed

New `tsOrNull()` (missing/empty/invalid → null) and `freshness(stored, incoming)` → `fresh | stale | indeterminate`. An existing product **or** variant row is overwritten **only** on `fresh` = a valid incoming `updated_at` that is ≥ the stored one (or nothing stored). A missing / invalid / unorderable timestamp is `indeterminate` → **no overwrite**; strictly older → `stale` → no overwrite. This replaces the previous permissive `isStale()` (which returned "not stale" — and thus allowed an overwrite — whenever a timestamp was absent).

## Tests (DB — to run under separate authorization on a disposable DB)

Updated + added in `ShopifyProductCatalogSyncTest` (hard `sca_domain_test` guard, `DatabaseTransactions`):
- `incomplete_variant_collection_does_not_archive_existing_variants` (missing / null / malformed)
- `empty_variant_array_does_not_archive_existing_variants`
- `delete_sets_reversible_pending_delete_not_immediate_archive`
- `newer_update_after_delete_revives_product`
- `reconciliation_confirms_deletion_only_when_product_absent` (absent → archived + variants; present → stays pending)
- `missing_timestamp_update_does_not_overwrite_newer`
- `invalid_timestamp_update_does_not_overwrite_newer`
- `variant_with_unorderable_timestamp_is_not_overwritten`
- (retained) duplicate prevention, idempotent update + zero-provenance assertion, stale guard, missing ids, removed-variant, variant-qty>1, webhook replay, bad signature.

## Non-destructive evidence

- `php -l` (via `kr-app`): clean on all 6 changed files.
- Logic smokes (no DB/vendor): `tsOrNull`/`freshness` fail-closed behavior (newer→fresh, older→stale, missing/invalid→indeterminate, nothing-stored→fresh) and the trusted-snapshot `is_array` rule — **11/11 checks pass**.
- DB feature tests **NOT executed** (create tables/rows; need dev vendor + database).

## Remaining activation requirements (unchanged; owner-authorized)

Run the DB tests on an isolated uniquely-created disposable DB (separate auth); add `read_products` scope + merchant OAuth re-consent; register `products/*` webhooks; deploy (code + 2 additive migrations) via minimal-deploy, then initial import, then optionally schedule reconciliation. `read_inventory`/`read_locations` only for later authoritative stock sync.

**STOP — corrections delivered (`5f53bec`), non-destructive checks pass, DB tests written but not run. Awaiting independent review and separate authorization before any database-changing test.**

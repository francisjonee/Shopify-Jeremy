# SCA — Shopify Phase 2 Slice B: Targeted Corrections (DEFECT-1 + idempotency fingerprint)

**Authorized narrow development correction on `feat/sca-shopify-phase2-linking`.** Dev branch only — NO production migration, merge, or deployment; NO live Shopify change; NO Option C. Static checks PASS (`php -l` clean on all 9 changed PHP files). New regression tests written but **NOT run** (they change the database and require separate disposable-DB authorization). 2026-10-28. **STOP for independent review.**

## Corrected SHA & changed files

- Branch `feat/sca-shopify-phase2-linking`: **`2343e04` → `a477dc4f7dbd2c07b95368c6534a35eb315e2b90`** (pushed `origin`). Live `main 905ea7d` untouched. **9 files.**

Source (6):
- `Sca/Shopify/src/Services/ShopifyProductLinkService.php` — DEFECT-1: `variantEligibility` now also requires the parent product active.
- `Sca/Shopify/src/Http/Controllers/ProductLinkController.php` — selector `linkable` requires product **and** variant active; exposes `product_status`.
- `Sca/Shopify/src/Services/EyewearShopifyIntakeService.php` — canonical fingerprint + `conflict` classification.
- `Sca/Shopify/src/Models/EyewearIntakeIdempotency.php` — `fingerprint` fillable.
- `Sca/Shopify/src/Database/Migrations/2026_10_28_000003_create_sca_eyewear_intake_idempotency.php` — add `fingerprint` char(64) nullable (migration not yet in prod; extended in place).
- `Sca/Registry/src/Http/Controllers/EyewearItemController.php` — `store()` surfaces `conflict` as a real error (no item created).

Tests (3): `ShopifyProductLinkTest.php`, `EyewearShopifyIntakeTest.php`, `ShopifyProductLinkRouteTest.php`.

## Correction 1 — DEFECT-1: product AND variant must both be active (items 1–3)

- `ShopifyProductLinkService::variantEligibility` now first confirms the parent `ShopifyProduct` exists for the shop and has `status='active'`, then the variant active + belonging to that product + shop. Used by **both** `link()` and `relink()`, so a new link or relink to a variant of an archived/draft product is rejected (`variant_not_eligible`).
- `ProductLinkController::search` computes `linkable = (variant.status==='active' && product.status==='active')` and returns `product_status`; the selector disables selection of ineligible rows (server still enforces regardless).
- **Existing links preserved (no auto-unlink):** eligibility is evaluated only when deciding a *new* link/relink. Nothing re-checks or removes an existing join row when a product is later archived. Covered by `existing_link_is_preserved_when_product_becomes_archived`.

## Correction 2 — idempotency fingerprint + explicit conflict (item 4)

- New `fingerprint` column = `hash('sha256', ...)` of a canonical structure: the allowlisted item attributes (brand, model_name, frame_serial, intake_type, year, country_of_origin, materials, original_specifications, sku; blanks normalized to null) plus the Shopify link selection (`shop|product|variant`, lowercased shop, or `none`), key-sorted → order-independent.
- On a reused key the service classifies the retry (fast path **and** the concurrent-insert 1062 path):
  - identical fingerprint → `exists` (genuine retry/double-click → returns the existing item, idempotent);
  - different fingerprint → **`conflict`** with reason `idempotency_key_reused_with_different_details`, creating/modifying nothing;
  - a legacy null fingerprint is treated as matching (stays idempotent, never a false conflict).
- `EyewearItemController::store` maps `conflict` to a form error (redirect to create, no item). A genuine retry still resolves to the existing item.

## Regression tests added (NOT run — require separate disposable-DB authorization)

- **DEFECT-1 (service):** `archived_product_with_active_variant_is_rejected_on_link_and_relink`; `existing_link_is_preserved_when_product_becomes_archived`. Existing fixtures updated to create an active parent product.
- **DEFECT-1 (intake + HTTP):** `create_with_archived_product_active_variant_rolls_back`; `catalog_search_marks_archived_product_not_linkable`; `create_with_link_rejects_archived_product_and_creates_nothing`.
- **Idempotency (service):** `identical_retry_with_same_key_returns_same_item`; `key_reuse_with_different_details_is_an_explicit_conflict`; `key_reuse_detects_attribute_only_divergence`.
- **Idempotency (HTTP):** `create_with_link_key_reuse_with_different_details_conflicts` (plus the existing identical-payload double-submit → one item).

## Static verification (non-destructive)

- `php -l` clean on all 9 changed PHP files (PHP 8.3.33). No app boot, no DB connection, no dev-vendor build. No Blade change this round.

## Outstanding tests requiring authorization

The full Slice B suite must be re-run on a **uniquely-named disposable database** (isolation-verified; prod `sca_krayin` untouched) to confirm the corrected behavior green:
- `EyewearShopifyIntakeTest`, `ShopifyProductLinkRouteTest`, `ShopifyProductLinkTest` at `a477dc4`.

## Production safety

Worktree-only; live `main 905ea7d` untouched. No `migrate` run anywhere; the `fingerprint` column exists only on the branch. No merge/deploy, no Shopify API call/product change, no Option C. The Phase-1 first-genuine-`products/*`-webhook verification remains a separate open task.

**STOP — corrections committed (`a477dc4`) on the dev branch; review + an authorized disposable-DB test run before any merge or deploy.**

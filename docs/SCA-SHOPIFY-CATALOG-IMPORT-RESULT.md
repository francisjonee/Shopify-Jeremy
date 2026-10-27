# SCA — Initial Shopify Catalog Import: RESULT

**Authorized ONE controlled initial import executed. PASS — 4565 Shopify products (5330 variants) mirrored into the SCA catalog, no duplicates, zero rejected/errors, and production eyewear/ownership data completely unchanged.** Catalog records only — no physical eyewear item, authentication, certificate, QR, or ownership/claim-link created. No webhook registration, reconciliation scheduling, code/migration, Shopify modification, or Option C change. 2026-10-27. **STOP for independent review.**

## [1] Preconditions (confirmed)

- Deployed SHA **`905ea7d`**; Shopify credential `scope=read_orders,read_products`, `has_token=1`.
- Catalog tables empty before (0 / 0); backup `sca-backup-20261027T021703Z` present (checksum MATCH, 10 artifacts); app `/admin/login` → 200, `kr-app` running.

## [2] Baseline provenance fingerprint (pre-import)

`items=3, state=3, ownership=5, certifications=4, qr_identifiers=3, external_claim_grants=1`, migration max batch 28.

## [4][5] Import run — `php artisan sca:shopify:import-catalog` (once, exit 0)

| Metric | Value |
|---|---|
| Shopify products processed | **4565** |
| Catalog products created | **4565** |
| updated / unchanged / stale | 0 / 0 / 0 |
| rejected | **0** |
| errors | none (exit 0) |
| API pages paginated | **46** |

(First-run numbers: every product new → all `created`, nothing `updated`/`unchanged`.)

## [6] Catalog represents Shopify identifiers with NO duplicates

- `sca_shopify_products`: **4565 rows = 4565 distinct `shopify_product_id`** (duplicate product ids: **0**).
- `sca_shopify_variants`: **5330 rows = 5330 distinct `shopify_variant_id`** (duplicate variant ids: **0**).
- DB UNIQUE constraints (`shop_domain,shopify_product_id` / `shop_domain,shopify_variant_id`) held; no collisions.
- Product status mirrors Shopify's own field: `active=1697, archived=2788, draft=80` (= 4565). (These are Shopify's product statuses copied into the catalog; the reversible `pending_delete` state is internal and set only by a `products/delete` webhook — not used by an import.)
- **Variant-vs-physical-pair preserved:** 173 variants carry `inventory_quantity > 1`; each is **one catalog row**, not N physical items — no passport/ownership was created for any quantity.

## [7] Existing provenance UNCHANGED (catalog-only invariant held)

Post-import fingerprint is **identical** to the baseline (diff empty): `items=3, state=3, ownership=5, certifications=4, qr_identifiers=3, external_claim_grants=1`, batch 28. **No eyewear item, certificate, ownership event, QR identifier, or private claim link was created or modified.** Migration history unchanged (no migration ran).

## [8] Application health & order access after import

- `/admin/login` (loopback) → **200**.
- `ShopifyClient::getShop()` → OK (`second-chance-eyewear-accessories.myshopify.com`).
- `ShopifyClient::getOrder("8019293831455")` → OK (`financial_status=refunded`) — **`read_orders` order access remains functional**; the order integration is unaffected.

## Summary

| Check | Result |
|---|---|
| [1] SHA 905ea7d + both scopes | PASS |
| [4][5] Import counts | **4565 processed / 4565 created / 0 rejected / 0 errors / 46 pages** |
| [6] No duplicates (rows == distinct ids) | PASS (4565/4565, 5330/5330) |
| [7] Eyewear/cert/ownership/QR/claim-link unchanged | **PASS** (fingerprint identical) |
| [8] App health + order access | PASS (admin 200, getShop/getOrder OK) |

**STOP — initial catalog import complete and verified; catalog-only (no provenance side-effects); production data unchanged. No webhook registration, reconciliation scheduling, code/migration, or Shopify modification performed. Remaining owner-gated step: register the `products/*` webhooks for incremental sync (reconciliation stays unscheduled).**

# SCA — Shopify Product Access After OAuth: Verification RESULT (READ-ONLY)

**Authorized read-only verification. PASS — the store is connected with both scopes and product reads work.** No import, no webhook registration, no product/data change, no migration; no access token or credential value revealed. 2026-10-27. **STOP.**

## [1] Stored OAuth credential — both scopes present

`sca_shopify_credentials` (non-secret columns): `shop_domain = second-chance-eyewear-accessories.myshopify.com`, **`scope = read_orders,read_products`**, `has_token = 1` (encrypted token present), `expires_at = NULL`, `updated_at = 2026-10-27 18:22:03` (newer — the re-consent replaced the prior read_orders-only token). Matches the dashboard (granted = `read_orders,read_products`).

## [2][3][4] Product listing via the existing client — works, no auth error

`ShopifyClient::isConfigured() = yes`. `ShopifyClient::listProducts(null, 5)`:
- **First-page product count: 5** (requested page size 5).
- **Pagination available: yes** (a `rel="next"` cursor was returned → more pages exist).
- **No authentication error** — returned products, not `SHOPIFY_AUTH_ERROR`. Sample first product: `id=9789314269471`, `variants=1` (shape as expected for the catalog upsert).
- Connection health (`getShop`): OK — `myshopify_domain=second-chance-eyewear-accessories.myshopify.com`, `plan=professional` — confirming the stored token authenticates against the expected store.

## [5] Existing order access still functional (read_orders)

`ShopifyClient::getOrder("8019293831455")` (an existing order id from the sale-link table): **OK** — `financial_status=refunded`, `line_items=1`. The `read_orders` capability is intact; the order integration was not disturbed by the scope upgrade. (No customer PII printed — only the order id and financial status.)

## [6] SCA catalog tables still empty

`sca_shopify_products = 0`, `sca_shopify_variants = 0`. Nothing was imported; the tables remain live-but-dormant. (No webhook is registered yet, so no incremental sync has occurred either.)

## [7] Summary

| Check | Result |
|---|---|
| [1] Stored credential has read_orders + read_products | **PASS** (scope `read_orders,read_products`, token present, updated 2026-10-27) |
| [2][3] Product listing first page / pagination | **PASS** (5 products; next-page cursor present) |
| [4] Products retrieved without auth error | **PASS** (getShop + listProducts OK; token authenticates) |
| [5] Order access still functional | **PASS** (getOrder OK, read_orders intact) |
| [6] Catalog tables still empty | **PASS** (0 / 0) |
| Secrets exposed | **None** (no token/credential/PII printed) |

**Connection-level activation is verified:** read access to products is live and paginating, orders still work, and nothing has been written. **Remaining steps (separately owner-gated, NOT done here):** register the `products/create|update|delete` webhooks, then run the initial `sca:shopify:import-catalog`; reconciliation stays unscheduled.

**STOP — read-only product-access verification PASS. No import, webhook registration, product/data change, or migration; no tokens or credentials revealed.**

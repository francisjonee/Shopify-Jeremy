# SCA — Shopify Inventory Sync, Phase 1: Implementation RESULT

**Approved Phase-1 catalog synchronization implemented on `feat/sca-shopify-inventory-sync`. Non-destructive checks only (php -l + logic smokes); DB-changing tests written but NOT run (await separate authorization). No production/merge/deploy/live-connect/webhook-registration/scope-change/OAuth-reauth; Option C and 139/140 untouched.** 2026-10-27. **STOP for independent ChatGPT review.**

## Implementation SHA & changed files

- Branch `feat/sca-shopify-inventory-sync`: `6ebe968` → **`312927ddc0a8de7c8b64415a837cf9c59931a70d`** (pushed to `origin` = github-sca-platform). Implemented in an isolated worktree; live tree stays `main 6ebe968`, clean.
- **16 files** (10 new / 5 edited / 1 new test):

| File | Δ |
|---|---|
| `…/Database/Migrations/2026_10_27_000001_create_sca_shopify_products.php` | new |
| `…/Database/Migrations/2026_10_27_000002_create_sca_shopify_variants.php` | new |
| `…/Models/ShopifyProduct.php`, `…/Models/ShopifyVariant.php` | new |
| `…/Services/ProductCatalogService.php` (sole writer) | new |
| `…/Services/ProductSyncEventProcessor.php` | new |
| `…/Services/ProductCatalogImporter.php` | new |
| `…/Services/ProductReconciliationService.php` (prepared, not activated) | new |
| `…/Console/ImportCatalogCommand.php`, `…/Console/ReconcileCatalogCommand.php` | new |
| `…/Services/ShopifyClient.php` | edit (+`getProduct`/`listProducts`) |
| `…/Support/WebhookTopics.php` | edit (+product topics, `isProductTopic`) |
| `…/Http/Controllers/WebhookController.php` | edit (route product topics) |
| `…/Services/WebhookAuditRecorder.php` | edit (catalog outcomes in summary) |
| `…/Providers/ShopifyServiceProvider.php` | edit (register 2 console cmds, console-only) |
| `app/tests/Feature/Sca/ShopifyProductCatalogSyncTest.php` | new (DB test) |

## How each approved item is satisfied

1. **Additive catalog tables, store-scoped unique ids** — `sca_shopify_products` (`UNIQUE(shop_domain, shopify_product_id)`) + `sca_shopify_variants` (`UNIQUE(shop_domain, shopify_variant_id)`, index on product). DB-enforced duplicate protection; no PII.
2. **Read-only client extension** — `ShopifyClient::getProduct($id)` and `listProducts($cursor,$limit≤250)` (Shopify REST cursor pagination; next cursor parsed from the `Link` header, only the opaque `page_info`, never a host-bearing URL). Same contract as `getOrder`: host-locked, `allow_redirects=false`, timeouts, 401/403→drop token, 429→`SHOPIFY_RATE_LIMITED`, never logs the token.
3. **Idempotent initial import** — `ProductCatalogImporter` paginates and upserts via the sole-writer service; re-run is a no-op; transport/auth error aborts (no "complete" on a half-fetched store); per-product domain error fails that product closed and continues (resumable). Triggered by `php artisan sca:shopify:import-catalog` (explicit; not scheduled; not auto-run).
4. **Authenticated product create/update/delete webhooks** — added to `WebhookTopics` allowlist; `WebhookController` routes product topics to `ProductSyncEventProcessor` **inside the existing** raw-body-HMAC → expected-shop → atomic record+process → retryable-500 boundary. The order/refund **sale-link path is unchanged** (preserved).
5. **Stale / out-of-order protection** — every product and variant stores `shopify_updated_at`; an incoming event whose `updated_at` is older than what we hold is classified `stale` and **does not overwrite** newer data; `content_hash` short-circuits unchanged rows.
6. **Archived products, removed variants, missing ids, partial failures** — `products/delete` and `status=archived` soft-archive (status flip + `archived_at`, **never a row delete**); a variant previously known but absent from an update is soft-archived; a payload missing a product/variant id is rejected/skipped fail-closed (never stored with a null/guessed key); each upsert is transactional and independent.
7. **Scheduled reconciliation PREPARED, NOT activated** — `ProductReconciliationService` + `sca:shopify:reconcile-catalog` exist and re-sync + report drift, but there is **no `Console\Kernel` schedule entry** — deploying the code starts no background work; activation is a deferred, owner-authorized step.
8. **Isolated tests** — `ShopifyProductCatalogSyncTest` (disposable `sca_domain_test` hard guard, `DatabaseTransactions`): duplicate→one row; idempotent update **+ asserts zero `sca_eyewear_items`/`sca_item_current_state`/`sca_ownership_events`/`sca_certifications` rows change**; stale guard; missing product id; missing variant id; delete soft-archive; removed-variant archive; **variant qty>1 → one catalog row + zero items**; webhook replay idempotency; bad-signature rejected writes nothing.

**Catalog-only invariant (the IMPORTANT clause):** `ProductCatalogService` and every caller write **only** the two catalog tables. No code path creates an eyewear item, passport, QR, ownership event, authentication/certification record, or claim link. `ItemService` is **not** invoked by any sync path.

## Non-destructive test evidence (this phase)

- `php -l` (via `kr-app`): **16/16 files — No syntax errors.**
- Logic smokes (no DB/vendor): `WebhookTopics` allowlist + `isProductTopic` routing → **OK**; `Link` header next-cursor parser (next / previous-only / absent / null) → **OK**.
- The DB feature tests were **NOT executed** (they create tables and rows). Running them requires the dev `vendor/` (phpunit) and a database — out of scope until authorized.

## Remaining activation requirements (owner-authorized; NOT done here)

1. **Run the DB tests** on an isolated, uniquely-created disposable database (the project runner provisions/migrates/drops it) — **separate authorization** requested before this database-changing step.
2. **OAuth scope** — add `read_products` to `SHOPIFY_SCOPES` and have the merchant **re-authorize** (the current token is `read_orders`-only; `getProduct`/`listProducts` will 403 until re-consented). *Not changed by this code; owner action.*
3. **Register product webhooks** (`products/create|update|delete`) with Shopify — deploy-time action, not done here.
4. **Deploy** the branch (code-only + 2 additive migrations) via the minimal-deploy discipline, then run the initial import command once, then enable reconciliation on a schedule (a `Console\Kernel` entry) if desired.
5. Optional later: authoritative stock-level sync would need `read_inventory`/`read_locations` (Phase 1 treats `inventory_quantity` as a non-authoritative reference).

**STOP — Phase 1 implemented (`312927d`), non-destructive checks pass, DB tests written but not run. Awaiting independent ChatGPT review and separate authorization before any database-changing test.**

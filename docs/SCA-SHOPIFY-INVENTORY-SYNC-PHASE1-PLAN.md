# SCA — Shopify Inventory Synchronization, Phase 1: Audit & Implementation Plan

**Status: PLAN ONLY (read-only audit done; no implementation code written, no DB-changing tests run). STOP for owner + ChatGPT review before any database-changing work.** 2026-10-27. Branch `feat/sca-shopify-inventory-sync` created at base `6ebe968` (no code yet; live working tree stays on `main`, untouched).

Written for: the owner and the independent (ChatGPT) reviewer.

---

## 1. Audit of what already exists (reuse, don't rebuild)

| Component | State | Reuse for Phase 1 |
|---|---|---|
| `Sca/Shopify` package | OAuth (`OAuthService`/`OAuthController`), `AccessTokenStore`, `ShopifyClient` (read-only, host-locked, fail-closed), `WebhookController` + `WebhookVerifier` + `WebhookTopics` + `WebhookAuditRecorder`, `SaleLinkEventProcessor`, `ShopifyReconciliationService` | Reuse all of it; extend narrowly |
| `ShopifyClient` | Only `getShop()` and `getOrder()` (REST, pinned `api_version`, `allow_redirects=false`, never logs token) | **Add** read-only `getProduct($id)` + `listProducts($cursor)` (REST, cursor/Link pagination) following the exact same fail-closed contract |
| Webhook boundary | `WebhookController`: raw-body HMAC → expected-shop enforce → topic allowlist → **atomic** `recorder->record()` (idempotent) + processor, domain work ONLY for a NEW receipt, infra failure → retryable 500 | Reuse verbatim; route product topics to a new processor inside the same atomic/idempotent block |
| `sca_shopify_webhook_receipts` | `idempotency_key` = `shop:topic:webhook_id` **UNIQUE** (DB-enforced replay protection), SHA-256 payload digest, no PII | Reuse as-is — product webhooks get replay protection for free |
| `WebhookTopics::SUPPORTED` | `orders/paid`, `orders/cancelled`, `refunds/create` only (default-deny) | **Add** `products/create`, `products/update`, `products/delete` |
| `ItemService::create()` (Provenance) | Canonical single-item intake: `EyewearItem` (`public_ref` via `Token::publicRef()`, `intake_type` default) + one `INTAKE/normal` projection row, in one txn; **no auth/cert/QR/ownership** | Reuse ONLY at physical-pair individuation (future/separate), **not** during catalog sync |
| `InventoryImportService` (Registry) | CSV intake: **one physical pair per row** via `ItemService::create`, insert-only, idempotent via append-only ledgers with UNIQUE keys | Mirror its idempotency discipline; it confirms sync must NOT be per-variant item creation |
| `sca_eyewear_items` | `id, public_ref(char20 UNIQUE), model_name, brand, frame_serial, year, country_of_origin, materials, original_specifications, sku, image_path, image_mime, intake_type, timestamps` — **no shopify_* columns** | Not written by catalog sync; optional future link |
| `sca_shopify_sale_links` | Already carries `shopify_product_id`, `shopify_variant_id`, `shopify_order_id`, `shopify_line_item_id` | Precedent for storing Shopify ids; sale-linking is a separate concern |

## 2. Core design decision — catalog sync, NOT item/passport creation

A Shopify **product variant is a catalog SKU with an inventory quantity** (e.g. "Model X / Black / qty 5"). An SCA `sca_eyewear_items` row is **one physical pair** and is the source of a passport. Creating one SCA item per variant would fold N physical pairs into one record and, once a passport/QR is minted, assign **one passport to multiple physical units** — explicitly forbidden (objective #6), and the IMPORTANT clause forbids auto-authenticate/certify/ownership/claim-links.

**Therefore Phase 1 is a CATALOG synchronization:** Shopify products/variants sync into **new, dedicated SCA catalog tables**, and the sync **never** creates/edits `sca_eyewear_items`, never mints a `public_ref`/passport/QR, never writes ownership/authentication/certification, and never creates claim links. Physical pairs continue to be individuated via existing CSV/manual intake (`ItemService::create`); **linking** a physical pair to a catalog variant is an OPTIONAL, additive, nullable reference deferred to a later authorized phase. This makes objective #5 ("updates/archival without destroying authentication or ownership history") true *by construction* — catalog sync cannot touch those tables.

## 3. Data model (additive migrations; DB-level duplicate protection)

Two new tables, store-scoped, no PII:

**`sca_shopify_products`**
- `id` PK; `shop_domain` (255); `shopify_product_id` (string/bigint)
- `title`, `vendor`, `product_type`, `handle`, `status` (`active|archived|draft`) — catalog attributes
- `content_hash` char(64) — SHA-256 of the normalized product payload, to make updates idempotent (skip no-op updates)
- `shopify_updated_at` (from payload), `synced_at`, `created_at`, `updated_at`
- **UNIQUE (`shop_domain`, `shopify_product_id`)** ← DB-enforced de-dup

**`sca_shopify_variants`**
- `id` PK; `shop_domain`; `shopify_product_id` (FK-by-value to above); `shopify_variant_id`
- `sku`, `title`, `option_values`, `price` (string), `inventory_quantity` (int, reference only), `shopify_status`
- `content_hash`, `shopify_updated_at`, `synced_at`, timestamps
- **UNIQUE (`shop_domain`, `shopify_variant_id`)** ← DB-enforced de-dup (one catalog row per variant)
- index (`shop_domain`, `shopify_product_id`)

(Alternative: a single `sca_shopify_catalog` table with a `kind` column; two tables chosen for clarity and because variants are queried independently. Final choice open for review.) A future, separate migration would add a **nullable** link `sca_eyewear_item_variant(eyewear_item_id UNIQUE, shopify_variant_id)` for physical-pair individuation — NOT in Phase 1.

## 4. ShopifyClient additions (read-only; same safety contract)

- `getProduct(string $productId): array` — `GET /admin/api/{v}/products/{id}.json`; same fail-closed handling as `getOrder` (id regex, `allow_redirects=false`, 401/403 → forget token, 404/429 mapped, never logs token).
- `listProducts(?string $pageInfo = null): array` — `GET /admin/api/{v}/products.json?limit=N[&page_info=…]`; returns the page + the next cursor parsed from the `Link` header (Shopify REST cursor pagination). Bounded page size; honors `429` by surfacing `SHOPIFY_RATE_LIMITED` for the caller to back off.
- No write endpoints. Needs scope `read_products` (see §8).

## 5. Webhook handling, replay protection, scheduled reconciliation

- **Topics:** add `products/create`, `products/update`, `products/delete` to `WebhookTopics::SUPPORTED`. (Shopify has no "archive" webhook — archival arrives as `products/update` with `status=archived`; hard delete as `products/delete`.)
- **Auth + replay:** unchanged and reused — HMAC over raw body (`WebhookVerifier`), expected-shop enforcement, and the `idempotency_key` UNIQUE row that makes a replayed delivery a safe no-op. Product webhooks inherit all of it.
- **New `ProductSyncEventProcessor`** (mirrors `SaleLinkEventProcessor`): parses the already-verified payload, extracts only catalog fields, and performs an idempotent upsert into the catalog tables; returns a safe per-entity outcome summary (counts/codes, no PII). Runs **only for a NEW receipt**, inside the controller's existing atomic block, so infra failure rolls back and retries. A malformed/partial payload is a safe no-op (fail-closed), never an error that loses the delivery.
- **Scheduled reconciliation (design):** a periodic job (same spirit as `ShopifyReconciliationService` for orders) does a bounded `listProducts` sweep and compares Shopify's current catalog to `sca_shopify_products/variants`, recording drift (missing/extra/stale `content_hash`) into a reconciliation-run audit row. It **re-syncs catalog rows only**; it never deletes SCA items and never acts on provenance. This catches missed/À-la-carte webhooks. (Registration of webhooks and enabling the schedule are deploy-time actions, explicitly out of scope here.)

## 6. Initial import + incremental sync + updates/archival

- **Initial import (idempotent):** paginate `listProducts` → for each product+variants, upsert by the UNIQUE keys; `content_hash` short-circuits unchanged rows. Re-running the import is a no-op (idempotent); partial failure is resumable (each upsert is independent and keyed).
- **Incremental:** `products/create|update` → upsert; `products/delete` → mark `status='archived'`/soft-flag, **never hard-delete** the catalog row (preserves audit + any future links).
- **Updates:** only mutate catalog attribute columns + `content_hash`/`synced_at`; identity keys immutable. Because no `sca_eyewear_items`/ownership/auth rows are touched, objective #5 holds by construction.
- **Missing identifiers:** a product/variant lacking a usable `shopify_*_id` is rejected fail-closed (recorded as a skipped outcome), never inserted with a null/guessed key.

## 7. Permissions & configuration changes REQUIRED (owner action)

| Item | Current | Needed for Phase 1 |
|---|---|---|
| **OAuth scope** | prod `app/.env` `SHOPIFY_SCOPES=read_orders` (read_products NOT granted; config *default* is `read_orders,read_products` but the env overrides it) | **Add `read_products`** → `SHOPIFY_SCOPES=read_orders,read_products`. **A scope change requires the merchant to RE-AUTHORIZE (re-install/OAuth re-consent)** — the existing token is read_orders-only and product reads will 403 until re-granted. |
| Stock-level sync (quantities as authoritative) | — | **Only if** later required: `read_inventory` (+ `read_locations`). Phase 1 treats `inventory_quantity` as a non-authoritative reference from the product payload, so these are **not** required now. Flagged, deferred. |
| Webhook topic registration | orders/refunds only | Register `products/create|update|delete` — **a deploy-time action, explicitly NOT done in this task** ("do not register webhooks"). |
| `SHOPIFY_SHOP_DOMAIN` / `api_version` | `second-chance-eyewear-accessories.myshopify.com` / `2026-07` | Unchanged. |
| Secrets (`client_id/secret`, `webhook_secret`) | env-only, fail-closed | Unchanged; never printed/committed. |

## 8. Isolated automated tests (to run AFTER review, on a disposable DB)

All on a per-run disposable DB (never `sca_krayin`), using the project's isolated-test discipline:
- **Duplicates:** same product/variant delivered twice → exactly one catalog row (DB UNIQUE enforced), second is a no-op.
- **Updates:** changed attributes update the catalog row + `content_hash`; unchanged payload is a no-op; and assert **no** `sca_eyewear_items`/ownership/auth row is created or modified.
- **Missing identifiers:** payload without a variant/product id → fail-closed skip, no row.
- **Archival:** `products/delete` / `status=archived` → row soft-archived, not deleted; any (future) linked item untouched.
- **Failure recovery:** infra error mid-batch rolls back and the retry completes; replayed webhook id is idempotent; malformed payload is a safe no-op.
- **Variant≠pair invariant:** a variant with `inventory_quantity>1` creates **one catalog row and zero** `sca_eyewear_items`.

These are database-changing tests → **gated on this plan's approval.**

## 9. Explicit non-goals / safety (this phase)

- No automatic authenticate/certify/ownership/claim-link from a sync (IMPORTANT clause).
- No `sca_eyewear_items`/passport/QR creation from catalog sync; variant ≠ physical pair.
- Dev branch only (`feat/sca-shopify-inventory-sync` @ `6ebe968`). **No** merge, deploy, live-Shopify connect, webhook registration, production migration, or integration activation. OAuth scopes not changed by code (owner action).
- 139/140 incident and Option C untouched.

## 10. Stop point

Implementation (migrations, `ShopifyClient` product methods, `ProductSyncEventProcessor`, catalog model/service, topic allowlist, importer, reconciliation design, tests) is **not started**. Awaiting owner + ChatGPT approval of this plan — in particular the §2 catalog-vs-item decision and the §7 `read_products` re-consent — before any database-changing test.

**STOP for owner + independent ChatGPT review.**

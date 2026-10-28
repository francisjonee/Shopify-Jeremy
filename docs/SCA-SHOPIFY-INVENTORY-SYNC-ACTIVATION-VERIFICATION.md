# SCA — Shopify Inventory Sync Activation: Verification (READ-ONLY)

**Version 6 released (owner). Connection, scopes, catalog, and read access all verified; the SCA receiver is proven. But NO genuine `products/*` webhook has been delivered yet → product-webhook delivery is PENDING (end-to-end product-sync via live webhook NOT yet confirmed).** Read-only only: no product created/modified, no re-import, no deploy/migration, no Shopify config change, no passport. 2026-10-28. **STOP.**

## [1] SCA deploy + health

Deployed SHA **`905ea7d`** (unchanged); `/admin/login → 200`; `kr-app` running.

## [2] Credential scopes

`sca_shopify_credentials`: `scope = read_orders,read_products`, `has_token = 1`, `updated_at = 2026-10-27 18:22:03`.

## [3] Six subscriptions in the active app config

Confirmed by the owner in the Dev Dashboard: **version `sca-eyewear-registry-6` active, scopes `read_orders,read_products`, six managed webhook subscriptions (3 order/refund + 3 product), API version `2026-07`, OAuth callback preserved.** Note: these are **app-managed (config-based)** subscriptions, which — as established — do **not** appear in the Admin API `webhooks.json` (it still returns 0 server-side; that is expected, not a contradiction). Server-side, the definitive proof that the three product subscriptions are live is the arrival of a genuine `products/*` delivery (see [5], currently PENDING).

## [4] Live product-listing & order-reading access — OK

Read-only live API (token used internally, never printed): `isConfigured=yes`; `getShop → OK` (`second-chance-eyewear-accessories.myshopify.com`); `listProducts(null,5) → OK` (first page 5, pagination cursor present, no auth error); `getOrder("8019293831455") → OK` (`financial_status=refunded`). Both `read_products` and `read_orders` work.

## [5] Genuine product webhook receipts — NONE yet → **WEBHOOK DELIVERY PENDING**

`sca_shopify_webhook_receipts` has **0** rows with topic `products/*`. (The earlier synthetic `sca-selftest-1` receipt was cleaned up; it is not counted.) So **no real `products/create|update|delete` has been delivered since the release.** This is expected — no product has been created/edited/deleted in the store since v6 went active, and per instruction we do **not** trigger one.

Evidence the webhook pipeline itself is healthy: order webhooks continue to deliver and record — the most recent is `orders/paid` at **2026-10-27 20:38:53** (`noop_non_sca`), among 109 total receipts. So the edge route, HMAC verification, and recorder are working for the store; product deliveries are expected on the next product change, and the SCA receiver is already proven to process them (bad-sig→401; valid→200 `processed`+upsert; replay idempotent — gov `8faa1fa`).

## [6] Processing / catalog-change / no-duplicate verification — PENDING

Not applicable yet: there are no genuine product receipts to verify. This step remains **PENDING** until the first real `products/*` delivery arrives. **End-to-end product sync via live webhook is NOT claimed as passed.**

## [7] Catalog counts & provenance consistent

`sca_shopify_products = 4565`, `sca_shopify_variants = 5330` (unchanged since the import). Provenance fingerprint unchanged: `items=3, state=3, ownership=5, certifications=4, qr_identifiers=3, external_claim_grants=1`. No eyewear/cert/ownership/QR/claim-link change.

## [8] Scheduled reconciliation — disabled

No cron entry (`/etc/cron.d`, `/etc/crontab`) references `schedule:run`, `reconcile`, or Shopify; the `ReconcileCatalogCommand` exists but is **not** registered on any schedule (no Console-Kernel schedule entry). Reconciliation remains manual-only / disabled.

## [9] Result

| Check | Result |
|---|---|
| [1] SHA 905ea7d + health | PASS |
| [2] scopes read_orders,read_products | PASS |
| [3] 6 subscriptions in active version | Confirmed by owner Dashboard (v6); managed subs not enumerable via server `webhooks.json` |
| [4] product-listing + order-reading | PASS (live, read-only) |
| [5] genuine product webhook receipts | **0 — WEBHOOK DELIVERY PENDING** |
| [6] processing/catalog/no-dup of a real delivery | **PENDING** (no real delivery yet) |
| [7] catalog + provenance consistent | PASS (4565/5330; 3/3/5/4/3/1) |
| [8] reconciliation disabled | PASS |

**Bottom line: activation is in place and the SCA side is healthy and proven, but end-to-end product-webhook sync is NOT yet confirmed — WEBHOOK DELIVERY PENDING** (no genuine `products/*` receipt since release). Next (no action needed from SCA): when a product is next created/updated/deleted in the store during normal business, confirm a new `sca_shopify_webhook_receipts` row with topic `products/*` and `processing_outcome=processed`, the corresponding catalog change, no duplicates, and provenance still unchanged.

**STOP — read-only activation verification delivered. No product created/modified, no re-import, no deploy/migration, no Shopify config change, no passport. Product-webhook delivery PENDING; end-to-end not claimed.**

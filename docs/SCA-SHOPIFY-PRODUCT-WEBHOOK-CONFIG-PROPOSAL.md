# SCA — Shopify Product Webhook Registration: Config Proposal (for owner review)

**Proposal only. No app version deployed/released, no new app created, no SCA production server or inventory changed.** 2026-10-27. **STOP for owner review before releasing the Shopify app configuration.**

Goal: add `products/create`, `products/update`, `products/delete` (all → the existing SCA webhook endpoint) to the **existing** Shopify app, preserving the three current managed subscriptions and all other settings.

## [4] Reuse the existing app — yes (do NOT create a new app)

The active version **`sca-eyewear-registry-5`** belongs to the existing app (same `client_id`, same installed token that already holds `read_orders,read_products`). Adding webhook subscriptions is a **configuration edit + a new released version on that same app** (Shopify will auto-number the next version, e.g. `sca-eyewear-registry-6`) — **not** a new app. The existing Shopify app-config project is reused:
- If the owner maintains a local Shopify CLI project (`shopify.app.toml`) linked to this app, reuse it (confirm it is linked to the existing app: `shopify app config link` → pick the existing app, do not create one).
- If the owner manages the app only in the Dev Dashboard, add the subscriptions there instead (same topics/endpoint). Either path edits the same app.

## [1][2][3] Invariants to preserve (unchanged by this edit)

- Existing subscriptions: `orders/paid`, `orders/cancelled`, `refunds/create` → keep.
- Access scopes: `read_orders,read_products` → keep (no scope change; re-consent already done).
- Webhook `api_version = 2026-07` → keep.
- OAuth callback `https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback` and the application URL → keep.
- Webhook endpoint for all topics: `https://verify.secondchanceauthenticators.com/sca/shopify/webhook` → unchanged.

## [5] Exact `shopify.app.toml` change (smallest, additive)

**Smallest change — append ONE subscription block** for the three product topics (leave the existing order/refund subscription block(s) exactly as they are, however they are currently laid out):

```toml
  [[webhooks.subscriptions]]
  topics = [ "products/create", "products/update", "products/delete" ]
  uri = "https://verify.secondchanceauthenticators.com/sca/shopify/webhook"
```

**Target state of the whole `[webhooks]` section** (for reference — the existing 3 preserved, the new 3 added, one shared endpoint, API version unchanged):

```toml
[webhooks]
api_version = "2026-07"

  [[webhooks.subscriptions]]
  topics = [ "orders/paid", "orders/cancelled", "refunds/create" ]
  uri = "https://verify.secondchanceauthenticators.com/sca/shopify/webhook"

  [[webhooks.subscriptions]]
  topics = [ "products/create", "products/update", "products/delete" ]
  uri = "https://verify.secondchanceauthenticators.com/sca/shopify/webhook"
```

(If the current file lists the three order/refund topics as three separate `[[webhooks.subscriptions]]` blocks, keep them as-is and just add the one product block above — the result is equally valid.)

**Do NOT change** these (shown so the diff is expected to touch only `[webhooks]`):
```toml
[access_scopes]
scopes = "read_orders,read_products"          # unchanged

[auth]
redirect_urls = [ "https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback" ]   # unchanged
# application_url / embedded / other keys — unchanged
```

## Deployment instructions (owner-executed; NOT run here)

From the existing app's project directory:
```bash
# 0. Ensure the project is linked to the EXISTING app (not a new one):
shopify app config link            # select the existing "sca-eyewear-registry" app if prompted
# 1. Edit shopify.app.toml: add ONLY the products [[webhooks.subscriptions]] block above.
# 2. Create a new version (shows a diff; review it):
shopify app deploy
#    -> the diff MUST show: + products/create, + products/update, + products/delete (one endpoint),
#       with access_scopes, api_version (2026-07), and redirect_urls UNCHANGED.
# 3. Release the new version (e.g. sca-eyewear-registry-6) when the diff is confirmed.
```
Dev Dashboard alternative: app → Configuration/Webhooks → add the three `products/*` subscriptions to the same endpoint, keep the three order/refund ones, Save, and release the new version.

## [6][7][8] Guardrails honored

- **No new app** — edits the existing app only (same `client_id`/install).
- **Not released** — this is a proposal; `shopify app deploy`/release is the owner's step after review.
- **No SCA server change** — nothing on the production host or in the database was modified; catalog remains `products=4565, variants=5330`. The SCA receiver is already deployed and proven (bad-sig→401; valid→200 receipt `processed` + catalog upsert; replay idempotent), so once the new version is released, Shopify product deliveries will be verified and processed.

## [9] Steps for owner approval

1. Confirm the diff from `shopify app deploy` adds exactly the three `products/*` topics on `…/sca/shopify/webhook`, with scopes, API version, and redirect URLs unchanged.
2. Approve and release the new app version (keeps all six subscriptions managed).
3. After release (follow-up, separate): send one Shopify test notification / edit a product, and confirm a new `sca_shopify_webhook_receipts` row with `processing_outcome=processed` plus the catalog update — with eyewear/ownership/certification/QR records unchanged. Reconciliation stays unscheduled.

**STOP — config proposal delivered for owner review. No app version deployed/released, no new app, no SCA server/inventory change.**

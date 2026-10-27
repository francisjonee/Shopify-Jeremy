# SCA — Shopify Product Webhook Release: BLOCKED (owner CLI action required)

**App identity verified; release NOT performed — two blockers require the owner. No app version deployed/released, no new app, no other app's credentials used; no SCA code/schema/service/inventory change; no products modified. 2026-10-27. STOP.**

## [1][2] App located & identity verified

- Shopify CLI present (`4.8.5`) and an app-config project exists at **`/opt/sca-gov/shopify-app/shopify.app.toml`** (tracked in gov).
- `name = "SCA Eyewear Registry"`; `client_id` in the toml **matches** `SHOPIFY_CLIENT_ID` of the app SCA is installed on (compared without printing the value) → **same existing app**, not another app. No new app involved.

## ⛔ BLOCKER A — no Partner authentication on this host

There is no `~/.config/shopify` auth and no Partner session; `shopify app deploy` requires an interactive Partner login, which cannot be performed non-interactively on this production VPS. Per the authorization's final clause, I **STOP and provide instructions** rather than attempt a workaround.

## ⛔ BLOCKER B — the committed `shopify.app.toml` is STALE (would strip `read_products`)

The committed file currently has:
```toml
[webhooks]
api_version = "2026-07"
  [[webhooks.subscriptions]]
  uri = "https://verify.secondchanceauthenticators.com/sca/shopify/webhook"
  topics = [ "orders/cancelled", "orders/paid", "refunds/create" ]

[access_scopes]
scopes = "read_orders"          # ⚠️ MISSING read_products
optional_scopes = [ ]

[auth]
redirect_urls = [ "https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback" ]
```
But the **live install was granted `read_orders,read_products`** (the owner's earlier Dev-Dashboard scope fix + re-consent). So this committed toml predates that fix. **Deploying it as-is would downgrade the app scopes back to `read_orders` only — removing `read_products` and breaking product access.** It must be reconciled to the live state **before** any deploy.

Requirement check: webhooks correct (3 order/refund present, none to be removed, endpoint + `api_version 2026-07` + redirect correct), but **scopes are wrong in this file** — do not deploy without fixing scopes first.

## Exact owner steps (authenticated workstation / Partner session)

```bash
# 0. Authenticate to the correct Partner organization:
shopify auth logout 2>/dev/null; shopify login        # log into the Partner org that owns "SCA Eyewear Registry"
cd <the app project dir>                                # the shopify.app.toml project for this app

# 1. Link to the EXISTING app (verify identity — do NOT create a new app):
shopify app config link                                 # choose "SCA Eyewear Registry"; confirm its client_id

# 2. PULL the current released config so the local toml matches the live app (this reconciles the
#    stale scopes — after pull, access_scopes MUST read "read_orders,read_products"):
shopify app config pull
#    -> VERIFY the pulled toml shows:  scopes = "read_orders,read_products"  and the 3 order/refund
#       webhook subscriptions. If it still shows only "read_orders", STOP — read_products is not in the
#       released config and must be added too (otherwise the re-consented grant is inconsistent).

# 3. Add EXACTLY the product webhook subscription block (append; keep the existing order/refund block):
#      [[webhooks.subscriptions]]
#      uri = "https://verify.secondchanceauthenticators.com/sca/shopify/webhook"
#      topics = [ "products/create", "products/update", "products/delete" ]

# 4. Deploy a new version and REVIEW THE DIFF before confirming/releasing:
shopify app deploy
#    -> the diff MUST show:  + products/create, + products/update, + products/delete  (one endpoint)
#       and NOTHING removed; access_scopes = "read_orders,read_products" (UNCHANGED, read_products still
#       present); api_version 2026-07 unchanged; redirect_urls unchanged.
#    -> If the diff shows access_scopes dropping read_products, or any existing webhook removed: ABORT.

# 5. Release the new version (e.g. sca-eyewear-registry-6).
```

### Target `[webhooks]` section (post-edit, for reference)
```toml
[webhooks]
api_version = "2026-07"

  [[webhooks.subscriptions]]
  uri = "https://verify.secondchanceauthenticators.com/sca/shopify/webhook"
  topics = [ "orders/cancelled", "orders/paid", "refunds/create" ]

  [[webhooks.subscriptions]]
  uri = "https://verify.secondchanceauthenticators.com/sca/shopify/webhook"
  topics = [ "products/create", "products/update", "products/delete" ]
```
And `access_scopes.scopes = "read_orders,read_products"` (must be present after the pull).

## [8][9] Post-release verification (owner, after the new version is live)

- `shopify app versions list` (or Dev Dashboard) → the active version lists **all six** subscriptions (3 order/refund + 3 product) on the one endpoint, scopes `read_orders,read_products`, API `2026-07`.
- SCA side already healthy and unchanged: `/admin/login → 200`; credential `read_orders,read_products`; catalog `products=4565, variants=5330`; provenance `3/3/5/4/3/1`. The SCA receiver is proven (bad-sig→401; valid→200 `processed` + upsert; replay idempotent), so deliveries will process once released.
- Do not modify a real product just to generate a test; use Shopify's "Send test notification" if a live check is wanted.

## Note for the gov `shopify-app/` copy

The committed `/opt/sca-gov/shopify-app/shopify.app.toml` is **out of date** (scopes `read_orders` only, no product webhooks). It was left unmodified here (editing it could mislead a deploy, since the authoritative current config must come from `shopify app config pull`). After a successful release, the owner should `config pull` and commit the refreshed toml to gov so the repo matches the live app.

**STOP — release blocked on (A) Partner authentication and (B) the stale committed toml (scopes would downgrade). App identity verified; exact reconcile-then-deploy steps provided. No app version released, no new app, no SCA server/inventory/product change.**

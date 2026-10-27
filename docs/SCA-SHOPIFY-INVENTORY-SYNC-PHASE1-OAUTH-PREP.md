# SCA — Shopify Inventory Sync Activation Step 1: OAuth `read_products` Preparation (READ-ONLY)

**Scope: read-only preparation only. No scope change, no reauthorization, no webhook registration, no import, no migrate/merge/restart, no Option C change. No access token, client secret, or credential value is revealed or logged anywhere below.** 2026-10-27. **STOP for approval before changing production configuration or initiating OAuth.**

## [1] Deployed Shopify connection & current OAuth configuration (observed; non-secret only)

- `SHOPIFY_SHOP_DOMAIN = second-chance-eyewear-accessories.myshopify.com` (valid `*.myshopify.com`).
- **`SHOPIFY_SCOPES = read_orders`** (products NOT yet granted).
- `SHOPIFY_API_VERSION = 2026-07` (within the supported set `2025-10 … 2026-07`).
- `SHOPIFY_OAUTH_REDIRECT_URI = https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback`.
- `SHOPIFY_CLIENT_ID`, `SHOPIFY_CLIENT_SECRET`, `SHOPIFY_WEBHOOK_SECRET` are all **present** (values not shown).
- Live credential row: `shop_domain = second-chance-eyewear-accessories.myshopify.com`, `scope = read_orders`, `has_token = 1`, `expires_at = NULL`, last updated `2026-10-05`. So the store is installed with a **read_orders-only** token; order webhooks work on it.
- Config is **not cached** (no `bootstrap/cache/config.php`), so an `.env` edit is read on the next request.

## [2] Minimum configuration change (prepared; NOT applied)

Exactly one line in `/opt/sca-platform/app/.env`:

```
- SHOPIFY_SCOPES=read_orders
+ SHOPIFY_SCOPES=read_orders,read_products
```

- This is **additive** — `read_orders` is kept; `read_products` is added. The scope string is **not a secret**.
- No code change is needed: the OAuth flow and the product-sync code are already deployed (`905ea7d`); `OAuthService::authorizeUrl` emits whatever `SHOPIFY_SCOPES` contains, and `grantedScopesSatisfyRequired` already checks that the granted scopes include every required one.
- Because config is not cached, the change takes effect on the next request. (If config is ever cached, run `php artisan config:clear` after the edit.) No service restart required.

## [3] OAuth callback & expected store domain — verification

- **Expected shop domain:** `second-chance-eyewear-accessories.myshopify.com` — matches the installed credential row's `shop_domain` exactly. ✅ (app side)
- **Redirect URI (app side):** `SHOPIFY_OAUTH_REDIRECT_URI = https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback`, and the public route `sca/shopify/oauth/callback` (`sca.shopify.oauth.callback`) resolves. HTTPS, exact path match. ✅
- **Owner must confirm (external, cannot be verified from the server):**
  1. The Shopify app (Dev Dashboard) has **this exact HTTPS redirect URL** in its allowed redirection URLs (Shopify requires an exact match, or the authorize call errors).
  2. The edge Caddy routes `/sca/shopify/oauth/callback` to `kr-app` (added in the prior Shopify edge activation, gov `8bc04d5`).

## [4] Exact merchant authorization URL & approval steps

**Recommended path — the in-app, ACL-gated initiator (no hand-built URL, CSRF-`state` protected):**
1. After the §2 scope change, an SCA staff member (with the `sca.shopify.view` permission) opens:
   `https://verify.secondchanceauthenticators.com/admin/sca/shopify/connect`
2. The app (`OAuthController::install`) generates a single-use `state` nonce, stores it in the session, and **redirects (302) to Shopify's authorize screen**. The URL it builds is:
   `https://second-chance-eyewear-accessories.myshopify.com/admin/oauth/authorize?client_id=<CLIENT_ID>&scope=read_orders,read_products&redirect_uri=https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback&state=<nonce>`
   (`<CLIENT_ID>` comes from env; not shown here.)
3. **The merchant (the Second Chance Eyewear store owner/admin, signed into that Shopify store) reviews and clicks Approve/Update**, granting the added **read products** permission alongside the existing read orders.
4. Shopify redirects the browser back to the callback; `OAuthController::callback` verifies the `state`, the query HMAC, and the `shop` param, then exchanges the code for a **new token carrying `read_orders,read_products`**, stored **encrypted** (`AccessTokenStore`). The old read_orders-only token is replaced.
5. **Verify (non-secret):** the `sca_shopify_credentials.scope` column now reads `read_orders,read_products` (or space-separated) and `has_token = 1`. No token value is ever displayed.

If the person initiating `connect` is not the store admin, Shopify will prompt for the store's own authentication before showing the approval screen — the **store admin performs the approval**.

## [5] Preserving `read_orders` and order webhooks

- The change is additive (`read_orders` retained), so the re-consented token still authorizes order reads.
- `products/*` webhook topics are already deployed in the allowlist but **not registered** with Shopify (a later step); the existing `orders/paid`, `orders/cancelled`, `refunds/create` registrations and the sale-link processing path are **untouched** by a scope change. Reconciliation of orders and `getOrder` continue to need only `read_orders`.

## [6] Credential safety

Only the scope string, shop domain, redirect URI, API version, and credential-presence booleans are handled. No access token, refresh token, client id, client secret, or webhook secret value is printed, logged, or committed — they remain env-only and the stored token stays encrypted. The authorize URL above uses a `<CLIENT_ID>` placeholder.

## [7] Readiness & stop

| Item | Status |
|---|---|
| Deployed connection & config observed | **DONE** (read_orders-only token; config not cached) |
| Minimum scope change prepared (1 line) | **PREPARED** (not applied) |
| Callback + shop domain (app side) verified | **OK**; Dev-Dashboard redirect allowlist + edge routing = **owner to confirm** |
| Authorization URL + approval steps | **DOCUMENTED** (in-app `connect` → Shopify approve → callback) |
| read_orders + order webhooks preserved | **YES** (additive) |
| No credential exposure | **CONFIRMED** |

**STOP — read-only OAuth preparation delivered. Await explicit approval before editing `SHOPIFY_SCOPES` or initiating OAuth. No scope change, reauthorization, webhook registration, import, migrate, merge, or restart performed; Option C untouched.**

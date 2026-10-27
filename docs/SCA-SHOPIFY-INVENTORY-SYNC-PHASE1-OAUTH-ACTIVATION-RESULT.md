# SCA — Shopify OAuth Activation Step 1: RESULT

**Authorized scope change applied; merchant OAuth approval is INTERACTIVE and PENDING.** The one-line `SHOPIFY_SCOPES` change is live and verified; the stored token remains `read_orders` until the Shopify administrator approves via the connection URL below. No webhook registration, no import, no reconciliation, no code deploy/migration, no ownership/auth/passport change, no Option C / 139/140 change. No credential or access-token value exposed. 2026-10-27. **STOP — PENDING merchant approval.**

## [1] Health & prior config

`/admin/login` → 200; `main 905ea7d`. Before: `SHOPIFY_SCOPES=read_orders`; credential `scope=read_orders, has_token=1` (token dated 2026-10-05).

## [2] Configuration change (applied)

`/opt/sca-platform/app/.env`, **one line only**:
```
- SHOPIFY_SCOPES=read_orders
+ SHOPIFY_SCOPES=read_orders,read_products
```
Verified **exactly one line differs** from the pre-change backup (`app/.env.bak.preoauth.20261027T155210Z`, 0600); every other line (all secrets) byte-identical and untouched. No secret value was read out or printed.

## [3] Credentials / tokens / order webhooks preserved

A scopes env edit does not touch the database or Shopify: the credential row is unchanged (`scope=read_orders, has_token=1`), the existing encrypted token is intact, and the registered order webhooks (`orders/paid`, `orders/cancelled`, `refunds/create`) and sale-link path are untouched. A 0600 backup of the prior `.env` is retained for rollback.

## [4] Effective OAuth configuration contains both scopes

Bootstrapped read of the live app: `effective_scopes=read_orders,read_products`; `OAuthService::requiredScopes = [read_orders, read_products]` (`has_read_orders=yes`, `has_read_products=yes`). Config is not cached, so this is live immediately; no restart performed or needed.

## [5] Callback URL registered & accessible

`GET https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback` → **400** (and loopback → 400): the route is reachable through the edge and **fails closed** on a bare request (missing shop/state/HMAC), exactly as designed (a 404 would mean unrouted). HTTPS, exact path. (Owner still owns the external check that the Dev Dashboard app allowlists this exact redirect URL.)

## [6] Official SCA connection URL (for the authorized Shopify administrator)

```
https://verify.secondchanceauthenticators.com/admin/sca/shopify/connect
```
A staff member with the `sca.shopify.view` permission opens it; the app generates a single-use CSRF `state` and redirects the browser to Shopify's authorize screen, now requesting **read_orders, read_products**. The **Second Chance Eyewear store administrator** reviews and approves the added "read products" permission.

## [7] Interactive approval — PENDING (not bypassed)

I cannot and did not click the approval in the merchant's Shopify admin. The re-consent must be completed interactively by the store administrator via the URL in [6].

## [8] Stored-credential verification — PENDING

Current stored credential: `scope=read_orders`, token dated `2026-10-05` — i.e. **the merchant has not re-consented yet**. After approval, re-check: `sca_shopify_credentials.scope` must include **read_products** and `has_token=1` with a newer `updated_at`.

## [9] Read-only product-access check — PENDING

Deferred until after approval. Running it now would only return `SHOPIFY_AUTH_ERROR` (403) because the active token is still `read_orders`; it is meaningful only once the `read_products` token is stored. When approval is confirmed, a read-only `ShopifyClient::getProduct`/`listProducts` probe (no import, no writes) confirms product access.

## [10] Outcome

| Step | Status |
|---|---|
| 1 Health + current config | DONE |
| 2 `SHOPIFY_SCOPES` → `read_orders,read_products` | **DONE** (one line; backup kept) |
| 3 Credentials/tokens/order webhooks preserved | DONE |
| 4 Effective config has both scopes | **DONE** (verified) |
| 5 Callback registered & accessible | DONE (400 fail-closed, routed) |
| 6 Connection URL provided | DONE |
| 7 Interactive merchant approval | **PENDING** (human action) |
| 8 Stored credential has both scopes | **PENDING** (still read_orders) |
| 9 Read-only product-access check | **PENDING** (after approval) |

**STOP — scope change live; merchant approval PENDING. Have the Shopify administrator open the connection URL in [6] and approve. Then re-run steps 8–9 to confirm the stored token carries read_products and product reads succeed. No webhook registration / import / reconciliation / deploy / migration / ownership change performed; no credentials exposed.**

### Rollback (if needed)

Restore the retained backup: `cp -p app/.env.bak.preoauth.20261027T155210Z app/.env` (reverts the scopes line to `read_orders`); no token/webhook/DB change to undo.

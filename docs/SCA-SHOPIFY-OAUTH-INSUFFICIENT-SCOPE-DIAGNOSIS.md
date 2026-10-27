# SCA — Shopify OAuth "Insufficient Scope" on Callback: Diagnosis (READ-ONLY)

**Scope: read-only diagnostics. No app-scope/config/deploy/OAuth/uninstall change. No OAuth code, callback-with-code, access/refresh token, client secret, or session state printed. Order integration preserved.** 2026-10-27. **Root cause: the token exchange SUCCEEDED but Shopify returned a token whose GRANTED scope did not include `read_products`, so `grantedScopesSatisfyRequired()` failed closed and the token was (correctly) not stored. The missing scope is a Shopify-app-configuration gap, not an SCA code or request error. STOP for owner action.**

## [1] Effective requested scopes — correct

`config('sca-shopify.scopes') = read_orders,read_products`; the authorize URL (`OAuthService::authorizeUrl`) requests both. SCA is asking for the right scopes. No SCA change needed here.

## [3] Where the failure happens (non-secret evidence)

`OAuthController::callback` runs in order: validate `shop` → verify CSRF `state` → verify callback HMAC → **exchange `code` for a token (succeeded)** → **step 5: `grantedScopesSatisfyRequired($payload['scope'])`**. That gate requires the returned `scope` to contain **every** required scope (`read_orders` AND `read_products`); it returned false → `fail(403, 'insufficient scope')` → **the token is NOT persisted** (`tokens->put()` is only reached after the gate passes).

So the merchant approved and the code→token exchange worked, but **Shopify's token response `scope` omitted `read_products`** (it granted `read_orders` only). The controller intentionally logs/stores nothing on failure, so the exact returned string isn't persisted; the DB row + the code path are the authoritative non-secret evidence. App logs contained only unrelated old PHPUnit stack traces and a tinker echo — **no production token/scope/secret was logged or exposed.**

## [4] Existing encrypted credential — intact, not replaced or damaged

`sca_shopify_credentials`: `shop_domain=second-chance-eyewear-accessories.myshopify.com`, `scope=read_orders`, `has_token=1` (encrypted token present, length 256), `expires_at=NULL`, **`updated_at=2026-10-05 20:47:55` — unchanged since before this OAuth attempt**. The failed callback did not overwrite or corrupt it (by design: store happens only after the scope gate passes). **The order integration (`read_orders`) remains fully functional** — orders webhooks/reconcile are unaffected throughout.

## [2][5] Why `read_products` was not granted — Shopify app configuration

I cannot read the external Shopify Partner/Dev Dashboard. But the signature (exchange OK, granted scope missing `read_products`) points to the app's **configured access scopes not including `read_products`**:

- Modern Shopify apps use **config-based ("managed") install scopes**: the granted scopes come from the app's declared configuration (`shopify.app.toml` `[access_scopes] scopes = "..."`, or Dev Dashboard → Configuration → Access scopes), and the `scope` query parameter in the authorize URL is **ignored/capped** by the app config. So requesting `read_products` in the URL has no effect until the app configuration **declares** it and that configuration version is **deployed/released**.
- `read_products` is standard (not protected customer data), so this is almost certainly a missing declaration, not a Shopify approval restriction.

**Owner must confirm in the Dev Dashboard:** the app's Access scopes include `read_products` (alongside `read_orders`), and the updated app version has been released. If `read_products` is absent there, that is the root cause.

## [6] Minimum safe correction — precise owner steps (no SCA code/scope change)

1. **Declare the scope in the Shopify app config:** in the Partner/Dev Dashboard for this app (or `shopify.app.toml`), set Access scopes to include **both** `read_orders` and `read_products`. (Additive — keep `read_orders`.)
2. **Deploy/release the app configuration** (a new app version) so the scope change takes effect for installs/consents. (Config-based scopes require the released version; an unreleased edit won't be granted.)
3. **Re-run the SCA connect flow from the allowlisted IP (103.200.35.3):** open `https://verify.secondchanceauthenticators.com/admin/sca/shopify/connect`; the store admin approves — the authorize screen will now include "read products"; the callback exchanges the code for a token whose granted scope includes `read_products` → "Shopify store connected."
4. **Verify (read-only, separate step):** `sca_shopify_credentials.scope` now includes `read_products` with a newer `updated_at`; then a read-only `getProduct`/`listProducts` probe (no import).

- **No change required on the SCA side:** `SHOPIFY_SCOPES` is already `read_orders,read_products` and the request/validation logic is correct. **Do not** uninstall/reinstall unless the Dashboard specifically requires it — declaring the scope + releasing + re-consenting is sufficient and **preserves the existing order integration** (the current `read_orders` token stays valid until a successful re-consent replaces it with a both-scopes token).
- Do not weaken `grantedScopesSatisfyRequired` to accept a partial grant — that gate is correct (it prevents silently operating without the product scope).

## [7] Summary

| Check | Finding |
|---|---|
| [1] Requested scopes | `read_orders,read_products` — correct (SCA side fine) |
| [3] Failure point | `grantedScopesSatisfyRequired` after a successful exchange — returned scope lacked `read_products` |
| [4] Existing credential | **Intact** (`read_orders`, token present, `updated_at` unchanged) — not replaced/damaged; orders unaffected |
| [2][5] Likely cause | `read_products` not declared/released in the Shopify app's configured access scopes (config-based install) |
| [6] Fix | Owner: declare `read_products` in app config → release the version → re-consent from the allowlisted IP; no SCA code/scope change |

**STOP — read-only diagnosis delivered. No app-scope/config/deploy/OAuth/uninstall/production change; no secrets printed; order integration preserved. Recommended fix is an owner-side Shopify app-config update + release + re-consent.**

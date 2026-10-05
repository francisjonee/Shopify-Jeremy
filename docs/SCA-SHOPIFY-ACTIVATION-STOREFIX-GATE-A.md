# SCA Shopify Activation — Target-Store Correction + Gate A (re-run) — PASS

**Date:** 2026-10-06 · **Deployed app:** `98ae654`, migrations **120** (unchanged).
**Status: SHOPIFY_SHOP_DOMAIN corrected to the real sales store; Gate A re-run PASS. No OAuth initiated, no app
create/uninstall, no secret/code/schema/edge change. STOP for review.** No secrets/tokens/PII recorded.

## Why
The failed Phase 2 OAuth attempt was caused by a wrong target store. Phase 1 had configured
`SHOPIFY_SHOP_DOMAIN=second-chance-authenticators.myshopify.com`, but the existing **SCA Eyewear Registry** app is
installed on the actual sales store **`second-chance-eyewear-accessories.myshopify.com`**.

## Change (one key only)
- **Read-only precheck:** `SHOPIFY_SHOP_DOMAIN` was `second-chance-authenticators.myshopify.com` (incorrect);
  credentials table `0` (pre-OAuth).
- **Backup (server-local, git-ignored, 600, `www-data`):** `app/.env.bak.pre-shopify-storefix` +
  `/root/sca-env-backup.app.env.pre-shopify-storefix`. (Prior backups retained.)
- **Changed only** `SHOPIFY_SHOP_DOMAIN=second-chance-eyewear-accessories.myshopify.com` (value is non-secret).
  All 8 Shopify keys still present; `SHOPIFY_CLIENT_ID/CLIENT_SECRET/WEBHOOK_SECRET` **not touched**; owner/mode
  preserved. `config:clear` run.

## Gate A (re-run) — PASS (no secret values exposed)
- `expected_shop_domain = second-chance-eyewear-accessories.myshopify.com` · `scopes = read_orders` ·
  `api_version = 2026-07` · `line_item_ref_property = sca_item_ref` ·
  `oauth_redirect_uri = https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback` (**callback
  unchanged**).
- Secrets: `client_id = SET`, `client_secret = SET`, `webhook_secret = SET` (SET/UNSET only).
- Diagnostics `ConnectivityVerifier::verify()` → `configured=true`, `connected=false`,
  `error_category='not_connected'` → **configured but not connected** (verify() short-circuits at
  `connected=false`; no outbound Shopify call).
- Shopify credential table `0` (unchanged pre-OAuth state); `webhook_receipts/sale_links = 0/0`.
- Webhook HMAC fail-closed: unsigned `POST /sca/shopify/webhook` → **401**.
- Edge/no-broad-exposure: callback 400, `/sca/anything-else` 404, `/admin/sca/shopify` 403, `/storage/x` 404.
- SCA invariants: `/p/<valid>` 200, `/p/<bogus>` 404, `/p/<malformed>` 404 (SCA-038); `/collector/login` 200;
  `http→https` 308; Secure cookie present; public `:8080` 000 (retired); **smsrocket.io 302** (co-tenant healthy).
- **Zero provenance/domain change:** `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4`, migrations **120**.

## Read-only analysis — existing Dev Dashboard install & required OAuth procedure
The Dev Dashboard shows **SCA Eyewear Registry** already **Installed** on
`second-chance-eyewear-accessories.myshopify.com` (install date Sep 16, 2026). Determination:
- That "installed" state is **Shopify-side** (merchant consent/authorization exists for the app on the store). It
  does **not** give SCA an access token: SCA's own `sca_shopify_credentials` table is **empty (0 rows)**, and the
  deployed code obtains + stores a token **only** via the OAuth callback's `exchangeCode` → `AccessTokenStore::put`
  (there is no token-seeding path).
- **Required procedure is UNCHANGED:** initiate the **existing Laravel OAuth flow** once, normally, via the
  staff-IP `/admin/sca/shopify/connect` route. Because consent already exists for the app on that store, Shopify's
  authorize step will typically **skip the merchant-consent prompt and redirect straight back to the callback with
  a fresh `code`**; the callback then exchanges it and stores SCA's encrypted token. **No uninstall/reinstall and
  no new app** are needed (and are forbidden).
- **Scope caveat for Phase 2/Gate B:** the existing install's **granted** scope must be exactly `read_orders`. If
  the Sep-16 install granted `read_products` too (the old config default), it will surface at Gate B
  (`grantedScopesSatisfyRequired` passes on `read_orders ⊆ granted`, but Gate B's "no unexpected scope" check would
  flag `read_products`). Confirm the app version `sca-shopify-activation-v2` is `read_orders`-only before OAuth; if
  a stale broader grant exists, resolve it Shopify-side (operator) rather than in SCA code.

## HARD STOP
No OAuth initiated; no app create/uninstall/reinstall; no install link generated; no webhooks registered/tested;
no order/Shopify data mutation; no code/edge/schema change. Rollback ready (`app/.env.bak.pre-shopify-storefix`),
not needed.

**Next (operator go, Phase 2):** run the existing Laravel OAuth flow from a staff-IP browser session against
`second-chance-eyewear-accessories.myshopify.com`, then Gate B (verify one encrypted credential for the expected
store, granted scope == `read_orders`, diagnostics connected, zero domain mutation). STOP for ChatGPT/operator
review. See [[sca-shopify-activation-preflight]], [[sca-shopify-edge-activation]].

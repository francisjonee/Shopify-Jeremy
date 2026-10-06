# SCA Shopify Activation — Phase 3 deploy + Gate C CLOSED — webhooks LIVE

**Date:** 2026-10-06 · **Status: DONE. Audited config (gov `3f1a788`) deployed to the EXISTING app; Gate C PASS.
No new app, no scope/OAuth/SCA-code/schema/Caddy/secret change, no order/test-webhook. STOP — not starting
Phase 4.**

## Deploy (ChatGPT-approved, from the linked existing app)
`cd /opt/sca-gov/shopify-app && shopify app deploy --allow-updates` (CLI 4.8.5; `--force` does not exist in this
version — `--allow-updates` auto-confirms config UPDATES and releases, and would NOT silently proceed on any
deletion). Pre-flight preview (non-release) first confirmed target **Org: Second Chance Eyewear & Accessories ·
App: SCA Eyewear Registry**, change list **"webhooks (updated)"** only (access_scopes/auth/application_url listed
but NOT flagged updated → scope/OAuth/app-URL unchanged), no new-app prompt.
- Result: **"New version released to users"** — version **`sca-eyewear-registry-4`**, message "Add SCA webhook
  subscriptions (orders/paid, orders/cancelled, refunds/create) @2026-07".
- Dashboard: `https://dev.shopify.com/dashboard/78057044/apps/424307752961/versions/1156804149249` → app ID
  **424307752961** (existing), confirming no new app.

## Gate C verification (read-only; no order, no test delivery)
- **Active config = released version = deployed toml:** 1 subscription block (no duplicates), api_version
  `2026-07`, topics exactly `orders/paid, orders/cancelled, refunds/create`, uri
  `https://verify.secondchanceauthenticators.com/sca/shopify/webhook`; scope `read_orders`, optional_scopes `[]`.
  (Operator may double-confirm live registrations via the Dev Dashboard version page or a read-only
  `GET /admin/api/2026-07/webhooks.json` — no test trigger.)
- **SCA connection intact:** `ConnectivityVerifier` `connected=true`, `matches_expected=true`; granted scope
  `read_orders`; `sca_shopify_credentials = 1` (deploy did not touch SCA's stored token/connection).
- **No events/data:** `sca_shopify_webhook_receipts / sca_shopify_sale_links = 0 / 0` (no order placed).
- **Webhook receiver still fail-closed:** unsigned `POST` → 401; forged-HMAC `POST` → 401 (HMAC not weakened).
- **Zero provenance/domain mutation:** `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4`, migrations **120**;
  ownership/claim/cert/auth/QR/item-state unchanged.
- **SCA invariants + co-tenant:** `/p/<valid>` 200, `/p/<bogus>` 404 (SCA-038); `/storage/x` 404;
  `/admin/sca/shopify` 403 (staff-IP); `/collector/login` 200; `smsrocket.io` 302 (healthy).

## State
Shopify webhook subscriptions (orders/paid, orders/cancelled, refunds/create → SCA receiver, API 2026-07) are now
**LIVE** on the existing SCA Eyewear Registry app. Integration = connected + subscribed; still **no events, no
sale-links, no SCA mutation**. Phase 3 / Gate C complete.

## NOT done (per instruction)
No Phase 4 dry-run; no product/order/pay/refund/cancel; no SCA pilot item; no manual sale-link. Temporary OAuth
callback edge handle still retained (remove in Phase 5). STOP for operator/ChatGPT.

# SCA Shopify Activation — Phase 3 (webhook registration) + Gate C

**Date:** 2026-10-06 · **Deployed app:** `98ae654`, migrations **120** (unchanged).
**Status: SCA-side preflight + Gate C PASS. Shopify-side webhook registration + subscription inspection are
operator actions (no in-app mechanism) — handed off; Gate C Shopify-side pending operator confirmation. No
mutation, no secrets exposed, no code/edge/schema change, no dry-run.** No secrets/tokens/PII recorded.

## Registration mechanism (determination)
The `Sca/Shopify` package is a **pure receiver**: there is no in-app webhook registration/subscription code, and
`ShopifyClient` exposes only `getShop()` — **no authorized in-app method exists to list or create Shopify webhook
subscriptions.** Therefore registration (and read-only inspection) of the Shopify-side subscriptions is performed
**operator-side** for this dev-dashboard app (`app_model = dev_dashboard_external`): the subscriptions are declared
in the **app configuration** of version **`sca-shopify-activation-v2`** (`shopify.app.toml [webhooks]`) and created
for the installed store when that version is released/installed. This is by design — **not** a blocker requiring a
code change (so no STOP-abort); it is a Shopify-UI/app-config action, which Claude cannot perform. Claude will not
decrypt/handle the access token or add code to make an ad-hoc Admin API call.

**Critical:** register via the **app config** (app-managed subscriptions), so deliveries are HMAC-signed with the
**app's Client Secret** — which is exactly what `SHOPIFY_WEBHOOK_SECRET` is set to. Do **not** register via the
store's *Settings → Notifications* (that uses a different signing secret and would break HMAC verification).

## Phase 3 read-only preflight (SCA side) — PASS
- HEAD `98ae654` == origin/main, clean tree.
- Receiver allowlist `WebhookTopics::SUPPORTED` = **exactly** `orders/paid | orders/cancelled | refunds/create`.
- `sca_shopify_credentials = 1`, shop `second-chance-eyewear-accessories.myshopify.com`, granted scope
  `read_orders`; `ConnectivityVerifier` `connected=true`, `matches_expected=true`, `verified_shop` = the store.
- `requested_scopes = read_orders`, `api_version = 2026-07`, `webhook_path = sca/shopify/webhook`.
- `webhook_receipts / sale_links = 0 / 0`.
- Provenance `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4`, migrations **120**.

## Gate C — SCA side PASS (read-only)
- **Receiver fail-closed:** unsigned `POST /sca/shopify/webhook` → **401**; **forged HMAC** (garbage signature,
  valid-looking topic/shop headers, JSON body) → **401**, and the forged delivery **recorded nothing** (receipts
  still `0/0` — HMAC rejected before any receipt write). HMAC not weakened.
- Edge/default-deny: callback GET → 400; `/sca/anything-else` → 404; `/admin/sca/shopify` → 403 (staff-IP).
- Scope unchanged: requested & granted `read_orders` (no `read_products`); credentials remain **exactly one**.
- Counts unchanged: `receipts/sale_links = 0/0` (no fabricated payloads; Claude did not POST any signed event).
- Zero SCA mutation: `AFTER_FP = c3fea71a`, migrations 120; ownership/claim/cert/auth/QR/item-status unchanged.
- SCA invariants: `/storage/x` 404; `/p/<valid>` 200, `/p/<bogus>` 404, `/p/<malformed>` 404 (SCA-038);
  `/collector/login` 200; `http→https` 308; Secure cookie present; public `:8080` 000 (retired); **smsrocket.io
  302** (co-tenant healthy).

## Gate C — Shopify side (OPERATOR action; pending confirmation)
Operator, using the existing app (no new app, no OAuth change, no SCA endpoint/Caddy change):
1. In version `sca-shopify-activation-v2`'s app config, confirm/declare the `[webhooks]` block:
   ```toml
   [webhooks]
   api_version = "2026-07"
     [[webhooks.subscriptions]]
     topics = [ "orders/paid", "orders/cancelled", "refunds/create" ]
     uri = "https://verify.secondchanceauthenticators.com/sca/shopify/webhook"
   ```
   Release/ensure this version is the one installed on `second-chance-eyewear-accessories.myshopify.com` so Shopify
   creates the subscriptions (no reinstall of the app needed — a version update suffices).
2. **Read-only verify** the Shopify-side state (Dev Dashboard webhooks list, or an authorized read-only Admin API
   `GET /admin/api/2026-07/webhooks.json`) and report: exactly the **three** topics, each `uri` =
   `https://verify.secondchanceauthenticators.com/sca/shopify/webhook`, `api_version 2026-07`, and **no duplicate**
   subscriptions. Do **not** trigger a test delivery.

When the operator reports that list, Gate C closes fully (Claude records it). If a Shopify administrative/test
delivery legitimately arrives during registration, the SCA receipts count may increment by that one delivery —
inspect and explain it (safe, non-PII) before proceeding; it must not create ownership.

## HARD STOP
No Shopify product/order/pay/refund/cancel, no SCA pilot item create/certify, no manual sale-link, no end-to-end
dry-run, no OAuth-callback removal, no Phase 4. STOP after Gate C for ChatGPT/operator review.

Integration state: **connected** (encrypted offline token, scope `read_orders`); webhook subscriptions to be
registered/confirmed operator-side; no events, no data. See [[sca-shopify-activation-preflight]],
[[sca-shopify-edge-activation]].

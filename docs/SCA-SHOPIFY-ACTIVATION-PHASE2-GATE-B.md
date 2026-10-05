# SCA Shopify Activation — Phase 2 (OAuth) + Gate B — PASS

**Date:** 2026-10-06 · **Deployed app:** `98ae654`, migrations **120** (unchanged).
**Status: OAuth connected (by operator); Gate B read-only verification PASS. No Phase 3, no mutation, no
secret/token exposed, no code/edge/schema change, callback handle NOT removed.** No secrets/tokens/PII recorded.

## Phase 2 (operator-performed)
The operator completed the existing Laravel OAuth authorization-code flow via the staff-IP
`/admin/sca/shopify/connect` route against the corrected store **`second-chance-eyewear-accessories.myshopify.com`**
(no new app; existing **SCA Eyewear Registry** app; no uninstall/reinstall).

## Gate B — verification (read-only; no secret values exposed)
- **Exactly one credential row** for `second-chance-eyewear-accessories.myshopify.com` (`credential_rows=1`,
  `shop_domain` matches the expected store).
- **Access token present and encrypted at rest** — proven **without decrypting**: the stored `access_token` is a
  well-formed Laravel `Crypt` payload (base64 → JSON with `iv`/`value`/`mac`) and is **not** a plaintext Shopify
  token (no `shp…` prefix). No refresh token (`refresh_token` absent) and `expires_at = NULL` — a standard Shopify
  **offline** access token (permanent, no browser-callback refresh). The token value was never printed, hashed, or
  decrypted.
- **Requested scopes exactly `read_orders`** (`config('sca-shopify.scopes')`); **granted scope exactly
  `read_orders`** (stored `scope` column) — **no `read_products`** (the Sep-16-install scope caveat is cleared).
- **Diagnostics connected:** `ConnectivityVerifier::verify()` → `configured=true`, `connected=true`,
  `reachable=true`, `matches_expected=true`, `verified_shop_domain=second-chance-eyewear-accessories.myshopify.com`,
  `error_category=null`. The sanctioned read-only `shop.json` check **succeeded** (token is valid and resolves to
  the expected store); no Shopify data beyond the verified shop domain was surfaced.
- **Pre-webhook counts intact:** `webhook_receipts/sale_links = 0/0` (OAuth connecting created neither).
- **Zero SCA mutation:** provenance `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4`, migrations **120** — unchanged;
  no ownership/claim/certification/authentication/QR/item-status/provenance change.
- **Webhook HMAC fail-closed:** unsigned `POST /sca/shopify/webhook` → **401**.
- **Edge / default-deny correct:** callback GET → 400 (reaches app, fails safe w/o a valid txn); wrong-method
  webhook → 404; `POST` callback → 404; `/sca/anything-else` → 404; `/admin/sca/shopify` → 403 (staff-IP).
- **SCA invariants unchanged:** `/storage/x` 404; `/p/<valid>` 200, `/p/<bogus>` 404, `/p/<malformed>` 404
  (SCA-038 constant shape); `/collector/login` 200; `http→https` 308; Secure cookie present; public `:8080` 000
  (retired, loopback-only); **smsrocket.io 302** (co-tenant healthy).

## Temporary OAuth-callback handle — recommendation (not removed)
**Recommendation: RETAIN the temporary `GET /sca/shopify/oauth/callback` edge handle until the Phase 4 webhook
dry-run is complete and the connection is proven stable end-to-end; remove it in Phase 5.** Rationale:
- **Token maintenance does not need it:** the stored token is an **offline** token (no expiry, no refresh token),
  so routine operation never uses the browser callback. On that basis alone it *could* be removed now.
- **But a reconnect/re-OAuth may still be needed during Phases 3–4** (e.g., a scope/app adjustment surfaced by the
  dry-run, token revocation, or a re-install), which requires the public callback. Removing it now would force an
  edge change under pressure mid-dry-run.
- Retention risk is low: the callback is state-nonce + HMAC + expected-shop validated and returns 400/401/403 on
  any invalid transaction. Remove it in Phase 5 via the governed Caddy validate+recreate procedure, then prove it
  becomes 404 while the permanent `POST /sca/shopify/webhook` stays reachable/fail-closed.
Per the task, it was **not** removed in this step.

## HARD STOP
No webhook registration/test, no Shopify order/refund/cancel, no product/listing change, no SCA item mutation, no
code/schema/edge change, no callback removal, no Phase 3 work.

Integration state: **connected** (encrypted offline token, scope `read_orders`), **no webhooks registered yet, no
events, no data**. STOP for ChatGPT/operator review. See [[sca-shopify-activation-preflight]],
[[sca-shopify-edge-activation]].

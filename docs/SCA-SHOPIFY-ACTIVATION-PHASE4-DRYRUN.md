# SCA Shopify Activation — Phase 4 controlled dev-store dry-run (in progress)

**Date:** 2026-10-06 · **Deployed app:** `98ae654` (no app code change), migrations **120**.
**Status: Phase 4A PASS; STOPPED for operator Shopify-UI action (create + pay the dedicated test order) before
Gate D1.** No secrets/PII/tokens recorded. Gate-by-gate; Phase 5 not authorized.

## Phase 4A — pre-mutation gate (PASS)
- **Gate C still true:** existing app connected (`connected=true`), granted scope exactly `read_orders`,
  credentials=1; the 3 webhook topics live (released `sca-eyewear-registry-4`); receiver fail-closed; migrations
  **120**; co-tenant healthy.
- **BEFORE snapshot (counts):** items 2, state 2, auth 3, cert 3, cert_events 4, qr 2, qr_lifecycle 2, ownership 4,
  status 6, claims 1, external_claim_grants 1, sale_links 0, webhook_receipts 0, collectors 2, images 3.
  `BEFORE_FP = c3fea71ad6ecf93345b2eefc5f5cbef4`.
- **Pre-existing items (must stay untouched):** id=1 `SCA-3C35D669ACBE` (sce_presale, DEMO-DO-NOT-USE);
  id=3 `SCA-F1B792AE4745` (external_intake, Ray-Ban PILOT-TEST).
- **Handler inspection (no code/schema change needed):** `orders/paid` → `SaleLinkService::linkPaidLine`
  (`assertEligible` requires only: no current owner + no other active sale-link — **cert NOT required at
  paid-time**); mapping by `public_ref` via the `sca_item_ref` line-item property (NOT SKU). Claim →
  `ClaimWorkflow::claim` resolves via `PassportResolver` (**requires active QR + current issued cert**), requires an
  `eligible` sale-link, then `ClaimService::complete` appends one ownership `claim` under lock. Refund →
  `SaleLinkEventProcessor::handleRefund` revokes by `refund_line_items[].line_item_id` only; `CommerceService::refund`
  appends `disputed` only if already owned (append-only, ownership preserved).
- **Dedicated TEST item created (one only, labeled; via the existing domain services):**
  - item id **4**, public_ref **`SCA-A960A57D3124`**, brand `SCA-SHOPIFY-DRYRUN`, model `PHASE4-TEST-DO-NOT-SELL`,
    intake `sce_presale`.
  - authenticated (passed, grade A, finalized) + certified (`SCA-CERT-2026-ADE62F13`) → active QR minted
    (`is_production=0`, test); lifecycle CERTIFIED; passport resolves 200.
  - Its QR public token is retained server-side for the Gate D2 claim (non-secret passport token; not needed by
    the operator).
- **Post-4A delta is exactly the test item:** items/state/auth/cert/cert_events/qr/qr_lifecycle each +1 (item 4);
  ownership 4, status 6, sale_links 0, receipts 0 unchanged. Pre-existing id1/id3 state unchanged (id1 CERTIFIED/
  normal/unowned; id3 REGISTERED/recovered/owner1). item3 passport still 200.

## STOP — operator Shopify-UI action required (Gate D1 trigger)
Create and pay ONE dedicated test order in the connected store `second-chance-eyewear-accessories.myshopify.com`
with the line item mapped to the test item. Exact minimal steps (no customer PII, no secrets):
1. Shopify admin → **Orders → Create order** (draft order).
2. Add one line item (a custom/test item or a test product), **Quantity = 1**.
3. Add a **line-item property** (custom attribute on that line): **name `sca_item_ref`**, **value
   `SCA-A960A57D3124`**. (Must be a line-item property — not an order note, not a variant metafield.)
4. **Mark as paid** (dev/test store: use the test/Bogus gateway or "Mark as paid") so `orders/paid` fires.
5. Use a minimal/test customer; do **not** enter real customer PII.
Then tell Claude "paid". Claude will run Gate D1 (verify one receipt + one eligible sale-link for item 4, mapped by
`sca_item_ref`, no PII persisted / `shopify_customer_ref` null, pre-existing items untouched, idempotency).

(No order is created by Claude; `shopify app deploy` is not re-run; Phase 5 not started.)

## Gate D1 — BLOCKED at order creation: `read_orders` is read-only (no draft-order write)
The Shopify admin "Custom item" dialog does not expose line-item properties, so the operator could not attach
`sca_item_ref` there. Creating the order via the **Admin API** was evaluated and **stopped before any mutation**:
- **`draftOrderCreate` (and legacy REST `POST /draft_orders.json`) require `write_draft_orders`** (verified against
  Shopify docs, 2025-01/current). Creating via the Orders API would require `write_orders`.
- The integration app's **granted scope is exactly `read_orders`** (confirmed Gate B/C; `optional_scopes=[]`). It is
  **read-only for orders by design** and therefore **cannot create a draft/test order** under current authorization.
- No API write was attempted; scopes were **not** broadened and the app config was **not** changed (both forbidden).

This is the intended security posture — the inbound integration app holds no order-write power. The test must
therefore use the **genuine inbound path** (a real checkout that carries the line-item property), which is exactly
how production sales will deliver `sca_item_ref`.

### Safest alternative (no scope/app/SCA-code change) — RECOMMENDED
**Storefront test checkout** on `second-chance-eyewear-accessories.myshopify.com`, where the line item carries the
`sca_item_ref` line-item property (value `SCA-A960A57D3124`, quantity 1), paid via the test/Bogus gateway so
`orders/paid` fires:
- Line-item properties are emitted by the product add-to-cart form (`properties[sca_item_ref]`) or the Storefront
  API cart line attributes — the Storefront API uses its own (separate) access token, not the Admin order scopes.
- Options to inject the property without a full theme build: (a) add a hidden `properties[sca_item_ref]` input to a
  dedicated test product's form via a theme snippet; or (b) build a test cart via the Storefront API with the line
  attribute; then complete a test (Bogus-gateway) checkout.
- This validates the real production mapping end-to-end and needs **no** Admin order-write scope, no app-config
  change, and no SCA code change.

### Alternatives NOT taken (require a change that is out of scope here)
- Granting `write_draft_orders`/`write_orders` to the app, or using a separate order-write Admin credential, would
  change scopes/app config — **not authorized**; flag for operator/ChatGPT if an admin-side draft is preferred over
  the storefront path.

**STOP — operator decision required:** proceed with the storefront test-checkout path above (recommended), or
authorize a scope/credential change out-of-band. No order created; nothing marked paid; Phase 5 not started.

## Gate D1 setup — storefront AJAX-cart mechanism (operator; no theme change, no scope change)
Chosen mechanism = **Shopify AJAX Cart API** (`/cart/add.js` with a line-item `properties` object) against a
**dedicated hidden/draft TEST product**. Rationale: line-item properties attach at the **cart** layer, so NO live
theme edit is needed (a theme product-form `properties[...]` input would risk affecting real products — rejected
per the "stop before a theme change that could affect real customers" instruction). Reversible: the only
persistent artifact is one hidden test product the operator can delete afterward; the cart is ephemeral. Uses no
Admin order-write scope and no SCA app/scope/OAuth/webhook/code/schema change. Claude performs none of this (no
store/admin access; app is read-only); steps below are operator-run, STOP before payment.

Operator steps (test data only; no real customer PII):
1. Admin → Products → **Add product**: title e.g. `ZZ-SCA-DRYRUN-TEST (do not sell)`, a price, set **inventory /
   continue selling** so it's purchasable; set **Status = Active but UNLISTED** — remove it from the Online Store
   sales channel OR keep the product hidden; do not feature it. (A draft product can't be bought, so make it
   Active-but-hidden, not Draft.) Note its **variant ID** (Admin product URL / variant).
2. Open the store's storefront in a browser (enter the store password if the dev store is password-protected).
3. In the browser DevTools console (same storefront origin), attach the line-item property via the cart API:
   ```js
   fetch('/cart/add.js', {method:'POST', headers:{'Content-Type':'application/json'},
     body: JSON.stringify({ items:[{ id: <VARIANT_ID>, quantity:1,
       properties:{ sca_item_ref: 'SCA-A960A57D3124' } }] }) }).then(r=>r.json()).then(console.log)
   ```
4. **VERIFY the property is genuinely on the line BEFORE paying** (not a note/attribute/metafield):
   ```js
   fetch('/cart.js').then(r=>r.json()).then(c=>console.log(JSON.stringify(
     c.items.map(i=>({title:i.title, quantity:i.quantity, properties:i.properties})))))
   ```
   Confirm the line shows `quantity: 1` and `properties: { "sca_item_ref": "SCA-A960A57D3124" }`.
5. Proceed to **/checkout**, complete payment with the **test/Bogus gateway** (no real charge, no real PII).
   Paying fires `orders/paid` → the webhook → SCA.

STOP before payment: operator confirms the `/cart.js` output shows `sca_item_ref=SCA-A960A57D3124` on the qty-1
line, then pays. After "paid", Claude runs Gate D1 (one receipt + one eligible sale-link for item 4, mapped by
`sca_item_ref` not SKU, no PII / `shopify_customer_ref` null, pre-existing items untouched, idempotency).

## Gate D1 — paid order + mapping + idempotency — PASS (order #3281)
Operator paid Shopify order **#3281** (one test line, `sca_item_ref=SCA-A960A57D3124`). Read-only verification:
- **Real `orders/paid` delivery HMAC-ACCEPTED:** exactly **one** `sca_shopify_webhook_receipts` row — topic
  `orders/paid`, shop `second-chance-eyewear-accessories.myshopify.com`, webhook_id
  `12eb1029-49ab-5de6-8681-dcaf7184d02b` (Shopify delivery UUID, non-PII), api_version `2026-07`,
  status `received`, `payload_sha256` present (64 chars). (A receipt is only written after HMAC verification →
  empirically confirms `SHOPIFY_WEBHOOK_SECRET` = app Client Secret verifies the real signed delivery.)
- **Exactly one eligible sale-link for the test item:** 1 row, `eyewear_item_id=4`, `eligibility_state=eligible`,
  order `8019293831455`, line `18855278313759`, product `10632814199071`, variant `52983511089439`,
  idempotency_key `…:orders/paid:8019293831455:18855278313759`.
- **Mapped by `sca_item_ref`, NOT SKU:** `sale_link.eyewear_item_id=4` → `public_ref SCA-A960A57D3124` (the
  `sca_item_ref` line-item property). The processor reads `line_items[].properties[sca_item_ref]`; the sale-link
  stores no SKU and SKU is never the key.
- **No customer PII persisted:** `shopify_customer_ref = NULL` (as designed). The receipts table has no PII columns
  (`id, idempotency_key, shop_domain, topic, webhook_id, api_version, payload_sha256, status, received_at,
  created_at`) — a one-way digest only, no raw body.
- **Eligibility ≠ ownership:** `sca_ownership_events = 4` (unchanged); test item 4 `current_owner_collector_id =
  NULL`. No ownership/status/cert/QR created by the paid webhook.
- **Pre-existing provenance untouched:** items=3 (2 original + test item 4), auth=4, cert=4, qr=3, status=6,
  claims=1; id1 CERTIFIED/normal/unowned, id3 REGISTERED/recovered/owner1 (baseline). Passports: item3 200, item4
  200. `POST_D1_FP = 3c51f3bea31835db7d4e9bdf7bd77aec` (migrations 120) — this provenance FP differs from the
  pre-Phase-4 baseline `c3fea71a` **solely** because of the Phase-4A test item; **Gate D1 itself added zero
  provenance rows** (only the Shopify-table receipt + sale-link, which are outside the provenance FP). All deltas
  isolated to the dedicated test item/order.
- **Receiver still fail-closed:** unsigned `POST /sca/shopify/webhook` → 401 (HMAC not weakened). Co-tenant
  smsrocket 302.

### Idempotency / redelivery — structural proof (active replay NOT safely possible → not improvised)
A live replay of the exact delivery is **not** safely possible: the receipt stores only a SHA-256 **digest, not the
raw body**, and there is no sanctioned replay endpoint — reconstructing a redelivery would require **fabricating a
payload and signing it with the webhook secret** (secret handling + payload fabrication), which the task forbids.
Per Gate D1's own rule, this is reported rather than improvised. Idempotency is guaranteed and evidenced instead by:
- `sca_shopify_webhook_receipts.idempotency_key` is **UNIQUE** (keyed on shop+topic+`X-Shopify-Webhook-Id`), and
  `WebhookController` runs domain processing **only for a newly-recorded receipt** → a duplicate delivery (same
  webhook id) is acknowledged without reprocessing.
- `sca_shopify_sale_links` has **UNIQUE `(shopify_shop_id, shopify_line_item_id)`** and **UNIQUE
  `webhook_idempotency_key`** → a duplicate paid for the same line cannot create a second sale-link/eligibility.
- Deployed `ShopifySaleLinkTest` covers duplicate-delivery idempotency + retry-after-500; and the current state
  (exactly 1 receipt, 1 sale-link) shows no duplication occurred for the real delivery.

**Gate D1 PASS.** Next: Gate D2 (claim via `ClaimWorkflow::claim` using the test item's QR token) — requires an
operator/collector browser step; Claude will give exact steps. No Phase 5; no further Shopify mutation by Claude.

## Gate D2 — preparation + baseline (claim NOT performed by Claude)
### D2 baseline (read-only; proves item 4 claimable-but-unclaimed)
- Test item 4: `lifecycle=CERTIFIED`, `registry=normal`, **`current_owner_collector_id=NULL` (unowned)**,
  active_qr_id 3, current_cert 4.
- Shopify sale-link for item 4: **1 row, `eligibility_state=eligible`** (order 8019293831455, line 18855278313759).
- Item 4 **ownership_events = 0**, **claims = 0** (no prior claim/ownership).
- Global baseline for later delta: collectors 2, claims_total 1, ownership_total 4, sale_links_total 1,
  receipts 1. `D2_BASELINE_FP = 3c51f3bea31835db7d4e9bdf7bd77aec`, migrations 120 (unchanged since D1).
- Claim entry live + gated: `GET /collector/claim/927e2d594775c21be67f91019b3648a9` → 302 (redirect to collector
  login when logged out; `collector.auth`). This is the canonical QR-path claim that calls
  `ClaimWorkflow::claim(token, collectorId)`.

### Operator / collector browser steps (operator performs; Claude does NOT claim)
Test data only; no real customer PII. Claim entitlement comes from the `eligible` Shopify sale-link (set at D1);
item 4's QR/passport token is `927e2d594775c21be67f91019b3648a9`.
1. **Register a NEW dedicated TEST collector** (do not reuse a real collector; collector 1 owns the real pilot
   item 3): https://verify.secondchanceauthenticators.com/collector/register — use a **test email you control** +
   a password. (Email is the collector identity — the only customer datum SCA stores; use a test mailbox.)
2. While signed in as that test collector, open the **claim URL** (same as scanning the physical QR then
   claiming): `https://verify.secondchanceauthenticators.com/collector/claim/927e2d594775c21be67f91019b3648a9`
   (If opened logged-out, you're redirected to login/register and returned here via `url.intended`.)
   (Passport preview, optional: `https://verify.secondchanceauthenticators.com/p/927e2d594775c21be67f91019b3648a9`.)
3. Review the item and **confirm the claim** (the Claim button → POST `collector.claim.perform`).
4. You should reach the success/result page ("added to your collection").
Then tell Claude **"claimed"**. Claude will run Gate D2 verification: ownership appended **exactly once** for item 4
→ the test collector, current-state resolves to that collector, the Shopify sale-link flips `eligible→claimed`
(entitlement retained as designed), no parallel/direct owner mutation, and a duplicate/repeat claim cannot create
duplicate ownership. Pre-existing items (id1, id3) must remain untouched.

STOP — awaiting the operator browser claim. Claude performs no claim, fabricates no request, and does not start
Phase 5.

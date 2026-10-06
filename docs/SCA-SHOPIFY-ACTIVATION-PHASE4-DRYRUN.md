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

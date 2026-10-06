# Shopify Operational Listing SOP — discovery + plan (PLAN ONLY)

**Date:** 2026-10-06 · **Status: DISCOVERY/PLAN ONLY. No implementation-repo, Shopify, production, or DB change.** · Deployed baseline `0f86b4a`, migrations **120**, FP `62b2e42f`. Promoted task; executable stage = DISCOVERY/PLAN ONLY. For ChatGPT audit. **Shopify Activation remains CLOSED — this does not reopen OAuth/webhook/scope.**

**Goal:** the safest practical workflow for listing/selling a real SCA-certified frame through Shopify while preserving the proven Shopify→SCA sale/claim linkage. **Headline: the receiver is production-proven and needs NO code; the only real risk is getting the correct `sca_item_ref` onto the order line item. Recommended = SOP + a tiny copy-to-clipboard helper (Option B).**

---

## 1. The exact `sca_item_ref` contract (verified, deployed)

- **Identifier:** the SCA **`public_ref`** (shape `/^SCA-[0-9A-Fa-f]{12}$/`), carried as a Shopify **line-item property** whose name is `config('sca-shopify.line_item_ref_property')` = **`sca_item_ref`** (default; `SaleLinkEventProcessor::extractRef`, `Config/shopify.php:42`). Config comment is explicit: "maps ONLY via this explicit reference — never brand/model/title/SKU/customer or other ambiguous metadata."
- **It is a line-item property — NOT sku, NOT a metafield, NOT product/variant data.** `product_id`/`variant_id` are recorded as pass-through columns only and are **never** used to resolve the SCA item; `metafield`/`sku` are not read anywhere in the Shopify package.
- **Resolution path (paid):** `WebhookController` (HMAC-verified, shop-checked, topic-allowlisted, record-then-process-only-if-new) → `SaleLinkEventProcessor::handlePaid` (per-line) → `SaleLinkService::linkPaidLine` → `normalizeRef` (trim, case-insensitive `SCA-`+12-hex, uppercased) → `resolveItem` (`public_ref` → `sca_eyewear_items.id`) → `assertEligible` (no current owner **and** no other active sale-link) → insert `eligibility_state='eligible'`.
- **Failure behavior (all fail-closed, per line):**
  | Case | Result |
  |---|---|
  | property missing | **safe skip** (`'skipped'`, no error, no sale-link) — ordinary non-SCA line |
  | malformed value (not `SCA-`+12hex) | `SCA_SALE_MAPPING_MALFORMED` → rejected, no sale-link |
  | multiple **distinct** `sca_item_ref` on one line | `SCA_SALE_MAPPING_AMBIGUOUS` (identical duplicates collapse) |
  | unknown `public_ref` | `SCA_SALE_ITEM_NOT_FOUND` |
  | item already owned, or a second active sale-link on the item | `SCA_SALE_ITEM_INELIGIBLE` (no double-sale) |
  | same (shop, line) already linked to a **different** item / unique race | `SCA_SALE_LINE_ITEM_CONFLICT` |
  | same (shop, line) already linked to the **same** item | idempotent `'exists'` (no new row) |
- **Independence + idempotency:** each `line_items[]` entry is processed independently; a `SaleLinkRejection` on one line never aborts siblings. HMAC-invalid/missing-secret → **401**, nothing recorded. Redelivery (same `X-Shopify-Webhook-Id`) → receipt `'duplicate'` → processing skipped; `UNIQUE(shopify_shop_id, shopify_line_item_id)` + `UNIQUE webhook_idempotency_key` + in-txn lock → a duplicate line cannot create a second sale-link. No raw body / no PII stored.
- **Quantity:** **not enforced in code** — `quantity` is never read; a qty>1 line still yields exactly **one** sale-link (one physical item). One-of-one qty-1 is an **operational** assumption that must be enforced on the Shopify side (inventory = 1).
- **Claim (collector-driven, unchanged):** an `eligible` sale-link lets the buyer claim via the existing QR/passport flow → one ownership `claim` event → item becomes owned/`REGISTERED`.

## 2. Where the property must be supplied (the real operational question)

Line-item properties attach at the **cart/checkout layer**, verified from the Phase-4 dry-run (`docs/SCA-SHOPIFY-ACTIVATION-PHASE4-DRYRUN.md`):
- The Shopify **Admin "Custom item" dialog does NOT expose line-item properties.**
- Creating a draft/order via the **Admin API requires `write_draft_orders`/`write_orders`** — **not granted** (app is `read_orders` only). **Granting them is out of scope** (would change scope / reopen activation).
- Therefore the property must come from **the storefront**: either (a) the product's **add-to-cart form emitting a hidden `properties[sca_item_ref]`** input (value per product), or (b) the **Storefront API / AJAX `/cart/add.js`** cart-line attributes (the dry-run proved option (b) with a hidden test product and `properties:{ sca_item_ref: '…' }`, qty 1, Bogus-gateway — no theme change, no scope change).

So, for **real inventory**, the choices to reliably attach the property are:
- **Self-service storefront:** a one-time **theme snippet** adding a hidden `properties[sca_item_ref]` input to the product-page add-to-cart form, with the value read per-product from a product **metafield** (e.g. `custom.sca_item_ref`) that staff set = the item's `public_ref`. (Metafield is storefront plumbing the theme copies into the line-item property — the SCA receiver never reads the metafield.) This is a **Shopify theme/config change**, product-scoped; no SCA code.
- **Assisted/concierge sale:** staff build the cart (AJAX `/cart/add.js` or Storefront API) with the property, then the buyer completes checkout — no theme change; suitable for one-of-one high-value pilot sales.

**Neither requires SCA application code.** The SCA receiver already consumes whatever arrives in the line-item property.

## 3. Current staff listing procedure

**None documented.** The capability is proven (dry-run) but there is no staff SOP, and `public_ref` is only shown (not one-click copyable) on the item-detail page ("SCA public reference" row + font-mono subtitle) and the printed QR label. Transcription of `public_ref` into the Shopify metafield/property is currently manual.

## 4. Failure behavior for missing/invalid/duplicate/wrong references (operational impact)

- **Missing / malformed / unknown** → no sale-link (fail-closed). The buyer cannot claim; the item **remains certified-unclaimed** (visible on the new staff dashboard's "Certified — unclaimed" tile) — catchable operationally.
- **Wrong-but-valid ref** (copied from the wrong item, or a typo that happens to match another real `public_ref`) → an `eligible` sale-link is created for the **wrong item** → the buyer could claim the wrong item. **This is the single most dangerous case** (it succeeds, silently, for the wrong item). Primary mitigation = **copy, never type**, from the correct item (Option B helper) + a before-publish value re-check against the physical item's QR.
- **Duplicate / already-owned / second sale** → `SCA_SALE_ITEM_INELIGIBLE` / `…CONFLICT` (fail-closed, no double-sale). Operationally: never relist a sold/owned item.
- **Quantity > 1** → one sale-link only; mismatch if more than one unit sold. Mitigation = inventory 1, one-of-one.

## 5. Inventory / quantity assumptions

One physical SCA frame = **one Shopify product/variant, inventory quantity 1, inventory tracked, overselling disabled, one-of-one**. The code does not enforce this; the SOP must.

## 6. Options compared

- **A — SOP only:** document the end-to-end procedure using existing Shopify + SCA interfaces (set the product's `sca_item_ref` source = the item's `public_ref`; verify via `/cart.js`; inventory 1; publish; post-sale verify the order's line-item property in Shopify Admin). **Zero SCA code.** Fully sufficient for correctness; the one weakness is manual transcription of `public_ref`.
- **B — SOP + copy helper:** A, plus a tiny **copy-to-clipboard** affordance beside `public_ref` on the SCA item-detail page so staff copy the exact value (no typos, right item). Directly mitigates the most dangerous failure (wrong/mistyped ref). The **only** justified SCA code: one view edit + small JS, read-only, existing `sca.eyewear.view` ACL, no schema.
- **C — more automation** (SCA→Shopify product/metafield sync or draft-order creation): **REJECT.** Requires write scopes / a new integration (reopens activation boundaries) and solves no safety gap that A/B cannot — the dangerous case is *human choice of the right item*, best mitigated by copy-from-the-right-item, not by automating product creation. Out of scope.

## 7. Recommendation — smallest complete solution = **Option B**

Document the SOP (Option A content) **and** add the one tiny copy-to-clipboard helper. Rationale: the receiver needs no code; the real residual risk is transcription of `public_ref`, and a copy button is the smallest change that materially reduces the wrong/mistyped-ref class. **Option A alone is defensible** if ChatGPT prefers zero code; the helper is the only code worth adding and is trivial/low-risk. **No automation.**

## 8. Is implementation code required at all?
**Not for correctness** — the receiver is production-proven and `public_ref` is already visible. The **only** code recommended is the optional **copy helper** (Option B). Everything else (theme snippet, product metafield, inventory=1, verification steps) is **Shopify-side configuration / staff procedure**, not SCA code.

## 9. If code is approved (Option B) — exact files / ACL / tests
- **Modified (1):** `packages/Sca/Registry/src/Resources/views/eyewear/show.blade.php` — a copy-to-clipboard button beside the "SCA public reference" value (small inline JS, progressive enhancement; the value remains selectable without JS).
- **New (1):** `tests/Feature/Sca/ShopifyListingRefCopyTest.php` (or extend an existing item-detail test) — assert the button + the exact `public_ref` value are present on item detail for `sca.eyewear.view` staff; assert no token/internal-id exposure; zero mutation.
- **ACL:** existing `sca.eyewear.view` (item-detail gate). No new key, no broadening.
- **No** controller/route/schema/migration/Shopify/receiver/ACL-definition change.

## 10. Proposed real-inventory pilot checklist (operator; ONE item; Shopify-side)
1. Choose **one** certified item with an active QR; **copy** its `public_ref` from item detail (Option B helper).
2. Create/choose its dedicated Shopify **product + single variant**; set **inventory = 1, tracked, oversell off**; one-of-one.
3. Wire `sca_item_ref`: set the product metafield (e.g. `custom.sca_item_ref`) = the copied `public_ref` **and** confirm the theme form emits `properties[sca_item_ref]` (self-service path) **or** prepare the assisted-cart snippet (concierge path).
4. **Verify before publish:** a test add-to-cart shows `/cart.js` line with `properties.sca_item_ref == SCA-…` (exact, uppercase-insensitive), `quantity: 1`; the value matches the physical item's QR/ref.
5. Complete a **test (Bogus-gateway)** checkout first (no real charge) → confirm the webhook created **one `eligible` sale-link** for that item and that a redelivery is idempotent (reuse the Phase-4 verification method). Then enable the real listing.
6. **After a real sale:** in Shopify Admin, open the order and confirm the **line-item property** `sca_item_ref=SCA-…` is present (Admin shows line-item properties on placed orders); confirm the buyer can claim; the item leaves the dashboard "Certified — unclaimed" tile once claimed.
7. Never relist a sold/owned item (fail-closed `INELIGIBLE`, but avoid operationally).

## 11. Explicit out-of-scope
No Shopify scope change / `read_products` / new app / webhook-topic / OAuth-callback / webhook-registration change; no mutation of the completed dry-run order/item; no claim/ownership/provenance-semantics change; no schema/migrations; **no Shopify product creation/sync automation**; **no bulk inventory onboarding (that is queue #5)**; no sale-link staff-visibility UI (separate potential future item, noted as a residual gap). The theme snippet / metafield / inventory settings are **Shopify-side operator configuration**, documented in the SOP, not SCA code.

## 12. Closure criteria for "Shopify Operational Listing SOP"
Closed when: (1) the SOP (§2–§10) is committed to governance and ChatGPT-audited; (2) if Option B approved, the copy helper is merged + deployed under the governed flow with full `tests/Feature/Sca` green and zero provenance mutation; (3) the real-inventory pilot checklist (§10) is available for the operator. A live real-inventory sale is **operator-gated** and may be a follow-on; executing one is not required to close the SOP itself (the mechanism is already dry-run-proven). Residual operational gap (no in-app sale-link visibility) is documented, not a blocker.

**DISCOVERY/PLAN ONLY — no code/Shopify/production/DB change performed.** See `docs/SCA-SHOPIFY-ACTIVATION-PHASE4-DRYRUN.md`, `TASK_QUEUE.md` (RECONCILED REMAINING WORK #3).

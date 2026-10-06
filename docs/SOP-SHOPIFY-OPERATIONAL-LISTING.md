# SOP — Listing an SCA-certified frame on Shopify (operator-facing)

**Audience:** Second Chance Authenticators staff who list/sell items on Shopify.
**Status:** operational procedure. The Shopify→SCA integration is live and CLOSED; this SOP uses it as-is. No one changes Shopify scopes, apps, OAuth, or webhooks.
**Baseline:** SCA app `0f86b4a`; store `second-chance-eyewear-accessories.myshopify.com`; API `2026-07`; scope `read_orders`.

---

## 1. The permanent contract (do not deviate)

| Thing | Value |
|---|---|
| Shopify **line-item property** name | **`sca_item_ref`** |
| Property **value** | the item's **SCA public reference (`public_ref`)** |
| Value shape | **`SCA-XXXXXXXXXXXX`** (the prefix `SCA-` + 12 hex characters) |
| Quantity per SCA line | **1** (one physical frame = one unit) |

- The SCA webhook links a paid Shopify order to the physical item **only** by reading the **`sca_item_ref` line-item property** and matching its value to an SCA `public_ref`. It does **not** read SKU, title, product/variant, or any metafield for this purpose.
- **Always COPY the `public_ref`, never type it.** A mistyped value fails safe (no link → the buyer cannot claim); a *valid but wrong* value would link the **wrong** item. Copying from the correct item's detail page eliminates both.

### Where to copy the value
Open the item in the SCA admin → **item detail** → the **"SCA public reference"** row has a **Copy** button (it copies the exact `public_ref`). The same value is printed on the item's QR label.

---

## 2. Operational flow (per item)

1. **Select the physical frame** and confirm it is **certified with an active QR** in SCA (only list sellable items).
2. **Copy its `public_ref`** from the SCA item-detail "SCA public reference" row (Copy button). Do not type it.
3. **Create/choose the dedicated Shopify product + single variant** for that exact physical frame (one-of-one). Set the variant **inventory = 1**, **inventory tracking ON**, **overselling disabled** (so it can sell only once).
4. **Make the storefront place `sca_item_ref` on the cart line** (see §3). The value must be the copied `public_ref`, exactly.
5. **Verify the cart line BEFORE publishing** (see §4) — the cart line must show `properties.sca_item_ref` = the exact `public_ref`, `quantity: 1`.
6. **Publish** the listing.
7. **After a sale:** open the order in Shopify Admin and confirm the **line item shows the property `sca_item_ref = SCA-…`** (Shopify Admin displays line-item properties on placed orders). The buyer then claims through the normal SCA QR/passport flow; once claimed, the item moves off the staff dashboard's "Certified — unclaimed" tile.

---

## 3. How the property gets onto the cart line (storefront mechanism)

Shopify line-item properties are attached at the **cart/checkout layer** — not from the Admin "Custom item" dialog (it cannot set line-item properties), and not via Admin order creation (that needs a write scope the SCA app deliberately does **not** have). Choose one storefront mechanism:

- **Self-service listings (normal customer checkout):** the product page's **add-to-cart form** must emit a **hidden `properties[sca_item_ref]` input** whose value is the item's `public_ref`. A common, convenient way to supply that value per product is a **product metafield** that a small theme snippet reads into the hidden input.
- **Assisted / concierge sale (one-of-one, staff-mediated):** staff build the cart with the property via the store's AJAX cart (`/cart/add.js` with `properties:{ sca_item_ref: '…' }`) or the Storefront API, then the buyer completes checkout. (This is the exact mechanism proven in the Phase-4 dry-run; no theme change.)

> **Metafield clarification (important).** The SCA integration does **NOT** consume any Shopify metafield. A metafield is **only one storefront convenience** for supplying the hidden `sca_item_ref` line-item property. If Jeremy's store adopts a standard metafield for this, treat it as a **storefront/theme convention, separate from the SCA integration contract**. A reasonable convention is a product metafield **`custom.sca_item_ref`** (single-line text) — but this key is a **recommendation to validate against the store/theme**, not a fixed SCA contract, and it must not be created/changed as part of this software task. The only contract the SCA receiver enforces is the **line-item property `sca_item_ref` = `public_ref`**.

Setting up the theme snippet / metafield / inventory is **operator Shopify-side configuration**. It is a one-time storefront change (per the self-service path) and is **outside** the SCA application.

---

## 4. Pre-publish verification (required; no test transaction needed)

The receiver mechanism is already proven (Phase-4 dry-run), so **a Bogus-Gateway test checkout is NOT required to close this SOP**. Before publishing a listing, confirm:

1. The **correct physical frame** is selected.
2. The **correct `public_ref` was copied** (from that frame's SCA item detail).
3. The **Shopify product/variant corresponds to that exact physical frame**.
4. Variant **inventory = 1**, **tracking enabled**, **overselling disabled**.
5. The **storefront/cart produces `properties.sca_item_ref` with the exact intended value** — verify by adding the product to a cart and checking `/cart.js` shows the line with `properties: { "sca_item_ref": "SCA-…" }`.
6. **Quantity = 1** on that line.

A **live real-inventory sale is an operator action, gated by the operator** — it is not part of this software task and not required to close this SOP.

---

## 5. What happens if the reference is wrong (fail-closed behavior)

| Situation | Result | What staff see / do |
|---|---|---|
| property **missing** on an SCA line | no sale-link (safe skip) | buyer can't claim; item stays "Certified — unclaimed" on the dashboard → fix the listing |
| value **malformed** (not `SCA-`+12 hex) | rejected, no sale-link | same as above |
| value is an **unknown** `public_ref` | rejected, no sale-link | same as above |
| **two different** `sca_item_ref` on one line | rejected (ambiguous) | put exactly one `sca_item_ref` per line |
| item **already owned**, or a **second** active sale-link on it | rejected (no double-sale) | never relist a sold/owned item |
| **valid but WRONG** `public_ref` (wrong item) | links the **wrong** item | **prevented by copy-from-the-right-item + §4 step 2/5**; this is the one case the system cannot catch for you |
| duplicate/redelivered webhook | idempotent (no second link) | nothing to do |

One physical frame = one product/variant, inventory 1, quantity 1. The code does not enforce quantity — **inventory = 1 is how you prevent overselling.**

---

## 6. Hard don'ts

Don't change Shopify scopes / add `read_products` or any write scope / create another app / change webhook topics, OAuth callback, or webhook registration. Don't put `sca_item_ref` on a multi-quantity line or on more than one line for the same item. Don't relist a sold item. Don't type the reference.

---

## 7. Related

SCA integration contract + code path: `docs/SCA-SHOPIFY-OPERATIONAL-LISTING-SOP-DISCOVERY.md`. Dry-run proof of the receiver: `docs/SCA-SHOPIFY-ACTIVATION-PHASE4-DRYRUN.md`. Copy affordance implementation evidence: `docs/SCA-SHOPIFY-OPERATIONAL-LISTING-IMPLEMENTATION.md`.

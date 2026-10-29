# SCA — First Real Order Assignment Eligibility Audit (READ-ONLY, local data only)

**VERDICT: NO suitable candidate exists in local data for a first Order→Eyewear Assignment.** The only
locally-identifiable sold order is refunded; every physical eyewear record is a test/demo item; and no
item↔variant link exists. A first assignment therefore requires prerequisites that are not present
locally and that need authoritative Shopify verification (separately authorized). Read-only inspection at
prod `eb137bf905758e7bfa2a9b13a2ce68384340c54f`; no Shopify API/`getOrder`/reconciliation, no DB write,
no customer PII inspected. 2026-10-29. **STOP.**

## [1] Production state
Live `/opt/sca-platform` = **`eb137bf`**, `main`, clean; loopback `/admin/login → 200`. Existing
assignment records: `sca_shopify_order_item_assignments` = **0 rows**.

## [2][3] Local Shopify order evidence — insufficient for an assignment
- **Webhook receipts** (`sca_shopify_webhook_receipts`): `orders/paid` **104**, `orders/cancelled` 4,
  `refunds/create` 2, `products/update` 1177, `products/create` 8, `products/delete` 1. **But the receipt
  table stores NO order id or line-item id** — only `shop_domain, topic, webhook_id, payload_sha256`
  (one-way digest) and processing-summary counts. So the 104 paid-order receipts are proof-of-delivery
  only; they **cannot supply a concrete `(order_id, line_item_id)`** for an assignment.
- **Sale links** (`sca_shopify_sale_links`): exactly **1 row**, state **`revoked_refund`** — item_id 4,
  shop `second-chance-eyewear-...myshopify.com`, order `8019293831455`, line `18855278313759`,
  product `10632814199071`, variant `52983511089439`. This is the ONLY local record carrying real order
  + line identifiers, and it is a **refunded** sale → ineligible (an assignment of a refunded line fails
  closed: `SCA_ASSIGN_LINE_REFUNDED`).
- **Conclusion:** the only locally-identifiable order is refunded; no other order/line ids exist in
  local data. Any genuine order's id/line/variant can be obtained only from the Shopify admin and
  verified via the authoritative read-only `getOrder` at assignment time — not performed here.

## [4] Physical eyewear records — all test/demo, none a real saleable candidate
| id | public_ref | brand / model | intake | owner | active QR | active sale link |
|---|---|---|---|---|---|---|
| 1 | `SCA-3C35D669ACBE` | **DEMO-DO-NOT-USE / SCA-DEMO-TEST-ITEM** | sce_presale | none (unowned) | yes (1) | none |
| 3 | `SCA-F1B792AE4745` | Ray-Ban / **PILOT-TEST** | external_intake | collector #1 (owned) | yes (1) | none |
| 4 | `SCA-A960A57D3124` | **SCA-SHOPIFY-DRYRUN / PHASE4-TEST-DO-NOT-SELL** | sce_presale | collector #3 (owned) | yes (1) | the refunded link above |
- Items 3 and 4 are **owned** → ineligible for a new sale link (sale ≠ ownership; an owned item is
  rejected). Item 4 is additionally tied to the refunded order and is explicitly flagged
  "DO-NOT-SELL".
- Item 1 is unowned with an active QR and no sale link — technically assignable — **but it is an explicit
  DEMO item ("DO-NOT-USE") with no associated paid order**, so it is not a real first-assignment candidate.
- There is **no real (non-demo/non-test) saleable pair** that is unowned, QR-active, and tied to a known
  paid order.

## [5] Catalog + variant links — no exact match available
- `sca_eyewear_item_shopify_variant` = **0 links** (no pair is linked to any Shopify variant).
- The refunded order's variant `52983511089439` and product `10632814199071` are **NOT in the catalog
  mirror** (0 matches in `sca_shopify_variants`/`sca_shopify_products`), despite 4574 products / 5344
  variants synced — so even that order could not be variant-matched.
- With 0 links, any assignment today would require the manager-override path regardless.

## [6] Matching discipline
No match was assumed from product name, model, SKU, or appearance. Findings rest only on exact
identifiers (order/line/product/variant ids) and record state (ownership, QR lifecycle, sale-link
state). No customer name/email/address was queried or disclosed (and the `order_email` column does not
exist on this production schema).

## [9] Candidate from local data alone? — NO
No paid, non-refunded, locally-identifiable order exists, and no real saleable eyewear record exists. The
one unowned item is a demo item with no order; the one order with local identifiers is refunded; there
are no variant links. **What would require later authoritative verification (separately authorized):** a
genuine order's paid/non-cancelled/non-refunded status, its exact line id, and its purchased variant —
all confirmed via the read-only `getOrder` at assignment time (not local data).

## [10] Missing prerequisites for a first genuine assignment
1. **A genuine paid, non-refunded, non-cancelled Shopify order** for a real SCE pair — its order id +
   line id + purchased variant come from the Shopify admin / authoritative `getOrder`, not local data.
2. **A real physical eyewear record** (not DEMO/DRYRUN/PILOT-TEST) that is **unowned**, has an **active
   QR Passport**, and corresponds to that order's purchased variant.
3. **An item↔variant link** for that pair (0 exist) — or an explicit **manager override + reason**.
> Per instruction, no test item was created and no order was fabricated to manufacture a candidate.

## [11] Recommended safe first operational test procedure (requires SEPARATE owner authorization)
1. **Owner selects a genuine recent order** in the Shopify admin: note its **order id**, the **line
   item** for the SCE pair, and the **purchased variant**; confirm it is paid and not refunded/cancelled.
2. **Identify the exact physical pair** that shipped (or will ship) for that line — a real SCA item that
   is unowned, certified, and has an active QR (verify on `/admin/sca/eyewear/{id}`, Certification & QR
   tab). If no such real item exists yet, it must first go through the normal intake →
   authenticate → certify → QR flow (separate, authorized work).
3. **Pre-link that pair to the purchased Shopify variant** via the item-detail Shopify catalog-link panel
   (enables the automatic variant-match safety) — **or** plan to use a **manager override + reason**.
4. **Under separate authorization**, perform ONE assignment at `/admin/sca/shopify/order-assign`: enter
   the order id → Look up (authoritative read-only `getOrder`) → select the line → enter the pair's
   `public_ref` → Assign. Confirm the append-only audit row and the QR-readiness message.
5. Verify afterward: a single `eligible` sale link for that `(shop,line)`, one assignment-audit row, and
   **no** new ownership/claim/QR/certification record. Follow the staff SOP
   (`SCA-SHOPIFY-ORDER-ASSIGNMENT-STAFF-SOP.md`).

All of step 1–5 is deferred: this audit only establishes that **no ready candidate exists in local data
today**.

**STOP — read-only eligibility audit complete. NO local candidate: the sole sale-linked order is
refunded, all eyewear records are test/demo (two owned), and there are no variant links. First assignment
is blocked on real operational prerequisites (a genuine paid order + a real unowned QR-active pair +
variant link or manager override), all requiring separately-authorized authoritative verification. No
Shopify API/store change, DB write, item creation, or order fabrication performed. SEPARATE OPEN: Phase-1
first genuine `products/*` webhook receipt verification.**

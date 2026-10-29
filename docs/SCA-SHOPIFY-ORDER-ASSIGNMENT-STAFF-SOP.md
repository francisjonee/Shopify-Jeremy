# SCA — Connecting Sold Glasses to a Shopify Order & QR Passport (Staff SOP)

**Written for:** SCA staff/operators (and Jeremy) doing fulfillment. Read-only verification at production
`eb137bf905758e7bfa2a9b13a2ce68384340c54f`; this document changes nothing. It is the standard procedure
for connecting a physical pair to the exact Shopify order it was sold on, and confirming its QR Passport
before packing. 2026-10-29.

## 0. What this procedure does (and does NOT do)
- It records **commerce evidence** — "this Shopify order line was fulfilled with THIS physical pair" — in
  SCA. It does **NOT** transfer ownership, create a customer claim, authenticate the item, or issue a
  QR/certificate. Ownership still happens later through the collector claim flow.
- Use it when a sold order did not already carry the pair's reference automatically (today that is every
  order — see §9 blockers). It is the staff complement to the automatic/reconcile paths.

## 1. The two admin interfaces (verified present & permission-gated)
| Interface | URL | Who can open | What it writes |
|---|---|---|---|
| **Eyewear item detail** (find the pair, its `public_ref`, QR status, and the Shopify-variant link panel) | `/admin/sca/eyewear/{id}` | `sca.eyewear.view` | — (read); the link panel writes only the SCA variant-link |
| **Shopify catalog link** (link a pair ↔ a Shopify variant) | panel on the item detail page; actions post to `/admin/sca/shopify/link` `/relink` `/unlink`; search `/admin/sca/shopify/catalog-search` | `sca.eyewear.shopify.link` | SCA variant-link table only |
| **Order → Eyewear Assignment** (bind a paid order line to the pair) | `/admin/sca/shopify/order-assign` (menu: **Shopify → Order → Eyewear Assignment**) | open: `sca.shopify.view`; submit: `sca.eyewear.shopify.order-assign`; no-variant-link override: `sca.eyewear.shopify.order-assign.override` | SCA sale-link + append-only assignment-audit only |
| **Shopify Operations** (observability: receipts, sale links, reconcile) | `/admin/sca/shopify/operations` | view: `sca.shopify.view`; reconcile: `sca.shopify.reconcile` | — (reconcile writes SCA sale-links only) |

Navigation: admin sidebar → **SCA Shopify Integration → Order → Eyewear Assignment** (and the item detail
is reached from **SCA Eyewear** list, or by scanning the pair's QR, see §3).

## 2. Before you start — gather two facts
1. **The Shopify order id** (digits), from the Shopify admin order page URL (`…/orders/<id>`). You do NOT
   paste order details into SCA — SCA re-reads the order itself (§7).
2. **The pair's `public_ref`** (`SCA-` + 12 hex), from SCA (§3).

## 3. How to find the pair's `public_ref`
- Open the pair in SCA: **SCA Eyewear** list → the item, i.e. `/admin/sca/eyewear/{id}`. The `public_ref`
  (`SCA-xxxxxxxxxxxx`) is shown in the page title/header and as a copyable field. **OR**
- **Scan the QR** on the physical pair: staff QR lookup (`POST /admin/sca/eyewear/lookup`, token in the
  request body — never in the URL or logs) resolves the scan to that item's detail page.
Copy the exact `public_ref` — it is the only accepted identifier (matching is never by brand/model/name).

## 4. Selecting the correct Shopify variant (no fuzzy name matching)
On the item detail page, the **Shopify catalog link** panel:
- Search the **synced local catalog** (product title / vendor / **SKU**) — this reads SCA's catalog
  mirror, it makes **no** Shopify API call.
- Pick the exact variant with **Select** (only *active* product+variant rows are selectable). The link is
  stored by the exact **Shopify variant id**, not by product name — so matching later is an exact-id
  check, never a fuzzy text match.
- One pair links to at most one variant; many pairs may share a variant (a SKU with quantity). Re-point
  with **Re-point link** (relink) or remove with **Unlink** — both audited; neither touches provenance.

**Why link the variant first:** at assignment time the system requires the pair's linked variant to equal
the variant actually purchased on the order line (exact id). Linking first gives you that automatic
safety check. If you skip it, the assignment needs a manager override (§6, §8).

## 5. Confirming the pair's QR Passport (for packing)
On the item detail page, **Certification & QR** tab:
- If an **SCA QR identity** is shown (permanent identity token + **Download printable QR (SVG)** /
  **Print QR label**), the pair has an active QR Passport — this is the QR that ships with it.
- If there is **no** QR identity, the pair has not been authenticated/certified yet — it must go through
  the normal authenticate → certify → QR flow before shipping; it is not ready to pack.
- The assignment confirmation (§6) also states QR readiness as a convenience ("QR ready for packing" vs
  "no active QR yet — authenticate/activate before shipping"). The QR token itself is never shown on the
  assignment screen.

## 6. Standard procedure — assign the order to the pair
1. (Recommended first) **Link the variant** for the pair (§4) if not already linked.
2. Open **Order → Eyewear Assignment** (`/admin/sca/shopify/order-assign`).
3. Enter the **Shopify order id** and **Look up order**. SCA fetches the authoritative order read-only and
   lists its lines with paid/cancelled/refunded status, the purchased variant, any existing binding.
4. On the correct line, enter the pair's **`public_ref`** and **Assign**.
5. SCA re-verifies the order authoritatively, enforces the variant-match (or the override, §8), and — if
   everything passes — records the binding and shows a confirmation including **QR availability**.
6. **Packing verification:** confirm the confirmation says the pair's QR is ready (or open the item's
   **Print QR label**), then pack that exact pair with that QR. Done.

## 7. SCA-record-only vs read-only Shopify API (nothing writes to Shopify)
- **Read-only Shopify API (read_orders scope):** the order lookup / assignment's authoritative
  `getOrder` (and the Operations *Reconcile* action). These only READ an order; they never modify Shopify.
- **SCA-record-only (no Shopify API):** catalog **search** (reads SCA's local mirror), **variant
  link/relink/unlink**, the **order assignment** write, and **QR label** views. These write only SCA
  tables.
- **No SCA action writes to the Shopify store** — no product/variant/inventory/order/customer/theme/
  webhook/OAuth/setting change, ever. Background webhook processing is unaffected.

## 8. Handling the tricky cases (all fail closed — no wrong binding)
| Situation | What happens | What staff do |
|---|---|---|
| **Variant mismatch** (pair's linked variant ≠ purchased variant) | Rejected `SCA_ASSIGN_VARIANT_MISMATCH`; nothing bound | Re-check you picked the right pair/line; fix the variant link if wrong |
| **Missing variant link** (pair not linked to any variant) | Rejected `SCA_ASSIGN_NO_VARIANT_LINK` unless a **manager** (holding `…order-assign.override`) supplies the override checkbox **and a reason** | Either link the variant first (§4, preferred), or have a manager override with a recorded reason |
| **Already assigned — same pair, same line** | Idempotent "exists"; one link, no duplicate | Nothing — it's already correct |
| **Already assigned — different pair on that line** | Rejected `SCA_SALE_LINE_ITEM_CONFLICT`; original binding unchanged | Investigate which pair truly shipped; a binding is never silently overwritten |
| **Pair already owned / already actively sold** | Rejected (ineligible) | That pair can't be re-sold; pick the correct unsold pair |
| **Order cancelled** | Rejected `SCA_ASSIGN_ORDER_CANCELLED` | Do not assign a cancelled order |
| **Line refunded** | Rejected `SCA_ASSIGN_LINE_REFUNDED` | Do not assign a refunded line |
| **Order not paid** | Rejected `SCA_ASSIGN_ORDER_UNPAID` | Wait until the order is paid |
| **Ambiguous / bad reference** | Bad `public_ref` shape → `SCA_ASSIGN_BAD_REF`; unknown pair → `SCA_ASSIGN_ITEM_NOT_FOUND`; order/line not found authoritatively → `SCA_ASSIGN_LINE_NOT_IN_ORDER` / Shopify error | Re-copy the exact `public_ref` and order id |

Every attempt (success or rejection) is written to the **append-only** assignment audit (actor, order,
line, pair, decision, reason) — it cannot be edited or deleted.

## 9. Administrator sufficiency vs restricted roles
- **For the first, controlled assignments:** the existing **Administrator** account is **sufficient** — it
  holds all required permissions (`sca.eyewear.view`, `sca.eyewear.shopify.link`,
  `sca.eyewear.shopify.order-assign`, and `…order-assign.override`).
- **Before wider rollout (recommended):** create restricted roles so the manager-override gate is
  meaningful — e.g. an **Operator** role with `sca.eyewear.shopify.link` + `sca.eyewear.shopify.order-assign`
  **but not** the override, and a **Manager** role that adds `…order-assign.override`. With a single
  all-powerful Administrator the override offers no separation of duties. (Role setup is standard Krayin
  admin configuration; not required to begin.)

## 10. Remaining blockers / prerequisites before the first genuine assignment
- **No code/deployment blockers.** The feature is live, routed, permission-gated, and error-free; the
  assignment-audit table exists (empty) with append-only protection.
- **Operational prerequisites (not code issues):**
  1. **No variant links exist in production yet (0).** For a clean, safety-checked first assignment,
     **link the pair to its Shopify variant first** (§4). Otherwise a **manager override + reason** is
     required for that assignment.
  2. Have the **Shopify order id** (from Shopify admin) and the pair's **`public_ref`** ready.
  3. The pair must be **unsold/unowned** (an owned or already-sold pair is ineligible).
  4. For packing, the pair should already have an **active QR Passport** (§5); if not, run the normal
     authenticate → certify → QR flow first.
- **Recommended for first use:** do one end-to-end dry run with the Administrator on a single real order —
  link the variant, assign, and confirm the audit row + QR readiness — before handing the procedure to
  additional staff.

**STOP — read-only SOP recorded. No Shopify API request, store change, DB write, test assignment, variant
link, QR/claim/ownership/certification change, or code/deploy was performed. The interface is ready; the
only prerequisites are operational (link variants or use manager override; have order id + public_ref;
optionally create restricted roles). SEPARATE OPEN: Phase-1 first genuine `products/*` webhook receipt
verification.**

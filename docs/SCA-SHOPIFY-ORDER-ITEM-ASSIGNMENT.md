# SCA — Shopify Staff Order-to-Physical-Eyewear Assignment (Implementation)

**Authorized development task. DONE on a dev branch off production `5bed316` (R0/R0b/R0c excluded).**
Lets authorized staff bind a paid Shopify order line to the exact physical eyewear pair before
fulfillment — the human-authoritative complement to read-only reconcile, for orders the storefront did
not stamp with `sca_item_ref` (per the matching audit: 104 paid orders → 0 active sale links). Order
facts are verified against the authoritative Shopify order, never staff-entered. The binding is written
only through the existing `SaleLinkService`. Static checks PASS (`php -l` clean on all files; Blade
balanced). DB-backed tests are WRITTEN but NOT run (no disposable-DB authorization in this task). No
production migration/merge/deploy, no live Shopify modification, no ownership/QR/claim change. 2026-10-29.
**STOP for review.**

## SHA & branch
- Branch `feat/sca-shopify-order-item-assignment` off prod `5bed316` → head
  **`c37592b7633f68e81453824be235ab5471c0d4c4`** (pushed to origin = impl repo). Live checkout
  untouched (`5bed316`, `main`, clean; loopback 200). **Excludes R0/R0b/R0c** (base is prod, not main).
- 9 files: 6 new, 3 modified. **1 additive migration.** All within `packages/Sca/Shopify` + tests.

## What it does (objectives 3–14)
- **[3] Lookup + select:** `GET /admin/sca/shopify/order-assign` (ACL `sca.shopify.view`) shows a
  lookup-by-order-id form; for a staff member who can assign, it fetches ONE authoritative order
  read-only (`ShopifyClient::getOrder`) and lists its lines with paid/cancelled/refunded status, the
  purchased variant, any storefront `sca_item_ref`, and any existing binding — for selection.
  (Store-wide order browsing is intentionally out of scope; lookup is by the Shopify order id, as with
  reconcile. The order id comes from the Shopify admin.)
- **[4] Select the pair by `public_ref`:** staff enter the exact pair's `public_ref`
  (`^SCA-[0-9A-Fa-f]{12}$`); it is resolved to one `sca_eyewear_items` row — never variant/SKU/title.
- **[5] Verified against trusted Shopify data:** `OrderItemAssignmentService` re-fetches the order
  authoritatively and reads paid/cancelled/refunded/line/variant ONLY from that response. The POST
  carries no order-status fields; nothing about eligibility is trusted from the form.
- **[6] Reject ineligible orders (fail closed):** cancelled → `SCA_ASSIGN_ORDER_CANCELLED`; refunded
  line → `SCA_ASSIGN_LINE_REFUNDED`; unpaid → `SCA_ASSIGN_ORDER_UNPAID`; line not in the authoritative
  order → `SCA_ASSIGN_LINE_NOT_IN_ORDER`; unknown item → `SCA_ASSIGN_ITEM_NOT_FOUND`; malformed ref →
  `SCA_ASSIGN_BAD_REF`; Shopify fetch failure → the safe `SHOPIFY_*` code. No sale link in any case.
- **[7] Exact identity:** the configured shop (host-locked client + expected-domain config), the exact
  `(shop, line)` pair, and the exact physical item by unique `public_ref`.
- **[8] Variant-link match required:** if the item has a Phase-2 `sca_eyewear_item_shopify_variant`
  link, it MUST equal the purchased line's variant (and shop) → else `SCA_ASSIGN_VARIANT_MISMATCH`,
  fail closed.
- **[9] No variant link → manager exception:** if the item has no variant link, the assignment is
  refused (`SCA_ASSIGN_NO_VARIANT_LINK`) UNLESS the request carries an explicit override AND the actor
  holds the manager ACL `sca.eyewear.shopify.order-assign.override` AND a non-empty reason — never
  silently accepted. The reason is recorded.
- **[10] Reuse `SaleLinkService::linkPaidLine`:** the binding is written only through it, inheriting
  its idempotency (`UNIQUE(shop,line)` + key), row locking, never-rebind (`SCA_SALE_LINE_ITEM_CONFLICT`),
  one-active-per-item eligibility, already-owned rejection (sale ≠ ownership), and refund/cancel rules.
  The service invents no parallel writer.
- **[11] Dedicated ACL:** `sca.eyewear.shopify.order-assign` (mutation, separate from view/reconcile/
  link) + the manager `…​.order-assign.override`. Server-enforced via `sca.can` route middleware + the
  controller override check.
- **[12] Append-only audit:** every attempt (assigned or rejected) appends one immutable row to
  `sca_shopify_order_item_assignments` (actor, shop, order id, line id, purchased variant, item id +
  `public_ref` snapshot, resulting sale-link id, action, variant-match decision, override reason,
  outcome code, timestamp). Immutability is DB-enforced (BEFORE UPDATE/DELETE triggers → SQLSTATE 45000).
- **[13] QR availability for packing:** the result surfaces whether the bound item has an ACTIVE QR
  (`ProjectionService::activeQrIdentifier`) and its production flag — **never the token**, and it
  creates no QR.
- **[14] Preserves provenance:** no authentication, certification, ownership, claim, collector, or QR
  record is created or changed (a disposable-DB test asserts the provenance counts are unchanged).

## Files
- NEW `Services/OrderItemAssignmentService.php` — the gate + binding + audit logic.
- NEW `Http/Controllers/OrderAssignmentController.php` — view/lookup + assign action.
- NEW `Resources/views/order-assign.blade.php` — staff screen (no token/PII rendered).
- NEW `Models/OrderItemAssignment.php` — append-only audit model.
- NEW `Database/Migrations/2026_10_31_000001_create_sca_shopify_order_item_assignments.php`.
- MOD `Routes/admin-routes.php` (+GET order-assign, +POST order-assign.store), `Config/acl.php` (+2
  ACLs), `Config/menu.php` (+1 entry).
- NEW `tests/Feature/Sca/ShopifyOrderItemAssignmentTest.php` (16 tests, written, NOT run).

## [16] Required migrations, operational workflow, rollback
- **Migration (additive, 1):** `2026_10_31_000001_create_sca_shopify_order_item_assignments` — a new
  append-only audit table + 2 triggers. It adds no column to any existing table and alters no existing
  schema, so it is safe to apply ahead of code (migrate-before-code) and is forward-only in effect.
  **Reversible:** `down()` drops the triggers then the table.
- **Operational workflow:** (1) Jeremy's staff open *Shopify → Order → Eyewear Assignment*; (2) paste
  the paid order's Shopify id and look it up; (3) for the correct line, enter the physical pair's
  `public_ref`; (4) submit — the system re-verifies the order authoritatively, enforces the
  variant-link match (or a manager override + reason when there is no variant link), and binds the line
  via `SaleLinkService`; (5) the confirmation states QR availability for packing. The assignment records
  commerce evidence only; ownership still happens through the existing claim path.
- **Rollback:** code — drop the branch / revert; nothing deployed. Schema (if ever deployed and rolled
  back) — the migration's `down()` removes the audit table + triggers; because the actual bindings live
  in `sca_shopify_sale_links` (unchanged by this feature) and the audit table is additive, removing it
  loses only the audit log, not any sale link. A specific erroneous binding is corrected through the
  existing sale-link revoke/cancel paths (not by editing the append-only audit).

## Tests to run under the next authorized disposable-DB session
`ShopifyOrderItemAssignmentTest` (hard-guarded to `sca_domain_test`, `DatabaseTransactions`, mocks the
Shopify API via `Http::fake`): variant-matched bind + audit; variant mismatch fail-closed; no-variant-
link requires manager override + reason (and refused without the ACL / without a reason); duplicate →
idempotent `exists`; different-item same-line → `SCA_SALE_LINE_ITEM_CONFLICT`; cancelled/refunded/unpaid
fail-closed; line-not-in-order + unknown-item + bad-ref + fetch-error fail-closed; QR availability
surfaced without the token; QR-active true/production; HTTP ACL separation (view/assign/override);
append-only audit (UPDATE/DELETE rejected); provenance counts unchanged.

## Safety / scope
Dev branch only; prod `5bed316` + live bind-mount untouched; no migration run; no live Shopify
modification; `read_orders`/`read_products` scopes unchanged (no new scope — order + refunds come from
the already-granted `read_orders`); no ownership/QR/cert/claim/email change; R0/R0b/R0c excluded; no
Option-C.

**STOP — implemented on a dev branch (`c37592b`). NEXT (separate auth): a disposable-DB session to run
`ShopifyOrderItemAssignmentTest`, then code-only merge review + a controlled deployment (the 1 additive
migration is migrate-before-code). SEPARATE OPEN: Phase-1 first genuine `products/*` webhook receipt
verification.**

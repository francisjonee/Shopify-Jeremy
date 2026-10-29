# SCA — Shopify Sale → Physical-Eyewear Matching Audit (READ-ONLY)

**How a completed Second Chance Eyewear Shopify order is connected to the exact physical pair the
customer bought — and why, in production today, it effectively is NOT.** Read-only inspection at prod
`5bed316` (live working tree). No code/DB/Shopify/config change. 2026-10-29.

## TL;DR
- **The only matching key is a line-item property `sca_item_ref` carrying the pair's `public_ref`
  (`SCA-`+12 hex).** `SaleLinkService` maps that one value to exactly one physical item. There is NO
  matching by variant / SKU / product / title / brand / model / customer — by design.
- **Production evidence of the gap:** the store has delivered **104 `orders/paid` webhooks** (and
  4 cancelled, 2 refunds, 870 product updates — the receiver works and is recording), yet there is
  **exactly 1 sale link in the whole database, and it is `revoked_refund` (0 active).** That means
  essentially none of the 104 paid orders carried an `sca_item_ref` property, so each was a safe
  "skipped — no sca_item_ref" no-op. **The mechanism is sound but inert: real orders are not
  identifying a physical pair.**
- **Nothing lets staff bind an order line to a specific pair.** The staff tools are (a) read-only
  *reconcile* (re-reads the same property from the authoritative order — it cannot create a binding
  the property doesn't already assert) and (b) item↔**variant** linking (a catalog-SKU reference,
  not an order binding). Neither connects a specific physical pair to a specific order before
  fulfillment.
- **Smallest safe fix (recommended):** a staff-driven, audited *bind order-line → public_ref* action
  that feeds the EXISTING `SaleLinkService` invariants (one-active, never-rebind, sale≠ownership,
  fail-closed) — a backend fallback for when the storefront did not inject the property. (The
  storefront property-injection itself is out of SCA's codebase / out of scope under the "no Shopify
  modifications" limit.)

## [1][2] Order processing + how a line identifies a physical record
Two code paths, ONE domain writer (`Sca\Provenance\SaleLinkService`), identical mapping rule:
1. **Webhook (automatic):** `WebhookController` verifies HMAC over the raw body → enforces the
   expected shop → topic allowlist (`orders/paid`, `orders/cancelled`, `refunds/create`, plus the
   `products/*` catalog topics) → idempotent receipt → for a NEW receipt, order/refund topics drive
   `SaleLinkEventProcessor`.
2. **Reconcile (staff, read-only):** `ShopifyReconciliationService` fetches ONE authoritative order
   via the read-only `ShopifyClient::getOrder`, normalizes it with `AuthoritativeOrder`, and feeds
   the SAME `SaleLinkService`.

**Identification rule (both paths):** for each order line, read the configured line-item property
`sca_item_ref` (`config('sca-shopify.line_item_ref_property')`, env `SHOPIFY_LINE_ITEM_REF_PROPERTY`,
default `sca_item_ref`). Its value must match the strict shape `^SCA-[0-9A-Fa-f]{12}$`; it is resolved
to exactly one row via `sca_eyewear_items.public_ref`. No fuzzy or metadata matching exists. A line
with no such property is a deliberate no-op ("ordinary non-SCA order").

## [3] public_ref matching + its operational requirements
`public_ref` is the SCA-controlled, opaque per-pair identifier. For the automatic path to bind a sale
to a pair, **the Shopify order line must already carry `properties: [{name:"sca_item_ref",
value:"SCA-xxxxxxxxxxxx"}]`** — i.e. the storefront/cart must attach the exact pair's `public_ref` as
a line-item property at purchase time. Operational prerequisites:
- The storefront (theme / product page / cart) must inject the specific pair's `public_ref` per
  purchase. **This injection does not exist in the SCA backend repo** (SCA is the CRM/receiver side);
  it would be a Shopify storefront change. **Prod proof it is absent: 104 paid orders → 0 surviving
  sale links.**
- `SHOPIFY_SCOPES=read_orders,read_products` (confirmed) — sufficient to read orders + the property.
- The order webhook subscriptions must exist in Shopify. **There is no webhook self-registration in
  the code** (no GraphQL `webhookSubscriptionCreate` etc.), yet 104 `orders/paid` receipts prove the
  subscriptions ARE active — so topic subscription is managed manually/externally in the Shopify app
  config, not by SCA. (Relatedly, the separate "first genuine `products/*` webhook verification" task
  remains open; product topics are clearly arriving — 870 `products/update` — but that task tracks a
  first *organic* delivery confirmation.)

## [4] Multiple physical pairs sharing one Shopify variant
- **Sale matching never uses the variant.** `SaleLinkService` resolves solely by `public_ref`, so N
  pairs sharing one variant/SKU is irrelevant to matching — each pair is uniquely addressed by its
  own `public_ref`.
- The Phase-2 link table `sca_eyewear_item_shopify_variant` is explicitly **many-items → one-variant**
  (`UNIQUE(eyewear_item_id)`, non-unique `(shop, variant)`), a staff *reference* join only. Its own
  header documents that one variant is a SKU with quantity while each physical pair is its own SCA
  identity. **It is not consulted by the matcher** (and must not be — a variant alone is ambiguous
  across pairs). Prod: 0 variant links (dormant).
- The only ambiguity the matcher recognises is MULTIPLE DIFFERING `sca_item_ref` values on ONE line →
  `SCA_SALE_MAPPING_AMBIGUOUS`, fail-closed (no guess).

## [5] Can staff assign the correct pair before fulfillment? — NO
- Staff routes (`/admin/shopify/...`): `reconcile` (ACL `sca.shopify.reconcile`) and
  `link`/`relink`/`unlink` + `catalog-search` (ACL `sca.eyewear.shopify.link`).
- `reconcile` is **read-only convergence**: it re-reads the authoritative order and applies the SAME
  property rule. It **cannot create a binding when the order carries no `sca_item_ref`** — staff never
  type a ref there (by explicit design: "staff never type a ref to bind").
- `link/relink/unlink` bind a physical item to a catalog **variant** (a SKU reference), **not to an
  order or a sale**. Linking a pair to a variant does not sell it or bind any order.
- **There is no route/service/UI that binds a specific physical pair to a specific order line.** So if
  the storefront did not stamp the property, there is currently no supported way for Jeremy's staff to
  record "this order bought THIS pair." This is the central missing workflow.

## [6] Missing steps to attach the correct QR Passport to a shipment
- QR Passport identity is minted in the authentication→certification flow (separate from commerce);
  a sale link carries no QR and triggers no QR/cert/ownership action (sale ≠ provenance).
- There is **no fulfillment-facing step** that, given a paid order, tells the packer which physical
  pair + which QR Passport to put in the box, nor any record tying the shipped QR to the order. The
  chain order → pair exists only if `sca_item_ref` was set; and even then nothing surfaces the pair's
  QR to a fulfillment view. Missing: (a) a reliable order→pair binding (see [5]/[8]); (b) a
  staff/fulfillment view that resolves a bound order to its pair + active QR for packing; (c)
  (optional) a post-ship record. None mutate provenance — all read-only/reference.

## [7] Duplicate-sale / refund / cancellation / incorrect-pair protections — STRONG
Present and verified in `SaleLinkService` + processors:
- **Duplicate sale:** `UNIQUE(shopify_shop_id, shopify_line_item_id)` + a unique
  `webhook_idempotency_key` + `lockForUpdate` + unique-violation convergence → a replayed/raced
  delivery yields `exists`, never a second link. Webhook receipts are themselves idempotent
  (shop+topic+webhook-id), so a redelivery doesn't reprocess.
- **One pair, one active sale:** `assertEligible` rejects a new link if the item already has an active
  link on a different line (`SCA_SALE_ITEM_INELIGIBLE`) — no double-sale of one physical pair.
- **Never rebind:** an existing (shop,line) bound to a different item → `SCA_SALE_LINE_ITEM_CONFLICT`.
- **Cancellation/refund:** deterministic revoke to `cancelled` / `revoked_refund`; `cancelLine` writes
  a `cancelled` TOMBSTONE when no prior link exists so a later out-of-order `paid` converges to
  cancelled instead of going live; revocation is a no-op once terminal; history is preserved; a
  refund/cancel **never changes ownership** (delegated to `CommerceService`, which disputes if owned).
  Refund/cancel after a prior sale cannot restore eligibility.
- **Sale ≠ ownership:** an already-owned item is ineligible for a fresh sale link; the service creates
  no collector/ownership/claim/transfer and rebuilds no owner projection.
- **Incorrect-pair RESIDUAL (the one real weakness):** the matcher trusts the `sca_item_ref` VALUE. It
  validates shape + existence + eligibility, but does **not** verify that the referenced pair actually
  corresponds to the purchased product/variant. A wrong `public_ref` in the property (storefront or
  human error) would bind the sale to the wrong — but still valid and eligible — pair. There is no
  cross-check against the purchased variant (e.g. via the Phase-2 variant link) today.

## [8] Smallest safe implementation to connect each order to exactly one pair
**Recommended slice — "Staff order-line → pair binding" (backend fallback), dev-branch, additive:**
A staff-only, ACL-gated, audited action that, given `(shop, order_id, line_id)` from an authoritative
read-only `getOrder` fetch AND a staff-selected pair `public_ref`, calls the EXISTING
`SaleLinkService::linkPaidLine` with that ref. This:
- reuses every invariant in [7] unchanged (one-active, never-rebind, idempotent, eligibility,
  sale≠ownership, fail-closed); binds the exact line, not a variant;
- fills the [5] gap for orders where the storefront did not stamp `sca_item_ref`, without weakening the
  automatic path or inventing a parallel writer;
- should **cross-check** the selected pair against the order line's purchased variant via the Phase-2
  `sca_eyewear_item_shopify_variant` link (warn/block on mismatch) to close the [7] incorrect-pair
  residual;
- is independently testable on a disposable DB; adds at most one audit table + one ACL + one staff
  screen; no provenance/ownership/QR/cert change.

**Preferred long-term complement (NOT this slice, outside SCA code):** have the storefront inject the
specific pair's `public_ref` as the `sca_item_ref` line-item property at purchase, so the automatic
webhook path binds with no staff step. That is a Shopify storefront change (excluded here by the "no
Shopify modifications" limit) and should be tracked separately. A fulfillment view resolving a bound
order → pair → active QR ([6]) is a further read-only slice.

## [9] Existing safeguards preserved
This audit changed nothing. All ownership, authentication, certification, and QR invariants are
untouched; the recommended slice is explicitly additive and routes through the existing sale-link
writer, which never creates provenance.

## Production state at audit time (`sca_krayin`, batch 29)
- Sale links: **1 total, `revoked_refund`** (0 active). Items: 3 (`external_intake` 1, `sce_presale`
  2). Variant links: **0**. Catalog mirror: 4572 products / 5342 variants. Shopify webhook receipts:
  **`orders/paid` 104**, `orders/cancelled` 4, `refunds/create` 2, `products/update` 870,
  `products/create` 7, `products/delete` 1. Shopify credentials row: 1.

**STOP — read-only audit delivered. Matching is by `sca_item_ref` → `public_ref` only; it is correct
and well-protected but INERT in production because real orders don't carry the property and there is
no staff order→pair binding. Recommended smallest safe next task: the staff order-line→pair binding
(additive, reuses SaleLinkService). No code/DB/Shopify/claim/ownership/email change made. SEPARATE
OPEN: Phase-1 first genuine `products/*` webhook receipt verification.**

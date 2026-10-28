# SCA — Shopify Phase 2: Product→Physical-Eyewear Linking — Audit & Plan (READ-ONLY)

**Read-only planning only — no code, DB change, deploy, Shopify change, or production activation.** 2026-10-28. **STOP for review.** (The pending **first-genuine-product-webhook verification** from Phase 1 remains a separate open task — see `docs/SCA-SHOPIFY-INVENTORY-SYNC-ACTIVATION-VERIFICATION.md`; Phase 2 does not touch or close it.)

Written for: the owner and the ChatGPT reviewer.

## 1. Audit of existing systems (what Phase 2 builds on)

| System | State (reuse) |
|---|---|
| Physical intake | `ItemService::create(array $attrs)` (Provenance) — sole canonical creator: one `sca_eyewear_items` row (`public_ref` via `Token::publicRef()`, `intake_type`) + one `INTAKE/normal` projection in `sca_item_current_state`, in a txn. No auth/cert/QR/ownership. |
| Staff manual intake UI | `EyewearItemController` (ACL `sca.eyewear.create`): `GET create` form → `POST store` (`StoreEyewearItemRequest`). Fields: `brand`(req), `model_name`(req), `frame_serial`, `intake_type` ∈ {`sce_presale`,`external_intake`}, `year`, `country_of_origin`, `materials`, `original_specifications`. |
| Bulk intake | `InventoryImportService` — one item per CSV row via `ItemService::create`, append-only ledger idempotency. |
| Catalog (Phase 1) | `sca_shopify_products` (4565) + `sca_shopify_variants` (5330); `ProductCatalogService` sole writer; catalog-only (never creates items/passports). Variant carries `sku,title,option_values,price,inventory_quantity,status`. **No product images/metafields synced in Phase 1.** |
| Auth → Cert → QR → Ownership chain | `AuthenticationService` → `CertificationService` (+ `CertificateSnapshotService`) → `QrService` (QR Ownership Passport) → ownership (`ClaimService`/`TransferService`/`OwnershipCorrectionService`), projected by `ProjectionService`. External-paid intake path: `SubmissionService`/`CustodyAcceptanceService`. **Phase 2 changes none of these.** |
| Existing eyewear↔Shopify link | **None** (no column, no table) — clean slate. |

## 2. Design — a safe variant↔physical-item relationship

**New additive table `sca_eyewear_item_shopify_variant`** (a dedicated, auditable join; the link lives here, NOT as item provenance):
- `id`; `eyewear_item_id` → `sca_eyewear_items.id` **UNIQUE** (a physical item links to at most one variant); `shop_domain`; `shopify_product_id`; `shopify_variant_id`; `linked_by` (staff user id); `linked_at`; optional `variant_sku_snapshot`/`variant_title_snapshot` (audit of what was linked); `created_at`/`updated_at`.
- **Index** `(shop_domain, shopify_variant_id)` — **not unique** → many items per variant.
- No FK into the catalog tables' business keys beyond by-value (catalog rows may be soft-archived; the link must survive). The link references a variant by id; the service validates the variant exists/active at link time.

**New sole-writer service `ShopifyProductLinkService`** (the only writer of this table): `link(itemId, shopDomain, productId, variantId, staffId)` — validates item exists, variant exists in catalog and is `active`, and no link exists for that item (UNIQUE); writes the row in a transaction. `unlink`/`relink` are explicit, ACL-gated, audited corrections. The service never creates an item and never touches auth/cert/QR/ownership.

## 3. Multiple physical pairs per one Shopify variant — supported

A Shopify variant is a catalog SKU with a quantity; each physical pair is a distinct `sca_eyewear_items` row with its own `public_ref`. The join is **1 variant → N items** (unique on `eyewear_item_id`, not on `shopify_variant_id`), so staff individuate as many physical pairs as exist for a variant, each with its own SCA identity, authentication, and QR passport. The variant's `inventory_quantity` is **advisory only** — never the count of SCA items.

## 4. No duplicate physical-item registration; history preserved

- **Not a "duplicate":** two *different* physical pairs linked to the same variant is intended (§3), not a duplicate.
- **Guarded against:** (a) linking the *same* item to a second variant — blocked by `UNIQUE(eyewear_item_id)`; (b) accidental double-submit of one intake action creating two items — guarded by a per-submit idempotency token (mirrors the import ledger's one-row-per-source discipline); (c) re-linking is explicit and audited, never silent.
- **History preserved by construction:** the link table is additive and orthogonal — creating/linking/unlinking writes only the join row; it never mutates `sca_ownership_events`, authentication, certification, QR, or projection rows. Unlinking removes only the join row (optionally soft, audited), never provenance.

## 5. Staff workflow (intake with Shopify selection)

Extend the existing `sca.eyewear.create` manual intake (optional Shopify step; manual-without-Shopify still works):
1. On the create form, an optional **"Link to Shopify product"** control: staff search **active** `sca_shopify_products` (by title/vendor/sku) → select a product → select one of its **active** variants (`sca_shopify_variants`).
2. The selection **prefills** the physical fields it can (see §6); staff complete the remaining physical-only fields (`frame_serial`, `year`, etc.) and pick `intake_type`.
3. On submit, in **one transaction**: `ItemService::create($attrs)` (the unchanged canonical creator) **then** `ShopifyProductLinkService::link(...)`. One staff action → one physical item → one link.
4. Also allow linking/unlinking from an existing item's detail page (ACL-gated) for items created before a product was synced.
5. The linked item then proceeds through the **existing** auth → cert → QR passport → ownership flow unchanged; the Shopify reference is shown for staff context and never triggers authentication.

## 6. What product info populates the individual eyewear record

From the Phase-1 catalog (basic fields only — no metafields/images synced yet), prefilled and **staff-editable**:
- `brand` ← product `vendor`
- `model_name` ← product `title` (optionally suffixed with the variant's `option_values`)
- `sku` ← variant `sku`
- `year`, `country_of_origin`, `materials`, `original_specifications`, `frame_serial` → **staff-entered** (not in the catalog).
- Image → staff-uploaded as today (Phase-1 did not sync product images; a later slice could).

The authoritative Shopify reference (`shopify_product_id`/`shopify_variant_id`) lives in the **link table**; the item's `brand/model/sku` are editable copies, so correcting an item never rewrites the catalog and vice-versa.

## 7. Catalog-sync-never-creates-physical-eyewear invariant — preserved and enforced

Catalog sync (`ProductCatalogService`, `ProductSyncEventProcessor`, importer, reconcile) continues to write **only** the catalog tables and **never** calls `ItemService` or `ShopifyProductLinkService`. Physical-item creation and linking happen **only** via staff intake (ACL `sca.eyewear.create`, plus a new `sca.eyewear.shopify.link` for link/unlink). A product webhook or import can **never** create or authenticate a physical pair. This invariant gets an explicit regression test (below).

## 8. Isolated tests + roadmap

**Tests (disposable DB, catalog-only invariants asserted):**
- Link create → one join row; variant→item is 1:N (two items → same variant → two link rows, both valid).
- `UNIQUE(eyewear_item_id)` → a second link for the same item is rejected (relink is explicit).
- Intake double-submit idempotency → one item, one link (not two).
- Link to a non-existent / archived / wrong-shop variant → fail-closed, no row.
- Prefill → brand/model/sku populated from the variant; staff override respected; physical-only fields untouched.
- **Invariant:** a `products/create|update|delete` webhook and an import create **zero** `sca_eyewear_items` and **zero** link rows.
- Non-interference: a linked item authenticates/certifies/gets a QR passport through the existing flow; unlink removes only the join row and leaves auth/cert/QR/ownership intact.

**Roadmap (small reviewable slices):**
- **Slice A:** additive migration (`sca_eyewear_item_shopify_variant`) + model + `ShopifyProductLinkService` + new ACL `sca.eyewear.shopify.link`; service/DB tests. No UI.
- **Slice B:** staff UI — optional Shopify selector on the create form (search active products/variants) + prefill + create-with-link in one txn; link/unlink on item detail.
- **Slice C:** surface the Shopify reference on item/auth screens; optional ops view of linked-pair counts per variant (advisory vs `inventory_quantity`).
- **Future (separate):** sync product images/metafields to enrich prefill; advisory stock reconciliation (linked pairs vs variant quantity) — never auto-mutating.

Each slice: additive migration only, no change to auth/cert/QR/ownership logic, catalog-only invariant retained, isolated tests on a disposable DB, STOP for review before any deploy.

## 9. Constraints & preservation

- No auto-authenticate/certify/passport/ownership from linking (link is metadata + prefill only).
- Additive schema; existing ownership/authentication history untouched.
- The Phase-1 **first-genuine-product-webhook verification remains open and separate** — Phase 2 neither performs nor closes it.

**STOP — read-only Phase 2 audit & plan delivered for owner + ChatGPT review. No code, DB change, deploy, Shopify change, or production activation. Pending webhook-delivery verification preserved as a separate task.**

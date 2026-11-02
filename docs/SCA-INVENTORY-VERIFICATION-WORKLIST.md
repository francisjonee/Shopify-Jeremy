# SCA — Staff Physical Inventory Verification Worklist

**A downloadable worklist of the 1,750 genuinely-linkable, in-stock catalog variants has been generated
from the local Shopify catalog mirror (read-only), with all staff-verification fields blank and a
one-per-variant row for staff to triage, physically confirm, and classify before any SCA registration.**
No Shopify call, no DB write, no import. Prod `6e36aa7`. 2026-11-02. **STOP.**

> Written for: the owner (Jeremy) + the staff who will physically verify inventory.

## Worklist location & shape
- **File:** `docs/worklists/sca-inventory-verification-worklist-20261102.csv` (committed to governance).
- **Records:** **1,750** rows (one per in-stock, active, linkable catalog variant). Fully quoted CSV
  (`QUOTE_ALL`) so titles with commas/quotes/newlines are safe.
- **Columns** (catalog-derived first, then a system hint, then blank staff fields, then batch):
  `shopify_product_title`, `shopify_product_id`, `shopify_variant_id`, `sku`, `option_values`,
  `inventory_quantity`, `possible_accessory_hint` *(system heuristic, see below)*,
  `staff_eyewear_or_accessory`, `physical_quantity_confirmed`, `verified_brand`, `verified_model`,
  `frame_serial`, `notes`, `verification_status`, `staff_batch`.
- **Staff fields are blank** (`staff_eyewear_or_accessory`, `physical_quantity_confirmed`,
  `verified_brand`, `verified_model`, `frame_serial`, `notes`, `verification_status`) — to be filled by
  staff only.

## How the set was selected (read-only, local mirror only)
- Source: `sca_shopify_products` + `sca_shopify_variants` (the synced catalog mirror) — **no Shopify API**.
- Included: variant `status = active` **AND** `inventory_quantity > 0` **AND** parent product
  `status = active` (the genuinely sellable + later-linkable set — matches `ShopifyProductLinkService`
  eligibility).
- Excluded: archived/deleted products and variants, and zero-stock variants. (73 in-stock active
  variants whose parent product is archived were excluded; raise with the owner if any should be
  re-activated.)
- `shopify_product_id` / `shopify_variant_id` are preserved **exactly** as 14-digit strings (verified
  unique; no truncation/scientific-notation — the CSV is fully quoted; open it importing columns as TEXT
  in a spreadsheet to avoid long-number reformatting).

## System accessory hint (NOT authoritative) — step 4
`possible_accessory_hint` = "REVIEW: possible accessory" when the title matches an accessory keyword
(case, pouch, cord, chain, strap, lanyard, cleaner/cloth/wipe, kit, clip, holder, stand, repair, screw,
nose pad, temple tip, retainer, band, "accessor…"). This is a **triage hint only** — staff make the real
call in `staff_eyewear_or_accessory`. **191** rows are flagged for review.

## Data-quality issues & findings — step 12
- **Vendor is not the brand:** every active product's `vendor` is the store name ("Second Chance Eyewear
  & Accessories"); brand/model live in the **free-text title** (e.g. "125 Rodenstock Green Frame…"). Staff
  must read brand/model from the title/physical item — the worklist does NOT pre-fill them.
- **Quantity distribution (the biggest scoping issue):** of 1,750 variants — **1,579 are qty = 1**
  (likely unique collectible pairs), **138 are qty 2–9**, and **33 are qty ≥ 10** totalling **1,328
  units** (max **395**). The high-quantity SKUs are almost certainly **bulk / interchangeable stock**
  (e.g. reading glasses by magnification), **not** unique pairs that each warrant an individual
  provenance record. **Owner decision needed:** whether bulk/mass items belong in the per-pair registry
  at all (recommended: onboard the qty=1 unique pairs first; treat high-qty SKUs as out-of-scope or a
  separate category). `inventory_quantity` is itself **non-authoritative** (Phase-1 copied it from the
  product payload).
- **Accessories present:** 191 titles look like accessories — expected for a store "…& Accessories";
  staff exclude non-eyewear.
- **Blank SKU:** **17** variants have no SKU (not required for linking — the `shopify_variant_id` is the
  key).
- **Multi-unit:** **171** variants have qty > 1 (→ multiple physical rows at import if each is a genuine
  distinct pair; but see the bulk caveat).

## Batching — step 9
Rows carry a `staff_batch` label in blocks of **100** (`B001`–`B018`, 18 batches) — a manageable
verification-shift chunk. Note the SCA **import** cap is **500 rows/CSV**, so one import CSV can hold up
to 5 verification batches; keep each import ≤ 500 verified eyewear rows.

## Converting verified rows into the SCA import format — step 10
After staff complete a batch, convert only the **confirmed eyewear** rows into the existing import CSV
(headers exactly):
```
intake_type,brand,model_name,frame_serial,year,country_of_origin,materials,original_specifications,shopify_variant_id
```
Mapping rule (one import row per **physically-confirmed pair**):
- Keep only rows where `staff_eyewear_or_accessory = eyewear` AND `verification_status = verified`; **drop
  accessories and unconfirmed rows**.
- For a row with `physical_quantity_confirmed = N`, emit **N import rows** (one per physical pair), each
  carrying the SAME `shopify_variant_id` (many-items→one-variant is supported).
- `intake_type` = `sce_presale` (Second Chance Eyewear's own stock) unless the owner says otherwise.
- `brand` ← `verified_brand`; `model_name` ← `verified_model`; `frame_serial` ← per-pair `frame_serial`
  (blank if none); `shopify_variant_id` ← the worklist `shopify_variant_id`.
- `year` / `country_of_origin` / `materials` / `original_specifications` ← from staff inspection/notes
  (optional; leave blank if unknown — only `intake_type` is required).
- Split the resulting rows into ≤ 500-row import CSVs. Then: upload → **preview (zero mutation)** →
  **owner preview sign-off** → confirm (see the pilot handover). Linked imports require the operator to
  hold `sca.eyewear.shopify.link`.
A small read-only converter can be scripted later from the completed worklist; it is **not** run here and
creates nothing until an authorized import.

## Safety posture (this task)
Read-only. Local mirror only; no Shopify API request or store change; no production DB write; no inventory
import; no certification / QR / order-assignment / ownership change; no deployment/migration; secure-claim
RC `4bd88d2` not deployed. Production unchanged at `6e36aa7`.

**STOP — worklist generated at `docs/worklists/sca-inventory-verification-worklist-20261102.csv`: 1,750
in-stock active linkable variants, one row each, exact 14-digit variant IDs, all staff fields blank, 18
batches of 100, 191 accessory hints. Key finding: 1,579 are qty=1 (likely unique pairs) while 33 qty≥10
SKUs hold 1,328 units (likely bulk/interchangeable) — owner should confirm scope (onboard qty=1 unique
pairs first; decide if bulk/mass items belong in the per-pair registry). Conversion-to-import mapping
documented. No Shopify/DB/import change made; prod `6e36aa7` unchanged.**

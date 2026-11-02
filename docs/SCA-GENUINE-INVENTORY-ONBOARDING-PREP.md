# SCA — Genuine Inventory Onboarding Preparation (read-only)

**The registry and the CSV import (with optional Shopify variant linking) are live and ready; genuine
onboarding is a staff-verification exercise, not a data-import-from-catalog exercise — the synced catalog
can safely supply only the exact `shopify_variant_id` (for linking) and a title to identify each pair,
while brand/model/serial/condition must be physically verified by staff.** Read-only review at prod
`6e36aa7`; no import, DB write, Shopify call, or change made. 2026-11-02. **STOP for review.**

> Written for: the owner (Jeremy) + the staff who will physically verify and register inventory.

## 1. Live production & synced catalog (verified read-only)
- App `6e36aa7`, `kr-app` healthy. CSV import feature live (`/admin/sca/eyewear/import`).
- Synced Shopify catalog (mirror, Phase-1): **4,610 products (1,708 active)**, **5,384 variants (5,375
  active)**. In-stock = **1,823 active variants with `inventory_quantity > 0`**, summing to **3,443
  units** (none null).
- SCA registry so far: **3 eyewear items** (the test items), **0 variant links**, **0 inventory imports
  run** — genuine onboarding has not begun.

## 2. The CSV import interface & columns (deployed contract)
`/admin/sca/eyewear/import` (ACL `sca.eyewear.create`; +`sca.eyewear.shopify.link` if any row links a
variant): **upload → preview (zero mutation) → confirm**. Max **500 data rows/CSV**.
- Required column, every row: **`intake_type`** ∈ {`sce_presale`, `external_intake`}.
- Optional intake columns: `brand`, `model_name`, `frame_serial`, `year` (integer 1800–2027),
  `country_of_origin`, `materials`, `original_specifications`.
- Optional link column: **`shopify_variant_id`** (exact numeric Shopify variant id; validated against the
  local catalog mirror — never Shopify; malformed/unknown/archived/cross-store → that row is INVALID).
- Each imported row becomes ONE UNCERTIFIED SCA item (its own `public_ref`); authentication, certification
  (which mints the QR), and QR labels remain the per-item human steps afterward.

## 3. What catalog data can SAFELY populate the CSV (and what cannot) — step 4
Finding from the live mirror: **the catalog is not structured per physical pair.**
- **`vendor` is the store name, not the eyewear brand** — all active products share one vendor,
  "Second Chance Eyewear & Accessories". ⇒ **do NOT map vendor → `brand`.**
- **Brand + model are embedded in the free-text product title**, e.g. *"125 Rodenstock Green Frame w/
  Silver temple"*. ⇒ brand ("Rodenstock") and model must be **parsed and confirmed by a human**;
  auto-splitting the title would invent/mis-state identities. **Do NOT auto-populate `brand`/`model_name`
  from the title.**
- Variants are mostly single (`option_values` = "Default Title"); `sku` is often a numeric id, not a
  human SKU.
- **Safe to derive from the catalog:** the **`shopify_variant_id`** (exact, for linking) and the **product
  title as a staff-facing reference** to locate/identify the physical pair. Nothing else is safe to treat
  as a verified per-pair fact.
- **Absolutely excluded:** bulk-importing catalog rows as items (a variant is a SKU-with-quantity, not an
  individual pair) — this would fabricate inventory. The import service enforces this by design (it reads
  staff-provided intake rows, never the mirror).

## 4. What staff must supply / physically verify — step 5
Per physical pair, staff confirm by inspecting the item: it genuinely EXISTS; `intake_type`
(**`sce_presale`** for Second Chance Eyewear's own stock); `brand` and `model_name` (verified against the
title, corrected as needed); `frame_serial` (if present); `year`, `country_of_origin`, `materials`,
`original_specifications` (physical/record inspection); and the exact `shopify_variant_id` the pair
corresponds to (via the staff catalog selector — see §6). Condition grade and authentication are recorded
later in the per-item authenticate→certify flow, not in the CSV.

## 5. Using Shopify inventory quantity as an ESTIMATE only — step 6
`inventory_quantity` (active) sums to **3,443** across **1,823** in-stock SKUs (avg ≈ 1.9/SKU; many are
qty 1). This is a **planning estimate** of how many physical pairs may need registration and how to size
batches — **not** a set of verified identities. It is explicitly **non-authoritative** (Phase-1 copied it
from the product payload; true stock would need `read_inventory`, out of scope). A SKU with quantity N
means staff register **N separate physical pairs** (N CSV rows, each linking the same variant id —
many-items→one-variant is supported), but only after physically confirming N units exist. Treat 3,443 as
"≈ up to ~3.4k pairs, pending staff count," i.e. ~7 batches of 500.

## 6. Practical onboarding workflow (genuine, staff-verified) — step 7
1. **Scope the batch (read-only).** From the in-stock active catalog, produce a staff **worklist** of
   candidate pairs: `shopify_variant_id`, product title, option, estimated qty. (Read-only query over the
   mirror; no Shopify call. The staff catalog selector `GET /admin/sca/shopify/catalog-search` — ACL
   `sca.eyewear.shopify.link` — already serves this lookup per variant.)
2. **Physically verify** each candidate: confirm the pair exists, read brand/model/serial/specs, decide
   `intake_type`, and note the exact `shopify_variant_id`.
3. **Build the CSV** (≤ 500 verified rows) from the template
   `docs/templates/sca-inventory-pilot-10pair-TEMPLATE.csv`: the 8 intake fields (staff-verified) + the
   optional `shopify_variant_id` (from §1/§6). For qty > 1, one row per physical pair.
4. **Upload → preview (creates nothing)** at `/admin/sca/eyewear/import`; review VALID / WARNING
   (duplicate) / INVALID and the variant-mapping summary.
5. **APPROVAL CHECKPOINT (§7)** → **confirm** → items created (and linked); then per pair:
   **authenticate → finalize → certify (mints the QR) → batch-print QR labels**.
6. Repeat per ≤500 batch. Registration + labeling scale; the throughput constraint is the per-pair human
   authentication/certification.

## 7. Approval checkpoint — step 9
Two gates, both already defined in the pilot operational handover
(`docs/SCA-INVENTORY-PILOT-OPERATIONAL-HANDOVER.md`):
1. **Owner authorization of the first genuine import** (a governance gate — the app will let any
   `sca.eyewear.create` staffer import; do not run the first real import without Jeremy's go-ahead).
2. **Preview sign-off**: staff upload → the preview mutates nothing → the owner/designated approver signs
   off on the previewed rows and variant mappings → only then is "Confirm import" clicked. A
   variant-linking CSV also requires the operator to hold `sca.eyewear.shopify.link`.

## 8. Batch capacity — step 8
Confirmed: **`MAX_ROWS = 500`** per CSV (swapless host, no background jobs). Larger inventories split
into ≤500-row batches; import is idempotent/resumable (content-hash batch identity + per-row unique
ledger), so re-uploading a batch never duplicates. ~3,443 estimated units ⇒ ~7 batches; recommend
starting with the **10-pair pilot** (`docs/SCA-INVENTORY-ONBOARDING-PILOT-SOP.md`) before scaling.

## 9. Information needed from Jeremy — step 10
1. **Scope:** which in-stock active SKUs are genuine physical SCE pre-sale pairs to onboard now (vs
   accessories, archived/placeholder listings, or non-eyewear). The 1,823 in-stock variants likely
   include non-pair items — Jeremy/staff must confirm the real set.
2. **intake_type:** confirm `sce_presale` for this inventory (store vendor = SCE).
3. **Linking:** whether to populate `shopify_variant_id` at import (needs `sca.eyewear.shopify.link`), or
   onboard unlinked and link later.
4. **Brand/model source of truth:** confirm staff will verify brand/model per pair (titles are free-text;
   not auto-derivable).
5. **Staffing** for per-pair authentication/certification (the real bottleneck), and **go-ahead + approver**
   for the first genuine batch.
6. Whether the ~3,443 `inventory_quantity` reflects the real physical count (it is non-authoritative).

## 10. Next executable onboarding action — step 10
**Start with the authorized 10-pair pilot** (SOP already prepared): (a) staff pick 10 genuine in-stock
pairs and look up each `shopify_variant_id` via the catalog selector; (b) fill the 10-row template with
physically-verified data; (c) upload → preview → **owner preview sign-off** → confirm; (d) per-pair
authenticate → certify (QR) → batch labels. This proves the end-to-end genuine flow on 10 real pairs
before scaling to ≤500-row batches. The optional read-only staff **worklist export** (in-stock variants:
id/title/qty) can be produced to seed the pilot selection on request. **No import is run until Jeremy
authorizes it.**

## 11. Safety posture (this task)
Read-only preparation. No production inventory import or DB write; no Shopify API request or store
modification; no certification/QR/ownership change; no development/migration/deployment; secure-claim RC
`4bd88d2` not activated. Production unchanged at `6e36aa7`.

**STOP — onboarding preparation delivered. The registry + CSV import (+ optional variant linking) are live
and ready for ≤500-row batches; the synced catalog can safely supply only the exact `shopify_variant_id`
and a title to identify each pair (vendor = store name, brand/model are free-text in titles), so genuine
per-pair facts (brand, model, serial, specs, intake_type) must be STAFF-VERIFIED — never bulk-imported
from the catalog. Inventory quantity (~3,443 across 1,823 in-stock SKUs) is a non-authoritative sizing
estimate only. Approval = owner go-ahead + preview sign-off. Next action = the authorized 10-pair pilot,
then scale. Information needed from Jeremy is listed in §9. No import/DB/Shopify change made; prod
`6e36aa7` unchanged.**

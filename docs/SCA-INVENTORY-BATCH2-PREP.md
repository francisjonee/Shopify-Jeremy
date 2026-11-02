# SCA — Inventory Onboarding Batch 2 Preparation (read-only)

**The next 10 in-stock (`qty=1`) eyewear candidates have been selected from the verification worklist for
staff physical review — all distinct from Batch 1, none already linked to an SCA item, all confirmed
active+linkable, with a review sheet and an import DRAFT whose physical-identity fields are blank (nothing
invented) and no import run.** Read-only; no Shopify call, no DB write, no import. Prod `6e36aa7`.
2026-11-02. **STOP for owner review.**

> Written for: the owner (Jeremy) + the staff who will physically verify these 10 pairs.

## Selection method (read-only)
Source: `docs/worklists/sca-inventory-verification-worklist-20261102.csv` (1,750 rows). Same deterministic
filter as Batch 1, continued down the worklist: `inventory_quantity = 1`, no system accessory hint, title
reads as eyewear (frame / glasses / sunglasses / optical / spectacle / lens / shades), **excluding** obvious
non-pair items (counter cards, catalogs/look books, Bluetooth/earphone/speaker gadgets, computer/reading/
magnification glasses, cases, cloths, cords, kits, etc.). **Batch-1 variant IDs and all variants already
linked to an SCA physical item were excluded** (the 10 already-linked variants = exactly Batch 1). The
first 10 matching candidates *after* the Batch-1 set were taken, in worklist order. Shopify product IDs,
variant IDs, SKUs and titles are preserved **exactly**; nothing in Shopify was touched.

## The 10 selected Batch-2 candidates
| # | Shopify variant ID | Shopify product ID | SKU | Product title (catalog, reference only) |
|---|---|---|---|---|
| 1 | `48797037494559` | `9309128753439` | `4879703749` | ALAIN MIKLI Mod. AO1347 – Col.2895 – Brand New/Unworn with Factory Lenses |
| 2 | `48873805283615` | `9335688167711` | `4887380528` | Vintage New\|Old Leonard Harley Gold Plated Sunglasses – Mod. Lh1010 Gp 18Ct. 55Mm |
| 3 | `49109051408671` | `9404006433055` | `4910905140` | Traction Productions Model: Ledosky Ivoiloupe – Brand New Eyeglass Frames |
| 4 | `51252452917535` | `9550863958303` | `4950691332` | Barton Perreira Seagrave Polarized Jav\|Sep Sunglasses – Brand New |
| 5 | `49588562166047` | `9576208400671` | `4958856216` | Vintage Nos Kangol Kl500-3 Sunglasses w/ Brand New Custom Berko's Gradient Brown Lenses – 56mm |
| 6 | `50011473871135` | `9789154361631` | `5001147387` | Vintage 1940s Browline Eyewear – Renewed with Berko's Custom Gradient Lenses |
| 7 | `51252418806047` | `9967189197087` | `5037116122` | Vintage 1980s Alain Mikli O144 281 Sunglasses – Handmade in France – Original Glass Lenses |
| 8 | `51252429357343` | `10051512041759` | `5054203641` | Trouble Andrew X Vintage Frames "Dirty Cigs" Edition – Unopened/Sealed |
| 9 | `50561634959647` | `10059132698911` | `5056163495` | Gucci Gg 4252\|S Kj14X Round Sunglasses – 58Mm Matte Black – Blue Lens – Italy |
| 10 | `50562863399199` | `10059342086431` | `5056286339` | Vintage American Optical Cat-Eye Glasses – 1950s/1960s Black & Brown Acetate Frame |

## Pre-selection safety checks (read-only, against the live local mirror)
- **Not already linked (step 7):** each of the 10 variants returned `already_linked = 0` in
  `sca_eyewear_item_shopify_variant`. The only linked variants in production are the 10 Batch-1 ones — all
  excluded here.
- **Active + linkable:** all 10 are `variant status = active` under an `active` parent product, shop
  `second-chance-eyewear-accessories.myshopify.com` (= `sca-shopify.expected_shop_domain`) — i.e. they would
  pass `ShopifyProductLinkService` eligibility at import time. (Confirmed read-only; no Shopify API call.)
- **Distinct from Batch 1:** zero overlap with variant IDs `47188919320863`…`48797142417695`; no duplicate
  variant IDs within Batch 2.

## Deliverables (committed, nothing imported)
- **Batch-2 staff review sheet:** `docs/worklists/batch2/sca-batch2-review-sheet-20261102.csv` — the 10
  candidates with exact catalog fields, a **`physical_pair_exists_confirmed`** column, and **blank** staff
  fields (`staff_eyewear_or_accessory`, `verified_brand`, `verified_model`, `frame_serial`, `verified_year`,
  `country_of_origin`, `materials`, `original_specifications`, `condition_notes`, `intake_type`,
  `verification_status`, `verified_by`, `verified_date`).
- **SCA import DRAFT:** `docs/worklists/batch2/sca-batch2-import-DRAFT-20261102.csv` — exact import contract
  (`intake_type,brand,model_name,frame_serial,year,country_of_origin,materials,original_specifications,
  shopify_variant_id`) with **`shopify_variant_id` prefilled** and **all eight intake fields BLANK**. It is a
  scaffold — **NOT importable as-is** (required `intake_type` empty). Staff complete it from the signed-off
  review sheet before any import.

## Missing / ambiguous information requiring staff verification
Nothing below is inferred or pre-filled — staff supply it from the physical item:
- **Physical pair exists** — confirm each listed pair is physically present (worklist quantity is
  non-authoritative).
- **Brand & model** — titles are marketing free-text. Several name a likely brand/model (Alain Mikli
  AO1347 / O144, Leonard Harley Lh1010, Barton Perreira Seagrave, Kangol KL500-3, Gucci GG4252/S, American
  Optical, Traction Productions Ledosky), but staff must read the actual brand/model from the frame. Left
  blank (not invented).
- **Frame serial / year / country / materials / original specs** — inspect and record (optional; blank if
  unknown).
- **intake_type** — staff/owner set (`sce_presale` expected for SCE stock) — required before import.
- **Condition** — recorded later during authentication, not in the CSV.
- **Flag — #8 "Trouble Andrew X Vintage Frames … Unopened/Sealed":** a sealed collector collab; confirm it
  is a wearable eyewear pair (not a sealed-box collectible to leave unopened) before registering, and how
  "unopened/sealed" should be represented. **#5/#6 are vintage frames re-lensed by SCE** ("Brand New Custom
  Lenses") — owner should confirm provenance wording (e.g. in `original_specifications`/service history), as
  it affects how the piece is described.

## Next steps (owner-gated — nothing runs yet)
1. Owner reviews/approves these 10 (and the #8 sealed-collectible flag).
2. Staff physically verify each pair on the review sheet (confirm exists; record brand/model/serial/specs;
   set `intake_type`; mark `verification_status`).
3. Transfer the **confirmed** rows into the import draft (fill `intake_type` + verified fields), then:
   upload `/admin/sca/eyewear/import` → **preview (zero mutation)** → **owner preview sign-off** → confirm.
   Linking requires `sca.eyewear.shopify.link`. Import is idempotent (content-hash + per-row ledger).
4. Then per pair: authenticate → finalize → certify (mints QR) → batch QR labels.

## Safety posture (this task)
Read-only. Local worklist + local mirror only; no Shopify API request or store change; no production DB
write; no SCA import; no authentication/certification/QR/ownership/claim; no deployment/migration/email;
secure-claim RC `4bd88d2` not deployed. The Shopify store is unchanged. Production unchanged at `6e36aa7`.
Batch 1 (item ids 7–16) is untouched.

**STOP — Batch 2 prepared: 10 in-stock `qty=1` eyewear candidates selected (variant IDs `48797037494559`,
`48873805283615`, `49109051408671`, `51252452917535`, `49588562166047`, `50011473871135`, `51252418806047`,
`51252429357343`, `50561634959647`, `50562863399199`), all distinct from Batch 1, all confirmed
active+linkable and `already_linked=0`, with a staff review sheet (physical-exists + verification fields
blank) and an import DRAFT (variant IDs prefilled, all intake fields blank — not importable until staff
complete it). Nothing invented, nothing imported, Shopify and production unchanged at `6e36aa7`. Awaiting
owner review.**

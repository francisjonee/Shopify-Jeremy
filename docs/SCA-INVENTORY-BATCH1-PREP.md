# SCA — Inventory Onboarding Batch 1: First 10 Pairs (read-only prep)

**Ten genuine-looking, in-stock (`qty=1`) eyewear candidates have been selected from the verification
worklist for staff physical review; all verification fields are blank, nothing is invented, and no import
is run.** Read-only; no Shopify call, no DB write, no import. Prod `6e36aa7`. 2026-11-02. **STOP for owner
review.**

> Written for: the owner (Jeremy) + the staff who will physically verify these 10 pairs.

## Selection method (read-only, from the worklist)
Source: `docs/worklists/sca-inventory-verification-worklist-20261102.csv`. Chose variants that are
`inventory_quantity = 1`, not accessory-flagged, whose title clearly reads as eyewear (frame / glasses /
sunglasses / optical / spectacle), **excluding** obvious non-pair items (counter cards, catalogs/look
books, Bluetooth/earphone gadgets, computer/reading/magnification glasses). First 10 in worklist order.
1,004→999 clear candidates existed; the first 10 are below. Shopify product IDs, variant IDs, SKUs and
titles are preserved **exactly**; nothing was modified in Shopify.

## The 10 selected candidates — step 10
| # | Shopify variant ID | Shopify product ID | SKU | Product title (catalog, reference only) |
|---|---|---|---|---|
| 1 | `47188919320863` | `8798913593631` | `4718891932` | Ultra Catalina 4 Striped Sunglasses – Vintage 1980's – With Brand New "Berkos Designs" Lenses |
| 2 | `48164649992479` | `9059270590751` | `4816464999` | Vintage Japanese Aluminum Frame Revived with Brand New Berko's Design™ Custom Lenses |
| 3 | `48177084399903` | `9061830099231` | `4817708439` | Vintage Japanese Aluminum Frame Revived with Brand New Berko's Design Custom Lenses |
| 4 | `48177595973919` | `9062093979935` | `4817759597` | Vintage Japanese Aluminum Frame Revived with Brand New Berko's Design Custom Lenses |
| 5 | `48177696309535` | `9062156992799` | `4817769630` | Vintage Japanese Aluminum Frame Revived with Brand New Berko's Design Custom Lenses |
| 6 | `48189911302431` | `9065157689631` | `4818991130` | Vintage Japanese Aluminum Frame Revived with Brand New Berko's Design Custom Lenses |
| 7 | `48193329463583` | `9066050912543` | `4819332946` | Vintage Japanese Aluminum Frame Revived with Brand New Berko's Design Custom Lenses |
| 8 | `48193435009311` | `9066084925727` | `4819343500` | Vintage Japanese Aluminum Frame Revived with Brand New Berko's Design Custom Lenses |
| 9 | `48777697493279` | `9298270978335` | `4877769749` | Emmanuelle Khanh 9280 Studded Vintage Sunglasses – New, Custom Gradient Lenses |
| 10 | `48797142417695` | `9309162373407` | `4879714241` | Traction Productions Palmaria Round Optical Frame – Handmade in France – New |

## Deliverables (committed, nothing imported)
- **Batch-1 staff review sheet:** `docs/worklists/batch1/sca-batch1-review-sheet-20261102.csv` — the 10
  candidates with their exact catalog fields, a **`physical_pair_exists_confirmed`** column for staff to
  tick (step 7), and **blank** staff fields: `staff_eyewear_or_accessory`, `verified_brand`,
  `verified_model`, `frame_serial`, `verified_year`, `country_of_origin`, `materials`,
  `original_specifications`, `condition_notes`, `intake_type`, `verification_status`, `verified_by`,
  `verified_date`.
- **SCA import DRAFT:** `docs/worklists/batch1/sca-batch1-import-DRAFT-20261102.csv` — the exact import
  contract (`intake_type,brand,model_name,frame_serial,year,country_of_origin,materials,
  original_specifications,shopify_variant_id`) with **`shopify_variant_id` prefilled** and **all eight
  intake fields BLANK**. It is a scaffold — **NOT importable as-is** (the required `intake_type` and the
  verified brand/model are intentionally empty). Staff fill it from the completed review sheet before any
  import.

## Missing / ambiguous information requiring staff verification — step 8
Nothing below is inferred or pre-filled — staff must supply it from the physical item:
- **Physical pair exists:** confirm each listed pair is physically present (worklist quantity is
  non-authoritative).
- **Brand & model:** the titles are marketing free-text (e.g. "Vintage Japanese Aluminum Frame Revived
  with Berko's Design", "Ultra Catalina 4"). They are **not** clean brand/model fields — #9 hints
  "Emmanuelle Khanh 9280" and #10 "Traction Productions Palmaria", but staff must read the actual brand/
  model from the frame. Left blank (not invented).
- **Frame serial:** not in the catalog — read from the physical frame (blank if none).
- **Year / country of origin / materials / original specifications:** not reliably in the catalog —
  inspect/record (optional fields; leave blank if unknown).
- **intake_type:** staff/owner set (`sce_presale` expected for SCE stock) — required before import.
- **Condition:** recorded later during authentication, not in the CSV.
- **"Revived with Brand New … Custom Lenses" note:** several frames are vintage frames re-lensed by SCE —
  owner should confirm how that is represented (e.g. in `original_specifications` / service history), as
  it affects provenance wording.

## Note on the selection (transparency)
A few `qty=1` titles that matched an eyewear keyword were **excluded as clearly not a collectible pair**
and flagged for the owner rather than selected: an "AKONI EYEWEAR **CounterCard**" (marketing display
card), a "Vava Eyewear … **Catalog And Look Book**-217 Pages" (a book), a "Smart Music Sunglasses &
**Earphones-Bluetooth**" gadget, and "Computer/Reading Glasses" items. This is exactly the accessory /
non-pair ambiguity to confirm during verification.

## Next steps (owner-gated — nothing runs yet)
1. Owner reviews/approves these 10 (and the exclusions).
2. Staff physically verify each pair on the review sheet (confirm exists; record brand/model/serial/
   specs; set `intake_type`; mark `verification_status`).
3. Transfer the **confirmed** rows into the import draft (fill `intake_type` + verified fields; one row
   per physical pair), then: upload `/admin/sca/eyewear/import` → **preview (zero mutation)** → **owner
   preview sign-off** → confirm. Linking requires `sca.eyewear.shopify.link`.
4. Then per pair: authenticate → certify (mints QR) → batch QR labels.

## Safety posture (this task)
Read-only. No Shopify product/inventory modification or API request; no production DB write; no SCA
import; no authentication / certification / QR / ownership / claim; no deployment/migration; secure-claim
RC `4bd88d2` not deployed. The Shopify store is completely unchanged. Production unchanged at `6e36aa7`.

**STOP — Batch 1 prepared: 10 in-stock `qty=1` eyewear candidates selected (variant IDs
`47188919320863`, `48164649992479`, `48177084399903`, `48177595973919`, `48177696309535`,
`48189911302431`, `48193329463583`, `48193435009311`, `48777697493279`, `48797142417695`), with a staff
review sheet (physical-exists + verification fields blank) and an import DRAFT (variant IDs prefilled, all
intake fields blank — not importable until staff complete it). Nothing invented, nothing imported, Shopify
and production unchanged at `6e36aa7`. Awaiting owner review.**

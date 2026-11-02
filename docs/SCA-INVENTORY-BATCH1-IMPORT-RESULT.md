# SCA — Batch 1: Import of 10 Uncertified Eyewear Records (RESULT)

**The first genuine production inventory import is complete: the 10 owner-authorized Batch-1 catalog
candidates are now registered as UNCERTIFIED SCA eyewear records (`SCA-…`), each atomically linked to its
exact existing Shopify variant, with every physical-identity field left blank (nothing invented) and no
authentication, certification, QR, ownership, or sale-link created. Zero Shopify API calls were made; the
Shopify store is unchanged. Production code unchanged at `6e36aa7`.** 2026-11-02. **STOP.**

> Written for: the owner (Jeremy) + the staff who will physically verify and certify these 10 pairs.

## What ran
- Built a 10-row import CSV from the approved Batch-1 draft containing **only trustworthy data**:
  `intake_type = sce_presale` (Second Chance Eyewear's own stock — the store vendor context) and the exact
  `shopify_variant_id` per row. All eight physical-identity columns (`brand`, `model_name`, `frame_serial`,
  `year`, `country_of_origin`, `materials`, `original_specifications`, and SKU/image) were **left blank** —
  no brand, model, serial, year, materials, condition, or authentication was invented.
- Ran the deployed inventory-import workflow (`InventoryImportService`): **preview (zero mutation)** →
  **confirm**. Preview returned `ok=true, total_rows=10, valid=10, warning=0, invalid=0,
  variant_valid=10, variant_invalid=0, can_confirm=true` with no unsupported/duplicate headers and no
  unexplained mismatch, so the confirm step proceeded.
- Variant eligibility was validated **against the local catalog mirror only** (active variant + active
  parent product + expected shop) — the service never calls Shopify. **No Shopify API request was made.**

## Result — 10 UNCERTIFIED records created, each linked (import batch #1, sha `38c53e024234990c…`)
| # | public_ref | item id | shopify_variant_id | shop |
|---|---|---|---|---|
| 1 | `SCA-6207BC1F69C6` | 7  | `47188919320863` | second-chance-eyewear-accessories.myshopify.com |
| 2 | `SCA-398555E2A342` | 8  | `48164649992479` | " |
| 3 | `SCA-11E0789F3700` | 9  | `48177084399903` | " |
| 4 | `SCA-896C37BDFE2E` | 10 | `48177595973919` | " |
| 5 | `SCA-3604FA23052F` | 11 | `48177696309535` | " |
| 6 | `SCA-A4194208AAC4` | 12 | `48189911302431` | " |
| 7 | `SCA-F0AF07F002F2` | 13 | `48193329463583` | " |
| 8 | `SCA-0A7FEAEBDC79` | 14 | `48193435009311` | " |
| 9 | `SCA-80EF09320D2D` | 15 | `48777697493279` | " |
| 10 | `SCA-464387C2ED74` | 16 | `48797142417695` | " |

`imported=10, skipped=0, failed=0, complete=true`. Every row `status=imported`, `link=linked`. All 10 items
carry `intake_type=sce_presale` and **NULL** brand/model/serial/year/materials/specs/sku/image. The import
was attributed to no specific staff member (`actor_staff_ref = NULL`, `linked_by = NULL`) — an
operator-run, owner-authorized import.

## DB fingerprint — before → after
| table | before | after | Δ |
|---|---|---|---|
| `sca_eyewear_items` | 3 | **13** | +10 (ids 7–16) |
| `sca_eyewear_item_shopify_variant` | 0 | **10** | +10 |
| `sca_eyewear_shopify_link_audit` | 0 | **10** | +10 (all `action=link`) |
| `sca_inventory_imports` | 0 | **1** | +1 |
| `sca_inventory_import_rows` | 0 | **10** | +10 |
| `sca_authentications` | 4 | 4 | 0 |
| `sca_certifications` | 4 | 4 | 0 |
| `sca_certification_events` | 5 | 5 | 0 |
| `sca_certificate_snapshots` | 1 | 1 | 0 |
| `sca_qr_identifiers` | 3 | 3 | 0 |
| `sca_qr_lifecycle_events` | 3 | 3 | 0 |
| `sca_ownership_events` | 5 | 5 | 0 |
| `sca_shopify_sale_links` | 1 | 1 | 0 |
| `sca_media_assets` | 2 | 2 | 0 |
| `sca_eyewear_item_images` | 3 | 3 | 0 |

(The three baseline test items — ids 1–6 occupy the pre-existing id space; the pre-import item count was 3
and all pre-existing records remain intact.) Counts for the new items (`id>=7`) in every sensitive table:
**authentications=0, certifications=0, qr=0, ownership=0, sale-links=0.** The records are therefore in the
initial UNCERTIFIED intake state (state is derived from these lifecycle tables; nothing downstream exists).

## Rejected / skipped rows
**None.** All 10 rows were VALID in preview and imported; 0 warnings, 0 invalid, 0 skipped, 0 failed.

## Shopify safety confirmation
No Shopify API request, product change, deletion, inventory adjustment, CLI/credential change, webhook
replay, or reconciliation occurred. Variant validation read the local mirror only. The Shopify store is
**completely unchanged**. The 10 variant IDs are referenced read-only as link targets.

## Idempotency / atomicity
Import identity is the content hash (`38c53e024234990c…`, `sca_inventory_imports.content_sha256` UNIQUE)
plus per-row ledger (`sca_inventory_import_rows` UNIQUE(import_id, source_line)). Re-uploading this exact
CSV would re-detect the batch and create nothing. Each row's item-create + variant-link ran in one
transaction; a link rejection would have rolled back that row's item (none occurred).

## Remaining prerequisites (owner / staff — NOT done here, by design)
1. **Physical verification** of each of the 10 pairs: confirm the pair exists; read and record
   `brand`, `model_name`, `frame_serial`, and any `year`/`country_of_origin`/`materials`/
   `original_specifications` from the item. These were intentionally left blank and should be filled via the
   append-only metadata-correction flow (not re-import). The marketing titles (e.g. "Vintage Japanese
   Aluminum Frame Revived with Berko's Design", "Emmanuelle Khanh 9280", "Traction Productions Palmaria")
   are references only — brand/model must be verified from the physical frame.
2. **Per pair: authenticate → finalize → certify** (certification mints the QR) → **batch-print QR labels.**
   This is the human bottleneck; the registry + linking scale, certification does not.
3. The remaining **17 verification batches (B002–B018)** of the worklist stay owner-gated and are onboarded
   the same way (≤500-row CSVs, preview → owner sign-off → confirm).

## Safety posture (this task)
Owner-authorized production write limited to the 10 approved records. No code change (prod `6e36aa7`, working
tree clean, `kr-app` healthy). No migration, no container recreate. No authentication/certification/QR/
ownership/sale-link created. No Shopify API call or store change. No email. Secure-claim RC `4bd88d2` not
deployed. Temporary import/preview scripts and the CSV were removed from `app/storage/app/` after
verification.

**STOP — Batch 1 imported: 10 UNCERTIFIED eyewear records (`SCA-6207BC1F69C6` … `SCA-464387C2ED74`, item
ids 7–16) created and each linked to its exact Shopify variant (`47188919320863` … `48797142417695`) under
`second-chance-eyewear-accessories.myshopify.com`. imported=10/skipped=0/failed=0. All physical fields
blank (nothing invented); intake_type=sce_presale. Zero cert/QR/ownership/sale-link; pre-existing records
intact; Shopify unchanged; prod `6e36aa7` unchanged. Next = staff physical verification + metadata, then
per-pair authenticate→certify→QR labels.**

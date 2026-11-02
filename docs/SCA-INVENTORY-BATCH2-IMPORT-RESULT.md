# SCA — Batch 2: Import of 10 Uncertified Inventory Records (RESULT)

**Batch 2 is imported: the 10 approved catalog candidates are now registered as UNCERTIFIED SCA eyewear
records (ids 17–26, `SCA-058DAA468939`…`SCA-6833B19571DB`), each atomically linked to its exact existing
Shopify variant, with every physical-identity field left NULL (nothing invented) and no authentication,
certificate, QR, ownership, or sale record created. Zero Shopify API calls; the store is unchanged. Batch 1
(ids 7–16) and all pre-existing records are intact. Production code unchanged at `6e36aa7`.** 2026-11-02.
**STOP.**

> Written for: the owner (Jeremy) + the staff who will physically verify and certify these 10 pairs. These
> are catalog-derived, **unverified** inventory candidates — **not** authenticated physical eyewear.

## Prechecks (all passed)
- **Production `6e36aa7`**, working tree clean, `kr-app` healthy; recent backup present
  (`sca-backup-20261102T021703Z.tar.gz.gpg`, 4.3G).
- All **10 variant IDs** matched the local catalog mirror, each `variant status = active` under an `active`
  parent product, shop `second-chance-eyewear-accessories.myshopify.com` (= `expected_shop_domain`), and
  **`already_linked = 0`**. The import CSV's 10 variant IDs were confirmed byte-identical (set + order) to
  the approved review sheet `docs/worklists/batch2/sca-batch2-review-sheet-20261102.csv`.
- **Batch 1 intact** before import: items 7–16 = 10, links = 10.

## What ran
CSV carried **only** trustworthy data: `intake_type = sce_presale` + exact `shopify_variant_id`; all eight
physical-identity columns blank. Ran the deployed `InventoryImportService`: **preview (zero mutation)** →
**confirm**. Preview: `ok=true, total=10, valid=10, warning=0, invalid=0, variant_valid=10,
variant_invalid=0, variant_missing=0, headers_ok=true, can_confirm=true`, every row `status=VALID` with
variant `status=valid` — no unexplained warning or mismatch, so confirm proceeded. Variant eligibility was
validated **against the local mirror only** — no Shopify API request.

## Result — 10 UNCERTIFIED records created, each linked (import batch #2, sha `4e19d7e74672a7ec…`)
| # | public_ref | item id | shopify_variant_id |
|---|---|---|---|
| 1 | `SCA-058DAA468939` | 17 | `48797037494559` |
| 2 | `SCA-209CE8C8FFDE` | 18 | `48873805283615` |
| 3 | `SCA-B644D0E40479` | 19 | `49109051408671` |
| 4 | `SCA-CDFCFE9EA2BA` | 20 | `51252452917535` |
| 5 | `SCA-4B0C9B5C48AA` | 21 | `49588562166047` |
| 6 | `SCA-7CE5F57BEEB8` | 22 | `50011473871135` |
| 7 | `SCA-280200845DE5` | 23 | `51252418806047` |
| 8 | `SCA-83ADBC121E34` | 24 | `51252429357343` |
| 9 | `SCA-C5445593472F` | 25 | `50561634959647` |
| 10 | `SCA-6833B19571DB` | 26 | `50562863399199` |

All on shop `second-chance-eyewear-accessories.myshopify.com`. `imported=10, skipped=0, failed=0,
complete=true`; every row `link=linked`. All 10 items carry `intake_type=sce_presale` and **NULL**
brand/model/serial/year/materials/specs/sku/image. Attributed to no specific staff member
(`actor_staff_ref = NULL`, `linked_by = NULL`) — operator-run, owner-authorized.

## DB fingerprint — before → after
| table | before | after | Δ |
|---|---|---|---|
| `sca_eyewear_items` | 13 | **23** | +10 (ids 17–26) |
| `sca_eyewear_item_shopify_variant` | 10 | **20** | +10 |
| `sca_eyewear_shopify_link_audit` | 10 | **20** | +10 (all `action=link`) |
| `sca_inventory_imports` | 1 | **2** | +1 (batch #2) |
| `sca_inventory_import_rows` | 10 | **20** | +10 |
| `sca_authentications` | 4 | 4 | 0 |
| `sca_certifications` | 4 | 4 | 0 |
| `sca_certification_events` | 5 | 5 | 0 |
| `sca_certificate_snapshots` | 1 | 1 | 0 |
| `sca_qr_identifiers` | 3 | 3 | 0 |
| `sca_qr_lifecycle_events` | 3 | 3 | 0 |
| `sca_ownership_events` | 5 | 5 | 0 |
| `sca_shopify_sale_links` | 1 | 1 | 0 |

New items (ids 17–26) referenced by sensitive tables: **auth=0, cert=0, qr=0, ownership=0, sale=0** → all 10
remain UNCERTIFIED and unverified (state is derived from these lifecycle tables; none exist). **Batch 1
after import: items 7–16 = 10, links = 10 — unchanged.**

## Rejected / skipped rows
**None.** All 10 rows VALID in preview and imported; 0 warnings, 0 invalid, 0 skipped, 0 failed.

## Shopify safety confirmation
No Shopify API request, product change/deletion, listing change, inventory adjustment, CLI/credential
change, webhook replay, or reconciliation. Variant validation read the local mirror only. The Shopify store
is **completely unchanged**; the 10 variant IDs are referenced read-only as link targets.

## Idempotency / atomicity
Import identity = content hash (`4e19d7e74672a7ec…`, `content_sha256` UNIQUE) + per-row ledger
(`sca_inventory_import_rows` UNIQUE(import_id, source_line)); distinct from Batch 1's hash
(`38c53e024234990c…`). Re-uploading this CSV would create nothing. Each row's item-create + variant-link ran
in one transaction (no rollback occurred).

## Remaining prerequisites (owner / staff — NOT done here)
1. **Physical verification** of each pair: confirm it exists; record `brand`, `model_name`, `frame_serial`,
   and any `year`/`country`/`materials`/`original_specifications` via the append-only metadata-correction
   flow (not re-import). Titles name likely brands (Alain Mikli AO1347/O144, Leonard Harley Lh1010, Barton
   Perreira Seagrave, Kangol KL500-3, Gucci GG4252/S, American Optical, Traction Productions Ledosky) but
   must be read from the frame. **#8 "Trouble Andrew × Vintage Frames, Unopened/Sealed"** — confirm it is a
   wearable pair vs a sealed collectible before authenticating; **#5/#6** are SCE-re-lensed vintage frames →
   confirm provenance wording.
2. **Per pair: authenticate → finalize → certify** (mints the QR) → **batch-print QR labels.**
3. Remaining worklist batches **B002–B018** onboard the same way (≤500-row CSVs, preview → owner sign-off →
   confirm).

## Safety posture (this task)
Owner-authorized production write limited to the 10 approved records. No code change (prod `6e36aa7`, tree
clean, `kr-app` healthy), no migration, no container recreate. No authentication/certification/QR/ownership/
sale-link created. No Shopify API call or store change. No email. Secure-claim RC `4bd88d2` not deployed.
Temporary import/inspect scripts and the CSV were removed from `app/storage/app/` after verification.

**STOP — Batch 2 imported: 10 UNCERTIFIED eyewear records (`SCA-058DAA468939` … `SCA-6833B19571DB`, item
ids 17–26) created and each linked to its exact Shopify variant (`48797037494559` … `50562863399199`) under
`second-chance-eyewear-accessories`. imported=10/skipped=0/failed=0. All physical fields NULL (nothing
invented); intake_type=sce_presale. Zero cert/QR/ownership/sale-link; Batch 1 (7–16) and all pre-existing
records intact; Shopify unchanged; prod `6e36aa7` unchanged. SCA registry now holds 20 catalog-linked
UNCERTIFIED inventory records (Batches 1–2). Next = staff physical verification + per-pair
authenticate→certify→QR labels.**

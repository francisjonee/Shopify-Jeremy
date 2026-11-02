# SCA — Batch 3: Controlled Import of 10 Additional Inventory Records (RESULT)

**Batch 3 is imported: the next 10 eligible catalog candidates are now registered as UNCERTIFIED SCA
eyewear records (ids 27–36, `SCA-4FC3733D7102`…`SCA-688D938F1C0A`), each atomically linked to its exact
existing Shopify variant, with every physical-identity field NULL (nothing invented) and no authentication,
certificate, QR, ownership, or sale record created. Zero Shopify API calls; the store is unchanged. Batches
1 and 2 (ids 7–26) and all pre-existing records are intact. Production code unchanged at `6e36aa7`.**
2026-11-02. **STOP.**

> Written for: the owner (Jeremy) + staff who will physically verify and certify these 10 pairs. These are
> catalog-derived, **unverified** inventory candidates — **not** physically verified, authenticated, or
> certified eyewear.

## Prechecks (all passed)
- **Production `6e36aa7`**, working tree clean, `kr-app` healthy; recent backup present
  (`sca-backup-20261102T021703Z.tar.gz.gpg`, 4.3G).
- Read the existing worklist (`docs/worklists/sca-inventory-verification-worklist-20261102.csv`, 1,750 rows)
  and excluded **all 20 variants already linked via Batches 1+2** (the only links in production). Same
  deterministic filter as prior batches: `qty=1`, no accessory hint, eyewear title, non-pair items excluded.
  The next 10 eligible candidates were taken in worklist order.
- All 10 validated against the local mirror: `variant status = active` under `active` parent product, shop
  `second-chance-eyewear-accessories.myshopify.com` (= `expected_shop_domain`), **`already_linked = 0`
  each**, zero duplicate variant IDs. The import CSV's 10 variant IDs matched the review sheet byte-for-byte
  (set + order).

## What ran
CSV carried only `intake_type = sce_presale` + exact `shopify_variant_id`; all eight physical-identity
columns blank. Ran `InventoryImportService`: **preview (zero mutation)** → **confirm**. Preview: `ok=true,
total=10, valid=10, warning=0, invalid=0, variant_valid=10, variant_invalid=0, variant_missing=0,
headers_ok=true, no unsupported/duplicate headers, can_confirm=true`, every row `status=VALID` with variant
`status=valid` — so confirm proceeded. Variant eligibility validated against the local mirror only — **no
Shopify API request.**

## Result — 10 UNCERTIFIED records created, each linked (import batch #3, sha `de0eb7dfa036df5f…`)
| # | public_ref | item id | shopify_variant_id | catalog title (reference only) |
|---|---|---|---|---|
| 1 | `SCA-4FC3733D7102` | 27 | `50584573509919` | Vintage American Optical 162-Panto Sunglasses (re-lensed) |
| 2 | `SCA-34505F6B93F3` | 28 | `50584803246367` | Moschino M3089-S Heart Cutout Sunglasses – Italy – Deadstock |
| 3 | `SCA-16317D9650E4` | 29 | `50587697905951` | Off-White Oeri068 1007 Shield Wraparound Sunglasses |
| 4 | `SCA-6B950F9A4F33` | 30 | `50587699970335` | Off-White Oeri068 2007 75 Sunglasses – Italy – Deadstock |
| 5 | `SCA-6A586F7064A1` | 31 | `51252412416287` | Titmus 5½ Textured Bronze (re-lensed) |
| 6 | `SCA-249A388061FA` | 32 | `50705131995423` | Vintage 1950s American Optical Cat-Eye Frames (re-lensed) |
| 7 | `SCA-A990588E15BC` | 33 | `50705168072991` | Vintage 1960s Sunmodes by SRO Rectangular Sunglasses (re-lensed) |
| 8 | `SCA-B8AC49628B20` | 34 | `50706777866527` | Deadstock Kala Eyewear USA Tortoise Shell Sunglasses |
| 9 | `SCA-2400BBDFFCBB` | 35 | `51252417167647` | Carrera 5329 40 Vario Sunglasses – Deadstock (re-lensed) |
| 10 | `SCA-688D938F1C0A` | 36 | `50779717304607` | SRO USA Vintage 5 Tortoise Round Frames (re-lensed) |

All on shop `second-chance-eyewear-accessories.myshopify.com`. `imported=10, skipped=0, failed=0,
complete=true`; every row `link=linked`. All 10 carry `intake_type=sce_presale` and **NULL**
brand/model/serial/year/materials/specs/sku/image. Attributed to no specific staff member
(`actor_staff_ref = NULL`, `linked_by = NULL`) — operator-run, owner-authorized.

## DB fingerprint — before → after
| table | before | after | Δ |
|---|---|---|---|
| `sca_eyewear_items` | 23 | **33** | +10 (ids 27–36) |
| `sca_eyewear_item_shopify_variant` | 20 | **30** | +10 |
| `sca_eyewear_shopify_link_audit` | 20 | **30** | +10 (all `action=link`) |
| `sca_inventory_imports` | 2 | **3** | +1 (batch #3) |
| `sca_inventory_import_rows` | 20 | **30** | +10 |
| `sca_authentications` | 4 | 4 | 0 |
| `sca_certifications` | 4 | 4 | 0 |
| `sca_certification_events` | 5 | 5 | 0 |
| `sca_certificate_snapshots` | 1 | 1 | 0 |
| `sca_qr_identifiers` | 3 | 3 | 0 |
| `sca_qr_lifecycle_events` | 3 | 3 | 0 |
| `sca_ownership_events` | 5 | 5 | 0 |
| `sca_shopify_sale_links` | 1 | 1 | 0 |

New items (ids 27–36) referenced by sensitive tables: **auth=0, cert=0, qr=0, ownership=0, sale=0** → all 10
remain UNCERTIFIED and unverified. **Batches 1+2 after import: items 7–26 = 20, links = 20 — unchanged.**
Import ledger holds three distinct batches (sha `38c53e02…`, `4e19d7e7…`, `de0eb7df…`).

## Rejected / skipped rows
**None.** All 10 rows VALID in preview and imported; 0 warnings, 0 invalid, 0 skipped, 0 failed, 0
duplicates.

## Shopify safety confirmation
No Shopify API request, product change/deletion, listing change, inventory adjustment, CLI/credential
change, webhook replay, or reconciliation. Variant validation read the local mirror only. The Shopify store
is **completely unchanged**; the 10 variant IDs are referenced read-only as link targets.

## Idempotency / atomicity
Import identity = content hash (`de0eb7dfa036df5f…`, UNIQUE) + per-row ledger. Distinct from Batches 1/2.
Re-uploading this CSV would create nothing. Each row's item-create + variant-link ran in one transaction.

## Remaining prerequisites (owner / staff — NOT done here)
1. **Physical verification** per pair: confirm it exists; record `brand`/`model_name`/`frame_serial`/
   `year`/`country`/`materials`/`original_specifications` via the append-only metadata-correction flow (not
   re-import). Titles name likely brands (American Optical, Moschino M3089-S, Off-White Oeri068, Titmus,
   Sunmodes/SRO, Kala, Carrera 5329) but must be read from the frame. **Many are SCE-re-lensed vintage
   frames** ("Custom Berko's Designs Lenses") → confirm provenance wording.
2. **Per pair: authenticate → finalize → certify** (mints QR) → **batch-print QR labels.**
3. Remaining worklist batches onboard the same way (≤500-row CSVs, preview → owner sign-off → confirm).

## Safety posture (this task)
Owner-authorized production write limited to the 10 approved records. No code change (prod `6e36aa7`, tree
clean, healthy), no migration, no container recreate, no infrastructure change. No authentication/
certification/QR/ownership/sale-link. No Shopify API call or store change. No email. Secure-claim RC
`4bd88d2` not deployed. Temp import script + CSV removed from `app/storage/app/`.

**STOP — Batch 3 imported: 10 UNCERTIFIED eyewear records (`SCA-4FC3733D7102` … `SCA-688D938F1C0A`, item
ids 27–36) created and each linked to its exact Shopify variant (`50584573509919` … `50779717304607`) under
`second-chance-eyewear-accessories`. imported=10/skipped=0/failed=0. All physical fields NULL (nothing
invented); intake_type=sce_presale. Zero cert/QR/ownership/sale-link; Batches 1+2 (7–26) and all
pre-existing records intact; Shopify unchanged; prod `6e36aa7` unchanged. SCA registry now holds 30
catalog-linked UNCERTIFIED inventory records (Batches 1–3). Next = staff physical verification + per-pair
authenticate→certify→QR labels.**

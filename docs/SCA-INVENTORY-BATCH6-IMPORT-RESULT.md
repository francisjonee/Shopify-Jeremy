# SCA — Batch 6: Controlled Import of 25 Inventory Records (RESULT)

**Batch 6 is imported: the next 25 eligible catalog candidates are now registered as UNCERTIFIED SCA
eyewear records (ids 87–111, `SCA-EEF56876A327`…`SCA-66D0981E3C8B`), each atomically linked to its exact
existing Shopify variant, all in INTAKE status with every physical-identity field NULL (nothing invented)
and no authentication, certificate, QR, ownership, or sale association. Zero Shopify API calls; the store is
unchanged. Batches 1–5 (ids 7–86) and all pre-existing records are intact. The SCA registry now holds the
expected 105 catalog-linked UNCERTIFIED inventory records. Production code unchanged at `6e36aa7`.**
2026-11-02. **STOP.**

> Written for: the owner (Jeremy) + staff who will physically verify and certify these pairs. Catalog-derived,
> **unverified** inventory candidates — **not** physically verified, authenticated, or certified eyewear.

## Prechecks (all passed)
- **Production `6e36aa7`**, working tree clean, `kr-app` healthy; recent backup present
  (`sca-backup-20261102T021703Z.tar.gz.gpg`, 4.3G). Governance baseline `d7ba2fd` (80 imported, last id 86)
  — matches the task's stated baseline exactly.
- Read the worklist (1,750 rows) and **read all existing variant links directly from the production DB** —
  **80** linked variants (Batches 1–5); excluded every one. Same deterministic filter: `qty=1`, no accessory
  hint, eyewear title, non-pair/accessory/catalog/display/bulk excluded. Next 25 eligible in worklist order.
- All 25 validated against the local mirror: **matched=25, active variant + active parent = 25, expected
  shop (`second-chance-eyewear-accessories.myshopify.com`) = 25, already_linked = 0, 25 distinct**, no
  non-active rows. Import CSV matched the review sheet byte-for-byte (set + order).

## What ran
CSV carried only `intake_type = sce_presale` + exact `shopify_variant_id`; all eight physical-identity
columns blank. `InventoryImportService`: **preview (zero mutation)** → **confirm**. Preview: `ok=true,
total=25, valid=25, warning=0, invalid=0, variant_valid=25, variant_invalid=0, variant_missing=0,
headers_ok=true, no unsupported/duplicate headers, can_confirm=true`; every row `status=VALID` with variant
`status=valid`. Variant eligibility validated against the local mirror only — **no Shopify API request**.

## Result — 25 UNCERTIFIED records created, each linked (import batch #6, sha `30f8f1db8090…`)
| public_ref | id | variant_id | | public_ref | id | variant_id |
|---|---|---|---|---|---|---|
| `SCA-EEF56876A327` | 87 | `51027476152607` | | `SCA-209839412199` | 101 | `51252428701983` |
| `SCA-D8551A7558F6` | 88 | `51027514818847` | | `SCA-AC280BA41561` | 102 | `51052665602335` |
| `SCA-C695B3A6CFDF` | 89 | `51252435190047` | | `SCA-285839340E84` | 103 | `51252427817247` |
| `SCA-96A35662DF95` | 90 | `51252416446751` | | `SCA-EA0FA57595F8` | 104 | `51252427161887` |
| `SCA-7338B0F21FD0` | 91 | `51252411171103` | | `SCA-F1D803E9D16A` | 105 | `51054040940831` |
| `SCA-6AE4F651E532` | 92 | `51034141819167` | | `SCA-4E707E9D48BE` | 106 | `51054350762271` |
| `SCA-71ECE6D5BA1F` | 93 | `51252430471455` | | `SCA-0DE9D629BBBB` | 107 | `51054377435423` |
| `SCA-67031B246FC7` | 94 | `51035497038111` | | `SCA-6FA25EEC21E4` | 108 | `51054397063455` |
| `SCA-DBD4A32CF6A0` | 95 | `51252436336927` | | `SCA-3C46D86FCB66` | 109 | `51068264972575` |
| `SCA-89073418C18C` | 96 | `51036154822943` | | `SCA-3286B35F6BF1` | 110 | `51068567257375` |
| `SCA-03E6964515E2` | 97 | `51252434272543` | | `SCA-66D0981E3C8B` | 111 | `51252423000351` |
| `SCA-11C84C1427F5` | 98 | `51252425916703` | | | | |
| `SCA-2DDD244F355C` | 99 | `51052378882335` | | | | |
| `SCA-903FD1455BF5` | 100 | `51252434632991` | | | | |

All on shop `second-chance-eyewear-accessories.myshopify.com`. `imported=25, skipped=0, failed=0,
complete=true`; every row `link=linked`. All 25 carry `intake_type=sce_presale` and **NULL** brand/model/
serial/year/country/materials/specs/sku/image. Attributed to no specific staff member (`actor_staff_ref =
NULL`, `linked_by = NULL`) — operator-run, owner-authorized.

## DB fingerprint — before → after
| table | before | after | Δ |
|---|---|---|---|
| `sca_eyewear_items` | 83 | **108** | +25 (ids 87–111) |
| `sca_eyewear_item_shopify_variant` | 80 | **105** | +25 |
| `sca_eyewear_shopify_link_audit` | 80 | **105** | +25 (all `action=link`) |
| `sca_inventory_imports` | 5 | **6** | +1 (batch #6) |
| `sca_inventory_import_rows` | 80 | **105** | +25 |
| `sca_authentications` | 4 | 4 | 0 |
| `sca_certifications` | 4 | 4 | 0 |
| `sca_qr_identifiers` | 3 | 3 | 0 |
| `sca_ownership_events` | 5 | 5 | 0 |
| `sca_shopify_sale_links` | 1 | 1 | 0 |

**All 25 new items (87–111): `lifecycle_state = INTAKE`, `registry_status = normal`, no owner/cert/qr**
(verified 25/25), 0 with any physical field set. New items referenced by sensitive tables: **auth=0, cert=0,
qr=0, ownership=0, sale=0**. **Batches 1–5 after import: items 7–86 = 80, links = 80 — unchanged.** Ledger
holds six distinct batches (sha `38c53e02…`, `4e19d7e7…`, `de0eb7df…`, `7f422673…`, `161842cd…`,
`30f8f1db…`). **Registry total: 105 catalog-linked UNCERTIFIED records — matches the task's expected result.**

## Rejected / skipped rows
**None.** All 25 rows VALID in preview and imported; 0 warnings, 0 invalid, 0 skipped, 0 failed, 0
duplicates.

## Shopify safety confirmation
No Shopify API request, product change/deletion, listing change, inventory adjustment, CLI/credential
change, webhook replay, or reconciliation. Variant validation read the local mirror only. The Shopify store
is **completely unchanged**; the 25 variant IDs are referenced read-only as link targets.

## Idempotency / atomicity
Import identity = content hash (`30f8f1db8090…`, UNIQUE) + per-row ledger; distinct from Batches 1–5.
Re-uploading this CSV would create nothing. Each row's item-create + variant-link ran in one transaction.

## Remaining prerequisites (owner / staff — NOT done here)
1. **Physical verification** per pair: confirm it exists; record brand/model/serial/year/country/materials/
   specs via the append-only metadata-correction flow (unlocked for these uncertified items), not re-import.
   Titles name likely brands (Alain Mikli, Cool-Ray Polaroid, Gianni Versace, Christian Dior, Jean Lafont,
   Garrett Leight, Kador, Silhouette, YSL, Porsche Design, etc.) but must be read from the frame. Many are
   SCE-re-lensed → confirm provenance wording.
2. **Per pair: authenticate → finalize → certify** (mints QR) → **batch-print QR labels.**
3. Remaining worklist candidates onboard the same way (≤500-row CSVs, preview → owner sign-off → confirm).

## Safety posture (this task)
Owner-authorized production write limited to the 25 approved records. No code change (prod `6e36aa7`, tree
clean, healthy), no migration, no container recreate, no infrastructure change. No authentication/
certification/QR/ownership/sale-link. No Shopify API call or store change. Secure-claim RC `4bd88d2` not
deployed. Temp import script + CSV removed from `app/storage/app/`.

**STOP — Batch 6 imported: 25 UNCERTIFIED eyewear records (`SCA-EEF56876A327` … `SCA-66D0981E3C8B`, item
ids 87–111) created and each linked to its exact Shopify variant (`51027476152607` … `51252423000351`)
under `second-chance-eyewear-accessories`. imported=25/skipped=0/failed=0. All in INTAKE with physical
fields NULL (nothing invented); intake_type=sce_presale. Zero cert/QR/ownership/sale-link; Batches 1–5
(7–86) and all pre-existing records intact; Shopify unchanged; prod `6e36aa7` unchanged. SCA registry now
holds 105 catalog-linked UNCERTIFIED inventory records (Batches 1–6) — the expected result. Next = staff
physical verification + per-pair authenticate→certify→QR labels.**

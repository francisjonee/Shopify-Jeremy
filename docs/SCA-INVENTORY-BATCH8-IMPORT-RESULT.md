# SCA — Batch 8: Controlled Import of 25 Inventory Records (RESULT)

**Batch 8 is imported: the next 25 eligible catalog candidates are now registered as UNCERTIFIED SCA
eyewear records (ids 137–161, `SCA-69B64106A879`…`SCA-E8D4B6DC1736`), each atomically linked to its exact
existing Shopify variant, all in INTAKE status with every physical-identity field NULL (nothing invented)
and no authentication, certificate, QR, ownership, or sale association. Zero Shopify API calls; the store is
unchanged. Batches 1–7 (ids 7–136) and all pre-existing records are intact. The SCA registry now holds the
expected 155 catalog-linked UNCERTIFIED inventory records. Production code unchanged at `6e36aa7`.**
2026-11-02. **STOP.**

> Written for: the owner (Jeremy) + staff who will physically verify and certify these pairs. Catalog-derived,
> **unverified** inventory candidates — **not** physically verified, authenticated, or certified eyewear.

## Prechecks (all passed)
- **Production `6e36aa7`**, working tree clean, `kr-app` healthy; recent backup present
  (`sca-backup-20261102T021703Z.tar.gz.gpg`, 4.3G). Governance baseline `7b4c266` (130 imported, last id
  136) — matches the task's stated baseline exactly.
- Read the worklist (1,750 rows) and **read all live SCA variant links directly from the production DB** —
  **130** linked variants (Batches 1–7); excluded every one. Same deterministic filter: `qty=1`, no
  accessory hint, eyewear title, non-pair/accessory/catalog/display/bulk excluded. Next 25 eligible in
  worklist order. (**955 clean candidates remain** in the worklist pool after this batch — ample runway.)
- All 25 validated against the local mirror: **matched=25, active variant + active parent = 25, expected
  shop (`second-chance-eyewear-accessories.myshopify.com`) = 25, already_linked = 0, 25 distinct**, no
  non-active rows. Import CSV matched the review sheet byte-for-byte (set + order).

## What ran
CSV carried only `intake_type = sce_presale` + exact `shopify_variant_id`; all eight physical-identity
columns blank. `InventoryImportService`: **preview (zero mutation)** → **confirm**. Preview: `ok=true,
total=25, valid=25, warning=0, invalid=0, variant_valid=25, variant_invalid=0, variant_missing=0,
headers_ok=true, no unsupported/duplicate headers, can_confirm=true`; every row `status=VALID` with variant
`status=valid`. Variant eligibility validated against the local mirror only — **no Shopify API request**.

## Result — 25 UNCERTIFIED records created, each linked (import batch #8, sha `b744e98aaf44…`)
| public_ref | id | variant_id | | public_ref | id | variant_id |
|---|---|---|---|---|---|---|
| `SCA-69B64106A879` | 137 | `51129447350559` | | `SCA-4475564FA6B4` | 152 | `51181102956831` |
| `SCA-33B80264FC77` | 138 | `51131982905631` | | `SCA-6EDA66298B64` | 153 | `51252412940575` |
| `SCA-AA6E9648A806` | 139 | `51252425883935` | | `SCA-9C976E883B9A` | 154 | `51185185947935` |
| `SCA-C90E9E92384C` | 140 | `51132001124639` | | `SCA-E94C812244E4` | 155 | `51185270980895` |
| `SCA-951962EE6E59` | 141 | `51252436959519` | | `SCA-8481788A29A3` | 156 | `51185279861023` |
| `SCA-5A9AF2FCE3B3` | 142 | `51252411957535` | | `SCA-C8A165AF9817` | 157 | `51252449575199` |
| `SCA-1A64D2D4CCCB` | 143 | `51161396117791` | | `SCA-0B533886603D` | 158 | `51252444266783` |
| `SCA-20C22DBC44FC` | 144 | `51161470173471` | | `SCA-78C602F0F68B` | 159 | `51252417331487` |
| `SCA-163D51526933` | 145 | `51162356023583` | | `SCA-1BF33F0DB6BE` | 160 | `51205722669343` |
| `SCA-5C53F2BFA4C6` | 146 | `51168515359007` | | `SCA-E8D4B6DC1736` | 161 | `51205755928863` |
| `SCA-7031C77D4375` | 147 | `51168563691807` | | | | |
| `SCA-B75ECCD09318` | 148 | `51252411891999` | | | | |
| `SCA-BA9C788C7B9A` | 149 | `51252439712031` | | | | |
| `SCA-EB1AC4213273` | 150 | `51174896304415` | | | | |
| `SCA-4F7DCC89CA76` | 151 | `51252442726687` | | | | |

All on shop `second-chance-eyewear-accessories.myshopify.com`. `imported=25, skipped=0, failed=0,
complete=true`; every row `link=linked`. All 25 carry `intake_type=sce_presale` and **NULL** brand/model/
serial/year/country/materials/specs/sku/image. Attributed to no specific staff member (`actor_staff_ref =
NULL`, `linked_by = NULL`) — operator-run, owner-authorized.

## DB fingerprint — before → after
| table | before | after | Δ |
|---|---|---|---|
| `sca_eyewear_items` | 133 | **158** | +25 (ids 137–161) |
| `sca_eyewear_item_shopify_variant` | 130 | **155** | +25 |
| `sca_eyewear_shopify_link_audit` | 130 | **155** | +25 (all `action=link`) |
| `sca_inventory_imports` | 7 | **8** | +1 (batch #8) |
| `sca_inventory_import_rows` | 130 | **155** | +25 |
| `sca_authentications` | 4 | 4 | 0 |
| `sca_certifications` | 4 | 4 | 0 |
| `sca_qr_identifiers` | 3 | 3 | 0 |
| `sca_ownership_events` | 5 | 5 | 0 |
| `sca_shopify_sale_links` | 1 | 1 | 0 |

**All 25 new items (137–161): `lifecycle_state = INTAKE`, `registry_status = normal`, no owner/cert/qr**
(verified 25/25), 0 with any physical field set. New items referenced by sensitive tables: **auth=0, cert=0,
qr=0, ownership=0, sale=0**. **Batches 1–7 after import: items 7–136 = 130, links = 130 — unchanged.**
Ledger holds eight distinct batches. **Registry total: 155 catalog-linked UNCERTIFIED records — matches the
task's expected result.**

## Rejected / skipped rows
**None.** All 25 rows VALID in preview and imported; 0 warnings, 0 invalid, 0 skipped, 0 failed, 0
duplicates.

## Shopify safety confirmation
No Shopify API request, product change/deletion, listing change, inventory adjustment, CLI/credential
change, webhook replay, or reconciliation. Variant validation read the local mirror only. The Shopify store
is **completely unchanged**; the 25 variant IDs are referenced read-only as link targets.

## Idempotency / atomicity
Import identity = content hash (`b744e98aaf44…`, UNIQUE) + per-row ledger; distinct from Batches 1–7.
Re-uploading this CSV would create nothing. Each row's item-create + variant-link ran in one transaction.

## Remaining prerequisites (owner / staff — NOT done here)
1. **Physical verification** per pair: confirm it exists; record brand/model/serial/year/country/materials/
   specs via the append-only metadata-correction flow (unlocked for these uncertified items), not re-import.
   Titles name likely brands (Rodenstock, Playboy, Ted Lapidus, Gianfranco Ferré, Seraphin, Versus/Versace,
   Zeiss, Prada, Raf Simons × Linda Farrow, L.A. Eyeworks, Courrèges, Persol, Safilo, Odette Lunettes, etc.)
   but must be read from the frame. Many are SCE-re-lensed → confirm provenance wording.
2. **Per pair: authenticate → finalize → certify** (mints QR) → **batch-print QR labels.**
3. Remaining worklist candidates (≈955 clean) onboard the same way (≤500-row CSVs, preview → owner sign-off
   → confirm).

## Safety posture (this task)
Owner-authorized production write limited to the 25 approved records. No code change (prod `6e36aa7`, tree
clean, healthy), no migration, no container recreate, no infrastructure change. No authentication/
certification/QR/ownership/sale-link. No Shopify API call or store change. Secure-claim RC `4bd88d2` not
deployed. Temp import script + CSV removed from `app/storage/app/`.

**STOP — Batch 8 imported: 25 UNCERTIFIED eyewear records (`SCA-69B64106A879` … `SCA-E8D4B6DC1736`, item
ids 137–161) created and each linked to its exact Shopify variant (`51129447350559` … `51205755928863`)
under `second-chance-eyewear-accessories`. imported=25/skipped=0/failed=0. All in INTAKE with physical
fields NULL (nothing invented); intake_type=sce_presale. Zero cert/QR/ownership/sale-link; Batches 1–7
(7–136) and all pre-existing records intact; Shopify unchanged; prod `6e36aa7` unchanged. SCA registry now
holds 155 catalog-linked UNCERTIFIED inventory records (Batches 1–8) — the expected result; ≈955 clean
candidates remain. Next = staff physical verification + per-pair authenticate→certify→QR labels.**

# SCA — Batch 9: Controlled Import of 25 Inventory Records (RESULT)

**Batch 9 is imported: the next 25 eligible catalog candidates are now registered as UNCERTIFIED SCA
eyewear records (ids 162–186, `SCA-1DC6D83C2CCA`…`SCA-7F68F06F6236`), each atomically linked to its exact
existing Shopify variant, all in INTAKE status with every physical-identity field NULL (nothing invented)
and no authentication, certificate, QR, ownership, or sale association. Zero Shopify API calls; the store is
unchanged. Batches 1–8 (ids 7–161) and all pre-existing records are intact. The SCA registry now holds the
expected 180 catalog-linked UNCERTIFIED inventory records. Production code unchanged at `6e36aa7`.**
2026-11-02. **STOP.**

> Written for: the owner (Jeremy) + staff who will physically verify and certify these pairs. Catalog-derived,
> **unverified** inventory candidates — **not** physically verified, authenticated, or certified eyewear.

## Prechecks (all passed)
- **Production `6e36aa7`**, working tree clean, `kr-app` healthy; recent backup present
  (`sca-backup-20261102T021703Z.tar.gz.gpg`, 4.3G). Governance baseline `e8b6116` (155 imported, last id
  161) — matches the task's stated baseline exactly.
- Read the worklist (1,750 rows) and **read all current production variant links directly from the DB** —
  **155** linked variants (Batches 1–8); excluded every one. Same deterministic filter: `qty=1`, no
  accessory hint, eyewear title, non-pair/accessory/catalog/display/bulk excluded. Next 25 eligible in
  worklist order. (**930 clean candidates remain** in the worklist pool after this batch.)
- All 25 validated against the local mirror: **matched=25, active variant + active parent = 25, expected
  shop (`second-chance-eyewear-accessories.myshopify.com`) = 25, already_linked = 0, 25 distinct**, no
  non-active rows. Import CSV matched the review sheet byte-for-byte (set + order).
- **Transparency note:** rows 17–19 (ids 178–180) are **three distinct variants of one product** ("No Name
  Los Angeles 'Lenor'", product `10257676108063`, variant IDs `51259455144223` / `51259455176991` /
  `51259455209759`). These are distinct variant IDs (not duplicates), each `qty=1`; staff should confirm
  they correspond to three physically distinct pairs during verification.

## What ran
CSV carried only `intake_type = sce_presale` + exact `shopify_variant_id`; all eight physical-identity
columns blank. `InventoryImportService`: **preview (zero mutation)** → **confirm**. Preview: `ok=true,
total=25, valid=25, warning=0, invalid=0, variant_valid=25, variant_invalid=0, variant_missing=0,
headers_ok=true, no unsupported/duplicate headers, can_confirm=true`; every row `status=VALID` with variant
`status=valid`. Variant eligibility validated against the local mirror only — **no Shopify API request**.

## Result — 25 UNCERTIFIED records created, each linked (import batch #9, sha `96285d4e2228…`)
| public_ref | id | variant_id | | public_ref | id | variant_id |
|---|---|---|---|---|---|---|
| `SCA-1DC6D83C2CCA` | 162 | `51205798232351` | | `SCA-354BE3A06D85` | 177 | `51259350810911` |
| `SCA-E56A261EBECF` | 163 | `51205814878495` | | `SCA-DA2604A05716` | 178 | `51259455144223` |
| `SCA-2B3EAD63063E` | 164 | `51205994643743` | | `SCA-CED96535C078` | 179 | `51259455176991` |
| `SCA-BB55F374C0F0` | 165 | `51206250365215` | | `SCA-664A4E448A9C` | 180 | `51259455209759` |
| `SCA-ADF016CA3369` | 166 | `51206574571807` | | `SCA-8A2ACC6BF94C` | 181 | `51263660097823` |
| `SCA-54E44603AC10` | 167 | `51206588432671` | | `SCA-185BD80623A3` | 182 | `51263855132959` |
| `SCA-F0238C467EF7` | 168 | `51206663471391` | | `SCA-2DB3ED076AE1` | 183 | `51267768287519` |
| `SCA-4103985AC53D` | 169 | `51206977716511` | | `SCA-6A0344DEFBC8` | 184 | `51269617352991` |
| `SCA-DF5740CB6FB9` | 170 | `51207808483615` | | `SCA-3141638C9124` | 185 | `51270336119071` |
| `SCA-67B877134A38` | 171 | `51216355393823` | | `SCA-7F68F06F6236` | 186 | `51270345851167` |
| `SCA-1DF897845AB4` | 172 | `51252430340383` | | | | |
| `SCA-121175FAE385` | 173 | `51249394024735` | | | | |
| `SCA-DE24BBD4FE17` | 174 | `51249401561375` | | | | |
| `SCA-6F101E662FC4` | 175 | `51253154316575` | | | | |
| `SCA-58DDFF3DEE39` | 176 | `51253682110751` | | | | |

All on shop `second-chance-eyewear-accessories.myshopify.com`. `imported=25, skipped=0, failed=0,
complete=true`; every row `link=linked`. All 25 carry `intake_type=sce_presale` and **NULL** brand/model/
serial/year/country/materials/specs/sku/image. Attributed to no specific staff member (`actor_staff_ref =
NULL`, `linked_by = NULL`) — operator-run, owner-authorized.

## DB fingerprint — before → after
| table | before | after | Δ |
|---|---|---|---|
| `sca_eyewear_items` | 158 | **183** | +25 (ids 162–186) |
| `sca_eyewear_item_shopify_variant` | 155 | **180** | +25 |
| `sca_eyewear_shopify_link_audit` | 155 | **180** | +25 (all `action=link`) |
| `sca_inventory_imports` | 8 | **9** | +1 (batch #9) |
| `sca_inventory_import_rows` | 155 | **180** | +25 |
| `sca_authentications` | 4 | 4 | 0 |
| `sca_certifications` | 4 | 4 | 0 |
| `sca_qr_identifiers` | 3 | 3 | 0 |
| `sca_ownership_events` | 5 | 5 | 0 |
| `sca_shopify_sale_links` | 1 | 1 | 0 |

**All 25 new items (162–186): `lifecycle_state = INTAKE`, `registry_status = normal`, no owner/cert/qr**
(verified 25/25), 0 with any physical field set. New items referenced by sensitive tables: **auth=0, cert=0,
qr=0, ownership=0, sale=0**. **Batches 1–8 after import: items 7–161 = 155, links = 155 — unchanged.**
Ledger holds nine distinct batches. **Registry total: 180 catalog-linked UNCERTIFIED records — matches the
task's expected result.**

## Rejected / skipped rows
**None.** All 25 rows VALID in preview and imported; 0 warnings, 0 invalid, 0 skipped, 0 failed, 0
duplicates.

## Shopify safety confirmation
No Shopify API request, product change/deletion, listing change, inventory adjustment, CLI/credential
change, webhook replay, or reconciliation. Variant validation read the local mirror only. The Shopify store
is **completely unchanged**; the 25 variant IDs are referenced read-only as link targets.

## Idempotency / atomicity
Import identity = content hash (`96285d4e2228…`, UNIQUE) + per-row ledger; distinct from Batches 1–8.
Re-uploading this CSV would create nothing. Each row's item-create + variant-link ran in one transaction.

## Remaining prerequisites (owner / staff — NOT done here)
1. **Physical verification** per pair: confirm it exists; record brand/model/serial/year/country/materials/
   specs via the append-only metadata-correction flow (unlocked for these uncertified items), not re-import.
   Titles name likely brands (Metalflex, BCBG, Donna Karan, D&G, Salt., Silhouette, Zagato, Halston, Prada,
   Face à Face, Alpina, DITA, Givenchy, Lanvin, TAG Heuer, etc.) but must be read from the frame. Many are
   SCE-re-lensed → confirm provenance wording. Confirm ids 178–180 (No Name LA "Lenor") are three distinct
   physical pairs.
2. **Per pair: authenticate → finalize → certify** (mints QR) → **batch-print QR labels.**
3. Remaining worklist candidates (≈930 clean) onboard the same way (≤500-row CSVs, preview → owner sign-off
   → confirm).

## Safety posture (this task)
Owner-authorized production write limited to the 25 approved records. No code change (prod `6e36aa7`, tree
clean, healthy), no migration, no container recreate, no infrastructure change. No authentication/
certification/QR/ownership/sale-link. No Shopify API call or store change. Secure-claim RC `4bd88d2` not
deployed. Temp import script + CSV removed from `app/storage/app/`.

**STOP — Batch 9 imported: 25 UNCERTIFIED eyewear records (`SCA-1DC6D83C2CCA` … `SCA-7F68F06F6236`, item
ids 162–186) created and each linked to its exact Shopify variant (`51205798232351` … `51270345851167`)
under `second-chance-eyewear-accessories`. imported=25/skipped=0/failed=0. All in INTAKE with physical
fields NULL (nothing invented); intake_type=sce_presale. Zero cert/QR/ownership/sale-link; Batches 1–8
(7–161) and all pre-existing records intact; Shopify unchanged; prod `6e36aa7` unchanged. SCA registry now
holds 180 catalog-linked UNCERTIFIED inventory records (Batches 1–9) — the expected result; ≈930 clean
candidates remain. Next = staff physical verification + per-pair authenticate→certify→QR labels.**

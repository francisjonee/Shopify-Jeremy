# SCA — Batch 10: Controlled Import of 25 Inventory Records (RESULT)

**Batch 10 is imported: the next 25 eligible catalog candidates are now registered as UNCERTIFIED SCA
eyewear records (ids 187–211, `SCA-5B0936FDD4A9`…`SCA-33619C87FA6B`), each atomically linked to its exact
existing Shopify variant, all in INTAKE status with every physical-identity field NULL (nothing invented)
and no authentication, certificate, QR, ownership, or sale association. Zero Shopify API calls; the store is
unchanged. Batches 1–9 (ids 7–186) and all pre-existing records are intact. The SCA registry now holds the
expected 205 catalog-linked UNCERTIFIED inventory records. Production code unchanged at `6e36aa7`.**
2026-11-02. **STOP.**

> Written for: the owner (Jeremy) + staff who will physically verify and certify these pairs. Catalog-derived,
> **unverified** inventory candidates — **not** physically verified, authenticated, or certified eyewear.

## Prechecks (all passed)
- **Production `6e36aa7`**, working tree clean, `kr-app` healthy; recent backup present
  (`sca-backup-20261102T021703Z.tar.gz.gpg`, 4.3G). Governance baseline `2354cb7` (180 imported, last id
  186) — matches the task's stated baseline exactly.
- Read the worklist (1,750 rows) and **read all current variant links directly from the production DB** —
  **180** linked variants (Batches 1–9); excluded every one. Same deterministic filter: `qty=1`, no
  accessory hint, eyewear title, non-pair/accessory/catalog/display/bulk excluded. Next 25 eligible in
  worklist order. (**905 clean candidates remain** in the worklist pool after this batch.)
- **Duplicate / multi-variant check (step 9):** 0 duplicate variant IDs in the selection; **no product
  contributes more than one selected variant** this batch.
- All 25 validated against the local mirror: **matched=25, active variant + active parent = 25, expected
  shop (`second-chance-eyewear-accessories.myshopify.com`) = 25, already_linked = 0, 25 distinct**, no
  non-active rows. Import CSV matched the review sheet byte-for-byte (set + order).
- **Category flag:** row 20 (id 206) is "Rudy Project SKERMO **Ski Goggles**" — goggles are eyewear but a
  different category from collectible frames; kept (it is genuine eyewear, not an accessory) and flagged for
  staff to confirm category during physical verification.

## What ran
CSV carried only `intake_type = sce_presale` + exact `shopify_variant_id`; all eight physical-identity
columns blank. `InventoryImportService`: **preview (zero mutation)** → **confirm**. Preview: `ok=true,
total=25, valid=25, warning=0, invalid=0, variant_valid=25, variant_invalid=0, variant_missing=0,
headers_ok=true, no unsupported/duplicate headers, can_confirm=true`; every row `status=VALID` with variant
`status=valid`. Variant eligibility validated against the local mirror only — **no Shopify API request**.

## Result — 25 UNCERTIFIED records created, each linked (import batch #10, sha `4ac681c1ca64…`)
| public_ref | id | variant_id | | public_ref | id | variant_id |
|---|---|---|---|---|---|---|
| `SCA-5B0936FDD4A9` | 187 | `51271814414623` | | `SCA-92B1884D5CBC` | 202 | `51329121648927` |
| `SCA-9F7B38A83D54` | 188 | `51272279851295` | | `SCA-B2D1A771EFD6` | 203 | `51352319000863` |
| `SCA-3C197AA01F04` | 189 | `51291803975967` | | `SCA-9E5C3BDE91D1` | 204 | `51352344592671` |
| `SCA-86918A22810B` | 190 | `51293594779935` | | `SCA-0A85EDFC1C66` | 205 | `51357134913823` |
| `SCA-5106E2A499C1` | 191 | `51298622374175` | | `SCA-BB81EF07AF81` | 206 | `51358256922911` |
| `SCA-23F1FD3BA132` | 192 | `51298648981791` | | `SCA-36492490DA76` | 207 | `51358919688479` |
| `SCA-8E50CEC86B6F` | 193 | `51300389191967` | | `SCA-02B9FF22A61B` | 208 | `51359968428319` |
| `SCA-89278DB87438` | 194 | `51300505223455` | | `SCA-80475B26D399` | 209 | `51360711901471` |
| `SCA-565B7529028E` | 195 | `51300568563999` | | `SCA-A4150DF172E1` | 210 | `51360779469087` |
| `SCA-9CA5DB9E5BBB` | 196 | `51320114643231` | | `SCA-33619C87FA6B` | 211 | `51360796541215` |
| `SCA-8CD983BDB426` | 197 | `51320126439711` | | | | |
| `SCA-431B27277B76` | 198 | `51320150982943` | | | | |
| `SCA-264E2A655FE4` | 199 | `51321080938783` | | | | |
| `SCA-EE1C266EAC18` | 200 | `51321525240095` | | | | |
| `SCA-14DB24D6BFFE` | 201 | `51321543524639` | | | | |

All on shop `second-chance-eyewear-accessories.myshopify.com`. `imported=25, skipped=0, failed=0,
complete=true`; every row `link=linked`. All 25 carry `intake_type=sce_presale` and **NULL** brand/model/
serial/year/country/materials/specs/sku/image. Attributed to no specific staff member (`actor_staff_ref =
NULL`, `linked_by = NULL`) — operator-run, owner-authorized.

## DB fingerprint — before → after
| table | before | after | Δ |
|---|---|---|---|
| `sca_eyewear_items` | 183 | **208** | +25 (ids 187–211) |
| `sca_eyewear_item_shopify_variant` | 180 | **205** | +25 |
| `sca_eyewear_shopify_link_audit` | 180 | **205** | +25 (all `action=link`) |
| `sca_inventory_imports` | 9 | **10** | +1 (batch #10) |
| `sca_inventory_import_rows` | 180 | **205** | +25 |
| `sca_authentications` | 4 | 4 | 0 |
| `sca_certifications` | 4 | 4 | 0 |
| `sca_qr_identifiers` | 3 | 3 | 0 |
| `sca_ownership_events` | 5 | 5 | 0 |
| `sca_shopify_sale_links` | 1 | 1 | 0 |

**All 25 new items (187–211): `lifecycle_state = INTAKE`, `registry_status = normal`, no owner/cert/qr**
(verified 25/25), 0 with any physical field set. New items referenced by sensitive tables: **auth=0, cert=0,
qr=0, ownership=0, sale=0**. **Batches 1–9 after import: items 7–186 = 180, links = 180 — unchanged.**
Ledger holds ten distinct batches. **Registry total: 205 catalog-linked UNCERTIFIED records — matches the
task's expected result.**

## Rejected / skipped rows
**None.** All 25 rows VALID in preview and imported; 0 warnings, 0 invalid, 0 skipped, 0 failed, 0
duplicates.

## Shopify safety confirmation
No Shopify API request, product/price/inventory change, deletion, listing change, CLI/credential change,
webhook replay, or reconciliation. Variant validation read the local mirror only. The Shopify store is
**completely unchanged**; the 25 variant IDs are referenced read-only as link targets.

## Idempotency / atomicity
Import identity = content hash (`4ac681c1ca64…`, UNIQUE) + per-row ledger; distinct from Batches 1–9.
Re-uploading this CSV would create nothing. Each row's item-create + variant-link ran in one transaction.

## Remaining prerequisites (owner / staff — NOT done here)
1. **Physical verification** per pair: confirm it exists; record brand/model/serial/year/country/materials/
   specs via the append-only metadata-correction flow (unlocked for these uncertified items), not re-import.
   Titles name likely brands (Christian Dior, Gucci, Ray-Ban, Giorgio Armani, Valentino, Paul Smith, Cazal,
   Chanel, Safilo, Polaroid, Rudy Project, etc.) but must be read from the frame. Many are SCE-re-lensed →
   confirm provenance wording. Confirm id 206 (Rudy Project ski goggles) category.
2. **Per pair: authenticate → finalize → certify** (mints QR) → **batch-print QR labels.**
3. Remaining worklist candidates (≈905 clean) onboard the same way (≤500-row CSVs, preview → owner sign-off
   → confirm).

## Safety posture (this task)
Owner-authorized production write limited to the 25 approved records. No code change (prod `6e36aa7`, tree
clean, healthy), no migration, no container recreate, no infrastructure change. No authentication/
certification/QR/ownership/sale-link. No Shopify API call or store change. Secure-claim RC `4bd88d2` not
deployed. Temp import script + CSV removed from `app/storage/app/`.

**STOP — Batch 10 imported: 25 UNCERTIFIED eyewear records (`SCA-5B0936FDD4A9` … `SCA-33619C87FA6B`, item
ids 187–211) created and each linked to its exact Shopify variant (`51271814414623` … `51360796541215`)
under `second-chance-eyewear-accessories`. imported=25/skipped=0/failed=0. All in INTAKE with physical
fields NULL (nothing invented); intake_type=sce_presale. Zero cert/QR/ownership/sale-link; Batches 1–9
(7–186) and all pre-existing records intact; Shopify unchanged; prod `6e36aa7` unchanged. SCA registry now
holds 205 catalog-linked UNCERTIFIED inventory records (Batches 1–10) — the expected result; ≈905 clean
candidates remain. Next = staff physical verification + per-pair authenticate→certify→QR labels.**

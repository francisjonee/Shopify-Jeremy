# SCA — Batch 5: Controlled Import of 25 Inventory Records (RESULT)

**Batch 5 is imported: the next 25 eligible catalog candidates are now registered as UNCERTIFIED SCA
eyewear records (ids 62–86, `SCA-831543615999`…`SCA-B382411A0855`), each atomically linked to its exact
existing Shopify variant, all in INTAKE status with every physical-identity field NULL (nothing invented)
and no authentication, certificate, QR, ownership, or sale association. Zero Shopify API calls; the store is
unchanged. Batches 1–4 (ids 7–61) and all pre-existing records are intact. Production code unchanged at
`6e36aa7`.** 2026-11-02. **STOP.**

> Written for: the owner (Jeremy) + staff who will physically verify and certify these pairs. Catalog-derived,
> **unverified** inventory candidates — **not** physically verified, authenticated, or certified eyewear.

## Prechecks (all passed)
- **Production `6e36aa7`**, working tree clean, `kr-app` healthy; recent backup present
  (`sca-backup-20261102T021703Z.tar.gz.gpg`, 4.3G). Governance baseline `deac657`.
- Read the worklist (1,750 rows); excluded **all 55 variants already linked via Batches 1–4** (read live
  from `sca_eyewear_item_shopify_variant`). Same deterministic filter: `qty=1`, no accessory hint, eyewear
  title, non-pair/accessory/catalog/display/bulk excluded. Next 25 eligible candidates in worklist order.
- All 25 validated against the local mirror: **matched=25, active variant + active parent = 25, expected
  shop (`second-chance-eyewear-accessories.myshopify.com`) = 25, already_linked = 0, 25 distinct**, no
  non-active rows. Import CSV matched the review sheet byte-for-byte (set + order).

## What ran
CSV carried only `intake_type = sce_presale` + exact `shopify_variant_id`; all eight physical-identity
columns blank. `InventoryImportService`: **preview (zero mutation)** → **confirm**. Preview: `ok=true,
total=25, valid=25, warning=0, invalid=0, variant_valid=25, variant_invalid=0, variant_missing=0,
headers_ok=true, no unsupported/duplicate headers, can_confirm=true`; every row `status=VALID` with variant
`status=valid`. Variant eligibility validated against the local mirror only — **no Shopify API request**.

## Result — 25 UNCERTIFIED records created, each linked (import batch #5, sha `161842cdd1ff…`)
| public_ref | id | variant_id | | public_ref | id | variant_id |
|---|---|---|---|---|---|---|
| `SCA-831543615999` | 62 | `51252436828447` | | `SCA-25F2F5733533` | 76 | `50995218940191` |
| `SCA-25BD8FE61948` | 63 | `50904710447391` | | `SCA-C61DDB5AE56E` | 77 | `50995870564639` |
| `SCA-5215AF63FA10` | 64 | `50905808961823` | | `SCA-87CE1CECFC34` | 78 | `51252443578655` |
| `SCA-FA87E4F621D9` | 65 | `51252417528095` | | `SCA-3AE3F083CEF6` | 79 | `51002722255135` |
| `SCA-CC634224B31E` | 66 | `50907416297759` | | `SCA-8097E00C4CB0` | 80 | `51002727334175` |
| `SCA-5009182FF588` | 67 | `50922247553311` | | `SCA-0FAFFD84D202` | 81 | `51252437778719` |
| `SCA-8EE199C9A8D4` | 68 | `50925100564767` | | `SCA-61108B3D552A` | 82 | `51002778517791` |
| `SCA-6ABE7C5F17AD` | 69 | `50930567545119` | | `SCA-0F65710C530F` | 83 | `51002781204767` |
| `SCA-761F0B924F30` | 70 | `51252412612895` | | `SCA-1694CBBC8006` | 84 | `51002790019359` |
| `SCA-231639DEBF5A` | 71 | `50932866613535` | | `SCA-6E8CF00E2916` | 85 | `51252433355039` |
| `SCA-993510BA6BE0` | 72 | `50938339066143` | | `SCA-B382411A0855` | 86 | `51018191700255` |
| `SCA-4A0FA2DBC60A` | 73 | `50968593498399` | | | | |
| `SCA-AF85E18057F8` | 74 | `51252438794527` | | | | |
| `SCA-EE7F836A57E0` | 75 | `50973166174495` | | | | |

All on shop `second-chance-eyewear-accessories.myshopify.com`. `imported=25, skipped=0, failed=0,
complete=true`; every row `link=linked`. All 25 carry `intake_type=sce_presale` and **NULL** brand/model/
serial/year/country/materials/specs/sku/image. Attributed to no specific staff member (`actor_staff_ref =
NULL`, `linked_by = NULL`) — operator-run, owner-authorized.

## DB fingerprint — before → after
| table | before | after | Δ |
|---|---|---|---|
| `sca_eyewear_items` | 58 | **83** | +25 (ids 62–86) |
| `sca_eyewear_item_shopify_variant` | 55 | **80** | +25 |
| `sca_eyewear_shopify_link_audit` | 55 | **80** | +25 (all `action=link`) |
| `sca_inventory_imports` | 4 | **5** | +1 (batch #5) |
| `sca_inventory_import_rows` | 55 | **80** | +25 |
| `sca_authentications` | 4 | 4 | 0 |
| `sca_certifications` | 4 | 4 | 0 |
| `sca_qr_identifiers` | 3 | 3 | 0 |
| `sca_ownership_events` | 5 | 5 | 0 |
| `sca_shopify_sale_links` | 1 | 1 | 0 |

**All 25 new items (62–86): `lifecycle_state = INTAKE`, `registry_status = normal`, no owner/cert/qr**
(verified 25/25), 0 with any physical field set. New items referenced by sensitive tables: **auth=0, cert=0,
qr=0, ownership=0, sale=0**. **Batches 1–4 after import: items 7–61 = 55, links = 55 — unchanged.** Ledger
holds five distinct batches (sha `38c53e02…`, `4e19d7e7…`, `de0eb7df…`, `7f422673…`, `161842cd…`).

## Rejected / skipped rows
**None.** All 25 rows VALID in preview and imported; 0 warnings, 0 invalid, 0 skipped, 0 failed, 0
duplicates.

## Shopify safety confirmation
No Shopify API request, product change/deletion, listing change, inventory adjustment, CLI/credential
change, webhook replay, or reconciliation. Variant validation read the local mirror only. The Shopify store
is **completely unchanged**; the 25 variant IDs are referenced read-only as link targets.

## Idempotency / atomicity
Import identity = content hash (`161842cdd1ff…`, UNIQUE) + per-row ledger; distinct from Batches 1–4.
Re-uploading this CSV would create nothing. Each row's item-create + variant-link ran in one transaction.

## Remaining prerequisites (owner / staff — NOT done here)
1. **Physical verification** per pair: confirm it exists; record brand/model/serial/year/country/materials/
   specs via the append-only metadata-correction flow (unlocked for these uncertified items), not re-import.
   Titles name likely brands (Vera Bradley, Neostyle, Maui Jim, Charles Jourdan, Jean-Louis Scherrer,
   Carrera, Odette Lunettes, Dolce & Gabbana, Ted Lapidus, Cazal, Porsche Design, Sophia Loren, Silhouette,
   etc.) but must be read from the frame. Many are SCE-re-lensed → confirm provenance wording.
2. **Per pair: authenticate → finalize → certify** (mints QR) → **batch-print QR labels.**
3. Remaining worklist candidates onboard the same way (≤500-row CSVs, preview → owner sign-off → confirm).

## Note on task provenance
This task's prompt originally arrived as a verbatim re-send of the Batch-4 instructions (stale baseline: gov
`415a77c`, "exclude the 30 previously imported"). Because Batch 4 had already completed, that premise no
longer matched production, so the import was **paused** and the owner reconfirmed intent. The owner then
issued a corrected **Batch 5** instruction (baseline `deac657`, "exclude all 55 previously imported"), which
is what was executed here.

## Safety posture (this task)
Owner-authorized production write limited to the 25 approved records. No code change (prod `6e36aa7`, tree
clean, healthy), no migration, no container recreate, no infrastructure change. No authentication/
certification/QR/ownership/sale-link. No Shopify API call or store change. Secure-claim RC `4bd88d2` not
deployed. Temp import script + CSV removed from `app/storage/app/`.

**STOP — Batch 5 imported: 25 UNCERTIFIED eyewear records (`SCA-831543615999` … `SCA-B382411A0855`, item
ids 62–86) created and each linked to its exact Shopify variant (`51252436828447` … `51018191700255`) under
`second-chance-eyewear-accessories`. imported=25/skipped=0/failed=0. All in INTAKE with physical fields NULL
(nothing invented); intake_type=sce_presale. Zero cert/QR/ownership/sale-link; Batches 1–4 (7–61) and all
pre-existing records intact; Shopify unchanged; prod `6e36aa7` unchanged. SCA registry now holds 80
catalog-linked UNCERTIFIED inventory records (Batches 1–5). Next = staff physical verification + per-pair
authenticate→certify→QR labels.**

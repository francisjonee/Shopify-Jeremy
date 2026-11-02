# SCA — Batch 4: Controlled Import of 25 Inventory Records (RESULT)

**Batch 4 is imported: 25 additional unique catalog candidates are now registered as UNCERTIFIED SCA
eyewear records (ids 37–61, `SCA-0EF887D4EF47`…`SCA-1E6804C9D8D7`), each atomically linked to its exact
existing Shopify variant, all in INTAKE status with every physical-identity field NULL (nothing invented)
and no authentication, certificate, QR, ownership, or sale association. Zero Shopify API calls; the store is
unchanged. Batches 1–3 (ids 7–36) and all pre-existing records are intact. Production code unchanged at
`6e36aa7`.** 2026-11-02. **STOP.**

> Written for: the owner (Jeremy) + staff who will physically verify and certify these pairs. Catalog-derived,
> **unverified** inventory candidates — **not** physically verified, authenticated, or certified eyewear.

## Prechecks (all passed)
- **Production `6e36aa7`**, working tree clean, `kr-app` healthy; recent backup present
  (`sca-backup-20261102T021703Z.tar.gz.gpg`, 4.3G).
- Read the worklist (1,750 rows); excluded **all 30 variants already linked via Batches 1–3** (the only
  links in production, read live from `sca_eyewear_item_shopify_variant`). Same deterministic filter as prior
  batches: `qty=1`, no accessory hint, eyewear title, non-pair/accessory/catalog/display/bulk items excluded.
  Next 25 eligible candidates in worklist order.
- All 25 validated against the local mirror: **matched=25, active variant + active parent = 25, expected
  shop (`second-chance-eyewear-accessories.myshopify.com`) = 25, already_linked = 0, 25 distinct variant
  IDs**, no non-active rows. Import CSV's 25 variant IDs matched the review sheet byte-for-byte (set + order).

## What ran
CSV carried only `intake_type = sce_presale` + exact `shopify_variant_id`; all eight physical-identity
columns blank. `InventoryImportService`: **preview (zero mutation)** → **confirm**. Preview: `ok=true,
total=25, valid=25, warning=0, invalid=0, variant_valid=25, variant_invalid=0, variant_missing=0,
headers_ok=true, no unsupported/duplicate headers, can_confirm=true`; every row `status=VALID` with variant
`status=valid`. Variant eligibility validated against the local mirror only — **no Shopify API request**.

## Result — 25 UNCERTIFIED records created, each linked (import batch #4, sha `7f42267314cd…`)
| public_ref | id | variant_id | | public_ref | id | variant_id |
|---|---|---|---|---|---|---|
| `SCA-0EF887D4EF47` | 37 | `50788457611551` | | `SCA-FAF7AD530A88` | 52 | `51252428865823` |
| `SCA-8822E9C3F778` | 38 | `50794236739871` | | `SCA-9CFC4200CA13` | 53 | `51252422541599` |
| `SCA-ECEFA0FA1C8D` | 39 | `50818462417183` | | `SCA-404D596CF463` | 54 | `50893332873503` |
| `SCA-F3D9691873BB` | 40 | `50824532132127` | | `SCA-F2DF550D4715` | 55 | `50897692393759` |
| `SCA-7119980083A5` | 41 | `50824626635039` | | `SCA-910C9724B898` | 56 | `50900801454367` |
| `SCA-38A9BC6FE5E2` | 42 | `51252426178847` | | `SCA-6B03730E3392` | 57 | `50900926890271` |
| `SCA-2B754B0F99F5` | 43 | `50854297207071` | | `SCA-08843FBA43D4` | 58 | `51252450394399` |
| `SCA-94D5C7F734CB` | 44 | `50854307627295` | | `SCA-5B70120CAE1D` | 59 | `51252425589023` |
| `SCA-FBAF34FF553B` | 45 | `51252436107551` | | `SCA-1BE865D24D6E` | 60 | `50903342448927` |
| `SCA-F40C48D65FF9` | 46 | `50854319882527` | | `SCA-1E6804C9D8D7` | 61 | `51252429455647` |
| `SCA-DFAECB619A44` | 47 | `51252410417439` | | | | |
| `SCA-A1A812FBCA6E` | 48 | `51252438597919` | | | | |
| `SCA-6A2591B526D7` | 49 | `51252410974495` | | | | |
| `SCA-4726D34B23BE` | 50 | `50892392562975` | | | | |
| `SCA-9E2E6582B758` | 51 | `50892995395871` | | | | |

All on shop `second-chance-eyewear-accessories.myshopify.com`. `imported=25, skipped=0, failed=0,
complete=true`; every row `link=linked`. All 25 carry `intake_type=sce_presale` and **NULL** brand/model/
serial/year/country/materials/specs/sku/image. Attributed to no specific staff member (`actor_staff_ref =
NULL`, `linked_by = NULL`) — operator-run, owner-authorized.

## DB fingerprint — before → after
| table | before | after | Δ |
|---|---|---|---|
| `sca_eyewear_items` | 33 | **58** | +25 (ids 37–61) |
| `sca_eyewear_item_shopify_variant` | 30 | **55** | +25 |
| `sca_eyewear_shopify_link_audit` | 30 | **55** | +25 (all `action=link`) |
| `sca_inventory_imports` | 3 | **4** | +1 (batch #4) |
| `sca_inventory_import_rows` | 30 | **55** | +25 |
| `sca_authentications` | 4 | 4 | 0 |
| `sca_certifications` | 4 | 4 | 0 |
| `sca_qr_identifiers` | 3 | 3 | 0 |
| `sca_ownership_events` | 5 | 5 | 0 |
| `sca_shopify_sale_links` | 1 | 1 | 0 |

**All 25 new items (37–61): `lifecycle_state = INTAKE`, `registry_status = normal`, no owner/cert/qr**
(verified 25/25). New items referenced by sensitive tables: **auth=0, cert=0, qr=0, ownership=0, sale=0**.
**Batches 1–3 after import: items 7–36 = 30, links = 30 — unchanged.** Ledger holds four distinct batches
(sha `38c53e02…`, `4e19d7e7…`, `de0eb7df…`, `7f422673…`).

## Rejected / skipped rows
**None.** All 25 rows VALID in preview and imported; 0 warnings, 0 invalid, 0 skipped, 0 failed, 0
duplicates.

## Shopify safety confirmation
No Shopify API request, product change/deletion, listing change, inventory adjustment, CLI/credential
change, webhook replay, or reconciliation. Variant validation read the local mirror only. The Shopify store
is **completely unchanged**; the 25 variant IDs are referenced read-only as link targets.

## Idempotency / atomicity
Import identity = content hash (`7f42267314cd…`, UNIQUE) + per-row ledger; distinct from Batches 1–3.
Re-uploading this CSV would create nothing. Each row's item-create + variant-link ran in one transaction.

## Remaining prerequisites (owner / staff — NOT done here)
1. **Physical verification** per pair: confirm it exists; record brand/model/serial/year/country/materials/
   specs via the append-only metadata-correction flow (unlocked for these uncertified items — see
   `docs/SCA-30-RECORD-OPERATIONAL-REVIEW.md`), not re-import. Titles name likely brands (Cébé, Jean Lafont,
   Sergio Tacchini, Persol, Nina Ricci, Emmanuelle Khanh, Nikon, Carrera, Calvin Klein, Silhouette, Persol,
   Odette Lunettes, etc.) but must be read from the frame. Many are SCE-re-lensed → confirm provenance
   wording.
2. **Per pair: authenticate → finalize → certify** (mints QR) → **batch-print QR labels.**
3. Remaining worklist candidates onboard the same way (≤500-row CSVs, preview → owner sign-off → confirm).

## Safety posture (this task)
Owner-authorized production write limited to the 25 approved records. No code change (prod `6e36aa7`, tree
clean, healthy), no migration, no container recreate, no infrastructure change. No authentication/
certification/QR/ownership/sale-link. No Shopify API call or store change. Secure-claim RC `4bd88d2` not
deployed. Temp import script + CSV removed from `app/storage/app/`.

**STOP — Batch 4 imported: 25 UNCERTIFIED eyewear records (`SCA-0EF887D4EF47` … `SCA-1E6804C9D8D7`, item ids
37–61) created and each linked to its exact Shopify variant (`50788457611551` … `51252429455647`) under
`second-chance-eyewear-accessories`. imported=25/skipped=0/failed=0. All in INTAKE with physical fields NULL
(nothing invented); intake_type=sce_presale. Zero cert/QR/ownership/sale-link; Batches 1–3 (7–36) and all
pre-existing records intact; Shopify unchanged; prod `6e36aa7` unchanged. SCA registry now holds 55
catalog-linked UNCERTIFIED inventory records (Batches 1–4). Next = staff physical verification + per-pair
authenticate→certify→QR labels.**

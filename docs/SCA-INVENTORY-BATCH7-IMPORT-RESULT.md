# SCA — Batch 7: Controlled Import of 25 Inventory Records (RESULT)

**Batch 7 is imported: the next 25 eligible catalog candidates are now registered as UNCERTIFIED SCA
eyewear records (ids 112–136, `SCA-793431B1EC41`…`SCA-98511CF2B53B`), each atomically linked to its exact
existing Shopify variant, all in INTAKE status with every physical-identity field NULL (nothing invented)
and no authentication, certificate, QR, ownership, or sale association. Zero Shopify API calls; the store is
unchanged. Batches 1–6 (ids 7–111) and all pre-existing records are intact. The SCA registry now holds the
expected 130 catalog-linked UNCERTIFIED inventory records. Production code unchanged at `6e36aa7`.**
2026-11-02. **STOP.**

> Written for: the owner (Jeremy) + staff who will physically verify and certify these pairs. Catalog-derived,
> **unverified** inventory candidates — **not** physically verified, authenticated, or certified eyewear.

## Prechecks (all passed)
- **Production `6e36aa7`**, working tree clean, `kr-app` healthy; recent backup present
  (`sca-backup-20261102T021703Z.tar.gz.gpg`, 4.3G). Governance baseline `449648b` (105 imported, last id
  111) — matches the task's stated baseline exactly.
- Read the worklist (1,750 rows) and **read all existing variant links directly from the production DB** —
  **105** linked variants (Batches 1–6); excluded every one. Same deterministic filter: `qty=1`, no
  accessory hint, eyewear title, non-pair/accessory/catalog/display/bulk excluded. Next 25 eligible in
  worklist order.
- All 25 validated against the local mirror: **matched=25, active variant + active parent = 25, expected
  shop (`second-chance-eyewear-accessories.myshopify.com`) = 25, already_linked = 0, 25 distinct**, no
  non-active rows. Import CSV matched the review sheet byte-for-byte (set + order).

## What ran
CSV carried only `intake_type = sce_presale` + exact `shopify_variant_id`; all eight physical-identity
columns blank. `InventoryImportService`: **preview (zero mutation)** → **confirm**. Preview: `ok=true,
total=25, valid=25, warning=0, invalid=0, variant_valid=25, variant_invalid=0, variant_missing=0,
headers_ok=true, no unsupported/duplicate headers, can_confirm=true`; every row `status=VALID` with variant
`status=valid`. Variant eligibility validated against the local mirror only — **no Shopify API request**.

## Result — 25 UNCERTIFIED records created, each linked (import batch #7, sha `e202dc67c306…`)
| public_ref | id | variant_id | | public_ref | id | variant_id |
|---|---|---|---|---|---|---|
| `SCA-793431B1EC41` | 112 | `51069250404639` | | `SCA-35309FCE7598` | 127 | `51252422344991` |
| `SCA-19B15FDFEC89` | 113 | `51069412606239` | | `SCA-047FE4752C8E` | 128 | `51128833933599` |
| `SCA-8AD37BDC0DC7` | 114 | `51252426735903` | | `SCA-68642866CB63` | 129 | `51128979095839` |
| `SCA-45817923053B` | 115 | `51071456477471` | | `SCA-990E3D56D020` | 130 | `51128984633631` |
| `SCA-0A7CD110CE64` | 116 | `51252431094047` | | `SCA-704C8D1E6BE9` | 131 | `51252448330015` |
| `SCA-A102EE1F9946` | 117 | `51252429029663` | | `SCA-8F350108BC32` | 132 | `51252423557407` |
| `SCA-5903782173EE` | 118 | `51252429979935` | | `SCA-E943B5A75BC6` | 133 | `51129422741791` |
| `SCA-FE2A63659B8F` | 119 | `51252410384671` | | `SCA-52F22B07865A` | 134 | `51129423593759` |
| `SCA-3BEB4DA4C876` | 120 | `51086742978847` | | `SCA-7D9C2AB12BC6` | 135 | `51252416315679` |
| `SCA-2F9C4C048D3B` | 121 | `51086852161823` | | `SCA-98511CF2B53B` | 136 | `51252425654559` |
| `SCA-359365E74E4D` | 122 | `51252431520031` | | | | |
| `SCA-887A222E0565` | 123 | `51252428898591` | | | | |
| `SCA-183B0744B000` | 124 | `51087820685599` | | | | |
| `SCA-885DD29BD996` | 125 | `51252412088607` | | | | |
| `SCA-BA67C75B1596` | 126 | `51252417691935` | | | | |

All on shop `second-chance-eyewear-accessories.myshopify.com`. `imported=25, skipped=0, failed=0,
complete=true`; every row `link=linked`. All 25 carry `intake_type=sce_presale` and **NULL** brand/model/
serial/year/country/materials/specs/sku/image. Attributed to no specific staff member (`actor_staff_ref =
NULL`, `linked_by = NULL`) — operator-run, owner-authorized.

## DB fingerprint — before → after
| table | before | after | Δ |
|---|---|---|---|
| `sca_eyewear_items` | 108 | **133** | +25 (ids 112–136) |
| `sca_eyewear_item_shopify_variant` | 105 | **130** | +25 |
| `sca_eyewear_shopify_link_audit` | 105 | **130** | +25 (all `action=link`) |
| `sca_inventory_imports` | 6 | **7** | +1 (batch #7) |
| `sca_inventory_import_rows` | 105 | **130** | +25 |
| `sca_authentications` | 4 | 4 | 0 |
| `sca_certifications` | 4 | 4 | 0 |
| `sca_qr_identifiers` | 3 | 3 | 0 |
| `sca_ownership_events` | 5 | 5 | 0 |
| `sca_shopify_sale_links` | 1 | 1 | 0 |

**All 25 new items (112–136): `lifecycle_state = INTAKE`, `registry_status = normal`, no owner/cert/qr**
(verified 25/25), 0 with any physical field set. New items referenced by sensitive tables: **auth=0, cert=0,
qr=0, ownership=0, sale=0**. **Batches 1–6 after import: items 7–111 = 105, links = 105 — unchanged.**
Ledger holds seven distinct batches (sha `38c53e02…`, `4e19d7e7…`, `de0eb7df…`, `7f422673…`, `161842cd…`,
`30f8f1db…`, `e202dc67…`). **Registry total: 130 catalog-linked UNCERTIFIED records — matches the task's
expected result.**

## Rejected / skipped rows
**None.** All 25 rows VALID in preview and imported; 0 warnings, 0 invalid, 0 skipped, 0 failed, 0
duplicates.

## Shopify safety confirmation
No Shopify API request, product change/deletion, listing change, inventory adjustment, CLI/credential
change, webhook replay, or reconciliation. Variant validation read the local mirror only. The Shopify store
is **completely unchanged**; the 25 variant IDs are referenced read-only as link targets.

## Idempotency / atomicity
Import identity = content hash (`e202dc67c306…`, UNIQUE) + per-row ledger; distinct from Batches 1–6.
Re-uploading this CSV would create nothing. Each row's item-create + variant-link ran in one transaction.

## Remaining prerequisites (owner / staff — NOT done here)
1. **Physical verification** per pair: confirm it exists; record brand/model/serial/year/country/materials/
   specs via the append-only metadata-correction flow (unlocked for these uncertified items), not re-import.
   Titles name likely brands (Lafont, Gianni Versace, Silhouette, Chloé, Oakley, Jimmy Choo, Kio Yamato,
   Titmus, Etnia Barcelona, Odette Lunettes, etc.) but must be read from the frame. Many are SCE-re-lensed →
   confirm provenance wording.
2. **Per pair: authenticate → finalize → certify** (mints QR) → **batch-print QR labels.**
3. Remaining worklist candidates onboard the same way (≤500-row CSVs, preview → owner sign-off → confirm).

## Safety posture (this task)
Owner-authorized production write limited to the 25 approved records. No code change (prod `6e36aa7`, tree
clean, healthy), no migration, no container recreate, no infrastructure change. No authentication/
certification/QR/ownership/sale-link. No Shopify API call or store change. Secure-claim RC `4bd88d2` not
deployed. Temp import script + CSV removed from `app/storage/app/`.

**STOP — Batch 7 imported: 25 UNCERTIFIED eyewear records (`SCA-793431B1EC41` … `SCA-98511CF2B53B`, item
ids 112–136) created and each linked to its exact Shopify variant (`51069250404639` … `51252425654559`)
under `second-chance-eyewear-accessories`. imported=25/skipped=0/failed=0. All in INTAKE with physical
fields NULL (nothing invented); intake_type=sce_presale. Zero cert/QR/ownership/sale-link; Batches 1–6
(7–111) and all pre-existing records intact; Shopify unchanged; prod `6e36aa7` unchanged. SCA registry now
holds 130 catalog-linked UNCERTIFIED inventory records (Batches 1–7) — the expected result. Next = staff
physical verification + per-pair authenticate→certify→QR labels.**

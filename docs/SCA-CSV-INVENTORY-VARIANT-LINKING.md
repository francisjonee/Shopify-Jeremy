# SCA — CSV Inventory Import with Shopify Variant Linking (DEVELOPMENT — awaiting review)

**The smallest safe automation from the inventory-onboarding strategy is now built on a development
branch: the bulk CSV import optionally links each newly registered physical pair to its exact Shopify
catalog variant, in one atomic transaction, reusing the deployed link safeguards and audit.** No
production deploy, no migration, no database writes, zero Shopify contact. Built from production
`4faf84d`; branch `feature/sca-csv-variant-link` = `9c1103c`. 2026-10-30. **STOP for review.**

## Objective
Extend the existing CSV inventory onboarding (`InventoryImportController` + `InventoryImportService`,
`/admin/sca/eyewear/import`, form → preview → confirm) so staff can OPTIONALLY associate each imported
item with its exact Shopify variant during import — removing the per-item manual linking step for
catalog-mapped inventory **without touching authentication, certification, or QR** (imported items stay
UNCERTIFIED). This is item [11] of `SCA-INVENTORY-ONBOARDING-STRATEGY.md`.

## Staff CSV format
Header row required. The eight intake columns are unchanged; **one optional column is added**:

```
intake_type,brand,model_name,frame_serial,year,country_of_origin,materials,original_specifications,shopify_variant_id
```

- `shopify_variant_id` (**optional**) — the exact **numeric Shopify variant id** to link the row's pair
  to. Leave it blank (or omit the column entirely) to onboard a row **unlinked** — identical to today's
  behaviour.
- There is **no shop column**: links always target the single configured expected store
  (`sca-shopify.expected_shop_domain`). A variant id that exists only under another store resolves to
  "not found" here (cross-store references are rejected, never linked).
- Several rows may carry the **same** variant id — many physical pairs of one SKU each get their own SCA
  identity and all link to that one variant (the link table is many-items → one-variant).

## How a reference is validated (local mirror only — never contacts Shopify)
During **preview** (zero mutation), each non-empty `shopify_variant_id` is resolved against the **local
synced catalog mirror**, scoped to the expected shop, mirroring `ShopifyProductLinkService` eligibility:

1. **Format** — must match `^[0-9]{1,24}$`, else the row is INVALID (`invalid_format`).
2. **Active variant for the expected shop** — `sca_shopify_variants` where `shop_domain = expected AND
   shopify_variant_id = <ref> AND status = active`. Zero rows → INVALID (`variant_not_found`: covers
   unknown, archived, and cross-store). More than one → INVALID (`variant_ambiguous`; the DB
   `UNIQUE(shop_domain, shopify_variant_id)` makes this practically impossible, but we fail closed
   rather than pick one).
3. **Active parent product** — the variant's product must exist for the shop and be `active`, else
   INVALID (`variant_not_eligible`). This matches link-time eligibility exactly, so a preview-valid
   mapping links successfully at confirm (unless the catalog changes in between — see below).

**A supplied-but-unresolvable reference makes that ROW invalid** (reported, not imported). We never
import the item with a bad link, and we never silently onboard it unlinked — staff fix the id and
re-upload. A blank cell (or no column) is simply unlinked.

## What confirm does (atomic, idempotent, fail-closed)
For each importable row, inside the **same transaction** as the canonical `ItemService::create` and the
import-ledger insert:
- if the row carries a **valid** mapping, call the **sole link writer**
  `ShopifyProductLinkService::link($itemId, $shop, $productId, $variantId, $actor)` — reusing its
  eligibility re-check against the live mirror, its `UNIQUE(eyewear_item_id)` one-variant-per-item guard,
  and its append-only audit row;
- on any non-success outcome, throw `LinkRejectedException` → the **whole row rolls back** (no orphan
  item, no ledger row, no link, no partial assignment). The row is reported `failed`; re-preview/confirm
  resumes it cleanly.

Because the link is re-validated at confirm, a variant **archived between preview and confirm** is caught
(that row fails and rolls back) while sibling valid rows still import.

### Guarantees preserved
- **500-row cap** (`MAX_ROWS`), **idempotency/resume**, **insert-only**: unchanged. The durable ledger
  (`sca_inventory_imports.content_sha256` UNIQUE batch + `sca_inventory_import_rows`
  `UNIQUE(import_id, source_line)`) remains the single idempotency authority. A re-upload of the same
  file skips already-imported rows and **preserves their links** (never duplicates item or link).
- **Batch identity** now folds the variant reference into `content_sha256` so two files that differ only
  in their variant assignment are distinct batches. It is **null-stable**: a CSV with **no** variant
  column hashes exactly as before (its prior batch identity is unchanged).
- **Human authentication + certification + QR are untouched.** Imported items remain UNCERTIFIED; linking
  is a catalog reference only and creates **no** authentication, certificate, QR, ownership, or claim
  row. (Covered by a no-provenance test.)

## Authorization
Importing is gated by `sca.eyewear.create` as before. A CSV that **assigns variants** additionally
requires the dedicated `sca.eyewear.shopify.link` ACL — the same authority the per-item link UI uses.
If the actor lacks it, the whole confirm is blocked with an actionable message (no confirm token is
minted, and the permission is re-checked at confirm); we never silently drop the links to import
unlinked. A CSV with no variant references needs only `sca.eyewear.create`.

## Preview / result UI
- **Form**: documents the optional column and its rules.
- **Preview**: a "Shopify variant links" summary (valid / invalid / no-variant counts), a per-row variant
  cell (→ variant id when valid, "invalid: <ref>" otherwise), the invalid reason in Notes, and a
  blocking notice when the actor lacks the link permission.
- **Result**: a "Shopify link" column showing `linked` per row.

## Changed files (6; branch `feature/sca-csv-variant-link` @ `9c1103c`)
- `app/packages/Sca/Registry/src/Services/InventoryImportService.php` — optional `shopify_variant_id`
  column; `resolveVariant()` (local-mirror, expected-shop, eligibility-mirroring); import-time link in the
  per-row transaction (throws `LinkRejectedException` on non-success); variant-aware counts;
  null-stable content hash. Constructor now also takes `ShopifyProductLinkService` (auto-wired).
- `app/packages/Sca/Registry/src/Http/Controllers/InventoryImportController.php` — `sca.eyewear.shopify.link`
  gate for linking imports (token withheld + re-checked at confirm); passes `canLink`/`linkBlocked`.
- `app/packages/Sca/Registry/src/Resources/views/eyewear/import/{form,preview,result}.blade.php` — docs,
  mapping display + counts + block notice, link-outcome column.
- `app/tests/Feature/Sca/InventoryImportVariantLinkTest.php` (new) — focused tests.

## Migration requirements
**NONE.** The catalog mirror (`sca_shopify_products`, `sca_shopify_variants`), the link table
(`sca_eyewear_item_shopify_variant`), and its audit table are already deployed. This change adds no
table, no column, and no migration.

## Testing plan
Focused tests (`InventoryImportVariantLinkTest`) cover: valid linking (+ audit + INTAKE-only projection);
many items → one variant; each invalid-reference class (malformed, unknown, archived variant, archived
product, cross-store); blank cell and no-column → unlinked; batch identity (null-stable without the
column, distinct when the variant value differs); idempotent resume preserving the link without
duplicates; a link that becomes ineligible between preview and confirm failing just that row and rolling
back its item while siblings import, then resuming cleanly; no provenance created by a linked import; and
the `sca.eyewear.shopify.link` ACL enforced over HTTP (blocked without it, succeeds with it).

**Per strict safety, the DB-changing tests were NOT run here** — running them requires a separately
authorized disposable-DB isolation (internal network, egress blocked, scoped `sca_test` user on
`sca_domain_test`, Http::fake, never `sca_krayin`). Non-destructive checks run: `php -l` on the changed
PHP files and the new test (all clean), and the three Blade views compiled + linted (directives). Next
step on approval: the isolated disposable-DB regression, then a code-only release candidate off
production.

## Safety posture (this task)
No production deployment / merge / migration / DB write. Zero live Shopify API requests (resolution reads
only the local mirror; the one external-system interface, `ShopifyProductLinkService`, reads only synced
catalog tables). No Shopify store/CLI/credential access. No real imports. No automatic
authentication / certification / QR / order-assignment / ownership. No email configuration. No R0/R0b/R0c
deployment (secure-claim RC `4bd88d2` remains DEPLOYMENT-BLOCKED and untouched). No unrelated Option C.

**STOP — development complete on `feature/sca-csv-variant-link` (`9c1103c`), pushed. Optional
`shopify_variant_id` column links each imported pair to its exact Shopify variant atomically, reusing the
deployed link safeguards + audit; invalid/unknown/archived/cross-store/ambiguous references reject the
row; blank/no-column behaves as before; 500-cap, idempotency/resume, insert-only, and human auth/cert/QR
all preserved; no migration. Tests written + syntax-checked, NOT run (DB isolation pending). Awaiting
review before the isolated regression and release-candidate steps.**

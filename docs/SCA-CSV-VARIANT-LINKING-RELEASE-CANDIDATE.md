# SCA — CSV Inventory Variant Linking: Production Release Candidate

**A dedicated, production-based release candidate for the CSV inventory variant-linking enhancement is
prepared and pushed. It is byte-identical to the tested development head and changes exactly six files
with no migration.** RELEASE-PREPARED — awaiting independent review and a separate deployment
authorization. No production merge/deploy/DB write/restart; zero Shopify contact. 2026-10-30. **STOP.**

## SHAs
- **Production (unchanged):** `4faf84d49b4a67823aff31ba0dc926bd91110c16` (live tree clean, `kr-app`
  healthy throughout).
- **Tested development head:** `79b0184` (branch `feature/sca-csv-variant-link`; isolated regression
  173 tests / 651 assertions / 0 failures — see `SCA-CSV-VARIANT-LINKING-VL9-VL10-TEST-CORRECTION.md`).
- **Release candidate:** **`a53eff321580f7338c2192bf0cdb0ef8375bfea7`** on branch
  **`release/sca-csv-variant-link`**, parent = `4faf84d` (single clean RC commit).

## Byte-identity to the tested tree
The RC tree is **byte-identical** to the tested head `79b0184`: `git diff --quiet 79b0184 <RC>` returns
no difference (verified before and after commit). The RC is a single commit off production carrying only
the net tested change.

## Changed files — exactly six (no migration, no schema change)
```
 app/packages/Sca/Registry/src/Http/Controllers/InventoryImportController.php |  18 +-
 app/packages/Sca/Registry/src/Resources/views/eyewear/import/form.blade.php  |   3 +
 app/packages/Sca/Registry/src/Resources/views/eyewear/import/preview.blade.php |  31 ++
 app/packages/Sca/Registry/src/Resources/views/eyewear/import/result.blade.php |   8 +
 app/packages/Sca/Registry/src/Services/InventoryImportService.php            | 197 +-
 app/tests/Feature/Sca/InventoryImportVariantLinkTest.php                     | 410 +
 6 files changed, 656 insertions(+), 11 deletions(-)
```
No file under any `src/Database/Migrations` directory is touched (`git diff --quiet 4faf84d <RC> --
'…/Migrations'` is empty). **Zero new migrations / zero schema change** — the catalog
(`sca_shopify_products`, `sca_shopify_variants`), link (`sca_eyewear_item_shopify_variant`), and audit
(`sca_eyewear_shopify_link_audit`) tables are already deployed.

## Verified invariants (on the RC tree)
- **[8] Protections intact:** `MAX_ROWS = 500`; idempotency/resume via `content_sha256` UNIQUE batch +
  `sca_inventory_import_rows UNIQUE(import_id, source_line)`; per-row `DB::transaction` (item + ledger +
  optional link + link-audit commit or roll back together).
- **[9] Backward-compatible column:** `ALLOWED_HEADERS` is still exactly the 8 intake fields (so only
  those reach `ItemService::create`); `shopify_variant_id` is accepted via `ACCEPTED_HEADERS` but
  optional. `content_sha256` is **null-stable** — a CSV omitting the column hashes exactly as before, so
  existing files and batch identities are unaffected.
- **[10] Local mirror only:** the service has no outbound HTTP (no `Http::`/Guzzle/Shopify client);
  variant resolution reads only `sca_shopify_variants` + `sca_shopify_products`. SCA never contacts
  Shopify.
- **[11] No provenance side effects:** imported items remain **UNCERTIFIED**; the path creates no
  authentication, certificate, QR, ownership, or sale-link. Linking is catalog-reference only.
- **[12] Excluded:** no claim / R0 / R0b / R0c / Option-C files are in the RC diff.
- **[13] Syntax:** `php -l` clean on the controller, service, and test; views were Blade-compiled in the
  development task and are byte-identical here.

## Deployment plan (code-only; for a SEPARATE authorization — NOT executed here)
This is a code-only change with **no migration**, so the standard code-only fast-forward applies (same
pattern as prior code-only deploys; the live `app/` is a bind-mount, opcache `validate_timestamps=On`, no
Docker recreate):
1. Pre-checks: confirm live tree at `4faf84d`, clean; `kr-app` healthy; take the usual pre-deploy backup.
2. On the live tree advance to the RC: `git merge --ff-only a53eff3` (fast-forward only — refuse if not a
   clean FF).
3. Clear compiled views: `php artisan view:clear` (and `config:clear` if config cache is in use).
4. Reload PHP: `apachectl -k graceful` (no container recreate, no restart of `kr-mariadb`).
5. Post-deploy smoke (read-only, staff): open `/admin/sca/eyewear/import`; upload a tiny CSV **without**
   the new column → preview behaves as before; optionally a 1-row CSV **with** a valid
   `shopify_variant_id` → preview shows a valid mapping (do not confirm unless a real onboarding is
   intended and separately authorized).
6. No migration step (there is none).

## Rollback procedure
If any issue is observed, revert the code to production (this is a **backward move to the previous
commit, not a fast-forward**):
1. On the live tree: `git checkout 4faf84d -- app/packages/Sca/Registry app/tests/Feature/Sca/InventoryImportVariantLinkTest.php`
   (or `git reset --hard 4faf84d` on the deploy branch) to restore the exact production state of the six
   files.
2. `php artisan view:clear` then `apachectl -k graceful`.
3. No database rollback is required — the change adds no migration and writes nothing until a staff
   member confirms an import; nothing in the schema changes.
Because there is no migration and no schema change, rollback is purely a code revert + view-cache clear +
graceful reload.

## Safety posture (this task)
No production merge/deploy/DB write/migration/restart; no real CSV import; no certification/QR/ownership/
transfer; no email. Zero Shopify API requests, store modifications, CLI, or production credentials. The
secure-claim RC `4bd88d2` is preserved as **RELEASE-PREPARED / DEPLOYMENT-BLOCKED** and was not touched.

**STOP — RC `a53eff3` on `release/sca-csv-variant-link` (parent prod `4faf84d`), byte-identical to tested
`79b0184`, exactly six files, no migration, pushed. Invariants [8]–[13] verified. Production unchanged at
`4faf84d` (clean, healthy); release worktree removed; no disposable-DB leftovers. Awaiting independent
review and a separate controlled-deployment authorization.**

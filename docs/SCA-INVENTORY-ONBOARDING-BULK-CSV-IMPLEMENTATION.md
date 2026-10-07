# SCA Inventory Onboarding / Bulk CSV — implementation candidate (NOT merged/deployed)

**Date:** 2026-10-07 · **Status: IMPLEMENTED + TESTED + PUSHED on a candidate branch; SOP committed. NOT merged, NOT deployed. Live tree restored to `main`; production byte-identical (prod DB NOT migrated).** For ChatGPT candidate audit. Approved direction gov `10f7d70` (Option B) + the batch+row ledger refinement.

## Candidate identity
- **Branch:** `origin/feat/sca-inventory-onboarding-bulk-csv`
- **Base SHA:** `1b029fd981388da76b66d50c7a851f3254aa1e5d` (= deployed `main`; merge-base)
- **Head SHA:** `a63008950b644c733a950cde63661e58aa435c35` (remediation; was audited-FAIL `4ad70519…`, now 2 commits)

## Remediation (audit FAIL → fixed; architecture unchanged)
Changed files vs the audited head `4ad70519`: `InventoryImportService.php`, `InventoryImportController.php`, `eyewear/import/preview.blade.php`, `InventoryImportTest.php` (+ `bi3` rows made 8-field). No schema/route/ACL/lifecycle/retry redesign.
- **R1 — duplicate CSV headers rejected.** `preview()` detects repeated normalized header names (after BOM/trim/lowercase) via `array_count_values`, returns `duplicate_headers`, sets `headers_ok=false` + `can_confirm=false` (no session confirm token issued), and surfaces them in the preview ("Duplicate columns — import blocked"); `import()` refuses with `error='duplicate_headers'`. Never silently picks first/last. (`bi13`)
- **R2 — malformed row width rejected.** `preview()` marks any data row whose cell count ≠ header count **INVALID** with "Expected N columns, found M." (attrs `[]`), per source line; it is never normalized and never reaches `ItemService::create` (importable excludes INVALID). Covers extra and missing cells; no shift/truncate/fill. (`bi14` extra, `bi15` missing)
- **R3 — row-ledger immutability proven.** New `bi16` creates a legitimate `sca_inventory_import_rows` record and asserts UPDATE and DELETE are both blocked (SQLSTATE 45000), complementing `bi10` (batch table).
- Operator SOP updated to state duplicate headers and malformed-width rows are rejected.

## Migrations added (2 — additive, new standalone tables only)
- `2026_10_07_000001_create_sca_inventory_imports` and `2026_10_07_000002_create_sca_inventory_import_rows` → prod migration count 120 → **122 at deploy** (not yet applied to prod; applied only to `sca_domain_test` for the test gate).
- **No existing table altered**; `sca_eyewear_items` and all provenance tables are untouched.

## Exact changed files
New: the 2 migrations · `packages/Sca/Registry/src/Services/InventoryImportService.php` · `packages/Sca/Registry/src/Http/Controllers/InventoryImportController.php` · `packages/Sca/Registry/src/Resources/views/eyewear/import/{form,preview,result}.blade.php` · `tests/Feature/Sca/InventoryImportTest.php`.
Modified (2): `packages/Sca/Registry/src/Routes/admin-routes.php` (new `admin.sca.eyewear.import.*` group, ACL `sca.eyewear.create`) · `packages/Sca/Registry/src/Resources/views/eyewear/index.blade.php` ("Import CSV" button beside "New Eyewear Item", `sca.eyewear.create`-gated).
**Untouched:** `ItemService`, provenance services/models/tables, `sca_eyewear_items` schema, ACL definitions, Shopify, QR/cert/auth/ownership/service, no background jobs.

## Schema details (both append-only; `no_update`/`no_delete` SQLSTATE-45000 triggers)
- **`sca_inventory_imports`** (batch audit/idempotency): `id`; `content_sha256` char(64) **UNIQUE**; `original_filename`; `actor_staff_ref` (soft, nullable, no FK); `total_rows`, `valid_count`, `warning_count`, `invalid_count`; `created_at`. No `updated_at`.
- **`sca_inventory_import_rows`** (per-source-row reconciliation, success-only): `id`; `import_id` FK→`sca_inventory_imports`; `source_line`; `row_fingerprint` (sha256 of the normalized row); `eyewear_item_id` FK→`sca_eyewear_items`; `public_ref` char(20); `created_at`; **UNIQUE(import_id, source_line)**. No `updated_at`.

## Transaction / retry / idempotency semantics
- **Preview** (`POST import/preview`): parse + per-row validate (reusing the `StoreEyewearItemRequest` rule contract) + classify **INVALID / WARNING / VALID**; **zero mutation**. Unsupported headers and >500 rows **block confirm**. The server-validated preview is held in the session under a **single-use token**; the raw CSV is not persisted.
- **Confirm** (`POST import/confirm`): consumes the token (single-use), then `import()`:
  - **Batch identity first:** find-or-create `sca_inventory_imports` by `content_sha256` (UNIQUE). A finished batch re-upload is a no-op; a partial one resumes.
  - **Per row (VALID, + WARNING only if acknowledged):** if `(import_id, source_line)` already in the row ledger → **skip** (durable success, never re-created). Else **one `DB::transaction` { `ItemService::create($attrs)` → insert the row-ledger record }** — the item and its reconciliation row commit atomically, and `UNIQUE(import_id, source_line)` makes a duplicate/concurrent attempt roll back the would-be duplicate item. A per-row throwable is caught, recorded as `failed` in the result, and does not persist a ledger row (so it stays retriable); siblings continue.
  - **Resume:** re-uploading the same file (same hash) imports only source lines not already in the ledger → a transient mid-batch failure can never duplicate the already-successful rows (proved by `bi8`).
  - **Never overwrites** an existing item (insert-only; `public_ref` always system-generated via `ItemService`).

## Lifecycle boundary (verified by tests)
Every imported row → exactly one `sca_eyewear_items` row + one `INTAKE`/`normal` `sca_item_current_state` projection, via `ItemService::create`. **No authentication, certification, QR identity, ownership, claim, sale-link, service event, media, or SKU/catalog state** is created (`bi4` asserts all of these are zero for imported items).

## Security
Upload validated server-side (`file`, ≤1 MB, `.csv`/`.txt` extension); content treated as untrusted and only read as strings + validated; row cap 500 enforced server-side (`bi3`); all CSV-derived values rendered through escaped Blade (`{{ }}`) so spreadsheet content cannot become executable HTML; no CSV download implemented (so no formula-injection surface); raw CSV not persisted (session handoff + durable ledger reconciliation only).

## Tests
- **Focused `InventoryImportTest` 12/12:** `bi1` preview zero-mutation; `bi2` unsupported headers surfaced + block (incl. a `public_ref`/`sku` column, so client-supplied identity can never be imported); `bi3` >500 rejected; `bi4` valid → INTAKE-only + no downstream artifacts + `SCA-<12hex>` refs; `bi5` invalid never reaches `ItemService`; `bi6` duplicate-warning needs ack, then resumes; `bi7` exact re-import no duplication (ledger skip + reclassification); `bi8` partial-batch resume imports only missing rows; `bi9` `UNIQUE(import_id, source_line)` blocks a duplicate source line; `bi10` ledger UPDATE/DELETE blocked (45000); `bi11` ACL (unauth → login, no-`sca.eyewear.create` → 403 on form/preview/confirm, with-perm 200); `bi12` HTTP double-confirm (single-use token) cannot duplicate.
- **Focused `InventoryImportTest` 16/16** after remediation (adds `bi13` duplicate-header, `bi14` extra-cell, `bi15` missing-cell, `bi16` rows-append-only).
- **Full governed gate:** `… -e DB_DATABASE=sca_domain_test … php artisan test tests/Feature/Sca` → **871 passed / 4717 assertions**, exit 0 (855 baseline + 16 import). (Pre-remediation was 867/4691 with 12 import tests.)

## Production-safety verification (post-restore)
Tree restored to `main` @ `1b029fd`; vendor re-pruned `--no-dev`. Prod DB (`sca_krayin`) **migrations 120** (the 2 new tables are **absent** in prod — applied only to the disposable `sca_domain_test`); `PROD_FP = 62b2e42fe409b4ec91f3381b35da819e` (unchanged); import route absent on main; phpunit pruned; `/collector` 302, smsrocket.io 302, Shopify webhook → **401**. No merge, no deploy, no prod DB mutation, no Shopify action.

## Operator documentation
`docs/SOP-INVENTORY-ONBOARDING-CSV.md` — CSV column contract, preview/confirm flow, duplicate-warning meaning, reconciliation (row → generated `public_ref`), and the 500-row cap.

## Closure
On passing candidate + deployment audit, governance will state **SCA Inventory Onboarding — CLOSED** (bulk onboarding to INTAKE; downstream authenticate/certify/QR remain the normal per-item staff flow — no follow-on slice).

See `docs/SCA-INVENTORY-ONBOARDING-BULK-CSV-DISCOVERY.md`.

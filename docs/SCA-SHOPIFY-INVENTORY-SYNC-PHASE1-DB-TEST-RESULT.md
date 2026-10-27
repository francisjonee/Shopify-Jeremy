# SCA — Shopify Inventory Sync Phase 1: Isolated Database Test RESULT

**Authorized single isolated DB-testing session executed. VERDICT: PASS — 21 tests, 67 assertions, 0 failures, 0 warnings.** Uniquely-named disposable database only; dropped and verified afterward; production `sca_krayin` unchanged. No production migration, merge, deploy, live-Shopify, OAuth, webhook registration/scheduling; Option C + 139/140 untouched; no full-regression/baseline run. 2026-10-27. **STOP for independent ChatGPT review.**

## [1] Candidate & harness SHA

- Reviewed catalog/service code: **`e96700b`** (byte-identical here).
- Run at branch tip **`9f05c8a`** = `e96700b` + a **test-only** change: `ShopifyProductCatalogSyncTest::setUp` DB guard parameterized via `SCA_TEST_DB` (default `sca_domain_test`, ALWAYS refuses `sca_krayin`) so the suite can target a uniquely-named disposable DB per this authorization. No product/service logic changed. Staged in an isolated worktree; live tree stayed `main 6ebe968`, clean.

## [2] Non-destructive syntax checks

`php -l` on the (edited) test file — No syntax errors. (All Phase-1 files already linted clean in prior rounds.) Dev dependencies (phpunit/pest) were built into the isolated worktree's own `vendor/` via `composer install --no-scripts --prefer-dist` in an ephemeral container (the live vendor is prod `--no-dev`); this touched only the disposable worktree, never the live app.

## [3] Uniquely-named disposable database, created only after an existence check

- Name: **`sca_shopify_p1_74d640a161a9`** (random per-run suffix).
- Existence pre-check returned 0 → `CREATE DATABASE` (no `IF NOT EXISTS`); granted `ALL` to the app user on **that DB only**.
- Baseline `SHOW DATABASES` before: `information_schema, mysql, performance_schema, sca_krayin, sys` (no stray disposable DB).

## [4] Connection isolation verified (both effective and live)

Before any test, a booted-app probe asserted: `getenv(DB_DATABASE)` == `DB::connection()->getDatabaseName()` == live `SELECT DATABASE()` == `sca_shopify_p1_74d640a161a9`, and that the target is not `sca_krayin`. Result: `ISOLATION OK: effective=sca_shopify_p1_74d640a161a9 live=sca_shopify_p1_74d640a161a9`. The ephemeral container reached MariaDB as `kr-mariadb` on `sca_internal` with the app user; `DB_DATABASE` was injected so only the disposable DB was ever addressed.

## [5] Migration + suite execution

Full schema migrated into the disposable DB, including the two new catalog migrations (`2026_10_27_000001_create_sca_shopify_products`, `_000002_create_sca_shopify_variants`) — exit 0. Then `vendor/bin/phpunit tests/Feature/Sca/ShopifyProductCatalogSyncTest.php`:

```
PHPUnit 11.5.50 — PHP 8.3.33
..................... 21 / 21 (100%)
OK (21 tests, 67 assertions)   Time 00:02.672
```

## [6] Behaviors verified (all ✔)

- Duplicate delivery → exactly one row (DB UNIQUE).
- Update changes catalog **and touches no provenance**.
- Stale (older `updated_at`) event does not overwrite newer data.
- Missing product id rejected / stored nothing; missing variant id skipped, product stored.
- Delete sets reversible `pending_delete` (not immediate archive; variants kept).
- Incomplete / null / malformed / empty / **partially-malformed** / non-array-entry / **duplicate-id** variant collections do **not** archive existing variants; a fully-valid snapshot still archives a genuinely removed variant.
- Newer update after delete **revives** the product.
- **Reconciliation** confirms deletion only when the product is absent from the live sweep (present → stays pending).
- Missing / invalid / per-variant unorderable timestamps **fail closed** (no overwrite).
- Variant quantity > 1 → **one catalog row + zero items**.
- Webhook replay is idempotent; bad signature → 401, writes nothing.

## [7] Catalog-only invariant confirmed

After the run, the disposable DB held **0 rows** in `sca_eyewear_items`, `sca_item_current_state`, `sca_ownership_events`, `sca_certifications`, `sca_qr_identifiers`, `sca_external_claim_grants` — and 0 in `sca_shopify_products`/`sca_shopify_variants` (each test rolls back under `DatabaseTransactions`). Catalog sync created no physical eyewear item, ownership, certificate, passport, QR code, or private claim link. (In-test, `update_changes_catalog_but_touches_no_provenance` and `variant_quantity_gt_one…` assert zero provenance rows directly.)

## [8] Counts

**21 tests, 67 assertions, 0 failures, 0 skipped, 0 warnings**, ~2.7 s.

## [9] Cleanup verified

`REVOKE ALL` on the disposable DB from the app user, then `DROP DATABASE` — the DB is gone (existence check = 0), no residual grant referencing it (0), and `SHOW DATABASES` is back to the baseline set. The isolated worktree (and its built vendor) was removed; live tree `main 6ebe968`, clean.

## [10] Production unchanged

`sca_krayin` after = baseline: items/state/owns/certs = **3 / 3 / 5 / 4**, max migration batch **27**. `kr-app` running; `/admin/login` → **200**. Only the disposable DB was ever created/dropped; production schema, data, and migration history were not touched.

## Remaining activation (owner-authorized; still pending)

Add `read_products` scope + merchant OAuth re-consent; register `products/*` webhooks; deploy (code + 2 additive migrations) via the minimal-deploy discipline; run the initial import; optionally schedule reconciliation.

**STOP — isolated DB test PASS delivered for independent ChatGPT review. Disposable DB dropped; production unchanged; no merge/deploy/migration/live-Shopify/OAuth/webhook action; no additional regression/baseline run.**

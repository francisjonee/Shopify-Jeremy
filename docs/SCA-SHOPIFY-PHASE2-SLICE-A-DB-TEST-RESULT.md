# SCA — Shopify Phase 2 Slice A: Isolated DB Test RESULT

**Authorized single isolated DB-testing session for Slice A (`5c1aa23`). VERDICT: PASS — 10 tests, 29 assertions, 0 failures / 0 skips / 0 warnings.** Uniquely-named disposable DB only; dropped and verified; production `sca_krayin` unchanged and the new table NOT migrated to prod. No prod migration/merge/deploy, no Shopify change, no live webhook, no Option C, no full regression. 2026-10-28. **STOP for independent review.**

## [1] Candidate & isolation

- `origin/feat/sca-shopify-phase2-linking` = **`5c1aa23e45f78f33a5cd8c590b907dd049595417`**; built in an isolated worktree at that SHA (live tree stayed `main 905ea7d`, clean). Dev vendor (phpunit) built in the worktree (live vendor is `--no-dev`).
- **[2] Disposable DB:** `sca_p2link_test_a2996cc08156` — created only after an existence check returned 0; granted to the app user on that DB only. `SHOW DATABASES` before = `information_schema, mysql, performance_schema, sca_krayin, sys` (no stray disposable DB).
- **[3] Isolation verified:** a booted-app probe confirmed `getenv(DB_DATABASE)` == `DB::connection()->getDatabaseName()` == live `SELECT DATABASE()` == `sca_p2link_test_a2996cc08156`, and ≠ `sca_krayin` → `ISOLATION OK`.

## [4] Migration (disposable DB only)

Full schema migrated into the disposable DB, including the new `2026_10_28_000001_create_sca_eyewear_item_shopify_variant` (DONE); the link table is present in the disposable DB (1) and **absent from prod** (see [12]).

## [5]–[10] Test results

`vendor/bin/phpunit tests/Feature/Sca/ShopifyProductLinkTest.php` → **OK (10 tests, 29 assertions)**, 0 failures/skips/warnings, PHPUnit 11.5.50 / PHP 8.3.33, ~1.1 s:

| Behavior | ✔ |
|---|---|
| [6] One variant → many items (two items link to the same variant) | ✔ `one_variant_links_to_many_items` |
| [7] One item cannot silently link to a different variant | ✔ `same_item_different_variant_is_rejected` (`already_linked_to_other_variant`; original link preserved) |
| [8] Duplicate / idempotent | ✔ `same_item_same_variant_is_idempotent` (`exists`, still 1 row); `link_creates_exactly_one_row` |
| [8] Explicit relink | ✔ `relink_repoints_to_another_eligible_variant` |
| [8] Wrong shop | ✔ `wrong_shop_is_rejected` (0 rows) |
| [8] Archived / unknown variant | ✔ `archived_or_unknown_variant_is_rejected` (0 rows) |
| [8] Unknown item | ✔ `unknown_item_is_rejected` |
| [8] Unlink | ✔ (within non-interference test: removes the join row only) |
| [9] No provenance change | ✔ `linking_and_unlinking_never_touch_provenance` — ownership/cert/QR/claim-grant/auth-submission counts identical before/after link **and** unlink; the physical item is not deleted |
| [10] Permission defined | ✔ `link_permission_is_defined` (`sca.eyewear.shopify.link` present in `config('acl')`) |

## [10] Slice-B scope noted

HTTP-route authorization enforcement (the `sca.can:sca.eyewear.shopify.link` middleware on real link/unlink routes) and relink **audit history** surfacing remain **Slice B** work; Slice A defines the permission and the service-level behavior only.

## [11] Cleanup verified

`REVOKE ALL` on the disposable DB from the app user, then `DROP DATABASE` → the DB is gone (existence check 0), no residual grant references it (0), `SHOW DATABASES` back to the baseline set. Worktree (and its built vendor) removed; live tree `main 905ea7d`, clean.

## [12] Production unchanged

`sca_krayin` after == baseline (diff empty): `items 3 / state 3 / ownership 5 / certifications 4 / qr 3 / claim_grants 1 / catalog_products 4565 / catalog_variants 5330`, max migration batch **28**. The new table `sca_eyewear_item_shopify_variant` is **not** present in prod (0 — correctly not migrated). `/admin/login → 200`.

**STOP — Slice A DB tests PASS on a disposable DB; disposable DB dropped; production untouched. No prod migration/merge/deploy, no Shopify change, no live webhook, no Option C, no full regression. Remaining: Slice B (staff UI + route-level auth + relink audit), separately authorized; and the still-open Phase-1 first-genuine-`products/*`-webhook verification.**

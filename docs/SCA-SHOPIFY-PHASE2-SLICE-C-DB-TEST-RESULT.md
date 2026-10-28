# SCA — Shopify Phase 2 Slice C: Isolated DB Test RESULT

**Authorized single isolated DB-testing session for Slice C (`992e048`). VERDICT: PASS — 7 tests, 29 assertions, 0 failures / 0 warnings / 0 skips**, after one **disclosed test-assertion correction** (feature was correct; no product code changed). Uniquely-named disposable DB only; dropped + verified; production `sca_krayin` and SHA `91b88f1` unchanged. No prod migration/merge/deploy, no live Shopify, no ownership change, no Option C, no full regression. 2026-10-28. **STOP for review.**

## [1] Candidate & isolation
- Candidate `origin/feat/sca-shopify-phase2-visibility` = **`992e048b1a6991aca3f7fae1f760a4dfb72fd309`** (== origin tip); isolated detached worktree at that SHA; dev vendor (phpunit) built in it. Live tree stayed `main 91b88f1`, clean.
- **[2] Disposable DB:** `sca_p2c_test_f1e008cde238` — created only after an existence check returned 0; granted to `sca_app` on that DB only. Baseline databases were the standard set (no stray disposable DB).
- **[3] Isolation verified** (booted probe): `getenv(DB_DATABASE)` == `DB::connection()->getDatabaseName()` == live `SELECT DATABASE()` == `SCA_TEST_DB` == `sca_p2c_test_f1e008cde238`, and ≠ `sca_krayin` → `ISOLATION OK`. The isolated env files held zero `sca_krayin` references.

## [4] Migration (disposable DB only)
Full schema migrated into the disposable DB (the Slice A/B migrations `2026_10_28_000001/000002/000003` DONE). **Slice C adds NO migration.**

## [5]–[12] Test results
`vendor/bin/phpunit tests/Feature/Sca/ShopifyLinkVisibilityTest.php` → **OK (7 tests, 29 assertions)**, 0 failures/warnings/skips, PHPUnit 11.5.50 / PHP 8.3.33.

| # | Behavior | Objective | ✔ |
|---|---|---|---|
| 1 | Detail shows linked product title/vendor/variant/SKU + Shopify reference + linked-at | [6] | ✔ |
| 2 | Pair count = 2 when two items share one variant | [7] | ✔ |
| 3 | Archived product → "Inactive in catalog"; link row preserved | [8] | ✔ |
| 4 | Deleted catalog product → "Unavailable in catalog" from snapshot; link preserved | [9] | ✔ |
| 5 | Unlinked item → "No Shopify variant is linked" | [6] | ✔ |
| 6 | Registry index shows linked / inactive / unlinked indicators together | [10] | ✔ |
| 7 | Viewer (no link ACL) sees read-only info but NOT relink/unlink controls; link-ACL staff sees them | [11] | ✔ |

- **[6] linked display:** `detail_shows_linked_product_variant_sku_reference` asserts the live product name (`Aviator Classic`), vendor, variant (`Gold / 58mm`), SKU (`RB-901`), reference (`111 / 901`), and the `Linked · active` state.
- **[7] pair count:** `detail_counts_physical_pairs_on_the_same_variant` — two items on variant 901 → "Physical pairs linked to this variant: 2". The COUNT value was independently re-confirmed = 2 against the disposable DB.
- **[8]/[9] archived/deleted preserve links:** both tests assert the link row count stays 1 after archival / catalog deletion — visibility never unlinks.
- **[10] no N+1:** the registry indicator is a single bounded query over the current page's ids (code review + the three-indicator test on one page load).
- **[11] authorization:** a `sca.eyewear.view`-only viewer gets the read-only panel but neither the relink search (`id="sl_q"`) nor the `/admin/sca/shopify/unlink` form; a `sca.eyewear.shopify.link` staffer gets the controls.

## [13] Exact counts + the one disclosed correction
First run = **7 tests, 29 assertions, 1 failure**: test #2 expected the contiguous literal `"Physical pairs linked to this variant: 2"`, but the panel renders the label and value separated by a closing `</span>`. **This was a test-expectation bug, not a product defect** — the pair-count feature was independently verified to return 2. The fix (test-only, one line, disclosed) changed the assertion to the exact rendered fragment `Physical pairs linked to this variant:</span> 2`. Re-run = **7 tests, 29 assertions, 0 failures/warnings/skips**. No failing product code was repaired or masked. The correction is committed to the branch: `992e048` → **`aaa21a6fc978e1fa4fd5be6e105e677d313e806d`** (test file only; byte-identical product code).

## [12] No mutation of links/provenance
Tests #3/#4 assert the link row survives archive/delete; all cases are read-only HTTP GETs plus fixture inserts. The visibility code issues only reads (`SELECT`/`COUNT`); no link, authentication, certification, QR, ownership, or claim record is written. (Slice C changes no service, route, ACL, or migration.)

## [14] Cleanup verified
`REVOKE ALL` + `DROP DATABASE` → disposable DB gone (existence 0), no residual grant (`mysql.db` 0), `SHOW DATABASES` back to baseline. Probe/env files and the test worktree (with vendor) removed.

## [15] Production unchanged
Live SHA **`91b88f1`**; `kr-app` loopback `/admin/login → 200`. `sca_krayin` fingerprint == baseline: items 3 / state 3 / authentications 4 / certifications 4 / qr 3 / ownership 5 / claim_grants 1 / catalog 4565 / 5330; migrations batch **29** / 145 rows; the Slice A/B tables remain present and **empty** (0/0/0). Slice C deployed nothing.

**STOP — Slice C visibility verified green on a disposable DB (7/7); production untouched. Branch now `aaa21a6` (test-assertion fix disclosed above). No prod migration/merge/deploy, no live Shopify, no ownership change, no Option C, no full regression. NEXT (owner): merge decision for the Slice C branch (code-only, NO migration). Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification.**

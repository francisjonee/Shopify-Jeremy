# SCA — Shopify Phase 2 Slice B: Final Regression RESULT (corrected `a477dc4`)

**Authorized single isolated DB-testing session for the corrected commit `a477dc4f7dbd2c07b95368c6534a35eb315e2b90`. VERDICT: PASS — 37 tests, 131 assertions, 0 failures / 0 errors / 0 warnings / 0 skips.** Both corrections (DEFECT-1 product+variant gating; idempotency fingerprint conflict) confirmed, and all previously-passing Slice B behavior intact. Uniquely-named disposable DB only; dropped + verified; production `sca_krayin` unchanged and the Slice A/B tables NOT migrated to prod. No prod migration/merge/deploy, no Shopify change, no live webhook, no Option C, no full regression. 2026-10-28. **STOP for independent review.**

## [1] Candidate & isolation

- Candidate `origin/feat/sca-shopify-phase2-linking` = **`a477dc4f7dbd2c07b95368c6534a35eb315e2b90`** (confirmed == origin tip); built in an isolated detached worktree at that SHA. Live tree stayed `main 905ea7d`, clean. DEFECT-1 fix (`productActive` guard) and `fingerprint` logic confirmed present in the checkout. Dev vendor (phpunit) built in the worktree.
- **[2] Disposable DB:** `sca_p2bf_test_c4d7872d1e07` — created only after an existence check returned 0; granted to `sca_app` on that DB only. Baseline `SHOW DATABASES` = `information_schema, mysql, performance_schema, sca_krayin, sys`.
- **[3] Isolation verified** (booted-app probe): `getenv(DB_DATABASE)` == `DB::connection()->getDatabaseName()` == live `SELECT DATABASE()` == `sca_p2bf_test_c4d7872d1e07`, and ≠ `sca_krayin` → `ISOLATION OK`. Isolated `.env`/`.env.testing` contained zero `sca_krayin` references.

## [4] Migration (disposable DB only)

Full schema migrated into the disposable DB; the three Slice A/B migrations (`2026_10_28_000001/000002/000003`) applied DONE. The corrected `000003` added the `fingerprint` column — confirmed present in the disposable DB (`information_schema.COLUMNS`). These tables are **absent from prod** (see [13]).

## [5]–[10] Test results

`vendor/bin/phpunit` over the three files → **OK (37 tests, 131 assertions)**, 0 failures/errors/warnings/skips, PHPUnit 11.5.50 / PHP 8.3.33, ~8.3 s.

**EyewearShopifyIntakeTest — 12 ✔** (incl. the three Slice A carry-overs): create-only; create+link+audit; rejected-link rollback; missing-key rejected; override persistence; no-provenance; audit immutability; **[6] `create_with_archived_product_active_variant_rolls_back`**; **[8] `identical_retry_with_same_key_returns_same_item`** + `same_idempotency_key_yields_exactly_one_item`; **[9] `key_reuse_with_different_details_is_an_explicit_conflict`** + `key_reuse_detects_attribute_only_divergence`.

**ShopifyProductLinkTest (Slice A compat + DEFECT-1) — 12 ✔**: 1:N linking, no silent relink, idempotent, explicit relink, wrong-shop/archived-variant/unknown rejected, non-interference, permission defined; **[6] `archived_product_with_active_variant_is_rejected_on_link_and_relink`**; **[7] `existing_link_is_preserved_when_product_becomes_archived`**.

**ShopifyProductLinkRouteTest — 13 ✔**: ACL 403 on catalog-search + link/relink/unlink + create-with-link (create-only staff); selector fields; query filter; link→relink→unlink audit; create-with-link; double-submit=1 item; override persistence; plain create; **[6] `catalog_search_marks_archived_product_not_linkable`** + `create_with_link_rejects_archived_product_and_creates_nothing`; **[9] `create_with_link_key_reuse_with_different_details_conflicts`**.

### Objective confirmations
- **[6] Archived/draft parent cannot be newly linked or relinked even with an active variant** — service rejects on both `link()` and `relink()` (`variant_not_eligible`); intake rolls back (no item); HTTP create redirects back with no item; selector marks the row not linkable. ✔
- **[7] Existing links survive subsequent product archival** — linking while live, then setting the product `status=archived`, leaves the join row intact (no auto-unlink). ✔
- **[8] Identical retries return the original item, no duplicate** — byte-identical resubmission returns the same item id; one ledger row; double-submit over HTTP yields exactly one item. ✔
- **[9] Reused key with changed attributes OR Shopify selection → explicit conflict, no data change** — `conflict` / `idempotency_key_reused_with_different_details`; no second item; original item + link unchanged; attribute-only divergence also conflicts; HTTP surfaces a form error. ✔
- **[10] Permissions, transaction rollback, audit immutability, provenance isolation** — all still pass (ACL 403s, rejected-link rollback, UPDATE+DELETE on audit rejected by triggers, provenance counts unchanged). ✔

## [11] Exact counts

**37 tests · 131 assertions · 0 failures · 0 errors · 0 warnings · 0 skipped/risky.** No failing code was modified during this session (read-only test execution).

## [12] Cleanup verified

`REVOKE ALL` on the disposable DB from `sca_app`, then `DROP DATABASE` → gone (existence check 0), no residual grant (`mysql.db` count 0), `SHOW DATABASES` back to baseline. Probe/env files and the test worktree (with its built vendor) removed; live tree `main 905ea7d`, clean.

## [13] Production unchanged

`sca_krayin` fingerprint == baseline: `items 3 / current_state 3 / ownership 5 / certifications 4 / qr 3 / claim_grants 1 / catalog_products 4565 / catalog_variants 5330`, max migration batch **28**, 142 migration rows. The three link/audit/idempotency tables are **absent** in prod (0). App health: `kr-app` loopback `/admin/login → 200`.

**STOP — corrected Slice B (`a477dc4`) PASSES on a disposable DB (37/37); both corrections confirmed; production untouched. No prod migration/merge/deploy, no Shopify change, no live webhook, no Option C, no full regression. Awaiting review → merge decision. Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification.**

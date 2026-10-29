# SCA — Assignment + Permission + rc21: FINAL Combined Regression — RESULT

**Authorized final integration regression of all three approved branches onto production baseline
`5bed316` (R0/R0b/R0c excluded). VERDICT: ALL GREEN — 79 tests / 512 assertions / 0 failures / 0 errors
/ 0 warnings / 0 skips across the five suites; `ShopifyReconciliationTest` 21/21 with rc8 AND rc21 both
passing.** rc21 was additionally proven (negative control) to detect a genuine per-row N+1 while
measuring only the Operations feature's own queries. The entire session ran on an `--internal`
(no-egress) Docker network with a fake store domain — **ZERO live Shopify API requests were possible and
ZERO Shopify store/config changes occurred.** Disposable DB only; dropped + verified; production
`sca_krayin` + SHA `5bed316` unchanged. NO merge/deploy (verification only). 2026-10-29. **STOP.**

## [1]–[5] SHAs, integration, combined diff
- Verified: prod/live `5bed316`; assignment `5b29338`; perm-fix `e2470a6`; rc21-fix `d6e4b96`.
- Integration worktree off `5bed316`; `--no-ff` merged all three (disjoint files, **no conflicts**,
  no conflict markers) → throwaway HEAD `86f1d13` (not pushed).
- **Combined diff vs `5bed316` = ONLY the approved changes + the ONE additive migration:** assignment
  (`OrderAssignmentController`, `OrderItemAssignment`, `OrderItemAssignmentService`, `order-assign.blade`,
  `Config/acl.php`, `Config/menu.php`, `admin-routes.php`, `ShopifyOrderItemAssignmentTest`, and
  `2026_10_31_000001_create_sca_shopify_order_item_assignments.php` — the only migration); perm-fix
  (`OperationsController`, `ShopifyOperationsPermissionTest`); rc21-fix (`ShopifyReconciliationTest`).
  **No R0/R0b/R0c code/migrations/symbols** (grep-verified).

## [6]–[9] Database isolation
- `sca_domain_test` re-checked **absent + 0 active connections** before create; scoped user `sca_test`
  granted `ALL` on `sca_domain_test` only — **no privilege on `sca_krayin`**.
- Isolation verified: `getenv(DB_DATABASE)` == connection == `SELECT DATABASE()` == `SCA_TEST_DB` ==
  `sca_domain_test`, ≠ `sca_krayin`. Migrated (incl. the additive assignment migration) + `db:seed`, on
  the disposable DB only.

## [10]–[14] Shopify safety — MANDATORY, satisfied with evidence
- **[10][11] No egress:** all migrate/seed/phpunit ran on a throwaway `docker network --internal
  sca_testnet`. Proven from the test-runner image (`sca-app:krayin-2.2.6`) before tests: TCP to
  `1.1.1.1:443` → **BLOCKED**, while `kr-mariadb:3306` → reachable. A live Shopify request during tests
  was physically impossible.
- **[12][13] Fake store / no prod creds:** the Shopify-touching tests set `expected_shop_domain =
  sca-test-store.myshopify.com` (fake, never Jeremy's store) + an in-memory `shpat_TESTONLY` token, and
  drive `ShopifyClient::getOrder` exclusively through `Http::fake`. The test `.env` contains no Shopify
  keys; production Shopify credentials were never read.
- **[14] No mutations/CLI:** no Shopify products/orders/customers/themes/webhooks/settings were touched;
  no Shopify CLI was run; the production SCA database was not accessed (disposable DB only). The prod
  `sca_shopify_credentials` row remains intact (count 1), unchanged.

## [15]–[19] Suite results
| Suite | Expected | Result |
|---|---|---|
| `ShopifyOperationsPermissionTest` | 6 | **6/6 OK** (9 assertions) |
| `ShopifyOrderItemAssignmentTest` | 17 | **17/17 OK** (64 assertions) |
| `ShopifySaleLinkTest` | 23 | **23/23 OK** (93 assertions) |
| `ShopifySaleClaimVisibilityTest` | 12 | **12/12 OK** (67 assertions) |
| `ShopifyReconciliationTest` | 21 | **21/21 OK** (279 assertions) |
| **Total** | **79** | **79 / 512 assertions / 0 fail / 0 err / 0 warn / 0 skip** |

## [20][21] rc8 + rc21 + N+1 detection
- **[20]** `rc8_operations_requires_staff_auth_and_view_acl` ✔ and
  `rc21_operations_queries_bounded_no_n_plus_1` ✔ (both green; the Administrator 500 is resolved).
- **[21] rc21 verified to work (negative control):** with an injected per-row query against
  `sca_shopify_sale_links` in `OperationsController::index`, rc21 **FAILED** —
  `assertSame` reported feature-query counts of **6 (3 rows) vs 23 (28 rows)**, i.e. it caught the
  per-row growth; and only ops-table queries were counted (admin-layout chrome never affected the
  numbers). The injection was then fully reverted (worktree clean, 0 residual). So rc21 measures ONLY
  Shopify-Operations queries and detects genuine N+1 growth; without an N+1 the count is a constant 3 at
  both dataset sizes (≤ the strict budget of 6).

## [22][23] Assignment behavior/security (via `ShopifyOrderItemAssignmentTest` 17/17)
- Assignment ACL + manager-override ACL separately enforced; manager override requires the ACL AND a
  recorded reason. Exact variant matching (mismatch fails closed). Refund/cancellation/unpaid/line-not-
  in-order fail closed. Duplicate idempotent (`exists`); conflicting different-item fails closed
  (`SCA_SALE_LINE_ITEM_CONFLICT`). Append-only audit: UPDATE and DELETE rejected by DB triggers.
- **[23]** Assignment creates NO authentication/certification/QR/ownership/claim records (a1 asserts
  the provenance counts unchanged); QR availability is surfaced without exposing any token.

## [24] Exact totals
**79 tests, 512 assertions, 0 failures, 0 errors, 0 warnings, 0 skipped.** No failing code was repaired
or masked; the only code touched during the session was the temporary negative-control injection, which
was reverted (no commit, worktree verified clean).

## [26] Cleanup verified
`REVOKE ALL` → `DROP USER 'sca_test'@'%'` → `DROP DATABASE sca_domain_test` → gone; `sca_test` user
count 0; `sca_krayin` present. `kr-mariadb` disconnected from `sca_testnet`; `sca_testnet` removed
(back to `sca_internal` only). Integration worktree + throwaway branch removed; test `.env` shredded +
probe deleted.

## [27] Production unchanged
Live SHA **`5bed316`**, `main`, clean; loopback `/admin/login → 200`. `sca_krayin`: migrations batch
**29 / 145**; items **3** / ownership **5** / claims **2** / cert **4** / qr **3** / sale_links **1**;
`sca_shopify_order_item_assignments` **absent (0)**; `sca_shopify_credentials` **1** (Shopify config
untouched).

**STOP — all three changes integrate cleanly and pass together (79/79; rc8 + rc21 green; rc21 N+1
detection proven). Production + Shopify config untouched; ZERO live Shopify requests / store changes.
Verification only — NOT merged. The three branches remain unmerged off `5bed316`: assignment `5b29338`
(1 additive migration), perm-fix `e2470a6` (code-only), rc21-fix `d6e4b96` (test-only). NEXT (separate
owner decision): code-only merge review of the three → controlled release (assignment's one additive
migration is migrate-before-code; perm-fix + rc21 are code/test-only). SEPARATE OPEN: Phase-1 first
genuine `products/*` webhook receipt verification.**

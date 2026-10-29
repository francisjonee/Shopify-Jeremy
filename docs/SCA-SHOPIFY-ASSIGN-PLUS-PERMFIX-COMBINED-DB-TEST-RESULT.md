# SCA — Order Assignment + Administrator Permission Fix: Combined Integration Regression — RESULT

**Authorized single disposable-DB integration session combining assignment `5b29338` + perm-fix
`e2470a6` onto production baseline `5bed316` (R0/R0b/R0c excluded).** VERDICT: the two features
integrate cleanly and are functionally GREEN — `ShopifyOperationsPermissionTest` 6/6,
`ShopifyOrderItemAssignmentTest` 17/17, `ShopifySaleLinkTest` 23/23, `ShopifySaleClaimVisibilityTest`
12/12, and `ShopifyReconciliationTest` 20/21 with **rc8 now FIXED**. The one remaining failure (rc21) is
a **pre-existing test-threshold artifact** — the admin-layout chrome exceeds rc21's query budget once
the page renders; it is **not a real N+1 and not caused by either change** (evidence below). Per the
task's "report and STOP without merging on any failure", **NOT merged.** Disposable DB only; dropped +
verified; production `sca_krayin` + SHA `5bed316` unchanged. **ZERO live Shopify requests were possible
— tests executed on an `--internal` (no-egress) docker network with a fake store domain (details in
the Shopify-safety section).** 2026-10-29. **STOP.**

## [1]–[5] SHAs, integration, combined diff
- Production/live `5bed316`; assignment `5b29338`; perm-fix `e2470a6` — all verified on origin.
- Integration worktree off **`5bed316`**; `--no-ff` merged both branches (disjoint files, no conflict)
  → integration HEAD `4e0ce89` (throwaway; not pushed).
- **Combined diff vs `5bed316` = exactly the approved files + the ONE additive migration:**
  `Config/acl.php` (M, +2 ACLs), `Config/menu.php` (M, +1), `admin-routes.php` (M, +2 routes),
  `OperationsController.php` (M, perm fix), `OrderAssignmentController.php` (A), `OrderItemAssignment.php`
  (A), `order-assign.blade.php` (A), `OrderItemAssignmentService.php` (A),
  `2026_10_31_000001_create_sca_shopify_order_item_assignments.php` (A, the only migration),
  `ShopifyOrderItemAssignmentTest.php` (A), `ShopifyOperationsPermissionTest.php` (A).
- **No R0/R0b/R0c:** no `PresaleClaimGrantService`/`CollectorEmailVerificationService`/
  `PresaleGrantClaimController`; no `2026_10_29*`/`2026_10_30*`/presale/order_email/email-verif
  migrations; no `claimByPresaleGrant`/`BUYER_VERIFICATION`/`email_verified`/`fulfillment_released`
  symbols in the combined diff.

## [6]–[8] Disposable DB + isolation
- `sca_domain_test` re-checked **absent + 0 active connections** before create; scoped user `sca_test`
  granted `ALL` on `sca_domain_test` only (no privilege on `sca_krayin`).
- Isolation verified: `getenv(DB_DATABASE)` == connection == `SELECT DATABASE()` == `SCA_TEST_DB` ==
  `sca_domain_test`, ≠ `sca_krayin`; test `expected_shop_domain` config = `<null>` at boot (tests set a
  fake store in their own `setUp`). Migrated (incl. the additive assignment migration) + `db:seed`.

## [9]–[12] Results
| Suite | Result |
|---|---|
| `ShopifyOperationsPermissionTest` | **6/6 OK** (9 assertions) |
| `ShopifyReconciliationTest` | **20/21** — rc8 ✔ (FIXED); **rc21 ✘** (see below) |
| `ShopifyOrderItemAssignmentTest` | **17/17 OK** (64 assertions) |
| `ShopifySaleLinkTest` | **23/23 OK** (93 assertions) |
| `ShopifySaleClaimVisibilityTest` | **12/12 OK** (67 assertions) |

**Totals (excl. rc21): 58 passing tests.** No errors/warnings/skips.

## [13]–[17] Behavior/security verification — confirmed
- **[13]** Administrator (`permission_type=all`) opens `/admin/sca/shopify/operations` → **200, no 500**
  (rc8 ✔ + `ShopifyOperationsPermissionTest::admin_all_role_loads_operations` ✔). The perm fix
  (`bouncer()->hasPermission`) resolved the prior `in_array(null)` crash.
- **[14]** View-only staff can open the screen (200) but cannot reconcile (403) or assign (403 on the
  assign route) without the mutation ACL (`ShopifyOperationsPermissionTest` + `ShopifyReconciliationTest`
  rc9 + `ShopifyOrderItemAssignmentTest` a14).
- **[15]** Assignment ACL (`sca.eyewear.shopify.order-assign`) and the manager-override ACL
  (`…order-assign.override`) remain separately enforced (a14: assign-ACL staff without override still
  refused `SCA_ASSIGN_NO_VARIANT_LINK`).
- **[16]** Paid-order eligibility + exact variant match + duplicate idempotency + conflict fail-closed +
  refund/cancel rejection + append-only audit immutability all pass (assignment a1–a16; sale-link suite
  23/23).
- **[17]** Assignment creates no ownership/certification/QR/claim records (a1 asserts the provenance
  counts unchanged; a12 shows QR availability without exposing a token).

## [18][19] Exact totals + the one failure (reported, NOT repaired; NOT merged)
- **rc21 `operations queries bounded no n plus 1` FAILS: "44 is less than 30" is false (44 queries).**
  Root cause established by categorizing the query log on the disposable DB (25 seeded rows):
  - `attribute_options:15`, `attributes:11`, `core_config:10` = **36 queries are Krayin core admin-layout
    chrome** (the `x-admin::layouts` bootstrap: EAV attribute system + config), inherent to rendering
    ANY admin page.
  - The operations feature's OWN queries are exactly **3** (`sca_shopify_webhook_receipts`,
    `sca_shopify_sale_links`, `sca_shopify_reconciliation_runs`) — **bounded, constant, NO N+1** over the
    25 rows (the invariant rc21 exists to protect HOLDS). `roles:1` is the only ACL query (bouncer
    caches); the assignment menu entry adds no query.
  - rc21 was one of the two PRE-EXISTING baseline failures: on `5bed316` it failed via the 500 crash, so
    its `< 30` query budget was never actually evaluated for an Administrator. The perm fix (correctly)
    lets the page render, which first exposes that Krayin's admin chrome (~36) alone exceeds rc21's
    30-query budget for an `all` role. **It is neither a regression from these changes nor a real N+1.**
  - **Not repaired here:** rc21 is an existing test; this session does not modify it. RECOMMENDATION
    (separate decision): either raise rc21's budget to reflect Krayin's admin-chrome cost for an
    Administrator, or scope its assertion to the feature's own queries (the 3 list queries) rather than
    total request queries. No product change is warranted — the feature is not N+1.
- No failing product code was repaired or masked.

## Shopify store safety ([critical requirements] — ZERO live requests)
- **Test execution network had NO internet egress.** All migrate/seed/phpunit ran on a throwaway
  `docker network --internal sca_testnet`; proven at setup: an `--internal`-network container could NOT
  reach `example.com` (DNS/connect failed) while `kr-mariadb:3306` WAS reachable. A live Shopify request
  during tests was therefore physically impossible; `kr-mariadb` was disconnected from `sca_testnet` and
  the network removed at teardown (back to `sca_internal` only).
- **Fake store, no prod credentials.** The test `.env` contains NO Shopify keys; the Shopify-touching
  tests set `expected_shop_domain = sca-test-store.myshopify.com` (a fake, never Jeremy's store) and
  inject an in-memory `shpat_TESTONLY` token; the disposable DB has no `sca_shopify_credentials` row.
  Production credentials were never read.
- **Simulated API only.** Every test that exercises a Shopify call uses `Http::fake(...)` (Laravel then
  stubs any unmatched URL with an empty 200 — no real egress), and host-locks to the fake domain.
  `ShopifyClient::getOrder` was only ever driven through these fakes.
- **No Shopify mutations / CLI / settings / webhook-subscription changes** of any kind occurred; the
  production SCA database was not touched (disposable DB only). **ZERO live Shopify API requests were
  made and ZERO Shopify store changes occurred.**

## [20] Cleanup verified
`REVOKE ALL` → `DROP USER 'sca_test'@'%'` → `DROP DATABASE sca_domain_test` → gone; `sca_test` user
count 0; `sca_krayin` present. `sca_testnet` removed; `kr-mariadb` back to `sca_internal` only.
Integration worktree + throwaway branch removed; test `.env` shredded + probe deleted.

## [21] Production unchanged
Live SHA **`5bed316`**, `main`, clean; loopback `/admin/login → 200`. `sca_krayin`: migrations batch
**29 / 145**; items **3** / ownership **5** / claims **2** / cert **4** / qr **3** / sale_links **1**;
`sca_shopify_order_item_assignments` **absent (0)**.

**STOP — combined integration is functionally GREEN (58 passing; rc8 fixed); the single rc21 failure is
a pre-existing admin-chrome query-budget artifact, not a real N+1 and not caused by either change. Per
instruction, NOT merged. Both candidate branches remain unmerged (assignment `5b29338` [1 additive
migration], perm-fix `e2470a6` [code-only]). NEXT (separate owner decision): resolve rc21's threshold,
then code-only merge review + a controlled release. ZERO live Shopify requests / store changes.
SEPARATE OPEN: Phase-1 first genuine `products/*` webhook receipt verification.**

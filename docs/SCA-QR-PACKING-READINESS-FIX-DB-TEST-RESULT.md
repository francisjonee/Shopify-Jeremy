# SCA — QR Packing-Readiness Fix: Isolated DB Regression — RESULT

**Authorized single disposable-DB session for candidate `a0bd8db` (branch
`fix/sca-qr-packing-readiness-copy`). VERDICT: ALL GREEN — 83 tests / 523 assertions / 0 failures / 0
errors / 0 warnings / 0 skips across the five suites; `ShopifyOrderItemAssignmentTest` 21/21 including
the new a17–a20.** Ran on an `--internal` (no-egress) Docker network with a fake store domain — ZERO
live Shopify requests were possible and ZERO Shopify store/config changes occurred. Disposable DB only;
dropped + verified; production `sca_krayin` + SHA `eb137bf` unchanged. No merge/deploy. 2026-10-29.
**STOP.**

## [1]–[3] Candidate, scope, prod health
- Candidate `a0bd8db418d8a5396f51b39bf7bab9c98be7d872`; diff vs `eb137bf` is **exactly two files**:
  `OrderAssignmentController.php` and `ShopifyOrderItemAssignmentTest.php`.
- Production live `eb137bf`, `main`, clean, loopback `/admin/login → 200`.
- Detached worktree at the candidate; dev vendor built via the app image.

## [4]–[7] Disposable DB + isolation
- `sca_domain_test` re-checked **absent + 0 active connections** before create; scoped user `sca_test`
  granted `ALL` on `sca_domain_test` only — **no privilege on `sca_krayin`**.
- Isolation verified: `getenv(DB_DATABASE)` == connection == `SELECT DATABASE()` == `SCA_TEST_DB` ==
  `sca_domain_test`, ≠ `sca_krayin`. Migrated (146) + `db:seed` on the disposable DB only.

## [8]–[12] Shopify safety — satisfied with evidence
- All migrate/seed/phpunit ran on a throwaway `docker network --internal sca_testnet`. Proven from the
  test-runner image BEFORE testing: TCP to `1.1.1.1:443` → **BLOCKED**, while `kr-mariadb:3306` →
  reachable — a live Shopify request was physically impossible.
- The Shopify-touching tests use `Http::fake`, a fake store domain (`sca-test-store.myshopify.com`), and
  an in-memory `shpat_TESTONLY` token. The test `.env` has **no** Shopify keys; production Shopify
  credentials were never read; no Shopify CLI; no products/orders/inventory/customers/webhooks/themes/
  settings touched.

## [13]–[15] Suite results
| Suite | Expected | Result |
|---|---|---|
| `ShopifyOrderItemAssignmentTest` | 21 | **21/21 OK** (75 assertions) |
| `ShopifySaleLinkTest` | 23 | **23/23 OK** (93 assertions) |
| `ShopifySaleClaimVisibilityTest` | 12 | **12/12 OK** (67 assertions) |
| `ShopifyOperationsPermissionTest` | 6 | **6/6 OK** (9 assertions) |
| `ShopifyReconciliationTest` | 21 | **21/21 OK** (279 assertions) |
| **Total** | 83 | **83 / 523 assertions / 0 fail / 0 err / 0 warn / 0 skip** |

## [16]–[20] Verification — confirmed (named evidence)
- **[16]** Active QR including `is_production=false` shows "QR ready for packing": `a17` (service:
  `qr_available=true`, `qr_production=false`) + `a19` (HTTP confirmation contains "QR ready for packing"
  and NOT "staging — not for print" / "(production)"). ✔
- **[17]** Revoked / missing QR never shows ready: `a18` (revoked → `qr_available=false`), `a12` (absent),
  `a20` (HTTP → "no active QR yet", not "ready for packing"). ✔
- **[18]** QR tokens never exposed in confirmation: `a12` asserts the active QR's token is absent from
  the result; the confirmation strings carry only "QR ready for packing" / "no active QR" — no token. ✔
- **[19]** Assignment creates no QR/ownership/claim/certification/authentication records: `a1` asserts
  the provenance counts are unchanged across an assignment. ✔
- **[20]** Permissions, variant matching, idempotency, and refund/cancellation protections intact:
  `a2`–`a11`, `a14`–`a16` (variant mismatch, no-link manager override, duplicate/conflict, cancelled/
  refunded/unpaid, ACL separation, append-only audit) all pass within the 21. ✔

## [21] Exact totals
**83 tests, 523 assertions, 0 failures, 0 errors, 0 warnings, 0 skipped.** No failing code was repaired
or masked (no code changed during the session).

## [23] Cleanup verified
`REVOKE ALL` → `DROP USER 'sca_test'@'%'` → `DROP DATABASE sca_domain_test` → gone; `sca_test` user count
0; `sca_krayin` present. `kr-mariadb` disconnected from `sca_testnet`; `sca_testnet` removed (back to
`sca_internal` only). Worktree removed; test `.env` shredded + probe deleted.

## [24] Production unchanged
Live SHA **`eb137bf`**, `main`, clean; loopback 200. `sca_krayin`: migrations batch **30 / 146**; items
**3** / ownership **5** / claims **2** / cert **4** / qr **3** / sale_links **1**;
`sca_shopify_order_item_assignments` **0 rows**.

**STOP — candidate `a0bd8db` passes the authorized isolated regression (83/83; the packing-readiness
correction is proven: active QR ⇒ ready regardless of is_production, revoked/absent ⇒ never ready, no
token exposed, no provenance created). Production + Shopify config untouched; ZERO live Shopify requests.
NOT merged. NEXT (separate auth): code-only merge review of `a0bd8db` → release (code-only, no
migration). SEPARATE OPEN: Phase-1 first genuine `products/*` webhook receipt verification.**

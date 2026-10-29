# SCA — Shopify Reconciliation rc21 Test Correction

**Authorized test-only correction of `ShopifyReconciliationTest::rc21_operations_queries_bounded_no_n_plus_1`.**
rc21 previously counted ALL queries while rendering the Operations page (`< 30` budget), which an
Administrator role (`permission_type=all`) exceeds purely on Krayin admin-layout chrome (~36 queries),
unrelated to this feature and not an N+1. The rewrite measures ONLY the Operations feature's own queries
and detects genuine per-row N+1 by comparing a small vs larger dataset. No production application code or
reconciliation behavior changed. Static check PASS (`php -l` clean). DB-backed; NOT run here (the
disposable-DB rerun is the separately-authorized NEXT step). 2026-10-29. **STOP for review.**

## SHA & branch
- Branch `fix/sca-reconciliation-rc21-test` off **`e2470a6`** (the Administrator permission fix) → head
  **`d6e4b96324fe2d6063004f6704c012e8d988c51d`** (pushed to origin). Based on the perm-fix because the
  Operations page must RENDER for an Administrator (which `e2470a6` enables) before its feature queries
  can be measured; the assignment branch's migration is irrelevant to rc21.
- **1 file changed, test-only:** `app/tests/Feature/Sca/ShopifyReconciliationTest.php` (rc21 body +
  one new private helper). Verified: the diff touches no file outside `app/tests/`.

## Why rc21 failed before (recap)
On a disposable DB, rendering `/admin/sca/shopify/operations` as an Administrator issued 44 queries;
the query log decomposes as `attribute_options:15 + attributes:11 + core_config:10 = 36` Krayin
admin-layout chrome (the `x-admin::layouts` EAV/config bootstrap, present on every admin page) plus the
feature's own **3** bounded list queries (`sca_shopify_webhook_receipts`, `sca_shopify_sale_links`
joined to `sca_eyewear_items`, `sca_shopify_reconciliation_runs`). rc21's old `< 30` total-query budget
therefore measured the framework chrome, not the feature — and it never actually evaluated for an
Administrator before the perm fix (the page 500'd).

## The correction (objectives 3–6)
- **[3] Feature-specific measurement:** a new helper `opsFeatureQueryCount(User $admin, int $seedRows,
  int $seedFrom)` renders the page (query log flushed first) and counts ONLY queries whose SQL matches
  `sca_shopify_(webhook_receipts|sale_links|reconciliation_runs)`. Admin-layout chrome is excluded.
- **[5] Genuine N+1 detection:** rc21 renders with a small dataset (3 pairs) and then a much larger one
  (25 more → 28 total) and asserts the feature-query count is **identical** (`assertSame($small,
  $large)`). A real per-row N+1 would make the large count grow; a constant count proves the bounded
  (paginated, LIMIT-per-page) queries do not multiply over rows.
- **[4][6] Strict, justified budget — not a raised global limit:** `assertLessThanOrEqual(6, $large)`.
  Justification: exactly 3 bounded list queries + one query of headroom; the chrome is excluded rather
  than tolerated by inflating the limit. A sanity assert (`$small > 0`) ensures the feature queries were
  actually observed.
- **[7] No production change:** `OperationsController` and all reconciliation logic are untouched (the
  only non-test change in this branch is the inherited `e2470a6` perm fix); the method name
  `rc21_operations_queries_bounded_no_n_plus_1` is preserved so references stay valid.

## [8] Static validation
- `php -l` clean on `ShopifyReconciliationTest.php`. Diff confined to `app/tests/` (verified).
- Expected behavior on the authorized disposable-DB rerun: with the perm fix, the Operations page
  renders (200) for an Administrator; the feature-query count is 3 at both dataset sizes → `assertSame`
  passes and `<= 6` passes, so rc21 turns GREEN while still failing loudly on any real per-row N+1.

## [10] Remaining database-test requirement (NEXT, separately authorized)
Rerun the **combined** regression on a fresh disposable `sca_domain_test` with network egress blocked
(the established `docker network --internal` pattern; fake store domain; `Http::fake`; no prod
credentials), over the integration of assignment `5b29338` + perm-fix `e2470a6` + this rc21 correction
`d6e4b96`, expecting: `ShopifyOperationsPermissionTest` 6/6, `ShopifyOrderItemAssignmentTest` 17/17,
`ShopifySaleLinkTest` 23/23, `ShopifySaleClaimVisibilityTest` 12/12, and `ShopifyReconciliationTest`
**21/21** (rc21 now green). Live production untouched throughout.

## Safety / scope
Test-only change on a dev branch; prod `5bed316` + live bind-mount untouched (confirmed `5bed316`,
clean, loopback 200); no migration/deploy; no Shopify API/credentials/CLI; no external network access
used in this task (no tests were run); no R0/R0b/R0c or Option-C.

**STOP — rc21 corrected (test-only) at `d6e4b96` on branch `fix/sca-reconciliation-rc21-test` (off
`e2470a6`). NEXT (separate auth): the combined disposable-DB regression with egress blocked, expecting
21/21 reconciliation. SEPARATE OPEN: Phase-1 first genuine `products/*` webhook receipt verification.**

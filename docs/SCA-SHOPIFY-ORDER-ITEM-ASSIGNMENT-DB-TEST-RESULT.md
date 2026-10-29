# SCA — Shopify Order→Eyewear Assignment: Isolated DB Regression — RESULT

**Authorized single disposable-DB session for candidate `c37592b` (branch
`feat/sca-shopify-order-item-assignment`). VERDICT: feature GREEN after two disclosed candidate
corrections — `ShopifyOrderItemAssignmentTest` 17/17 (64 assertions) + existing `ShopifySaleLinkTest`
23/23 + `ShopifySaleClaimVisibilityTest` 12/12 all pass. `ShopifyReconciliationTest` has 2 failures
that are PRE-EXISTING on baseline `5bed316` and UNRELATED to this change (proven by isolation).**
Disposable DB only; dropped + verified; production `sca_krayin` + SHA `5bed316` unchanged. Branch
advanced `c37592b → 5b29338` with the two corrections (both disclosed below). No merge/deploy, no prod
DB change, no live Shopify, no ownership/QR/claim change. 2026-10-29. **STOP.**

## [1]–[4] Candidate, isolation, migrate + seed
- Candidate verified `c37592b`; detached worktree; dev vendor built via the app image
  `sca-app:krayin-2.2.6`. Live checkout stayed `5bed316`, clean.
- Disposable `sca_domain_test` re-checked **absent + 0 active connections** before create; scoped user
  `sca_test` granted `ALL` on `sca_domain_test` only (no privilege on `sca_krayin`).
- Isolation verified: `getenv(DB_DATABASE)` == connection == `SELECT DATABASE()` == `SCA_TEST_DB` ==
  `sca_domain_test`, ≠ `sca_krayin` → ISOLATION OK. Migrated (incl. the additive
  `2026_10_31_000001_create_sca_shopify_order_item_assignments`) + `db:seed`.

## [5] `ShopifyOrderItemAssignmentTest` — OK (17 tests, 64 assertions), 0 err/fail/warn/skip
After two disclosed corrections ([20]). All behavioral + security objectives covered.

## [6] Existing regression — compatibility
| Suite | Result |
|---|---|
| `ShopifySaleLinkTest` | **23/23 OK** (93 assertions) |
| `ShopifySaleClaimVisibilityTest` | **12/12 OK** (67 assertions) |
| `ShopifyReconciliationTest` | 19/21 — **2 failures, PRE-EXISTING + UNRELATED** (see [21]) |

## [7]–[19] Security & behavior checks — confirmed
- **[7]** Order/line facts come only from the authoritative `getOrder` (faked via `Http::fake`); the
  POST carries no status fields (a9 asserts a line absent from the authoritative order → rejected; the
  order endpoint is confirmed fetched).
- **[8]** Only paid, non-cancelled, non-refunded lines bind: cancelled → `SCA_ASSIGN_ORDER_CANCELLED`
  (a6), refunded line → `SCA_ASSIGN_LINE_REFUNDED` (a7), unpaid → `SCA_ASSIGN_ORDER_UNPAID` (a8) — all
  no sale link.
- **[9]** `public_ref` resolves to exactly one item; unknown ref → `SCA_ASSIGN_ITEM_NOT_FOUND`,
  malformed → `SCA_ASSIGN_BAD_REF` (a10).
- **[10]** Variant-link must equal the purchased variant (a1 matched → bound); mismatch →
  `SCA_ASSIGN_VARIANT_MISMATCH`, fail closed (a2).
- **[11]** No variant link ⇒ refused (`SCA_ASSIGN_NO_VARIANT_LINK`) without the manager override ACL
  AND a non-empty reason; with manager override + reason → bound and recorded as `no_link_override`
  with the reason (a3); empty reason refused (a3b).
- **[12]** Duplicate same (order,line,item) → idempotent `exists`, one link row (a4); conflicting
  different item on the same line → `SCA_SALE_LINE_ITEM_CONFLICT`, original unchanged (a5) — reusing
  `SaleLinkService` guards.
- **[13]** Concurrency: the binding is written only through `SaleLinkService::linkPaidLine`
  (`UNIQUE(shop,line)` + row lock + unique-violation convergence), so the same line/item converges to
  one link; a repeat attempt returns `exists` (a4). One physical item cannot carry two active links
  (SaleLinkService `assertEligible`, covered by `ShopifySaleLinkTest`).
- **[14]** Cancelled/refunded cannot regain eligibility (a6/a7 reject; `SaleLinkService` never flips a
  revoked/cancelled link back — covered by `ShopifySaleLinkTest`/reconciliation).
- **[15]** Append-only audit: direct UPDATE and DELETE on `sca_shopify_order_item_assignments` are both
  rejected by the DB triggers (a16).
- **[16]** QR availability surfaced as presence + production flag; the result contains no
  `public_token` and the item's token string never appears in the serialized result (a12); true +
  production when an active production QR exists (a13).
- **[17]** No provenance created: collectors/ownership/claims/auth/cert/qr counts unchanged across an
  assignment (a1 asserts equality).
- **[18]** Unauthenticated POST → redirect to login; view-only staff (no assign ACL) → 403; assign ACL
  without manager override + no variant link → request allowed but service refuses (a14).
- **[19]** Rejection leaves no partial state: every reject path writes no sale link (asserted across
  a2/a3/a5/a6/a7/a8/a9/a10/a11); a `SaleLinkRejection` rolls back the outer transaction (the binding),
  then a rejected audit row is recorded separately.

## [20] Exact totals + two DISCLOSED candidate corrections (not silent repairs)
- `ShopifyOrderItemAssignmentTest`: **17 tests, 64 assertions, 0 errors, 0 failures, 0 warnings, 0
  skipped** (after the corrections).
- **Correction 1 — product DEFECT fixed (`c37592b → 5b29338`):** `OrderAssignmentController` called the
  core `User::hasPermission()` directly, which throws `TypeError` (`in_array` on a null `permissions`)
  for an **`all`-type staff role** → a 500 for a manager viewing/performing an assignment. Switched to
  `bouncer()->hasPermission()` — the same `all`-safe API the `sca.can` ACL middleware (`ScaAuthorize`)
  uses. No behavior change for `custom` roles. (Surfaced by a14/a15.)
- **Correction 2 — TEST FIXTURE corrected:** the two HTTP-path tests used a non-numeric line id
  (`'L1''`), which the controller correctly rejects (`line_item_id` must be `^[0-9]{1,24}$`, matching
  real Shopify line ids). Fixtures now use numeric line ids. Not a product change.
- No failing product code was masked.

## [21] Pre-existing, unrelated failures + safeguard notes
- **`ShopifyReconciliationTest` rc8 + rc21 FAIL (2):** `GET /admin/sca/shopify/operations` with an
  `all`-type staff → 500. Root cause: `OperationsController::index` (line 81,
  `auth()->user()?->hasPermission('sca.shopify.reconcile')`) hits the SAME core
  `User::hasPermission(null)` crash for an `all` role. **This file is byte-identical to baseline
  `5bed316` (`git diff` empty) and this change does not touch it.** PROVEN pre-existing: with this
  branch's ACL/menu/routes reverted to baseline, rc8/rc21 still fail identically. It is therefore NOT a
  regression from this candidate — it is a latent defect in the already-deployed Operations screen,
  reported here for a SEPARATE fix (switch that call to `bouncer()` too). Not changed in this task
  (unrelated development).
- **Manager-override safeguard:** verified sound — the override requires BOTH the dedicated manager ACL
  and a recorded non-empty reason; the UI checkbox/field are cosmetic, enforcement is server-side in
  the service.
- **Mismatched-variant safeguard:** verified sound — fail closed on any mismatch, including a null
  purchased variant.
- Residual (unchanged from the implementation doc): grant/claim tokens are not involved here; the
  feature stores no token.

## [22] Cleanup verified
`REVOKE ALL` → `DROP USER 'sca_test'@'%'` → `DROP DATABASE sca_domain_test`. Post-checks:
`sca_domain_test` gone; `mysql.user` count for `sca_test` = 0; `sca_krayin` present. Worktree removed;
test `.env` shredded + probe deleted.

## [23] Production unchanged
Live SHA **`5bed316`**, `main`, clean; loopback `/admin/login → 200`. `sca_krayin`: migrations batch
**29 / 145**; items **3** / ownership **5** / claims **2** / cert **4** / qr **3** / sale_links **1**;
`sca_shopify_order_item_assignments` **absent (0)**.

**STOP — candidate `5b29338` (was `c37592b`) passes the authorized isolated regression (17/17 +
compatible sale-link/claim suites). Production untouched. The 2 reconciliation failures are a
pre-existing, unrelated `OperationsController` `all`-role `hasPermission` crash (recommend a separate
`bouncer()` fix). NEXT (separate auth): code-only merge review of `5b29338` → controlled deploy (1
additive migration, migrate-before-code). SEPARATE OPEN: Phase-1 first genuine `products/*` webhook
receipt verification.**

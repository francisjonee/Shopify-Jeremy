# SCA — Secure Ownership Claim Integration (R0/R0b/R0c onto the prod line)

**Authorized development task. DONE: R0/R0b/R0c secure buyer-verification claim integrated onto the
deployed production line (`4faf84d`) — conflict-free — preserving all deployed Shopify-sync, staff
order-assignment, QR, and transfer-status features.** Branch `feat/sca-secure-claim-integration` head
**`9e4c6396145770212e05101868b8d77d84a6b6f4`** (merge `f84dc1c` of R0c head `539cd1f` + one new
integration test). `php -l` clean. DB-backed tests NOT run (separate disposable-DB authorization
required). Dev branch only — no deploy/merge/migration/prod-DB/Shopify/email change. 2026-10-29.
**STOP for review.**

## [1] Branch histories & R0/R0b/R0c commits
- Prod line `4faf84d` (order-assignment + QR + transfer-status) and the R0c source share base
  **`cb8a8c3`**. The R0/R0b/R0c work is the 7-commit chain on `origin/main`'s second merge parent:
  `e644c9c^2 = 539cd1f` — `ce74229` (R0) → `bf77490` (R0 e16) → `1592a78` (R0b) → `c1e252a` (R0c) →
  `3148029`/`b042125`/`539cd1f` (R0c corrections/fixes).

## [2][3] Integration method
- Branch off prod **`4faf84d`**; `git merge --no-ff 539cd1f` (three-way base `cb8a8c3`). 539cd1f
  contains ONLY R0/R0b/R0c (transfer-status was merged separately into `origin/main`), so this brings
  **only the claiming changes** — nothing else.

## [4][5] Conflicts & feature preservation
- **Conflict-free.** The two changesets are **file-disjoint** (R0c: 33 files, prod-line: 18 files, **0
  overlap**), so the merge produced no conflict markers. Nothing was resolved by weakening security.
- Deployed features **preserved** (present + untouched in the merged tree): `OrderItemAssignmentService`,
  `OrderAssignmentController` (QR packing-readiness copy intact — "QR ready for packing", 0 "staging"),
  `SaleLinkEventProcessor`, `TransferController`/transfer-status, `EyewearItemController` (QR label),
  catalog sync. The full change vs `4faf84d` is exactly the 33-file R0c set + 1 new integration test.

## [6] Public-QR-only claiming disabled
`ClaimWorkflow::claim(token, collector)` → throws `ClaimRejection::PUBLIC_CLAIM_RETIRED` before any
resolve/mutation (R0). It cannot grant ownership. The only ownership paths are `claimByGrant` (external
intake) and `claimByPresaleGrant` (sce_presale, R0b/R0c).

## [7] Verified-buyer email + exact order→pair binding preserved
`claimByPresaleGrant` → `buyerIsVerified(saleLinkId, collectorId)`: requires the sale link's **trusted
`order_email`** (non-null) AND an **active collector with `email_verified_at` set** whose normalized
email **equals** the order email; otherwise `BUYER_VERIFICATION_REQUIRED`, no ownership. The grant is
bound to the exact item + its eligible sale link (not a variant).

## [8] R0b cannot issue usable bearer-only grants without R0c
A presale grant is redeemable only through `claimByPresaleGrant`, which calls `buyerIsVerified` before
consuming the grant / opening ownership. A grant in hand, without a verified buyer-email match, yields
`BUYER_VERIFICATION_REQUIRED` and no ownership — so R0b's grant is not a usable bearer credential on its
own; R0c verification is mandatory.

## [9] The four additive migrations vs prod batch 30/146
Added vs `4faf84d` (prod is batch 30/146; none of these are applied):
`2026_10_29_000001_add_fulfillment_release_to_sca_eyewear_items` (nullable `fulfillment_released_at/_by`
columns), `2026_10_29_000002_create_sca_presale_claim_grants` (new table), `2026_10_30_000001_add_order_email_to_sca_shopify_sale_links`
(nullable `order_email` column), `2026_10_30_000002_create_sca_collector_email_verifications` (new
table). All **additive** — two new tables + columns added to existing tables; no alteration/drop of
existing columns, no data migration. **Compatible with the batch-30 schema**; on deploy they become
batch 31 (migrate-before-code). The prod-line migration `2026_10_31_000001_create_sca_shopify_order_item_assignments`
is already applied (batch 30) and is untouched by this branch.

## [10] Email delivery fails closed with no provider
`CollectorEmailVerification` notification is `via(['mail'])`; with `MAIL_MAILER=log` (no provider) no
real email is delivered, so `email_verified_at` is never set → `buyerIsVerified` returns false →
`BUYER_VERIFICATION_REQUIRED`. The verified-buyer claim therefore **fails closed** when email is not
configured (no bypass). The email-verification error paths log only the exception class (no token/PII).

## [11] Focused integration tests
- **Existing R0c + prod-line suites both present and disjoint** post-merge (VerifiedBuyerClaimTest,
  PresaleClaimGrantTest, OwnershipR0PublicClaimRetiredTest, ClaimWorkflowTest, ShopifySaleClaimVisibilityTest,
  ExternalClaimTest, SaleLinkOrderEmailTest + ShopifyOrderItemAssignmentTest, ShopifyOperationsPermissionTest,
  ShopifyReconciliationTest, ShopifySaleLinkTest). The null-order_email fail-closed case is already covered
  by `VerifiedBuyerClaimTest::missing_order_email_on_sale_link_fails_closed`.
- **NEW `SecureClaimOrderAssignmentIntegrationTest`** (the actual seam, written, NOT run): (a) a STAFF
  assignment via `OrderItemAssignmentService` creates a sale link with **null `order_email`**, and a
  presale claim against it by a VERIFIED collector is rejected `BUYER_VERIFICATION_REQUIRED` with no
  ownership; (b) public-QR-token claiming stays `PUBLIC_CLAIM_RETIRED` with order-assignment present.

## [12] Static validation
`php -l` clean on the new test and the key merged files (`ClaimWorkflow`, `SaleLinkService`,
`OrderItemAssignmentService`). No conflict markers anywhere.

## [14] Exact changes, outstanding risks, required DB tests
- **Changes:** merge of 539cd1f (33 R0c files incl. the 4 migrations, services, controllers, routes,
  notification, ACL, backfill command, and R0c tests) + 1 new integration test. **No prod-line file was
  modified** (disjoint).
- **OUTSTANDING RISK / FOLLOW-UP (not a conflict):** `OrderItemAssignmentService` calls
  `SaleLinkService::linkPaidLine` with **no** `order_email` (R0c added it as an optional 7th param), so
  **staff-assigned sale links have `order_email = NULL` and are not verified-buyer-claimable until the
  email is populated.** This is *secure* (fails closed), but means the staff order-assignment path and
  the verified-buyer claim don't yet connect end-to-end. A small follow-up (separate task) should have
  `OrderItemAssignmentService` pass the authoritative order email (it already fetches the order via
  `getOrder`, whose DTO now carries `email`) into `linkPaidLine`, mirroring the webhook/reconcile paths.
  Until then, verified claims depend on order_email arriving via the webhook/reconcile propagation or
  backfill.
- **Required DB tests (next, separately-authorized disposable-DB session):** run the combined suite —
  `VerifiedBuyerClaimTest`, `PresaleClaimGrantTest`, `OwnershipR0PublicClaimRetiredTest`,
  `ClaimWorkflowTest`, `ShopifySaleClaimVisibilityTest`, `ExternalClaimTest`, `SaleLinkOrderEmailTest`,
  `ShopifyOrderItemAssignmentTest`, `ShopifyOperationsPermissionTest`, `ShopifyReconciliationTest`,
  `ShopifySaleLinkTest`, and the new `SecureClaimOrderAssignmentIntegrationTest` — expecting all GREEN
  (the R0c suites previously passed 77/77 at `539cd1f`; the prod-line suites 83/83 at `4faf84d`; the
  disjoint merge should preserve both).

## Safety / scope
Dev branch only; prod `4faf84d` + live bind-mount untouched (still `4faf84d`, clean, 200); `origin/main`
(`a397a7e`) untouched; no migration run, no prod-DB write, no Shopify/CLI/email change, no deploy/merge,
no buyer-verification weakening, no Option-C.

**STOP — R0/R0b/R0c integrated onto the prod line conflict-free (`9e4c639`); security invariants intact
(public-QR retired, verified-buyer gate, R0b-needs-R0c, email fails closed); 4 additive migrations
compatible with batch 30. OUTSTANDING: a follow-up to wire the authoritative order email through the
staff order-assignment path (staff-assigned links are currently null-order_email → fail closed). NEXT
(separate auth): combined disposable-DB regression → then the launch path (email provider → deploy).
SEPARATE OPEN: none from Phase-1 (product-webhook verification COMPLETE).**

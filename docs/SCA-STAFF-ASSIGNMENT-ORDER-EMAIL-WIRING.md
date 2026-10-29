# SCA — Staff Order-Assignment → Trusted Order-Email Wiring (R0c seam closed)

**Authorized development on the secure-claim integration branch.** Closes the outstanding seam: the
staff order→eyewear assignment now propagates the **trusted** buyer email from the authoritative
Shopify `getOrder` into the sale link, so a staff-assigned pair becomes verified-buyer-claimable (R0c).
Email comes ONLY from the authoritative response — never staff/form/QR/customer input. `php -l` clean.
DB-backed tests added but NOT run (separate disposable-DB authorization required). Dev branch only — no
merge/deploy/migration/prod-DB/Shopify/email change. 2026-10-29. **STOP for review.**

## Branch / SHA
- `feat/sca-secure-claim-integration`: `9e4c639` → **`c65dc1f9d9190df1997fc56dc38cd1b394b7bdc3`**
  (pushed origin). Live `/opt/sca-platform` untouched (`4faf84d`, clean, 200). **3 files** (1
  production, 2 tests). No migration.

## [2][3] The trusted email already available
`AuthoritativeOrder::fromShopify()` already parses the trusted buyer email into `->email`
(`$order['email']` else `$order['customer']['email']`; null if empty/whitespace; otherwise
`strtolower(trim())`). `OrderItemAssignmentService::assign()` already builds this `$order` from a
read-only `getOrder`. The reference consumers (`ShopifyReconciliationService` line 101,
`SaleLinkEventProcessor`) already forward this email to `SaleLinkService::linkPaidLine` as its optional
7th `$orderEmail` arg.

## [4] The one-line wiring (production change)
`OrderItemAssignmentService::assign()` — the sale-link write inside the outer transaction:
```php
// before
$r = $this->saleLinks->linkPaidLine($shop, $orderId, $lineItemId, $ref, $line['productId'], $purchasedVariant);
// after
$r = $this->saleLinks->linkPaidLine($shop, $orderId, $lineItemId, $ref, $line['productId'], $purchasedVariant, $order->email);
```
(`$order` added to the closure's `use(...)`.) This uses the existing R0c interface; nothing else in the
assignment path changed.

## [5] Email source is authoritative only
The email is read solely from `$order->email` (the authoritative `getOrder` response). `assign()` has
**no** email parameter, and the controller passes none — so staff form input, QR tokens, and
customer-supplied/unauthenticated data can never set it. Same trusted-source rule as the webhook and
reconcile paths.

## [6] Invariants preserved
Exact order/line/item binding, variant matching (link-match or manager override), Administrator
override, append-only audit, and all `SaleLinkService` sale-link invariants are unchanged — only the
trusted email is now supplied to the same writer.

## [7] Fail-closed on missing/invalid/unavailable email
`AuthoritativeOrder::email()` returns `null` for a missing/empty/whitespace email → the link stores
`null` → `buyerIsVerified` returns false → `BUYER_VERIFICATION_REQUIRED` (no ownership). A malformed but
non-empty value is stored normalized **as-is** (never fabricated or substituted); it simply will not
match any VERIFIED collector email, so verification still fails closed. No email is ever invented.

## [8] No overwrite on retry / conflict
`SaleLinkService::linkPaidLine` treats an existing `(shop, line)` row as authoritative and returns
`exists` **without writing** — so a re-assignment (same or a conflicting/later email) never overwrites a
stored `order_email`. The trusted email captured on first creation is immutable via this path. (Tests
a25/a26.)

## [9] Compatibility with webhook / reconcile / refund / cancellation
- Webhook (`SaleLinkEventProcessor`) and reconcile (`ShopifyReconciliationService`) already pass the
  trusted email; this change makes the staff path consistent with them (same 7th arg, same normalization
  via `AuthoritativeOrder`/payload parse).
- Refund/cancellation are unaffected: `assign()` fails closed for cancelled orders
  (`SCA_ASSIGN_ORDER_CANCELLED`) and refunded lines (`SCA_ASSIGN_LINE_REFUNDED`) before any link write
  (existing tests a6/a7), so no `order_email` is written for them; `cancelLine`/`revokeLine` are
  untouched and do not set `order_email`.

## [10] Focused tests (DB-backed; NOT run)
`ShopifyOrderItemAssignmentTest` additions:
- **a21** authoritative top-level email → stored normalized.
- **a22** missing email → null.
- **a23** `customer.email` fallback → propagated.
- **a24** whitespace email → null (no fabrication/substitution).
- **a25** duplicate assignment → `exists`, one row, `order_email` preserved.
- **a26** conflicting re-assign (order now reports a different email) → `exists`, `order_email`
  unchanged (never overwritten).
- Refund/cancellation (a6/a7) and "no ownership created by assignment" (a1) already covered.

`SecureClaimOrderAssignmentIntegrationTest` (updated, end-to-end):
- **positive path** — staff-assign an order whose trusted email matches a VERIFIED collector → that
  buyer claims → exactly one ownership (the fix proven end-to-end);
- **null email** → verified-buyer gate fails closed (no ownership);
- **public-QR claim** stays `PUBLIC_CLAIM_RETIRED` with order-assignment present.

## [11] R0 / verified-buyer requirements preserved
`ClaimWorkflow::claim` still → `PUBLIC_CLAIM_RETIRED`; `claimByPresaleGrant` still requires
`buyerIsVerified` (non-null trusted `order_email` + verified collector email match) → no bypass, no
security weakening.

## [12] Static validation
`php -l` clean on `OrderItemAssignmentService.php`, `ShopifyOrderItemAssignmentTest.php`,
`SecureClaimOrderAssignmentIntegrationTest.php`. Production diff vs `9e4c639` = exactly the two lines in
`OrderItemAssignmentService`.

## [14] Migration dependencies / required regression
- No new migration. Depends on the R0c `order_email` column (migration
  `2026_10_30_000001_add_order_email_to_sca_shopify_sale_links`) already on this branch (batch 31 on
  deploy; additive; not applied in prod).
- **Required (next, separately-authorized disposable-DB session):** FULL combined isolated regression of
  the whole integration branch `c65dc1f` — the R0c suites (VerifiedBuyerClaimTest, PresaleClaimGrantTest,
  OwnershipR0PublicClaimRetiredTest, ClaimWorkflowTest, ShopifySaleClaimVisibilityTest, ExternalClaimTest,
  SaleLinkOrderEmailTest), the prod-line suites (ShopifyOrderItemAssignmentTest incl. a21-a26,
  ShopifyOperationsPermissionTest, ShopifyReconciliationTest, ShopifySaleLinkTest), and
  SecureClaimOrderAssignmentIntegrationTest — expecting all GREEN, on an internal no-egress network with
  Http::fake.

**STOP — trusted order-email wired through the staff order-assignment path (`c65dc1f`); staff-assigned
sale links now carry the authoritative buyer email so the verified-buyer claim can match, with no
weakening (authoritative-only source, fail-closed on missing/invalid, no overwrite on retry). NEXT
(separate auth): the full combined isolated regression of the integration branch before any release
preparation. No merge/deploy/migration/Shopify/email change made.**

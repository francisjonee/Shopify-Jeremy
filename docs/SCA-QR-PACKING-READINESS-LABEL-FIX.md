# SCA — QR Passport Packing-Readiness Label Correction

**Authorized display-only fix for the misleading "staging — not for print" packing message.** The
order-assignment confirmation derived its QR packing-readiness wording from the `is_production` flag,
but certification always mints QRs `is_production=false` and the QR label/print routes ignore the flag —
so every normally certified item was mislabeled "staging — not for print" even though its label prints
and scans normally. The fix bases the message solely on whether the item has an ACTIVE QR. No change to
QR creation, rotation, revocation, identity, stored flags, routes, certification, ownership,
authentication, or claim behavior. Static checks PASS (`php -l`). DB-backed tests written but NOT run
(no disposable-DB authorization). Dev branch only off prod `eb137bf`; not deployed. 2026-10-29. **STOP.**

## SHA & branch
- Branch `fix/sca-qr-packing-readiness-copy` off prod **`eb137bf`** → head
  **`a0bd8db418d8a5396f51b39bf7bab9c98be7d872`** (pushed to origin). Live checkout untouched (`eb137bf`,
  `main`, clean; loopback 200).
- **2 files:** 1 production (OrderAssignmentController — one message line + comment), 1 test. No
  migration, no schema, no DB write.

## [2] All `is_production` uses + its intended meaning
- Set only in `QrService::createIdentity(itemId, isProduction=false)` (default false) and carried onto a
  reissued replacement (`reissue` copies the previous flag). The migration comment reads "staging tokens
  never printed."
- **`CertificationService::issue()` calls `createIdentity($itemId)` with no flag → every certified
  item's QR is `is_production=false`.** Nothing in the normal flow ever sets it `true`.
- The QR label/image routes (`EyewearItemController::qr` / `qrLabel` / `qrLabelsBatch`) each document and
  behave as "never touches is_production" — they render the real passport QR for ANY active QR.
- The ONLY consumer that read the flag for a user-facing decision was `OrderAssignmentController` line 93
  (the packing-readiness confirmation). `OrderItemAssignmentService::qrAvailability()` returns
  `[qr_available, is_production]`, but `is_production` was only consumed by that one message.

## [3] Are normally-certified items with an active QR genuinely print-ready? — YES
The label/print routes render the canonical passport QR for any active QR regardless of `is_production`;
a certified item with an active QR is packing-ready. The "staging — not for print" wording was wrong for
them.

## [4] Exact condition that produced "staging — not for print"
`OrderAssignmentController` (old line 93): `qr_available && ! qr_production` → "(staging — not for
print)". Because `qr_production` mirrors the active QR's `is_production`, which certify always leaves
`false`, this branch fired for **every** normally-certified item.

## [5] The fix — display only
`OrderAssignmentController`: the packing message is now derived solely from an ACTIVE QR:
```php
$qr = $result['qr_available']
    ? 'QR ready for packing'
    : 'no active QR yet — authenticate/activate before shipping';
```
The `is_production`/"(production)"/"(staging — not for print)" wording is removed from the confirmation.
**No stored QR flag is changed**, and `qrAvailability()` still faithfully returns the stored
`is_production` value (now simply unused by the message) — so the service contract and its existing
tests are preserved.

## [6] Preserved behavior
QR tokens, the `qr`/`qr/label`/`qr/labels` routes, certification, QR creation/rotation/revocation,
ownership, authentication, and claim behavior are all untouched. The only production change is the one
confirmation-string line.

## [7] Revoked / inactive QR never described as ready
`qr_available` comes from `ProjectionService::activeQrIdentifier()`, which nets `activated − revoked`
lifecycle events — so a revoked or absent QR yields `qr_available=false` → "no active QR yet …", never
"ready for packing." (Covered by test a18/a20.)

## [8] Focused tests (written, NOT run — DB-backed)
Added to `tests/Feature/Sca/ShopifyOrderItemAssignmentTest.php`:
- **a17** active QR with `is_production=false` (staging flag) ⇒ `qr_available=true` (packing-ready),
  `qr_production=false` (flag faithfully reported, does not gate).
- **a18** QR activated then revoked ⇒ `qr_available=false` (not packing-ready).
- **a19** HTTP assign with an active QR ⇒ confirmation flash contains "QR ready for packing" and NOT
  "staging — not for print"/"(production)".
- **a20** HTTP assign with no active QR ⇒ flash says "no active QR yet", not "ready for packing".
(Existing a12 [absent] and a13 [active, production flag] remain and still pass.) These require a
separately-authorized disposable-DB session to execute.

## [9] Static validation
`php -l` clean on `OrderAssignmentController.php` and `ShopifyOrderItemAssignmentTest.php`. Diff confined
to those two files (6 lines of production code incl. comment; +66 test lines).

## [10] Changed files
- MOD `app/packages/Sca/Shopify/src/Http/Controllers/OrderAssignmentController.php` (packing-readiness
  message now based on active-QR presence; explanatory comment).
- MOD `app/tests/Feature/Sca/ShopifyOrderItemAssignmentTest.php` (+a17–a20).

## Test requirement (next, separately authorized)
On a disposable `sca_domain_test`, run `ShopifyOrderItemAssignmentTest` expecting all cases green
(17 prior + a17–a20 = 21), confirming the corrected wording and the active/absent/revoked/staging
conditions.

**STOP — display-only packing-readiness correction on dev branch `a0bd8db` (off prod `eb137bf`); no QR/
cert/ownership/flag/route change; not deployed. NEXT (separate auth): disposable-DB test run → merge
review → (code-only) release. SEPARATE OPEN: Phase-1 first genuine `products/*` webhook receipt
verification.**

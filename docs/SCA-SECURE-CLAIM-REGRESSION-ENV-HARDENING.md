# SCA — Secure Claim Regression: Environment Hardening (fully green)

**Authorized test-env hardening on the integration branch.** Resolved the environment-dependent test
failures and established a **completely green, reproducible** secure-claim regression: **19 suites,
245 tests, 1141 assertions, 0 failures/errors/warnings/skips.** Test-only corrections (no application
or authentication behavior changed; reset-link origin validation and the collector/admin boundary
preserved). Branch `feat/sca-secure-claim-integration`: `c65dc1f` → **`7da38b8af9be0704c359bb027feaacc4f9f58d3b`**
(pushed). DB-backed tests run on a disposable DB on an `--internal` no-egress network — ZERO live
Shopify requests. Disposable DB dropped + verified; production `sca_krayin` + SHA `4faf84d` unchanged.
No merge/deploy. 2026-10-29. **STOP for review.**

## [2]–[9] Diagnosis & corrections (evidence-based, test-only)
1. **h8 (`TransactionalEmailHardeningTest`) — deterministic:** the test asserts the reset-URL origin is
   the canonical `https://verify.secondchanceauthenticators.com`, but — unlike its sibling origin tests
   (h2/h3/h7) — it did **not** set `config(['app.url' => CANON])`, so it relied on the ambient `APP_URL`
   (which is the prod canon in the authoring/CI env, but `http://localhost` in a disposable test env).
   **Fix:** pin `config(['app.url' => self::CANON])` at the top of h8, exactly like the siblings. Origin
   validation is unchanged — it still asserts the reset URL uses `config('app.url')`.
2. **h7 (`TransactionalEmailHardeningTest`) — flaky, throttle pollution:** `/collector/forgot-password`
   carries `throttle:6,1`. The class POSTs to it in 5 tests sharing one per-IP limiter whose state
   persists in the array cache within the phpunit process, so a later test's POST (h7) could be
   throttled (429) → "notification not sent". It passed in isolation; failure count varied run-to-run.
   **Fix:** `withoutMiddleware(ThrottleRequests::class)` in `setUp()` — the rate limit is not this
   class's subject (enumeration safety, reset-link origin, single-use token are), and no test here
   asserts throttling. CSRF/auth/host behavior under test is unchanged. (Verified non-flaky: green 3×.)
3. **c11 (`CollectorAuthTest`) — expected access-denial, not a regression:** evidence — an acting
   collector GET `/admin/dashboard` returns **302 → `/admin/login` with the `user` guard
   unauthenticated** (`user_guard=0`). The authentication boundary HOLDS (a collector session is not a
   staff user; the dashboard is not served). The test's `assertSee('Something went wrong')` assumed
   Krayin's masked-200 error page; this environment denies via a guest redirect to the staff login.
   **Fix:** assert the denial in **either** supported shape (redirect containing `/admin/login`, OR the
   error page), keeping the guard-check invariants (`user` guard false). **No authentication behavior
   changed** — only the assertion is made environment-robust.

## [10][12] Static checks
`php -l` clean on both edited test files. Changes are confined to `CollectorAuthTest.php` (+15/−4) and
`TransactionalEmailHardeningTest.php` (+9) — **test files only**; no production code touched this task.

## [11]–[14] Isolation & Shopify safety
Fresh `sca_domain_test` (absent + 0 connections before create; scoped `sca_test` user with `ALL` on the
test DB only — no `sca_krayin` access). Isolation verified (getenv == connection == SELECT DATABASE()
== SCA_TEST_DB == `sca_domain_test`, ≠ `sca_krayin`) before migrating (150) + seeding (17). All runs on
a throwaway `docker network --internal sca_testnet` with egress proven BLOCKED (TCP 1.1.1.1:443 fails)
while `kr-mariadb` is reachable → zero live Shopify; fake store domain + `Http::fake`; no prod
credentials read.

## [15][16] Full combined regression — ALL GREEN (definitive pass)
| Suite | Result | | Suite | Result |
|---|---|---|---|---|
| OwnershipR0PublicClaimRetired | 7/29 | | TransferWorkflow | 15/52 |
| PresaleClaimGrant | 12/44 | | TransferStatusClarity | 8/24 |
| VerifiedBuyerClaim | 10/33 | | PublicPassport | 18/83 |
| ClaimWorkflow | 11/44 | | PublicPassportSafety | 14/66 |
| ExternalClaim | 18/93 | | CollectorPrivacy | 21/94 |
| SecureClaimOrderAssignmentIntegration | 3/10 | | QrPrintLabel | 12/36 |
| ShopifyOrderItemAssignment | 27/84 | | CollectorAuth | 16/66 |
| ShopifySaleLink | 23/95 | | TransactionalEmailHardening | 9/24 |
| ShopifySaleClaimVisibility | 12/67 | | ShopifyOperationsPermission | 6/9 |
| ShopifyReconciliation | 21/279 | | | |
**TOTAL: 19 suites, 245 tests, 1141 assertions, 0 failures / 0 errors / 0 warnings / 0 skips.**

Note: in an earlier combined loop, `ExternalClaimTest` showed a single transient failure (18/91) while
every other suite was green; it then passed 18/93 on 3 immediate isolated retries and in the definitive
full pass above. `ExternalClaimTest` is untouched by this task; the blip is a known transient flake in
the shared-DB claim/QR suites (see the suite-deadlock/QR-decode flake notes), not a code failure — and,
per the task, no unrelated fix was applied to it.

## [17] Security rejections still enforced
Within the green suites: public-token-only claiming → `PUBLIC_CLAIM_RETIRED` (OwnershipR0 + integration);
wrong buyer / unverified email → `BUYER_VERIFICATION_REQUIRED` (VerifiedBuyerClaim); invalid/expired/
consumed/void grants rejected (PresaleClaimGrant); refund/cancel block ineligible claims; staff-assigned
order email is authoritative-only and fails closed when missing/invalid (ShopifyOrderItemAssignment
a21–a26 + integration). No security weakening.

## [19] Cleanup verified
`REVOKE ALL` → `DROP USER 'sca_test'@'%'` → `DROP DATABASE sca_domain_test` → gone; `sca_test` count 0;
`sca_krayin` present. `kr-mariadb` disconnected from `sca_testnet`; `sca_testnet` removed (back to
`sca_internal` only). Worktree removed; test `.env` shredded + probe deleted.

## [20] Production unchanged
Live SHA **`4faf84d`**, `main`, clean; loopback 200. `sca_krayin`: migrations batch **30 / 146**; items
**3** / ownership **5** / claims **2** / cert **4** / qr **3** / sale_links **1**.

**STOP — the secure-claim integration regression is now completely green and reproducible
(`7da38b8`, 245/1141/0) after three evidence-based, boundary-preserving test corrections (no app/auth
change). Production + Shopify config untouched; ZERO live Shopify requests. NOT merged. Launch remains
blocked on transactional email + the authorized migrate-before-code deploy (+ fulfillment-release ACL +
order_email backfill + real inventory/order). Phase-1 webhook verification COMPLETE.**

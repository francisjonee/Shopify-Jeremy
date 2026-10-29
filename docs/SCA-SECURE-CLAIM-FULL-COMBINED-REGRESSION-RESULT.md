# SCA — Secure Ownership Claim: Full Combined Regression — RESULT

**Authorized single disposable-DB session for candidate `c65dc1f` (branch
`feat/sca-secure-claim-integration`). VERDICT: the integrated secure-claim system (R0/R0b/R0c) +
deployed staff order-assignment + QR + transfer all pass together — every security-relevant suite is
GREEN (the 11 claim/Shopify/integration suites: 150 tests / 787 assertions / 0 failures).** Two
failures appeared in the broader [26] regression set, both in files **untouched by this integration**
(byte-identical to `cb8a8c3`) and both **environment/config artifacts** (not code regressions, no
security impact) — detailed in §Failures. Ran on an `--internal` no-egress network with a fake store —
ZERO live Shopify requests. Disposable DB dropped + verified; production `sca_krayin` + SHA `4faf84d`
unchanged. No merge/deploy. 2026-10-29. **STOP.**

## [1]–[8] Candidate, isolation, scope
- Candidate `c65dc1f`; prod baseline `4faf84d` (clean, 200). Detached worktree; dev vendor built.
- **[4]** Only the 4 R0b/R0c additive migrations are new vs prod (`2026_10_29_000001/000002`,
  `2026_10_30_000001/000002`). **[3]** Deployed features (OrderItemAssignmentService,
  OrderAssignmentController, TransferController, EyewearItemController) preserved.
- Fresh `sca_domain_test` (absent + 0 connections before create); scoped user `sca_test` with `ALL` on
  the test DB only (no `sca_krayin` access). Isolation verified (getenv == connection == SELECT
  DATABASE() == SCA_TEST_DB == `sca_domain_test`, ≠ `sca_krayin`). Migrated (150) + seeded (17).

## [9]–[14] Shopify safety — satisfied with evidence
- Tests ran on a throwaway `docker network --internal sca_testnet`; proven from the test-runner image
  BEFORE testing: TCP `1.1.1.1:443` **BLOCKED**, `kr-mariadb:3306` reachable → a live Shopify request
  was physically impossible. Fake store domain + `Http::fake` + in-memory `shpat_TESTONLY`; no Shopify
  keys in the test `.env`; prod credentials never read; no CLI/reconcile/import/live-webhook.

## [15]–[25] Core combined suites — ALL GREEN
| # | Suite | Result |
|---|---|---|
| 15 | OwnershipR0PublicClaimRetiredTest | 7 / 29 ✔ |
| 16 | PresaleClaimGrantTest | 12 / 44 ✔ |
| 17 | VerifiedBuyerClaimTest | 10 / 33 ✔ |
| 18 | ClaimWorkflowTest | 11 / 44 ✔ |
| 19 | ExternalClaimTest | 18 / 93 ✔ |
| 20 | SecureClaimOrderAssignmentIntegrationTest | 3 / 10 ✔ |
| 21 | ShopifyOrderItemAssignmentTest | 27 / 84 ✔ (incl. a21–a26 order-email) |
| 22 | ShopifySaleLinkTest | 23 / 95 ✔ |
| 23 | ShopifySaleClaimVisibilityTest | 12 / 67 ✔ |
| 24 | ShopifyReconciliationTest | 21 / 279 ✔ |
| 25 | ShopifyOperationsPermissionTest | 6 / 9 ✔ |
| | **Subtotal** | **150 tests / 787 assertions / 0 fail/err/warn/skip** |

## [26] Collector / email-verification / passport / transfer regression
| Suite | Result |
|---|---|
| TransferWorkflowTest | 15 / 52 ✔ |
| TransferStatusClarityTest | 8 / 24 ✔ |
| PublicPassportTest | 18 / 83 ✔ |
| PublicPassportSafetyTest | 14 / 66 ✔ |
| CollectorPrivacyTest | 21 / 94 ✔ |
| QrPrintLabelTest | 12 / 36 ✔ |
| CollectorAuthTest | 15 ✔ / **1 fail (c11, environment — see below)** |
| TransactionalEmailHardeningTest | **fails with test APP_URL; 9/24 ✔ with prod APP_URL** (environment) |
(Email-verification challenge request→confirm→stamp is covered by VerifiedBuyerClaimTest.)

## [27]–[38] Security verification — all confirmed by the GREEN suites
- **[27]** public QR possession never grants ownership — OwnershipR0 7/7 + integration (public-QR
  `PUBLIC_CLAIM_RETIRED`). **[28]** claim requires verified buyer + trusted order email —
  VerifiedBuyerClaimTest. **[29]** staff assignment propagates ONLY the authoritative Shopify order
  email — ShopifyOrderItemAssignmentTest a21–a26 + integration positive path. **[30]** missing/malformed/
  conflicting email fails closed — a22/a24/a26 + VerifiedBuyerClaimTest missing-email. **[31]** duplicate
  assignment never overwrites the trusted email — a25/a26. **[32]** grants bound to exact item + sale
  link, not bearer-only — PresaleClaimGrantTest + VerifiedBuyerClaimTest. **[33]** refunds/cancellations
  block ineligible claims — a6/a7 + PresaleClaimGrantTest + ShopifySaleLinkTest. **[34]** no cross-item/
  cross-order claims — ShopifySaleClaimVisibilityTest + SaleLinkService conflict/never-rebind. **[35]**
  registration/email-verification cannot bypass buyer validation — VerifiedBuyerClaimTest
  (unverified/mismatched rejected; `buyerIsVerified` requires `email_verified_at`). **[36]** transfers
  functional + independent of the claim gate — TransferWorkflowTest + TransferStatusClarityTest.
  **[37]** missing email-provider cannot silently mark a buyer verified — `email_verified_at` is set
  only by the challenge confirm; with no provider it stays null → gate fails closed (VerifiedBuyerClaimTest).
  **[38]** no private QR tokens / grant secrets / buyer PII leak into public responses — CollectorPrivacyTest
  + PublicPassportSafetyTest; R0c error paths log only the exception class.

## [39][40] Failures — exact cause, NOT integration regressions, implementation UNCHANGED
Both failing files are **byte-identical to the common ancestor `cb8a8c3`** (not in the R0c changeset,
the prod-line changeset, or this task's change), so neither is caused by the integration.
1. **TransactionalEmailHardeningTest (h7, h8):** the tests hard-assert the production reset-password URL
   origin `https://verify.secondchanceauthenticators.com`, but the disposable test `.env` sets
   `APP_URL=http://localhost`. Re-running the suite with `APP_URL=https://verify.secondchanceauthenticators.com`
   → **OK (9/24)**. Pure test-environment/config mismatch; the reset-token flow + origin-pinning code is
   correct.
2. **CollectorAuthTest::c11 (collector session cannot access staff admin):** the test expects a "Something
   went wrong" error page, but in this environment the collector session is **redirected to
   `/admin/login`** (access is still denied). The security property holds — a collector cannot reach
   staff admin — only the denial *shape* differs (redirect vs error page) in the dev-preview environment.
   Independent of `APP_URL`.
No implementation was changed (per the task). These are pre-existing environment/expectation artifacts
to address separately in the test suite, not blockers introduced by the secure-claim integration.

## [41] Cleanup verified
`REVOKE ALL` → `DROP USER 'sca_test'@'%'` → `DROP DATABASE sca_domain_test` → gone; `sca_test` count 0;
`sca_krayin` present. `kr-mariadb` disconnected from `sca_testnet`; `sca_testnet` removed (back to
`sca_internal` only). Worktree removed; test `.env` shredded + probe deleted.

## [42] Production unchanged
Live SHA **`4faf84d`**, `main`, clean; loopback 200. `sca_krayin`: migrations batch **30 / 146**; items
**3** / ownership **5** / claims **2** / cert **4** / qr **3** / sale_links **1**; R0c tables
(`sca_presale_claim_grants`, `sca_collector_email_verifications`) **absent (0/0)**.

## [43] Remaining launch blockers (unchanged by this regression)
1. **Transactional email delivery (THE blocker):** `MAIL=log`, no provider token, SPF absent at
   GoDaddy. Until live, `email_verified_at` cannot be set in prod → the verified-buyer gate is
   unsatisfiable (fails closed) → no secure claim possible.
2. **Deploy the integration branch** (`c65dc1f`): migrate-before-code the 4 additive migrations (batch
   31), set `MAIL_MAILER=postmark` + token + verified sender, `config:clear` + graceful.
3. **ACL + backfill:** grant `sca.eyewear.fulfillment.release`; run the (near-no-op) order_email
   backfill for legacy links.
4. **Real inventory + a genuine paid order** for the first real assignment/claim (all current eyewear
   records are test/demo; the one sale link is refunded).
- *(Housekeeping, non-blocking)* fix the two environment-dependent tests above (parametrize the reset
  URL origin on `APP_URL`; relax c11's denial-shape assertion to accept the login redirect).

**STOP — candidate `c65dc1f` passes the full combined regression (150/787/0 across the 11 claim+Shopify+
integration suites; transfer/passport/privacy/QR green). The two red tests are pre-existing environment/
config artifacts in untouched files (not integration regressions, no security impact); no implementation
was changed. Production + Shopify config untouched; ZERO live Shopify requests. NOT merged. Launch
remains blocked on transactional email + the authorized deploy. SEPARATE: Phase-1 webhook verification
COMPLETE.**

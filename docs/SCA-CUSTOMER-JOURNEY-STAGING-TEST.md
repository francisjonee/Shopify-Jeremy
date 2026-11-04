# SCA — Complete Customer Journey Staging Test (software testing only)

**The entire Shopify purchase→customer-owned-Passport journey was built as a test-only integration and
exercised end-to-end in a proven-isolated disposable environment — and it all passes. The integration
(`test/customer-journey-on-e3f73f8b` = `ce1f8da`) is the consolidated secure-claim RC layered onto the
exact current production commit `e3f73f8b`; its tree is byte-identical to the already-audited RC
`f4509f70`, 46 files vs prod all inside `Sca` packages + tests, with the 4 additive secure-claim
migrations and no composer/config/Docker/Caddy/.env/CI change. In a disposable `sca_domain_test` DB
(restricted user barred from `sca_krayin` by grant — ERROR 1044 — with all external network egress
blocked, fake Shopify credentials, and the array mail transport), the complete regression suite passed
1,611 tests / 1 skip / 8,256 assertions / 0 failures / 0 errors, and every customer-journey step and
every security/failure case maps to a specific passing test. Zero product defects were found. The only
non-passing result encountered was the test suite's own hard safety guard refusing to run outside a DB
named `sca_domain_test` (a deliberate interlock, resolved by naming the disposable DB correctly) — an
environment/harness matter, not a product defect. Production was never touched: live tree stayed at
`e3f73f8b`, the prod DB fingerprint is unchanged (items 208, sale_links 1, migrations 146, 0 secure-claim
tables/columns), every simulated record existed only in the disposable DB, and the whole sandbox was torn
down afterward. The integration branch is preserved for future use. Secure buyer claiming was NOT deployed
or activated; `origin/main` was NOT merged.** 2026-11-04. **STOP.**

> Written for: the owner (Jeremy) and the external auditor. Software testing only, under owner
> authorization. Baseline: live prod `e3f73f8b`; consolidated secure-claim RC `f4509f70`.

## Phase 1 — Test release preparation
- Live production verified at `e3f73f8b5f027f14fe61b70faa2cba27e1b4510e` (branch `main`, clean tree).
- Built a **test-only integration** by merging the consolidated secure-claim RC `f4509f70` onto a branch
  based on the exact production commit `e3f73f8b`: `test/customer-journey-on-e3f73f8b` = **`ce1f8da`**
  (one merge, one add/add conflict in `PassportP2UxTest.php` resolved to the RC's fuller version).
- **Diff audit `e3f73f8b..ce1f8da`:** 46 files, **all within `Sca` packages + `tests/`**; the 4 additive
  secure-claim migrations (batch 31: fulfillment cols, `sca_presale_claim_grants`, sale-link `order_email`,
  `sca_collector_email_verifications`); **zero** composer/config/Docker/Caddy/.env/CI changes. The
  integration tree is byte-identical to the already-audited RC `f4509f70`. `origin/main` NOT merged.
- **NOT deployed.**

## Phase 2 — Isolated test environment (isolation proven before any DB change)
- Disposable DB `sca_domain_test` (utf8mb4_unicode_ci) + restricted user `sca_jtest` granted ONLY on
  `sca_domain_test.*`. Internal (egress-blocked) docker network; runner from `sca-app:krayin-2.2.6` with
  the integration worktree mounted **read-only** + writable overlay volumes (vendor/storage/bootstrap-cache);
  `.env` copied from live then overridden: DB→disposable, Shopify→fake, `MAIL_MAILER=array`, `APP_ENV=testing`.
  Dev deps (phpunit) installed on a bridge, then the runner was moved to the internal-only network.
- **Isolation proofs (before migrate/test):** `github.com`/`packagist.org` unresolvable (egress blocked);
  `sca_jtest` + correct password → `sca_krayin` = **ERROR 1044 Access denied**; → `sca_domain_test` = OK;
  Laravel `db:show` = `sca_domain_test` @ `kr-mariadb`, env `testing`, mail `array`.
- `migrate:fresh --seed` applied all migrations incl. the 4 secure-claim ones (verified present in the
  disposable DB). Fake Shopify creds + mocked API; no real email; no real Shopify request.

## Phase 3 — Complete customer journey (all green; simulated data)
Each step verified by the integration's own feature tests (factories + `RefreshDatabase`):

| # | Journey step | Covering test(s) | Result |
|---|---|---|---|
| 1–2 | Register item + associate fake Shopify variant | `CertificationWorkflowTest`, `QrLabelIdentityTest` (variant-linked fixtures) | ✅ |
| 3–4 | Simulated authentication w/ grade → finalize | `CertificationWorkflowTest` (C-series), `StaffDashboardIdentityTest` | ✅ |
| 5 | Certify → unique QR Passport | `CertificationWorkflowTest`, `QrArtifactTest` (rg1–rg10) | ✅ |
| 6 | Public Passport + certificate PDF | `PublicPassportTest` (P1–P18), `CertificatePdfTest` | ✅ |
| 7 | Fixed-size QR label PDF | `QrLabelPdfTest` (single + batch, page-per-label, canonical URL) | ✅ |
| 8–9 | Simulated paid eligible order → assign exact order line to item | `SecureClaimOrderAssignmentIntegrationTest`, `SaleLinkOrderEmailTest` | ✅ |
| 10 | Authorized staff fulfillment release | `PresaleClaimGrantTest` (release requires ACL; idempotent) | ✅ |
| 11 | Generate private buyer-claim link | `PresaleClaimGrantTest` (grant issuance idempotent) | ✅ |
| 12–13 | Register test customer + email-verification link (simulated delivery) | `VerifiedBuyerClaimTest` (request/confirm), `ClaimEmailVerificationUxTest`, `CollectorAuthTest` | ✅ |
| 14 | Verified customer email matches trusted fake order email | `VerifiedBuyerClaimTest`, `SaleLinkOrderEmailTest` (trusted email normalized) | ✅ |
| 15 | Complete ownership claim | `VerifiedBuyerClaimTest`, `PresaleClaimGrantTest` (exactly one ownership) | ✅ |
| 16 | Item appears in My Collection | `CollectorCollectionTest` (C1–C32) | ✅ |
| 17–18 | Authorized collector→collector transfer; history correct | `TransferWorkflowTest` (T1–T14, exactly one current owner, history preserved) | ✅ |

## Phase 4 — Security & failure cases (all green)
| Security property | Covering test | Result |
|---|---|---|
| QR-only claiming cannot create ownership | `OwnershipR0PublicClaimRetiredTest` (410, zero ownership) | ✅ |
| Unverified email cannot claim | `VerifiedBuyerClaimTest` "unverified even if matching is rejected" | ✅ |
| Incorrect buyer email cannot claim | `VerifiedBuyerClaimTest` "wrong buyer … rejected" (match case-insensitive) | ✅ |
| Missing trusted order email cannot claim | `VerifiedBuyerClaimTest` / `SaleLinkOrderEmailTest` "missing email fails closed" | ✅ |
| Unpaid/refunded/cancelled/ineligible cannot claim | `VerifiedBuyerClaimTest`, `PresaleClaimGrantTest`, `SaleLinkOrderEmailTest` (refund/cancel replay never restores eligibility) | ✅ |
| Missing fulfillment release cannot claim | `PresaleClaimGrantTest` "grant requires fulfillment release first" | ✅ |
| Unauthorized staff cannot release | `PresaleClaimGrantTest` "release requires the fulfillment-release ACL" | ✅ |
| Claim links are single-use | `PresaleClaimGrantTest` "double claim is single-use idempotent" | ✅ |
| Duplicate ownership claims rejected | `PresaleClaimGrantTest`, `VerifiedBuyerClaimTest` (replay/second buyer) | ✅ |
| Non-owners cannot transfer | `TransferWorkflowTest` T2/T7/T12 | ✅ |
| Public Passport exposes no customer info | `PublicPassportSafetyTest`, `PublicPassportTest` P9–P11 | ✅ |
| No duplicate active QR | `QrArtifactTest` rg6, `CertificationWorkflowTest` | ✅ |
| Authentication/certification restrictions intact | `CertificationWorkflowTest` C16–C18 (DB trigger blocks ineligible/cross-item) | ✅ |

## Phase 5 — Regression & results
- **Complete suite** `tests/Feature/Sca`: **1,611 passed / 1 skipped / 8,256 assertions / 0 failures /
  0 errors** (382s). Matches the RC baseline exactly.
- Focused journey/order run: 101/433/0. Focused claim/transfer/collection/security run: 106/400/0.
- **1 skip** = a pre-existing conditional skip (same single skip seen in every prior RC run), not a defect.
- **Product defects found: none.** The only non-pass encountered was the suite's hard guard "Refusing to
  run outside sca_domain_test" — a deliberate test-harness safety interlock that aborts if the connected DB
  is not the disposable `sca_domain_test`. It fired because the disposable DB was first named
  `sca_journey_test` (for concurrency-safety); renaming it to `sca_domain_test` cleared it. **Environment/
  harness, not product. Nothing was auto-fixed; no product code changed.**
- **Isolation of simulated data:** every record was created only in the disposable `sca_domain_test`; the
  test user is barred from `sca_krayin` by grant (1044). Production live tree stayed at `e3f73f8b`; prod DB
  fingerprint unchanged (items 208, sale_links 1, migrations 146, 0 secure-claim tables, 0 `order_email`).
- **Cleanup:** runner, disposable DB, test user, internal network, overlay volumes, worktree, and the
  temporary DB password file all removed; prod `kr-app`/`kr-mariadb` healthy.
- **Integration branch preserved:** `test/customer-journey-on-e3f73f8b` = `ce1f8da` (local + origin).

## What works / what remains before a real-world launch
- **Works (proven in staging):** the entire purchase→ownership software path — issuance (authenticate →
  certify → QR + label/PDF → public Passport), Shopify order→pair assignment with trusted order-email
  capture, fulfillment release → private claim link, verified-buyer email-gated claim, My Collection, and
  collector→collector transfer — plus all listed security invariants.
- **Remains (operational, not code — unchanged by this test):**
  1. **Transactional email (SMTP)** — the claim's email-verification step needs real delivery; still
     unconfigured (`MAIL=log` in prod). See `SCA-TRANSACTIONAL-EMAIL-READINESS-2026-11-03.md`.
  2. **Owner-authorized deploy of the secure-claim RC** — migrate-before-code of the 4 additive migrations;
     claiming must launch via the RC (its R0 closes the latent pre-R0 public-claim GAP-1 still on prod).
  3. **`sca.eyewear.fulfillment.release` ACL grant** + **`order_email` backfill** for the existing sale link.
  4. **Physical operations** — per-pair authentication (throughput gate) + QR-label printing + a first real
     paid order / certified pair.
  (See `SCA-PURCHASE-TO-PASSPORT-LAUNCH-READINESS.md`.)

## Safety posture (this task)
Software testing only. ZERO production DB writes; ZERO Shopify API requests/modifications; the 205 imported
records untouched; no live authentication/certification/QR issuance/customer claims; no real emails; no
Postmark configuration; no production deployment or migration; no production settings change; secure buyer
claiming NOT activated; `origin/main` NOT merged. All tests ran in a disposable, egress-blocked environment
whose DB user could not reach production. Sandbox fully torn down; the test integration branch preserved.

**STOP — Customer-journey staging test COMPLETE. Integration `test/customer-journey-on-e3f73f8b` = `ce1f8da`
(secure-claim RC `f4509f70` onto prod `e3f73f8b`, tree-identical to the audited RC; 46 files all Sca+tests;
4 additive migrations). Isolated disposable `sca_domain_test`: full suite 1,611 passed / 1 skip / 8,256
assertions / 0 fail / 0 error; every journey step + security case maps to a passing test; ZERO product
defects (the only non-pass was the suite's own `sca_domain_test` safety guard — harness, not product).
Production untouched (tree `e3f73f8b`, DB fingerprint identical); sandbox torn down; branch preserved;
secure claiming NOT deployed/activated; `origin/main` NOT merged. Remaining pre-launch items are
operational: SMTP, RC deploy + owner auth, fulfillment ACL + order_email backfill, physical auth/QR/first
real order.**

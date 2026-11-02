# SCA — Secure Buyer Claiming: Release Preparation (read-only)

**The secure buyer-claiming release candidate (`4bd88d2`) is implementation-complete and its four
security invariants hold in code: (4) public QR scanning alone cannot claim — public-token claiming is
permanently retired (410, no claim row, no ownership); (5) a claim completes only when the collector's
VERIFIED email matches the TRUSTED Shopify order email (fail-closed on missing/unverified/mismatch);
(6) staff fulfillment-release (dedicated ACL) and an eligible staff-assigned Shopify sale line are
required, with the trusted email sourced only from the authoritative Shopify order; (7) all four
migrations are additive and leave the existing 205 imported records safely NON-claimable by default.
The RC was cut from `4faf84d` and now sits one release BEHIND production (`6e36aa7` added three
unrelated features afterwards), so it must be RE-INTEGRATED onto current production before deployment —
a clean, low-risk operation: only 2 files overlap and both conflicts are purely additive. Deployment
remains BLOCKED on two things, neither of which is a code fault: a working transactional-email (SMTP)
transport, and separate owner deploy authorization.** READ-ONLY review; nothing built, merged,
migrated, or deployed; production unchanged at `6e36aa7`; all 205 imported records preserved.
2026-11-02. **STOP.**

> Written for: the owner (Jeremy) and the external auditor reading from GitHub. No production write, no
> Shopify call, no claim activation.

---

## 1. The release candidate vs. current production
| | commit | date | contents |
|---|---|---|---|
| Current production (live working tree + local main) | `6e36aa7` | 2026-10-30 | baseline + 3 features |
| Secure-claim RC (`release/sca-secure-claim`) | `4bd88d2` | 2026-10-29 | baseline + 12 claim commits |
| Shared merge-base | `4faf84d` | 2026-10-29 | common ancestor |
| origin/main (DO NOT pull) | `a397a7e` | 2026-10-29 | a **different** divergent integration line |

**The RC predates current production.** Both branch from `4faf84d`. The RC adds **12 commits**
(`ce74229`…`4bd88d2`: R0 retire public claim → R0b private presale grant → R0c verified-buyer gate →
order-assignment wiring → env/test hardening). Production separately advanced **3 commits** that the RC
does **not** contain:
- `a53eff3` CSV inventory optional Shopify variant linking
- `b007606` transfer-link Copy/Share (view-only)
- `6e36aa7` document enhancements (Digital Provenance Report + on-demand collector certificate)

Consequence: the RC is **not** based on today's production and cannot be deployed as-is. It must be
re-integrated onto `6e36aa7` first.

## 2. How to integrate onto current production WITHOUT pulling origin/main
origin/main (`a397a7e`) is a separate, already-superseded integration of the same R0 work and must not
be merged (it would drag in unrelated/divergent history). The correct, minimal path keeps the current
live line and replays only the RC's own 12 commits on top:

1. Branch a fresh integration branch from production `6e36aa7` (e.g. `release/secure-claim-on-6e36aa7`).
2. Replay the 12 RC commits onto it — `git cherry-pick 4faf84d..4bd88d2` (equivalently rebase the RC
   range onto `6e36aa7`). This pulls **only** the claim work, nothing from origin/main.
3. Resolve the 2 additive conflicts (§3), run migrations on a disposable DB, run the full regression
   (§9). The result is the deployable artifact; it is **not** deployed by this step.

## 3. Conflicts with recently deployed Passport / PDF / ownership features
A real in-memory merge simulation (`git merge-tree 6e36aa7 4bd88d2`) reports conflicts in **exactly 2
files**, and both are **purely additive** — no logic clash:

| File | RC adds | Production added | Resolution |
|---|---|---|---|
| `Sca/Collector/.../collector-routes.php` | `EmailVerificationController` import + `email/verify/{token}` (confirm) and `email/verify/request` routes | `CollectionReport`/`CollectionCertificate` imports + `collection/{ref}/report` and `collection/{ref}/certificate` routes | Keep **both** import lines and **both** route blocks (different regions/namespaces) |
| `tests/Feature/Sca/CollectorAuthTest.php` | expects the new email-verify routes | expects the new report/certificate routes | Combine the expected-route assertions (keep both) |

**No conflict with the Passport, certificate-PDF, provenance-report, or ownership-transfer features.**
The claim subsystem (`Sca/Claim`, presale grants, email verification, fulfillment release, sale-link
order email) is disjoint from the document/report/CSV work deployed in `6e36aa7`. The claim path reuses
the existing canonical `ClaimService`/ownership-event machinery it already shared, which is unchanged.

## 4. Public QR scanning alone cannot authorize a claim — CONFIRMED
R0 (`ce74229`) permanently retires public QR-token ownership claiming. Contract (enforced +
regression-tested in `OwnershipR0PublicClaimRetiredTest`): a public-token claim attempt — even on an
item with an eligible Shopify sale link — is **rejected 410**, creates **no claim row and no ownership
event**, and the public claim page is **view-only**. Public `/p/{token}` passport VIEWING is unchanged
and PII-free. All claim routes additionally sit behind the `collector.auth` guard, so an anonymous
scanner is routed through sign-in and still cannot claim. Ownership can be created only via the private,
staff-issued grant path.

## 5. Email must match the trusted Shopify order email — CONFIRMED
`ClaimWorkflow::claimByPresaleGrant` enforces the R0c verified-buyer gate **inside the completion
transaction** (re-validated at consumption). `buyerIsVerified()` returns true **only** when:
1. the sale link carries a **trusted `order_email`** (populated from the authoritative Shopify order,
   never a form) — null/empty → **fail closed**;
2. the signed-in collector is **active with `email_verified_at` NOT NULL** (email proven via the
   single-use challenge) — otherwise → fail closed;
3. the two emails match **normalized** (`strtolower(trim())`).

Possession of the private token is explicitly never sufficient. On any miss the claim is rejected
(`BUYER_VERIFICATION_REQUIRED`, surfaced as a 409 with a non-leaking message) and no ownership is
created. Covered by `VerifiedBuyerClaimTest` and `SaleLinkOrderEmailTest`.

## 6. Staff order-assignment + fulfillment-release remain enforced — CONFIRMED
- **Fulfillment release** is a dedicated staff permission `sca.eyewear.fulfillment.release` (separate
  from intake/return/claim), exposed via a confirm-interstitial GET + POST
  (`admin.sca.eyewear.fulfillment.release`). It records an append-once release and issues the buyer's
  private, time-limited, single-use claim link. `PresaleClaimGrantService` refuses to issue a grant
  unless `fulfillment_released_at` is set, an **eligible** Shopify sale link exists, there is no current
  owner/completed claim, and registry status is non-adverse. The staff id comes from the authenticated
  session, never request input.
- **Trusted order email** is written onto the sale link **only** from the authoritative Shopify
  `getOrder` response during staff order→item assignment (`OrderItemAssignmentService`), never from a
  staff/customer form; a dry-run-default, idempotent backfill command exists for pre-R0c links
  (`sca:shopify:backfill-sale-link-email`, writes only NULL rows).

## 7. Migrations are additive and compatible with existing records — CONFIRMED
Four migrations, all additive, no destructive change to existing tables:

| Migration | Effect | Compatibility with the 205 imported records |
|---|---|---|
| `…10_29_000001_add_fulfillment_release…` | adds 2 **nullable** columns to `sca_eyewear_items` | existing rows get NULL → **not released → not claimable** (safe default) |
| `…10_29_000002_create_sca_presale_claim_grants` | **new** table (FKs restrictOnDelete) | none affected |
| `…10_30_000001_add_order_email…` | adds 1 **nullable** column to `sca_shopify_sale_links` | existing link(s) get NULL → gate **fails closed** until backfilled |
| `…10_30_000002_create_sca_collector_email_verifications` | **new** table (FK cascade) | none affected |

No column drops, no new NOT-NULL on existing tables (the NOT-NULL `expires_at` columns are on the new,
initially-empty tables). The 205 imported items have no sale link and no fulfillment release, so after
migration they remain **non-claimable by default** — exactly the safe outcome. Sequencing:
**migrate-before-code** (additive columns/tables are invisible to the old code).

## 8. Required transactional-email settings
Current production mail config is `MAIL_MAILER=log`, `MAIL_FROM_ADDRESS=no-reply@localhost`,
`MAIL_FROM_NAME=SCA` — **log driver, no real delivery.** The R0c verification challenge
(`CollectorEmailVerification`: single-use token, 60-minute expiry, link origin pinned to
`config('app.url')` for host-header hardening) rides the Laravel mail abstraction, so going live
requires:
1. A working **SMTP transport** — `MAIL_MAILER=smtp` with valid host/port/username/password/encryption
   (per the Postmark-via-SMTP preflight; `symfony/mailer` is installed).
2. A **verified sender** `MAIL_FROM_ADDRESS` on the sending domain (not `localhost`).
3. `APP_URL` pinned to the canonical production origin (`https://verify.secondchanceauthenticators.com`)
   so verification links resolve correctly.

The issuance chain (authenticate → certify → QR) is email-independent; **only customer claiming** is
gated on this. The request path is already enumeration-safe and transport-failure-hardened
(`TransactionalEmailHardeningTest`), so a transport outage fails closed without leaking.

## 9. Integration plan & regression-test checklist
**Integration (all on a disposable branch/DB; no deploy):**
1. Branch `release/secure-claim-on-6e36aa7` from `6e36aa7`.
2. `git cherry-pick 4faf84d..4bd88d2` (the 12 RC commits only; never origin/main).
3. Resolve the 2 additive conflicts per §3 (keep-both).
4. On a disposable DB: run the 4 migrations in date order; confirm they apply cleanly to a copy of
   production schema and that existing rows are untouched/NULL.
5. Dependency check: `composer install` (no new runtime deps beyond `symfony/mailer`, already present).

**Regression checklist (run in the isolated sandbox pattern just validated):**
- Full `tests/Feature/Sca` suite green on the re-integrated branch (the prior green regression was on
  the OLD base `4faf84d`; it must be re-established on `6e36aa7`).
- Claim-specific suites: `OwnershipR0PublicClaimRetiredTest`, `VerifiedBuyerClaimTest`,
  `PresaleClaimGrantTest`, `SaleLinkOrderEmailTest`, `SecureClaimOrderAssignmentIntegrationTest`,
  `ExternalClaimTest`, `ClaimWorkflowTest`, `TransactionalEmailHardeningTest`, `CollectorAuthTest`.
- Regression of the production features the RC must not disturb: `ProvenanceReportTest`,
  `CollectorCertificateAvailabilityTest`, `InventoryImportVariantLinkTest`, transfer suites.
- Negative re-confirm: public-token claim → 410; token-without-verified-email → 409; mismatched email →
  409; unreleased item → no grant; cancelled/refunded sale link at consumption → rejected.
- (The 5 concurrency suites and `AdminLoginLogoTest` behave as documented sandbox artifacts unless the
  worker DB-host/credentials are forwarded; not product issues — see the end-to-end test result doc.)

## 10. Blockers & the exact next step
**Blockers (none are code defects):**
- **B1 — Transactional email (SMTP).** Hard gate: without real delivery the collector cannot verify
  their email, so no claim can complete. Must be configured + a verified sender before activation.
- **B2 — Separate owner deploy authorization** + the migrate-before-code production deploy (a brief,
  additive, owner-scheduled change). Not yet given.
- **B3 — Re-integration required.** The RC is based on `4faf84d`; it must be replayed onto `6e36aa7`
  and re-regressed before it is deployable (§2, §9). Until then there is no artifact that matches
  current production.
- **B4 — order_email backfill** for any pre-R0c sale link (production has 1): run the dry-run first,
  then `--apply`; the 205 imported items have no sale links and are unaffected.

**Exact next implementation step:** create `release/secure-claim-on-6e36aa7` from `6e36aa7`,
`git cherry-pick 4faf84d..4bd88d2`, resolve the two additive conflicts (keep-both), then run the
migrations on a disposable DB and the full regression in the isolated sandbox. This produces the
deployable, current-base artifact **without deploying** — deployment stays gated on B1 (SMTP) and B2
(owner authorization). Do not activate buyer claiming until B1–B4 are cleared.

## Safety posture (this task)
Read-only review only. No production DB write, no deployment/migration/merge, no Shopify API call or
store change, no customer claim, buyer claiming NOT activated. The secure-claim RC remains undeployed.
Production unchanged at `6e36aa7`; all 205 imported inventory records preserved (items 208, auth 4,
cert 4, qr 3, ownership 5, sale links 205 — unchanged).

**STOP — Secure buyer-claiming is implementation-complete and its invariants hold (public-QR claiming
retired/410; verified-email-vs-trusted-Shopify-order-email gate fail-closed; staff fulfillment-release
+ eligible sale line required; 4 additive migrations leave the 205 imports non-claimable by default).
It must be re-integrated onto current production `6e36aa7` (the RC predates it) — a low-risk replay of
12 commits with only 2 additive conflicts, never pulling origin/main — then re-regressed. Deployment
stays BLOCKED on transactional email (SMTP) and separate owner authorization. Next step: cherry-pick
`4faf84d..4bd88d2` onto a branch off `6e36aa7`, resolve the two keep-both conflicts, migrate on a
disposable DB, and run the full regression — without deploying. Nothing was changed; prod `6e36aa7`
intact.**

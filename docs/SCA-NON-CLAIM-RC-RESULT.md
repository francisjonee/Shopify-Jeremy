# SCA — Independent Non-Claim Release Candidate (RESULT + GO/NO-GO)

**An independent, email-free production release candidate is prepared and fully regression-tested:
`release/non-claim-on-6e36aa7` = `e3f73f8b5f027f14fe61b70faa2cba27e1b4510e`, cut directly from production
`6e36aa7` and containing ONLY the approved, email-independent improvements — the public-Passport
accessibility/UX polish, the QR-label identification (brand/model + sequence), the fixed-size QR-label
PDF export, and the staff-dashboard identity/status-safety fixes (plus the pi8 regression-test
correction). It contains NO secure-claim functionality: a full diff audit confirms no buyer-claim routes
or controllers, no email-verification code, no secure-claim migrations, and no schema change at all (the
disposable DB built from this branch has zero secure-claim tables/columns), and nothing outside the `Sca`
packages + tests. In a proven-isolated disposable sandbox the complete suite passed 1,563 tests / 8,072
assertions / 0 failures / 0 errors / 1 skip, and a focused feature group (public Passport, certification,
certificate PDF, QR + labels, My Collection, ownership transfer, staff dashboard) passed 175 / 722 / 0.
Because it carries no migration and no email dependency, it is deployable independently of transactional
email. VERDICT: GO for production deployment — subject only to separate owner deploy authorization.** No
production deployment/migration/DB write, no Shopify call, no customer email/claim/ownership change;
secure claiming not activated; `origin/main` not merged; production unchanged at `6e36aa7`; the 205
imported records untouched. 2026-11-04. **STOP — do not deploy until separately authorized.**

> Written for: the owner (Jeremy) and the external auditor. Prepared, UNDEPLOYED release for a separate
> go-live authorization.

## 1–5. Branch, commits, conflict handling
- **Production baseline (verified):** `6e36aa74a3af4cd17415c4aad996a53a166dd1bf` (live tree + `main`, clean).
- **Release branch:** `release/non-claim-on-6e36aa7` = `e3f73f8b5f027f14fe61b70faa2cba27e1b4510e`, created **directly from `6e36aa7`** and pushed to the implementation origin. 5 commits atop prod:
  1. `6f31b84` — P2 customer-Passport UX, **independently-applicable subset** (see §conflict handling).
  2. `d7629d3` — QR label identity (brand/model + sequence + 100% reminder) — cherry-pick of `17b6b53`.
  3. `cd7edaa` — fixed-size QR label PDF (single + batch) — cherry-pick of `bdea6ac`.
  4. `d757d78` — staff dashboard identity/status safety — cherry-pick of `4a33e93`.
  5. `e3f73f8` — pi8 regression-test correction (sentinel ids, test-only) — cherry-pick of `f4509f7`.
- **Conflict handling (Task 5, no secure-claim imported):** the QR/dashboard/pi8 commits cherry-picked
  **clean** (they touch only `Sca\Registry` + tests, untouched by secure-claim). The P2 commit `e80b386`
  was NOT cherry-picked wholesale because it also edits P1/secure-claim-entangled files (the collector
  `layout`/`account`/`login`/`register` views and the `Claim` package). Instead, only its
  **independently-applicable files** were taken (verified to be touched by no secure-claim/P1 commit, so
  their content = prod + P2 exactly): `passport/layout.blade`, `passport/show.blade`, `collection/index`,
  `collection/show`, `transfer/accept`, `transfer/initiate`, `transfer/unavailable`, and `PassportP2UxTest`.
  The P2 test was trimmed to the included scope (the claim-unavailable and collector-account-flash cases,
  which depend on secure-claim routes/views, were removed with an explanatory note). The entire `Claim`
  package and the P1/secure-claim collector-auth views were **excluded**.

## 6. Diff audit (no claim / no email / no migration / nothing unrelated)
Diff `6e36aa7..e3f73f8b`: **27 files, +1,054 / −38, entirely within `Sca` packages + `tests/`**.
- **No buyer-claim routes or controllers added** — zero `Sca\Claim` files; the only controllers changed are the **staff** `AuthenticationController` / `CertificationController` (view-data only — a read-only `hasImage` flag for the certify/finalize/authenticate confirm screens), not buyer-claim.
- **No email-verification activated** — no `EmailVerificationController`, no `collector.email.verify.*` route, no `CollectorEmailVerification`.
- **No secure-claim migrations** — zero files under `Database/Migrations/`. Confirmed on the built disposable DB: `sca_presale_claim_grants` / `sca_collector_email_verifications` tables = **absent**; `sca_shopify_sale_links.order_email` and `sca_eyewear_items.fulfillment_released_at` columns = **absent**. (The grep hits for "presale" are the pre-existing item `intake_type = 'sce_presale'` enum used in test fixtures, not claim code.)
- **No unrelated / infrastructure changes** — no `composer.json`/`lock`, `config/`, Docker, Caddy, `.env`, or CI changes.
- Note: this release does **not** include the R0 public-QR-claim retirement (that ships with the email-gated secure-claim release). It leaves production's existing claim surface **unchanged** — it neither activates secure claiming nor alters current claim behaviour.

## 7. Regression (proven-isolated disposable environment)
Sandbox: disposable `sca_domain_test` + restricted `sca_test` user, internal-only docker network, worktree
app read-only. **Isolation proven before any migration/test:** internet egress blocked, prod DB →
ERROR 1044, identity `sca_domain_test`; production `vendor/` remained `--no-dev`. (Autoload class count
46,647 vs the consolidated RC's 46,661 — the secure-claim classes are absent, as expected.)
- **Complete suite** `tests/Feature/Sca`: **1,563 tests / 8,072 assertions / 0 failures / 0 errors / 1 skip** (exit 0).
- **Focused feature group:** 175 tests / 722 assertions / 0 fail.

## 8. Feature verification (Task 8/11)
Green in the focused group and the full run: **public Passport** (`PublicPassportTest`, `PublicPassportSafetyTest`), **certification** (`CertificationWorkflowTest`), **certificate PDF** (`CertificatePdfTest`), **QR + labels** (`QrArtifactTest`, `QrLabelIdentityTest`, `QrLabelPdfTest`), **collector / My Collection** (`CollectorCollectionTest`, `CollectorPublicItemTest`), **ownership transfer** (`TransferWorkflowTest`), and the **staff dashboard** (`StaffDashboardIdentityTest`) + **public-Passport a11y** (`PassportP2UxTest`).

## 9. The 205 imported records remain compatible and untouched
This release makes **no migration, no schema change, and no data write** — the 205 catalog-derived
INTAKE records are byte-for-byte unaffected. Functionally the release improves exactly how such
uncertified items present to staff: they now show an explicit "Not authenticated" chip and a neutral
"Catalog-linked" pill (instead of a green ✓ that could read as certified) — correct, safer signalling
for uncertified inventory. No authentication, certification, QR, ownership, or Shopify state changes.

## 10. Deployment & rollback procedures
**This is a code-only, migration-free deploy.**
- **Prerequisite:** separate owner authorization (no transactional email, no DB change, no ACL grant required).
- **Deploy:**
  1. Record the current live SHA `6e36aa7` as the rollback point; a routine DB backup is prudent but no migration runs.
  2. Fast-forward the live working tree to `e3f73f8b` (`git -C /opt/sca-platform merge --ff-only` on `main`, or checkout the release SHA onto the bind-mounted tree). `origin/main` is NOT pulled.
  3. `php artisan view:clear` (opcache `validate_timestamps=On`, so a graceful reload suffices for PHP/Blade changes); **no** `config:clear` needed (no config change); **no** container recreate.
  4. `apachectl -k graceful`.
  5. Smoke: public Passport `/p/{token}` renders with the new a11y; a QR label (HTML + new PDF) prints; the registry listing shows "Not authenticated"/"Catalog-linked"; a certify-confirm screen shows brand/model/serial/photo; My Collection + transfer load.
- **Rollback:** revert the live tree to `6e36aa7` + `php artisan view:clear` + `apachectl -k graceful`. **No DB rollback** (no migration ran).

## GO / NO-GO
**GO for production deployment**, subject only to separate owner deploy authorization. The release is
email-independent, migration-free, schema-neutral, fully regression-tested (full suite + feature group
green), audited free of any claim/email/secure-claim/unrelated content, and leaves the 205 imports and
all provenance/claim state untouched. (The secure buyer-claiming feature is deliberately NOT part of this
release and remains separately blocked on transactional email + its own authorization.)

## Safety posture (this task)
No production deployment or migration; no production DB write; no Shopify API request/change; no inventory
import; no production authentication/certification/QR issuance; no customer claim or ownership change;
secure claiming NOT activated; `origin/main` NOT merged; no shared-infrastructure change. All tests ran in
a disposable environment with no production DB access and no outbound network. Production unchanged at
`6e36aa7`; `vendor/` `--no-dev`; the 205 imported records untouched. Sandbox + worktree removed; the
branch ref remains locally and on origin.

**STOP — Non-claim RC `release/non-claim-on-6e36aa7` = `e3f73f8b` (off prod `6e36aa7`, 5 commits: P2
public-Passport/collection/transfer UX subset + QR identity + QR PDF + staff dashboard + pi8 test).
Audited: no claim routes/controllers, no email verification, NO migrations (0 secure-claim
tables/columns), nothing unrelated; 27 files all Sca+tests. Isolated sandbox: full suite
1,563/8,072/0-fail/0-error/1-skip; feature group 175/722/0; public Passport/cert/PDF/QR/collector/transfer
all green. The 205 imports untouched (no migration/schema/data change; uncertified items now correctly
show "Not authenticated"/"Catalog-linked"). Code-only, migration-free deploy; rollback = revert tree +
view:clear + graceful (no DB rollback). VERDICT: GO, pending separate owner deploy authorization. Not
deployed/merged; prod `6e36aa7` intact.**

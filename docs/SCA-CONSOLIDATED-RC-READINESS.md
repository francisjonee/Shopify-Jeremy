# SCA — Consolidated Release Candidate & Deployment Readiness (GO / NO-GO)

**One consolidated, production-based release candidate is prepared and fully regression-tested:
`release/consolidated-6e36aa7` = `f4509f706ace1a8b088a1aac190fc0bfed6d08a6`, a clean LINEAR descendant of
production `6e36aa7` (16 approved commits, zero merges, nothing unrelated — 71 files, all inside `Sca`
packages + tests). It bundles every previously approved and tested improvement: the secure buyer-claiming
feature (R0/R0b/R0c + email verification + fulfillment release + order-email wiring), the customer-UX
hardening (claim/email-verification flow, public-Passport accessibility/error-page polish), the QR
printing improvements (brand/model/sequence on labels + a fixed-size PDF export), the staff-dashboard
identity/status safety fixes, and the regression-test corrections. In a proven-isolated disposable
sandbox the complete suite passed 1,612 tests / 8,256 assertions / 0 failures / 0 errors / 1 skip, and
the security invariants hold (public QR-only claiming retired, verified-buyer + trusted Shopify
order-email gate, authentication/certification/PDF/QR/My-Collection/transfer all green).**

**GO / NO-GO:** **The full consolidated RC is NO-GO for immediate deployment** — it contains the
secure-claim feature, which remains DEPLOYMENT-BLOCKED on (a) a verified transactional-email transport
(still unconfigured) and (b) separate owner deploy authorization. Secure buyer-claiming is NOT
launch-ready and must not be represented as such. **However, the non-claim improvements (QR printing +
staff dashboard, and most customer-Passport UX) are GO-ready for a separate, email-independent release**
— they carry no migration and no email dependency (see §13). No production deployment, migration, DB
write, Shopify call, or customer email was performed; production is unchanged at `6e36aa7`; the 205
imported records are untouched; secure claiming is not activated. 2026-11-04. **STOP.**

> Written for: the owner (Jeremy) and the external auditor. This is a prepared, UNDEPLOYED release
> candidate for a separately-authorized deployment decision.

## 1–4. Commit history, contents, branch, approved commits
- **Production baseline:** `6e36aa74a3af4cd17415c4aad996a53a166dd1bf` (live working tree + local `main`).
- **Release branch:** `release/consolidated-6e36aa7` → `f4509f706ace1a8b088a1aac190fc0bfed6d08a6` (pushed to the implementation origin). **Merge-base with `6e36aa7` = `6e36aa7`** (linear; 16 commits; **0 merges**). It is byte-identical in tree to the tested tip `f4509f70` (`investigate/pi8-flake`).
- **The 16 approved commits (oldest→newest), by feature:**
  - Secure buyer-claiming (10): `9bba68d` R0 retire public-QR claiming · `4b06689` R0 test · `9707580` R0b private presale grant · `798bd7e` R0c verified-buyer gate · `04afadf` R0c test · `4b13082` R0c order-email propagation + backfill · `cf0e1aa` R0c test · `326db54` order-assignment integration test · `8e23254` wire trusted order email · `c9a2d7d` test env hardening.
  - Claim/email-verification UX (P1): `b758020`.
  - Customer-Passport P2 UX (a11y + error pages): `e80b386`.
  - QR label identity (brand/model + sequence): `17b6b53`.
  - Fixed-size QR label PDF: `bdea6ac`.
  - Staff-dashboard identity/status safety: `4a33e93`.
  - Regression-test fix (pi8 sentinel ids, test-only): `f4509f7`.

## 5–6. Production functionality & security preserved; diff audited for unrelated changes
- **Diff `6e36aa7..f4509f70`:** 71 files, +3,772 / −395, **entirely within `Sca` packages and `tests/`** (Claim 7, Collector 12, Passport 2, Provenance 9, Registry 17, Shopify 6, tests 18). **No** `composer.json`/`composer.lock`, **no** `config/`, **no** Docker/Caddy/`.env`/CI changes — no dependency, infrastructure, or unrelated change. Every file maps to an approved feature above.
- Security requirements preserved and re-verified by the suite (§9–11): the public QR claim path stays retired (410), the verified-buyer/order-email gate is mandatory and fail-closed, ACLs and typed FINALIZE/ISSUE confirmations are intact.

## 7. Database migrations required by the release
Exactly **four additive migrations** (all from the secure-claim commits; the UX/printing/dashboard commits add none):
1. `2026_10_29_000001_add_fulfillment_release_to_sca_eyewear_items` — adds 2 nullable columns.
2. `2026_10_29_000002_create_sca_presale_claim_grants` — new table.
3. `2026_10_30_000001_add_order_email_to_sca_shopify_sale_links` — adds 1 nullable column.
4. `2026_10_30_000002_create_sca_collector_email_verifications` — new table.
All additive and backward-compatible (existing rows get NULL → fail-closed); **migrate-before-code**. Confirmed in prod: these tables/columns are **absent** today (0 secure-claim tables in `sca_krayin`).

## 8. Regression results (proven-isolated disposable environment)
Sandbox: disposable `sca_domain_test` + restricted `sca_test` user, internal-only docker network, worktree
app read-only. **Isolation proven before any migration/test:** internet egress blocked, prod DB →
ERROR 1044, identity `sca_domain_test`; production `vendor/` remained `--no-dev`.
- **Complete suite** `tests/Feature/Sca`: **1,612 tests / 8,256 assertions / 0 failures / 0 errors / 1 skip** (exit 0).
- **Focused invariant group:** 121 tests / 460 assertions / 0 fail.

## 9–11. Invariant verification
- **(9) Public QR-only claiming remains DISABLED** — `OwnershipR0PublicClaimRetiredTest` green: a public-token claim is rejected 410 with no claim row and no ownership event.
- **(10) Trusted Shopify order-email + verified-buyer** — `VerifiedBuyerClaimTest` + `SaleLinkOrderEmailTest` green: a claim completes only when the collector's verified email matches the sale link's trusted (Shopify-sourced) `order_email`; missing/unverified/mismatch fail closed.
- **(11) Core features** — green: `CertificationWorkflowTest` (authenticate→finalize→certify), `CertificatePdfTest` (PDF), `QrArtifactTest` + `QrLabelPdfTest` (QR + fixed-size PDF labels), `CollectorCollectionTest` (My Collection), `TransferWorkflowTest` (ownership transfer).

## 12. Deployment plan (for a FUTURE, separately-authorized deploy of the FULL RC)
**Prerequisites (all must be met first):**
1. **Transactional email** configured + verified (SMTP sender, SPF/DKIM) — see `SCA-TRANSACTIONAL-EMAIL-READINESS-2026-11-03.md`. Until then the verified-buyer gate is unsatisfiable and claiming cannot complete.
2. **Separate owner authorization** for the production deploy.
3. **ACL grant** `sca.eyewear.fulfillment.release` to the issuing staff role (admin already holds it).
4. **`order_email` backfill** for any pre-existing sale link (dry-run then `--apply`); the 205 imports have no sale links.

**Deploy steps (migrate-before-code):**
1. Backup prod DB + record `6e36aa7` as rollback point.
2. Apply the 4 additive migrations (batch 31) from a separate mount against `sca_krayin`.
3. Fast-forward the live working tree to `f4509f70`; `composer install --no-dev` if deps changed (none did); `php artisan config:clear && view:clear`; `apachectl -k graceful` (no container recreate).
4. Set `MAIL_MAILER=smtp` + verified sender in `app/.env`; `config:clear`.
5. Smoke test: issuance chain (authenticate→certify→QR→label/PDF), public Passport, My Collection, transfer; one controlled email-verification + verified-buyer claim on a real order/pair.

**Rollback:** revert the live tree to `6e36aa7` + `view:clear` + `apachectl -k graceful`. The migrations are additive, so **no DB rollback is required** (the new tables/columns are simply unused by the old code). Do not drop the new tables unless the owner directs it.

## 13. Independent release of the non-claim improvements (email-independent) — FEASIBLE
The QR-printing and staff-dashboard improvements — and most of the customer-Passport P2 UX — are
**presentation-only, carry NO migration, and have NO email/claim dependency**, so they can ship WITHOUT
transactional email and WITHOUT the secure-claim migrations:
- **Cleanly independent (touch no migration / Claim / email / fulfillment file):** `17b6b53` (QR label identity), `bdea6ac` (QR label PDF), `4a33e93` (staff dashboard identity/status), `f4509f7` (pi8 test-only).
- **Mostly independent:** `e80b386` (P2 customer UX) — passport/collector a11y + error pages, no migration/email, but it also edits 2 Claim-package views (`show.blade`, `unavailable.blade`) that the secure-claim branch also touched, so splitting P2 cleanly onto `6e36aa7` needs minor conflict resolution on those two views (or shipping only its passport/collector portions).
- **Email-gated (must stay with secure-claim):** the 10 secure-claim commits + `b758020` (claim/email-verification UX) + the 4 migrations.

**Recommended path:** cut a separate `release/non-claim-on-6e36aa7` by cherry-picking `17b6b53`, `bdea6ac`, `4a33e93` (+ `f4509f7`) onto `6e36aa7` (clean), optionally adding `e80b386` with the two-view conflict resolved, then run the full regression and deploy **that** under owner authorization — shipping the ready QR-printing/dashboard/UX value now, with the secure-claim RC held for when email is live. (Building+testing that split branch is the suggested next task if the owner elects the independent-release path.)

## 14. Recorded
- **Consolidated RC:** `release/consolidated-6e36aa7` = `f4509f706ace1a8b088a1aac190fc0bfed6d08a6` (pushed; not deployed, not merged; `origin/main` not touched).
- **Migrations:** the 4 additive secure-claim migrations (batch 31), migrate-before-code.
- **Tests:** full suite 1,612/8,256/0-fail/0-error/1-skip; invariant group 121/460/0.

## GO / NO-GO
| Scope | Verdict |
|---|---|
| **Full consolidated RC (incl. secure-claim)** | **NO-GO now** — blocked on transactional email + separate owner deploy authorization. GO only once both are met and the migrate-before-code steps run. |
| **Non-claim subset (QR printing + staff dashboard + customer UX)** | **GO-ready for a separate, email-independent release** (no migration, no email) — pending a cut/test of `release/non-claim-on-6e36aa7` and owner authorization. |

## Safety posture (this task)
No production deployment or migration; no Shopify API request or store change; no production DB write; no
inventory import, authentication, certification, or QR generation; no customer claim/ownership change; no
live customer email; secure claiming NOT activated; `origin/main` NOT merged; no shared-infrastructure
change. All tests ran in a disposable environment with no production DB access and no outbound network.
Production unchanged at `6e36aa7`; `vendor/` `--no-dev`; 0 secure-claim tables in prod; the 205 imports
untouched. Sandbox + worktree removed.

**STOP — Consolidated RC `release/consolidated-6e36aa7` = `f4509f70` (prod `6e36aa7` + 16 approved linear
commits, 0 merges, 71 files all in Sca+tests, no unrelated changes; 4 additive migrations). Full suite
1,612/8,256/0-fail/0-error/1-skip; invariants green (public-QR retired, verified-buyer/order-email,
auth/cert/PDF/QR/collection/transfer). GO/NO-GO: full RC = NO-GO (secure-claim blocked on transactional
email + owner auth; NOT launch-ready); the non-claim QR-printing/dashboard/UX improvements = GO-ready for
a separate email-independent release (no migration/email). Nothing deployed/merged; prod `6e36aa7`
intact.**

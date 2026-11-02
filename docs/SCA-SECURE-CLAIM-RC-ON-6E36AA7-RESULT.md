# SCA — Secure Claim: Current-Production Release Candidate, Integrated & Regression-Tested (RESULT)

**The secure buyer-claiming release candidate has been re-created on top of current production and fully
regression-tested, without deploying anything. A new branch `release/secure-claim-on-6e36aa7`
(`c9a2d7d7…`) was built from exactly `6e36aa7` by replaying only the secure-claim commits
(`4faf84d..4bd88d2`); the two known additive conflicts were resolved keeping both production and
secure-claim behavior; and a diff review confirms the branch equals "current production + the
secure-claim feature set" with zero unrelated changes. In a disposable, network-isolated sandbox
(proven unable to reach production, Shopify, or the internet before any test ran) the four additive
migrations applied cleanly to a throwaway database and the full application suite passed: 1,574 tests,
8,096 assertions, 0 failures, 0 errors, 1 skip. Public QR-only claiming is retired, buyer-email
matching + staff fulfillment-release + unauthorized-claim rejection all hold, and the existing
inventory/certification/QR-Passport/PDF/ownership-transfer features still pass. Deployment remains
BLOCKED on transactional email and separate owner authorization.** Production was never written to,
migrated, or deployed; the live tree stays at `6e36aa7`; the store was never contacted; all 205
imported records are intact; the disposable environment has been removed. 2026-11-02. **STOP.**

> Written for: the owner (Jeremy) and the external auditor reading from GitHub. The RC is prepared for
> a FUTURE, separately-authorized deployment — it is NOT deployed and buyer claiming is NOT active.

---

## 1. Baseline verified (Task 1)
- Live working tree + local `main` = **`6e36aa7`**, clean; `kr-app`/`kr-mariadb` healthy.
- RC source = **`4bd88d2`**; shared merge-base with production = **`4faf84d`**.
- Governance baseline **`04601ce`** (the release-prep review this task executes).

## 2–3. New branch + cherry-pick (Tasks 2–3)
- Created **`release/secure-claim-on-6e36aa7`** from exactly `6e36aa7` in an **isolated git worktree**
  (the live bind-mounted tree was never checked out onto a different ref).
- `git cherry-pick 4faf84d..4bd88d2` replayed **10 secure-claim commits**
  (`ce74229`→R0 … `7da38b8`→env-hardening). The range's **two merge commits** (`f84dc1c`, `4bd88d2`)
  were correctly skipped — each is a `--no-ff` merge whose tree adds nothing beyond the feature commits
  already replayed.
- Result SHA **`c9a2d7d74efd2b01ee7b6f1ca0a9d99761f2c782`**, tree `dc54c7eb…`; 10 commits atop
  `6e36aa7`; merge-base with `6e36aa7` = `6e36aa7` (linear, current-base).

## 4. Conflicts resolved — both additive, both preserving both sides (Task 4)
| File | Resolution |
|---|---|
| `Sca/Collector/.../collector-routes.php` | Kept **all three** controller imports and **both** route blocks — the R0c email-verify routes AND the production report/certificate routes (different regions; no logic overlap). |
| `tests/Feature/Sca/CollectorAuthTest.php` | The c11 collector/admin-boundary assertion: both sides rewrote the *same* block to assert the *same* invariant (a collector is denied the staff dashboard). Kept the RC's env-hardened form (the one its green regression was validated against); no distinct test was dropped. |

## 5–6. No origin/main, no unrelated changes (Tasks 5–6)
- `origin/main` (`a397a7e`, a divergent integration line) was **not** merged or pulled.
- Equivalence check: the set of files where `git diff 4bd88d2 HEAD` differs from `git diff 4faf84d
  6e36aa7` is **exactly** the two conflict files, and there are **zero files changed over the RC that
  are not part of the production delta**. The branch is precisely "production `6e36aa7` + the
  secure-claim feature set," nothing else.

## 7–8. Isolated sandbox, proven before any migration/test (Tasks 7–8)
Disposable runner built from image `sca-app:krayin-2.2.6` serving **this worktree** read-only, with
throwaway overlay volumes for vendor/storage/bootstrap-cache, a disposable DB `sca_domain_test`, a
restricted user `sca_test`, an **internal-only** docker network (no egress), and fake Shopify
credentials. Proven **before** any migration or test:
- Internet egress blocked (DNS unresolvable; no HTTP).
- Shopify unreachable (`*.myshopify.*` unresolvable).
- Production DB denied — `sca_test` → `sca_krayin` = **ERROR 1044**; the user sees only its own DB.
- Identity = `sca_domain_test` across env, Laravel config, and `SELECT DATABASE()`.

## 9. Migrations — additive, disposable DB only (Task 9)
`migrate:fresh --seed` on the disposable DB applied the full schema including the **four additive
secure-claim migrations**: `2026_10_29_000001` (nullable `fulfillment_released_at`/`_by` on
`sca_eyewear_items`), `2026_10_29_000002` (new `sca_presale_claim_grants`), `2026_10_30_000001`
(nullable `order_email` on `sca_shopify_sale_links`), `2026_10_30_000002` (new
`sca_collector_email_verifications`). Both new tables and all three new columns verified present.
**Production DB confirmed to still have zero secure-claim tables** — migrations never touched it.

## 10–13. Regression results — GREEN (Tasks 10–13)
- **Full application suite:** `tests/Feature/Sca` → **1,574 tests, 8,096 assertions, 0 failures, 0
  errors, 1 skipped** (exit 0).
- **Secure-claim / claim-boundary suites (Tasks 11–12):** 136 tests / 582 assertions / 0 fail —
  `OwnershipR0PublicClaimRetiredTest`, `VerifiedBuyerClaimTest`, `PresaleClaimGrantTest`,
  `SaleLinkOrderEmailTest`, `SecureClaimOrderAssignmentIntegrationTest`, `ClaimWorkflowTest`,
  `ExternalClaimTest`/`ExternalClaimRevokeTest`/`ExternalIntakeResultClaimTest`,
  `ShopifySaleClaimVisibilityTest`, `TransactionalEmailHardeningTest`, `CollectorAuthTest`.
  - **(11) Public QR-only claiming retired** — `OwnershipR0PublicClaimRetiredTest` green: a
    public-token claim is rejected 410 with no claim row and no ownership event.
  - **(12) Buyer-email matching + fulfillment-release + unauthorized rejection** — `VerifiedBuyerClaimTest`,
    `PresaleClaimGrantTest`, `SaleLinkOrderEmailTest`, `CollectorAuthTest` green: a claim completes only
    when the collector's verified email matches the trusted Shopify order email, only after staff
    fulfillment-release, and unauthorized/non-owner/unverified attempts fail closed.
- **(13) Existing features still work** — prod-feature regression: 173 tests / 1,654 assertions / 0
  fail — `ProvenanceReportTest`, `CollectorCertificateAvailabilityTest`, `InventoryImportVariantLinkTest`,
  `PublicPassportTest`/`PublicPassportSafetyTest`, `CertificatePdfTest`/`CertificateSnapshotTest`,
  `QrArtifactTest`/`QrPrintLabelTest`/`QrLabelsBatchTest`/`QrReissueTest`,
  `TransferWorkflowTest`/`TransferStatusClarityTest`, `ItemOwnershipHistoryTest`.

## 14. Triage — zero application defects (Task 14)
The final run had **0 failures / 0 errors**, so there is nothing to triage as a defect. For the
record, an initial run showed ~907 failures; this was a **test-harness setup gap, not a code problem**:
a fresh git worktree has no `.env` file, so Krayin's installer middleware 302-redirected every route to
`/install`. Supplying a `.env` (copied from live but with the **disposable DB** credentials and **fake
Shopify** values; the file is git-ignored so the branch stayed clean) and seeding the DB made the
previously-failing suites pass, and the full suite then went green. Isolation was re-proven after the
`.env` was added. (This also explains, and confirms, the 5 concurrency "failures" seen in the earlier
end-to-end test on the live app: there the spawned worker fell back to the live `.env` host alias
`mariadb`, unreachable on the isolated network; here the worktree `.env` uses `kr-mariadb`, so those
concurrency proofs pass.)

## 15–16. Release candidate recorded (Tasks 15–16)
- **Branch:** `release/secure-claim-on-6e36aa7` — pushed to the implementation origin
  (`github-sca-platform`), tracking `origin/release/secure-claim-on-6e36aa7`. (A branch push only — no
  deploy, no merge, no `origin/main` change.)
- **Release SHA:** `c9a2d7d74efd2b01ee7b6f1ca0a9d99761f2c782` (tree `dc54c7eb…`), 10 commits atop
  `6e36aa7`.
- **Migrations (batch applies on deploy, migrate-before-code):** the four additive migrations listed in
  §9.
- **Deployment prerequisites (unchanged — all must clear first):**
  1. **Transactional email (SMTP)** configured with a verified sender, and `APP_URL` pinned to the
     canonical production origin, so the collector email-verification challenge can be delivered (today
     `MAIL=log` → the verified-buyer gate is unsatisfiable → claiming cannot complete).
  2. **Separate owner authorization** for the production deploy, performed migrate-before-code.
  3. **ACL grant** of `sca.eyewear.fulfillment.release` to the issuing staff role (admin already holds
     it).
  4. **`order_email` backfill** for any pre-existing sale link (production has 1): dry-run then
     `--apply`; the 205 imported items have no sale links and are unaffected.
  5. A real paid order + certified pair to exercise an end-to-end claim.
- **Rollback (future deploy):** revert the live tree to `6e36aa7` + `view:clear` + graceful reload; the
  migrations are additive so no DB rollback is required.

## Safety posture (this task)
No production deployment, migration, or DB write; no Shopify API request or store change; no live
customer claim; buyer claiming NOT activated; `origin/main` NOT merged. The live tree stayed at
`6e36aa7` and clean; the production DB is unchanged (items 208, auth 4, cert 4, qr 3, ownership 5,
variant links 205) and still has **zero** secure-claim tables; production `vendor/` remains `--no-dev`;
all 205 imported inventory records are intact. The disposable test environment (runner, DB, user,
network, volumes) and the temporary worktree were removed; the RC branch ref remains locally and on
origin.

**STOP — A current-production-based secure-claim release candidate is ready for future deployment
approval: `release/secure-claim-on-6e36aa7` = `c9a2d7d7…`, built from `6e36aa7` by replaying
`4faf84d..4bd88d2` (10 commits; 2 additive conflicts resolved keep-both; zero unrelated changes vs the
production delta). In a proven-isolated sandbox the 4 additive migrations applied to a disposable DB
and the full suite passed 1,574/8,096/0-fail/0-error/1-skip; public-QR claiming retired, buyer-email +
fulfillment-release + unauthorized-rejection verified, and all existing inventory/cert/QR/PDF/transfer
features green. Deployment stays BLOCKED on transactional email + separate owner authorization.
Production untouched at `6e36aa7`; store never contacted; 205 imports intact; disposable env removed;
nothing deployed or activated.**

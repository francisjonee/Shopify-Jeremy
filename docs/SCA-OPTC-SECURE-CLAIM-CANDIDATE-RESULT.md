# SCA-OPTC — Secure QR Passport Claiming: Candidate Implementation Result

**Status:** CANDIDATE IMPLEMENTED, PUSHED, AWAITING INDEPENDENT ChatGPT AUDIT.
**NOT merged. NOT deployed. No production migration. No service restart. No integration activation.**
Production `main 6022b75` and database `sca_krayin` were never touched.

- **Impl branch:** `feat/sca-optc-secure-claim` (impl origin `github-sca-platform`), head **`7b41e8d38b7f34b3186925120737b4463a81baeb`**, based on `6022b75`. Pushed.
- **Diff vs baseline:** 22 files, **+978 / −279**. ZERO dependency changes (`composer.json`/`composer.lock` unchanged). One additive, nullable migration.
- **Date:** 2026-10-21.

---

## 1. What was approved (the 8 scope points) and how each was met

1. **Permanently disable public-token ownership claiming (no re-enable flag); public passports stay read-only; historical ownership preserved.**
   `ClaimWorkflow::claim()` is hard-coded fail-closed — no flag, nothing to re-enable. An item owned by someone else → `ALREADY_OWNED` (privacy-safe, no owner identity); any other case → `NOT_ELIGIBLE`. The idempotent `already_yours` short-circuit for the *current* owner is preserved. `preview()` returns `claim_via_link` (never `eligible`). The public passport (`/p/{token}`) and claim page remain read-only; the claim page directs the buyer to their private link. The retired Shopify sale-link path (`openShopifyClaim`/`eligibleSaleLinkId`) is left inert for staff reconciliation only.
2. **Additive fulfillment-release migration (nullable timestamp + staff ref).**
   `2026_10_23_000001_add_fulfillment_release_to_sca_eyewear_items` adds `fulfillment_released_at` (nullable timestamp) and `fulfillment_released_by` (nullable unsigned bigint, SOFT staff ref — no FK, mirroring `issued_by_staff_ref`). No backfill, no CHECK, no index, no provenance/fingerprint change. Filename-dated after 139/140 and the Phase-2 candidate's 141 so it sorts last regardless of the 139/140 incident.
3. **Separate staff fulfillment-release action with authorization, typed confirmation, audit attribution.**
   New `FulfillmentReleaseService` (append-once, idempotent, item-locked, session-derived actor) + `FulfillmentReleaseController` (GET typed-`RELEASE` confirm interstitial + POST) + `FulfillmentReleaseRequest` (server-side typed-confirm) + dedicated ACL node `sca.eyewear.fulfillment.release` + confirm view + routes. Attribution is the session staff id (never request input, never rendered).
4. **Allow private grant issuance for `sce_presale` only after fulfillment release + certification + existing ownership/status checks.**
   `ExternalClaimGrantService::GRANTABLE_INTAKE_TYPES = ['external_intake','sce_presale']`; the intake predicate broadened; a new gate rejects an `sce_presale` item whose `fulfillment_released_at` is null — on top of the unchanged certified / unowned / non-adverse checks.
5. **Preserve external_intake grants and all single-use / revocation / transfer protections.**
   `external_intake` keeps its original rule (no release concept, immediately grantable once certified). `claimByGrant`, single-use atomic consume, revoke, and transfer flows are untouched (verified by the unchanged, still-green grant tests e1–e18, revoke, transfer suites).
6. **Keep `claim_source='external_intake'` for grant redemptions and document its meaning.**
   `ClaimService::openExternalClaim` still writes `claim_source='external_intake'` for every grant redemption regardless of intake type, with a doc comment: it labels the claim PATH ("certification-entitled claim redeemed via a private grant"), not the item's intake category; it is read in exactly one place (`complete()`), satisfies all CHECKs, and keeps the change migration-free.
7. **Update relevant staff views and tests.**
   Staff item-detail (`EyewearItemController::show` + `eyewear/show.blade.php`) generalized to both grantable intake types and now surfaces the release action for unreleased pre-sale items; `ExternalClaimLinkController` rejection copy generalized. Tests updated/added (see §3).
8. **Do NOT auto-release inventory or issue grants during import.**
   No import path calls release or issuance. `FulfillmentReleaseTest::f9` asserts a freshly-created item is unreleased with no grant.

---

## 2. Security invariant (the fix)

Possession of the public `/p/{token}` value — **even** with a certified item, an active QR, an eligible Shopify sale link, and an authenticated collector — can **never** create ownership. Every ownership-creating claim flows through the staff-issued PRIVATE single-use grant, whose opaque token is independent of the public passport token. Proven by `ClaimWorkflowTest::c1` (HTTP 409, zero ownership/claims, sale link untouched) and `ExternalClaimTest::e16` (public token fails closed; ownership then succeeds only via release → grant → `claimByGrant`).

---

## 3. Test evidence (isolated, ephemeral container; production never a target)

**Runner:** `scripts/run-optc-tests.sh` — purpose-built for this candidate (NOT the Phase-2 runner). It runs in an ephemeral `sca-app:krayin-2.2.6` container on `sca_internal`, validates the DB target against a strict allowlist **before** any destructive statement (rejects `sca_krayin` and arbitrary/shared names), provisions the disposable DB fresh, and drops it in an EXIT trap. Dev dependencies (phpunit/pest/mockery — absent from the prod `vendor/`) were installed into the disposable worktree `vendor/` (gitignored); `composer.lock` unchanged.

- **Focused pass — isolated, uniquely-named DB `sca_optc_test_<rand>` (created & dropped this run):**
  `ClaimWorkflowTest`, `FulfillmentReleaseTest`, `ExternalClaimTest`, `ShopifySaleClaimVisibilityTest`, `CollectorAuthContextTest` → **OK, 68 tests, 333 assertions, 0 failures.** Migration `2026_10_23_000001 … DONE`. DB dropped.
- **Full suite — fresh `sca_domain_test` (the only name the suite's 98 inlined guards accept), provisioned & dropped:**
  **13 failures**, all OUTSIDE Option C's blast radius. Verified against a **clean baseline (`6022b75`) run in the identical harness** (12 failures): the sets are identical except **one** test — `CollectorHandleTest::h7`.
  - The 12 shared failures (admin `AuthenticationTest`/`HelpTest` TypeError, `CertificateDocumentClassificationTest::d9`, three real-connection concurrency suites, `TransactionalEmailHardeningTest::h8` canonical-URL, two `AuthenticationHardeningTest` rate-limit) are **pre-existing environment artifacts** of this minimal harness (no `APP_URL`/canonical SCA config, array cache vs real throttle store, admin seed data, real-race timing). None touch claim/fulfillment/grant code. The canonical harness reports 1442/1/0.
  - `CollectorHandleTest::h7` asserts a bare numeric DB id is not a substring of the rendered HTML. It **also fails in isolation on id `1`** (every HTML page contains "1", e.g. viewport scale), and in the full candidate run on id `220` (matching `max-width:220px` in the injected dev-preview CSS). Its pass/fail is pure autoincrement-id luck + the preview-banner CSS; the baseline merely drew a non-colliding id. Option C touches no collector-handle code. **Pre-existing test fragility, not a regression.**

**Migration result:** `2026_10_23_000001_add_fulfillment_release_to_sca_eyewear_items … DONE` on every provisioned DB. **Cleanup:** every disposable DB dropped on exit (focused unique DBs + `sca_domain_test`); `sca_krayin` never used.

---

## 4. Changed files (22; +978 / −279)

Production code: `Sca/Claim/.../ClaimWorkflow.php`, `Sca/Claim/.../views/show.blade.php`, `Sca/Provenance/.../ClaimService.php`, `Sca/Provenance/.../ExternalClaimGrantService.php`, `Sca/Provenance/.../Migrations/2026_10_23_000001_*.php` (new), `Sca/Provenance/.../Exceptions/FulfillmentReleaseRejection.php` (new), `Sca/Provenance/.../Services/FulfillmentReleaseService.php` (new), `Sca/Registry/.../Config/acl.php`, `Sca/Registry/.../ExternalClaimLinkController.php`, `Sca/Registry/.../EyewearItemController.php`, `Sca/Registry/.../FulfillmentReleaseController.php` (new), `Sca/Registry/.../Requests/FulfillmentReleaseRequest.php` (new), `Sca/Registry/.../views/eyewear/fulfillment-release-confirm.blade.php` (new), `Sca/Registry/.../views/eyewear/show.blade.php`, `Sca/Registry/.../Routes/admin-routes.php`.
Tests/tooling: `tests/TestCase.php` (shared `guardDisposableDb()`), `tests/Feature/Sca/{ClaimWorkflowTest,CollectorAuthContextTest,ExternalClaimTest,ShopifySaleClaimVisibilityTest}.php`, `tests/Feature/Sca/FulfillmentReleaseTest.php` (new), `scripts/run-optc-tests.sh` (new).

---

## 5. Notes for the audit / deploy (if later approved)

- App code + the additive migration **deploy together** (the grant gate reads `fulfillment_released_at`; the column must exist first).
- One intentional behaviour change beyond the plan: a non-owner public-token claim on an **owned** item now returns `ALREADY_OWNED` (was collapsed to a generic reject) — consistent with `preview()` and the grant path; privacy-safe; creates nothing.
- The public-QR login-return context (`AuthContextResolver`) no longer shows a claim CTA (it keyed on `eligible`); the private grant link still does. `CollectorAuthContextTest::a5` updated accordingly.
- `tests/TestCase.php::guardDisposableDb()` widens the DB guard for the 5 Option-C test files only (to allow a per-run `sca_*_test` DB) while still failing closed on `sca_krayin`; the other ~93 files keep their inline `sca_domain_test` guard (hence the full suite must run on `sca_domain_test`).

**STOP — awaiting independent ChatGPT audit of `7b41e8d`. Do not merge, deploy, migrate production, restart, or activate any integration.**

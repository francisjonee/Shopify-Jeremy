# SCA Authentication & Certification Safeguards — Implementation Evidence (pre-merge)

**Status:** CANDIDATE pushed — awaiting ChatGPT independent pre-merge audit. NOT merged, NOT deployed. No migration, no schema, no Stripe/mail/Shopify, no collector/public changes, no infra. The pending QR-reason migration 139 is untouched.

| | |
|---|---|
| Governance task | `c0251ccbb0f77098aa9bdb4a55412318c2795d82` (audit P1 irreversible finalize/certify; P2 default-Passed) |
| Exact base (origin/main, reconfirmed) | `0afc68b2d6a18688e367daa66e304c96c147dbf1` |
| Branch | `fix/sca-auth-cert-safeguards` (1 ahead / 0 behind) |
| **Candidate SHA (head)** | **`d21f08703051448ec9a77da741a74ac1daea858b`** |
| Files changed vs base | **12** (501 insertions, 29 deletions) |
| Focused tests | `AuthCertSafeguardsTest` (10) + adjusted `AuthenticationWorkflowTest` + `CertificationWorkflowTest` → all green (47 in the three files) |
| Full `tests/Feature/Sca` | **1397 passed / 1 skipped / 0 failed** (7403 assertions) |
| Production | migration 138 (reason migration 139 still Pending/undeployed), FP `d15a5cbdfb8df52ba65628b276533cfe`, loopback 200 — untouched |

## Files changed (12)
Controllers: `AuthenticationController.php`, `CertificationController.php`. New FormRequests: `FinalizeAuthenticationRequest.php`, `IssueCertificationRequest.php`. Views: `authentication/create.blade.php` (Scope A), new `eyewear/finalize-confirm.blade.php`, new `eyewear/certify-confirm.blade.php`, `eyewear/show.blade.php` (links→confirm GET). Routes: `admin-routes.php` (2 GET confirm routes). Tests: new `AuthCertSafeguardsTest.php`, adjusted `AuthenticationWorkflowTest.php` + `CertificationWorkflowTest.php`.

## Scope A — deliberate authentication result (no default Passed)
`authentication/create.blade.php` — the Result `<select>` now leads with `<option value="" disabled>Select inspection result</option>`, pre-selected only when there is no valid `old('result')` to restore (first load). `old('result')` is preserved after a validation error. No code change to validation: `StoreAuthenticationRequest` already enforces `result ∈ {passed,failed,inconclusive}` (required) and the condition-grade `required_if/prohibited_unless` rules, so a blank result fails server-side with no draft. (tests a1–a3)

## Scope B — server-enforced confirmation interstitials
New dedicated routes + read-only GET confirm actions + typed-word FormRequests; item-view actions now link to the confirm GET rather than POSTing directly.

- **Finalize** — `GET sca/eyewear/{id}/authentications/{authId}/finalize/confirm` (`admin.sca.eyewear.authentication.finalize.confirm`, `AuthenticationController::confirmFinalize`): read-only interstitial showing item ref + the authentication's result/grade + the "becomes immutable" consequence, with Cancel and a typed-**FINALIZE** form. `POST …/finalize` now takes `FinalizeAuthenticationRequest` (`confirm` required, server-checked `Rule::in(['FINALIZE'])`, upper-trimmed in `prepareForValidation`). Existing exact-item/auth binding (real 404, no leak), draft-only service finalize under lock, and idempotency are unchanged. An already-finalized auth has nothing to confirm → bounced to the item.
- **Issue** — `GET sca/eyewear/{id}/certify/confirm?authentication_id=…` (`admin.sca.eyewear.certification.issue.confirm`, `CertificationController::confirmIssue`): read-only interstitial showing item ref + source authentication + the "mints the permanent QR, freezes the certificate" consequence, with Cancel and a typed-**ISSUE** form (carrying `authentication_id`). The confirm GET validates exact-item binding (missing/cross-item → real 404) and eligibility (not finalized+passed, or already-certified → bounced to the item). `POST …/certify` now takes `IssueCertificationRequest` (`confirm` = ISSUE + `authentication_id` required). Service eligibility (same-item + finalized + passed + not-already-certified) and QR/snapshot generation are unchanged.

All confirm GETs perform only SELECTs (read-only). A missing/wrong typed word fails validation and reaches no mutation. Stale/duplicate confirmed submissions create no second provenance event / certification / QR identity (the service remains the authoritative idempotent/eligibility guard). Typed confirmation is enforced **server-side**, not browser JS; no JS-only modals introduced. Actor stays session-derived.

## Tests
New `AuthCertSafeguardsTest` (disposable `sca_domain_test`, hard guard):
- a1 create form has no default result (disabled empty placeholder pre-selected; Passed not pre-selected); a2 blank result records no draft; a3 each deliberately selected result still records.
- b1 finalize confirm GET is read-only (no finalize); b2 confirm GET respects ACL (403) + exact-item/missing (404); b3 finalize requires the typed FINALIZE (missing/wrong → no finalize); b4 confirmed finalize succeeds + already-finalized GET bounced + duplicate confirmed POST no re-finalize.
- c1 issue confirm GET is read-only (no cert/QR); c2 confirm GET respects ACL (403) + cross-item/missing (404) + ineligible-source redirect; c3 issue requires the typed ISSUE (missing/wrong → no cert/QR); c4 confirmed issue succeeds (passed-only) + already-certified GET bounced + duplicate confirmed POST no second cert/QR.

Adjusted callers (new typed-confirm contract, intentional): `AuthenticationWorkflowTest` finalize POSTs now send `confirm=FINALIZE`; `CertificationWorkflowTest` certify POSTs now send `confirm=ISSUE`. These continue to assert the same underlying behaviors (success/redirect, cross-item/missing 404, draft/failed/inconclusive not certified, idempotency). No other test file exercises these HTTP routes.

Commands: focused `php artisan test tests/Feature/Sca/AuthCertSafeguardsTest.php tests/Feature/Sca/AuthenticationWorkflowTest.php tests/Feature/Sca/CertificationWorkflowTest.php` → 47 passed; full `php artisan test tests/Feature/Sca` (DB_DATABASE=sca_domain_test) → 1397 passed / 1 skipped / 0 failed (7403 assertions).

## Security / compatibility review
- No schema/migration: confirmation is a request-validated typed word, not stored state.
- ACL unchanged (`sca.eyewear.authenticate` / `sca.eyewear.certify` on both the confirm GET and the POST). Confirm GETs are read-only and leak nothing on missing/cross-item/ineligible (real 404 or redirect to the item).
- Exact-item/auth binding, service-level locking, draft/issued eligibility and idempotency are all preserved; the new typed word is an additional pre-condition, never a replacement.
- No public-route, collector-UX, Stripe/mail/Shopify, or infrastructure change. Pending QR-reason migration 139 untouched and still undeployed.

## Remaining risks
- Minor: the item view now links (GET) to the confirm page; a staff member with a stale confirm page who submits after the item state changed is handled by the service's existing eligibility/idempotency guards (no second mutation). The audit's P2 #6 (certify error shown on a non-default tab) is now largely moot for the happy path since issuance flows through a dedicated confirm page that shows its own `session('error')`/validation errors; the residual tab-placement nicety was out of this task's explicit scope and left unchanged.

**STOP — awaiting ChatGPT independent pre-merge audit of candidate `d21f087`. Do not merge, deploy, run production migrations, modify production data, conduct a pilot, or start another initiative.**

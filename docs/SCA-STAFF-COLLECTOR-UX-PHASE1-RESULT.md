# SCA Staff & Collector UX Hardening — Phase 1 — Implementation Evidence (pre-merge)

**Status:** CANDIDATE pushed — awaiting ChatGPT independent pre-merge audit. NOT merged, NOT deployed. No migration, schema, provider, ACL, public-route, payment-state, provenance, or infrastructure change. The pending QR-reason migration 139 is untouched.

| | |
|---|---|
| Governance task | `7f0d4806e836a942b4df6be942a42e78d8ed346d` |
| Exact base (origin/main, reconfirmed) | `62c5d8b7370b5c846a4adbc3c530f9800495bab1` |
| Branch | `fix/sca-staff-collector-ux-phase1` (1 ahead / 0 behind) |
| **Candidate SHA (head)** | **`63177b197511c35653f70d1577c7392728652997`** |
| Files changed vs base | **13** (9 app + 4 test) |
| Focused tests | `StaffCollectorUxPhase1Test` (11) + adjusted `CollectorUi3Test` / `EyewearRegistryTest` / `CollectorHandleTest` — all green |
| Full `tests/Feature/Sca` | **1407 passed / 1 skipped / 0 failed** (7459 assertions) |
| Production | migration 138 (QR-reason 139 still pending/undeployed), FP `d15a5cbd…`, loopback 200 — untouched |

## Inspection findings (evidence before edits)
Each fix maps to an audited defect (`docs/SCA-STAFF-COLLECTOR-OPS-AUDIT.md`); exact baseline anchors inspected:
1. `profile.blade.php:117-118` rendered a clickable `/u/{handle}` "Friendly link"; `/u/*` is edge-blocked (`CollectorServiceProvider.php:88-89`). The canonical `/c/{public_ref}` link (`ProfileController.php:75`) is edge-admitted.
2. Collector `SubmissionController::boundItemResult` mapped both `failed` and `inconclusive` to one `not_passed` state (`:111-112`); `submissions/show.blade.php:59-61` showed one copy. (Staff already shows the distinct `ucfirst(latest_auth_result)`.)
3. `InventoryImportController.php:48` interpolated the raw preview code (`no_data_rows`); `AuthenticationController` finalize flashed the raw exception (`'Could not finalize: '.$e->getMessage()`).
4. `StoreEyewearItemRequest.php` `year.max` message said "cannot be in the future" while the rule allows `date('Y')+1`.
5. `StoreEyewearItemRequest.php` brand/model were `nullable`, while the custody path (`AcceptCustodyRequest`) requires them.
6. Staff `grant_issuable` (`Registry SubmissionController.php:177`) omitted two checks the authoritative `ExternalClaimGrantService::issueForItem` makes (`external_intake`, no completed claim).
7. Staff `submissions/show.blade.php:69` ("advance automatically" on verified payment) and collector `submissions/show.blade.php:42` ("Online payment will be available shortly") while Stripe is dormant.

## Changes (13 files)
**App (9):**
- `Sca/Collector/.../views/profile.blade.php` — **#1**: no clickable `/u/{handle}`; handle shown reserved with honest copy; points to the canonical public link.
- `Sca/Collector/.../Http/Controllers/SubmissionController.php` — **#2**: `inconclusive` becomes its own result state (failed stays `not_passed`); no value/semantic change.
- `Sca/Collector/.../views/submissions/show.blade.php` — **#2** distinct inconclusive copy + **#7** honest collector dormant-payment copy (no implied charge).
- `Sca/Registry/.../Http/Controllers/InventoryImportController.php` — **#3a**: preview error mapped to safe copy (no raw code).
- `Sca/Registry/.../Http/Controllers/AuthenticationController.php` — **#3b**: finalize error mapped to safe copy (no raw exception).
- `Sca/Registry/.../Http/Requests/StoreEyewearItemRequest.php` — **#4** honest `year.max` message + **#5** `brand`/`model_name` required (manual-create request only) with messages.
- `Sca/Registry/.../views/eyewear/create.blade.php` — **#5**: Brand/Model marked required (`*` + `required`), old input preserved via `old()`.
- `Sca/Registry/.../Http/Controllers/SubmissionController.php` — **#6**: `grant_issuable` now mirrors the service (adds `external_intake` + no-completed-claim).
- `Sca/Registry/.../views/submissions/show.blade.php` — **#7**: honest staff payment/manual-override copy (not a payment/charge/receipt); verified-payment branch retained but reworded.

**Tests (4):** new `StaffCollectorUxPhase1Test`; adjusted `CollectorUi3Test` (inconclusive + dormant + unpublished-handle copy), `EyewearRegistryTest` (manual create now sends brand/model — i5/i7), `CollectorHandleTest` (h21: `/u` no longer advertised on the profile).

## Security / compatibility
- No provenance/certification/QR/ownership/payment-state/ACL/public-route change; no migration/schema/provider/infra; no Stripe activation.
- **#5 is scoped to the manual-create HTTP request only**: `AcceptCustodyRequest` (already required), the CSV import path (`InventoryImportService`), direct `ItemService::create`, and existing items are unaffected — proven by `p5b` (service create with null brand/model still succeeds).
- **#6** mirrors the authoritative service (defense against a UX dead-end) and never grants; service enforcement, adverse-status and permissions unchanged. Service remains the sole enforcer.
- Escaping, CSRF, old input, HTTP 403/404, server-side validation, item/collector binding and no-public-leak all preserved. No internal error becomes a false success.
- Reviewed interaction with the prior merged QR-reason and Auth/Cert safeguards: finalize now routes through the typed-FINALIZE confirm (safeguards) and the finalize-error mapping (#3b) replaces only the error copy — no behavior change. QR-reason untouched. No regression (full gate green).

## Tests / commands
- Focused: `php artisan test tests/Feature/Sca/StaffCollectorUxPhase1Test.php tests/Feature/Sca/CollectorUi3Test.php tests/Feature/Sca/EyewearRegistryTest.php` → 44 passed; `tests/Feature/Sca/CollectorHandleTest.php` → 49 passed.
- Full: `php artisan test tests/Feature/Sca` (DB_DATABASE=sca_domain_test) → **1407 passed / 1 skipped / 0 failed (7459 assertions)**. The 1 skip is the pre-existing long-standing skip. (A first full run surfaced one real regression — `CollectorHandleTest::h21` still asserted the now-removed `/u` profile link — fixed by updating that assertion to the new contract; the re-run is fully green.)

`StaffCollectorUxPhase1Test` proves, per area, with negative/security cases: #1 no clickable `/u` link + canonical `/c` shown + honest reserved copy; #2 failed vs inconclusive read differently and neither claimable; #3a import preview no raw code + #3b finalize safe error; #4 next-year accepted / two-years rejected with the honest message; #5 brand/model required on manual intake (no item created when missing) + service/external path unaffected; #6 "Make claimable" shown only when the service would accept (not-certified/adverse/completed-claim hidden); #7 honest staff + collector dormant payment copy.

## Deferred / notes
- No item deliberately deferred. The audit's P2 #6 "certify error on a non-default tab" was already mooted by the Auth/Cert safeguards confirm pages and is out of this task's seven-item scope. The staff "advance automatically on a verified payment" branch is retained (reworded) for a future authorized Stripe activation but cannot render while dormant.

**STOP — awaiting ChatGPT independent pre-merge audit of candidate `63177b1`. Do not merge, deploy, run production migrations, modify production data, conduct a pilot, or start another initiative.**

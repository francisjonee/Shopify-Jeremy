# SCA External Paid Authentication Intake — Slice 2 (Staff Worklist + Receive/Custody Bridge) — implementation candidate (NOT merged/deployed)

**Date:** 2026-10-07 · **Status: IMPLEMENTED + TESTED + PUSHED on a candidate branch. NOT merged, NOT deployed. Live tree restored to `main`; production byte-identical (prod NOT migrated — stays 124, relax-migration ABSENT).** For ChatGPT candidate audit. Approved direction: Slice 2 (Slice 1 deploy audit PASS).

## Candidate identity
- **Branch:** `origin/feat/sca-external-paid-auth-slice2`
- **Base SHA (= deployed `main`, merge-base):** `65880542218d6f0cde552aa3e2cb01c788fba068`
- **Head SHA:** `f4c8574e483db2816da75e408fdc649535c67378` (1 commit)
- **Migrations added:** 1 (trigger-only, additive) → prod 124 → **125 at a future deploy** (NOT applied to prod; applied only to `sca_domain_test`).

## Exact custody / binding semantics
`CustodyAcceptanceService::accept(int $submissionId, array $authoritative, ?int $staffRef)` is the **sole authorized first-bind path**. One `DB::transaction`:
1. `AuthenticationSubmission::whereKey($id)->lockForUpdate()->first()` (row lock serializes concurrency); missing → `SubmissionRejection::NOT_FOUND`.
2. **Idempotent reveal:** if `eyewear_item_id` is already set → return `already_accepted` with the existing bound item, **zero mutation** (double-click / retry converge).
3. **Eligibility:** `status === 'awaiting_item'` else `SubmissionRejection::NOT_ELIGIBLE_FOR_CUSTODY`.
4. Create **exactly one** `external_intake` item via the existing `ItemService::create([...])` using **staff-confirmed authoritative** identity (only `ItemService`-supported fields; `intake_type` forced to `external_intake`). The item id comes from `ItemService::create`'s result — **never** from request input.
5. **Bind** that exact new item + transition `awaiting_item → received` via one query-builder `update` (bypasses the model mass-assignment guard; the Slice-2 trigger permits `NULL→value`).
6. Append the custody transition (`awaiting_item → received`, `actor_collector_id = null` for staff action) to the append-only `sca_submission_status_events` ledger.

Any throw rolls back **both** the item creation (nested `ItemService` transaction = savepoint) **and** the binding/transition — so there is never an orphan item, a partial transition, a submission bound to an unrelated item, or two items from a retry. Returns `{status: accepted|already_accepted, submission_id, eyewear_item_id, item_public_ref}`.

## Bridge-lock resolution (final invariant)
Migration `…000003_relax_submission_bridge_for_custody_bind` replaces `trg_sca_auth_submissions_bu` so:
- `collector_account_id`, `public_ref` remain **immutable**;
- `eyewear_item_id`: `NULL → value` **ALLOWED** (the single controlled first-bind); `value → different` and `value → NULL` **FORBIDDEN** (`IF OLD.eyewear_item_id IS NOT NULL AND NOT (NEW <=> OLD) THEN SIGNAL`).
Plus unchanged: `UNIQUE(eyewear_item_id)` (one item ↔ at most one submission); the model still `$guarded`s `eyewear_item_id` (mass-assignment cannot bind); `SubmissionService::create/transition` still never write it. Authority that *only* the custody service binds is an **application/domain** guarantee (ACL-gated staff route + that single service method) — not a fragile session-variable trigger. This is the approved posture: app authorization + DB immutability-after-bind + single binding code path. `down()` restores the Slice-1 full lock.

## ACL / routes / UI added
- **ACL (separate read vs mutate):** `sca.eyewear.submission` (list/detail/confirm — read only) and `sca.eyewear.submission.accept` (custody mutation).
- **Routes** (`admin.sca.submission.*`, prefix `sca/submission`, non-numeric so no `{id}` collision): `GET index` + `GET {id} show` (gate `sca.eyewear.submission`); `GET {id}/accept acceptConfirm` + `POST {id}/accept accept` (gate `sca.eyewear.submission.accept`). Staff-only; **no collector/public route**.
- **Menu:** "SCA Submissions" → `admin.sca.submission.index` (visibility ≠ access).
- **Views** (reuse `x-admin::layouts`): `submissions/index.blade.php` (status filter + table; collector shown only as opaque `COL-…`), `submissions/show.blade.php` (identity, declared-not-authoritative frame info, append-only transition history, bound-item link or custody CTA), `submissions/accept.blade.php` (confirm form prefilled from declared values, editable; staff confirm authoritative identity).
- **Controller** `SubmissionController` + `AcceptCustodyRequest` (brand+model required, `ItemService`-supported fields only; **no item id / public_ref / intake_type / collector accepted from the request**). `staffRef` = `auth()->guard('user')->id()` (attribution only). On accept → redirect to the existing `admin.sca.eyewear.show` (hand off to authenticate/certify/QR); on `already_accepted` → back to submission detail; on rejection → back with a safe message. Missing submission → explicit 404 `Response`.

## Exact changed files (9 new, 4 modified)
New: migration `…000003_relax_submission_bridge_for_custody_bind.php`; `Provenance/src/Services/CustodyAcceptanceService.php`; `Registry/src/Http/Controllers/SubmissionController.php`; `Registry/src/Http/Requests/AcceptCustodyRequest.php`; `Registry/src/Resources/views/submissions/{index,show,accept}.blade.php`; `tests/Feature/Sca/SubmissionStaffWorklistTest.php`.
Modified: `Provenance/src/Exceptions/SubmissionRejection.php` (+`NOT_ELIGIBLE_FOR_CUSTODY`); `Registry/src/Config/acl.php` (+2 keys); `Registry/src/Config/menu.php` (+1 entry); `Registry/src/Routes/admin-routes.php` (+SubmissionController group); `tests/Feature/Sca/SubmissionDomainTest.php` (`s14` updated to the post-Slice-2 bridge invariant).
**Untouched:** authentication/certification/QR/ownership/grant/claim/Shopify/MAIL services + semantics; `ItemService` (called, not modified); `sca_eyewear_items` schema; no second item schema.

## Provenance mutation matrix (custody acceptance)
| Artifact | Created? |
|---|---|
| `sca_eyewear_items` (external_intake) | **1** (the only provenance crossing — expected) |
| `sca_item_current_state` (INTAKE / normal) | **1** (ItemService's normal projection) |
| authentication / certification / QR identifier | **0** |
| ownership event / claim / external-claim grant | **0** |
| Shopify sale link / webhook receipt | **0** |
| service event | **0** |
Proven by `w5` (INTAKE/normal projection, bound to exactly the created item) + `w6` (all downstream counts 0). No existing provenance semantics modified.

## Tests
- **`SubmissionStaffWorklistTest` — 12:** `w1` authorized list/view; `w2` unauthorized (and read-only) cannot list/view/accept (403); `w3` status filter; `w4` only `awaiting_item` acceptable (draft/submitted/received/cancelled rejected, no item created); `w5` accept creates external_intake item + binds exact item + `received` + INTAKE/normal + ledger entry; `w5b` HTTP accept → redirect to item detail; `w6` zero downstream artifacts; `w7` double-accept idempotent (same item, no second item, single `received` ledger event); `w8` arbitrary/injected existing item id ignored — a NEW item is created; `w9` bound item cannot be rebound or removed (45000); `w9b` first-bind NULL→value permitted; `w10` forced failure after item creation → **orphan item rolled back + submission not partially mutated** (Mockery item-service that inserts then throws).
- **`SubmissionDomainTest` — 21** (Slice-1, still green; `s14` updated: NULL→value now permitted at DB while model mass-assignment still cannot bind; collector/public-ref immutability, value→* blocked, UNIQUE, ledger append-only, zero-provenance all unchanged).
- **Full governed gate:** `… -e DB_DATABASE=sca_domain_test … php artisan test tests/Feature/Sca` → **925 passed / 4928 assertions**, exit 0 (913 Slice-1 baseline + 12).

## Production-safety verification (post-restore)
- Live tree restored to `main` @ **`65880542218d6f0cde552aa3e2cb01c788fba068`**; vendor re-pruned `--no-dev`; caches cleared.
- **Candidate code absent on `main`:** `SubmissionController.php` not on disk; acl/menu/SubmissionRejection/routes/SubmissionDomainTest reverted to the Slice-1 state.
- **Prod DB unchanged:** migrations **124**; the relax-migration is **ABSENT** in prod; `sca_authentication_submissions` **0 rows**; provenance counts byte-identical (items 3 / certs 4 / ownership 5 …).
- **Live HTTP invariants:** `/p/{bogus}` 404 · `/collector` 302 · `/admin/sca/submission` 403 (edge staff-IP gate externally) · unsigned webhook 401 · `/storage` 404 · smsrocket 302.
- **Shopify / MAIL untouched** (no change). No production mutation, no deploy.

## Candidate gate
**NOT merged. NOT deployed. No production mutation. No payment/Stripe/Shopify/SMTP/shipping; no collector/public UI; no auth/cert/QR/ownership/grant changes.** Awaiting ChatGPT candidate audit of head `f4c8574e483db2816da75e408fdc649535c67378`.

See `docs/SCA-EXTERNAL-PAID-AUTHENTICATION-INTAKE-DISCOVERY.md`, `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE1-DEPLOY-RESULT.md`.

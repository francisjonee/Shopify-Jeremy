# SCA External Paid Authentication Intake — Slice 3 (Collector Submission UX + Status Tracking, no payment) — implementation candidate (NOT merged/deployed)

**Date:** 2026-10-07 · **Status: IMPLEMENTED + TESTED + PUSHED on a candidate branch. NOT merged, NOT deployed. Live tree restored to `main`; production byte-identical (prod stays 125 — NO new migration this slice).** For ChatGPT candidate audit. Approved direction: Slice 3 (Slice 2 deploy audit PASS).

## Candidate identity
- **Branch:** `origin/feat/sca-external-paid-auth-slice3`
- **Base SHA (= deployed `main`, merge-base):** `c72530e59af0eb20bfc24df0d97e6dc0feadc990`
- **Head SHA:** `b43391a73a9ea302b3e5751c584a0709c1a78d3a` (1 commit)
- **Migrations added:** **0** (no schema change — pure UX + service methods over the existing tables).

## Collector routes / navigation / UI
Behind the existing `collector.auth` guard, under `/collector` (web group = session + CSRF), ref-addressed by the opaque `SUB-…` public_ref (constraint `SUB-[0-9A-Fa-f]{12}`; never a numeric id):
- `GET  collector/submissions` → `submission.index` (own submissions only)
- `GET  collector/submissions/new` → `submission.create`
- `POST collector/submissions` → `submission.store` (throttle:10,1)
- `GET  collector/submissions/{ref}` → `submission.show` (status tracking)
- `GET  collector/submissions/{ref}/edit` → `submission.edit` (draft only)
- `PATCH collector/submissions/{ref}` → `submission.update` (throttle:20,1; draft only)
- `GET  collector/submissions/{ref}/review` → `submission.review`
- `POST collector/submissions/{ref}/submit` → `submission.submit` (throttle:10,1)

**Navigation:** an "Submit eyewear for authentication →" link added to the collector account page. **Views** (`sca-collector::layout`): `submissions/{index,form,review,show,not_found}.blade.php`. The show/review views clearly separate **collector-declared** (not yet authenticated) info from authenticated SCA info, and explain that the Digital Passport is issued only after certification.

## Exact draft / submit / status semantics
- **Create:** `SubmissionService::create(collectorId, declared)` → `draft` (opaque `SUB-…`, `eyewear_item_id` null, zero provenance), then redirect to review.
- **Edit:** `updateDraft(id, collectorId, declared)` — owner-scoped + **draft-only** (else `NOT_EDITABLE`); updates ONLY `declared_brand/model/frame_serial/notes`.
- **Submit:** `submitDraft(id, collectorId)` — owner-scoped + draft-only → `draft → submitted` (append ledger event, actor = collector). After submit the declared info is read-only (edit form redirects away; update is refused).
- **Status machine for this slice:** `draft → submitted` (collector) → `awaiting_item` (staff pilot gate, below). Collectors can never set an arbitrary status; the only collector-driven transition is the single `draft → submitted`.
- **Status tracking:** `show` renders the current status + plain-language help + the append-only progress ledger (own submission only).

## Minimal staff manual-pilot action (honest, no payment)
Because payment is not implemented, reaching `awaiting_item` needs an explicit step. Implemented as the **smallest honest mechanism**: one staff action `POST admin/sca/submission/{id}/advance` → `SubmissionService::staffAdvanceToAwaitingItem` (`submitted → awaiting_item`, actor null), gated by the **existing** `sca.eyewear.submission.accept` ACL (**no new key**), surfaced as a "Mark awaiting item" button on the Slice-2 staff detail only when `status === 'submitted'`. It **stands in for the future payment confirmation (Slice 4) and carries NO payment semantics** — no fake payment success, no payment fields. The state machine was not distorted: `submitted → awaiting_item` is the existing Slice-1 transition. No Slice-2 redesign.

## Photos — DEFERRED (documented decision)
Re-audited per the brief. Pre-custody there is **no `eyewear_item`** to bind media to, and `sca_media_assets` is **item-bound (`eyewear_item_id` NOT NULL)** with polymorphic subjects tied to an item. A submission-scoped private media store would require **new infrastructure** (a nullable/parallel binding or a new table + its own authorized streaming/isolation). Per the brief ("if that requires disproportionate new infrastructure, explicitly defer photos rather than weakening storage security"), **photos are DEFERRED**. Declared text identification is sufficient for pre-intake triage; custody staff capture authoritative media **after** the item exists (existing item media paths). No storage security was weakened.

## IDOR / security controls
- **Collector-only** (`collector.auth`); a staff/admin session does not satisfy the guard.
- **Every** read/write scoped to `Auth::guard('collector')->id()`; ownership enforced inside the service (`forCollectorByRef`, `lockOwned`), not just the controller.
- Another collector's **valid** `SUB-…` → **explicit 404** (`response()->view(..., 404)`, never `abort(404)` which Krayin masks to 200) for read/edit/review, and for mutate/submit — no ownership disclosure, no mutation.
- **No mass assignment of protected fields:** `SubmitFrameRequest` exposes only `brand/model/frame_serial/notes`; the service reads only those — `collector_account_id`/`public_ref`/`eyewear_item_id`/`status`/payment/provenance are never read and cannot be injected (proven by `u5`). The model still `$guarded`s `eyewear_item_id`.
- **CSRF** (web group); **server-side validation** (`SubmitFrameRequest`, brand+model required); **rate limiting** on create/update/submit; opaque refs generated server-side; **no private collector info exposed publicly** (collector routes are authenticated; nothing added to the public passport).

## Provenance mutation matrix (entire collector lifecycle + the pilot gate)
| Artifact | Created by create/edit/submit/advance/track? |
|---|---|
| `sca_eyewear_items` / INTAKE projection | **0** |
| authentication / certification / QR | **0** |
| ownership / claim / external-claim grant | **0** |
| Shopify sale link / service event / status event | **0** |
Only the already-deployed **Slice-2 custody-acceptance** creates the permanent `external_intake` item. Proven by `u13` (full lifecycle incl. the staff advance → provenance fingerprint over 11 tables byte-identical).

## Exact changed files (8 new, 7 modified; 0 migrations)
New: `Sca/Collector/src/Http/Controllers/SubmissionController.php`, `Sca/Collector/src/Http/Requests/SubmitFrameRequest.php`, `Sca/Collector/src/Resources/views/submissions/{index,form,review,show,not_found}.blade.php`, `tests/Feature/Sca/CollectorSubmissionUxTest.php`.
Modified: `Sca/Provenance/src/Services/SubmissionService.php` (collector-scoped + staff-advance methods), `Sca/Provenance/src/Exceptions/SubmissionRejection.php` (+`NOT_EDITABLE`), `Sca/Collector/src/Routes/collector-routes.php` (+submission group), `Sca/Collector/src/Resources/views/account.blade.php` (nav link), `Sca/Registry/src/Http/Controllers/SubmissionController.php` (+`advance` + `SubmissionService` injected), `Sca/Registry/src/Routes/admin-routes.php` (+advance route), `Sca/Registry/src/Resources/views/submissions/show.blade.php` (advance button). **Untouched:** auth/cert/QR/ownership/grant/claim/Shopify/MAIL; no second account/auth system; no new ACL key; no schema.

## Tests
- **`CollectorSubmissionUxTest` — 13:** `u1` authed collector access; `u2` guest + staff-session denied (redirect to collector login); `u3` create draft + system opaque `SUB-` ref; `u4` edit own draft; `u5` protected-field injection refused on create AND update (collector/public_ref/eyewear_item_id/status); `u6` submit via the allowed transition + ledger; `u7` submitted → read-only (edit redirects, update no-ops); `u8` sees only own submissions; `u9` another collector's valid ref → safe 404 for read/edit/review/mutate/submit, target untouched; `u10` status tracking; `u11` collector submission appears in the staff worklist; `u12` staff pilot gate (read-only staff 403, accept-staff advances submitted→awaiting_item); `u13` full lifecycle zero provenance.
- **Full governed gate:** **938 passed / 5008 assertions**, exit 0 (925 Slice-2 baseline + 13). Slice-1/Slice-2 suites remain green.

## Production-safety verification (post-restore)
- Live tree restored to `main` @ **`c72530e59af0eb20bfc24df0d97e6dc0feadc990`**; vendor re-pruned `--no-dev`; caches cleared.
- **Candidate code absent on `main`:** collector `SubmissionController.php` not on disk; `collector.submission.index` route **ABSENT**; collector routes/service/views reverted to the Slice-2 state.
- **Prod DB unchanged:** migrations **125** (no new migration); `sca_authentication_submissions` **0 rows**; provenance counts byte-identical (items 3 / certs 4 / ownership 5 …).
- **Live HTTP invariants:** `/p/{bogus}` 404 · `/collector` 302 · `/collector/submissions` 404 (route absent on main) · `/collector/forgot-password` 200 · unsigned webhook 401 · `/storage` 404 · smsrocket 302.
- **Shopify / MAIL untouched.** No production mutation, no deploy.

## Candidate gate
**NOT merged. NOT deployed. No production mutation. No Stripe/payment, no Shopify, no fake payment, no SMTP/SMS/shipping, no permanent item creation from collector action, no auth/cert/QR/ownership/grant change, no public unauthenticated submission.** Awaiting ChatGPT candidate audit of head `b43391a73a9ea302b3e5751c584a0709c1a78d3a`.

See `docs/SCA-EXTERNAL-PAID-AUTHENTICATION-INTAKE-DISCOVERY.md`, `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE2-DEPLOY-RESULT.md`.

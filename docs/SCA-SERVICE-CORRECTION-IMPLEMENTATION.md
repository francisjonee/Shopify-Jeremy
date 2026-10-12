# SCA Service-History Correction & Annotation — Implementation Evidence (pre-merge)

**Status:** CANDIDATE pushed — awaiting ChatGPT pre-merge audit. NOT merged, NOT deployed.

| | |
|---|---|
| Governance baseline (NEXT_TASK promotion) | `ffe7ce958a939fd96e03050c3d5345cf77ff7d31` |
| Implementation branch | `feat/sca-service-correction` |
| Exact production base SHA | `9bc0907c486688c7acd0d22ad2ee9f5db37d93bb` (migration 136) |
| Candidate SHA (single commit) | `18aba7c8f464e1ac384561648698373444d07c88` |
| Expected migration | 136 → **137** (`2026_10_18_000001_create_sca_service_event_corrections`) |
| Changed files | 13 (6 modified, 7 added) |
| Focused tests | `ServiceCorrectionTest` 30 + `ServiceCorrectionConcurrencyTest` 1 → **31 passed** |
| Full `tests/Feature/Sca` | **1274 passed / 1 skipped / 0 real failures** (the one full-run miss is the documented `CertificateDocumentClassificationTest::d9` low-ID `assertDontSee` substring flake — passes in isolation; the real deploy gate never resets auto-increment) |
| Production provenance FP (unchanged) | `d15a5cbdfb8df52ba65628b276533cfe`, counts `3/3/4/4/5/2/1/1/7` |
| Production service-event / correction counts | service_events `0`, correction table **absent** in prod |

## Core invariant upheld

A recorded `sca_service_events` row is permanent evidence. Correction/annotation/void are **new immutable rows** in a dedicated ledger; the original service event is never UPDATEd or DELETEd, and no ownership / current-state projection / authentication / certification / QR / registry status / claim / transfer / Shopify sale-link / collector-account state is mutated. `ServiceService::record()` and `ProjectionService::rebuild()` are untouched.

## Changed files

**Added (7)**
- `app/packages/Sca/Provenance/src/Database/Migrations/2026_10_18_000001_create_sca_service_event_corrections.php`
- `app/packages/Sca/Provenance/src/Services/ServiceCorrectionService.php` (sole writer + sole canonical reader)
- `app/packages/Sca/Provenance/src/Exceptions/ServiceCorrectionRejection.php`
- `app/packages/Sca/Registry/src/Http/Controllers/ServiceCorrectionController.php`
- `app/packages/Sca/Registry/src/Http/Requests/ServiceCorrectionRequest.php`
- `app/packages/Sca/Registry/src/Resources/views/eyewear/service-correct.blade.php`
- `app/tests/Feature/Sca/ServiceCorrectionTest.php` (+ `ServiceCorrectionConcurrencyTest.php` and `tests/Support/svc_correction_worker.php` for the real two-connection proof)

**Modified (6)**
- `app/packages/Sca/Registry/src/Config/acl.php` — new `sca.eyewear.service.correct` key
- `app/packages/Sca/Registry/src/Routes/admin-routes.php` — confirm GET + throttled apply POST, numeric item+event ids
- `app/packages/Sca/Registry/src/Http/Controllers/EyewearItemController.php` — `show` uses the canonical effective reader
- `app/packages/Sca/Registry/src/Resources/views/eyewear/show.blade.php` — effective values + corrected/void badges + Correct links
- `app/packages/Sca/Collector/src/Services/CollectionService.php` — owner-safe history routed through `collectorHistory`
- `app/packages/Sca/Collector/src/Resources/views/collection/show.blade.php` — "(corrected)" indicator + collector-visible notes

## Schema (migration 136→137)

`sca_service_event_corrections`: `id`; `service_event_id` FK→`sca_service_events` RESTRICT; `eyewear_item_id` FK→`sca_eyewear_items` RESTRICT; `disposition` ∈ {correct, annotate, void}; full corrected snapshot (`corrected_service_type`, `corrected_condition_grade_after`, `corrected_notes`, `corrected_occurred_at`) nullable, used by 'correct'; `annotation` TEXT + `annotation_collector_visible` BOOL default **false** (staff-only by default); `reason` VARCHAR(255) nullable; `actor_staff_ref` nullable soft ref; `created_at`. Indexes `(service_event_id,id)` and `(eyewear_item_id,service_event_id,id)`.

- CHECKs: `disposition IN (...)`; `corrected_service_type IS NULL OR IN (ServiceService::TYPES)`; `corrected_condition_grade_after IS NULL OR IN (GRADES)`.
- Triggers: `trg_sca_service_corr_no_update` / `trg_sca_service_corr_no_delete` (append-only); `trg_sca_service_corr_bi` BEFORE INSERT enforces the target event exists AND `eyewear_item_id` equals the event's item (cross-table identity; no cross-item correction, no rebinding).

## Fold semantics (ONE canonical reader)

`ServiceCorrectionService::effectiveHistory(itemId)` folds each event + its corrections ordered `(created_at, id)`: latest valid `correct` snapshot wins; annotations accumulate; `void` is terminal. Two bounded queries total (events + corrections), grouped in PHP — no N+1. `collectorHistory(itemId)` is a **privacy projection over the same fold** (no duplicate logic): effective non-void rows, collector-visible annotation **text only**, a non-sensitive "corrected" indicator+date; never staff refs, reasons, internal ids, or voided content. Staff `show` and collector My Collection both consume this one reader.

## Concurrency & fail-closed

Each writer runs in one `DB::transaction`: locks `sca_item_current_state` FOR UPDATE → resolves the target event under the lock (exact item binding, else NOT_FOUND) → optimistic token = per-event correction count re-read **under the lock**, must equal `expected_correction_count` (else STALE) → rejects terminal VOIDED → computes effective, rejects NOOP → appends one row. Actor is `auth()->guard('user')->id()`, never client input. Rejections map to generic flashes (no SQL/internal leak). GET confirm interstitial is read-only; POST is throttled (`throttle:30,1`) behind the admin web group (CSRF + staff auth) and the dedicated ACL.

## Mandatory-test → evidence map

| Spec test | Covered by |
|---|---|
| 1 original byte-identical; 13 first correction effective | sc8, sc11, sc20 |
| 2 one immutable correction row | sc8 |
| 3 UPDATE/DELETE on correction row blocked at DB | sc18 |
| 4 cross-item correction insert blocked at DB | sc19 |
| 5 invalid corrected type (validation + DB) | sc5 + sc18b |
| 6 invalid corrected grade (validation + DB) | sc5 + sc18b |
| 7 actor server-derived, spoof ignored | sc17 |
| 8 dedicated ACL; record-only cannot correct | sc1, sc2 |
| 9 GET read-only + CSRF-safe POST mutation | sc29 (+ throttled web-group POST) |
| 10 missing/cross-item target fail closed | sc15, sc16 |
| 11 reason required/bounded | sc4 |
| 12 no-op rejected | sc9 |
| 14 second correction supersedes; chain immutable | sc11, sc18 |
| 15 optimistic STALE (sequential) | sc14 |
| 16 real two-connection proof | **cc_sc1** (overlapping `correct()` via worker; exactly one wins, loser clean STALE, one row) |
| 17 zero provenance mutation + fingerprint | sc28 (+ prod FP `d15a5cbd` unchanged) |
| 18 corrected condition is observation only (no auth/projection change) | sc28 |
| 19 owner sees corrected type/date/condition/notes | sc25 |
| 20 owner view leaks no reason/staff/internal/ids | sc22, sc25 |
| 21 former owner loses access | sc26 |
| 22 public Passport service-free | sc27 |
| 23 staff detail uses effective + authorized Correct link | sc24 |
| 24 staff audit distinguishes original vs corrections (no edit/delete) | confirm interstitial + sc8/sc11/sc21 |
| 4/annotate; 5/void terminal; 6/no post-void | sc12, sc13, sc21, sc23 |
| 25 bounded reads / no N+1 | effectiveHistory = 2 queries (sc11/sc21 exercise) |
| 26/27 existing recording + all suites green | full `tests/Feature/Sca` |
| 28 full suite green | 1274 passed / 1 skipped / 0 real failures |
| 29 13-table FP unchanged; service/correction counts outside FP recorded | prod FP `d15a5cbd`; service_events 0 / correction table absent in prod |

## Production-untouched proof

Live working tree restored to `main@9bc0907` with `composer install --no-dev --optimize-autoloader`. Prod DB `sca_krayin`: last migration `2026_10_17_000001_add_shopify_reconciliation` (136), `sca_service_event_corrections` absent, `sca_service_events` = 0, 13-table provenance fingerprint `d15a5cbdfb8df52ba65628b276533cfe` with counts `3/3/4/4/5/2/1/1/7` — byte-identical to the established baseline. All correction work ran on the disposable `sca_domain_test` DB only.

## Boundaries honored

No Krayin core edits. No Caddy / DNS / Shopify / Stripe / SMTP / OAuth changes. No collector/public mutation route. No `ProjectionService::rebuild()` call from correction. No hard delete / unvoid.

**STOP — awaiting ChatGPT pre-merge audit of candidate `18aba7c`. Do not merge or deploy.**

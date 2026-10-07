# SCA External Paid Authentication Intake — Slice 1 (Submission Domain Foundation) — implementation candidate (NOT merged/deployed)

**Date:** 2026-10-07 · **Status: IMPLEMENTED + TESTED + PUSHED on a candidate branch. NOT merged, NOT deployed. Live tree restored to `main`; production byte-identical (prod NOT migrated — stays 122, new tables ABSENT).** For ChatGPT candidate audit. Approved direction: Slice 1 (gov discovery `99985e01`).

## Candidate identity
- **Branch:** `origin/feat/sca-external-paid-auth-slice1`
- **Base SHA (= deployed `main`, merge-base):** `0815ea0808b6ceac2bb82d88c891fdedc2b97bda`
- **Head SHA:** `2436c23029204369cbc8617b7cf59ee398202f5a` (1 commit)
- **Migrations added:** 2 (additive, new standalone tables only) → would be prod 122 → 124 **at a future deploy** (NOT applied to prod now; applied only to the disposable `sca_domain_test`).

## Scope delivered (and the lines NOT crossed)
The smallest durable **pre-registry** authentication-submission domain: a collector-linked submission + its safe progression toward physical custody, with an append-only audit ledger and a dedicated service boundary. **No** public/collector UI, **no** staff UI, **no** payment/Stripe/Shopify, **no** shipping, **no** result/ownership/grant automation, **no** email, **no** `ItemService::create`, **no** authentication/certification/QR/ownership/claim change. `eyewear_item_id` stays NULL throughout Slice 1.

## Schema

**`sca_authentication_submissions`** (MUTABLE operational, NOT provenance):
- `id`; `public_ref CHAR(20) UNIQUE` (opaque `SUB-…`, `Token::publicRef('SUB')`, immutable); `collector_account_id` FK→`sca_collector_accounts` (immutable, trigger); `status VARCHAR(24) default 'draft'` (CHECK below); `declared_brand`, `declared_model` (collector-declared, non-authoritative), `declared_frame_serial` nullable, `declared_notes` nullable; `eyewear_item_id` **nullable** FK→`sca_eyewear_items`, **UNIQUE** (`uniq_submission_item`), set once NULL→value then immutable (trigger) — **never written in Slice 1**; timestamps.
- CHECK `chk_submission_status` ∈ `draft | submitted | awaiting_item | received | cancelled`.
- `BEFORE UPDATE` trigger `trg_sca_auth_submissions_bu`: rejects any change to `collector_account_id` or `public_ref`; rejects changing `eyewear_item_id` once non-NULL (value→different or value→NULL) — allows the one-time Slice-2 NULL→value bind.

**`sca_submission_status_events`** (APPEND-ONLY audit ledger — operational history, NOT provenance):
- `id`; `submission_id` FK; `from_status` nullable (NULL on create); `to_status` (CHECK same set); `actor_collector_id` nullable soft ref; `created_at` only (no `updated_at`).
- `no_update`/`no_delete` triggers (SIGNAL `45000`), matching the SCA event-table convention. Never folded by `ProjectionService`.

## State machine (Slice-1 minimal, provider/policy-neutral)
`draft → submitted → awaiting_item → received`; `draft|submitted|awaiting_item → cancelled`. `received` and `cancelled` are **terminal** (no outgoing transition in Slice 1). Payment/shipping/return/dispute/result states are deliberately **not** encoded — they arrive with their own justified slices. (I kept exactly the approved foundation set + a single terminal `cancelled`, reachable from each non-terminal state; `received` is terminal because post-custody handling belongs to Slice 2+.)

## Service boundary — `Sca\Provenance\Services\SubmissionService` (the ONLY writer)
- `create(int $collectorId, array $declared)` — asserts the collector exists and is **active**; `Token::publicRef('SUB')`; inserts at `draft` with `eyewear_item_id = null` (forced — never caller-supplied); reads only `brand/model/frame_serial/notes` from `$declared` (injected `public_ref`/`eyewear_item_id` are ignored); appends the initial event (`from = null`); all in one transaction.
- `transition(int $submissionId, string $to, ?int $actorCollectorId)` — loads the row `lockForUpdate`; **idempotent** self-transition no-op (no event); enforces `TRANSITIONS`; rejects invalid/reverse with `SubmissionRejection::INVALID_TRANSITION` (nothing written); updates only `status`; appends an audit event. Never touches `collector_account_id` or `eyewear_item_id`.
- `SubmissionRejection` codes: `COLLECTOR_NOT_FOUND`, `INVALID_TRANSITION`, `NOT_FOUND` (opaque, no PII).
- Controllers/UI never manipulate status directly — that is future-slice surface calling this service.

## Provenance boundary (absolute)
Creating/mutating a submission creates **no** `eyewear_item`, authentication, certification, QR, claim, ownership event, status event, or Shopify record. Enforced by: the service never calling `ItemService::create` or any provenance writer; `eyewear_item_id` forced NULL in Slice 1; and proven by test `s18` (a full-surface fingerprint over 13 provenance/registry/Shopify tables is byte-identical before/after a complete submission lifecycle).

## Exact changed files (6 new)
New migrations `…2026_10_08_000001_create_sca_authentication_submissions.php`, `…000002_create_sca_submission_status_events.php`; `Provenance/src/Models/AuthenticationSubmission.php`; `Provenance/src/Exceptions/SubmissionRejection.php`; `Provenance/src/Services/SubmissionService.php`; `tests/Feature/Sca/SubmissionDomainTest.php`. **No existing file modified.**

## Tests
- **Focused `SubmissionDomainTest` — 19 passed / 44 assertions:** create binds collector + starts at draft (`s1`); system-generated opaque `SUB-` ref, unique (`s2`); injected ref/item ignored (`s3`); invalid/inactive/disabled collector rejected, nothing written (`s4`,`s4b`); allowed forward transitions (`s5`); invalid skip (`s6`) and reverse (`s7`) rejected without status change; terminal `received`/`cancelled` have no outgoing transition (`s8`); cancel reachable from each non-terminal state (`s9`); idempotent self-transition no-op, no duplicate event (`s10`); **collector reassignment blocked at the DB** (`s11`); service transition never changes collector/bridge (`s12`); `eyewear_item_id` stays NULL through all transitions (`s13`); bound item immutable once set + NULL→value allowed (`s14`); one item backs at most one submission (`s15`, UNIQUE); ledger records each change with `from=null` initial (`s16`); ledger append-only (`s17`); **zero provenance mutation across a full lifecycle** (`s18`).
- **Full governed gate:** `… -e DB_DATABASE=sca_domain_test … php artisan test tests/Feature/Sca` → **911 passed / 4852 assertions**, exit 0 (892 baseline + 19).

## Production-safety verification (post-restore)
- Live tree restored: `git checkout main` + `reset --hard origin/main` → app HEAD **`0815ea0808b6ceac2bb82d88c891fdedc2b97bda`**; vendor re-pruned `--no-dev`; `config:clear`+`route:clear`.
- **Candidate code absent on `main`:** `SubmissionService.php` and `SubmissionDomainTest.php` do not exist on disk.
- **Prod DB unchanged:** migrations **122**; both new tables **ABSENT** in prod (`sca_authentication_submissions`, `sca_submission_status_events` applied only to `sca_domain_test`); provenance counts byte-identical — items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3.
- **Live HTTP invariants:** `/p/{bogus}` 404 · `/collector` 302 · `/collector/forgot-password` 200 · `/storage/..` 404 · unsigned `/sca/shopify/webhook` 401 · `smsrocket.io` 302.
- **Shopify / MAIL untouched.** No production mutation, no deploy.

## Candidate gate
**NOT merged. NOT deployed. No production mutation. No payment/Stripe/Shopify/SMTP. `eyewear_item_id` NULL throughout; `ItemService::create` not called.** Awaiting ChatGPT candidate audit of head `2436c23029204369cbc8617b7cf59ee398202f5a`.

See `docs/SCA-EXTERNAL-PAID-AUTHENTICATION-INTAKE-DISCOVERY.md`.

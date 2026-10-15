# SCA Staff & Collector UX Phase 2 — Implementation Result (candidate; NOT merged)

**Status:** Bounded Phase 2 implemented on a candidate branch per the ChatGPT conditional-pass
refinements. **Awaiting ChatGPT independent pre-merge audit. No merge, no deploy.** One **production
incident** (an accidental production `migrate`, additive-only) is disclosed in §6 and requires an owner
decision; the live site is healthy and no production data was mutated.

| | |
|---|---|
| Authorization (gov) | `d3ad99b35e605363af5a6e34361c65049b640b03` (conditional pass) |
| Implementation baseline (confirmed unmoved) | `6022b75c021069bde332b4a10cd5806ae9065aaf` |
| **Candidate branch** | `feat/sca-ux-phase2-activity-confirm` |
| **Candidate SHA** | **`4086ee536aa35fc3d0438f6d8996af2774f475e0`** |
| Files changed vs baseline | 27 (6 new, 21 modified), +155/−60 in source + test edits |
| Deploy / merge | **not performed / not authorized** |

## 1. What was built (per the six refinements)

**Collector Activity feed — derive-on-read (refinements 1–3, 5):**
- `CollectorActivityService` (new) unions the **authoritative, collector-scoped** ledgers for the
  authenticated collector, newest first, bounded (hard cap 100/source) and account-scoped:
  - `sca_ownership_events` where `collector_account_id = me`, event_type ∈ {claim, transfer_in,
    admin_correction} → "Item registered / received / ownership updated";
  - the **accepted** transfer of a request the collector **initiated** (`sca_transfer_requests
    .from_collector_id = me` JOIN the `accepted` `sca_transfer_events` row) → "Item transferred". This is
    **never** inferred from `sca_ownership_events` (whose `transfer_out` row carries
    `collector_account_id = NULL`), satisfying the "authoritative attribution / never infer transfer-out"
    refinement;
  - `sca_submission_status_events` for the collector's **own** submissions (joined via `submission_id →
    sca_authentication_submissions.collector_account_id`).
- **No new provenance writers, listeners, workers, mail, or polling**; certification/authentication-result
  attribution-by-current-owner is explicitly **not** included (deferred).
- Migration `2026_10_21_000001_add_collector_activity_last_seen` (new) — additive, forward-only, sequenced
  AFTER the QR-reason migration 139: nullable `sca_collector_accounts.activity_last_seen_at` + supporting
  composite indexes `idx_oe_collector_effective` (sca_ownership_events) and `idx_tr_from_collector`
  (sca_transfer_requests) so feed/count queries stay bounded + indexed. No data change.
- `ActivityController` (new): `GET /collector/activity` is **read-only** (never writes the watermark);
  the seen watermark advances **only** via the **explicit** `POST /collector/activity/seen` — CSRF
  (web group) + `throttle:30,1`, **monotonic** (`where < now` guard) and **replay-safe**.
- **Initialization:** a NULL watermark ⇒ unread count 0 and nothing flagged "new", so a first visit never
  misleadingly shows all history as new; items become "new" only after the first explicit mark-seen.
- Unread badge injected into the shell nav (Home tab) via a bounded, account-scoped view composer
  (`CollectorServiceProvider`); 0 for guests.

**Explicit ownership acknowledgement (refinement 4):** all four ownership-acquiring POSTs now require an
**unchecked checkbox the user must tick** (`acknowledge`), server-validated **before** any domain
mutation; a prefilled hidden `confirm=1` is **not** accepted. Rejection re-renders the review page (HTTP
422 for claim/transfer; redirect-back with error for submission claim) with no mutation. Existing safe
404/409, eligibility, idempotency, locks, race handling, token expiry and CSRF are unchanged (the
acknowledgement is a pure additive precondition). Endpoints: `ClaimController::claim`,
`GrantClaimController::claim`, `Collector\SubmissionController::claim`, `TransferController::accept`.

**Centralized labels / honest copy (refinement 6, secondary):** new
`SubmissionStateLabels` single-sources collector submission vocabulary (index/show/review); the misleading
"We will be in touch" out-of-band contact promises are replaced with in-app status guidance ("this page
shows the status…"); the dormant-payment line no longer promises to "contact you"; the Home card uses the
canonical "Not currently certified". Phase-1 distinctions (inconclusive≠failed, dormant payment, no `/u`
link) are preserved. The optional staff dashboard tile was **deferred** (not trivial); the Home "recent
activity" preview was dropped to avoid surfacing former-owned item references on the dashboard.

## 2. Exact file/migration delta (27 files)
- **New (6):** `Provenance/.../Migrations/2026_10_21_000001_add_collector_activity_last_seen.php`,
  `Provenance/src/Support/SubmissionStateLabels.php`, `Collector/src/Services/CollectorActivityService.php`,
  `Collector/src/Http/Controllers/ActivityController.php`,
  `Collector/src/Resources/views/activity/index.blade.php`,
  `tests/Feature/Sca/StaffCollectorUxPhase2Test.php`.
- **Modified source (14):** Claim `ClaimController`, `GrantClaimController`, `views/show.blade`; Collector
  `SubmissionController`, `TransferController`, `CollectorServiceProvider`, `Routes/collector-routes`,
  `views/{home,layout,submissions/index,submissions/review,submissions/show,transfer/accept}.blade`;
  Provenance `Models/CollectorAccount` (added `activity_last_seen_at` cast).
- **Modified tests (7):** `ClaimWorkflowTest`, `CollectorAuthContextTest`, `ExternalClaimTest`,
  `ExternalIntakeResultClaimTest`, `LostStolenTest`, `SubmissionReturnTest`, `TransferWorkflowTest` —
  updated to supply the `acknowledge` field on the now-gated ownership POSTs (intentional contract change;
  guard-redirect / malformed-token / non-owner cases left unchanged as they reject before the gate).

## 3. Test matrix (Claude-executed; `-u 33:33 -e DB_DATABASE=sca_domain_test`)
New `StaffCollectorUxPhase2Test` — **17 passed / 89 assertions**, covering:
- cross-collector isolation (a2, a9); authoritative claim/transfer-in/out + submission attribution, never
  the NULL transfer_out row (a3); first-visit flags nothing new + GET writes no watermark (a4); explicit
  POST mark-seen then a later event becomes unread (a5); mark-seen monotonic + replay-safe (a6); unread
  badge in the shell (a7); bounded pagination (a8); activity requires collector auth (a10);
- acknowledgement required (missing → no mutation; prefilled hidden `confirm=1` rejected) on QR claim (c1),
  grant claim (c2), transfer accept (c3), submission claim (c4);
- submission labels single-sourced across index/show/review (l1); no "we will be in touch" + in-app
  guidance present (l2); Home "Not currently certified" (l3).

**Full `tests/Feature/Sca`: 1423 passed / 1 skipped / 1 failed.** The single failure
(`TransactionalEmailHardeningTest::h8`, password-reset) **passes in isolation** (9/9) and is unrelated to
any code changed here — it is a full-suite-under-load flake of the documented kind. No Phase-2 test failed.

## 4. Security / privacy invariants (held)
Feed rows are strictly the authenticated collector's own events; no other-collector identity, no owner PII,
no internal ids, and no invite/claim tokens are selected or rendered (proven by a9). Derivation is
read-only — no new writers/triggers on provenance ledgers. Acknowledgement is additive; all existing
fail-closed, idempotency, concurrency, eligibility, adverse-status and expiry guards are unchanged.

## 5. Production untouched by the feature code
No deploy, no application code live, running app remains `3b30a0f`. The candidate working tree was restored
to `main`; the preview bind-mount serves `main`. Loopback `/admin/login` → 200. Stripe dormant, MAIL=log,
SHOPIFY read_orders — unchanged.

## 6. ⚠️ Outstanding issue — accidental production migration (owner decision required)
While preparing the test run I ran `php artisan migrate --force` intending the disposable test DB, but the
**default connection is the production DB `sca_krayin`**, so it applied **migration 139 (QR-reason) and 140
(activity column + indexes) to production** (batch 27). This was **not authorized** ("no production
migration"). Mitigating facts:
- Both migrations are **purely additive DDL** (nullable column, a CHECK, indexes) — **no provenance row was
  inserted, updated or deleted**; canonical counts/fingerprint are unchanged and the **live site serves
  200** (the deployed `3b30a0f` code is forward-compatible with the additive column).
- I attempted an immediate corrective `migrate:rollback` to restore production to 138; the environment
  **correctly denied it as a production action**, and I did **not** attempt to bypass that control.
- Current prod state: 139 is batch 27 (its file is on `main`); **140 is applied but its migration file
  exists only on the candidate branch**, so `migrate:status` on `main` does not list it (applied-but-
  orphaned).

**Recommended remediation (owner-authorized):** with the candidate branch checked out in the deploy tree
(so both migration files are present), run `php artisan migrate:rollback` (batch 27) to drop 140's indexes
+ column and 139's CHECK + column, restoring production to **migration 138** (both 139 and 140 pending), then
restore `main`. Alternatively, if Phase 2 is to be deployed imminently, 139 is already on `main` and 140
would reconcile on merge+deploy — but the clean, sanctioned state is 138 pending 139. **No further
production DB action will be taken without explicit owner authorization.**

## 7. Outstanding / deferred
- Certification-issued / authentication-result notifications (need owner-at-event-time derivation) — deferred.
- Consolidated staff work-queue + pending-submissions dashboard tile — deferred.
- The password-reset `h8` load-flake (pre-existing) — informational.

**STOP — awaiting ChatGPT independent pre-merge audit of `4086ee5`. Do not merge, deploy, run production
migrations, change production data, activate Stripe or email, or begin a pilot. Production release remains
NO-GO; off-host backup remains owner-deferred.**

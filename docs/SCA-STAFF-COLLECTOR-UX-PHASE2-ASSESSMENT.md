# SCA Staff & Collector UX Hardening — Phase 2 — Architectural Assessment (READ-ONLY)

**Type:** Read-only discovery / architectural assessment. **No code implemented, no branch created, no
deploy, no migration, no data mutation, no mail/Stripe activation.** Prepared for ChatGPT independent
assessment audit before any implementation task is authorized.

**Implementation main baseline (confirmed):** `6022b75c021069bde332b4a10cd5806ae9065aaf`.
**Unmerged / pending state:** the QR-reason migration `2026_10_20_000001_add_reason_to_sca_qr_lifecycle_events`
(migration 139) is merged to `main` but **not yet deployed** (running prod app is `3b30a0f`, migration 138).
No open candidate branches other than the now-CLOSED backup-DR work. Any Phase-2 migration would be the
**next sequential migration after** the pending QR-reason one, and must not be reordered ahead of it.
**Production release remains NO-GO** (off-host backup deferred by owner); this assessment changes nothing there.

**Method:** direct source inspection at `6022b75` plus three parallel read-only sweeps (notifications
inventory, staff-visibility map, collector status-copy audit). All file:line references below were read in
the repo at this SHA.

---

## 1. Focus 1 — In-app collector notifications

### 1.1 What EXISTS
- A read-only collector dashboard at `/collector`: route `collector.home`
  (`app/packages/Sca/Collector/src/Routes/collector-routes.php:49`) → `HomeController::index`
  (`app/packages/Sca/Collector/src/Http/Controllers/HomeController.php:25`) →
  `CollectorDashboardService::forCollector` (`app/packages/Sca/Collector/src/Services/CollectorDashboardService.php:43`)
  → `home.blade.php`. It surfaces **static counts only**: collection stats + up to 4 recent items,
  an authentication-submissions summary (reads the mutable `.status` column, not the ledger), and
  public-profile publication state. No time-ordered activity, no "new/unseen" markers.
- Rich **append-only event ledgers** already exist (all under
  `app/packages/Sca/Provenance/src/Database/Migrations/`), folded into `sca_item_current_state` by
  `ProjectionService` (`app/packages/Sca/Provenance/src/Services/ProjectionService.php`). Those that
  **natively carry a collector reference + a usable timestamp** (candidate notification sources):
  - `sca_ownership_events` — `collector_account_id`, `effective_at` (migration `2026_09_14_120010…:12`;
    writers `ClaimService.php:101`, `TransferService.php:88,96`). Covers **claim granted** and
    **ownership transfer-in/out**.
  - `sca_status_events` — `raised_by_collector_id` (nullable), `effective_at`
    (`2026_09_14_120014…:12`). Covers a collector's own lost/stolen/recovered actions.
  - `sca_submission_status_events` — `actor_collector_id`, resolvable to the owning collector via
    `submission_id → sca_authentication_submissions.collector_account_id`
    (`2026_10_08_000002…:25`; already read by the collector submission page). Covers **submission
    lifecycle** transitions.
  - `sca_transfer_events` — `actor_collector_id` (`2026_09_14_120012…:12`).
- Item/staff-scoped ledgers that do **NOT** natively name a collector (would need a join to the
  owner-at-event-time): `sca_certification_events` (**certification issued**),
  `sca_authentications` (**authentication result**; note there is no `*_events` table — the row itself
  carries `finalized_at`), `sca_qr_lifecycle_events`, `sca_service_events`, `sca_market_reference_events`,
  `sca_item_metadata_events`.

### 1.2 What is MISSING
- **No in-app notification/alert/inbox/activity-feed** data model or UI anywhere in the SCA app. The only
  class named "Notification" is the mail-only password-reset
  (`app/packages/Sca/Provenance/src/Notifications/CollectorResetPassword.php:17`, `via()=['mail']`).
- **No per-collector read/seen marker** (no `read_at`/`seen_at`/`last_seen…` anywhere) — so there is
  currently no way to derive "new since last seen."
- **No domain-event dispatch/listener** on certification-issued / claim-completed / transfer-accepted /
  authentication-finalized (the only dispatched framework event is `PasswordReset`).
- **"badge"/"alert"/"activity" keyword hits are all incidental** (authenticity pills, one passport
  `role="alert"` banner, CSS) — not a notification feature.

**Implication:** notifications must be **built on the existing ledgers** (the task's "do not invent a
parallel notification architecture"). Claims, transfers, and submission-status are already
collector-scoped and are the low-risk starting set; certification/authentication are item-scoped and need
an owner-at-event-time derivation.

---

## 2. Focus 2 — Explicit claim confirmation before ownership acceptance

### 2.1 The ownership-acquiring surfaces (all behind the `collector` guard)
- **QR claim:** `ClaimController::claim` (`app/packages/Sca/Claim/src/Http/Controllers/ClaimController.php:48`)
  → `ClaimWorkflow::claim` (`app/packages/Sca/Claim/src/Services/ClaimWorkflow.php:62`).
- **Grant claim (external intake):** `GrantClaimController::claim` → `ClaimWorkflow::claimByGrant`
  (`ClaimWorkflow.php:187`).
- **Submission-bound claim:** `SubmissionController::claim`
  (`app/packages/Sca/Collector/src/Http/Controllers/SubmissionController.php:189`) → `ClaimWorkflow::claimByGrant`.
- **Transfer accept:** `TransferController::accept`
  (`app/packages/Sca/Collector/src/Http/Controllers/TransferController.php:93`) → `TransferWorkflow::accept`
  (`app/packages/Sca/Collector/src/Services/TransferWorkflow.php:122`).

Each has a **GET review page** (`sca-claim::show` line 9 form; `transfer/accept.blade.php:16` form) then a
**POST that mutates ownership**. The domain logic is already idempotent + concurrency-safe (item lock in
`ClaimService::complete`/`TransferService::accept`, idempotency keys, optimistic version + expiry,
1062-convergence, adverse-status re-checks, privacy-safe opaque results).

### 2.2 The gap: inconsistent confirmation strength
A **confirmation pattern already exists** for *less* consequential actions, but is **not applied to the
ownership-acquiring POSTs**:
- Registry status (lost/stolen/recovered): GET interstitial `ItemStatusController::confirm*`
  (`app/packages/Sca/Collector/src/Http/Controllers/ItemStatusController.php:45-55`) + POST requiring an
  explicit field via `CollectorStatusConfirmRequest`
  (`app/packages/Sca/Collector/src/Http/Requests/CollectorStatusConfirmRequest.php:28` →
  `'confirm' => ['required', Rule::in(['1'])]`); view sets `confirm=1`
  (`collection/status-confirm.blade.php:22`).
- Privacy anonymization: typed `confirm === 'DELETE'` (`PrivacyController.php:41`).

By contrast, **claim / grant-claim / submission-claim / transfer-accept mutate ownership on a single-click
POST with no explicit confirm field** — a bare or replayed POST (valid CSRF) completes ownership
acquisition without an explicit acknowledgement. This is the precise, bounded gap: **not absence of a
review page, but absence of an explicit server-validated confirmation**, inconsistent with the stricter
treatment of lost/stolen reports and anonymization.

---

## 3. Focus 3 — Staff workflow visibility & outstanding actions (secondary)

### 3.1 What EXISTS
- A staff dashboard `admin.sca.dashboard.index` → `DashboardController::index`
  (`app/packages/Sca/Registry/src/Http/Controllers/DashboardController.php:25`) rendering **counts-only
  tiles** (`dashboard/index.blade.php:41-102`): awaiting-authentication (INTAKE), auth-failed,
  authenticated-not-certified, certified-unclaimed, sold-awaiting-claim, adverse, and a "certified but no
  active QR" exception tile. Each tile links to a **filtered list**, not to the action.
- A separate submissions worklist `SubmissionController::index`
  (`app/packages/Sca/Registry/src/Http/Controllers/SubmissionController.php:88`) with a single `status`
  filter (`STATUSES` allowlist `:29`), no search/sort, `orderByDesc(id)` paginate 20.
- A rich eyewear registry index (`EyewearItemController::index:64`) with lifecycle/registry/owned/sale/
  date filters and a sort allowlist.
- Per-item action entry points with GET typed-confirm interstitials already in place: finalize
  (`eyewear/show.blade.php:305`), certify (`:340`), QR reissue (`:367`), claim grant
  (`submissions/show.blade.php:106` → `SubmissionController::issueGrant` → `ExternalClaimGrantService`),
  claim link (`eyewear/show.blade.php:226`).

### 3.2 What is MISSING
- **No consolidated item-level "outstanding actions" work-queue** — only aggregate counts; staff must
  drill into a filtered list and open each item.
- **No queue/count of authentications awaiting FINALIZE** (drafts) — reachable only per item.
- **Pending submissions are not represented on the dashboard** — the worklist is disconnected (no tile, no
  link).
- **No "QR to reissue" pending surface** — reissue is reactive; the "certified, no active QR" tile opens
  the broad all-certified list, not a precise filter (noted in-view at `dashboard/index.blade.php:100`).
- **Label drift:** `submissions/index.blade.php:30,54`, `submissions/show.blade.php:93,96,123,129`,
  dashboard tile strings, and parts of `eyewear/show.blade.php:192,278,300,331` hardcode status copy
  rather than using `ItemStateLabels` (`app/packages/Sca/Provenance/src/Support/ItemStateLabels.php`).

---

## 4. Focus 4 — Collector status consistency & misleading messages (secondary)

### 4.1 Inconsistent wording (same state, different words)
- **Submission status has three independent vocabularies with no shared source:** friendly labels in
  `submissions/index.blade.php:7-13`; a different help-text map in `submissions/show.blade.php:13-19`
  with a **raw `ucfirst` "Current stage"** at `:12,28`; raw humanized in `submissions/review.blade.php:11`;
  and dashboard buckets in `CollectorDashboardService.php:28-32,57-58`. There is **no
  `SubmissionStateLabels` helper** (`ItemStateLabels` covers item/registry/cert/ownership/lifecycle only,
  not submission status).
- **"Not certified" vs "Not currently certified":** `home.blade.php:81` hardcodes "Not certified" while
  the canonical `ItemStateLabels::certificationShort(false)` (`ItemStateLabels.php:102`) and
  `collection/index.blade.php:191` / `public/profile.blade.php:77` say "Not currently certified".
- **Certification-validity phrasing** differs between the public passport (`passport/show.blade.php:101`
  "Valid — current certification" / "Not current", hardcoded) and collector detail
  (`collection/show.blade.php:184` via `ItemStateLabels::certificationShort`).

### 4.2 Misleading copy (promises contact/notification the system does not deliver; `MAIL_MAILER=log`)
- `submissions/show.blade.php:15` — "Your request has been sent. **We will be in touch** about sending in
  your frame."
- `submissions/show.blade.php:62` (not_passed) — "…**We will be in touch** about returning it."
- `submissions/show.blade.php:66` (inconclusive) — "…**We will be in touch** about returning it or any
  next steps." (The inconclusive≠failed body itself was Phase-1 handled; the residual contact promise is
  not.)
- `submissions/show.blade.php:43` (dormant-payment, Phase-1 copy) — "…SCA staff will progress your
  submission and **contact you** with next steps…".
- Password reset copy (`password/forgot.blade.php:6,14`, `ForgotPasswordController.php:65`) says a link was
  sent; the broker runs but mail is log-only, so delivery is dormant (enumeration-safe design is
  intentional — flag as environment-dependent, not a defect).

These "we will be in touch" promises are the strongest argument **coupling the status-copy fix to the
notifications work**: once an in-app notification/update surface exists, the copy can honestly say "we'll
post an update here / check your submission status," instead of promising out-of-band contact that nothing
sends.

### 4.3 Already handled in Phase 1 (NOT re-proposed)
inconclusive≠failed body copy; dormant online-payment copy; collector profile no longer links the
edge-blocked `/u/{handle}`.

---

## 5. Focus 5 — Cross-cutting invariants (privacy / idempotency / concurrency / regression)

- **Privacy:** every collector surface is strictly session-scoped (ids from the guard, never request
  input); opaque refs only; claim/transfer failures return privacy-safe opaque 404/409 without leaking
  owner/sender identity. Any notification feed MUST inherit this: show only the authenticated collector's
  own events; never another collector's identity; never expose internal ids or raw tokens.
- **Idempotency/concurrency (already strong):** `ClaimWorkflow` and `TransferWorkflow` complete ownership
  under the item lock with idempotency keys, optimistic version + expiry, unique-violation (1062)
  convergence, and real-state re-checks that distinguish a domain race from an infrastructure failure.
  **Claim-confirmation changes must not weaken these** — a confirmation field is an additive precondition
  only.
- **Regression protection:** notifications should be **read-only derivation** from existing ledgers (no
  new writers on provenance paths, no triggers on provenance tables), so the provenance fingerprint and
  all existing provenance/claim/transfer tests remain untouched.

---

## 6. Recommended bounded implementation (smallest coherent slice)

> Primary = notifications + claim confirmation. Secondary = submission-label centralization + the
> misleading-copy fix. Staff work-queue = mostly deferred (triage only).

### 6.1 In-app collector notifications — RECOMMENDED: Option A (derive-on-read)

**Option A — derive-on-read from existing ledgers (RECOMMENDED).** A read-only
`CollectorNotificationService` unions the **collector-scoped** ledgers for the authenticated collector and
orders by timestamp:
- `sca_ownership_events` where `collector_account_id = :me` → "You claimed …", "You received … via
  transfer", "You transferred … away".
- `sca_submission_status_events` joined via `submission_id` to the collector's submissions → "Your
  submission SUB-… is now …".
- (optionally) `sca_status_events` where `raised_by_collector_id = :me`.

Unread tracking = **one additive, nullable `notifications_last_seen_at` timestamp on
`sca_collector_accounts`** (the only migration truly required; next sequential after the pending QR-reason
139). "New" = events with timestamp > `notifications_last_seen_at`; opening the notifications page stamps
it to `now()`. A small unread **count** is a single bounded `COUNT(... > last_seen)` query at shell render.
- **Pros:** no new write path, no dual-write/consistency risk, cannot drift from provenance, reuses
  indexed `(…, effective_at, id)` ledgers, no backfill problem (history simply appears, which is
  desirable), no workers/queues/polling.
- **Cons:** certification-issued and authentication-result are **not** collector-scoped; surfacing them as
  notifications needs an owner-at-event-time join (see Deferred).

**Option B — a written `sca_collector_notifications` table** populated by domain services at event time.
- **Pros:** uniform across all four triggers; recipient computed precisely at event time; natural
  read/unread.
- **Cons:** new write path inside provenance-adjacent services → dual-write consistency, idempotency and
  duplicate-delivery handling, a backfill decision, and added risk to the exact paths Phase-1/earlier work
  hardened. Heavier; higher regression surface. **Not recommended for the first slice.**

**Must-have slice (Option A):** claims + transfers + own-submission status, with an unread count in the
collector shell and a `/collector/notifications` list page. No email, no Stripe, no workers, no polling.

**Likely files (new/edited):**
- New: `app/packages/Sca/Collector/src/Services/CollectorNotificationService.php` (read-only union/order);
  `app/packages/Sca/Collector/src/Http/Controllers/NotificationController.php` (index + mark-seen POST);
  `app/packages/Sca/Collector/src/Resources/views/notifications/index.blade.php`.
- Edit: `collector-routes.php` (GET `notifications`, POST `notifications/seen`, throttled);
  `layout.blade.php` (unread badge in the shell nav); one additive migration for
  `notifications_last_seen_at`.

### 6.2 Explicit claim / transfer confirmation — reuse the existing confirm pattern

Apply the **existing** `CollectorStatusConfirmRequest`-style explicit-confirm precondition to the four
ownership-acquiring POSTs (`ClaimController::claim`, `GrantClaimController::claim`,
`SubmissionController::claim`, `TransferController::accept`). The GET review/accept pages already serve as
the interstitial; add a required `confirm` field (checkbox/hidden `=1`, or a typed word for parity with
anonymization) validated server-side, so a bare/replayed POST cannot silently acquire ownership. Preserve
all existing idempotency/concurrency/eligibility logic unchanged (the field is an additive precondition).

### 6.3 Secondary (bounded, do with 6.1/6.2)
- **Centralize submission labels:** new `SubmissionStateLabels` helper (mirroring `ItemStateLabels`), used
  by `submissions/index`, `submissions/show` (replace the raw `ucfirst` at `:12,28`), `submissions/review`,
  and `CollectorDashboardService` — one vocabulary.
- **Fix misleading copy:** replace the `submissions/show.blade.php:15,62,66` "We will be in touch"
  promises with honest, in-app wording ("we'll post updates to your submission here"), consistent with the
  new notifications surface; fix `home.blade.php:81` "Not certified" → "Not currently certified" (or route
  it through `ItemStateLabels::certificationShort`).
- **Staff (triage, mostly DEFERRED):** the only cheap, bounded staff win is adding a **pending-submissions
  count tile + link** on the staff dashboard (connect the disconnected worklist) and an **awaiting-finalize
  (draft authentications) count/filter**. A full consolidated work-queue is **deferred** (larger design).

### 6.4 Migrations
At most **one additive nullable column** (`sca_collector_accounts.notifications_last_seen_at`) for Option
A. No triggers, no provenance-table change. If Option B were ever chosen, it would add a table — not
recommended now.

---

## 7. Security / privacy invariants (must hold)
1. Notifications are strictly the authenticated collector's own events (guard id, never request input); no
   other collector's identity, no internal ids, no raw tokens, no owner PII.
2. Read-only derivation — no new writers/triggers on provenance ledgers; provenance fingerprint unchanged.
3. Claim/transfer confirmation is additive — existing fail-closed, idempotency, concurrency, eligibility,
   and adverse-status guards remain authoritative.
4. No mail/Stripe activation; no background workers; no unbounded polling (counts/list are bounded,
   indexed, on-demand queries).
5. CSRF on every POST (web group); throttling on the mark-seen and any new POSTs.

## 8. Failure & duplicate-delivery handling
- Derive-on-read (Option A) has **no delivery step**, so there is no duplicate-delivery problem; a replayed
  "mark seen" is idempotent (sets a timestamp). A transfer accepted then reversed by admin correction
  shows as successive ownership events (truthful history), not a contradictory duplicate.
- Claim/transfer confirmation inherits the existing convergence: a double submit is idempotent
  (`already_yours` / no-op) and never double-acquires.

## 9. Verification matrix (tests + acceptance criteria)
| Area | Acceptance criterion | Test (new unless noted) |
|---|---|---|
| Notifications feed | Logged-in collector sees only their own claim/transfer-in/out + own-submission events, newest first; another collector's events never appear | `CollectorNotificationsTest` (scoping, ordering, privacy) |
| Unread count | Count reflects events after `notifications_last_seen_at`; opening the list zeroes it; replay-safe | same |
| No leakage | No internal ids, tokens, or other-collector identity in payload/HTML | same (assert absence) |
| Claim confirm | POST claim/grant-claim/submission-claim without the explicit `confirm` field does NOT acquire ownership (no ownership event, safe status); with it, exactly one owner; idempotent on replay | extend `ExternalClaimTest`/`ExternalIntakeResultClaimTest`; new `ClaimConfirmationTest` |
| Transfer accept confirm | Same, for `TransferController::accept`; self/stale/adverse still fail closed | new `TransferAcceptConfirmationTest` |
| Submission labels | index/show/review/dashboard render one vocabulary from `SubmissionStateLabels`; no raw `ucfirst` drift | `SubmissionStateLabelsTest` + view assertions |
| Misleading copy | No "we will be in touch" in submissions/show; cert label consistent ("Not currently certified") | view assertions |
| Staff tile (if included) | Dashboard shows a pending-submissions count linking the worklist; count derives from the allowlist states | extend `StaffDashboardTest` |
| Regression | Full `tests/Feature/Sca` green; provenance fingerprint + existing claim/transfer/provenance tests unchanged | existing suite |

## 10. Must-have vs deferred
- **Must-have (one slice):** 6.1 Option-A notifications (claims + transfers + own-submission), 6.2
  explicit confirmation on the four ownership-acquiring POSTs, 6.3 submission-label centralization +
  misleading-copy fix.
- **Deferred (bounded follow-ups):** certification-issued / authentication-result notifications (need
  owner-at-event-time derivation); a consolidated staff work-queue; QR-reissue pending surface;
  broader staff label-drift cleanup. The pending-submissions dashboard tile is an optional cheap add.

## 11. Risks
- **Scope creep** into a general notification/event-bus — mitigated by Option A (derive-on-read, no new
  writers) and the must-have/deferred split.
- **Owner-at-event-time ambiguity** for certification/authentication notifications — explicitly deferred
  rather than approximated with current-owner (which would misattribute after a transfer).
- **Copy/notification coupling** — the "we'll be in touch" fix should land with (or after) the
  notifications surface so the new copy is truthful.
- **Migration ordering** — the one additive column must sequence after the pending QR-reason 139, not
  before.

---

**STOP — read-only assessment complete; awaiting ChatGPT independent assessment audit. No implementation,
branch, deploy, migration, data mutation, mail/Stripe activation, service restart, DNS change, QR rotation,
ownership transfer, or pilot was performed, and none is authorized by this task. Production release remains
NO-GO; off-host backup remains owner-deferred.**

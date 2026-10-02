# SCA Destructive / high-impact action confirmations — readiness audit (READ-ONLY, DO NOT IMPLEMENT)

**Date:** 2026-10-02 · **Deployed baseline:** main `daf7c65`, migrations **120**.
**Status: AUDIT ONLY — zero changes; no status action executed; no DB/provenance/route/code/schema touched.**
**For ChatGPT review. ACTIVE / NEXT_TASK remain unpromoted. SMTP remains deferred.**

Addresses app-audit P1s [C-F1] (collector Report Lost/Stolen one-click) and [A-F3] (admin terminal variants
without confirmation). Traces the actual route→request/controller→service→event/projection path for every
destructive/high-impact registry-status action and recommends severity-scaled, server-enforced confirmation.

## 1. Traced paths (exact)

**Shared engine.** All status changes are pure appends to `sca_status_events` (immutable via an append-only
DB trigger) + a `ProjectionService::rebuild()` that recomputes `sca_item_current_state.registry_status` (fold
= latest by `effective_at,id`). **Registry status is orthogonal to ownership, certification and QR** —
`StatusService` never rewrites ownership/claim/transfer/auth/cert/service rows. The **PassportResolver does
NOT gate on registry_status** (it only requires an active QR + current issued cert), so an adverse item still
resolves 200 but the `PassportPresenter::registryBanner()` renders a fixed public string.

Public banner mapping (`PassportPresenter.php:123-131`): `lost`→"Reported lost", `stolen`→"Reported stolen",
`disputed`→"Registry status: under review", `retired`→"Retired from the SCA registry", `invalidated`→"Registry
status: invalidated — not verified", `recovered`/`normal`/default→"No adverse reports on the SCA registry".
**Every action below is therefore externally visible on the public passport.**

**Collector** (`collector` guard): `POST collection/{ref}/status/{lost|stolen|recovered}` →
`ItemStatusController::{reportLost|reportStolen|markRecovered}` → `OwnerStatusWorkflow::report()` →
`StatusService::recordCollectorStatus()`. The workflow opens ONE transaction, `lockForUpdate` on the item's
projection row, **authorizes current ownership under the lock** (`current_owner_collector_id === collectorId`
else opaque `NOT_FOUND`), re-reads current status under the lock, is **idempotent** on same-status, and
enforces a transition matrix (lost/stolen only from clear/other-adverse; recovered only from lost/stolen;
never over a staff-owned status). Status is fixed by the controller action (never client input).

**Admin** (`sca.can:sca.eyewear.status`): `StatusController`:
- `resolve` (→`normal`, dispute resolution) → `StaffStatusWorkflow::apply()` — `StaffStatusRequest` (reason
  **optional**). No interstitial.
- `confirmRetire`/`confirmInvalidate` (GET) → `retire`/`invalidate` (→`retired`/`invalidated`) →
  `StaffStatusWorkflow::apply()` — `TerminalStatusRequest` (**required reason + typed RETIRE/INVALIDATE**).
  **Already fully confirmed.**
- `adminRecover`/`adminRetire`/`adminInvalidate` (SCA-ADVERSE-RECOVERY-024 owner-orphaned valve,
  →`recovered`/`retired`/`invalidated`) → `AdverseRecoveryWorkflow::apply()` — `AdverseRecoveryRequest`
  (**required reason**, **no typed word, no GET interstitial**). The valve applies only to an owner-orphaned
  `lost`/`stolen` item (no active owner), re-checked under the lock (an active owner → fail closed).
- Both admin workflows `lockForUpdate` the projection row, re-read status under the lock, enforce an explicit
  transition matrix, and are idempotent.

**No admin setter for `lost`/`stolen` exists** — those are owner-raised (collector) or producer-raised
(`disputed` via commerce reversal); `STAFF_STATUSES=[normal,retired,invalidated]`,
`ADMIN_RECOVERY_STATUSES=[recovered,retired,invalidated]`. The task's "Admin: Lost/Stolen" are **not present by
design** and should stay absent (a finding, not a gap to fill).

## 2. Concurrency / stale-confirmation analysis (the key question)

**No expected-state/version guard is required for any of these actions** — unlike QR reissue. Reasons, from
the traced services:
- Every workflow (`OwnerStatusWorkflow`, `StaffStatusWorkflow`, `AdverseRecoveryWorkflow`) **locks the
  projection row, re-reads the current status under that lock, enforces a transition matrix, and is
  idempotent**. A confirmation page that goes stale between GET and POST therefore cannot cause an
  unauthorized or partial mutation: the POST either (a) no-ops (already in target), or (b) fails closed with a
  real 409 (now-disallowed transition), or (c) still performs the operator's chosen action if it remains valid.
- **The target status is fixed by the route action, never carried from the (stale) page**, so a stale page can
  never redirect the action to a different status. Retire-from-{normal|recovered|disputed} is the same
  intended "retire this item" regardless of which non-terminal state it was in when the page loaded — so a
  stale GET→POST cannot produce a *wrong* action, only a safe 409/no-op.
- This is precisely why QR reissue *did* need its expected-active guard (there the "which active QR" was
  implicit and a double-submit rotated twice, each rotation internally valid) and these do **not**. Per the
  task: do not add a guard merely for consistency — **recommend none here.**

**Collector safety (previous owner, post-transfer):** already safe. `OwnerStatusWorkflow` re-checks
`current_owner_collector_id === collectorId` **under the lock** on every report, so a previous owner POSTing an
old confirmation page after a transfer completes gets the opaque `NOT_FOUND` — never a mutation. Confirmation
pages add a UX step only; they must **re-authorize ownership on both the GET interstitial and the POST** (the
POST already does, via the workflow). No new authorization logic is required.

**Admin safety:** no permission broadening. All confirm GET + POST routes stay behind the existing
`sca.can:sca.eyewear.status` ACL. Confirmation is a UX/interstitial layer, not a new authority.

## 3. Which actions are genuinely destructive / need confirmation, and at what level

Server-enforced confirmation reusing SCA's established **GET interstitial + server-validated `FormRequest`**
pattern (never `confirm()`/JS-only). Two levels, scaled by severity:
- **Level 2 — typed-word interstitial + required reason** (`RETIRE`/`INVALIDATE`): irreversible/terminal +
  publicly "not verified / retired". Reuses `status/confirm.blade.php` + `TerminalStatusRequest`.
- **Level 1 — explicit-confirm interstitial (no typed word) + reason field**: externally visible but
  **reversible** owner/dispute states. A server GET interstitial whose POST requires an explicit `confirm`
  field (so a blind/accidental POST without going through it fails validation) — no typed ceremony.

Typed words recommended: `RETIRE`, `INVALIDATE` only. `LOST`/`STOLEN`/`RECOVER` do **not** warrant a typed
word (reversible, owner stays owner) — a plain confirmation screen suffices, matching "do not require the same
word for everything if severity differs."

## 4. Matrix

| Surface | Action | Current effect (state→event→projection) | Public passport effect | Current confirmation | Recommended confirmation | Reason requirement | Concurrency protection | Expected mutation |
|---|---|---|---|---|---|---|---|---|
| Collector | **Report Lost** | normal/recovered→`lost`; append `sca_status_events`+rebuild; owner/cert/QR unchanged | banner "Reported lost" | **None (one-click)** | **Level 1** explicit-confirm interstitial | **Optional** (service supports it; currently no UI field — [C-F2]) | Already fail-closed (lock+ownership recheck+idempotent+matrix); **no guard** | +1 status_event, registry_status→lost, rebuilt_at; nothing else |
| Collector | **Report Stolen** | normal/recovered→`stolen`; append+rebuild | banner "Reported stolen" | **None (one-click)** | **Level 1** explicit-confirm (firmer copy) | **Optional** | same — no guard | +1 status_event, →stolen |
| Collector | **Report Recovered** | lost/stolen→`recovered`; append+rebuild (restorative — clears the warning) | banner back to "No adverse reports" | **None (one-click)** | **Level 1** explicit-confirm (lightest) | **Optional** | same — no guard | +1 status_event, →recovered |
| Admin | **Lost / Stolen (setter)** | — | — | — | **Not applicable — no such admin action; keep absent by design** | — | — | — |
| Admin | **Resolve (→normal)** | disputed→`normal`; append+rebuild | banner "under review" → "No adverse reports" | **None** (`StaffStatusRequest`, reason optional) | **Level 1** explicit-confirm | **Recommend required** (justify clearing a dispute); currently optional | lock+matrix+idempotent; **no guard** | +1 status_event, →normal |
| Admin | **Retire (standard)** | normal/recovered/disputed→`retired` | banner "Retired from the SCA registry" | **Level 2 ALREADY** (GET interstitial + typed `RETIRE` + required reason) | **No change** | Required (already) | lock+matrix; no guard | +1 status_event, →retired |
| Admin | **Invalidate (standard)** | normal/recovered/disputed→`invalidated` | "invalidated — not verified" | **Level 2 ALREADY** (typed `INVALIDATE` + required reason) | **No change** | Required (already) | lock+matrix; no guard | +1 status_event, →invalidated |
| Admin | **adminRecover (024)** | owner-orphaned lost/stolen→`recovered` | back to "No adverse reports" | Reason required, **no interstitial/typed word** | **Level 1** explicit-confirm (restorative) | Required (already) | lock+owner-orphaned recheck+matrix+idempotent; **no guard** | +1 status_event, →recovered |
| Admin | **adminRetire (024)** | owner-orphaned lost/stolen→`retired` (**terminal/irreversible**) | "Retired from the SCA registry" | Reason required, **no interstitial/typed word** ⚠️ | **Level 2** typed `RETIRE` + interstitial (parity with standard retire) | Required (already) | lock+matrix; **no guard** | +1 status_event, →retired |
| Admin | **adminInvalidate (024)** | owner-orphaned lost/stolen→`invalidated` (**terminal/irreversible**) | "invalidated — not verified" | Reason required, **no interstitial/typed word** ⚠️ | **Level 2** typed `INVALIDATE` + interstitial | Required (already) | lock+matrix; **no guard** | +1 status_event, →invalidated |

Genuinely destructive + currently under-protected: **adminRetire / adminInvalidate** (terminal, irreversible,
public — the real P1). Externally visible but reversible and currently unconfirmed: **collector Lost / Stolen /
Recovered**, **admin Resolve**, **adminRecover**. Already correct: standard Retire / Invalidate.

## 5. Smallest implementation scope (for a future task — not now)

- **Collector (3 actions):** replace the 3 one-click forms in
  `packages/Sca/Collector/src/Resources/views/collection/show.blade.php:150-162` with links to 3 GET confirm
  interstitials. Add 3 GET routes `collection/{ref}/status/{lost|stolen|recovered}/confirm` +
  `ItemStatusController::confirm*` (authorize ownership on the GET, privacy-safe 404 otherwise — reuse the
  workflow's ownership check); one shared collector confirm blade; a `CollectorStatusConfirmRequest`
  (reason optional + a required `confirm` field so the POST can't be hit blind). The existing POST routes +
  `OwnerStatusWorkflow` are reused unchanged. +`OwnerStatusConfirmationTest`.
- **Admin adminRetire / adminInvalidate:** add 2 GET confirm routes
  (`sca/status/{ref}/admin/{retire|invalidate}/confirm`) reusing the existing `status/confirm.blade.php`
  pattern, and require a typed word on the POST — either a new `AdverseTerminalRequest` (reason required +
  `Rule::in([RETIRE|INVALIDATE])`, mirroring `TerminalStatusRequest`) or parametrize the existing confirm
  blade/request. `adminRecover` and `resolve` get Level-1 explicit-confirm interstitials + (for resolve) a
  reason-required request. All stay behind `sca.can:sca.eyewear.status`. +tests.
- **No schema/migration, no service change, no QR/gallery/SMTP/infra, no permission broadening.** Services
  already provide the fail-closed concurrency and the reason columns; this is routes + requests + views +
  tests only. Prefer a shared confirm blade per surface (collector vs admin) only where it does not obscure
  the per-action authorization/semantics — the admin typed-word blade already exists and should be reused.

**Recommendation: GO for a confirmation-UX task** at these severity levels (push-only → review → governed
merge/deploy), prioritizing adminRetire/adminInvalidate (true P1) and the collector trio. **No expected-state
guard anywhere** (services already fail closed). **AUDIT ONLY — no implementation. Awaiting ChatGPT review;
ACTIVE/NEXT_TASK remain unpromoted.**

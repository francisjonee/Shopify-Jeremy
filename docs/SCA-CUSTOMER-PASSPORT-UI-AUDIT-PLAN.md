# SCA — Customer Ownership Passport UI: Audit & Plan (READ-ONLY)

**Read-only audit at repo main `e644c9c` (prod `cb8a8c3`). No code/DB/merge/deploy change.** Finding: the customer-facing Passport, My Collection, and ownership-transfer UI is **already built, deployed, mobile-friendly, and safety-hardened**; most objectives are already met. The one genuine, independently-testable improvement is **transfer status/confirmation clarity** (presentation-only). 2026-10-29. **STOP.**

## [3] What already exists and is functional (deployed on `cb8a8c3`)

### Public QR passport — `/p/{token}` (Sca\Passport) — COMPLETE
`PassportController::show` → `PassportPresenter` DTO → `passport/show.blade.php` (+ `layout`, `not_found`). Already delivers objective [4]:
- Mobile layout (`viewport` + `@media(max-width:480px)` stacking; `max-width:560px`).
- Frame image when present (streamed via the tokened `/p/{token}/image` route; omitted cleanly when absent), brand+model, **authenticity badge** (✓, kept secondary beneath an adverse warning), certification validity/number/date, authentication date, QR status, registry status.
- **Adverse registry status is the dominant signal** (color-coded warning first); invalidated → historical-record notice; recovered → clear.
- Safe by construction [7][8]: allowlisted DTO only — **no raw model, no resolving/claim token, no owner/contact PII, no `/storage` path, no internal id**; logo inline `data:`; CSP via `PublicPassportHeaders`. Trust copy states plainly that **authentication/certification does NOT establish ownership or possession** (QR ≠ ownership).

### Collector app (Sca\Collector) — COMPLETE (Collector UI 2.0 S1–3)
- **Registration / login / password reset / account / profile / home / public profile** — all present and functional.
- **My Collection** (`collection/index`) — objective [5] met: per-pair cards with image (owner-authorized ordinal route), brand/model, **cert + registry status badges**, header stats (Registered count, Brands), search + brand + status filters + sort, collection groups, empty state; mobile-styled.
- **Eyewear detail** (`collection/show`) — asset-first gallery, authenticity badge, certification/registry/ownership timeline, Market Reference, adverse-status banner ("you remain the registered owner … cannot transfer until recovered"), status flash. Owner-safe DTOs only (no frame_serial/tokens/staff refs/paths).
- **Ownership transfer** (`TransferController` + `transfer/initiate|accept|unavailable`) — objective [6] partially met: owner generates a **single-use, expiring invite link** (copyable; re-shown on return via `pendingInviteToken`), Cancel action, recipient **accept** page with a self-transfer guard, and an `unavailable` page. Privacy-safe: recipient is never looked up by email/PII; no recipient identity exposed.

## [7][8] Safety already enforced
Public pages expose no owner PII, no private claim/QR tokens, and no internal records; QR possession is never presented as proof of ownership (explicit passport trust copy + the R0 retirement of public-token claiming). Nothing in this plan changes that.

## What needs improvement (genuine gaps)
The system is mature; the only material UX gap is in **transfer status/confirmation clarity** (objective [6], "clear confirmation and status messages"):
1. **No "transfer pending" indicator on the item detail page.** `collection/show` always shows a plain "Transfer ownership →" link; it does not reflect that a single-use transfer link is already active (the data exists — `TransferWorkflow::pendingInviteToken`). An owner who initiated a transfer sees no in-context signal on the item.
2. **No confirmation/status flash after transfer actions.** `TransferController::initiate/cancel/accept` set no `status` flash, so generating, cancelling, or accepting a transfer re-renders with no explicit "done" message (the detail page can render `session('status')`, but none is set).

(Minor/none elsewhere: the passport and collection screens need no functional change; any further work would be cosmetic.)

## [9] Reuse
All of the above reuses existing controllers/workflows unchanged — `TransferWorkflow` (`initiate`/`cancel`/`accept`/`pendingInviteToken`), `CollectionController`, the collector `layout`, and the existing flash-message slot already rendered in `collection/show`. No new service, route, or migration is required for the recommended slice.

## [10] Smallest safe implementation slice (recommended)
**"Transfer status clarity" — presentation + flash only, no schema, no workflow/mutation change, independently testable:**
1. In `collection/show`, when `TransferWorkflow::pendingInviteToken(owner, ref)` is non-null, render a **"Transfer pending — a single-use link is active"** banner (with a "Manage / cancel transfer" link) in place of the plain transfer link; otherwise show the normal entry. (Controller passes a `transferPending` boolean DTO flag — reuses the existing service; no token rendered on the item page.)
2. Add clear status flashes from `TransferController`: initiate → "Transfer link generated — share it with the recipient"; cancel → "Transfer cancelled — you remain the registered owner"; accept → "Ownership transferred to you." (Rendered by the existing `session('status')` slot.)

This is a self-contained slice (≈2 view edits + a controller DTO flag + 3 flash strings), reuses deployed workflows, creates/changes no ownership, touches no claim path, and is covered by focused feature tests (banner shows iff a transfer is pending; flashes appear after initiate/cancel/accept). It does NOT activate claims (independent of the deferred email/R0c work).

## Safety / scope
Read-only audit; no production/code/DB/merge/deploy change; no live claim or transfer; no email-provider config; no Option C. The recommended slice, when separately authorized, is dev-branch + disposable-DB-tested per standard process.

**STOP — audit delivered. The customer Passport/My-Collection/transfer UX already exists and is deployed; the smallest safe next UI task is the presentation-only "transfer status clarity" slice above. Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification.**

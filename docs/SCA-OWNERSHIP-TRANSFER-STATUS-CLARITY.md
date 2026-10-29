# SCA — Ownership Transfer Status Clarity (Implementation)

**Authorized presentation-only development task.** Implements the "transfer status clarity" slice
recommended by `docs/SCA-CUSTOMER-PASSPORT-UI-AUDIT-PLAN.md`: surface a pending single-use transfer
invitation on the item-detail page and add clear confirmation messages after generate / cancel /
accept — **without changing any transfer service, ownership logic, or customer claiming.** Dev branch
only. NO production merge/deploy, NO migration/schema change, NO live transfer, NO Shopify/email/
Option-C change. Static checks PASS (`php -l` clean on all touched/new files; Blade directives
balanced). DB-backed feature tests are **written but NOT run** (no DB-changing tests authorized in
this task — defer to a separately-authorized disposable-DB session). 2026-10-29. **STOP for review.**

## SHA & branch
- Branch `feat/sca-transfer-status-clarity` off repo main **`e644c9c`** → head
  **`a44103ab0009bfedeef7830f3abedaf2270d6485`** (pushed to `origin` = impl repo
  `francisjonee-sca-platform-private`). Live checkout `/opt/sca-platform` untouched (still prod
  `cb8a8c3`, `main`, clean — bind-mount safe). Isolated worktree used + removed.
- **6 files** (5 modified, 1 new test). **No migration. No schema change. No service change.**

## What changed (presentation + controller display data + status messages only)

### 1. Item-detail "Transfer pending" banner
- **`CollectionController::show`** now injects `TransferWorkflow` and passes a presentation-only
  boolean `transferPending`. The value is derived by calling the EXISTING
  `TransferWorkflow::pendingInviteToken($collectorId, $ref)` and reducing it to `!== null` **in the
  controller** — mirroring the existing `passportEligible` pattern. **The invite token is fetched
  server-side and discarded; it is NEVER passed into the view.** (Objective 6.)
- **`collection/show.blade.php`** (inside the existing `@unless ($adverse)` Transfer block): when
  `transferPending` is true, render a **"⏳ Transfer pending"** banner that states the invitation is
  single-use and *awaiting acceptance by the recipient*, that the owner *remains the registered owner
  until the recipient signs in and accepts*, and a **"Manage or cancel transfer →"** action linking to
  the existing `collector.transfer.show` page (where the single-use link + Cancel button already
  live). When not pending, the ordinary "Transfer ownership →" link is shown as before. (Objectives
  3, 4, 5.) **No token is rendered on this page in either branch.** (Objective 6.)

### 2. Confirmation messages (status flashes)
- **`TransferController`** now attaches a `status` flash to each redirect:
  - `initiate` → `collector.transfer.show`: "Transfer invitation ready. Share the single-use link
    below with the recipient — it expires, and you remain the owner until they accept."
  - `cancel` → `collector.transfer.show`: "Transfer invitation cancelled. The previous link no longer
    works, and you remain the owner."
  - `accept` → `collector.collection.index`: "Ownership transferred to you. This item is now in your
    collection."
- **`transfer/initiate.blade.php`** and **`collection/index.blade.php`** (the two redirect targets)
  now render a `session('status')` / `session('error')` flash slot, using the same styling as the
  existing `collection/show.blade.php` flash slots. (The shared layout renders only validation
  `$errors`, so these two targets previously showed no session flash.) (Objective 7.)

## What was deliberately NOT touched (Objectives 8, 9, 11; STRICT LIMITS)
- **`TransferWorkflow`, `TransferService`, `ProjectionService`** — unchanged. The single-use /
  expiring / owner-only / self-guard / stale / adverse-status protections are byte-for-byte as
  before. No new method was added to any transfer service.
- **No migration / schema / DB change.** No R0/R0b/R0c claiming behavior touched. No Shopify, no
  email-provider config, no Option-C work.
- **Access control is unchanged and verified:** the item-detail page is already owner-scoped (a
  non-owner / unauthenticated request yields the privacy-safe 404 / login redirect), so the pending
  banner and the Manage/cancel action are visible only to the current owner. (Objective 9.)

## Tests — written, NOT run (defer to a separately-authorized disposable-DB session)
`tests/Feature/Sca/TransferStatusClarityTest.php` (new, `php -l` clean), hard-guarded to
`sca_domain_test`, `DatabaseTransactions`:
- **d1** no-pending → item detail shows the ordinary transfer link copy, not the banner.
- **d2** pending → item detail shows the "Transfer pending" banner + "awaiting acceptance" + "Manage
  or cancel transfer"; the ordinary "generate" copy is replaced.
- **d3 (token privacy)** → with a pending invite, the item-detail HTML contains **neither the 32-hex
  invite token nor the accept URL that embeds it**.
- **m1 / m2 / m3** → generate / cancel / accept each render their confirmation message (via
  `followingRedirects`).
- **a1** → a non-owner's detail request is a 404 and exposes no transfer controls, banner, or token.
- **a2** → an unauthenticated detail request redirects to the collector login.

These require a disposable DB (migrate + `db:seed`, then `vendor/bin/phpunit` on `sca_internal`),
which is out of scope for this task's authorization. Run them under the next authorized DB session
before any merge.

## Static validation performed (non-destructive)
- `php -l` clean: `CollectionController.php`, `TransferController.php`,
  `TransferStatusClarityTest.php`.
- Blade directive balance verified on all three touched views (`@if`/`@endif`, `@unless`/
  `@endunless`, `@foreach`/`@endforeach` all paired; inline `@section('title', …)` needs no
  `@endsection`).
- Full worktree diff reviewed: 40 insertions / 5 deletions across the 5 non-test files; all within
  `packages/Sca/Collector`.

## Safety / scope
Dev branch only; prod `main` (`cb8a8c3`) + live bind-mount untouched; no migration run; no live
transfer; `read_orders`/Shopify unchanged; R0/R0b/R0c claiming behavior unchanged; passport /
registration / My Collection / external-intake untouched.

**STOP — transfer status-clarity implemented (`a44103a`). NEXT (separate auth): an authorized
disposable-DB session to run `TransferStatusClarityTest` + the existing `TransferWorkflowTest`
(confirm no regression in the transfer surface), then code-only merge review. No deploy without
separate authorization. SEPARATE OPEN: Phase-1 first genuine `products/*` webhook receipt
verification.**

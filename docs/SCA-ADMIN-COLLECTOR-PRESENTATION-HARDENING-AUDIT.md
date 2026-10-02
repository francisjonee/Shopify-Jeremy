# SCA Admin + Collector presentation hardening — readiness / design audit (READ-ONLY)

**Date:** 2026-10-02 · **Deployed baseline:** main `236acd9`, migrations **120** (production confirmed at
`236acd9`; `origin/main == 236acd9`).
**Status: AUDIT / DESIGN ONLY — zero implementation; no DB write / mutation / schema / route / ACL change.
For ChatGPT review. ACTIVE / NEXT_TASK remain unpromoted.**

The four remaining **P2** presentation findings from the final production-readiness audit (gov `b390838`),
re-checked against current code. All four are **genuine (not already resolved)**; all are presentation-level.

---

## Finding 1 — Admin owner shown as raw `Collector #<db id>`

**Current behavior.** Four staff surfaces render the owner as `'Collector #'.<sequential DB id>`:
- `eyewear/show.blade.php:183` — Overview "Registered owner".
- `EyewearItemController.php:675` — `currentOwnerLabel` (→ `ownership-history.blade.php`).
- `EyewearItemController.php:729` — per-row owner in the ownership-history ledger.
- `OwnershipCorrectionController.php:46` — `currentOwnerLabel` on the ownership-correction confirm page.

**Root cause.** The projection row exposes only `current_owner_collector_id` (the internal DB id); the admin
read model does **not** currently load the collector's opaque `public_ref`. The views therefore print the raw
id. (Inconsistent with the opaque `COL-…` ref already used as the lookup key on the Collector Support surface
and as the ownership-correction destination input.)

**Proposed UX.** Render the collector's opaque **`COL-…` `public_ref`** instead of `Collector #<id>`; for
staff who hold `sca.collector.support`, make it a **link to the existing** `admin.sca.collector.support.show`
detail (deep-link the support tool); for staff without that permission, show the plain `COL-…` text (no link).
On the ownership-history **ledger**, keep per-event owner refs as `COL-…` (do NOT collapse to "Registered to a
collector" — the A→B→A owner distinction is the point of the ledger).

**Files likely to change.** `EyewearItemController::show` + `::ownershipHistory` (load `public_ref` for the
current owner and for each ownership-event `collector_account_id` via a read join/lookup on
`sca_collector_accounts`), `OwnershipCorrectionController::confirm` (same for `currentOwnerLabel`),
`eyewear/show.blade.php:183`, `eyewear/ownership-history.blade.php`, `eyewear/ownership-correct.blade.php`.

**Does controller/service data already support it?** **No — needs a small read-model addition** (a join/lookup
to resolve `public_ref` from `collector_account_id`). **No schema** (`public_ref` already exists on
`sca_collector_accounts`). This is the only finding requiring controller work; 2/3/4 are view-level.

**ACL / privacy.** `public_ref` is opaque, operator-safe (already shown on the support surface, used as its
lookup key) and is **strictly less revealing** than the current sequential DB id — no PII (no email/name). The
clickable link is **gated on `sca.collector.support`** so only support-authorized staff get a link (others see
plain text); the target route keeps its own ACL. No access broadened.

**Regression.** Admin item Overview + ownership-history + ownership-correct show `COL-…` and **never**
`Collector #<digits>`; the support deep-link appears only with `sca.collector.support` (plain text without);
ownership-history still distinguishes distinct owners across A→B→A; no email/DB-id/internal field leaked;
rendering mutates nothing.

## Finding 2 — First-certification CTA discoverability

**Current behavior.** The only control to issue a **first** certification is a "Certify from this
authentication" POST form **inside a row of the Authentication tab** (`show.blade.php:298-303`, guarded
`$a->result==='passed' && !$certification && !$qrIdentity && hasPermission('sca.eyewear.certify')`). The
**Certification & QR** tab's uncertified branch (`show.blade.php:320-325`) shows only prose ("Not certified.
Certification is issued from a finalized passed authentication…") with **no action**.

**Root cause.** The action lives on a different tab from where an operator goes to certify; the Certification
tab explains but offers nothing to click.

**Proposed UX (smallest; same mechanism).** In the Certification & QR uncertified branch, when a finalized
**passed** authentication exists and there is no current cert/QR and the operator has `sca.eyewear.certify`,
render the **same** certify form (POST `admin.sca.eyewear.certification.issue` with that `authentication_id`)
— i.e. a discoverable "Issue certification" button in the Certification tab — **or**, if the reviewer prefers
zero duplication, an in-tab pointer link to the Authentication tab. This reuses the existing endpoint; it does
**not** create a second certification mechanism.

**Files likely to change.** `eyewear/show.blade.php` **only** (compute the eligible authentication from the
already-passed `$authentications` collection: `$authentications->first(fn($a)=>$a->result==='passed' &&
$a->finalized_at)`).

**Does controller/service data already support it?** **Yes** — `show()` already passes `$authentications`,
`$certification`, `$qrIdentity`; the eligibility is derivable in the view with no new data.

**ACL / privacy.** None changed — reuses the existing `sca.eyewear.certify`-gated endpoint and the same
request shape. No new route/mechanism.

**Regression.** An uncertified item with a finalized passed authentication shows an "Issue certification" CTA
in the Certification tab (gated on `sca.eyewear.certify`); it posts to the existing endpoint and certifies
identically to the Authentication-tab control; an item with no eligible authentication shows the explanatory
prose and no button; an already-certified/revoked item is unaffected.

## Finding 3 — Collector Support terminology (raw enums)

**Current behavior.** The now-reachable Collector Support surfaces show raw enums:
- `collector/support-index.blade.php:32` — account `status` raw (`active`/`disabled`/`pseudonymized`).
- `collector/support-show.blade.php:15` — "Account state" `$collector['status']` raw.
- `collector/support-show.blade.php:52` — owned-item `registry_status` raw (`lost`/`stolen`/`disputed`/…).
- `collector/support-show.blade.php:54` — certification reads `'Certified' : 'Not certified'` (slightly off
  from the canonical "Not currently certified").

**Root cause.** The Collector Support surface pre-dates / was missed by the `ItemStateLabels` rollout and
humanizes nothing.

**Proposed UX.** Route the item `registry_status` through **`ItemStateLabels::registryShort()`** (the existing
canonical map — the same compact form the admin registry grid/filter use), and align the certification cell to
**`ItemStateLabels::certificationShort($it->certified)`** ("Certified" / "Not currently certified"). The
**account `status`** (`active`/`disabled`/`pseudonymized`) is a collector-**account** lifecycle, **not** an
item-state concept, so it is **not** an `ItemStateLabels` candidate — humanize it with a simple `ucfirst()`
(e.g. "Active"/"Disabled"/"Pseudonymized"); **do not introduce another map**.

**Files likely to change.** `collector/support-index.blade.php`, `collector/support-show.blade.php` (view-only;
call the existing presenter / `ucfirst`). Optionally the controller DTO already passes `registry_status` +
`certified` + `status` raw, which the Blade maps — no controller change needed.

**Does controller/service data already support it?** **Yes** — `CollectorSupportController::ownedItems` already
passes `registry_status`, `certified`, and account `status`; only the Blade rendering changes.

**ACL / privacy.** **None** — search semantics, ACL, routes, and data visibility unchanged; this only relabels
values already shown. `public_ref`-only addressing and the no-email policy are untouched.

**Regression.** Support index/detail show canonical registry wording (e.g. `disputed`→"Under review") +
"Not currently certified" and a humanized account state; raw `pseudonymized`/`disputed`/`lost` strings no
longer appear as labels; search/lookup results and counts unchanged; zero mutation.

## Finding 4 — Anonymization success feedback dropped (CONFIRMED)

**Current behavior.** `PrivacyController::destroy` (`:67`) flashes the success under key **`status_notice`**
and redirects to `collector.login.show`; but `login.blade.php:6-7` renders only **`session('status')`** — so
after an irreversible account anonymization the collector lands on sign-in with **no confirmation**.

**Root cause.** Flash-key mismatch: the collector app uses `status` on the **login** screen and `status_notice`
on the **collection detail** screen (`collection/show.blade.php:14`); the anonymization redirect targets login
but flashes the collection-detail key.

**Proposed UX (smallest; existing convention).** Change the flash in `PrivacyController::destroy` from
`->with('status_notice', …)` to **`->with('status', …)`** — the exact key the login screen already renders
(green confirmation). (Equivalent alternative: also render `session('status_notice')` in `login.blade`; the
one-line flash-key change is smaller and matches the login convention.)

**Files likely to change.** `PrivacyController.php` (one line) — **or** `login.blade.php` (one line). No
controller logic/semantics change.

**Does controller/service data already support it?** **Yes** — the message string already exists; only the
flash key needs to match.

**ACL / privacy.** None — same redirect, same message, no new data; anonymization semantics untouched.

**Regression.** After a successful anonymization the collector login screen shows the success confirmation
(`session('status')`); the destructive guard paths (still-owns-items / failure) are unaffected; no second
mutation; message leaks no identity.

---

## Bundle vs split

**Ship as ONE bounded presentation-hardening bundle.** All four are P2, independent, presentation-only, with
no schema / route / ACL / domain-semantics change and self-contained regressions. Findings **2, 3, 4** are
view-level (2 and 3 view-only; 4 a one-line flash key). Finding **1** is the only one with controller/read-model
work (a `public_ref` join + support-link gating across ~4 sites) and the widest file touch — recommend it be a
**clearly separable commit within the bundle** so the reviewer can lift it out if they'd rather land the
pure-view 2/3/4 first. No ordering dependency between them. Suggested single feature branch, per-finding
commits, one combined `tests/Feature/Sca` gate.

**No business/product decision is required for these four** (unlike the separate passport adverse-status
prominence + trust-copy items, which remain operator decisions and are **not** part of this bundle).

## Boundaries honored
Read-only: no code/DB/schema/route/ACL/mutation/SMTP/infra change; no temporary users; production remains at
`236acd9`, migrations 120. **Recommendation: GO for a single presentation-hardening implementation task**
(push-only → review → governed merge/deploy). **AUDIT ONLY — nothing promoted; awaiting ChatGPT review.**

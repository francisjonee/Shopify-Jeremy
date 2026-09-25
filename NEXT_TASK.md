# NEXT TASK

**STATUS:** ACTIVE — `SCA-COLLECTOR-PASSPORT-ACCESS-041` implemented and pushed for ChatGPT audit (NOT merged, NOT deployed).

Feature branch `sca-collector-passport-access-041` pushed to the implementation repo from accepted base
`ec75d4f5cd18fbb4b9314e28fa8ab99fb6a44398`. Awaiting ChatGPT audit; must not be merged, deployed, or
promoted onward (SCA-042 must not start) until ChatGPT authorizes.

*Prior task `SCA-STAFF-COLLECTOR-SUPPORT-040` is DONE (deployed `ec75d4f`). `SCA-PRODUCTION-CUTOVER` remains
BLOCKED/DEFERRED awaiting Jeremy; it does not block application development.*

## Title

SCA-COLLECTOR-PASSPORT-ACCESS-041 — owned-item access to the canonical public passport

## Implementer

Claude

## Why this task now

Collectors can see owned items in My Collection, but the public passport is primarily reached by scanning
the physical permanent QR. An authenticated current owner should be able to open the same canonical public
passport directly from their My Collection item detail. Access/UX only — it must not create a second
passport representation or weaken the passport security/privacy contract.

## Executable directive (as governed)

Add a collector-authenticated GET route associated with an owned collection item (conceptually
`GET /collector/collection/{ref}/passport`, naming per existing conventions) that: requires collector
authentication; resolves the item by its opaque/public SCA reference; establishes from the canonical
projection that the authenticated collector is the current owner; establishes that an active permanent QR
identity exists; establishes whatever current-certification eligibility the existing passport resolver
requires; obtains the active QR token server-side; and redirects to the existing canonical `/p/{token}`
route. Do not render a second passport page.

On the owned-item detail page, conditionally show a "View public passport" action, only when the item can
legitimately resolve through the existing public passport. Do not display the raw QR token or any
IP/host-derived identity. It must keep working after an SCA-038 supersede (same permanent QR).

Fail closed: current owner allowed; previous owner after transfer denied; unrelated collector denied;
unauthenticated → collector login; unknown item safe failure; ownerless item denied; inactive/stale QR
denied; revoked / no-current-certification must not circumvent the existing passport 404 contract. Prefer
safe not-found over revealing whether another collector's item exists.

Passport contract — HARD BOUNDARY: do not modify `PassportResolver`/`PassportController` unless inspection
finds an unavoidable conflict and you STOP for ChatGPT review first. SCA-020/034 Option-A stays authoritative
(eligible → passport; unknown/ineligible/revoked → existing constant-shape behavior; supersede → same token
resolves the successor). No distinguishable revoked-item public state.

QR permanence: no QR creation/reissue/token rotation/lifecycle event/`active_qr_identifier_id` change/
identity duplication — consume the already-active permanent identity read-only. Zero business/provenance
mutation. Expected schema impact: none.

Privacy: do not expose in My Collection HTML the raw QR/public token, unnecessary internal PKs, other
collector identity/PII, claim/transfer/grant/reset tokens, or staff-only provenance reasons. The final
`/p/{token}` page stays governed by its existing public allowlist.

Tests (focused + full `tests/Feature/Sca` + lint + composer validate/audit + secret/debug scan) must prove
the owner redirect + canonical render, eligibility-gated UI, no raw token in HTML, all fail-closed cases,
Option-A preserved for revoked, supersede reaching the successor via the unchanged QR, zero mutation, and
unchanged public passport behavior.

Non-goals: no My Collection history enrichment, collector profile editing, notifications, QR
download/printing, certificate redesign, staff changes, new public passport fields, or domain/DNS work.

## Completion state (recorded)

Implemented on branch `sca-collector-passport-access-041` (base `ec75d4f`). New route
`GET collector/collection/{ref}/passport` (`collector.collection.passport`, `collector.auth`) →
owner+eligibility authorized via the canonical projection (`CollectionService::activePassportTokenForOwnedItem`)
→ redirect to `sca.passport.show`. `PassportResolver`/`PassportController` unchanged; no schema migration.
Focused `CollectorPassportAccessTest` 12/32; full SCA suite 521/2198. Full evidence in
`docs/task-reports/SCA-COLLECTOR-PASSPORT-ACCESS-041.md` (implementation repo). **Push only — awaiting ChatGPT
audit before any merge/deploy. SCA-042 must not start.**

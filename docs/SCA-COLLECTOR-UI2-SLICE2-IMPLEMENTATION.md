# SCA Collector Experience / UI 2.0 — Slice 2 Implementation Evidence (pre-merge)

**Status:** CANDIDATE pushed — awaiting ChatGPT pre-merge audit. NOT merged, NOT deployed. Presentation-hierarchy redesign only; **no migration**, no controller/service change, no new domain behavior.

| | |
|---|---|
| Governance promotion | `3ff6a5d1ccb2f257be5e712a19b03f189321e090` |
| Implementation branch | `feat/sca-collector-ui2-slice2` (one commit ahead of base, 0 behind) |
| Exact production base SHA | `e20e549948ecbf5c967d48a7444275280dafb97c` (migration 138) |
| Candidate SHA | `dba6c4d7b83b674615f461d081f64d9c07e2077d` |
| Migration | **none** (138 unchanged) |
| Changed files vs base | 4 (469 insertions, 176 deletions) |
| Focused tests | `CollectorCollectionUi2Test` 12 → **12 passed** |
| Full `tests/Feature/Sca` | **1347 passed / 1 skipped / 0 failed** |
| Production provenance FP (unchanged) | `d15a5cbdfb8df52ba65628b276533cfe`, counts `3/3/4/4/5/2/1/1/7`, migration 138 |

## Changed files (4)
- `app/packages/Sca/Collector/src/Resources/views/collection/index.blade.php` — My Collection: browse-first.
- `app/packages/Sca/Collector/src/Resources/views/collection/show.blade.php` — Eyewear Detail: asset-first.
- `app/tests/Feature/Sca/CollectorCollectionUi2Test.php` *(new, 12)*.
- `app/tests/Feature/Sca/CollectorItemDetailParityTest.php` — one assertion updated from the old combined "Manage item" heading to the new split "Transfer" / "Report a problem".

No controller, service, route, or DTO change. All data comes from the existing owner-safe `CollectionService` readers.

## A. My Collection — browse first, manage second
- Eyewear grid is the visual focus (responsive image cards: brand/model primary, SCA ref secondary, concise cert/registry/condition). Canonical current-owner catalog + all filters/sorts/pagination unchanged.
- CP-6 group-chip switcher (All items + named private collections) kept at the top as the browsing control, with `aria-current` on the active chip; active-group context + GET filter query preserved (group carried as a hidden field and on Reset).
- Collection administration (create/rename/reorder/delete) moved into a **secondary collapsed `<details>` "Manage collections"** disclosure below the grid — same forms, routes, CSRF tokens and `@method`s as before; it no longer precedes/dominates the eyewear.
- Obsolete "Back to account" removed (Slice-1 shell is authoritative).
- Mobile ~360px: controls wrap, grid `minmax(200px,1fr)`, inputs `max-width:100%`; no horizontal overflow.

## B. Eyewear Detail — asset-first hierarchy
- **Asset hero leads**: authenticity badge, authorized gallery (ordinal image routes; the selected thumbnail now exposes `aria-pressed` to assistive tech, progressive-enhancement JS unchanged, no-JS featured image stays), item name (brand/model), SCA ref, metadata. Adverse registry warning remains dominant and first (safety).
- **Current Market Reference surfaced near the asset** (left panel, just under identity) instead of only under History — owner-safe current advisory range + as-of + basis + source summary + exact non-guarantee wording; shown only when a canonical current reference exists; voided/absent is not fabricated; no invented value/appreciation/conversion/comparables. (Removed the duplicate copy from the History tab.)
- **Primary trusted actions**: Public Passport (only under existing eligibility), Transfer (reachable when not adverse).
- **Details/history** (Authentication, Certification, Documents, Ownership history, Service history) remain in the owner-safe tabs; data semantics unchanged.
- **Safety separated**: the former combined "Manage item" is split into an ordinary **Transfer** block and a visually distinct **"Report a problem"** area (Report lost / Report stolen / Mark recovered). Confirmation pages, routes, authorization and all adverse transfer restrictions are unchanged.
- **Personal organization/sharing secondary**: CP-4 public-profile visibility and CP-6 private Organize relocated **below** the asset (were above identity) — exact routes/CSRF/eligibility/mutation preserved.
- No frame serial, QR token, internal IDs, storage paths, staff refs/reasons, private docs, or other-collector identity in the detail HTML.

## Domain/security invariants — unchanged
Current-owner authorization + privacy-safe 404; authorized/no-store image & document routes; public-profile visibility semantics; private collection membership/order; transfer workflow/token/eligibility; lost/stolen/recovered workflow + adverse restrictions; authentication/certification/history; Market Reference Slice-1 advisory semantics; Passport/QR/certificate; CSRF/throttle/collector guard/opaque refs; zero new provenance/current-state writers.

## Mandatory-test → evidence map
| Requirement | Test |
|---|---|
| catalog/detail current-owner scoped; non-owner/guest safe | u1, u4 (+ existing MyCollection/parity) |
| Collection shell active on index/detail | u1 (index), existing ce4 (detail) |
| active private-group browse context + GET filters intact | u2 |
| catalog cards use authorized image route, no storage path/id | u3 |
| detail hero owner-safe brand/model/ref + truthful states | u4 |
| Market Reference prominent only when current ref exists; advisory wording | u5 |
| public Passport only under eligibility | u6 |
| visibility + private-collection controls keep routes/CSRF/eligibility | u7 |
| transfer hidden/blocked under adverse | u8 |
| lost/stolen/recovered safety actions present + separated | u9 (+ existing LostStolen/status confirm suites) |
| documents owner/public-only | existing parity/documents coverage |
| gallery authorized ordinal routes + accessible selected thumbnail | u10 |
| no sensitive field/QR token/storage/staff leak in detail | u11 |
| GET index/detail zero provenance/current-state mutation | u12 |
| existing CP-2/CP-4/CP-6, parity/gallery, transfer/status, Market Reference, Collector Experience green + full gate | full `tests/Feature/Sca` 1347 passed |

## Responsive evidence
Mobile-first from ~360px: index grid `repeat(auto-fill, minmax(200px,1fr))`, controls `flex-wrap`, inputs `max-width:100%`; the Slice-1 shell bottom tab bar persists; detail two-panel `.detail` collapses to single column ≤720px (existing parity CSS). Deterministic markup/CSS assertions in the suite (authorized routes, aria-pressed, `<details>` disclosure, no overflow-inducing fixed widths). No frontend framework introduced.

## Production-untouched proof
Live tree restored to `main@e20e549`, vendor `--no-dev`, `/admin/login → 200`. Prod DB migration 138, provenance FP `d15a5cbd…` / counts `3/3/4/4/5/2/1/1/7` unchanged; no schema change. All work ran on the disposable `sca_domain_test` DB only.

**STOP — awaiting ChatGPT pre-merge audit of candidate `dba6c4d`. Do not merge or deploy; do not start another initiative.**

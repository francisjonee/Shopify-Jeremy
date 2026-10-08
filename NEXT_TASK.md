# NEXT TASK

**STATUS: CP-2 PROMOTED — Rich My Collection (collection-level experience). Implement on a new branch from exact production baseline `8d8c35947d7c405124e0df4f09ff3ef4ee9e6bb8`. Do not deploy. STOP for ChatGPT pre-merge audit.**

Updated 2026-10-09.

## Baseline / audit finding
Implementation: `francisjonee/francisjonee-sca-platform-private`
Exact base: `8d8c35947d7c405124e0df4f09ff3ef4ee9e6bb8`
Prod migrations: 131.

ChatGPT audited the deployed My Collection implementation before promotion. Item DETAIL is already rich and must not be rebuilt: it already has owner-authorized multi-image gallery, identity metadata, authenticity/current certification semantics, certification history, owner-visible documents, ownership timeline, service history, public-Passport convenience, transfer, and lost/stolen/recovered controls.

**CP-2 therefore targets the COLLECTION-LEVEL experience only:** make `/collector/collection` useful for collectors with more than a few frames while preserving canonical current-ownership membership and privacy.

## Objective
Turn My Collection from a simple vertically ordered list into a responsive, private collection catalog with truthful summary, search/filter/sort, richer cards, and clear empty/no-result states. All display state must be derived at read time from existing canonical data. No duplicate collection/provenance state.

## Required behavior

### 1. Collection header / summary
On authenticated `GET /collector/collection`, show a compact collection header derived from canonical current ownership:
- total registered frames;
- currently certified count;
- distinct known brands;
- collector display name where appropriate (canonical account display_name; presentation only).
Reuse/centralize existing CP-1 collection-stat semantics rather than introducing stored counters.

### 2. Rich responsive cards
Replace the narrow row presentation with a responsive card/grid experience appropriate for desktop and mobile.
Each owned-item card may show ONLY owner-safe existing facts:
- primary owner-authorized catalog image when present, stable placeholder when absent;
- brand + model;
- SCA reference;
- SKU when present;
- condition grade/label when present;
- current certification state (truthful: Certified vs Not currently certified);
- canonical registry warning when adverse;
- optional safe metadata already present in canonical item data (e.g. year) if it improves the card.

The whole card should navigate to the existing owner-authorized detail route. Do not expose raw image/storage paths, internal IDs, QR/cert tokens, staff refs, frame_serial, Shopify data, other collectors, or private authentication notes.

### 3. GET-only search/filter/sort
Add server-side GET query controls to `/collector/collection`:
- free-text search across owner-safe collection identity fields: brand, model, SCA public reference, SKU;
- brand filter using brands that occur in THIS collector's current collection only;
- certification filter: all / currently certified / not currently certified;
- registry filter: all / normal / attention (attention = owner-safe adverse statuses already recognized by collection UI);
- sort options:
  - recently added to this collector (default);
  - brand A–Z;
  - brand Z–A;
  - SCA reference.

Requirements:
- query params are allowlisted/normalized server-side; invalid values fall back safely;
- filters never broaden membership beyond canonical `current_owner_collector_id`;
- search/filter/sort create zero domain mutation;
- no raw SQL interpolation from request values;
- query state remains visible in controls and pagination/navigation if pagination is introduced;
- no cross-collector brand/filter leakage.

### 4. “Recently added” semantics
Default ordering must be derived from canonical ownership provenance: the effective date of the event that made the authenticated collector the CURRENT owner (claim / transfer_in / admin_correction as applicable), with a deterministic tie-breaker.
Do NOT use item creation date as a substitute and do NOT persist a duplicate `added_to_collection_at` field.

If deriving this cleanly requires a small read-query helper/subquery, implement it read-only and test claim/transfer/correction cases.

### 5. Result context + empty states
- True empty collection: retain a helpful zero-owned state and a clear path to existing authentication submission flow.
- Filters/search with zero matches: distinguish “no matching items” from “you own no items”; provide a clear reset-filters action.
- Show a compact result count/context when filters/search are active.
- Preserve query parameters when changing sort/filter in the intended form flow.

### 6. Performance / query discipline
Design for collections larger than today's test data:
- avoid N+1 per-card queries;
- primary image availability must use existing owner-safe image route and server-derived presence only;
- brand choices and summary should use bounded aggregate/read queries;
- if pagination is added, use a reasonable fixed page size and preserve filters. Pagination is optional if the implementation can demonstrate bounded behavior without it; for unbounded collection lists, pagination is preferred.

### 7. Privacy / authorization invariants
Must remain true:
- membership ONLY from canonical current ownership;
- previous owner loses list/detail/image access immediately after transfer;
- guessed/non-owned refs remain privacy-safe;
- collector guard required; staff session alone does not grant collector access;
- public Passport receives NO collector/profile identity;
- no public collection/profile route is added;
- all collection browsing is read-only / zero provenance mutation.

## Architecture guidance
Prefer a typed/normalized read-filter object or a small explicit options array at the CollectionService boundary rather than passing the raw Request/query bag into SQL-building code.

It is acceptable to extend `ownedItems()` or add a dedicated collection-catalog query method. Preserve existing call sites/tests that rely on `ownedItems(int $collectorId)` unless deliberately migrated with equivalent semantics.

The current list DTO lacks a trustworthy current-certification boolean and “added to collection” date. Extend the owner-safe DTO from canonical joined/derived data rather than inferring presentation from lifecycle_state.

Use the existing owner-authorized image route for card images. Do not create public image URLs.

UI changes should stay within the collector layout and be responsive; do not introduce a frontend framework.

## Mandatory tests
Add/extend focused tests proving at minimum:
1. auth/staff separation and current-owner membership remain intact;
2. search matches brand/model/ref/SKU and cannot reveal another collector;
3. brand filter choices are collector-scoped;
4. certified/not-certified filter uses canonical current certification, including revoked/no-current cases;
5. registry attention filter matches the existing adverse-state policy and normal excludes adverse;
6. invalid filter/sort inputs safely normalize/fallback;
7. default recently-added order follows ownership event effective chronology, including transfer-in and admin-correction where supported;
8. deterministic tie ordering;
9. brand A–Z / Z–A and ref sorting;
10. query controls retain normalized state;
11. true-empty vs filtered-no-result states;
12. richer cards never expose internal ids/tokens/frame_serial/staff/Shopify/other-collector data;
13. prior owner disappears immediately after transfer;
14. browsing/search/filter/sort causes zero provenance/domain mutation;
15. public Passport privacy remains unchanged;
16. no N+1 regression for per-card detail/history/image lookups; test/query-count evidence or equivalent structural proof.

Run the relevant focused My Collection suites and the full `tests/Feature/Sca/` gate. Report exact pass/assertion/skip counts.

## Forbidden / out of scope
- no schema/migration unless ChatGPT explicitly re-approves a demonstrated necessity;
- no public collector profile;
- no public collection/item visibility controls;
- no handles;
- no favorites/wishlist/custom collections/tags;
- no social/follow/friends/comments;
- no marketplace/resale;
- no valuations/market-price data;
- no item-detail redesign except tiny compatibility changes required by the collection DTO;
- no provenance mutation/model redesign;
- no Stripe/SMTP/Shopify/Caddy/DNS work;
- no CP-3.

## Handoff
Create a new CP-2 branch from exact `8d8c359`. Implement the complete bounded slice, update/add a CP-2 implementation document, run focused + full gates, push candidate, and report:
- branch/base/head;
- changed files;
- whether migrations changed (expected: none, remains 131);
- exact UX/query semantics;
- focused/full test counts;
- production untouched / deployed SHA still `8d8c359`;
- provenance/Stripe/mail state unchanged.

Then **STOP for ChatGPT pre-merge audit. Do not merge or deploy.**

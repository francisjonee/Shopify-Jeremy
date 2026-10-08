# NEXT TASK

**STATUS: CP-6 PROMOTED — Private Collection Organization. Implement on a NEW branch from exact production baseline `0101755b03352305050b7b7290ad917b588112ff` / migration 134. Do not merge/deploy. STOP for ChatGPT pre-merge audit.**

Updated 2026-10-09.

## Architecture audit
ChatGPT audited the live CP-2 My Collection catalog, CP-4 public-item visibility, canonical projection/ownership boundary, transfer service, ownership correction, privacy lifecycle, and collector routes at exact production baseline `0101755b...`.

### Existing truths to preserve
- My Collection membership is ONLY canonical current ownership: `sca_item_current_state.current_owner_collector_id == authenticated collector`.
- CP-2 already provides search, brand/cert/registry filters, deterministic sorting, pagination, summary stats, rich cards.
- CP-4 public visibility is a separate presentation preference and public reads independently intersect canonical current ownership.
- `ProjectionService::rebuild()` is the single canonical projection boundary used by ownership/status writers and already performs CP-4 stale-visibility hygiene.
- Privacy pseudonymization fails closed while collector owns items and deletes presentation/privacy state in one transaction.
- Ownership/provenance event history must remain untouched.

## CP-6 architectural decision
**CP-6 = private user-defined collections (named groups) with many-to-many item membership and explicit manual ordering.**

Do NOT implement a separate tag system or a first-class favorites system in CP-6.
- Tags would overlap CP-2 filtering without a demonstrated product need.
- “Favorites” can later be implemented as a special/system collection if needed; no schema should hard-code it now.

An item may belong to **zero, one, or many** user-defined collections.

CP-6 is **PRIVATE ONLY**.
No public collection/group page, no CP-4 public grouping, no handle/public-profile change. CP-4 visibility remains item-level and independent.

Core invariant:
**Organization is a collector-owned presentation preference. It never grants ownership, never makes an item public, and never becomes provenance.**

## Data model
Expected migration 134→135.

### `sca_collector_collections`
- id
- collector_account_id FK → collector accounts, RESTRICT
- public_ref: opaque high-entropy collection identifier, immutable; use a new unambiguous prefix such as `CCL-` + 12 hex (or equivalent existing Token convention)
- name VARCHAR(80)
- position integer/bigint (manual ordering of groups)
- created_at / updated_at.

Constraints/indexes:
- UNIQUE public_ref
- collector-scoped normalized name uniqueness. Prefer a dedicated `name_normalized` column + UNIQUE(collector_account_id, name_normalized) so DB is collision authority.
- index (collector_account_id, position, id)
- collector_account_id/public_ref immutable at storage layer.

### `sca_collector_collection_items`
- id
- collector_collection_id FK → collections, CASCADE (deleting a collection deletes memberships only)
- collector_account_id FK → collector accounts, RESTRICT (denormalized deliberately for safe collector-scoped cleanup/query/constraint)
- eyewear_item_id FK → items, RESTRICT
- position integer/bigint (manual ordering within group)
- created_at / updated_at.

Constraints/indexes:
- UNIQUE(collector_collection_id, eyewear_item_id)
- index (collector_account_id, eyewear_item_id)
- index (collector_collection_id, position, id)
- collection/id/account/item identity columns immutable after insert.

If a robust DB constraint/trigger can guarantee membership.collector_account_id matches the collection owner, add it; otherwise the sole writer must enforce it under lock and tests must prove no cross-collector writes through application paths.

No brand/model/cert/status/ownership/public-visibility fields are copied into CP-6 tables.

## Name semantics
Conservative private name:
- trim outer whitespace;
- collapse internal whitespace runs to one space;
- 1–80 Unicode characters for display;
- normalized uniqueness = Unicode-safe lowercase/case-folded normalized display value as supported by runtime;
- reject control characters and all-whitespace;
- no reserved-name list needed because names are private and addressed by opaque ref, not URL slug.

Generic duplicate error; DB UNIQUE is ultimate authority.
Renaming changes only name/name_normalized; public_ref stable.

## Ordering
Manual ordering is in scope.

Keep it simple and bounded:
- collection groups have a `position`;
- memberships have a `position`;
- create/appending places at end;
- provide move/reorder actions using opaque collection/item refs;
- server derives/validates ownership and rewrites only rows belonging to session collector.
- positions need not be globally gapless, but ordering must be deterministic with `position, id` tie-break.
- do not accept internal ids.

Avoid O(N) writes for ordinary reads. Reorder may rewrite a bounded collector-owned list, but enforce a sensible maximum request size and test it.

## Ownership eligibility and mutation
A collector may add an item to a private collection ONLY if they are its canonical current owner at mutation time.

Mutation lock order:
1. lock active collector account;
2. lock target collection (must belong to collector);
3. resolve item by opaque item ref;
4. lock canonical `sca_item_current_state` row;
5. re-read current_owner_collector_id under lock;
6. insert/update membership.

This serializes add-membership against ownership mutation on the same item.

Removing membership is always privacy-safe but must still require the collection belong to session collector; unknown/non-member item should be idempotent/non-disclosing.

## Ownership-loss cleanup — mandatory
Stale organization membership MUST NOT survive transfer/admin correction and later silently reappear.

Extend the canonical ownership projection boundary:
After `ProjectionService::rebuild($itemId)` determines current owner, delete CP-6 membership rows for that item where `collector_account_id != current owner`.
If owner is null, delete all CP-6 memberships for that item.

This cleanup must happen in the SAME ownership-changing transaction as the projection rebuild, analogous to CP-4 hygiene.

Do NOT delete current-owner memberships on adverse registry status. CP-6 is private organization; lost/stolen frames still belong to the collector and should remain organized/searchable. This intentionally differs from CP-4 public visibility.

### Reacquisition
Transfer A→B:
- all A memberships for the item are deleted transactionally;
- B inherits none.

B→A later:
- A's old memberships do NOT resurrect;
- A must organize the reacquired item again explicitly.

Admin correction follows the same rule because it rebuilds through ProjectionService.

Public reads are irrelevant because CP-6 is private-only, but private collection-group reads must ALSO intersect canonical current ownership as defense in depth, so stale rows can never authorize visibility even if cleanup failed.

## Collection deletion
Deleting a user-defined collection:
- deletes only CP-6 collection row + memberships (CASCADE or explicit same transaction);
- never deletes item/provenance/public visibility;
- idempotent behavior should be safe;
- collection public_ref is not reused/redirected; there is no public route.

No tombstone required for private opaque collection refs in CP-6.

## Privacy/pseudonymization
Because pseudonymization currently refuses while collector owns items:
- once ownership is resolved and privacy proceeds, delete all CP-6 memberships and collections in the SAME privacy transaction;
- do this before pseudonymizing the account;
- zero CP-6 presentation state survives;
- no CP-6 name/ref copied to provenance.

## CP-4 interaction
Strict separation:
- adding/removing/reordering an item in CP-6 MUST NOT change `sca_collector_public_items`;
- setting CP-4 visibility MUST NOT add/remove/change CP-6 membership;
- deleting a CP-6 group does NOT make anything private/public;
- CP-6 names/groups never appear on public `/c/*` or `/u/*` surfaces in this slice.

## Private UX
Extend My Collection without replacing CP-2.

Recommended:
- index gets a private “Collections” section/chips/sidebar above/alongside existing filters;
- “All items” remains canonical default and shows all current-owned items;
- selecting a group filters CP-2 catalog to current-owned items in that group;
- preserve CP-2 search/brand/cert/registry/sort within the selected group;
- show group item count derived from current-ownership intersection, not stored counter;
- create/rename/delete/reorder groups;
- item detail gets “Add to collections / Organize” control with multi-select membership;
- mobile usable; no drag-and-drop dependency required. Up/down or explicit reorder controls are acceptable and easier to test/accessibility-wise.
- clear empty state for a new/empty group and filtered no-results state.

Address groups by opaque `CCL-` ref only. Item actions continue to use item public_ref.

## Routes
All CP-6 routes under existing collector.auth + web/CSRF.

Suggested bounded shape:
- POST `/collector/collections` create
- PATCH `/collector/collections/{collectionRef}` rename
- DELETE `/collector/collections/{collectionRef}` delete
- POST/PATCH `/collector/collections/reorder` group order
- POST `/collector/collections/{collectionRef}/items/{itemRef}` add
- DELETE same remove
- POST/PATCH `/collector/collections/{collectionRef}/items/reorder` membership order

Throttle mutations reasonably (e.g. 30/min; create/rename/delete lower if desired).
No public routes.
No Caddy/DNS change.

## Bounded queries
- Collection list/counts should be one/few bounded aggregate queries, no N+1.
- CP-2 catalog group filter should be a join/exists scoped to session collector + collection ref + canonical current ownership.
- Never hydrate all owned items just to count.
- Cap number of user-defined collections per collector at **50**.
- Cap reorder payload at **50 collections** and membership reorder at CP-2 page/list practical bound; if allowing >50 items in one group, use explicit max **100** per reorder request.
- Membership total need not be capped, but reads remain paginated via CP-2's 24-card catalog.

## Concurrency
Mandatory real two-connection proofs:
1. add-to-group racing transfer away:
   - add blocks/serializes on canonical item-state lock;
   - if transfer wins first, add fails;
   - if add wins first, subsequent ownership rebuild deletes old-owner membership before transfer commit;
   - after commit old owner cannot read item via group.
2. add racing admin ownership correction — same invariant.
3. same-name collection creation/rename collision → one succeeds, loser generic duplicate/unavailable; no raw DB error/500.
4. pseudonymization vs CP-6 mutation follows account-first serialization and cannot leave/resurrect organization state.

Do not accept raw 1205/1213 as the final user-visible contract where CP-6 defines a generic domain rejection.

## Mandatory tests
At minimum prove:
1. no collections by default; All items CP-2 unchanged;
2. create valid collection, normalized duplicate rejected generically;
3. 50-collection cap;
4. rename preserves opaque ref/memberships/order;
5. delete removes only group/memberships; provenance + CP-4 unchanged;
6. group order deterministic and reorder collector-scoped;
7. add requires session collector active + collection ownership + canonical current item ownership;
8. same item may belong to multiple groups;
9. duplicate add idempotent;
10. remove idempotent/non-disclosing;
11. group catalog intersects canonical current ownership and preserves CP-2 filters/search/sort/pagination;
12. counts derived from current ownership intersection;
13. item detail multi-membership state owner-scoped;
14. transfer A→B deletes A memberships transactionally; B inherits none;
15. B→A reacquisition does not resurrect A memberships;
16. admin correction same cleanup behavior;
17. adverse status does NOT delete private CP-6 membership;
18. CP-4 visibility completely independent both directions;
19. pseudonymization deletes groups/memberships when privacy is eligible;
20. no CP-6 fields copied into provenance; fingerprint unaffected by ordinary CP-6 mutations;
21. opaque refs only; no internal ids in request/HTML;
22. cross-collector collection/item guesses privacy-safe;
23. collection/membership identity immutability constraints;
24. normalized-name DB uniqueness;
25. real two-connection add-vs-transfer proof;
26. real two-connection add-vs-admin-correction proof or shared canonical lock proof plus actual correction integration;
27. real collision test produces generic domain outcome, no raw SQL;
28. privacy concurrency cannot resurrect state;
29. bounded query/no-N+1 proof for group list/counts/catalog;
30. no CP-6 data appears on public /c or /u profile HTML;
31. no public CP-6 routes;
32. existing CP-2 catalog without group parameter remains behaviorally unchanged.

Run focused CP-6 + CP-2 catalog + CP-4 public item/concurrency + transfer + ownership correction + privacy + public profile/handle + Passport regressions and full `tests/Feature/Sca`. Report exact counts/skips.

## Migration/deployment boundary
Expected migration 134→135.
Candidate implementation only.
Do NOT merge/deploy.
No Caddy/DNS/Stripe/SMTP/Shopify work.

Use the reproducible 13-table provenance row-data fingerprint procedure recorded in CP-5 Phase-A evidence for test/deployment invariants where applicable.

## Handoff
Create a NEW branch from exact `0101755b03352305050b7b7290ad917b588112ff`.
Implement complete bounded CP-6.
Push candidate and report:
- branch/base/head;
- changed files;
- migration/schema/constraints;
- name normalization + caps;
- organization service and lock order;
- ProjectionService ownership-loss cleanup;
- privacy cleanup;
- CP-2 catalog integration;
- routes/private UX;
- concurrency proofs;
- focused/full test counts;
- production untouched at `0101755b...`, migration 134;
- production fingerprint `d15a5cbdfb8df52ba65628b276533cfe` + canonical counts;
- collector/profile/public-item/handle/tombstone counts;
- Stripe dormant/mail log;
- confirmation no Caddy/DNS changes.

Then STOP for ChatGPT pre-merge audit.
Do not merge/deploy.
Do not start any post-CP6 initiative.

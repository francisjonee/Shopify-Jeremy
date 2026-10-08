# NEXT TASK

**STATUS: CP-4 PROMOTED — Public Collection Controls. Implement on a NEW branch from exact deployed baseline `3e707582c21e40b97e909c8593987787fd4c33c4`. Do not merge/deploy. STOP for ChatGPT pre-merge audit.**

Updated 2026-10-09.

## Architecture audit
ChatGPT audited deployed CP-2 current-owner collection semantics and CP-3 publication/privacy lifecycle before promotion.

### Existing truths
- Private My Collection membership is derived ONLY from `sca_item_current_state.current_owner_collector_id`.
- Transfer changes canonical current ownership; previous owner immediately loses private collection/detail/image authorization.
- CP-3 public profile publication is explicit, account-first serialized, active-account gated, and removed by pseudonymization.
- CP-3 public profile currently exposes ZERO collection/item/count information.
- Public Passport is item/provenance oriented and deliberately collector-identity-free.
- Registry adverse statuses are `disputed, lost, stolen, retired, invalidated`.
- Owner images are currently streamed only through owner-authorized private routes with raw paths hidden.

Critical invariants:
**Ownership ≠ publicity.**
**Profile publication ≠ item publication.**
**An old owner's visibility preference must never survive as public authority after transfer.**
**A new owner must never inherit the old owner's publication choice.**

## CP-4 objective
Allow an authenticated collector with a currently published CP-3 profile to explicitly choose which CURRENTLY OWNED items appear on that public profile.

Default is private. Publication is per collector+item, explicit opt-in, reversible, and presentation-only.

CP-4 adds:
1. private per-item public-visibility controls;
2. a minimal public collection section on the existing `/c/{publicRef}` profile;
3. public item image streaming for eligible visible items;
4. immediate fail-closed behavior on transfer, unpublish, account disable/pseudonymization, or adverse registry state.

No standalone public item detail page in CP-4.

## Visibility data model
Add dedicated presentation/privacy state, preferred table:
`sca_collector_public_items`

Columns:
- id
- collector_account_id
- eyewear_item_id
- is_visible boolean default false
- visible_since nullable timestamp
- created_at / updated_at

Constraints:
- UNIQUE(collector_account_id, eyewear_item_id)
- FK collector → sca_collector_accounts RESTRICT
- FK item → sca_eyewear_items RESTRICT
- no copied brand/model/cert/image/ownership/status fields
- no provenance mutation
- collector_account_id + eyewear_item_id immutable at storage layer
- one preference per collector/item.

Expected migration 132→133.

A visibility row is only a collector's presentation preference. It is NEVER evidence of ownership and never authorizes public rendering by itself.

Rows MAY remain after transfer as inert historical presentation preference, because public reads must always intersect canonical current ownership. If the same collector later legitimately reacquires the same item, do NOT automatically resurrect old visibility: on loss of ownership the old preference must be forced/reset to private OR the read/write model must include an ownership-epoch binding that makes the old choice permanently ineligible. Prefer the simpler, explicit privacy rule: **transfer/ownership-loss resets old owner's visibility to private transactionally** while public reads still independently require current ownership as defense in depth.

Do not make the recipient visible automatically.

## Private controls
Add controls only behind `collector.auth`.

Preferred endpoints:
- POST `/collector/collection/{ref}/public` → make visible
- DELETE `/collector/collection/{ref}/public` → make private

Rules:
- session collector only; no collector id from payload;
- opaque item public_ref route;
- server derives item id;
- mutation requires:
  - account active;
  - CP-3 public profile currently published;
  - canonical CURRENT ownership by session collector;
  - item public-eligible under registry rules below;
- CSRF + throttle;
- idempotent;
- do not create a visibility row on failed eligibility;
- make-private should be safe/idempotent for current owner; if ownership has already been lost it must not disclose whether a stale preference/item exists.

UI:
- My Collection card/detail may show neutral “Shown on public profile” / “Private” state and controls.
- Explain that public-profile publication and item visibility are separate.
- No bulk “publish everything” in CP-4.

## Public eligibility
An item appears publicly ONLY when ALL are true at read time:
1. collector CP-3 publication exists and is_published=true;
2. collector account status=active and CP-3 profile itself is resolvable (including nonblank display_name);
3. visibility preference for THIS collector+item is visible;
4. canonical `sca_item_current_state.current_owner_collector_id` equals that collector;
5. registry status is NOT in `StatusService::ADVERSE_STATUSES`.

Certification is NOT required merely to list an item publicly. Public UI must truthfully say certified/not currently certified from canonical current state.

Adverse registry status must immediately suppress the item and its public image. Recovery/normalization does NOT automatically republish a previously adverse item: when an item enters an adverse status, reset visibility to private transactionally, or bind preference to a safe eligibility epoch. Prefer explicit reset-to-private so collector must opt in again after recovery.

No public disclosure that a hidden item exists or why it disappeared.

## Transfer / ownership-loss integration
This is release-critical.

When canonical ownership changes away from collector A:
- A's public visibility for that item must be reset private in the SAME ownership-changing transaction before/with projection rebuild/commit;
- recipient B gets no visible preference;
- public profile query independently requires current ownership, so even an integration failure cannot authorize A;
- previous owner's public image route must fail immediately after commit;
- reacquisition by A remains private until A explicitly republishes.

Integrate at the canonical ownership-changing workflow/service, not only the collector TransferController. This must cover all ownership-change paths that can replace the current owner, including accepted collector transfer and staff/admin ownership correction. Audit existing ownership writers and hook the reset at the shared canonical boundary if one exists; if not, cover each writer explicitly and document why.

Lock order must be consistent with existing ownership/projection locks and CP-3 account/publication locks. Do not introduce account↔item lock inversion. Visibility reset caused by ownership/status change should not need to lock the collector account; it may update/delete the presentation row by item/current-old-owner under the already-held item/ownership transaction.

## Adverse-status integration
When canonical registry status transitions INTO any adverse status:
- visibility for the current owner/item must reset private in the SAME status-changing transaction;
- public reads independently reject adverse status;
- returning to normal/recovered does NOT restore visibility automatically.

Cover all status writers that can enter adverse state (collector and staff/system paths). Prefer a shared status-service boundary after the append and before transaction commit.

## Public collection presentation
Extend existing `/c/{publicRef}` only.

If eligible visible items exist, show a modest “Collection” section/grid.
If none exist, do NOT reveal hidden/private item count. A neutral empty public state is acceptable, e.g. “No items shared publicly.”

For each visible item allow only:
- public SCA item reference;
- brand;
- model;
- optional year;
- optional SKU only if already considered public-safe; if uncertain OMIT SKU in CP-4;
- current certification state: “Certified” / “Not currently certified”;
- certification number only when currently certified and already public-safe under Passport semantics;
- condition label only if already public-safe; if uncertain OMIT condition in CP-4;
- image if an eligible catalog image exists.

Conservative CP-4 default: expose ref + brand + model + year + current certification label + image. Do not expose SKU, condition, ownership dates, acquisition date, service history, transfer history, registry history/status reason, documents, internal ids, QR/passport token, frame_serial, staff data, Shopify data, notes.

Do NOT link a public item to Passport in CP-4. Passport remains independently discoverable by its QR/token, not through collector identity.

Public ordering: deterministic, e.g. brand/model/ref or visible_since then ref. Do not expose private acquisition chronology.

No public search/filter/pagination required unless needed for bounded performance; cap the public list to a documented safe maximum or paginate without revealing hidden totals. Prefer bounded pagination if collections can grow.

## Public item image
Add a public image route bound to BOTH public profile ref and item public ref, e.g.
`GET /c/{publicRef}/items/{itemRef}/image`.

It succeeds only if the item currently passes the SAME public-item eligibility predicate used by the public collection query:
- profile resolvable/published/active;
- preference visible;
- current owner = profile collector;
- non-adverse registry;
- image exists.

Then stream bytes from existing catalog storage.
- raw path never emitted;
- `X-Content-Type-Options: nosniff`;
- `Cache-Control: no-store` because transfer/unpublish/adverse transition must revoke immediately;
- missing/hidden/non-owner/transferred/adverse/no-image/unknown refs → same ordinary 404;
- do not reuse the private collector-auth image URL in public HTML.

## CP-3 unpublish / pseudonymization
Unpublishing the profile may leave per-item preferences stored, but the entire public collection/image surface must immediately 404/vanish because public reads require CP-3 publication.

Republishing the profile MAY restore previously selected item visibility only if the collector still currently owns the item and it is non-adverse. This is acceptable because profile unpublish is a profile-level switch, not an ownership/status revocation.

Pseudonymization already refuses while collector owns items. If privacy eventually succeeds with no owned items, delete any remaining CP-4 visibility rows for that collector in the SAME privacy transaction as publication/profile deletion. Presentation state must not survive anonymization.

## Service architecture
Create a dedicated CP-4 service as sole writer/resolver for public item visibility.

Centralize one public-item eligibility query/predicate used by:
- public collection cards;
- public image resolver;
- private visibility-state display where appropriate.

Do not duplicate eligibility logic across controller/view methods.

Keep DTO allowlisted and path/id free.

Avoid N+1:
- public profile collection should be bounded aggregate/list query;
- image presence only in DTO;
- image bytes separate route;
- no per-card ownership/cert/status queries.

## Mandatory tests
At minimum prove:

1. current ownership alone never makes item public;
2. published CP-3 profile alone never makes item public;
3. explicit visible preference + published profile + current ownership + non-adverse => item appears;
4. private control is authenticated self-only and payload cannot retarget collector/item;
5. cannot publish item not currently owned;
6. cannot publish while CP-3 profile unpublished/non-resolvable/account non-active;
7. first publish creates one preference; replay idempotent; unpublish idempotent;
8. public HTML allowlist: no email/account ref/internal ids/raw paths/SKU/condition if omitted/ownership dates/history/service/docs/tokens/staff/Shopify/hidden totals;
9. public image succeeds only for same eligible visible item and has correct MIME/nosniff/no-store;
10. hidden/non-owner/unknown/adverse/transferred/no-image image cases are indistinguishable 404;
11. accepted transfer A→B: A item + image disappear immediately; A preference reset private; B does not inherit visibility;
12. A→B→A reacquisition: A remains private until explicit new opt-in;
13. staff/admin ownership correction away from A also immediately removes/reset visibility;
14. entering EACH relevant adverse path (at least collector lost/stolen and staff/system disputed/retired/invalidated as feasible) suppresses item + image and resets visibility;
15. recovery/normalization does not auto-republish; explicit opt-in required again;
16. CP-3 profile unpublish closes collection/images immediately; republish may restore still-safe selected items;
17. pseudonymization cleanup deletes stale CP-4 rows when privacy succeeds; owning-item privacy rejection leaves state intact;
18. real concurrency/race proof: visibility publish racing ownership transfer cannot leave publicly resolvable old-owner item after transfer commits;
19. race: visibility publish racing adverse status cannot leave publicly resolvable item after adverse commit;
20. public collection query is bounded/no N+1 and hidden items do not affect exposed totals/counts;
21. Passport remains collector-identity-free and gains no profile/item link;
22. My Collection remains private and complete regardless of public visibility;
23. visibility actions/public browsing create zero provenance/domain events except the already-requested ownership/status operation in integration tests;
24. migration uniqueness/FKs/immutability/default-private proven;
25. malformed/unknown profile/item refs fail closed.

Run focused CP-4 tests, CP-3 public-profile/concurrency tests, CP-2 My Collection tests, transfer/status/privacy/Passport regressions, and full `tests/Feature/Sca`. Report exact counts/skips.

## Production edge
Current Caddy already admits `/c/*`, so the nested CP-4 public image route is within the existing namespace. No Caddy/DNS change should be required. Prove route reachability in deployment later; do not modify edge config in this implementation slice.

## Forbidden / out of scope
- NO automatic publish-all;
- NO public item detail page;
- NO public Passport links from collector profile;
- NO public search/directory;
- NO public handles/slugs (CP-5);
- NO custom collections/tags/favorites (CP-6);
- NO social/follow/comment;
- NO marketplace/resale/valuation;
- NO ownership/provenance redesign;
- NO Stripe/SMTP/Shopify/Caddy/DNS work;
- NO CP-5+;
- NO production deployment.

## Handoff
Create a NEW CP-4 branch from exact `3e707582c21e40b97e909c8593987787fd4c33c4`.
Implement the complete bounded slice, expected migration 132→133.
Audit every canonical ownership/status writer before wiring revocation/reset; document coverage.
Run all required tests and full SCA gate.
Push candidate and report:
- branch/base/head;
- changed files;
- migration;
- ownership/status integration points;
- public/private routes;
- focused/full test counts;
- production untouched at `3e70758`, migration 132;
- provenance fingerprint/counts unchanged;
- publication/private-profile counts;
- Stripe dormant/mail log.

Then STOP for ChatGPT pre-merge audit.
Do not merge/deploy or start CP-5.

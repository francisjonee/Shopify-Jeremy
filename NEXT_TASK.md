# NEXT TASK

**STATUS: SCA MARKET REFERENCE / VALUE HISTORY — SLICE 1 CANDIDATE PUSHED, AWAITING ChatGPT PRE-MERGE AUDIT. Branch `feat/sca-market-reference`, base `b4b51b7`/migration 137, candidate SHA `26a572a4c60e8a0820de24ca62582df38389a6c9`, migration 137→138 (one commit ahead, 17 files). Append-only advisory NON-provenance Market Reference ledger (record/supersede/void; integer minor-unit range; USD/PHP; basis enum; as-of; deterministic one-current fold; item-state lock + optimistic STALE; dedicated ACL sca.eyewear.market_reference.manage; staff + current-owner only; public Passport/profile/collection/cert/QR excluded). Focused 27 passed (incl. real two-connection proof); full `tests/Feature/Sca` 1312 passed / 1 skipped / 0 failed. Prod untouched: FP `d15a5cbd`, counts `3/3/4/4/5/2/1/1/7`, migration 137, market_reference table absent. Evidence: `docs/SCA-MARKET-REFERENCE-SLICE1-IMPLEMENTATION.md`. DO NOT merge/deploy/begin automated pricing/public value/resale/another initiative — STOP for pre-merge audit.**

<!-- Promotion spec for Slice 1 (implemented by candidate 26a572a) retained below. -->
### Promoted: SCA MARKET REFERENCE / VALUE HISTORY — SLICE 1 (base b4b51b7 / migration 137)

## Architecture audit conclusion
Production currently has **no valuation / appraisal / market-price subsystem**. Existing boundaries already establish the correct placement:
- identity metadata belongs to `sca_eyewear_items` plus governed metadata-correction evidence;
- certification snapshots freeze certificate render facts and must remain valuation-neutral;
- My Collection membership derives only from canonical current ownership;
- public Passport uses an explicit privacy allowlist;
- presentation/catalog state is deliberately separate from provenance.

Therefore market/value information MUST be a separate append-only, non-provenance domain. Do **not** add mutable `estimated_value` columns to `sca_eyewear_items`; do not derive value from certification/authentication; do not mutate certificate PDF/snapshots; do not treat value as proof of authenticity, ownership, title, or guaranteed sale price.

### Product policy for Slice 1
Name the feature **Market Reference** (not “official appraisal” and not “AI valuation”).

A Market Reference is a dated staff-curated estimate/reference for one eyewear item. It may be based on documented market observations/comparables or another staff-entered basis, but SCA does not guarantee a future sale price.

**Slice 1 visibility:** staff + CURRENT canonical owner only. **No public Passport exposure, no CP-3/CP-4 public profile exposure, no certificate/PDF exposure, no marketplace/resale integration.** Public exposure is a later separately audited decision.

### Core invariant
**Market Reference is advisory non-provenance evidence. Recording, superseding, correcting, or voiding a Market Reference MUST NOT mutate item identity, authentication, certification/snapshot/PDF, QR, ownership, claim/transfer, registry status, service history, Shopify sale links, collector account state, or `sca_item_current_state`.**

## Required Slice 1 model
Expected migration: **137→138**.

Create one dedicated append-only ledger, e.g. `sca_market_reference_events`. Do not create a mutable current-value column/table that becomes a second authority.

Each immutable event is bound to exactly one eyewear item and represents one of:
- `record` — a new market-reference observation;
- `supersede` — a new observation replacing the previously-current observation while preserving all history;
- `void` — terminally removes an erroneous current observation from effective display without deleting it.

Do not implement in-place UPDATE/DELETE. DB triggers must block UPDATE/DELETE.

### Market Reference fields
For a record/supersede, store bounded structured data:
- `currency` — ISO-style 3-letter uppercase code; Slice 1 allowlist at minimum USD and PHP. Prefer a small explicit application/DB allowlist rather than arbitrary text.
- `low_amount_minor` — non-negative integer minor units.
- `high_amount_minor` — non-negative integer minor units; MUST be >= low.
- `as_of_date` — date of the market observation, not future beyond a small clock-tolerance policy.
- `basis` — bounded enum. Use a conservative allowlist such as `comparable_sales`, `market_observation`, `documented_appraisal`, `other`.
- `source_summary` — bounded staff-entered explanation of evidence/basis. Required for record/supersede.
- optional `source_reference` — bounded human-readable citation/reference. Do not fetch arbitrary URLs, scrape providers, or call external pricing APIs in Slice 1.
- `reason` — required for supersede/void, explaining why the prior effective observation is being replaced/voided.
- `actor_staff_ref` — server-derived only.
- immutable `created_at`.
- explicit predecessor linkage for supersede/void (e.g. `supersedes_event_id` / `voids_event_id`) bound to the same item.

Do not store floats/decimals as the authoritative amount. Use integer minor units. Validate reasonable upper bounds to prevent overflow/nonsense.

### Effective-history semantics
Implement ONE canonical MarketReferenceService as sole writer + canonical reader.
- deterministic order by `(created_at,id)`;
- at most one effective current reference per item;
- first event must be `record`;
- `supersede` must target the current effective event and atomically makes the new observation current;
- `void` must target the current effective event and leaves no current reference;
- no supersede/void of a historical/non-current target;
- after void, a later fresh `record` MAY start a new reference chain; history remains auditable;
- duplicate/replay/stale submissions fail closed and do not create ambiguous current state.

Use the established item serialization boundary: lock `sca_item_current_state` FOR UPDATE, resolve item and current reference under lock, and use an optimistic freshness token (event count or exact current event identity) from the staff confirmation screen. Concurrent writes must deterministically yield one winner and one STALE/rejection, not two currents.

DB integrity must enforce same-item predecessor linkage and append-only behavior. Prefer CHECKs/triggers so malformed raw rows cannot create impossible event types/ranges/currency/binding.

### Staff workflow
Add a dedicated ACL, e.g. `sca.eyewear.market_reference.manage`, separate from ordinary item view/catalog/metadata permissions.

On staff item detail:
- show current Market Reference, if any;
- show full chronological audit history;
- show currency + low/high range + as-of date + basis + source summary/reference;
- show actor/time/reason for supersede/void;
- provide explicit Record / Supersede / Void controls only to the dedicated ACL;
- no generic edit/delete UI;
- POST mutation must be staff-authenticated, CSRF-protected and reasonably throttled;
- target item/event IDs resolved/revalidated server-side; no client-supplied actor.

Use clear language: **“Market Reference”** and a short disclaimer such as “Informational estimate based on recorded market evidence; not a guarantee of sale price.” Do not label ordinary records “appraisals.” `documented_appraisal` basis may be displayed as “Documented appraisal” only when staff explicitly selected that basis.

### Collector workflow
Current canonical owner may see the **effective current Market Reference** on the private My Collection item detail:
- range, currency, as-of date, basis, and a safe source summary;
- clear informational/non-guarantee wording;
- optional safe history of prior reference ranges/dates may be included if it contains no staff/internal audit data.

Collector MUST NOT receive:
- actor/staff refs;
- correction/void reasons;
- internal DB ids/predecessor ids;
- other collectors;
- Shopify data;
- raw security tokens;
- staff-only source details if a separate staff-only source field is used.

Previous owner/non-owner/unauthenticated user gets no Market Reference through collector routes.

### Public/privacy boundary
Slice 1 MUST leave unchanged:
- public Passport;
- public collector profile / public collection;
- certificate PDF;
- QR payload/resolution.

Add explicit regression tests proving market value text/amounts do not appear on those public surfaces.

### No automatic pricing in Slice 1
Do NOT:
- call AI to invent a value;
- scrape marketplaces;
- integrate eBay/StockX/other providers;
- infer price from brand/model alone;
- copy Shopify order price into Market Reference automatically;
- compute value from authentication grade as an authoritative formula.

Those require a later data-source/reliability architecture audit.

## Fail-closed requirements
- missing/wrong item or predecessor → zero write;
- invalid/stale current reference token → STALE/zero write;
- invalid currency/range/date/basis/text → zero write;
- low > high → zero write;
- negative/overflow amount → zero write;
- supersede/void non-current historical event → zero write;
- first event supersede/void → zero write;
- exact duplicate/no-op supersede → NOOP/zero write;
- DB failure → no partial rows;
- direct UPDATE/DELETE blocked;
- cross-item predecessor binding blocked at DB boundary;
- zero mutation of all provenance/current-state domains.

## Mandatory tests
1. first record creates one immutable reference and becomes current.
2. record validates integer minor units and renders currency correctly.
3. low > high, negative, overflow, bad currency/basis/date/text fail closed.
4. supersede appends new evidence; original byte-identical; new reference current.
5. supersede chronology deterministic and predecessor exact.
6. exact duplicate/no-op supersede rejected.
7. void current reference appends evidence and removes effective current display; original/history retained.
8. cannot supersede/void historical non-current target.
9. after void, fresh record can start a new chain without rewriting history.
10. wrong-item/cross-item predecessor rejected in service AND DB.
11. optimistic stale token rejects concurrent second writer with zero partial state.
12. real two-connection concurrency proof using production service.
13. actor is server-derived/authenticated staff.
14. dedicated ACL: view-only/catalog/metadata staff cannot mutate market references.
15. staff history shows actor/time/reason and full evidence.
16. current owner sees safe current reference; previous/non-owner/unauth denied.
17. collector output leaks no staff refs/reasons/internal ids/security/Shopify data.
18. public Passport contains no market reference/value.
19. public profile/public collection contain no market reference/value.
20. certificate PDF/snapshot and QR remain unchanged.
21. DB UPDATE/DELETE ledger rows blocked.
22. malformed raw rows / cross-item predecessor / impossible disposition-range combinations blocked at DB boundary.
23. zero mutation of ownership/current-state/auth/cert/QR/status/claim/transfer/service/Shopify; reproduce provenance fingerprint/count gate.
24. existing metadata, certification, collector, passport, service-history tests remain green.
25. full `tests/Feature/Sca` green.

## Delivery contract
- NEW branch from exact production `b4b51b7bb0244da6e1624c1095239c80cc206bb9`.
- Expected migration 137→138.
- One substantial implementation slice; do not split into microtasks unless a real architecture blocker is discovered.
- Add focused Market Reference + real concurrency tests.
- Run relevant regressions + full `tests/Feature/Sca`.
- Produce governance implementation evidence mapping schema, event semantics, DB constraints/triggers, ACL/routes, concurrency, staff/collector/public privacy, tests and zero-provenance proof.
- Push candidate + governance evidence.
- **DO NOT merge. DO NOT deploy. DO NOT begin automated pricing, public value exposure, resale/marketplace, or another initiative.**
- STOP for ChatGPT pre-merge audit.

<!-- Prior status (pre-merge PASS gate for candidate 2d578feb) retained below for traceability. -->

### ChatGPT pre-merge audit verdict
**PASS.** Actual GitHub candidate `2d578feb5f429d9e7549d968c21fbfc879ba0885` satisfies the promoted Service History Correction & Annotation architecture after R1/R2 remediation.

Verified:
- exactly 1 commit ahead / 0 behind production base `9bc0907...`
- scoped 15-file slice; no unrelated initiative
- migration 136→137 creates dedicated append-only `sca_service_event_corrections`
- original `sca_service_events` remains immutable and untouched
- sparse factual evidence uses explicit per-field change flags
- nullable notes/grade support unambiguous explicit clear via flag=1 + NULL
- non-nullable service_type/occurred_at require a value when flagged
- DB CHECKs now enforce sparse-row self-consistency; contradictory raw rows fail closed
- non-correct rows cannot carry corrected factual payload
- DB cross-item trigger + service exact item/event binding prevent rebinding
- correction ledger UPDATE/DELETE blocked
- deterministic fold applies only flagged fields in `(created_at,id)` order
- selected-but-equal values are omitted; all-NOOP rejects
- staff chronology renders exact changed fields old→new plus actor/time/reason
- item current-state `FOR UPDATE` serialization + correction-count token provide STALE protection
- real two-connection concurrency proof remains present
- terminal void behavior preserved
- dedicated `sca.eyewear.service.correct` ACL, admin auth/CSRF/throttle boundary preserved
- collector path is a privacy projection over the same canonical fold; voided events and staff-only audit data excluded
- public passport remains service-free
- `ServiceService::record()` and `ProjectionService::rebuild()` unchanged
- zero intended ownership/current-state/authentication/certification/QR/status/claim/transfer/Shopify mutation
- R2 raw-DB tests prove unflagged payload rejection, required flagged values, and valid nullable clears
- explicit condition-grade clear-to-NULL is proven through production controller/service
- reported focused result: 42 passed
- reported full SCA result: 1285 passed / 1 skipped / 0 failed.

### Controlled merge/deployment gate
Claude may now merge/deploy **only this exact approved candidate** `2d578feb5f429d9e7549d968c21fbfc879ba0885`.

Before merge/deploy:
1. Reconfirm production/main baseline is still `9bc0907c486688c7acd0d22ad2ee9f5db37d93bb`; if main/production moved, STOP for ChatGPT.
2. Reconfirm approved candidate is exactly 1 ahead / 0 behind baseline and candidate tree is unchanged.
3. Merge with a normal auditable merge commit; after merge, prove candidate→merge tree has **zero changed files**. Any content drift = STOP.
4. Run the exact merge tree full `tests/Feature/Sca` gate before production migration. Known unrelated low-ID document-classification flake may be rerun only under the established policy; any real failure = STOP before migrate.
5. Capture PRE production migration number, provenance fingerprint/counts, service-event count, and confirm correction table absent.
6. Apply migration 137 once. Verify table, all CHECK constraints, append-only triggers, cross-item trigger and indexes exist.
7. Run production-safe health/boundary smoke only; do not fabricate or mutate real service/correction evidence merely to demonstrate the feature.
8. Capture POST provenance fingerprint/counts and service-event count; they must be byte/count identical to PRE. New correction table should contain 0 rows immediately after deploy unless a real authorized staff action occurs independently.
9. Confirm no Caddy/DNS/Shopify OAuth/Stripe/SMTP changes; Stripe remains dormant and mail remains current production configuration.
10. Record exact merge SHA, main SHA, deployed SHA, migration 137, exact merge-tree test result, schema evidence, PRE/POST invariants and health/boundary results in a governance deployment evidence document.

**STOP after deployment evidence. Do not declare the initiative closed. Do not start another initiative. Return to ChatGPT for independent post-deployment audit.**

Updated 2026-10-13.

## Why this is next
Shopify Reconciliation & Operations is CLOSED. ChatGPT audited the live service-history architecture at production `9bc0907`.

The existing service-history foundation is intentionally strong and must be preserved:
- `sca_service_events` is append-only and storage-immutable.
- service recording is staff-only and session-attributed.
- service type and condition observations are validated.
- service events never rewrite authentication grade, certification, ownership, registry status, QR identity, or lifecycle.
- the current owner sees owner-safe service history; non-owners fail closed.
- public Passport does not expose service notes/staff data.

The operational integrity gap is correction: if staff records the wrong service type/date/condition/notes, there is currently no governed way to correct the record. Editing/deleting the immutable event is forbidden and must remain forbidden.

## Initiative
**SCA Service-History Correction & Annotation**

Build an append-only correction/annotation layer over immutable service events.

### Core invariant
**A recorded service event is permanent historical evidence. Correction never edits or deletes it. A correction appends new evidence that explicitly supersedes/corrects presentation of the target event while preserving the original forever. Service-history correction must never mutate ownership, authentication, certification, QR, registry status, claim, Shopify state, or any other provenance domain.**

### Architecture requirements
1. Preserve the existing `sca_service_events` rows and immutability trigger unchanged. No UPDATE/DELETE escape hatch.
2. Add a dedicated append-only service-history correction/annotation ledger, preferably migration **136→137**.
3. Corrections target one exact existing service event and exact eyewear item. The target relationship must be server-validated; cross-item correction must fail closed.
4. Do NOT create a replacement `sca_service_events` row pretending the corrected facts were another real service occurrence. Keep the original service occurrence immutable and attach correction evidence to it.
5. Support a bounded correction snapshot for the displayable service facts:
   - service type
   - occurred_at
   - condition_grade_after
   - notes
   A correction should carry the effective corrected values plus mandatory reason, actor staff ref, and created_at.
6. Prefer **full corrected snapshot per correction row** rather than one row per changed field, because service history is one coherent historical occurrence and reads need deterministic latest-effective presentation.
7. Corrections themselves are append-only. If a correction is wrong, append another correction against the same original service event. Latest valid correction wins for effective presentation; the entire correction chain remains auditable.
8. Add storage-level immutability for correction rows (UPDATE/DELETE rejected).
9. Add storage-level same-item integrity where practical: correction.eyewear_item_id must match the target service event's eyewear_item_id. If MariaDB CHECK cannot enforce cross-table identity, use a BEFORE INSERT trigger plus service validation.
10. Add a dedicated mutation ACL, e.g. `sca.eyewear.service.correct`, separate from ordinary `sca.eyewear.service` recording and `sca.eyewear.view`.
11. Staff correction must use a GET confirmation/review interstitial + POST mutation. The target event must be server-resolved; never accept staff id, item id, or prior values from the client as authoritative evidence.
12. Require a nonblank correction reason, bounded length. Normalize corrected notes safely and preserve nullable semantics.
13. The correction screen must show the immutable original event and the current effective presentation so staff understands what is being corrected.
14. Use optimistic concurrency. The POST must prove the correction chain is still the one the staff reviewed. Prefer expected correction-count or latest-correction opaque/version token; re-check under lock. A concurrent correction must produce safe STALE rejection, never last-write-wins silently.
15. Transaction lock order: lock the canonical item/current-state row first, then resolve/lock the target service event/correction chain as needed. Keep consistent with other SCA correction workflows.
16. Reject a semantic no-op: if submitted effective values equal the current effective presentation, no correction row is appended.
17. Existing service recording remains unchanged and may continue after a corrected historical event.
18. Owner-facing My Collection service history must show the **effective corrected presentation**, not stale original values, while preserving privacy. It may show a simple non-sensitive “Corrected” indicator/date, but must not expose correction reason, staff identity, internal ids, or correction-chain metadata.
19. Staff item detail should show effective service history and a correction affordance to authorized staff. Staff audit view may show original + correction history/reasons/actor refs as appropriate behind staff ACL.
20. Public Passport remains unchanged: no service notes/corrections/reasons/staff data become public.
21. Transfer behavior: service history follows the item as it does today. The new current owner sees effective corrected service history; former owner loses access under existing ownership authorization.
22. Correction does NOT change `condition_grade_after` into an authentication grade or current condition projection. It remains a historical observation only.
23. No hard delete. No “undo” by deleting correction rows. Re-correction is another append.
24. No collector/public mutation route. No Caddy/DNS/edge change.
25. No SMTP/Stripe/Shopify/OAuth changes.

## Suggested schema
Prefer a table such as `sca_service_event_corrections`:
- id BIGINT
- service_event_id FK → `sca_service_events.id` RESTRICT
- eyewear_item_id FK → `sca_eyewear_items.id` RESTRICT
- corrected_service_type VARCHAR(24)
- corrected_condition_grade_after nullable VARCHAR(8)
- corrected_notes nullable TEXT
- corrected_occurred_at timestamp/date consistent with canonical event semantics
- reason bounded text/string
- actor_staff_ref nullable/soft ref
- created_at
Indexes:
- (service_event_id, id)
- (eyewear_item_id, service_event_id, id)
Immutability trigger: reject UPDATE/DELETE.
Insert integrity trigger: target event must exist and belong to eyewear_item_id.
Canonical type/grade constraints should mirror `ServiceService::TYPES/GRADES`.

Do not copy unrelated provenance/current-state data.

## Effective read rule
For each original service event:
- if no correction exists → render original values;
- if corrections exist → render the latest correction row's corrected snapshot;
- original event identity/occurrence remains canonical historical anchor.

Implement the effective read in one domain/read service and reuse it for staff + collector presentation. Avoid duplicate “latest correction” logic in controllers/views.

Queries must be bounded and avoid N+1. Service history per item is expected to be modest, but use a deterministic join/subquery/window/latest-id strategy rather than issuing one correction query per event.

## Staff UX
From item service history:
- existing “Record service” remains.
- authorized staff see “Correct” per service event.
- GET correction screen shows item opaque ref, immutable original, current effective values, prior correction count/history, and mandatory warning that original evidence will remain.
- POST submits corrected snapshot + reason + optimistic concurrency token.
- success returns to item detail with clear “correction appended” message.
- stale/no-op/not-found/cross-item failures are safe and generic; no raw SQL/internal details.

## Mandatory tests
At minimum prove:
1. Original `sca_service_events` row remains byte-identical after correction.
2. Correction appends exactly one immutable correction row.
3. UPDATE and DELETE on correction row fail at DB layer.
4. Direct cross-item correction insert fails at DB layer.
5. invalid corrected service type fails validation + DB constraint.
6. invalid corrected condition grade fails validation + DB constraint.
7. performer/actor is derived from authenticated staff; client spoof ignored.
8. correction requires dedicated ACL; ordinary service-record permission alone cannot correct.
9. GET correction interstitial is read-only and CSRF-safe POST performs mutation.
10. missing item/event and cross-item target fail closed.
11. reason required/bounded.
12. no-op correction rejected with zero new row.
13. first correction changes effective presentation while original stays unchanged.
14. second correction supersedes first for effective presentation; both correction rows remain immutable/auditable.
15. optimistic concurrency: two staff review same chain; first commits; second gets STALE and appends nothing.
16. real two-connection concurrency proof if practical: overlapping corrections cannot both silently win.
17. correction changes zero ownership/current-state/authentication/certification/QR/status/claim/grant/Shopify rows.
18. corrected condition remains observation only; authentication grade unchanged.
19. current owner My Collection sees corrected type/date/condition/notes.
20. owner view leaks no reason/staff/internal/correction ids.
21. former owner loses service history after transfer; new owner sees effective corrected history.
22. public Passport still exposes no service notes/correction/reason/staff data.
23. staff item detail uses effective values and authorized correction link.
24. staff audit view/history can distinguish original and corrections without editing them.
25. service-history reads use bounded queries/no N+1.
26. existing ordinary service-recording tests remain green.
27. existing ownership/transfer/collector/privacy/passport/auth/cert/status/Shopify suites remain green.
28. full `tests/Feature/Sca` green.
29. established 13-table provenance fingerprint procedure remains unchanged by deployment; note that service-event/correction tables are outside that historical fingerprint, so additionally record PRE/POST service-event counts and correction counts at deploy.

## Audit/deployment discipline
- NEW branch from exact production `9bc0907c486688c7acd0d22ad2ee9f5db37d93bb`.
- Expected migration 136→137.
- Do not alter existing service-event immutability.
- Do not touch Caddy/DNS/SMTP/Stripe/Shopify/OAuth.
- Do not merge/deploy.
- Push candidate + governance implementation evidence.
- STOP for ChatGPT pre-merge audit.

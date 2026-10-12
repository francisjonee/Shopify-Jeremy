# NEXT TASK

**STATUS: SERVICE HISTORY CORRECTION & ANNOTATION — CANDIDATE PUSHED, AWAITING ChatGPT PRE-MERGE AUDIT. Branch `feat/sca-service-correction`, base `9bc0907` (migration 136), candidate SHA `18aba7c8f464e1ac384561648698373444d07c88`, migration 136→137. Focused 31 passed; full `tests/Feature/Sca` 1274 passed / 1 skipped / 0 real failures (d9 low-ID flake passes isolated). Prod untouched: FP `d15a5cbd`, counts `3/3/4/4/5/2/1/1/7`, migration 136, no correction table. Evidence: `docs/SCA-SERVICE-CORRECTION-IMPLEMENTATION.md`. DO NOT merge/deploy — STOP for pre-merge audit.**

_Original promotion spec (implemented by candidate `18aba7c`) follows unchanged:_

### Architecture audit finding
Production already has SCA-SERVICE-015. `ServiceService` appends immutable `sca_service_events`; canonical service types are repair/lens/polish/tuneup/inspection/other and optional observed condition A-D; performer is server-derived staff; service events do not mutate ownership/current-state/certification/authentication/lifecycle. DB immutability protects existing rows. Staff registry shows history and has append-only record-service flow; current collector owners receive an owner-safe service DTO; public passport intentionally exposes no service data. Existing correction patterns (ownership, certification, item metadata) consistently use append-only evidence, item locking/optimistic freshness, safe rejection codes, staff attribution, and never rewrite prior evidence.

### Initiative
**SCA Service History Correction & Annotation**

### Core invariant
**A recorded service event is permanent evidence. Correction must NEVER UPDATE or DELETE `sca_service_events`. Corrections/annotations are new immutable evidence layered over the original event. The original values remain auditable forever. Service correction must never mutate ownership, current-state projection, authentication grade/result, certification/QR, registry status, claim/transfer, Shopify sale links, collector account state, or any other provenance ledger.**

### Required model
1. Add one dedicated append-only service-correction/annotation ledger; expected migration **136→137**. Do not create a second service-event table or copy history.
2. Each correction row must bind to exactly one existing `sca_service_events` row and therefore exactly one item. FK/item consistency must be enforced in service/domain code and, where practical, DB constraints/triggers.
3. Support two explicit staff operations:
   - **correct**: replace the *effective display values* of a service event for factual mistakes in service_type, condition_grade_after, notes, and/or occurred_at. Original event remains byte-unchanged.
   - **annotate**: append a staff note that supplements the event without replacing factual fields.
4. Support **void/entered-in-error** as an explicit correction disposition for a wholly erroneous service record. It hides the event from ordinary collector-effective history but NEVER deletes it; staff audit must still show the original + void evidence. Do NOT implement moving/rebinding an event to another item. If an event was recorded against the wrong item, staff voids it and separately records a new correct event through the existing SCA-SERVICE-015 flow.
5. Effective service history is a deterministic fold: original event + ordered correction evidence. Define ordering explicitly (created_at,id). Latest valid factual correction wins for supplied corrected fields; annotations accumulate; void is terminal for ordinary effective display and cannot be silently “unvoided.” Do not overwrite prior correction rows.
6. Prefer sparse correction semantics: only actually corrected fields are supplied/stored as correction values; unchanged fields remain inherited from the prior effective state. Reject a factual correction that changes nothing.
7. A correction/annotation must carry a required bounded reason/annotation text and server-derived staff actor. Never accept actor id from request.
8. Add append-only DB immutability for the new ledger (UPDATE/DELETE blocked), consistent with existing provenance/event tables.
9. Concurrency: correction mutation runs in one transaction, locks the item's canonical current-state row (or another established item serialization row), resolves the target event under that lock, and validates an optimistic freshness token for the target correction stream. A concurrent correction/void must cause STALE rather than silently reorder staff intent.
10. Target binding must be exact. The controller must resolve the service event as belonging to the route item; no cross-item correction and no request-supplied item rebinding.
11. Reuse canonical `ServiceService::TYPES` and `GRADES`; do not invent divergent type/grade validation.
12. Do not call `ProjectionService::rebuild()` for service correction. Service history remains orthogonal to current-state projection.
13. Existing `ServiceService::record()` behavior stays intact; no weakening of SCA-SERVICE-015.
14. Build one canonical effective-history reader/service and use it for BOTH staff display and collector owner-safe history. Do not duplicate correction-fold logic in controllers/views/Collector CollectionService.
15. Staff view must clearly distinguish:
   - original recorded event,
   - current effective values,
   - correction chronology with actor/time/reason,
   - annotations,
   - entered-in-error/void state.
   Staff may see staff attribution; no edit/delete controls for historical rows.
16. Collector view remains privacy-safe: current owner only; show effective non-void service events and safe annotations only if policy explicitly marks them collector-visible. Default annotations should be **staff-only** unless the implementation introduces an explicit safe visibility flag with tests. Never expose staff ids, correction reasons, internal ids, or voided erroneous event content to collector.
17. Public passport remains unchanged: no service history/correction/annotation data.
18. Add a dedicated mutation ACL such as `sca.eyewear.service.correct`, separate from existing `sca.eyewear.service` record permission. View-only/record-only staff cannot correct/void/annotate.
19. CSRF + existing staff auth boundary required. Add reasonable mutation throttling if consistent with current admin mutation surfaces.
20. No Krayin core edits; no Caddy/DNS/Shopify/Stripe/SMTP changes.

### Required fail-closed behavior
- missing item/event or event not belonging to item → safe 404/rejection, zero write
- stale correction-stream token → STALE, zero write
- invalid type/grade/date/text → validation rejection, zero write
- factual no-op → NOOP, zero write
- correction/annotation after terminal void → reject (except read-only audit)
- duplicate/replayed submit must not create ambiguous effective state; use the established confirmation/idempotency pattern appropriate to this admin surface
- any DB failure → zero partial correction rows
- original `sca_service_events` row remains byte-identical under every success/failure path

### Mandatory tests
1. factual correction appends correction evidence; original service row byte-identical; effective staff history shows corrected values.
2. sparse correction inherits unchanged original/prior-effective fields.
3. second correction deterministically folds over first; chronology retained.
4. annotation appends without changing effective factual values.
5. void marks event entered-in-error without deleting/updating original; collector ordinary history excludes it; staff audit retains it.
6. no unvoid / no correction-or-annotation after terminal void.
7. wrong-item target fails closed.
8. stale concurrent correction token fails with zero write.
9. no-op factual correction rejected.
10. invalid type/grade/date and oversized text fail safely.
11. actor is authenticated staff, not spoofable request input.
12. separate correction ACL enforced; record-only/view-only cannot mutate correction ledger.
13. collector current-owner sees only effective non-void safe service history; previous owner/non-owner denied exactly as today; no staff/internal/correction-reason leak.
14. public passport remains service-free.
15. zero mutation of ownership/current-state/authentication/certification/QR/status/claim/transfer/Shopify provenance tables; reproduce the established provenance fingerprint/count gate around focused correction operations.
16. DB UPDATE/DELETE against original service event remains blocked; UPDATE/DELETE against correction ledger also blocked.
17. existing SCA-SERVICE-015 record-service tests remain green.
18. full `tests/Feature/Sca` green.

### Delivery
Implement this as one substantial slice on a NEW branch from exact production `9bc0907c486688c7acd0d22ad2ee9f5db37d93bb`. Expected migration 136→137 if the architecture holds. Run focused service/correction/collector/passport tests plus the full SCA suite. Produce a governance implementation report mapping requirements/tests and documenting schema, fold semantics, ACL/routes, concurrency token, privacy, and zero-provenance proof. Push candidate + governance evidence. **DO NOT merge or deploy. STOP for ChatGPT pre-merge audit.**

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

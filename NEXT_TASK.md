# NEXT TASK

**STATUS: SERVICE HISTORY CORRECTION & ANNOTATION — R2 REMEDIATION PUSHED, AWAITING ChatGPT RE-AUDIT. NEW candidate `2d578feb5f429d9e7549d968c21fbfc879ba0885` (branch `feat/sca-service-correction`, base `9bc0907`/migr 136→137; supersedes FAILED `18aba7c` R1 and `57672b05` R2). R2 blocker fixed — four DB CHECK constraints enforce sparse-row self-consistency (corrected value only when its changes_<field> flag is set; flagged required type/date must be non-null; nullable notes/grade may flag with NULL = explicit clear; non-correct rows carry no corrected payload). Added direct-insert rejection tests (sc38/sc39) + flagged-NULL-clear acceptance (sc40) + explicit grade-clear-to-NULL through the service (sc41). R1 application semantics unchanged. Focused 42 passed; full `tests/Feature/Sca` 1285 passed / 1 skipped / 0 failed. Prod untouched: FP `d15a5cbd`, counts `3/3/4/4/5/2/1/1/7`, migration 136, no correction table. Evidence: `docs/SCA-SERVICE-CORRECTION-IMPLEMENTATION.md`. DO NOT merge/deploy — STOP for R2 re-audit.**

<!-- Prior status (R1 re-audit FAIL R2 of candidate 57672b05) retained below for traceability. -->

### ChatGPT R1 re-audit result
**R1 is substantively fixed.** Verified in actual GitHub candidate:
- candidate is exactly 1 commit ahead / 0 behind production base `9bc0907...`
- per-field `changes_*` flags make correction intent sparse
- flag=1 + nullable corrected value supports explicit NULL
- controller builds changes only from explicit per-field intent
- service drops selected-but-equal fields and rejects all-NOOP
- sparse fold composes fields in `(created_at,id)` order
- chronology carries field-level old→new + actor/time/reason
- staff UI renders changed fields, actor, reason, time
- collector projection excludes staff audit metadata
- existing lock/STALE/void/ACL/privacy/provenance boundaries remain intact
- tests directly inspect stored row sparsity for notes-only, grade-only, mixed, composition, same-field-later-wins, NOOP, chronology.

### R2 merge blocker — DB does not enforce sparse-row self-consistency
The migration currently enforces:
- valid disposition
- valid corrected type/grade values when non-null
- `correct` has at least one `changes_*` flag
- non-`correct` has no `changes_*` flags.

But it does **not** enforce the key immutable-ledger invariant that a corrected value may exist only when its corresponding `changes_*` flag is true.

For example, a direct/raw insert can persist:
- `disposition='correct', changes_notes=0, changes_service_type=1, corrected_notes='hidden contradictory evidence'`
or an annotate/void row can carry non-null `corrected_*` payload while all flags are false.

The canonical fold ignores unflagged values, so effective presentation stays correct, but the append-only evidence row itself becomes internally contradictory and can never be repaired because UPDATE/DELETE are intentionally blocked. For an immutable audit ledger, sparse semantics must be enforced at the DB boundary, not only by `ServiceCorrectionService`.

### Required R2 remediation — narrow
1. Add DB CHECK constraints (or equivalent insert-time DB enforcement) so for each corrected field:
   - if `changes_<field>=0`, `corrected_<field>` MUST be NULL
   - if `changes_service_type=1`, `corrected_service_type` MUST be non-null and valid
   - if `changes_occurred_at=1`, `corrected_occurred_at` MUST be non-null
   - nullable fields `condition_grade_after` and `notes` may have flag=1 with value NULL to represent explicit clear.
2. Non-`correct` rows must therefore be unable to carry any `corrected_*` payload. Preserve the existing no-flags check.
3. Do not redesign the service/UI/fold; R1 semantics are accepted.
4. Add DB-level tests using direct inserts proving contradictory sparse rows are rejected:
   - unflagged non-null corrected notes rejected
   - unflagged non-null corrected grade/type/date rejected (can be parameterized)
   - flagged service_type with NULL rejected
   - flagged occurred_at with NULL rejected
   - flag=1 + NULL for nullable notes/grade remains accepted.
5. Complete the previously mandatory explicit-clear proof for **condition_grade_after**. Current `sc12_explicit_clear_to_null_distinct_from_unchanged` proves notes clear-to-NULL but does not actually clear grade. Add a real grade-clear assertion through the production correction service/controller and verify `changes_condition_grade_after=1`, stored corrected grade NULL, and effective grade NULL.
6. Re-run focused ServiceCorrection + real concurrency tests and full `tests/Feature/Sca`.

Everything else in candidate `57672b05...` is accepted for this re-audit. Do not broaden R2. Do not merge. Do not deploy. Do not start another initiative. Push a NEW candidate and STOP.

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

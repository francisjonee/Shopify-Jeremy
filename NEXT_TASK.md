# NEXT TASK

**STATUS: SCA MARKET REFERENCE / VALUE HISTORY — SLICE 1 PRE-MERGE AUDIT PASS. R1 + R2 CLOSED. Exact approved candidate: `d880e128e0713d60e42a2d821206cf663c09be43`, based on production `b4b51b7bb0244da6e1624c1095239c80cc206bb9` / migration 137. Candidate is approved for controlled merge/deployment ONLY under the gate below. Initiative remains OPEN until ChatGPT independently audits deployed production and records post-deployment PASS.**

## ChatGPT pre-merge audit verdict
**PASS.**

Independent audit of actual GitHub candidate confirms:
- exact production base `b4b51b7bb0244da6e1624c1095239c80cc206bb9`
- candidate exactly 1 commit ahead / 0 behind
- Slice 1 remains scoped to the audited 17 implementation/test files
- expected migration 137→138
- dedicated append-only, non-provenance Market Reference ledger
- record/supersede/void lifecycle
- integer minor-unit range + USD/PHP and basis allowlists
- strict exact calendar-date validation
- immutable UPDATE/DELETE blocking
- same-item predecessor enforcement
- DB lifecycle enforcement against actual current effective event
- DB monotonic append-order enforcement consistent with canonical `(created_at,id)` fold
- equal timestamps valid and deterministically ordered by higher id
- service item-state FOR UPDATE + optimistic token STALE protection
- genuine two-connection production-service concurrency proof
- dedicated ACL/auth/CSRF/throttle + server-derived actor
- staff full audit history
- current-owner-only safe collector projection
- public Passport/profile/collection, certificate snapshot/PDF and QR remain valuation-free
- no automated/AI/external pricing or Shopify-price ingestion
- zero intended provenance/current-state mutation.

R1 and R2 direct proofs are accepted:
- impossible/non-exact dates fail closed; valid leap date accepted; future policy preserved
- raw second-current record rejected
- raw historical predecessor supersede/void rejected
- valid lifecycle rows accepted
- backdated current supersede rejected
- backdated current void rejected
- backdated post-void fresh record rejected
- equal-timestamp successor accepted and proven canonical current
- normal production-service record→supersede→void remains correct.

Reported focused gate: **35 passed**.
Reported full SCA gate: **1320 passed / 1 skipped / 0 failed**.

## Controlled merge/deployment gate
Claude may merge/deploy **only exact approved candidate `d880e128e0713d60e42a2d821206cf663c09be43`**.

1. Reconfirm main/production is still exact baseline `b4b51b7bb0244da6e1624c1095239c80cc206bb9`. If it moved, STOP.
2. Reconfirm candidate is 1 ahead / 0 behind and candidate tree unchanged.
3. Merge with an auditable merge commit. Prove candidate→merge has **zero changed files** / content-identical tree. Any drift = STOP.
4. Run the exact merge-tree full `tests/Feature/Sca` gate before production migration. Any real failure = STOP before migrate. Existing documented unrelated flakes may only be handled under the established fail-before-migrate/rerun policy and must be disclosed.
5. Capture PRE production:
   - migration number 137
   - reproducible provenance fingerprint and canonical counts
   - Market Reference table absent
   - relevant baseline integration/config state.
6. Apply migration 138 once.
7. Verify production schema exactly:
   - `sca_market_reference_events`
   - all CHECK constraints
   - append-only UPDATE/DELETE triggers
   - BEFORE INSERT same-item + lifecycle + monotonic-order trigger
   - self/item FKs and expected indexes.
8. Immediately after deploy, Market Reference ledger must contain **0 rows** unless a real independently authorized staff action occurred. Do not fabricate production Market Reference evidence for smoke testing.
9. Run production-safe route/boundary smoke:
   - app/admin health
   - routes registered
   - unauthenticated mutation fail-closed
   - dedicated ACL/CSRF/throttle already proven by exact merge-tree tests
   - collector/public surfaces remain healthy without creating evidence.
10. Capture POST provenance fingerprint/counts and prove byte/count identity to PRE.
11. Confirm no unexpected changes to service history, ownership/current state, authentication, certification/PDF/snapshot, QR, registry status, claim/transfer, Shopify sale links, collector accounts.
12. Confirm no Caddy/DNS/Shopify OAuth/Stripe/SMTP changes; Stripe remains dormant and mail remains current production configuration.
13. Record exact merge/main/deployed SHA, migration 138, exact merge-tree test results, schema verification, PRE/POST invariants, ledger count, boundary smoke, and integration/config evidence in a governance deployment result document.

**STOP after deployment evidence. Do not declare Slice 1 closed. Do not start automated pricing, public value exposure, resale, or another initiative. Return to ChatGPT for independent post-deployment audit.**

<!-- Prior status (R1 re-audit FAIL R2 of candidate 23c28eb) retained below for traceability. -->

## ChatGPT independent R1 re-audit
Verified actual GitHub candidate:
- exact production base `b4b51b7bb0244da6e1624c1095239c80cc206bb9`
- candidate `23c28ebc78754e82dfc37e082d04ca983dcdc234`
- exactly 1 commit ahead / 0 behind base
- rewritten single candidate commit relative to prior failed SHA is acceptable
- accepted Slice-1 architecture remains intact.

### R1 blocker B — CLOSED
`MarketReferenceService::normAsOfDate()` now:
- requires exact `YYYY-MM-DD`;
- uses strict createFromFormat + exact round-trip;
- rejects impossible/non-exact dates;
- retains future tolerance.

`mr27` directly exercises the production service and proves impossible/non-exact rejection, valid leap date, zero invalid writes, and preserved future rejection.

Do not change this area in R2.

### R1 blocker A — PARTIALLY CLOSED; narrow R2 remains
`trg_mre_bi` now correctly derives the existing stream's current event by `(created_at,id)` and rejects:
- record while a current exists;
- supersede whose predecessor is not the existing current;
- void whose predecessor is not the existing current;
- cross-item predecessors.

The direct-DB tests genuinely prove those normal-order cases.

## R2 blocker — NEW row can be backdated behind the event it supersedes/voids
The canonical fold order is `(created_at,id)`. The BEFORE INSERT trigger validates lifecycle against the stream **before** NEW is inserted, but it does not constrain NEW.created_at relative to the existing last event.

Therefore a raw insert can:
1. have current `e1`;
2. insert a structurally valid `supersede e2 -> e1` with `NEW.created_at < e1.created_at`;
3. pass the trigger because e1 is current before the insert;
4. after insertion, canonical `foldCurrent()` orders e2 before e1, so e1 remains effective even though immutable e2 says it supersedes e1.

The same ordering defect applies to a backdated void. It also allows a fresh record inserted after a void to be backdated before that void, so the trigger accepts it while the fold still ends at the void.

This means the DB still permits immutable lifecycle evidence whose predecessor/action semantics disagree with the canonical fold.

### Required R2 remediation
At the DB insert boundary, guarantee that every newly appended market-reference event sorts after the existing last event for that item under the canonical `(created_at,id)` ordering.

A narrow acceptable implementation is to reject a NEW row whose `created_at` is earlier than the existing last event's `created_at`. Equal timestamps are valid because the auto-increment NEW id sorts after the prior id.

Preserve:
- canonical fold order `(created_at,id)`;
- service-created `now()` timestamps;
- current lifecycle trigger logic;
- append-only semantics;
- all accepted R1 behavior.

Do not redesign the ledger or change the product policy.

### Mandatory R2 direct-DB proof
Add raw DB tests showing:
1. backdated supersede of the actual current event is rejected;
2. backdated void of the actual current event is rejected;
3. after a valid void, a backdated fresh record that would sort before the void is rejected;
4. equal-timestamp valid successor remains accepted and becomes current by higher id;
5. normal service record/supersede/void remains unchanged.

For accepted inserts, assert the canonical `currentReference()` result agrees with the lifecycle action/predecessor.

Re-run focused MarketReference tests including the real two-connection concurrency test and full `tests/Feature/Sca`.

Update `docs/SCA-MARKET-REFERENCE-SLICE1-IMPLEMENTATION.md` with R2 evidence, push a NEW candidate SHA, and STOP.

**DO NOT merge. DO NOT deploy. DO NOT begin another initiative.**

<!-- Prior status (pre-merge FAIL R1 of candidate 26a572a) retained below for traceability. -->

## ChatGPT independent pre-merge audit
Actual GitHub candidate verified:
- exact base `b4b51b7bb0244da6e1624c1095239c80cc206bb9`
- candidate exactly 1 commit ahead / 0 behind
- 17 changed files
- expected migration 137→138
- dedicated append-only market-reference ledger
- record/supersede/void application lifecycle
- integer minor units + bounded USD/PHP and basis allowlists
- item-state FOR UPDATE + event-count/current-id STALE protection
- genuine two-process/two-connection production-service concurrency proof
- dedicated ACL + staff auth/CSRF/throttle
- server-derived actor
- canonical service reader + collector privacy projection
- current-owner-only collector integration
- public Passport/profile/collection exclusion
- certificate snapshot/PDF + QR exclusion
- zero intended provenance/current-state mutation
- append-only UPDATE/DELETE triggers and same-item predecessor trigger.

Those areas are accepted for R1 and should not be redesigned.

## R1 blocker A — immutable DB ledger permits semantically impossible histories
The DB currently enforces row shape and **same-item** predecessor linkage, but not lifecycle validity.

A direct/raw insert can still persist structurally valid but impossible immutable history, for example:
1. `record → record` while the first record is still current;
2. `record(e1) → supersede(e2→e1) → supersede(e3→e1)`, where e3 targets the historical/non-current e1;
3. `void` targeting a historical/non-current same-item event.

The application service correctly rejects these paths, but the canonical reader `foldCurrent()` trusts every persisted row and simply treats any record/supersede as current and any void as clearing current. Therefore one malformed raw row can permanently alter effective Market Reference state even though the ledger is append-only and cannot be repaired.

This conflicts with the promoted invariants:
- at most one effective current per item;
- supersede/void must target the current effective event;
- no supersede/void of historical target;
- malformed raw rows must fail closed at the DB boundary;
- immutable evidence must not permit impossible event histories.

### Required remediation A
Add insert-time DB enforcement (trigger or equivalent DB boundary) that validates the lifecycle against the existing immutable stream for NEW.eyewear_item_id:
- `record` allowed only when the current effective state is null (first ever or after a valid current void);
- `supersede` predecessor must equal the actual current effective event for that item;
- `void` predecessor must equal the actual current effective event for that item;
- preserve same-item predecessor enforcement;
- after a valid void, a fresh record remains allowed.

Keep the production service locking/token logic unchanged. The DB rule is defense-in-depth for raw/malformed rows, not a replacement for service serialization.

Add direct-DB tests proving:
- second record while current exists is rejected;
- supersede of historical same-item predecessor is rejected;
- void of historical same-item predecessor is rejected;
- valid current supersede and valid current void still work;
- fresh record after valid void still works.

## R1 blocker B — canonical service accepts impossible calendar dates
`MarketReferenceService::normAsOfDate()` uses permissive `Carbon::parse()`. Inputs such as an impossible calendar date can normalize to another real date rather than fail, even though the architecture requires invalid dates to fail closed and MarketReferenceService is the canonical writer/validator.

The FormRequest's `date` rule protects the HTTP UI, but direct callers of the production service are part of the domain boundary and current focused tests explicitly exercise the service directly.

### Required remediation B
Use strict YYYY-MM-DD validation in `MarketReferenceService` itself:
- exact format only;
- reject impossible calendar dates rather than normalize them;
- retain the existing future-tolerance policy after strict parsing.

Add service-level tests for at least:
- impossible date such as `2026-02-31` rejected with INVALID and zero write;
- malformed but parseable/non-exact date rejected;
- valid leap/calendar date accepted as appropriate;
- existing future-date rejection preserved.

## R1 scope guard
Do NOT redesign:
- record/supersede/void product policy;
- staff/collector UI;
- amount/currency/basis model;
- ACL/routes;
- owner privacy;
- public exposure policy;
- concurrency mechanism;
- provenance boundaries;
- automated pricing/public value/resale.

Re-run focused MarketReference tests including real concurrency and full `tests/Feature/Sca`. Update `docs/SCA-MARKET-REFERENCE-SLICE1-IMPLEMENTATION.md` with R1 evidence, push a NEW candidate SHA, and **STOP**.

**DO NOT merge. DO NOT deploy. DO NOT begin another initiative.**

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

# NEXT TASK

**STATUS: SERVICE HISTORY CORRECTION & ANNOTATION — POST-DEPLOYMENT AUDIT PASS / CLOSED.**

ChatGPT independently audited the deployed production result against the exact pre-merge-approved candidate.

### Authoritative closure
- Approved candidate: `2d578feb5f429d9e7549d968c21fbfc879ba0885`
- Production base before deployment: `9bc0907c486688c7acd0d22ad2ee9f5db37d93bb`
- Merge = main = deployed: `b4b51b7bb0244da6e1624c1095239c80cc206bb9`
- Production migration: **137**
- Deployment evidence: `docs/SCA-SERVICE-CORRECTION-DEPLOY-RESULT.md`
- Governance deployment evidence commit: `947a88b`

### Independent post-deployment findings
**PASS.**
- GitHub candidate→deployed comparison is exactly 1 commit ahead / 0 behind with **files=[]**: merge tree is content-identical to approved candidate.
- Deployed commit is the expected auditable merge of the approved Service History Correction candidate.
- Exact merge-tree full SCA gate recorded as **1285 passed / 1 skipped / 0 failed**. Two earlier runs aborted before migration on known unrelated QR flakes; evidence confirms production remained at migration 136 until the clean gate.
- Migration **136→137** applied.
- Production schema evidence matches approved migration: `sca_service_event_corrections` present with 9 CHECK constraints, 3 triggers, 2 secondary indexes + PK, and 2 RESTRICT FKs.
- New correction ledger contained **0 rows** after deploy; no fabricated production evidence.
- `sca_service_events` remained **0→0**.
- Reproducible provenance fingerprint remained byte-identical: `d15a5cbdfb8df52ba65628b276533cfe`.
- Canonical provenance counts remained `3/3/4/4/5/2/1/1/7`.
- Production-safe route/auth/CSRF smoke was fail-closed and created zero correction rows.
- kr-app remains loopback-only.
- No Caddy/DNS change.
- Shopify OAuth remains `read_orders`.
- Stripe remains dormant.
- Mail remains `log`.
- `ServiceService::record()` and `ProjectionService::rebuild()` remained outside this slice.
- Core invariant preserved: original service events remain permanent evidence; correction/annotation/void are append-only overlay evidence and do not mutate provenance/current-state ledgers.

### Closure decision
**SCA Service History Correction & Annotation is CLOSED and LIVE in production.**

Do not perform further work on this initiative unless a separately audited defect/remediation is opened.

**Do not automatically begin another initiative. The next product initiative must first be selected and architecture-audited before implementation is promoted.**

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

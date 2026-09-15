# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-ADMIN-AUTH-006

## Title

Build the SCA staff authentication inspection and condition-grading workflow

## Implementer

Claude

## Last completed

`SCA-ADMIN-ITEMS-005` — PASS.

PR #6 accepted head:

`75af06aa0960c9990707b23a21acaf0e6e90b1c1`

Merged/deployed implementation `main`:

`14614d14ce6b35aa0d917a3a4227c474d574f257`

Post-merge living-preview verification confirmed the SCA Eyewear Registry navigation, intake, list, detail, search, real 403/404 semantics, Foundation/WIP banner, 16 provenance tables, and 22 integrity triggers. One clearly marked `DEMO-DO-NOT-USE` item is intentionally retained for preview demonstration.

## Authority

Use implementation `main`, `docs/SCA-DOMAIN-DESIGN.md`, the accepted provenance migrations/models/services, and the existing SCA Registry module as the source of truth.

Do not invent parallel authentication, item, current-state, media, or audit storage. Reuse the canonical `sca_authentications`, `sca_authentication_events`, `sca_media_assets`, `sca_current_state`, and related accepted SCA domain structures exactly as designed.

Authentication and certification are separate state machines. A passed authentication is evidence that may later permit certification; this task must never issue a certification, QR identity, ownership record, or Shopify sale/claim state.

## Objective

Create the next staff-facing workflow inside the authenticated Krayin operational shell so authorized SCA staff can inspect a physical eyewear item, record authentication/condition evidence, finalize an authentication outcome, and view immutable authentication history from the item detail page.

The workflow must preserve provenance: finalized historical authentication records/events are append-only and cannot be silently edited or deleted.

## Required Work

1. Pull latest `Shopify-Jeremy/main`, this `NEXT_TASK.md`, and implementation `main` before starting.
2. Create branch:

`feat/sca-admin-auth-006`

3. Inspect the exact accepted authentication/event/media/current-state schemas and existing domain services/triggers before coding. Document any mismatch between this task wording and the canonical schema; canonical accepted design wins unless a genuine blocker requires stopping for architecture review.
4. Extend only SCA-owned code/modules. Do not modify `app/packages/Webkul/**`, vendor code, or generic Krayin tables to store canonical SCA authentication data.
5. Integrate authentication into the existing SCA eyewear item detail workflow. Authorized staff should be able to start/view an authentication inspection for the exact item they are viewing.
6. Implement SCA-specific ACL permissions for authentication viewing/recording/finalizing as appropriate. Preserve existing registry permissions. Unauthenticated access must be rejected/redirected correctly; authenticated staff lacking required SCA permission must receive real HTTP 403 semantics.
7. Record inspector/grader attribution using the canonical schema. The server must derive/validate staff attribution; do not trust arbitrary client-submitted staff identity when the current authenticated employee should be authoritative.
8. Implement condition grading using only canonical accepted values/fields. Do not invent a second condition system. Validate result/state/grade values and required evidence according to the accepted schema/invariants.
9. Implement inspection notes and the accepted authentication result lifecycle. Make draft/in-progress versus finalized behavior explicit if supported by the canonical model.
10. Support inspection media references through canonical `sca_media_assets` only to the extent safely supported by the existing schema. If actual binary upload/storage policy is not yet approved, implement safe metadata/reference handling and clearly defer binary-media infrastructure rather than inventing permanent storage architecture. No public permanent URLs may derive from the temporary preview IP.
11. Finalization must use the accepted SCA domain/service/integrity layer and must append required authentication events. Do not update historical finalized event rows in place.
12. Enforce exact-item binding throughout. An authentication/event/media record for Item A must never be attachable, displayed, or finalized as evidence for Item B.
13. Preserve the accepted rule that failed authentication can never become certification. Do not add certification actions or imply that `passed` itself equals certified.
14. Update the item detail page to show an authentication section with appropriate current/latest summary plus chronological immutable history. Clearly distinguish `not authenticated`, in-progress/draft if applicable, passed, failed, and finalized states according to the canonical model.
15. Do not add hard-delete UI/actions for authentication records/events/media provenance. Do not permit editing finalized historical authentication evidence in place.
16. Keep the retained `DEMO-DO-NOT-USE` item available on the living preview; do not use the living preview DB for automated tests. Use disposable/test DB fixtures.
17. Add automated feature/integration/domain tests covering at minimum:
    - unauthenticated authentication routes are protected;
    - authenticated staff without authentication permission receives real HTTP 403;
    - authorized staff can open the authentication workflow for the correct item;
    - nonexistent item/authentication resources return real HTTP 404;
    - inspector attribution cannot be spoofed by client input;
    - valid authentication inspection can be created for an item;
    - invalid result/state/condition values are rejected without persistence;
    - exact-item binding: Item A authentication cannot appear/attach/finalize under Item B;
    - finalization appends the required authentication event(s);
    - finalized history cannot be updated or deleted through staff UI/application paths;
    - failed authentication remains failed/finalized according to canonical lifecycle and no certification is created;
    - passed authentication still creates no certification in this task;
    - condition grade and notes display on the correct item detail/history;
    - media metadata/reference, if implemented, binds to the correct authentication/item and rejects cross-item misuse;
    - one item's authentication history cannot leak into another item's detail page;
    - existing SCA Registry tests remain passing;
    - existing provenance-domain tests remain passing.
18. Include direct database/integrity regression tests where application-only tests could mask trigger/invariant failures. Do not weaken existing triggers to make UI behavior easier.
19. Run the complete relevant SCA test suite and record exact test/assertion counts.
20. Run `composer validate` and `composer audit` and record exact results.
21. Confirm the implementation adds no certification issuance, QR publication/permanent identity URL, Shopify connection, collector auth/claim/ownership, transfer/service/status/document workflow, DNS/infrastructure change, Krayin core/vendor edit, or real customer data.
22. Create/update:

`docs/task-reports/SCA-ADMIN-AUTH-006.md`

The report must include:
- exact implementation base SHA;
- canonical tables/models/services/triggers inspected and reused;
- routes/controllers/services/views/navigation/ACL changed;
- authentication lifecycle implemented;
- inspector attribution strategy;
- exact condition/result/state validation rules;
- event/finalization behavior;
- media-reference behavior and any intentionally deferred binary-storage work;
- exact-item/cross-item protections;
- immutable-history protections;
- UI behavior on item detail;
- test mapping and exact PASS/FAIL/assertion counts;
- Registry and provenance regression results;
- `composer validate` / `composer audit` results;
- known limitations/technical debt;
- exact changed-file list;
- branch/final head SHA;
- explicit scope confirmation.
23. Make logical checkpoint commits throughout implementation.
24. Push `feat/sca-admin-auth-006` to GitHub.
25. STOP after push. Do not create/merge a PR during implementation. Do not deploy the feature branch. Do not start `SCA-CERT-QR-007`.

## Acceptance Gate

PASS requires:

- authentication is recorded against canonical SCA physical items and canonical authentication/event structures;
- authorized staff can use the workflow from the item detail surface;
- staff identity/inspector attribution cannot be spoofed;
- authentication result/condition validation is enforced;
- exact-item binding prevents cross-item evidence/history misuse;
- finalization/event behavior respects the accepted append-only model;
- finalized history cannot be edited/deleted through the workflow;
- real 403/404 HTTP semantics are preserved;
- passed/failed authentication does not create certification;
- no certification/QR/ownership/Shopify scope creep;
- existing registry and provenance suites remain passing;
- no Krayin core/vendor changes;
- task report is committed and branch pushed.

## Merge / deployment workflow

Claude implements/tests/commits/pushes and then STOPS. ChatGPT creates/audits the PR. If remediation is required, Claude fixes only the audited issues on the same branch and stops again. After ChatGPT explicitly declares AUDIT PASS, Claude may merge the exact accepted head into `main` and deploy accepted `main` only when ChatGPT explicitly authorizes that merge/deployment step.

The living preview remains:

`http://195.26.255.80:8080`

Never deploy an unaudited feature branch to it.

## Completion Rule

When implementation is complete, report only:

1. branch name;
2. final branch head SHA;
3. task report path;
4. exact test/assertion summary;
5. important findings/blockers/deferrals;
6. confirmation everything is pushed.

Then STOP for ChatGPT audit.

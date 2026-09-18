# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-MY-COLLECTION-013

## Title

Build collector My Collection portal

## Implementer

Claude

## Last completed

`SCA-CLAIM-012` — PASS.

Accepted PR #14 head:

`b94fce3f907e03606b31e29642d9fafbb807b3dc`

Merged/deployed implementation `main`:

`0d6994094bd86974e710b39e991147f1a7a038fc`

The explicit QR claim workflow is live: exact active QR + valid certification/authentication + eligible sale evidence + authenticated collector can atomically create the initial registered ownership event. Sale evidence alone still creates no ownership. Deployment verified zero claim/ownership/collector/sale-link side effects.

## Authority and safety boundary

This task implements the authenticated collector **My Collection read experience** only.

It must show the authenticated collector only the physical eyewear they currently own according to canonical ownership/current-state evidence. Do not infer ownership from Shopify customer/order identity, historical ownership alone, email, claim attempts, sale links, or client-supplied item IDs.

Do not implement ownership transfer, service-event creation, lost/stolen/recovered mutations, document generation, resale, Shopify customer synchronization, or other lifecycle mutations. Those remain later tasks.

Live Shopify OAuth activation/webhook registration remain deferred pending a permanent publicly trusted SCA HTTPS endpoint. Do not reopen that blocker and do not mutate Jeremy's live Shopify store.

## Objective

Give an authenticated SCA collector a privacy-safe, SCA-branded My Collection area where they can list and inspect the authenticated/certified physical eyewear they currently own, using canonical provenance/current-state data without exposing staff/private/internal/Shopify information or weakening public-passport privacy.

## Required Work

1. Pull latest governance `main`, this task, and implementation `main` (`0d6994094bd86974e710b39e991147f1a7a038fc`) before coding.
2. Create branch `feat/sca-my-collection-013`.
3. Inspect only the relevant accepted collector auth, ownership/current-state projection, claim evidence, certification/authentication, public passport presenter/allowlist, service-event schema if already present, routes/views, and related tests. Reuse accepted structures; do not redesign unrelated modules.
4. Implement My Collection inside an SCA-owned collector surface protected by the independent `collector` guard and separate from Krayin staff/admin chrome.
5. Collection membership must derive from canonical **current ownership/current-state** for the authenticated collector. Historical owners must not continue to see an item after ownership later changes. Do not use Shopify sale/customer data as the ownership source.
6. Provide a collection/list page with safe owner-facing summary information for each currently owned item. Keep the minimum useful fields consistent with accepted SCA provenance and privacy rules.
7. Provide an owner-only item detail page resolved through an opaque/public-safe item reference or another accepted non-enumerable route identity. Do not expose internal numeric DB IDs in URLs or rendered output.
8. The detail page may show trusted item identity, certification/authentication status, condition grade/summary, current lifecycle/status, certification number, and provenance/history that the authenticated current owner is authorized to see. Reuse canonical presenters/services where practical rather than trusting client data.
9. If service-history records already exist in the accepted schema, display only safe existing records appropriate to the owner. Do **not** create service events or invent placeholder provenance. If none exist, render an honest empty state; service creation belongs to `SCA-SERVICE-015`.
10. Do not expose staff IDs/names unless explicitly approved by the accepted owner-facing data policy; do not expose authentication private notes, raw Shopify order/customer identifiers, sale-link internals, password/session data, private data belonging to another collector, internal DB IDs, security/QR tokens, or other secrets.
11. Enforce ownership authorization server-side on every owner detail request. An authenticated collector requesting another collector's item must receive a privacy-safe real 404 (preferred to avoid confirming another collector's ownership) or an already-established equivalent non-leaking response.
12. Unauthenticated collection/detail access must redirect/fail safely through collector sign-in. A Krayin staff session alone must not satisfy collector authentication. A collector session must not gain staff/admin access.
13. Keep the public passport `/p/{token}` behavior and allowlist unchanged unless a minimal non-private navigation affordance is strictly necessary. My Collection must not make public passport pages reveal owner identity, ownership contact data, or private collector information.
14. My Collection is read-only with respect to provenance and ownership in this task. Viewing/listing/detail must create zero claims, ownership events, transfers, service events, sale-link changes, certifications, authentications, QR events, or lifecycle/current-state mutations.
15. Do not add owner mutation buttons that imply unfinished functionality. Transfer actions belong to `SCA-TRANSFER-014`; service mutations belong to `SCA-SERVICE-015`; status mutations belong to `SCA-STATUS-016`.
16. Handle empty collections cleanly and safely. Do not reveal whether other collectors/items exist.
17. Avoid N+1/unbounded history loading where practical. Use scoped queries/pagination or sensible limits if the accepted architecture/data volume requires them; do not over-engineer a new query layer for this task.
18. Add focused automated tests covering at minimum: authenticated collector sees their currently owned claimed item; empty collection; unauthenticated redirect; staff session does not imply collector access; collector session cannot access admin; another collector's item is absent from list and owner-detail request fails without leakage; internal IDs/private owner data/staff/private auth notes/Shopify identifiers/security tokens are absent; certification/authentication/condition data shown is canonical; historical/non-current ownership does not grant collection access where testable with accepted ownership events; list/detail views create no domain mutations; public passport remains unauthenticated and owner-private; no Shopify identity auto-link/inference; safe real 404/redirect behavior.
19. Include direct query/invariant tests where useful to prove collection membership follows current ownership rather than historical claim/sale evidence.
20. Run My Collection focused tests plus relevant collector-auth, claim/ownership, passport/privacy, certification/authentication regressions and mandatory repository checks. Match testing depth to the read-only/privacy risk; do not broaden unnecessarily.
21. Run `composer validate`, `composer audit`, and repository secret-safety checks for the task diff.
22. Create/update `docs/task-reports/SCA-MY-COLLECTION-013.md` with concise evidence: membership/authorization contract, displayed fields/privacy boundary, read-only/no-mutation evidence, test counts, changed files, findings/deferrals, base SHA, final branch SHA.
23. Make logical checkpoint commits and push `feat/sca-my-collection-013`.
24. STOP after push for ChatGPT review. Do not create/merge a PR, do not deploy the feature branch, and do not start `SCA-TRANSFER-014` or later tasks.

## Acceptance Gate

PASS requires:

- authenticated collector can list only items they currently own;
- owner detail is authorized from canonical current ownership and cannot enumerate another collector's item;
- historical sale/claim/Shopify identity alone never grants access;
- useful canonical certification/authentication/condition/provenance data is shown without private/internal/security leakage;
- empty collection works safely;
- collector/staff auth separation remains intact;
- list/detail are read-only and create no ownership/provenance/lifecycle mutation;
- public passport remains public and owner-private;
- no live Shopify dependency/store mutation;
- no Krayin core/vendor changes;
- focused tests and mandatory checks pass;
- task report and implementation are committed and pushed.

## Deferred work

Ownership transfer is `SCA-TRANSFER-014`; service-event creation is `SCA-SERVICE-015`; lost/stolen/recovered mutations are `SCA-STATUS-016`; documents are `SCA-DOCUMENTS-017`. Live Shopify OAuth/webhook activation remains deferred pending the permanent SCA HTTPS domain. Do not implement or work around those in this task.

## Completion Rule

When complete, report only:

1. branch and final HEAD SHA;
2. task report path;
3. focused test/assertion results and mandatory checks;
4. collection membership/authorization contract;
5. owner-facing fields and privacy boundary;
6. read-only/no-domain-mutation evidence;
7. collector/staff/public-passport separation evidence;
8. blocker/deferral, if any;
9. confirmation everything is pushed.

Then STOP for ChatGPT review.

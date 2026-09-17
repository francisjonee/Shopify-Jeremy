# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-CLAIM-012

## Title

Build QR claim ownership workflow

## Implementer

Claude

## Last completed

`SCA-COLLECTOR-AUTH-011` — PASS.

Accepted PR #13 head:

`2675d9620775619aea7009c5258f0bac05fa4c5a`

Merged/deployed implementation `main`:

`500df276e33f6b102f69154b83c577eae8439d45`

Independent SCA collector registration/login/session/logout is live and separated from Krayin staff authentication. Deployment verified zero collector accounts and zero ownership/claim/sale-link side effects.

## Authority and safety boundary

This task implements the INITIAL QR CLAIM OWNERSHIP workflow only.

A Shopify sale is eligibility evidence only. A sale MUST NOT automatically establish SCA ownership. Ownership begins only after an authenticated SCA collector successfully completes the governed claim flow for the exact eligible physical item.

Do not implement ownership transfer, My Collection beyond the minimum claim-success destination, service history, lost/stolen, Shopify customer synchronization, social login, or later lifecycle features.

Live Shopify OAuth activation/webhook registration remain deferred pending a permanent publicly trusted SCA HTTPS endpoint. Do not reopen that blocker and do not mutate Jeremy's live Shopify store.

## Objective

Allow an authenticated SCA collector who possesses/scans the permanent QR identity for an eligible sold physical eyewear item to claim that exact item once, producing the canonical initial registered ownership evidence atomically and idempotently without exposing private sale/customer information.

## Required Work

1. Pull latest governance `main`, this task, and implementation `main` (`500df276e33f6b102f69154b83c577eae8439d45`) before coding.
2. Create branch `feat/sca-claim-012`.
3. Inspect only the relevant accepted claim/ownership/current-state schema and services, public passport/QR resolver, collector guard, Shopify sale-link eligibility contract, integrity triggers, and related SCA tests. Reuse accepted structures and do not redesign unrelated modules.
4. Implement the claim flow in an SCA-owned collector surface using the independent `collector` guard. The public QR/passport may lead toward claim, but mutation requires an authenticated collector session.
5. Resolve the item from the permanent opaque QR identity/current active QR projection. Do not accept a client-supplied internal item ID, collector ID, Shopify customer ID, brand/model/SKU/title, or fuzzy identity as authoritative mapping.
6. If an unauthenticated visitor initiates claim from a valid QR/passport, preserve only the minimum safe claim continuation context through collector login/registration, then return them to the exact claim flow. Do not expose the opaque token unnecessarily in rendered content/logging.
7. Eligibility must be evaluated server-side for the exact physical item and must require the accepted prerequisites: current valid certification/authentication/active QR as defined by canonical projection; an active eligible Shopify sale-link for that exact item under the accepted 010 contract; and no existing current registered owner/consumed successful claim that would make an initial claim invalid.
8. Do not require or infer Shopify customer identity/email equality for the claimant. The Shopify sale proves sale eligibility, not who the canonical SCA owner is. The authenticated collector performing the valid claim becomes the registered owner only through this explicit claim transaction.
9. Claim completion must be atomic. In one transaction/locked invariant path, create the canonical claim evidence and append the initial ownership event for the authenticated collector, then update/recompute the accepted current-state projection as required. Partial claim-without-ownership or ownership-without-claim must not survive failure.
10. Enforce one successful initial claim for the physical item. Double-submit, browser retry, concurrent claim attempts, and replay must converge safely without duplicate ownership events or two collectors becoming current owner.
11. A second different collector attempting to claim an already registered item must fail closed without leaking the current owner's private identity/contact data.
12. If the eligible sale-link has been cancelled/refunded/revoked before successful claim, claim must fail closed and create no ownership. Do not invent return semantics beyond the accepted sale-link states.
13. Successful claim must use the canonical collector account identity from the authenticated session, never a collector reference supplied by the client.
14. Preserve append-only provenance/history. Do not overwrite/delete prior claim/ownership evidence to resolve retries or conflicts.
15. Do not expose Shopify order/customer identifiers, sale-link internals, staff IDs, password/session data, private collector data, or internal DB IDs on public/claim failure surfaces.
16. Keep the public passport privacy boundary intact. If claim affordance is added to the passport, it must not make the passport require login and must not reveal ownership/private eligibility details to anonymous visitors.
17. Do not create ownership merely by scanning QR, viewing passport, registering/logging in, or having an eligible Shopify sale. Only explicit successful claim completion creates ownership.
18. Add focused automated tests covering at minimum: valid eligible authenticated claim; unauthenticated claim redirects safely through collector auth; exact QR-to-item binding; nonexistent/malformed/inactive QR fails safely; missing/ineligible/cancelled/refunded sale-link rejected; uncertified/ineligible item rejected; successful claim creates exactly one canonical claim + initial ownership event and correct current projection; retry/double-submit idempotency; concurrent/two-collector conflict allows only one current owner; already-owned item rejected without owner PII leakage; authenticated collector identity cannot be spoofed by request input; claim transaction rollback on injected/internal failure leaves neither partial claim nor ownership; scan/passport/login alone creates no ownership; no Shopify/customer auto-link; passport remains public/privacy-safe; collector/staff auth separation remains intact; real 404/403/409 behavior where appropriate.
19. Include direct DB/invariant tests for one-current-owner/claim uniqueness and append-only integrity where relevant to the canonical schema.
20. Run claim-focused tests plus relevant collector-auth, passport, sale-link, ownership/provenance regressions and mandatory repository checks. Match testing depth to the risk of this ownership mutation; do not broaden into unrelated suites without reason.
21. Run `composer validate`, `composer audit`, and repository secret-safety checks for the task diff.
22. Create/update `docs/task-reports/SCA-CLAIM-012.md` with concise evidence: claim eligibility contract, exact QR/item mapping, transaction/idempotency/concurrency behavior, ownership event produced, privacy boundary, tests/checks, changed files, findings/deferrals, base SHA, final branch SHA.
23. Make logical checkpoint commits and push `feat/sca-claim-012`.
24. STOP after push for ChatGPT review. Do not create/merge a PR, do not deploy the feature branch, and do not start `SCA-MY-COLLECTION-013` or later tasks.

## Acceptance Gate

PASS requires:

- only an authenticated SCA collector can complete a claim;
- exact physical item is resolved from its permanent active QR identity, never fuzzy/client-authoritative mapping;
- eligible sale evidence is required but never automatically creates ownership;
- successful claim atomically creates canonical claim evidence + initial registered ownership event for the authenticated collector;
- exactly one current owner results and retries/concurrency cannot duplicate or reassign initial ownership;
- cancelled/refunded/revoked/ineligible sales cannot be claimed;
- request input cannot spoof collector identity;
- failure/rollback cannot leave partial claim/ownership state;
- no private owner/Shopify/internal identity leaks;
- public passport remains public and privacy-safe;
- no live Shopify dependency or store mutation;
- no Krayin core/vendor changes;
- focused ownership-risk tests and mandatory checks pass;
- task report and implementation are committed and pushed.

## Deferred live Shopify configuration

Live Shopify OAuth activation and webhook registration remain deferred pending the permanent SCA HTTPS domain and secure server-side credentials. Mocked/controlled accepted sale-link evidence may be used for tests. Do not use the temporary HTTP preview IP as an OAuth/webhook callback.

## Completion Rule

When complete, report only:

1. branch and final HEAD SHA;
2. task report path;
3. focused test/assertion results and mandatory checks;
4. exact QR/item + sale eligibility contract;
5. claim transaction/idempotency/concurrency behavior;
6. ownership evidence/current-state result;
7. privacy/auth separation evidence;
8. confirmation no live Shopify/store mutation or automatic ownership occurred;
9. blocker/deferral, if any;
10. confirmation everything is pushed.

Then STOP for ChatGPT review.

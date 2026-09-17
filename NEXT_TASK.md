# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-SHOPIFY-SALELINK-010

## Title

Link Shopify sale events to the exact physical SCA eyewear item

## Implementer

Claude

## Last completed

`SCA-SHOPIFY-CONNECT-009` — PASS.

OAuth remediation accepted head:

`830c8a18b5c40c10f43e5fd2b6d84a08ed9ab399`

Merged/deployed implementation `main`:

`044c910fad457b83b47874001babdb3df6a270f1`

Connection foundation, webhook verification/idempotency, and external-merchant OAuth authorization-code flow are implemented and deployed. Live OAuth activation and live webhook registration remain intentionally DEFERRED until a permanent publicly trusted SCA HTTPS endpoint and server-side Shopify credentials are available. This external configuration deferral does not block this task.

## Authority and safety boundary

This task implements Shopify SALE LINKING only.

A Shopify order/payment is commerce evidence. It MUST NOT create, transfer, or infer canonical SCA ownership. Do not create collector accounts, ownership events, claims, transfers, or owner identity from Shopify customer data. Those belong to later tasks.

Do not mutate Jeremy's live Shopify store. Do not require live OAuth or live webhook registration to complete this task. Use controlled fixtures/mocked signed webhook events and the existing verified webhook foundation.

Do not use `http://195.26.255.80:8080` as an OAuth/webhook callback. Do not add real Shopify secrets to source, reports, logs, command history, screenshots, or chat.

## Objective

Implement an idempotent, auditable sale-link workflow that can take a verified Shopify commerce event and link the relevant paid order line to exactly one eligible physical SCA eyewear item, while safely handling cancellation/refund/return state and preserving the separation between sale evidence and registered ownership.

## Required Work

1. Pull latest governance `main`, this task, and implementation `main` (`044c910fad457b83b47874001babdb3df6a270f1`) before coding.
2. Create branch `feat/sca-shopify-salelink-010`.
3. Inspect only the relevant accepted architecture and implementation: canonical `sca_shopify_sale_links` schema/invariants, item/current-state projection, Shopify webhook receipt pipeline, topic allowlist, certification/eligibility rules, and existing tests/services. Reuse accepted structures; do not redesign unrelated modules.
4. Define the exact physical-item mapping contract. A Shopify line must resolve to one specific SCA item using an explicit stable SCA-controlled identifier/reference. Do not match by brand/model/title, fuzzy text, customer identity, or other ambiguous product metadata.
5. Fail closed when the mapping is absent, malformed, ambiguous, points to a nonexistent item, or points to an item that is not eligible for sale linking.
6. Preserve exact-item binding throughout processing. Never allow an order/line reference for one physical item to mutate/link another item.
7. Implement sale-link creation from an already cryptographically verified/accepted Shopify event path. Do not bypass the CONNECT-009 HMAC/shop/topic/idempotency boundary.
8. For paid-order evidence, create/update only the canonical Shopify sale-link/evidence state needed by the accepted domain design. Do not create ownership or collector records.
9. Enforce idempotency at both application and database levels where the canonical schema permits/requires it. Replayed webhook deliveries, duplicate order events, retries, and double processing must not create duplicate sale links or duplicate lifecycle evidence.
10. Define and implement deterministic behavior for the task-relevant Shopify event topics already established by CONNECT-009: paid, cancelled, and refund-related events. If the accepted schema distinguishes returned from refunded, implement only what can be derived truthfully from available verified event evidence; do not invent a return event from a refund unless the canonical design explicitly equates them.
11. Cancellation/refund/return handling must update sale eligibility/evidence according to the accepted domain rules without erasing history and without creating ownership changes.
12. Out-of-order or repeated events must fail safely or converge deterministically. A stale/replayed event must not incorrectly restore a superseded sale state.
13. Do not persist unnecessary Shopify customer PII or raw webhook payloads. Persist only identifiers/evidence required by the canonical sale-link model and existing minimal integration audit policy.
14. Do not write/update/delete Shopify products, variants, orders, customers, inventory, fulfillment, refunds, discounts, or other Shopify data. This task consumes mocked/verified event evidence only.
15. Do not alter authentication, certification, QR identity, or public passport privacy behavior except where the accepted current-state projection explicitly requires a sale-eligibility state update. Existing certification/authentication evidence must remain immutable.
16. Add focused automated tests covering at minimum: exact physical-item mapping success; missing mapping; malformed mapping; nonexistent item; ambiguous/cross-item mapping rejection; ineligible item rejection; paid event creates exactly one sale link; duplicate/replayed paid event remains one link; duplicate Shopify order/line evidence cannot bind two physical items; cancelled behavior; refund behavior; return behavior if supported by canonical evidence; out-of-order/retry behavior; no ownership/collector/claim record created; no customer PII/raw payload persisted; forged/unverified webhook cannot reach sale linking; existing webhook receipt idempotency remains intact; existing item/auth/cert/passport behavior remains intact.
17. Include direct DB/invariant tests for relevant uniqueness/exact-item constraints and any trigger behavior relied on by the implementation.
18. Run the Shopify/sale-link tests plus relevant SCA regressions required by the touched projection/domain path. Do not inflate testing beyond what this change requires, but do not skip mandatory repository release checks.
19. Run `composer validate`, `composer audit`, and the repository secret-safety check for the task diff.
20. Create/update `docs/task-reports/SCA-SHOPIFY-SALELINK-010.md` with concise implementation evidence, exact mapping contract, event-state behavior, idempotency guarantees, test counts, changed files, findings/deferrals, base SHA, and final branch SHA.
21. Make logical checkpoint commits and push `feat/sca-shopify-salelink-010`.
22. STOP after push for ChatGPT review. Do not create/merge a PR, do not deploy the feature branch, and do not start `SCA-COLLECTOR-AUTH-011` or `SCA-CLAIM-012`.

## Acceptance Gate

PASS requires:

- verified Shopify commerce evidence can link to exactly one eligible physical SCA item through an explicit non-ambiguous mapping;
- missing/invalid/ambiguous/cross-item mappings fail closed;
- paid/cancelled/refunded/returned behavior follows accepted domain semantics and is deterministic under retries/out-of-order delivery;
- duplicate delivery/order-line evidence cannot create duplicate or conflicting sale links;
- sale linking creates NO canonical ownership, collector account, claim, or transfer;
- no unnecessary customer PII/raw webhook body persistence;
- no Shopify-side mutation;
- CONNECT-009 HMAC/shop/topic/idempotency protections remain intact;
- existing auth/cert/QR/passport invariants remain intact;
- no real credentials in git/report;
- no Krayin core/vendor changes;
- focused tests and mandatory checks pass;
- task report and implementation are committed and pushed.

## Deferred live Shopify configuration

Live OAuth activation and webhook registration remain deferred pending the permanent SCA HTTPS domain and secure server-side credentials. Do not reopen or work around this blocker during task 010. Mocked/signed event testing is the authorized path for this task.

## Completion Rule

When complete, report only:

1. branch and final HEAD SHA;
2. task report path;
3. exact focused test/assertion results and mandatory checks;
4. exact physical-item mapping contract implemented;
5. paid/cancelled/refunded/returned behavior implemented;
6. idempotency/integrity evidence;
7. confirmation no ownership/collector/claim was created and no Shopify store mutation occurred;
8. important blocker/deferral, if any;
9. confirmation everything is pushed.

Then STOP for ChatGPT review.

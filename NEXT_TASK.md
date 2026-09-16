# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-SHOPIFY-CONNECT-009

## Title

Verify and connect the live Second Chance Eyewear Shopify store safely

## Implementer

Claude

## Last completed

`SCA-PUBLIC-PASSPORT-008` — PASS.

PR #9 accepted head:

`a11a726351e861fcda0ad6c0178314e357fdc6e0`

Merged/deployed implementation `main`:

`ae2a994bd8eb2f41c58effd54e8798c819f2709a`

Post-merge preview verification confirmed the public passport is live, unauthenticated/read-only, privacy allowlisted, and resolved from the permanent opaque QR identity without exposing private/staff/owner/Shopify/internal data.

## Authority and safety boundary

This task establishes the Shopify CONNECTION FOUNDATION only.

Do NOT implement physical-item sale linking, ownership/claim, inventory mutation, product/order mutation, refunds, fulfillment, customer mutation, or automatic lifecycle changes. Those belong to later tasks.

The live Shopify store is an external production system. Never guess its identity, credentials, app installation, API version, scopes, webhook secret, or callback URL. Never commit credentials or secrets.

If required live-store credentials or exact store/app identity are unavailable, implement and test the safe connection/webhook foundation locally, document the exact missing inputs, and STOP rather than fabricating or weakening verification.

## Objective

Establish a least-privilege, auditable Shopify integration foundation that can:

1. verify the exact intended Shopify store/app identity;
2. authenticate safely to Shopify with secrets held outside source control;
3. perform a read-only connectivity/store-identity check;
4. receive and cryptographically verify Shopify webhooks;
5. reject forged/replayed/malformed webhook requests safely;
6. record only minimal integration/webhook metadata needed for idempotency/audit;
7. leave physical SCA item linking and sale-state behavior completely untouched.

## Required Work

1. Pull latest `Shopify-Jeremy/main`, this `NEXT_TASK.md`, and implementation `main` before starting.
2. Create branch:

`feat/sca-shopify-connect-009`

3. Inspect before coding:
   - `docs/SCA-DOMAIN-DESIGN.md` Shopify reference policy;
   - existing `sca_shopify_sale_links` schema/triggers/models/services, if present;
   - current SCA module architecture and config patterns;
   - repository history/config for any existing Shopify app integration;
   - `.env.example`, secret handling, deployment scripts, and ignored files;
   - current official Shopify Admin API/webhook requirements applicable to the app type actually being used.
4. Do not assume whether this is a custom app, public app, development app, or another installation model. Determine it from existing project evidence and/or verified live credentials. Document the result.
5. Determine and document the exact intended store identity before any live API action. At minimum capture non-secret canonical identity such as the verified `*.myshopify.com` domain/store identifier returned by Shopify. Do not rely only on a vanity storefront domain.
6. Add SCA-owned Shopify integration configuration with secrets read only from environment/runtime secret storage. No access token, client secret, webhook secret, session secret, private key, or credential may be committed, printed in reports, logged, rendered in UI, or returned in errors.
7. Update `.env.example` with variable NAMES/placeholders only. Never insert real secret values.
8. Use the least privileges required for THIS task. Prefer read-only scopes sufficient to verify store/app connectivity. Do not request product/order/customer write scopes. If webhook registration itself requires additional permission, document it and do not broaden scopes beyond what is actually required.
9. Implement a safe Shopify client/service abstraction in SCA-owned code. It must:
   - use the verified store domain rather than arbitrary user-controlled hosts;
   - use HTTPS only;
   - use an explicit supported API version rather than an unbounded/latest endpoint;
   - have sane connect/request timeouts;
   - fail closed on authentication/TLS/API errors;
   - redact secrets from logs/exceptions;
   - not follow redirects to arbitrary hosts if that could leak authorization headers.
10. Implement a read-only connectivity/store-identity verification operation. It should confirm the authenticated Shopify shop identity and compare it to the configured expected store. A mismatch must fail closed and must not continue into webhook registration or later integration behavior.
11. If credentials are available and verified, perform only the minimal safe live read required to establish store identity/connectivity. Do not mutate products, orders, customers, inventory, fulfillment, refunds, discounts, or SCA provenance data.
12. Build an unauthenticated Shopify webhook endpoint in SCA-owned code, isolated from public passport/admin behavior. The endpoint must verify the webhook HMAC against the RAW request body before parsing/trusting payload data.
13. Webhook verification must use constant-time comparison and fail closed. Missing/invalid HMAC must return an appropriate non-success response and must create no trusted event record or SCA domain mutation.
14. Validate relevant Shopify webhook metadata/headers defensively. Do not trust topic/shop domain/event identifiers solely because they are headers; enforce expected store identity where applicable.
15. Add idempotency/replay protection using Shopify's webhook/event identifier where available, with a database uniqueness guarantee. Duplicate delivery must be acknowledged safely without processing twice.
16. Add the minimum SCA-owned persistence necessary for integration audit/idempotency if no suitable canonical table exists. If a new table is required, keep it integration-specific and minimal, for example: event UUID/idempotency key, verified shop domain, topic, received timestamp, processing status, safe payload hash. Do NOT persist entire customer/order payloads merely for convenience.
17. Do not place Shopify webhook events into provenance tables as ownership/sale/authentication/certification events during this task. Connection events are integration evidence only.
18. Treat webhook payload content as untrusted even after HMAC verification. This task may verify/record receipt metadata but must not link an order line to an eyewear item or change item lifecycle/current state.
19. Do not log raw webhook bodies by default. If a payload hash is useful for audit/idempotency, use a one-way cryptographic digest. Do not store unnecessary customer PII.
20. Add explicit supported webhook topic allowlisting for the foundation. Unknown/unneeded topics must not trigger domain processing. Keep the allowlist as narrow as possible for the next planned sale-link task and document why each topic is needed. Do not subscribe/register topics speculatively.
21. Do not register live webhooks to the temporary plain-HTTP preview IP. `http://195.26.255.80:8080` is NOT an acceptable permanent Shopify webhook callback. If Shopify requires a publicly trusted HTTPS callback and none is available, defer live webhook registration and document the blocker. Local/automated webhook verification tests are still required.
22. Do not alter the permanent SCA QR identity or public passport routing as part of Shopify integration.
23. Add admin/staff diagnostics only if needed, protected by SCA ACL. Diagnostics must show safe non-secret state only, e.g. configured/not configured, verified store domain, API version, last safe verification result. Never show access tokens/secrets.
24. Add automated tests covering at minimum:
   - Shopify config requires HTTPS/canonical expected store domain;
   - secrets are not exposed through config diagnostics/views/errors/logging added by this task;
   - read-only store identity verification succeeds for matching mocked Shopify response;
   - mismatched Shopify store identity fails closed;
   - API auth/network/error responses fail closed;
   - webhook with valid HMAC over exact raw body is accepted;
   - missing HMAC rejected;
   - invalid HMAC rejected;
   - body changed after HMAC generation rejected;
   - webhook from unexpected shop domain rejected;
   - malformed/unexpected topic rejected or safely ignored according to documented contract;
   - duplicate webhook/event identifier is idempotent and cannot create duplicate trusted event records;
   - payload hash is deterministic and raw payload/PII is not persisted by the integration audit record;
   - webhook receipt causes NO SCA item lifecycle/current-state/certification/authentication/ownership mutation;
   - no physical-item Shopify sale link is created by this task;
   - public passport tests remain passing;
   - certification/authentication/Registry/provenance suites remain passing.
25. Include direct DB tests for any new idempotency uniqueness constraint and confirm duplicate delivery cannot bypass application logic.
26. Run the complete relevant SCA test suite and record exact test/assertion counts.
27. Run `composer validate` and `composer audit` and record exact results.
28. Run a repository secret-safety check on the task diff. Confirm no real Shopify token/secret/private key/webhook secret has entered tracked files or task reports.
29. If a safe verified live connectivity check is possible with credentials already present in the server environment, record only NON-SECRET evidence in the report: verified canonical shop domain/store identity, API version, HTTP success/failure category, and time. Never copy tokens or secret-bearing headers.
30. If live credentials/store identity are not available, STOP short of live connection and state exactly what Jeremy/user must provide or configure. Do not ask for secrets to be pasted into GitHub, task reports, source files, or chat. Prefer server environment/secret storage.
31. Create/update:

`docs/task-reports/SCA-SHOPIFY-CONNECT-009.md`

The report must include:
- exact implementation base SHA;
- evidence inspected to determine Shopify app/store model;
- canonical expected store identity, if safely verified;
- API version and rationale;
- exact requested/required scopes and why each is necessary;
- secret-storage/environment variable names only, never values;
- Shopify client/service architecture;
- live connectivity check result if safely performed;
- webhook route and HMAC verification design;
- supported topic allowlist;
- idempotency/replay design and DB uniqueness enforcement;
- exact data persisted for webhook audit and explicit PII/raw-payload exclusions;
- confirmation webhook receipt performs no SCA domain mutation;
- callback HTTPS/domain status and whether live webhook registration was deferred;
- tests and exact PASS/FAIL/assertion counts;
- public-passport/cert/auth/registry/provenance regression results;
- `composer validate` / `composer audit` results;
- secret-safety diff check;
- blockers/missing external inputs;
- exact changed-file list;
- branch/final head SHA;
- explicit scope confirmation.
32. Make logical checkpoint commits throughout implementation.
33. Push `feat/sca-shopify-connect-009` to GitHub.
34. STOP after push. Do not create/merge a PR during implementation. Do not deploy the feature branch. Do not start `SCA-SHOPIFY-SALELINK-010`.

## Acceptance Gate

PASS requires:

- exact intended Shopify store identity is verified or the absence of required external credentials is explicitly and safely blocked/documented;
- integration secrets remain outside source control and are not exposed;
- least-privilege/read-only connection foundation is implemented;
- Shopify client is pinned to an explicit supported API version and verified expected HTTPS store host;
- webhook HMAC is verified against raw body before payload trust;
- unexpected store/topic and invalid/missing HMAC fail closed;
- duplicate webhook delivery is idempotent with DB uniqueness enforcement;
- no unnecessary raw payload/customer PII persistence;
- webhook receipt makes zero SCA provenance/lifecycle/ownership/sale-link mutations;
- temporary preview IP is not registered/stored as permanent webhook callback;
- existing SCA suites remain passing;
- no Krayin core/vendor changes;
- no real credentials in git/report;
- task report committed and branch pushed.

## Merge / deployment workflow

Claude implements/tests/commits/pushes and STOPS. ChatGPT creates/audits the PR. Remediation stays on the same branch. After explicit AUDIT PASS, Claude may merge the exact accepted head and deploy accepted `main` only when explicitly authorized.

Living preview:

`http://195.26.255.80:8080`

The preview may be used for non-secret diagnostics after accepted merge, but must NOT be registered as the permanent Shopify webhook callback because it is plain HTTP and temporary.

## Completion Rule

When implementation is complete, report only:

1. branch name;
2. final branch head SHA;
3. task report path;
4. exact test/assertion summary;
5. verified non-secret Shopify identity/connectivity evidence OR exact external blocker;
6. important findings/deferrals;
7. confirmation everything is pushed.

Then STOP for ChatGPT audit.

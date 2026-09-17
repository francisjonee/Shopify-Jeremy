# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-COLLECTOR-AUTH-011

## Title

Build independent SCA collector account authentication

## Implementer

Claude

## Last completed

`SCA-SHOPIFY-SALELINK-010` — PASS.

Accepted PR #12 head:

`5914aabeb885ec544c0807d1fddd9ec5ddec6738`

Merged/deployed implementation `main`:

`58b0d6c8f36ba5d294a52378f5af3b9c0d05cd1c`

Exact physical-item sale linking, paid/cancel/refund evidence, retry-safe webhook processing, idempotency, and the strict no-ownership boundary are implemented and deployed. Live Shopify OAuth activation/webhook registration remain intentionally deferred pending a permanent publicly trusted SCA HTTPS endpoint; do not reopen that blocker during this task.

## Authority and safety boundary

This task implements COLLECTOR ACCOUNT AUTHENTICATION only.

Collector identity is an independent SCA identity. Shopify customer/order identity, email, or commerce evidence MUST NOT automatically create a collector account, authenticate a collector, establish ownership, or transfer ownership.

Do not implement QR claim ownership, ownership events, transfers, My Collection, Shopify customer synchronization, or sale-to-owner inference in this task. Those belong to later tasks.

Do not mutate Jeremy's live Shopify store. Do not require live Shopify OAuth/webhook activation. Do not use the temporary HTTP preview IP as an OAuth/webhook callback and do not add real credentials/secrets to source, reports, logs, history, screenshots, or chat.

## Objective

Implement a secure, SCA-branded collector account and authentication foundation, separate from Krayin staff/admin authentication, that can later be used by the QR claim workflow without weakening provenance, privacy, or ownership invariants.

## Required Work

1. Pull latest governance `main`, this task, and implementation `main` (`58b0d6c8f36ba5d294a52378f5af3b9c0d05cd1c`) before coding.
2. Create branch `feat/sca-collector-auth-011`.
3. Inspect only the relevant accepted collector/account schema, authentication conventions, public-passport boundary, sale-link/claim prerequisites, Laravel/Krayin auth configuration, and existing SCA tests. Reuse accepted structures; do not redesign unrelated modules.
4. Implement collector authentication in an SCA-owned module/surface separate from Krayin staff/admin authentication. Collector credentials/sessions must not grant staff/admin access or reuse staff authorization semantics.
5. Use the canonical collector account model/table if already defined by the accepted domain design. Do not invent duplicate identity stores when an accepted collector structure exists. If the canonical schema intentionally separates profile from login credentials, preserve that separation.
6. Implement the minimum secure account lifecycle required for later claim work: collector registration, sign-in, authenticated session, sign-out, and an authenticated collector landing/account page sufficient to prove the session boundary.
7. Registration must validate and normalize identity fields safely, enforce canonical uniqueness where required, hash passwords using the framework's approved password hasher, and never persist plaintext passwords or authentication secrets.
8. Prevent account enumeration where practical. Authentication failures must not disclose whether a specific collector account/email exists beyond what is necessary for safe registration validation.
9. Apply CSRF/session protections and secure framework authentication/session mechanisms. Do not create custom bearer-token/session cryptography when Laravel's accepted mechanisms satisfy the requirement.
10. Enforce route separation: unauthenticated collector-only pages/actions requiring a session must redirect/fail safely to collector sign-in, while authenticated collector sessions must not gain `/admin` access. Krayin admin sessions must not automatically become collector sessions.
11. Keep the public passport (`/p/{token}`) publicly readable and privacy-safe. Collector authentication must not expose private collector/account data on passport pages or change passport token resolution semantics.
12. Do not infer or create ownership during registration/sign-in. Creating a collector account must create zero ownership events, zero claims, zero transfers, and must not change any eyewear lifecycle/current-state projection.
13. Do not automatically bind a collector to Shopify customer identity, order email, order customer ID, or sale link. Any later linkage must be explicit and governed by later task requirements.
14. Do not persist unnecessary PII. Store only collector account/profile fields required by the accepted design and authentication workflow. Do not expose password hashes, session identifiers, internal account IDs, or private profile data to public surfaces.
15. Implement safe validation/rate-limiting using existing framework capabilities where appropriate for registration/sign-in. Do not introduce a broad identity-provider architecture or social login unless already required by accepted design.
16. Add focused automated tests covering at minimum: registration success; duplicate canonical identity rejection; password hashing/no plaintext persistence; sign-in success; invalid credentials fail safely; sign-out/session invalidation; collector-authenticated route protection; unauthenticated redirect/failure; collector session cannot access staff admin; staff admin session does not imply collector authentication; CSRF/session behavior as testable; registration/sign-in create no ownership/claim/transfer/sale-link changes; public passport remains unauthenticated and privacy-safe; no Shopify identity auto-link; real 404/403 behavior where the new collector surface requires it.
17. Include direct DB/invariant tests for collector uniqueness/credential integrity where relevant to the accepted schema.
18. Run collector-auth focused tests plus relevant SCA regressions for passport/auth/session/domain boundaries. Do not inflate testing beyond what the touched path requires, but run mandatory repository release checks.
19. Run `composer validate`, `composer audit`, and repository secret-safety checks for the task diff.
20. Create/update `docs/task-reports/SCA-COLLECTOR-AUTH-011.md` with concise implementation evidence, authentication/session model, collector/staff separation, stored identity fields, test counts, changed files, findings/deferrals, base SHA, and final branch SHA.
21. Make logical checkpoint commits and push `feat/sca-collector-auth-011`.
22. STOP after push for ChatGPT review. Do not create/merge a PR, do not deploy the feature branch, and do not start `SCA-CLAIM-012` or later tasks.

## Acceptance Gate

PASS requires:

- an independent SCA collector can securely register, sign in, maintain an authenticated session, and sign out;
- collector auth is separate from Krayin staff/admin auth;
- collector session cannot grant staff/admin access and staff session does not imply collector authentication;
- credentials are securely hashed and plaintext passwords/secrets are never persisted or exposed;
- canonical identity uniqueness/integrity is enforced;
- authentication/session failures fail safely without unnecessary account enumeration;
- registration/authentication creates NO ownership, claim, transfer, sale-link, certification, authentication, QR, or lifecycle mutation;
- no automatic Shopify customer/order identity linkage occurs;
- public passport behavior/privacy remains intact;
- no real credentials/secrets in git/report;
- no Krayin core/vendor changes;
- focused tests and mandatory checks pass;
- task report and implementation are committed and pushed.

## Deferred live Shopify configuration

Live Shopify OAuth activation and webhook registration remain deferred pending the permanent SCA HTTPS domain and secure server-side credentials. Do not reopen or work around this blocker during task 011.

## Completion Rule

When complete, report only:

1. branch and final HEAD SHA;
2. task report path;
3. focused test/assertion results and mandatory checks;
4. collector authentication/session model implemented;
5. collector/staff separation evidence;
6. identity fields stored and uniqueness/integrity behavior;
7. confirmation no ownership/claim/transfer/Shopify auto-link or domain lifecycle mutation occurred;
8. important blocker/deferral, if any;
9. confirmation everything is pushed.

Then STOP for ChatGPT review.

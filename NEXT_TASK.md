# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-PUBLIC-PASSPORT-008

## Title

Build the public SCA verification passport resolved by permanent QR identity

## Implementer

Claude

## Last completed

`SCA-CERT-QR-007` — PASS.

PR #8 accepted head:

`53c2f1ea002c123fbe51ca2fffd84dafd561a9fd`

Merged/deployed implementation `main`:

`0f7f08f5512115f6f7cc9b319740ffa52d928cbd`

Post-merge preview verification confirmed the retained DEMO item is `CERTIFIED`, with one issued certification and one active opaque QR identity. Stored identity values contain no host/IP/port/URL. The existing finalized passed authentication remains immutable. No public passport currently exists.

## Authority

Use implementation `main`, `docs/SCA-DOMAIN-DESIGN.md`, the accepted privacy classification/allowlist, canonical `sca_qr_identifiers`, certification/authentication/current-state structures, and existing SCA services/triggers as source of truth.

This task is the public READ surface only. It must resolve a certified item from the permanent opaque QR/public identity without exposing internal/private data or creating ownership/Shopify behavior.

## Objective

Build a public, unauthenticated SCA verification/passport page that resolves a valid active QR identity token to the correct certified eyewear item and displays only explicitly approved public provenance information.

The temporary preview can host a DEVELOPMENT demonstration route, but the stored QR token must remain host-independent. No database field may be rewritten to contain the preview IP/host. Production-domain binding remains a deployment concern.

## Required Work

1. Pull latest `Shopify-Jeremy/main`, this `NEXT_TASK.md`, and implementation `main` before starting.
2. Create branch:

`feat/sca-public-passport-008`

3. Inspect the accepted privacy classification in `docs/SCA-DOMAIN-DESIGN.md` and the exact canonical schemas before coding. Create a committed public-field allowlist in SCA-owned code. Default deny: a field is public only if explicitly allowlisted.
4. Build the passport in SCA-owned code only. Do not modify `app/packages/Webkul/**` or vendor code.
5. Add an unauthenticated public route resolved by the opaque active QR identity token. Use a neutral route shape such as `/verify/{token}` unless the accepted architecture already defines one. Do not expose internal numeric IDs in the public route.
6. Resolution must require an ACTIVE canonical QR identifier and bind through canonical current-state/certification/item relationships. Unknown, inactive, malformed, or wrong-item tokens must return a real public HTTP 404 with no existence leak.
7. Do not make certification public merely because a token exists. The resolved item must satisfy the accepted current certification/state requirements. Stale/inactive identities must not resolve as current certified passports.
8. The public response must be assembled through an explicit presenter/DTO/view-model containing only allowlisted fields. Do not pass raw DB rows/models wholesale to the public view.
9. Publicly display only fields explicitly approved by the canonical privacy policy. Expected categories, subject to the accepted design, include:
   - public SCA identity/certification reference;
   - authenticity/certification status;
   - approved eyewear descriptive fields such as brand/model/frame serial only where classified public;
   - approved condition grade/summary from the qualifying authentication;
   - approved certification/authentication dates/status summary;
   - high-level provenance/registry status intended for public verification.
10. Explicitly exclude staff IDs/names unless canonical policy specifically marks a public display identity; internal database IDs; private notes; authentication inspection notes; customer/contact data; emails/phones/addresses; owner/collector identity; Shopify customer/order identifiers; internal timestamps not allowlisted; internal ACL/role data; raw event payloads; secrets/configuration; and non-public media metadata.
11. Never expose the opaque QR token in page copy, HTML debug output, analytics payloads, page title, logs intentionally added by this task, or links beyond what is inherently present in the requested URL. Do not render certification `public_token` if it is security-sensitive unless the accepted privacy policy explicitly requires it; prefer the human-safe certification number/public reference.
12. Add safe cache behavior for a public verification surface. Do not allow personalized/staff data to be cached into the passport. If caching is introduced, key only on safe public identity and ensure status changes can invalidate/bypass stale certified results. Simpler no-store/no-cache behavior is acceptable for this task if safer.
13. Add basic abuse-resistant input handling: strict token format/length validation before lookup, constant-shape 404 behavior for malformed/unknown/inactive tokens, no SQL wildcard/prefix search, and no public enumeration/search endpoint.
14. Build a clean SCA-branded passport UI separate from Krayin admin chrome. It should clearly communicate:
   - Second Chance Authenticators verification;
   - certification/authenticity status;
   - item identity/details allowed publicly;
   - condition summary;
   - provenance/registry summary;
   - a clear DEVELOPMENT PREVIEW indicator when served from the current preview environment so clients do not mistake the IP for the permanent QR destination.
15. Do not expose an admin login/navigation surface on the public passport.
16. Registry/lost-stolen warning capability: inspect canonical current-state/status structures. If the current schema already supports an allowlisted public registry status, render it safely. If lost/stolen transitions are not yet implemented (`SCA-STATUS-016`), show only a truthful neutral current registry status supported by existing data and explicitly document that lost/stolen lifecycle management is deferred. Do not invent status rows.
17. Public provenance summary must be derived from canonical trusted records and should not reveal private event details. Prefer high-level facts/counts/statuses explicitly allowlisted by design rather than dumping event histories.
18. Preserve exact-item binding throughout token -> QR -> item -> certification -> authentication resolution. Never allow a token for Item A to render Item B data even if crafted parameters are supplied. The public route should need no item-id parameter at all.
19. The route/render layer must be read-only. No claim, ownership, transfer, Shopify, certification mutation, authentication mutation, or staff action may be available from the public passport.
20. Keep the retained DEMO certified item/QR available for post-merge preview verification. Automated tests must use disposable test DB fixtures, not the preview DB.
21. Add automated feature/integration/domain tests covering at minimum:
   - public passport route works without login for a valid active certified identity;
   - valid token resolves exact correct item;
   - malformed token -> real 404;
   - unknown well-formed token -> same real 404 behavior;
   - inactive QR token -> 404;
   - token whose item lacks current issued certification -> 404;
   - stale/non-current QR cannot resolve after identity changes where canonical lifecycle permits;
   - exact-item binding prevents cross-item certification/authentication data leak;
   - public HTML contains approved public fields/status only;
   - public HTML does NOT contain staff identifiers, private notes, authentication notes, owner/contact data, internal DB ids, Shopify refs, raw event payloads, or secrets;
   - opaque QR token is not rendered in page body/title/debug content;
   - no numeric item id is required/exposed by route;
   - no public enumeration/search route exists;
   - public route exposes no mutation actions;
   - DEVELOPMENT PREVIEW indicator appears under preview/non-production configuration and can be disabled for production configuration;
   - public response has safe cache headers;
   - existing certification tests remain passing;
   - existing authentication tests remain passing;
   - existing Registry tests remain passing;
   - existing provenance-domain tests remain passing.
22. Include direct DB/integrity regression coverage where needed to prove inactive/stale/wrong-item identity cannot be presented as current certification. Do not weaken triggers.
23. Run the complete relevant SCA test suite and record exact test/assertion counts.
24. Run `composer validate` and `composer audit` and record exact results.
25. Confirm no Shopify connection, collector account/claim/ownership, transfer/service/status mutation, certificate PDF/document generation, DNS/permanent-domain change, infrastructure change, Krayin core/vendor edit, or real customer data is introduced.
26. Create/update:

`docs/task-reports/SCA-PUBLIC-PASSPORT-008.md`

The report must include:
- exact implementation base SHA;
- canonical privacy policy/schema/services inspected;
- exact public allowlist implemented and rationale/source for each field;
- route/controller/presenter/view/config changed;
- token validation/resolution behavior;
- exact-item and stale/inactive protections;
- public cache/security headers;
- DEVELOPMENT PREVIEW behavior;
- public registry-status behavior and lost/stolen deferral if applicable;
- explicit negative list of private fields verified absent;
- test mapping and exact PASS/FAIL/assertion counts;
- certification/authentication/Registry/provenance regression results;
- `composer validate` / `composer audit` results;
- known limitations/technical debt;
- exact changed-file list;
- branch/final head SHA;
- explicit scope confirmation.
27. Make logical checkpoint commits throughout implementation.
28. Push `feat/sca-public-passport-008` to GitHub.
29. STOP after push. Do not create/merge a PR during implementation. Do not deploy the feature branch. Do not start `SCA-SHOPIFY-CONNECT-009`.

## Acceptance Gate

PASS requires:

- unauthenticated valid active QR identity resolves the exact certified item;
- malformed/unknown/inactive/stale/ineligible identities return real 404 without enumeration leak;
- public data is default-deny and emitted only through an explicit allowlisted presenter/DTO;
- no staff/private/owner/contact/Shopify/internal-event data leaks;
- opaque QR security token is not rendered in page content;
- public route is read-only, separate from admin chrome, and exposes no item-id enumeration/search;
- preview environment is clearly labeled DEVELOPMENT PREVIEW without changing permanent stored identity;
- safe cache behavior is present;
- exact-item binding remains intact;
- existing cert/auth/registry/provenance suites remain passing;
- no later-task scope creep or Krayin core/vendor changes;
- task report is committed and branch pushed.

## Merge / deployment workflow

Claude implements/tests/commits/pushes and STOPS. ChatGPT creates/audits the PR. Remediation stays on the same branch. After explicit AUDIT PASS, Claude may merge the exact accepted head and deploy accepted `main` only when explicitly authorized.

Living preview:

`http://195.26.255.80:8080`

A preview verification URL may be composed at runtime from the DEMO item's active QR token after merge. The preview URL is non-permanent and must never be stored as the item's identity.

## Completion Rule

When implementation is complete, report only:

1. branch name;
2. final branch head SHA;
3. task report path;
4. exact test/assertion summary;
5. important findings/blockers/deferrals;
6. confirmation everything is pushed.

Then STOP for ChatGPT audit.

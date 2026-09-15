# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-CERT-QR-007

## Title

Build staff certification issuance and stable SCA QR identity records

## Implementer

Claude

## Last completed

`SCA-ADMIN-AUTH-006` — PASS.

PR #7 accepted head:

`bb0b04140cf09d38b84e5f44374ce82e6d6190ba`

Merged/deployed implementation `main`:

`44301d69f31e3665aa07d332a5614d52a9789442`

Post-merge living-preview verification confirmed authentication inspection, condition grading, exact-item binding, real 404 semantics, finalized-history immutability, and that authentication does not create certification. The retained DEMO item has one clearly marked finalized passed authentication (grade A) and lifecycle `AUTHENTICATED`.

## Authority

Use implementation `main`, `docs/SCA-DOMAIN-DESIGN.md`, the accepted provenance domain services/triggers, and the existing SCA Registry/authentication workflow as source of truth.

Canonical certification and QR tables/invariants win over task wording. Inspect the exact accepted `sca_certifications`, `sca_qr_identities`, `sca_item_current_state`, authentication structures, identifier policy, triggers, and domain services before implementing.

Certification is a distinct state transition from authentication. A passed authentication does not itself mean certified. Certification issuance must explicitly reference an eligible finalized passed authentication for the SAME eyewear item.

## Objective

Create the staff-facing certification workflow for eligible authenticated eyewear and establish a permanent, host-independent SCA QR identity record that later public-passport routing can resolve.

This task establishes certification and stable identity data. It must NOT make the temporary development IP a permanent QR destination and must NOT build the full public passport, Shopify integration, collector ownership/claim, or printable certificate-document system.

## Required Work

1. Pull latest `Shopify-Jeremy/main`, this `NEXT_TASK.md`, and implementation `main` before starting.
2. Create branch:

`feat/sca-cert-qr-007`

3. Inspect and document the exact canonical certification/QR schema, identifier policy, lifecycle/current-state behavior, services, and DB triggers before coding. If task wording conflicts with the accepted canonical design, canonical design wins; stop only for a genuine architecture blocker.
4. Extend only SCA-owned modules/code. Do not modify `app/packages/Webkul/**`, vendor code, or generic Krayin entities to store canonical certification/QR data.
5. Add appropriate SCA staff ACL permissions for certification viewing/issuance. Preserve real unauthenticated protection and real HTTP 403 semantics for authenticated restricted staff.
6. Integrate certification into the existing SCA eyewear detail workflow. Staff should see certification eligibility/status/history appropriate to the canonical model.
7. Certification issuance must require an eligible authentication that is:
   - for the exact same eyewear item;
   - `passed`;
   - finalized;
   - otherwise eligible according to accepted domain invariants.
8. Failed, inconclusive, draft/unfinalized, nonexistent, and cross-item authentications must never issue certification. Return real 404 for nonexistent/cross-item resources where resource hiding is appropriate, and validation/domain rejection for ineligible same-item resources.
9. Use the accepted certification service/integrity layer. Do not bypass existing same-item/finalization triggers or weaken them.
10. Generate certification identity/reference values only through the canonical SCA identifier mechanism. Staff must not choose arbitrary certification/public identity values.
11. Establish/activate the canonical QR identity for the exact certified item according to the accepted one-active-QR-per-item rule. Reuse canonical `sca_qr_identities`; do not invent a second QR table.
12. QR/public identity tokens must be high-entropy, opaque, stable, and host-independent. Persist the identity token/reference, NOT a permanent URL containing `195.26.255.80`, port `8080`, localhost, a staging hostname, or another environment-specific host.
13. Do not generate or encode a permanent scannable QR destination until the Jeremy-controlled production public route/domain is approved. If a visual QR preview is useful for staff demonstration, it must be clearly marked DEVELOPMENT/NON-PERMANENT and derived from a non-authoritative preview route/config without changing the stored permanent identity. Prefer deferring QR-image generation entirely if doing it safely would introduce architecture or dependencies outside this task.
14. Update `sca_item_current_state` only through accepted certification/domain behavior. After successful certification, the canonical lifecycle/certification state must reflect certification without overwriting immutable authentication evidence.
15. Prevent duplicate certification issuance where the canonical model requires one active/issued certification for the same qualifying state. Ensure retries/double-clicks cannot create conflicting active certification or QR identities.
16. Certification/QR records must obey canonical append-only/immutability rules. Do not expose hard-delete or in-place historical-edit staff actions.
17. Keep the existing DEMO item and finalized DEMO passed authentication available for living-preview verification after merge. Automated tests must use the disposable test DB, not preview data.
18. Add automated feature/integration/domain tests covering at minimum:
   - unauthenticated certification routes protected;
   - restricted authenticated staff receives real HTTP 403;
   - eligible finalized passed authentication can be certified;
   - draft/unfinalized passed authentication cannot be certified;
   - failed authentication cannot be certified;
   - inconclusive authentication cannot be certified;
   - nonexistent authentication returns real HTTP 404 where routed by id;
   - cross-item authentication cannot certify another item and does not leak data;
   - generated certification reference/token is server-generated and unique;
   - staff/client input cannot spoof certification/public identity token;
   - certification creates/activates the correct canonical QR identity for the same item;
   - one active QR identity per item is preserved under retry/double-submit/concurrency-relevant paths;
   - QR identity/token contains no preview host/IP/port and is host-independent;
   - successful certification updates the correct current-state projection;
   - certification does not alter/delete the finalized authentication evidence;
   - no certification/QR history hard-delete/edit route is exposed;
   - one item's certification/QR information cannot leak into another item's detail page;
   - existing authentication tests remain passing;
   - existing Registry tests remain passing;
   - existing provenance-domain tests remain passing.
19. Include direct DB/integrity regression tests for same-item, finalized-passed eligibility, certification immutability, and one-active-QR constraints where application tests alone could mask trigger failures. Do not weaken production triggers.
20. Run the complete relevant SCA test suite and record exact test/assertion counts.
21. Run `composer validate` and `composer audit` and record exact results.
22. Confirm no public-passport implementation, permanent preview-IP URL, Shopify connection, collector auth/claim/ownership, transfer/service/status/document generation, DNS/infrastructure change, Krayin core/vendor edit, or real customer data is introduced.
23. Create/update:

`docs/task-reports/SCA-CERT-QR-007.md`

The report must include:
- exact implementation base SHA;
- canonical certification/QR tables, services, identifier rules, triggers, and current-state behavior inspected/reused;
- routes/controllers/services/views/ACL changed;
- certification eligibility and issuance behavior;
- exact same-item protections;
- generated certification/public identity behavior;
- QR identity lifecycle and one-active-QR enforcement;
- explicit proof stored identities are host-independent and do not contain preview IP/port;
- idempotency/retry/concurrency behavior;
- immutable-history protections;
- UI behavior on item detail;
- any QR-image generation intentionally deferred and why;
- test mapping and exact PASS/FAIL/assertion counts;
- authentication/Registry/provenance regression results;
- `composer validate` / `composer audit` results;
- known limitations/technical debt;
- exact changed-file list;
- branch/final head SHA;
- explicit scope confirmation.
24. Make logical checkpoint commits throughout implementation.
25. Push `feat/sca-cert-qr-007` to GitHub.
26. STOP after push. Do not create/merge a PR during implementation. Do not deploy the feature branch. Do not start `SCA-PUBLIC-PASSPORT-008`.

## Acceptance Gate

PASS requires:

- certification can be explicitly issued only from a same-item finalized passed authentication;
- authentication remains distinct and immutable;
- canonical certification and QR identity records are used;
- certification/public identity values are server-generated and cannot be spoofed;
- stable stored QR identity is host-independent and contains no temporary preview address;
- one-active-QR and duplicate/retry protections hold;
- current-state projection reflects certification correctly;
- real 403/404 semantics and exact-item resource hiding are preserved;
- no public passport, permanent preview QR URL, Shopify, ownership, or later-task scope creep;
- existing auth/registry/provenance suites remain passing;
- no Krayin core/vendor changes;
- task report is committed and branch pushed.

## Merge / deployment workflow

Claude implements/tests/commits/pushes and STOPS. ChatGPT creates/audits the PR. Remediation stays on the same branch. After ChatGPT explicitly declares AUDIT PASS, Claude may merge the exact accepted head and deploy accepted `main` only when explicitly authorized.

Living preview:

`http://195.26.255.80:8080`

Never store that address as permanent SCA QR identity and never deploy an unaudited feature branch.

## Completion Rule

When implementation is complete, report only:

1. branch name;
2. final branch head SHA;
3. task report path;
4. exact test/assertion summary;
5. important findings/blockers/deferrals;
6. confirmation everything is pushed.

Then STOP for ChatGPT audit.

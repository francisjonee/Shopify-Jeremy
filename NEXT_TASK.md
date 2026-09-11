# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-KRAYIN-HARDEN-001

**RETRY_GENERATION:** 1

## Title

Complete the missing Krayin v2.2.6 security-report coverage in PR #2 and return for re-audit

## Implementer

Claude

## Authority

ChatGPT audited the first pass of `SCA-KRAYIN-HARDEN-001`. The narrow hardening changes themselves are acceptable so far, but the security review is incomplete against the explicit task scope.

Authoritative implementation repository:

`francisjonee/francisjonee-sca-platform-private`

Authoritative implementation PR:

`#2`

Continue on the existing branch:

`chore/sca-krayin-harden-001`

PR #2 is open and must remain unmerged. Do not start any follow-on task.

## Audit Finding

The report checked several CVEs, SQL injection, IDOR, installer takeover, and upload behavior, but it did not explicitly investigate/disposition all security-report classes required by the original task.

In particular, current public Krayin reports include at least:

- GitHub issue #2560: unauthenticated email injection through `/admin/mail/inbound-parse`, confirmed by the reporter against v2.2.3. This must be checked against the exact pinned v2.2.6 source/runtime rather than assumed fixed.
- GitHub issue #2616: privilege escalation / unrestricted role assignment, reported for Krayin <=2.2.5. Verify the exact v2.2.6 behavior and code path.
- GitHub issue #2617: stored XSS via client-controlled upload validation, reported for Krayin <=2.2.5. Verify the exact v2.2.6 behavior/code path.

The original task explicitly required investigation of XSS, authorization/role escalation, unauthenticated email abuse/injection, SQL injection, IDOR/missing authorization, and other high-impact reports. A PASS cannot omit these named classes.

## Required Remediation

1. Pull the latest `Shopify-Jeremy/main` and read this file.
2. Stay on `chore/sca-krayin-harden-001`; do not create a new task branch.
3. Inspect the exact Krayin v2.2.6 source and relevant runtime behavior for issue #2560 unauthenticated inbound-email injection. Determine whether `/admin/mail/inbound-parse` is unauthenticated, whether AJAX bypass behavior remains, whether webhook/signature verification exists, and whether an unauthenticated request can create/inject CRM email data. Use safe test data only and remove it afterwards.
4. Inspect issue #2616 privilege escalation against v2.2.6. Verify whether a restricted/custom-role user can assign or obtain a full-admin/all-permission role or otherwise escalate through user/role management. Record exact code/runtime evidence.
5. Inspect issue #2617 stored XSS/upload validation against v2.2.6. Verify the relevant upload/configuration path and output behavior with safe non-destructive test payloads. Record exact evidence.
6. Re-check the broader XSS class sufficiently to explain the status of the known notes/activity XSS fixes in the pinned release where relevant; do not rely only on version labels.
7. For every finding, use one of VERIFIED, NOT APPLICABLE, REMEDIATED, ACCEPTED RISK, or BLOCKED and explain why.
8. If any of these issues actually affects v2.2.6 and can be narrowly mitigated without modifying Krayin core/vendor or changing architecture, propose/implement the narrow safe mitigation permitted by the original task. If remediation requires core/vendor changes, a major upgrade, architectural change, or uncertain compatibility, do not improvise: mark RESULT=BLOCKED and give exact options for ChatGPT decision.
9. Re-run only the regression/security checks needed after any remediation: dependency audit, login/dashboard, SCA Foundation, authorization boundary, safeguard, database/migrations, and relevant exploit regression. If no runtime/config change is made, avoid unnecessary unrelated changes.
10. Update `docs/task-reports/SCA-KRAYIN-HARDEN-001.md` with a clearly labeled remediation generation 1 section, exact findings/evidence, test cleanup, commit SHA(s), and PR #2 reference.
11. Reconcile RESULT with the report. Do not state `RESULT=PASS` while also claiming an unresolved material security BLOCKER. A known future prerequisite may be documented as blocked for production use, but the report must clearly distinguish task completion from a blocker that prevents real data/public exposure.
12. Push to the existing branch and leave PR #2 open and unmerged.
13. STOP for ChatGPT re-audit.

## Preserve Accepted Work

Do not undo the already-supported narrow changes unless new evidence requires it:

- MariaDB image digest pinning;
- baseline Apache response headers;
- `.dockerignore` build-context hygiene.

## Prohibited Changes

Do not:

- merge PR #2;
- modify Krayin core/vendor merely to silence a finding;
- start provenance/eyewear/authentication/certification/QR/collector/transfer/service/Shopify work;
- expose the app publicly or change DNS;
- introduce PostgreSQL;
- perform broad dependency/framework upgrades;
- invent off-server backup credentials/provider;
- advance the roadmap/task queue;
- self-approve.

## Acceptance Criteria

Return PASS only if the missing security-report classes are explicitly checked against v2.2.6 with evidence; any applicable material issue is safely remediated or correctly returned as BLOCKED for architecture decision; test data is removed; regression remains healthy; the report is internally consistent; and PR #2 remains open/unmerged.

## Completion Rule

After pushing remediation evidence to PR #2:

**STOP.**

Wait for ChatGPT re-audit.
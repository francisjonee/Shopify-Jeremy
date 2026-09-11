# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-KRAYIN-HARDEN-001

**RETRY_GENERATION:** 2

## Title

Clean final hardening report status wording in PR #2 and return for final re-audit

## Implementer

Claude

## Authority

ChatGPT re-audited remediation generation 1 for `SCA-KRAYIN-HARDEN-001` in implementation PR #2.

The security remediation itself now passes the technical audit:

- Krayin issue #2560 was confirmed applicable to pinned v2.2.6 and is now mitigated with SCA-owned, default-closed inbound-email middleware returning a real HTTP 403;
- issue #2616 privilege escalation was checked against v2.2.6 and found not applicable/fixed with role-assignment guards and ACL boundaries;
- issue #2617 stored-XSS/upload validation was checked against v2.2.6 and found not applicable/fixed with server-side extension handling and sanitization;
- broader XSS handling, regressions, dependency audit, safeguard, login/dashboard, migrations and SCA Foundation remain healthy;
- no Krayin core/vendor modification was introduced.

Authoritative implementation repository:

`francisjonee/francisjonee-sca-platform-private`

Authoritative implementation PR:

`#2`

Continue on existing branch:

`chore/sca-krayin-harden-001`

Do not start any follow-on task.

## Final Audit Finding

Only current-state documentation is stale.

The task report still contains present-tense lines inherited from the first pass, including:

- top metadata: `PR: to be opened by the operator — see § 9.`
- §9: wording that says the operator still needs to open the PR;
- §10: `Only three files` even though remediation generation 1 added additional SCA-owned files;
- any similar current-state wording that implies PR #2 does not yet exist or that the task still has only the generation-0 file set.

PR #2 is already open and unmerged. The current report must describe that accurately while preserving historical narrative where useful.

## Required Remediation

1. Edit only `docs/task-reports/SCA-KRAYIN-HARDEN-001.md` unless a strictly necessary documentation reference elsewhere requires correction.
2. Change current-state PR metadata/status so it says PR #2 is open and unmerged, awaiting ChatGPT final audit.
3. Correct §9/current PR wording so it no longer says the operator still needs to open the PR.
4. Correct §10/current file-count wording so it reflects the complete task state after remediation generation 1, or clearly label the three-file list as generation-0-only history.
5. Preserve generation-1 security evidence and all technical remediation exactly; do not alter application code, dependency versions, container configuration, middleware behavior, architecture, or product scope.
6. Keep historical narrative only where it is clearly labeled as history and cannot be mistaken for current state.
7. Push the documentation-only correction to the existing branch feeding PR #2.
8. Leave PR #2 open and unmerged.
9. STOP for ChatGPT final re-audit.

## Acceptance Criteria

PASS only if:

- PR #2 current status is accurately documented as open and unmerged;
- no current-state line says a PR still needs to be opened;
- current changed-file description no longer incorrectly says only three files for the complete task;
- generation-1 security findings/remediation remain unchanged;
- no code/config/dependency changes are introduced;
- PR #2 remains open and unmerged.

## Prohibited Changes

Do not:

- merge PR #2;
- change application code or security middleware;
- change dependencies or Docker configuration;
- start provenance/eyewear/authentication/certification/QR/collector/transfer/service/Shopify work;
- change DNS/public exposure;
- advance any queued task;
- self-approve.

## Completion Rule

After pushing the documentation-only correction:

**STOP.**

Wait for ChatGPT final re-audit.

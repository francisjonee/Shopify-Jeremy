# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-KRAYIN-HARDEN-001

## Title

Harden the accepted Krayin v2.2.6 foundation before SCA provenance development

## Implementer

Claude

## Authority

PR #1 for `SCA-KRAYIN-INSTALL-001` passed ChatGPT final architecture/security audit and was merged into the implementation repository on 2026-09-12.

Merged implementation repository:

`francisjonee/francisjonee-sca-platform-private`

Merge commit:

`4d585511b8578d3e330f62a44defe7c858253a24`

This task is the next governed task. Do not start provenance, eyewear, authentication, certification, QR, collector, transfer, service, or Shopify feature work.

## Goal

Perform a formal security-hardening pass on the exact accepted Krayin v2.2.6 foundation before SCA stores real provenance data or is exposed publicly.

The purpose is to identify, verify, remediate where narrowly safe, and document security/operational risks in the current foundation without redesigning the product.

## Read First

- `docs/ADR-0006-KRAYIN-CRM-ADMIN-FOUNDATION.md`
- `docs/ARCHITECTURE.md`
- `docs/ROADMAP.md`
- `TASK_QUEUE.md`
- `docs/EXECUTION_WORKFLOW.md`
- this `NEXT_TASK.md`
- `docs/task-reports/SCA-KRAYIN-INSTALL-001.md` in the implementation repository

## Required Work

1. Sync implementation `main` and create a new task branch for `SCA-KRAYIN-HARDEN-001`.
2. Record the exact starting Krayin, Laravel, PHP, Composer, MariaDB, Docker image, and dependency versions.
3. Re-run dependency/security audits and record exact evidence. Do not perform broad dependency upgrades merely because newer versions exist.
4. Investigate current security reports relevant to the exact Krayin v2.2.6 codebase, including reported classes of issue such as XSS, authorization/role escalation, unauthenticated email abuse/injection, SQL injection, IDOR/missing authorization, and other high-impact reports discovered during the review. Verify applicability against the pinned code; do not assume every public report affects this release.
5. Audit authentication and authorization boundaries for Krayin staff/admin routes and the SCA Foundation route. Confirm restricted staff cannot access full-admin-only operations.
6. Re-run and preserve the accepted default-admin safeguard, including confirmation that only another active full administrator can satisfy its lockout guard.
7. Audit public exposure assumptions: app remains loopback-only for this task; no DNS/public endpoint changes. Identify what must be in place before future HTTPS/public exposure, including rate limiting and safe error behavior.
8. Review sensitive-file and secret exposure, Laravel production/debug settings, session/cookie/security headers where applicable, database network exposure, file permissions, and container isolation.
9. Review Docker/container image pinning and supply-chain reproducibility. Record mutable tags/digests or other reproducibility gaps; make only narrow changes that are clearly safe and justified.
10. Verify backup security and operational readiness. Off-server encrypted backup is a known gap. Do not place real provenance data into the system until durable off-server backup exists. If implementing an off-server destination requires credentials/provider decisions not already authorized, document the blocker rather than inventing credentials or providers.
11. Verify backup/restore still works after any hardening changes.
12. Re-run minimum runtime regression: login, dashboard, SCA Foundation route, migrations/database, dependency audit, safeguard, restart persistence, and sensitive-path checks.
13. Create and commit `docs/task-reports/SCA-KRAYIN-HARDEN-001.md` in the implementation repository. It must distinguish VERIFIED, NOT APPLICABLE, REMEDIATED, ACCEPTED RISK, and BLOCKED findings; include commands/evidence, exact versions, limitations, technical debt, recommendations, commit SHAs, and PR reference.
14. Make logical checkpoint commits throughout the work. Do not leave all findings only in terminal/chat.
15. Push the branch and open a pull request into implementation `main` if available. If the VPS still cannot call the GitHub API, push the branch and return the exact branch name so the operator can open the PR. Do not treat inability to open a PR as permission to merge.
16. STOP for ChatGPT audit. Do not merge or start another task.

## Security Remediation Rule

Claude may make narrow hardening changes inside this task when they are directly supported by evidence and do not alter SCA product architecture. Examples include safe configuration, SCA-owned guards/middleware, container/runtime hardening, or dependency patch-level remediation compatible with the pinned foundation.

If a finding requires a Krayin core modification, major framework/dependency upgrade, architectural change, new external provider, or uncertain compatibility, document it and stop for ChatGPT decision rather than improvising.

## Acceptance Criteria

Return `RESULT=PASS` only if:

- exact foundation versions are recorded;
- dependency audit is clean or every remaining advisory is explicitly evaluated and dispositioned;
- relevant Krayin security reports are checked against the pinned v2.2.6 code and dispositioned with evidence;
- staff authentication/authorization boundaries are tested;
- the SCA admin safeguard remains effective;
- sensitive files/secrets are not exposed;
- production/debug/database/container boundaries remain safe for the current loopback staging state;
- public-exposure prerequisites and rate-limiting gaps are explicitly documented;
- backup/restore remains proven and off-server-backup readiness is explicitly addressed;
- runtime regression checks pass;
- no SCA product-domain feature work has started;
- no Krayin core/vendor modification is hidden or casually introduced;
- task report and checkpoint commits are pushed;
- implementation PR is left open and unmerged for ChatGPT audit.

If a material security blocker remains unresolved, return `RESULT=BLOCKED` with exact evidence and recommended options rather than `PASS`.

## Prohibited Changes

Do not:

- merge your own PR;
- expose Krayin publicly or change DNS;
- create real provenance/customer production data;
- start SCA domain/provenance schema work;
- start Shopify integration;
- build QR/public passport/collector features;
- introduce PostgreSQL;
- perform broad or major dependency/framework upgrades without architecture approval;
- modify Krayin core/vendor merely to silence a finding;
- invent external credentials, storage providers, or production infrastructure;
- advance the task queue yourself.

## Completion Rule

After pushing the hardening branch/report and opening or identifying the PR:

**STOP.**

Wait for ChatGPT architecture/security audit.
# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-KRAYIN-INSTALL-001

**RETRY_GENERATION:** 1

## Title

Remediate the Krayin foundation security findings from PR #1 and return it for re-audit

## Implementer

Claude

## Authority

This is a narrow remediation generation issued after ChatGPT audit of implementation PR #1.

Authoritative implementation repository:

`francisjonee/francisjonee-sca-platform-private`

Authoritative implementation PR:

`#1`

Continue on the existing branch:

`chore/sca-krayin-install-001`

Do not start any queued follow-on task.

## Read First

- `docs/ADR-0006-KRAYIN-CRM-ADMIN-FOUNDATION.md`
- `docs/ARCHITECTURE.md`
- `docs/ROADMAP.md`
- `TASK_QUEUE.md`
- `docs/EXECUTION_WORKFLOW.md`
- the current PR #1 audit comment
- `docs/task-reports/SCA-KRAYIN-INSTALL-001.md` in the implementation repository
- this `NEXT_TASK.md`

## Audit Status

The foundation installation itself is substantially accepted: Krayin v2.2.6 is installed, MariaDB persistence works, restart/backup/restore evidence exists, the SCA Foundation extension loads without vendor/core edits, and the implementation branch/PR history is now valid.

PR #1 must **not** merge yet because the pinned dependency set still contains `maatwebsite/excel 3.1.68`, which the committed task report identifies under a HIGH security advisory, while a compatible fixed release is available. The fresh-install process also needs a repeatable safeguard preventing Krayin's documented default super-admin credentials from remaining active.

## Required Remediation

1. Keep Krayin itself pinned to the approved v2.2.6 baseline unless this task explicitly requires otherwise.
2. Update only the necessary Composer dependency set so `maatwebsite/excel` is on a non-vulnerable compatible release, at minimum `3.1.70` or a later compatible release within Krayin's declared constraint.
3. Keep the dependency change minimal. Do not perform an unrelated broad Composer upgrade.
4. Run and record:
   - `composer validate`;
   - `composer audit`;
   - the resulting installed/locked `maatwebsite/excel` version.
5. The HIGH advisory reported for `maatwebsite/excel 3.1.68` must no longer be present before PASS.
6. Add a repeatable SCA-owned fresh-install safeguard/check ensuring Krayin's known default `admin@example.com` / `admin123` super-admin cannot remain active after installation.
   - Do not edit `app/packages/Webkul/**` or `vendor/**`.
   - The safeguard may be an SCA-owned install/check script or equivalent automated validation.
   - It must fail loudly or remediate safely if the default account remains.
   - Do not commit a real administrator credential.
7. Re-run the existing foundation smoke evidence after the dependency/safeguard changes:
   - app responds;
   - login page loads;
   - administrator login succeeds with credentials redacted;
   - dashboard loads;
   - database/migrations healthy;
   - SCA Foundation route/module still loads;
   - controlled restart preserves data/login;
   - backup and isolated restore sanity still succeed.
8. Confirm again:
   - no default/example admin credential remains active;
   - no real secret is committed;
   - no vendor/core modification exists;
   - no public DB exposure;
   - no permanent QR/DNS/Shopify work occurred.
9. Update `docs/task-reports/SCA-KRAYIN-INSTALL-001.md` with:
   - remediation generation 1;
   - new dependency version;
   - Composer validate/audit results;
   - fresh-install safeguard path and behavior;
   - smoke/restart/backup evidence;
   - any new findings;
   - final result;
   - new remediation commit SHA(s);
   - PR #1 reference.
10. Push the remediation commits to the existing `chore/sca-krayin-install-001` branch.
11. Leave PR #1 open and **unmerged**.
12. Return evidence and STOP for ChatGPT re-audit.

## Acceptance Criteria

Return `RESULT=PASS` only if all are true:

- `maatwebsite/excel` is no longer on the vulnerable 3.1.68 release;
- the previously reported HIGH advisory is absent from `composer audit`;
- Composer validation succeeds or any non-security warning is explicitly documented;
- repeatable fresh-install safeguard/check prevents the default Krayin super-admin credentials from remaining active;
- existing app/login/dashboard/database/SCA-module smoke tests pass;
- restart persistence still passes;
- backup and isolated restore sanity still pass;
- no secrets/default credentials are committed;
- no vendor/core modifications remain;
- task report is updated and committed;
- PR #1 remains open and unmerged;
- no queued feature task has started.

## Prohibited Changes

Do not:

- merge PR #1;
- change Krayin core/vendor files;
- start eyewear/provenance/authentication/QR/collector/Shopify work;
- change DNS;
- introduce PostgreSQL;
- perform an unrelated broad dependency/framework upgrade;
- change architecture/roadmap/task queue;
- invent the next task;
- self-approve.

## Completion Rule

After pushing the remediation commits and returning evidence:

**STOP.**

Wait for ChatGPT to re-audit PR #1.
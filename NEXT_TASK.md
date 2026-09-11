# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-KRAYIN-INSTALL-001

**RETRY_GENERATION:** 2

## Title

Fix the Krayin admin-security safeguard lockout bug in PR #1 and return it for final re-audit

## Implementer

Claude

## Authority

This is a narrow remediation generation issued after ChatGPT re-audit of implementation PR #1.

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
- `docs/task-reports/SCA-KRAYIN-INSTALL-001.md` in the implementation repository
- this `NEXT_TASK.md`

PR comments are audit history only. Do not depend on access to GitHub PR comments for executable instructions. This file is the authoritative instruction for this remediation.

## Audit Status

Generation 1 successfully remediated the original two blockers:

- `maatwebsite/excel` was updated from vulnerable 3.1.68 to 3.1.70 and the task report records a clean `composer audit`;
- an SCA-owned `sca:verify-admin-security` safeguard and operator wrapper were added and tested.

However, ChatGPT re-audit found a lockout-safety defect in the safeguard. The safeguard must not consider an arbitrary active CRM user to be a replacement administrator. A restricted/non-admin staff user does not make it safe to deactivate the only active full administrator.

PR #1 remains open and must not merge until this is corrected and re-audited.

## Required Remediation

1. Inspect the current implementation of:
   - `app/packages/Sca/Foundation/src/Console/Commands/VerifyAdminSecurity.php`;
   - `scripts/verify-admin-security.sh`;
   - relevant Krayin User/Role models and role semantics.
2. Correct the `--fix` lockout guard so an unsafe/default administrator may be deactivated only when another active **full administrator** exists.
3. Do not count a normal active CRM user or restricted/custom-role staff member as a safe replacement administrator.
4. Use Krayin's actual role semantics to determine full administrative capability. The current Krayin baseline represents the administrator role with `permission_type = all`; implement the check robustly through the user's role relationship/role data rather than merely counting active users.
5. Preserve safe behavior: if the unsafe account is the only active full administrator, `--fix` must refuse loudly and return non-zero rather than locking administrators out.
6. Prove the safeguard with explicit tests and record results:
   - unsafe/default admin + no other active user -> refuse;
   - unsafe/default admin + active restricted/non-admin user -> **refuse**;
   - unsafe/default admin + another active full administrator -> remediation may proceed safely;
   - after safe remediation, rerun -> PASS;
   - remove all temporary test accounts/data after testing.
7. Keep all safeguard code SCA-owned. Do not edit `app/packages/Webkul/**` or `vendor/**`.
8. Re-run the minimal regression checks after the fix:
   - `composer validate`;
   - `composer audit` remains free of the previously reported HIGH advisory;
   - locked/installed `maatwebsite/excel` remains on the remediated compatible release;
   - app/login/dashboard still work;
   - SCA Foundation route/module still works;
   - migrations/database remain healthy;
   - admin-security safeguard passes on the final database state.
9. Update `docs/task-reports/SCA-KRAYIN-INSTALL-001.md`:
   - add remediation generation 2;
   - explain the lockout bug and exact correction;
   - record all three role/lockout test scenarios and results;
   - record regression/security results;
   - record generation-2 commit SHA(s);
   - keep PR #1 reference;
   - set final RESULT accurately.
10. Clean stale statements in the existing report that still describe the `maatwebsite/excel` CVE as unresolved. Historical sections may state that it was originally found, but current technical-debt/recommendation sections must clearly say it is resolved in generation 1 and must not recommend resolving an already-fixed issue.
11. Push the remediation commits to the existing `chore/sca-krayin-install-001` branch.
12. Leave PR #1 open and **unmerged**.
13. Return evidence and STOP for ChatGPT final re-audit.

## Acceptance Criteria

Return `RESULT=PASS` only if all are true:

- the safeguard requires another active full administrator before deactivating an unsafe/default administrator;
- a restricted/non-admin active user cannot satisfy the lockout guard;
- the three required lockout scenarios are tested and documented;
- `maatwebsite/excel` remains on the remediated compatible release and `composer audit` remains clean of the previously reported HIGH advisory;
- app/login/dashboard/database/SCA Foundation regression checks pass;
- no default/example admin credential remains active in the final state;
- no test users/data remain;
- no real secret is committed;
- no Krayin vendor/core modification is introduced;
- stale current-state CVE statements in the task report are corrected;
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
- perform unrelated dependency/framework upgrades;
- change architecture/roadmap/task queue beyond this authorized NEXT_TASK update;
- invent or start the next task;
- self-approve.

## Completion Rule

After pushing the generation-2 remediation commits and returning evidence:

**STOP.**

Wait for ChatGPT to re-audit PR #1.
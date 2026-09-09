# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-CTRL-001

**RETRY_GENERATION:** 1

## Title

Prove controller dry-run and duplicate suppression

## Implementer

Claude

## Objective

Remediate the missing acceptance evidence from `SCA-CTRL-001` generation 0.

The controller source was merged before its required dry-run proof existed. This retry is **evidence/remediation only**. Do not expand into SCA product work and do not enable unattended/live execution.

## Required Inputs

Read first:

- `README.md`
- `CLAUDE.md`
- `docs/EXECUTION_WORKFLOW.md`
- `docs/ADR-0003-CLAUDE-TASK-CONTROLLER.md`
- `docs/ADR-0004-VPS-HOSTING-SUPERSEDES-ADR-0001.md`
- `docs/CONTROLLER.md`
- this `NEXT_TASK.md`

## Work

1. Confirm the installed controller on the VPS corresponds to the controller source currently on `main` or report the exact drift before proceeding.
2. Confirm the controller remains in safe mode:
   - non-root `sceyewear` service account;
   - unattended/systemd execution disabled;
   - `SCA_ALLOW_LIVE=0` or equivalent live-dispatch guard still disabled.
3. Run the controller status command and capture the relevant output.
4. Run **one dry-run dispatch** for `SCA-CTRL-001#1` using the documented controller command.
5. Capture evidence that the dispatch key was recorded and the controller did **not** invoke Claude live.
6. Run the **same dry-run a second time** without changing `TASK_ID` or `RETRY_GENERATION`.
7. Capture evidence that the second attempt is suppressed as a duplicate and does not create a second dispatch.
8. Capture the controller state and recent append-only audit log showing the first dry-run and duplicate suppression.
9. If a controller defect prevents this proof, make only the smallest controller fix needed, test it, commit it on the task branch, open/update the PR, and return the diff/commit evidence. Do not redesign the controller.
10. After returning evidence, STOP for ChatGPT audit.

## Acceptance Criteria

Return all of the following:

- `RESULT=PASS` or a specific `BLOCKED_*` result;
- controller installed-source vs `main` comparison result;
- service account confirmation;
- live/unattended mode confirmation;
- exact status command and relevant output;
- exact first dry-run command and relevant output;
- dispatch key evidence for `SCA-CTRL-001#1`;
- proof that no live Claude invocation occurred during dry-run;
- exact second dry-run command and relevant output;
- explicit duplicate-suppression evidence;
- state file/ledger evidence sufficient to prove only one dispatch key was recorded;
- audit-log evidence showing the first dry-run and duplicate suppression;
- branch/commit/PR reference only if code/docs required remediation;
- environment variable **names only**, values redacted;
- security findings, if any.

## Prohibited Changes

- Do not build SCA product features.
- Do not connect or modify the live Shopify store.
- Do not deploy the SCA product application.
- Do not modify DNS.
- Do not publish permanent QR URLs.
- Do not add/change Shopify scopes.
- Do not enable unattended/systemd controller execution.
- Do not set `SCA_ALLOW_LIVE=1`.
- Do not run the controller with `--live`.
- Do not copy root credentials into the service account.
- Do not expose credential values.
- Do not auto-merge any PR.
- Do not invent the next task.
- Do not self-approve.

## Required Evidence

Provide concise, real command output sufficient for ChatGPT to independently verify every acceptance criterion. Redact secret values and customer/private data.

## Completion Rule

After returning the required evidence, **STOP**.

Wait for ChatGPT architecture audit. Claude may resume only after ChatGPT replaces/revises `NEXT_TASK.md` with an approved `STATUS: READY` task.

## Last Completed

Controller source from generation 0 was merged, but its required dry-run and duplicate-suppression proof was missing. Generation 1 exists only to close that evidence gap safely.

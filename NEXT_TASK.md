# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-CTRL-002

**RETRY_GENERATION:** 0

## Title

Prove one controlled live Claude dispatch

## Implementer

Claude

## Objective

Prove the controller can complete one real end-to-end Claude Code dispatch safely under the non-root service account.

This task validates the live execution path only. Unattended scheduling must remain disabled until this task is audited and accepted by ChatGPT.

## Required Inputs

Read first:

- `README.md`
- `CLAUDE.md`
- `docs/EXECUTION_WORKFLOW.md`
- `docs/ADR-0003-CLAUDE-TASK-CONTROLLER.md`
- `docs/ADR-0004-VPS-HOSTING-SUPERSEDES-ADR-0001.md`
- `docs/CONTROLLER.md`
- `audits/SCA-CTRL-001-gen1-PASS.md`
- this `NEXT_TASK.md`

## Work

1. Confirm the installed controller still matches the source on current `main`, or report exact drift and STOP before live execution.
2. Confirm the controller service account is `sceyewear` and is non-root.
3. Establish the minimum authentication needed for the `sceyewear` account to run Claude Code and push/open a pull request for this repository.
   - Do **not** copy root credentials.
   - Prefer account-native or least-privilege authentication scoped only as broadly as required.
   - Never print, commit, paste into a PR, or return any secret/token value.
   - If interactive human authentication is required, pause and give the operator the exact safe command/action to perform, then continue only after it succeeds.
4. Keep unattended execution disabled. Do not install/enable the controller timer or cron during this task.
5. Immediately before the controlled test, enable only the minimum live-dispatch guard required for this one manual run.
6. Run the controller manually in live mode exactly once for `SCA-CTRL-002#0`.
7. The controller-launched Claude session must execute only this task and produce a harmless proof change on the controller-created task branch:
   - create `audits/SCA-CTRL-002-live-proof.md`;
   - include only safe information: task ID, retry generation, statement that the file was created by the controller-launched Claude session, and the resulting commit SHA/PR reference if available;
   - do not include credentials, customer data, machine secrets, environment values, or unrelated project information.
8. The controller-launched Claude session must commit the proof change, push only the task branch, open a pull request against `main`, then STOP. It must not merge the PR.
9. Capture evidence showing the controller actually invoked Claude live, the Claude process completed, the expected branch/commit/PR was produced, and controller state reached `AWAITING_ARCHITECT_AUDIT`.
10. After the single controlled live run completes, return the live-dispatch guard to disabled (`SCA_ALLOW_LIVE=0` or equivalent) before reporting completion.
11. Confirm unattended scheduling is still disabled after the test.
12. Return all required evidence and STOP for ChatGPT audit.

## Acceptance Criteria

Return all of the following:

- `RESULT=PASS` or a specific `BLOCKED_*` result;
- installed-source vs `main` comparison result;
- service account confirmation;
- Claude Code authentication status for `sceyewear` without exposing credentials;
- GitHub authentication status for `sceyewear` without exposing credentials;
- confirmation that no root credential was copied;
- confirmation that unattended/systemd/cron execution remained disabled;
- exact manual live controller command and relevant output;
- evidence that a real Claude Code process was invoked by the controller;
- controller run-log evidence sufficient to distinguish this from dry-run mode;
- dispatch key evidence for `SCA-CTRL-002#0`;
- resulting task branch name;
- resulting commit SHA;
- resulting pull request URL/number;
- proof that the PR remains unmerged;
- final controller state showing `AWAITING_ARCHITECT_AUDIT`;
- final confirmation that the live-dispatch guard was returned to disabled;
- environment variable names only, values redacted;
- security findings, if any.

## Prohibited Changes

- Do not build SCA product features.
- Do not connect or modify the live Shopify store.
- Do not deploy the SCA product application.
- Do not modify DNS.
- Do not publish permanent QR URLs.
- Do not add/change Shopify scopes.
- Do not enable unattended/systemd/cron execution.
- Do not copy root credentials into `sceyewear`.
- Do not expose any credential value.
- Do not push directly to `main`.
- Do not merge the proof PR.
- Do not make unrelated repository changes.
- Do not invent the next task.
- Do not self-approve.

## Required Evidence

Provide concise real command output sufficient for ChatGPT to independently verify every acceptance criterion. Redact all secret values and private data.

If authentication cannot be safely established, return a specific `BLOCKED_AUTH_*` result with the exact non-secret human action required, then STOP.

## Completion Rule

After returning the required evidence, **STOP**.

Wait for ChatGPT architecture audit. Claude may resume only after ChatGPT replaces/revises `NEXT_TASK.md` with an approved `STATUS: READY` task.

## Last Completed

`SCA-CTRL-001` generation 1 passed architecture audit. Dry-run dispatch, duplicate suppression, non-root execution, safe-mode behavior, and append-only controller audit logging are proven. Live Claude invocation and PR creation are not yet proven.

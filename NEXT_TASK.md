# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-CTRL-001

**RETRY_GENERATION:** 0

## Title

Bootstrap and prove the Claude task controller

## Implementer

Claude

## Objective

Create the minimal controller on the project VPS that turns approved `NEXT_TASK.md` work into a controlled Claude Code execution, then stops for ChatGPT architecture audit.

This task is infrastructure/workflow only. Do not build SCA product features.

## Required Inputs

Read first:

- `README.md`
- `CLAUDE.md`
- `docs/EXECUTION_WORKFLOW.md`
- `docs/ADR-0003-CLAUDE-TASK-CONTROLLER.md`
- this `NEXT_TASK.md`

## Work

1. Inspect the VPS/workspace and report the installed Claude Code/runtime prerequisites.
2. Create the smallest reliable controller implementation that:
   - reads `NEXT_TASK.md` from `main`
   - dispatches only `STATUS: READY`
   - de-duplicates by `TASK_ID + RETRY_GENERATION`
   - creates/uses a dedicated task branch
   - invokes Claude Code non-interactively for the exact task
   - records state as `RUNNING`, then `AWAITING_ARCHITECT_AUDIT` or a specific failure state
   - uses a single-run lock
   - supports a HOLD/KILL switch
   - never auto-merges
3. Run it under a non-root service account.
4. Store controller state/logs outside the public architecture repo if they may contain machine-specific data.
5. Add only safe controller documentation/configuration to Git as needed. Never commit credentials or `.env` contents.
6. Prove the controller in DRY-RUN/TEST mode using `SCA-CTRL-001` itself or a harmless synthetic task. The proof must demonstrate that the same task cannot be dispatched twice.
7. Do not enable unattended production execution until the dry-run evidence is returned and audited by ChatGPT.

## Acceptance Criteria

Return all of the following:

- `RESULT=PASS` or a specific `BLOCKED_*`
- controller source path
- service account used
- runtime / Claude Code versions
- exact start/stop/status commands
- HOLD/KILL switch command or mechanism
- lock mechanism
- state file/database location
- dispatch/audit log location
- dry-run evidence showing one dispatch and duplicate suppression
- branch/commit/PR references for any repository changes
- environment variable names only, values redacted
- security findings

## Prohibited Changes

- Do not build SCA product features.
- Do not connect or modify the live Shopify store.
- Do not deploy the SCA product application.
- Do not modify DNS.
- Do not create permanent QR URLs.
- Do not add Shopify scopes.
- Do not auto-merge any PR.
- Do not enable unattended controller execution beyond dry-run/test mode before ChatGPT audit.
- Do not invent the next task.
- Do not self-approve.

## Required Evidence

Provide concise command output and file/service references sufficient to independently verify every acceptance criterion. Redact all secrets.

## Completion Rule

After returning evidence, STOP.

Wait for ChatGPT architecture audit. Claude may resume only after `NEXT_TASK.md` is replaced/revised with an approved `STATUS: READY` task.

## Last Completed

Architect–Implementer workflow established. ADR-0003 approved the VPS-based Claude task controller. `SCA-BOOT-001` was deferred until controller bootstrap is accepted.

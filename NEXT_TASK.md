# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-BOOT-001

**RETRY_GENERATION:** 0

## Title

Establish the SCA implementation baseline before feature development

## Implementer

Claude

## Objective

Recover or establish the actual SCA product codebase that will implement the architecture in this repository. Do not begin new provenance features until the current implementation source and runtime are known.

## Required Inputs

Read first:

- `README.md`
- `docs/PRODUCT_REQUIREMENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/EXECUTION_WORKFLOW.md`
- `docs/ADR-0001-MANAGED-HOSTING.md`
- `docs/ADR-0002-ARIANEE-REJECTED.md`

## Work

1. Inspect the local/workspace environment for any existing Second Chance Authenticators / SCA Ownership Bridge implementation created by prior staff.
2. If existing implementation code is present, preserve it. Do not rebuild working functionality from scratch.
3. Identify and report:
   - framework/runtime
   - package manager
   - application entry point
   - database technology/schema/migrations
   - authentication approach
   - existing Shopify integration
   - existing QR/serial/claim routes
   - existing admin/customer routes
   - environment variable **names only**
   - local start/test commands
   - current deployment assumptions
4. Run the existing application/tests locally if reasonably possible without production secrets.
5. Ensure the implementation code is in a clean Git repository with no credentials committed.
6. If no implementation code exists in the workspace, **STOP** and report `BLOCKED_NO_IMPLEMENTATION_SOURCE`. Do not scaffold a replacement yet.
7. If implementation code exists but is not in GitHub, prepare it for a private implementation repository and report what is needed to push it. Do not put implementation source into this architecture repository unless an approved architecture decision changes the repository role.

## Acceptance Criteria

Return all of the following:

- `RESULT=PASS` or a specific `BLOCKED_*` result
- implementation source path
- implementation repository URL if already available
- framework/runtime and versions
- database summary
- existing feature inventory
- exact local start/test commands
- test/build output summary
- current Git commit SHA if applicable
- list of required environment variable names with values redacted
- any security problems discovered
- any missing source/artifacts required to proceed

## Prohibited Changes

- Do not add new SCA product features.
- Do not redesign the data model.
- Do not change Shopify scopes.
- Do not deploy to production.
- Do not create permanent QR URLs yet.
- Do not commit secrets, access tokens, Shopify credentials, database credentials, or `.env` contents.
- Do not delete prior staff work simply because a different implementation would be easier.
- Do not create, select, or begin the next implementation task.
- Do not self-approve this task.

## Required Evidence

Provide concise evidence for every acceptance criterion, including relevant command output, paths, commit SHA(s), and test/build results. Redact all secret values.

## Completion Rule

After returning the required evidence, **STOP**.

Claude must wait for ChatGPT architecture audit. Claude may resume only after `NEXT_TASK.md` has been replaced or revised with an approved task that has `STATUS: READY`.

If ChatGPT rejects the evidence, the next task will be a remediation task with an incremented `RETRY_GENERATION`. Claude must fix only that remediation scope.

## Last Completed

Architecture bridge initialized. Product requirements, target architecture, Arianee rejection, and the Architect–Implementer approval workflow are recorded.

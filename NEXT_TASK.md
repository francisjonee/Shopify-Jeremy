# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-RECOVERY-001

**RETRY_GENERATION:** 0

## Title

Recover and inventory the existing SCA Ownership Bridge implementation

## Implementer

Claude

## Objective

Find the existing Second Chance Authenticators / SCA Ownership Bridge implementation that was previously built and tested, preserve it, and establish an accurate implementation baseline before any new SCA feature work.

Do **not** scaffold or rebuild the application from scratch unless a later task explicitly authorizes that.

## Context

Project history indicates an SCA Ownership Bridge implementation previously existed and had working behavior around serial creation, QR generation, customer claiming, duplicate ownership protection, My Collection, Shopify integration, and PostgreSQL/production deployment work.

The architecture repository is not the application source repository. The implementation may exist in another Git repository, another workspace, a local machine, a deployment source, or an accessible remote.

## Required Inputs

Read first:

- `README.md`
- `CLAUDE.md`
- `docs/PRODUCT_REQUIREMENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/EXECUTION_WORKFLOW.md`
- `docs/ADR-0004-VPS-HOSTING-SUPERSEDES-ADR-0001.md`
- `.claude/memory/implementation-recovery-required.md`
- `audits/SCA-CTRL-002-DEFERRED.md`
- this `NEXT_TASK.md`

## Work

1. Search the current accessible workspace/server for existing SCA / Second Chance Authenticators / Ownership Bridge application source.
2. Inspect accessible Git remotes/repositories for a likely existing implementation repository. Do not create a new repository yet.
3. If a candidate implementation is found, verify it is actually the SCA codebase by inspecting the code and Git history rather than relying only on a folder/repository name.
4. Preserve existing source exactly. Do not delete, replace, or rewrite working prior implementation.
5. Report the implementation baseline:
   - source path;
   - repository URL and default/current branch if available;
   - current commit SHA;
   - framework/runtime and package manager;
   - application entry point;
   - database technology, schema/migrations, and ORM if any;
   - authentication approach;
   - Shopify integration approach and current scopes/config assumptions;
   - existing serial/QR/claim/My Collection/admin/customer routes or modules;
   - deployment configuration/host assumptions;
   - environment variable **names only**;
   - available start/build/test commands.
6. Run only safe local/static checks that do not require production secrets or modify production data. If dependencies are already present, run build/tests where reasonably possible. Do not deploy.
7. Compare the existing implementation against the documented SCA architecture at a high level and identify what is already implemented versus clearly missing. Do not implement the missing features in this task.
8. If the implementation source cannot be reached from the current environment, return `BLOCKED_SOURCE_ACCESS` and state the exact non-secret human action needed to make the existing source available (for example: push the existing local repository to an accessible private GitHub repo, provide the existing repository URL/access, or run Claude from the machine containing the source).
9. If multiple candidate codebases exist, return `BLOCKED_MULTIPLE_CANDIDATES` with enough evidence to distinguish them. Do not choose by guess.
10. Return the required evidence and STOP for ChatGPT audit.

## Acceptance Criteria

Return all of the following:

- `RESULT=PASS`, `BLOCKED_SOURCE_ACCESS`, `BLOCKED_MULTIPLE_CANDIDATES`, or another specific blocker;
- exact implementation source path if found;
- repository URL if available;
- current branch and commit SHA if available;
- framework/runtime/package-manager summary;
- database/schema/ORM summary;
- authentication summary;
- Shopify integration summary;
- existing feature inventory, including serial, QR, claim, duplicate protection, My Collection, admin/customer surfaces where present;
- deployment configuration summary;
- environment variable names only, values redacted;
- exact safe start/build/test commands discovered;
- build/test/static-check result if safely runnable;
- high-level implemented-vs-missing comparison against current SCA architecture;
- security findings, including any accidentally committed secrets or production coupling found;
- exact human recovery action if the source is not accessible.

## Prohibited Changes

- Do not scaffold a replacement SCA application.
- Do not rebuild existing working features from scratch.
- Do not add new SCA product features.
- Do not change the provenance data model.
- Do not change Shopify scopes.
- Do not connect, modify, or write to the live Shopify store.
- Do not deploy or restart the production SCA application.
- Do not modify DNS or permanent QR URLs.
- Do not create a new implementation repository unless a later approved task authorizes it.
- Do not expose or commit secrets, credentials, tokens, database URLs, or `.env` values.
- Do not invent the next task.
- Do not self-approve.

## Required Evidence

Provide concise real evidence for the findings: paths, repository/branch/commit references, relevant safe command output, discovered scripts, and test/build output where safely runnable. Redact all secrets and customer/private data.

## Completion Rule

After returning the required evidence, **STOP**.

Wait for ChatGPT architecture audit. Claude may resume only after ChatGPT replaces/revises `NEXT_TASK.md` with an approved `STATUS: READY` task.

## Last Completed

`SCA-CTRL-001` generation 1 passed architecture audit. The fully automatic live-dispatch proof (`SCA-CTRL-002`) is deferred because manual operator-to-Claude task pickup is already working and is sufficient for current delivery. Product implementation recovery now takes priority.

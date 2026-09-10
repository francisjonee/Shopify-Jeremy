# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-FOUNDATION-001

**RETRY_GENERATION:** 0

## Title

Create the portable SCA application foundation on the temporary VPS

## Implementer

Claude

## Owner Approval

Jeremy's team explicitly approved a greenfield rebuild from scratch and authorized implementation to begin. The inaccessible old Ownership Bridge is no longer a prerequisite.

For this task only, creation of the new **private** SCA implementation repository is authorized.

## Objective

Create the clean, portable foundation for the new Second Chance Authenticators application and prove it can run safely on the current temporary VPS without coupling the product to that server.

This task creates infrastructure/application scaffolding only. Do **not** build SCA product features yet.

## Architecture Inputs — Read First

- `README.md`
- `CLAUDE.md`
- `docs/PRODUCT_REQUIREMENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/INFRASTRUCTURE_BLUEPRINT.md`
- `docs/ROADMAP.md`
- `docs/ADR-0004-VPS-HOSTING-SUPERSEDES-ADR-0001.md`
- `docs/ADR-0005-GREENFIELD-PORTABLE-SCA-BUILD.md`
- `docs/EXECUTION_WORKFLOW.md`
- `.claude/memory/greenfield-build-approved.md`
- this `NEXT_TASK.md`

## Required Technical Direction

Use the approved foundation stack:

- TypeScript
- Node.js
- Next.js
- PostgreSQL
- Prisma
- Docker / Docker Compose
- modular monolith

Use the current VPS only as temporary development/staging infrastructure.

## Work

1. Sync the architecture repository to current `main` and confirm ADR-0005 is present before building.
2. Create a new **private** GitHub implementation repository named `francisjonee/sca-platform` if it does not already exist.
   - Initialize the repository safely with a `main` branch and minimal README if required.
   - Verify repository visibility is private.
   - Do not place application source in `Shopify-Jeremy`.
3. Clone the implementation repository to an appropriate dedicated working directory on the temporary VPS.
4. Create a task branch named `chore/sca-foundation-001` from `main`.
5. Scaffold a production-oriented Next.js application using TypeScript and the App Router. Pin dependencies through the lockfile. Use one package manager consistently and document it.
6. Add Prisma configured for PostgreSQL.
   - Do not create the SCA product-domain tables in this task.
   - Prove Prisma configuration validates and the application can connect to PostgreSQL safely.
7. Add Docker support:
   - multi-stage production Dockerfile for the web application;
   - Docker Compose for the temporary environment;
   - PostgreSQL container with a named persistent volume;
   - web container running as non-root where practical;
   - health checks;
   - `.dockerignore`.
8. Bind the temporary web service to localhost/internal access only unless an existing approved staging reverse proxy requires otherwise. Do not expose a new public production endpoint in this task.
9. Add environment-driven configuration with `.env.example` containing **names/placeholders only**. At minimum include names equivalent to:
   - `DATABASE_URL`
   - `APP_URL`
   - `PUBLIC_QR_BASE_URL`
   - `NODE_ENV`
   - `PORT`
   Do not commit any real secret, token, password, database URL, VPS IP, or hostname.
10. Add application health/readiness endpoints sufficient to prove:
   - web process is alive;
   - PostgreSQL connectivity is ready.
11. Add baseline quality commands/scripts for:
   - lint;
   - TypeScript typecheck;
   - automated test;
   - production build;
   - Prisma validate/generate.
12. Add a minimal automated test for the foundation/health behavior. Do not add product-domain tests yet.
13. Add database backup/restore scripts or documented commands suitable for PostgreSQL in this Docker environment.
   - Backups/dumps must be ignored by Git.
   - Prove a safe temporary backup can be created.
   - If reasonably possible without product data, prove a restore into an isolated temporary/test database or clearly report why restore proof is deferred.
   - Do not claim the temporary VPS is a durable external backup destination.
14. Add implementation-repository documentation covering:
   - local/temp-VPS start and stop;
   - build/test commands;
   - environment variable names;
   - database backup/restore procedure;
   - migration approach;
   - rule that permanent production QR URLs must not use this VPS hostname/IP;
   - future migration to a permanent server.
15. Start the foundation on the temporary VPS and run real smoke tests.
16. Restart the Docker stack once and prove it returns healthy and PostgreSQL remains reachable.
17. Search the implementation tree for accidentally hard-coded temporary server IP/hostname and secret values before committing.
18. Commit only the foundation changes to `chore/sca-foundation-001`, push that branch, and open a pull request against `main` in the **private implementation repository**.
19. Do **not** merge the implementation PR. Return evidence and STOP for ChatGPT audit.

## Acceptance Criteria

Return all of the following:

- `RESULT=PASS` or a specific `BLOCKED_*` result;
- private implementation repository URL/name;
- proof repository visibility is private without exposing credentials;
- implementation working path on the temporary VPS;
- task branch name;
- exact runtime/framework/package-manager versions selected;
- Docker/Compose version summary;
- PostgreSQL and Prisma version summary;
- `.env.example` variable names only, values redacted/placeholders;
- proof there are no committed secrets;
- proof no temporary VPS IP/hostname is hard-coded into application/business configuration;
- Prisma validate/generate result;
- lint result;
- typecheck result;
- automated test result;
- production build result;
- Docker build/start result;
- health endpoint result;
- database readiness result;
- backup command/result;
- restore proof or explicit safe reason it is deferred;
- restart persistence/health proof;
- resulting implementation commit SHA;
- resulting implementation PR URL/number;
- proof the PR is still unmerged;
- security findings;
- confirmation that no SCA product feature, Shopify connection, DNS change, or permanent QR publication occurred.

## Prohibited Changes

- Do not recover or import the old Ownership Bridge.
- Do not build provenance product tables yet.
- Do not build QR generation yet.
- Do not build authentication/collector login yet.
- Do not build claims or My Collection yet.
- Do not build Admin/CRM product features yet.
- Do not connect or modify the live Shopify store.
- Do not add or change Shopify scopes.
- Do not deploy a public production SCA endpoint.
- Do not change DNS.
- Do not generate or publish permanent lifetime QR codes.
- Do not hard-code the temporary VPS IP/hostname.
- Do not store durable media only in the application container.
- Do not commit secrets or `.env` values.
- Do not push implementation work directly to `main` except the minimum repository initialization required to establish the new private repo/base branch.
- Do not merge the implementation PR.
- Do not invent the next task.
- Do not self-approve.

## Completion Rule

After returning all required evidence, **STOP**.

Wait for ChatGPT architecture audit. The next SCA task will be issued only after the operator reviews/approves it.

## Last Completed / Superseded Work

- `SCA-CTRL-001` generation 1: PASS.
- `SCA-CTRL-002`: deferred; automatic live dispatch is not required for current delivery.
- `SCA-RECOVERY-001`: accepted as `BLOCKED_SOURCE_ACCESS`, then superseded by the explicit greenfield-build decision in ADR-0005. The old implementation is no longer required.

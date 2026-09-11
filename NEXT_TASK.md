# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-CRM-FOUNDATION-001

**RETRY_GENERATION:** 0

## Title

Validate and deploy the Krayin CRM foundation for SCA on the temporary VPS

## Implementer

Claude

## Owner Approval

Jeremy's team has approved changing the initial SCA implementation strategy from building the staff CRM/admin foundation from scratch to using a mature MIT-licensed CRM foundation.

Krayin CRM is the selected initial candidate. This task must validate the exact upstream version, license, requirements, security posture, deployment, persistence, backup/restore, and extension mechanism before SCA product features are built.

## Objective

Create a reproducible, portable, hardened Krayin foundation suitable for later SCA modules while proving that SCA can extend Krayin without invasive vendor-core modification.

This is a foundation/validation task only. **Do not build SCA product-domain features yet.**

## Architecture Inputs — Read First

- `README.md`
- `CLAUDE.md`
- `docs/PRODUCT_REQUIREMENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/ROADMAP.md`
- `docs/ADR-0005-GREENFIELD-PORTABLE-SCA-BUILD.md`
- `docs/ADR-0006-KRAYIN-CRM-ADMIN-FOUNDATION.md`
- `docs/INFRASTRUCTURE_BLUEPRINT.md` (apply portability/security principles; note its old PostgreSQL/Next.js specifics are superseded where ADR-0006 conflicts)
- `docs/EXECUTION_WORKFLOW.md`
- this `NEXT_TASK.md`

## Required Technical Direction

Use the selected Krayin release's supported stack. Expected baseline:

- Krayin CRM
- Laravel / PHP
- MySQL or MariaDB
- Composer
- Node/npm tooling only where required by Krayin assets
- Docker / Docker Compose where practical and maintainable

Do not force PostgreSQL, Prisma, or Next.js into the admin foundation merely to preserve the superseded stack.

## Work

1. Sync this architecture repository to current approved branch/main state and confirm ADR-0006 is present before implementation.
2. Identify the official upstream Krayin repository and select a stable release/version rather than an unpinned moving target.
3. Record evidence of the selected release's MIT license and official runtime/database requirements.
4. Review the selected release for obvious deployment blockers before installation:
   - open/known security concerns relevant to the selected version;
   - unsupported/EOL PHP or framework requirements;
   - database compatibility;
   - required queues/cache/mail services;
   - upgrade/migration mechanism.
   Report findings; do not silently ignore material risks.
5. Create or reuse the authorized private implementation repository `francisjonee/sca-platform`.
   - Verify it is private.
   - Application/custom SCA source belongs there, not in `Shopify-Jeremy`.
6. Create task branch `chore/sca-crm-foundation-001` from implementation `main`.
7. Establish a reproducible Krayin deployment in the private implementation repository.
   - Pin dependencies/version sufficiently for repeatability.
   - Prefer an installation structure that preserves a clean upstream/vendor boundary.
   - Do not fork/edit vendor core merely for branding or convenience in this task.
8. Configure MySQL or MariaDB using the selected Krayin version's supported path.
   - persistent database storage;
   - credentials from environment/secrets only;
   - no real secrets committed.
9. Add/maintain Docker and Docker Compose deployment for the temporary VPS if this can be done without creating a brittle unsupported Krayin installation.
   - If official/runtime constraints make a different deployment materially safer, document the reason and stop for architecture review rather than improvising a permanent divergence.
10. Keep the temporary deployment non-production.
   - Do not publish a permanent QR route;
   - do not connect the live Shopify store;
   - do not change DNS;
   - do not treat the temporary VPS as durable backup storage.
11. Secure the initial CRM installation:
   - no default/example admin credentials retained;
   - no debug mode exposed publicly;
   - secrets outside Git;
   - least public exposure practical for staging;
   - document writable directories/permissions;
   - document scheduled jobs/queues if required.
12. Add `.env.example` with variable names/placeholders only. Do not commit passwords, tokens, VPS IP, hostname, Shopify secrets, or real database URLs.
13. Prove the CRM is operational with smoke tests:
   - application loads;
   - staff login works;
   - database connectivity works;
   - core CRM navigation works;
   - restart returns to healthy state.
14. Prove persistence through at least one controlled Docker/application restart.
15. Add database backup/restore scripts or documented commands appropriate for MySQL/MariaDB.
   - backup output ignored by Git;
   - create a safe test backup;
   - restore into an isolated temporary/test database when reasonably possible;
   - do not claim the VPS copy is an off-server durable backup.
16. Demonstrate the supported Krayin extension/package/module mechanism with a harmless SCA proof extension/module, for example an isolated package that registers an `SCA Foundation` admin marker/page/route.
   - It must not create eyewear/authentication/ownership/provenance product tables yet.
   - It must not modify vendor core.
   - Its purpose is only to prove SCA can extend the CRM cleanly.
17. Document the custom-code boundary:
   - upstream/vendor Krayin code;
   - SCA-owned module/package code;
   - configuration/branding overrides;
   - database migrations;
   - future collector/public code.
18. Document an upgrade strategy:
   - how upstream Krayin updates will be evaluated/applied;
   - how SCA modules remain isolated;
   - how database backup/rollback occurs before upgrades;
   - how unavoidable core patches, if ever approved later, will be tracked.
19. Search the implementation tree for secrets, default credentials, temporary VPS IP/hostname, and accidental vendor-core modifications.
20. Run available quality/security checks appropriate to the selected stack, including at minimum:
   - Composer dependency validation/audit where supported;
   - application/framework tests available for the deployed baseline or a documented smoke-test suite;
   - frontend build if required by the selected Krayin release;
   - configuration/cache clear/build checks appropriate to Laravel;
   - database migration status.
21. Commit only the foundation changes to `chore/sca-crm-foundation-001`, push the branch, and open a PR against implementation `main`.
22. Do **not** merge the implementation PR. Return evidence and STOP for ChatGPT audit.

## Acceptance Criteria

Return all of the following:

- `RESULT=PASS` or a specific `BLOCKED_*` result;
- exact official Krayin upstream repository;
- exact selected Krayin version/tag/commit;
- MIT license evidence/reference;
- PHP, Laravel, Composer, Node/npm (if used), and MySQL/MariaDB versions;
- selected release support/compatibility evidence;
- known material security/upgrade findings for the selected version;
- private implementation repository name/URL and proof it is private;
- implementation working path on temporary VPS;
- task branch name;
- deployment topology summary;
- `.env.example` variable names only with values redacted/placeholders;
- proof no secrets/default credentials are committed;
- proof temporary VPS IP/hostname is not hard-coded into SCA business configuration;
- proof no vendor-core modification was made;
- SCA proof extension/module path and evidence it loads;
- database migration/status result;
- application load result;
- staff login smoke-test result without exposing credentials;
- restart persistence result;
- backup command/result;
- isolated restore result or explicit safe reason deferred;
- Composer validation/audit result;
- relevant application/test/build results;
- documented upstream upgrade/rollback strategy;
- resulting implementation commit SHA;
- implementation PR URL/number;
- proof PR remains unmerged;
- security findings;
- confirmation that no SCA product-domain tables/features, Shopify connection, DNS change, or permanent QR publication occurred.

## Prohibited Changes

- Do not build the old Next.js/PostgreSQL/Prisma foundation from SCA-FOUNDATION-001.
- Do not recover/import the old Ownership Bridge.
- Do not build eyewear/provenance product tables yet.
- Do not build QR generation yet.
- Do not build collector authentication/claim/My Collection yet.
- Do not build ownership transfer/service/lost-stolen features yet.
- Do not connect or modify the live Shopify store.
- Do not add/change Shopify scopes.
- Do not change DNS.
- Do not publish permanent lifetime QR codes.
- Do not hard-code the temporary VPS IP/hostname.
- Do not commit secrets or real `.env` values.
- Do not leave default/example admin credentials active.
- Do not modify Krayin vendor/core files for convenience.
- Do not introduce PostgreSQL as a second database without a new approved ADR.
- Do not merge the implementation PR.
- Do not invent the next task.
- Do not self-approve.

## Completion Rule

After returning all required evidence, **STOP** and wait for ChatGPT architecture/security audit.

## Superseded Work

- `SCA-FOUNDATION-001` is superseded by ADR-0006 and this task before implementation acceptance.
- `SCA-RECOVERY-001` remains superseded by the greenfield decision.
- `SCA-CTRL-002` remains deferred.

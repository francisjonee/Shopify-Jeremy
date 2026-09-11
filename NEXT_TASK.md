# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-KRAYIN-INSTALL-001

**RETRY_GENERATION:** 0

## Title

Install Krayin CRM on the temporary SCA VPS and prove it is ready for SCA customization

## Implementer

Claude

## Authority

This task is approved by Jeremy's team and issued by ChatGPT under:

- `docs/ADR-0006-KRAYIN-CRM-ADMIN-FOUNDATION.md`
- `docs/ARCHITECTURE.md`
- `docs/ROADMAP.md`
- `TASK_QUEUE.md`
- `docs/EXECUTION_WORKFLOW.md`

Krayin is the approved staff-facing CRM/admin foundation for SCA.

`TASK_QUEUE.md` is planning only. **Do not start any queued task.** Execute only this file.

## Primary Goal

Install a stable, pinned Krayin CRM release on the temporary VPS and make it operational.

At the end of this task we must have a working installation that:

- loads successfully;
- has working administrator login;
- uses persistent MySQL or MariaDB storage;
- survives restart;
- can be backed up and restored;
- contains no committed secrets;
- can be extended by SCA without editing Krayin vendor/core files;
- has all material installation findings and evidence committed to Git.

Do not build actual SCA eyewear/provenance features yet.

---

## Mandatory Git / Findings Discipline

This requirement is part of task acceptance, not optional documentation.

### Commit continuously

Do not accumulate the entire installation as one uncommitted change.

Make logical checkpoint commits as meaningful work is completed, for example:

1. reproducible Krayin/deployment foundation;
2. database/environment/persistence setup;
3. successful installation/runtime configuration;
4. backup/restore and operational scripts;
5. SCA proof extension;
6. documentation/security/final evidence.

The exact commit grouping may differ if technically appropriate, but meaningful completed work must be committed as durable project history.

### Commit findings

Create this file in the private implementation repository:

```text
docs/task-reports/SCA-KRAYIN-INSTALL-001.md
```

Keep it updated during the task and commit it with the implementation.

It must record:

- exact Krayin version/tag/commit;
- MIT license verification;
- PHP/Laravel/Composer/Node/MySQL-or-MariaDB/Docker versions used;
- actual deployment topology;
- important installation commands/procedures;
- configuration decisions;
- files/components added or changed;
- database migration/install results;
- restart/persistence results;
- backup/restore results;
- extension/module findings;
- security findings;
- Krayin limitations or unexpected behavior discovered;
- upgrade risks;
- operational findings;
- technical debt/known issues;
- recommendations for future tasks;
- any proposed change to the task queue or architecture, clearly marked as a recommendation only;
- explicit confirmation of prohibited work not performed;
- implementation commit SHA(s) and PR reference when available.

Important findings must not exist only in terminal output or Claude's chat response.

If a serious blocker is discovered, commit the findings report before stopping whenever repository access permits it.

---

## Read Before Doing Anything

Read these first:

1. `README.md`
2. `CLAUDE.md`
3. `docs/ADR-0006-KRAYIN-CRM-ADMIN-FOUNDATION.md`
4. `docs/ARCHITECTURE.md`
5. `docs/ROADMAP.md`
6. `TASK_QUEUE.md`
7. `docs/PRODUCT_REQUIREMENTS.md`
8. `docs/EXECUTION_WORKFLOW.md`
9. this `NEXT_TASK.md`

If an older document conflicts with ADR-0006 regarding Next.js, Prisma, PostgreSQL, or building the CRM from scratch, ADR-0006 wins.

---

# TASK

## 1. Select and pin Krayin

Use the official Krayin CRM upstream project.

Before installation:

- verify official upstream repository;
- verify MIT license;
- identify an appropriate stable release;
- do not install an unpinned development branch;
- record exact tag/version/commit;
- record required PHP, Laravel, Composer, Node/npm, and MySQL/MariaDB versions.

If the newest stable release has a known material blocker, choose the most appropriate supported stable release and document why.

Do not continue if the license is not MIT.

## 2. Use the SCA implementation repository

Create or use private repository:

`francisjonee/sca-platform`

Requirements:

- repository must be private;
- do not place application code in `Shopify-Jeremy`;
- create branch `chore/sca-krayin-install-001`;
- do not work directly on implementation `main` except minimum repository initialization if required.

## 3. Install Krayin on the temporary VPS

Install the pinned Krayin release on the existing temporary SCA VPS using a clean dedicated application directory.

Prefer portable deployment using Docker, Docker Compose, persistent named volumes, and environment-driven configuration.

If Krayin's supported installation path makes Docker materially unsafe or brittle, STOP and report `BLOCKED_DEPLOYMENT_ARCHITECTURE` rather than inventing an unsupported setup.

Install all runtime components required by the selected Krayin release.

## 4. Configure persistent database storage

Use MySQL or MariaDB according to Krayin's supported path.

Requirements:

- persistent database volume/storage;
- data survives app/container restart;
- credentials from environment/secrets only;
- no database password committed;
- database port not publicly exposed unless strictly required;
- document exact database version.

Do not add PostgreSQL.

## 5. Configure environment safely

Create `.env.example` with names/placeholders only.

Do not commit real database credentials, administrator password, server IP/hostname, Shopify tokens, API keys, SMTP credentials, or application/session secrets.

Real `.env` must be Git ignored.

## 6. Complete the Krayin installation

Perform required dependency installation, application key/configuration, database migrations/setup, storage permissions, asset build, cache/config preparation, and any other officially required steps.

Create a secure administrator account.

Do not expose the administrator password in evidence and do not leave vendor/default/example credentials active.

## 7. Start Krayin and prove it works

Prove:

- HTTP application responds;
- Krayin login page loads;
- administrator can log in;
- dashboard/admin navigation loads;
- database connection is healthy;
- migrations/setup are complete;
- no fatal application errors are present in logs.

## 8. Restart/persistence test

Perform a controlled restart and prove:

- Krayin returns online;
- administrator login still works;
- database data persists;
- configuration remains correct.

## 9. Backup and restore test

Create reusable database backup/restore commands or scripts.

Requirements:

- backup files ignored by Git;
- create one test backup;
- restore into an isolated test database if safely possible;
- verify restored database is readable;
- document that VPS-only backup is not durable production backup;
- document intended later off-server backup approach.

## 10. Prove SCA can extend Krayin cleanly

Create a minimal harmless SCA proof module/package/extension using a supported Krayin/Laravel extension pattern.

It may register only something such as:

- `SCA Foundation` admin menu entry;
- SCA test page;
- SCA namespaced route;
- `SCA Foundation Ready` marker.

It must:

- live in SCA-owned code;
- remain isolated from vendor/core code;
- load successfully;
- require no Krayin vendor/core modifications.

Do not create real eyewear/provenance schema yet.

## 11. Confirm clean vendor boundary

Document where upstream Krayin code, Composer/vendor code, SCA custom modules, configuration overrides, and future SCA migrations live.

Search for accidental upstream/vendor edits. Revert any such modification before PASS.

## 12. Basic security validation

At minimum check:

- debug/public staging configuration;
- default credentials;
- committed secrets;
- Composer dependency audit if supported;
- logs for obvious security/config errors;
- writable-directory permissions;
- database exposure;
- public service exposure;
- temporary VPS hostname/IP embedded in SCA business logic.

Do not connect Shopify.

## 13. Documentation

Add implementation documentation covering:

- selected Krayin version;
- runtime requirements;
- installation/start/stop/restart;
- environment variable names;
- administrator initialization without password disclosure;
- database migrations;
- backup/restore;
- SCA custom-module location;
- Krayin upgrade procedure;
- rollback procedure;
- temporary VPS portability.

Also complete the mandatory task report at:

`docs/task-reports/SCA-KRAYIN-INSTALL-001.md`

## 14. Final Git state and PR

Before opening the PR:

- all implementation changes committed;
- task report committed;
- no important findings left only in chat/terminal;
- working tree clean except intentional ignored runtime files;
- branch pushed.

Open a pull request from:

`chore/sca-krayin-install-001`

against implementation `main`.

**DO NOT MERGE THE PR.**

ChatGPT must audit implementation and committed findings before merge.

---

# DO NOT DO THESE THINGS

Do not:

- build Next.js/Prisma/PostgreSQL foundation;
- install another CRM instead of Krayin;
- modify Krayin vendor/core files;
- build SCA eyewear/product-domain tables;
- build authentication/provenance/ownership data model;
- build QR generation;
- build collector accounts/My Collection/transfers/service history;
- connect Shopify or change scopes;
- change DNS;
- publish permanent SCA QR codes;
- hard-code temporary VPS IP/hostname;
- commit secrets;
- merge the implementation PR;
- start any queued task from `TASK_QUEUE.md`;
- modify `TASK_QUEUE.md`, roadmap, or ADRs unless this task explicitly authorizes it;
- begin a second implementation task after completing this one.

---

# REQUIRED RETURN EVIDENCE

Return one report containing:

## Result

`RESULT=PASS`

or explicit `RESULT=BLOCKED_<REASON>`.

## Installation Evidence

- official upstream;
- MIT license confirmation;
- exact Krayin version/tag/commit;
- PHP/Laravel/Composer/Node/npm/MySQL-or-MariaDB/Docker versions as applicable;
- VPS application path;
- deployment topology.

## Repository / Commit Evidence

- private implementation repository URL/name;
- proof repository is private;
- branch name;
- **ordered list of checkpoint commit SHAs with short purpose**;
- final implementation commit SHA;
- task-report path and commit SHA containing it;
- PR URL/number;
- proof PR remains unmerged;
- clean working-tree result.

## Runtime Evidence

- application/login/admin result;
- database connectivity/migration result;
- restart/persistence result;
- relevant log/smoke-test result.

## Backup Evidence

- backup command/result;
- restore result;
- restored database verification.

## Extension Evidence

- proof module path;
- what it registers/displays;
- proof it loads;
- proof no vendor/core modification remains.

## Security / Findings Evidence

- Composer/dependency audit if available;
- secret/default-credential/debug/exposure checks;
- material security findings;
- operational findings;
- known limitations/technical debt;
- recommendations for future tasks;
- confirmation all material findings are recorded in committed `docs/task-reports/SCA-KRAYIN-INSTALL-001.md`.

## Scope Confirmation

Explicitly confirm:

- no SCA product-domain features built;
- no Shopify connection;
- no DNS change;
- no permanent QR publication;
- no PostgreSQL introduced;
- no vendor/core modifications remain;
- no queued follow-on task started.

---

# COMPLETION RULE

Once all required evidence is committed and returned:

**STOP.**

Do not merge the PR.
Do not start the next queued task.
Do not rewrite governance files.
Do not self-approve.

Wait for ChatGPT to audit the Krayin installation, committed task report, and PR. ChatGPT will then update `TASK_QUEUE.md` and issue exactly one next `NEXT_TASK.md`.

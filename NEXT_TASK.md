# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-KRAYIN-INSTALL-001

**RETRY_GENERATION:** 0

## Title

Install Krayin CRM on the temporary SCA VPS and prove it is ready for SCA customization

## Implementer

Claude

## Authority

This task is approved by Jeremy's team and issued by ChatGPT under the architecture defined in:

- `docs/ADR-0006-KRAYIN-CRM-ADMIN-FOUNDATION.md`
- `docs/ARCHITECTURE.md`
- `docs/ROADMAP.md`

Krayin is now the approved staff-facing CRM/admin foundation for SCA.

## Primary Goal

**Install a stable, pinned Krayin CRM release on the temporary VPS and make it operational.**

At the end of this task we must have a working Krayin installation that:

- loads successfully;
- has a working administrator login;
- uses persistent MySQL or MariaDB storage;
- survives restart;
- can be backed up and restored;
- contains no committed secrets;
- can be extended by SCA without editing Krayin vendor/core files.

Do not build the actual SCA eyewear/provenance features yet.

---

## Read Before Doing Anything

Read these files first:

1. `README.md`
2. `CLAUDE.md`
3. `docs/ADR-0006-KRAYIN-CRM-ADMIN-FOUNDATION.md`
4. `docs/ARCHITECTURE.md`
5. `docs/ROADMAP.md`
6. `docs/PRODUCT_REQUIREMENTS.md`
7. `docs/EXECUTION_WORKFLOW.md`
8. this `NEXT_TASK.md`

If any older document conflicts with ADR-0006 regarding Next.js, Prisma, PostgreSQL, or building the CRM from scratch, **ADR-0006 wins**.

---

# TASK

## 1. Select and pin Krayin

Use the **official Krayin CRM upstream project**.

Before installation:

- verify the repository is the official Krayin project;
- verify its MIT license;
- identify the latest appropriate stable release;
- do not install an unpinned development branch;
- record the exact tag/version/commit selected;
- record required PHP, Laravel, Composer, Node/npm, and MySQL/MariaDB versions.

If the newest stable release has a known material blocker, choose the most appropriate supported stable release and explain why.

Do not continue if the license is not MIT.

## 2. Use the SCA implementation repository

Create or use the private repository:

`francisjonee/sca-platform`

Requirements:

- repository must be **private**;
- do not place application code in `Shopify-Jeremy`;
- create branch:

`chore/sca-krayin-install-001`

Do not work directly on implementation `main` except minimum repository initialization if required.

## 3. Install Krayin on the temporary VPS

Install the pinned Krayin release on the existing temporary SCA VPS.

Use a clean dedicated application directory.

Prefer a portable deployment using:

- Docker;
- Docker Compose;
- persistent named volumes;
- environment-based configuration.

If Krayin's supported installation method makes Docker materially unsafe or brittle, STOP and report `BLOCKED_DEPLOYMENT_ARCHITECTURE` rather than inventing an unsupported setup.

The installation must include all runtime components required by the selected Krayin release.

Expected components may include:

- Krayin/Laravel application;
- PHP runtime;
- web server or reverse proxy as appropriate;
- MySQL or MariaDB;
- Composer dependencies;
- frontend asset build/runtime requirements;
- queue/scheduler only if required by Krayin.

## 4. Configure persistent database storage

Use **MySQL or MariaDB according to the supported Krayin release path**.

Requirements:

- persistent database volume;
- database must not disappear when containers/app restart;
- database credentials must come from environment/secrets;
- no database password committed to Git;
- no database port exposed publicly unless strictly required;
- document database version.

Do **not** add PostgreSQL.

## 5. Configure environment safely

Create `.env.example` in the private implementation repository.

It must contain variable names/placeholders only.

Do not commit:

- real database credentials;
- administrator password;
- server IP;
- VPS hostname;
- Shopify tokens;
- API keys;
- SMTP credentials;
- session/app secrets.

Real `.env` must be Git ignored.

## 6. Complete the Krayin installation

Run the required Krayin/Laravel installation steps including, as applicable:

- dependency installation;
- application key/configuration;
- database migrations;
- seed/setup process;
- storage permissions;
- asset build;
- cache/config preparation.

Create a secure administrator account.

Do not expose the administrator password in task evidence.

Do not leave vendor/default/example credentials active.

## 7. Start Krayin and prove it works

Start the full stack.

Prove all of the following:

- HTTP application responds successfully;
- Krayin login page loads;
- administrator can log in;
- Krayin dashboard/admin navigation loads;
- database connection is healthy;
- migrations are complete;
- no fatal application errors are present in logs.

A screenshot is optional. Terminal/output evidence is sufficient if clear.

## 8. Restart test

Perform a controlled restart of the application/database stack.

After restart prove:

- Krayin comes back online;
- administrator login still works;
- database data persists;
- configuration remains correct.

## 9. Backup and restore test

Create a reusable database backup command/script for MySQL/MariaDB.

Requirements:

- backup files ignored by Git;
- create one test backup;
- restore that backup into an isolated test database if safely possible;
- verify the restored database is readable.

Do not call a backup stored only on the temporary VPS a durable production backup.

Document how an off-server backup will later be implemented.

## 10. Prove SCA can extend Krayin cleanly

Create a **minimal SCA proof module/package/extension** using Krayin/Laravel's supported extension pattern.

It may do only something harmless such as:

- register an `SCA Foundation` admin menu entry;
- register an SCA test page;
- register an SCA namespaced route;
- display `SCA Foundation Ready`.

This proof must:

- live in SCA-owned custom code;
- be isolated from vendor/core code;
- load successfully in Krayin;
- require no modification to Krayin vendor/core files.

Do **not** create the real eyewear/provenance schema yet.

## 11. Confirm clean vendor boundary

Document exactly where:

- upstream Krayin code lives;
- Composer/vendor code lives;
- SCA custom modules live;
- configuration overrides live;
- future SCA migrations will live.

Search for accidental edits to upstream/vendor core.

If vendor/core was modified, task result is not PASS unless the change is reverted.

## 12. Basic security validation

At minimum check:

- production/debug configuration appropriate for staging exposure;
- no default passwords;
- no secrets committed;
- Composer dependency audit if supported;
- application logs for obvious security/configuration errors;
- writable-directory permissions;
- database exposure;
- public service exposure;
- Git repository secret scan/search;
- no temporary VPS hostname/IP embedded in SCA business logic.

Do not connect Shopify during this task.

## 13. Documentation

Add implementation documentation to `sca-platform` covering:

- selected Krayin version;
- required runtime versions;
- installation/start procedure;
- stop/restart procedure;
- environment variables;
- administrator initialization procedure without passwords;
- database migration procedure;
- database backup procedure;
- database restore procedure;
- location of SCA custom modules;
- Krayin upgrade procedure;
- rollback procedure;
- temporary VPS portability notes.

## 14. Commit and create PR

Commit the completed foundation to:

`chore/sca-krayin-install-001`

Push it to the private `francisjonee/sca-platform` repository.

Open a pull request against `main`.

**DO NOT MERGE THE PR.**

ChatGPT must audit the implementation before merge.

---

# DO NOT DO THESE THINGS

Do not:

- build Next.js/Prisma/PostgreSQL foundation;
- install another CRM instead of Krayin;
- modify Krayin vendor/core files;
- build SCA eyewear tables;
- build authentication records;
- build ownership/provenance tables;
- build QR generation;
- build collector accounts;
- build My Collection;
- build transfer workflow;
- build service history;
- connect Shopify;
- change Shopify scopes;
- change DNS;
- publish permanent SCA QR codes;
- hard-code temporary VPS IP/hostname;
- commit secrets;
- merge the implementation PR;
- begin a second task after completing this one.

---

# REQUIRED RETURN EVIDENCE

When finished, return one report with:

## Result

`RESULT=PASS`

or one explicit blocker such as:

`RESULT=BLOCKED_<REASON>`

## Installation Evidence

- official Krayin upstream repository;
- MIT license confirmation;
- selected exact Krayin version/tag/commit;
- PHP version;
- Laravel version;
- Composer version;
- Node/npm version if used;
- MySQL/MariaDB version;
- Docker and Docker Compose versions if used;
- temporary VPS application path;
- deployment topology.

## Repository Evidence

- private implementation repository URL/name;
- proof repository is private;
- branch name;
- commit SHA;
- PR URL/number;
- proof PR is still unmerged.

## Runtime Evidence

- application load result;
- login-page result;
- administrator login success with credentials redacted;
- database connectivity result;
- migration result;
- dashboard/navigation smoke-test result;
- restart/persistence result.

## Backup Evidence

- backup command/script;
- successful backup result;
- restore test result;
- restored database verification result.

## Extension Evidence

- SCA proof extension/module path;
- what it registers/displays;
- proof it loads inside Krayin;
- proof no vendor/core files were modified.

## Security Evidence

- Composer audit result if available;
- secret scan result;
- default-credential check;
- debug/public exposure check;
- database exposure check;
- material security findings;
- any known risk requiring later action.

## Scope Confirmation

Explicitly confirm:

- no SCA product-domain features were built;
- no Shopify connection was made;
- no DNS was changed;
- no permanent QR was created/published;
- no PostgreSQL was introduced;
- no vendor/core modifications remain.

---

# COMPLETION RULE

Once all required evidence is returned:

**STOP.**

Do not merge the PR.
Do not start the next SCA feature.
Do not rewrite this task.
Do not self-approve.

Wait for ChatGPT to audit the Krayin installation and issue the next task.

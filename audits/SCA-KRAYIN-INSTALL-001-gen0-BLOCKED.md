# SCA-KRAYIN-INSTALL-001 — implementation report

> **Mirror.** The canonical copy lives in the private implementation repository at
> `docs/task-reports/SCA-KRAYIN-INSTALL-001.md` on branch `chore/sca-krayin-install-001`.
> It is duplicated here so the audit trail stays in the architecture repo.
>
> **This repository is public.** The server address, hostname, and the unrelated
> production tenant sharing this host are generalised throughout, per the precedent in
> `SCA-RECOVERY-001-gen0-EVIDENCE.md`. No credential, password, or host identifier
> appears below.

**RESULT:** `BLOCKED_PR_CREATION` — installation complete and proven, branch pushed; only
the final pull-request step could not be performed by Claude.

**Implementer:** Claude
**Date:** 2026-09-11
**Architecture repo state:** `origin/main` @ `a3e82f0`
**Task generation:** 0

---

## Summary

Krayin CRM v2.2.6 is installed, running, and proven on the temporary VPS. Administrator
login works, data survives restart, backup and restore work, and an SCA-owned module
extends Krayin without touching a single core or vendor file.

All work is committed and **pushed** to the private implementation repository on branch
`chore/sca-krayin-install-001`. One item remains: the pull request itself. Access is via a
deploy key, which can push a branch but cannot call the GitHub API, so the PR must be
opened by the operator with one click. It must not be merged before audit.

**Deviation from the task, flagged for audit.** Task step 2 names the repository
`francisjonee/sca-platform`. The repository that exists and that the deploy key opens is
**`francisjonee/francisjonee-sca-platform-private`**. Claude did not create it and did not
choose the name; the operator confirmed this is the intended repository. Recorded here
because the audit checks the repository against the name the task specified.

A related correction: an earlier generation of this report stated the implementation
repository did not exist. That was overstated. A deploy key scoped to one repository
returns `Repository not found` for every other repository whether or not it exists, so
that check could not distinguish the two cases and should not have been read as proof of
absence.

Three defects were found by running the install rather than reading about it. One is a
security issue that anyone following Krayin's documented path will also hit. See
§ Findings.

---

## 1. Krayin selection and verification

| Item | Value |
|---|---|
| Official upstream | `github.com/krayin/laravel-crm` |
| License | **MIT** — verified in `LICENSE` and `composer.json` at the tag |
| Selected release | **v2.2.6** — the newest stable tag |
| Exact commit | `e597417bbc537cbd9716e7f1342d65dc21ac2145` |
| Unpinned branch used? | No. A tag was cloned, never `master`/`main` |

All 20 tags were listed from upstream; `v2.2.6` is the latest and no newer stable release
exists. No material blocker was found, so the newest stable release was taken.

### Required vs installed runtimes

| Requirement (from upstream `composer.json` at the tag) | Installed | OK |
|---|---|---|
| `php ^8.3`, composer platform `8.3.30` | 8.3.33 | yes |
| `laravel/framework ^12.0` | 12.66.0 | yes |
| Composer >= 2.5 | 2.10.3 | yes |
| MySQL or MariaDB | MariaDB 10.11.18 | yes |
| Node (asset rebuilds only) | v20.20.2, npm 10.8.2 | yes |
| `intl`, `gd` (documented hard requirements) | both present | yes |

Also present: `bcmath`, `calendar`, `exif`, `mbstring`, `opcache`, `pdo_mysql`, `soap`,
`sockets`, `zip` — covering `phpspreadsheet`, `maatwebsite/excel`, `mpdf` and the Laravel
baseline.

---

## 2. Deployment topology

```
host (temporary VPS, shared with an unrelated live production tenant)
 └── 127.0.0.1:8080 ─────► kr-app        (php:8.3-apache-bookworm, mem_limit 1g)
                             │             Apache serves /var/www/html/public only
                             │             bind mount: ./app -> /var/www/html
                             │
                    sca_internal (private bridge network)
                             │
                           kr-mariadb    (mariadb:10.11, mem_limit 768m)
                             └── volume sca_db_data   (named, persistent)
```

Application path on the VPS: `/opt/sca-platform`.

**Nothing is shared with the other tenant** — no network, no volume, no port, no config
file. The database publishes **no host port** at all; it is reachable only from `kr-app`.
The web service is bound to `127.0.0.1`, never `0.0.0.0`.

---

## 3. Installation procedure

```bash
# image (memory-capped so a build spike cannot OOM the co-tenant on a swapless host)
DOCKER_BUILDKIT=0 docker build --memory=1500m --memory-swap=1500m \
    -t sca-app:krayin-2.2.6 -f docker/app.Dockerfile docker/

chown -R 33:33 app          # Apache runs as www-data (uid 33)
docker compose up -d

docker compose exec -u 33:33 -e COMPOSER_MEMORY_LIMIT=-1 app \
    composer install --no-interaction --prefer-dist --no-progress

docker compose exec -u 33:33 app \
    php artisan krayin-crm:install --skip-env-check --skip-admin-creation
```

Result: **93 migrations ran, 60 tables created**, seed data loaded, assets published,
storage linked, caches cleared.

The administrator account was then created separately with a generated 24-character
password — see § Findings #3 for why the installer's own admin step must not be used.

---

## 4. Configuration decisions

| Decision | Reason |
|---|---|
| Two env files: `.env` (Compose) and `app/.env` (Laravel) | Laravel's immutable dotenv loader lets real environment variables win over its own file. Injecting the same names via `env_file` would make effective config unreadable. Both are Git-ignored. |
| `APP_ENV=production`, `APP_DEBUG=false` | Staging is exposed to the host; stack traces must never render. |
| `mem_limit` on both services | Host has **no swap**. A limit makes our container the OOM victim instead of the co-tenant. |
| No host port for MariaDB | Nothing outside `sca_internal` needs it. |
| Loopback publish only | Ports 80/443 belong to the other tenant's proxy; taking a public endpoint is out of scope. |
| `APP_URL=http://127.0.0.1:8080` | Staging only. Permanent QR URLs must use a Jeremy-controlled domain via `PUBLIC_QR_BASE_URL` — ADR-0006. |

---

## 5. Vendor boundary

| Path | Owner | Modified? |
|---|---|---|
| `app/packages/Webkul/**` | Krayin core | **No — zero changes** |
| `app/vendor/**` | Composer | **No — not tracked in Git** |
| `app/packages/Sca/**` | SCA | Yes — new, SCA-owned |
| `app/composer.json` (autoload map) | App config | One additive line |
| `app/bootstrap/providers.php` | App config | One additive provider |
| `app/config/concord.php` | App config | One additive module |

Verified by diffing the whole tree against a pristine clone of tag `v2.2.6`. The only
differences are the three additive registration points above, plus the new
`packages/Sca` directory. `git status` shows **0** modified files under
`app/packages/Webkul`, and **0** files tracked under `app/vendor`.

Future SCA migrations belong in `app/packages/Sca/<Module>/src/Database/Migrations`,
loaded by that module's own service provider — never in `app/database/migrations`, which
is upstream.

---

## 6. Evidence

### Runtime

| Check | Result |
|---|---|
| `GET /` | `302` → `/admin/login` |
| `GET /admin/login` | `200`, 16,988 bytes, CSRF token and email/password fields present |
| Administrator login (real POST with CSRF) | `302` → `/admin/dashboard` |
| `GET /admin/dashboard` authenticated | `200`, 456,003 bytes |
| Database connectivity | 60 tables, 93 migrations recorded |
| `migrate:status` | all `Ran` |
| Application log after install | empty — no errors |
| Laravel / PHP / env | 12.66.0 / 8.3.33 / `production`, debug **OFF** |

### Restart persistence

`docker compose down` (without `-v`) then `up -d`:

| After restart | Result |
|---|---|
| Containers | both `healthy` |
| Tables | 60 (unchanged) |
| Migrations | 93 (unchanged) |
| Administrator row | intact |
| Login | `302` → dashboard, dashboard `200` |
| SCA module page | still renders |

### Backup and restore

```
./scripts/db-backup.sh
OK  ./backups/sca-sca_krayin-20260911T181533Z.sql.gz  (20K)

./scripts/db-restore.sh backups/sca-sca_krayin-20260911T181533Z.sql.gz
OK  restored 'sca_krayin_restore_test' with 60 tables
```

Restore went into an **isolated** database, not the live one. Verification: live 60
tables, restored 60 tables, administrator row present in the restored copy. The test
database was dropped afterwards. Dumps are Git-ignored (`/backups/`), confirmed with
`git check-ignore`.

The backup script validates the gzip stream and the dump header, and deletes the file
rather than leaving a truncated dump that looks like success. The restore script defaults
to a throwaway database and demands typed confirmation before overwriting the live one.

**A dump on this VPS is not a durable backup.** Off-server backups are not implemented.
Before SCA holds real provenance data, encrypted dumps must be pushed to S3-compatible
object storage on a schedule, with retention and periodic restore rehearsal.

### SCA extension proof

Path: `app/packages/Sca/Foundation`

Registers an `SCA Foundation` admin menu entry, a matching ACL entry, the namespaced
route `admin.sca.foundation.index` at `/admin/sca/foundation`, and a page rendering
**SCA Foundation Ready**.

| Check | Result |
|---|---|
| Route registered | `GET\|HEAD admin/sca/foundation → Sca\Foundation\...` |
| Menu entry in rendered dashboard | present |
| Page authenticated | `200`, marker text rendered |
| Page **un**authenticated | `302` → `/admin/login` (not public) |
| Core/vendor files modified | none |

It mounts under the same prefix and middleware stack (`web`, `admin_locale`, `user`) that
Krayin's own `AdminServiceProvider` uses, so it is protected by the ordinary staff login
rather than being separately secured.

No SCA product-domain schema was created. `ModuleServiceProvider` declares no models
deliberately.

---

## 7. Findings

### 1. Krayin's installer cannot complete under `APP_ENV=production` — HIGH friction

`krayin-crm:install` calls `migrate:fresh` **without `--force`**. Laravel refuses
destructive migrations in production unless confirmed, and with no interactive terminal
the command is silently **cancelled**. The installer does not check, and proceeds to
seeding, which then fails with a confusing unrelated error:

```
Step: Migrating all tables...
   APPLICATION IN PRODUCTION.
   WARN  Command cancelled.
Step: Seeding basic data...
   SQLSTATE[42S02]: Base table or view not found: 1146 Table 'sca_krayin.attributes' doesn't exist
```

The visible error names the wrong problem entirely — nothing suggests the migration was
skipped. Zero tables were created.

**Workaround used:** set `APP_ENV=local` for the install, then restore `APP_ENV=production`
and `optimize:clear`. Verified production afterwards.

**Recommendation:** document this in the install runbook permanently. Any future
reinstall or a fresh permanent-server build will hit it again.

### 2. `krayin-crm:install` silently overwrites application config — MEDIUM

The installer runs `vendor:publish --provider=CoreServiceProvider --force`, which
overwrites `config/concord.php`. This **discarded the SCA module registration** with no
warning. It was caught by diffing against pristine upstream, not by any error.

Anything SCA adds to a publishable config file will be destroyed by a reinstall or
upgrade. A warning comment now sits in `config/concord.php`, and the runbook's upgrade
procedure covers re-applying it.

### 3. A default administrator account is created even when explicitly skipped — SECURITY

`--skip-admin-creation` skips the interactive prompt, but the seeder **still creates**:

```
id=1  Example Admin  admin@example.com  role_id=1 (super admin)  status=1
```

Verified with `password_verify()` that the password was the well-known default
`admin123`, and that the account was active with full privileges.

Anyone following Krayin's documented non-interactive install ends up with a live super
admin on published credentials. If such an instance were ever exposed, it is an immediate
full compromise.

**Remediated here:** account id 1 was rewritten with a real address and a generated
24-character password hashed with bcrypt cost 12. Verified afterwards that `admin123` no
longer authenticates, that the new password does, and that **0** `@example.com` accounts
remain.

The password is **not** in this repository and not in this report. It is stored outside
the repo at mode 0600 on the VPS; the operator should move it to a password manager and
rotate it. Rotation procedure is in the runbook.

### 4. Known vulnerable dependency — HIGH, NOT remediated

`composer audit` reports:

| Field | Value |
|---|---|
| Package | `maatwebsite/excel` |
| Installed | **3.1.68** |
| Severity | **High** |
| CVE | CVE-2026-84374 |
| Advisory | `GHSA-c7r6-vx3h-w5g2` |
| Title | Laravel Excel writes exports outside the configured filesystem disk when given a caller-controlled path |
| Affected | `>=3.1.8, <3.1.70` |
| Fixed in | **3.1.70**, which satisfies Krayin's own `^3.1` constraint |

This was **deliberately not fixed**. The task pins a Krayin release, and changing the
resolved dependency set is an architecture decision, not an implementer's call. Current
exposure is low: the instance is loopback-only, holds no real data, and exploitation
needs an authenticated admin performing an export with a controlled path.

**Recommendation — must be resolved before real data or any public exposure:**

```bash
docker compose exec -u 33:33 app composer update maatwebsite/excel --with-dependencies
```

Then re-run `composer audit` and the smoke tests. Requesting approval for this as a small
follow-up task.

### 5. Apache vhost defeats the documented docroot setting — fixed

The `php:8.3-apache` image hard-codes `DocumentRoot /var/www/html` in its vhost, and a
VirtualHost `DocumentRoot` beats the server-level one in `conf-enabled`. Apache therefore
served the Laravel project root — which holds `.env` and `vendor/` — and the deny rule
turned every request into a blanket `403`.

Fixed in the Dockerfile, which now rewrites the vhost and asserts the result so the build
fails loudly if upstream changes the layout.

**Verified not leaking:** `/.env`, `/composer.json`, `/vendor/autoload.php`,
`/storage/logs/laravel.log`, `/app/.env` and `/../.env` all return Krayin's 404 page, not
file content.

Minor observation: those 404 pages are served with HTTP status `200` rather than `404`.
Cosmetic and not a leak, but it will confuse monitoring later.

---

## 8. Security validation

| Check | Result |
|---|---|
| Secrets in tracked files | none — scanned all tracked files |
| Real `.env` files tracked | **0** — both Git-ignored, verified with `git check-ignore` |
| Temporary VPS IP or hostname in tracked files | none |
| Default credentials | none — `@example.com` accounts: 0; `admin123` rejected |
| Debug mode | OFF; `APP_ENV=production` |
| Project root web-exposed | no — `public/` only, sensitive paths verified |
| Database host exposure | none — no host port binding; 3306 not listening on host |
| App exposure | `127.0.0.1:8080` only, never `0.0.0.0` |
| World-writable real files | **0** (6 matches were symlinks, whose permission bits are meaningless) |
| Writable dirs ownership | `storage/`, `bootstrap/cache/` = `www-data`, mode 755 |
| `.env` permissions | 0600 both |
| Composer audit | 1 high advisory — finding #4 |
| Application log after install | empty |

### Effect on the co-tenant

The unrelated live production stack was verified untouched at every stage: all five of its
containers still report **eight days** of continuous uptime, meaning none was restarted.
No shared network was created, its proxy was never modified, and no volume of its was
touched. Host memory never fell below ~2.4 GB available during the build.

---

## 9. Technical debt and known issues

1. **Off-server backups not implemented.** Highest-priority operational gap.
2. **`maatwebsite/excel` CVE unresolved** — finding #4.
3. **No automated test suite yet.** Verification here was live HTTP and database checks.
   Krayin ships `phpunit.xml`; a smoke test should be wired into the repo.
4. **No queue worker or scheduler.** Krayin runs fine without them at this stage; they
   will be needed before background jobs.
5. **No HTTPS.** Correct for loopback staging, but a blocker for any real use.
6. **Reinstall destroys SCA config registration** — finding #2.
7. **Assets were not rebuilt** — upstream prebuilt assets are used. Node is present for
   when theming starts.
8. **404 pages return HTTP 200** — finding #5.

---

## 10. Recommendations for future tasks

Recommendations only — not started, and not to be treated as approved scope.

1. Resolve the `maatwebsite/excel` advisory.
2. Implement off-server encrypted backups with retention and a restore rehearsal.
3. Add a minimal automated smoke test and wire it into the repository.
4. Decide the staging hostname question deliberately. Exposing Krayin publicly requires
   restarting the co-tenant's reverse proxy, which briefly drops an unrelated live site.
   That needs consent and a scheduled window — it should be its own task.
5. Only then begin the SCA provenance domain, inside `packages/Sca`.

### Proposed change to architecture or task queue

One, marked clearly as a recommendation:

**The architecture describes this machine as a "blank VPS"** (ADR-0005,
`INFRASTRUCTURE_BLUEPRINT.md`). It is not — it carries an unrelated live production
tenant that owns ports 80/443, on a host with no swap. Every constraint in this report
flows from that. The blueprint should be corrected so future tasks are planned against
the real environment.

---

## 11. Git state

Repository: **`francisjonee/francisjonee-sca-platform-private`** (private). Working path
on the VPS: `/opt/sca-platform`. Branch: `chore/sca-krayin-install-001`, **pushed**.

| # | SHA | Purpose |
|---|---|---|
| — | `56d4a64` | The repository's own `Initial commit` on `main`, pre-existing |
| 1 | `564df08` | Local repository initialization (README, .gitignore) |
| 2 | `e273a69` | Deployment foundation + pinned Krayin v2.2.6 source |
| 3 | `a02dfcb` | SCA Foundation proof module + backup/restore scripts |
| 4 | `0d3cf07` | Apache docroot fix, concord re-registration, runbook |
| 5 | `7ddb2a9` | Task report (this file) |
| 6 | `72a5ff4` | Merge commit joining this work onto the repository's `main` |

The repository was initialized with its own root commit while this task's work was
committed locally, leaving two unrelated histories a pull request could not merge. They
were joined with a merge rather than a rebase, deliberately: a merge is additive, so
commits 1-5 keep the SHAs listed above and this report stays accurate.

**Branch is pushed. No pull request exists yet** — see § 12. Nothing is merged into
`main`.

---

## 12. Blocker

One step remains: **opening the pull request.**

Access to the implementation repository is a deploy key. A deploy key can push a branch
but cannot call the GitHub API, and opening a pull request is an API action. The GitHub
CLI is not installed on this host and no account-level credential is present.

### Action required — operator, one click

Open a pull request from `chore/sca-krayin-install-001` into `main` in
`francisjonee/francisjonee-sca-platform-private`.

**Do not merge it.** ChatGPT must audit the installation and this report first.

If future tasks should open their own pull requests without operator involvement, that
needs a fine-grained personal access token scoped to this repository. That is a broader
grant than a deploy key and is the operator's decision, not Claude's.

## 13. Scope confirmation

Explicitly confirmed:

- no SCA product-domain features built — no eyewear items, certifications, QR identifiers,
  ownership, transfers, service history, or collector accounts;
- no provenance or authentication data model created;
- no QR generated or published;
- no Shopify connection made and no scope changed;
- no DNS changed;
- no PostgreSQL introduced;
- no Next.js or Prisma foundation built;
- no vendor or core modification remains — verified against pristine upstream;
- no queued task from `TASK_QUEUE.md` started;
- no governance, roadmap, or ADR file modified;
- no pull request merged — none exists yet;
- nothing self-approved, and no next task invented;
- the unrelated production tenant was not modified in any way.

**Awaiting ChatGPT architecture audit.**

# SCA-KRAYIN-INSTALL-001 — generation 0 — implementer evidence

**RESULT:** `BLOCKED_REPOSITORY_ACCESS`

**Implementer:** Claude
**Date:** 2026-09-11
**Repo state:** `origin/main` @ `c42cfb2`
**Environment:** the temporary SCA VPS, Ubuntu

> **Note on detail.** This repository is public. The server address, hostname, the
> unrelated production tenant sharing this host, and its service inventory are
> deliberately generalised below, following the precedent set in
> `audits/SCA-RECOVERY-001-gen0-EVIDENCE.md`. Counts, versions, and conclusions are
> unchanged. The unredacted detail was given to the operator in session.

Inputs read: `README.md`, `CLAUDE.md`, `docs/ADR-0006-KRAYIN-CRM-ADMIN-FOUNDATION.md`,
`docs/ROADMAP.md`, `docs/EXECUTION_WORKFLOW.md`, `.claude/rules/github-flow.md`,
`.claude/rules/output.md`, `.claude/memory/*`, `NEXT_TASK.md` @ `c42cfb2`.

ADR-0006 is present and read. Krayin is understood as the approved admin foundation, and
as superseding the Next.js / Prisma / PostgreSQL direction in ADR-0005.

---

## Summary

**No installation was attempted.** The task cannot reach a required dependency, so it
stops at task step 2 under the `BLOCKED` outcome defined in
`docs/EXECUTION_WORKFLOW.md`.

Two things need the architect's attention. The first blocks the task. The second does not
block it, but it contradicts a stated premise of the architecture and should be resolved
before Krayin is installed.

1. **Blocker — no write path to `francisjonee/sca-platform`.** The credential available to
   this environment reaches exactly one repository, this one, read-only as far as has been
   proven. It cannot create a repository.
2. **Premise correction — the VPS is not blank.** It carries a live production tenant.

---

## 1. The blocker

Task step 2 requires the private implementation repository `francisjonee/sca-platform`,
and task step 14 requires a branch, a push, and a pull request there.

What this environment actually has:

| Capability | State | How it was established |
|---|---|---|
| GitHub CLI (`gh`) | **Not installed** | `command -v gh` returns nothing |
| Account-level credential | **None found** | No `gh` config; no credential helper configured |
| Deploy key → `Shopify-Jeremy` | **Works** | SSH authenticated; `git ls-remote` returned all refs |
| Deploy key → write access | **Unproven** | See note below |
| Deploy key → any other repo | **Impossible by design** | A deploy key is scoped to one repository |

**Word check:** *deploy key* = an SSH key that unlocks exactly one repository. It cannot
list, create, or reach any other repository on the account.

A deploy key cannot create a repository under any circumstances. Repository creation is an
account-level operation. So no combination of the credentials present here can satisfy task
step 2.

**On the unproven write access.** Two read-only probes of the push permission — a
`git-receive-pack` handshake and a `git push --dry-run`, neither of which modifies a
repository — were refused by this environment's own command-safety controls. Rather than
route around that refusal, it is recorded here as unproven. It does not change the blocker:
even with write access, that key opens `Shopify-Jeremy` only.

## 2. Premise correction — the VPS is not blank

`docs/ADR-0005` and `docs/INFRASTRUCTURE_BLUEPRINT.md` both describe the target machine as
a **"blank VPS"**. ADR-0006 inherits that framing without revisiting it.

It is not blank. It runs an **unrelated live production application** — five containers,
serving real traffic, up continuously for eight days at time of writing. That application
is not part of SCA and is not Jeremy's.

Verified facts about the host, with the tenant generalised:

| Property | Measured | Consequence for this task |
|---|---|---|
| Ports 80 and 443 | **Both bound** by the production tenant's reverse proxy | Krayin cannot take them. A public hostname means sharing that proxy |
| Swap space | **None configured** | No overflow when memory runs out; the kernel kills a process, and it may pick the production one |
| Memory | 5.9 GB total, ~4.0 GB available; tenant uses ~0.4 GB | Enough for Krayin if capped, not enough to be careless with |
| CPU | 4 cores | Adequate |
| Disk | 372 GB free of 387 GB | Ample |
| Database port 3306 | **Not publicly bound** | Good baseline; must stay that way |

Why this matters to the architecture, not just to operations:

- **Task step 3 prefers Docker and step 8 of the prior task forbade a new public endpoint.**
  Both remain satisfiable, but only if Krayin binds to localhost. Publishing Krayin on a
  domain later requires restarting the production tenant's proxy, which briefly interrupts
  an unrelated live business. That is a scheduling and consent question, not a technical
  one, and it is outside this task's authority.
- **"Temporary construction environment" implies a machine SCA can freely disturb.** This
  machine is not that. A memory spike during `composer install` is a production incident for
  someone else.
- The portability requirements in ADR-0005 §2 and the blueprint become *more* important
  here, not less. This host is shared, so it is doubly unsuitable as a single point of truth.

This is reported, not acted on. Whether to proceed on a shared host, move to a dedicated
one, or accept the constraint is the architect's decision.

## 3. What already exists on the VPS

A Krayin scaffold predating ADR-0006 is present in the SCA working directory. It was
created 2026-09-11, before the Krayin decision was recorded, and it happens to align with
it.

| File | Purpose |
|---|---|
| `docker-compose.yml` | Application + MariaDB service definitions, memory-capped |
| `app.Dockerfile` | PHP 8.3 + Apache, Composer 2, Node 20 |
| `apache-override.conf` | Laravel docroot set to `/public`; project root denied |
| `php-custom.ini` | `memory_limit` 512M, deliberately not the 4G Krayin's docs suggest |
| `.env` | Database credentials, mode 0600, not committed anywhere |

State: **nothing is built and nothing is running.** Krayin itself was never downloaded.
The application directory does not exist. This is configuration only, and it is not under
version control.

It targets Krayin v2.2.6. **That version claim is inherited, not verified.** Task step 1
requires confirming the upstream project, its MIT license, the appropriate stable release,
and the required PHP/Laravel/Composer/Node/database versions directly from the official
source. That verification has not been performed and must not be skipped by assuming the
scaffold is correct.

## 4. What is reachable once the blocker clears

Task steps 1 and 3 through 13 do not depend on the implementation repository. They can be
executed and proven locally, with the commit and PR held until push access exists:

version selection and license verification; installation; persistent database volume;
environment configuration; migrations and admin account creation; runtime proof; restart
persistence; backup and restore; the SCA proof module demonstrating a clean vendor
boundary; and the security validation sweep.

Only steps 2 and 14 are hard-blocked.

## 5. Exact human action required

Either option unblocks the task. Both are approval-gated under `CLAUDE.md` §5, so the
operator performs them, not Claude.

### Option A — repository plus a write deploy key (recommended, least privilege)

1. Create `francisjonee/sca-platform` in the GitHub UI. Set visibility to **Private**.
   Initialize with a `main` branch.
2. Claude generates an SSH keypair on the VPS and returns the public half.
3. Add it under the new repository → Settings → Deploy keys, with **Allow write access**
   enabled.

This grants exactly one repository and nothing else. The private key never leaves the
server and is never committed.

**Limitation, stated honestly:** a deploy key can push a branch but cannot open a pull
request, because opening a PR is an API action requiring account authentication. Under this
option Claude pushes `chore/sca-krayin-install-001` and returns a compare link; the operator
clicks "Create pull request". The PR still must not be merged before audit.

### Option B — a fine-grained personal access token

Scoped to `sca-platform` only, with repository-creation permission if the repository is not
created by hand. This satisfies step 14 end to end, including opening the PR.

Broader than Option A. A token is account-level; a deploy key is not. Recommended only if
the architect wants the full step-14 loop automated.

### Also required — a decision on the shared host

Section 2 is a business and consent question, not a technical one. Requested:

- confirmation that installing Krayin on a host carrying an unrelated production tenant is
  acceptable; and
- confirmation that Krayin binds to **localhost only** in this task, deferring any public
  hostname — and the proxy restart it would require — to a later, separately scheduled task.

## 6. Security findings

1. **No secret was committed, printed, or copied.** This report contains no address,
   hostname, credential, token, or database URL.
2. **No credential discovery was performed.** An attempt to enumerate token environment
   variables and credential files was refused by this environment's safety controls and was
   not retried by another route. Only `gh`'s absence was established, by checking whether
   the command exists.
3. **Pre-existing exposure, unchanged by this task:** ports 80 and 443 are publicly bound by
   the unrelated tenant. Not SCA's to alter, and noted only because SCA cannot use them.
4. **Database port is not publicly exposed.** Task step 4 requires this to remain true.
5. **The scaffold's `.env` is mode 0600 and is not in any repository.** It must be Git
   ignored when the implementation repository exists.
6. **`memory_limit` is 512M, not the 4G Krayin's documentation suggests.** On a swapless
   host shared with production, raising it is a production risk for the other tenant. If
   `composer install` is killed for memory, the correct remedy is swap, not a higher limit.

---

## Acceptance criteria — line by line

Nothing was installed, so most criteria are not reached. Listed in full so the audit can
confirm the comparison was made.

| Criterion | Result |
|---|---|
| `RESULT` | **`BLOCKED_REPOSITORY_ACCESS`** |
| Official Krayin upstream repository | **Not verified.** Task step 1 not started |
| MIT license confirmation | **Not verified** |
| Selected Krayin version / tag / commit | **Not selected.** Scaffold names v2.2.6; unverified, section 3 |
| PHP / Laravel / Composer / Node versions | Not established — nothing installed |
| MySQL / MariaDB version | Not established |
| Docker / Compose versions | Not established |
| VPS application path | Exists as configuration only; no application present, section 3 |
| Deployment topology | Not built |
| Private repository URL / name | **Unreachable.** Section 1 |
| Proof repository is private | Not applicable — repository not reached |
| Branch name | Not created in the implementation repository |
| Commit SHA | None in the implementation repository |
| PR URL / number | None |
| Proof PR unmerged | Not applicable — no PR exists |
| Application load / login page / admin login | **Not run.** Nothing is installed |
| Database connectivity / migrations | Not run |
| Dashboard smoke test | Not run |
| Restart / persistence | Not run |
| Backup command and result | Not created |
| Restore test | Not run |
| SCA proof extension | Not created |
| Proof no vendor/core modified | Not applicable — no vendor tree exists |
| Composer audit | Not run |
| Secret scan | This report reviewed before commit; no secret present |
| Default-credential check | Not applicable — no installation |
| Debug / public exposure check | Not applicable |
| Database exposure check | Port 3306 not publicly bound, section 2 |
| Security findings | Section 6 |

## Scope confirmation

Explicitly confirmed, as required by the task:

- no SCA product-domain features were built;
- no Shopify connection was made, and no scope was changed;
- no DNS was changed;
- no permanent QR was created or published;
- no PostgreSQL was introduced;
- no vendor or core files were modified — none exist;
- no Next.js / Prisma / PostgreSQL foundation was built;
- no repository was created;
- no container was started, stopped, or altered;
- the unrelated production tenant on this host was not touched in any way;
- no next task was invented, and nothing was self-approved.

All commands run for this report were read-only.

**Awaiting ChatGPT architecture audit.**

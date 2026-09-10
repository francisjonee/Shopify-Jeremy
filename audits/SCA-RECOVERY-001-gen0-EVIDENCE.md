# SCA-RECOVERY-001 — generation 0 — implementer evidence

**RESULT:** `BLOCKED_SOURCE_ACCESS`

**Implementer:** Claude
**Date:** 2026-09-10
**Repo state:** `origin/main` @ `1fef0dd`
**Environment:** the project VPS, Ubuntu 24.04

> **Note on detail.** This repository is public. Server addresses, hostnames, unrelated
> client project names, and the running service inventory are deliberately generalised
> below. The counts and conclusions are unchanged. The unredacted report was returned to
> the operator in session.

Inputs read: `README.md`, `CLAUDE.md`, `docs/PRODUCT_REQUIREMENTS.md`,
`docs/ARCHITECTURE.md`, `docs/EXECUTION_WORKFLOW.md`,
`docs/ADR-0004-VPS-HOSTING-SUPERSEDES-ADR-0001.md`,
`.claude/memory/implementation-recovery-required.md`, `audits/SCA-CTRL-002-DEFERRED.md`,
`NEXT_TASK.md`.

---

## Summary

No SCA / Second Chance Authenticators / Ownership Bridge application source is reachable
from this environment. Eight independent search paths were exhausted. Nothing was deleted,
moved, or modified.

Per `.claude/memory/implementation-recovery-required.md`, this is **not** a claim that no
implementation ever existed. It is a statement about reach: if prior work exists, it is
somewhere this VPS and this GitHub account cannot see. The exact human action to fix that
is in section 10.

---

## 1. Filesystem — every project directory on the VPS

Fifteen directories were enumerated. Only two relate to SCA:

| Path | What it actually is |
|---|---|
| `/opt/secondchanceeyewear` | This architecture repo — documentation only |
| `/opt/sca-controller` | The task controller from `SCA-CTRL-001`, plus its own clone of this same docs repo |

Neither holds application code. The remaining thirteen directories belong to unrelated
client projects and system services. None contains SCA source.

## 2. Every Git repository on the VPS

Eight Git working copies exist on the machine. Their remotes were read directly:

- two point at this architecture repo (`Shopify-Jeremy`);
- five point at unrelated projects;
- one has no remote.

A scan of every `.git/config` on the machine found **no** remote URL matching
`sca`, `eyewear`, `chance`, or `bridge`.

## 3. The GitHub account — all repositories

```
$ gh repo list --limit 200 --json name -q 'length'
32
$ gh api user/orgs -q '.[].login'
(none — the account belongs to no organizations)
```

All 32 repositories were listed and reviewed. The only Jeremy/SCA repository is this one.
Name searches scoped to this owner for `second chance`, `ownership bridge`,
`authenticators`, and `secondchance` returned nothing.

The token in use carries `repo` scope, so private repositories owned by this account are
visible. A repository owned by a **different** GitHub account would not be — see
section 10, option B.

## 4. This repository's entire history

```
$ git rev-list --all --count
40
$ git log --all --reverse --format='%h %ad %s' --date=short | head -1
ef453e2 2026-09-10 Initialize SCA architecture bridge
```

Every file that has ever existed here, across all 40 commits and all 4 branches, is
documentation, `.claude/` instructions, `audits/`, or the `ops/controller/` scripts from
`SCA-CTRL-001`. No application file was ever added and later removed.

## 5. Deployment surfaces — nothing SCA is running

Checked the web server configuration, the system service list, and the container runtime.

- No web host, virtual host, or `server_name` matching `sca`, `eyewear`, `authenticat`,
  or `secondchance`.
- No system service matching those terms.
- Eleven containers are running; every one belongs to an unrelated project.
- No host PostgreSQL is installed. The database containers present belong to other
  projects.

There is no SCA deployment, and no SCA database, on this machine.

## 6. Backups and archives

A filesystem-wide search for `.tar.gz`, `.zip`, `.sql`, and `.dump` files whose names
match `sca`, `eyewear`, `chance`, `bridge`, `jeremy`, or `shopify` returned **no matches**.
The backup directories on the machine contain no SCA-named archive.

## 7. Shopify fingerprints — none anywhere

```
$ find / -xdev -not -path '*/node_modules/*' \
    \( -name 'shopify.app*.toml' -o -name 'shopify.web.toml' -o -name '.shopify' \)
(no matches)
```

An SCA implementation with Shopify integration would almost certainly carry one of these
files. None exists on this host.

## 8. Full-text content search

A recursive, case-insensitive search of all project and home directories for
`ownership.?bridge`, `second.?chance.?(eyewear|authenticat)`, and
`secondchanceauthenticators` — excluding `node_modules`, `.git`, build output and caches.

Every hit outside this repository was an assistant log, session transcript, or config
file. **No source file matched.**

One hit is material to the audit: a project note dated 2026-09-10 recording that
`/opt/secondchanceeyewear` was created as an architecture bridge repo, and that no SCA
application existed anywhere at that time.

A session transcript from 2026-09-09 corroborates the origin. It shows the operator asking
for the SCA project folder to be created, the folder not existing yet, and this repository
being nominated as the project's home.

**The SCA workspace on this VPS was created from nothing on 2026-09-09. It was never a
checkout of prior work.**

## 9. Nothing was changed

No file was deleted, renamed, or overwritten. No repository was created. All searches were
read-only.

---

## 10. Exact human action required

One of these will unblock the task. Only Francis or Jeremy can perform them.

### Option A — the source is on a local machine (most likely)

Push it to a private repository on the account this VPS can already reach:

```bash
cd <folder holding the SCA code>
git init                       # only if it is not already a git repo
git add -A
git commit -m "Preserve existing SCA Ownership Bridge implementation"
gh repo create <owner>/sca-ownership-bridge --private --source=. --push
```

Then give Claude the repository name. **Do not delete the local copy** until recovery is
audited.

Creating that repository is an approval-gated action under `CLAUDE.md` §5, so the operator
performs it, not Claude.

### Option B — the source is under a different GitHub account

If Jeremy or a previous developer owns the repository, either:

- add this account as a collaborator with read access, then give Claude the repo URL; or
- give Claude the exact `owner/repo` name so access can be confirmed.

The current credential only sees repositories owned by this account. That is a genuine
blind spot, not a completed search.

### Option C — the source is on a different server

The search above covers **this** VPS only. If a second host exists, name it.

### Option D — no prior implementation exists

If the earlier SCA work was a prototype elsewhere, a no-code tool, or a different product,
then the honest baseline is zero. That is the architect's call after this audit, not
Claude's. This task forbids scaffolding a replacement.

---

## 11. Implemented vs missing — against `docs/ARCHITECTURE.md`

Nothing is implemented, so every surface is missing. Listed so the audit can confirm the
comparison was made.

| Architecture element | Status |
|---|---|
| Data model — `collector_accounts`, `eyewear_items`, `authentications`, `ownership_events`, `transfer_requests`, `service_events`, `status_events`, `shopify_sale_links`, `qr_identifiers` | Not implemented |
| Claim state machine | Not implemented |
| Shopify integration, read-only scopes, store connection rule | Not implemented |
| Webhooks, idempotency, audit trail | Not implemented |
| Public QR route and field allowlist | Not implemented |
| Admin / CRM surface | Not implemented |
| Collector Portal — My Collection | Not implemented |
| Public Registry | Not implemented |
| Serial creation, QR generation, customer claiming, duplicate ownership protection | Not implemented |
| PostgreSQL schema, migrations, ORM | Not implemented |
| Deployment configuration | Not implemented |

All defined as documentation in this repository only.

---

## 12. Security findings

1. **No accidentally committed secret found.** The full 40-commit history of this
   repository was scanned. Only environment variable **names** appear, in
   `ops/controller/controller.env.example`. No token, key, database URL, `.env` content,
   or customer data.

2. **No production coupling found.** Nothing on this VPS connects to a live Shopify store,
   and no SCA database or deployment exists to be coupled to.

3. **Blind spot, recorded deliberately:** the search covers this VPS and repositories owned
   by this GitHub account. It cannot see repositories owned by other accounts, private
   machines, or other hosts. Section 10 addresses each.

4. **This report was redacted before commit.** The unredacted version named the VPS
   address, its hostname, unrelated client project directories, and the full running
   service inventory. Publishing that to a public repository would hand an attacker a map
   of the machine. The substance, counts, and conclusions are unchanged.

5. **Nothing was exposed by this task.** All commands were read-only. No credential was
   read, printed, or copied.

---

## Acceptance criteria — line by line

| Criterion | Result |
|---|---|
| `RESULT` | **`BLOCKED_SOURCE_ACCESS`** |
| Implementation source path | **None found.** Eight search paths, sections 1–8 |
| Repository URL | **None.** Only this architecture repo — documentation, not the app |
| Branch and commit SHA | Not applicable — no implementation found |
| Framework / runtime / package manager | Not applicable |
| Database / schema / ORM | Not applicable. No SCA database exists on this host (section 5) |
| Authentication summary | Not applicable |
| Shopify integration summary | Not applicable. No Shopify project files anywhere (section 7) |
| Feature inventory (serial, QR, claim, duplicate protection, My Collection, admin, customer) | **None present.** Section 11 |
| Deployment configuration | Not applicable. Nothing SCA is deployed (section 5) |
| Environment variable names only | None discovered — no application config exists. No values to redact |
| Safe start / build / test commands | **None discovered.** No `package.json`, `Makefile`, or equivalent exists |
| Build / test / static-check result | Not runnable — there is no code to check |
| Implemented vs missing comparison | Section 11 |
| Security findings | Section 12 |
| Exact human recovery action | Section 10 |

**Prohibited changes — none performed.** No scaffold, no rebuild, no new features, no data
model change, no Shopify scope change, no store contact, no deploy or restart, no DNS or
QR change, no new repository created, no secret exposed, no next task invented, no
self-approval.

**Awaiting ChatGPT architecture audit.**

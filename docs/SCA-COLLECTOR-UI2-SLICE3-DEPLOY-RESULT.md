# SCA Collector Experience / UI 2.0 — Slice 3 Deployment Result

**Status:** DEPLOYED to production. Awaiting ChatGPT independent POST-DEPLOYMENT audit. Slice 3 is NOT closed; Collector UI 2.0 is NOT closed; no other initiative started.

| | |
|---|---|
| Governance approval (deploy gate) | `7c6909e3b316552a0498986af10b6d34b2e0ccf6` |
| Approved candidate | `a19f4721cc7d21229b2f23c380392ca0fc63cb86` |
| Audited production baseline | `ffef6dedfdd21d865c73bb809bf81c917b367dda` (confirmed unmoved pre-merge) |
| **MERGE_SHA** | **`6ca15958844dace74f7d087a10a3355a6497dd00`** |
| **ORIGIN_MAIN** | **`6ca15958844dace74f7d087a10a3355a6497dd00`** |
| **DEPLOYED_HEAD** | **`6ca15958844dace74f7d087a10a3355a6497dd00`** |
| Migration | **138** (PRE 138 / POST 138; "Nothing to migrate"; 0 pending) |
| Deployed-tree full gate | **1367 passed / 1 skipped / 0 failed** (7235 assertions) |
| PRE provenance FP | `d15a5cbdfb8df52ba65628b276533cfe`, counts `3/3/4/4/5/2/1/1/7` |
| POST provenance FP | `d15a5cbdfb8df52ba65628b276533cfe`, counts `3/3/4/4/5/2/1/1/7` (**unchanged**) |

## Pre-merge checks
- Resolved candidate full SHA `a19f4721cc7d21229b2f23c380392ca0fc63cb86`; local branch head = `origin/feat/sca-collector-ui2-slice3` = that SHA.
- Production `main` was exactly the audited baseline `ffef6de` (local = origin) immediately before merge — did NOT move.
- Candidate 1 ahead / 0 behind base.

## Controlled merge + content identity
- `--no-ff` merge of the approved candidate into `main` → merge commit `6ca1595`.
- Candidate → merge tree is **byte-identical**: `git diff --quiet a19f472..6ca1595` ⇒ no file delta (TREE_IDENTICAL). The merge introduces only the reviewed candidate content (6 collector views + `CollectorUi3Test.php`), no unreviewed change.
- `main` pushed to origin: `ffef6de..6ca1595`.

## Deploy
Deployed via the established `scripts/deploy-preview.sh` (deploys only `origin/main`; refuses anything else):
1. Checked out + hard-reset to `origin/main` `6ca1595`; HEAD==origin/main enforced.
2. Installed dev deps → ran the mandatory full `tests/Feature/Sca` gate on the exact deployed/merge tree (`set -e` would abort before any prod migrate on failure): **1367 passed / 1 skipped / 0 failed (7235 assertions)**.
3. `php artisan migrate --force` → **"Nothing to migrate"** (this slice adds no migration; stays 138).
4. Memory-capped image rebuild (`--memory=1500m`) + `docker compose up -d` (loopback bind preserved; co-tenant and ports 80/443 untouched).
5. Re-installed `--no-dev --optimize-autoloader` so the deployed vendor tree excludes dev packages.
6. `config:clear` + `route:clear`.

## Health + boundaries (no fabricated session)
- Containers: `kr-app` Up (healthy), `kr-mariadb` Up (healthy).
- `GET /admin/login` → **200**.
- Guest collector fail-closed (loopback, no session): `/collector`, `/collector/submissions`, `/collector/profile`, `/collector/account` all **302 → /collector/login**.
- No production collector/session was created; no provenance evidence fabricated.

## Dormancy / no-drift invariants
- **Stripe dormant**: `STRIPE_ENABLED` unset (defaults false), `STRIPE_SECRET` absent; config not cached, so effective `sca-stripe.enabled` is false.
- **`MAIL_MAILER=log`** (unchanged).
- **Shopify OAuth `SHOPIFY_SCOPES=read_orders`** (unchanged; no scope expansion).
- No Caddy/DNS/provider/infrastructure change: `/opt/smsrocket-stack/Caddyfile` untouched (last modified Oct 9, pre-dating this deploy); edge/DNS/OAuth/SMTP all unchanged.

## Provenance-untouched proof
13-table row-data fingerprint identical PRE and POST deploy: `d15a5cbdfb8df52ba65628b276533cfe`, canonical counts `3/3/4/4/5/2/1/1/7`. No schema change; migration 138.

**STOP — awaiting ChatGPT independent post-deployment audit of `6ca1595`. Slice 3 not closed; Collector UI 2.0 not closed; Market Reference Slice 2 / any other initiative NOT started.**

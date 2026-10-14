# SCA Market Reference / Value History — Slice 2 Deployment Result

**Status:** DEPLOYED to production. Awaiting ChatGPT independent POST-DEPLOYMENT audit. Slice 2 is NOT closed; no other initiative started.

| | |
|---|---|
| Governance approval (deploy gate) | `8b389ccfd3d30fb1c6bf9cd379fb0ddce2e40b9c` |
| Approved candidate | `9e8453e2bad54ed24ef22a151c881e539b9dc8be` |
| Audited production baseline | `6ca15958844dace74f7d087a10a3355a6497dd00` (confirmed unmoved pre-merge) |
| **MERGE_SHA** | **`3b30a0f24323463c42dda58b476a453f58e49389`** |
| **ORIGIN_MAIN** | **`3b30a0f24323463c42dda58b476a453f58e49389`** |
| **DEPLOYED_HEAD** | **`3b30a0f24323463c42dda58b476a453f58e49389`** |
| Migration | **138** (PRE 138 / POST 138; "Nothing to migrate"; 0 pending) |
| Deployed-tree full gate | **1380 passed / 1 skipped / 0 failed** (7308 assertions) |
| PRE provenance FP | `d15a5cbdfb8df52ba65628b276533cfe`, counts `3/3/4/4/5/2/1/1/7` |
| POST provenance FP | `d15a5cbdfb8df52ba65628b276533cfe`, counts `3/3/4/4/5/2/1/1/7` (**unchanged**) |

## Pre-merge checks
- `origin/main` was exactly the audited baseline `6ca1595` immediately before merge (local = origin) — did NOT move.
- Approved candidate `9e8453e` (local = origin), 1 ahead / 0 behind.

## Controlled merge + content identity
- `--no-ff` merge of the approved candidate into `main` → merge commit `3b30a0f`.
- Candidate → merge tree **byte-identical**: `git diff --quiet 9e8453e..3b30a0f` ⇒ no file delta (TREE_IDENTICAL). Only the reviewed 5-file candidate content (MarketReferenceService, CollectionService, CollectionController, collection/show.blade, new MarketReferenceHistoryTest).
- `main` pushed to origin: `6ca1595..3b30a0f`.

## Deploy (established `scripts/deploy-preview.sh`, origin/main only)
First gate run **aborted at the mandatory SCA test gate BEFORE any production migrate** (`set -e`), on `QrReissueTest::rg8` ("certification authentication and ownership are untouched", line 286) — the documented unrelated QR-reissue flake (projection `rebuilt_at` off-by-one-second under full-suite load; `QrService::reissue`→`rebuild` stamps `rebuilt_at`). Production was untouched (no migrate/rebuild ran; FP/migration verified unchanged). `QrReissueTest` was then confirmed **11/11 green in isolation**, establishing it as a load-sensitive flake, not a Slice-2 regression (Slice 2 touches only Market Reference read/presentation). Per the established fail-before-migrate/re-run policy the gate was re-run.

Clean re-run:
1. Checked out + hard-reset to `origin/main` `3b30a0f`; HEAD==origin/main enforced.
2. Full `tests/Feature/Sca` on the exact merge tree: **1380 passed / 1 skipped / 0 failed (7308 assertions)**.
3. `php artisan migrate --force` → **"Nothing to migrate"** (no migration this slice; stays 138).
4. Memory-capped image rebuild (`--memory=1500m`) + `docker compose up -d` (loopback bind preserved; co-tenant/ports 80-443 untouched).
5. Re-installed `--no-dev --optimize-autoloader` (deployed vendor excludes dev packages).
6. `config:clear` + `route:clear`.

## Health + boundaries (no fabricated session)
- Containers: `kr-app` Up (healthy), `kr-mariadb` Up (healthy).
- `GET /admin/login` → **200**.
- Guest collector fail-closed (loopback, no session): `/collector`, `/collector/collection` → **302 → /collector/login**.
- Public value-free boundary: proven on the exact merge tree by `MarketReferenceHistoryTest::m12` (certified/QR-active/owned item with a Market Reference history → `/p/{token}` contains no "Value history"/"Market Reference"/range figures). No production collector/session fabricated.

## Dormancy / no-drift invariants
- **Stripe dormant**: `STRIPE_ENABLED` unset, `STRIPE_SECRET` absent.
- **`MAIL_MAILER=log`** (unchanged).
- **Shopify OAuth `SHOPIFY_SCOPES=read_orders`** (unchanged; no scope expansion).
- No Caddy/DNS/provider/infrastructure change: `/opt/smsrocket-stack/Caddyfile` untouched (mtime Oct 9, pre-dating this deploy).

## Provenance-untouched proof
13-table row-data fingerprint identical PRE and POST deploy: `d15a5cbdfb8df52ba65628b276533cfe`, canonical counts `3/3/4/4/5/2/1/1/7`. No schema change; migration 138. (Market Reference ledger counts are outside the 13-table provenance fingerprint and are advisory, non-provenance; no ledger rows were created by this deploy.)

**STOP — awaiting ChatGPT independent post-deployment audit of `3b30a0f`. Slice 2 not closed; no other initiative started.**

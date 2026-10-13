# SCA Collector Experience / UI 2.0 — Slice 2 Deployment Result (post-merge)

**Status:** DEPLOYED to production. Awaiting ChatGPT independent post-deployment audit. Slice 2 NOT declared closed; no other initiative started.

| | |
|---|---|
| Governance approval (pre-merge PASS) | `99387ae87f0b17050de904d1d64e02cdf5fba831` |
| Approved candidate | `dba6c4d7b83b674615f461d081f64d9c07e2077d` |
| Production base before deploy (audited) | `e20e549948ecbf5c967d48a7444275280dafb97c` (migration 138) |
| **MERGE_SHA** | **`ffef6dedfdd21d865c73bb809bf81c917b367dda`** |
| **ORIGIN_MAIN** | **`ffef6dedfdd21d865c73bb809bf81c917b367dda`** |
| **DEPLOYED_HEAD** | **`ffef6dedfdd21d865c73bb809bf81c917b367dda`** (`Deployed main @ ffef6de`) |
| Migration | **138 (unchanged)** — `Nothing to migrate`; none expected/permitted |
| Full merge-tree SCA gate | **1347 passed / 1 skipped / 0 failed (7041 assertions)** (clean first run) |

## 1. Merge discipline
- Production/main reconfirmed at the audited baseline `e20e549` (local == origin == audited base) immediately before merge — main had not moved.
- Approved candidate `dba6c4d` was exactly **1 ahead / 0 behind**, parent == baseline.
- Merged with an auditable `--no-ff` merge commit `ffef6de`.
- **Candidate→merge content identity proven:** `git diff --stat ffef6de dba6c4d` is **empty** — merge commit only, no unreviewed file/content delta.
- `origin/main` advanced `e20e549 → ffef6de`; deploy ran only merged `main`.

## 2. Test gate (exact merge tree, disposable `sca_domain_test`)
`scripts/deploy-preview.sh` installed dev deps then ran the full `tests/Feature/Sca` gate with `set -e`: **1347 passed / 1 skipped (webp) / 0 failed, 7041 assertions** on the first run (no flakes), then proceeded. This includes the Slice-2 suite `CollectorCollectionUi2Test` (12: browse-first/manage-secondary, group switcher + active-group context, authorized card images, asset-hero owner-scoping, Market Reference prominence/absence, passport eligibility, visibility/organize routes, transfer adverse-gating, separated safety actions, gallery aria-pressed, no sensitive leak, zero mutation) plus CP-2/CP-4/CP-6, item-detail parity/gallery, transfer/status, Market Reference and Collector Experience regressions — all green on the deployed tree.

## 3. Migration
`php artisan migrate --force` → **`Nothing to migrate`**. Production migration remains **138** (count 138). No schema change (presentation/read-model only).

## 4. PRE / POST production invariants (identical)
| Invariant | PRE | POST |
|---|---|---|
| Last migration / count | migration 138 / 138 | migration 138 / 138 |
| 13-table provenance fingerprint | `d15a5cbdfb8df52ba65628b276533cfe` | `d15a5cbdfb8df52ba65628b276533cfe` |
| Canonical counts (items/qr/certs/auth/ownership/claims/grants/sale/status) | `3/3/4/4/5/2/1/1/7` | `3/3/4/4/5/2/1/1/7` |

Provenance fingerprint and counts byte/count identical PRE→POST. The slice introduced no writer and no table.

## 5. Production-safe smoke (no fabricated collector)
- `GET /admin/login` → **200**.
- Guest `GET /collector` → **302 → /collector/login**.
- Guest `GET /collector/collection` → **302 → /collector/login** (collector-auth shell boundary fail-closed).
- Authenticated collector Collection index/detail rendering and the Slice-1 shell/active-state are proven by the Slice-2 + Collector Experience + parity tests within the deployed merge-tree gate; not re-exercised live to avoid creating a fabricated collector/session.

## 6. Integration / config — no drift
- `kr-app` loopback-only `127.0.0.1:8080->80/tcp` (healthy); no public bind re-introduced.
- `sr-caddy` not recreated by this deploy (Up 4 days); `/opt/smsrocket-stack/Caddyfile` unchanged (mtime 2026-10-09). **No Caddy/DNS change.**
- `SHOPIFY_SCOPES=read_orders` (no OAuth change); `MAIL_MAILER=log` (no SMTP change); Stripe dormant (no keys). No provider/infrastructure drift.

## 7. Deployment steps executed (canonical gate)
`scripts/deploy-preview.sh` on merged `main@ffef6de`: dev-deps install → full SCA test gate (1347 passed) → `chown 33:33 storage bootstrap/cache` → `migrate --force` (Nothing to migrate) → memory-capped image rebuild (`--memory=1500m`) → `docker compose up -d` (loopback preserved; co-tenant/edge untouched) → `composer install --no-dev --optimize-autoloader` → `config:clear` + `route:clear` → health 200.

**STOP after deployment evidence. Slice 2 NOT declared closed; no other initiative started. Returned for ChatGPT independent post-deployment audit.**

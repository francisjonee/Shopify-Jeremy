# SCA Collector Experience / UI 2.0 — Slice 1 Deployment Result (post-merge)

**Status:** DEPLOYED to production. Awaiting ChatGPT independent post-deployment audit. Slice 1 NOT declared closed; Slice 2 / any other initiative NOT started.

| | |
|---|---|
| Governance approval (pre-merge PASS) | `8ff69442987e7600a099e9daf3e163cd490bcd18` |
| Approved candidate | `0c8628d352f9a0fb843774bff5281bc808a9248c` |
| Production base before deploy | `9cf72728248cf3e36d0525de4520d69717dacd5d` (migration 138) |
| **Merge SHA = main SHA = deployed SHA** | **`e20e549948ecbf5c967d48a7444275280dafb97c`** |
| Migration | **138 (unchanged)** — no migration in this slice (`Nothing to migrate`) |
| Full merge-tree SCA gate | **1335 passed / 1 skipped / 0 failed** (clean first run; no flakes) |

## 1. Merge discipline
- Production/main reconfirmed at baseline `9cf7272` (local == origin) before merge; approved candidate `0c8628d` was exactly **1 ahead / 0 behind**, parent == baseline.
- Merged with an auditable `--no-ff` merge commit `e20e549`.
- **Tree identity proven:** `git diff --stat e20e549 0c8628d` is **empty** — merge tree byte-identical to the approved candidate (merge commit only, no file/content delta).
- `origin/main` advanced `9cf7272 → e20e549`; deploy ran only merged `main`.

## 2. Test gate (exact merge tree, disposable `sca_domain_test`)
`scripts/deploy-preview.sh` installed dev deps then ran the full `tests/Feature/Sca` gate with `set -e`: **1335 passed / 1 skipped (webp) / 0 failed** on the first run (no flakes). The focused `CollectorExperienceTest` (15, incl. the R1 submission-progress tests ce12–ce15) and `AppPolishTest` (6) are part of that suite and passed, proving — on the deployed tree — guest `/collector` → sign-in, authenticated `/collector` renders Home, nav scoping/active-state, and truthful submission-progress labels.

## 3. Migration
`php artisan migrate --force` → **`Nothing to migrate`**. Production migration remains **138** (count 138). No schema change — this slice is presentation/read-model only.

## 4. PRE / POST production invariants (identical)
| Invariant | PRE | POST |
|---|---|---|
| Last migration / count | migration 138 / 138 | migration 138 / 138 |
| 13-table provenance fingerprint | `d15a5cbdfb8df52ba65628b276533cfe` | `d15a5cbdfb8df52ba65628b276533cfe` |
| Canonical counts (items/qr/certs/auth/ownership/claims/grants/sale/status) | `3/3/4/4/5/2/1/1/7` | `3/3/4/4/5/2/1/1/7` |

Provenance fingerprint and counts byte/count identical PRE→POST. The slice introduced no writer and no table.

## 5. Production-safe health / smoke (no fabricated evidence)
- `GET /admin/login` → **200**.
- Guest `GET /collector` → **302 → /collector/login** (unchanged guest-to-sign-in behavior).
- `collector.home` route registered → `HomeController` (the authenticated Home dashboard).
- An authenticated collector Home rendering successfully is proven by `ce2` within the deployed merge-tree gate (asserts 200 + Home content + nav); not re-exercised in production to avoid creating a fabricated collector/session.

## 6. Integration / config — no drift
- `kr-app` remains loopback-only `127.0.0.1:8080->80/tcp` (healthy); no public bind re-introduced.
- `sr-caddy` not recreated by this deploy (Up 4 days); `/opt/smsrocket-stack/Caddyfile` unchanged (mtime 2026-10-09). **No Caddy/DNS change.**
- `SHOPIFY_SCOPES=read_orders` (no OAuth change); `MAIL_MAILER=log` (no SMTP change); Stripe dormant (no keys). No schema/provider/infrastructure drift.

## 7. Deployment steps executed (canonical gate)
`scripts/deploy-preview.sh` on merged `main@e20e549`: dev-deps install → full SCA test gate (1335 passed) → `chown 33:33 storage bootstrap/cache` → `migrate --force` (Nothing to migrate) → memory-capped image rebuild (`--memory=1500m`) → `docker compose up -d` (loopback preserved; co-tenant/edge untouched) → `composer install --no-dev --optimize-autoloader` → `config:clear` + `route:clear` → health 200.

**STOP after deployment evidence. Slice 1 NOT declared closed; Slice 2 / another initiative NOT started. Returned for ChatGPT independent post-deployment audit.**

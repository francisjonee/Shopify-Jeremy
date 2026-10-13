# SCA Market Reference / Value History — Slice 1 Deployment Result (post-merge)

**Status:** DEPLOYED to production. Awaiting ChatGPT independent post-deployment audit. Slice 1 remains OPEN (not declared closed); no automated pricing / public value exposure / resale / new initiative started.

| | |
|---|---|
| Governance approval (pre-merge PASS) | `d6c333a6b8bea26a8cf4b50a69eda650e5062231` |
| Approved candidate | `d880e128e0713d60e42a2d821206cf663c09be43` |
| Production base before deploy | `b4b51b7bb0244da6e1624c1095239c80cc206bb9` (migration 137) |
| **Merge SHA = main SHA = deployed SHA** | **`9cf72728248cf3e36d0525de4520d69717dacd5d`** |
| Migration | 137 → **138** (`2026_10_19_000001_create_sca_market_reference_events`) |
| Full merge-tree SCA gate | **1320 passed / 1 skipped / 0 failed** (clean first run; no flakes) |

## 1. Merge discipline
- Production/main reconfirmed at baseline `b4b51b7` (local == origin) before merge; approved candidate `d880e12` was exactly **1 ahead / 0 behind**, parent == baseline.
- Merged with an auditable `--no-ff` merge commit `9cf7272`.
- **Tree identity proven:** `git diff --stat 9cf7272 d880e12` is **empty** — merge tree has zero changed files vs the approved candidate. No drift.
- `origin/main` advanced `b4b51b7 → 9cf7272`; deploy ran only merged `main` (deploy-preview.sh refuses anything else).

## 2. Pre-migration test gate (exact merge tree, disposable `sca_domain_test`)
`scripts/deploy-preview.sh` installed dev deps, then ran the full `tests/Feature/Sca` gate with `set -e` (aborts before the production migrate on any failure). Result: **1320 passed / 1 skipped (webp) / 0 failed** on the first run — no flakes — then it proceeded to migrate. (No unrelated QR flake occurred this deploy; none needed to be re-run.)

## 3. PRE / POST production invariants (identical)
| Invariant | PRE | POST |
|---|---|---|
| Last migration | `…create_sca_service_event_corrections` (137) | `…create_sca_market_reference_events` (138) |
| Migration count | 137 | 138 |
| 13-table provenance row-data fingerprint | `d15a5cbdfb8df52ba65628b276533cfe` | `d15a5cbdfb8df52ba65628b276533cfe` |
| Canonical counts (items/qr/certs/auth/ownership/claims/grants/sale/status) | `3/3/4/4/5/2/1/1/7` | `3/3/4/4/5/2/1/1/7` |
| `sca_service_events` | 0 | 0 |
| `sca_service_event_corrections` | 0 | 0 |
| `sca_market_reference_events` | table absent | present, **0 rows** |

Provenance fingerprint and all provenance/service-event/correction state are byte/count identical PRE→POST. The additive migration created an empty Market Reference ledger; **no production Market Reference was fabricated** for smoke testing.

## 4. Schema verification (production `sca_market_reference_events`)
- Table present.
- **9 CHECK constraints:** `chk_mre_disposition`, `chk_mre_currency`, `chk_mre_basis`, `chk_mre_low_bounds`, `chk_mre_high_bounds`, `chk_mre_range`, `chk_mre_payload` (disposition↔payload presence), `chk_mre_linkage` (disposition↔predecessor), `chk_mre_reason` (disposition↔reason).
- **3 triggers:** `trg_mre_no_update` (BEFORE UPDATE), `trg_mre_no_delete` (BEFORE DELETE), `trg_mre_bi` (BEFORE INSERT — same-item predecessor + lifecycle validity against the actual current effective event + monotonic append-order `NEW.created_at >= last.created_at`).
- **Indexes:** `idx_mre_item (eyewear_item_id,id)`, `idx_mre_item_order (eyewear_item_id,created_at,id)`, PRIMARY `(id)`, plus the two self-FK indexes.
- **FKs:** `eyewear_item_id → sca_eyewear_items`; `supersedes_event_id → sca_market_reference_events`; `voids_event_id → sca_market_reference_events` (all RESTRICT).

## 5. Production-safe health / boundary smoke (no fabricated evidence)
- `GET /admin/login` → **200**.
- Routes registered: `GET|HEAD` + `POST` `admin/sca/eyewear/{id}/market-reference` (`admin.sca.eyewear.market_reference.confirm` / `.apply`).
- `GET …/market-reference` (unauthenticated, loopback) → **302 → /admin/login** (route live + staff-gated).
- `POST …/market-reference` (unauthenticated, no CSRF) → **419** (CSRF fail-closed before controller).
- `sca_market_reference_events` row count after smoke: **0** (probes created nothing).
- Dedicated ACL / CSRF / throttle already proven by the exact merge-tree tests (`mr14`, boundary tests).

## 6. Integration / config unchanged
- `kr-app` remains **loopback-only** `127.0.0.1:8080->80/tcp` (healthy); no public bind re-introduced.
- Edge untouched: `sr-caddy` not recreated by this deploy (Up 4 days); `/opt/smsrocket-stack/Caddyfile` unchanged (mtime 2026-10-09). **No Caddy/DNS change.**
- `SHOPIFY_SCOPES=read_orders` unchanged — **no Shopify OAuth change**. `MAIL_MAILER=log` unchanged — **no SMTP change**. **Stripe remains dormant** (no Stripe keys configured).
- No unexpected change to ownership/current-state, authentication, certification/PDF/snapshot, QR, registry status, claim/transfer, Shopify sale links, collector accounts, or service history (provenance FP identical; service tables unchanged).

## 7. Deployment steps executed (canonical gate)
`scripts/deploy-preview.sh` on merged `main@9cf7272`: dev-deps install → full SCA test gate (passed 1320) → `chown 33:33 storage bootstrap/cache` → `php artisan migrate --force` (138 applied) → memory-capped image rebuild (`--memory=1500m`) → `docker compose up -d` (loopback binding preserved; co-tenant/edge untouched) → `composer install --no-dev --optimize-autoloader` (production dependency state) → `config:clear` + `route:clear` → health check 200.

**STOP after deployment evidence. Slice 1 NOT declared closed; no automated pricing / public value exposure / resale / new initiative. Returned for ChatGPT independent post-deployment audit.**

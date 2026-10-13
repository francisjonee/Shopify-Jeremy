# SCA Service-History Correction & Annotation — Deployment Result (post-merge)

**Status:** DEPLOYED to production. Awaiting ChatGPT independent post-deployment audit. Initiative remains OPEN (not declared closed); no new initiative started.

| | |
|---|---|
| Governance approval (pre-merge PASS) | `9e2a584a43503c9160707fdf7dc7758b9067315c` |
| Approved candidate | `2d578feb5f429d9e7549d968c21fbfc879ba0885` |
| Production base before deploy | `9bc0907c486688c7acd0d22ad2ee9f5db37d93bb` (migration 136) |
| **Merge SHA = main SHA = deployed SHA** | **`b4b51b7bb0244da6e1624c1095239c80cc206bb9`** |
| Migration | 136 → **137** (`2026_10_18_000001_create_sca_service_event_corrections`) |
| Full merge-tree SCA gate | **1285 passed / 1 skipped / 0 failed** |

## 1. Merge discipline
- Production/main reconfirmed at baseline `9bc0907` (local == origin) before merge; approved candidate `2d578feb` was exactly **1 ahead / 0 behind**, parent == baseline.
- Merged with an auditable `--no-ff` merge commit `b4b51b7`.
- **Tree identity proven:** `git diff --stat b4b51b7 2d578feb` is **empty** — the merge tree has zero changed files vs the approved candidate. No content drift.
- `origin/main` fast-forwarded `9bc0907 → b4b51b7`; deploy ran only merged `main` (deploy-preview.sh refuses anything else).

## 2. Pre-migration test gate (exact merge tree, disposable `sca_domain_test`)
The canonical `scripts/deploy-preview.sh` installs dev deps, then runs the full `tests/Feature/Sca` gate with `set -e` so any failure aborts **before** the production migrate.
- The first two gate runs aborted before migrate on **documented, unrelated QR flakes only** — `QrReissueTest::rg8` (a pre-existing one-second clock-boundary flake: `QrService::reissue` legitimately calls `ProjectionService::rebuild()` which stamps `rebuilt_at=now()`, and the test compares the projection row without unsetting `rebuilt_at`; proven **4/4 green in isolation**) and `QrArtifactTest::rg2` (the known random-token `DECODE_FAILED` QR-decode flake). Both are in production QR code untouched by this slice; production stayed at migration 136 (no migrate, no prune) on both aborts. Re-run per the established flake policy.
- The third gate run passed cleanly: **1285 passed / 1 skipped (webp) / 0 failed**, then proceeded to migrate.

## 3. PRE / POST production invariants (identical)
| Invariant | PRE | POST |
|---|---|---|
| Last migration | `…add_shopify_reconciliation` (136) | `…create_sca_service_event_corrections` (137) |
| Migration count | 136 | 137 |
| 13-table provenance row-data fingerprint | `d15a5cbdfb8df52ba65628b276533cfe` | `d15a5cbdfb8df52ba65628b276533cfe` |
| Canonical counts (items/qr/certs/auth/ownership/claims/grants/sale/status) | `3/3/4/4/5/2/1/1/7` | `3/3/4/4/5/2/1/1/7` |
| `sca_service_events` count | 0 | 0 |
| `sca_service_event_corrections` | table absent | present, **0 rows** |

Provenance fingerprint and all provenance/service-event state are byte/count identical PRE→POST. The additive migration created an empty correction table; no real service/correction evidence was fabricated to demonstrate the feature.

## 4. Schema verification (production `sca_krayin`)
- Table `sca_service_event_corrections` present.
- **9 CHECK constraints:** `chk_svc_corr_disposition`, `chk_svc_corr_type`, `chk_svc_corr_grade`, `chk_svc_corr_correct_nonempty`, `chk_svc_corr_noncorrect_noflags`, and the four R2 sparse-consistency checks `chk_svc_corr_type_flag`, `chk_svc_corr_occurred_flag`, `chk_svc_corr_notes_flag`, `chk_svc_corr_grade_flag`.
- **3 triggers:** `trg_sca_service_corr_bi` (BEFORE INSERT cross-item identity), `trg_sca_service_corr_no_update` (BEFORE UPDATE), `trg_sca_service_corr_no_delete` (BEFORE DELETE).
- **Indexes:** `idx_svc_corr_event (service_event_id,id)`, `idx_svc_corr_item_event (eyewear_item_id,service_event_id,id)`, PRIMARY `(id)`.
- **FKs:** `service_event_id → sca_service_events`, `eyewear_item_id → sca_eyewear_items` (both RESTRICT).

## 5. Production-safe health / boundary smoke (no fabricated evidence)
- `GET /admin/login` → **200** (deploy health).
- `GET /admin/sca/eyewear/999999/service/999999/correct` (unauthenticated, loopback) → **302 → /admin/login** — route live and staff-auth-gated; no mutation.
- `POST …/correct` (unauthenticated, no CSRF) → **419** (CSRF fail-closed before any controller logic).
- `sca_service_event_corrections` row count after smoke: **0** (boundary probes created nothing).
- `php artisan route:list` shows GET+POST `admin/sca/eyewear/{id}/service/{eventId}/correct` (`admin.sca.eyewear.service.correct.confirm` / `.apply`).

## 6. Integration boundaries unchanged
- `kr-app` remains **loopback-only** `127.0.0.1:8080->80/tcp` (healthy); no public bind re-introduced.
- Edge untouched: `sr-caddy` not recreated by this deploy (Up 4 days); `/opt/smsrocket-stack/Caddyfile` unchanged (mtime 2026-10-09). **No Caddy/DNS change.**
- `SHOPIFY_SCOPES=read_orders` unchanged — **no Shopify OAuth scope change**.
- `MAIL_MAILER=log` unchanged; **Stripe remains dormant** (no Stripe keys configured). No SMTP change.
- `ServiceService::record()` and `ProjectionService::rebuild()` unchanged; zero ownership/current-state/authentication/certification/QR/status/claim/transfer/Shopify mutation (provenance FP identical).

## 7. Deployment steps executed (canonical gate)
`scripts/deploy-preview.sh` on merged `main@b4b51b7`: dev-deps install → full SCA test gate (passed) → `chown 33:33 storage bootstrap/cache` → `php artisan migrate --force` (137 applied) → memory-capped image rebuild (`--memory=1500m`) → `docker compose up -d` (loopback binding preserved; co-tenant/edge untouched) → `composer install --no-dev --optimize-autoloader` (production dependency state) → `config:clear` + `route:clear` → health check 200.

**STOP after deployment evidence. Initiative NOT declared closed; no new initiative started. Returned for ChatGPT independent post-deployment audit.**

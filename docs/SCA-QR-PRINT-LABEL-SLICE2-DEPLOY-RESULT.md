# SCA-QR-PRINT-LABEL — Slice 2 merge + governed deploy result

**Date:** 2026-10-06 · **Status: ✅ DONE — merged `--no-ff` + deployed. Post-deployment verification PASS.** Authorized after ChatGPT PASS/APPROVED of candidate `fdac4da` (gov evidence `b550bc2b`). No physical QR printed; Slice 3 not started.

## SHAs
- **Base / deployed-from:** `0ca71581cc5ec0981be37c11cebf555722519aad`
- **Audited candidate head:** `fdac4da799a13381f41db841edeb446e63994bd1` (unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `4d92ec94749e8f7f43288be5a22cef618ebc3994`** (`--no-ff` merge of `feat/sca-qr-labels-batch`)

## Pre-merge gates (fail-closed) — all PASS
candidate head `fdac4da` **unchanged** vs audited; `origin/main` == merge-base == `0ca7158` (approved baseline); 1 commit ahead; forbidden-path scan → NONE; tree clean on `main`.

## Deploy (`scripts/deploy-preview.sh`, deploys only `origin/main`)
`git reset --hard origin/main` → `4d92ec9`; mandatory SCA gate on `sca_domain_test` **826 passed / 4512 assertions** (incl. `QrLabelsBatchTest`, `QrPrintLabelTest`, `QrArtifactTest`, `QrReissueTest`, `PublicPassportTest`); `migrate --force` → **Nothing to migrate** (migrations **120**); memory-capped image rebuild + `docker compose up -d` (sca project only; co-tenant & 80/443 untouched); re-install `--no-dev --optimize-autoloader` (dev pruned); `config:clear` + `route:clear`; `kr-app`/`kr-mariadb` healthy; `GET /admin/login → 200`; `Deployed main @ 4d92ec9`.

## Post-deployment verification — all PASS
| Check | Expected | Result |
|---|---|---|
| deployed SHA == merge SHA | `4d92ec9` | `DEPLOYED_HEAD = 4d92ec94749e8f7f43288be5a22cef618ebc3994` |
| migrations | 120 | **120** (Nothing to migrate) |
| provenance fingerprint | `62b2e42f…` | **`DEPLOYED_FP = 62b2e42fe409b4ec91f3381b35da819e`** (unchanged) |
| batch route POST-only + admin/ACL | yes | `admin.sca.eyewear.qr.labels` → `POST admin/sca/eyewear/qr/labels`; non-staff **403** |
| non-staff cannot access batch printing | 403 | POST `/admin/.../qr/labels` non-staff → **403** (edge `@admin` + `sca.eyewear.view`) |
| eyewear list eligible-only batch selection | yes | index renders checkboxes only when `cs_qr` present; deploy-gate `QrLabelsBatchTest` bl3/bl5 (eligible-only / skip) PASS on merged code |
| single-label printing still works | yes | `qrLabel` route intact (403 non-staff); `QrPrintLabelTest` PASS in gate |
| existing SVG download still works | yes | `qr` route intact (403 non-staff); `QrArtifactTest` PASS in gate |
| batch output uses the same QR renderer | yes | gate `QrLabelsBatchTest` bl2 (batch SVG == `/qr` download bytes) PASS on merged SHA |
| mixed / all-ineligible behavior correct | yes | gate bl3 (mixed → eligible + omit count) + bl4 (all-ineligible → 200 sheet, 0 labels, no redirect/404) PASS |
| public passport valid/bogus | 200 / 404 | `/p/{active item-1}` → **200**; `/p/{bogus-32}` → **404** (SCA-038 intact) |
| `/collector` healthy | 302 | **302** |
| Shopify webhook fail-closed | 401 | POST no-HMAC → **401** |
| `/storage` blocked | 404 | `/storage/*` → **404** |
| smsrocket co-tenant healthy | 302 | **302**; sr-caddy owns 80/443 (untouched) |
| no unexpected DB/provenance mutation | none | `DEPLOYED_FP` unchanged `62b2e42f`; migrations 120; phpunit pruned (prod `--no-dev`) |

## Scope delivered (unchanged from the audited candidate)
Current-page multi-select on the eyewear list (eligible-only checkboxes via HTML5 `form=`; no nested forms; works without JS) → `POST admin/sca/eyewear/qr/labels` (ACL `sca.eyewear.view`, admin-only, CSRF) → `qrLabelsBatch` loops the single shared `renderActiveQrSvg` (no second encoder; cap `MAX_BATCH_LABELS = 50`) → batch sheet of Slice-1 labels (shared `_qr-label-card` partial; ~30 mm QR, quiet zone, A4/Letter 4-col grid, `break-inside: avoid`). Mixed → omit count; all-ineligible → zero-label sheet; empty/>50 → validation redirect; unknown ids omitted without data leak. Read-only; no schema/migration/`is_production`/reissue/passport/Shopify/SMTP/Caddy/Docker change; no new public route.

## NOT done
No physical QR printed. **Slice 3 not started.** No PDF export, label presets, Zebra/Dymo, cross-page selection, `is_production` semantics, or any other change.

**Outcome: SCA-QR-PRINT-LABEL Slice 2 is DONE (merged `--no-ff` + deployed, `4d92ec9`); production verified byte-identical except the additive staff batch route.** See [[sca-production-qr-label-workflow-discovery]], `docs/SCA-QR-PRINT-LABEL-SLICE2-IMPLEMENTATION.md`.

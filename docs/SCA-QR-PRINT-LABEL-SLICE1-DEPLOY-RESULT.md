# SCA-QR-PRINT-LABEL — Slice 1 merge + governed deploy result

**Date:** 2026-10-06 · **Status: ✅ DONE — merged `--no-ff` + deployed. Post-deployment verification PASS. No physical QR printed; no further scope.** Authorized after ChatGPT PASS/APPROVED of candidate `f439afb` (gov evidence `e98b83c`).

## SHAs
- **Base / deployed-from:** `98ae6542294e42f3fd7dc86fbda5dc69a32e6d71`
- **Reviewed candidate (feature HEAD):** `f439afb15c721265984cbea2662590ece422387c` (audited; unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `0ca71581cc5ec0981be37c11cebf555722519aad`** (`--no-ff` merge of `feat/sca-qr-print-label`)

## Pre-merge gates (fail-closed) — all PASS
- candidate head `f439afb` **unchanged** vs the audited SHA (no re-audit needed);
- `origin/main` == merge-base == `98ae654` (cleanly based on the audited base);
- 1 commit ahead; 5-file scope (2 new + 3 modified), all `packages/Sca/Registry` + tests;
- forbidden-path scan (`migration|vendor|Webkul|composer.(json|lock)|docker|caddy|.env`) → **NONE**;
- working tree clean, on `main` @ deployed HEAD before merge.

## Deploy (`scripts/deploy-preview.sh`, deploys only `origin/main`)
- `git reset --hard origin/main` → `0ca7158`; refuses non-main.
- Installed WITH dev deps → **mandatory SCA test gate on `sca_domain_test`: 814 passed / 4458 assertions** (incl. `QrPrintLabelTest`, `QrArtifactTest`, `QrReissueTest`, `PublicPassportTest`).
- `php artisan migrate --force` → **Nothing to migrate** (schema unchanged, migrations **120**).
- Memory-capped image rebuild (`--memory=1500m`) + `docker compose up -d` (sca project only; co-tenant & 80/443 untouched).
- Re-installed `--no-dev --optimize-autoloader` (dev packages pruned: debugbar/ignition/faker/pest/paratest/mockery/pint/sail removed); `config:clear` + `route:clear`.
- Health: `kr-app Up (healthy)`, `kr-mariadb Up (healthy)`, `GET /admin/login → 200`. `Deployed main @ 0ca7158`.

## Post-deployment verification — all PASS
| Check | Expected | Result |
|---|---|---|
| production running merged implementation | `0ca7158` | `DEPLOYED_HEAD = 0ca71581cc5ec0981be37c11cebf555722519aad` (merge commit) |
| migrations | 120 | **120** (Nothing to migrate) |
| provenance fingerprint | `62b2e42f…` | **`DEPLOYED_FP = 62b2e42fe409b4ec91f3381b35da819e`** (unchanged) |
| staff QR-label route exists + admin/ACL protected | yes | route `admin.sca.eyewear.qr.label` → `admin/sca/eyewear/{id}/qr/label` registered; non-staff IP → **403** (edge `@admin` + `sca.eyewear.view` ACL) |
| existing SVG download still works | yes | route `admin.sca.eyewear.qr` intact; non-staff → 403; functionally green on deployed code (`QrArtifactTest` rg1/rg2 PASS in the deploy gate) |
| print view renders the same active QR | yes | deploy-gate `QrPrintLabelTest` ql2 (download bytes embedded verbatim, single `<svg>`) + ql3 (decodes to the canonical active-token URL) PASS against the merged SHA |
| public passport operational | 200 / 404 | `/p/{active item-1 token}` → **200**; `/p/{bogus-32}` → **404** (SCA-038 constant-shape intact) |
| `/collector` healthy | 302 | **302** |
| Shopify webhook fail-closed | 401 | `POST /sca/shopify/webhook` no-HMAC → **401** |
| smsrocket co-tenant healthy | 302 | **302**; sr-caddy owns 80/443 (untouched) |
| no unexpected production mutation | none | FP unchanged `62b2e42f`; migrations 120; `/storage/*` → 404; phpunit pruned (prod `--no-dev`) |

## Scope delivered (unchanged from the audited candidate)
Staff-only, read-only in-app **Print QR label** view beside the SVG download, via a single shared renderer (`EyewearItemController::renderActiveQrSvg`, no second encoder); route `GET {id}/qr/label` (ACL `sca.eyewear.view`); standalone print page (inline QR + `public_ref` + "Scan to verify authenticity" + SCA branding outside the QR + `window.print()`; `@media print` ~30 mm QR, quiet zone preserved; raw token never shown as text); "Print QR label" link on the item page. No schema/migration, no new public route, no `is_production`/reissue/resolver/Shopify/SMTP change.

## NOT done (unchanged scope)
No physical QR printed/attached. No Slice 2 (batch), PDF export, label presets, `is_production` activation, or any other task. Integration otherwise unchanged; Shopify (Phases 0–5, closed) untouched.

**Outcome: SCA-QR-PRINT-LABEL Slice 1 is DONE (merged `--no-ff` + deployed, `0ca7158`); production verified byte-identical except the additive staff route.** See [[sca-production-qr-label-workflow-discovery]], `docs/SCA-QR-PRINT-LABEL-SLICE1-IMPLEMENTATION.md`.

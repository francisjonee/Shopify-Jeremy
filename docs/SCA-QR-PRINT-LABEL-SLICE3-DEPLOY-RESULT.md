# SCA-QR-PRINT-LABEL — Slice 3 merge + governed deploy result — **WORKFLOW CLOSED**

**Date:** 2026-10-06 · **Status: ✅ DONE — merged `--no-ff` + deployed. Post-deployment verification PASS.** Authorized after ChatGPT PASS/APPROVED of candidate `5eccc6a` (gov evidence `9669c534`). Final software slice.

## SHAs
- **Base / deployed-from:** `4d92ec94749e8f7f43288be5a22cef618ebc3994`
- **Audited candidate head:** `5eccc6acea92dea662e4c4c18cabc5444f83d60d` (unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `30b680f797bdcf0d9bf2e6031c32c4f80c41dfc4`** (`--no-ff` merge of `feat/sca-qr-print-polish`)

## Pre-merge gates (fail-closed) — all PASS
candidate head `5eccc6a` **unchanged** vs audited; `origin/main` == merge-base == `4d92ec9` (approved baseline); 1 commit ahead; forbidden-path scan (controller/route/config/model/service/migration/vendor/docker/caddy/.env) → NONE (views + tests only); tree clean on `main`.

## Deploy (`scripts/deploy-preview.sh`, deploys only `origin/main`)
`git reset --hard origin/main` → `30b680f`; mandatory SCA gate on `sca_domain_test` **830 passed / 4512→4530 assertions** (incl. `QrPrintLabelTest` ql1–ql10, `QrLabelsBatchTest` bl1–bl14, `QrArtifactTest`, `QrReissueTest`, `PublicPassportTest`); `migrate --force` → **Nothing to migrate** (migrations **120**); memory-capped image rebuild + `docker compose up -d` (sca project only; co-tenant & 80/443 untouched); re-install `--no-dev --optimize-autoloader` (dev pruned); `config:clear` + `route:clear`; `kr-app`/`kr-mariadb` healthy; `GET /admin/login → 200`; `Deployed main @ 30b680f`.

## Post-deployment verification — all PASS
| Check | Expected | Result |
|---|---|---|
| deployed SHA == merge SHA | `30b680f` | `DEPLOYED_HEAD = 30b680f797bdcf0d9bf2e6031c32c4f80c41dfc4` |
| migrations | 120 | **120** (Nothing to migrate) |
| provenance fingerprint | `62b2e42f…` | **`DEPLOYED_FP = 62b2e42fe409b4ec91f3381b35da819e`** (unchanged) |
| list shows "Select all eligible on this page" (authorized) | yes | present in deployed `index.blade.php`; `QrLabelsBatchTest::bl12` PASS in the merged-code gate |
| select-all operates only on current-page QR-eligible boxes | yes | JS toggles only `.sca-batch-cb` (rendered only for `cs_qr` items, current page); `bl12`/`bl13` PASS |
| individual checkbox changes sync select-all state/count | yes | JS `sync()` recomputes count + select-all `checked`/`indeterminate` on every box `change` (progressive enhancement) |
| batch Print button behavior intact | yes | count + enabled/disabled logic unchanged; `QrLabelsBatchTest` bl1–bl8 PASS |
| single-label print page improved instructions | yes | deployed `qr-print-label.blade.php` has "Fit to page: Off"; `QrPrintLabelTest::ql10` PASS |
| batch print page improved instructions | yes | deployed `qr-print-labels.blade.php` has "Fit to page: Off"; `QrLabelsBatchTest::bl14` PASS |
| single QR label printing operational | yes | `qrLabel` route intact (403 non-staff); `QrPrintLabelTest` PASS in gate |
| batch QR printing operational | yes | `qrLabelsBatch` route intact (403 non-staff); `QrLabelsBatchTest` PASS in gate |
| SVG QR download operational | yes | `qr` route intact (403 non-staff); `QrArtifactTest` PASS in gate |
| raw QR token not human-readable on labels | yes | `QrPrintLabelTest::ql8`/`ql10` + `QrLabelsBatchTest` assert token absent from body |
| public passport valid/bogus | 200 / 404 | `/p/{active item-1}` → **200**; `/p/{bogus-32}` → **404** |
| `/collector` healthy | 302 | **302** |
| Shopify webhook fail-closed | 401 | POST no-HMAC → **401** |
| `/storage` blocked | 404 | **404** |
| smsrocket co-tenant healthy | 302 | **302**; sr-caddy owns 80/443 (untouched) |
| no unexpected DB/provenance mutation | none | `DEPLOYED_FP` unchanged `62b2e42f`; migrations 120; phpunit pruned |

## Regression totals (merged/deployed code)
**830 passed / 4530 assertions, exit 0** (826 prior + 4 new: `ql10`, `bl12`, `bl13`, `bl14`).

---

## SCA Production QR/Label Workflow — CLOSED

**Completed software capability:** `certify → permanent QR → single / batch label printing → physical scan → public Digital Passport`.

Delivered across the workflow:
- **Slice 1** (`0ca7158`): in-app single Print QR label view beside the SVG download — shared `renderActiveQrSvg` renderer; staff-only; ~30 mm QR, quiet zone preserved; constant-404 fail-safe.
- **Slice 2** (`4d92ec9`): batch/sheet printing — current-page eligible-only multi-select → POST → A4/Letter grid of labels via the same renderer; 50-cap; read-only; mixed/all-ineligible handling.
- **Slice 3** (`30b680f`): production print polish — "Select all eligible on this page" (progressive enhancement) + clear non-technical print-dialog instructions.

Throughout: QR identity/token semantics, reissue, public passport/resolver, provenance, `is_production`, Shopify, SMTP, schema/migrations, Caddy/Docker — **unchanged**. One shared QR encoder; no public batch/label endpoint; all QR routes admin-prefixed + `sca.eyewear.view`.

**Optional future enhancements (NOT unfinished QR/Label work):** PDF export, label/card size presets, cross-page / select-all-matching-filter selection, compact-sticker variants, and printer-specific (Zebra/Dymo) integrations. Each would be a separately-justified future task only if a concrete business need arises. The physical printing + attachment itself remains an operational/human step.

**Outcome: SCA-QR-PRINT-LABEL Slice 3 DONE (merged `--no-ff` + deployed, `30b680f`); production verified byte-identical except the additive view/JS polish. The Production QR/Label Workflow is CLOSED.** See [[sca-production-qr-label-workflow-discovery]], `docs/SCA-QR-PRINT-LABEL-SLICE3-IMPLEMENTATION.md`.

# SCA-QR-PRINT-LABEL — Slice 2 (batch/sheet printing) implementation (candidate; NOT merged/deployed)

**Date:** 2026-10-06 · **Status: IMPLEMENTED + TESTED + PUSHED on a candidate branch. NOT merged, NOT deployed. Live tree restored to `main`; production byte-identical.** For ChatGPT pre-merge audit.

Implements the approved Slice 2 plan (gov `d5bb343`): current-page multi-select on the eyewear list → POST selected ids → staff-only batch print sheet, one Slice-1-style label per eligible item, reusing the single shared renderer. No schema/migration, no second encoder, no new public route, no `is_production`/reissue/resolver/passport/Shopify/SMTP/Caddy/Docker change.

## Candidate identity
- **Branch:** `origin/feat/sca-qr-labels-batch` (impl repo `francisjonee-sca-platform-private`)
- **Base SHA:** `0ca71581cc5ec0981be37c11cebf555722519aad` (= deployed `main`; merge-base; clean 1-commit, fast-forwardable)
- **Head SHA:** `fdac4da799a13381f41db841edeb446e63994bd1`

## Changed-file scope (3 new + 4 modified; NO schema/migration, Krayin core/vendor, composer/.env/Docker/Caddy)
New:
- `packages/Sca/Registry/src/Resources/views/eyewear/_qr-label-card.blade.php` — shared label-card presentation (QR + `public_ref` + "Scan to verify authenticity" + "Second Chance Authenticators" outside the QR); `@once` CSS; `.qr` fixed ~30 mm; `break-inside/page-break-inside: avoid`.
- `packages/Sca/Registry/src/Resources/views/eyewear/qr-print-labels.blade.php` — standalone batch sheet; A4/Letter CSS grid (4 columns @ 44 mm), `@media print` page margins, Print button, non-printing omitted-count notice, empty-state.
- `tests/Feature/Sca/QrLabelsBatchTest.php` — 12 regression tests.

Modified:
- `packages/Sca/Registry/src/Http/Controllers/EyewearItemController.php` — add `qrLabelsBatch()` + `private const MAX_BATCH_LABELS = 50`; reuses the existing private `renderActiveQrSvg()` (one encoder).
- `packages/Sca/Registry/src/Routes/admin-routes.php` — add `POST qr/labels` → `qrLabelsBatch`, name `admin.sca.eyewear.qr.labels`, ACL `sca.can:sca.eyewear.view`.
- `packages/Sca/Registry/src/Resources/views/eyewear/index.blade.php` — sibling batch `<form id="sca-batch-print">` (CSRF, `target=_blank`) + eligible-only (`$item->cs_qr`) checkboxes associated via the HTML5 `form=` attribute (no nested forms; works without JS) + optional count JS (progressive enhancement).
- `packages/Sca/Registry/src/Resources/views/eyewear/qr-print-label.blade.php` — Slice-1 single view refactored to `@include` the shared `_qr-label-card` partial (single + batch presentation now cannot diverge).

`git diff --name-only 0ca7158..fdac4da` matches none of `migration|vendor|Webkul|composer.(json|lock)|docker|caddy|.env`.

## Behavior (matches approved plan + requirements)
- **Staff workflow:** eyewear list shows a "Print QR labels" form; a checkbox appears **only** on cards with an active QR (`cs_qr`); staff tick items on the **current page**, submit → the batch sheet opens in a new tab.
- **QR invariant:** `qrLabelsBatch` renders every label through the **same** `renderActiveQrSvg()` used by `qr()`/`qrLabel()` — no second encoder/library/path. Test `bl2` asserts each batch label's SVG bytes are identical to that item's `/qr` download.
- **Presentation reuse:** both single (`qr-print-label`) and batch (`qr-print-labels`) views render the **shared `_qr-label-card` partial**; QR fixed ~30 mm with the baked quiet zone preserved; labels never split across pages (`break-inside: avoid`); A4/Letter 4-column grid.
- **Eligibility:** mixed selection → eligible labels printed + a non-printing "N of M omitted" notice; **all-ineligible → sheet (200) with zero labels + omitted notice (no redirect, no 404)**; unknown ids → omitted by the same null path (the submitted id is not echoed → no data revealed); empty → validation redirect back to the list with feedback.
- **Limits/security:** server cap `MAX_BATCH_LABELS = 50` (>50 → validation redirect, nothing rendered); **POST-only + CSRF**; ACL `sca.eyewear.view`; **admin route only, not public**; read-only (no writes anywhere).
- **No nested forms / no-JS:** the batch form is a sibling of the filter/lookup forms; checkboxes bind via `form=`. Select + submit works with JavaScript disabled; the count/disable JS is optional enhancement.

## Tests — new Slice 2 (`QrLabelsBatchTest`, 12/12)
`sca_domain_test` hard-guarded, `DatabaseTransactions`. bl1 batch renders one label each; bl2 each label SVG == that item's `/qr` download bytes (one renderer); bl3 mixed → eligible printed + "1 of 3" omitted + zero mutation; bl4 all-ineligible → 200 sheet, 0 labels, "No labels to print" (not redirect/404); bl5 unknown id omitted, id not echoed; bl6 empty → validation redirect + `assertSessionHasErrors('ids')`; bl7 >50 → redirect + errors + zero mutation; bl8 happy-path zero QR/provenance mutation + `is_production` untouched; bl9/bl9b ACL (guest redirect / no-view 403); bl10 route POST-only + GET rejected; bl11 no new public route (admin-prefixed; `/p/{token}` unchanged).

## Regression — full governed SCA gate
`docker compose exec -T -u 33:33 -e DB_DATABASE=sca_domain_test app php artisan test tests/Feature/Sca` → **826 passed / 4512 assertions**, exit 0 (814 prior + 12 new; Slice-1 `QrPrintLabelTest` still green after the partial refactor; `QrArtifactTest`, `QrReissueTest`, `PublicPassportTest` green). Duration 177 s.

## Production-safety verification (post-restore)
`kr-app` bind-mounts the live tree; the change touches only the Registry admin surface. After push, the tree was **restored to `main`** and vendor **re-pruned `--no-dev`**. Verified: tree `main` @ `0ca7158`; `PROD_FP = 62b2e42fe409b4ec91f3381b35da819e` (unchanged); migrations **120**; `qr/labels` route **absent** on main (0); phpunit pruned; `/collector` 302, smsrocket.io 302, Shopify webhook POST → **401** fail-closed. No merge, no deploy, no DB/schema/scope/config/Caddy change.

## NOT done (unchanged scope)
No merge, no deploy. No cross-page selection, PDF export, label presets, Zebra/Dymo integration, `is_production` semantics, QR reissue change, schema/migrations, passport/resolver/Shopify/SMTP/Caddy/Docker change, or unrelated cleanup.

**Outcome:** Slice 2 implemented + green on a candidate branch, production untouched. STOP for ChatGPT audit. See [[sca-production-qr-label-workflow-discovery]], `docs/SCA-QR-PRINT-LABEL-SLICE2-BATCH-PLAN.md`.

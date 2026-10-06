# SCA-QR-PRINT-LABEL — Slice 3 (production print UX polish) implementation (candidate; NOT merged/deployed)

**Date:** 2026-10-06 · **Status: IMPLEMENTED + TESTED + PUSHED on a candidate branch. NOT merged, NOT deployed. Live tree restored to `main`; production byte-identical.** For ChatGPT pre-merge audit. **Intended FINAL software slice of the Production QR/Label Workflow.**

Implements the approved Slice 3 plan (Option A, gov `e4754d8`): a "select all eligible on this page" batch convenience + clearer print-dialog instructions. View-only (3 Blade views) + tests; no controller/route/ACL/renderer/schema change.

## Candidate identity
- **Branch:** `origin/feat/sca-qr-print-polish`
- **Base SHA:** `4d92ec94749e8f7f43288be5a22cef618ebc3994` (= deployed `main`; merge-base; clean 1-commit, fast-forwardable)
- **Head SHA:** `5eccc6acea92dea662e4c4c18cabc5444f83d60d`

## Changed-file scope (0 new views + 3 modified views + 2 modified tests; NO controller/route/ACL/renderer/schema)
- `packages/Sca/Registry/src/Resources/views/eyewear/index.blade.php` — add the "Select all eligible on this page" control to the batch toolbar; extend the existing optional JS to toggle all `.sca-batch-cb`, keep the count + Print enabled/disabled, and sync the select-all checked/indeterminate state.
- `packages/Sca/Registry/src/Resources/views/eyewear/qr-print-label.blade.php` — clearer print-dialog instructions.
- `packages/Sca/Registry/src/Resources/views/eyewear/qr-print-labels.blade.php` — clearer print-dialog instructions.
- `tests/Feature/Sca/QrPrintLabelTest.php` — +`ql10`.
- `tests/Feature/Sca/QrLabelsBatchTest.php` — +`bl12`, `bl13`, `bl14`.

`git diff --stat 4d92ec9..5eccc6a` = 5 files, 90 insertions(+), 4 deletions(-). Matches none of `migration|vendor|Webkul|composer.(json|lock)|docker|caddy|.env|Controller|Routes/|Config/|Models/|Services/`.

## Behavior (exactly the two approved changes)
1. **Select all eligible on this page** — a labelled checkbox (`id="sca-select-all"`, no `name` → never submitted) in the batch toolbar. The JS:
   - operates **only** on the `.sca-batch-cb` checkboxes rendered on the current page (all QR-eligible) — current page only, no cross-page state;
   - checking it checks all eligible boxes; clearing it unchecks all;
   - changing an individual box re-syncs the select-all state (checked when all selected, `indeterminate` when some);
   - the existing live selected-count and Print enabled/disabled behavior are preserved;
   - **progressive enhancement only** — with JavaScript disabled the select-all does nothing while the manual checkboxes + `form=` association + submit continue to work.
2. **Print-dialog instructions** on both print pages: "In your browser's print dialog set **Scale: 100%** · **Fit to page: Off** · **Paper: A4 or Letter** · **Margins: Default**. Black & white recommended, on matte paper. At 100% the QR prints ~30 mm square with its quiet zone preserved; if the browser is left to shrink-to-fit, the QR may be too small to scan reliably." (Does not imply CSS can enforce print settings; preserves the matte/black-on-white recommendation.)

Nothing else changed: the shared `renderActiveQrSvg` renderer, the `_qr-label-card` partial markup, the batch controller/route/ACL, QR identity/reissue, passport/resolver, provenance, `is_production`, Shopify, SMTP, Caddy, Docker — all untouched. No new route. **Explicitly NOT implemented** (per instruction): human-readable verify-domain line, PDF export, presets, compact sticker, cross-page selection, select-all-matching-filter, Zebra/Dymo, logo-in-QR, `is_production`.

## Tests
New/added (all green): `QrPrintLabelTest::ql10` (single view shows the print-dialog instructions; raw token still absent); `QrLabelsBatchTest::bl12` (authorized list exposes the select-all control + `sca-batch-print` form), `bl13` (staff with `sca.eyewear` but not `sca.eyewear.view` loads the list but gets **no** batch-print controls), `bl14` (batch sheet shows the print-dialog instructions). Focused QR run: **27 passed** (ql1–ql10 + bl1–bl14).
Full governed gate: `… -e DB_DATABASE=sca_domain_test … php artisan test tests/Feature/Sca` → **830 passed / 4530 assertions**, exit 0 (826 prior + 4 new; Slice 1 `QrPrintLabelTest`, Slice 2 `QrLabelsBatchTest`, `QrArtifactTest`, `QrReissueTest`, `PublicPassportTest` all green — the shared renderer/partial and existing selection path intact). Duration 184 s.

## Production-safety verification (post-restore)
`kr-app` bind-mounts the live tree; the change is view/JS-only on the Registry admin surface. After push, the tree was **restored to `main`** and vendor **re-pruned `--no-dev`**. Verified: tree `main` @ `4d92ec9`; `PROD_FP = 62b2e42fe409b4ec91f3381b35da819e` (unchanged); migrations **120**; `sca-select-all` **absent** from the main index source (0); phpunit pruned; `/collector` 302, smsrocket.io 302, Shopify webhook POST → **401** fail-closed. No merge, no deploy, no DB/schema/scope/config/Caddy change.

## Workflow closure note
This is the intended **final** software slice. If it passes audit and deployment verification, the deploy evidence will state the **SCA Production QR/Label Workflow is CLOSED**, with PDF/presets/cross-page/printer integrations remaining **optional future work only**.

**Outcome:** Slice 3 implemented + green on a candidate branch, production untouched. STOP for ChatGPT audit. See [[sca-production-qr-label-workflow-discovery]], `docs/SCA-QR-PRINT-LABEL-SLICE3-DISCOVERY.md`.

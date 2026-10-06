# SCA-QR-PRINT-LABEL — Slice 1 implementation (candidate; NOT merged/deployed)

**Date:** 2026-10-06 · **Status: IMPLEMENTED + TESTED + PUSHED on a candidate branch. NOT merged, NOT deployed. Live tree restored to `main`; production byte-identical.** For ChatGPT pre-merge audit.

Implements the approved Slice 1 (in-app Print QR Label view) from `docs/SCA-PRODUCTION-QR-LABEL-WORKFLOW-DISCOVERY.md` (gov `2300f199`). Smallest production-safe version: a staff-only, read-only print view beside the existing SVG download, reusing the existing active QR identity and the existing QR renderer via a single shared method (no second encoder). No schema/migration, no public route, no `is_production`/reissue/resolver/Shopify/SMTP change.

## Candidate identity
- **Branch:** `origin/feat/sca-qr-print-label` (impl repo `francisjonee-sca-platform-private`)
- **Head SHA:** `f439afb15c721265984cbea2662590ece422387c`
- **Base / merge-base:** `98ae6542294e42f3fd7dc86fbda5dc69a32e6d71` (= deployed `main`; clean 1-commit, fast-forwardable)

## Exact file scope (2 new + 3 modified; NO schema/migration, NO Krayin core/vendor, NO composer/.env/Docker/Caddy)
New:
- `packages/Sca/Registry/src/Resources/views/eyewear/qr-print-label.blade.php` — standalone print page.
- `tests/Feature/Sca/QrPrintLabelTest.php` — 11 regression tests.

Modified:
- `packages/Sca/Registry/src/Http/Controllers/EyewearItemController.php` — extracted shared `renderActiveQrSvg()` used by BOTH `qr()` (download) and new `qrLabel()` (print view); `qr()` refactored to call it; `qrLabel()` added.
- `packages/Sca/Registry/src/Routes/admin-routes.php` — `GET {id}/qr/label` → `qrLabel`, name `admin.sca.eyewear.qr.label`, `where id [0-9]+`, ACL `sca.can:sca.eyewear.view`.
- `packages/Sca/Registry/src/Resources/views/eyewear/show.blade.php` — "Print QR label" link beside "Download printable QR (SVG)".

`git diff --stat 98ae654..f439afb` = 3 files changed, 64 insertions(+), 14 deletions(-) (controller), + 2 new files. No path matching `migration|vendor|Webkul|composer.(json|lock)|docker|caddy|.env`.

## Behavior (matches approved plan + requirements)
- **Single renderer / no divergence:** `renderActiveQrSvg(int $id): ?array` is the one QR encoder. It reads the item's current `active_qr_identifier_id` from the projection (exactly what the SCA-038 resolver accepts, so a revoked/inactive/absent QR can never be printed), encodes `config('app.url') + /p/{token}` as a self-contained chillerlan SVG (ECC-H, quietzone 4, explicit fills), and returns `{svg, public_ref}` or null. Both `qr()` and `qrLabel()` call it; `qr()` wraps the SVG as the attachment download, `qrLabel()` embeds the identical SVG in the print view. No second QR library/path introduced.
- **Print view** (`qr-print-label.blade.php`): standalone minimal HTML (not the admin layout, for clean printing). Contains the inline QR SVG, the human-readable `public_ref`, the caption "Scan to verify authenticity", minimal SCA branding ("Second Chance Authenticators") placed OUTSIDE the QR, and a Print button (`window.print()`). `@media print` hides the toolbar/hint and sizes the QR to ~30 mm square (`.qr { width:30mm; height:30mm }`); the 4-module quiet zone is baked into the SVG viewBox so scaling preserves it. The raw token is never printed as text (it lives only in the QR modules); `public_token` column name absent from the body.
- **Reprint = pure read, same identity:** the view performs no writes; reprinting re-reads the same active token. (Reissue remains the only new-identity path, unchanged.)
- **Fail-safe:** missing item / no active QR → the same constant 404 (`qrNotFound()`) as the download; creates nothing.
- **ACL:** `sca.eyewear.view` (same as the download); admin-prefixed + auth. Not a public route.

## Tests — new Slice 1 (`QrPrintLabelTest`, 11/11)
`sca_domain_test` hard-guarded, `DatabaseTransactions` rollback per test. Covers every required dimension:
- **authorization/ACL:** `ql6` guest → redirect to admin login; `ql7` staff without `sca.eyewear.view` → 403.
- **certified item w/ active QR opens print view:** `ql1` 200.
- **correct public_ref appears:** `ql1` `assertSee(public_ref)` + caption + Print button.
- **correct active QR rendered:** `ql3` the printed SVG decodes (independent rasterize) to exactly `https://verify.secondchanceauthenticators.com/p/{active-token}`; `ql3b` after a reissue the print shows ONLY the new active token (old token absent).
- **print & download share one source:** `ql2` the download's exact SVG bytes are embedded verbatim in the print page; exactly one `<svg>` (no divergent encoder).
- **no DB/provenance mutation:** `ql4` QR identity/lifecycle/projection fingerprint + all domain counts unchanged by the GET; `is_production` untouched.
- **missing/ineligible fails safely:** `ql5` uncertified item → 404 (no identity created); `ql5b` unknown id → 404.
- **raw token not visible:** `ql8` token string + `public_token` absent from the body.
- **no new public route:** `ql9` `admin.sca.eyewear.qr.label` is admin-prefixed; every `qr/label` route is admin-prefixed; `sca.passport.show` still maps exactly to `p/{token}`.

## Regression — full governed SCA gate
`docker compose exec -T -u 33:33 -e DB_DATABASE=sca_domain_test app php artisan test tests/Feature/Sca` (incl. existing `QrArtifactTest` rg1–rg10, `QrReissueTest`, `PublicPassportTest`, trusted-proxy/zero-mutation suites):
- **814 passed / 4458 assertions**, exit 0 (803 prior + 11 new). Duration 156s.

## Production safety during implementation (bind-mount discipline)
`kr-app` bind-mounts `/opt/sca-platform/app → /var/www/html` (live). The change touches only the Registry **admin** surface (staff-IP `/admin`); the public passport/collector packages were not modified. After committing/pushing the branch, the live tree was **restored to `main`** and vendor **re-pruned to `--no-dev`**. Verified post-restore: tree on `main` @ `98ae654`; `PROD_FP = 62b2e42fe409b4ec91f3381b35da819e` (unchanged); migrations 120; `qr/label` route **absent** on main (0); phpunit pruned; `/collector` 302, smsrocket.io 302, Shopify webhook POST → 401 fail-closed. No merge, no deploy, no DB/schema/scope/config/Caddy change.

## NOT done (unchanged scope)
No merge, no deploy. No batch printing, PDF export, label presets, QR reissue change, `is_production` semantics, schema/migrations, public passport changes, Shopify changes, SMTP, or unrelated cleanup. Physical printing is a later human action.

**Outcome:** Slice 1 implemented + green on a candidate branch, production untouched. STOP for ChatGPT audit. See [[sca-production-qr-label-workflow-discovery]].

# SCA Admin Registry Grid — image sizing + card spacing refinement (VIEW/CSS only) — PUSH ONLY

**Date:** 2026-10-01 · **Base:** deployed main `974cbfc` (migrations 120). **Candidate HEAD:** `20efdd3`
on branch `sca-grid-image-spacing`. **Status:** PUSH ONLY — not merged, not deployed. Awaiting independent
pre-merge review. Readiness GO: gov `ffc8223`.

## Scope / commit
Presentation only. 1 commit; 2 files — `Registry/.../eyewear/index.blade.php` (the scoped `@push('styles')`
block, 2 CSS values) + `tests/Feature/Sca/CatalogGridTest.php` (rg8 assertions). Exactly the two approved
edits:
```
.sca-registry .sca-canvas:  padding: 12px -> 6px   (image fills more of the fixed 180px canvas)
.sca-registry .sca-body:    gap: 5px -> 8px         (more even info-section spacing)
```
`.sca-pills` margin left unchanged (per scope). `height: 180px` + `object-fit: contain` unchanged, so equal
canvases and no crop/distortion are preserved. No markup, no behavior change.

## Preserved (unchanged)
Card dimensions, responsive `grid-cols-1/2/3/4`, pills, "No image" placeholder, View-item positioning,
grouped QR-lookup + filter/search/sort toolbar, pagination, the authorized Admin image route (gallery
primary, never `/storage`), and all functionality. No controller/service/route/ACL/gallery/schema/migration/
Collector/Passport/provenance/infra change; no gallery data touched.

## Tests (CatalogGridTest 10; full tests/Feature/Sca 722/3969; php -l clean)
rg8 now additionally asserts `.sca-registry .sca-canvas { … padding: 6px }` and
`.sca-registry .sca-body { … gap: 8px }`, with the existing `height: 180px` + `object-fit: contain`
assertions retained. rg1-rg7, rg9, rg10 unchanged and green.

## Push-only + restoration evidence (production remains on 974cbfc)
Candidate pushed to `origin/sca-grid-image-spacing` (HEAD `20efdd3`, base `974cbfc`). Pilot restored to main
`974cbfc` (working tree reverted; `--no-dev`; caches cleared; kr-app healthy on `195.26.255.80:8080`). No
candidate value live: live index still has `height: 180px; padding: 12px` (candidate `padding: 6px` = 0
occurrences). Prod migrations **120**; FP_QR `a920dc1c…`; is_production 0,0; item 3 still has its **3
operator gallery images, untouched**; verify. passport 200; smsrocket 302.

## GO → DONE — MERGED --no-ff + DEPLOYED 2026-10-01

`MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = f4c84e6bbc21bfaebe4337eee50c3e023b314b38` (reviewed HEAD
`20efdd3`, base `974cbfc`, 1 commit). Pre-merge gates passed (origin/main `974cbfc`, feature `20efdd3`,
merge-base `974cbfc`, clean tree, exactly the 2 approved files).

**Deploy (`deploy-preview.sh`, exit 0):** full tests/Feature/Sca gate passed; **Nothing to migrate —
migrations remain 120**; recreate; `--no-dev`; `Deployed main @ f4c84e6`. Pilot bind `195.26.255.80:8080`
re-applied; sca_edge attached.

**Post-deploy verification (all PASS):** DEPLOYED_HEAD == ORIGIN_MAIN == MERGE_SHA `f4c84e6`. Live
`/admin/sca/eyewear`: `.sca-canvas { height: 180px; padding: 6px }` ✓, `.sca-body { gap: 8px }` ✓,
`.sca-canvas img { object-fit: contain }` intact ✓, `.sca-pills { margin-top: 6px }` unchanged ✓; 2 equal
`.sca-canvas` (item 3 featured via `/admin/sca/eyewear/3/image`; item 1 the equal-size `.sca-noimg`
placeholder); responsive grid-cols-1/2/3/4 + QR lookup + search/filters/date/sort + View item intact; no
`/storage` leak. `/storage` denied 404; SCA-038 200/404/404; Collector gallery + Passport unchanged
(verify. item-3 image 200). **Item 3's 3 operator gallery images untouched** (3 rows; no gallery data
modified during verification). Migrations 120; FP_QR `a920dc1c…`, FP_CERT `22fb9f55…`, FP_AUTH `3bd0f029…`,
FP_OWN `831ae932…` unchanged; is_production 0,0; :8080 200; smsrocket 302; Caddyfile `0faece7a`; sca_edge +
MariaDB-private intact.

**COMPLETE. STOP — no further task.**

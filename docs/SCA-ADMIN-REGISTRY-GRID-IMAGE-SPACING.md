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

**PUSH ONLY — not merged/deployed. Candidate `20efdd3` returned for independent pre-merge review.**

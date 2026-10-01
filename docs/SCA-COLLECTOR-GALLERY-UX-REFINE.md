# SCA Collector Gallery UX refinement (VIEW/CSS only) — PUSH ONLY

**Date:** 2026-10-01 · **Base:** deployed main `a8a6d88` (migrations 120). **Candidate HEAD:** `582690b`
on branch `sca-gallery-ux-refine` (impl repo). **Status:** PUSH ONLY — not merged, not deployed. Awaiting
independent pre-merge review.

## Scope / commit
Presentation-only. 1 commit; **3 files** — all Collector gallery Blade/CSS + its structural test:
- MOD `Collector/.../views/layout.blade.php` — gallery CSS (stable main canvas; square non-growing
  thumbnail tiles with `object-fit:contain`; hidden native scrollbar; active/focus states).
- MOD `Collector/.../views/collection/show.blade.php` — wrap the main `<img>` in
  `.sca-gallery-main-canvas` (stable product-image frame). No logic/URL change.
- MOD `tests/Feature/Sca/CollectorGalleryTest.php` — `rg8` strengthened to the styling contract.

**No change** to `sca_eyewear_item_images`, schema/migrations, `CatalogGalleryService`, collector service/
controller/DTO, routes/authorization, Admin gallery behavior, image ordering/featured semantics, upload/
delete/reorder, Passport behavior, provenance/QR/cert/auth/ownership, the `/storage` boundary, or infra.

## UX delivered
- **Stable product-image canvas:** fixed-height (240px) `.sca-gallery-main-canvas`, image `object-fit:
  contain` — differently sized uploads never crop the eyewear or jump the card.
- **Polished thumbnails:** fixed **66px square**, non-growing (`flex:0 0 auto`) tiles, `object-fit:contain`
  (whole product visible), sitting naturally `[1][2][3]`; subtle active border (`border-color` + 1px ring);
  `:focus-visible` outline retained (keyboard accessible).
- **Scrollbar hidden:** strip keeps `overflow-x:auto` + `flex-wrap:nowrap` for many images but hides the
  native scrollbar cross-browser (`scrollbar-width:none`, `-ms-overflow-style:none`,
  `::-webkit-scrollbar{display:none}`); contained within the fixed-width left panel (no page overflow).
- 0-image placeholder and 1-image behavior unchanged; thumbnail-switching JS and owner-authorized ordinal
  URLs unchanged.

## Tests
`rg8` now asserts: stable contained canvas (`height:240px` + `object-fit:contain`); square non-growing
thumbs (`flex:0 0 auto`, `width/height:66px`) with `object-fit:contain`; strip `flex-wrap:nowrap` +
`overflow-x:auto` + hidden scrollbar (`scrollbar-width:none` + `::-webkit-scrollbar{display:none}`); active
+ focus states; unchanged ordinal URLs; no `/storage` leak. Focused 24; **full tests/Feature/Sca 719/3936**;
php -l clean.

## Push-only + restoration evidence (production remains on a8a6d88)
Candidate pushed to `origin/sca-gallery-ux-refine` (HEAD `582690b`, base `a8a6d88`). Pilot restored to main
`a8a6d88` (working tree reverted; `--no-dev`; caches cleared; kr-app healthy on `195.26.255.80:8080`). No
candidate CSS live (`sca-gallery-main-canvas` in live layout = 0). Prod migrations **120**; FP_QR
`a920dc1c…`; is_production 0,0; verify. item-3 image 200; collector 302; smsrocket 302.

### Observed concurrent pilot data (NOT from this task) — FLAGGED
Item 3 now has **3 gallery images** (was 1 at Slice-3 close): position 1 is still the original operator
image (`sca-catalog/2EtJ7…png`, file 15:42, 793,158 B, legacy mirror intact); positions 2–3 are two new
real photos (`e5pKZ…` 1,050,172 B and `3nyMc…` 553,473 B) added **18:47 today via the now-live Admin
multi-image gallery** — legitimate operator pilot activity, NOT a leak from this CSS task (which touched only
Blade/CSS + a test on the disposable DB; no candidate CSS is live; provenance/migrations unchanged). Left
intact. This is useful real N≥2 data that the UX refinement is designed to present cleanly. The earlier
"item 3 = 1 gallery row" baseline is now stale.

## Rollback
View/CSS-only; no schema. Reverting the commit restores the current deployed presentation. Feature branch,
`--no-ff`, deploy-gated, push-only first for independent review.

## FINAL REVIEW = PASS/GO → DONE — MERGED --no-ff + DEPLOYED 2026-10-01

`MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = 5db1ab03319a43b43bbd4c9320c07ff8a4043384` (reviewed HEAD
`582690b`, base `a8a6d88`, 1 commit). Pre-merge gates passed (origin/main `a8a6d88`, feature `582690b`,
merge-base `a8a6d88`, clean tree, 1 commit/3 files).

**Deploy (`deploy-preview.sh`, exit 0):** full tests/Feature/Sca gate passed; **Nothing to migrate —
migrations remain 120**; recreate; `--no-dev`; `Deployed main @ 5db1ab0`. Pilot public bind
`195.26.255.80:8080` re-applied post-recreate; sca_edge attached.

**Post-deploy structural gallery gate (live Collector detail, item 3 = the 3 real operator images, NOT
modified):** 3 separate 66×66 square thumbnail tiles (`type="button" class="sca-thumb"` ×3); stable
`.sca-gallery-main-canvas` at `height:240px` with `object-fit:contain`; thumbnails `flex:0 0 auto` +
`width/height:66px` + `object-fit:contain`; strip `overflow-x:auto` + scrollbar hidden
(`scrollbar-width:none` + `::-webkit-scrollbar{display:none}`); switching script present; no `/storage` or
raw-path leak. Ordinals 1/2/3 stream their exact operator bytes (793158 / 1050172 / 553473), ordinal 4 →
404; item 3 gallery untouched (3 rows, mirror = original `2EtJ7…` at position 1 — nothing added/deleted/
reordered for verification). (Pixel-level in-browser rendering is the operator's visual confirmation; the
structural/CSS contract is proven deterministically here.)

**Security/invariant smoke (all unchanged):** migrations 120; FP_QR `a920dc1c…`, FP_CERT `22fb9f55…`,
FP_AUTH `3bd0f029…`, FP_OWN `831ae932…`; is_production 0,0; counts qr=2/certs=3/auth=3/own=4; SCA-038 valid
200 / bogus 404 / malformed 404; `/storage` 404; collector 302; :8080 200; smsrocket 302; Caddyfile
`0faece7a`; sca_edge + MariaDB-private intact.

**Collector gallery UX refinement COMPLETE. STOP — do not start another gallery/cutover task.**

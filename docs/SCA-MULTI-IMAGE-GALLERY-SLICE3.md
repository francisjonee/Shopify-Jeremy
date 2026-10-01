# SCA MULTI-IMAGE GALLERY — Slice 3 (Collector read-only product gallery) — PUSH ONLY

**Date:** 2026-10-01 · **Base:** deployed main `0bcdca5` (migrations 120). **Candidate HEAD:** `6275a45`
on branch `sca-gallery-slice3` (impl repo). **Status:** PUSH ONLY — not merged, not deployed. Awaiting
independent pre-merge review. Readiness GO: gov `2f6f031`.

## Scope / commit
1 commit; **7 files changed + 1 new**; **no migration** (table from Slice 1); no model change; no
`CatalogGalleryService`/Provenance change; no Krayin core/vendor edit; no infra.
- MOD `Collector/src/Services/CollectionService.php` — `catalogImageAtOrdinalForOwnedItem(collectorId,
  ref, n)`; `detail()` adds `image_count`.
- MOD `Collector/src/Http/Controllers/CollectionImageController.php` — `showAt(ref, n)` (+ shared
  `stream()` helper; `show()` kept = featured).
- MOD `Collector/src/Routes/collector-routes.php` — `GET collection/{ref}/images/{n}`
  (`collector.collection.images`, `collector.auth`).
- MOD `Collector/.../views/collection/show.blade.php` — gallery (featured main + ordered thumbnail strip +
  narrowly-scoped inline swap script); MOD `.../views/layout.blade.php` — thumbnail-strip CSS (mobile
  horizontal scroll).
- MOD tests `CollectorCatalogTest.php`, `CollectorItemDetailParityTest.php` (seed gallery rows); NEW
  `CollectorGalleryTest.php` (9).

## Locked decisions — implemented
- Single source of truth = `sca_eyewear_item_images`; **no collector image table, copy, sync, or collector
  featured state**; Collector fully read-only.
- Large image starts at **ordinal 1 (Admin featured)**; thumbnails ordered by Admin position.
- DTO adds **only** `image_count`; the Blade derives ordinals `1..N` + owner-authorized route URLs. No DB
  id / storage_path / disk / mime / checksum / internal item id in DTO or HTML.
- Route `GET collection/{ref}/images/{n}` → `showAt`, current-owner authorized; ordinal resolved
  server-side (`ownedItemId → listForItem → imageById`); the DB id never leaves; `no-store` + `nosniff`;
  non-owner / previous-owner / guessed ref / out-of-range → the identical privacy-safe explicit 404; kept
  `…/image` featured route for grid/cards; ordinal 1 == featured bytes.
- UX: 0 → "No catalog image" placeholder (no strip); 1 → single main (no strip/controls); ≥2 → featured
  main + horizontally-scrollable ordered thumbnail strip. Thumbnail click swaps the displayed image in place
  via a narrowly-scoped inline script (no framework, no mutation, no navigation); **no-JS keeps the featured
  image visible and the strip inert — thumbnails never navigate to the raw endpoint.**
- Admin add / reorder / delete / make-featured reflected automatically on the next request (live gallery
  read; no synchronization).
- Parity layout preserved (identity + Overview/Authentication/Certification/Documents/History + owner
  actions untouched).
- Passport unchanged: single `image_url` (featured), `PublicAllowlist` + SCA-038 untouched; **no public
  gallery**. `/storage` denied.

## Tests (focused 24; full tests/Feature/Sca 719/3923)
`CollectorGalleryTest` (9): zero→placeholder+ordinal 404; one→main, no strip, ordinal 1 bytes; ≥2→ordered
thumbnails + EXACT bytes per ordinal (ordinal 1 == featured); no DB id/path/disk/mime/checksum/table-name
leak (only ordinal URLs); Admin reorder reflected automatically; Admin delete reflected automatically;
owner 200 / non-owner + previous-owner + out-of-range + guessed ref privacy-safe 404; structural UX
(main + N thumb buttons in ordinal order, `.sca-thumbs` `overflow-x:auto`/`flex-wrap:nowrap`, swap script
present, no strip for N=1); viewing + switching = zero mutation (QR/cert/auth/ownership/current-state fp +
is_production + gallery rows/positions + legacy mirror unchanged). `CollectorCatalogTest` +
`CollectorItemDetailParityTest` fixtures seed a gallery row (real data always has one). php -l clean.

## Push-only + restoration evidence (production remains on 0bcdca5)
Candidate pushed to `origin/sca-gallery-slice3` (HEAD `6275a45`, base `0bcdca5`). Pilot restored to main
`0bcdca5` (working tree reverted; `--no-dev`; caches cleared; kr-app healthy on `195.26.255.80:8080`, no
recreate). No candidate code live: `route:list` `collection/{ref}/images/{n}` = 0, controller `showAt` = 0,
service `image_count` = 0. Prod migrations **120**; item 3 image intact (1 gallery row,
`sca-catalog/2EtJ7…png`); FP_QR `a920dc1c…`; is_production 0,0; verify. item-3 image 200; collector 302;
smsrocket 302.

## FINAL REVIEW = PASS/GO → DONE — MERGED --no-ff + DEPLOYED 2026-10-01

`MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = a8a6d8821617a2506a679254e83cb6593353c9d5` (reviewed HEAD
`6275a45`, base `0bcdca5`, 1 commit). Pre-merge gates passed (origin/main `0bcdca5`, feature `6275a45`,
merge-base `0bcdca5`, clean tree, 1 commit/8 files).

**Deploy (`deploy-preview.sh`, exit 0):** full tests/Feature/Sca gate passed; **Nothing to migrate —
migrations remain 120**; recreate; `--no-dev`; `Deployed main @ a8a6d88`. Pilot public bind
`195.26.255.80:8080` re-applied after the recreate; sca_edge auto-attached; collector ordinal route live.

**Post-deploy GOVERNED NET-ZERO GALLERY VERIFICATION (real Admin endpoints + Collector/Passport reads) —
all PASS:**
- Baseline: item 3 = 1 gallery row (operator image, position 1, SHA-256 `f3dee651…`).
- Added 2 test images via the real Admin `storeImages` → 3 rows, positions 1,2,3, position 1 still the
  original.
- Collector detail showed 3 ordered thumbnails with the original at position 1; each ordinal's Collector
  stream returned the EXACT expected bytes (ordinal 1 = original, 2 = test-1, 3 = test-2; all 200).
- Reordered test-1 to position 1 (Admin `reorderImages`) → Collector ordinal 1 and **Passport both followed
  to the new primary** (test-1 bytes).
- Deleted both test images (Admin `deleteImage`) → **FINAL restored: item 3 = 1 row at position 1 = original
  path + legacy mirror + SHA `f3dee651…`**; Collector ordinal 1 and Passport serve the original; out-of-range
  ordinal 2 → 404; catalog disk holds ONLY the operator image (both test files removed — nothing left
  behind).
- **Provenance unchanged** across the whole sequence: QR/cert/auth/ownership/current-state fingerprints
  identical; is_production 0,0; migrations 120.
- Owner access 200; non-owner / out-of-range privacy-safe 404; Collector tabs (Overview/Authentication/
  Certification/Documents/History) 5/5 intact; no `/storage` or internal gallery-metadata leak in the
  Collector HTML.
- `/storage` denied 404; SCA-038 valid 200 / bogus 404 / malformed 404; :8080 passport 200; smsrocket 302;
  Caddyfile `0faece7a`, sca_edge, MariaDB-private unchanged.

**Slice 3 COMPLETE. STOP — do not begin a public Passport gallery, legacy-column removal, or another cutover
task.**

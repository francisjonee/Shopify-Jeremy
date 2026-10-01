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

**PUSH ONLY — not merged/deployed. Candidate `6275a45` returned for independent pre-merge review. Do not
merge/deploy, and do not begin any public-Passport gallery or legacy-column-removal work.**

# SCA MULTI-IMAGE GALLERY — Slice 2 (Admin gallery management) — PUSH ONLY

**Date:** 2026-10-01 · **Base:** deployed main `8b03543` (migrations 120). **Candidate HEAD:** `0ecf533`
on branch `sca-gallery-slice2` (impl repo). **Status:** PUSH ONLY — not merged, not deployed. Awaiting
independent pre-merge review. Readiness GO: gov `6c04229`.

## Scope / commit
1 commit; **6 files changed + 1 new**; **no migration** (table exists from Slice 1); no model change; no
Krayin core/vendor edit.
- MOD `Provenance/src/Services/CatalogGalleryService.php` — added `listForItem`, `imageById`, `addMany`,
  `deleteOne`, `reorder`, `imageIds`, `isPathReferenced`, `normalize`; removed Slice-1 `setSingle`/`clear`.
- MOD `Registry/src/Http/Controllers/EyewearItemController.php` — `updateCatalog` → SKU-only; new
  `storeImages`, `deleteImage`, `reorderImages`, `imageAt`; `show()` passes `galleryImages`; all image
  routes `no-store`.
- MOD `Registry/src/Routes/admin-routes.php` — gallery routes.
- MOD `Registry/src/Resources/views/eyewear/show.blade.php` — one Catalog manager.
- NEW `tests/Feature/Sca/CatalogGalleryAdminTest.php` (12); MOD `CatalogUiTest.php`, `CatalogGalleryTest.php`
  (migrated image flows to the gallery endpoints).

## Locked decisions — implemented
1. **One manager:** SKU + featured(badge) + thumbnail gallery + Make-featured + Move + Delete + multi-Add;
   the single-image `image`/`remove_image` inputs are gone; `updateCatalog` is SKU-only. Fully usable with
   **no JS** (plain forms; server is the integrity boundary).
2. **Ordering-derived primary (no `is_primary`):** featured = lowest `(position,id)`; every mutation
   normalizes to contiguous **1..N** via a single-transaction full-set renumber on the non-unique index.
3. **Server authority / cross-item:** every `{imageId}` resolved `WHERE eyewear_item_id={id}`; a foreign id
   on another item's route → 404 with no mutation; reorder requires the exact current id set. No storage
   path/disk/mime/checksum/DB id in collector/public HTML; `/storage` denied.
4. **Legacy mirror = current primary**, updated in the SAME transaction on upload / reorder / make-primary
   / delete-primary(promote next) / delete-last(→NULL). Rollback-safe (see Slice-2 audit §5).
5. **File/transaction safety:** upload validates (type/size + decoded-image guard **≤10000 px/side & ≤50
   MP** + **8-image total cap**) BEFORE storing, stores files, mutates in one transaction, and on DB
   failure deletes every file stored by that request; delete commits row-removal/renumber/mirror FIRST and
   deletes the physical file only post-commit and only when no gallery row or legacy column still
   references it (reference-aware).
6. **Limits:** 8/item total, 4 MB each, JPG/JPEG/PNG/WebP; decoded guard as above; invalid/corrupt
   rejected even when the extension/MIME claims an image; multi-file failures leave no partial state.
7. **Reorder:** complete authoritative set only (no missing/duplicate/foreign/invented); server renumbers.
8. **Existing consumers preserved:** Admin featured route kept; Collector + Passport still receive the
   primary only; public passport DTO stays the single `image_url`. No Collector/public gallery in this slice.
9. **Provenance:** gallery ops touch only `sca_eyewear_item_images` + the legacy mirror columns.

## Tests (focused 30; full tests/Feature/Sca 709/3853)
`CatalogGalleryAdminTest` (12): first upload; multi-upload order; 8-cap + 9th rejection; invalid +
decompression rejection with no partial state; make-primary; arbitrary reorder; malformed reorder
(missing/duplicate/foreign/invented); cross-item delete + stream fail-closed; delete non-primary/primary/
last with mirror follow; exact streamed bytes per image; Admin/Collector/Passport featured follow the new
primary after reorder; failed-DB upload leaves no orphan file; failed-DB delete leaves file + row intact;
ACL matrix; no internal-field leak; full zero-provenance fingerprint + is_production. `CatalogUiTest` and
`CatalogGalleryTest` migrated to the gallery endpoints. php -l clean.

## Push-only + restoration evidence (production remains on 8b03543)
Candidate pushed to `origin/sca-gallery-slice2` (HEAD `0ecf533`, base `8b03543`). Pilot restored to main
`8b03543` (working tree reverted; `composer install --no-dev`; caches cleared; kr-app healthy on
`195.26.255.80:8080`, no recreate). Proof **no candidate code/route/schema leaked**: live packages grep for
`storeImages/reorderImages/listForItem` = 0; `route:list` gallery-mgmt routes = 0; prod migrations **120**
(unchanged); item 3 image intact (1 gallery row, `sca-catalog/2EtJ7…png`); FP_QR `a920dc1c…`; is_production
0,0; counts qr=2/certs=3/auth=3/own=4. verify. passport 200 / item-3 image 200; :8080 passport 200;
smsrocket 302.

**PUSH ONLY — not merged/deployed. Candidate `0ecf533` returned for independent pre-merge review. Do not
begin Collector gallery Slice 3.**

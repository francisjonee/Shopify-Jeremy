# SCA MULTI-IMAGE GALLERY — Slice 1 (schema + backfill + read-switch) — PUSH ONLY

**Date:** 2026-10-01 · **Base:** deployed main `91dfb2a`. **Candidate HEAD:** `6879130` on branch
`sca-gallery-slice1` (impl repo). **Status:** PUSH ONLY — not merged, not deployed. Awaiting independent
pre-merge review. Architecture GO: the gallery readiness audit (gov `f0e64d7`).

## Scope (exactly the authorized Slice 1)
Schema + idempotent/file-safe backfill + read-switch making `sca_eyewear_item_images` the authoritative
read source for the effective PRIMARY image, with current single-image behavior identical. **NOT** in this
slice: multi-image Admin UI, upload-many/reorder controls, Collector gallery UI, public gallery,
legacy-column removal. 7 files: 4 new + 3 modified.

## Locked decisions implemented
1. **No `is_primary`.** Featured = lowest `position` (ties by `id`); position is the sole source of
   truth. Reads order by `(position, id)`.
2. **Non-unique `(eyewear_item_id, position)` index** + service-owned normalization (Slice-1 single-image
   path writes exactly one position-1 row → contiguous 1..N trivially holds).
3. **Limits** (for Slice 2's upload path; not enforced here as there is no new upload path yet): max 8
   images/item, 4 MB/image, JPG/PNG/WebP, decoded-pixel safety ceiling to be recorded with Slice 2.
4. **Passport = primary only.** `image_url` allowlist, presenter, view, and SCA-038 constant-shape 404
   are unchanged; only the stream source switches to the gallery primary.
5. **Legacy migration.** Existing legacy image → gallery position 1 referencing the SAME file (no
   move/re-encode); `image_path`/`image_mime` kept dormant for rollback (NOT dropped).

## Files
- NEW `…/Provenance/src/Database/Migrations/2026_10_01_000001_create_sca_eyewear_item_images.php` —
  table + idempotent, file-safe backfill (per-item `exists()` guard; inserts only where a legacy image
  exists and no gallery row yet; no file operations). `down()` drops the table only.
- NEW `…/Provenance/src/Models/EyewearItemImage.php`.
- NEW `…/Provenance/src/Services/CatalogGalleryService.php` — `primaryImage(itemId, legacyPath?,
  legacyMime?)` (gallery lowest-position, else legacy fallback), `hasGalleryRows`, `count`, `setSingle`
  (exactly one position-1 row), `clear`. Returns only `{path,mime}`; never exposes storage/mime/id to any
  DTO/view.
- MOD `…/Registry/src/Http/Controllers/EyewearItemController.php` — `updateCatalog` mirrors the existing
  single-image control into the gallery (setSingle/clear) inside a `DB::transaction` with an orphan-file
  guard, still writing legacy columns; `image()` streams `primaryImage(gallery ?? legacy)`.
- MOD `…/Collector/src/Services/CollectionService.php` — `catalogImageForOwnedItem` returns
  `primaryImage(gallery ?? legacy)`; `has_image` unchanged (legacy mirrors the primary in Slice 1).
- MOD `…/Passport/src/Http/Controllers/PassportController.php` — `image()` streams
  `primaryImage(gallery ?? legacy)`; presenter/view/allowlist untouched.

## Tests / gates
New `tests/Feature/Sca/CatalogGalleryTest` (9): (rg1) no image → no rows + placeholder; (rg2) backfill
maps legacy → single position-1 same-file, idempotent, legacy retained; (rg3) primary = lowest position
then id; (rg4) single-image control keeps exactly one contiguous position (upload/replace/remove); (rg5)
Admin/Collector/Passport serve byte-equal primary for a migrated legacy image; (rg6) non-owner /
unauthenticated / bogus-token privacy-safe 404 unchanged; (rg7) no `/storage/sca-catalog`, path, mime,
storage_disk, checksum, media id, or table name in Collector/Public HTML (a core `/storage/configuration/`
CRM-logo CSS selector is unrelated and allowed); (rg8) backfill + gallery writes cause zero
QR/cert/auth/ownership/projection/`is_production` mutation; (rg9) legacy columns stay a faithful mirror of
the primary for rollback. **Focused 9/61; full tests/Feature/Sca 697/3745; php -l clean.**

## Pilot restore + leak proof (deployed `91dfb2a`)
Pilot restored to main `91dfb2a` (working tree reverted; `composer install --no-dev`; caches cleared;
kr-app healthy on `195.26.255.80:8080`). **No candidate code live** (`grep` for CatalogGalleryService /
sca_eyewear_item_images in live packages = 0). **No schema leak:** prod `sca_krayin` has NO
`sca_eyewear_item_images` table; migrations remain **119**. **Provenance unmutated:** `is_production` 0,0;
counts qr=2 / certs=3 / certev=4 / auth=3 / own=4 (unchanged). The new migration was applied only to the
disposable `sca_domain_test` DB for the branch's tests.

### Observed concurrent pilot data change (NOT a candidate/schema leak) — FLAGGED
During this session, **prod item 3 (`SCA-F1B792AE4745`) acquired a real single catalog image**
(`image_path = sca-catalog/2EtJ7…png`, `image_mime image/png`, 793,158 bytes, `updated_at 2026-10-01
15:42`, file present on the real public disk). This was written through the **normal (main) single-image
Admin control** — a legitimate live-pilot upload by a human operator — NOT by this Slice-1 candidate:
Slice-1 tests run against `sca_domain_test` with `Storage::fake`, and the feature-branch `updateCatalog`
would have failed on the absent prod gallery table and rolled back via the orphan guard (leaving no file),
whereas a real 775 KB file exists and no prod gallery table does. The live main pilot serves this image
correctly (collector 200 / passport 200, bytes match the disk). **It was left intact** (deleting it would
destroy legitimate operator data). Note: the earlier baseline "both items image_path NULL" is now stale
for item 3. This is actually a useful real-data validation of the Slice-1 compatibility story — on a
future Slice-1 deploy the backfill will map this image to gallery position 1 (same file), changing nothing
visible. **Action for the user: confirm this was an intended operator upload.**

## Rollback
Each slice is an independent feature branch, `--no-ff`, deploy-gated. Migration `down()` drops the table;
legacy columns are retained through Slices 1-3, so reverting code + dropping the table restores exact
present-day behavior. In prod the backfill would map item 3's one legacy image to position 1 (same file).

## DONE — MERGED --no-ff + DEPLOYED 2026-10-01 (pre-merge CONDITIONAL GO)

`MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = 8b03543ecd8a5754228871509b910536a9de3803` (reviewed candidate
`6879130`, base `91dfb2a`, 1 merge of 1 commit). Pre-merge gates passed (origin/main `91dfb2a`, feature
`6879130`, merge-base `91dfb2a`, clean tree, 7 files). The changed production baseline (item 3's real
operator image) was explicitly accepted as real data.

**Pre-deploy baseline (locked):** item 3 `image_path=sca-catalog/2EtJ7…png`, mime `image/png`, file
SHA-256 `f3dee6510178bfb287c040e36dfaa20479ab3ac637d29298e6bd09c0cd996d34`, 793,158 bytes; Admin/Collector/
Passport all 200 with that SHA; item 1 NULL; FP_QR `a920dc1c…` FP_CERT `22fb9f55…` FP_CERTEV `18b521db…`
FP_AUTH `3bd0f029…` FP_OWN `831ae932…`; is_production 0,0; migrations 119; gallery table absent.

**Deploy (`deploy-preview.sh`, exit 0):** test gate full tests/Feature/Sca passed (sca_domain_test, dev
deps), then prod `migrate --force`, recreate, `--no-dev` prune, caches cleared; `Deployed main @ 8b03543`.

**Migration integrity (all required checks PASS — no deviation, no rollback):** migrations **119→120**;
gallery table created; **exactly 1 gallery row total**; item 3 = 1 row at **position 1**, item 1 = 0 rows;
gallery `storage_path` == pre-deploy legacy `image_path` (`sca-catalog/2EtJ7…png`); legacy
`image_path`/`image_mime` **intact**; file **SHA-256 `f3dee651…` / 793,158 bytes unchanged**, exactly one
file on the catalog disk (no move/copy/re-encode/delete).

**Post-deploy proof:** deployed HEAD == origin/main == merge SHA `8b03543`. Admin, Collector, and Passport
all return the SAME pre-deploy bytes (SHA `f3dee651…`) through their existing routes. Item 1 remains
no-image (admin image 404). `/storage` denied (404) — public image URL blocked; images only via routes.
Non-owner collector 404. No gallery internals in collector HTML. verify. passport 200 / item-3 public
image 200 / bogus 404; collector 302; :8080 passport 200; smsrocket 302. sca_edge auto-attached
(172.20.0.3); pilot public bind `195.26.255.80:8080` re-applied after the recreate; MariaDB private.
**All 5 provenance fingerprints unchanged; is_production 0,0; counts qr=2/certs=3/certev=4/auth=3/own=4.**

**Slice 1 COMPLETE. Stop. Do NOT begin Slice 2** (multi-image Admin UI, upload-many/reorder, Collector
gallery UI, public gallery, legacy-column removal) without its own review + GO.

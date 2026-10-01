# SCA MULTI-IMAGE PRODUCT GALLERY — Readiness / Architecture Audit (READ-ONLY, DO NOT IMPLEMENT)

**Date:** 2026-10-01 · **Deployed base:** `91dfb2a` · **Author:** implementation session, for ChatGPT review.
**Status:** AUDIT ONLY. No migration, table, route, code, or file was created. Nothing was mutated.

Goal: evolve the single catalog image into a Shopify-style product gallery (multiple Admin-managed
images; large featured image + thumbnail strip; click-to-feature; Admin upload/remove/reorder) that the
Collector mirrors **read-only**, with Admin media as the single source of truth, **no `image_2/3…`
columns**, `/storage` edge-denial preserved, no Krayin core edits, and zero provenance mutation.

---

## 1. Current implementation (audited)

### 1.1 Data — single image, two columns on the item
`packages/Sca/Provenance/src/Database/Migrations/2026_09_30_000001_add_catalog_to_sca_eyewear_items.php`
added three **nullable, additive, mutable presentation** columns to `sca_eyewear_items`: `sku`,
`image_path`, `image_mime`. Explicitly separate from immutable provenance; they gate nothing (QR, cert,
auth never read them); designed as a future Shopify-sync target. `EyewearItem` model
(`packages/Sca/Provenance/src/Models/EyewearItem.php`) is bare (`$guarded=[]`, no casts/relations).
**Prod today: both items (1, 3) have `image_path = NULL` → 0 images; backfill will be a no-op in prod.**

### 1.2 An existing, DISTINCT media table — `sca_media_assets`
`packages/Sca/Provenance/src/Database/Migrations/2026_09_14_120015_create_sca_media_assets.php` +
model `MediaAsset.php`. Columns: `eyewear_item_id`, `subject_type`, `subject_id`, `storage_disk`,
`storage_path`, `checksum_sha256`, `is_public`, `kind`, `created_at`; FK `restrictOnDelete`; CHECK
`subject_type IN ('authentication','service','certification','item')` and CHECK `kind IN
('photo','document','certificate_pdf')`; index `(subject_type, subject_id)`. This is **provenance-evidence
media** (authentication/service photos, certificate PDFs) with an append-only/evidence lifecycle, an
`is_public` opt-in, and no ordering column. See §3 for why the gallery should NOT overload it.

### 1.3 Admin flow
- Route group `admin.sca.eyewear.*` (`packages/Sca/Registry/src/Routes/admin-routes.php`):
  `POST {id}/catalog` → `updateCatalog` (ACL `sca.eyewear.catalog`); `GET {id}/image` → `image`
  (ACL `sca.eyewear.view`).
- `EyewearItemController::updateCatalog` (L416-454): validates `sku` (≤64), `image`
  (`image|mimes:jpg,jpeg,png,webp|max:4096`), `remove_image` (bool). On remove: `Storage::disk('public')
  ->delete($item->image_path)` then nulls path+mime. On upload: deletes the prior file, then
  `$file->store('sca-catalog','public')` → sets `image_path`+`image_mime`. Single `$item->save()`.
- `EyewearItemController::image` (L460-472): streams `Storage::disk('public')->get(image_path)` with
  `Content-Type: image_mime`, `Cache-Control: private, max-age=300`. 404 (explicit Response) when no image.
- View `packages/Sca/Registry/src/Resources/views/eyewear/show.blade.php` (L23-33, L47-81): featured
  `<img src=route('admin.sca.eyewear.image',id)>` or a dashed "No catalog image" box; an accordion edit
  form (`enctype=multipart/form-data`, `@csrf`, file input, SKU, remove checkbox) gated by
  `bouncer()->hasPermission('sca.eyewear.catalog')`. Uses core `x-admin::*` components — no core edits.

### 1.4 Collector flow (read-only, owner-authorized)
- `CollectionService` (`packages/Sca/Collector/src/Services/CollectionService.php`): `baseQuery` selects
  `i.image_path` **server-side only** to derive `has_image = image_path !== null` (L436/498); the path is
  **never** placed in a DTO. `catalogImageForOwnedItem(collectorId, ref)` (L380-393) returns
  `{path,mime}` only for a **currently-owned** item (via `ownedItemId`), else null.
- `CollectionImageController::show(ref)` (`…/Http/Controllers/CollectionImageController.php`): streams the
  owned item's image with `Cache-Control: no-store`, `X-Content-Type-Options: nosniff`; non-owner /
  previous-owner / guessed-ref / no-image all → identical privacy-safe `response()->view(...,404)`
  (explicit, not `abort()`), via the `collector` guard, `web` group, **no CSP**.
- Route `collector.collection.image` = `GET collection/{ref}/image`.
- View `collection/show.blade.php` (L46-53): featured `<img src=route('collector.collection.image',ref)>`
  or the SCA-COLLECTOR-IMAGE-PRESENTATION "No catalog image" placeholder (just deployed in `91dfb2a`).

### 1.5 Public passport surface (SCA-038 Option A)
- Routes (`packages/Sca/Passport/src/Routes/public-routes.php`): `GET /p/{token}` → `show`;
  `GET /p/{token}/image` → `image`. Group middleware = **only** `PublicPassportHeaders` (CSP
  `default-src 'none'; img-src 'self' data:; style-src 'unsafe-inline'; …`), **outside** admin/`web`
  groups — no session/CSRF, **no ACL** (access control is the resolver + constant-shape 404).
- `PassportResolver::resolve(token)` binds the token to **exactly one item** through an all-exact chain
  (well-formed `^[0-9a-f]{32}$` → QR by `public_token` → current state → **active** QR match → current
  certification `issued` → passed finalized authentication → item). Any step null → one 404.
- `PassportController::image(token)` reuses the resolver, then streams `item->image_path`
  (`no-store`,`nosniff`), else `imageNotFound()` = `response('',404)`. `show` renders the allowlisted DTO;
  `PassportPresenter::imageUrl()` emits a **single** relative `route('sca.passport.image',[token])` (or
  null), guarded by `PublicAllowlist::assertOnlyAllowlisted` (`image_url` is the only image key). The view
  shows one `<img>` when present, nothing otherwise (no placeholder). **The token IS the authorization —
  no item-id/ordinal parameter exists anywhere.**

### 1.6 Storage deletion / replacement / orphan behavior today
`updateCatalog` deletes the prior file before storing a replacement and on removal — so the
single-image path self-cleans. The **reusable safe pattern** for new work is `DocumentService`
(`packages/Sca/Provenance/src/Services/DocumentService.php`): store file → DB row inside a transaction,
and **delete the stored file if the DB write throws** (orphan guard); records `checksum_sha256`.
(Note: one orphan was found and removed during the earlier sync verification — it came from a probe that
nulled `image_path` via raw SQL without a Storage delete, i.e. not through `updateCatalog`.)

### 1.7 Edge / infra invariants to preserve
Caddy default-denies `/storage` (404); images are ONLY reachable through authorized app routes. Disk
`public` root `storage/app/public`, `url = APP_URL.'/storage'` (never emitted). All image streams must
stay route-served. No Krayin core/vendor edits anywhere.

### 1.8 Existing tests (the regression baseline to extend)
- `CatalogUiTest` (admin) rg1-rg9; `CollectorCatalogTest` rg1-rg6; `PassportCatalogImageTest` rg1-rg6;
  `CatalogGridTest` rg1-rg7; `CollectorItemDetailParityTest` rg1-rg9 (rg9 = placeholder). Each asserts no
  path/mime/SKU leak, authorized-route-not-`/storage`, byte equality, constant-shape 404, and zero
  QR/provenance/`is_production` mutation. The gallery work must keep every one of these green (updating
  only where single→featured semantics change) and add the new coverage in §12.

---

## 2. Proposed schema — `sca_eyewear_item_images` (normalized child, NO extra columns)

```
Schema::create('sca_eyewear_item_images', function (Blueprint $t) {
    $t->bigIncrements('id');
    $t->unsignedBigInteger('eyewear_item_id');
    $t->unsignedInteger('position');                 // 1-based order; LOWEST = featured/primary
    $t->string('storage_disk', 32)->default('public');
    $t->string('storage_path', 512);                 // server-generated unguessable path (sca-catalog/…)
    $t->string('image_mime', 100)->nullable();
    $t->char('checksum_sha256', 64)->nullable();     // integrity + dedupe, matches sca_media_assets
    $t->unsignedInteger('byte_size')->nullable();    // audit / limit evidence (optional)
    $t->timestamp('created_at')->useCurrent();
    $t->timestamp('updated_at')->nullable();         // reorder/replace touch this

    $t->foreign('eyewear_item_id')->references('id')->on('sca_eyewear_items')->restrictOnDelete();
    $t->index(['eyewear_item_id', 'position']);      // listing + featured lookup (see §2.2 re: uniqueness)
});
// Optional CHECK position >= 1.
```

### 2.1 `is_primary` flag — NOT needed (recommended)
Featured = **lowest `position`** (tie-broken by `id`). One source of truth for ordering; impossible to
desync. "Make this the primary" = move it to position 1 (a reorder). This directly satisfies "prefer one
source of truth and avoid redundant state." **Recommendation: no `is_primary` column.**

### 2.2 Uniqueness of `(eyewear_item_id, position)` — recommend NON-unique index
A UNIQUE `(item,position)` best documents intent but breaks naive reorder swaps on MariaDB (per-row
constraint checks mid-UPDATE, not deferrable), forcing a two-phase renumber (offset all by +100000, then
set 1..N). Because **reorder always rewrites the whole set atomically** (§6), a plain index plus
app-enforced contiguous renumber is simpler and race-safe. **Recommendation: non-unique
`index(eyewear_item_id, position)`**; featured = `ORDER BY position, id LIMIT 1`. (Alternative: UNIQUE +
two-phase renumber — note the trade-off for review.)

### 2.3 Why a dedicated table, not `sca_media_assets` or JSON
- `sca_media_assets` is append-only **provenance evidence** with `restrictOnDelete` and CHECK constraints
  on `kind`/`subject_type`; a mutable, freely reorder/delete catalog gallery has a different lifecycle.
  Overloading it means ALTERing those CHECKs and adding a `position` column meaningless to every
  non-gallery row — poor normalization and risk to provenance media.
- A JSON column on `sca_eyewear_items` violates "normalized child table," can't index/constrain ordering,
  and complicates per-image authorization. **Dedicated table recommended** (same separation rationale the
  original catalog-columns migration already states).

---

## 3. Exact affected files / routes / services / views (no implementation here)

**New:** migration `…/Provenance/src/Database/Migrations/XXXX_create_sca_eyewear_item_images.php`; model
`…/Provenance/src/Models/EyewearItemImage.php` (+ optional `EyewearItem::images()` relation); service
`…/Registry/src/Services/CatalogGalleryService.php` (upload/delete/reorder transactions + orphan guard;
reuse DocumentService store-then-row-then-cleanup pattern).

**Registry (Admin):** `EyewearItemController` — add `images` (multi-upload), `imageDelete`,
`imagesReorder`, and a specific-image stream `imageAt`; keep `image` = featured for back-compat.
`admin-routes.php` — add `POST {id}/images`, `POST {id}/images/{imageId}/delete` (or `DELETE`),
`POST {id}/images/reorder` (ACL `sca.eyewear.catalog`), `GET {id}/images/{imageId}` (ACL
`sca.eyewear.view`); keep `{id}/image`. `eyewear/show.blade.php` — gallery UI (featured + thumbnail strip
+ manage controls) using core `x-admin::*` + the Alpine already shipped with Krayin admin (no new lib, no
core edit). SKU stays on `updateCatalog` (decouple SKU from gallery).

**Collector (read-only mirror):** `CollectionService` — add `galleryForOwnedItem(ref)` returning an
ordered list of `{ ordinal }` (1..N) + keep `has_image` (count>0) and `catalogImageForOwnedItem` =
featured. `CollectionImageController` — add `showAt(ref, n)` streaming the n-th owned image
(`no-store`,`nosniff`), privacy-safe 404; keep `show` = featured. `collector-routes.php` — add
`GET collection/{ref}/images/{n}` (`n` = `[0-9]+`). `collection/show.blade.php` + `layout.blade.php` —
CSS-only featured swap (see §5).

**Passport (primary-only, see §7):** `PassportPresenter::imageUrl()` — one-line change to resolve the
**featured** gallery image (fallback to legacy `image_path` until §Slice-4). Route + allowlist
(`image_url`) + view UNCHANGED.

**Tests:** extend the five files in §1.8 + new `CatalogGalleryTest` (admin) and
`CollectorGalleryTest`; passport covered by extending `PassportCatalogImageTest`.

---

## 4. Authorization model (unchanged boundaries, extended per-image)
- **Admin:** mutations → `sca.eyewear.catalog`; streams → `sca.eyewear.view`. Every image id in a URL is
  bound server-side to the route's item (`where eyewear_item_id = {id}`) → 404 otherwise.
- **Collector:** every detail + every per-image stream authorized by **current ownership**
  (`ownedItemId`); the `{n}` ordinal is resolved **within the owned item's** gallery only; non-owner /
  previous-owner / guessed ref / out-of-range `n` → identical privacy-safe explicit 404. **No raw DB
  image id, storage path, mime, or checksum ever leaves the service** — the DTO exposes only a per-item
  ordinal (1..N) used to build the route URL. (Ordinal count/order is inherent to a visible gallery and is
  not a sensitive internal identifier.)
- **Passport:** token→item binding only; featured image via the existing single `/p/{token}/image`
  reusing the resolver + constant-shape 404. No per-image public route (primary-only).
- `/storage` stays edge-denied; all images route-served; no core edits.

---

## 5. UI approach
- **Admin** (Tailwind + Krayin's Alpine; no new lib, no core edit): large featured image + horizontal
  thumbnail strip; clicking a thumbnail sets the featured view client-side (Alpine state, purely visual —
  authority is server `position`). Multi-file upload input; per-thumbnail Remove (POST delete); reorder
  via up/down buttons (accessible, lib-free; drag-drop optional later) posting the new order; a "Featured"
  badge on position 1.
- **Collector** (inline-style, **JS-FREE**, no CSP): read-only mirror using the **CSS-only** technique
  already proven for the tabs — one hidden radio per image + `:checked ~ .featured img` to swap the large
  featured image when a thumbnail (a `<label>`) is selected; position 1 checked by default. All images via
  owner-authorized ordinal routes; no upload/remove/reorder controls. Renders N featured `<img>`s toggled
  by CSS (bandwidth bounded by the §8 count cap + `no-store`). Zero-image → existing placeholder.
- **Passport:** unchanged single featured `<img>` (primary-only).

---

## 6. Safe upload / delete / reorder transactions + orphan handling
- **Upload (1..k files):** for each file, `store('sca-catalog','public')` (unguessable path) → INSERT row
  with `position = currentMax+1`, mime, checksum, byte_size — all inside ONE DB transaction; on any throw,
  roll back AND delete every file stored in this request (DocumentService pattern). Reject when
  `existing + new > MAX` (§8) before storing.
- **Delete one:** transaction deletes the row; after commit, `Storage::delete` the file (best-effort,
  logged on failure — row already gone, so no dangling reference). Positions need not be contiguous;
  featured = `MIN(position)` so deleting the featured auto-promotes the next. (Optional: renumber to
  close gaps for tidy reorder UX.)
- **Reorder:** accept the full ordered list of the item's image ids; validate it equals EXACTLY the
  item's current set (no foreign/missing ids) → renumber 1..N in one transaction (non-unique index ⇒ no
  swap conflict). Last-write-wins on concurrent staff edits (acceptable; note in risks).
- **Orphan reconciliation (ops, not a job):** a read-only query `storage files under sca-catalog/ not
  referenced by any row` can be reported; no background sync job is introduced (single source of truth =
  the table + its files).

---

## 7. Public passport: primary image only (RECOMMENDED DEFAULT)
Expose **only the featured/primary** image on the passport. Rationale: (a) the passport is a minimal,
unauthenticated public attestation — a full gallery adds public surface and per-image public routes for
no verification value; (b) keeps the SCA-038 constant-shape contract and the single `image_url` allowlist
key unchanged (lower regression risk); (c) `img-src 'self'` already permits the one same-origin image.
If a full public gallery is ever wanted, it would need `/p/{token}/image/{n}` (token-bound, per-image
constant-shape 404) + an `image_urls` allowlist key + a view loop — explicitly **deferred**.

---

## 8. Limits (recommended, enforced in the upload validator)
- **Count:** max **8** images/item (reject upload that would exceed). - **Size:** keep **4 MB**/image
  (`max:4096`). - **MIME/types:** jpg, jpeg, png, webp (unchanged; we store+stream, never re-encode, so
  GD's missing `imagewebp` is irrelevant). - **Dimensions:** guard against decompression bombs with a max
  (e.g. **6000×6000**) via `getimagesize` (verify webp is readable by the installed GD/libwebp; else skip
  the dimension check for webp or use `finfo`). - **Ordering:** positions 1..N, featured = lowest.

---

## 9. Migration strategy (behavior-preserving, zero provenance mutation)
1. Create `sca_eyewear_item_images`.
2. **Backfill:** for each `sca_eyewear_items` with `image_path NOT NULL`, INSERT one row
   `(eyewear_item_id, position=1, storage_disk='public', storage_path=image_path, image_mime, checksum=
   null, byte_size=null)`. **No file is moved or rewritten** — the existing stored file is simply now
   referenced by a gallery row at position 1, so users see the identical image. **Prod backfill = 0 rows**
   (both items NULL) → effectively a no-op in production.
3. **Keep** `image_path`/`image_mime` columns **dormant** (frozen; read paths switch to the gallery,
   write paths stop touching them). This preserves a trivial rollback source. A later **Slice 4** drops
   them once the gallery is proven.
4. Touches ONLY `sca_eyewear_items` (dormant cols) + the new table. **No QR / certification /
   authentication / ownership / projection / media-asset row is read or written** → QR/provenance/cert/
   auth/ownership fingerprints provably unchanged (asserted in every test).

---

## 10. Rollback strategy
- Each slice is an independent feature branch, `--no-ff` merge, `deploy-preview.sh` gated, reversible.
- Migration `down()` drops `sca_eyewear_item_images`; because the legacy columns are retained through
  Slices 1-3, reverting code + dropping the table restores exact present-day single-image behavior. In
  prod (0 images) rollback is a no-op. Slice 4 (column drop) is the only non-trivial revert and is
  deferred until the gallery is fully verified; its own `down()` re-adds the nullable columns (data for
  dropped columns is unrecoverable, which is why it is last and gated).

---

## 11. Risks & mitigations
1. **Reorder uniqueness/swap** → non-unique index + atomic full-set renumber (§2.2/§6).
2. **Orphan files** (failed multi-upload, partial delete) → store-then-row-then-cleanup transaction +
   best-effort post-commit delete + a read-only reconciliation query.
3. **Collector JS-free gallery renders N images** → count cap (8) + `no-store`.
4. **webp + GD dimension check** → verify libwebp in GD or skip dimension guard for webp.
5. **Decompression bombs / huge dimensions** → `getimagesize` max-pixel guard.
6. **Passport exact-item binding** must hold for the featured image → one-line presenter change + rg
   proving the featured image is the item's own position-1 and the token stays the only authorization.
7. **Dual-source transition** (legacy cols vs gallery) → freeze legacy writes, read only gallery, a
   migration-parity test proving an existing single image renders byte-identically post-migration.
8. **Stale cache after reorder/replace** → `no-store` on ALL image routes (switch the Admin route from
   `max-age=300` to `no-store`).
9. **`/storage` leakage** → no `/storage` URL or raw path/mime/id ever emitted; rg asserts absence.
10. **CSP** → passport `img-src 'self'` already OK (primary-only); collector has no CSP; Admin uses
    shipped Alpine (no inline-handler CSP issue, no new lib).
11. **Concurrent staff reorder** → last-write-wins (documented; acceptable for a 2-staff operation).

---

## 12. Tests / gates (regression coverage to define)
**Admin (`CatalogGalleryTest` + extend `CatalogUiTest`/`CatalogGridTest`):** multi-upload appends in
order; featured = position 1; reorder changes featured + order; per-image delete; final-image delete →
placeholder; specific-image stream byte-equals the uploaded file; count/size/mime/dimension limits
rejected; `sca.eyewear.catalog` required for mutation, `sca.eyewear.view` for stream; orphan file deleted
on failed insert & on delete; no `/storage`/path/mime/id leak; **zero QR/provenance/cert/auth/ownership
mutation**.

**Collector (`CollectorGalleryTest` + extend `CollectorCatalogTest`/`CollectorItemDetailParityTest`):**
owner sees featured + N thumbnails; each ordinal stream byte-equals the SAME Admin file (Admin↔Collector
byte equality); non-owner / previous-owner / guessed ref / out-of-range `n` → identical privacy-safe 404;
no raw path/mime/DB-id leak (only ordinals in URLs); no-image → placeholder + featured route 404;
read-only zero mutation.

**Passport (extend `PassportCatalogImageTest`):** shows ONLY the featured/primary image (position 1);
multi-image item still exposes a single `image_url`; no `image_urls`/gallery/SKU/path leak;
constant-shape 404 preserved; SCA-038 `/p/{token}` 200/404 unchanged; reorder that changes the featured
image changes what the passport serves (token-bound), still one image; zero mutation.

**Migration:** existing single image → position 1 renders byte-identically on Admin, Collector, and
passport (no visible change); no-image items stay placeholder; backfill touches no provenance table;
fingerprints unchanged.

---

## 13. Recommended implementation slices
- **Slice 1 — schema + backfill + read-switch (behavior-preserving):** create table, backfill existing
  single image → position 1, switch Admin header/grid, Collector featured, and passport featured to read
  the featured gallery row; **UX identical** (still one featured image, no new controls); legacy columns
  dormant. Gate: migration-parity + all existing rg green + zero mutation.
- **Slice 2 — Admin gallery management:** multi-upload, per-image delete, reorder, featured=position 1,
  Admin gallery UI (featured + thumbnails + reorder + remove). Admin-only.
- **Slice 3 — Collector read-only gallery mirror:** collector featured + thumbnail strip (CSS-only swap),
  owner-authorized ordinal image routes, non-owner denial, byte equality, no leak.
- **Slice 4 (optional, deferred) — cleanup:** drop legacy `image_path`/`image_mime` once the gallery is
  fully proven. Passport stays **primary-only** throughout (decided in Slice 1).

---

**STOP for ChatGPT review.** No migration/table/route/code/file created; deployed `91dfb2a` unchanged;
zero mutation. Awaiting selection of schema options (§2.2 index, §8 limits, §7 primary-only confirmation)
and a GO for Slice 1.

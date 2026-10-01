# SCA MULTI-IMAGE GALLERY — Slice 2 Readiness / Design Audit (READ-ONLY, DO NOT IMPLEMENT)

**Date:** 2026-10-01 · **Baseline:** deployed main `8b03543`, migrations **120**. Slice 1 complete:
`sca_eyewear_item_images` is authoritative; item 3 = one real position-1 image with the legacy mirror
preserved. **Status: AUDIT ONLY — no routes/controller/service/view/test/migration created. Nothing
mutated. Returned for independent review before implementation.**

Slice 2 = **Admin gallery management only**. Collector multi-image UI and any public gallery are explicitly
NOT in scope; passport stays primary-only; Collector keeps resolving the authoritative primary through the
Slice-1 read layer.

---

## 1. Current state (inherited from Slice 1)
- Table `sca_eyewear_item_images` (id, eyewear_item_id FK restrictOnDelete, position, storage_disk,
  storage_path, image_mime, checksum_sha256, byte_size, created_at, updated_at); non-unique index
  `(eyewear_item_id, position)`; featured = lowest `(position, id)`; **no `is_primary`**.
- `CatalogGalleryService`: `primaryImage(itemId, legacyPath?, legacyMime?)`, `hasGalleryRows`, `count`,
  `setSingle` (one position-1 row), `clear`. Returns only `{path,mime}`; never leaks internals.
- Admin routes (`admin.sca.eyewear.*`): `POST {id}/catalog` → `updateCatalog` (ACL `sca.eyewear.catalog`;
  currently SKU **and** single image/remove), `GET {id}/image` → `image` (featured; ACL
  `sca.eyewear.view`). `updateCatalog` mirrors the single image into the gallery (`setSingle`/`clear`) in a
  `DB::transaction` with an orphan guard and still writes the legacy columns.
- View `eyewear/show.blade.php` renders one featured `<img>`/placeholder + an accordion "Edit catalog
  (SKU / image)" form (`multipart/form-data`, `@csrf`, file input + remove checkbox), gated by
  `sca.eyewear.catalog`. Layout = core `<x-admin::layouts>` (no core edit); the core layout exposes
  `@stack('scripts')` and `@stack('styles')`.
- Collector `catalogImageForOwnedItem` and passport `image()` both read `primaryImage(gallery ?? legacy)`.
  Passport presenter/view/allowlist (single `image_url`) and SCA-038 404 are unchanged.
- **Front-end stack:** Krayin admin is Vue 3 (Vite bundle) and already ships `vuedraggable ^4.1.0`. Adding
  a *new* Vue component means touching the core Vite build — **avoid**. The sanctioned, build-free,
  core-edit-free path is a small **vanilla JS** block pushed to `@stack('scripts')`, as progressive
  enhancement over server-authoritative forms (full no-JS fallback).

---

## 2. UI design — ONE coherent catalog manager (replaces the single-image control)
Replace the "Edit catalog (SKU / image)" accordion with a single **Catalog** panel containing:
1. **SKU** field + save (unchanged behavior; still `sca.eyewear.catalog`).
2. **Gallery** block:
   - A large **Featured** image (position 1) with a clear "Featured" badge.
   - A **thumbnail strip** of all images in `(position,id)` order; each thumbnail streams via
     `GET {id}/images/{imageId}` and shows controls: **Make featured** (reorder to position 1),
     **Move left/right** (adjacent reorder), **Delete**.
   - An **Add images** multi-file input (`images[]`) with the limit shown ("up to 8; JPG/PNG/WebP; ≤4 MB");
     disabled/explained when at the cap.
   - Clicking a thumbnail updates the large preview client-side (vanilla JS, cosmetic only — server
     `position` remains the authority). With JS off, every action is a normal form submit, so the page
     still fully works.
- The single-image `image`/`remove_image` inputs are **removed**; all image mutation flows through the
  gallery endpoints. No "old single-image control + competing gallery manager" coexistence.
- Optional enhancement: drag-reorder via the pushed vanilla JS (HTML5 draggable, no library) that, on drop,
  submits the new order to the reorder endpoint. Baseline remains the Make-featured / Move buttons.
- **Pre-impl check:** confirm no admin CSP blocks a `@push('scripts')` inline block (Krayin injects
  `custom_scripts` config, so inline is expected; verify at build time, else move the JS to a pushed
  static asset referenced from the SCA package).

---

## 3. Routes / controller / ACL matrix
All under the existing `admin.sca.eyewear.*` group; `{id}` and `{imageId}` constrained `[0-9]+`; CSRF
applies (admin web group). `{imageId}` is ALWAYS resolved `WHERE id={imageId} AND eyewear_item_id={id}` →
a foreign/unknown image id is a privacy-safe 404; no cross-item manipulation is representable.

| Method & path | Controller | ACL | Purpose |
|---|---|---|---|
| `POST {id}/images` | `storeImages` | `sca.eyewear.catalog` | upload 1..k files (`images[]`), append after current max |
| `POST {id}/images/{imageId}/delete` | `deleteImage` | `sca.eyewear.catalog` | delete one image of this item |
| `POST {id}/images/reorder` | `reorderImages` | `sca.eyewear.catalog` | set full order (make-featured / move) |
| `GET {id}/images/{imageId}` | `imageAt` | `sca.eyewear.view` | stream one gallery image (item-bound) |
| `GET {id}/image` *(kept)* | `image` | `sca.eyewear.view` | stream featured (lowest position) |
| `POST {id}/catalog` *(kept, SKU-only)* | `updateCatalog` | `sca.eyewear.catalog` | SKU only; image inputs removed |

Stream headers: switch all image routes to `Cache-Control: no-store` + `X-Content-Type-Options: nosniff`
(the admin route currently uses `private, max-age=300`; under reorder a cached position/URL could go stale,
so no-store is required for Slice 2). Collector/passport already use no-store.

---

## 4. Service methods (`CatalogGalleryService`)
- `listForItem(itemId): array` — rows ordered `(position,id)` as `{image_id, position}` only (NO
  path/mime/disk/checksum) for the admin view to build stream URLs + controls.
- `imageById(itemId, imageId): ?{path,mime}` — item-bound stream resolver (null → 404).
- `addMany(itemId, array<storedPath,mime,checksum,bytes>): void` — append at `max(position)+1..`, then
  `normalize`. Caller (controller) stores files first and owns the transaction + orphan cleanup.
- `deleteOne(itemId, imageId): ?string` — delete the row, `normalize`, update the legacy mirror; return the
  freed `storage_path` so the controller deletes the file **after** commit.
- `reorder(itemId, array orderedImageIds): void` — validate the set equals EXACTLY the item's current
  image-id set (no foreign/missing), assign `position = 1..N` in that order, update the legacy mirror.
- `normalize(itemId, ?orderedIds=null): void` — renumber to contiguous `1..N` (by `orderedIds` if given,
  else `(position,id)`), then set the legacy mirror to the new position-1 file (or NULL if empty). Single
  source of truth for the contiguous invariant + the mirror.
- Keep `primaryImage` (read), `count`; `setSingle`/`clear` become internal special cases of
  `addMany`/`deleteOne`+`normalize` (or are retired once `updateCatalog` is SKU-only).

### Position-renumber algorithm (non-unique index; contiguous 1..N; MariaDB-safe)
Within one `DB::transaction`: fetch the target order (explicit `orderedIds`, or `(position,id)`); loop
`i=1..N` issuing `UPDATE … SET position=i, updated_at=now() WHERE id=orderedIds[i-1] AND
eyewear_item_id=itemId`. Non-unique index ⇒ no mid-statement uniqueness violation and no two-phase offset
needed. After renumber, set the mirror. **Hard invariant (tested): after any completed mutation an item's
positions are exactly contiguous 1..N, no gaps, no duplicates.**

---

## 5. Legacy mirror rule for N>1 — CONFIRMED rollback-safe
Adopt the operator's rule: **`image_path`/`image_mime` mirror the CURRENT PRIMARY only** (the position-1
file). Updated — in the SAME transaction as the position change — on: upload (if it becomes/forms the
primary), reorder/make-primary (→ new primary), delete-primary (→ promoted next), delete-last (→ NULL).
`normalize()` centralizes this so it cannot drift.

Why it is rollback-safe:
- **Code-only rollback of Slice 2** (table kept): the Slice-1 read layer already serves `primaryImage` =
  lowest position for N rows, so reads keep working regardless of the mirror; behavior is unchanged.
- **Full emergency rollback that DROPS the table**: legacy columns become the only source, and because
  they always point at the current primary's still-on-disk file, every item degrades gracefully to exactly
  its pre-gallery single-image (the primary). Non-primary files become unreferenced on disk (harmless:
  `/storage` denied, not reachable; a reconciliation query can sweep them) — never a dangling reference,
  never a broken image. The primary's file is never deleted while it is the mirror target.
- Requirement: the mirror update MUST be inside the same transaction as every position-changing op (never
  a second, separately-committing step) so a crash can't leave the mirror pointing at a deleted/renumbered
  row.

This is safe; no better transitional rule is needed. (Slice 4 later drops the legacy columns + fallback.)

---

## 6. Orphan / file-failure handling (critical)
- **Upload-many:** store each file to disk FIRST (`$file->store('sca-catalog','public')`); then INSERT all
  rows + `normalize` in ONE `DB::transaction`; on ANY throw, roll back AND delete every file stored in this
  request (collect the stored paths, delete in the `catch`). No partial gallery, no orphan file.
- **Delete-one:** `DB::transaction` deletes the row + renumbers + updates the mirror; the file is deleted
  only AFTER a successful commit (best-effort; failure → logged orphan, never a dangling row). **A file is
  never deleted before its DB row is gone**, so a failed DB op can never destroy a still-referenced image.
- **Reorder:** no file ops; pure position UPDATE in a transaction.
- **Replace/add without disturbing others:** "add" only appends; "delete" removes only the targeted row;
  "reorder" only reassigns positions — unrelated images are never touched or re-stored.
- **Reconciliation (ops, not a job):** read-only query for `sca-catalog/*` files unreferenced by any row.

---

## 7. Validation & limits (unchanged unless a reason emerges — none found)
Max **8** images/item (reject when `existing + uploaded > 8`, before storing any file); **4 MB**/image
(`max:4096`); MIME **jpg,jpeg,png,webp** (stored+streamed, never re-encoded → GD's missing `imagewebp` is
irrelevant). **Decompression/dimension guard:** reject images whose decoded dimensions exceed a ceiling —
**propose 10,000 px per side AND 50 megapixels total** (comfortably allows normal high-res product
photography while bounding memory), checked via `getimagesize` before acceptance; if a webp's dimensions
are unreadable by the installed GD, fall back to `finfo`/reject rather than decode. Record the exact chosen
ceiling in the implementation report + tests.

---

## 8. Security analysis
- **No cross-item manipulation:** every `{imageId}` and every id in a reorder payload is validated against
  the route item (`eyewear_item_id={id}`); foreign/unknown → 404 / reject. The browser never supplies a
  trusted path — only an id that is re-bound server-side.
- **ACL** on every mutation (`sca.eyewear.catalog`) and stream (`sca.eyewear.view`); CSRF on all POSTs.
- **No raw internals leak:** `storage_path`/`storage_disk`/`image_mime`/`checksum`/DB id never reach
  Collector or public HTML/DTO. (Admin internally references the gallery row id in its own staff-only URLs;
  that is acceptable for the IP-restricted admin and still never emits the storage path.)
- **`/storage` stays edge-denied**; all images route-served.
- **Limits** bound upload abuse / decompression bombs (§7).

---

## 9. Provenance isolation — explicitly verified (design-level)
Every Slice-2 operation reads/writes ONLY `sca_eyewear_item_images` and the `sca_eyewear_items` legacy
mirror columns (`image_path`/`image_mime`/`sku`). It never reads or writes `sca_qr_identifiers`,
`sca_certifications`, `sca_certification_events`, `sca_authentications`, `sca_ownership_events`,
`sca_item_current_state`, or `is_production`. Passport eligibility (active QR + issued certification, via
`PassportResolver`) and SCA-038 constant-shape 404 do not consult catalog images, so they cannot change.
Passport remains primary-only (single `image_url`; no public gallery). **Mandatory gate: fingerprints for
QR / certification / certification_events / authentication / ownership / current_state and `is_production`
are byte-identical before/after every multi-image operation (upload-many, reorder, delete, delete-last).**

---

## 10. File scope
- MOD `…/Registry/src/Routes/admin-routes.php` — add the 3 mutation routes + `imageAt`.
- MOD `…/Registry/src/Http/Controllers/EyewearItemController.php` — add `storeImages`, `deleteImage`,
  `reorderImages`, `imageAt`; make `updateCatalog` SKU-only; switch streams to `no-store`.
- MOD `…/Provenance/src/Services/CatalogGalleryService.php` — add `listForItem`, `imageById`, `addMany`,
  `deleteOne`, `reorder`, `normalize` (mirror-aware).
- MOD `…/Registry/src/Resources/views/eyewear/show.blade.php` — one Catalog manager (SKU + gallery
  featured/thumbnails/controls); `@push('scripts')` vanilla enhancement; `@push('styles')` as needed.
- NEW optional `…/Registry/src/Http/Requests/StoreGalleryImagesRequest.php` — upload validation + count cap.
- MOD tests: `CatalogUiTest` (its rg3/rg4 image-via-`/catalog` move to the new endpoints), `CatalogGalleryTest`;
  NEW `CatalogGalleryAdminTest`. No model/migration change (table exists); no Krayin core edit.

---

## 11. Tests / GO-NO-GO gates
- Upload-many: appends in order; `count` grows; 9th rejected; non-image / >4 MB / over-dimension rejected;
  stored files present; **positions contiguous 1..N**.
- Reorder / make-primary: arbitrary order → positions 1..N match; featured = new position-1; mirror updated;
  foreign/missing id in payload rejected with no mutation.
- Delete: gap closed (renumber 1..N); deleting primary promotes next + mirror follows; **deleting the last
  image → gallery empty + legacy mirror NULL + placeholder + image route 404**; file removed only after commit.
- Cross-item: `{imageId}` of another item → 404; reorder with a foreign id → rejected.
- Orphan/failure: simulated DB failure on upload → NO orphan file remains; simulated failure on delete →
  the still-referenced image + its file survive intact.
- Streaming: `GET {id}/images/{imageId}` byte-equals the uploaded file; `no-store`; ACL enforced.
- SKU still editable via `updateCatalog`; the single-image inputs are gone.
- Passport: still primary-only; `image_url` allowlist + SCA-038 200/404 unchanged; reorder that changes the
  primary changes the single passport image (token-bound), still one image.
- Collector: unchanged — resolves the authoritative primary; non-owner 404; no leak.
- No `/storage/sca-catalog`, path, mime, disk, checksum, or DB id in collector/public HTML.
- **Zero QR/cert/auth/ownership/current-state/is_production mutation (fingerprints identical) across every
  op.** Full `tests/Feature/Sca` green.

**GO/NO-GO:** fail closed if any positions non-contiguous/duplicated after an op; if any op mutates a
provenance fingerprint or `is_production`; if a DB rollback leaves an orphan file or a file delete destroys
a still-referenced image; if any raw internal leaks; if `/storage` serves an image; if passport exposes
more than the primary; or if the single-image control still coexists with the gallery.

## 12. Rollback
Code-only revert of the Slice-2 commit restores the Slice-1 single-image admin control; the gallery table
+ Slice-1 read layer keep working (reads lowest position). The legacy mirror (always = current primary)
makes a full table-drop degrade gracefully to single-primary behavior. No migration in Slice 2 (table
already exists), so there is no schema rollback step. Feature branch, `--no-ff`, deploy-gated, push-only
first for independent pre-merge review.

---

**AUDIT ONLY. No implementation. Awaiting independent review + GO for Slice 2. Do not begin implementation,
and do not start Collector gallery UI or any public gallery.**

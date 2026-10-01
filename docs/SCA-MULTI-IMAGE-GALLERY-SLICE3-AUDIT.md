# SCA MULTI-IMAGE GALLERY — Slice 3 Readiness / Design Audit (READ-ONLY, DO NOT IMPLEMENT)

**Date:** 2026-10-01 · **Baseline:** deployed main `0bcdca5`, migrations **120**. Slice 2 complete: Admin
manages the authoritative multi-image gallery (`sca_eyewear_item_images`), position 1 = featured, cap 8,
and Admin/Collector/Passport all consume the featured image. **Status: AUDIT ONLY — no routes/controller/
service/view/test/migration created; zero production changes; ACTIVE/NEXT_TASK stay unpromoted. Returned
for ChatGPT review before implementing Slice 3.**

Slice 3 = make the **Collector item-detail** page show the full Admin-managed gallery (Shopify-like main
image + thumbnails), **read-only**. Collector never uploads/deletes/reorders/sets-featured. No Collector
image table, copy, sync job, or collector-specific featured state. Passport stays primary-only.

---

## 1. Exact paths to reuse (no new storage/state)
- **Authoritative data:** `sca_eyewear_item_images` (unchanged). Ordering `(position,id)`; featured = lowest;
  contiguous 1..N guaranteed by the Slice-2 service.
- **`Sca\Provenance\Services\CatalogGalleryService`** (reuse as-is, no new method required):
  `listForItem(itemId)` → ordered `[{image_id,position}]` (server-side only), `imageById(itemId,imageId)`
  → `{path,mime}` (item-bound), `count(itemId)`, `primaryImage(...)`.
- **`Sca\Collector\Services\CollectionService`** — has `ownedItemId(collectorId,ref)` (current-owner
  authz), `catalogImageForOwnedItem` (featured), `detail()` with `has_image`. Add owner-safe gallery
  reads here.
- **`Sca\Collector\Http\Controllers\CollectionImageController`** — has `show(ref)` (featured, `collector`
  guard, no-store/nosniff, privacy-safe 404). Add the per-ordinal stream here.
- **Routes** `Sca/Collector/src/Routes/collector-routes.php` — `collection/{ref}/image` kept; add one
  ordinal route in the same `collector.auth` group.
- **View** `collection/show.blade.php` left identity panel image block (the deployed `@if has_image … @else
  "No catalog image"` at ~L46-53) + `layout.blade.php` styles. Collector layout = inline styles, web group
  **no CSP**, mobile-first `.wrap-wide` detail page (from the parity slice).

---

## 2. Owner-authorized route for serving image N (ordinal, no DB IDs)
Add: `GET collection/{ref}/images/{n}` → `CollectionImageController::showAt(ref, n)`; `n` constrained
`[0-9]+`; `collector.auth` guard; name `collector.collection.images`. (Distinct from the kept
`collection/{ref}/image` featured route and from `collection/{ref}/documents/{handle}` — no clash.)

Resolution (all server-side, current-owner authorized):
`CollectionService::catalogImageAtOrdinalForOwnedItem(collectorId, ref, n)`:
1. `ownedItemId(collectorId, ref)` → null ⇒ return null (non-owner/previous-owner/guessed).
2. `gallery->listForItem(itemId)` → ordered rows; take the `n`-th (1-based → offset `n-1`); out of range
   ⇒ null.
3. `gallery->imageById(itemId, thatRow['image_id'])` → `{path,mime}`.
Controller streams bytes with **`Cache-Control: no-store` + `X-Content-Type-Options: nosniff`**, or the
identical privacy-safe explicit 404 (`response()->view('sca-collector::collection.not_found', [], 404)`) for
null / missing file — exactly as `show()` does today. **The ordinal maps to the current ordered gallery at
request time**, so Admin reorder/add/delete is reflected automatically (no sync). The DB image id is used
only internally (step 3) and never leaves the server. Ordinal 1 == featured (same bytes as the kept
`…/image` route), so the featured route stays valid for the grid/cards.

Why ordinal, not an opaque id/handle: positions are a visible, non-sensitive property of a gallery the owner
is already looking at (they see N thumbnails in order); an ordinal 1..N resolved under ownership exposes no
internal identifier and needs no handle-encoding. (Contrast documents, which use an opaque `DocumentHandle`
because they are not an ordered visible set.)

---

## 3. Owner-safe gallery DTO shape
In `CollectionService::detail()` add exactly:
- `image_count` => `gallery->count(itemId)` (int ≥ 0).
Keep `has_image` (`image_path !== null`, i.e. gallery non-empty since the legacy mirror tracks the primary).
The Blade derives ordinals as `1..image_count` and builds `route('collector.collection.images', [ref, $n])`.
**Nothing else** is added — no `image_id`, `storage_path`, `storage_disk`, `image_mime`, `checksum`,
internal item id, or position objects reach the DTO/HTML; only the integer count and ordinal route URLs.
(An equivalent shape is `gallery => [1,2,…N]`; `image_count` is the minimal form.)

---

## 4. UX — desktop & mobile (borrow product-gallery only; keep the existing detail page)
The gallery replaces only the left-panel featured-image block; identity info + Overview/Authentication/
Certification/Documents/History tabs are untouched.
- **Large main image:** starts at ordinal 1 (featured). `<img>` with the existing framed style
  (max-width:100%, max-height ~240-320px, rounded border).
- **Thumbnail strip:** one thumbnail per ordinal in Admin order, each streaming
  `…/images/{n}`. Desktop: a row under the main image (wrap allowed). **Mobile: a horizontally scrollable
  strip** (`display:flex; overflow-x:auto; -webkit-overflow-scrolling:touch; flex-wrap:nowrap`) so it never
  causes horizontal PAGE overflow and stays thumb-friendly — **recommended over wrapping** (wrapping many
  thumbs grows vertical height and crowds the mobile identity panel; a contained scroll strip is the common
  product-page mobile pattern). The strip lives inside the fixed-width left panel, so page width is bounded.
- **Selected thumbnail** gets a visible active ring/border.
- **Interaction (progressive JS, narrowly scoped, no framework):** each thumbnail is
  `<a href="{ordinal image url}" data-main>` wrapping the thumb `<img>`. A single small inline
  `@push`/`<script>` (collector web group has no CSP, so inline is allowed) adds one delegated click
  listener that `preventDefault()`s and swaps the main `<img>.src` to the thumbnail's target. **No-JS state:**
  the main image is the featured image and the thumbnail strip is fully visible; with JS off, clicking a
  thumbnail navigates to that ordinal's full image (a sensible fallback), and the first-image/featured view
  is always correct. **Selection is presentation-only** — it changes the browser view, never position/
  featured/DB/mirror/catalog state.
  - Alternative (zero-JS) considered: the CSS-only radio + `:checked ~` technique already used for the tabs,
    rendering N full `<img>` toggled by CSS. It works with no JS and no CSP concern but loads all N
    full-size images and is heavier for a "large main" layout. **Recommend the progressive-JS main-swap**
    (one listener, ~10 lines) as cleaner and lighter; fall back to CSS-only only if JS is disallowed.

## 5. Zero / one / multiple states
- **0 images** (`image_count == 0`): keep the deployed **"No catalog image"** placeholder; no strip, no JS.
- **1 image**: show the single image cleanly (main only); **no thumbnail strip, no switching controls**.
- **≥2 images**: main + thumbnail strip + progressive switching.

## 6. Behavior after Admin add / reorder / delete / make-featured (no sync)
Collector reads the live gallery every request: `image_count` and each ordinal resolve against the current
ordered rows. Admin **add** → higher ordinal appears next request; **delete** → ordinal disappears + count
drops + renumber (contiguous) means ordinals stay 1..N; **reorder/make-featured** → ordinal 1 (main) and
the strip order change automatically. No collector-side synchronization exists or is added.

---

## 7. Authorization / privacy boundaries
- Every image (main + each thumbnail) served ONLY via the `collector.auth` ordinal route, authorized by
  **current ownership** (`ownedItemId`); never `/storage`.
- Non-owner / previous-owner-after-transfer / guessed ref / out-of-range ordinal / missing file → the SAME
  privacy-safe explicit 404 `show()` uses today (never `abort()` → Krayin masks to 200).
- DTO/HTML expose only the integer count + ordinal route URLs — no DB id, storage path/disk, MIME column,
  checksum, internal item id, or other server field.
- Collector cannot mutate: no upload/delete/reorder/make-featured routes or forms are added to the collector
  surface. Viewing/switching performs zero writes.

## 8. Caching
Ordinal image responses: `Cache-Control: no-store` + `X-Content-Type-Options: nosniff` (identical to the
featured route) so a reordered/replaced/removed image is never served stale. The detail HTML is dynamic
(no caching change).

---

## 9. Public Passport — unchanged (confirmed)
Slice 3 touches only the Collector surface. Passport keeps the single `image_url` (featured) via
`PassportPresenter`/`PassportController::image`, the `PublicAllowlist` FIELDS are unchanged (no `image_urls`
key), and SCA-038 constant-shape 404 is untouched. **No public gallery; no allowlist/SCA-038 change.**

## 10. Exact file scope (view-only + read-only additions; NO migration)
- MOD `Collector/src/Services/CollectionService.php` — add
  `catalogImageAtOrdinalForOwnedItem(collectorId, ref, n)` (reusing `ownedItemId` + `listForItem` +
  `imageById`); add `image_count` to `detail()`. (Reuses the injected `CatalogGalleryService`.)
- MOD `Collector/src/Http/Controllers/CollectionImageController.php` — add `showAt(ref, n)` (keep `show`).
- MOD `Collector/src/Routes/collector-routes.php` — add `GET collection/{ref}/images/{n}`.
- MOD `Collector/src/Resources/views/collection/show.blade.php` — gallery (main + thumbnail strip + a small
  `@push('scripts')`/inline progressive swap); MOD `…/views/layout.blade.php` — thumbnail-strip styles
  (responsive horizontal scroll).
- MOD tests: `CollectorCatalogTest`, `CollectorItemDetailParityTest`; NEW `CollectorGalleryTest`.
- No `CatalogGalleryService`/Provenance change; no model; **no migration** (expectation holds); no Krayin
  core/vendor edit; no infra/DNS/Caddy/SMTP/:8080 work.

## 11. Regression tests / GO-NO-GO gates
- **0 images** → placeholder, no strip, ordinal route 404.
- **1 image** → single main, no thumbnail strip; ordinal 1 streams bytes.
- **≥2 ordered images** → `image_count` correct; ordinals 1..N each stream the EXACT stored bytes of the
  Admin image at that position (byte-equality per ordinal); ordinal 1 == featured bytes.
- **Thumbnail/main URLs contain no DB id or storage path** (HTML asserts only `/collector/collection/{ref}/
  images/{n}`; never `sca-catalog`, `/storage/sca-catalog`, `storage_path`, `image_mime`, `checksum`,
  `sca_eyewear_item_images`, or a numeric gallery id).
- **Admin reorder reflected automatically** → after a reorder, collector ordinal 1 (and the strip order)
  follow on the next request, no collector action.
- **Admin delete reflected automatically** → the deleted image's ordinal disappears; count drops; remaining
  ordinals stay contiguous and stream correctly.
- **Current owner 200**; **non-owner & previous-owner-after-transfer privacy-safe 404**; guessed/unknown ref
  404; out-of-range ordinal 404.
- **No `/storage` leak**; **no internal gallery metadata leak** (as above).
- **Viewing/switching causes zero mutation**: QR/cert/auth/ownership/current-state fingerprints and
  `is_production` identical before/after loading + switching; gallery rows/positions/legacy mirror unchanged.
- **Passport still primary-only**: single `image_url`; SCA-038 200/404 unchanged.
- Full `tests/Feature/Sca` green.

**GO/NO-GO:** fail closed if any ordinal exposes a DB id/path/MIME/checksum; if a non-owner/previous-owner can
fetch any ordinal; if `/storage` serves a gallery image; if viewing/switching mutates any gallery/legacy/
provenance state; if Admin reorder/add/delete does NOT reflect automatically; if the passport gains a gallery
or its allowlist/SCA-038 changes; or if any schema migration appears.

## 12. Rollback
View-only + read-only additions; **no schema/migration**. Reverting the Slice-3 commit restores the Slice-2
collector (single featured image) with the gallery table and Admin behavior untouched. Feature branch,
`--no-ff`, deploy-gated, push-only first for independent pre-merge review.

---

**AUDIT ONLY. No implementation, no production change. ACTIVE=NONE / NEXT_TASK=NONE (unpromoted). Awaiting
ChatGPT review + GO before implementing Slice 3. Do not add a public gallery or change passport/SCA-038.**

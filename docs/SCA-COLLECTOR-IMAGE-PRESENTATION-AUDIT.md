# SCA-COLLECTOR-IMAGE-PRESENTATION — Diagnostic Audit (READ-ONLY)

**Date:** 2026-10-01 · **Deployed:** `4af8a65` (collector item-detail parity live). **Read-only — nothing changed;
zero mutation** (QR fp `a920dc1c…`, migrations 119, both items back to `image_path` NULL after a net-zero probe).

## Question

The collector item-detail page doesn't visibly show the item's catalog image. Audit which case applies:
(a) `image_path` exists + Admin shows it but Collector doesn't → **defect** in the collector image path; or
(b) `image_path` is NULL → **no defect**; add a polished "No image" placeholder to the collector left panel.

## Finding — case (b). NOT a defect in the collector image path.

**1. Both production items have NO catalog image.** `items_with_image = 0 of 2`:
- item 1 `SCA-3C35D669ACBE` — `image_path = NULL`, `sku = NULL`, unowned.
- item 3 `SCA-F1B792AE4745` — `image_path = NULL`, `sku = NULL`, owned by collector 1.

No catalog image has ever been uploaded for either item (the Slice-1 staff catalog-edit was never used on them).

**2. The premise "Admin shows the image but Collector doesn't" does not hold here.** With `image_path` NULL, **Admin
also shows no image** — `eyewear/show.blade.php` renders its **"No catalog image"** placeholder
(`@if ($item->image_path) <img …> @else <div …>No catalog image</div> @endif`). So *neither* surface displays an actual
image, because there is none.

**3. The collector image rendering + authorization path is CORRECT (proven).** A net-zero probe set `image_path` on
item 3, rendered the collector detail as its owner (collector 1), then removed it:
- the collector detail **did** render `<img src="/collector/collection/{ref}/image">` (`collector-detail-renders-img =
  YES`), and
- the owner-authorized `CollectionImageController::show` **streamed the bytes** (`status 200`, `Content-Type image/png`).
So when an image exists, the collector shows it through the existing owner-authorized route — there is **no rendering or
authorization defect** to fix.

**4. The real gap = a missing placeholder (presentation only).** The deployed collector parity view shows the image
**only** when present and renders **nothing** otherwise:
`@if (!empty($item['has_image'])) <img …> @endif` — there is **no `@else` placeholder**. Admin renders a "No catalog
image" box in the same situation. So, for the current NULL-image items, the collector left panel simply has no image
slot at all, which reads as "the image is missing."

## Recommendation (case-b fix — NOT applied here, audit-only)

Add a polished **"No image"** placeholder to the collector left panel's image slot (an `@else` branch), consistent with
the Admin/catalog placeholder, so the layout always shows an image *or* a placeholder. **Do not** invent/create an
image, and keep using **only** the existing owner-authorized `collector.collection.image` route — no `/storage`, no
`image_path`/`image_mime` exposure, no weakening of ownership authorization. (Once a catalog image is uploaded for an
item via the existing Slice-1 staff catalog-edit, both Admin and Collector will display it automatically — already
proven in the probe.)

Scope would be **view-only** (`collection/show.blade.php` `@else` placeholder, matching the existing left-panel style)
plus a regression asserting the placeholder renders when `has_image` is false and the real image when true. No schema/
route/ACL/service/controller change; no QR/provenance/ownership/certification mutation.

**Audit only — reported before any change, per the directive. Awaiting go for the placeholder fix.**

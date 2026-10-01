# SCA Admin Registry Catalog Grid UX refinement — Readiness / Code Audit (READ-ONLY, DO NOT IMPLEMENT)

**Date:** 2026-10-01 · **Baseline:** deployed main `5db1ab0`, migrations 120. **Status: AUDIT ONLY — no
code changed; zero production change. Returned for review before implementing.**

Objective: make `/admin/sca/eyewear` (the registry index) look like a polished Shopify-style catalog grid,
**presentation only**, preserving all SCA-051 registry behavior (filters/search/sort/QR-lookup/pagination).

---

## 1. Current state (audited)

**Controller `EyewearItemController::index()` (L59-151)** already passes everything the view needs — **no
data change is required.** `$items = query->paginate(20)->withQueryString()` where each row selects
`sca_eyewear_items.*` (so `image_path`, `image_mime`, `sku`, `brand`, `model_name`, `public_ref`,
`intake_type`, `created_at`) **plus** presence/display projection columns `cs_lifecycle`, `cs_registry`,
`cs_owner`, `cs_cert` (certification id → presence only), `cs_qr` (active QR id → presence only). Filters/
search/cert-lookup/date-range/owned/allowlisted-sort + stable id tiebreaker + `paginate(20)` are all intact
and are **out of scope to change**.

**View `Registry/.../eyewear/index.blade.php` (the only file that renders this)** already is a Tailwind
card grid: `grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4`; each card = a fixed `h-40`
image area (authorized route `route('admin.sca.eyewear.image', $item->id)` with `object-contain`, else a
"No image" placeholder in the same `h-40` box) → brand/model → `SKU:` → `public_ref` → a status row →
`View item →` pinned via `mt-auto`. QR-lookup form (POST `admin.sca.eyewear.lookup`, field `qr`) + the GET
filter form (fields `search, cert_number, intake_type, registry_status, lifecycle, owned, date_from,
date_to, sort, dir` + Apply/Reset) + `{{ $items->links() }}` pagination.

**Current rendering cause of the "cramped raw look":** the status row is tiny `text-[11px]` spans with
minimal padding (`px-1.5 py-0.5 rounded`) showing **raw lowercase codes** (`{{ $item->cs_lifecycle }}`,
`{{ $reg }}`) — so lifecycle/registry read as raw enum values, not pills; the image area is a flat
`bg-gray-50` box with a tiny "No image"; and the filter form is one long `flex-wrap` row of ~10 controls
with no grouping, so it looks cramped. The structure (hierarchy, equal `h-40` image box, action at bottom,
responsive cols) is largely right already — this is a **styling** refinement, not a rebuild.

**The featured image is already correct & authorized:** `route('admin.sca.eyewear.image', id)` streams the
**gallery primary** (Slice-1 read-switch: `CatalogGalleryService::primaryImage(gallery ?? legacy)`), never
`/storage`. `@if ($item->image_path)` gates the image — and because the legacy mirror always equals the
current primary (Slice-2 `normalize()`), `image_path != null` ⇔ a gallery primary exists. **No new image
source, table, copy, or sync is needed or proposed.**

---

## 2. Can it be done view-only? YES — `index.blade.php` (+ its test) only
No controller/service/DTO/route/data change. The whole refinement is markup/CSS in `index.blade.php`, plus
a small **scoped `@push('styles')`** CSS block (the admin core layout exposes `@stack('styles')` at
`packages/Webkul/Admin/.../layouts/index.blade.php:81`). The existing admin image route and `image_path`
gate are reused unchanged.

---

## 3. Proposed markup/CSS structure (presentation only)
- **Equal featured-image canvas on every card:** one shared canvas wrapper with a FIXED aspect/height (keep
  `h-40`, or an `aspect-[4/3]`) + `display:flex; align-items:center; justify-content:center; background;
  padding`. Image: `max-height:100%; max-width:100%; object-fit:contain` (not `w-full h-full`, so eyewear is
  never cropped/stretched). Placeholder: the SAME canvas box with a centered muted icon + "No image".
  **Cards with and without an image get identical image-area dimensions** (the canvas is fixed regardless of
  content).
- **Clean status pills** (lifecycle, registry, Certified, QR): one pill class —
  `inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-medium` with consistent `gap` — and
  humanized text (lifecycle Title-Case, registry `ucfirst`). Tones: lifecycle neutral (slate); registry
  green when `normal`/`recovered`, red when adverse (`disputed/lost/stolen/retired/invalidated`); Certified
  emerald (only when `cs_cert`); QR blue (only when `cs_qr`). Presence-only — never the cert/QR id value.
- **Card:** `flex flex-col` with `rounded-xl border shadow-sm hover:shadow-md`; body `p-4 gap-1.5`; order
  brand/model (semibold) → SKU (muted) → SCA ref (mono muted) → pill row → **View item** pinned bottom
  (`mt-auto`, styled as a subtle full-width button/link). Equal card height comes from CSS-grid row stretch
  (default `align-items:stretch`) + `mt-auto` action.
- **Responsive grid:** keep `grid-cols-1 sm:2 lg:3 xl:4` (reduce cleanly; the grid wraps so there is no
  page-level horizontal overflow); consistent `gap`.
- **Controls:** group the QR-lookup and the filter/search/sort form into a light bordered panel
  (`rounded-lg border bg-gray-50 p-3`) with aligned `items-end gap-3` rows so they read as a toolbar. **Every
  field name, option, value, and the Apply/Reset/Find-item behavior stays byte-for-byte** — only wrapper
  spacing/alignment changes.

---

## 4. KEY TECHNICAL RISK — Tailwind class compilation (drives the recommendation)
Krayin's admin CSS is a **pre-compiled Tailwind build**; a brand-new arbitrary/utility class that the admin
build didn't scan from SCA views may **silently not apply**. The current blade already renders with
`grid-cols-*`, `h-40`, `text-[11px]`, `bg-red-100`, etc., so those are safe; but newly introduced classes
(e.g. `aspect-[4/3]`, `rounded-full`, new color shades) are **not guaranteed** to be in the compiled CSS.
**Recommendation:** put the custom pill/canvas/card styling in a scoped **`@push('styles')` inline `<style>`
block** (plain CSS, guaranteed to apply, no build step — exactly the pattern used for the collector gallery
and QR), and reuse only already-present Tailwind utilities for layout. This is the smallest *safe* scope and
removes the compilation risk. No Krayin core/Tailwind-config edit.

---

## 5. Regression plan (strengthen `tests/Feature/Sca/CatalogGridTest.php`; no new file needed)
Existing rg1-rg7 already cover grid container, brand/model, SKU, ref, Certified/QR badges, no-image
placeholder, authorized-route-not-`/storage`, SCA-051 search+intake filter, pagination (20/page, page=2),
ACL (redirect/403), zero mutation. Strengthen/add:
- **Equal image canvases:** both an image card and a no-image card render the SAME canvas wrapper class/
  dimensions (assert the shared canvas class appears for both; image card has the `object-contain` routed
  `<img>`, no-image card has the placeholder — same box).
- **Featured-image route use:** card image `src` = `/admin/sca/eyewear/{id}/image`; never `/storage` or a raw
  `sca-catalog/...` path (rg3 extended).
- **No-image state:** placeholder present, no `<img>` for that card.
- **Product hierarchy order:** brand/model before SKU before `public_ref` before the pill row before
  `View item` (assert by ascending `strpos`).
- **Badge/pill structure:** lifecycle + registry pills always; Certified pill iff `cs_cert`; QR pill iff
  `cs_qr`; all carry the shared pill class; humanized (not raw-lowercase) label.
- **Responsive-grid contract:** container keeps `grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4`.
- **Controls preserved:** every control present with unchanged `name`s — `search, cert_number, intake_type,
  registry_status, lifecycle, owned, date_from, date_to, sort, dir`, the QR-lookup form (`qr` + lookup
  action), Apply/Reset, and `$items->links()` pagination; SCA-051 filter/search still narrows the set
  (rg4/rg5 retained).
- **No `/storage`/raw-path leak; zero mutation** (rg7 retained; fingerprints + is_production unchanged).

## 6. Risks & mitigations
1. **Tailwind arbitrary-class compilation** (§4) → use `@push('styles')` inline CSS for custom bits; reuse
   known-working utilities only. Primary risk; fully mitigated.
2. **Dark-mode parity** — the card currently has `dark:` variants; the inline CSS should honor dark mode (or
   keep neutral tokens) so the admin dark theme doesn't break. Mitigate by scoping light/dark in the inline
   block or reusing existing `dark:` utilities.
3. **Equal-height cards** rely on grid row-stretch; a very long pill wrap could still vary height — mitigate
   with a min-height on the body or clamping (presentation only).
4. **Behavior drift** — the single biggest "don't": do not rename/reorder/remove any filter field or change
   `paginate(20)`/sort allowlist. Enforced by retained rg4/rg5 + the new controls-preserved assertions.
5. **No regression to SCA-051** — all query logic stays in the controller (untouched).

## 7. GO / NO-GO recommendation
**GO for a VIEW/CSS-only implementation scoped to `index.blade.php` + `CatalogGridTest.php`**, using a
scoped `@push('styles')` inline CSS block for the pill/canvas/card polish and reusing existing Tailwind for
layout. No controller/service/data/route/ACL/schema change; no new image source; authorized image route and
`image_path` gate reused; all SCA-051 filter/search/sort/QR-lookup/pagination semantics preserved. Hard
boundaries (no schema/gallery/upload/featured/Passport/Collector/provenance/`/storage`/core change) are all
satisfiable within this scope.

**AUDIT ONLY. Awaiting review + GO before implementing. Smallest safe scope = `index.blade.php` (+ its
test); no controller/data change needed.**

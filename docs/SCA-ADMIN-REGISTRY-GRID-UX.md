# SCA Admin Registry Catalog Grid UX refinement (VIEW/CSS only) — PUSH ONLY

**Date:** 2026-10-01 · **Base:** deployed main `5db1ab0` (migrations 120). **Candidate HEAD:** `380116d`
on branch `sca-admin-grid-ux`. **Status:** PUSH ONLY — not merged, not deployed. Awaiting independent
pre-merge review. Readiness GO: gov `e6f5313`.

## Scope / commit
Presentation only. 1 commit; **exactly 2 authorized files** — `Registry/.../eyewear/index.blade.php` and
`tests/Feature/Sca/CatalogGridTest.php`. No controller/service/DTO/route/ACL/schema/migration change; no
gallery/upload/delete/reorder/featured-semantics change; no Collector/Passport/provenance change; no
`/storage` or raw-path exposure; no Krayin core/vendor edit.

## UX delivered
- **Scoped styling, no Admin-wide impact:** a `@push('styles')` block whose every selector is prefixed
  `.sca-registry` (plus `.dark .sca-registry` dark-mode variants); layout reuses known-working Tailwind
  utilities. (Avoids the pre-compiled-Tailwind risk flagged in the audit.)
- **Equal fixed product-image canvas:** every card uses a 180px `object-fit:contain` canvas — identical
  image area for image and no-image cards; eyewear never cropped/stretched; card never jumps on differently
  sized uploads. The featured image uses the existing **authorized Admin image route** (gallery primary via
  the Slice-1 read-switch), gated by `image_path` — no new source; **no `/storage`**.
- **Clean status pills:** `rounded-full`, consistently spaced, human-readable lifecycle (Title-Case) /
  registry (`ucfirst`, red when adverse) / Certified (green) / QR (blue) — presence-only, never an id value.
- **Consistent cards:** `rounded-xl`, subtle border/shadow, hierarchy brand/model → SKU → SCA reference →
  pills → **View item** pinned at the bottom (`mt-auto`); equal height via grid row-stretch.
- **Responsive grid:** `grid-cols-1 sm:2 lg:3 xl:4`, no page-level horizontal overflow.
- **Grouped toolbar:** the QR-lookup (POST) + filter/search/sort (GET) forms wrapped in a scoped
  `.sca-toolbar` panel. **Every field name, option, value, placeholder, method, action, and the Apply/Reset/
  Find-item behavior is byte-identical;** `paginate(20)` + `$items->links()` unchanged. Index stays
  read-only and shows ONLY the featured/position-1 image (no gallery switching/thumbnails on the index).

## Tests (CatalogGridTest 10; full tests/Feature/Sca 722/3967; php -l clean)
rg1-rg7 retained. Added:
- **rg8** — equal fixed canvas for image and no-image cards (`class="sca-canvas"` ×2), featured route for
  the image card, placeholder for the no-image card, canvas CSS `height:180px` + `object-fit:contain`,
  page-scoped `.sca-registry` selectors, no `/storage/sca-catalog`.
- **rg9** — product hierarchy order (`sca-title` < `sca-sku` < `sca-ref` < `sca-pills` < `sca-view`); pill
  structure (`sca-pill-cert">Certified`, `sca-pill-qr">QR`, lifecycle `sca-pill-neutral">Certified`
  humanized, NOT the raw `CERTIFIED` enum in the pill).
- **rg10** — responsive grid classes present; all filter controls (`search, cert_number, intake_type,
  registry_status, lifecycle, owned, date_from, date_to, sort, dir`) + QR-lookup (`qr` + lookup action) +
  `.sca-toolbar` + Apply/Reset preserved.

## Push-only + restoration evidence (production remains on 5db1ab0)
Candidate pushed to `origin/sca-admin-grid-ux` (HEAD `380116d`, base `5db1ab0`). Pilot restored to main
`5db1ab0` (working tree reverted; `--no-dev`; caches cleared; kr-app healthy on `195.26.255.80:8080`). No
candidate CSS/markup live (`.sca-registry .sca-card` and `class="sca-card"` in the live index = 0). Prod
migrations **120**; FP_QR `a920dc1c…`; is_production 0,0; item 3 still has its **3 operator gallery images,
untouched** (this task never touched gallery data); verify. passport 200; smsrocket 302.

**PUSH ONLY — not merged/deployed. Candidate `380116d` returned for independent pre-merge review.**

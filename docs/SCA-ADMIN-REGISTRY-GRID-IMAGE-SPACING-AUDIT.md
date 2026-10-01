# SCA Admin Registry Grid — image sizing + card spacing micro-refinement — Audit (READ-ONLY)

**Date:** 2026-10-01 · **Baseline:** deployed main `974cbfc`, migrations 120. **Status: AUDIT ONLY — no
code changed; zero production change. Returned for review before implementing.**

Scope requested: a very small VIEW/CSS-only tweak to the just-deployed catalog grid — make the featured
image fill more of the fixed 180px canvas (no crop/distortion), and add slightly more vertical spacing in
the card info section. Keep everything else (card dimensions, responsive grid, toolbar, pills, placeholder,
authorized image route, all functionality) unchanged.

## Current deployed CSS (the only relevant rules, in the `@push('styles')` block of `index.blade.php`)
```
.sca-registry .sca-canvas     { ...; height: 180px; padding: 12px; ... }
.sca-registry .sca-canvas img { max-width: 100%; max-height: 100%; object-fit: contain; }
.sca-registry .sca-body       { display: flex; flex-direction: column; gap: 5px; padding: 14px; flex: 1 1 auto; }
.sca-registry .sca-pills      { ...; gap: 6px; margin-top: 6px; }
.sca-registry .sca-foot       { margin-top: auto; padding: 11px 14px; ... }
```

## Cause of "image too small"
The canvas is 180px tall but has **`padding: 12px`** on all sides, so the `object-fit:contain` image is
constrained to a ~156px-tall × (cardwidth−24px) box — leaving a visible empty margin around small/portrait
eyewear photos. The fix is simply to shrink that padding (the canvas height and `object-fit:contain`, which
guarantee equal canvases and no crop/distortion, stay exactly as they are).

## Recommended change — EXACTLY 2 CSS value edits (scoped block only; no markup, no behavior)
1. **Bigger usable image area** — `.sca-registry .sca-canvas` `padding: 12px` → **`padding: 6px`**. The
   canvas stays `height: 180px` and the image stays `object-fit: contain` (so no crop, no distortion, and
   every card still has the identical image area); the image just gains ~12px in each dimension (≈156→168px
   tall) and visually fills more of the canvas. (A 4px padding is an option for an even larger image; 6px
   keeps a small, even breathing margin — recommended.)
2. **Slightly more info-section spacing** — `.sca-registry .sca-body` `gap: 5px` → **`gap: 8px`** (more even
   space between brand/model, SKU, SCA reference, and the pills). Optionally nudge
   `.sca-registry .sca-pills` `margin-top: 6px` → `8px` for consistent rhythm. The View-item action stays in
   `.sca-foot` (pinned via `margin-top:auto`), so it remains naturally at the bottom; equal card heights are
   still enforced by the CSS-grid row stretch.

Net: cards grow only by the few px of added body spacing (uniform across all cards — equal heights
preserved); the fixed 180px image canvas and the responsive grid are unchanged.

## Explicitly unchanged
Card/canvas dimensions (180px canvas, fixed), responsive `grid-cols-1/2/3/4`, the grouped QR-lookup +
filter/search/sort toolbar, pills, "No image" placeholder, the authorized Admin image route (gallery
primary, never `/storage`), and all functionality. No controller/service/route/gallery/schema/migration/
Collector/Passport/provenance/infra change. No gallery data touched.

## File scope & tests
- `Registry/.../eyewear/index.blade.php` — the 2 CSS values above (scoped `.sca-registry` block). No markup.
- `tests/Feature/Sca/CatalogGridTest.php` — existing rg8 asserts `height: 180px` + `object-fit: contain`
  (both preserved, so it stays green). **Recommended:** add one assertion pinning the new
  `padding: 6px` + `gap: 8px` so the intent is regression-locked (optional, view-only). Full
  `tests/Feature/Sca` re-run + `php -l` as usual.

## Risk / recommendation
Trivial, presentation-only; equal canvases and no-crop guaranteed by the unchanged `height`/`object-fit`;
dark mode unaffected (padding/gap aren't themed). **Recommendation: GO for the 2-value VIEW/CSS edit**
(push-only → review → governed merge/deploy), scoped entirely to `index.blade.php` (+ the optional test
assertion).

**AUDIT ONLY. Awaiting review + GO before implementing.**

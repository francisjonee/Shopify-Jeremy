# SCA-COLLECTOR-IMAGE-PRESENTATION — placeholder follow-up (VIEW-ONLY)

**Date:** 2026-10-01 · **Base:** deployed main `4af8a65` (collector item-detail parity).
**Scope:** view-only. **Status:** PUSH ONLY — not merged, not deployed. Awaiting pre-merge review.

## Intent

The collector item-detail left identity panel must *always reserve the image area*. The diagnostic
audit (gov `1dfaf48`, case **(b)**) established that both production items have `image_path = NULL`,
so the collector showed nothing where the image slot should be (no `@else`), while Admin renders a
"No catalog image" placeholder in the same situation. The owner-authorized image rendering path was
proven correct — the only gap was the missing placeholder (presentation only).

## Change

Single view edit — `packages/Sca/Collector/src/Resources/views/collection/show.blade.php`:

- `has_image = true` → the **existing** `<img>` is preserved verbatim, sourced only from the
  owner-authorized `route('collector.collection.image', …)` — never `/storage`, `image_path`, or
  `image_mime`.
- `has_image = false` → a polished **"No catalog image"** placeholder (dashed-border 180px box,
  muted text), visually consistent with the Admin/catalog placeholder.

No service / controller / DTO / schema / route / ACL change. The two-panel + CSS-only-tabs structure
and responsive behavior are untouched. Authorization is unchanged (owner-only `collector.collection.image`).

## Regression

`tests/Feature/Sca/CollectorItemDetailParityTest.php` — new `rg9`:

1. **NULL image →** "No catalog image" placeholder present, and **no** `/collector/collection/{ref}/image`
   `<img>` emitted.
2. **image present →** the owner-authorized `/collector/collection/{ref}/image` URL is rendered and the
   placeholder is **absent**.
3. **privacy/staff-only exclusions intact →** the raw stored path (`sca-catalog`), its disk URL
   (`/storage/sca-catalog`), and the `image_mime` column never appear in the HTML. (A core
   `/storage/configuration/` CSS selector for the CRM logo is unrelated framework output and is
   correctly out of scope.)
4. **zero mutation →** provenance/QR/ownership fingerprint identical before/after viewing with an image set.

## Results

- Focused `CollectorItemDetailParityTest`: **9 passed / 58 assertions** (rg1–rg9).
- Full `tests/Feature/Sca`: **688 passed / 3684 assertions** (687 + rg9).
- `php -l` clean on the modified view.
- Diff: 2 files, +36 lines (view +5, test +31). No other files touched.

## Invariants (to re-confirm at deploy, not changed here)

QR fingerprint `a920dc1c…`, migrations 119, `is_production` 0,0, SCA-038 Option-A public passport,
`/storage` edge-denied, MariaDB private, sca_edge persistence. Both prod items remain `image_path` NULL —
once a catalog image is uploaded via the existing Slice-1 staff catalog-edit, both Admin and Collector
display it automatically (already proven in the audit probe).

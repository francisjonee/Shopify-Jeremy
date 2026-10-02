# SCA Public Passport — Mobile UX (PUSH-ONLY)

**Date:** 2026-10-02 · **Base:** deployed main `cbde6d2`, migrations **120**.
**Status: IMPLEMENTED + TESTED + PUSHED. NOT merged, NOT deployed. For independent pre-merge review.**
Implements `SCA-PUBLIC-PASSPORT-MOBILE-UX-AUDIT.md` (gov `2127f89`). Presentation / view-only.

## Candidate
- **SHA:** `c7b29c4` · **Branch:** `origin/sca-passport-mobile-ux`
- **Base / merge-base:** `cbde6d2` (verified), 1 commit, **3 files** (+209/−31).
- **Scope:** `Passport/Resources/views/passport/layout.blade.php`, `.../show.blade.php`, new
  `tests/Feature/Sca/PublicPassportMobileUxTest.php`.
- **No** presenter, `ItemStateLabels`, `PublicAllowlist`, `PassportResolver`, middleware/CSP, route, migration,
  schema, ACL, or core/vendor change (verified: all forbidden-change guards 0).

## What changed (view/CSS only)
1. **Detail rows → classes.** The inline `$row`/`$rowLabel`/`$rowValue` strings in `show.blade` are replaced by
   `.row`/`.row-label`/`.row-value` defined in the **existing** `layout.blade` `<style>` block (an inline
   `style=""` cannot carry a media query). Desktop/tablet keep the two-column label-left/value-right layout
   unchanged — the class values mirror the previous inline styles.
2. **Mobile stacking `@media (max-width: 480px)`:** rows become `flex-direction:column; align-items:flex-start`
   (label over value), the value is left-aligned and full-width, and `.card`/row padding is modestly tightened
   (22→18px / 11→9px). The card is capped at 560px, so any viewport ≥481px renders the unchanged desktop layout.
3. **Defensive wrapping:** `.row > * { min-width:0 }` + `.row-value { overflow-wrap:anywhere }` so long
   certification numbers / brands / models / registry descriptions wrap inside the column instead of forcing
   horizontal overflow (at all widths — improvement, no regression for normal values).

**Explicitly unchanged:** the CLEAR wording "No adverse reports on the SCA registry" (ItemStateLabels untouched);
logo/header, "Authenticated & Certified" badge, provenance summary, SCA-reference block, featured image, the
adverse warning banner and its dominance/order **before** the authenticity block, the trust/explainer copy, and the
footer. No JavaScript; no Tailwind/Vite/front-end rebuild (hand-written inline CSS; CSP `style-src 'unsafe-inline'`
already permits the `<style>` block, no `script-src` relaxation).

## Tests
- **New `PublicPassportMobileUxTest` (9):** rows use `class="row"/row-label/row-value` and carry no inline flex
  style; `@media (max-width: 480px)` with the `flex-direction:column` stacking rule + mobile left-align is
  delivered; `overflow-wrap:anywhere` + `min-width:0` present; a very long unbroken brand/model + certification
  number renders at 200; CLEAR wording unchanged; adverse warning still before authenticity (`assertSeeInOrder`);
  no `<script>` + CSP unchanged (no `script-src`); no `/storage`/`configuration/`/token/collector leakage on an
  adverse page; SCA-038 valid 200 / unknown 404 / malformed 404 unchanged; GET mutates nothing.
- **Results:** focused passport suites 55/55; **full `tests/Feature/Sca` → 793 passed (4362 assertions), 0
  failed.** `php -l` clean on the changed PHP/test.

## Restoration + zero-production-mutation proof
Pilot restored to deployed main `cbde6d2` (`git checkout main`, tree clean, `composer install --no-dev`,
`config:clear`+`route:clear`). Candidate **not live**: live tree still has the inline `style="{{ $row }}"` on all
11 detail rows, no `@media (max-width: 480px)` in `layout.blade`, and `PublicPassportMobileUxTest.php` absent.
Runtime: the live `/p/<valid>` page contains **0** occurrences of `max-width: 480px`.
- `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4` (== baseline) · migrations 120 · gallery 3.
- Smoke: loopback `:8080 → 302`; edge `/p/<valid> → 200`, `/p/<bogus> → 404`, `/storage/x → 404`.

## Boundaries honored
No `PassportResolver` / 200-vs-404 / SCA-038 / status-cert-auth-ownership semantics / QR / routes / ACL / schema /
services / `PublicAllowlist` / CSP / `/storage` / logo mechanism / `SCA_PUBLIC_PREVIEW` / Admin / Collector / env /
infra change. Retired/Invalidated 200-vs-404 remains deferred. Branch from exactly `cbde6d2`; **COMMIT + PUSH ONLY
— not merged, not deployed.**

## Next
Independent pre-merge review of `c7b29c4`. On GO: governed `--no-ff` merge + `scripts/deploy-preview.sh`, then
closeout. (CLEAR-label wording evaluation deferred to view the corrected stacked layout first.)

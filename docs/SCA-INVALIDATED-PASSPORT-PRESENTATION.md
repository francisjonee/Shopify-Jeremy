# SCA Invalidated Passport Presentation (Option A) — PUSH-ONLY

**Date:** 2026-10-05 · **Base:** deployed production `f78e31d`, migrations **120**.
**Status: IMPLEMENTED + TESTED + PUSHED. NOT merged, NOT deployed. For independent pre-merge review.**
Implements **Option A** from `SCA-RETIRED-INVALIDATED-PASSPORT-POLICY-AUDIT.md` (gov `1868134`). Presentation /
view-only.

## Candidate
- **SHA:** `5b511a6` · **Branch:** `origin/sca-invalidated-presentation`
- **Base / merge-base:** `f78e31d` (verified), 1 commit, **3 files** (+233/−9):
  `Passport/Resources/views/passport/show.blade.php`, new
  `tests/Feature/Sca/PublicPassportInvalidatedPresentationTest.php`, and one updated assertion in
  `tests/Feature/Sca/PublicPassportSafetyTest.php`.
- **No** `PassportResolver`, `PassportPresenter`, `ItemStateLabels`, `PublicAllowlist`, `Config/passport`,
  `layout.blade`, middleware/CSP, route, migration, or core/vendor change (all guards 0).

## What changed (view-only)
In `show.blade`'s adverse branch, when the **already-derived** `registry_severity === 'invalid'`:
- the green **"✓ Authenticated & Certified"** badge + provenance line are **not** rendered;
- that area becomes a neutral historical-record notice: *"This Passport is retained as a historical SCA record
  and must not be treated as current verification. The authentication and certification details shown below
  remain part of the historical record."*
- the dominant **RECORD INVALIDATED** banner is unchanged; the cert/auth detail rows still render (history **not**
  erased).

Everything else is untouched: normal/recovered keep the green clear presentation; lost/stolen/disputed keep their
warning **and** green badge; **retired keeps 200 + RETIRED warning + the green badge** (explicitly retained). The
change keys off the existing `registry_severity` fact only — no new status interpretation in Blade.

## Boundaries honored
No resolver / cert-revocation / QR revocation-regen / registry-status-workflow / DB-schema-migration /
route-ACL-allowlist-CSP / `ItemStateLabels` semantic change. **SCA-038 constant-shape 404 preserved** (invalidated
still 200 — no new 404 reason). **Mobile responsive layout preserved** (`@media (max-width:480px)` + `.row`
classes + `overflow-wrap` still delivered on the invalidated page).

## Tests
- **New `PublicPassportInvalidatedPresentationTest` (10):** normal → green badge; recovered → clear + green;
  lost/stolen/disputed → warning + green retained (+ warning-before-authenticity); retired → RETIRED + green
  retained; **invalidated → 200 + RECORD INVALIDATED + NO green badge + historical/not-current notice**;
  invalidated cert/auth rows + events + `current_certification_id` unmutated and cert number still rendered;
  bogus/malformed/ineligible → constant-shape 404; mobile `@media`+`.row`+`overflow-wrap` present on invalidated;
  no `/storage`/`configuration/`/token/collector/`<script>` leak + CSP unchanged; invalidated GET mutates nothing.
- **Updated** the one `PublicPassportSafetyTest` invalidated assertion from the old green-badge expectation to the
  new no-green + historical-notice behavior.
- **Results:** focused passport suites 65/65; **full `tests/Feature/Sca` → 803 passed (4426 assertions), 0
  failed.** `php -l` clean.

## Restoration + zero-production-mutation proof
Pilot restored to deployed main `f78e31d` (`git checkout main`, tree clean, `composer install --no-dev`,
`config:clear`+`route:clear`). Candidate **not live**: `show.blade` has no `registry_severity === 'invalid'`
branch and no historical-notice text; `PublicPassportInvalidatedPresentationTest.php` absent. Runtime: the live
`/p/<valid>` page still shows the green "Authenticated & Certified" badge (1) and **no** historical notice (0).
- `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4` (== baseline) · migrations 120 · gallery 3.
- Smoke: loopback `:8080 → 302`; edge `/p/<valid> → 200`, `/p/<bogus> → 404`, `/storage/x → 404`.

## Next
Independent pre-merge review of `5b511a6`. On GO: governed `--no-ff` merge + `scripts/deploy-preview.sh`, then
closeout. (Option B — cert-revocation→404 for invalidated — remains the separate, un-chosen domain alternative and
is **not** part of this task.)

# SCA Public Passport — Mobile UX (PUSH-ONLY)

**Date:** 2026-10-02 · **Base:** deployed main `cbde6d2`, migrations **120**.
**Status: DONE — reviewed (PASS), merged `--no-ff`, and DEPLOYED `f78e31d` 2026-10-02.** (History below kept as
the push-only review record.) Implements `SCA-PUBLIC-PASSPORT-MOBILE-UX-AUDIT.md` (gov `2127f89`). View-only.

---
## DEPLOYMENT RESULT (2026-10-02)
**Fail-closed re-gate (all held):** origin/main `cbde6d2`; candidate local==origin `c7b29c4`; merge-base `cbde6d2`;
ahead 1/behind 0; clean tree; exactly the reviewed 3 files; forbidden-change guards (migrations/routes/
**PassportResolver/PassportPresenter/ItemStateLabels/PublicAllowlist/Middleware/Config**/core/vendor) all 0.

**Pre-merge full suite:** `tests/Feature/Sca` **793 passed (4362 assertions), 0 failed**.

**Governed merge + deploy:** `git merge --no-ff` → **MERGE_SHA `f78e31d`**, pushed origin/main;
`scripts/deploy-preview.sh` exit 0 (full-suite gate re-passed under `set -e`), "Deployed main @ f78e31d", kr-app not
recreated (code-only; Phase-B public :8080 stays retired/loopback-only; stash NOT reapplied). **MERGE_SHA ==
ORIGIN_MAIN == DEPLOYED_HEAD == `f78e31d`; migrations 120 (no migration).**

**Post-deploy verification:**
- **Zero prod mutation:** `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4` (== baseline) · migrations 120 · gallery 3.
- **Deployed Passport CSS/markup:** live `/p/<valid>` contains `@media (max-width: 480px)` (1), `class="row"` (8
  populated rows), `overflow-wrap: anywhere` (1); CLEAR wording "No adverse reports on the SCA registry" unchanged.
  Deployed `show.blade` = 11 `class="row"`, 0 inline `$row` remnants; `layout.blade` carries the stacking rule +
  `min-width:0`.
- **Adverse-warning-before-authenticity contract intact:** deployed `show.blade` `@if ($adverse)` (33) →
  `role="alert"` banner (35) → `registry_headline` (36) → authenticity badge (41); the 9 `PublicPassportMobileUxTest`
  (incl. `assertSeeInOrder` adverse-before-authenticity) + safety suite passed in pre-merge and the deploy gate
  (no production status mutated to manufacture an adverse state).
- **Untouched (diff cbde6d2→f78e31d = 3 files only):** no `ItemStateLabels` / `PassportResolver` /
  `PassportPresenter` / `PublicAllowlist` / `Config/passport` / CSP / middleware change.
- **Live regression:** `/p/<valid>` 200; `/p/<bogus>` & `/p/<malformed>` 404 (SCA-038 shape); `/storage/x` 404;
  `http→https` 308; Secure cookies present; loopback `:8080` 302 while public `195.26.255.80:8080` 000 (retired);
  kr-app + kr-mariadb healthy.

**Outcome:** mobile-responsive stacked detail rows LIVE; desktop two-column preserved; adverse hierarchy, CLEAR
wording, resolver/eligibility, SCA-038, privacy/CSP, and Phase-B all unchanged. Zero production provenance/domain
mutation. CLEAR-label wording evaluation and Retired/Invalidated 200-vs-404 policy remain deferred.

---

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

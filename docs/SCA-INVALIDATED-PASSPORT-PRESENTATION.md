# SCA Invalidated Passport Presentation (Option A) — PUSH-ONLY

**Date:** 2026-10-05 · **Base:** deployed production `f78e31d`, migrations **120**.
**Status: DONE — reviewed (PASS), merged `--no-ff`, and DEPLOYED `98ae654` 2026-10-05.** (History below kept as
the push-only review record.) Implements **Option A** from `SCA-RETIRED-INVALIDATED-PASSPORT-POLICY-AUDIT.md` (gov
`1868134`). View-only.

---
## DEPLOYMENT RESULT (2026-10-05)
**Fail-closed re-gate (all held):** origin/main `f78e31d`; candidate local==origin `5b511a6`; merge-base
`f78e31d`; ahead 1/behind 0; clean tree; exactly the reviewed 3 files; forbidden guards (migrations/routes/
**PassportResolver/PassportPresenter/ItemStateLabels/PublicAllowlist/Config/layout/Middleware**/core/vendor) all 0.

**Pre-merge full suite:** `tests/Feature/Sca` **803 passed (4426 assertions), 0 failed**.

**Governed merge + deploy:** `git merge --no-ff` → **MERGE_SHA `98ae654`**, pushed origin/main;
`scripts/deploy-preview.sh` exit 0 (full-suite gate re-passed under `set -e`), "Deployed main @ 98ae654"; kr-app
**not recreated** (code-only, "Up 3 days"); Phase-B public :8080 stays retired/loopback-only; stash NOT reapplied.
**MERGE_SHA == ORIGIN_MAIN == DEPLOYED_HEAD == `98ae654`; migrations 120 (no migration).**

**Post-deploy verification:**
- **Zero prod mutation:** `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4` (== baseline) · migrations 120 · gallery 3.
- **Deployed `show.blade` (structural; no production status mutated):** adverse branch `@if ($adverse)` →
  `role="alert"` banner → `@if ($sev === 'invalid')` → historical notice ("retained as a historical SCA record …
  must not be treated as current verification … details shown below remain part of the historical record"), **no**
  green badge; `@else` → green "✓ Authenticated & Certified" retained for lost/stolen/disputed/**retired**; clear
  branch → green. Detail rows (Certification No., Authenticity, Authenticated) still render = historical cert/auth
  facts preserved. The 10 `PublicPassportInvalidatedPresentationTest` cases (invalidated no-green + historical
  notice; cert/auth rows + `current_certification_id` unmutated; retired keeps green; 404 shape; mobile rule;
  no leak; zero mutation) passed in pre-merge and the deploy gate against this exact code.
- **Live CLEAR passport (runtime `/p/<valid>`):** green badge present (1), **no** RECORD INVALIDATED (0), **no**
  historical notice (0); mobile `@media (max-width: 480px)` (1) + `class="row"` (8) → normal unchanged + mobile
  stacked layout intact.
- **Diff `f78e31d..98ae654` = exactly 3 files** (show.blade + 2 tests); resolver/presenter/labels/allowlist/config/
  layout/CSP/routes/migrations untouched.
- **Live regression:** `/p/<valid>` 200; `/p/<bogus>` & `/p/<malformed>` 404 (SCA-038 constant shape); `/storage/x`
  404; `http→https` 308; Secure cookies present; loopback `:8080` 302 while public `195.26.255.80:8080` 000
  (retired); co-tenant smsrocket.io 302; kr-app + kr-mariadb healthy.

**Outcome:** invalidated public Passport now presents as a historical, non-current record (no green all-clear)
while retaining its provenance facts; Retired and every other state unchanged. Zero production provenance/domain
mutation; resolver/eligibility/SCA-038/CSP/mobile layout all intact. Option B (cert-revocation→404) remains the
separate, un-chosen domain alternative.

---

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

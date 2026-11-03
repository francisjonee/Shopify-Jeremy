# SCA — Staff Dashboard Identification & Status Safety (RESULT)

**The two P1 staff-dashboard issues from the 2026-11-03 operational-safety review are fixed on a
dedicated development branch, tested green in an isolated sandbox, and NOT deployed. Branch
`feature/sca-staff-dashboard-identity` (`4a33e938`) sits on top of the QR-label-PDF branch (`bdea6ac`)
and is presentation-only — 4 Blade edits + 1 new partial + 2 controllers (view-data only: a read-only
"has a photo" check) + 2 tests; no service, migration, route, or business-logic change (authentication,
certification, QR, ownership, and Shopify logic are untouched, and the FINALIZE / ISSUE typed
confirmations and all ACLs are preserved). (P1-1) The authenticate, finalize-confirm, and certify-confirm
screens now show the item's recorded brand / model / frame serial and featured photo — with explicit
"Not recorded" / "No photo on record" fallbacks, never inferred from a Shopify catalog title — plus the
unique SCA reference, so a staffer can confirm the physical pair in hand before the irreversible step.
(P1-2 / P2-1) On the registry listing, the green "Shopify ✓" pill is now a neutral "Catalog-linked"
(never the certification green), and uncertified (INTAKE) records carry an explicit amber "Not
authenticated" chip; "Certified" stays green and distinct.** In a network-isolated, disposable-DB
sandbox (proven unable to reach production, Shopify, or the internet) the focused and new/changed-file
suites passed fully; the full `tests/Feature/Sca` run was 1,612 tests / 8,254 assertions with a single
failure in an unrelated, untouched public-profile test (`CollectorPublicItemTest::pi8`) that is a
pre-existing full-suite isolation flake — it passes 29/29 in isolation and alongside all of this change's
files, and its code path was not modified here. No production deployment, DB write, imports, auth/cert/QR,
ownership change, or Shopify call; the live checkout stays at `6e36aa7`; the 205 imports are untouched.
2026-11-03. **STOP.**

> Written for: the owner (Jeremy) + staff who process physical eyewear, and the external auditor.

## Branch / commit (deliverable)
- **Branch:** `feature/sca-staff-dashboard-identity` — based on `bdea6ac`; pushed to the implementation origin (`github-sca-platform`). Branch push only — no deploy, no merge, `origin/main` untouched.
- **Commit SHA:** `4a33e9386fe71c280a16496cbd0227e15d3d1130`
- **Changed files (9):** controllers `AuthenticationController.php`, `CertificationController.php` (view-data only); views `authentication/create.blade.php`, `eyewear/finalize-confirm.blade.php`, `eyewear/certify-confirm.blade.php`, `eyewear/index.blade.php`, new `eyewear/_confirm-item-identity.blade.php`; tests `StaffDashboardIdentityTest.php` (new), `ShopifyLinkVisibilityTest.php` (label update).

## What changed
### P1-1 — physical-pair identity on the irreversible screens
A new shared partial `_confirm-item-identity.blade.php` renders, for the item being authenticated/
certified: the featured catalog photo (or a "No photo on record" placeholder), and **Brand / Model /
Frame serial** each showing the recorded value or an explicit **"Not recorded"** (never inferred from a
Shopify catalog title), plus the **SCA public reference**. It is included on all three screens —
`…/authenticate`, `…/authentications/{id}/finalize/confirm`, `…/certify/confirm`. The controllers pass a
read-only `hasImage` flag (gallery row OR legacy `image_path`). The FINALIZE / ISSUE typed confirmations
and the `sca.eyewear.authenticate` / `sca.eyewear.certify` ACLs are unchanged.

### P1-2 / P2-1 — catalog link no longer looks like certification; explicit "Not authenticated"
On the registry listing (`index.blade.php`): the active-link pill changed from the green "Shopify ✓"
(`sca-pill-cert`) to a **neutral "Catalog-linked"** (`sca-pill-neutral`); the inactive label is
"Catalog link inactive" and the unlinked label "No catalog link". A new amber `sca-pill-warn` **"Not
authenticated"** chip renders for INTAKE records (no authentication inspection yet). "Certified" keeps
the green `sca-pill-cert` so authentication status is visually distinct from a catalog link.

## Authorized tasks — status
1. Dev branch off `bdea6ac` — done. 2. Reviewed the three screens — done. 3. Brand/model/serial/photo
shown where available — done. 4. "Not recorded" fallback; never inferred from catalog titles — done.
5. SCA public reference on every confirmation screen — done. 6. FINALIZE/ISSUE requirements preserved —
done (asserted). 7. Green "Shopify ✓" → neutral "Catalog-linked" — done. 8. Clear "Not authenticated"
indicator — done. 9. "Certified" kept visually distinct — done. 10. Auth/cert/QR/ownership/Shopify logic
preserved — done (diff is views + view-data + tests only). 11. Focused tests — done. 12. Full isolated
regression — done (below). 13. Diff reviewed: no security/business-logic change — confirmed. 14. Commit +
document — done. 15. STOP — done.

## Tests & regression
- **New `StaffDashboardIdentityTest` (8 tests):** identity shown on the authenticate/finalize/certify
  screens + SCA reference; "Not recorded" for missing brand/model/serial (never invented); featured photo
  rendered when present else "No photo on record"; ACLs still enforced (403 for a sibling-perm role on
  each screen); listing shows "Not authenticated" for INTAKE and drops the green "Shopify ✓"; "Certified"
  present (and no "Not authenticated") for a certified item.
- **Updated `ShopifyLinkVisibilityTest`** to the new neutral listing labels (and asserts "Shopify ✓" is gone).
- **Focused group** (StaffDashboardIdentityTest + Authentication/Certification/ItemMetadataCorrection): 62 tests / 263 assertions / 0 fail.
- **All this change's files together** (CollectorPublicItemTest + StaffDashboardIdentityTest + ShopifyLinkVisibilityTest): 44 tests / 183 assertions / 0 fail — i.e. this change does not pollute the public-profile test.
- **Full application suite:** `tests/Feature/Sca` → 1,612 tests / 8,254 assertions, **1 failure, 1 skip**. Isolation proven before any migration/test (egress blocked, prod DB → ERROR 1044, identity `sca_domain_test`); production `vendor/` still `--no-dev`.

## Remaining operational issue (NOT caused by this change)
- **`CollectorPublicItemTest::pi8_public_html_allowlist` fails only in the full 1,612-test run** (an
  allowlist "leak" on the **public collector profile**). Evidence it is a pre-existing **test-isolation
  flake**, not a product regression from this change: it **passes 29/29 in isolation**; it **passes
  alongside every file this change adds/edits**; and its code path (`Sca\Collector` / `Sca\Passport`) is
  **not touched** by this `Sca\Registry` change (and the new test file sorts after it, so it cannot
  pollute it). Adding 8 test methods shifted full-suite ordering enough to surface a latent polluter in
  some unrelated earlier test. **Recommended as a separate follow-up** (identify and fix the polluting
  test's leftover state / tighten the pi8 allowlist); it is not a blocker for this presentation-only
  branch, which is not deployed.

## Safety posture (this task)
Implemented on an isolated dev branch only. No production deployment, migration, or DB write; no imports
or metadata changes; no authentication/certification/QR generation; no customer claims or ownership
transfers; no Shopify API call; secure claiming NOT activated; `origin/main` NOT merged. The live
checkout stayed at `6e36aa7` and clean; the production DB is unchanged; the 205 imported records are
untouched; production `vendor/` remains `--no-dev`.

**STOP — Staff-dashboard identity/status safety delivered on `feature/sca-staff-dashboard-identity`
(`4a33e938`, off `bdea6ac`): the authenticate/finalize/certify screens now show brand/model/serial +
photo (clear "Not recorded" fallback, never from catalog titles) + the SCA reference so staff can
confirm the pair before the irreversible step; the listing uses a neutral "Catalog-linked" pill (not the
cert green) and an explicit "Not authenticated" chip for INTAKE, with "Certified" kept distinct. Typed
FINALIZE/ISSUE + ACLs + all auth/cert/QR/ownership/Shopify logic unchanged (verified). Isolated sandbox:
focused + per-file groups GREEN (62/263, 44/183); full suite 1,612/8,254 with 1 unrelated pre-existing
public-profile isolation flake (pi8; passes isolated + alongside this change's files; untouched code
path) flagged for separate follow-up. Branch pushed, NOT deployed/merged; prod `6e36aa7` intact; 205
imports untouched.**

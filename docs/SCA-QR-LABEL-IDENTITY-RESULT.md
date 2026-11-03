# SCA — QR Label Identification & Print Safety (RESULT)

**The top QR-label staff risk from the 2026-11-03 review — a printed label that carries only the opaque
SCA reference, inviting mis-attachment to the wrong physical pair — is fixed on a dedicated development
branch, tested green in an isolated sandbox, and NOT deployed. Branch `feature/sca-qr-label-identity`
(`17b6b533`) sits on top of the P2 branch (`e80b386a`) and changes only the QR-label render path and
views (1 controller method set + 3 label views) plus one new test — no change to the QR payload, token,
encoder, error-correction, or quiet zone, no change to active-QR eligibility, the ACL, or any
authentication / certification / ownership / Shopify logic. Each printed label now shows the item's
verified brand and model beside the existing unique SCA reference (never invented — a clear
"Brand/model not recorded" fallback when none is on record), the batch sheet numbers labels #1, #2, …
in print order, and the print instructions lead with "Print at 100% (actual size)" and a reminder to
match the brand/model and reference to the pair before attaching.** In a network-isolated,
disposable-DB sandbox (proven unable to reach production, Shopify, or the internet) the full suite
passed 1,594 tests / 8,182 assertions / 0 failures / 0 errors / 1 skip, including 6 new tests. No
production deployment, migration, DB write, QR generation, label printing, or Shopify call; the live
checkout stays at `6e36aa7`; the 205 imported records are untouched; secure claiming is NOT activated.
2026-11-03. **STOP.**

> Written for: the owner (Jeremy) + the staff who print/attach QR labels, and the external auditor.

## Branch / commit (deliverable)
- **Branch:** `feature/sca-qr-label-identity` — based on `e80b386a` (the P2 UX branch); pushed to the implementation origin (`github-sca-platform`). Branch push only — no deploy, no merge, `origin/main` untouched.
- **Commit SHA:** `17b6b533bd1a301817217181bca91a26da36e925`
- **Changed files (5):** `EyewearItemController.php` (label render/pass only), `_qr-label-card.blade.php`, `qr-print-label.blade.php`, `qr-print-labels.blade.php`, and new `tests/Feature/Sca/QrLabelIdentityTest.php`.

## What changed
- **`renderActiveQrSvg()`** (the one shared QR renderer) now also returns the item's `brand`, `model`,
  and a computed `item_label` (`trim(brand model)`). Brand/model are read as recorded — **never
  invented**; when both are null the label renders a clear **"Brand/model not recorded"** fallback so
  staff notice the gap. The SVG, token, URL, encoder options (`EccLevel::H`, quiet zone 4,
  `svgUseFillAttributes`) and the active-QR resolution are byte-for-byte unchanged (verified: the encoder
  / payload lines are not in the diff; a test asserts the label's embedded SVG is identical to the SVG
  download).
- **`_qr-label-card.blade.php`** (shared by single + batch) now shows the brand/model line (or the
  fallback) beside the existing SCA reference, plus an optional **sequence badge** (`#N`). The raw
  `public_token` still never appears as text.
- **Batch sheet** numbers labels `#1, #2, …` in print (selection) order; the sequence counts only
  **eligible** labels; ineligible/unknown ids are still omitted as a count only (never their data).
- **Print instructions** (single + batch) now lead with **"Print at 100% (actual size)."** and add
  "match each label's brand & model and SCA reference to the correct pair before attaching."

## Authorized tasks — status
1. Dev branch off `e80b386a` — done. 2. Reviewed the card + `renderActiveQrSvg()` — done. 3. Brand+model
on each label — done. 4. Existing unique SCA reference retained — done. 5. Batch sequence number when
available — done (batch only; single label is "1 of 1" implicitly, no badge). 6. No invented data; clear
fallback — done. 7. QR payload/token/encoder/ECC/quiet zone preserved — done (verified). 8. Print-at-100%
reminder — done (strengthened lead). 9. Authorization + active-QR eligibility preserved — done (ACL test
still 403 for a non-`view` role; resolution unchanged). 10. No auth/cert/ownership/Shopify change — done
(diff confined to the label render path + views). 11. Tests for label identity, missing metadata, print
order, access controls — done. 12. Isolated regression — done. 13. Mobile/print-layout review — the card
additions are presentation-only; print CSS unchanged except the new `.item`/`.seq` rules; the full suite
(incl. the public-Passport mobile/safety suites and the QR print suites) is green. 14. Commit + document
+ STOP — done.

## Tests & regression
- **New `QrLabelIdentityTest` (6 tests / exact-markup assertions):** single label shows verified
  brand/model + reference; missing brand/model → explicit fallback (no fabrication); batch numbers labels
  in selection order; batch sequence counts only eligible items (+ omitted notice, no ineligible data);
  the identity addition leaves the QR SVG byte-identical to the download and never leaks the token as
  text; label + batch still enforce the `sca.eyewear.view` ACL (403 for a sibling-perm role).
- **QR suites together:** `QrLabelIdentityTest` + `QrPrintLabelTest` + `QrLabelsBatchTest` +
  `QrArtifactTest` + `QrReissueTest` → 60 tests / 260 assertions / 0 fail.
- **Full application suite:** `tests/Feature/Sca` → **1,594 / 8,182 / 0 failures / 0 errors / 1 skip**
  (exit 0). Isolation proven before any migration/test (egress blocked, prod DB denied → ERROR 1044,
  identity `sca_domain_test`); production `vendor/` still `--no-dev`.
- (Test-writing note: an initial assertion for a bare `#3` matched CSS hex colors like `#374151`; fixed to
  assert the exact badge markup `<div class="seq">#N</div>`.)

## Remaining (not in this task; from the review)
- **P1-2 (fixed-size print):** physical QR size still depends on the browser not shrink-to-fitting; a
  server-rendered fixed-size PDF is a larger, separate task (this change only strengthens the on-screen
  reminder).
- **P2 items** (align the label gate to require a current certification; name the omitted batch items; a
  label-stock template; a dedicated print ACL; the token shown on the detail page) remain open.

## Safety posture (this task)
Implemented on an isolated dev branch only. No production deployment, migration, or DB write; no QR
generation or physical label printing; no Shopify API call; no authentication/certification/ownership
change; secure claiming NOT activated; `origin/main` NOT merged. The live checkout stayed at `6e36aa7`
and clean; the production DB is unchanged; the 205 imported records are untouched; production `vendor/`
remains `--no-dev`.

**STOP — QR label identification delivered on `feature/sca-qr-label-identity` (`17b6b533`, off
`e80b386a`): each label now shows verified brand + model (clear fallback when absent) beside the SCA
reference, batch labels are numbered #1,#2,… in print order, and the print hint leads with "Print at
100% (actual size)". QR payload/token/encoder/eligibility/ACL and all auth/cert/ownership/Shopify logic
unchanged (verified). Isolated sandbox: full suite 1,594/8,182/0-fail/0-error/1-skip; QR suites 60/260.
Branch pushed, NOT deployed, NOT merged; prod `6e36aa7` intact; 205 imports untouched. Remaining:
fixed-size PDF and the other P2 items.**

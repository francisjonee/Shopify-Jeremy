# SCA — Fixed-Size QR Label PDF (RESULT)

**A reliable, fixed-size PDF printing option for certified-eyewear QR labels is implemented on a
dedicated development branch, tested green in an isolated sandbox, and NOT deployed. Branch
`feature/sca-qr-label-pdf` (`bdea6aca`) sits on top of the QR-label-identity branch (`17b6b533`) and
adds — additively — a single-item and a batch PDF export using the app's existing
`barryvdh/laravel-dompdf`. Each PDF label is a fixed 50 mm × 70 mm page (one label per page) carrying a
30 mm QR with a 4-module quiet zone, so scannability no longer depends on the browser's print scaling.
The QR in the PDF is a PNG rendered from the SAME canonical passport URL and public token, with the SAME
error-correction level (H) and quiet zone as the existing SVG — only the raster format differs; a test
decodes it back to the canonical `/p/{token}` to prove the payload and token are preserved. Each label
shows the verified brand + model (never invented — a clear "Brand/model not recorded" fallback) beside
the unique SCA reference; batch labels are numbered in print order; an all-ineligible selection produces
no PDF (it redirects with a notice). The existing HTML/SVG label printing, the active-QR eligibility,
and the `sca.eyewear.view` ACL are unchanged.** In a network-isolated, disposable-DB sandbox (proven
unable to reach production, Shopify, or the internet) the full suite passed 1,604 tests / 8,220
assertions / 0 failures / 0 errors / 1 skip, including 10 new tests. No production deployment,
migration, DB write, QR generation, label printing, or Shopify call; the live checkout stays at
`6e36aa7`; the 205 imported records are untouched; secure claiming is NOT activated. 2026-11-03.
**STOP.**

> Written for: the owner (Jeremy) + the staff who print/attach QR labels, and the external auditor.

## Branch / commit (deliverable)
- **Branch:** `feature/sca-qr-label-pdf` — based on `17b6b533`; pushed to the implementation origin (`github-sca-platform`). Branch push only — no deploy, no merge, `origin/main` untouched.
- **Commit SHA:** `bdea6acac75383d0d9a5e0b817ad7738771b656b`
- **Changed files (6, additive):** `EyewearItemController.php` (new `qrLabelPdf`/`qrLabelsPdf`/`renderActiveQrPng` + a label-size constant), `admin-routes.php` (2 routes), new `qr-label-pdf.blade.php`, `show.blade.php` (+1 link), `index.blade.php` (+1 button), new `QrLabelPdfTest.php`.

## What was built
- **Single PDF** — `GET /admin/sca/eyewear/{id}/qr/label/pdf` (name `admin.sca.eyewear.qr.label.pdf`, ACL `sca.eyewear.view`): a one-page fixed-size PDF of the item's active-QR label; filename `sca-qr-label-{public_ref}.pdf`.
- **Batch PDF** — `POST /admin/sca/eyewear/qr/labels/pdf` (name `…qr.labels.pdf`, POST+CSRF, same ACL): a multi-page PDF, one label per page, numbered `#1, #2, …` in selection order; filename `sca-qr-labels.pdf`. Same validation/dedupe/eligibility as the HTML batch; ineligible/unknown ids are excluded; **all-ineligible → redirect to the list with a notice** (no empty PDF).
- **QR integrity** — `renderActiveQrPng()` resolves the token the same way as the SVG renderer and encodes the identical canonical URL (`config('app.url')` + `/p/{token}`) with `EccLevel::H` and quiet zone 4, output as a PNG data URI (scale 10, opaque white background) that dompdf embeds reliably. The raw token appears only inside the QR, never as text.
- **Identity on each label** — verified brand + model (fallback "Brand/model not recorded" when none is recorded; never invented) + the unique SCA reference + "Scan to verify authenticity".
- **UI** — the item-detail "Certification & QR" tab gains a "Download PDF label (fixed size)" link; the registry listing's batch form gains a "Download PDF labels" button (via `formaction`, reusing the same checkbox selection). The existing "Print QR label" (HTML) and "Download printable QR (SVG)" remain.

## Tests & regression
- **New `QrLabelPdfTest` (10 tests):** single PDF generated (200, `application/pdf`, `%PDF-`, filename has the reference); 404 when the item has no active QR; the PDF QR PNG **decodes to `CANON/p/{token}`** (payload + token preserved); the label shows brand/model; the missing-metadata fallback ("Brand/model not recorded", never invented); batch labels numbered in order with one page break per non-last label; batch excludes ineligible items / all-ineligible redirects with a flash; both PDF endpoints enforce the `sca.eyewear.view` ACL (403 for a sibling-perm role); and require authentication (guest redirect).
- **QR + PDF suites together:** 53 tests / 196 assertions / 0 fail.
- **Full application suite:** `tests/Feature/Sca` → **1,604 / 8,220 / 0 failures / 0 errors / 1 skip** (exit 0). Isolation proven before any migration/test (egress blocked, prod DB → ERROR 1044, identity `sca_domain_test`); production `vendor/` still `--no-dev`.
- (Note: two initial PDF-internal page-count assertions were dropped because dompdf's object references make such counts unreliable; page-per-label is instead proven at the view level, and exclusion via the all-ineligible redirect.)

## Staff printing guide (paper / label / printer settings)
- **Label size:** each PDF page is **50 mm × 70 mm (portrait)** — one label per page. The QR prints **30 mm square** with its quiet zone; brand/model, the SCA reference, and the caption sit below it.
- **On a dedicated label printer (recommended):** set the media/stock size to **50 × 70 mm** and print at **100% / actual size** (do NOT "fit to page" or "shrink oversized pages"). Each PDF page = one label; the batch PDF advances one label per page in the numbered order.
- **On an office printer (A4/Letter):** print at **100% / actual size**, "fit to page" OFF; each 50 × 70 mm label prints centered on its own sheet. Use **black & white on matte paper** for best scan contrast.
- **Before attaching:** check each label's **brand & model and SCA reference** match the physical pair (the batch sequence number `#N` matches the on-screen print order). Scan one with a phone to confirm it opens the item's public passport.
- **Scannability:** the QR uses the highest error-correction (H) and a full 4-module quiet zone at 30 mm, which scans reliably with standard phone cameras when printed at 100%.

## Not in scope / remaining
- Per-label-stock templates (e.g. Avery multi-up sheets) — the current PDF is one label per fixed-size page; a multi-up sheet template could be a later option.
- The other P2 items from the review (align the label gate to require a current certification; name the omitted batch items in the HTML sheet; a dedicated print ACL; the token shown on the item-detail page) remain open.

## Safety posture (this task)
Implemented on an isolated dev branch only. No production deployment, migration, or DB write; no QR
generation or physical label printing; no Shopify API call; no authentication/certification/ownership
change; secure claiming NOT activated; `origin/main` NOT merged. The live checkout stayed at `6e36aa7`
and clean; the production DB is unchanged; the 205 imported records are untouched; production `vendor/`
remains `--no-dev`.

**STOP — Fixed-size PDF QR labels delivered on `feature/sca-qr-label-pdf` (`bdea6aca`, off `17b6b533`):
single + batch PDF at a fixed 50 × 70 mm page (one label per page), QR PNG from the identical canonical
URL/token + ECC-H/quiet-zone (decoded in test to CANON/p/{token}), verified brand/model (clear fallback)
+ SCA reference, batch numbered in order, all-ineligible → redirect. Existing HTML/SVG printing,
eligibility, and ACL unchanged (additive diff). Isolated sandbox: full suite 1,604/8,220/0-fail/0-error/
1-skip; QR+PDF suites 53/196. Branch pushed, NOT deployed, NOT merged; prod `6e36aa7` intact; 205
imports untouched. Printing guide above.**

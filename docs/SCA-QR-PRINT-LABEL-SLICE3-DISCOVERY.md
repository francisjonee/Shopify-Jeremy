# SCA QR / Label Workflow — Slice 3 (production print polish) discovery + plan (PLAN ONLY)

**Date:** 2026-10-06 · **Status: DISCOVERY + PLAN ONLY. No code, deployment, DB mutation, or production change.** · Deployed baseline `4d92ec9`, migrations **120**, FP `62b2e42fe409b4ec91f3381b35da819e`. Continues the QR/Label Workflow (Slice 1 + Slice 2 deployed). For ChatGPT audit.

**Decision up front: recommend Option A (small UX/print polish only) — and completing it CLOSES the QR/Label Workflow.** B (presets) and C (PDF export) are evaluated and **rejected/deferred** as not providing operational value proportional to their complexity.

---

## 1. Findings — inspection of the deployed implementation

**Single-label view (`qr-print-label.blade.php`):** standalone page; toolbar (Print / Back), a hint line, one card (`.label-card` 54 mm, bordered on screen) via the shared `_qr-label-card` partial; `@media print` hides chrome + removes the border. Opens in a new tab (show-page link `target=_blank`). **QR fixed 30 mm** (`.qr{width:30mm;height:30mm}`, SVG scales to fill, baked 4-module quiet zone preserved).

**Batch sheet (`qr-print-labels.blade.php`):** standalone page; toolbar (Print N / Back to list), a print-instruction notice, an omitted-count notice, a CSS grid `repeat(4, 44mm)` with `gap:4mm`, each cell `.label-card` 44 mm; `@media print { @page{margin:10mm} }` + `break-inside/page-break-inside: avoid` per card. Opens in a new tab.

**Shared label card (`_qr-label-card.blade.php`):** brand "Second Chance Authenticators" (9 pt), 30 mm QR, `public_ref` (10 pt monospace, `word-break`), caption "Scan to verify authenticity" (8.5 pt). Single source of presentation for single + batch.

**Selection (`index.blade.php`):** sibling `<form id="sca-batch-print">` + eligible-only (`$item->cs_qr`) checkboxes bound via HTML5 `form=`; optional JS updates the submit count and disables at 0. **No "select all on this page" control exists.**

### Point-by-point evaluation
| Question | Finding |
|---|---|
| Single-label print UX | Clean, functional; one 30 mm label, chrome hidden on print. Adequate. |
| Batch-sheet print UX | Clean 4-col grid, labels don't split pages, omitted summary. Adequate. |
| Actual physical dimensions | QR 30 mm square; single card 54 mm; batch cell 44 mm — all `mm` (physical), so correct **provided the browser prints at 100%**. |
| A4 & US Letter | Grid = 4×44 mm + 3×4 mm = **188 mm** ≤ A4 usable (190 mm @10 mm margins) and ≤ Letter (196 mm). 4 columns fit **both**. ✅ |
| 30 mm QR still appropriate | Yes. ~57-module symbol (incl. quiet zone), ECC-H, encoding a ~66-char HTTPS URL → ~0.5 mm/module at 30 mm: reliably phone-scannable and robust on a small eyewear tag. Keep 30 mm as the default. |
| Label/card presets meaningful? | **No clear value.** One 30 mm card already serves single + batch; no evidence SCE uses specific label stock. Presets add UI branches + CSS + tests for a hypothetical need. **Defer.** |
| Compact sticker vs larger card | Current compact card (brand+QR+ref+caption) already suits attaching to a case/presentation card. No evidence a second size is needed. **Defer.** |
| "Select all eligible on this page" | **Missing, and genuinely useful** — printing a full page means ticking up to 20 boxes by hand. A one-click select-all is the single highest-value polish. ✅ (Option A) |
| Print instructions sufficient? | Present ("Print at 100% (no shrink-to-fit), black on white, matte") but terse for non-technical staff. **Clearer, dialog-specific wording helps** (Scale = 100% / Fit-to-page OFF / paper A4 or Letter). ✅ (Option A) |
| SCA branding/text sufficient? | Brand + caption + `public_ref` is sufficient. A human-readable verify domain line is a *nice* fallback for non-scanning verification — **optional**, not required. |
| `public_ref` legible? | Yes — 10 pt monospace, 16-char `SCA-…` ref. Legible. |
| Browser print scaling/margins risk | **The one real operational risk:** browsers can default to "Fit to page"/auto-scale, which would shrink the 30 mm QR. CSS cannot force print scale; the mitigation is **clearer instructions** telling staff to set 100%. (`mm` sizing is otherwise immune to margin changes.) ✅ (Option A) |
| PDF export value vs complexity | **Low net value, high complexity.** Every browser's print dialog already offers "Save as PDF", so server-side PDF largely **duplicates browser printing**. Worse, the deployed PDF engine (dompdf, used for the certificate) has poor inline-SVG support → rendering the chillerlan **SVG** QR would likely require rasterizing to PNG = effectively a **second rendering path**, which the architecture forbids. **Reject/defer.** |
| Would Slice 3 work duplicate browser printing? | PDF export would (browser Save-as-PDF). The Option A polish does **not** — it improves selection + guidance, not the print mechanism. |
| Accessibility / usability of selection+print | Checkboxes are real labelled inputs; no-JS path works; count/disable is progressive. Gaps: no select-all (tedium), and instruction clarity. No blocking a11y defects. |

---

## 2. Actual remaining operational gaps (evidence-based)
1. **No "select all eligible on this page"** → ticking up to 20 boxes by hand to print a full sheet. (Usability.)
2. **Print-dialog guidance is terse** → risk a non-technical staffer prints at "Fit to page" and shrinks the QR. (Correctness-of-output risk; the only real one.)
3. *(Optional)* No human-readable verify URL on the label for someone who cannot scan. (Nice-to-have.)

Everything else (presets, sticker sizes, PDF, cross-page selection, richer artifact) is **not a production gap** — it is nice-to-have.

---

## 3. Recommended Slice 3 scope — **Option A (small UX/print polish only)**
Smallest change that closes the real gaps, view/JS-only, no new renderer, no controller/route/ACL/schema change:

1. **"Select all eligible on this page"** — a checkbox in the batch toolbar that toggles all `.sca-batch-cb` on the current page, wired into the existing optional JS (also keeps the live count). **JS-only progressive enhancement**; the manual checkboxes + submit continue to work with JS disabled (the select-all simply does nothing without JS, or is hidden).
2. **Clearer print instructions** on both print views — explicit, non-technical dialog guidance: "In the print dialog: **Scale 100%**, **Fit to page OFF**, **Paper A4 or Letter**, **Margins Default**, colour off (black & white), matte paper." (Mitigates the only real correctness risk.)
3. *(OPTIONAL, include only if ChatGPT wants it)* a small human-readable `verify.secondchanceauthenticators.com/p/…`-style **domain line** under the caption in `_qr-label-card` — a non-scanning fallback. Marked optional; adds a line of text, no logic. **Defaults to deferred** unless requested.

**Reject Option B** (presets) and **Option C** (PDF export) per §1 — no proportional operational value; PDF also risks a second renderer and duplicates browser Save-as-PDF. **Option D** = A only (items 1–2); the optional domain line is the only possible add. **Not Option E** solely because the select-all + instruction gaps are real, cheap wins; if ChatGPT prefers, E (ship nothing) is defensible since printing already *works*.

---

## 4. Exact expected files affected (Option A)
**Modified (3):**
- `packages/Sca/Registry/src/Resources/views/eyewear/index.blade.php` — add the "Select all eligible on this page" checkbox in the batch toolbar; extend the existing inline JS to toggle all `.sca-batch-cb` + keep the count/disable. (No new form, no controller change.)
- `packages/Sca/Registry/src/Resources/views/eyewear/qr-print-label.blade.php` — expand the `.hint` instruction text.
- `packages/Sca/Registry/src/Resources/views/eyewear/qr-print-labels.blade.php` — expand the `.notice` instruction text.

**Optional modified (1, deferred by default):** `packages/Sca/Registry/src/Resources/views/eyewear/_qr-label-card.blade.php` — add a human-readable domain line.

**NOT touched:** `EyewearItemController`, routes, ACL, `renderActiveQrSvg` (no new renderer), schema/migrations, `is_production`, QR identity/reissue, passport/resolver, provenance, Shopify, SMTP, Caddy, Docker, Krayin core/vendor, composer, `.env`. No new route (public or admin).

## 5. Required tests
Light, presentational (the select-all toggle is client-side JS, not exercisable in PHPUnit without a browser — so test the *presence* of the control + the improved copy, and keep the functional Slice 1/2 suites green):
- extend/ add: index renders a "select all" control associated with `sca-batch-print` and gated on `sca.eyewear.view`;
- single + batch print views contain the clearer print-instruction wording;
- (if the optional domain line is included) the label card shows the human-readable verify domain and still **does not** expose the raw token;
- **regression:** full `tests/Feature/Sca` stays green (Slice 1 `QrPrintLabelTest`, Slice 2 `QrLabelsBatchTest`, `QrArtifactTest`, `QrReissueTest`, `PublicPassportTest`) — the shared renderer/partial and existing selection path unchanged.

No DB/behavioral tests needed (zero logic/route/schema change).

## 6. Explicitly deferred / NON-required (nice-to-have, not production-blocking)
- **PDF/export** (duplicates browser Save-as-PDF; dompdf SVG risk → near second-renderer).
- **Label/card size presets** and a distinct **compact-sticker layout** (no evidenced need; 30 mm serves both).
- **Cross-page / "select all matching filter"** selection (state/complexity; current-page is sufficient).
- **Richer QR artifact** (logo-in-QR — harms scan reliability; explicitly not recommended).
- **Zebra/Dymo/printer-specific integration.**
- **`is_production` activation** (architecturally mint-time only; not a printing gap).
- Physical printing + attachment itself (human/business operation, not software).

## 7. Does Slice 3 CLOSE the QR/Label Workflow?
**Yes.** After Option A, the end-to-end staff workflow — certify → (single or batch) print a correct, scannable ~30 mm label with clear guidance → scan → public passport — is operationally complete with no remaining software gap. Every other idea is classified above as optional/deferred. **Recommend that completing Slice 3 (Option A) formally CLOSES the Production QR/Label Workflow task**, with the deferred list remaining available as separate, individually-justified future tasks if a concrete business need appears.

**DISCOVERY/PLAN ONLY — no code/deploy/DB/production change performed.** See [[sca-production-qr-label-workflow-discovery]], `docs/SCA-QR-PRINT-LABEL-SLICE2-DEPLOY-RESULT.md`.

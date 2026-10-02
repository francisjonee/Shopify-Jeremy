# SCA Public Passport — Mobile UX Audit (READ-ONLY)

**Date:** 2026-10-02 · **Baseline:** deployed main `cbde6d2`, migrations **120**.
**Status: AUDIT / DESIGN ONLY. No code/commit (app)/deploy/DB/ACL/route/CSP/infra change. ACTIVE/NEXT unpromoted.
STOP for ChatGPT / operator review.**

Scope: the smallest **responsive, presentation-only** refinement to the detail/information rows below the product
image on the public Passport, preserving the desktop experience and the deployed trust/safety hierarchy. Traced
against the actual deployed Blade/CSS/presenter at `cbde6d2`, not the screenshots.

Files traced: `packages/Sca/Passport/src/Resources/views/passport/layout.blade.php` (the single inline `<style>`),
`.../passport/show.blade.php` (the rows), `Sca/Provenance/src/Support/ItemStateLabels.php` (registry labels),
`packages/Sca/Passport/src/Presenters/PassportPresenter.php`.

## 1. Exact root cause

The detail rows are styled with **inline `style=""` attributes** built from three PHP strings in
`show.blade.php:15-17`:
```
$rowLabel = 'color:#64748b;font-size:13px';
$rowValue = 'font-weight:600;text-align:right';
$row      = 'display:flex;justify-content:space-between;gap:16px;padding:11px 0;border-top:1px solid #f1f5f9';
```
Each row (`show.blade.php:68-125`) is a `display:flex; justify-content:space-between` with a left label and a
**right-aligned value that has no width/shrink/wrapping control**. Two independent defects follow:

- **(a) Not responsive — structurally cannot be.** The whole passport has **no `@media` query anywhere**
  (`layout.blade.php:13-46` is the only CSS; the only `max-width` uses are the 560px `.wrap` cap and the logo/image
  size caps — not breakpoints). **Inline `style=""` cannot carry a media query** (media queries only exist in a
  `<style>` block / stylesheet). So at every viewport the rows render the same two-column desktop layout. On a
  ~360px phone the card content is ≈284px wide; after the label + `gap:16px`, the right value column is very narrow,
  so long values ("No adverse reports on the SCA registry", certification numbers, long brand/model) wrap awkwardly
  against the label.
- **(b) Flexbox shrink/overflow.** Flex items default to `min-width:auto`, which refuses to shrink below their
  content width, and the value has no `overflow-wrap`. Long unbroken tokens (certification numbers/SKUs) can push
  width or wrap mid-token even before the phone width is reached. This affects desktop too for pathological values.

The "No adverse reports on the SCA registry" clear label is the most visible symptom, but it is a **layout**
symptom (a long string squeezed into a narrow right column), not a wording problem.

## 2. Existing responsive behavior / breakpoints

**None.** `body` padding `24px 16px 72px`; `.wrap{max-width:560px}`; `.card{padding:22px}`; rows `padding:11px 0`;
product image already responsive (`max-width:100%;max-height:240px`, `show.blade.php:65`). No `@media`, no Tailwind,
no Vite/@push/@stack — the public Passport is **hand-written self-contained inline CSS** in `layout.blade.php`
(distinct from the Admin surface's pre-compiled Tailwind). Adding raw CSS + a media query to that same `<style>`
block needs **no build step and no JS**.

## 3. Smallest recommended change (Blade/CSS, view-only)

Convert the three inline row strings into **CSS classes in the existing `layout.blade.php` `<style>` block** and add
one mobile breakpoint. This is the minimal change that makes a media query possible at all.

- **`layout.blade.php`** — add to the `<style>` block:
  ```css
  .row { display:flex; justify-content:space-between; gap:16px; padding:11px 0; border-top:1px solid #f1f5f9; }
  .row-label { color:#64748b; font-size:13px; }
  .row-value { font-weight:600; text-align:right; min-width:0; overflow-wrap:anywhere; }
  .row > * { min-width:0; }                 /* let flex children shrink so long values wrap, not overflow */
  @media (max-width: 480px) {
      .row { flex-direction:column; align-items:flex-start; gap:2px; padding:9px 0; }
      .row-value { text-align:left; }         /* stacked: label above, value full-width left-aligned */
      .card { padding:18px; }                 /* modest, not crowded */
  }
  ```
- **`show.blade.php`** — replace `style="{{ $row }}"`→`class="row"`, `style="{{ $rowLabel }}"`→`class="row-label"`,
  `style="{{ $rowValue }}"`→`class="row-value"`; delete the now-unused `$row/$rowLabel/$rowValue` vars. The one
  special first row keeps its border suppression as `class="row" style="border-top:none"` (inline style still
  CSP-allowed). The warning banner, badge, provenance line, SCA-reference block, image and trust-copy block are
  **untouched**.

**Breakpoint rationale:** `max-width: 480px` targets phone portrait. The card is capped at 560px, so any viewport
≥481px already renders the full desktop/tablet card comfortably → desktop/tablet **retain the two-column layout
unchanged**. (If the operator prefers, 420–500px are all defensible; 480px is the conventional phone-portrait cut.)

**Wrapping safety:** `overflow-wrap:anywhere` + `min-width:0` on the value make certification numbers / long
model strings wrap inside their column instead of overflowing, at **all** widths — a strict improvement, no
regression for normal values.

## 4. Is a presenter wording change necessary? — NO

The awkward "No adverse reports on the SCA registry" is resolved by the stacking fix (the value gets the full card
width on its own line). **No presenter or `ItemStateLabels` change is required**, so per the brief none is proposed.

Separately, the optional shorter CLEAR label **"Clear — no adverse reports"** was evaluated:
- `ItemStateLabels::registryStatus()` default is the **shared** source consumed by the Passport presenter **and**
  `Collector/CollectionService` — changing it there would alter the Collector surface too (blast radius = 2
  surfaces) and re-open the deliberately-unified terminology (SCA-STATUS-TERMINOLOGY-CONSISTENCY).
- A passport-only shorter label would require a view/presenter-specific override, re-introducing exactly the
  divergence that unification removed.
- **Recommendation:** do **not** change the CLEAR wording as part of this mobile fix. If the operator still wants
  the shorter label, treat it as a **separate, explicit decision** and prefer changing the shared
  `ItemStateLabels` default (so all surfaces stay consistent) rather than a passport-only fork. Adverse wording and
  severity semantics stay **exactly as approved** (no change proposed or implied).

## 5. Optional, low-risk polish (operator's discretion)
- **"About this passport" heading:** the trust-copy block (`show.blade.php:131-135`) currently leads with a bold
  "Second Chance Authenticators". It can be presented under a small **"About this passport"** label with the
  **exact same sentence** (no meaning change). Purely a visual section label; include or omit.
- Mobile padding/gaps are modestly tightened inside the `@media` block above (`.card` 22→18px, row 11→9px) — enough
  to feel intentional without crowding. No change above 480px.

## 6. Impact analysis

- **Desktop/tablet:** pixel-identical for normal content — the classes mirror the current inline values exactly and
  the `@media` block only applies ≤480px. `min-width:0`/`overflow-wrap` change rendering only for pathologically
  long values (which already wrap badly today) → improvement, not regression.
- **Adverse-state / trust-safety hierarchy:** **fully preserved.** The adverse warning banner
  (`show.blade.php:34-39`) is a separate block with its own inline styles, not a `.row`; the fix touches only the
  detail rows below the image. The banner still renders first and dominant, before the authenticity badge. The fix
  must not reorder or restyle the banner.
- **Privacy/security:** CSS/view-only. No new fields, no `PublicAllowlist` change, no CSP change (the `<style>`
  block is already permitted by `style-src 'unsafe-inline'`; **no inline/external JS**, so no `script-src`
  relaxation). Logo delivery (inline data URI), `/storage` policy, tokens, owner/collector/staff privacy, SCA-038
  shape — all untouched.
- **No JS / no rebuild:** confirmed — raw CSS added to a hand-written inline `<style>`; no Tailwind compile, no
  Vite, no JavaScript. CSP-compatible as-is.

## 7. Regression tests to add/update (later)
Extend `PublicPassportSafetyTest` (or `PublicPassportTest`), still read-only against the disposable test DB:
- Response `<style>` contains `@media (max-width: 480px)` and the stacking rule (`flex-direction:column`) +
  `overflow-wrap` — proves the responsive CSS is delivered (headless tests can't measure pixels).
- Detail rows carry `class="row"`/`class="row-value"` (structure migrated off inline strings).
- **Long-value resilience:** a certified item with an very long unbroken brand/model and a long certification
  number returns 200 and renders those values (present, not dropped). CSS wrapping can't be pixel-asserted headless;
  assert the value text is present + the wrapping CSS exists.
- **Regressions unchanged:** adverse banner still appears **before** the authenticity block (`assertSeeInOrder`,
  re-use existing); CLEAR registry label unchanged ("No adverse reports on the SCA registry") if no wording change;
  no `<script>`; CSP header unchanged; preview still default-off; a GET mutates nothing.

## 8. Implementation scope / forbidden scope

**In scope (view/CSS only, 2 files):** `layout.blade.php` (`<style>` additions: row classes + one
`@media (max-width:480px)` block) and `show.blade.php` (inline row strings → classes; optional "About this
passport" label). Tests as §7. No presenter change. No `ItemStateLabels` change (unless the operator separately
elects the shared CLEAR-label change).

**Forbidden (unchanged):** `PassportResolver`, 200-vs-404 behavior, SCA-038, registry/status semantics,
certification/authentication semantics, QR/tokens, ownership/privacy, provenance/domain services, DB/schema/
migrations, routes, ACL, `PublicAllowlist`, CSP/security headers, `/storage` policy, logo delivery mechanism,
`SCA_PUBLIC_PREVIEW`, Collector/Admin surfaces, infrastructure/environment. **Retired/Invalidated 200-vs-404 policy
remains explicitly deferred and untouched.** The trust/safety hierarchy (adverse warning dominant and before the
authenticity block) must be preserved.

---
**Record:** governance only. ACTIVE/NEXT unpromoted. STOP for ChatGPT/operator review — do not implement
automatically. See [[sca-public-passport-trust-safety-audit]], [[sca-status-terminology-consistency-audit]],
[[report-to-github-first]].

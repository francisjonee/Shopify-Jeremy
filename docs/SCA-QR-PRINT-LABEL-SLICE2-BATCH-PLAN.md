# SCA QR / Label Workflow — Slice 2 (batch / sheet printing): discovery + implementation plan (PLAN ONLY)

**Date:** 2026-10-06 · **Status: DISCOVERY + PLAN ONLY. No code, no deployment, no DB mutation.** · Deployed baseline `0ca7158`, migrations **120**, FP `62b2e42fe409b4ec91f3381b35da819e`. Continues the Production QR/Label task (Slice 1 deployed, gov `92d57125`). For ChatGPT audit.

**Goal:** let a non-technical staff member print **multiple** existing SCA QR labels on **one sheet** — Eyewear list → select eligible items → "Print QR labels" → a print-ready sheet with one Slice-1-style label per selected item. Read-only; reuse Slice 1's renderer; no second encoder.

---

## 1. Discovery — current deployed implementation

- **Eyewear list is a CUSTOM Blade card grid**, not a Krayin DataGrid: `EyewearItemController::index()` builds a filtered/sorted query and `->paginate(20)`, rendering `eyewear/index.blade.php` as a `@foreach ($items as $item)` card grid. There is **no existing checkbox / mass-action / bulk infrastructure** in this view, and **Krayin's DataGrid mass-action machinery is not used here** — so there is nothing to reuse from Krayin; the right move is a minimal multi-select on the existing custom grid.
- **Eligibility is already known at render time:** `index()` selects `s.active_qr_identifier_id as cs_qr` per row (presence-only). The card badges already reflect "active QR". So the view can show a selection checkbox **only** for items where `cs_qr` is non-null — eligibility-aware selection for free, no extra query.
- **POST + CSRF already works here:** the page already has a POST form (`admin.sca.eyewear.lookup`) and a GET filter form, both in the admin `web` group (CSRF active). A new POST form is a known-good pattern.
- **Slice 1 renderer (the one encoder):** `EyewearItemController::renderActiveQrSvg(int $id): ?array` reads the projection's active QR token and returns `{svg, public_ref}` or null (missing/no-active-QR). `qr()` (download) and `qrLabel()` (single print view) both call it. Slice 2 reuses **this same private method** directly (batch method on the same controller) → guaranteed identical QR for every printed label, zero duplication, no new encoder.
- **Single-label presentation:** `eyewear/qr-print-label.blade.php` is a standalone print page (QR + `public_ref` + "Scan to verify authenticity" + "Second Chance Authenticators" branding + `window.print()` + `@media print` ~30 mm QR, quiet zone preserved, no raw token text). Slice 2 reuses this exact label markup via a shared partial.

## 2. Minimal UI flow
1. Staff filter/sort the eyewear list as today (≤20 items/page).
2. Each **eligible** card (has an active QR) shows a checkbox; ineligible items show no checkbox (muted "no active QR" note).
3. A "**Print QR labels**" submit button (shows a live count via tiny progressive-enhancement JS; works without JS too) submits the checked ids.
4. Server renders a **print-ready sheet** (new tab) — a CSS grid of Slice-1 labels, one per eligible selected item, with a non-printing summary of any omitted (ineligible) items and a Print button.

Selection is **within the current filtered page** (≤20). Cross-page / "select all matching filter" is intentionally **out of scope** (see §9).

## 3. Proposed route / controller / view changes (smallest)
- **Route** (`admin-routes.php`, EyewearItemController group, prefix `sca/eyewear`):
  `Route::post('qr/labels', 'qrLabelsBatch')->name('qr.labels')->middleware('sca.can:sca.eyewear.view');`
  Full name `admin.sca.eyewear.qr.labels`, URI `admin/sca/eyewear/qr/labels`. Collection route (no `{id}`), POST only. No collision with `{id}/qr*` (those are `where id [0-9]+`; `qr` is non-numeric).
- **Controller** (`EyewearItemController`): add `qrLabelsBatch(Request $request): View|RedirectResponse`:
  - validate `ids` = required array, each `integer`; dedupe; enforce `MAX_BATCH_LABELS` (proposed **50**) — over-cap → redirect back with a neutral message (renders nothing);
  - empty/none → redirect back with "select at least one item with an active QR";
  - loop ids calling **`$this->renderActiveQrSvg($id)`** (the Slice 1 encoder); collect eligible `{public_ref, svg}`; ids returning null → `skipped[]` (no active QR / not found) — never throws, never mutates;
  - if ≥1 eligible → render `eyewear.qr-print-labels` with `labels[]` + `skipped[]`; if 0 eligible → same sheet view showing only the skipped notice (no 404).
  - add `private const MAX_BATCH_LABELS = 50;`.
- **Views:**
  - **new** `eyewear/_qr-label-card.blade.php` — the single label card markup (QR SVG + `public_ref` + caption + branding), extracted so single + batch are byte-identical. (Slice 1's `qr-print-label.blade.php` refactored to `@include` it — small modify, no behavior change.)
  - **new** `eyewear/qr-print-labels.blade.php` — standalone print sheet: CSS grid of `_qr-label-card`, `@media print` page-breaks, Print button, non-printing skipped-summary.
  - **modify** `eyewear/index.blade.php` — wrap the results grid in `<form method="POST" action="{{ route('admin.sca.eyewear.qr.labels') }}" target="_blank">@csrf …</form>`; per-eligible-item `<input type="checkbox" name="ids[]" value="{{ $item->id }}">`; a "Print QR labels" submit + small count JS. (The batch form is sibling to—not nested in—the existing filter/lookup forms.)

## 4. Batch-size & eligibility behavior
- **Max batch:** server-enforced `MAX_BATCH_LABELS = 50` (defensive; over-cap rejected with a message). The UI naturally yields ≤20 (one page), so 50 is generous headroom; it also bounds memory on the swapless host (≤ ~50 × ~58 KB SVG ≈ ~3 MB HTML).
- **Ineligible in selection:** an item without an active QR (or an unknown id) is **silently skipped into a non-printing "omitted" list**, never an error and never a mutation. A mixed selection prints the eligible labels and reports the rest. (Checkbox-only-on-eligible makes this rare, but the server re-checks defensively via the same `renderActiveQrSvg` null path.)
- **All-ineligible / empty:** friendly redirect-back or a sheet showing only the omitted notice — no 404, no exception.

## 5. Print-sheet layout (A4 / Letter) — feasibility confirmed
A4 210×297 mm (Letter 216×279 mm) with 10 mm margins → ~190×277 mm usable. A label cell = 30 mm QR + padding + ref/caption ≈ **44 mm wide × 52 mm tall** → **4 columns × 5 rows = 20 labels/page**; 50 labels ≈ 3 pages. Implementation: CSS grid (`grid-template-columns` ~`repeat(4, 44mm)`), each cell `break-inside: avoid`, QR fixed `30 mm` square (baked 4-module quiet zone preserved as in Slice 1), `@media print { @page { margin: 10mm } }`, toolbar/summary `display:none` on print. So ~30 mm QRs fit cleanly in a practical grid on both A4 and Letter.

## 6. Security / ACL
Reuse the **existing `sca.eyewear.view`** permission (same as Slice 1's single label + the SVG download; the list staff already view). Admin-prefixed + auth + ACL; **not public**. No new permission needed for the smallest version. (A dedicated `sca.eyewear.qr.print` could be split out later if separation is desired — noted, not proposed now.) **POST (not GET)** carries the selected ids in the body: it avoids any browser/URL length limit for large selections, matches the existing lookup-POST pattern, and is CSRF-protected. The POST is **read-only** (renders a view; no writes).

## 7. Guaranteeing one shared renderer
`qrLabelsBatch` calls the identical `renderActiveQrSvg($id)` used by `qr()` and `qrLabel()`. No new QR library/options/path. A test asserts each batch-sheet label's SVG is byte-identical to that item's single-download SVG, locking the invariant.

## 8. Required automated tests (`tests/Feature/Sca/QrLabelsBatchTest.php`, `sca_domain_test`, DatabaseTransactions)
- **ACL:** guest → redirect to admin login; staff without `sca.eyewear.view` → 403.
- **happy path:** POST N certified ids → 200 sheet with N labels; each shows its `public_ref` + "Scan to verify authenticity" + branding.
- **same renderer:** each label's `<svg>` equals that item's `/admin/.../qr` download bytes (single shared encoder).
- **mixed eligibility:** some ids lack an active QR → eligible printed, ineligible in the omitted list, HTTP 200, **zero mutation**.
- **all ineligible / unknown id:** no 404/exception; omitted notice; no label; no mutation.
- **empty selection:** validation redirect-back, nothing rendered.
- **over-cap (>50):** rejected with message, nothing rendered.
- **zero provenance mutation:** QR identity/lifecycle/projection fingerprint + domain counts unchanged by the POST; `is_production` untouched.
- **method/route:** GET to `qr/labels` not registered (405/404); route is POST + admin-prefixed.
- **no new public route:** `admin.sca.eyewear.qr.labels` is admin-prefixed; `/p/{token}` unchanged.
- **regression:** full `tests/Feature/Sca` (incl. Slice 1 `QrPrintLabelTest`, `QrArtifactTest`) stays green.

## 9. Exact expected file scope
**New (3):** `packages/Sca/Registry/src/Resources/views/eyewear/qr-print-labels.blade.php`; `packages/Sca/Registry/src/Resources/views/eyewear/_qr-label-card.blade.php`; `tests/Feature/Sca/QrLabelsBatchTest.php`.
**Modified (3):** `packages/Sca/Registry/src/Http/Controllers/EyewearItemController.php` (add `qrLabelsBatch` + `MAX_BATCH_LABELS`); `packages/Sca/Registry/src/Routes/admin-routes.php` (add POST route); `packages/Sca/Registry/src/Resources/views/eyewear/index.blade.php` (selection form + checkboxes + submit). Optional minor modify: `eyewear/qr-print-label.blade.php` to `@include` the shared partial.
**NOT touched:** schema/migrations, `is_production`, QR identity/reissue, public passport/resolver, Shopify, SMTP, Caddy, Docker, Krayin core/vendor, `.env`, composer. No new public route.

## 10. Risks / what could make it larger than expected
- **Cross-page selection** ("select all matching the current filter", or persisting selection across pagination) — needs session/state or filter-replay-to-ids; **explicitly deferred**. Slice 2 = current-page selection only. (Biggest scope risk; keeping it out keeps Slice 2 small.)
- **"Select all on page" convenience** — a tiny JS checkbox; low risk, optional.
- **No-JS behavior** — the form must work without JS (plain checkboxes + submit); the count/select-all is progressive enhancement only. Admin Tailwind is pre-compiled, so any needed styles go via `@push('styles')`/inline (known gotcha); the standalone print sheet carries its own CSS like Slice 1 (no Tailwind dependency).
- **Three forms on the index page** — the new POST batch form must be a **sibling** of (not nested in) the existing GET filter and POST lookup forms (HTML forms can't nest); checkboxes live inside the batch form only.
- **Memory** — bounded by the 50-cap (~3 MB HTML worst case); server only builds the string, the browser renders. Safe on the swapless host.
- **Pagination + selection** — paginating (GET links, outside the form) drops the current checkbox selection; acceptable for Slice 2, documented for staff.

## 11. Recommendation
Approve the above as the **smallest production-safe Slice 2**: current-page multi-select on the existing custom grid → POST ids → batch sheet reusing Slice 1's `renderActiveQrSvg` and a shared label-card partial; `sca.eyewear.view` ACL; 50-cap; ineligible-skip; A4/Letter 4×5 grid. No new encoder, no mutation, no schema, no new public route. Defer cross-page selection, PDF export, label presets, and printer-specific integration.

**DISCOVERY/PLAN ONLY — no code/deploy/DB mutation performed.** See [[sca-production-qr-label-workflow-discovery]], `docs/SCA-QR-PRINT-LABEL-SLICE1-IMPLEMENTATION.md`, `docs/SCA-QR-PRINT-LABEL-SLICE1-DEPLOY-RESULT.md`.

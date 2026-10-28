# SCA — Shopify Phase 2 Slice C: Linked-Product Visibility (staff UI)

**Authorized development-branch implementation. Dev branch only — NO production migration, deploy, or live Shopify change; NO new ownership/passport records; NO Option C.** Read-only presentation over the Slice A+B link data. Static checks PASS (`php -l` clean; Blade balanced). Focused tests written but **NOT run** (DB-changing; require separate disposable-DB authorization). 2026-10-28. **STOP for review.**

## SHA & scope

- Branch `feat/sca-shopify-phase2-visibility` off deployed `91b88f1` → **`992e048b1a6991aca3f7fae1f760a4dfb72fd309`** (pushed `origin`). Live `main`/prod untouched.
- **4 files, +78/−5.** Scope is read-only presentation: two controller **read-query** methods, two views, one test. **No migration, no route, no ACL, no service change.**
  - `Registry/src/Http/Controllers/EyewearItemController.php` — `shopifyLinkPanel()` enriched; `index()` adds a bounded linked-map.
  - `Registry/src/Resources/views/eyewear/partials/shopify-link.blade.php` — detail panel enrichment.
  - `Registry/src/Resources/views/eyewear/index.blade.php` — registry card indicator.
  - `tests/Feature/Sca/ShopifyLinkVisibilityTest.php` (new).

## Objectives met

1. **Linked product name / variant / SKU / Shopify reference on the detail page** — the "Shopify link" tab now shows the live product title + vendor, variant title, SKU (live, falling back to the stored snapshot), the Shopify reference (`product_id / variant_id`), shop, and linked-at.
2. **Count of physical items linked to each variant** — "Physical pairs linked to this variant: N" (single `COUNT` over the shop+variant, bounded).
3. **Clear linked/unlinked indicator in the registry** — each card shows `Shopify ✓` (linked, active), `Shopify (inactive)` (linked but archived/unavailable), or `No Shopify link`.
4. **Historical links preserved on archive/delete** — the display reads the link row's `*_snapshot` columns, which always survive; eligibility/visibility is never a reason to delete a link. Nothing in Slice C writes or removes links.
5. **Archived/unavailable products shown inactive without auto-unlinking** — a LEFT JOIN to the live catalog: archived/draft product → "Inactive in catalog"; missing catalog row (deleted) → "Unavailable in catalog", rendered from the snapshot. The link row remains intact (asserted by tests).
6. **UI read-only except the already-authorized actions** — Slice C adds only reads; the link/relink/unlink controls remain gated behind `sca.eyewear.shopify.link` (unchanged from Slice B). A viewer with `sca.eyewear.view` but not the link ACL sees the read-only info but none of the mutation controls.
7. **Efficient queries (no N+1)** — the registry indicator uses ONE query over just the current page's ≤20 item ids (LEFT JOIN to variant status), keyed for O(1) lookup; the detail panel uses two bounded queries (current link + sibling count) plus the existing audit query. No per-row catalog lookups; no scan of the 4565-product / 5330-variant catalog.
8. **Focused tests** (written, not run) — see below.
9. **Provenance untouched** — no change to authentication/ownership/certification/QR/claim reads or writes; Slice C never queries or mutates those beyond the pre-existing detail panels.

## Tests — `ShopifyLinkVisibilityTest` (NOT run; needs separate disposable-DB authorization)

Disposable-DB hard guard. Cases: detail shows product name/variant/SKU/reference; sibling **pair count = 2** across two items on one variant; **archived** product → "Inactive in catalog" with the link row still present; **deleted** catalog product → "Unavailable in catalog" from the snapshot with the link preserved; unlinked detail message; registry index shows **linked / inactive / unlinked** indicators together; a **viewer** (no link ACL) sees the read-only info but not the relink search (`id="sl_q"`) or the `/admin/sca/shopify/unlink` form, while a link-ACL staffer does.

## Static verification

- `php -l` clean on the controller and the test.
- Blade directives balanced in both views (the apparent `@push` imbalance is a comment mention on line 8; the real `@push('styles')` on line 9 is closed on line 47).
- No DB connection, no app boot, no dev-vendor build against production.

## Safety

Dev branch only; prod `main` (`91b88f1`) and the live bind-mount untouched. No migration (Slice C adds none), no deploy, no live Shopify call, no new ownership/passport, no Option C. The DB-backed tests are deferred to a separate authorized disposable-DB run.

**STOP — Slice C implemented on the dev branch (`992e048`); review before any DB test, merge, or deploy. Separate OPEN: the first genuine `products/*` webhook verification on the next normal Shopify product change.**

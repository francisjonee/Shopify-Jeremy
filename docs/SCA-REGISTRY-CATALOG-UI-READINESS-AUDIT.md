# SCA-REGISTRY-CATALOG-UI — Readiness / Planning Audit (READ-ONLY)

**Date:** 2026-09-30 · Deployed baseline `5e02f3e`. **Planning only — nothing implemented.**

## Goal (from the operator)

Give the SCA eyewear registry a **catalog-style UI that looks and feels exactly like Krayin's core Product pages**, but
keep all data/logic on the **already-built SCA side** (system of record). Prepare for a **later Shopify product sync**
(image/SKU/price) — **no Shopify work in this task**. Decisions taken: eyewear is **one-of-one** (1 item = 1 QR = 1
cert); the catalog lives **on the SCA eyewear item** (not Krayin core `products`); match core **visually** by reusing
core's own Blade components.

## Why this is low-risk (addresses the "bugs / not connected" worry)

The SCA registry is **not** a from-scratch island: `eyewear/index.blade.php` and `show.blade.php` already open with
`<x-admin::layouts>` — the same top-level shell core Products uses — so they already inherit Krayin's header, sidebar,
mega-search, auth, ACL and menu. The gap is only the **inner markup**. We close it by rendering SCA data through the
**same core components** core Products uses (verified present and reusable): `x-admin::layouts`, `breadcrumbs`,
`accordion`, `activities`, `activities.actions.note`/`file`, `datagrid`, `media`, `tags`, `attributes.view`, `tabs`.
No Krayin core/vendor file is edited (the SCA convention throughout) — we only *consume* published `x-admin::*`
components from the SCA views.

## Data model — smallest additive change

`sca_eyewear_items` today: `public_ref, model_name, brand, frame_serial, year, country_of_origin, materials,
original_specifications, intake_type`. Add **nullable catalog fields** (mutable presentation, distinct from immutable
provenance):

- `sku` (nullable, string) — catalog SKU (Shopify-sourced later; manually settable now).
- `image_path` (nullable, string) — public catalog image (stored on a **public** disk, see below). Optionally
  `image_disk`.
- `list_price` (nullable, decimal) + `currency` (nullable) — optional, for the catalog card. (Confirm if wanted now.)
- Later Shopify sync (out of scope) will fill these + reuse the existing `sca_shopify_sale_links.shopify_product_id`.

**Guardrail:** these are **catalog** attributes — mutable and re-syncable — and are explicitly **not** provenance. They
are separate from the append-only identity metadata (brand/model/etc. governed by SCA-046) and from the immutable QR/
certification/ownership ledgers. A plain staff edit is appropriate for them (new narrow ACL `sca.eyewear.catalog`, or
fold into an existing one — decision). They do **not** go through the append-only metadata-correction flow.

**Image storage:** catalog images are **public** (they render on the public passport), so they must use a **public
disk**, kept entirely separate from the existing **private** documents/evidence store (`DocumentController`, streamed,
never public). No evidence file ever becomes a catalog image and vice-versa.

## UI mapping — copy core, adapt where the domain differs

### A. Detail page (`eyewear/show.blade.php`) → mirror `products/view.blade.php`

Core layout = **left sticky info panel** + **right activities/tabs panel**. Reorganize the current single-column stack
(9 cards) into that two-panel shape, **preserving every existing datum, action, form, route and ACL check**:

| Core product view | SCA eyewear view |
|---|---|
| Left: breadcrumbs, tags, **title (name)**, **SKU**, Note/File actions | Left: `x-admin::breadcrumbs`, title (**brand + model**, fallback `public_ref`), **SKU**, **image** via `x-admin::media`, quick actions |
| Left: `@include products.view.attributes` → `x-admin::accordion` "About Product" | "About Item" `x-admin::accordion` — public_ref, brand, model, frame_serial, year, country, materials, original_specs, intake_type, created (label/value rows) |
| Right: `x-admin::activities` tabs = All / Notes / Files / **Change-logs** / *Inventory* | Right: tabs = **Overview / Authentication / Certification & QR / Documents / History (change-logs) / Service** — **drop Inventory** (one-of-one) |

The right-panel sections are the existing cards, moved under tabs: Authentication (record/finalize/certify), Certification
& SCA Identity (incl. the **Download printable QR (SVG)** we shipped, cert PDF, correct-certification, cert history),
External-intake claim link, Service history, Documents & evidence (private), Provenance summary + ownership-history link,
Registry status + metadata-correct. **All routes/forms/ACL gates copied verbatim** — pure re-layout.

**Nuance — do NOT copy core's free inline edit.** Core's "About" card uses the EAV `x-admin::attributes.view` with
`allow-edit=true` → free inline update. SCA identity fields are governed (append-only SCA-046; brand/model locked on
snapshot-less legacy certs). So the "About Item" card renders **read-only rows** + the existing **"Correct item
metadata"** governed link — never core's blind inline edit. Only the new **catalog** fields (sku/image/price) get a
simple edit.

**Nuance — activities timeline.** Core's `x-admin::activities` is backed by Krayin's note/file/system activity store
tied to an entity. SCA has its own append-only ledgers (certification/ownership/QR/service/status events). Recommended:
reuse the `x-admin::activities` **shell/tabs** and feed the **"change-logs" / history tab from SCA's own events**
(rendered in the native timeline style), rather than wiring SCA events into Krayin's activity tables. Krayin Notes/Files
on the eyewear item are optional (could be enabled later); the meaningful "history" is the provenance ledger. (Decision:
enable Krayin Notes/Files too, or history-only.)

### B. Catalog index (`eyewear/index.blade.php`) → catalog grid matching core

Core index = sticky header (breadcrumbs + title + create button) + `x-admin::datagrid`. SCA-051 already gives rich
filters/search/sort/pagination + the POST QR-lookup. Two presentation options:

- **(Recommended) Catalog card grid** — responsive cards with **thumbnail + brand/model + SKU + cert/QR/lifecycle
  badge**, keeping the SCA-051 filter bar above it. This is the true "catalog" look with images.
- **(Alternative) Core datagrid** — an `EyewearItemDataGrid` (JSON-backed) with a thumbnail column — pixel-matches core's
  list, but is a table, not a catalog grid, and re-implements SCA-051 filtering inside the datagrid.

Recommend the card grid (reuses existing controller/filters; adds a thumbnail). Keep the sticky header + create button
styled like core.

### C. Collector "client side" — passport + My Collection enrichment

Krayin core products have **no** customer-facing view; the SCA customer surfaces already exist and are the right place:

- **Public passport** (`/p/{token}`, SCA-038 Option A): add **image + SKU** to the rendered page. **Guardrail:** extend
  the `PassportPresenter` **allowlisted DTO** with `image_url` + `sku` **only** — never the raw token, owner, staff, or
  any internal id; keep the strict 32-hex gate and the **constant-shape 404** untouched. Image/SKU are public catalog
  data, so this is privacy-safe.
- **Collector "My Collection"** (`collection/index.blade.php`, `show.blade.php`): show the thumbnail + SKU alongside the
  existing authentication/QR/certification the owner already sees.

## Guardrails / invariants (unchanged by this task)

- **No Krayin core/vendor edits** — SCA views only consume published `x-admin::*` components.
- **Zero change to provenance**: QR identity + triggers, certification/authentication/ownership ledgers, projection,
  `is_production`, and the **SCA-038 resolver behaviour** (200/constant-shape 404) are untouched. The only passport
  change is additive allowlisted fields.
- **Catalog ≠ provenance**: new fields are mutable presentation; they never gate authenticity or touch the QR/cert.
- **Private evidence stays private**: catalog image uses a public disk, fully separate from the streamed private
  document store.

## Proposed slices (each governed: plan → approve → implement → review → deploy)

1. **Slice 1 — data + admin detail page.** Migration (nullable `sku`, `image_path`[, `list_price`,`currency`]); catalog
   image upload (public disk) + set-SKU (staff, new ACL); refactor `show.blade.php` to the core two-panel layout
   (left info + image + SKU + "About" accordion; right tabs) reusing `x-admin::*`; history tab from SCA events. **No
   Shopify.**
2. **Slice 2 — catalog index.** Card grid with thumbnails + SKU + badges, core-styled header, retaining SCA-051 filters.
3. **Slice 3 — client side.** Passport DTO allowlist +`image_url`+`sku`; My Collection thumbnail + SKU.

(Optionally hide the unused core **Products** menu + delete the stray "Test" product — trivial, separate.)

## Out of scope (explicitly)

Shopify connect/sync/webhooks (SHOPIFY-CONNECT-009, now domain-unblocked but not this task); `is_production`; SMTP;
`:8080` retirement; `SESSION_SECURE_COOKIE` Phase B; DNS/Caddy; any provenance/QR/cert logic change; Krayin core edits.

## Open decisions for the operator

1. Include `list_price` + `currency` now, or just `sku` + `image`?
2. Catalog index: **card grid** (recommended) vs core **datagrid** table?
3. History tab: SCA-provenance-history only (recommended), or also enable Krayin Notes/Files on the item?
4. Catalog-field edit: new `sca.eyewear.catalog` ACL, or reuse an existing permission?
5. Also hide the core Products menu + remove the "Test" product?

## Recommendation

Proceed with **Slice 1** first (data model + core-style admin detail page). It's additive, no core edits, no provenance
change, and immediately delivers the native look on the page you screenshotted. I'll bring a focused implementation for
pre-merge review. **Nothing implemented yet — awaiting approval + the 5 decisions above.**

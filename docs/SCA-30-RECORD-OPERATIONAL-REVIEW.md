# SCA — 30-Record Inventory Operational Readiness Review (read-only)

**READY. All 30 catalog-linked inventory records (ids 7–36) are fully visible and manageable from the
existing staff admin interface: they appear in the registry listing and item-detail with their `public_ref`
and a pending-authentication ("Intake / Not authenticated") status, their missing physical details render as
"—" (unknown, never invented), and the metadata-correction workflow is reachable and permits staff to fill
brand/model/serial/etc. because the items carry no certification. No blockers found.** Read-only at prod
`6e36aa7`; no record modified, no import/auth/cert/QR. 2026-11-02.

> Written for: the owner (Jeremy) + staff who will manage this inventory from the dashboard.

## 1. All 30 records exist and are correctly linked (task 1, 3, 5)
Verified read-only against prod: **30 items (ids 7–36), 30 Shopify-variant links** to exactly the expected
variants (Batches 1–3). Every record: `intake_type = sce_presale`; **brand/model/serial/year/country/
materials/specs = NULL**; **0 authentications, 0 certifications, 0 QR**. The current-state projection
(`sca_item_current_state`) has a row for all 30: **`lifecycle_state = INTAKE`, `registry_status = normal`,
no owner/cert/qr** — i.e. correctly pending authentication.

## 2. Staff registry listing (`GET /admin/sca/eyewear`, ACL `sca.eyewear`) — WORKS
`EyewearItemController::index` (SCA-051) renders each item as a card:
- **Title** = `brand model` or, when both are blank (all 30), falls back to the **`public_ref`** — nothing
  invented (`eyewear/index.blade.php:209`). **SKU** shows `—` when null (`:211`). The `public_ref` is shown
  (`:212`).
- **Status pills**: lifecycle = **"Intake"** (`ItemStateLabels::lifecycleAdmin('INTAKE')`), registry =
  "normal"; **no** Certified/QR pill (none exist); and a **"Shopify ✓"** pill because each item has an
  active-variant link (`:226–228`, `$shopifyLinks` built from `sca_eyewear_item_shopify_variant`).
- **Search/filter**: `public_ref` (and brand/model/serial) search, intake-type / registry / lifecycle /
  owned / sale filters, allowlisted sort — all read-only and paginated. A staffer can find the 30 by
  searching `SCA-` or filtering lifecycle = Intake.

## 3. Item detail (`GET /admin/sca/eyewear/{id}`, ACL `sca.eyewear.view`) — WORKS
`EyewearItemController::show` returns a real 404 for a missing id (not a raw abort) and renders:
- **Physical fields** Brand / Model / Frame serial / Year / Country / Materials / Original specifications
  each as **`{{ $value ?: '—' }}`** (`eyewear/show.blade.php:160–166`) → every NULL shows "—" (unknown, not
  invented). Intake type shows `sce_presale` (`:167`).
- **Status**: Lifecycle state **"Intake"**, Registry status "normal" (`:190–191`); the Authentication tab
  shows **"Not authenticated"** / "No authentication inspections recorded yet" (`:274,:283`).
- **Shopify link** section present (Phase-2 Slice B) showing the linked catalog variant.

## 4. Metadata-correction workflow reachable + usable (task 4) — WORKS
- The detail page shows a **"Correct item metadata"** link to
  `admin.sca.eyewear.metadata.correct.confirm`, gated by **`sca.eyewear.metadata.correct`**
  (`show.blade.php:170–172`); routes `GET/POST metadata/correct` exist.
- **Critical for follow-on verification:** `ItemMetadataCorrectionController::pdfFieldsLocked` locks
  brand/model **only when the item has a *current certification* without an SCA-045 snapshot**; for an item
  with **no certification it returns `false`** (`:86–88`). Since all 30 are uncertified, **brand, model,
  frame_serial, year, country, materials and original specifications are all editable** via the governed,
  append-only correction flow. Staff can record verified physical identity here once each pair is inspected.

## 5. UI problems / blockers (task 6)
**None that prevent management.** The records list, open, show pending status, display unknowns honestly as
"—", carry the Shopify-link badge, and expose an editable (unlocked) metadata-correction path. Minor,
non-blocking observations:
- Listing cards title uncertified items by `public_ref` (expected, since brand/model are blank) — staff
  identify them by the Shopify ✓ link / variant until physical details are entered. The catalog product
  title is not shown on the card; staff needing it can resolve the variant via the linked Shopify record or
  the detail page's Shopify-link section. (Enhancement only, not a blocker.)
- Authentication / certification / QR actions are correctly **gated** behind their own ACLs and require the
  per-pair human workflow — by design, not a defect.

## Safety posture (this task)
Read-only. No record modified; no import, authentication, certification, QR, ownership, or claim; no Shopify
API request or store change; no production DB write; no deployment/migration. Secure-claim RC `4bd88d2` not
activated. Prod unchanged at `6e36aa7`.

**STOP — Operational readiness CONFIRMED: all 30 catalog-linked UNCERTIFIED records (ids 7–36) are visible
and manageable from the existing staff dashboard — registry listing + item-detail show each `public_ref`
with a pending "Intake / Not authenticated" status, NULL physical details render as "—" (never invented),
and the metadata-correction workflow is reachable and unlocked for these uncertified items so staff can fill
verified brand/model/serial/etc. No blockers. Next = per-pair physical verification + metadata entry, then
authenticate → certify → QR labels. Nothing modified; prod `6e36aa7` unchanged.**

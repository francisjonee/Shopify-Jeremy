# SCA-COLLECTOR-ITEM-DETAIL-PARITY — Readiness / Planning Audit (READ-ONLY)

**Date:** 2026-10-01 · **Deployed baseline:** `444c067` (Catalog UI Slices 1–3 DONE).

> **PRE-MERGE CORRECTION PUSHED (push-only) 2026-10-01 — awaiting re-review.** New HEAD **`df05859`** (2 commits on
> base `444c067`: `14f30a6` + `df05859`), **4 files, view-only.** Review HOLD found `.tabbar{display:flex;flex-wrap:wrap}`
> was **dead CSS** (no `.tabbar` element → responsive bar not realized structurally). Fixed structurally (still CSS-only/
> no-JS, `~`/`+` selectors intact): one **`.tabhost`** flex-wrap container holds the radios (`position:absolute`, out of
> flex flow but DOM-adjacent to labels + DOM-siblings of panels), the labels as flex items (the wrapping bar), a
> full-width **`.tabrule`**, and full-width panels below; dead `.tabbar` removed. New **rg8** asserts the structural
> contract (one `.tabhost`; 5 radios/labels/panels; radio→label adjacency; radios before panels; `.tabhost` flex-wrap +
> `:checked ~ .tabpanel` CSS present; **no `tabbar`**). Focused **8/50**; full `tests/Feature/Sca` **687 passed**; live
> render: tabhost=1/radios=5/labels=5/panels=5/tabrule=1, dead `.tabbar` gone, flex-wrap present. Pilot restored to
> `444c067` (parity not live, dev pruned, fp `a920dc1c…` / migrations 119 unchanged, healthy). Still view-only; no
> backend/schema/route/ACL change.
>
> _(Initial push:)_ Feature branch `sca-collector-item-detail-parity` @ **`14f30a6`**, base `444c067`, **1 commit, 4 files** (view-only). Operator
> decision honored: **KEEP** the collector's Report Lost/Stolen/Recovered + Transfer actions under a separated
> **"Manage item"** section in Overview (routes/forms/authorization/mutation unchanged). The audit's **view-only** path
> held — **no service/controller/DTO/schema/route/ACL change**, no Krayin core/vendor edits, no mutation. `collection/
> show.blade.php` rewritten to two-panel + **CSS-only tabs** (hidden radios + `:checked ~`, no JS) over the owner-safe
> DTOs; `layout.blade.php` gained inline tab/two-panel CSS + a per-page wide-wrapper hook (responsive: desktop
> two-panel, phone stacks, labels wrap). Terminology **"Registered to you" / "You"** (never "Collector #N"). Tabs:
> Overview (status/registry/ownership/passport/Manage-item), Authentication (owner-safe read-only — no staff
> table/refs/notes/actions), Certification (number/date + SCA-048 history — no cert/QR tokens, source-auth-id, generate-
> PDF/correct/download-QR), Documents (is_public=1 only via opaque-handle download — no private, no upload), History
> (neutral ownership "You" + service). Tests `CollectorItemDetailParityTest` (7): five tabs+identity; **no staff-only
> leak** (frame_serial, QR+cert tokens, path, staff ref `4242`, `Collector #`, is_production, private-doc); You
> terminology; retained owner actions; **non-owner & previous-owner-after-transfer → 404**; public-document boundary;
> zero mutation. Focused 7/35; full `tests/Feature/Sca` **686 passed / 3661**; `php -l` clean. Live (feature branch)
> render of collector 1's item 3: 200, two-panel, "Registered to you", "Manage item", no "Collector #". Pilot restored
> to `444c067` (parity view not live, dev pruned, fp `a920dc1c…` / migrations 119 unchanged, healthy). Report (app repo):
> `docs/task-reports/SCA-COLLECTOR-ITEM-DETAIL-PARITY.md`. **Not merged/deployed.**

**Planning section below — original audit (read-only, nothing implemented at audit time).** ACTIVE = NONE / NEXT_TASK = NONE.

**Goal:** redesign `/collector/collection/{ref}` so the collector item-detail *visually* follows the new admin eyewear
detail page (left: image + identity; right: owner-safe tabs **Overview / Authentication / Certification / Documents /
History**), while staying collector-specific, read-only, and owner-authorized — reusing the **same SCA item/provenance
data** (no duplicate collector data).

## 1. Key finding — this is a VIEW redesign; the data is already owner-safe

The collector already renders **all** of this data today (in one long `collection/show.blade.php` card), and the
`CollectionService` DTOs are already rigorously privacy-scrubbed (ids, staff refs, reasons, tokens, checksums, internal
paths are read for classification only and **never returned**). So parity needs **no new data, no schema, and little-to-
no service/controller change** — primarily a Blade reorganization + collector terminology + a wider, tabbed layout.

Constraints confirmed: collector routes are in the **`web` group only — no CSP** today, but the layout convention is
**inline styles, no JS** → use **CSS-only tabs** (hidden radio inputs + `:checked ~` sibling selectors) so the page stays
self-contained and CSP-safe if a CSP is added later. The collector `layout.blade.php` wrap is **`max-width:420px`
(mobile-first)** — the detail page needs a **wider, responsive** container (two columns on desktop, stacked on mobile);
proposed via a page-level wrapper/`@section` width override, not a global layout change.

## 2. Proposed collector layout (parity)

```
[ left panel ]                         [ right panel: CSS-only tabs ]
 catalog image (owner image route)      Overview | Authentication | Certification | Documents | History
 authenticity badge (✓ / neutral)       ────────────────────────────────────────────────────────────
 SCA reference                          (one panel visible at a time; stacks under the image on mobile)
 Item (brand + model), SKU
 year / country / materials (if set)
 original_specifications (if set)
```

- **Left panel** = identity: image (existing `collector.collection.image` route), authenticity badge, SCA reference,
  brand+model, SKU, year/country/materials/original_specifications. **No** frame_serial, **no** internal id, **no** path.
- **Right panel** = tabs (below):

## 3. Field-by-field admin → collector mapping + classification

Legend: **✓ safe** (expose as-is) · **~ present** (expose with collector-specific wording) · **✗ staff-only** (exclude).

### Overview
| Admin field/control | Collector |
|---|---|
| Current lifecycle_state | ~ `status` label ("Owned & registered" etc.) ✓ |
| registry_status (raw) | ~ safe banner + adverse warning (existing) ✓ |
| Registered owner = **"Collector #N"** | ~ **"Registered to you"** / **"You"** (already collector-worded) ✓ |
| External-intake **claim-link issuance** (staff) | ✗ staff-only — never on collector |
| Provenance summary **counts** (authentications/certs/qr/ownership/service/status) | ✗ raw counts are a staff operability view — collector gets the narrative tabs instead; **no count dump** |
| "View public passport" (collector, SCA-041) | ✓ keep (server-side redirect, no token) |
| Collector **report lost/stolen/recovered + transfer** actions | ~ **collector-owned** capabilities (SCA-016/transfer), NOT staff registry-management — keep (decision §8) |

### Authentication
| Admin | Collector |
|---|---|
| Staff authentication **table**: performed_by_staff_ref, notes, draft/finalized, **Finalize**/**Certify** actions | ✗ staff-only — **excluded entirely** |
| Authenticity outcome | ~ authenticity badge + `authenticity_status`, `condition_grade` + `condition_label`, `authentication_date` (all already in the collector `detail()` DTO, derived from a finalized passed authentication) ✓ |

### Certification
| Admin | Collector |
|---|---|
| certification_number, issued date | ✓ (already in DTO) |
| **certification public_token** (opaque security token) | ✗ staff-only |
| **QR public_token** / "Download printable QR" / Generate-PDF / **Correct certification (revoke/supersede)** | ✗ staff-only |
| source_authentication_id | ✗ staff-only |
| Certification **history** (current / revoked / superseded + successor) | ✓ (SCA-048 collector DTO: numbers/dates/status/successor_number only; **no reason/staff/token/checksum/id**) |
| "View public passport" | ✓ keep here or Overview |

### Documents
| Admin | Collector |
|---|---|
| ALL documents incl **private (is_public=0)** + upload form + visibility toggle | ✗ staff-only (private docs + upload **excluded**) |
| Owner-visible docs (`is_public=1`) | ✓ existing collector DTO: `kind`, `date`, derived current/superseded cert label, `certification_number` (public), **opaque `handle`** (`DocumentHandle::encode`, no DB id) + owner-authorized **Download** (`collector.collection.document.download`) |

### History
| Admin | Collector |
|---|---|
| Ownership ledger (admin: internal ids/other-collector ids) | ~ collector ownership timeline (SCA-049): neutral `label` + `date` + **"You"** marker; **never** another collector's name/ref/email, staff ref, reason, id, token |
| Service history (admin: raw) | ✓ collector service DTO: `type` label, `date`, condition grade/label, `notes` (owner-safe) |

## 4. Must-remain-staff-only (hard exclusion list)

frame_serial · certification `public_token` · QR `public_token` · `source_authentication_id` · `snapshot_checksum` ·
`performed_by_staff_ref` / `actor_staff_ref` · authentication/correction **notes & reasons** · all internal DB ids ·
`image_path` / `image_mime` · `is_production` · **private (is_public=0) documents** · document **upload** · **generate
certificate PDF**, **correct/revoke certification**, **download-QR**, **catalog edit**, **registry resolve/retire/
invalidate / adverse-recovery**, **external claim-link issuance**, **draft/finalize/certify** · provenance raw-event
dumps · any other collector's identity. (All already excluded by the collector DTOs — the redesign must not re-introduce
them.)

## 5. Route / ACL implications

**No new routes.** Reuses: `collector.collection.show` (the page), `collector.collection.image` (Slice 3, owner-authz),
`collector.collection.document.download` (owner-authz, opaque handle), `collector.collection.passport` (SCA-041
redirect), and the existing collector status/transfer actions. All under `collector.auth` + current-ownership
authorization in `CollectionService` (ref-addressed). **Privacy-safe 404 preserved**: `show($ref)` already returns the
explicit `collection.not_found` 404 for a non-owner / previous-owner / unknown ref — unchanged.

## 6. Smallest DTO / service / view / controller changes

- **Service/DTO:** expected **none** for data (all fields already provided). *Possible* tiny optional additions, only if
  the redesign wants them, kept owner-safe: e.g., an `authenticated` boolean already derivable; none required.
- **Controller:** `CollectionController::show` already passes `item`, `services`, `documents`, `certificationHistory`,
  `ownershipHistory`, `passportEligible`. **No change** (optionally group the vars, but not required).
- **View:** rewrite `collection/show.blade.php` into the two-panel + CSS-only-tabs layout; add the tab CSS to the page or
  `layout.blade.php` `<style>` (inline, no JS); add a page-level wider responsive wrapper for this route only.
- **No Krayin core/vendor edits. No schema. No QR/cert/authentication/ownership/provenance mutation.**

## 7. Tests (focused, new — `CollectorItemDetailParityTest`)

Render the owner detail (200) and assert: the two-panel + the five tab labels present; image via the owner route;
**Authentication tab shows the authenticity summary but NOT** performed_by_staff_ref / staff notes / Finalize / Certify;
**Certification tab shows number/date/history but NOT** any 32-hex token (cert/QR), source_authentication_id, Generate-PDF/
Correct-cert/Download-QR; **Documents tab shows only owner-visible docs** (seed a private doc → absent) with the opaque
handle, **no upload form**; **History** shows neutral ownership ("You") + service, **no other-collector identity / staff
ref / reason**; ownership shows **"Registered to you" / "You"**, never "Collector #N"; **frame_serial / image_path /
is_production / internal ids never in the HTML**; **non-owner & previous-owner-after-transfer → privacy-safe 404**
(unchanged); zero provenance/QR mutation from viewing. Plus full `tests/Feature/Sca` green (esp. SCA-041/042/048/049 and
the Slice-3 collector image/doc tests).

## 8. Open decisions for the operator

1. **Collector status/transfer actions** (report lost/stolen, mark recovered, transfer ownership): these are *existing,
   authorized collector capabilities* (SCA-016/transfer), **not** staff registry-management. **Recommend KEEP** them
   (in the Overview tab) — the page stays "read-only" w.r.t. provenance but preserves the owner's own controls. Confirm,
   or make the page strictly read-only and relocate those actions.
2. Tab mechanism: **CSS-only tabs** (recommended, JS-free/CSP-safe) vs. `<details>` accordions vs. stacked sections.

## 9. Security boundaries / risks

- Reuse current-ownership authz + the opaque-ref addressing; **no item id in any URL**; privacy-safe 404 unchanged.
- CSS-only tabs = no JS, no new asset, no CSP change; collector layout stays self-contained.
- Risk: the redesign must not "reach past" the collector DTOs to raw models (which carry staff/private columns) — keep
  rendering strictly from the existing owner-safe DTO arrays (a test asserts no staff/private token/id appears).
- Risk: wider layout must still render cleanly on mobile (stack) — responsive, no horizontal scroll.

## 10. GO / NO-GO gates

GO only if: five owner-safe tabs render with the correct field set; **every item in §4 is absent from the HTML**;
ownership reads "You"/"Registered to you"; Authentication excludes staff table/actions; Certification excludes cert/QR
tokens + staff cert controls; Documents excludes private docs + upload; non-owner/previous-owner → privacy-safe 404;
no new route/schema/core-edit; zero provenance/QR/is_production mutation; full `tests/Feature/Sca` green.

## 11. Rollback

View-only (+ optional inline CSS). Rollback = revert the commit and redeploy prior main; no schema/data to undo.

## Exact file scope (proposed)

- `packages/Sca/Collector/src/Resources/views/collection/show.blade.php` — rewrite to two-panel + CSS-only tabs.
- `packages/Sca/Collector/src/Resources/views/layout.blade.php` — add tab CSS + allow a wider wrapper for this page
  (minimal; inline styles only).
- (Optional, only if a grouped view-model is preferred) `CollectionController::show` / `CollectionService` — **no data
  change**; not required.
- `tests/Feature/Sca/CollectorItemDetailParityTest.php` — new.

## Summary / recommendation

Proceed to a **governed implementation** as a **view-only parity redesign** (two-panel + CSS-only owner-safe tabs over
the existing owner-safe DTOs), collector terminology, **no new data/schema/routes/core edits, no mutation**. One open
decision: keep the collector's own status/transfer actions (recommended) vs. strictly read-only. **ACTIVE = NONE /
NEXT_TASK = NONE — planning only; awaiting ChatGPT review + promotion.**

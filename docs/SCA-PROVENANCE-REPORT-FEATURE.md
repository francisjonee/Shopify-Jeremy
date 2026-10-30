# SCA — Requirements Gap Analysis + Next Feature: Digital Provenance / Insurance Report

**Against Jeremy's original Ownership Passport requirements, almost everything is implemented; the
clearest genuinely-missing, business-essential, email-free / Shopify-free capability is the owner-facing
Insurance Report, so I built it: an on-demand Digital Provenance Record PDF a collector can download for
an item they own.** Development-only, on an isolated branch off production; no tests run; no production
change. Branch `feature/sca-provenance-report` = `ba2da33` off `b007606`. 2026-10-30. **STOP for review.**

## 1. Requirements → implementation gap analysis
Source: `docs/PRODUCT_REQUIREMENTS.md` (Jeremy vision) + `docs/ROADMAP.md`.

**Fully implemented (do not duplicate):**
- Pre-sale state: authentication, condition grade, registry/provenance record, SCA Certification ID,
  permanent QR identity, printed QR (batch labels), ownership `UNCLAIMED`.
- SCA-canonical model; Shopify catalog sync (Phase 1); order-line → exact physical pair assignment; CSV
  inventory onboarding + optional variant linking (just deployed).
- Digital Provenance Record fields (model, brand, year, country, materials, original specs,
  authentication, condition, inspection images/gallery, certification status, current ownership,
  ownership history, transfer history, service history, market reference).
- Permanent QR + state-dependent public passport (incl. adverse/transfer-pending presentation);
  append-only ownership; ownership transfer (+ pending indicator, and the new Copy/Share link);
  service history; lost/stolen/recovered registry; My Collection dashboard + browse/filter + private
  collections.

**Built but intentionally not deployed (excluded):** secure ownership claim R0/R0b/R0c (`4bd88d2`,
DEPLOYMENT-BLOCKED on transactional email + separate auth). Not in scope.

**Partially implemented:** Market Information — an advisory Market Reference (current + history) exists;
Jeremy's richer MSRP / avg / highest / lowest / last-verified-sale fields are future and explicitly "not
an appraisal." Not the most essential gap.

**Genuinely missing (confirmed: zero `insurance` references in the codebase):**
- **Insurance Report (PDF)** — `PRODUCT_REQUIREMENTS` "Insurance Report … generate a PDF containing
  relevant authentication, condition, photos, certification, serial/specification, ownership, and
  supporting record information"; roadmap Phase 9 `SCA-DOCUMENTS-017` ("…provenance/insurance
  documents"). A per-certification certificate PDF exists (`CertificatePdfService`) and staff can upload
  documents, but there is **no owner-generated consolidated provenance/insurance report**.
- Collector dashboard "Downloadable records / insured-value summaries" — same gap.

**Selected next feature:** the **owner-facing Digital Provenance / Insurance Report PDF**. It is
business-essential (collectors must document valuable eyewear to insure it; it is a core SCA deliverable
and a concrete collector value), requires **no transactional email and no Shopify**, and duplicates none
of the excluded features (inventory, QR, Shopify sync, order assignment, My Collection, transfer).

## 2. What was implemented
A collector viewing an item they currently own can **Download provenance report (PDF)** from the item
detail. The report is a point-in-time "SCA Digital Provenance Record — Insurance & Documentation Report"
containing: item identity (brand, model, year, country, materials, SKU, original specifications),
authentication status + condition grade + authentication date, certification number/date + certification
history, ownership history (neutral, append-only), service history, current market reference (with the
advisory/non-appraisal disclaimer), registry status, the featured inspection image, and a generation
date + verification note.

## 3. Architectural decisions
- **On-demand, not stored.** Unlike the immutable, checksummed per-certification `CertificatePdfService`
  artifact, this report is generated live and streamed to the owner — it is **never stored**, adds **no
  media row and no new table/migration**, appends no provenance/ownership/status event, and mutates
  nothing. A report is inherently a point-in-time snapshot ("as of <date>"), which is exactly what an
  insurer needs, so live generation is correct and keeps the change DB-free.
- **Owner-safety by construction.** Every field is drawn from the **same owner-authorized,
  privacy-projected `CollectionService` DTOs** that render My Collection (`ownedItemByRef`,
  `serviceHistoryForOwnedItem`, `marketReferenceForOwnedItem`, `certificationHistoryForOwnedItem`,
  `ownershipHistoryForOwnedItem`). The report therefore **cannot** contain owner PII, another
  collector's identity, `frame_serial`, staff refs, internal ids, QR/cert tokens, or storage paths. A
  non-owner / previous owner / unknown ref yields `null` → the controller returns the **shared
  privacy-safe real 404** used across My Collection (ownership/existence never confirmed by guessing).
- **`frame_serial` deliberately excluded.** Jeremy's requirement lists "serial/specification," but
  exposing `frame_serial` to the collector surface would break an existing owner-safe invariant; the
  report includes `original_specifications` (owner-visible) and omits `frame_serial`. Adding the serial
  would need a separate, explicit owner decision (noted below).
- **No QR token embedded.** The report references verification via the item's permanent QR / public
  passport in words; it embeds no `/p/{token}` URL (avoids placing a credential-ish token in a shared
  document). A rendered QR image is a possible future enhancement.
- **Featured image embed.** The featured inspection image is embedded as an inline `data:` URI read
  through the existing owner-authorized accessor (`catalogImageForOwnedItem`) — bytes only, no path
  exposed.
- **Reuses installed `barryvdh/laravel-dompdf`** (the same engine as `CertificatePdfService`); the
  template is self-contained (inline CSS, DejaVu Sans, no external assets).
- **Authorization via existing route group.** New route is inside the `collector.auth` group;
  throttled `30,1`; GET-only, read-only.

## 4. Changed files (branch `feature/sca-provenance-report` @ `ba2da33`, off `b007606`)
New:
- `app/packages/Sca/Collector/src/Services/ProvenanceReportService.php` — assembles owner-safe data +
  renders the PDF (`pdfForOwnedItem`), returns bytes or null.
- `app/packages/Sca/Collector/src/Http/Controllers/CollectionReportController.php` — owner-gated
  download; 404 for non-owner.
- `app/packages/Sca/Collector/src/Resources/views/report/provenance.blade.php` — dompdf template
  (owner-safe fields only).
Modified:
- `app/packages/Sca/Collector/src/Routes/collector-routes.php` — `GET collection/{ref}/report`
  (`collector.collection.report`, throttle 30,1).
- `app/packages/Sca/Collector/src/Resources/views/collection/show.blade.php` — "Download provenance
  report (PDF)" action on the Overview tab.

No migration; no change to ownership / certification / QR / Shopify / claim services or their invariants.

## 5. Static checks performed (no tests — development mode)
`php -l` clean on the service, controller, and routes file; both Blade views compile and the generated
PHP passes `php -l` (checked against the production vendor, read-only). **No automated / integration /
database / production tests were run**, per the owner's testing freeze.

## 6. Tests required later (before any release) — NOT run now
- **Ownership authorization:** owner gets a PDF; a non-owner / previous-owner-after-transfer / unknown
  ref gets the privacy-safe 404 (no existence/ownership disclosure); unauthenticated → login.
- **Owner-safety of content:** assert the rendered PDF/HTML contains none of `frame_serial`, owner
  email/name, staff refs, internal numeric ids, QR/cert tokens, or storage paths — across certified,
  uncertified, adverse (lost/stolen/invalidated), transferred (new + prior owner), and no-image items.
- **Correctness:** certification history (current / superseded+successor / revoked), ownership history
  order + "you" marker, service history, market reference present/absent, featured-image present/absent
  and missing-file fallback.
- **No side effects:** generating a report creates no `sca_media_assets` row, no ownership/status/cert
  event, no projection rebuild; DB row counts unchanged.
- **Rendering robustness:** large `original_specifications`, multi-byte text, and a large image embed do
  not error; response headers are `application/pdf` + attachment + `no-store`.
- Isolated disposable-DB regression of the above + the existing collector/passport suites, egress
  blocked, before any RC/deploy.

## 7. Safety posture (this task)
Development-only on an isolated branch off production. No production DB change / migration / merge /
deploy; no automated/integration/DB/production tests; no live Shopify API or store change; no email
configuration; no real customer claim or ownership transfer; no R0/R0b/R0c deploy or security weakening;
no Option C. Production unchanged at `b007606`. Secure-claim RC `4bd88d2` remains DEPLOYMENT-BLOCKED and
untouched.

**STOP — gap analysis delivered and the next essential missing feature (owner-facing Digital Provenance /
Insurance Report PDF) implemented on `feature/sca-provenance-report` (`ba2da33`): on-demand, owner-safe by
construction (reuses the My Collection DTOs), no stored artifact, no migration, no service/invariant
change. Static checks clean; no tests run (owner testing freeze). Branch pushed; production unchanged at
`b007606`. Awaiting review; tests listed above are required before any regression/RC/deploy.**

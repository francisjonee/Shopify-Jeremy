# SCA — Resale Documentation Gap Analysis (+ one representation-safety fix)

**The existing certificate PDF, the new Digital Provenance Report, current-ownership-gated document
access, and the PII-free public passport together already satisfy Jeremy's resale documentation
requirements — no new document is warranted. The only genuine, smallest-safe change is a
representation guard so the provenance report can never be read as a certified/insured VALUE.**
Development-only, on an isolated branch off `ba2da33`; no tests run; production unchanged at `b007606`.
Branch `feature/sca-provenance-report-resale` = `63b5808`. 2026-10-30. **STOP for review.**

## 1. Requirements (resale documentation)
From `docs/PRODUCT_REQUIREMENTS.md` / `docs/ROADMAP.md`: authentication begins a permanent record that
follows the eyewear "through ownership, resale, transfer, service, and status changes"; a Digital
Provenance Record with authentication/condition/certification/photos/ownership+transfer+service history;
the Insurance Report; downloadable records; and a permanent QR resolving to a PII-free public passport.
Phase 9 `SCA-DOCUMENTS-017` = "authentication/ownership/provenance/insurance documents."

## 2. What exists and whether it covers resale documentation
- **Certificate PDF** (`CertificatePdfService`): immutable, byte-reproducible, per-certification
  attestation; staff/system-generated (POST `/admin/sca/certificate/{ref}`, ACL
  `sca.eyewear.certificate`), stored as one `is_public=1` media asset. Provenance-safe (no owner
  PII/serial/tokens/ids). Downloadable by the **current-owner** collector from My Collection.
- **Digital Provenance Report** (new, `ProvenanceReportService`, `ba2da33`): on-demand owner-generated
  PDF of the full record (identity/specs, authentication + condition, certification + history, ownership
  history, service history, market reference, registry status, featured image). Owner-safe by
  construction (same My Collection DTOs); not stored; no mutation.
- **Public passport** (`/p/{token}`): PII-free independent verification anyone (e.g. a prospective
  buyer) can reach by scanning the permanent QR — the designed pre-purchase trust channel.

**Conclusion:** together these cover the resale documentation need — the seller/owner can self-serve the
full record (provenance report) and the formal certificate, share the provenance-report file with a
buyer, and the buyer can independently verify via the public passport. **Creating another PDF would
duplicate existing functionality (declined per the task).**

## 3. Document access before vs after ownership transfer — REVIEWED, correct
All collector document surfaces are gated on **canonical current ownership**, so transfer behaves
correctly and privately:
- `visibleDocumentsForOwnedItem` / `ownerVisibleDocument` (certificate + uploaded `is_public` docs) and
  the new `ProvenanceReportService.pdfForOwnedItem` all resolve via `ownedItemByRef`/`ownedItemId`
  (current `current_owner_collector_id`).
- **New owner (B) after accepting a transfer:** gains access to the certificate PDF and all `is_public`
  documents (media assets are keyed to `eyewear_item_id`, not to an owner) and can generate the
  provenance report — which includes the full append-only ownership history (neutral labels; "you"
  marker) with no prior-owner PII.
- **Previous owner (A) after transfer:** every surface returns the shared privacy-safe real 404
  (ownership/existence never confirmed) — A can no longer download the item's documents. Correct and
  privacy-preserving.
- **Private (staff-only) documents** (`is_public=0`) are never collector-visible, before or after
  transfer.
No leak and no missing-access gap was found in the transfer document flow.

## 4. The one genuine issue addressed (representation safety)
The provenance report was titled "Insurance & Documentation Report" and includes a market-reference
dollar range. Although it already carried a "not an appraisal" disclaimer, the juxtaposition risked a
reader treating the market estimate as a **certified or insured value** — exactly the representation the
task forbids. Smallest-safe fix (view-only, one Blade file):
- Retitled to **"SCA Digital Provenance Record — documentation for insurance & resale"** (insurance is
  the use, not a valuation claim), with an explicit header line: *"Not an appraisal and not a statement
  of insured or market value."*
- Strengthened the market-reference disclaimer: *"Informational market estimate only … not an appraisal,
  not a certified or insured value, and not a guarantee of sale price. Any insured value is set by you
  and your insurer, not by this figure."*
- Footer now states the document is a provenance/authentication record to support insurance and resale,
  not an appraisal or insured/market value.
The market-reference advisory disclaimer is preserved and reinforced (constraint 9).

## 5. Changed files (branch `feature/sca-provenance-report-resale` @ `63b5808`, off `ba2da33`)
- `app/packages/Sca/Collector/src/Resources/views/report/provenance.blade.php` — representation wording
  only (title, header guard line, market disclaimer, footer). No logic/service/route/schema change.

## 6. Security & privacy considerations (all preserved)
- Owner-only access and the shared privacy-safe 404 for non-owners are unchanged (the fix is wording in
  an already-owner-gated report).
- No owner PII, no other-collector identity, no `frame_serial`, no QR/cert tokens, no internal ids, no
  storage paths are introduced (the report still renders only the owner-safe DTOs).
- Authentication/certification/transfer invariants untouched; no provenance/ownership/status mutation; no
  migration; no new route or ACL.
- Market estimate explicitly not represented as a certified/insured valuation.

## 7. Observations (NOT changed — flagged for the owner, not essential now)
- **Certificate PDF generation is a separate staff action** (not automatic at certification), so a
  certified item can lack a downloadable certificate until staff generate it. The provenance report
  covers the full record regardless; auto-generating the certificate at certify time would be a
  behaviour change to the certification flow and is out of this task's smallest-safe scope — queue
  separately if the owner wants it.
- A rendered QR image or a verification code on the provenance report (anti-tamper for a shared file)
  is a possible future enhancement; the report already points to the permanent-QR / public-passport
  independent verification channel.

## 8. Tests required later (NOT run — owner testing freeze)
- Provenance report renders with the new wording; no automated/DB/integration test was run.
- (Carried from `ba2da33`) ownership-auth/404 across certified/uncertified/adverse/transferred/no-image;
  owner-safety content scan (no PII/serial/tokens/ids/paths); correctness; no-side-effects; render
  robustness; isolated disposable-DB regression + existing collector/passport suites — all before any
  RC/deploy.

## 9. Safety posture (this task)
Development-only on an isolated branch off `ba2da33`. No production merge/migration/deploy/restart; no
automated/DB/integration/production tests; no live Shopify API or store change; no production DB write; no
live claim/transfer/report generation; no email configuration; no secure-claim RC (`4bd88d2`) deploy; no
Option C. Production unchanged at `b007606`.

**STOP — resale documentation gap analysis delivered: existing certificate PDF + provenance report +
current-ownership-gated access + PII-free public passport already satisfy the requirements, and document
access across transfer is correct and privacy-safe, so no new document was created. The one genuine,
smallest-safe change — a representation guard ensuring the provenance report is never read as a certified
or insured value — is implemented on `feature/sca-provenance-report-resale` (`63b5808`, view-only, off
`ba2da33`). Blade compiles; no tests run (owner freeze). Branch pushed; production unchanged at
`b007606`. Secure-claim RC `4bd88d2` untouched.**

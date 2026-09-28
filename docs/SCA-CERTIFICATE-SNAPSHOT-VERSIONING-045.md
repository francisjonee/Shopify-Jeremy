# SCA-CERTIFICATE-SNAPSHOT-VERSIONING-045 — Read-only planning / architecture audit

**Type:** READ-ONLY planning. No implementation, migration, PDF generation/repair, or data mutation.
**Audited against:** implementation `main` @ `fdf8595828e618b8a65742134836c2e914c67d3e` (deployed).
**Method:** inspected `CertificatePdfService` (`snapshotForCertification` + `render` + `ensureForItem`), the
certificate template inputs, `DocumentService::storeGeneratedMedia`/`restoreGeneratedMedia`/`putGenerated`,
`sca_media_assets` + `sca_certifications` schema, the integrity triggers, and SCA-038/042/043/044 behavior.

`SCA-PRODUCTION-CUTOVER` remains BLOCKED/DEFERRED awaiting Jeremy.

---

## 1. Current rendering dependency map

The certificate PDF renders exactly 9 inputs (from `certificate/document.blade.php` + `snapshotForCertification`):

| PDF field | Source (today, live) | Mutable after issuance? |
|---|---|---|
| `public_ref` | `sca_eyewear_items.public_ref` | **No** — item public_ref is immutable, never edited |
| `cert_number` | `sca_certifications.certification_number` | **No** — set once at issue; issued cert row is trigger-immutable |
| `cert_date` | `sca_certifications.issued_at` | **No** — issued cert immutable |
| `cert_token` | `sca_certifications.public_token` | **No** — set once; issued cert immutable |
| `condition_grade` / `condition_label` | `sca_authentications.condition_grade` (cert's source auth) | **No** — the source authentication is finalized ⇒ `trg_sca_authentications_immutable` forbids UPDATE |
| `auth_date` | `sca_authentications.finalized_at` (source auth) | **No** — finalized auth immutable |
| **`brand`** | **`sca_eyewear_items.brand`** | **YES (risk)** — item row; create-only today, correctable in a future SCA-044 slice |
| **`model`** | **`sca_eyewear_items.model_name`** | **YES (risk)** — item row; same |

The PDF deliberately excludes registry status, owner, notes, frame_serial, internal ids (SCA-023 policy), so
none of those are a divergence surface.

## 2. Reproducibility risks

- **Only `brand` and `model`** (from `sca_eyewear_items`) can cause an already-issued certificate to
  re-render differently from the originally stored PDF — and **only once metadata correction ships** (items
  are create-only today, so live-read currently equals issuance-time). Everything else the PDF renders is
  already immutable at the storage layer (issued cert + finalized auth).
- **Concrete failure:** repair (`restoreGeneratedMedia`) re-renders and requires the bytes to match the
  recorded `checksum_sha256` (`hash_equals`) or it **refuses** ("checksum mismatch — refusing to restore
  non-canonical bytes"). So after a `brand`/`model` correction, if an old media file is lost, repair of that
  certificate **fails closed** — the historical artifact becomes unrestorable.
- **Forward risk:** if a future slice adds SCA-044 fields (year/country/materials/specs) or any item-derived
  field to the certificate template, those fields join the divergence surface. The snapshot design must be
  general, not brand/model-specific.
- **Template risk:** any change to `certificate/document.blade.php` or the deterministic render rules (pinned
  `PDF_EPOCH` dates, snapshot-derived `fileIdentifier`) changes the bytes for a re-render of ANY cert →
  repair of pre-change PDFs would mismatch. Template evolution therefore also needs versioning.

## 3. Recommended snapshot data model

**Recommendation: a dedicated append-only `sca_certificate_snapshots` table with TYPED columns for the
render inputs + a `template_version`, written at certification issuance.** One immutable row per
certification.

Compared options:
- **Typed columns on `sca_certifications`** — rejected: pollutes and grows the immutable cert row; each new
  PDF field needs a cert-table migration; couples snapshot evolution to the core provenance table.
- **Immutable JSON on the certification** — rejected as the *primary* store: weak validation/typing and
  queryability, and the codebase deliberately avoids JSON for provenance (everything is typed columns +
  events). JSON would be "convenient" but not integrity-first. (A verbatim JSON *copy of rendered inputs*
  MAY be added later as a redundant forward-compat capture, but not as the authority.)
- **Separate `sca_certificate_snapshots` table (typed) — chosen.** Isolates the reproducibility artifact
  from the immutable cert row; append-only and independent per certification (supports supersede);
  naturally carries `template_version`; new render fields are additive nullable columns on this table
  without touching `sca_certifications`; typed ⇒ validated, queryable, durable.

Proposed columns (all set once, never updated): `id`, `certification_id` (FK, unique), `template_version`
(e.g. `v1`), the frozen render inputs as typed columns (`public_ref`, `brand`, `model`, `condition_grade`,
`condition_label`, `cert_number`, `cert_date`, `auth_date`, `cert_token`), `source` (`issued` |
`reconstructed`), `captured_at`, and optionally `snapshot_checksum` (sha256 of the canonical serialization,
for tamper-evidence). Immutability enforced by a no-UPDATE/no-DELETE trigger (consistent with the other
append-only tables).

Even though most inputs are already immutable, freezing them all keeps the render input a single
self-contained source of truth (the renderer never reads `sca_eyewear_items`/authentications again),
eliminating all present and future divergence — not just brand/model.

## 4. Template-version model

- Add `template_version` to each snapshot (current template = `v1`). `CertificatePdfService::render` selects
  the template + the deterministic render rules (pinned dates, `fileIdentifier` derivation) **by the
  snapshot's `template_version`**.
- Future certificate-template changes introduce `v2` (a new versioned template file, e.g.
  `certificate/document_v2.blade.php`); **old snapshots keep rendering with `v1`**, so any old certificate is
  reproduced deterministically with the semantics that existed at its issuance. Retaining old template
  versions in the codebase is the explicit long-term maintenance commitment this buys.

## 5. Legacy certificate / PDF compatibility policy

- Existing issued certifications have **no** snapshot row; their stored PDF bytes + `checksum_sha256` are the
  **authoritative historical artifact**. **Do not backfill, regenerate, relink, or delete them.**
- **Grandfather** legacy certs: `CertificatePdfService` renders from a snapshot **when one exists**, else
  falls back to the current live-read path (`v1`) — which remains correct for legacy certs precisely because
  their items are still un-corrected. No fiction is introduced.
- **No pretend-issuance reconstruction.** A snapshot must never claim `source='issued'`/issuance `captured_at`
  for data gathered later. If a snapshot is ever created for a legacy cert, it is marked
  `source='reconstructed'` with the real reconstruction timestamp.
- **Missing old file + repair after metadata change:** with a snapshot, repair renders from the frozen
  snapshot → reproduces original bytes → checksum matches → restore succeeds. Without a snapshot (legacy) and
  after its item's PDF-relevant field changed, repair **fails closed** (current behavior). This is why the
  **metadata-correction slice must, before changing any PDF-relevant item field, first freeze a
  `reconstructed` snapshot of the pre-correction values** (which for an un-corrected item equal the issuance
  values) — protecting reproducibility without falsifying provenance. That ordering makes SCA-045 a
  prerequisite of the correction slice.

## 6. Issuance / supersede / revoke / repair / failure lifecycle (future)

- **Freeze point:** the snapshot row is written when a certification is **issued**, inside the same
  transaction as issuance — **data only, no PDF rendering**. So the frozen facts reflect issuance-time item
  state even when the PDF is generated later.
- **Supersede (SCA-038):** the successor certification gets its **own independent** snapshot row; the
  predecessor's snapshot/PDF are untouched (append-only, independent successor).
- **Revoke (SCA-038):** creates no certification ⇒ **changes no snapshot**. Revoked certs simply become
  non-current; their snapshot/PDF remain immutable historical evidence.
- **SCA-043 explicit staff-triggered generation:** `ensureForItem` renders from the certification's **frozen
  snapshot + template_version**, never from current item state. Explicit staff-triggered generation remains
  the accepted lifecycle; automatic generation is still not introduced.
- **Idempotent repair:** re-render from the frozen snapshot → deterministic bytes → matches recorded checksum
  → restore. Still one artifact per certification.
- **Snapshot-creation failure at issuance:** it is a plain DB insert in the issuance transaction; failure
  rolls back issuance (fail closed). Because snapshot capture is **data, not rendering**, this never makes
  provenance depend on PDF rendering — the SCA-043 invariant is preserved. (PDF *rendering* still happens
  only later, explicitly.)

## 7. Migration / backfill policy

- Additive: new `sca_certificate_snapshots` table + its immutability triggers + a unique index on
  `certification_id`. No change to `sca_certifications`, `sca_media_assets`, or existing PDFs.
- **No backfill** of existing certificates/PDFs. Legacy certs stay snapshot-less and grandfathered.
- Versioning the current template as `v1` is a **code** change (rename/duplicate the existing template into a
  versioned path + a version→template map), not a data migration; existing PDFs are unaffected.
- Compatibility strategy: render-from-snapshot-when-present with a `v1` live-read fallback for legacy — so
  deploying 045 changes no existing behavior until snapshots start being written for new issuances.

## 8. Security / privacy implications

The snapshot stores the **same public-safe facts already in the PDF** (public_ref, brand, model, grade,
dates, opaque cert_token) — no PII, no owner/status, no internal-only secrets, no new public surface. The
snapshot table is staff/internal. `cert_token` is already the opaque, host-independent identity printed on
the certificate (not a URL). No new exposure; SCA-042/044 public boundaries are unchanged.

## 9. Acceptance-test matrix (for the implementation slice)

- New issuance writes exactly one immutable snapshot row (`source='issued'`, `template_version='v1'`) inside
  the issuance transaction; snapshot is append-only (UPDATE/DELETE rejected).
- Supersede writes an independent successor snapshot; predecessor snapshot unchanged.
- Revoke writes/changes no snapshot.
- PDF generation for a cert-with-snapshot renders from the snapshot (proven by mutating the current item
  `brand`/`model` after issuance and showing the generated/repaired PDF still matches the frozen facts +
  checksum).
- Repair of a cert-with-snapshot after an item field change reproduces original bytes and restores
  successfully; repair of a legacy snapshot-less cert whose item is unchanged still works (fallback).
- Legacy certs without snapshots: unaffected; existing PDFs/checksums authoritative; no backfill occurs.
- Template `v2` (simulated) renders new snapshots with v2 while a `v1` snapshot still renders via v1
  deterministically.
- Snapshot-insert failure at issuance rolls back issuance; no partial cert/snapshot; no PDF rendered.
- Invariants: append-only provenance; predecessor immutability; QR permanence; ownership/status/claim/
  transfer untouched; SCA-042 classification still correct; SCA-043 explicit-generation lifecycle intact;
  SCA-044 fields remain current-state (not snapshot-authoritative for the current view).
- Full `tests/Feature/Sca` green; certificate/PDF/repair suites still pass.

## 10. Recommended smallest implementation slice

One cohesive unit (anything smaller delivers nothing usable):
1. `sca_certificate_snapshots` table (typed render inputs + `template_version` + `source`/`captured_at`
   [+ optional `snapshot_checksum`]) with append-only triggers; additive migration, no backfill.
2. Version the current template as `v1` + a version→template/render-rules map in `CertificatePdfService`.
3. Capture the snapshot (data-only, in-transaction) at **issuance** and at **supersede** (successor).
4. `render`/`ensureForItem`/repair render **from the snapshot when present**, with a `v1` live-read
   **fallback for legacy** snapshot-less certs.

This makes every *newly issued* certificate permanently reproducible and is the prerequisite that unlocks the
later append-only metadata-correction slice (which will freeze `reconstructed` snapshots before editing any
PDF-relevant field). Backfilling/reconstructing legacy snapshots is explicitly **out of this slice**.

## 11. Governance
Planning only — `NEXT_TASK` stays **NONE**; SCA-045 recorded here for ChatGPT review, not
implementation-active. SCA-046 not promoted.

**STOP — audit for ChatGPT review.**

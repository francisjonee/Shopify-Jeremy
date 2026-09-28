# SCA-SUCCESSOR-CERTIFICATE-PDF-043 — Read-only planning / lifecycle audit

**Type:** READ-ONLY planning. No implementation, no schema, no migration, no PDF generation, no deploy.
**Audited against:** implementation `main` @ `50c54ad2ce0afe8f993e11d8b1979e5d667c7935` (deployed).
**Method:** inspected `CertificatePdfService` + all callers, the generate route/controller/ACL, the SCA-038
supersede service/transaction, `DocumentService::storeGeneratedMedia`, and the `sca_media_assets` schema.

`SCA-PRODUCTION-CUTOVER` remains BLOCKED/DEFERRED awaiting Jeremy.

---

## 1. How certificate-PDF generation works today (evidence)

- **`CertificatePdfService::ensureForItem($itemId)`** generates a PDF for the item's **current** issued
  certification only: `certId = projection->currentCertification($itemId)`; `null` → throws
  `CertificateRejection::NO_ISSUED_CERT` (→ 409). It runs in a `DB::transaction` that `lockForUpdate`s the
  item current-state row (same lock order as issue/status/transfer). One `sca_media_assets` row per
  certification (`subject_type='certification'`, `subject_id=<certId>`, `kind='certificate_pdf'`,
  `is_public=1`, checksum, private disk). Idempotent: if the row exists and its file exists → no-op; if the
  row exists but the file is gone → deterministic **repair** (re-render must match the recorded checksum);
  else store new. `render()` is byte-for-byte reproducible (pinned PDF dates + snapshot-derived file id).
  It appends **no** cert/ownership/status event and does **not** rebuild the projection.
- **Only caller:** `CertificateController@generate` (`POST sca/certificate/{ref}`, name
  `admin.sca.certificate.generate`, ACL **`sca.eyewear.certificate`**, item addressed by `public_ref`).
  Nothing else calls it.
- **Certification issuance (007) and supersede (038) do NOT generate a PDF.** The SCA-038
  `supersede()` transaction contains only certification-event inserts + `projection->rebuild` — **no**
  PDF/media/Storage call. Issuance and PDF generation are already **fully decoupled**.
- **Staff UI:** the admin item page shows a "Generate certificate PDF" button whenever the current
  certification is issued (`state === 'issued'` + `sca.eyewear.certificate`). After a supersede the current
  certification is the successor (issued), so **the button is already shown for the successor**.
- **Storage idempotency:** enforced at app level (existence check under the item lock in `ensureForItem`).
  `sca_media_assets` has an index on `(subject_type,subject_id)` and CHECKs on `subject_type`/`kind`, but
  **no DB UNIQUE** on `(subject_type,subject_id,kind)` — duplicate prevention depends on all generation
  going through the single locked `ensureForItem` path (it does).

### Answers to the specific lifecycle questions
- **Can PDF rendering safely occur inside the supersede transaction?** **No.** dompdf rendering is
  memory-heavy (and has shown transient failures on this swapless shared host). Rendering inside the
  supersede transaction would roll back the **certification correction** on a render failure — violating
  "provenance integrity must not depend on PDF rendering succeeding."
- **If PDF generation fails after issuance?** With the decoupled model the certification still stands; the
  successor simply has no PDF yet. Recovery = re-run the idempotent `ensureForItem` (the existing route).
- **On retry?** Idempotent: existing row+file → no-op; row without file → deterministic repair; nothing →
  create. No duplicates (item-locked).
- **Should revoked certifications ever get newly generated PDFs?** **No.** After a revoke,
  `currentCertification` is `null` → `ensureForItem` returns 409. Revoked/superseded certs are never the
  generation target.
- **Should historical certifications without a PDF be backfillable?** The current route only targets the
  **current** cert, so a historical cert that never had a PDF cannot get one via existing code. Recommend
  **out of scope** (the pilot condition is the *current successor* lacking a PDF, which the existing route
  already covers). If ever wanted, it would be a separate staff, cert-id-scoped action under the same ACL —
  not part of 043.

## 2. Does the existing UI already generate the missing successor PDF for the pilot item?

**Yes.** For pilot item `SCA-F1B792AE4745` the current certification is the successor
`SCA-CERT-2026-5AC07F22` (issued), so the staff item page already shows "Generate certificate PDF", and
`ensureForItem` would create the successor's immutable PDF (`subject_id`=successor), leaving the predecessor
`SCA-CERT-2026-FEE6D3D8` PDF untouched; SCA-042 would then label the successor **Current** and the
predecessor **Superseded / historical**. **Not generated during this audit (as instructed).**

## 3. Design comparison

**Option A — automatic (issuance/supersede auto-creates the successor PDF).**
- *A1 inside the supersede transaction:* **rejected** — a render failure rolls back the certification
  correction; provenance would depend on rendering. Violates the core invariant.
- *A2 after commit, same request:* doesn't roll back the cert, but couples supersede latency/success to
  dompdf, adds memory pressure at the mutation moment, still needs idempotent retry if the process dies
  before generation, and would make supersede inconsistent with first issuance (which does not auto-generate).
- Net: automatic buys only convenience at the cost of integrity/failure-semantics risk.

**Option B — explicit staff-triggered via the existing idempotent mechanism.**
- Already implemented: `admin.sca.certificate.generate` → `ensureForItem` targets the current (successor)
  cert, idempotent, item-locked, predecessor untouched, 409 on revoked/no-cert.
- Certification/provenance integrity never depends on PDF rendering; consistent with first-issue behavior;
  SCA-042 classification works with no special case.

**Recommendation: Option B.** It matches the accepted architecture (issuance ⟂ rendering) and the explicit
invariant that provenance must not depend on rendering. Automatic generation is not chosen for convenience.

## 4. Recommended SCA-043 scope (smallest, if any code at all)

The core capability **already exists** (Option B is fully supported). The only genuine gap is
**discoverability**: after a supersede, staff aren't told that the current (successor) certification has no
PDF while a historical one is still shown. Two options for ChatGPT:

- **B0 (zero-code, ops):** staff generate the pilot successor PDF via the existing UI; close SCA-043 as an
  operational action. No code, no schema.
- **B1 (smallest code — recommended if a task is wanted):** on the **staff** item-detail page, when the
  current issued certification has **no** `certificate_pdf` media asset yet, show a small read-only hint
  beside the existing button ("Current certification has no certificate PDF yet — Generate"). Read-only
  presentation; reuses the existing generate route; no change to generation, supersede, QR, ownership,
  provenance, or SCA-042/041.
  - **Files:** `EyewearItemController@show` (compute a boolean "current cert has PDF?" via a single
    `sca_media_assets` existence read) + `eyewear/show.blade.php` (hint). **No service/route/schema change.**
  - **Non-goals:** no automatic generation; no generation for revoked/historical certs; no historical
    backfill; no collector-side change; no schema/migration; no QR/ownership/provenance mutation.

**Optional future hardening (NOT part of 043; flagged):** add a DB `UNIQUE(subject_type,subject_id,kind)`
on `sca_media_assets` as belt-and-suspenders for idempotency. This is a **schema migration** and must first
verify no existing duplicates; only worthwhile if a second (non-locked) generation path is ever added.
Recommend deferring.

## 5. Acceptance tests (for B1, if promoted)
- After supersede with no successor PDF: staff item page shows the "no current certificate PDF" hint +
  Generate; the collector still sees only the predecessor labeled Superseded (SCA-042 unchanged).
- Clicking Generate creates the successor PDF (`subject_id`=successor, `is_public=1`); repeat is idempotent
  (no duplicate); predecessor PDF row/file untouched.
- After generation, SCA-042 labels successor **Current** and predecessor **Superseded**; both downloadable
  to the authorized current owner.
- Revoked / no current cert: no hint; Generate returns 409; no PDF created.
- No QR rotation; no ownership/status/certification-event/projection mutation from generation; SCA-041
  passport unchanged; full `tests/Feature/Sca` green.

## 6. Privacy / security & migration impact
- Generation stays **staff-only** (`sca.eyewear.certificate`); the PDF snapshot is provenance-safe (no
  PII/internal ids/staff ref/live status). No new exposure. The B1 hint reveals only "a current-cert PDF
  does/doesn't exist" to authorized staff — no sensitive data.
- **Migration impact: none** for B0/B1. (Only the deferred optional UNIQUE hardening would need a migration.)

## 7. Governance
Planning only — `NEXT_TASK` stays **NONE**; SCA-043 recorded here for ChatGPT review, not
implementation-active. SCA-044 not promoted.

**STOP — audit for ChatGPT review.**

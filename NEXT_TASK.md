# NEXT TASK

**STATUS:** NONE — no executable task is authorized.

`SCA-SUCCESSOR-CERTIFICATE-PDF-043` is **DONE** — a **zero-code lifecycle validation / architecture
decision** (no implementation, no schema, no deploy). Manual pilot validation confirmed the existing
explicit staff-triggered generation lifecycle works end-to-end for pilot item `SCA-F1B792AE4745`: the
collector now sees both immutable documents — `SCA-CERT-2026-5AC07F22` (Current certificate) and
`SCA-CERT-2026-FEE6D3D8` (Superseded / historical), both downloadable — and SCA-042 classifies both
correctly.

## Accepted architecture decision (recorded)
- **Option B (explicit staff-triggered PDF generation) is the accepted lifecycle.** Automatic generation is
  **rejected** — certification integrity must not depend on PDF rendering/storage success.
- Certification issuance/supersede (SCA-038) remains **independent** of PDF rendering.
- Each certification receives **its own immutable point-in-time PDF** only when explicitly generated (via
  `admin.sca.certificate.generate` → `CertificatePdfService::ensureForItem`, targeting the current cert).
- Predecessor PDFs remain **immutable and downloadable**; never modified, replaced, relinked, or deleted.
- Re-generation is **idempotent** through the existing service (item-locked; one artifact per cert).
- PDF generation mutates **no** QR identity, ownership, registry status, certification provenance, or
  historical document.
- The **B1 "current cert has no PDF yet" staff hint remains an OPTIONAL future UX task**, not part of 043.

## Read-only production verification (pilot item #3, `SCA-F1B792AE4745`)
- Exactly **two** `certificate_pdf` media assets, one per certification, **no duplicate**: media #1 → cert #2
  `SCA-CERT-2026-FEE6D3D8` (historical), media #2 → cert #3 `SCA-CERT-2026-5AC07F22` (current); both
  `is_public=1`.
- Certifications #2 and #3 both `issued`/immutable; successor #3 `supersedes_certification_id=2`.
- **Permanent QR unchanged**: single QR identity #2 with one `activated` lifecycle event (no
  revoke/reissue); `active_qr_identifier_id=2`. **Current-certification projection unchanged**:
  `current_certification_id=3` (successor). Nothing was modified during verification.

`SCA-PRODUCTION-CUTOVER` remains **BLOCKED/DEFERRED** awaiting Jeremy.

*Planning/decision evidence: `docs/SCA-SUCCESSOR-CERTIFICATE-PDF-043.md`.*

ChatGPT promotes exactly one next task here when ready. **SCA-044 is not activated.**

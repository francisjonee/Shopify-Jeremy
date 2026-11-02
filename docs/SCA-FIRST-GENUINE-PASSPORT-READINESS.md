# SCA — First Genuine Eyewear Passport: Operational Readiness (read-only)

**READY. The full staff chain to issue the first real QR Passport — metadata correction → authentication →
finalization → certification (which atomically mints + activates the QR Passport and freezes the immutable
certificate snapshot) → QR label print — exists in the SCA admin dashboard and is permission-gated. One
clean candidate is selected (item 17, `SCA-058DAA468939`, Alain Mikli AO1347, Brand New/Unworn). No code
blockers; the only prerequisites are physical: the pair in hand, staff-verified brand/model, optional
evidence photos, and a staffer holding the right ACLs. A step-by-step checklist is below.** Read-only at
prod `6e36aa7`; no DB write, no metadata/auth/cert/QR change. 2026-11-02. **STOP.**

> Written for: the owner (Jeremy) + the staff member who will issue the first genuine Passport.

## 1. The staff workflow (verified in code, all dashboard-driven)
| Step | Route (admin) | ACL | What it does |
|---|---|---|---|
| Correct metadata | `GET/POST …/{id}/metadata/correct` | `sca.eyewear.metadata.correct` | Append-only; sets verified brand/model/serial/year/country/materials/specs. **Unlocked** for these uncertified items (`pdfFieldsLocked=false` when no current cert). |
| (Evidence photos) | `POST …/{id}/images` | `sca.eyewear.catalog` | Attach item photos (optional; the auth form itself has no image field). |
| Authenticate | `GET/POST …/{id}/authenticate` | `sca.eyewear.authenticate` | Records a **draft** inspection: `result` ∈ passed/failed/inconclusive; a **passed** result **requires** `condition_grade` ∈ A/B/C/D (grade prohibited unless passed); `notes` optional ≤5000. |
| Finalize | `GET/POST …/{id}/authentications/{authId}/finalize` | `sca.eyewear.authenticate` | Typed **"FINALIZE"** confirmation; makes the authentication **immutable** evidence. Irreversible. |
| Certify (+ QR) | `GET …/{id}/certify/confirm`, `POST …/{id}/certify` | `sca.eyewear.certify` | Typed **"ISSUE"** confirmation. Requires a **finalized + passed** authentication. In ONE transaction (`CertificationService::issue`): writes the certification + event, **mints & activates the one-active QR identity** (rejects if one already exists), and **freezes the SCA-045 immutable certificate snapshot**. Returns certification number + QR public token. |
| Print QR label | `GET …/{id}/qr`, `GET …/{id}/qr/label`, `POST …/qr/labels` (batch) | `sca.eyewear.view` | Renders the active QR for single or batch label printing (read-only; never creates a second QR). |

**Key ordering fact:** certification freezes an immutable snapshot of the item's metadata, so **brand/model
(and any other verified details) must be entered via metadata-correction BEFORE certifying** — otherwise the
permanent certificate/Passport would capture blank identity.

## 2. Selected first candidate (task 2–3)
| field | value |
|---|---|
| SCA public_ref | **`SCA-058DAA468939`** (item id 17, Batch 2) |
| Shopify variant | `48797037494559` (product `9309128753439`, SKU `4879703749`) |
| Catalog title (reference) | **ALAIN MIKLI Mod. AO1347 – Col.2895 – Brand New/Unworn with Factory Lenses** |
| Current state | `INTAKE` / `normal`; no owner, **no certification, no QR** |
| Stored metadata | brand/model/serial/year/etc = **NULL** (nothing invented); 0 evidence images |

Why this one: a clearly identifiable designer frame (Alain Mikli, model AO1347), **Brand New/Unworn with
factory lenses** — so condition is straightforward and there is **no re-lensing provenance complication**
(unlike many SCE-re-lensed vintage pairs). Any imported record works; this is the cleanest first pick.

## 3. Physical details & evidence required before authentication (task 4)
Staff must have in hand / record (nothing is pre-filled):
- **The physical pair itself** — confirm it genuinely exists (worklist/catalog quantity is non-authoritative).
- **Verified brand & model** from the frame — expected "Alain Mikli" / "AO1347 Col.2895"; enter via
  metadata-correction. Optional: `frame_serial`, `year`, `country_of_origin`, `materials`,
  `original_specifications` (leave blank if unknown — do not invent).
- **Authentication judgement**: `result` (passed to proceed) and, for passed, a `condition_grade` A–D
  (a new/unworn pair is likely A, but the inspector decides); optional `notes`.
- **Evidence photos** (recommended, optional): attach item images via the catalog-image upload. The
  authentication record stores result/grade/notes only — photos live on the item, not the auth row.

## 4. Can staff complete it on the dashboard? (task 5–6) — YES
All six steps are dashboard routes behind the ACLs above; the item detail page exposes the "Correct item
metadata", "Authenticate", "Certify", and QR actions (each gated — visibility ≠ authorization). The
certificate snapshot and QR are produced by the certify step; the on-demand certificate PDF
(`CertificatePdfService`, already live) and the QR label view are then available. The one requirement:
**the acting staff account must hold** `sca.eyewear.view`, `sca.eyewear.metadata.correct`,
`sca.eyewear.catalog` (for photos), `sca.eyewear.authenticate`, and `sca.eyewear.certify`. These abilities
all exist in `acl.php`; grant them to the issuing staffer's role if not already held.

## 5. Blockers / missing inputs (task 7)
**No code or platform blockers.** Practical prerequisites only:
1. **Physical pair + inspection** — the genuine item must be physically present and authenticated by a
   qualified staffer (the real gate).
2. **Verified brand/model** — must be read from the frame and entered before certifying (snapshot ordering).
3. **Staff ACLs** — confirm the issuing account holds the five abilities above.
4. **QR label medium** — a printer / label stock for the physical QR tag (operational, not code).
5. Evidence photos are optional but recommended for a strong first provenance record.
6. Mail is `MAIL=log` and secure-claim RC `4bd88d2` is deployment-blocked — **neither matters here**:
   authentication/certification/QR issuance is fully email-independent and does not touch customer claiming.

## 6. Execution checklist — first genuine QR Passport (task 8)
Run on item **`SCA-058DAA468939`** (or another chosen imported record), physical pair in hand:
1. **Confirm authorization**: owner go-ahead for the first real certification; issuing staffer holds the 5
   ACLs.
2. Open the item in the dashboard: `/admin/sca/eyewear` → search `SCA-058DAA468939` → open detail.
3. **Correct metadata** → enter verified **brand** ("Alain Mikli"), **model** ("AO1347 Col.2895"), and any
   confirmed serial/year/country/materials/specs. Leave unknowns blank. Save.
4. *(Optional, recommended)* **Upload evidence photos** of the physical pair (catalog images).
5. **Authenticate** → `result = passed`, `condition_grade` = inspector's grade (A–D), optional notes. Save
   draft.
6. Review the draft, then **Finalize** → type **FINALIZE** to confirm. (Irreversible → immutable evidence.)
7. **Certify** → **Certify (confirm)** → type **ISSUE** to confirm. This atomically issues the certification,
   **mints + activates the QR Passport**, and freezes the certificate snapshot. Record the returned
   **certification number**.
8. **Verify**: item detail now shows a current certification + active QR; the public Passport resolves at
   `/p/{qr_public_token}`; the on-demand certificate PDF is available.
9. **Print the QR label** (`…/{id}/qr/label`, or batch) and affix it to the physical pair.
10. Ownership/claim is a **separate, later** step (collector transfer/claim) and is **not** part of issuing
    the Passport — do not initiate it here.

## Safety posture (this task)
Read-only. No DB write; no metadata/authentication/certification/QR/ownership change; no Shopify API request
or store change; no deployment/migration. Secure-claim RC `4bd88d2` not activated. Prod unchanged at
`6e36aa7`; all 205 imported records remain INTAKE/uncertified.

**STOP — Readiness CONFIRMED. The metadata→authenticate→finalize→certify(+QR snapshot)→label chain is live,
dashboard-driven, and ACL-gated; certification and QR Passport issuance are one atomic step. First candidate
= `SCA-058DAA468939` (item 17, Alain Mikli AO1347, variant `48797037494559`), INTAKE/uncertified, brand/model
NULL. No code blockers — prerequisites are physical (pair in hand, staff-verified brand/model entered before
certify, the 5 staff ACLs, a QR label printer; evidence photos recommended). Step-by-step checklist above.
Nothing issued; prod `6e36aa7` unchanged.**

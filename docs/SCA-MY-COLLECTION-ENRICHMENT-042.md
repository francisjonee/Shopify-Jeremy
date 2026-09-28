# SCA-MY-COLLECTION-ENRICHMENT-042 — Read-only planning / gap audit

**Type:** READ-ONLY planning. No feature branch, no code/schema/migration, no PDF generation, no deploy.
**Audited against:** implementation `main` @ `223cc40a8928af9b70ff2ab711b18c3fa4c31b38` (deployed).
**Method:** inspected actual routes, `CollectionService`/`CollectionController`, `CertificatePdfService`,
`sca_media_assets` schema, collection views, and existing behavior — not prior planning summaries.

`SCA-PRODUCTION-CUTOVER` remains BLOCKED/DEFERRED awaiting Jeremy.

---

## 1. Collector experience map (owned item)

The collector surface is entirely in `Sca\Collector`: `CollectionService` exposes only `ownedItems`,
`ownedItemByRef`, `activePassportTokenForOwnedItem` (041), `serviceHistoryForOwnedItem`,
`visibleDocumentsForOwnedItem`, `ownerVisibleDocument`. There are **no** collector routes for
certification/authentication/ownership/transfer/status *history*.

| Category | Data exists | Append-only vs projection | Staff sees | Collector sees today | Owner-exposure already authorized? | Sensitive content to gate |
|---|---|---|---|---|---|---|
| Certification history | `sca_certifications` + `sca_certification_events` (issued/revoked/superseded) | Append-only events + projection `current_certification_id` | Full history inc. correction reason (038 item page) | **Current only**: `certification_number` + date (from projection) | Current cert facts: yes (already on passport). History: **no** | `sca_certification_events.reason` (staff correction reason), `actor_staff_ref`, internal cert ids |
| Authentication history | `sca_authentications` (result, grade, inspector, notes, finalized) | Append-only | All authentications inc. inspector + notes | **Current only**: `condition_grade` + `authentication_date` of the current cert's source auth | Current grade/date: yes (passport). Full history: **no** | inspector identity (`performed_by_staff_ref`), authentication `notes`, failed attempts, internal ids |
| Ownership / transfer history | `sca_ownership_events`, `sca_transfer_events`, `sca_transfer_requests` | Append-only | Full ledger "Collector #\<id\>" (033) | **Nothing** — only `ownership = "Registered to you"` | **No** | **previous-owner identity** (`collector_account_id` of prior owners) — direct PII/linkage risk; correction reasons |
| Service history | `sca_service_events` | Append-only | All, inc. staff ref | **Yes** — type, condition-after, notes, date (`serviceHistoryForOwnedItem`, staff id excluded) | **Yes** (accepted since 015) | staff id already excluded; `notes` already deemed owner-safe by accepted behavior |
| Documents / certificate PDFs | `sca_media_assets` (`subject_type`,`subject_id`,`kind`,`is_public`) | Immutable generated evidence | All media for the item | **`is_public=1` only**: `kind` label + date + opaque handle (`visibleDocumentsForOwnedItem`) | **Yes** for public assets | non-public assets (fail-closed already); storage path/disk/checksum (not selected); **cert-PDF↔cert linkage not surfaced** (the finding, §2) |
| Registry-status history | `sca_status_events` | Append-only | Full status history + staff actions (022/024) | **Current only** `registry_status` + owner actions (lost/stolen/recovered) | Current status: yes. History: **no** | staff resolution/retire/invalidate reasons, internal ids |
| Public passport access | via active QR token → `/p/{token}` | Projection-gated (Option-A) | n/a | **Yes** (041) — eligibility-gated redirect | Yes | raw QR token (never rendered; 041) |

**Takeaway:** the collector today sees *current* projected facts + service history + public documents. No
append-only *history* is exposed. The one concrete, pilot-exposed defect is in **documents**: certificate
PDFs are shown without any current-vs-superseded distinction.

## 2. Certificate PDF finding (pilot: 2026-09-24 PDF shown while current cert is the 2026-09-25 successor `SCA-CERT-2026-5AC07F22`)

Determined precisely from code:

- **Which certification the PDF belongs to:** `sca_media_assets` keys each certificate PDF to one
  certification via `subject_type='certification'`, `subject_id=<certification id>`, `kind='certificate_pdf'`
  (`CertificatePdfService::ensureForItem` + `DocumentService::storeGeneratedMedia`). The 2026-09-24 PDF's
  `subject_id` is the **predecessor** certification; it does **not** belong to the current successor.
- **Immutable point-in-time?** **Yes.** `render($certId)` is a "byte-for-byte reproducible snapshot from
  immutable facts"; the media row is never mutated; a staff "repair" only restores the *same bytes* to the
  *same path* and must match the recorded `checksum_sha256` or fails closed. Each PDF is a permanent
  point-in-time document for its specific certification.
- **Does superseding leave the previous PDF?** **Yes, intentionally.** SCA-038 supersede touches only the
  certification-event ledger; it never touches `sca_media_assets`. The predecessor PDF row persists with
  `is_public=1` — correct for append-only immutable evidence.
- **Must a successor PDF be explicitly generated?** **Yes.** `ensureForItem` creates a PDF only for the
  *current* certification and only when a staff member triggers `admin.sca.certificate.generate`. It is
  **not** auto-generated on supersede, so after a supersede the successor has **no** PDF until staff run it.
  (This is why the pilot item shows only the older predecessor PDF.)
- **What happens if it is generated:** `ensureForItem` resolves `currentCertification` (= successor), finds
  no media row for `subject_id=successor`, renders and stores a **new** immutable `certificate_pdf` asset
  keyed to the successor (`is_public=1`). The predecessor PDF is untouched. Result: two PDFs — predecessor
  (superseded) and successor (current).
- **Should both remain accessible?** Per the append-only/immutable-evidence invariant, **yes** — neither is
  deleted or rewritten. The problem is purely **presentation**: they are indistinguishable today.
- **How the UI can distinguish Current vs Historical without rewriting evidence:** classify **at read time**
  by comparing each certificate PDF's `subject_id` to the canonical projection — `subject_id ==
  current_certification_id` → "Current certificate"; a `subject_id` that the certification-event fold marks
  `superseded`/`revoked` → "Superseded / historical certificate". No media row is mutated; no PDF is
  generated; immutable evidence is preserved and simply labeled.

## 3. Recommended smallest coherent SCA-042

### SCA-042 = collector-safe **certificate-document current/historical labeling** (read-only)

The pilot exposed a concrete, current usability/trust defect (owner shown a superseded certificate with no
indication). This is the smallest coherent, invariant-safe unit — chosen because the code shows the linkage
data already exists and no other history is currently exposed or requested.

**Exact scope**
- Enrich `CollectionService::visibleDocumentsForOwnedItem` to also read each media asset's `subject_type` +
  `subject_id` (already columns) and, for `kind='certificate_pdf'`, derive a **status label** by comparing
  `subject_id` against the item's canonical certification state (via `ProjectionService::currentCertification`
  and the certification-event fold): `Current` vs `Superseded`. Optionally include the PDF's own
  `certification_number` (a collector-safe, passport-allowlisted value) so the owner can match a PDF to a
  certificate number.
- Update `collection/show.blade.php` to render the label (e.g. a "Current certificate" / "Superseded
  certificate" badge) next to each certificate document. Non-certificate documents render unchanged.
- Optional (still read-only, no generation): when the current certification has **no** certificate PDF yet,
  show a neutral, non-actionable note ("A certificate for the current certification is being prepared") so a
  superseded PDF is never implied to be current. No button, no generation.

**Non-goals**
- No certificate PDF generation (no production or test PDF), no auto-generate-on-supersede (that is a staff/
  automation task — see §4). No deletion/rewriting/re-flagging of any media row. No exposure of
  certification/authentication/ownership/transfer/status **history**. No profile editing, notifications, QR
  download, staff changes, new public-passport fields, or domain work.

**Affected routes / services / views / schema**
- Routes: **none** (reuses `GET collector/collection/{ref}`).
- Service: `CollectionService::visibleDocumentsForOwnedItem` (+ a small read-only helper to classify by
  current/superseded certification).
- View: `sca-collector::collection.show`.
- **Schema: none** — `subject_type`/`subject_id` already exist and already link a PDF to its certification;
  current/superseded is derivable from existing append-only events. No migration required.

**Privacy policy**
- Expose only: document `kind` label, date, opaque handle (as today), a derived `Current`/`Superseded`
  label, and optionally the certificate's own `certification_number`. **Never** expose `subject_id`/internal
  ids, storage path/disk/checksum, other-owner data, or tokens. Only `is_public=1` assets remain listed
  (fail-closed unchanged). Authorization stays "current owner of the item" (`ownedItemId`).

**Acceptance tests (focused)**
- Owner of a superseded-then-current item sees the successor's PDF labeled **Current** and the predecessor's
  PDF labeled **Superseded** (once both exist).
- When only a superseded PDF exists (successor PDF not yet generated), it is labeled **Superseded** and is
  never presented as current; the neutral "being prepared" note shows if implemented.
- A single-certification item's PDF is labeled **Current**.
- No `subject_id`/internal id/storage path/checksum/token rendered.
- Non-owner / unauthenticated fail closed (unchanged).
- The listing is read-only: zero mutation across `sca_media_assets` and all domain tables; no PDF generated.
- Public passport (`/p/{token}`) and existing document **download** authorization unchanged.

**Regression gates**
- Full `tests/Feature/Sca` green; `CertificatePdfTest`, `DocumentsTest`, `MyCollectionTest`,
  `CollectorPassportAccessTest` unaffected. `php -l`, `composer validate --strict`, `composer audit`,
  secret/debug scan.

## 4. Remainder ranked for SCA-043+

1. **Successor certificate-PDF generation after supersede** (staff-triggered or auto-on-supersede) — the
   *mutation* half of the pilot finding. Deferred from 042 (which is read-only). Must keep the predecessor
   PDF immutable and generate the successor's PDF as a new immutable asset. Small, but a staff/automation +
   generation task, so separated.
2. **Collector certification history** (issued → superseded/revoked → current), read-only, deriving from the
   append-only cert-event fold — **must classify/withhold** `reason` and `actor_staff_ref` (staff-only).
3. **Collector service/authentication summary enrichment** (e.g., surface condition-grade lineage) —
   authentication *history* requires withholding inspector identity + notes classification.
4. **Collector-facing ownership/transfer history** — **highest privacy risk** (previous-owner identity/
   linkage). Likely should show only "you have owned since \<date\>" style facts, never prior-owner PII;
   needs an explicit privacy design before any exposure.
5. **Registry-status history for the owner** — read-only, withholding staff reasons/ids.
6. Downloadable-records / insurance-report bundle (Jeremy §189/§175) — larger, later.

## 5. Governance

Planning only. No branch, no code/schema/migration/generation/deploy. `NEXT_TASK` stays **NONE**;
SCA-042 is recorded here for ChatGPT review and is **not** implementation-active. SCA-043 not promoted.

**STOP — audit for ChatGPT review.**

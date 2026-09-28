# SCA-ITEM-METADATA-CORRECTION-046 — Read-only planning / architecture audit

**Type:** READ-ONLY planning. No implementation, branch, schema, migration, data change, or PDF/snapshot
generation/reconstruction.
**Audited against:** implementation `main` @ `17854a86f12d16485c7eb05ffa5418d7036a8eee` (deployed).
**Method:** inspected SCA-035 (`OwnershipCorrectionService`) + SCA-038 (`CertificationCorrectionService`)
correction patterns, `sca_eyewear_items` schema + SCA-044 fields, SCA-045 snapshot architecture
(`CertificateSnapshotService`, `CertificatePdfService` render/repair), the passport/My-Collection live-reads,
and current production snapshot coverage.

`SCA-PRODUCTION-CUTOVER` remains BLOCKED/DEFERRED awaiting Jeremy.

## Key facts established
- `sca_eyewear_items` is **not** in the append-only trigger set → the row is UPDATE-able; the item row is the
  natural **current-value projection**, updated by the correction service (governed, gated, audited — not
  ad-hoc CRUD).
- Passport (`PassportPresenter`) and My Collection (`CollectionService`) read item metadata **live** → after
  a correction they show the **current corrected** value, while a frozen SCA-045 certificate snapshot keeps
  showing the as-issued value.
- **Production reality: all 3 certifications are snapshot-less legacy (0 snapshots); certs 2 & 3 have existing
  PDFs** (checksums `0f74aee3…`, `bc01e71e…`). So the legacy brand/model boundary governs every current
  certified item.
- `sca_item_metadata_events` does not exist yet.

## 1. Canonical correction model — recommended
Keep the audited model: **append-only `sca_item_metadata_events` + the `sca_eyewear_items` row as the current
projection.** Minimum event schema (typed, bounded, append-only per convention):
`id`, `eyewear_item_id` (FK), `correction_group_id` (opaque, ties fields changed in one request),
`field` (enum/CHECK of the 7 correctable fields), `old_value` (text, nullable), `new_value` (text, nullable),
`reason` (varchar 255, mandatory), `actor_staff_ref` (unsigned, soft ref like other events),
`created_at` (useCurrent). Ordering by (`created_at`,`id`); stale guard by row count (below).

**One event per changed field, grouped by `correction_group_id`** (recommended over one combined
before/after blob). Rationale: matches the codebase's typed-column convention (it deliberately avoids JSON),
gives clean per-field history ("brand: X→Y on <date> by staff #n, reason …"), and the group id reconstructs
"this correction changed brand + year" for the UI. `old_value`/`new_value` are stored as text because a
metadata event is an audit record; the **typed** current value is enforced on the `sca_eyewear_items` column
during the projection update.

## 2. Legacy certificate boundary — HARD DECISION
When staff correct a **PDF render input (`brand`/`model_name`)** for an item whose current certification has
**no SCA-045 snapshot**: the existing immutable PDF file is unaffected by the correction itself, but it would
become **un-repairable if later lost** (repair re-renders from current item state → checksum mismatch →
fails closed). All 3 production certs are in this state today.

- **Option A — block PDF-relevant correction for snapshot-less legacy certs.** Provably safe, zero new
  rendering coupling, honest. Cost: brand/model typos on the 3 existing pilot certs can't be fixed until a
  separate reconstruction task ships.
- **Option B — reconstruct a `source='reconstructed'` snapshot from current pre-correction state first.**
  Evidence shows B **can be made provably safe** only with a mandatory verification gate: render the
  reconstructed snapshot and require it to reproduce the **existing certificate PDF's recorded checksum**
  before accepting it (we proved base↔candidate v1 byte-identity in SCA-045, so for an un-corrected legacy
  item the reconstructed values equal the issuance-time values and reproduce the stored PDF). Without that
  gate, B risks misrepresenting reconstructed data as issuance truth. B also (a) re-couples the correction
  path to dompdf rendering, (b) must handle legacy certs that have **no** PDF (nothing to verify against),
  and (c) would be exercised against all 3 production certs immediately.

**Recommendation: Option A inside SCA-046** (block brand/model for snapshot-less legacy certs, with a clear
domain rejection), and make the **verified-reconstruction Option B a SEPARATE prerequisite task** that later
unblocks legacy brand/model. Reconstruction is *achievable* safely but is its own audited unit (render-verify
semantics, no-PDF-legacy handling, honest `reconstructed` labeling) — not bundled into the first correction
slice. brand/model **remain correctable in SCA-046 for snapshotted (post-045) certifications** (safe — §3).

## 3. Post-045 snapshotted certifications — confirmed safe
For a certification that already has a snapshot, a metadata correction: updates only the item row + appends
metadata events; it does **not** modify the snapshot, re-render/alter the PDF, change its checksum, or touch
certification history. The PDF renders from the frozen snapshot (SCA-045), so it stays the as-issued
point-in-time document; passport/My Collection/staff detail show the current corrected values. brand/model
correction is therefore safe for snapshotted certs.

## 4. Non-PDF fields — proceed independently
`frame_serial`, `year`, `country_of_origin`, `materials`, `original_specifications` are **not** certificate
render inputs (SCA-045 confirmed the PDF's 9 inputs; these are not among them). Correcting them can never
affect any PDF/snapshot/checksum, so they proceed for **all** certifications (snapshotted or legacy) with no
certificate-integrity gate. Do not block them.

## 5. Privacy / public-surface behavior
Preserve SCA-044 classification: public = `year`, `country_of_origin`, `materials`, `brand`/`model`;
owner/staff-only = `original_specifications`, `frame_serial`. **Correction history, reasons, old values, and
actor identity are STAFF-ONLY** (default yes; no existing architecture exposes them elsewhere). Passport and
My Collection expose only the resulting **current** values per their existing classification — never
correction reasons, staff identity, or historical/sensitive old values.

## 6. Concurrency / stale-state
Established pattern: one `DB::transaction` that `lockForUpdate`s `sca_item_current_state` for the item; stale
guard = the append-only **metadata-event count** for the item that the staff screen carried
(`expectedEventCount`), a monotonic token for a brand-new ledger (a concurrent metadata correction bumps it →
STALE). Ownership/cert corrections don't touch this ledger, so the metadata-event count is the correct,
independent guard. Re-validate current values inside the boundary; append events; update the item projection
columns; commit atomically.

## 7. ACL / staff workflow
Dedicated **`sca.eyewear.metadata.correct`** (never reuse view/certify/ownership-correct/certification-correct
permissions). Smallest workflow off the staff item-detail page: "Correct item metadata" → GET confirm
interstitial showing current values + per-field inputs + mandatory reason + typed confirmation (e.g. `CORRECT`)
+ the `expectedEventCount` token → POST applies atomically. **Unchanged fields produce no event**; a request
that changes nothing is a NOOP (rejected/no-op, per 035). PDF-relevant fields (`brand`/`model`) are only
offered/accepted when permitted by the §2 legacy policy.

## 8. Provenance isolation
Correction mutates only: INSERT into `sca_item_metadata_events` + UPDATE of the changed `sca_eyewear_items`
columns. It must NOT touch ownership events/projection, claims, transfers, certification rows/events,
certificate snapshots, media/PDF rows or files, QR identity/lifecycle, registry-status events, authentication
history, or service history. Regression tests assert each of these is byte/content-identical before/after a
correction.

## 9. Migration impact
Additive only: new `sca_item_metadata_events` table + `_no_update`/`_no_delete` append-only triggers +
`field`/value CHECK(s) + FK to `sca_eyewear_items`; register `sca.eyewear.metadata.correct` in the Registry
ACL config. No backfill; no modification of SCA-045 snapshot rows; no change to `sca_eyewear_items` columns
(they already exist from SCA-044).

## 10. Acceptance test matrix (proposed)
Authorized correction persists new values + one event per changed field (grouped); unauthorized staff → 403;
collector/public → denied; mandatory reason enforced server-side; typed confirmation enforced; no-op (nothing
changed) rejected/no-op with no event; multi-field correction is atomic (all-or-nothing, one group id); stale
concurrent submission → STALE, zero mutation; metadata events are append-only (UPDATE/DELETE rejected);
passport/My Collection/staff detail show corrected current values; public/private field boundaries preserved
(reasons/actor/old-values never public); a **snapshotted** certificate's snapshot + PDF + checksum + cert
history are byte/content-identical after a brand/model correction; **legacy snapshot-less brand/model** follows
the recommended policy (blocked with a safe rejection in SCA-046); **non-PDF legacy field** correction
succeeds; QR/ownership/certification/status/authentication/service provenance byte/content-identical; zero
unintended PDF generation/repair; existing NULL-metadata items correct cleanly (NULL→value and value→NULL).

## 11. Recommended smallest implementation slice
**SCA-046 = append-only correction for the 5 non-PDF fields (`frame_serial`, `year`, `country_of_origin`,
`materials`, `original_specifications`) for ALL certs, PLUS `brand`/`model_name` correction ONLY when the
item's current certification has an SCA-045 snapshot.** brand/model correction on a **snapshot-less legacy**
certification is **temporarily blocked** (clear domain rejection). This delivers the full correction
capability everywhere it is provably safe, with no rendering coupling and no reconstruction risk.

**The legacy brand/model problem is a SEPARATE prerequisite task** (verified Option-B reconstruction:
render-and-checksum-match-or-block, honest `reconstructed` labeling, no-PDF-legacy handling) that later
unblocks brand/model on the existing legacy certs. It should not be bundled into SCA-046.

Deliverables for SCA-046: migration (`sca_item_metadata_events` + triggers + CHECK/FK) + ACL entry;
`ItemMetadataCorrectionService` (lock + stale guard + per-field diff + append + projection update);
`ItemMetadataCorrectionController` (GET confirm + POST) with `sca.eyewear.metadata.correct`; a request class
(reason + typed confirm + expected count + per-field inputs); staff item-detail entry point; focused tests
per §10. No production migration/backfill; snapshot rows untouched.

## Governance
Planning only — `NEXT_TASK` stays **NONE**; SCA-046 recorded here for ChatGPT review, not
implementation-active. SCA-047 not promoted.

**STOP — audit for ChatGPT review.**

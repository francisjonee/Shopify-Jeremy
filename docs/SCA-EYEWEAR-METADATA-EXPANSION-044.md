# SCA-EYEWEAR-METADATA-EXPANSION-044 — Read-only planning / gap audit

**Type:** READ-ONLY planning. No implementation, branch, schema, migration, data change, or deploy.
**Audited against:** implementation `main` @ `50c54ad2ce0afe8f993e11d8b1979e5d667c7935` (deployed) +
`docs/PRODUCT_REQUIREMENTS.md`.
**Method:** inspected the Digital Provenance Record requirement, `sca_eyewear_items` schema, the intake
flow, and every reader/writer of item descriptive fields (staff detail, My Collection, passport, certificate
PDF, claim/support surfaces).

`SCA-PRODUCTION-CUTOVER` remains BLOCKED/DEFERRED awaiting Jeremy.

---

## 1. Required fields (from `PRODUCT_REQUIREMENTS.md` — "Digital Provenance Record")

The record "should support": **Model**, **Manufacturer / brand**, **Year**, **Country of origin**,
**Materials**, **Original specifications**, Authentication record, Condition grade, Inspection images,
Certification status, Current ownership status, Ownership/Transfer/Service history, Market information
(future).

Of these, the ones **not modeled as identity metadata** today are **Year, Country of origin, Materials,
Original specifications** — but these four are not asserted as the final set; they are the explicit missing
identity fields. Condition grade / inspection images / authentication record are **not** item metadata (see
§3 category B). No requirement states these four are mandatory; treat them as **optional** (records are
often partial).

## 2. Current state (evidence)

- **Schema `sca_eyewear_items`:** `public_ref` (immutable opaque), `model_name` (nullable), `brand`
  (nullable), `frame_serial` (nullable, advisory/non-unique), `intake_type`, timestamps. Index
  `(brand, frame_serial)`. **No** year/country/materials/specifications.
- **Intake:** `StoreEyewearItemRequest` validates `brand|model_name|frame_serial` (nullable strings) +
  `intake_type`; `ItemService::create` inserts the item + its `sca_item_current_state` row.
- **Items are create-only.** There is **no UPDATE to `sca_eyewear_items` anywhere** in the codebase (verified
  by grep; the only `->update` calls are on collector_accounts / authentications / shopify_sale_links).
  Item identity metadata is set once at intake and never edited today.
- **Readers of item descriptive fields:** staff `EyewearItemController@show` + `eyewear/show.blade`,
  `index.blade` (search over public_ref/brand/model), `CollectorSupportController` (040), `CollectionService`
  (My Collection detail/summary), `PassportPresenter` (+ `PublicAllowlist`, `passport/show.blade`),
  `CertificatePdfService`, claim/grant controllers + `AuthContextResolver` (labels).
- **Public exposure gate:** `PublicAllowlist::FIELDS` tags each passport key public **(P)** or sensitive
  **(S)**; `assertOnlyAllowlisted` fails loudly on any non-allowlisted key. `brand`/`model` are (P);
  **`frame_serial` is (S) — deliberately excluded** from the public passport (anti-counterfeiting).
- **Certificate PDF fact source (critical):** `CertificatePdfService::snapshotForCertification` reads
  `brand`/`model_name` **live from the item row** at render/repair time — there is **no frozen per-cert
  item snapshot**. Because items are immutable today, live-read == point-in-time and the PDF renders
  byte-identically, which is what makes the checksum-verified **repair** path work.

## 3. Identity vs observation vs correctable (A / B / C)

- **A — Identity metadata (permanent physical facts, belong to the item row + correction provenance):**
  brand, model_name, frame_serial (existing) + **year, country_of_origin, materials,
  original_specifications** (new). These describe the physical eyewear.
- **B — Authentication/certification observations (must NOT be modeled as item metadata):** condition grade,
  inspection findings, inspection images, pass/fail. These already live on `sca_authentications` /
  authentication media and must stay there. Do **not** move or duplicate them onto the item. (Note: a value
  like "materials" could be *observed* during authentication, but as an enduring **identity** fact it belongs
  to the item, recorded once, not per authentication.)
- **C — Correctable metadata (A-fields entered wrong):** must be fixed through an **auditable, append-only**
  correction — never ordinary destructive row editing — mirroring SCA-035 (ownership) / SCA-038
  (certification). Destructive edits are rejected: they erase provenance and (see §4) break certificate
  repair.

## 4. Certificate snapshot / provenance boundary (the key risk)

The certificate PDF is checksum-locked immutable evidence, but its displayed item facts are read **live**.
Consequences once metadata becomes expandable/correctable:

- A change to any item field the certificate displays, **or** any change to the certificate template/field
  set, makes a previously-generated PDF's deterministic **re-render diverge** from the stored bytes →
  checksum mismatch → the **repair** path (restore a lost file) **fails closed**, and the immutable PDF no
  longer matches current item data.
- Therefore, before the certificate PDF displays new metadata, **or** before any correction can touch a
  PDF-displayed field, the certificate must **freeze a per-certification snapshot of exactly the item facts
  it renders, plus a template version**, and render/repair from that frozen snapshot — not from the live
  item row. This decouples immutability from later item edits and template evolution.
- **Boundary rule:** the certificate is a point-in-time attestation of the item facts **as of issuance**;
  the passport / My Collection show **current** item facts. A later correction updates current views but must
  **not** retroactively alter any issued certificate PDF.

## 5. Recommended data & correction model

- **Identity metadata (A)** → nullable columns on `sca_eyewear_items`: `year` (smallint/nullable),
  `country_of_origin` (string), `materials` (string/text), `original_specifications` (text). The item row
  holds the **current** value (fast reads for passport/PDF/search).
- **Correction (C)** → an **append-only** `sca_item_metadata_events` ledger (item_id, field/values, reason,
  actor_staff_ref, created_at), written atomically under the item current-state lock, updating the row's
  current value — exactly the events+projection pattern used for ownership (035). The append-only ledger is
  the audit source of truth; the row is the projection. Guarded by a dedicated ACL
  `sca.eyewear.metadata.correct` (distinct from create). Never a destructive bare UPDATE.
- **Observations (B)** stay on `sca_authentications`; untouched.

## 6. Recommended sequencing — smallest slice first

**Slice 1 (recommended SCA-044, smallest & safest): additive intake fields, NOT on the certificate PDF.**
- Add the four nullable identity columns; capture them in `StoreEyewearItemRequest` + `eyewear/create.blade`
  + `ItemService::create`; display on staff item detail, My Collection detail, and the public passport
  (adding (P) allowlist entries + presenter fields for the public-safe ones).
- **Do NOT modify the certificate PDF template** → no existing immutable PDF is affected, repair stays
  deterministic, no snapshot-freezing needed yet.
- **No correction mechanism** (items remain create-only for now).
- **Backfill:** none — columns are nullable; existing pilot records read NULL and render "—"/omitted.

**Slice 2 (later): certificate snapshot-freezing + template versioning** — prerequisite for putting new
fields on the certificate PDF and for any correction that touches PDF-displayed fields. Freeze per-cert item
facts at generation; render/repair from the frozen snapshot.

**Slice 3 (later): append-only metadata correction (category C)** — `sca_item_metadata_events` + dedicated
ACL, mirroring 035/038; only safe once Slice 2 protects issued certificates.

This ordering delivers the DPR fields immediately while keeping the risky parts (immutable-PDF coupling and
provenance-safe correction) as separate, independently-audited slices.

## 7. Privacy / security per field

- `year`, `country_of_origin`, `materials` → **public (P)** on the passport (non-PII identity facts, matching
  the DPR intent).
- `original_specifications` → **review before public exposure**; if it can carry identifying/serial-like
  detail, keep it **staff/owner-visible only** (like `frame_serial` (S)) until classified. Conservative
  default: not on the public passport in Slice 1.
- `frame_serial` remains **(S)**, excluded from the passport. No new PII is introduced.

## 8. Migration / compatibility / search

- **Migration:** additive nullable columns only (safe, online); **no backfill required**. Slice 3 would add
  the `sca_item_metadata_events` table + ACL. Slice 2 would add a per-cert snapshot column/table.
- **Compatibility:** existing pilot records (e.g., `SCA-F1B792AE4745`) simply have NULL new fields; nothing
  breaks. Slice 1 not touching the PDF means existing certificate PDFs and their repair remain valid.
- **Search/filter:** current index search is public_ref/brand/model. Extending search to new fields (and any
  supporting index) is a **later, optional** enhancement, not part of Slice 1.

## 9. Acceptance tests (Slice 1)

- Intake accepts and persists the four new nullable fields; omitting them is valid (nullable).
- Staff item detail + My Collection render the new fields when present and gracefully omit when NULL.
- Public passport shows only the (P)-classified new fields; `assertOnlyAllowlisted` passes; no (S) field
  (frame_serial, and original_specifications if withheld) leaks.
- Existing pilot records (NULL new fields) render without error on all surfaces.
- **Certificate PDF is unchanged**: existing certificates still generate/repair byte-identically (template
  untouched); no checksum breakage.
- No item UPDATE path is introduced (items remain create-only in Slice 1); zero change to
  QR/ownership/certification/provenance; SCA-041 passport access + SCA-042 classification unchanged.
- Full `tests/Feature/Sca` green.

## 10. Governance
Planning only — `NEXT_TASK` stays **NONE**; SCA-044 recorded here for ChatGPT review, not
implementation-active. SCA-045 not promoted.

**STOP — audit for ChatGPT review.**

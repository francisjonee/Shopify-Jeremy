# SCA — Owner-Triggered On-Demand Certificate PDF Availability

**A certified item's owner can now make their official SCA certificate available for download
themselves, closing the gap where a certificate existed only after a separate staff action — by reusing
the existing idempotent certificate service, with no change to certification behavior.** Development-only,
on an isolated branch; no tests run; production unchanged at `b007606`. Branch
`feature/sca-collector-certificate-availability` = `a923dfd` (off `63b5808`). 2026-10-30. **STOP for
review.**

## 1. Review of the existing certificate workflow
- `CertificatePdfService::ensureForItem(itemId)` renders the canonical, immutable, byte-reproducible
  certificate PDF for the item's **current issued certification** and stores it as ONE
  `sca_media_assets` row (`subject_type=certification`, `kind=certificate_pdf`, `is_public=1`). It is
  **idempotent and concurrency-safe**: wrapped in a transaction that `lockForUpdate`s the item
  current-state row, it looks up existing media by `(certification, certificate_pdf)` and returns it
  unchanged on replay; a missing file is repaired to the **same recorded checksum**; it requires an
  already-issued certification (`NO_ISSUED_CERT` otherwise). It issues/alters nothing.
- **Trigger today:** only staff, via `POST /admin/sca/certificate/{ref}` (ACL `sca.eyewear.certificate`).
  It is **not** automatic at certification time.
- **Collector retrieval today:** the Documents tab lists `is_public` certificate assets
  (`visibleDocumentsForOwnedItem`) and downloads via `CollectionDocumentController`
  (`ownerVisibleDocument`), both gated on **canonical current ownership**.

## 2. Gap and business requirement
Per `PRODUCT_REQUIREMENTS` (certificates / downloadable records) and roadmap Phase 9 `SCA-DOCUMENTS-017`,
a certified item's owner should be able to obtain their certificate. Because generation is a separate
staff step, a genuinely-certified item can have **no downloadable certificate** in the owner's My
Collection until staff act. That is the exact gap. (Distinct from the regenerable Digital Provenance
Report, which is on-demand and not stored; the **certificate** is the immutable issued attestation.)

## 3. What was implemented (reuse, not reinvention)
A collector viewing an item they currently own sees, on the **Certification** tab, a **"Make my
certificate available (PDF)"** button — shown only when the item **has an active certification** but **no
current certificate PDF** is yet downloadable. Submitting it (POST, CSRF, throttle 10/min) calls the
**existing** `CertificatePdfService::ensureForItem`; the certificate then appears under Documents for
download via the existing surface.

New `CollectorCertificateService.ensureForOwnedItem(collectorId, publicRef)`:
- resolves the internal item id **only for a currently-owned item** (`ownedItemIdByRef`, a thin public
  accessor over the existing owner-authorized `ownedItemId`); a non-owner / previous owner / unknown ref
  → `not_owner` → the controller returns the shared privacy-safe real 404;
- delegates to `ensureForItem`; maps `NO_ISSUED_CERT` → `no_certification` (clean message, not an error);
- otherwise `ready`.

## 4. Changed files (branch `a923dfd`, off `63b5808`)
New:
- `app/packages/Sca/Collector/src/Services/CollectorCertificateService.php`
- `app/packages/Sca/Collector/src/Http/Controllers/CollectionCertificateController.php`
Modified:
- `app/packages/Sca/Collector/src/Services/CollectionService.php` — `+ public ownedItemIdByRef()` (thin
  owner-authorized accessor over the existing private `ownedItemId`; no query change).
- `app/packages/Sca/Collector/src/Routes/collector-routes.php` — `+ POST collection/{ref}/certificate`
  (`collector.collection.certificate`, CSRF via web group, throttle 10,1).
- `app/packages/Sca/Collector/src/Resources/views/collection/show.blade.php` — the conditional button.

No migration; no new table; no change to the certification / QR / ownership / transfer services or their
invariants.

## 5. Security considerations (requirements 7–10)
- **Never issues a new certification, alters, or duplicates the immutable document** (req 7): all work is
  the existing `ensureForItem`, which requires a pre-existing issued certification and reuses/repairs the
  one artifact.
- **Concurrency / repeat requests cannot duplicate** (req 9): `ensureForItem` serializes on the item
  current-state row and looks up existing media before creating; a second concurrent/duplicate POST
  returns the existing document (`created=false`). The route is additionally throttled 10/min.
- **Owner authorization + visibility + transfer access preserved** (req 8): the action is gated on
  canonical current ownership; the produced asset is `is_public=1` and surfaces through the existing
  current-ownership-gated Documents rules — the **new owner** can generate/download after a transfer; the
  **previous owner** and any non-owner get the shared privacy-safe 404; staff-only (`is_public=0`)
  documents are unaffected.
- **No PII / tokens / internal ids / storage paths exposed:** the controller handles only the opaque
  `public_ref` and flash messages; the internal item id is used server-side only; the certificate
  content is the existing provenance-safe PDF.
- **Independent of Shopify and transactional email** (req 10): `ensureForItem` touches neither.

## 6. Tests required later (NOT run — owner testing freeze)
- Owner with an issued cert + no existing certificate doc → POST makes it available (appears under
  Documents); a second/concurrent POST creates **no** duplicate media row (one artifact); an item with no
  issued certification → `no_certification` message, no media created.
- Authorization: non-owner / previous-owner-after-transfer / unknown ref → shared privacy-safe 404; new
  owner after transfer can generate and download; previous owner cannot.
- The button shows only when certified-but-no-current-certificate-doc, and disappears once available.
- No side effects: generating appends no ownership/status/cert event, no projection rebuild, issues no
  certification; certificate bytes/checksum identical to the staff-generated artifact.
- Isolated disposable-DB regression + existing certificate/document/collector suites before any RC/deploy.

## 7. Safety posture (this task)
Development-only on an isolated branch off `63b5808`. No production merge/deploy/migration/DB write; no
automated/DB/integration/production tests; no live Shopify API or store change; no live certification/PDF
generation; no live claim/transfer; no email configuration; no secure-claim RC (`4bd88d2`) deploy; no
Option C. Production unchanged at `b007606`.

**STOP — owner-triggered on-demand certificate availability implemented on
`feature/sca-collector-certificate-availability` (`a923dfd`): a currently-owning collector can make the
canonical certificate PDF available via the existing idempotent/concurrency-safe `CertificatePdfService`,
which never issues/alters a certification or duplicates the immutable document; owner authorization,
public-document visibility, and ownership-transfer access are preserved; independent of Shopify/email; no
migration. Static checks clean; no tests run (owner freeze). Branch pushed; production unchanged at
`b007606`. Now three stacked unmerged branches: `ba2da33` ← `63b5808` ← `a923dfd`. Secure-claim RC
`4bd88d2` untouched.**

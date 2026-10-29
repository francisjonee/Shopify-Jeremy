# SCA — Physical Eyewear Inventory Onboarding Strategy (READ-ONLY)

**The fastest safe way for Jeremy's team to onboard genuine SCE inventory and prepare per-pair QR
Passports.** Bulk physical-item registration (CSV) and batch QR-label printing are already implemented;
authentication + certification (which mints the QR) are deliberately per-item human steps and are the
real throughput constraint. Importing the Shopify catalog as items is neither done nor advisable.
Read-only review at prod `4faf84d`; no code/DB/Shopify/import/cert/QR change. 2026-10-29. **STOP.**

## [1][2] Data models — three distinct things (do not conflate)
- **Shopify product** (`sca_shopify_products`, 4575 rows) and **variant** (`sca_shopify_variants`, 5345)
  — the synced catalog mirror. A variant is a **SKU with a quantity**, not an individual pair.
- **Physical eyewear item** (`sca_eyewear_items`) — ONE row per individual physical pair, with its own
  immutable system-generated `public_ref`. This is the provenance unit (authentication, certification,
  QR, ownership, transfer all attach here).
- **Link** (`sca_eyewear_item_shopify_variant`) — an optional reference join: **one item → at most one
  variant; many items → one variant** (several physical pairs of one SKU). Reference only; never drives
  auth/cert/QR/ownership.

## [3][4] Batch onboarding — SUPPORTED for item registration (CSV)
`InventoryImportController` + `InventoryImportService` (`/admin/sca/eyewear/import`, ACL
`sca.eyewear.create`): **form → preview (zero mutation) → confirm**.
- Accepts a CSV with exactly the intake fields (`intake_type, brand, model_name, frame_serial, year,
  country_of_origin, materials, original_specifications`).
- `preview()` validates + classifies every row INVALID / WARNING / VALID (with in-file duplicate
  detection); `import()` creates VALID (and explicitly-acknowledged WARNING) rows via the canonical
  `ItemService::create` — each frame gets its own `public_ref` + one INTAKE projection row and
  **NOTHING else** (no auth/cert/QR/ownership/sale-link/media/catalog).
- **Idempotent + resumable + dedup-safe:** `sca_inventory_imports.content_sha256` UNIQUE (same file = one
  batch; re-upload resumes, never re-imports a finished batch); `sca_inventory_import_rows`
  `UNIQUE(import_id, source_line)` (≤1 item per source line per batch); item-create + ledger row in ONE
  transaction (a conflict rolls back the would-be duplicate). Insert-only — never overwrites.
- **Cap: 500 data rows per CSV** (`MAX_ROWS`, swapless host, no background jobs) → larger inventories
  are split into multiple ≤500-row batches.
So hundreds of pairs are **registered** without repeating the per-item create. (Authentication,
certification/QR, and variant-linking are separate — see [5]/[7]/[11].)

## [5] Authentication / certification / QR safeguards — per-item, by design
- **Authenticate → finalize** (`/admin/sca/eyewear/{id}/authenticate` → `…/finalize`, ACL
  `sca.eyewear.authenticate`): records the human authenticity judgment; a typed-confirm finalize.
- **Certify** (`/admin/sca/eyewear/{id}/certify`, ACL `sca.eyewear.certify`): `CertificationService::issue`
  **requires a same-item, finalized, PASSED authentication** (validated in the service AND DB-enforced)
  and, in the same transaction, **mints + activates the one-active QR identity** (rejects if an active
  QR already exists → exactly one QR per item). Certifying IS the QR-generation step.
- These are **intentionally per-item** and not batched: authentication is a human judgment, and the QR
  identity is minted only off a real passed authentication. This is the core authenticity safeguard and
  must not be bypassed by any bulk automation.

## [6] Would importing Shopify catalog records as items create bad data? — YES, avoid it
- The CSV import does NOT read the Shopify mirror; it onboards **staff-provided intake rows**. Good:
  a variant is a SKU-with-quantity, so importing 5345 variants as 5345 items would wrongly conflate
  SKUs with individual pairs and fabricate non-existent inventory.
- Catalog sync **never creates items** (`ProductCatalogService` writes only catalog tables); so the
  mirror cannot leak into provenance.
- Within CSV import, **duplicates are prevented** (content-hash batch identity + per-line unique ledger +
  in-file dup detection), and imported items are **UNCERTIFIED** (no QR) until a human authenticates +
  certifies them — so import cannot create certified/incorrect records. Conclusion: **register via CSV
  of real intake data; never bulk-import the catalog as items.**

## [7] Associating each pair with its exact Shopify variant
Via the item-detail **Shopify catalog link** panel (`ShopifyProductLinkService`, ACL
`sca.eyewear.shopify.link`): staff search the **synced catalog** (product/vendor/SKU — no Shopify API)
and select the exact variant; the link is by **exact Shopify variant id** (never fuzzy name matching),
`UNIQUE(eyewear_item_id)` (one variant per item), many-items-per-variant allowed, fully audited. This is
currently **per item** (not part of CSV import) — see the [11] automation recommendation.

## [8] Batch QR-label generation — SUPPORTED
`POST /admin/sca/eyewear/qr/labels` (`qrLabelsBatch`, ACL `sca.eyewear.view`): takes a list of item ids
(deduped, capped at `MAX_BATCH_LABELS`), renders a **printable sheet** of each item's ACTIVE QR, and
safely **skips** any item without an active QR. (Single-item `…/qr` SVG + `…/qr/label` also exist.) This
supports warehouse QR-label preparation in sheets after certification.

## [9] Practical onboarding for 10 / 100 / 1,000 pairs
All three use the same pipeline; only batching/throughput differ.
- **10 pairs:** one CSV import (or manual create) → authenticate+finalize+certify each (QR auto-minted) →
  link each to its Shopify variant → batch-print the 10 QR labels. Minutes of tooling; the work is the
  10 authentications.
- **100 pairs:** one CSV batch (≤500) registers all 100 at once → the **bottleneck is 100 per-item
  authentications + certify clicks** (irreducibly human for authenticity) → link variants → batch-print
  labels in sheets. Plan staff time around the ~100 authentications, not the registration.
- **1,000 pairs:** **2–3 CSV batches** (≤500 each) register everything quickly → the dominant cost is
  **~1,000 authentications + 1,000 certifications** (human judgment; cannot be safely automated away) →
  variant links → batch-print labels. Registration and labeling scale fine; authentication/certification
  is the throughput constraint and should drive staffing/scheduling.

## [10] Implemented vs would-require-development
- **Implemented/deployed:** CSV bulk item registration (≤500/batch, idempotent/resumable/dedup); per-item
  authenticate→finalize→certify (atomic QR mint); per-item Shopify-variant link; batch QR-label printing;
  order→eyewear assignment (at sale time).
- **Would require development (optional, additive):** variant-linking at import time; a certification
  **worklist** (certify many finalized-authenticated items from one screen); raising/removing the 500-row
  cap would need background jobs (unsafe on the swapless host without them). **No** safe path batches the
  authentication judgment itself.

## [11] Smallest safe automation (reduce manual work, never bypass auth/cert)
**Recommended — import-time variant linking (additive, highest leverage):** extend the CSV import to
accept an **optional** Shopify variant reference per row (SKU, or product/variant id) and, for rows that
carry one, create the `item ↔ variant` link in the same import transaction via the existing, already-
validated `ShopifyProductLinkService` (active-variant check + `UNIQUE(eyewear_item_id)` guard + audit).
This removes the per-item manual linking step for catalog-mapped inventory **without touching
authentication, certification, or QR** — import still creates only uncertified items (+ a reference
link). A row with no/invalid variant simply onboards unlinked (fail-open on the optional field, never
fabricated).
**Secondary (optional) — certification worklist:** a staff screen listing finalized-PASSED-but-
uncertified items with a one-click certify per item (each a real certification minting its own QR; the
authentication decision and the one-QR-per-item rule are unchanged). Cuts navigation overhead for large
batches without weakening the safeguard.
**Explicitly NOT recommended:** any bulk/auto "certify" that skips a finalized passed authentication, or
importing the Shopify catalog as physical items — both would bypass the authenticity safeguard / create
bad data.

**STOP — read-only strategy delivered. Registration (CSV ≤500/batch, idempotent) and batch QR-label
printing are already implemented; authentication + certification (QR mint) are per-item human steps and
the true throughput constraint; the Shopify catalog must NOT be imported as items. Smallest safe
automation: optional variant-linking at CSV-import time (additive; no auth/cert/QR change), with a
certification worklist as a secondary option. No code/DB/Shopify/import/cert/QR change made. Secure-claim
RC `4bd88d2` remains deployment-blocked (unrelated). Phase-1 webhook verification COMPLETE.**

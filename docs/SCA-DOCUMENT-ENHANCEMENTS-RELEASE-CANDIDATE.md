# SCA — Document Enhancements: Consolidated Production Release Candidate

**One production-based release candidate consolidates the three approved document enhancements and their
test corrections; it is byte-identical to the green-tested development tree, changes 17 files with no
migration, and both new routes are collector-auth + current-ownership gated.** RELEASE-PREPARED — awaiting
independent review and a separate deployment authorization. No production merge/deploy/DB write/restart;
zero Shopify contact. 2026-10-30. **STOP.**

## SHAs
- **Production (unchanged):** `b0076068c60704036da0ca04735dfd1a1537a070` (clean, `kr-app` healthy).
- **Tested development head:** `4bf93dd` (stack `ba2da33` → `63b5808` → `a923dfd` → `4bf93dd`; isolated
  regression **1536 tests / 7960 assertions / 0 failures / 0 errors / 1 pre-existing skip**).
- **Release candidate:** **`6e36aa74a3af4cd17415c4aad996a53a166dd1bf`** on branch
  **`release/sca-document-enhancements`**, parent = `b007606` (single clean commit).

## Byte-identity & scope
The RC tree is **byte-identical** to the tested head `4bf93dd` (`git diff --quiet 4bf93dd <RC>` = no
difference, verified before and after commit). **Exactly 17 files**; **zero migrations / zero schema
change** (`git diff` shows no file under any `Migrations` directory).

### Changed files
Application (8, all in the `Collector` package):
- `Services/ProvenanceReportService.php`, `Http/Controllers/CollectionReportController.php`,
  `Resources/views/report/provenance.blade.php` — Digital Provenance / Insurance Report PDF.
- `Services/CollectorCertificateService.php`, `Http/Controllers/CollectionCertificateController.php` —
  on-demand Certificate PDF availability.
- `Resources/views/collection/show.blade.php` — item-detail buttons (report + make-certificate-available).
- `Routes/collector-routes.php` — `GET collection/{ref}/report` (throttle 30,1) + `POST
  collection/{ref}/certificate` (throttle 10,1), both in the `collector.auth` group.
- `Services/CollectionService.php` — **additive** owner-authorized `ownedItemIdByRef()` accessor only (no
  change to any existing method's logic).
Tests (9): `ProvenanceReportTest` + `CollectorCertificateAvailabilityTest` (new coverage);
`CertificateDocumentClassificationTest`, `CollectorAuthTest`, `CollectorCollectionTest`,
`ShopifyConnectionTest`, and the three `*ConcurrencyTest` files (test-harness corrections). All test-only.

## Contents confirmed (task item 6)
- **Owner-facing Digital Provenance Report PDF** — present (service + controller + template + route).
- **Insurance/resale disclaimers** — present (report is documentation, not a certified or insured value;
  market-reference advisory/non-appraisal wording).
- **Owner-requested Certificate PDF availability** — present (reuses the existing idempotent
  `CertificatePdfService::ensureForItem`).
- **Dedicated regression coverage + justified test-harness corrections** — present (2 new suites; the 8
  prior failures fixed test-only).

## Safeguards verified
- **[8] Ownership gating:** both new routes are in the `collector.auth` group; the controllers authorize
  via `CollectionService::ownedItemByRef` / `ownedItemIdByRef` (current ownership) and return the shared
  privacy-safe real 404 for a non-owner / previous-owner-after-transfer / unknown ref (asserted by
  `ProvenanceReportTest` and `CollectorCertificateAvailabilityTest`).
- **[9] Existing protections unchanged:** no change to the immutable certificate (`CertificatePdfService`
  reused, not modified), privacy, transfer, or provenance services; the only non-feature app change is the
  additive read-only `ownedItemIdByRef` accessor. The provenance report is on-demand and stored nothing;
  certificate availability is idempotent and preserves the immutable document (same checksum).
- **[10] Commerce code unchanged:** no change to Shopify synchronization, inventory import, or
  order-assignment code (the only Shopify-named file in the diff is `ShopifyConnectionTest`, a test).
- **[11] Excluded:** no R0/R0b/R0c and no Option-C files in the diff.
- **[12] Static checks:** `php -l` clean on the controllers/services/routes; both Blade views compile and
  lint (checked against the production vendor, read-only). No tests were run in this task (already green
  at `4bf93dd`).

## Deployment procedure (code-only; for a SEPARATE authorization — NOT executed here)
No migration, so the standard code-only fast-forward applies (live `app/` is a bind-mount; opcache
`validate_timestamps=On`; no Docker recreate). **The concurrency tests require the app at `/var/www/html`,
which is the production docroot — this is purely a test-run detail and does not affect deployment.**
1. Pre-checks: live tree at `b007606`, clean; `kr-app` healthy; usual pre-deploy backup.
2. On the live tree: `git merge --ff-only 6e36aa7` (fast-forward only — refuse if not a clean FF; never
   pull `origin/main`, never merge secure-claim RC `4bd88d2`).
3. `php artisan view:clear` (the change includes compiled Blade views) and `config:clear` if config cache
   is used.
4. `apachectl -k graceful` (no container recreate; no migration).
5. Post-deploy smoke (read-only, staff/collector): open an owned item's detail; confirm the "Download
   provenance report (PDF)" and "Make my certificate available (PDF)" actions render; do **not** generate a
   real report/certificate unless separately authorized.

## Rollback plan
Code-only, so rollback is a code revert + view-cache clear (a **backward move to the previous snapshot,
not a fast-forward**):
1. On the live tree: `git reset --hard b007606` (or `git checkout b007606 -- app/packages/Sca/Collector
   app/tests/Feature/Sca`) to restore production.
2. `php artisan view:clear` then `apachectl -k graceful`.
3. **No database rollback** — there is no migration, and the features write nothing until a collector
   explicitly requests a report/certificate.

## Safety posture (this task)
No production merge/deploy/DB write/migration/restart; zero live Shopify API requests or store
modifications; no Shopify CLI/credentials; no real report/certificate generation; no real claim/transfer;
no email configuration; no secure-claim RC (`4bd88d2`) deploy; no unrelated development. Production unchanged
at `b007606`; release worktree removed. Secure-claim RC `4bd88d2` remains **DEPLOYMENT-BLOCKED**.

**STOP — consolidated document-enhancements RC `6e36aa7` on `release/sca-document-enhancements` (parent prod
`b007606`), byte-identical to green-tested `4bf93dd`, 17 files, no migration, both new routes collector-auth
+ current-ownership gated, immutable-cert/privacy/transfer/provenance and Shopify/inventory/order code
unchanged, R0/Option-C excluded. Static checks clean; pushed; production unchanged at `b007606`. Awaiting
independent review and a separate controlled-deployment authorization. Secure-claim RC `4bd88d2` remains
DEPLOYMENT-BLOCKED.**

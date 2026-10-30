# SCA — Document Enhancements: Controlled Production Deployment (DONE)

**The three approved document enhancements are DEPLOYED. The live SCA application is now at `6e36aa7`;
all prechecks and post-deployment checks passed, the database is unchanged, and no rollback was needed.**
Code-only fast-forward, 17 files (8 Collector app + 9 test), no migration, no container recreate, zero
Shopify contact. 2026-10-30. **STOP.**

## Result
- **Deployed SHA:** `6e36aa74a3af4cd17415c4aad996a53a166dd1bf` (was `b007606`). Live tree clean.
- **Method:** `git merge --ff-only 6e36aa7` on the live `main` checkout (local ref only — `origin/main`
  never pulled, secure-claim RC `4bd88d2` never merged), then `php artisan view:clear` + `apachectl -k
  graceful`. No migration; no Docker recreate; `kr-app` stayed `Up` (not restarted).
- **Delivered:** owner-facing Digital Provenance / Insurance Report PDF; insurance/resale representation
  disclaimers; owner-requested on-demand Certificate PDF availability; dedicated regression coverage +
  test-harness corrections.

## Prechecks (all passed)
1. Production `b007606`, working tree clean, `kr-app` healthy.
2. RC `6e36aa7`, direct parent `b007606`, fast-forwardable.
3. Exactly 17 files: **8 Collector application** + **9 test**.
4. No migration / schema change / Shopify-application change / R0-R0b-R0c change (only the 8
   Collector-package document-feature files; the sole Shopify-named file is `ShopifyConnectionTest`, a
   test).
5. Migration baseline **batch 30 / 146 migrations**, **0 genuinely-pending**.
6. Recoverable backup verified: `backups/sca-backup-20261030T021703Z.tar.gz.gpg` (2026-10-30 03:29 UTC,
   ~4.58 GB, bundles DB dump + media), **sha256 matches** its sidecar (`eb57f6d2…bc2a22`), decryption key
   `secrets/backup.key` present (mode 600). Rollback point recorded: `b007606`.
7. Mail (`MAIL_MAILER`) and Shopify (`SHOPIFY_SCOPES`) config present and left unchanged.

## Deployment steps executed
8–11. Fast-forwarded the live checkout to `6e36aa7`; `app/.env` MD5 unchanged (`3a8c4b06…b92dc` before
and after), and `vendor/` + `storage/` intact (all git-ignored, untouched by the FF).
12. `php artisan view:clear` → "Compiled views cleared successfully." (the change includes compiled
    Blade views).
13. `apachectl -k graceful` → exit 0; `kr-app` still `Up` (in-place reload, no recreate).
14. No migrations run; no container recreated.

## Post-deployment verification (all passed)
15. Deployed SHA is exactly `6e36aa7`.
16. Health: `/collector/login` → HTTP 200 and `/admin/login` → HTTP 200 (app loopback).
17. Routes registered inside `collector.auth`: `collector.collection.report` (`GET
    collection/{ref}/report`) and `collector.collection.certificate` (`POST collection/{ref}/certificate`),
    both behind `Sca\Collector\Http\Middleware\CollectorAuthenticate`.
18. Current-owner authorization present in the deployed code: `ProvenanceReportService` →
    `ownedItemByRef`; `CollectorCertificateService` → `ownedItemIdByRef`; both controllers return the
    shared privacy-safe `collection.not_found` 404 for a non-owner.
19. The deployed Digital Provenance Record template carries its disclaimers: "not an appraisal" (×2) and
    "not a statement of insured or market value" (×1).
20. The certificate-availability action reuses the existing `CertificatePdfService` (`ensureForItem`) —
    retaining the immutable, idempotent, opaque-handle document safeguards (no new generation logic).
21. **Database unchanged (before == after):** migrations **146** / batch **30**; `sca_eyewear_items`
    **3**; `sca_ownership_events` **5**; `sca_certifications` **4**; `sca_media_assets` **2**;
    `sca_qr_identifiers` **3**; `sca_claims` **2**; `sca_transfer_events` **2**.
22. Logs: **zero** ERROR/CRITICAL and **zero** WARNING entries dated 2026-10-30.
23. No real report/certificate was generated and no customer transaction initiated — verification was by
    route/code inspection and health checks only.

## Rollback
Not needed — all checks passed. Documented procedure if required later (code-only; a **backward move to
the previous snapshot, not a fast-forward**): on the live tree `git reset --hard b007606` (or `git
checkout b007606 -- app/packages/Sca/Collector app/tests/Feature/Sca`), then `php artisan view:clear` +
`apachectl -k graceful`. **No database rollback and no media-record change** — there was no migration and
the features write nothing until a collector explicitly requests a report/certificate.

## Safety posture (honored)
Zero live Shopify API requests / store modifications / CLI / credential changes; no product/variant/
order/inventory/theme/webhook change; no reconciliation or catalog import; no production DB write beyond
independent background operations; no live customer claim or transfer; no email configuration; no
R0/R0b/R0c deploy or merge; no unrelated change. Secure-claim RC `4bd88d2` remains DEPLOYMENT-BLOCKED and
untouched.

**STOP — deployment complete. Live SCA application now at `6e36aa7` (code-only fast-forward from
`b007606`, 17 files, no migration, no recreate). All prechecks and post-deploy checks passed; database
fingerprint unchanged; backup `20261030T021703Z` verified recoverable; no deployment errors. Rollback not
required. Secure-claim RC `4bd88d2` remains DEPLOYMENT-BLOCKED.**

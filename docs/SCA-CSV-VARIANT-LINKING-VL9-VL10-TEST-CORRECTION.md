# SCA — CSV Variant Linking vl9/vl10 Test Correction + Re-Regression

**The two incorrect assertions in `InventoryImportVariantLinkTest` are corrected (test-only); the full
isolated regression is now GREEN across every suite with no application change.** Corrected candidate
`feature/sca-csv-variant-link` = `79b0184` (was `9c1103c`; parent prod `4faf84d`). Isolated disposable
DB, `--internal` network with egress proven blocked, fake Shopify creds, zero live Shopify. 2026-10-30.
**STOP.**

## The correction (test-only — commit `79b0184`)
Exactly one file changed — `app/tests/Feature/Sca/InventoryImportVariantLinkTest.php`. No change to
`InventoryImportService`, the controller, the views, or any business logic (verified: `git status` showed
only the test file). The assertions now reflect the established CSV-import contract:

- **`vl9`** (re-upload the same file):
  - *No acknowledgment* → the row matches the just-created item on `brand + model_name + frame_serial`,
    so `duplicateReason` re-classifies it a duplicate **WARNING**; an unacknowledged WARNING is excluded
    from the importable set, so it is **neither re-created nor counted as `skipped`** (`imported=0,
    skipped=0`). Asserts the second preview row is `WARNING` and the same batch id.
  - *With acknowledgment* → the row is importable, so the durable ledger
    (`UNIQUE(import_id, source_line)`) identifies it as already imported and **skips** it (`imported=0,
    skipped=1`).
  - Both paths retain **exactly one eyewear item, one Shopify variant link, and one link-audit row**.
- **`vl10`** (partial failure then resume): the resume import acknowledges warnings so the
  already-imported sibling (now a duplicate WARNING) is importable and **ledger-skipped** (`skipped=1`)
  while the previously-failed row imports (`imported=1`), `complete=true`; row 1's item keeps exactly one
  link (skipped, never re-created/re-linked). The first half (ineligible-at-confirm rolls back just that
  row, no orphan, one ledger row) is unchanged.

Idempotency and duplicate-prevention remain explicitly asserted in both tests. `php -l` clean.

## Isolation evidence (mandatory safety)
- **Candidate** `79b0184`; its only diff vs `9c1103c` is the single test file.
- **Disposable DB** `sca_domain_test` confirmed absent / 0 connections / no `sca_test` user before
  creation; fresh `sca_test` user granted `USAGE` globally + `ALL` on `sca_domain_test` only. Proven
  locked out of production: `USE sca_krayin` → `ERROR 1044 Access denied`; visible DBs =
  `information_schema, sca_domain_test` only.
- **Identity probe** (all four exclusively `sca_domain_test`): `env(DB_DATABASE)` = `getenv(SCA_TEST_DB)`
  = Laravel connection = `SELECT DATABASE()`.
- **Network**: temporary `sca_testnet` with `internal=true`; from the test-runner `curl https://1.1.1.1`
  → exit 7 (connect refused), `repo.packagist.org` → exit 6 (DNS failed), while `kr-mariadb` was
  reachable. Vendor was built beforehand on the default network; all migrate/seed/tests ran on the
  internal network. Fake Shopify shop/creds; no Shopify CLI, reconciliation, catalog import, or webhook
  replay; zero live Shopify requests.

## Suites and results — ALL GREEN
| Suite(s) | Tests | Assertions | Result |
|---|---:|---:|---|
| **InventoryImportVariantLinkTest** (corrected) | 15 | 81 | **OK** (incl. `vl9`, `vl10`) |
| InventoryImportTest + ShopifyProductLinkTest + ShopifyProductLinkRouteTest + EyewearShopifyIntakeTest + ShopifyLinkVisibilityTest | 60 | 268 | **OK** |
| ProvenanceDomainTest + CertificationWorkflowTest + QrArtifactTest + QrLabelsBatchTest + ShopifyOrderItemAssignmentTest | 98 | 302 | **OK** |
| **Total** | **173** | **651** | **0 failures / 0 errors / 0 warnings / 0 skips** |

`QrArtifactTest` (which carries a known `rg2` QR-decode flake) passed cleanly this run.

## Cleanup and production verification
- Dropped `sca_domain_test` and `sca_test` (verified absent). Disconnected `kr-mariadb` from `sca_testnet`
  and removed the network (verified gone; `kr-mariadb` back to `sca_internal` only). Removed the isolated
  worktree (verified). Shredded the test password; removed the probe script.
- **Production unchanged** (before == after): live tree `4faf84d`, clean; `sca_krayin` migrations
  **146**, max batch **30**; `sca_eyewear_items` **3**, `sca_eyewear_item_shopify_variant` **0**,
  `sca_inventory_imports` **0**; `kr-app` healthy.

## Status / next steps
- Variant-linking candidate is now `79b0184` with a fully green isolated regression and no application
  change since `9c1103c` (test-only). Feature behaviour is unchanged and proven.
- Next, each separately authorized: a code-only release candidate off production, then a controlled
  deployment. No migration is required (catalog + link + audit tables already deployed).
- Secure-claim RC `4bd88d2` remains DEPLOYMENT-BLOCKED and untouched. No email / no Option C.

**STOP — vl9/vl10 corrected (test-only, commit `79b0184`); full isolated regression GREEN (173 tests /
651 assertions / 0 failures); application logic unchanged; disposable DB/user/network/worktree removed;
production verified unchanged at `4faf84d`.**

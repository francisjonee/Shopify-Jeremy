# SCA — Shopify Inventory Sync, Phase 1: Final Variant-Snapshot Correction

**One reviewed correction applied on `feat/sca-shopify-inventory-sync`. Non-destructive checks only (php -l + logic smoke); DB tests extended but NOT run (separate authorization required). No production/merge/deploy/live-Shopify/OAuth/webhook-registration. All other Phase 1 behavior preserved.** 2026-10-27. **STOP for independent review.**

## Updated SHA & changed files

- Branch `feat/sca-shopify-inventory-sync`: `5f53bec` → **`e96700b9a369ac259cd8a14c1162622fb16e6898`** (pushed `origin`). Worktree; live tree `main 6ebe968`, clean.
- `app/packages/Sca/Shopify/src/Services/ProductCatalogService.php` (`syncVariants`), `app/tests/Feature/Sca/ShopifyProductCatalogSyncTest.php`.

## The correction

Previously, removed-variant archival ran when `trustedSnapshot && count($seen) > 0` — which still archived "missing" variants even if the incoming array mixed **valid and malformed** entries. Now archival requires the **entire** snapshot to be complete and valid:

- A new `snapshotComplete` flag is seeded from `trustedSnapshot` (present array). Inside the loop, **any** of these flips it false and **disables removed-variant archival for that event**: a non-array entry, a missing/invalid variant id, or a **duplicate** variant id.
- Individually valid variants are **still upserted** (fail-closed per-variant freshness) regardless — only the archival of absent variants is suppressed when the snapshot is uncertain.
- The archive step is gated on `snapshotComplete && count($seen) > 0`, so the existing missing/null/malformed/empty-collection protection remains intact (an untrusted or empty collection never archives).
- A fully valid, complete snapshot **still** archives a genuinely removed variant (regression preserved).
- Added a `duplicate` counter to the per-variant outcome summary.

Mapping to the required changes: (1) archive only on a complete+valid snapshot ✅; (2) any malformed/missing-id entry disables archival ✅; (3) valid variants still update ✅; (4) tests for partially-malformed + duplicate ids ✅; (5) missing/empty/null protection intact ✅; (6) all other behavior preserved ✅.

## Tests (DB — run under separate authorization)

Added to `ShopifyProductCatalogSyncTest`:
- `partially_malformed_snapshot_does_not_archive_missing_variants` — valid 901 updates, malformed (no-id) entry present, absent 902 stays **active**; `rejected=1`, `archived=0`.
- `non_array_variant_entry_disables_archival` — a scalar entry disables archival; 902 stays active.
- `duplicate_variant_id_disables_archival_and_is_safe` — 901 listed twice + 902 omitted → `duplicate≥1`, `archived=0`, 902 active, one row for 901.
- `fully_valid_snapshot_still_archives_removed_variant` — regression: clean complete snapshot still archives the removed 902.
- (retained) missing/null/malformed/empty-collection protection, reversible delete, revive, reconciliation confirm, fail-closed timestamps, duplicate-row prevention, variant-qty>1, webhook replay, bad signature, zero-provenance assertion.

## Non-destructive evidence

- `php -l` (via `kr-app`): clean on both changed files.
- Snapshot-completeness logic smoke (no DB/vendor): clean→archive; missing-id→block; non-array→block; duplicate→block; valid-still-seen; empty→no-archive; untrusted→no-archive; duplicate-counted — **8/8 pass**.
- DB feature tests **NOT executed** (create tables/rows; need dev vendor + database).

## Remaining activation (unchanged; owner-authorized)

Run the DB tests on an isolated uniquely-created disposable DB (separate auth); add `read_products` + merchant OAuth re-consent; register `products/*` webhooks; deploy (code + 2 additive migrations) via minimal-deploy, then initial import, then optionally schedule reconciliation.

**STOP — correction delivered (`e96700b`), non-destructive checks pass, DB tests written but not run. Awaiting independent review and separate authorization before any database-changing test.**

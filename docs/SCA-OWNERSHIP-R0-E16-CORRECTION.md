# SCA — Ownership R0: ExternalClaimTest E16 Correction

**Authorized test-only correction on the R0 branch `feat/sca-ownership-r0-retire-public-claim`.** The sole incompatibility from the R0 isolated DB-test (`ExternalClaimTest::e16`, which expected a public QR-token claim to succeed) is now updated to the retired-public-claim contract. Test-only; no production code, migration, route, permission, or other test changed. `php -l` clean. DB tests NOT run (separate disposable-DB authorization). 2026-10-28. **STOP.**

## SHA & file
- Branch `feat/sca-ownership-r0-retire-public-claim`: **`ce74229` → `bf774905dd3997abc4efcd5044b16d7db0d6272d`** (pushed `origin`).
- **1 file:** `app/tests/Feature/Sca/ExternalClaimTest.php` (only the e16 method).

## Change
- **Renamed** `e16_shopify_claim_path_is_unchanged` → `e16_public_qr_token_claim_is_retired_even_with_eligible_sale_link`.
- **Setup retained exactly:** certified `sce_presale` item + active QR + eligible Shopify sale link + an authenticated collector.
- **Assertions now (R0 contract):** `ClaimWorkflow::claim()` throws `ClaimRejection::PUBLIC_CLAIM_RETIRED`; **0** `sca_ownership_events` and **0** `sca_claims` for the item; item remains unclaimed (`ownerId` null); the eligible `sca_shopify_sale_links` row stays `eligible` (unconsumed).
- **No private grant substituted** in this test — private-grant claiming is covered by the e-series above (req 6).

## Verification
- `php -l` clean on `ExternalClaimTest.php`.
- Only `ExternalClaimTest.php` changed (git status). No production code/migration/route/permission or other test touched.
- The DB re-run of this suite requires separate disposable-DB authorization and was NOT performed; with this change the suite's expected result is the full `ExternalClaimTest` passing (the previous 1 error resolved).

**STOP — e16 corrected (`bf77490`). R0 remains UNMERGED and NOT deployed. Release dependency stands: do not deploy R0 without approved R0b (private `sce_presale` grant + fulfillment-release); `external_intake` grant claiming is unaffected. Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification.**

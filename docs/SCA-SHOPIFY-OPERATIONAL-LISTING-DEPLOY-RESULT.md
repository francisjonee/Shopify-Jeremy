# Shopify Operational Listing SOP — merge + governed deploy result — **CLOSED**

**Date:** 2026-10-06 · **Status: ✅ DONE — merged `--no-ff` + deployed. Post-deployment verification PASS. Shopify untouched.** Authorized after ChatGPT PASS/APPROVED of candidate `e81d7ef` (gov evidence `6ce6999`).

## SHAs
- **Base / deployed-from:** `0f86b4af90134de6c60664e16aad440a1d111204` (corrects the implementation-evidence diff-line typo "0ca…" → the actual base `0f86b4a`→`e81d7ef`; the audited candidate was not amended).
- **Audited candidate head:** `e81d7ef934ab05dd0e34f771e51863bbcfa23c2a` (unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `1b029fd981388da76b66d50c7a851f3254aa1e5d`** (`--no-ff` merge of `feat/sca-shopify-listing-ref-copy`)

## Pre-merge gates (fail-closed) — all PASS
candidate head `e81d7ef` **unchanged**; `origin/main` == merge-base == `0f86b4a`; 1 commit ahead; change set = exactly `eyewear/show.blade.php` + `ShopifyListingRefCopyTest.php`; tree clean.

## Deploy (`scripts/deploy-preview.sh`)
`git reset --hard origin/main` → `1b029fd`. **First run aborted at the mandatory test gate on a known timing flake** — `QrReissueTest::rg8` compared the full projection row before/after a reissue and `rebuilt_at` differed by one second (`20:57:48`→`20:57:49`) as the reissue crossed a second boundary (854/855 passed; unrelated to this view-only change). Because `set -e` aborts the gate **before** migrate/build/recreate, production was untouched during the abort. **Re-ran the governed deploy unchanged → gate 855 passed / 4600 assertions**, `Nothing to migrate` (migrations **120**), memory-capped image rebuild + `docker compose up -d` (sca project only; co-tenant & 80/443 untouched), re-install `--no-dev` (dev pruned), `config:clear` + `route:clear`, `kr-app`/`kr-mariadb` healthy, `GET /admin/login → 200`, `Deployed main @ 1b029fd`.

## Post-deployment verification — all PASS
| Check | Result |
|---|---|
| deployed SHA == merge SHA | `DEPLOYED_HEAD = 1b029fd981388da76b66d50c7a851f3254aa1e5d` |
| migrations | **120** (Nothing to migrate) |
| provenance fingerprint | **`DEPLOYED_FP = 62b2e42fe409b4ec91f3381b35da819e`** (unchanged) |
| authorized item detail → 200 | `ShopifyListingRefCopyTest::sl1` PASS on merged code |
| staff without `sca.eyewear.view` → 403 | `sl3` PASS; live non-staff `/admin/sca/eyewear/1` → **403** |
| unauthenticated item detail → login behavior | `sl3` PASS (redirect to `admin.session.create`) |
| SCA public reference still visibly rendered | deployed `show.blade.php` renders `public_ref` (span + value) |
| Copy control present beside that value | `sca-copy-ref` present in deployed view (4 matches) |
| copy target == item's exact `public_ref` | `sl1`/`sl2` PASS (`data-sca-ref` == `public_ref`) |
| not internal item id / QR public_token | `sl2` PASS (shape `SCA-<12hex>`, ≠ numeric id, ≠ QR token) |
| no new server request/mutation from the helper | client-side only (Clipboard API / selection fallback); no route/controller added |
| rendering zero provenance mutation | `sl4` PASS; `DEPLOYED_FP` unchanged |
| ownership-correction / navigation controls intact | item-detail "Correct ownership…" + ownership-history links unchanged; full `tests/Feature/Sca` green |
| public passport valid/bogus | `/p/{valid}` **200**, `/p/{bogus}` **404** |
| `/collector` | **302** |
| unsigned Shopify webhook fail-closed | **401** |
| `/storage` blocked | **404** |
| admin/staff edge protection | `/admin/sca/eyewear/1` → **403** (non-staff) |
| smsrocket co-tenant health | **302** |

## Regression totals
**855 passed / 4600 assertions, exit 0** (on the re-run). Migrations **120**. Provenance FP **`62b2e42fe409b4ec91f3381b35da819e`**.

## Shopify untouched (confirmed)
No Shopify API call or mutation was made during this deployment. No scope/app/OAuth/webhook change. The `custom.sca_item_ref` **metafield remains a documented recommended storefront convention pending validation against Jeremy's actual theme/store** — it is **not** part of the SCA receiver contract (the receiver reads only the line-item property `sca_item_ref`). No Bogus-Gateway transaction and no real-inventory sale were performed.

---

## Shopify Operational Listing SOP — CLOSED

Staff have (1) the committed operator SOP `docs/SOP-SHOPIFY-OPERATIONAL-LISTING.md` stating the permanent contract (line-item property `sca_item_ref` = `public_ref`, shape `SCA-XXXXXXXXXXXX`, qty 1, copy-never-type) and the end-to-end flow + pre-publish verification + fail-closed behavior, and (2) a deployed one-click **Copy** affordance for the exact `public_ref` on item detail. The receiver was already production-proven (Phase 4). **The future Shopify theme/metafield setup and the first real-inventory sale are operator actions — not unfinished SCA implementation — and do not create a second SOP slice.**

**Outcome: DONE (merged `--no-ff` + deployed, `1b029fd`); production verified byte-identical except the additive, read-only copy affordance. Shopify Operational Listing SOP is CLOSED.** See `docs/SCA-SHOPIFY-OPERATIONAL-LISTING-SOP-DISCOVERY.md`, `docs/SOP-SHOPIFY-OPERATIONAL-LISTING.md`, `docs/SCA-SHOPIFY-OPERATIONAL-LISTING-IMPLEMENTATION.md`.

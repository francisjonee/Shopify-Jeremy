# SCA Inventory Onboarding / Bulk CSV — merge + governed deploy result — **CLOSED**

**Date:** 2026-10-07 · **Status: ✅ DONE — merged `--no-ff` + deployed (2 additive migrations applied; prod 120→122). Post-deployment verification PASS. Shopify untouched; no real inventory imported.** Authorized after ChatGPT PASS/APPROVED of candidate `a6300895` (gov remediation `c64655b`).

## SHAs
- **Base / deployed-from:** `1b029fd981388da76b66d50c7a851f3254aa1e5d`
- **Audited candidate head:** `a63008950b644c733a950cde63661e58aa435c35` (unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `976088944de0fd2883f12a0686fafaa708ce8b9e`** (`--no-ff` merge of `feat/sca-inventory-onboarding-bulk-csv`, 2 commits: impl + R1/R2/R3 remediation)

## Pre-merge gates (fail-closed) — all PASS
head `a6300895` unchanged; `origin/main` == merge-base == `1b029fd`; exactly the 2 additive migrations in the diff; tree clean.

## Deploy (`scripts/deploy-preview.sh`)
`git reset --hard origin/main` → `9760889`; mandatory SCA gate on `sca_domain_test` **871 passed / 4717 assertions** (incl. `InventoryImportTest` 16); `migrate --force` → **both migrations ran** (`create_sca_inventory_imports`, `create_sca_inventory_import_rows`) → **migrations 122**; memory-capped image rebuild + `docker compose up -d` (sca project only; co-tenant + 80/443 untouched); `--no-dev` prune; `config:clear`+`route:clear`; `kr-app`/`kr-mariadb` healthy; `GET /admin/login → 200`; `Deployed main @ 9760889`.

## Post-deployment verification — all PASS
| Check | Result |
|---|---|
| deployed SHA == merge SHA | `DEPLOYED_HEAD = 976088944de0fd2883f12a0686fafaa708ce8b9e` |
| migrations | **122** (both ledger migrations applied) |
| provenance FP | provenance data **byte-identical** — recomputed with migration-count held at 120 = **`62b2e42fe409b4ec91f3381b35da819e`** (items 3/qr 3/certs 4/auth 4/ownership 5/status 7/gallery 3/projection unchanged). The composite incl. the migration-count field is now `6c0768bd…` **solely** because of the +2 additive migrations — no provenance mutation. |
| both ledger tables exist | `sca_inventory_imports` YES, `sca_inventory_import_rows` YES |
| ledger append-only triggers retained | `trg_sca_inventory_imports_no_update/no_delete` + `trg_sca_inventory_import_rows_no_update/no_delete` all present |
| Import CSV form (authorized) | route live; non-staff → **403** (edge `@admin` + `sca.eyewear.create`) — functionally green via deploy-gate `InventoryImportTest::bi11` |
| unauthenticated → login | `bi11` PASS (redirect to `admin.session.create`) |
| staff lacking `sca.eyewear.create` → 403 | `bi11` PASS; live non-staff form/preview → **403** |
| preview zero provenance/inventory mutation | `bi1` PASS |
| duplicate normalized headers block confirmation | `bi13` PASS |
| unsupported headers block confirmation | `bi2` PASS |
| 500-row cap blocks confirmation | `bi3` PASS |
| malformed extra/missing-width rows INVALID, not imported | `bi14`/`bi15` PASS |
| warning acknowledgement behavior | `bi6` PASS |
| valid CSV → INTAKE-only + system public_ref | `bi4` PASS (`SCA-<12hex>`, one INTAKE/normal projection each) |
| no auth/cert/QR/ownership/sale/service/media artifacts from import | `bi4` PASS (all zero) |
| exact re-upload idempotent | `bi7` PASS |
| partial batch resumes only missing rows | `bi8` PASS |
| per-row + batch ledger immutability / unique | `bi9`/`bi10`/`bi16` PASS |
| HTTP double-confirm single-use | `bi12` PASS |
| prod ledger rows after deploy | `sca_inventory_imports` 0 / `sca_inventory_import_rows` 0 (no inventory imported during verification) |
| public passport valid/bogus | `/p/{valid}` **200**, `/p/{bogus}` **404** |
| `/collector` | **302** |
| unsigned Shopify webhook fail-closed | **401** |
| `/storage` blocked | **404** |
| admin/staff edge protection | import form / preview / registry index → **403** non-staff |
| smsrocket co-tenant | **302** |
| Shopify untouched | no Shopify API/scope/app/OAuth/webhook change; no real inventory imported |

## Regression totals
**871 passed / 4717 assertions, exit 0** (on the deploy gate). Migrations **122**. Provenance data FP (at m=120) **`62b2e42fe409b4ec91f3381b35da819e`**.

---

## SCA Inventory Onboarding / Bulk CSV — CLOSED

Staff can onboard real inventory at scale via **Registry → Import CSV → preview → confirm**: each valid (and acknowledged-warning) row becomes a new **INTAKE** SCA item through the canonical `ItemService::create` (system-generated `public_ref`, one INTAKE/normal projection, no downstream lifecycle artifacts). Idempotent + resumable + auditable via the two append-only ledger tables; duplicate/unsupported headers and malformed-width rows are rejected; the 500-row cap, `sca.eyewear.create` ACL, and no-overwrite/insert-only guarantees hold. **Bulk onboarding to INTAKE is complete; downstream authenticate/certify/QR remain the normal per-item staff flow — no follow-on slice.** Importing real inventory is an operator action after this closure; only governed test data was used in verification.

**Outcome: DONE (merged `--no-ff` + deployed, `9760889`); provenance data verified byte-identical; prod migrations 120→122 (additive ledger tables only). Inventory Onboarding / Bulk CSV is CLOSED.** See `docs/SCA-INVENTORY-ONBOARDING-BULK-CSV-{DISCOVERY,IMPLEMENTATION}.md`, `docs/SOP-INVENTORY-ONBOARDING-CSV.md`.

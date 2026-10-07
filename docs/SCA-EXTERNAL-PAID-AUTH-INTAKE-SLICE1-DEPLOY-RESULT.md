# SCA External Paid Authentication Intake — Slice 1 (Submission Domain Foundation) — merge + governed deploy result

**Date:** 2026-10-07 · **Status: ✅ DONE — merged `--no-ff` + deployed (2 additive migrations applied; prod 122→124). Post-deployment verification PASS. No Shopify/MAIL/DNS/payment/Caddy/co-tenant change.** Authorized after ChatGPT re-audit PASS of head `c06c45a91e4a93ae6dc33fdb7b50c31e19959536` (gov evidence `06c3fbc66ed0893562cfd3e6bc440cf46f9d2dc8`).

> **Slice 1 only. The overall External Paid Authentication Intake capability is NOT closed** — Slices 2–6 (staff receive/custody bridge, collector submission UX, payment, result/ownership wiring, exceptions/returns) remain, per `docs/SCA-EXTERNAL-PAID-AUTHENTICATION-INTAKE-DISCOVERY.md`. **Slice 2 not started.**

## SHAs
- **Base / deployed-from:** `0815ea0808b6ceac2bb82d88c891fdedc2b97bda`
- **Audited candidate head:** `c06c45a91e4a93ae6dc33fdb7b50c31e19959536` (unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `65880542218d6f0cde552aa3e2cb01c788fba068`** (`--no-ff` merge of `feat/sca-external-paid-auth-slice1`, impl + R1 remediation)

## Pre-merge gates (fail-closed) — all PASS
candidate head `c06c45a9` unchanged; `origin/main` == merge-base == `0815ea08`; tree clean. Merge diff = exactly the 6 expected files (2 migrations + model + exception + service + test), the 2 additive migrations only.

## Deploy (`scripts/deploy-preview.sh`)
`git reset --hard origin/main` → `6588054`; mandatory SCA gate on `sca_domain_test` (**913 passed / 4857 assertions**); `migrate --force` → **both migrations ran** (`create_sca_authentication_submissions`, `create_sca_submission_status_events`) → **migrations 124**; memory-capped image rebuild + `docker compose up -d` (sca project only; co-tenant + 80/443 untouched); `--no-dev` prune; `config:clear`+`route:clear`; `kr-app`/`kr-mariadb` healthy; `GET /admin/login → 200`; `Deployed main @ 6588054`.

**Deploy-gate note:** the first run aborted on the known random-token QR-decode flake `QrArtifactTest::rg2` (`DECODE_FAILED: failed to read version`) — 912 passed + that 1 flake. `set -e` aborts the gate **before** migrate/build, so production was untouched by the aborted run. Re-run unchanged → gate green, deploy completed.

## Migrations before/after
**Before: 122 · After: 124** (exactly the 2 approved additive, new-table migrations).

## Post-deployment verification — all PASS
| Check | Result |
|---|---|
| deployed HEAD == merge SHA | `65880542218d6f0cde552aa3e2cb01c788fba068` |
| regression (deploy gate) | **913 passed / 4857 assertions** (892 baseline + 21 SubmissionDomainTest) |
| migrations | **124** (122→124) |
| new tables exist | `sca_authentication_submissions` **PRESENT**, `sca_submission_status_events` **PRESENT** |
| triggers exist | `trg_sca_auth_submissions_bu` (BEFORE UPDATE), `trg_sca_submission_status_events_no_update`, `trg_sca_submission_status_events_no_delete` |
| CHECK constraints exist | `chk_submission_status`, `chk_sse_to_status` |
| **Slice-1 bridge locked** | on the **production schema**, a raw ordinary `UPDATE … SET eyewear_item_id = <item>` (NULL→value) is **rejected (SQLSTATE 45000)** — verified inside a rolled-back transaction so no row persisted; submission table remained **0 rows** afterward |
| new tables empty in prod | `sca_authentication_submissions` **0 rows**, `sca_submission_status_events` **0 rows** (no real submission created for the test) |
| provenance counts unchanged | items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3 (pre-existing claims 2 / sale_links 1) — identical to the pre-Slice-1 baseline |
| MAIL_MAILER | **`log`** (runtime `config('mail.default')=log`); `MAIL_PASSWORD`/`POSTMARK_TOKEN` UNSET |
| APP_URL | `https://verify.secondchanceauthenticators.com` |
| Shopify untouched | scopes still `read_orders` (read-only); no app/scope/OAuth/webhook change; prod sale-links/receipts unchanged |
| `/p/{bogus}` · `/collector` | **404** · **302** |
| `/collector/forgot-password` | **200** (collector forgot-password operational) |
| `/storage/..` · unsigned webhook | **404** · **401** |
| loopback `:8080` external | **000** (Phase-B preserved) |
| admin edge | `/admin/sca/dashboard` → **403** (edge staff-IP gate externally) |
| smsrocket co-tenant | **302** |

## Provenance counts / fingerprint analysis (migration-count vs data mutation)
The canonical provenance-FP formula folds the migration count as field `"m"`, so an additive migration (122→124) necessarily changes the composite fingerprint **without any provenance-data change**. Distinguishing the two:
- **Provenance DATA (m held at the prior count):** byte-identical — the item/qr/cert/auth/ownership/status/gallery rows and counts are exactly the long-standing baseline (items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3). No provenance row was inserted, updated, or deleted.
- **Composite (including `"m"`):** moved **solely** because migration count 122→124 — i.e. **schema-version movement**, two new EMPTY operational tables (`sca_authentication_submissions` 0 rows, `sca_submission_status_events` 0 rows), not a data mutation.
- The new submission tables are **not** provenance and are **not** folded by `ProjectionService`.

## Scope / boundary confirmation
No Shopify change/scope/webhook; no SMTP/MAIL change (`log`); no DNS; no payment; no Caddy; no co-tenant change; only the 2 approved additive migrations applied. `eyewear_item_id` first-bind remains reserved for Slice 2 (UPDATE-locked + model-guarded + service-incapable). No real submission created in production.

**Outcome: DONE (merged `--no-ff` + deployed, `6588054`); provenance DATA byte-identical; prod migrations 122→124 (two empty operational tables); Slice-1 bridge lock verified on the prod schema; new tables empty.** External Paid Authentication Intake **Slice 1 is deployed; the overall capability remains OPEN (Slices 2–6 pending).** See `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE1-IMPLEMENTATION.md`, `docs/SCA-EXTERNAL-PAID-AUTHENTICATION-INTAKE-DISCOVERY.md`.

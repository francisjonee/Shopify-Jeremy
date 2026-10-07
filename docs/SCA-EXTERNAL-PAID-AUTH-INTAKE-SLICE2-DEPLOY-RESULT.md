# SCA External Paid Authentication Intake — Slice 2 (Staff Worklist + Custody Bridge) — merge + governed deploy result

**Date:** 2026-10-07 · **Status: ✅ DONE — merged `--no-ff` + deployed (1 trigger-only migration; prod 124→125). Post-deployment verification PASS. No Shopify/MAIL/DNS/payment/Stripe/shipping/co-tenant change.** Authorized after ChatGPT candidate PASS of head `f4c8574e483db2816da75e408fdc649535c67378` (gov evidence `ed0f5d33133964fe02fcda683555d55c1f7bb412`).

> **Slice 2 only. The overall External Paid Authentication Intake capability is NOT closed** — Slices 3–6 (collector submission UX, payment, result/ownership wiring, exceptions/returns) remain. **Slice 3 not started.**

## SHAs
- **Base / deployed-from:** `65880542218d6f0cde552aa3e2cb01c788fba068`
- **Audited candidate head:** `f4c8574e483db2816da75e408fdc649535c67378` (unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `c72530e59af0eb20bfc24df0d97e6dc0feadc990`**

## Pre-merge gates (fail-closed) — all PASS
candidate head `f4c8574e` unchanged; `origin/main` == merge-base == `65880542`; tree clean. Merge diff = exactly 1 trigger-only migration + the Slice-2 service/controller/request/views/acl/menu/routes/tests.

## Migrations before/after
**Before: 124 · After: 125** — exactly one trigger-only migration (`…000003_relax_submission_bridge_for_custody_bind`, no new table/column; replaces the bridge trigger).

## Deploy (`scripts/deploy-preview.sh`)
`git reset --hard origin/main` → `c72530e`; SCA gate on `sca_domain_test` **925 passed / 4928 assertions**; `migrate --force` → the one trigger migration ran → **migrations 125**; memory-capped rebuild + `docker compose up -d` (sca project only); `--no-dev` prune; caches cleared; `kr-app`/`kr-mariadb` healthy; `GET /admin/login → 200`; `Deployed main @ c72530e`. (No deploy-gate QR flake this run; fail-closed rerun policy was ready but not needed.)

## Post-deployment verification — all PASS
| Check | Result |
|---|---|
| deployed HEAD == merge SHA | `c72530e59af0eb20bfc24df0d97e6dc0feadc990` |
| migration count | **125** (relax migration PRESENT) |
| regression (deploy gate) | **925 passed / 4928 assertions** (913 Slice-1 baseline + 12) |
| `trg_sca_auth_submissions_bu` — NULL→value | **PERMITTED** (controlled first-bind) — verified on prod schema in a rolled-back txn |
| — bound value → different value | **BLOCKED (45000)** |
| — bound value → NULL | **BLOCKED (45000)** |
| — collector_account_id change | **BLOCKED (45000)** (immutable) |
| — public_ref change | **BLOCKED (45000)** (immutable) |
| UNIQUE(eyewear_item_id) one-item-one-submission | **ENFORCED (23000)** |
| model guard (mass-assignment cannot bind) | retained — covered by deploy-gate `SubmissionDomainTest::s3b`/`s14` |
| staff ACL keys present | `sca.eyewear.submission` **OK**, `sca.eyewear.submission.accept` **OK** |
| routes present | `admin.sca.submission.{index,show,accept.confirm,accept}` all **OK** |
| menu present | `sca-submissions` **OK** |
| submission tables empty in prod | `sca_authentication_submissions` **0 rows**, `sca_submission_status_events` **0 rows** — no production custody test manufactured |
| provenance DATA unchanged | items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3 (pre-existing claims 2 / sale_links 1) — byte-identical to the Slice-1 baseline |
| MAIL_MAILER | **`log`**; `MAIL_PASSWORD`/`POSTMARK_TOKEN` UNSET |
| APP_URL | `https://verify.secondchanceauthenticators.com` |
| Shopify untouched | `SHOPIFY_API_SECRET` UNSET; no scope/app/OAuth/webhook change; sale-links/receipts unchanged |
| `/p/{bogus}` · `/collector` · `/collector/forgot-password` | **404 · 302 · 200** |
| `/storage/..` · unsigned webhook | **404 · 401** |
| `/admin/sca/submission` · `/admin/sca/dashboard` | **403 · 403** (edge staff-IP gate externally) |
| loopback `:8080` external | **000** (Phase-B preserved) |
| smsrocket co-tenant | **302** |

## Provenance fingerprint / count analysis (migration-count vs data mutation)
The canonical provenance-FP folds migration count as `"m"`, so 124→125 necessarily moves the composite fingerprint **without any provenance-data change**:
- **DATA (m held at prior count):** byte-identical — the item/qr/cert/auth/ownership/status/gallery rows and counts are exactly the Slice-1 baseline (items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3). No provenance row inserted/updated/deleted.
- **Composite (incl. `"m"`):** moved **solely** because migration count 124→125 — a single **trigger-only** migration (no new table, no new row). Schema-version movement, not data mutation.
- The new submission tables remain empty (0/0) and are not folded by `ProjectionService`.

## Boundary confirmation
No Shopify/MAIL/DNS/payment/Stripe/shipping change; no co-tenant change; exactly one trigger-only migration applied; no collector/public route added; no auth/cert/QR/ownership/grant/claim change. No real production submission or permanent item created — verification used schema/route/ACL/runtime inspection + a rolled-back trigger probe + the green disposable test suite.

**Outcome: DONE (merged `--no-ff` + deployed, `c72530e`); provenance DATA byte-identical; prod migrations 124→125 (one trigger-only migration); Slice-2 bridge invariant verified on the prod schema; submission tables empty.** External Paid Authentication Intake **Slice 2 is deployed; the overall capability remains OPEN (Slices 3–6 pending).** See `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE2-IMPLEMENTATION.md`, `docs/SCA-EXTERNAL-PAID-AUTHENTICATION-INTAKE-DISCOVERY.md`.

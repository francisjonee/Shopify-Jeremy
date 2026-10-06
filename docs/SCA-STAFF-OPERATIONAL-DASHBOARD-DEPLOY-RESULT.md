# SCA Staff Operational Dashboard / Worklists — merge + governed deploy result — **CLOSED**

**Date:** 2026-10-06 · **Status: ✅ DONE — merged `--no-ff` + deployed. Post-deployment verification PASS.** Authorized after ChatGPT PASS/APPROVED of candidate `87473845` (gov evidence `e45407d`).

## SHAs
- **Base / deployed-from:** `703fbde9884ddeb9219c0cf54d34f5fe9e3f48a8`
- **Audited candidate head:** `87473845c14e35aa05ab8970046443e55ea807b5` (unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `0f86b4af90134de6c60664e16aad440a1d111204`** (`--no-ff` merge of `feat/sca-staff-dashboard`)

## Pre-merge gates (fail-closed) — all PASS
candidate head `87473845` **unchanged**; `origin/main` == merge-base == `703fbde`; 1 commit ahead; change set = exactly `DashboardController.php` + `dashboard/index.blade.php` + `StaffDashboardTest.php` + `admin-routes.php` + `menu.php`; `EyewearItemController` untouched; tree clean.

## Deploy (`scripts/deploy-preview.sh`, deploys only `origin/main`)
`git reset --hard origin/main` → `0f86b4a`; mandatory SCA gate on `sca_domain_test` **851 passed / 4585 assertions** (incl. `StaffDashboardTest`); `migrate --force` → **Nothing to migrate** (migrations **120**); memory-capped image rebuild + `docker compose up -d` (sca project only; co-tenant & 80/443 untouched); re-install `--no-dev` (dev pruned); `config:clear` + `route:clear`; `kr-app`/`kr-mariadb` healthy; `GET /admin/login → 200`; `Deployed main @ 0f86b4a`.

## Post-deployment verification — all PASS
| Check | Result |
|---|---|
| deployed SHA == merge SHA | `DEPLOYED_HEAD = 0f86b4af90134de6c60664e16aad440a1d111204` |
| migrations | **120** (Nothing to migrate) |
| provenance fingerprint | **`DEPLOYED_FP = 62b2e42fe409b4ec91f3381b35da819e`** (unchanged) |
| Dashboard route live for authorized staff | `admin.sca.dashboard.index` registered (route:list = 1); `StaffDashboardTest::d1` PASS on merged code |
| staff with `sca.eyewear` → 200 | `d1` PASS |
| staff without `sca.eyewear` → 403 | `d3` PASS; live non-staff `/admin/sca/dashboard` → **403** |
| unauthenticated → login behavior | `d2` PASS (redirect to `admin.session.create`) |
| Dashboard nav entry usable via admin navigation | `menu.php` entry deployed (merged into `menu.admin`, mirrors Registry entry) |
| Awaiting-authentication count + drill-down | `d4` + `d12` PASS (`?lifecycle=INTAKE`) |
| Authentication-failed count + drill-down | `d5` + `d12` PASS (`?lifecycle=AUTH_FAILED`) |
| Authenticated-not-certified count + drill-down | `d6` + `d12` PASS (`?lifecycle=AUTHENTICATED`) |
| Certified-unclaimed count + drill-down | `d7` + `d12` PASS (`?lifecycle=CERTIFIED&owned=unowned`) |
| adverse count == `StatusService::ADVERSE_STATUSES` | `d9` PASS |
| adverse manage action permission-aware for `sca.eyewear.status` | `d10` PASS |
| certified-without-active-QR exception count | `d11` PASS (counts a QR-revoked certified item; excludes a normal one) |
| exception UI states destination is the broader all-certified list (not a precise filter) | present in deployed view (`exc-note`) |
| no dead-enum lifecycle tiles | `d13` PASS (no `SOLD_AWAITING_CLAIM`/`TRANSFER_PENDING`; no RETIRED/INVALIDATED lifecycle drill-downs) |
| total/registered are orientation only | `d8` + `d14` PASS (registered is not an attention queue; claimed item excluded from certified-unclaimed) |
| dashboard rendering → zero provenance mutation | `d15` PASS; `DEPLOYED_FP` unchanged |
| public passport valid/bogus | `/p/{valid}` **200**, `/p/{bogus}` **404** |
| `/collector` | **302** |
| unsigned Shopify webhook fail-closed | **401** |
| `/storage` blocked | **404** |
| staff/admin edge protection | `/admin/sca/dashboard`, `/admin/sca/eyewear`, `/admin/sca/status` all **403** from non-staff IP |
| smsrocket co-tenant health | **302** |

## Regression totals (merged/deployed code)
**851 passed / 4585 assertions, exit 0** (836 prior + 15 new). Migrations **120**. Provenance FP **`62b2e42fe409b4ec91f3381b35da819e`**.

## Scope delivered
Read-only dashboard: tiles (count + link) for Awaiting authentication / Authentication failed / Authenticated-not-certified / Certified-unclaimed / Needs-attention adverse (→ existing status queue) / certified-no-active-QR exception, plus total/registered orientation. Reuses the `sca_item_current_state` projection, the existing Registry index filters, and `StatusService::ADVERSE_STATUSES`. ACL `sca.eyewear`; adverse link gated on `sca.eyewear.status`. No schema/migration, no lifecycle-semantics change, no new ACL key, `EyewearItemController` untouched, no analytics.

---

## SCA Staff Operational Dashboard / Worklists — CLOSED

Staff now have a single read-only "what needs my attention next?" surface with live counts and one-click drill-downs to the existing Registry filters and adverse queue, covering the real 5-state lifecycle + adverse axis + the certified-no-active-QR exception. **The deferred draft-auth "awaiting finalize" worklist and the precise `qr=missing` Registry filter remain optional future items and do NOT create another dashboard/worklists slice.**

**Outcome: DONE (merged `--no-ff` + deployed, `0f86b4a`); production verified byte-identical except the additive read-only dashboard surface. Staff Operational Dashboard / Worklists is CLOSED.** See `docs/SCA-STAFF-OPERATIONAL-DASHBOARD-DISCOVERY.md`, `docs/SCA-STAFF-OPERATIONAL-DASHBOARD-IMPLEMENTATION.md`.

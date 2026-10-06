# SCA Staff Operational Dashboard / Worklists — implementation (candidate; NOT merged/deployed)

**Date:** 2026-10-06 · **Status: IMPLEMENTED + TESTED + PUSHED on a candidate branch. NOT merged, NOT deployed. Live tree restored to `main`; production byte-identical.** For ChatGPT pre-merge audit. Approved discovery gov `0ec7818`.

A small read-only staff "what needs my attention next?" dashboard. Zero schema; reuses the `sca_item_current_state` projection, the existing Registry index filters (drill-down), and the existing adverse-status queue + `StatusService::ADVERSE_STATUSES`.

## Candidate identity
- **Branch:** `origin/feat/sca-staff-dashboard`
- **Base SHA:** `703fbde9884ddeb9219c0cf54d34f5fe9e3f48a8` (= deployed `main`; merge-base; clean 1-commit, fast-forwardable)
- **Head SHA:** `87473845c14e35aa05ab8970046443e55ea807b5`

## Changed files (3 new + 2 modified; EyewearItemController untouched)
- **NEW** `packages/Sca/Registry/src/Http/Controllers/DashboardController.php` — read-only aggregate counts.
- **NEW** `packages/Sca/Registry/src/Resources/views/dashboard/index.blade.php` — tiles (count + link) + orientation header.
- **NEW** `tests/Feature/Sca/StaffDashboardTest.php` — 15 focused tests.
- **MOD** `packages/Sca/Registry/src/Routes/admin-routes.php` — one route group: `GET admin/sca/dashboard` → `admin.sca.dashboard.index`, middleware `sca.can:sca.eyewear`.
- **MOD** `packages/Sca/Registry/src/Config/menu.php` — one "SCA Dashboard" sidebar entry mirroring the existing Registry entry.

`git diff --name-only 703fbde..87473845` = exactly those five paths; **`EyewearItemController` not touched**; no migration/schema/vendor/composer/Docker/Caddy/public-route/ACL-definition change.

## Dashboard states / count queries implemented (over `sca_item_current_state`)
| Tile | Count query | Drill-down |
|---|---|---|
| Awaiting authentication | `lifecycle_state = INTAKE` | `?lifecycle=INTAKE` |
| Authentication failed | `lifecycle_state = AUTH_FAILED` | `?lifecycle=AUTH_FAILED` |
| Authenticated — not certified | `lifecycle_state = AUTHENTICATED` | `?lifecycle=AUTHENTICATED` |
| Certified — unclaimed | `lifecycle_state = CERTIFIED AND current_owner_collector_id IS NULL` | `?lifecycle=CERTIFIED&owned=unowned` |
| Needs attention (adverse) | `registry_status IN StatusService::ADVERSE_STATUSES` (disputed/lost/stolen/retired/invalidated) | existing `admin.sca.status.queue` |
| Exception: certified, no active QR | `current_certification_id IS NOT NULL AND active_qr_identifier_id IS NULL` | broader `?lifecycle=CERTIFIED` list (UI states this is NOT a precise missing-QR filter) |
| (orientation) Total items | `COUNT(*)` | — |
| (orientation) Registered | `lifecycle_state = REGISTERED` | — (orientation only, not a queue) |

**Dead-enum tokens deliberately NOT surfaced:** `SOLD_AWAITING_CLAIM`, `TRANSFER_PENDING`, `RETIRED`, `INVALIDATED` (never written by the projection → would always be zero). No lifecycle-derivation change was made to populate anything.

## ACL behavior
- Dashboard route gated by the existing **`sca.eyewear`** permission (`sca.can:sca.eyewear`) — **no new ACL key, no broadening.**
- The **adverse** tile's manage-link to `admin.sca.status.queue` is **permission-aware for `sca.eyewear.status`** (`bouncer()->hasPermission`): staff without it still see the adverse *count* but get no manage link.
- The sidebar entry mirrors the proven Registry entry exactly (same key/route/sort/icon shape + identical Krayin menu/ACL behaviour). **Navigation visibility never grants authorization** — the route middleware is the real gate; a non-`sca.eyewear` staffer gets 403. (This reproduces the existing accepted pattern, so the documented toolbar-fallback was not needed.)

## Tests
- **Focused `StaffDashboardTest` — 15/15:** d1 authorized 200; d2 unauth → login redirect; d3 non-`sca.eyewear` → 403; d4 intake count; d5 auth-failed; d6 authenticated; d7 certified-unclaimed; d8 registered orientation-only (and a claimed item is NOT in certified-unclaimed); d9 adverse parity with `StatusService::ADVERSE_STATUSES`; d10 adverse manage-link permission-aware for `sca.eyewear.status`; d11 certified-no-QR counts a QR-revoked certified item and excludes a normal certified one; d12 drill-down URLs reuse existing surfaces; d13 no dead-enum tiles; d14 total orientation; d15 zero provenance mutation.
- **Full governed gate:** `… -e DB_DATABASE=sca_domain_test … php artisan test tests/Feature/Sca` → **851 passed / 4585 assertions**, exit 0 (836 prior + 15 new; the new menu entry regressed no other admin view). No schema change.

## Zero-mutation evidence
`StaffDashboardTest::d15` seeds items (intake/certified/adverse), renders the dashboard, and asserts the projection+events fingerprint (rows + status/qr-lifecycle/ownership/certification counts) is unchanged. The dashboard performs only `COUNT(*)` reads.

## Production-safety verification (post-restore)
`kr-app` bind-mounts the live tree; the change is a new read-only admin surface. After push, the tree was **restored to `main`** and vendor **re-pruned `--no-dev`**. Verified: tree `main` @ `703fbde`; `PROD_FP = 62b2e42fe409b4ec91f3381b35da819e` (unchanged); migrations **120**; the dashboard route/`DashboardController` are **absent** from main; phpunit pruned; `/collector` 302, smsrocket.io 302, Shopify webhook POST → **401** fail-closed. No merge, no deploy, no DB/schema/config/Caddy change.

## Scope boundary honored / NOT done
No schema/migration; no provenance/lifecycle-semantic change; no Shopify/collector/QR/certification/ownership change; no SMTP; no public routes; no Caddy/Docker/infra; no reporting/charts/KPIs/market-value; no new ACL key / no broadening; `EyewearItemController` untouched. The deferred draft-auth "awaiting finalize" list and the `qr=missing` Registry filter were **not** implemented. No merge, no deploy.

## Closure note
On passing audit + deployment verification, governance will state **SCA Staff Operational Dashboard / Worklists — CLOSED**, with no second dashboard/worklists slice afterward.

**Outcome:** implemented + green on a candidate branch, production untouched. STOP for ChatGPT audit. See `docs/SCA-STAFF-OPERATIONAL-DASHBOARD-DISCOVERY.md`.

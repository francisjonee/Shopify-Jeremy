# SCA Staff Navigation / Discoverability — merge + governed deploy result — **CLOSED**

**Date:** 2026-10-06 · **Status: ✅ DONE — merged `--no-ff` + deployed. Post-deployment verification PASS.** Authorized after ChatGPT PASS/APPROVED of candidate `3d35864` (gov evidence `c75864a`).

## SHAs
- **Base / deployed-from:** `30b680f797bdcf0d9bf2e6031c32c4f80c41dfc4`
- **Audited candidate head:** `3d358640dcbbd0f59852110dff0f382e75afa7d8` (unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `703fbde9884ddeb9219c0cf54d34f5fe9e3f48a8`** (`--no-ff` merge of `feat/sca-staff-nav-ownership-correct-link`)

## Pre-merge gates (fail-closed) — all PASS
candidate head `3d35864` **unchanged**; `origin/main` == merge-base == `30b680f` (production baseline); 1 commit ahead; change set = exactly `eyewear/show.blade.php` + `StaffNavOwnershipCorrectionLinkTest.php`; tree clean on `main`.

## Deploy (`scripts/deploy-preview.sh`, deploys only `origin/main`)
`git reset --hard origin/main` → `703fbde`; mandatory SCA gate on `sca_domain_test` **836 passed / 4544 assertions** (incl. `StaffNavOwnershipCorrectionLinkTest`, ownership/correction, staff-registry, passport, QR suites); `migrate --force` → **Nothing to migrate** (migrations **120**); memory-capped image rebuild + `docker compose up -d` (sca project only; co-tenant & 80/443 untouched); re-install `--no-dev --optimize-autoloader` (dev pruned); `config:clear` + `route:clear`; `kr-app`/`kr-mariadb` healthy; `GET /admin/login → 200`; `Deployed main @ 703fbde`.

## Post-deployment verification — all PASS
| Check | Expected | Result |
|---|---|---|
| deployed SHA == merge SHA | `703fbde` | `DEPLOYED_HEAD = 703fbde9884ddeb9219c0cf54d34f5fe9e3f48a8` |
| migrations | 120 | **120** (Nothing to migrate) |
| provenance fingerprint | `62b2e42f…` | **`DEPLOYED_FP = 62b2e42fe409b4ec91f3381b35da819e`** (unchanged) |
| authorized staff see "Correct ownership…" on item detail | yes | link present in deployed `show.blade.php`; `StaffNavOwnershipCorrectionLinkTest::nav1` PASS on merged code |
| present for a zero-ownership item | yes | `nav2` PASS (asserts `sca_ownership_events=0` for the item and the link rendered) |
| targets the existing confirm route for that item | yes | `nav3` PASS (`href` == `admin.sca.eyewear.ownership.correct.confirm` for the id) |
| existing Ownership History intact | yes | unchanged in `show.blade.php`; `nav1` asserts the history control still present |
| staff without `sca.eyewear.ownership.correct` do not see the action | yes | `nav4` PASS |
| direct unauthorized access to the confirm route remains 403 | yes | `nav5` PASS; live: non-staff `/admin/.../ownership/correct` → **403** |
| Collector Support unchanged / reachable | yes | index button still in deployed source (`index.blade.php`, 1 match); route `admin.sca.collector.support.index` still admin-gated (non-staff → **403**) — no change made |
| no provenance mutation from navigation/rendering | none | `nav6` PASS; `DEPLOYED_FP` unchanged `62b2e42f`; migrations 120 |
| `/collector` healthy | 302 | **302** |
| Shopify webhook fail-closed | 401 | POST no-HMAC → **401** |
| `/storage` blocked | 404 | **404** |
| smsrocket co-tenant healthy | 302 | **302**; sr-caddy owns 80/443 (untouched) |

Live admin surface protection confirmed: item detail, ownership-correct confirm, and collector-support all return **403** from a non-staff IP (edge `@admin` + ACL unchanged; visibility ≠ authorization).

## Regression totals (merged/deployed code)
**836 passed / 4544 assertions, exit 0** (830 prior + 6 new).

## Scope delivered
One Blade view change: a `bouncer()->hasPermission('sca.eyewear.ownership.correct')`-gated "Correct ownership…" link on the eyewear item-detail History tab → existing `admin.sca.eyewear.ownership.correct.confirm` route, shown regardless of ownership count (closes the zero-ownership raw-URL dead-end and the ≥2-hop path). Existing Ownership History link and the correction workflow untouched; route guard unchanged; no permission broadened. No controller/route/ACL/`menu.php`/semantics/provenance/collector/QR/cert/Shopify/SMTP/schema/migration/public-route/Caddy/Docker change.

---

## SCA Staff Navigation / Discoverability — CLOSED

Every already-built staff capability is now reachable without knowing a hidden URL: the one confirmed raw-URL-only gap (ownership correction for zero-ownership items) is closed by the item-detail action; all other capabilities were already reachable from the sidebar, the Eyewear Registry index toolbar, or the item-detail page. **Collector Support was already discoverable (permission-gated button on the Eyewear Registry index) and required no change.** There is **no further navigation slice.** A staff dashboard / worklists remains a **separate optional** queued item (RECONCILED REMAINING WORK #2) — **not started**.

**Outcome: DONE (merged `--no-ff` + deployed, `703fbde`); production verified byte-identical except the additive, permission-gated item-detail link. Staff Navigation / Discoverability is CLOSED.** See `docs/SCA-STAFF-NAV-DISCOVERABILITY-DISCOVERY.md`, `docs/SCA-STAFF-NAV-DISCOVERABILITY-IMPLEMENTATION.md`.

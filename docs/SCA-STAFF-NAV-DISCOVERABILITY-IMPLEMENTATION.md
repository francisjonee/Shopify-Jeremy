# SCA Staff Navigation / Discoverability — implementation (candidate; NOT merged/deployed)

**Date:** 2026-10-06 · **Status: IMPLEMENTED + TESTED + PUSHED on a candidate branch. NOT merged, NOT deployed. Live tree restored to `main`; production byte-identical.** For ChatGPT pre-merge audit. Approved discovery gov `393d09f`.

One navigation change implementing the approved plan: a direct "Correct ownership…" action on the eyewear item-detail page, closing the single confirmed raw-URL-only gap (ownership correction for zero-ownership items). Collector Support unchanged (already discoverable). View-only + focused test.

## Candidate identity
- **Branch:** `origin/feat/sca-staff-nav-ownership-correct-link`
- **Base SHA:** `30b680f797bdcf0d9bf2e6031c32c4f80c41dfc4` (= deployed `main`; merge-base; clean 1-commit, fast-forwardable)
- **Head SHA:** `3d358640dcbbd0f59852110dff0f382e75afa7d8`

## Changed files (exactly one view + one test — hard boundary honored)
- `packages/Sca/Registry/src/Resources/views/eyewear/show.blade.php` — **+11 lines**: a permission-gated "Correct ownership…" link in the History-tab Ownership-history block.
- `tests/Feature/Sca/StaffNavOwnershipCorrectionLinkTest.php` — **new**, 6 focused tests.

`git diff --name-only 30b680f..3d35864` = exactly those two paths. **No** controller, route, ACL config, `menu.php`, provenance service, schema, or migration change.

## Behavior (exactly the approved one change)
- Links to the **existing named route** `admin.sca.eyewear.ownership.correct.confirm` with the current item id (`route('admin.sca.eyewear.ownership.correct.confirm', $item->id)`).
- Gated with the established pattern `@if (bouncer()->hasPermission('sca.eyewear.ownership.correct'))`.
- **Shown regardless of ownership count, including zero ownership** — closing the zero-ownership raw-URL-only dead-end and the previous ≥2-hop path (item → ownership-history → correct).
- Placed naturally in the History tab's "Ownership history" block, beside the existing **Ownership History** link, which is **unchanged** (not removed/modified).
- The correction workflow itself is untouched; this is navigation only. Route guard (`sca.can:sca.eyewear.ownership.correct`) is unchanged → **visibility does not grant authorization**; no permission broadened.

## Tests — new (`StaffNavOwnershipCorrectionLinkTest`, 6/6)
`sca_domain_test` hard-guarded, `DatabaseTransactions`:
- `nav1` authorized staff see "Correct ownership…" on item detail (and the existing "Ownership history" control is still present);
- `nav2` the link is shown even for a **zero-ownership** item (asserts `sca_ownership_events = 0` for it);
- `nav3` the rendered link's `href` targets the existing confirm route for that item;
- `nav4` staff with `sca.eyewear.view` but **without** `sca.eyewear.ownership.correct` do **not** see the link;
- `nav5` that unauthorized staffer still receives **403** when requesting the confirm route directly (visibility ≠ authorization);
- `nav6` rendering the item detail **and** the confirm interstitial causes **zero provenance mutation** (ownership/state/claims/certs fingerprint unchanged).

## Regression — full governed SCA gate
`… -e DB_DATABASE=sca_domain_test … php artisan test tests/Feature/Sca` → **836 passed / 4544 assertions**, exit 0 (830 prior + 6 new; ownership/correction, staff-registry, passport, QR suites all green). No schema change.

## Production-safety verification (post-restore)
`kr-app` bind-mounts the live tree; the change is a single view on the staff `/admin` surface. After push, the tree was **restored to `main`** and vendor **re-pruned `--no-dev`**. Verified: tree `main` @ `30b680f`; `PROD_FP = 62b2e42fe409b4ec91f3381b35da819e` (unchanged); migrations **120**; the correction link is **absent** from the main `show.blade.php` source (0); phpunit pruned; `/collector` 302, smsrocket.io 302, Shopify webhook POST → **401** fail-closed. No merge, no deploy, no DB/schema/config/Caddy change.

## Scope boundary honored / NOT done
No change to controller, routes, ACL definitions, `menu.php`, ownership/correction semantics, provenance services, collector functionality, QR, certification, Shopify, SMTP, schema/migrations, public routes, or Caddy/Docker/infrastructure. No dashboard/worklist work. Collector Support untouched. No merge, no deploy.

## Closure note
This is the single required change. On passing audit + deployment verification, the deploy evidence will state **SCA Staff Navigation / Discoverability — CLOSED**, and no further navigation slice will be created.

**Outcome:** implemented + green on a candidate branch, production untouched. STOP for ChatGPT audit. See `docs/SCA-STAFF-NAV-DISCOVERABILITY-DISCOVERY.md`.

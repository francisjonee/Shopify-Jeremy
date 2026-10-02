# SCA Collector Support navigation — make the existing tool discoverable (PUSH-ONLY)

**Date:** 2026-10-02 · **Base:** deployed main `af84b0a`, migrations **120**.
**Status: IMPLEMENTED + TESTED + PUSHED. NOT merged, NOT deployed. For independent review.**
Resolves the sole **P1** from the final production-readiness audit (gov `b390838`): the existing read-only
Collector Support lookup (SCA-STAFF-COLLECTOR-SUPPORT-040) was ACL-gated but unreachable via normal Admin nav.

## Candidate
- **SHA:** `1730576b62eafe42fb96e26843a13f8ed11187f0` · **Branch:** `origin/sca-collector-support-nav`
- **Base / merge-base:** `af84b0a` (clean, 1 commit, exactly 2 files). origin/main untouched (still `af84b0a`).

## Inspection (existing architecture)
- Routes exist: `admin.sca.collector.support.index` (`GET sca/collectors`) + `.show`, both
  `middleware('sca.can:sca.collector.support')` (`Registry/.../admin-routes.php:137-142`). ACL
  `sca.collector.support` exists (`Config/acl.php:92`). Controller + views exist. **Nothing to rebuild.**
- Admin menu is config-driven (`menu.admin`, `Registry/Config/menu.php` → only `sca-eyewear`). Krayin filters
  the sidebar on each item's **`key`** (`Webkul/Core/src/Menu.php:86` → `bouncer()->hasPermission($item['key'])`),
  and `User::hasPermission` is an **exact** `in_array` on the ACL key. `Menu::prepareMenuItems` runs
  `Arr::undot` on the item key (`:168`), so a **top-level** menu key must be single-segment — it can never
  equal the dotted ACL key `sca.collector.support` without mis-nesting under a synthetic `sca` parent that has
  no route (breaks rendering). This is exactly why the existing `sca-eyewear` entry (key `sca-eyewear`) only
  gates `all` vs `custom`, not the real permission.

## Change (presentation only; 2 files)
- `packages/Sca/Registry/src/Resources/views/eyewear/index.blade.php`: add a **"Collector support"** action
  link in the Registry index header toolbar, beside the existing Adverse-queue / New-item links, pointing to
  the **existing** `route('admin.sca.collector.support.index')`, wrapped in
  **`@if (bouncer()->hasPermission('sca.collector.support'))`** — the exact existing permission, checked the
  same way everywhere else. This gates correctly for **both** `all` and custom roles (authorized custom staff
  see it; unauthorized do not), which a config-menu key cannot (see Inspection).
- `tests/Feature/Sca/CatalogGridTest.php`: rg13 + rg14 (below).

**NO** new route/controller, **NO** ACL broadening, **NO** `menu.php` change, **NO** Collector-data/search-
semantics change, **NO** schema, **NO** Collector/public change, **NO** Krayin core/vendor edit.
`git diff af84b0a..1730576` = these 2 files only.

Note (not folded in): the Collector Support *surface itself* still shows a couple of raw enums
(`support-index.blade.php`, `support-show.blade.php`) — documented as a **P2** in the final-readiness audit and
intentionally **left out** of this P1 per scope.

## Why a toolbar link, not a sidebar menu entry
A `menu.php` entry would gate on the item key, which (per Inspection) cannot equal `sca.collector.support`
for a top-level item, so it could not be made "visible only to staff with that permission" for custom roles
without breaking the sidebar. The toolbar link's explicit `bouncer()->hasPermission('sca.collector.support')`
is the smallest change that gates **precisely** by the existing permission for every role type, reuses the
existing route, and stays inside the staff-IP + Admin-auth boundary (the registry index is under `/admin*`).
Caveat (acceptable): discoverable to staff who also have registry-list access (`sca.eyewear`) — true for the
pilot's `all`-type operators.

## Tests
- **CatalogGridTest 14/14** incl. **rg13** (`all` role AND a custom role with `['sca.eyewear','sca.collector.
  support']` both see the link + route) and **rg14** (custom `['sca.eyewear']` without support → link absent;
  the direct route still 403 without / 200 with the permission; `fp()` fingerprint identical → zero mutation).
- Full **`tests/Feature/Sca` 764 passed (4231 assertions), exit 0** (baseline `af84b0a` 762/4219 → +2). `php -l`
  clean; Blade parses. Collector/public navigation is unaffected (the link is an admin-only blade).

## Restoration / not-live / zero-mutation proof
- A stray commit was first made on local `main`, then moved to the feature branch and local `main` reset to
  `af84b0a`; **origin/main was never advanced** (verified `origin/main == af84b0a`). Pilot restored to `main`
  = `af84b0a` (`--no-dev`, caches cleared). Candidate **absent** (0 "Collector support" refs in the deployed
  index.blade). Live: `/p` 200/404, `/storage` 404, `/admin/sca/eyewear` 403 + `/admin/sca/collector` 403
  (existing ACL retained) from a non-staff source; kr-app `127.0.0.1:8080` loopback-only. Prod unchanged
  (presentation-only, no mutation run): migrations 120, status_events 6, QR tokens `bee93d2b…`/`10c739b7…`,
  gallery 3.

**STOP after push. Not merged/deployed. Awaiting review of `1730576` (base `af84b0a`).**

---

## DONE — MERGED (--no-ff) + DEPLOYED 2026-10-02

Pre-merge review = PASS/GO. Fail-closed gate re-checked: origin/main `af84b0a`, candidate local+origin
`1730576`, merge-base `af84b0a`, ahead 1 / behind 0, clean tree, exactly the reviewed 2-file scope
(Blade +9 / CatalogGridTest +32), no menu.php/ACL/controller/route/service/schema/core change.

**MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `236acd93f06b2267c3d209aee0675550b09e1cb5`** (governed `--no-ff`
merge of `1730576` onto `af84b0a`). Deployed via `scripts/deploy-preview.sh` (exit 0, first run — no flake):
gate **full tests/Feature/Sca 764 passed (4231 assertions)** before any production change;
**`Nothing to migrate` — migrations remain 120**; `Deployed main @ 236acd9`. Code-only (bind-mounted view) →
kr-app NOT recreated; Phase-B loopback intact; stash NOT re-applied.

**Post-deploy verification (NON-MUTATING; no temporary prod user created):**
- Deployed index.blade carries the gated link: `bouncer()->hasPermission('sca.collector.support')` present,
  route `admin.sca.collector.support.index` present, text "Collector support" present → targets the EXISTING
  route `…/admin/sca/collectors`.
- Gating correctness (authorized `all`; authorized custom WITH `sca.collector.support`; custom WITHOUT →
  hidden; direct route retains its ACL 403-without/200-with) is proved by the deploy-gate CatalogGridTest
  rg13/rg14 (ran green in the 764/4231 gate). No prod user/role created (per instruction).
- **No new route/controller/permission:** exactly the two existing routes
  `admin.sca.collector.support.{index,show}`; exactly one existing ACL key `sca.collector.support`.
- **No Collector/public navigation receives the link:** grep of collector + passport views finds no
  `admin.sca.collector.support` / "Collector support" reference (admin-only blade).
- Collector Support search/data behavior unchanged (its controller/views/service untouched — not in the diff).
- Standard regression (live): SCA-038 `/p` valid 200/200, bogus/malformed 404/404; `/storage` 404;
  `/admin/sca/eyewear` 403 + `/admin/sca/collectors` 403 (staff-IP + ACL); `/collector/login` 200;
  `http→https` 308; `secure` cookie (Phase B); gallery + QR download/reissue routes registered; public `:8080`
  retired — kr-app `127.0.0.1:8080` loopback-only + healthy; MariaDB private.
- **ZERO provenance/domain mutation — AFTER == BEFORE (`c3fea71ad6ecf93345b2eefc5f5cbef4`):** projection, QR
  tokens + is_production, status_events 6, cert/cert-events/auth/ownership, gallery 3, QR lifecycle,
  migrations 120 — all unchanged.

The final-readiness P1 (Collector Support unreachable) is resolved. **COMPLETE. STOP — do not begin the P2
bundle.**

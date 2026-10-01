# SCA Admin Login — broken logo root cause + fix (PUSH ONLY)

**Date:** 2026-10-01 · **Base:** deployed main `f4c84e6` (migrations 120). **Candidate HEAD:** `21fe5eb`
on branch `sca-admin-logo-fix`. **Status:** PUSH ONLY — not merged, not deployed. Awaiting independent
pre-merge review.

## Root cause (confirmed, not guessed)
Krayin's admin login view (`packages/Webkul/Admin/.../sessions/login.blade.php`) renders the logo as:
```blade
@if ($logo = core()->getConfigData('general.general.admin_logo.logo_image'))
    <img src="{{ Storage::url($logo) }}" alt="{{ config('app.name') }}" />
@else
    <img src="{{ vite()->asset('images/logo.svg') }}" alt="{{ config('app.name') }}" />
@endif
```
A custom admin logo IS configured in the DB (`core_config` `general.general.admin_logo.logo_image =
configuration/46a8f40097856564568f5d9a9596800d.png` — the operator's uploaded 140,822-byte SCA PNG, present
at `storage/app/public/configuration/46a8…png`). `Storage::url($logo)` =
`https://verify.secondchanceauthenticators.com/storage/configuration/46a8…png`. The production Caddy edge
**default-denies `/storage`** → that URL returns **404** (text/plain) → the browser shows a broken image,
and `alt="{{ config('app.name') }}"` = **"SCA"** (the alt text the operator saw). This is caused by the
intentional `/storage` edge hardening, NOT a missing file. The **same `Storage::url($logo)` source** is used
in `sessions/login`, `sessions/forgot-password`, `sessions/reset-password`, `layouts/header`, and
`layouts/sidebar/mobile` — all break identically through the edge.

## Fix (SCA-owned; NO Krayin core/vendor edit; NO /storage; hardening preserved)
1. `BrandLogoController::show` (new) streams the SAME configured admin-logo file from the `public` disk
   server-side (`Storage::disk('public')->get()/mimeType()`) — bytes + Content-Type only, never a
   `/storage` URL, storage tree never exposed; 404 when no logo configured / file missing.
2. Public (pre-auth) route `GET /admin/sca/brand-logo` (name `admin.sca.brand-logo`), `['web',
   'admin_locale']` only (NO `sca.auth`), under the admin prefix so it rides the staff-IP-allowlisted
   `/admin*` edge path and loads on the pre-login page without a session.
3. Login view override inside the SCA package
   (`Registry/src/Resources/admin-override/sessions/login.blade.php`), registered with priority on the core
   `admin` view hint via `$this->app['view']->prependNamespace('admin', …)` in `RegistryServiceProvider`.
   The core `login.blade.php` is left byte-for-byte untouched. (`app/resources/views` is entirely gitignored
   — `.gitignore` = `*` — so a Laravel app vendor-override there would not be committed/deployed; the
   override MUST be package-owned. This is why it lives in the SCA package.) The override is identical to the
   core login except the logo `<img>` → `route('admin.sca.brand-logo')`, with the vite asset kept as the
   fallback when no admin logo is configured.

## Verification (live, pre-restore)
`/admin/login` renders the logo `<img src="…/admin/sca/brand-logo">` with **zero `/storage` img srcs**
(`<img … src="…/storage…"` count = 0) and `alt="SCA"`; the route returns **200 `image/png`, 140,822 bytes**
(the SCA logo) via loopback; `/storage/configuration/46a8…png` still **404** at the edge. (A `/storage/
configuration` string remains only inside a benign core `<script>` block, not an `<img src>`.)

## Elsewhere (same source — reported, NOT fixed here)
`layouts/header`, `layouts/sidebar/mobile` (post-login admin chrome), `sessions/forgot-password`,
`sessions/reset-password` use the identical `Storage::url($logo)` and remain broken through the edge.
**Recommended bounded follow-up:** point those at the same `admin.sca.brand-logo` route (same override
technique). Scoped out of this push to keep it to the reported login symptom + minimal surface.

## Tests (AdminLoginLogoTest 4; full tests/Feature/Sca 726/3985; php -l clean)
rg1 login uses the brand-logo route + NO `/storage` `<img>` + app-name alt; rg2 the route streams the
configured image (200, image/*, exact bytes); rg3 404 + vite fallback when no logo configured; rg4 auth
unchanged — the brand-logo route is public (200 unauth) while an admin registry page still redirects
unauthenticated to the login.

## Scope / push-only + restoration (production remains on f4c84e6)
1 commit; 1 modified (`RegistryServiceProvider` +14) + 3 new (`BrandLogoController`,
`admin-override/sessions/login.blade.php`, `AdminLoginLogoTest`). **No `packages/Webkul` (Krayin core)
file changed.** Candidate pushed to `origin/sca-admin-logo-fix` (`21fe5eb`, base `f4c84e6`). Pilot restored
to main `f4c84e6` (working tree reverted; `--no-dev`; caches cleared): BrandLogoController / admin-override
/ brand-logo route all absent on the live app; migrations 120; FP_QR `a920dc1c…`; is_production 0,0; gallery
3; kr-app loopback-only `127.0.0.1:8080` (Phase B state intact); verify. passport 200; `/storage` 404;
smsrocket 302.

## PRE-MERGE REVIEW #1 = CHANGE REQUESTED → CORRECTED + RE-PUSHED (same branch)

Review of `21fe5eb`: root cause + the `admin.sca.brand-logo` streaming endpoint approved, but do not ship a
login-only fix while header / mobile-sidebar / forgot-password / reset-password keep the same broken
`/storage` logo source.

**Correction (same branch, new HEAD `359713a`; chain `21fe5eb → 359713a`, base `f4c84e6`):** one canonical
endpoint retained (no new endpoint, no duplicated image, still serves the EXISTING configured SCA logo).
Added SCA-package-owned overrides (same `prependNamespace('admin', …)`) for the four remaining surfaces and
regenerated login, each a faithful copy of its core view changed in ONLY the logo src line(s) —
`Storage::url($logo)` → `route('admin.sca.brand-logo')` (login/forgot/reset 1 line each, header 2 lines,
mobile-sidebar 1 line; verified by `diff` — everything else byte-identical, so dark-mode vite fallback,
`id="logo-image"`, classes and all header/sidebar behavior are preserved; this also removed the earlier
`w-[110px]`→`w-auto` class drift in login). Override files:
`Registry/src/Resources/admin-override/{sessions/login,sessions/forgot-password,sessions/reset-password,
components/layouts/header/index,components/layouts/sidebar/mobile/index}.blade.php`.

**No `packages/Webkul` (Krayin core) change** (git diff vs base empty). No DB/auth/ACL/Caddy/route/
provenance/gallery/Passport/Collector/infra change; `/storage` stays edge-denied.

**Tests — AdminLoginLogoTest expanded to one branding contract (7):** login/forgot/reset + authenticated
header+sidebar use `admin.sca.brand-logo`; the route streams the configured PNG bytes/content-type; 404 +
vite fallback when unconfigured; no `<img>` uses `/storage` or the raw configured path; auth unchanged
(route public pre-auth, admin pages still redirect unauthenticated). Full tests/Feature/Sca **729/3999**;
php -l clean.

**Scope:** 1 commit on top of `21fe5eb`; 4 new overrides + regenerated login + expanded test. Pilot
re-restored to main `f4c84e6` (override dir + brand-logo route absent on the live app; `packages/Webkul`
untouched; migrations 120; FP_QR `a920dc1c…`; is_production 0,0; gallery 3; kr-app loopback-only
`127.0.0.1:8080`; verify. passport 200; `/storage` 404; smsrocket 302).

## RE-REVIEW = PASS/GO → DONE — MERGED --no-ff + DEPLOYED 2026-10-02

`MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = 6840503bbf8ce0f7fd6f2f790511db20b14ea574` (reviewed HEAD
`359713a`, base `f4c84e6`, chain `21fe5eb → 359713a`). Pre-merge gates passed (origin/main `f4c84e6`,
feature `359713a`, merge-base `f4c84e6`, clean tree, 2 commits, `packages/Webkul` untouched, all-SCA scope).

**Deploy (`deploy-preview.sh`, exit 0):** full tests/Feature/Sca gate passed; **Nothing to migrate —
migrations remain 120**; `Deployed main @ 6840503`. Code-only change (bind-mounted views) → kr-app not
recreated, so the Phase-B loopback-only bind `127.0.0.1:8080` is intact (no public :8080, no stash
re-apply).

**Post-deploy verification (all PASS):** DEPLOYED_HEAD == ORIGIN_MAIN == MERGE_SHA `6840503`.
- Admin logo surfaces (via loopback = app direct, bypassing the Caddy staff-IP gate for inspection):
  **login / forget-password / reset-password** each 200 and reference `admin/sca/brand-logo` with **0
  `/storage` `<img>`**; the **authenticated header + sidebar + mobile-sidebar** reference the route **3×**
  with 0 `/storage` `<img>`.
- `GET /admin/sca/brand-logo` → **200 `image/png`, 140,822 bytes** (the configured SCA logo).
- `GET https://verify…/storage/configuration/46a8…png` → **404** (edge `/storage` deny intact).
- Staff-IP + auth unchanged: verify. collector/login 200, admin/login **403** (non-staff allowlist),
  `http→https` 308. Phase-B Secure cookie present on verify. (`sca_session … secure`).
- SCA-038 passport 200/404/404; item-3 image 200 (Collector gallery unaffected); smsrocket 302.
- Provenance unchanged: FP_QR `a920dc1c…`, FP_CERT `22fb9f55…`, FP_AUTH `3bd0f029…`, FP_OWN `831ae932…`;
  is_production 0,0; gallery 3; migrations 120. Configured logo / DB / Caddy / `/storage` policy / infra
  untouched.

(Pixel-level in-browser rendering from a staff IP is the operator's visual confirmation; the markup +
route + served PNG bytes prove the SCA logo now loads on every surface.)

**COMPLETE. STOP — no further task.** (Deferred elsewhere: none for this fix; the whole admin-logo source is
now canonical.)

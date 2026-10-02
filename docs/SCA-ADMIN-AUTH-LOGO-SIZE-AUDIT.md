# SCA Admin Auth-Page Logo Size — presentation readiness audit (READ-ONLY, DO NOT IMPLEMENT)

**Date:** 2026-10-02 · **Deployed base:** main `6840503` (admin SCA logo live via `admin.sca.brand-logo`).
**Status: AUDIT ONLY — no code changed; zero production change. For review before implementing.**

Ask: make the SCA logo larger on the Admin **Login, Forgot Password, Reset Password** pages — ~140–160px
wide, auto height, centered, responsive, no stretch. Presentation only. Do NOT change the
`admin.sca.brand-logo` route/controller, the configured logo, `/storage` policy, authentication, the
**header/sidebar** logo sizing, or any backend behavior.

## Current markup (identical in all three auth overrides)
`Registry/src/Resources/admin-override/sessions/{login,forgot-password,reset-password}.blade.php` — the
logo block (lines 7-22) is byte-identical across the three:
```blade
<div class="flex h-[100vh] flex-col items-center justify-center gap-10">
    <div class="flex flex-col items-center gap-5">   {{-- already centers the logo (items-center) --}}
        @if ($logo = core()->getConfigData('general.general.admin_logo.logo_image'))
            <img class="h-10 w-[110px]" src="{{ route('admin.sca.brand-logo') }}" alt="{{ config('app.name') }}" />
        @else
            <img class="w-max" src="{{ vite()->asset('images/logo.svg') }}" alt="{{ config('app.name') }}" />
        @endif
```

## Cause of "too small"
The configured-logo `<img>` is `class="h-10 w-[110px]"` — a FIXED 40px height × 110px width. That both caps
the logo at 110px wide and, because width AND height are both pinned, can distort a non-2.75:1 logo. The
operator wants ~150px wide with auto height (aspect preserved).

## Recommended change — smallest SCA-package-owned, 3 lines (one per auth view)
Change ONLY the configured-logo `<img>` in the three auth overrides from `class="h-10 w-[110px]"` to a
~150px-wide, auto-height, responsive, non-stretch presentation. **Use an inline `style`, not a new Tailwind
arbitrary class**, because Krayin's admin CSS is a pre-compiled Tailwind build and a new arbitrary value
(e.g. `w-[150px]`) is not guaranteed to be in the compiled stylesheet (the same risk documented for the
registry grid); inline style always applies and needs no build:

```blade
<img style="width: 150px; height: auto; max-width: 100%;" src="{{ route('admin.sca.brand-logo') }}" alt="{{ config('app.name') }}" />
```
- **~150px wide** (mid of the 140–160 target); `height: auto` → aspect preserved, **no stretch**.
- `max-width: 100%` → responsive; never overflows a narrow viewport.
- **Centered** already by the existing parent `flex flex-col items-center` — no change needed.
- The `@else` vite fallback (`class="w-max"`) is left exactly as core (only affects the no-configured-logo
  case; out of scope).

Scope: exactly the configured-logo `<img>` line in `sessions/login.blade.php`,
`sessions/forgot-password.blade.php`, `sessions/reset-password.blade.php`. **Header and mobile-sidebar
overrides are NOT touched** (their logo sizing stays). No route/controller/config/DB/`/storage`/auth/backend
change; `packages/Webkul` stays untouched.

## Regression (recommended)
Extend `AdminLoginLogoTest`: on each auth page (login/forgot/reset) assert the logo `<img>` carries the
enlarged sizing (`width: 150px` + `height: auto`) and still points at `admin.sca.brand-logo` with no
`/storage` `<img>` (existing branding contract preserved). The authenticated header/sidebar test (rg7) must
remain green unchanged — proving header/sidebar sizing was not altered. Full `tests/Feature/Sca` + `php -l`.

## Risk
Trivial, presentation-only, three identical one-line edits; inline style sidesteps the Tailwind-compilation
risk; centering/responsiveness already provided by the existing flex container; the `/storage` hardening,
auth, header/sidebar, and the canonical logo route are all untouched.

**Recommendation: GO** for the 3-line inline-style edit (push-only → review → governed merge/deploy), scoped
to the three auth-page overrides. **AUDIT ONLY — awaiting review + GO before implementing.**

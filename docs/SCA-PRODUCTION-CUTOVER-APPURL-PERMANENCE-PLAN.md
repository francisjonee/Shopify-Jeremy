# SCA-PRODUCTION-CUTOVER — Application URL / Permanence Configuration — Planning Audit (READ-ONLY)

**Date:** 2026-09-30
**Deployed baseline:** `bd9e3cd` (unchanged). **No changes — reads only.** Runtime = accepted Phase 2C state
(`https://verify.secondchanceauthenticators.com` live, Let's Encrypt cert, `/collector/login`→200).
**Goal:** transition the app identity from the temporary `http://195.26.255.80:8080` to the permanent
`https://verify.secondchanceauthenticators.com`, via **`.env` only** (no code, no schema, no DB).

## 1. Config variables actually consumed by the deployed code (verified by `env()` grep)

| Var | Current | Required final | Runtime effect (evidence) | Apply in |
|---|---|---|---|---|
| **APP_URL** | `http://195.26.255.80:8080` | `https://verify.secondchanceauthenticators.com` | `config/app.php:55` (`config('app.url')` — fallback root for URL generation **outside** a request); `config/filesystems.php:41` (`public` disk url = `APP_URL/storage` — used only by the **Krayin admin logo/config images**, IP-restricted; **no** SCA public/collector surface renders a public-disk URL); `config/sanctum.php:22` (adds the APP_URL host to Sanctum stateful domains). **Live web URLs are request-derived (unchanged).** | Phase A |
| **PUBLIC_QR_BASE_URL** | unset | *(optional)* `https://verify.secondchanceauthenticators.com` | **NONE — behaviorally INERT.** No `env('PUBLIC_QR_BASE_URL')` anywhere in the codebase (only a config comment). The QR destination is derived from the request/route (`/p/{token}`), not this var. Setting it has **zero runtime effect**; do so only as forward-documentation for the (deferred) printable-QR feature. | Optional |
| **SCA_PUBLIC_PREVIEW** | unset (`=1` default) | `0` | `config/passport.php:21` → `config('sca-passport.preview')` → `PassportController` → `passport/layout.blade.php:49` `@if (! empty($preview))` renders the **"SCA DEVELOPMENT PREVIEW — not the permanent verification address"** banner. `=0` removes the banner. **Presentation-only** (see §4). | Phase A |
| **SESSION_SECURE_COOKIE** | unset (→ not Secure) | `true` | `config/session.php:171` (`config('session.secure')`) — marks the session **and** XSRF cookies `Secure` (HTTPS-only). | **Phase B only** — after `:8080` retirement (see §3) |
| **SESSION_DOMAIN** | unset (`null`, host-only) | **unset (`null`) — NO CHANGE** | `config/session.php:158` — `null` scopes cookies to the exact request host (`verify.…`). **Do NOT set `.secondchanceauthenticators.com`** — that would share SCA session/CSRF cookies with the live Shopify apex (isolation/security regression). | Keep null |

**Also consumed (no change needed):** `SCA_PASSPORT_PATH` = `p` (keep — QR tokens resolve at `/p/{token}`);
`ASSET_URL` unset (keep — `asset()` falls back to `APP_URL`/request; SCA public surfaces don't rely on it).
**Related but separate:** `SCA_PREVIEW_BANNER` (`env()` in `DevelopmentPreviewBanner.php:26`) is a **different** var —
the admin-only WIP banner injected into Krayin admin HTML (IP-restricted). `SCA_PUBLIC_PREVIEW=0` does **not** affect
it. Optionally set `SCA_PREVIEW_BANNER=0` at cutover to remove the staff WIP banner; not required, purely cosmetic,
staff-facing.

## 2. `PUBLIC_QR_BASE_URL` — re-confirmed INERT before setting

`grep env('PUBLIC_QR_BASE_URL')` across the whole app (excl. vendor) → **no match** (only a comment in
`passport.php`). It is read by **no code path**. The permanent QR destination is `{request host}/p/{token}`
(host-derived), and the printable-QR artifact is a deferred, not-yet-built feature. **Setting it changes nothing at
runtime** — recommend setting it to the verify URL only as documentation so the future printable-QR feature has the
canonical base, but it is not functionally required and must not be assumed to "activate" anything.

## 3. `SESSION_SECURE_COOKIE=true` sequencing vs. `:8080` retirement

`config('session.secure')` is a **static** flag (no per-request "auto"): `true` marks the session/XSRF cookies
`Secure`, so browsers send them **only over HTTPS**. If set while the plain-HTTP `:8080` fallback is still used for
interactive login, **`:8080` login breaks** (the browser won't return the Secure cookie over `http`), and existing
`:8080` sessions stop authenticating. Therefore:
- **Do NOT set `SESSION_SECURE_COOKIE=true` in Phase A** (while `:8080` remains the fallback).
- Set it in **Phase B**, sequenced with `:8080` retirement: (a) move all interactive staff/collector access to
  `https://verify.…`; (b) confirm nobody relies on `:8080` login; (c) set `SESSION_SECURE_COOKIE=true` +
  `config:clear`; (d) verify `verify.` login still works (Secure cookie over HTTPS) and `:8080` interactive login is
  gone/retired. Until then, the cookie is non-Secure but still functions over HTTPS on `verify.` (acceptable interim;
  hardened by Phase B).

## 4. `SCA_PUBLIC_PREVIEW=0` — exact effect + proof of no QR/cert/provenance/SCA-038 impact

Flow: `env('SCA_PUBLIC_PREVIEW')` → `config('sca-passport.preview')` → `PassportController` passes `preview` to the
view → `passport/layout.blade.php:49` `@if (! empty($preview))` renders the development-preview `<div>`. Setting `=0`
makes `$preview` false → the banner is **not rendered**. That is the **only** effect.
- **Proven independent of resolution/identity:** the passport **resolver** reads `preview`/`APP_URL` **0 times**
  (grep of `packages/Sca/Passport/src/Services` + resolver = 0); SCA-038 Option A resolution (certified `/p/{token}`→
  200; bogus/revoked→constant-shape 404) happens **before** the view and is unaffected. It touches **no**
  `sca_qr_identifiers`, `sca_certifications`, or any provenance table — it is a render-time boolean only. Live now the
  banner IS shown ("SCA DEVELOPMENT PREVIEW — not the permanent verification address"); `=0` removes it and changes
  nothing else. (Independently: `.env` edits mutate no DB; QR fp/counts stay identical.)

## 5. Absolute-URL generation re-audit under `https://verify.…`

All live URL generation is **request-derived** (host from `X-Forwarded-Host`, scheme from `X-Forwarded-Proto` via the
trusted proxy) and is already correct on `verify.` (proven in Phase 2C: form action `https://verify.…/collector/login`):
- **Collector login/logout/register/reset** — `route()`/`redirect()->route()`/`redirect()->intended()` (host-derived).
  The **password-reset email** uses `url(route('collector.password.reset', …, false))` **synchronously**
  (`QUEUE_CONNECTION=sync`, 0 `ShouldQueue` in SCA) → request root → `https://verify.…/collector/reset-password/…`.
  (Delivery still `MAIL_MAILER=log`; the URL is correct regardless — no `APP_URL` dependency.)
- **Claim / transfer** — `route('collector.claim.*')`, `route('collector.collection.*')` redirects (host-derived); no
  emailed absolute invitation URL (Shopify-driven, deferred).
- **Passport URLs** — `route('sca.passport.show')`, no host constraint; `PassportPresenter` builds no URLs.
- **Forms / redirects** — request-derived (verified live).
- **Generated documents** — the certificate PDF embeds the **opaque token, no URL/host**; document/cert **downloads**
  are route-based streamed responses (`DocumentStream->download`, `redirect()->route`), not public-disk URLs.
- **Only `APP_URL`-dependent URL** = the `public` filesystem disk (`APP_URL/storage`), used by the **Krayin admin
  logo** (IP-restricted) — not any SCA public/collector surface. Setting `APP_URL=verify.` makes that load over HTTPS;
  leaving it pilot only causes a wrong-host image on the staff admin. **No public-facing URL depends on `APP_URL`.**

## 6. GO / NO-GO gates, order of operations, rollback

**Order of operations (future implementation — `.env` only, `0600` www-data preserved; no code/schema/DB):**

*Phase A — URL/permanence (no login impact):*
1. Backup `app/.env`.
2. Set `APP_URL=https://verify.secondchanceauthenticators.com`, `SCA_PUBLIC_PREVIEW=0`
   (optionally `PUBLIC_QR_BASE_URL=https://verify.secondchanceauthenticators.com` [inert, docs] and
   `SCA_PREVIEW_BANNER=0` [admin cosmetic]). **Do NOT touch `SESSION_DOMAIN` or `SESSION_SECURE_COOKIE`.**
3. `docker compose exec -u 33:33 app php artisan config:clear` (deploy uses `config:clear`; config is not cached, so
   `.env` is read fresh on the next request — no restart needed, per the `TRUSTED_PROXIES` precedent).

**GO gates (Phase A) — all must pass:**
- `config('app.url')` = `https://verify.secondchanceauthenticators.com` (probe/tinker).
- Public passport: **no** "SCA DEVELOPMENT PREVIEW" text on `https://verify.…/p/{valid}`.
- SCA-038 Option A intact: `/p/{valid}`→200, `/p/{bogus}`→404 (constant shape, ~2863 B).
- Collector: `https://verify.…/collector/login` form action `https://verify.…`; a full login → My Collection
  round-trip works (session cookie set over HTTPS); reset link (via log) = `https://verify.…`.
- Admin logo/config images load over `https://verify.…/storage/…`.
- **`:8080` fallback still fully works** (login + admin) — because `SESSION_SECURE_COOKIE` remains unset.
- Zero mutation: QR fp `6bb119ee…` + counts (118/2/3) unchanged; smsrocket 200; DOCKER-USER byte-identical; MariaDB
  private.

**NO-GO / rollback (Phase A):** restore `app/.env` from backup (`APP_URL` back to the pilot, remove
`SCA_PUBLIC_PREVIEW`/`PUBLIC_QR_BASE_URL`/`SCA_PREVIEW_BANNER`); `config:clear`. Instant revert; **no DB restore ever
needed** (`.env` mutates no data).

*Phase B — Secure cookie (SEPARATE, sequenced with `:8080` retirement):* set `SESSION_SECURE_COOKIE=true` + `config:clear`
only after `:8080` interactive login is retired; verify `verify.` login works and `:8080` login no longer does; rollback
= unset it + `config:clear`.

## 7. Zero-mutation confirmation (this audit)

`bd9e3cd`, tree CLEAN; `.env` unchanged (`APP_URL=http://195.26.255.80:8080`; none of `PUBLIC_QR_BASE_URL`/
`SCA_PUBLIC_PREVIEW`/`SESSION_SECURE_COOKIE`/`SESSION_DOMAIN` set); migrations=118, qr=2, certs=3; QR fp
`6bb119ee0b598222bfec58bb80c7a4cb`; verify. + `:8080` + smsrocket healthy. **No `.env`/DNS/Caddy/QR/DB change.**

**Recommendation:** implement **Phase A** as a small governed `.env`-only task (backup → set APP_URL + SCA_PUBLIC_PREVIEW=0
[+ optional inert PUBLIC_QR_BASE_URL / SCA_PREVIEW_BANNER=0] → config:clear → GO gates), keep `SESSION_SECURE_COOKIE`
for **Phase B** with `:8080` retirement, and keep `SESSION_DOMAIN` null. Planning only; nothing changed.

# SCA PRODUCTION CUTOVER — Phase B Readiness Audit (READ-ONLY, DO NOT EXECUTE)

**Date:** 2026-10-01 · **App baseline:** deployed main `f4c84e6`, migrations 120. **Status: AUDIT ONLY —
no `.env`/Caddy/Docker/firewall/DNS/DB/code/session/QR/config change. ACTIVE/NEXT_TASK unpromoted. For
ChatGPT review.**

Objective: determine readiness to (1) retire the public `195.26.255.80:8080` pilot path, then (2) enforce
`SESSION_SECURE_COOKIE=true`.

---

## 1. `:8080` reference inventory
There are **two distinct bindings** (often conflated):
- **PUBLIC pilot bind `195.26.255.80:8080`** — lives ONLY in `git stash@{0}` ("pilot: temporary public
  exposure"); it is re-applied after every deploy (the known deploy gotcha). **This is the public pilot
  path Phase B retires.** Gated by host firewall `DOCKER-USER`: `RETURN established` + `ACCEPT` 103.225.137.242
  + `ACCEPT` 103.200.35.2 + `DROP` all, on `ctorigdstport 8080` (2 staff IPs only).
- **COMMITTED loopback bind `127.0.0.1:${APP_BIND_PORT:-8080}:80`** (`docker-compose.yml:64`) — local-only,
  NOT publicly reachable; used solely by `scripts/deploy-preview.sh:72` (`curl http://127.0.0.1:8080/admin/
  login` health check) and asserted by `scripts/validate-hardening.sh:18`. This is NOT a public surface and
  can safely remain.

**No SCA application code/config references `:8080` or `195.26.255.80`** (grep of `packages/Sca/*`, `config/`,
`bootstrap/`, routes, views = none; the only literal host is a Caddyfile comment). `APP_BIND_PORT=8080` in
`.env` feeds the loopback bind only.

## 2. Does anything depend on :8080? — NO
No Admin, Collector, QR, Passport, certificate, document, image/gallery, redirect, form-action, asset, or
email/link-generation path depends on `:8080`. All generated URLs derive from `config('app.url') =
https://verify.secondchanceauthenticators.com` (+ relative route paths); the permanent QR artifact encodes
`https://verify.../p/{token}` from `app.url` (host-independent, immutable). The pilot is reachable at BOTH
`:8080` (HTTP) and verify. (HTTPS) today; verify. is fully functional (below), so operators can use verify.
exclusively. The only consumer of a `:8080` endpoint is the deploy health check — on the LOOPBACK bind, not
the public one.

## 3. Live HTTPS behavior through https://verify.secondchanceauthenticators.com
- Collector login (public): **200**. Admin login: **403** from a non-staff IP (Caddy `/admin*` remote_ip
  allowlist working; the 2 staff IPs pass). Passport `/p/{token}` 200, bogus/malformed 404 (SCA-038 intact).
  Catalog images stream 200 via authorized routes; `/storage` 404.
- `http://verify…` → **308** redirect to HTTPS (Caddy). So the ONLY plain-HTTP route to the app is the
  direct container `:8080` bind — once retired, there is NO HTTP path to the app at all.
- **Cookies are ALREADY `Secure` over verify. HTTPS and non-Secure over :8080 HTTP** (observed Set-Cookie):
  because `config('session.secure')` is NULL, Laravel auto-derives the cookie Secure flag from the request
  scheme, and the request is correctly detected as HTTPS via the trusted proxy. So HTTPS sessions are
  already hardened; `SESSION_SECURE_COOKIE=true` only FORCES Secure on every response regardless of scheme.

## 4. APP_URL / trusted proxies / session state (effective runtime)
`app.url=https://verify.secondchanceauthenticators.com`; `app.env=production`; `session.driver=file`;
`session.secure=NULL` (⇒ **SESSION_SECURE_COOKIE unset**); `session.domain=NULL` (host-derived — works for
both :8080 and verify.); `session.same_site=lax`; `TRUSTED_PROXIES=172.20.0.0/24` (effective — verify.
traffic arrives via sr-caddy on `sca_edge`, so `X-Forwarded-Proto: https` is honored and the request is
detected secure); `sca-passport.preview=false` (banner already disabled — §8).

## 5. Is SESSION_SECURE_COOKIE=true safe after :8080 retirement? — YES
With TRUSTED_PROXIES already set, Laravel already detects verify. requests as secure (proof: Secure cookies
on verify. today). Forcing `true` marks EVERY cookie Secure regardless of scheme. The only non-HTTPS surface
is the public `:8080` HTTP path; while it exists, forcing Secure would break `:8080` login (the browser
withholds a Secure cookie over HTTP). **After the public :8080 path is retired (and Caddy 308-redirects all
HTTP → HTTPS), no HTTP login surface remains, so `SESSION_SECURE_COOKIE=true` is safe and is strictly
hardening** (prevents any non-Secure cookie from ever being issued, e.g. on a misrouted HTTP request).
Collector + Admin (staff-IP) HTTPS logins are unaffected (already Secure). The loopback deploy health check
(`GET http://127.0.0.1:8080/admin/login`) still returns 200 — it's a status check that does not rely on
receiving/sending a session cookie, so forcing Secure does not break it.

## 6. Exact changes to retire the public :8080 (for the eventual execution — NOT done here)
1. **Pilot bind (Docker):** stop re-applying `git stash@{0}`; recreate kr-app on the COMMITTED loopback
   compose so it binds only `127.0.0.1:8080` — `docker compose up -d --force-recreate app` from
   `/opt/sca-platform` (one recreate; ~2-10s kr-app blip, verify. briefly 502). Keep `stash@{0}`
   **undropped** during the bake period so rollback is a one-step re-apply; drop it only in a later
   finalization. The committed loopback bind + `deploy-preview.sh` + `validate-hardening.sh` stay unchanged.
2. **Host firewall:** remove the `DOCKER-USER` `:8080` rules (the 2 staff ACCEPTs + the DROP, and optionally
   the established-RETURN if it exists only for this) once the bind is loopback-only — they become moot.
   Preserve the exact rule text for rollback. (Host iptables change; not an app change.)
3. **No `.env`/code change for retirement itself** (`APP_BIND_PORT` stays for the loopback bind).
4. **Then, as a SEPARATE gated step:** set `SESSION_SECURE_COOKIE=true` in prod `.env` + `php artisan
   config:clear` (no rebuild/migration). Optionally also `SESSION_SAME_SITE` stays `lax`; leave
   `SESSION_DOMAIN` unset (host-derived).

## 7. Rollback
- **:8080 retirement fails / operator still needs it:** `git stash apply stash@{0}` → `docker compose up -d
  app` → `git checkout -- docker-compose.yml` (re-exposes `195.26.255.80:8080`); re-add the DOCKER-USER
  staff-IP ACCEPT + DROP rules. Non-destructive; QR/DB untouched.
- **SESSION_SECURE_COOKIE=true causes a problem:** remove the line from `.env` (back to unset/auto) +
  `config:clear`. Reverts to today's secure=null auto-behavior; sessions keep working. Non-destructive.

## 8. Development-Preview banner
Already handled: `sca-passport.preview` = `env('SCA_PUBLIC_PREVIEW','1')==='1'`, and prod has
`SCA_PUBLIC_PREVIEW=0` ⇒ `preview=false`, so `passport/layout.blade.php` renders the banner only
`@if(!empty($preview))` → **the banner is already OFF in production.** No Phase B action required. (Hard-
removing the preview code/config is cosmetic and belongs to a separate production-finalization step, not a
blocker.)

## 9. Provenance / QR invariance — CONFIRMED
Phase B touches ONLY the container port binding, host firewall, and one session `.env` flag + caches. It
performs **no QR token regeneration/reissue** (QR tokens are permanent, host-independent, derived from
`app.url`), and modifies **no** provenance / certifications / authentications / ownership / current-state /
gallery data / `is_production` (which stays 0,0). No migration (stays 120). No DB write at all.

## 10. Ordered cutover plan + hard GO/NO-GO gates (DO NOT EXECUTE YET)
**Pre-cutover GATE:** operators confirmed off `:8080` / able to use verify.; verify. green (collector 200,
admin 200 from a staff IP, passport 200/404/404, images 200, `/storage` 404); migrations 120; fingerprints
FP_QR `a920dc1c…` + cert/auth/own + is_production 0,0 recorded as baseline. NO-GO if verify. not fully
functional for both audiences.

**Step 1 — retire public :8080** (recreate loopback-only + remove firewall rules). GATE: `curl
http://195.26.255.80:8080/...` now refused/unreachable (connection refused or firewall drop); verify. still
200 (collector) / 200 (admin staff-IP) / passport 200/404; loopback `127.0.0.1:8080/admin/login` still 200
(deploy health intact); smsrocket unaffected; fingerprints + is_production unchanged. NO-GO/rollback if
verify. degraded or the loopback health check breaks.

**Step 2 — enforce secure cookies** (`SESSION_SECURE_COOKIE=true` + `config:clear`). GATE: collector login
over verify. completes with a Secure session cookie; admin login over verify. (staff IP) completes; no
plain-HTTP login path exists (http→https 308); Set-Cookie carries `secure` on every response; fingerprints +
migrations + is_production unchanged. NO-GO/rollback (unset + config:clear) if any login regresses.

**Bake, then finalize (separate, later):** after a stable bake, optionally `git stash drop stash@{0}`,
remove `APP_BIND_PORT`/loopback bind if desired, and hard-remove the preview code. Not part of this plan's
execution.

**AUDIT ONLY — nothing executed. Awaiting ChatGPT review + an explicit GO before any Phase B step.**

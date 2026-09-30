# SCA-PRODUCTION-CUTOVER — Phase 2C.1 — Waiting-for-DNS Readiness Audit (READ-ONLY)

**Date:** 2026-09-30
**Application baseline:** `c568331` (unchanged). **No changes made — reads only.**
**New intended SCA hostname:** `verify.secondchanceauthenticators.com` (apex + `www` stay on the live Shopify store).
**Current blocker:** the GoDaddy `verify` A record cannot be saved yet (domain-protection verification needs the
client's code). DNS / public ACME / public TLS remain BLOCKED pending client availability.

**Headline verdict: the application is essentially host-agnostic and READY for the `verify.` subdomain with NO code
changes.** All public URLs are request-derived (host from `Host`, scheme from the trusted-proxy `X-Forwarded-Proto`),
there is no global scheme/root forcing, no hard-coded host in production code, no queued URL generation, and QR/cert
identity is host-independent by design. The only genuine blocker is the external DNS record itself.

---

## 1. Minimal Caddy diff (apex/www → `verify.` only)

Change the site label from the apex to the subdomain and **delete the `www` block entirely** (no www handling is
needed for the SCA app; `www` stays on Shopify). The body is unchanged for pre-DNS; at the actual cutover the single
`tls internal` line is removed so Caddy issues a public Let's Encrypt cert for `verify.`.

```diff
-secondchanceauthenticators.com {
-	tls internal
+verify.secondchanceauthenticators.com {
+	# tls internal   ← keep while pre-DNS; DELETE this line at cutover for public auto-TLS (LE)
 	@public path /p/* /collector /collector/*
 	handle @public { reverse_proxy kr-app:80 }
 	@admin path /admin /admin/*
 	handle @admin {
 		@staff remote_ip 103.225.137.242 103.200.35.2
 		handle @staff { reverse_proxy kr-app:80 }
 		respond "Forbidden" 403
 	}
 	handle { respond "Not found" 404 }
 }
-
-www.secondchanceauthenticators.com {
-	tls internal
-	redir https://secondchanceauthenticators.com{uri} permanent
-}
```

The `smsrocket.io { reverse_proxy app:80 }` block and the global `{ email … }` block stay **byte-for-byte
unchanged**. `sca_edge`, the sr-caddy compose `networks:[internal, sca_edge]`, and `TRUSTED_PROXIES=172.20.0.0/24`
all carry over untouched.

## 2. `verify.` Caddy policy (verified against the current block)

- `/p/*` → kr-app (public passport). ✅
- `/collector` + `/collector/*` → kr-app (public collector portal). ✅
- `/admin` + `/admin/*` → only `103.225.137.242` + `103.200.35.2` (Caddy `remote_ip` on the real client IP), else
  403. ✅ (`APP_ADMIN_PATH=admin`, so `/admin` is the correct admin prefix.)
- Everything else — installer (`/install*`), web-forms, API, broadcasting, sanctum, cache, root `/`, `/up`, and
  `/sca/*` (Shopify/OAuth/webhook) — falls to `handle { respond "Not found" 404 }`, i.e. **default-deny**. ✅
- **No `www` handling for the SCA app** (removed). ✅
- **Forward-looking note (not a 2C item):** when Shopify OAuth is activated (`SHOPIFY-CONNECT-009`, deferred), the
  callback/webhook lives under `/sca/*`, which this policy denies. That phase must add an explicit allow for the exact
  Shopify callback/webhook paths; it is correctly denied now.

## 3. Hard-coded reference audit + classification

A full sweep for `secondchanceauthenticators`, `195.26.255.80`, `:8080` across non-vendor PHP/Blade found **7
occurrences, all in `tests/`** — **zero in production code**:

| Location | Classification |
|---|---|
| `tests/…/TrustedProxyReadinessTest.php` (`DOMAIN` const, `:8080` pilot-compat test) | **test-only** — asserts the trust boundary; unaffected by hostname. |
| `tests/…/CertificationWorkflowTest.php:199` (host list incl. `195.26.255.80`/`8080`) | **test-only** — asserts the passport/token leaks no host. |
| `tests/…/PublicPassportPilotTest.php:187-188` (asserts NOT contains `195.26.255.80`/`:8080`) | **test-only, intentionally historical** — a guard that the passport never embeds the pilot host; still valid. |

**Nothing must change in production code for the hostname.** (The `195.26.255.80:8080` in `app/.env` `APP_URL` is
config, addressed in §4.)

## 4. Effect of the later HTTPS-env values (and misbehavior risks)

| Key | What it does today | Under `verify.` | When to set |
|---|---|---|---|
| `APP_URL=https://verify.…` | `config('app.url')`; only the **fallback** root for URLs generated **outside** a request (CLI/queue). Live web URLs are request-derived, so APP_URL is largely cosmetic while serving. | Correct fallback; harmless. No code misbehaves. | Cutover (separate later gate). Safe to set once `verify.` HTTPS is healthy. |
| `PUBLIC_QR_BASE_URL=https://verify.…` | **Not read by any code** — appears only in a config comment. Setting it has **zero runtime effect** today. | No effect until a future printable-QR feature consumes it. | Only meaningful when the (deferred) printable-QR artifact is built; that feature should read it. |
| `SESSION_SECURE_COOKIE=true` | `config('session.secure')`; marks the session cookie `Secure` (HTTPS-only). Currently unset → cookie not Secure → works over the `:8080` plain-HTTP pilot. | Correct under HTTPS. **Risk:** if set `true` while the `:8080` plain-HTTP path is still used for login, the session cookie won't be sent over HTTP → `:8080` login breaks. | **Only after** HTTPS `verify.` is the interactive login path (i.e. `:8080` login retired/unused). Not in 2C. |
| `SCA_PUBLIC_PREVIEW=0` | `config('sca-passport.preview')` → removes the "development preview" label on the public passport page (`PassportController`). | Correct for production. No misbehavior. | Cutover, once `verify.` is the real destination. (Separate from the admin `SCA_PREVIEW_BANNER`, a different var.) |

No code behaves **incorrectly** under the subdomain for any of these; the only real hazard is the **ordering** of
`SESSION_SECURE_COOKIE=true` vs. `:8080` login (documented above).

## 5. Session / cookie / `SESSION_DOMAIN`

`config/session.php`: `'domain' => env('SESSION_DOMAIN', null)`, `'secure' => env('SESSION_SECURE_COOKIE')` (both
unset), `'same_site' => 'lax'`, `'path' => '/'`, `SESSION_DRIVER=file`.

- **No `SESSION_DOMAIN` change is required or wanted.** With `domain=null` the cookie is scoped to the exact request
  host (`verify.secondchanceauthenticators.com`). **Do NOT set `SESSION_DOMAIN=.secondchanceauthenticators.com`** — a
  dot-domain would scope SCA session/CSRF cookies to the apex and *all* subdomains, i.e. share them with the Shopify
  storefront — an isolation/security regression. Host-scoped (null) is exactly right for a single-subdomain app.
- `same_site=lax` is correct: the collector portal is same-site (login/forms/passport all on `verify.`); no
  cross-site cookie flow is needed (Shopify OAuth is deferred and would be handled separately).

## 6. CSRF / redirects / login-logout / claim / transfer / password-reset / passport & QR links under `verify.`

All host-derived; all correct under `verify.` behind the trusted proxy:
- **CSRF** — token cookie + session are host-scoped to `verify.`; `same_site=lax` form POSTs are same-site. ✅
- **Redirects / login / logout** — Krayin admin + collector auth use relative `route()`/`redirect()->route()` →
  host-derived. No forced scheme/host. ✅ (No global HTTPS-redirect middleware exists; Caddy terminates TLS.)
- **Claim invitation round-trip** — `GrantClaimController`/`ClaimController` use `route('collector.claim.*')` /
  `route('collector.collection.index')` (relative, host-derived). No emailed absolute invitation URL (claim is
  Shopify-sale-link driven; that integration is deferred). ✅
- **Transfer acceptance** — in-app via the collector portal; no absolute-URL/email generation found. ✅
- **Password-reset URL** — `CollectorResetPassword` builds `url(route('collector.password.reset', …, false))`
  **synchronously** (`QUEUE_CONNECTION=sync`; the notification does **not** implement `ShouldQueue` — none in SCA do),
  so it uses the **request root** → `https://verify.…/collector/reset-password/{token}?email=…`. Correct under
  `verify.` with **no APP_URL dependency**. (Delivery is still `MAIL_MAILER=log` → the link is correct but not
  emailed until SMTP is configured — deferred, not a hostname issue.) ✅
- **Certification / passport links** — passport route `/{path}/{token}` has **no host constraint**;
  `PassportPresenter` builds **no URLs** (pure data). Collector "view passport" does
  `redirect()->route('sca.passport.show', …)` (host-derived). ✅
- **QR URL generation** — the **certificate PDF embeds no URL/host** (it prints the opaque `cert_token` and says
  "verify … using the certification identity token", host-independent); the admin item view states the QR value is
  "the permanent, host-independent SCA identity token — not a URL" and the scannable image/URL is a deferred feature.
  So there is no live QR-URL generation to get wrong. ✅

## 7. QR token host-independence + what `PUBLIC_QR_BASE_URL` affects

- The two permanent tokens are `sca_qr_identifiers.public_token` (`Token::opaque()`, 32-hex), **immutable**
  (`trg_sca_qr_identifiers_no_update` / `_no_delete`), and contain **no host/IP/port** — confirmed in the migration
  comment, the admin view copy, and the cert template. The destination URL is derived from `{host}/p/{token}` at
  resolution time; changing the host changes only the *derived* URL, never the token.
- **`PUBLIC_QR_BASE_URL` affects nothing today** — it is not referenced by any code (comment only). It becomes
  meaningful only when the **deferred printable-QR artifact** is built; that feature should encode
  `https://verify.secondchanceauthenticators.com/p/{token}`. Until then it is inert.

## 8. Decision memo — the two `is_production=0` QR rows (do NOT mutate)

**Facts.** Both rows are pilot markers: `id=1` (item 1, token `bee93d2b…`) and `id=2` (item 3, token `10c739b7…`),
each `is_production=0`, each with an `activated` lifecycle event, and each currently resolving to a live passport
(`/p/{token}` → 200). `is_production` is **written once at identity creation and read by no application logic** (it is
purely a "safe to print permanently?" marker; the migration notes "staging tokens never printed"). The rows are
**immutable** (no_update trigger), so `is_production` **cannot be flipped** in place.

**Options before physical QR printing (a governed, human decision — deferred to the printing phase, not 2C):**
1. **Adopt the existing pilot tokens as permanent.** They are already permanent/immutable/host-independent and
   resolve correctly; `is_production` was only a "don't print during pilot" flag. Simplest; requires a governance
   decision that these two pilot items are the real items and their current tokens are the ones to print. No data
   change (the flag stays 0 and is cosmetic).
2. **Issue fresh production QRs.** Via the governed `QrService` reissue (a staff action) create+activate a new
   `is_production=true` identity per item; this preserves both tokens/histories but **revokes the old active QR**, so
   the old pilot token would stop resolving as the active passport. Only choose this if the pilot tokens were ever
   physically distributed and must be retired (they were not — is_production=0).

**Recommendation:** defer to the printable-QR phase (post-HTTPS). Given the tokens are unprinted pilots that already
work, Option 1 (adopt) is the low-risk default, decided explicitly by the client/governance. **Do not mutate or
reconstruct these rows now.**

## 9. Post-DNS verification checklist (for the eventual cutover)

Run in order; STOP + roll back on any failure.
1. **DNS** — `dig +short verify.secondchanceauthenticators.com @8.8.8.8` and `@1.1.1.1` → `195.26.255.80`
   (low TTL); apex + `www` still Shopify (`23.227.38.32` / `shops.myshopify.com`) — **unchanged**.
2. **Public ACME** — apply the Caddy diff (remove `tls internal`), `caddy validate`, `docker compose up -d
   --force-recreate caddy` in a quiet window; watch the Caddy log for successful LE issuance for `verify.`.
3. **Certificate validation** — from an external client, **without `--resolve` and without `-k`**:
   `curl -v https://verify.secondchanceauthenticators.com/collector/login` → valid publicly-trusted chain, CN/SAN =
   `verify.secondchanceauthenticators.com`, not expired.
4. **Passport** — `https://verify.…/p/{valid-token}` → 200; **bogus token** → constant-shape 404 (SCA-038).
5. **Collector** — `/collector/login` → 200; a full login → My Collection round-trip.
6. **Admin allowlist** — `/admin*` from a non-staff IP → 403; from an actual staff IP → reaches the app (do not
   weaken the allowlist to test).
7. **Blocked routes** — `/install`, `/install/api/run-migration`, `/sca/oauth/callback`, `/api/user`, `/`, `/up`
   → 404.
8. **Forwarded client IP / HTTPS** — confirm Laravel sees `https` + the real public client IP through Caddy
   (`172.20.0.2` peer trusted); generated form actions are absolute `https://verify.…`.
9. **Shopify apex unchanged** — `https://secondchanceauthenticators.com/` still 200 `powered-by: Shopify`.
10. **SMSRocket unchanged** — `https://smsrocket.io/` → 200 over its existing public cert.
11. **Non-mutation** — SCA counts + QR fp `6bb119ee…` unchanged; DOCKER-USER byte-identical; MariaDB private; `:8080`
    fallback still 200.

## 10. Rollback procedure for the `verify.` cutover

If any gate in §9 fails: restore `/opt/smsrocket-stack/Caddyfile` to the pre-cutover 2B content (re-add `tls
internal` to the `verify.` block, or restore `sha256 00f16788…` if the apex form is preferred); `caddy validate`;
`docker compose up -d --force-recreate caddy`; verify smsrocket 200 and `:8080` 200. DNS can be left pointing at
`195.26.255.80` (harmless with `tls internal`, SNI-only) or reverted by the client. `TRUSTED_PROXIES`, `sca_edge`,
DOCKER-USER, and all `.env` values remain untouched. No DB restore is ever needed (no provenance mutation). If public
LE issuance partially succeeded, the cert sits harmlessly in the preserved `smsrocket-stack_caddy_data` volume.

## 11. Baseline reconfirm + zero mutation (this task)

`c568331`, tree CLEAN; Caddyfile `sha256 00f16788…` still `tls internal`; `sca_edge` (sr-caddy + kr-app) intact;
`TRUSTED_PROXIES=172.20.0.0/24`; `APP_URL=http://195.26.255.80:8080` (unchanged); SCA counts `qr=2 certs=3
migrations=118`; **QR fp `6bb119ee0b598222bfec58bb80c7a4cb` unchanged**; smsrocket.io HTTPS 200; `:8080` `/up` 200;
MariaDB private. **No DNS/Caddy/.env/network/firewall/QR/data/cert change was made.**

## 12. Readiness verdict + genuine blockers

**READY.** No application or configuration defect blocks the `verify.` cutover; the app is host-agnostic and the edge
is already validated. The **only genuine blocker is external**: the client must save the GoDaddy `verify` A record
(needs their domain-protection verification code). Nothing on this host can proceed until then, and public ACME must
**not** be attempted before `verify.` resolves to `195.26.255.80`.

**Decisions/sequencing to line up while waiting (human/governance — no code needed):**
- Confirm the subdomain label (`verify.` assumed) and the low TTL value.
- Sequence `SESSION_SECURE_COOKIE=true` **after** `:8080` login is retired/unused (else it breaks `:8080` login).
- `is_production` QR decision (§8) — defer to the printable-QR phase; recommend "adopt existing pilot tokens."
- SMTP (password-reset delivery) and off-site backup remain separately deferred; neither blocks 2C.

**No implementation performed. Phase 2C not activated. No ACME requested. Phase-2B edge untouched. STOP.**

# SCA — Transactional Email Configuration Readiness (READ-ONLY)

**The minimum secure email configuration needed to launch verified-buyer ownership claiming.** Read-only
inspection at prod `4faf84d` and release candidate `4bd88d2`. **KEY FINDING: the Postmark *API*
transport is NOT installed (`symfony/postmark-mailer` is only a composer suggestion), so `MAIL_MAILER=postmark`
would fail at runtime. The config-only path is Postmark via *SMTP* (works with the already-installed
`symfony/mailer`); the API path needs a dependency added to the release (a dev task).** No account/DNS/
email/config change made; no secrets requested or shown. 2026-10-29. **STOP.**

## [1] Current Laravel mail configuration (no secrets)
- Prod `app/.env`: `MAIL_MAILER=log`, `MAIL_FROM_ADDRESS=no-reply@localhost` (placeholder),
  `MAIL_FROM_NAME=SCA`. **No** `MAIL_HOST/PORT/USERNAME/PASSWORD/ENCRYPTION` and **no** `POSTMARK_TOKEN`.
- `config/mail.php` defines mailers `smtp, ses, mailgun, postmark, sendmail, log, array, failover,
  roundrobin`; default = `env('MAIL_MAILER','smtp')`. `config/services.php` has
  `postmark.token => env('POSTMARK_TOKEN')`.

## [2] Transports actually usable in the release (`4bd88d2`)
- Installed: `symfony/mailer` (base) → **SMTP**, sendmail, log, array work out of the box.
- **NOT installed:** `symfony/postmark-mailer`, `symfony/http-client`, and the SES/Mailgun/Resend API
  packages (they appear only as *suggestions* in `composer.lock`, not in `composer.json`/vendor). So the
  **API** transports (`postmark`, `ses`, `mailgun`, `resend`) are NOT functional as shipped.
- The collector email-verification + password-reset notifications use `via(['mail'])` → the **default
  mailer** (whatever `MAIL_MAILER` resolves to).

## [4] Can Postmark be used with existing support, or does it need a dependency?
- **Postmark via SMTP — YES, config-only (recommended minimum):** set `MAIL_MAILER=smtp`,
  `MAIL_HOST=smtp.postmarkapp.com`, `MAIL_PORT=587`, `MAIL_ENCRYPTION=tls`, and `MAIL_USERNAME` =
  `MAIL_PASSWORD` = the Postmark **Server API token** (Postmark's SMTP uses the server token as both).
  Uses the installed `symfony/mailer` SMTP transport — **no code/vendor change**.
- **Postmark via the API transport — requires a dependency:** `MAIL_MAILER=postmark` + `POSTMARK_TOKEN`
  needs `composer require symfony/postmark-mailer symfony/http-client`, which is a **code/vendor change
  to the release** (not in `4bd88d2`) + re-test + redeploy. Only choose this if the owner prefers the
  API over SMTP.
> Either way the sender signature + DNS (below) are identical; the SMTP path is the shortest and needs
> no change to the release.

## [3] Sender identity, templates, verification links, expiry, reset flow
- **Sender:** `MAIL_FROM_ADDRESS` must change from the `no-reply@localhost` placeholder to a **verified**
  address on `secondchanceauthenticators.com` (e.g. `no-reply@secondchanceauthenticators.com`);
  `MAIL_FROM_NAME` e.g. "Second Chance Authenticators".
- **Email-verification challenge** (`CollectorEmailVerification`): subject "Verify your Second Chance
  Authenticators email"; link ORIGIN pinned to `config('app.url')` (host-header hardened, NOT the request
  host); carries only the opaque one-time token + the collector email (no password/id/order). Token is
  **single-use, SHA-256-hashed at rest (raw never stored), 60-minute TTL** (`TTL_MINUTES=60`).
- **Password reset** (`CollectorResetPassword`): broker token, URL origin also from `config('app.url')`;
  single-use; standard broker expiry. (The hardening tests assert the origin tracks `config('app.url')`.)
- **`config('app.url')` in prod must be `https://verify.secondchanceauthenticators.com`** so both links
  resolve to the real site. (Confirm prod `APP_URL`.)

## [5] Sender-domain verification (SPF / DKIM / DNS at GoDaddy)
DNS authority is **GoDaddy/Secureserver** (not Namecheap). Required at the provider + DNS:
- **Verified sender signature** for `no-reply@secondchanceauthenticators.com` in the provider.
- **DKIM:** publish the provider's DKIM record. A Postmark `pm` DKIM selector is already present on the
  apex — confirm it matches the specific Postmark **server/account** used (re-verify in the Postmark
  dashboard); if it is stale/for a different account, update it.
- **Return-Path / bounce CNAME:** Postmark's `pm-bounces` (custom Return-Path) CNAME for alignment.
- **SPF:** currently **absent** — add a `v=spf1 … -all` that includes the provider's sending host.
- **DMARC:** already present (`p=quarantine`). DMARC can pass on DKIM alignment alone, so a verified DKIM
  is the hard requirement; SPF is strongly recommended.
All DNS changes are manual at GoDaddy; none are in this repo.

## [6] Configuration values the owner must provide (no secrets in this report)
1. A transactional-email **provider account** (Postmark recommended) + a **Server API token** *(secret —
   store directly in prod `app/.env`, never in governance/logs/chat)*.
2. A **verified sender** address on `secondchanceauthenticators.com`.
3. **DNS records** at GoDaddy: SPF (add), DKIM (confirm/publish the provider's selector), Return-Path/
   bounce CNAME.
4. An **SCA-owned test inbox** (owner-controlled) for the delivery smoke test — never a customer address.
5. Decision: **SMTP** (config-only, recommended) vs **API** (needs the dependency added to the release).

## [7] Setup procedure (owner + developer; separately authorized — not performed here)
1. *(Owner)* create/confirm the Postmark account; create a Server; copy its Server API token.
2. *(Owner)* add a verified sender signature for `no-reply@secondchanceauthenticators.com`.
3. *(Owner, GoDaddy DNS)* publish the DKIM record (per the Postmark server), the Return-Path/bounce
   CNAME, and add an SPF record; keep DMARC.
4. *(Dev)* if the **API** transport is chosen, add `symfony/postmark-mailer` + `symfony/http-client` to
   the release and re-test; if **SMTP** is chosen, no code change.
5. *(Dev, at deploy — separate auth)* set in prod `app/.env`: either SMTP vars (host/port/tls + token as
   username+password) or `MAIL_MAILER=postmark` + `POSTMARK_TOKEN`; set `MAIL_FROM_ADDRESS`/`_NAME` to
   the verified sender; ensure `APP_URL=https://verify.secondchanceauthenticators.com`; `config:clear`.

## [8] Non-production email delivery test (before enabling production claims)
On a **disposable/staging** environment (not prod) with the provider creds and an SCA-owned inbox:
create a test collector, trigger `POST /collector/email/verify/request`, confirm the email arrives,
click the 60-minute link, assert `email_verified_at` is stamped; also exercise the password-reset email.
This proves real delivery + the 60-min single-use token end-to-end without touching prod.

## [9] Production smoke tests, rollback conditions, fail-closed checks
- **Smoke (post-config):** send ONE verification email to the SCA-owned inbox; confirm receipt + link
  resolves to `https://verify.secondchanceauthenticators.com/collector/email/verify/<token>…`; confirm
  `email_verified_at` stamped; then one end-to-end verified-buyer claim on a real paid order + pair.
- **Rollback conditions:** if emails don't deliver, land in spam, or DKIM/SPF/DMARC fail → set
  `MAIL_MAILER=log` (or disable the claim launch) and do NOT open customer claims; the code change is
  env-only (no DB).
- **Fail-closed verification (must hold before AND after):** with email misconfigured/unavailable,
  `email_verified_at` is never set → `buyerIsVerified` returns false → `BUYER_VERIFICATION_REQUIRED`, no
  ownership. Confirm a buyer **cannot** claim until their email is genuinely verified and matches the
  trusted order email. No configuration step may set `email_verified_at` without a real confirmed link.

## [10] No Shopify store modification
Transactional email is entirely independent of Shopify: it touches only Laravel mail config + DNS at the
email provider/domain. No Shopify product/order/inventory/customer/webhook/OAuth/theme/setting change,
no Shopify API call, no CLI. The `read_orders`/`read_products` scopes are unaffected.

## Outstanding owner actions (summary)
1. Choose SMTP (config-only) **or** API (release needs `symfony/postmark-mailer` added).
2. Provide: provider account + Server token (secret, into prod `.env` only), verified sender, SCA-owned
   test inbox.
3. GoDaddy DNS: add SPF, confirm/publish DKIM (match the Postmark server), add Return-Path CNAME.
4. Confirm prod `APP_URL=https://verify.secondchanceauthenticators.com`.
5. Authorize the non-prod delivery test, then (separately) the migrate-before-code deploy of `4bd88d2`.

**STOP — read-only readiness delivered. Minimum secure path: Postmark **SMTP** (config-only; no release
change) OR the Postmark API transport (adds `symfony/postmark-mailer` to the release). Required: verified
sender on secondchanceauthenticators.com + SPF/DKIM/Return-Path at GoDaddy + `APP_URL` = the prod site.
Email stays fail-closed (no provider ⇒ no `email_verified_at` ⇒ no claim); no Shopify change involved.
No account/DNS/email/config/deploy change was made; no secrets requested or exposed.**

# SCA — Ownership Passport Email-Delivery Readiness (READ-ONLY)

**VERDICT: BLOCKED — operational email delivery is not yet configured, though the application/code side is READY FOR CONFIGURATION.** Read-only assessment at prod `cb8a8c3` (R0+R0b+R0c candidate `539cd1f`, combined regression 77/77). No mail/DNS/DB change, no test email sent, no credentials printed. 2026-10-29. **STOP.**

Exact missing requirements are in [11]. The R0c collector email-verification gate cannot function in production until these are satisfied.

## [1] Current mail configuration (no secrets exposed)
- `app/.env` contains only `MAIL_MAILER`, `MAIL_FROM_ADDRESS`, `MAIL_FROM_NAME`. **No** `MAIL_HOST`/`MAIL_PORT`/`MAIL_USERNAME`/`MAIL_PASSWORD`/`MAIL_ENCRYPTION`/`MAIL_SCHEME` keys exist.
- Effective config in the running app: `mail.default = log`, transport `log`, `from.address = no-reply@localhost` (framework placeholder), `from.name = SCA`, `app.url = https://verify.secondchanceauthenticators.com`.
- **No real mail is delivered** (log transport); `from_address` is a non-deliverable placeholder.

## [2] Provider / verified sender / existing service
- All standard mailers are *available* in `config/mail.php` (`smtp, ses, postmark, resend, sendmail, log, array, failover, roundrobin, mailgun`), but **none is configured**: `services.postmark.token`, `services.ses.key`, and `services.mailgun.secret` are all **unset**. No provider API token or SMTP credentials are present.
- DNS (read-only `dig`; host resolver was intermittently timing out on `127.0.0.53`, so DKIM specifics need provider-dashboard confirmation): `secondchanceauthenticators.com` has **DMARC** (`v=DMARC1; p=quarantine; rua=mailto:dmarc_rua@onsecureserver.net`) and shows **DKIM selectors `pm` (Postmark's selector) and `s1`** present; **SPF is ABSENT** on both the apex and the `verify.` subdomain. The `rua=onsecureserver.net` + the Postmark `pm` selector indicate **DNS is at GoDaddy/Secureserver** (consistent with the Postmark preflight; CLAUDE.md's "Namecheap" is wrong) and that **Postmark was partially provisioned at the DNS layer** at some point.

## [3] Appropriate sender address/domain
- Use a verified address on **`secondchanceauthenticators.com`** (the apex that carries DMARC + the `pm` DKIM selector), e.g. `no-reply@secondchanceauthenticators.com` (or a `verify@`/`notifications@` on that domain). The current `no-reply@localhost` MUST be replaced with the verified sender. Do **not** invent a provider account or credentials — the sender signature must be verified in the chosen provider.

## [4] Notification uses Laravel Mail correctly — YES
`CollectorEmailVerification` (R0c): `via() = ['mail']`, `toMail()` returns a `MailMessage` with `->subject/->action`, and the confirm link ORIGIN is pinned to `config('app.url')` (host-header hardened, like the password-reset notification). `CollectorAccount` is `Notifiable` and has the `email` attribute, so `routeNotificationForMail` resolves correctly. No code change needed; it rides whatever transport is configured.

## [5] SMTP vs an approved transactional service
**Raw SMTP is NOT required.** The app already supports the `postmark` mailer, so delivery can use **Postmark** (a managed transactional service: API token, no SMTP credentials) by setting `MAIL_MAILER=postmark` + `POSTMARK_TOKEN`. Given the `pm` DKIM selector is already published, Postmark is the natural choice; `ses`/`resend`/`mailgun`/SMTP are all equally supported if preferred. The verification volume is tiny (one email per buyer claim), so any provider's lowest tier suffices.

## [6] SPF / DKIM / DMARC (verifiable read-only; NO DNS change made)
- **DMARC:** present on the apex (`p=quarantine`). ✓
- **DKIM:** a `pm` (Postmark) and `s1` selector appear present on the apex — **verify the active provider's DKIM is authenticated in that provider's dashboard** (the published records must match the provider's server).
- **SPF:** **MISSING** on both the apex and `verify.` subdomain — a `v=spf1` record including the chosen provider (e.g. `include:spf.mtasts...`/Postmark's `spf.mtasts`? → Postmark uses the Return-Path/`pm-bounces` CNAME for SPF alignment) should be added. DMARC can pass on **DKIM alignment alone**, so a correctly-verified DKIM is the hard requirement; SPF is strongly recommended for deliverability.
- All DNS changes are manual at **GoDaddy/Secureserver** (not in this repo, not in scope here).

## [7] Reliable delivery, bounce handling, safe error reporting
- **Deliverability:** verified sender signature at the provider + DKIM authenticated + (recommended) SPF; `from@secondchanceauthenticators.com` aligned with DMARC.
- **Bounce/complaint handling:** use the provider's bounce/complaint dashboard/webhooks (Postmark provides both); no bounce ingestion is built in SCA (not required for a one-shot verification link, but monitor the provider).
- **Safe error reporting (already hardened):** `ForgotPasswordController` and the R0c `EmailVerificationController`/`CollectorEmailVerificationService` log only the exception class on a transport failure — never the email, token, or provider response — and a transport failure never 500s or becomes an enumeration oracle. Tokens are SHA-256-hashed at rest. ✓

## [8] Minimal deployment configuration + controlled smoke-test plan (NOT executed)
**Config (separately authorized; applied to `app/.env`, not this repo):**
```
MAIL_MAILER=postmark
POSTMARK_TOKEN=<provider server token>        # from the Postmark account (not invented)
MAIL_FROM_ADDRESS=no-reply@secondchanceauthenticators.com   # verified sender signature
MAIL_FROM_NAME="Second Chance Authenticators"
```
Then `php artisan config:clear` + `apachectl graceful` (no Docker recreate). Keep `verify.` as `app.url` (link origin) — the sender domain is the apex.

**Controlled real-email smoke test (one recipient, explicit approval):**
1. Intended test recipient: an **SCA-operated inbox the owner controls** (e.g. the owner's own address) — never a customer address. Choose it at test time; do not hard-code.
2. Create a disposable collector with that email, trigger `POST /collector/email/verify/request`, confirm the email arrives, click the confirm link, assert `email_verified_at` is set.
3. Then a presale-claim happy-path with a sale link whose trusted `order_email` matches that verified address.
Permissions required: Postmark account access (owner), GoDaddy/Secureserver DNS access (owner), and prod `app/.env` write + graceful reload (deploy authorization). This smoke test is a **separately authorized** step — not performed here (no test email sent).

## [9] Production order-email backfill scope (read-only)
- Prod `sca_shopify_sale_links` currently holds **exactly 1 row**, state **`revoked_refund`** (`sce_presale`) — a refunded sale that can never be claimed. The `order_email` column is not yet in prod (R0c unmerged).
- Therefore the backfill universe is **1 row, with 0 claim-eligible rows** needing a usable order email. New orders will capture `order_email` going forward (R0c propagation).

## [10] Can a zero-(eligible-)row backfill be skipped? — YES
With **0 eligible sale links** lacking an order email, the production backfill is **not required for launch correctness** and can be safely skipped. The single `revoked_refund` row is inert (unclaimable); leaving its `order_email` null is harmless. If more legacy eligible orders appear later, run the dry-run first, then `--apply` (idempotent, NULL-only).

## [11] Remaining manual provider / domain / credential setup (the BLOCKERS)
1. **Transactional provider account + API token** — create/confirm a Postmark (or SES/Resend/Mailgun) account and a **server/API token**; store as `POSTMARK_TOKEN` in prod `app/.env`. *(Owner; not in repo.)*
2. **Verified sender signature** for `no-reply@secondchanceauthenticators.com` in that provider. *(Owner.)*
3. **DNS at GoDaddy/Secureserver:** add **SPF** (`v=spf1 … -all` including the provider), confirm the provider's **DKIM** (the `pm` selector must match the active Postmark server) and the **Return-Path/bounce** CNAME; DMARC already present. *(Owner; manual.)*
4. **Prod `app/.env`** change to `MAIL_MAILER=postmark` + token + verified `MAIL_FROM_ADDRESS`, then `config:clear` + graceful reload. *(Deploy authorization.)*
5. **Controlled smoke test** per [8] to an SCA-owned inbox.

Until 1–5 are done, `email_verified_at` cannot be set in production, so the R0c verified-buyer gate remains unsatisfiable and customer claims cannot launch.

**STOP — READ-ONLY. VERDICT: BLOCKED pending operational email delivery (provider token + verified sender + SPF/DKIM confirmation + prod MAIL config). App/code is ready; the order-email backfill is effectively a no-op (0 eligible rows) and safely skippable. No mail/DNS/DB/deploy change, no email sent, no credentials printed. RELEASE GATE unchanged: R0+R0b+R0c stay blocked on operational SMTP/transactional delivery. Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification.**

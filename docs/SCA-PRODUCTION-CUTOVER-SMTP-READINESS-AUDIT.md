# SCA-PRODUCTION-CUTOVER — SMTP / Password-Recovery Readiness Audit (READ-ONLY)

**Date:** 2026-09-30
**Baseline:** `c568331` (unchanged). **No changes — reads only. No credentials selected, no email sent, no DNS/.env/mail change.**
**Blocker context:** production is gated on the client's GoDaddy verification for the `verify.` A record; SMTP setup
shares that same DNS-access dependency (SPF/DKIM), plus a provider account.

**Headline:** the application is **already code-complete for transactional email** — the collector password-reset
flow, the dedicated `sca_collectors` broker, and the `smtp` mailer are all in place. Activation needs only (a) a
provider account + SMTP credentials, (b) SPF/DKIM DNS records on a **dedicated SCA sending subdomain** (never the
Shopify apex), and (c) an `.env` `MAIL_*` switch. **No code change is required.** One **pre-activation hardening item**
(sync-send robustness) is flagged separately below.

---

## 1. Current state

- `config/mail.php`: `default=env('MAIL_MAILER','smtp')`; a full `smtp` mailer (`MAIL_HOST/PORT/ENCRYPTION/USERNAME/
  PASSWORD`) plus `ses`/`mailgun`/`postmark`/`sendmail`/`log`/`array`/`failover` transports; `from` from
  `MAIL_FROM_ADDRESS`/`MAIL_FROM_NAME`. `config/services.php` already reads `POSTMARK_TOKEN`, `MAILGUN_*`,
  `AWS_ACCESS_KEY_ID/SECRET/REGION` for the dedicated transports.
- `.env` today: **`MAIL_MAILER=log`**, `MAIL_FROM_ADDRESS=no-reply@localhost` (placeholder), `MAIL_FROM_NAME=SCA`,
  `QUEUE_CONNECTION=sync`. So reset emails are **written to the log, not delivered** — the only reason recovery is
  non-functional. Not a code defect.
- Domain mail DNS for `secondchanceauthenticators.com` (dig @8.8.8.8/1.1.1.1): **SPF/TXT apex = none; MX = none;
  DKIM = none** at common selectors (shopify/google/default/k1/s1/s2/selector1-2/mail); **DMARC exists**:
  `v=DMARC1; p=quarantine; adkim=r; aspf=r; rua=mailto:dmarc_rua@onsecureserver.net` (GoDaddy-managed, relaxed
  alignment). ⇒ **Any mail from this org fails DMARC unless it passes aligned SPF or DKIM**; with `p=quarantine`,
  unauthenticated SCA mail would be spam-filed. So DKIM/SPF DNS is mandatory before real sending.
- Co-tenant `sr-mail` (Postfix): `ALLOWED_SENDER_DOMAINS=smsrocket.io` only, `myhostname=mail.smsrocket.io`, DKIM
  auto-generated for smsrocket.io, internal network only. **SCA must not and cannot route through it** (it rejects
  non-smsrocket senders). SCA uses an independent provider — full isolation, no shared config/volume/network.

## 2. Password-reset flow — end-to-end audit (secure; NO defect found)

1. **Request:** `GET /collector/forgot-password` (guest form) → `POST /collector/forgot-password`
   (`throttle:6,1`). `ForgotPasswordController::sendLink` validates `email` (`email:rfc`, ≤255), lowercases, calls
   `Password::broker('sca_collectors')->sendResetLink(['email'=>…, 'status'=>'active'])`, and always returns the
   **same generic confirmation** — enumeration-safe. `status=active` means disabled/pseudonymized/unknown addresses
   silently get no link.
2. **Token creation:** the `sca_collectors` broker writes a **hashed** token to `sca_collector_password_resets`
   (separate from the staff `users` broker); `expire=60` min, `throttle=60` s (one email per email address per 60 s).
3. **Email generation:** `CollectorAccount` (`CanResetPassword`+`Notifiable`) overrides
   `sendPasswordResetNotification($token)` → `notify(new CollectorResetPassword($token))`. `toMail` builds
   `url(route('collector.password.reset', ['token','email'], false))` **synchronously** (no `ShouldQueue`;
   `QUEUE_CONNECTION=sync`) → request-derived absolute URL, correct under `verify.`. Body: subject, action link,
   "expires in 60 minutes, single-use" note. No password/id/ownership data. (Today: logged, not sent.)
4. **Reset link:** `GET /collector/reset-password/{token}?email=…` (`token` = `[^/]+`) renders the reset form.
5. **Password update:** `POST /collector/reset-password` (`throttle:6,1`). `ResetPasswordController::reset` validates
   `token`/`email`/`password` (`confirmed`, `min:8`), calls `broker->reset(status=active, …)`; the success callback
   sets **only** `password = Hash::make(...)`, saves, fires `PasswordReset`. No auto sign-in (→ login page).
6. **Token invalidation:** the broker validates the token (hashed at rest, account-bound by email, 60-min expiry,
   **single-use — deleted on success**) and consumes it; invalid/expired/reused/wrong-account/disabled →
   **one generic non-enumerating error**, no password change.

**Boundaries:** the collector broker/guard/provider/table are fully separate from staff `users`; `password` is
`$hidden`; no token or password is ever logged or shown; responses never leak account existence; rate limiting is
layered (route `throttle:6,1` on both POSTs + broker 60-s throttle + 60-min single-use token). **This is a correct,
standard, hardened Laravel reset flow. No application defect.**

## 3. Provider comparison (low-volume pilot) + recommendation

All three below are **SMTP drop-ins** (or a one-line dedicated transport) → **zero code change**, and all support
per-subdomain DKIM so the Shopify apex is never touched.

| Provider | Fit for a low-volume transactional pilot | DNS to add (on a subdomain) | Cost | Notes |
|---|---|---|---|---|
| **Postmark** (recommended) | Best-in-class **transactional** deliverability; separate transactional message stream; detailed per-message logs (45-day) + bounce/spam webhooks. | DKIM TXT selector + a **Return-Path CNAME** (`pm-bounces.<sub>`→pm.mtasv.net) for SPF alignment. | Free 100/mo trial, then ~$15/mo (10k). | Simplest path to reliable password-reset delivery + auditability; SMTP host `smtp.postmarkapp.com`. |
| **Amazon SES** | Very reliable, cheapest, scales; needs an AWS account and a **production-access** (out-of-sandbox) request. | Easy-DKIM (3 CNAMEs) + a **custom MAIL FROM subdomain** (MX + SPF TXT) for SPF alignment. | ~$0.10 / 1k. | Lowest cost; more ops overhead; SMTP host `email-smtp.<region>.amazonaws.com`. |
| **Resend** | Modern, simplest setup, generous free tier; newer track record than Postmark/SES. | DKIM TXT + `send.<sub>` SPF TXT (+ optional DMARC). | Free 3k/mo (100/day). | Good pilot option; SMTP host `smtp.resend.com`. |

**Recommendation:** **Postmark** as the primary — it is transactional-first, gives the strongest deliverability and
the clearest delivery/bounce logs for a security-critical email (password reset), and its DKIM + Return-Path setup is
minimal and subdomain-scoped. **Amazon SES** is the low-cost alternative if AWS ops are acceptable; **Resend** the
simplest if a generous free tier is preferred. The final choice + credentials are the client's (not selected here).

## 4. Sender identity / From / Reply-To (dedicated sender: YES, but on a subdomain)

- **Use a dedicated SCA sender, on a dedicated sending subdomain — NOT the bare apex.** Recommended From:
  `"Second Chance Authenticators" <no-reply@verify.secondchanceauthenticators.com>` (reuses the subdomain already
  being set up), or a dedicated mail subdomain (`mail.` / the provider's suggested sending subdomain) if isolating
  mail reputation from the web host is preferred.
- **Do NOT send From `@secondchanceauthenticators.com` (bare apex)** and **do NOT modify apex SPF/DKIM/MX.** The apex
  is the live Shopify storefront's primary domain; an apex From would require adding apex SPF (interacting with
  Shopify's sending) and edits to the store's primary records. A subdomain From passes the existing org DMARC
  (`aspf=r`/`adkim=r` relaxed alignment) via aligned subdomain SPF/DKIM and never touches Shopify.
- **`support@secondchanceauthenticators.com`:** usable only as a **Reply-To**, and only if the client has a real
  monitored inbox for it — the apex **MX is empty**, so no mailbox receives it today; replies would bounce. Do not
  invent one. Recommendation: transactional From = `no-reply@<sending-subdomain>`; Reply-To = the client's real
  monitored support inbox if they want replies, else omit.
- **`MAIL_FROM_ADDRESS=no-reply@localhost` must change** to the chosen subdomain sender at activation (config, not code).

## 5. SPF / DKIM / DMARC records (on the sending SUBDOMAIN; apex untouched)

Exact strings are provider-supplied; the shape is:
- **DKIM:** the provider's selector record(s) on the subdomain — e.g. `<selector>._domainkey.<sending-subdomain>` (TXT
  or CNAME). This is the primary DMARC-alignment mechanism.
- **SPF / Return-Path:** either an SPF `TXT` on the sending/Return-Path subdomain (`v=spf1 include:<provider> -all`)
  or the provider's bounce/Return-Path CNAME (Postmark) so the envelope-from aligns.
- **DMARC:** the existing org policy (`p=quarantine`, relaxed) is **already compatible** — a subdomain that passes
  aligned SPF **or** DKIM passes DMARC. **No change to the org DMARC is required** (do not weaken it). Optionally the
  client may add SCA's own `rua` for monitoring, but it is not needed.
- **Isolation guarantees:** all records live on the SCA subdomain, so Shopify's apex email and the GoDaddy-managed
  apex DMARC/`rua` are untouched; `sr-mail`/smsrocket DKIM (its own volume, smsrocket.io only) is untouched.

## 6. Laravel mail configuration (drop-in — no code change)

At activation set in `app/.env` (values from the chosen provider; secrets not chosen here):
```
MAIL_MAILER=smtp                 # or 'postmark'/'ses' dedicated transport
MAIL_HOST=<provider smtp host>   # smtp.postmarkapp.com | email-smtp.<region>.amazonaws.com | smtp.resend.com
MAIL_PORT=587
MAIL_ENCRYPTION=tls
MAIL_USERNAME=<provider smtp user/token>
MAIL_PASSWORD=<provider smtp pass/token>     # SECRET
MAIL_FROM_ADDRESS=no-reply@verify.secondchanceauthenticators.com
MAIL_FROM_NAME="Second Chance Authenticators"
```
`config/mail.php`, the `CollectorResetPassword` notification, and the `sca_collectors` broker are already wired; the
deploy uses `config:clear` so `.env` is read fresh (no cache pitfall). Disable provider **open/click tracking** for
this stream so the single-use reset link is never rewritten through a tracking redirector.

## 7. Token expiry / rate limiting (already correct)

60-min single-use hashed token; broker 60-s per-email throttle; route `throttle:6,1` on both forgot- and
reset-password POSTs (and login `6,1`, register `10,1`). Adequate for the pilot; no change needed.

## 8. Logging / privacy

- App: enumeration-safe; **no token/password/PII logged**; generic responses. Good.
- Provider: its logs will hold the recipient address + message (including the reset link). Mitigations: **disable link
  tracking**; rely on the token's 60-min single-use nature (inert after use/expiry); keep the provider's default
  short retention; restrict provider dashboard access. Ensure `MAIL_FROM` is the branded no-reply, not `@localhost`.

## 9. Failure behavior + **PRE-ACTIVATION HARDENING ITEM (reported separately — not a current defect, not fixed)**

- Today (`MAIL_MAILER=log`): the "email" always "succeeds" (written to log); the flow is robust.
- **Latent robustness gap that activates with real SMTP:** `sendResetLink` sends the notification **synchronously**
  (`QUEUE_CONNECTION=sync`, no `ShouldQueue`). If the SMTP provider is unreachable/misconfigured, the transport
  exception would propagate out of `ForgotPasswordController::sendLink` → the user gets a **500 instead of the generic
  success message**, which both harms UX and **breaks the enumeration-safety guarantee** (a 500 vs. the generic 200
  becomes an oracle, and a provider error could even distinguish existing vs. non-existing addresses depending on
  timing). **This is NOT a defect in the current logged configuration** (log can't fail), so it is reported here as a
  **hardening item to implement at/with SMTP activation**, under separate authorization — options: (a) wrap the
  `sendResetLink` call in a try/catch that logs the failure server-side and always returns the generic message, or
  (b) queue the reset notification (`ShouldQueue` + a queue worker) so transport failures never reach the request.
  Option (a) is the smaller change and preserves the current sync/no-worker infra. **Do not implement without a
  separate governed task.**

## 10. What needs DNS access vs. what can be prepared without it

- **Needs the client's GoDaddy DNS access (same blocker as the `verify.` A record):** the sending-subdomain **DKIM**
  record(s), the **SPF/Return-Path** record, and (if SES custom MAIL FROM) an **MX** on the mail subdomain. Real
  sending will be DMARC-quarantined until these exist.
- **Preparable now, no DNS (and no code):** choose the provider; draft the exact `.env` `MAIL_*` block; pre-write the
  DNS record templates for the client to paste; (optionally, and under separate authorization) apply the §9 sync-send
  hardening. Creating the provider account/credentials and sending test mail are external/human steps, excluded here.

## 11. SMTP activation checklist (future — for when DNS access is available)

1. Client creates the provider account; obtains SMTP credentials + the provider's DKIM/Return-Path values.
2. Client adds the **DKIM + SPF/Return-Path** records on the SCA **sending subdomain** at GoDaddy (apex untouched);
   verify propagation (`dig TXT <selector>._domainkey.<sub>`), and provider-side domain "verified".
3. (Recommended, separate governed task) apply the §9 sync-send hardening.
4. Set the `.env` `MAIL_*` block (§6); `docker compose exec -u 33:33 app php artisan config:clear`.
5. Send a controlled test to a seed inbox + a deliverability checker (e.g. mail-tester) → confirm **SPF pass, DKIM
   pass, DMARC pass**, inbox placement, correct branded From, working reset link over `https://verify.…`.
6. End-to-end: real collector forgot-password → email received → reset link → password change → token single-use +
   enumeration-safety intact. Confirm no token/PII in app logs.
7. Record activation + evidence in governance.

## 12. Rollback procedure

Mail activation is `.env`-only and reversible with **no data impact**: set `MAIL_MAILER=log` (and/or revert the
`MAIL_*` block) → `php artisan config:clear`; delivery reverts to logging instantly. The DNS DKIM/SPF records are
additive on the SCA subdomain and can be removed by the client without affecting Shopify/apex or smsrocket. No DB
restore is ever needed (reset tokens are transient + single-use; `sca_collector_password_resets` currently has 0
rows). Provider account can be paused/deleted independently.

## 13. Zero-mutation confirmation

`c568331`, tree CLEAN; Caddyfile `sha256 00f16788…` (`tls internal`); `.env` `MAIL_MAILER=log`,
`MAIL_FROM_ADDRESS=no-reply@localhost`, `TRUSTED_PROXIES=172.20.0.0/24` — **unchanged**; SCA counts `qr=2 certs=3
collectors=2 pwresets=0`; QR fp `6bb119ee0b598222bfec58bb80c7a4cb`; smsrocket.io 200; `:8080` 200; MariaDB private.
**No SCA/DNS/Caddy/.env/mail/Docker/firewall/data change was made. Phase 2C not activated. STOP.**

# SCA Production Email / SMTP — readiness audit (READ-ONLY, DO NOT IMPLEMENT)

**Date:** 2026-10-02 · **Production baseline:** main `dff2781`, migrations **120**.
**Status: AUDIT ONLY — zero production change. READ-ONLY. For ChatGPT review before any implementation.**
**ACTIVE / NEXT_TASK remain unpromoted.**

Ask: read-only audit of production email/SMTP config and every implemented email-dependent workflow;
inspect the password-reset flow end-to-end at code/config level (request → token → email → reset URL →
reset); propose a plan to send ONE controlled test email after review. **Hard boundaries honored:** no
`.env` change, no credential change, no test email sent, no password reset performed, no DNS/SPF/DKIM/DMARC
change, no DB write, no QR regen, no gallery/provenance/certification/authentication/ownership mutation, no
Caddy/firewall/Docker change, public `:8080` stays retired.

---

## 1. Which mailer production uses, and where it is configured

- **Effective mailer = `log`.** Runtime (read-only `php artisan tinker`): `mail.default = log`; the resolved
  transport is the **log** driver. **Nothing is delivered externally** — every message (including every
  password-reset email) is written to the Laravel log only.
- **Authoritative source = `app/.env`** (container `/var/www/html/.env`, mode 0600 `www-data`). This is the
  file Laravel reads. Relevant lines:
  - `MAIL_MAILER=log`
  - `MAIL_FROM_ADDRESS=no-reply@localhost`
  - `MAIL_FROM_NAME=SCA`
  - `QUEUE_CONNECTION=sync`
  - (no `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_ENCRYPTION`/`MAIL_SCHEME` lines)
- **Repo-root `/opt/sca-platform/.env` is the COMPOSE env, NOT read by Laravel** (it carries
  `APP_BIND_PORT` + compose DB creds). Confirmed lesson from the cutover work. Mail is governed solely by
  `app/.env`.

## 2. Are SMTP credentials present / complete?

**No. No SMTP credentials are configured** (and none are needed while the mailer is `log`).

- `app/.env` has **no** `MAIL_HOST` / `MAIL_PORT` / `MAIL_USERNAME` / `MAIL_PASSWORD` / `MAIL_ENCRYPTION`.
- The runtime SMTP block shows `host='smtp.mailgun.org' port=587 encryption='tls'`, `username` **not set**,
  `password` **not set**. ⚠️ **These host/port/encryption values are the framework DEFAULT placeholders**
  from `config/mail.php` (`env('MAIL_HOST','smtp.mailgun.org')` etc.), **not** active configuration and
  **not** evidence of a Mailgun account. Because `MAIL_MAILER=log`, the smtp transport is never constructed.
- No secrets were printed; credential presence was checked as booleans only. **Mailgun is NOT in use** — the
  placeholder is the stock Laravel default.

## 3. Is mail disabled / logged / queued / sent externally?

- **Logged, not sent.** `log` mailer → messages go to the Laravel log channel; **no external delivery**,
  **no outbound SMTP connection**.
- **Not queued — synchronous.** `queue.default = sync`. The one SCA mail notification
  (`CollectorResetPassword`) is **NOT `ShouldQueue`** (grep: 0 occurrences), and Krayin's admin reset
  notification is likewise synchronous. **No queue worker is required** for any current email workflow.
- This matches the enumeration-safe forgot-password hardening already deployed (`4095ad5`): with
  `MAIL_MAILER=log`, a mail-transport failure cannot leak PII/tokens or 500.

## 4. Which workflows send email

Full grep of `packages/Sca/` for `Mail::send|raw|to|queue`, `Mailable`, `ShouldQueue`: **no `Mail::*` calls,
no Mailable classes, no queued notifications in SCA code.** The only SCA-originated email is one password-reset
notification. The two live email workflows are both **authentication / password-reset** paths:

| Workflow | Trigger | Broker | Notification | Reset route | Token table (expiry) |
|---|---|---|---|---|---|
| **Collector reset** | `POST collector/forgot-password` → `ForgotPasswordController@...:42` `Password::broker('sca_collectors')->sendResetLink()` | `sca_collectors` | **`CollectorResetPassword`** (SCA-037, `packages/Sca/Provenance/src/Notifications/`) | `collector.password.reset` (`GET collector/reset-password/{token}`) | `sca_collector_password_resets` (**60 min**) |
| **Admin reset** | `POST admin/forget-password` | `users` (Krayin default) | Laravel/Krayin default `ResetPassword` | `admin.reset_password.create` (`GET admin/reset-password/{token}`) | `user_password_resets` (**60 min**) |

- `CollectorResetPassword`: `via() = ['mail']`; **not** `ShouldQueue`; `toMail()` builds
  `$url = url(route('collector.password.reset', ['token'=>…, 'email'=>…], false))`, subject "Reset your SCA
  collector password", action "Reset password" → `$url`, "This link expires in 60 minutes and can be used
  once." Carries **only** the opaque broker token + email — **no password, id, or ownership data**.
- `CollectorAccount` implements `CanResetPasswordContract` / `use CanResetPassword`;
  `sendPasswordResetNotification($token)` → `$this->notify(new CollectorResetPassword($token))`.
- **Other Krayin core emails** (e.g. internal user-invite / lead / activity notifications) may exist in
  Webkul core but are (a) not SCA auth workflows and (b) inert anyway under `MAIL_MAILER=log`. They are not
  part of the pilot's email surface and are out of scope for this audit.
- Current broker-table row counts (read-only, no write): `user_password_resets = 0`,
  `sca_collector_password_resets = 0` — no pending reset tokens.

## 5. Queue workers required?

**No.** `queue.default = sync` and neither reset notification is `ShouldQueue`, so mail is dispatched inline
on the request. No worker/daemon/`queue:work` is needed for current functionality. (If SMTP is later enabled
and async sending is wanted, that would be a separate, opt-in change — not required to send reset mail.)

## 6. From address / name appropriate for Second Chance Authenticators?

**No — placeholder, must be corrected before any real send.**
- `MAIL_FROM_ADDRESS = no-reply@localhost` → **not a deliverable production address** and not an SCA domain.
  Recommend an SCA-domain address, e.g. `no-reply@secondchanceauthenticators.com` (or a dedicated mail
  subdomain such as `mail.secondchanceauthenticators.com`) **aligned with the SMTP sender/DKIM** — see §9.
- `MAIL_FROM_NAME = "SCA"` → functional but terse; recommend **"Second Chance Authenticators"** for
  recipient clarity/trust.
- This is a `.env` change only (no code), to be made under governance **after** SMTP + DNS are ready — not in
  this audit.

## 7. Do email-generated URLs use https://verify.secondchanceauthenticators.com?

**Yes — HTTPS verify., and Phase-B Secure-cookie compatible.**
- `app.url = https://verify.secondchanceauthenticators.com` (confirmed runtime).
- Collector reset URL via `url(route(..., false))`: `route(...,false)` yields a relative path, `url()`
  prefixes the request root; the forgot-password POST arrives over `verify.` HTTPS (edge is HTTPS-only,
  `http→https` 308), and the CLI/non-request fallback root is `app.url` = the same HTTPS verify. host. Either
  way the link is **`https://verify.secondchanceauthenticators.com/collector/reset-password/{token}?email=…`**.
- Admin reset URL is built by Krayin via `route()` → honors `app.url` → same HTTPS verify. host.
- **Secure-cookie compatibility:** reset pages are served over HTTPS on verify.; Phase-B
  `SESSION_SECURE_COOKIE=true` (session/CSRF cookies `Secure`) is satisfied because there is no HTTP reset
  path. No mixed-content / cookie-drop risk.

## 8. Any SMTP dependency on the retired public :8080?

**None.** Email URLs derive from `app.url` / the verify. request host — never `:8080`. No mail code or config
references port 8080. Retiring the public `:8080` bind (kr-app loopback-only) has **zero** effect on email.

## 9. SPF / DKIM / DMARC — do they need verification? (audit only, no DNS change)

**Yes — must be verified/configured for the chosen sending domain before any real external send.** Read-only
DNS lookups (no changes made):
- **DMARC exists and is enforcing:** `_dmarc.secondchanceauthenticators.com` →
  `v=DMARC1; p=quarantine; adkim=r; aspf=r; rua=mailto:dmarc_rua@onsecureserver.net`.
  - `p=quarantine` → **unauthenticated/unaligned mail from this domain is sent to spam/quarantine.**
  - `rua=…@onsecureserver.net` confirms **DNS is at GoDaddy / Secureserver** (consistent with the cutover
    notes: apex/www on the registrar; `verify.` A-record points to this VPS). **DNS is not on this server —
    no DNS changes in scope.**
- **SPF:** no apex `v=spf1` TXT was returned by the quick lookup. Before sending, an SPF record for the
  sending domain MUST authorize the chosen ESP/relay (e.g. `include:` the provider), or SPF will fail →
  quarantine under the policy above. (A deeper/authoritative SPF check should be run against the exact
  sending (sub)domain once chosen.)
- **DKIM:** none configured (no SMTP/ESP yet). The ESP's DKIM selector record MUST be published and the From
  domain signed so DKIM passes **and aligns** (`adkim=r` relaxed → organizational-domain alignment suffices).
- **Conclusion:** because DMARC is already `p=quarantine` with relaxed alignment, real SCA mail will be
  quarantined unless **SPF or DKIM passes aligned to the From domain.** The From address (§6), the ESP/SMTP
  choice, and these DNS records must be decided together. **All DNS work is the operator's at GoDaddy — audit
  only, nothing changed here.**

## 10. Password-reset flow, end-to-end (code/config level — nothing triggered)

Identical shape for both brokers (`sca_collectors` for collectors, `users` for admins):

1. **Request.** User submits the forgot-password form.
   - Collector: `POST collector/forgot-password` (route `collector.password.email`, `throttle:6,1`) →
     `ForgotPasswordController` → `Password::broker('sca_collectors')->sendResetLink($credentials)`.
   - Admin: `POST admin/forget-password` → Krayin controller → `Password::broker('users')->sendResetLink()`.
   - Enumeration-safe: the controller returns a generic success regardless of whether the address exists, and
     (hardening `4095ad5`) does not 500 / leak on mail-transport failure.
2. **Token creation.** The broker generates a random token, stores its **hash** in the broker table
   (`sca_collector_password_resets` / `user_password_resets`) keyed by email with a timestamp; **60-minute**
   expiry; single-use (consumed on successful reset). *(This is a DB write performed by the real flow — NOT
   performed in this audit; current row counts are 0/0.)*
3. **Email generation.** The notifiable's `sendPasswordResetNotification($token)` fires the notification
   (`CollectorResetPassword` for collectors; Krayin/Laravel `ResetPassword` for admins), `via(['mail'])`,
   **synchronous** (no queue). Under `MAIL_MAILER=log` the message is **written to the log, not delivered.**
4. **Reset URL.** Built via `route()`/`url(route(...,false))` → `https://verify.secondchanceauthenticators.com/
   collector/reset-password/{token}?email=…` (collector) or `/admin/reset-password/{token}` (admin). HTTPS,
   token + email only.
5. **Reset.** `GET …/reset-password/{token}` renders the form (collector:
   `ResetPasswordController@show`, route `collector.password.reset`); `POST …/reset-password` (collector
   `collector.password.reset.update`, `throttle:6,1`) → `Password::broker(...)->reset(...)`. On
   `Password::PASSWORD_RESET` the password hash is updated and the token row is deleted/consumed. New
   password requires min length + confirmation per the controller rules.

**Net:** the flow is HTTPS-only, token-scoped, 60-min single-use, throttled, enumeration-safe, Secure-cookie
compatible, and needs no queue worker. **The only reason production reset email is not *delivered* today is
`MAIL_MAILER=log` + absent SMTP credentials/From — i.e. a config/DNS gap, not a code gap.**

---

## 11. Proposed controlled single-test-email plan (FOR REVIEW — do not execute yet)

Goal: prove end-to-end external delivery over a real relay **once**, without exposing credentials, without
changing any real user's password, and without triggering the reset flow against a real account.

**Prereqs (operator + governed `.env` edit, separate approved step — NOT part of this audit):**
- Decide ESP/relay + sending (sub)domain; publish/verify **SPF + DKIM** so mail aligns under the existing
  `p=quarantine` DMARC (§9). Set a production `MAIL_FROM_ADDRESS` on that domain and
  `MAIL_FROM_NAME="Second Chance Authenticators"`.
- Set `MAIL_MAILER=smtp` + `MAIL_HOST/PORT/USERNAME/PASSWORD/ENCRYPTION` in **`app/.env`** (0600). Credentials
  are entered by the operator; **never** echoed, logged, committed, or printed. `QUEUE_CONNECTION` stays
  `sync` (no worker needed).

**The controlled send (proves SMTP transport, touches no user/password/token):**
- Send **one** ad-hoc message to an **operator-controlled test inbox** (not a real collector/admin, not a
  reset link) via tinker:
  `Mail::raw('SCA SMTP connectivity test '.now(), fn($m)=>$m->to('OPERATOR_TEST_INBOX')->subject('SCA SMTP connectivity test'));`
  This uses **no** broker, creates **no** reset token, and changes **no** password.
- **Do NOT** reset a real operator's password and **do NOT** call `sendResetLink` against a real account.

**Prove delivery without exposing secrets:**
- Confirm receipt at the test inbox; inspect headers for **SPF=pass, DKIM=pass, DMARC=pass** and the correct
  From/display-name.
- Cross-check the ESP dashboard/API for an `accepted`/`delivered` event + message-id; capture only
  message-id + status + recipient + From — **never** `MAIL_PASSWORD` or any secret. Verify the Laravel log
  shows no transport error.

**Optional second-stage (only if a live reset email must be proven), still no real-user impact:**
- Seed a **throwaway test collector** with the operator test inbox, trigger its reset, confirm the email
  arrives with an `https://verify.…/collector/reset-password/{token}` link, then delete the test account.
  This sends a reset *email* but still changes **no real user's** password (clicking the link is required to
  change a password, and only the test account's). Gated behind explicit approval + DB-write authorization —
  out of scope for the connectivity proof above.

**Rollback:** the test is non-mutating to domain data (no QR/provenance/gallery/cert/ownership change, no
migration). If SMTP is not being adopted immediately, revert `app/.env` to `MAIL_MAILER=log` after the test.

---

## 12. Summary of findings & recommendation

| # | Determination | Finding |
|---|---|---|
| 1 | Mailer in production | **`log`** — written to log, **not delivered externally** |
| 2 | Config source | **`app/.env`** (`MAIL_*`); repo-root `.env` is compose-only |
| 3 | SMTP credentials | **Absent/none** (runtime host/port are framework default placeholders, not active; Mailgun NOT in use) |
| 4 | Disabled/logged/queued/sent | **Logged**, **synchronous** (`queue=sync`), not sent |
| 5 | Email workflows | **2**, both auth: Collector reset (`CollectorResetPassword`) + Admin reset (Krayin default) |
| 6 | Queue workers | **Not required** (sync, notifications not `ShouldQueue`) |
| 7 | From address/name | **Placeholder — inappropriate.** `no-reply@localhost` / "SCA" → needs SCA-domain address + "Second Chance Authenticators" |
| 8 | Email URLs | **HTTPS `verify.secondchanceauthenticators.com`** (`app.url`/request); Phase-B Secure-cookie compatible |
| 9 | Reset links HTTPS | **Yes**, 60-min single-use, throttled, enumeration-safe |
| 10 | SPF/DKIM/DMARC | **Needs config/verify.** DMARC already `p=quarantine` (relaxed) at GoDaddy; **no apex SPF seen**, **no DKIM** → unaligned mail will quarantine. DNS off-server — audit only |
| 11 | `:8080` dependency | **None** — mail URLs never use `:8080`; retirement is irrelevant to email |

**Bottom line:** the SCA/Krayin email *code* is production-ready and secure (HTTPS verify. links, 60-min
single-use tokens, enumeration-safe, sync, no `:8080` coupling). **Production email is not yet operational by
configuration:** mailer is `log`, no SMTP credentials, placeholder From, and SPF/DKIM unconfigured under an
enforcing `p=quarantine` DMARC. Enabling real delivery is a coordinated **`.env` + ESP + DNS** change (not a
code change) followed by the single controlled test in §11.

**No GO requested. AUDIT ONLY — zero changes made. Awaiting ChatGPT review. ACTIVE / NEXT_TASK remain
unpromoted; nothing implemented, no `.env`/DNS/DB/mail/infra change.**

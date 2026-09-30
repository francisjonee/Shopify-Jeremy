# NEXT TASK

**STATUS: `SCA-COLLECTOR-PASSWORD-RESET-FAILURE-HARDENING` — IMPLEMENTED + PUSHED (push-only). Awaiting ChatGPT
pre-merge audit. NOT merged, NOT deployed.**

Base/deployed `c568331`. Feature branch `sca-collector-pwreset-failure-hardening` on `github-sca-platform` — fix
`8324b0e` (supersedes `f3e86f2`), report in `docs/task-reports/SCA-COLLECTOR-PASSWORD-RESET-FAILURE-HARDENING.md`.

## Token-cleanup semantic verification — Classification **B** (final pre-merge; corrected)

ChatGPT's audit asked whether a `Throwable` from `sendResetLink()` can occur **after** the SMTP server already
accepted the message. Traced the installed source (Laravel 12.66, `symfony/mailer` ^7.2) — **it can**:
`SmtpTransport::executeCommand("\r\n.\r\n",[250])` **writes then reads** the 250 (a timeout/drop after the server
queued the message throws despite delivery); and `SentMessageEvent` + `checkThrottling()` (`AbstractTransport::send`),
`MessageSent` (`Mailer::send`), and `NotificationSent` (`NotificationSender`) all fire **after** acceptance,
synchronously inside `sendResetLink()`. ⇒ a thrown delivery does **not** prove non-acceptance. **Correction: retain
the token** (deleting it could invalidate a link the collector received). The token is account-bound, hashed,
single-use, 60-min; an undelivered token is inert.

## What was implemented (push only)

Minimal hardening of `ForgotPasswordController::sendLink`: `try/catch (\Throwable)` around
`Password::broker('sca_collectors')->sendResetLink(...)` → on failure returns the **identical** generic redirect+flash
(no HTTP 500; no exception/email/token/provider/credential text to the browser). `$request->validate` stays before the
try. **Token is retained** (no deletion). Privacy-safe log records only the exception class. Preserved: 60-min expiry,
60-s broker throttle, route `throttle:6,1`, single-use deletion on success, collector/staff broker separation,
`status=active` eligibility, no-auto-login, exact success behavior. Scope = 3 files (controller + test + report). No
`.env`/DNS/Caddy/Docker/network/firewall/queue/schema/QR change.

## Verification

- Focused `CollectorPasswordRecoveryTest`: **20 passed / 97 assertions** (r17 now asserts the token is RETAINED
  after failure).
- Full `tests/Feature/Sca`: **641 passed / 3462 assertions** (exit 0).
- **Discriminator proven:** reverting the controller to base `c568331` makes r15/r17/r20 **FAIL** (uncaught → 500);
  the fix makes them pass. `php -l` clean.
- Pilot restored to deployed main `c568331`: clean tree, `--no-dev` (phpunit pruned), kr-app healthy on
  `195.26.255.80:8080`, `:8080` endpoints (incl `/collector/forgot-password`) 200, smsrocket 200, 2B edge intact
  (SCA vhost SNI 200), MariaDB private.

**PUSH ONLY — stopped for ChatGPT audit; no merge, no deploy.** `SCA-PRODUCTION-CUTOVER` remains OPEN (Phase 2C blocked
on the client's GoDaddy `verify` A record). SCA-054 must not start.

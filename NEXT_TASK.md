# NEXT TASK

**STATUS: `SCA-COLLECTOR-PASSWORD-RESET-FAILURE-HARDENING` — IMPLEMENTED + PUSHED (push-only). Awaiting ChatGPT
pre-merge audit. NOT merged, NOT deployed.**

Base/deployed `c568331`. Feature branch `sca-collector-pwreset-failure-hardening` on `github-sca-platform` — fix
`f3e86f2`, task report `8fdce4d` (`docs/task-reports/SCA-COLLECTOR-PASSWORD-RESET-FAILURE-HARDENING.md`).

## What was implemented (push only)

Minimal hardening of `ForgotPasswordController::sendLink` so a mail-transport failure preserves the endpoint's
enumeration-safety:
- `try/catch (\Throwable)` around `Password::broker('sca_collectors')->sendResetLink(...)` → on failure returns the
  **identical** generic redirect+flash (no HTTP 500; no exception/email/token/provider/credential text to the
  browser). `$request->validate` stays before the try (malformed input still 422s).
- **Residual-token cleanup:** `sendResetLink` creates the token before delivery; on a throw (⇒ not delivered, plaintext
  unrecoverable) the residual token is deleted best-effort via the public `getUser` + `deleteToken` (cleanup itself
  guarded) — no misleading token lingers, and the 60-s throttle doesn't block a legitimate retry.
- **Privacy-safe log:** `Log::warning('SCA collector password-reset delivery failed', ['exception' => $e::class])` —
  only the exception class; never email/token/message/provider response.
- Preserved: 60-min expiry, 60-s broker throttle, route `throttle:6,1`, single-use deletion, collector/staff broker
  separation, `status=active` eligibility, no-auto-login, exact success behavior.

Scope = exactly 2 files (`ForgotPasswordController.php` + `CollectorPasswordRecoveryTest.php`). No
`.env`/DNS/Caddy/Docker/network/firewall/queue/schema/QR change.

## Verification

- Focused `CollectorPasswordRecoveryTest`: **20 passed / 97 assertions** (r1–r14 unchanged; r15–r20 new).
- Full `tests/Feature/Sca`: **641 passed / 3462 assertions** (exit 0; was 635/3432).
- **Discriminator proven:** reverting the controller to base `c568331` makes r15/r17/r20 **FAIL** (uncaught → 500);
  the fix makes them pass. `php -l` clean.
- Pilot restored to deployed main `c568331`: clean tree, `--no-dev` (phpunit pruned), kr-app healthy on
  `195.26.255.80:8080`, `:8080` endpoints (incl `/collector/forgot-password`) 200, smsrocket 200, 2B edge intact
  (SCA vhost SNI 200), MariaDB private.

**PUSH ONLY — stopped for ChatGPT audit; no merge, no deploy.** `SCA-PRODUCTION-CUTOVER` remains OPEN (Phase 2C blocked
on the client's GoDaddy `verify` A record). SCA-054 must not start.

# NEXT TASK

**STATUS: ACTIVE — `SCA-COLLECTOR-PASSWORD-RESET-FAILURE-HARDENING` (PUSH ONLY).**

Promoted 2026-09-30 by ChatGPT. Base/deployed `c568331`. Preserves the collector forgot-password endpoint's
enumeration-safe behavior when the configured mail transport throws / is unavailable. **PUSH ONLY — do NOT merge,
deploy, or execute Phase 2C.** (Distinct from the held `SCA-054` staff-UX candidate.)

## Root cause (inspected at c568331)

Laravel `PasswordBroker::sendResetLink` creates the reset token **before** calling
`$user->sendPasswordResetNotification($token)`. Today `MAIL_MAILER=log` (can't fail), but under a real SMTP transport
a delivery throw would propagate out of `ForgotPasswordController::sendLink` → **HTTP 500**, which both harms UX and
**breaks the enumeration-safety guarantee** (a 500 vs. the generic 200/redirect becomes an oracle; a transport
exception message can also contain the recipient address). See
`docs/SCA-PRODUCTION-CUTOVER-SMTP-READINESS-AUDIT.md` §9.

## Executable contract

1. **Harden `ForgotPasswordController::sendLink` only** (minimal): wrap the `Password::broker('sca_collectors')
   ->sendResetLink(...)` call in a `try/catch (\Throwable)`. On catch, return the **same** enumeration-safe generic
   redirect+flash as the success/unknown/disabled paths — **no HTTP 500**, no exception/email/token/provider/credential
   text to the browser. Validation (`$request->validate`) stays **before** the try so malformed input still 422s.
2. **Token cleanup on failure (decided):** a thrown transport exception means the message was not accepted, so the
   token was not delivered and its plaintext is unrecoverable (only a hash remains). **Delete the residual token**
   best-effort via the public broker API (`getUser` + `deleteToken`), wrapped in its own guard so cleanup failure also
   never 500s. Rationale: prevents a misleading residual token and frees the 60-s broker throttle for a legitimate
   retry; it never invalidates a delivered link (a throw ⇒ not delivered). This is a deliberate, security-analyzed
   choice, not a broker-semantics requirement.
3. **Privacy-safe operational logging:** record the failure so ops can detect a broken transport, but log **only** a
   fixed message + the exception **class** (and optionally code) — **never** the email, token, `$e->getMessage()`,
   provider response, or collector identity.
4. **Preserve everything else unchanged:** 60-min token expiry, 60-s broker throttle, route `throttle:6,1`,
   single-use deletion on success, collector/staff broker separation, `status=active` eligibility, no-auto-login, and
   the exact successful-reset behavior.
5. **Tests (focused, `tests/Feature/Sca/CollectorPasswordRecoveryTest.php`)** using a **deliberately failing mail
   transport**: prove (a) active/unknown/disabled all return the **identical** enumeration-safe response under
   failure; (b) **no 500**; (c) no exception/email/token/provider text in the response; (d) the residual token is
   **deleted** on failure (0 rows); (e) privacy-safe log carries no email/token/message; (f) normal successful reset
   still works (real in-memory transport); (g) zero unrelated domain mutation.
6. **Run** the focused suite + full `tests/Feature/Sca`; report exact totals; `php -l` clean.

**Forbidden:** DNS, SMTP credentials/provider activation, real email, `.env`, Caddy, Docker/network/firewall, queue
infrastructure/workers, schema/migrations (unless an unexpected hard requirement is discovered — then STOP and
report), QR changes, Phase 2C execution. **Push only; return to ChatGPT for audit.**

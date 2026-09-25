# NEXT TASK

**STATUS:** NONE — no executable task is authorized.

`SCA-COLLECTOR-PASSWORD-RECOVERY-037` is **DONE** (audited, merged, and deployed to production `main` at `df80e4b5a655f59a1337cb1a8792beb6e6d40f54`; the `sca_collector_password_resets` migration ran; forgot/reset routes are live). Real email delivery remains **not production-ready** until SMTP/mail infrastructure is configured (`MAIL_MAILER=log`). ChatGPT promotes exactly one next task here when ready; SCA-038 is not activated.

*The prior 037 task spec is preserved in the implementation repo report `docs/task-reports/SCA-COLLECTOR-PASSWORD-RECOVERY-037.md`.*

## Title

Collector forgot-password / reset-password application workflow

## Implementer

Claude

## Why this task now

SCA-036 is merged, deployed, and manually pilot-validated: authenticated collectors can change their password without disturbing ownership/provenance, the old password stops working, the new password works, and My Collection remains intact. The remaining account-access gap is a collector who cannot authenticate because they forgot the password. Today that collector has no self-service recovery path and can be stranded from registered ownership.

This task stays application-focused. Production SMTP/mail delivery infrastructure is explicitly deferred. Build the recovery workflow against Laravel's mail/password-reset abstractions and prove delivery with the test/fake mailer; do not configure or deploy an SMTP provider in this task.

## Scope (approved, tight)

Add collector **Forgot password** + **Reset password** only, using the existing collector account/guard architecture. The workflow must be privacy-safe, tokenized, expiring, single-use, and must never mutate provenance or collector identity.

Before coding, inspect the current accepted `origin/main` and existing auth/password infrastructure. Reuse framework facilities where safe. If a collector-specific password broker/reset-token store is required, implement the smallest conventional schema/config needed. If the existing framework architecture cannot safely support a separate collector broker without invasive auth changes, STOP and report the blocker rather than improvising a second authentication system.

## Required implementation

1. Branch `feat/sca-collector-password-recovery-037` from **current accepted `origin/main`** and report the exact base SHA before coding.
2. Add a guest-facing **Forgot password?** affordance from collector login.
3. Add a collector password-reset request endpoint/form accepting email.
   - Response must be enumeration-safe: do not reveal whether an email belongs to a collector.
   - Apply CSRF and appropriate throttling.
   - Disabled/pseudonymized collectors must not receive a usable reset capability.
4. Generate a cryptographically secure, expiring reset token using Laravel/framework-standard password-reset facilities where possible. Store only the framework-standard safe representation; never log or persist plaintext passwords.
5. Send the reset link through Laravel's mail abstraction. Tests must use fake/test delivery. **Do not configure production SMTP, DNS, Caddy, or a mail provider.** Runtime delivery remains dependent on later mail-infrastructure configuration.
6. Add reset form/endpoint accepting token + collector email + new password + confirmation.
   - Reuse the registration/SCA-036 password policy (`Password::min(8)` + `confirmed`).
   - Reject invalid, expired, already-used, wrong-account, disabled, or pseudonymized reset attempts.
   - On success, hash the new password with the existing application mechanism and invalidate/consume the reset token.
   - Existing active sessions must be handled deliberately and documented. Prefer invalidating other collector sessions if the current session architecture safely supports it; do not weaken session security merely to achieve this.
7. After successful reset, provide a clear path back to collector sign-in. Do not automatically claim, transfer, or alter any item.

## Critical provenance / identity invariant

Password recovery may change **only the collector password credential plus the minimum reset-token/session state required for secure recovery**. It must NEVER create/delete/update ownership events, claims, transfers, certification/authentication events, QR identity, registry status, item state, `collector_account_id`, collector `id`, `public_ref`, `email`, or collector lifecycle `status`. Existing ownership must continue resolving through the same collector account after reset.

## Security requirements

- Guest-safe workflow; collector need not already be authenticated.
- Enumeration-safe request response for existing and unknown email addresses.
- CSRF on state-changing browser forms.
- Throttle reset requests and reset attempts consistently with existing collector auth protections.
- Cryptographically secure, expiring, single-use token.
- Token/account binding must be authoritative at mutation time.
- New password policy identical to registration/SCA-036.
- No password/token leakage to logs, query diagnostics, public pages, or task reports.
- Disabled/pseudonymized collectors fail closed.
- Staff/admin authentication must not substitute for collector recovery authorization.
- Preserve existing collector login/change-password/logout behavior.

## Mail boundary

The application may add the collector reset notification/mailable and the minimum broker/config/schema required to support reset tokens. Tests must prove the intended email contains the correct collector reset URL without sending real mail. **Do not change production mail credentials or infrastructure.** If the current deployment uses `MAIL_MAILER=log`, leave it unchanged. The completion report must state clearly that real email delivery is not production-ready until SMTP/mail infrastructure is configured.

## Tests

Add focused `CollectorPasswordRecoveryTest` coverage proving at minimum: forgot-password pages/routes exist; GETs are zero-mutation; unknown and known emails receive indistinguishable public responses; valid active collector produces a reset notification under fake/test mail; unknown/disabled/pseudonymized accounts do not gain usable reset capability; token is account-bound, expires, and is single-use; invalid/expired/reused token fails without password change; weak password fails; mismatched confirmation fails; valid reset succeeds; stored password is hashed; old password no longer authenticates; new password authenticates; collector identity fields remain unchanged; ownership events are byte/count/content unchanged; claims/transfers/projection owner unchanged; owned item remains in My Collection after sign-in with the new password; public passport/privacy behavior unchanged; CSRF and throttling are present. Run the full SCA regression suite plus `composer validate`, `composer audit`, PHP lint, and secret scan.

## Explicit non-goals

No email-address change or verification, display-name/profile editing, MFA, magic-link login, social login, admin password reset, account merge, ownership correction/transfer changes, SMTP/provider setup, production mail credentials, DNS/domain/Caddy work, Shopify work, permanent QR-domain work, infrastructure changes, or unrelated UI redesign.

## Completion rule

Create `docs/task-reports/SCA-COLLECTOR-PASSWORD-RECOVERY-037.md`. Push the feature branch; **do not merge and do not deploy**. Report base SHA, final HEAD, files changed, exact routes, broker/token/schema design, expiry/single-use behavior, enumeration/throttle/CSRF controls, session behavior, provenance/identity non-mutation evidence, mail boundary, focused + full test results, lint/composer/secret checks, and confirmation production/live pilot was not mutated. Restore the preview to accepted `main` if local branch testing touched the preview checkout. STOP for ChatGPT audit; SCA-038 must not be started.
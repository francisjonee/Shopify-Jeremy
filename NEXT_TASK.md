# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-COLLECTOR-PASSWORD-CHANGE-036

## Title

Authenticated collector password change + minimal account-security UX

## Implementer

Claude

## Why this task now

SCA-035 is merged, deployed, and manually pilot-validated. The read-only 036 design audit confirmed a
logged-in collector's only account actions are View My Collection, Sign out, and a prominent
**Permanently anonymize my account** — with no way to rotate their own password. For a registry that now
represents ownership of valuable authenticated eyewear, self-service password change is the smallest
high-value gap. Production cutover/domain/mail remain intentionally deferred, so this is pure application
work.

## Scope (approved, tightened)

Authenticated collector password change **only**, plus a minimal account-page reorganization.
**No display-name editing.** Reuse the existing collector auth architecture; do not build a second auth
system.

## Required implementation

1. Branch `feat/sca-collector-password-change-036` from **current accepted `origin/main`** (report the base
   SHA before coding).
2. Add an authenticated password change: collector provides **current password + new password + confirm**.
   - Verify the current password against the **`collector` guard**.
   - Enforce the **same password policy used at registration** (`Password::min(8)` + `confirmed`).
   - Hash the replacement via the existing application mechanism (`Hash::make`).
   - **Regenerate the current session** after success, keeping the collector authenticated.
3. Account UX (minimal, no portal redesign): identity/email → View My Collection → **Account security**
   (Change password) → **Danger zone** (Permanently anonymize my account). Anonymization capability is
   unchanged — only moved/de-emphasized.

## Critical provenance invariant

Password change modifies only the collector's password credential. It must NEVER create/delete/update
ownership events, transfer ownership, recreate the collector, or change `collector_account_id`,
`public_ref`, `email`, collector `status`, claims, transfers, certification, authentication, QR identity,
or registry status. Existing ownership must keep resolving through the same immutable collector account.
Add explicit regression coverage.

## Security requirements

Collector guard required (staff/admin session alone must not grant access); correct current password
required; new-password confirmation required; registration password policy reused; CSRF enforced;
throttling consistent with existing collector auth/privacy routes; session regenerated on success (old
password stops authenticating, new password authenticates); disabled/pseudonymized collectors fail closed
per the existing collector-auth lifecycle. Do not weaken existing login/logout/session behavior.

## 419 / non-goals

**419:** no change — the SCA-035 419 was expected stale-CSRF behavior. Do not modify `ScaHttpStatusHandler`,
CSRF handling, session lifetime, cookie config, or the 419 page.

**Explicit non-goals:** no forgot-password, reset-password, password broker, reset-token table, email
change, email verification, display-name/profile editing, SMTP/mail config, DNS/domain/Caddy work, schema
migration (STOP and report if an unavoidable blocker appears), ownership/provenance changes, admin/staff
auth changes, or infrastructure changes.

## Tests

Add focused `CollectorPasswordTest` proving at minimum: unauthenticated denied; staff/admin guard does not
substitute; form GET zero-mutation; current password required; wrong current fails (no change); weak new
fails; mismatched confirm fails; valid change succeeds; stored password hashed; old password no longer
authenticates; new password authenticates; collector stays authenticated after regeneration; CSRF enforced;
throttling present; disabled/pseudonymized fail closed; `collector_account_id`/`public_ref`/`email`/`status`
unchanged; ownership events unchanged (count/content); claims/transfers unchanged; current-ownership
projection unchanged; owned items still in My Collection; public passport privacy unaffected; account page
places password management before the Danger Zone. Run the full SCA regression suite + `composer validate`,
`composer audit`, PHP lint, secret scan.

## Completion rule

Create `docs/task-reports/SCA-COLLECTOR-PASSWORD-CHANGE-036.md`. Push the feature branch; **do not merge,
do not deploy.** Report base SHA, final HEAD, files changed, exact routes, password validation/security
design, session behavior, provenance non-mutation evidence, focused + full test results, lint/composer/
secret checks, and confirmation production/live pilot was not mutated. STOP for ChatGPT audit; SCA-037 must
not be started.

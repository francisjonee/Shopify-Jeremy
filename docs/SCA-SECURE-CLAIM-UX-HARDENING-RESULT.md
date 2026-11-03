# SCA — Secure Claim & Email-Verification UX Hardening (RESULT)

**The P1 usability problems from the 2026-11-03 customer-Passport review are fixed on a dedicated
development branch, tested green in an isolated sandbox, and NOT deployed. Branch
`feature/secure-claim-ux-hardening` (`b758020d`) sits on top of the secure-claim RC (`c9a2d7d`) and
changes only views, controllers, and copy — no schema, no migration, and no change to authentication,
claim eligibility, the R0/R0b/R0c verified-buyer gate, or trusted Shopify order-email matching. The
"verification email sent" confirmation now actually shows; the verification-required failure is no
longer a dead-end (it returns to the claim page with the verify control); the account page has an
accessible "Verify your email" control + state indicator; verification outcomes survive redirects for
both signed-in and guest users; and the register/login forms have per-field, screen-reader-associated
validation errors. In a network-isolated, disposable-DB sandbox (proven unable to reach production,
Shopify, or the internet) the full application suite passed 1,583 tests / 8,138 assertions / 0
failures / 0 errors / 1 skip, including 9 new tests for the corrected flows and regression guards that
an unverified buyer still creates no ownership and a verified buyer still completes.** No production
deployment, migration, DB write, customer email, claim, or Shopify call; the live checkout stays at
`6e36aa7`; the 205 imported records are untouched; secure claiming is NOT activated. 2026-11-03.
**STOP.**

> Written for: the owner (Jeremy) and the external auditor reading from GitHub. This is a prepared,
> UNDEPLOYED improvement branch for future review/approval.

## Branch / commit (deliverable)
- **Branch:** `feature/secure-claim-ux-hardening` — based on RC `c9a2d7d` (`release/secure-claim-on-6e36aa7`); pushed to the implementation origin (`github-sca-platform`), tracking `origin/feature/secure-claim-ux-hardening`. Branch push only — no deploy, no merge, `origin/main` not touched.
- **Commit SHA:** `b758020da035d18ffe43a2291209cd48c170452f`
- **Diff vs RC:** 9 files, +294 / −17 (8 code/view + 1 new test).

## Changed files
| File | Change |
|---|---|
| `Sca/Claim/.../views/show.blade.php` | Render `session('status')`/`session('error')` flash (role=status/alert) so the "email sent" confirmation and the verification-required message appear (P1-1). |
| `Sca/Claim/.../Http/Controllers/PresaleGrantClaimController.php` | On `BUYER_VERIFICATION_REQUIRED`, redirect back to the presale claim page (which renders the verify control) with an actionable error flash, instead of the 409 "unavailable" dead-end (P1-2). Gate unchanged. |
| `Sca/Collector/.../Http/Controllers/AccountController.php` | Pass `emailVerified` flag to the account view (P1-3). |
| `Sca/Collector/.../views/account.blade.php` | Accessible "Verify your email" card (shown only while unverified) + "Email verified ✓" indicator (P1-3). |
| `Sca/Collector/.../Http/Controllers/EmailVerificationController.php` | `confirm()` lands outcomes where the flash renders for both audiences — signed-in → account, guest → login (was always guest-only login, dropping the flash for signed-in users). Message stays generic (P1-4). |
| `Sca/Collector/.../views/layout.blade.php` | Added `.field-error` / `.field-hint` styles + `input[aria-invalid]` border (P1-5). |
| `Sca/Collector/.../views/register.blade.php` | Per-field errors with `aria-invalid`/`aria-describedby` + password hint ("at least 8 characters", matching `Password::min(8)`) (P1-5). |
| `Sca/Collector/.../views/login.blade.php` | Per-field errors with ARIA; generic enumeration-safe message preserved (P1-5). |
| `tests/Feature/Sca/ClaimEmailVerificationUxTest.php` | **New** — 9 tests for the corrected flows + regression guards. |

## How each authorized task was met
1. Dev branch based on the RC — **done** (`b758020d` off `c9a2d7d`, isolated worktree; live tree never moved off `6e36aa7`).
2. Confirmation after requesting a verification link — **done** (P1-1): the claim page now renders the status flash; the account verify control redirects back to a page that shows it too.
3. Replace the verification-required dead-end — **done** (P1-2): redirects to the claim/verify page with clear next-step copy and the send-verification control.
4. Accessible email-verification control in the account experience — **done** (P1-3): account-page card + verified indicator; real `<form>`+`<button>`, headed and described.
5. Verification messages survive redirects — **done** (P1-4): signed-in → account, guest → login; both render the flash.
6. Field-level validation errors — **done** (P1-5): register + login, with `aria-invalid`/`aria-describedby`.
7. Buyer-verification security preserved — **done**: no change to `ClaimWorkflow`, `buyerIsVerified`, the gate, or the controllers' authorization; a test asserts an unverified buyer still creates no ownership and the grant stays `issued`.
8. Privacy / enumeration-safety preserved — **done**: `request()` unchanged (same generic flash whether or not a mail is sent — asserted); `confirm()` message never reveals account existence; no token/email/id added to any page HTML (claim token remains only in the form-action URL).
9. No change to authentication, claim eligibility, or trusted order-email matching — **confirmed** (diff is views/controllers/copy only).
10. Focused automated tests — **done**: `ClaimEmailVerificationUxTest` (9 tests / 42 assertions).
11. Regression in a proven isolated environment — **done** (below).
12. Documentation — this governance record.
13. Commit to a dedicated dev branch + STOP — **done**.

## Isolated sandbox + test results
- **Isolation proven before any migration/test:** disposable DB `sca_domain_test` + restricted user `sca_test` (prod `sca_krayin` → ERROR 1044); internal-only docker network (internet + Shopify unreachable); worktree app mounted read-only; dev deps in throwaway volumes; fake Shopify credentials; identity = `sca_domain_test` (env + Laravel + `SELECT DATABASE()`). Production `vendor/` confirmed still `--no-dev`.
- **New test:** `ClaimEmailVerificationUxTest` → 9 tests / 42 assertions / 0 fail.
- **Claim + collector-auth + email group:** 146 tests / 627 assertions / 0 fail.
- **Full application suite:** `tests/Feature/Sca` → **1,583 tests / 8,138 assertions / 0 failures / 0 errors / 1 skip** (exit 0). (The shared collector `layout.blade.php` was touched, so the full suite was run for assurance.)
- The disposable environment (runner, DB, user, network, volumes) and the temporary worktree were removed afterward; the branch ref remains locally and on origin.

## Remaining launch blockers (unchanged by this task)
Deployment of secure claiming is still gated on, and only on:
1. **Transactional email (SMTP)** with a verified sender + published SPF/DKIM (see
   `SCA-TRANSACTIONAL-EMAIL-READINESS-2026-11-03.md`) — without delivery, the email-verification gate
   cannot be satisfied in production.
2. **Separate owner authorization** to deploy (migrate-before-code), plus the `sca.eyewear.fulfillment.release`
   ACL grant and the `order_email` backfill.
This branch removes the self-service-claim UX friction but does not change those gates, and it is **not**
deployed. (Note: it is stacked on the RC `c9a2d7d`; a future deployment would fold these commits into
the RC under separate authorization.)

Remaining, deferred (not in this task's authorized scope): the P2 polish from the review — public-Passport
and collector heading/ARIA structure, descriptive image `alt`, terminology consistency, claim-view raw
HTTP-code pages / shared layout, and the duplicate edge/app security headers.

## Safety posture (this task)
Implemented on an isolated dev branch only. No production deployment, migration, or DB write; no Shopify
API call or store change; no customer email sent (mail faked/array in the sandbox); no customer claim or
ownership change; secure claiming NOT activated; `origin/main` NOT merged. The live checkout stayed at
`6e36aa7` and clean; the production DB is unchanged and still has **zero** secure-claim tables; the 205
imported records are untouched; production `vendor/` remains `--no-dev`.

**STOP — P1 secure-claim/email-verification UX fixes delivered on `feature/secure-claim-ux-hardening`
(`b758020d`, off RC `c9a2d7d`): confirmation now visible (P1-1), no verification dead-end (P1-2),
accessible account verify control (P1-3), redirect-surviving flashes (P1-4), per-field form errors
(P1-5). View/controller/copy only — security gate, claim eligibility, and trusted order-email matching
unchanged (verified by a no-ownership regression test). Isolated sandbox: full suite
1,583/8,138/0-fail/0-error/1-skip; new test 9/9. Branch pushed, NOT deployed, NOT merged; prod `6e36aa7`
intact; 205 imports untouched; claiming not activated. Launch still gated on transactional email +
separate owner deploy authorization.**

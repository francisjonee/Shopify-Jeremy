# SCA — Customer Passport P2 UX Improvements (RESULT)

**The remaining P2 customer-experience improvements from the 2026-11-03 review are implemented on a
dedicated development branch, tested green in an isolated sandbox, and NOT deployed. Branch
`feature/sca-passport-p2-ux` (`e80b386a`) sits on top of the secure-claim UX-hardening branch
(`b758020`) and changes **only Blade views** (13 files) plus one new test — no controllers, services,
routes, or migrations — so no authentication, ownership, or claim-eligibility logic is touched. The
work prioritizes mobile accessibility: the public Passport gains descriptive image alt text, a
navigable heading outline (visually-hidden section headings + the adverse-warning headline promoted to
a real heading), and a clearer "SCA record status" label; collector/claim/transfer pages get proper
page headings, a de-duplicated single top-level heading, and `role="status"/"alert"` on flash/error
blocks so they are announced; and the claim/transfer "unavailable" pages now show plain-language
headings instead of raw HTTP status numbers, with recovery guidance for expired transfer links.
Branding and layout are preserved (the sr-only headings and ARIA roles are invisible; promoted
headings are styled to match the prior text).** In a network-isolated, disposable-DB sandbox (proven
unable to reach production, Shopify, or the internet) the full application suite passed 1,588 tests /
8,155 assertions / 0 failures / 0 errors / 1 skip, including 5 new focused tests. No production
deployment, migration, DB write, Shopify call, customer email, or claim; the live checkout stays at
`6e36aa7`; the 205 imported records are untouched; secure claiming is NOT activated. 2026-11-03.
**STOP.**

> Written for: the owner (Jeremy) and the external auditor reading from GitHub. This is a prepared,
> UNDEPLOYED improvement branch for review/approval.

## Branch / commit (deliverable)
- **Branch:** `feature/sca-passport-p2-ux` — based on `b758020` (the P1 UX-hardening branch, itself off RC `c9a2d7d`); pushed to the implementation origin (`github-sca-platform`), tracking `origin/feature/sca-passport-p2-ux`. Branch push only — no deploy, no merge, `origin/main` untouched.
- **Commit SHA:** `e80b386a0386a7b813752af3bee843f02fb1a8a6`
- **Diff vs base:** 13 Blade views + 1 new test; +36 / −21 in the views (the test adds ~120 lines).

## Changed files & what changed
| File | Change | P2 ref |
|---|---|---|
| `Passport/.../passport/layout.blade.php` | Added a `.sr-only` utility (visually-hidden). | P2-1 |
| `Passport/.../passport/show.blade.php` | Descriptive image `alt` ("Photo of {item}", was `alt=""`); sr-only `<h2>` section headings ("Verified item details", "Authentication and certification"); adverse headline `<div>`→`<h2>`; label "SCA identity"→"SCA record status". | P2-1, P2-2, P2-5 |
| `Claim/.../views/unavailable.blade.php` | Raw HTTP status number → `<h1>"This item can't be claimed right now"` + the specific message. | P2-8 |
| `Collector/.../transfer/unavailable.blade.php` | Raw status number → `<h2>"Transfer unavailable"` + the message + expired/used-link guidance ("ask the current owner to send you a new transfer link"). | P2-7 |
| `Collector/.../layout.blade.php` | Added `.sr-only` utility; `role="alert"` on the global error block. | P2-1, P2-4 |
| `Collector/.../account.blade.php` | Title `<p>`→`<h2>`; `role="status"` on the status flash. | P2-1, P2-4 |
| `Collector/.../login.blade.php` | Title `<p>`→`<h2>`; `role="status"` on the status flash. | P2-1, P2-4 |
| `Collector/.../register.blade.php` | Title `<p>`→`<h2>`. | P2-1 |
| `Collector/.../collection/index.blade.php` | Page title `<h1>`→`<h2>` (de-dupe the double `<h1>` with the brand; local CSS selector retargeted); `role="status"` on flash. | P2-1, P2-4 |
| `Collector/.../collection/show.blade.php` | Item name `<div>`→`<h2>`; `role="status"` on both flashes. | P2-1, P2-4 |
| `Collector/.../transfer/initiate.blade.php` | `role="status"` on the flash. | P2-4 |
| `Collector/.../transfer/accept.blade.php` | Section titles `<p>`→`<h2>`. | P2-1 |
| `Claim/.../views/show.blade.php` | `already_yours` bare "View" link → styled "View in My Collection →". | P2-9 |
| `tests/Feature/Sca/PassportP2UxTest.php` | **New** — 5 tests / 17 assertions. |

## How each authorized task was met
1. Reviewed the remaining P2 findings — done (source: `SCA-CUSTOMER-PASSPORT-UX-REVIEW-2026-11-03.md`).
2. Prioritized mobile usability & accessibility — done (most changes are a11y; layout/responsive CSS unchanged).
3. Heading structure + ARIA — done (sr-only section headings; page titles as `<h2>` under the brand `<h1>`; adverse headline as `<h2>`; `role="status"/"alert"` on flashes/errors; de-duplicated the double `<h1>`).
4. Image alt text — done (public-Passport photo now has a descriptive alt).
5. Simplify confusing terminology — done conservatively ("SCA identity"→"SCA record status"); trust-reviewed public-Passport safety copy was intentionally left unchanged.
6. Error pages exposing raw HTTP codes — done (claim + transfer "unavailable").
7. Remove unnecessary duplicate headings/headers — done for duplicate **headings** (the brand `<h1>` + a second page `<h1>`); duplicate security **headers** deferred (see below).
8. Preserve branding/layout — done (invisible a11y additions; headings styled to match).
9. Limited to customer-facing views/styles/presentation — done (diff is Blade views + one test only).
10. Focused tests — done (`PassportP2UxTest`).
11. Regression in a verified isolated environment — done (below).
12. No security/auth/ownership/claim-eligibility change — verified: the diff contains no controller, service, route, request, or migration file.
13. Committed to a dedicated branch off `b758020` — done.
14. This document.
15. STOP for review — done.

## Isolated sandbox + test results
- **Isolation proven before any migration/test:** disposable DB `sca_domain_test` + restricted user `sca_test` (prod `sca_krayin` → ERROR 1044); internal-only docker network (internet + Shopify unreachable); worktree app mounted read-only; dev deps in throwaway volumes; fake Shopify credentials; identity = `sca_domain_test`. Production `vendor/` confirmed still `--no-dev`.
- **New test:** `PassportP2UxTest` → 5 tests / 17 assertions / 0 fail.
- **Full application suite:** `tests/Feature/Sca` → **1,588 tests / 8,155 assertions / 0 failures / 0 errors / 1 skip** (exit 0). (The shared public-Passport and collector layouts were touched, so the full suite was run.)
- The disposable environment and worktree were removed afterward; the branch ref remains locally and on origin.

## Remaining P2 findings NOT done (deferred, with rationale)
- **Duplicate/conflicting security HTTP headers** (`Referrer-Policy`, `X-Frame-Options`, `X-Content-Type-Options` each sent twice by the edge Caddy and the app) — this is an **infrastructure** change on the **live shared edge** (Caddy also fronts production smsrocket), not a customer-facing view/style, so it is outside this task's authorized scope. Recommend a separate, owner-approved edge change.
- **CSS-only tab ARIA roles** (`role="tab"/tablist/tabpanel"`) on the item-detail tabs — adding tab semantics to the no-JS radio/label tabs risks breaking the working keyboard/no-JS behavior; left as a known limitation (the tabs are already keyboard-operable as radios).
- **Public-Passport trust/safety copy** beyond the one label — intentionally not altered (it was hardened under a prior trust & safety review).
- **Public-Passport "no CTA/on-ramp"** — by CSP design (no forms/JS on the public page); left as-is.

## Safety posture (this task)
Implemented on an isolated dev branch only. No production deployment, migration, or DB write; no Shopify
API call or store change; no customer email; no customer claim or ownership change; secure claiming NOT
activated; `origin/main` NOT merged. The live checkout stayed at `6e36aa7` and clean; the production DB
is unchanged; the 205 imported records are untouched; production `vendor/` remains `--no-dev`.

**STOP — P2 customer-Passport UX improvements delivered on `feature/sca-passport-p2-ux` (`e80b386a`,
off `b758020`): accessibility (descriptive alt, sr-only/section headings, de-duplicated top heading,
`role=status/alert` flashes), clearer "SCA record status" label, and friendly claim/transfer error
pages (no raw HTTP codes, with expired-link guidance). Views-only — no auth/ownership/claim logic
changed. Isolated sandbox: full suite 1,588/8,155/0-fail/0-error/1-skip; new test 5/5. Branch pushed,
NOT deployed, NOT merged; prod `6e36aa7` intact; 205 imports untouched. Deferred: duplicate edge
security headers (infra), CSS-only-tab ARIA roles.**

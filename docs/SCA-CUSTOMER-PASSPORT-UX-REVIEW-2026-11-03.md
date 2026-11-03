# SCA — Customer Passport Interface & UX Review (read-only, 2026-11-03)

**The deployed customer experience is launch-ready and safe: the public QR Passport and the collector
(My Collection / detail / certificate / provenance / transfer) surfaces expose no private data, carry
strong security headers, present authenticity clearly with an explicit "authentication ≠ ownership"
disclaimer, and are mobile-responsive — NO P0 (no security, privacy, or critical-flow blocker) was
found in production. The real usability risk lives in the UNDEPLOYED secure-claim RC's buyer-claim +
email-verification flow, which has several dead-ends that would frustrate a self-service claimer: the
"email sent" confirmation never renders, the verification-required failure page offers no way to
verify, and there is no verify control or "email unverified" indicator on the account/login pages.
These are RC-only (claiming is not live) and are view/controller-level — fixable before the RC ever
ships, and they are the clear top priority for the claim launch. The remaining items are P2 polish
(accessibility heading/outline structure, per-field form errors, customer-friendly copy, terminology
consistency).** Read-only review; no changes made, no customer emails, no Shopify calls, no DB writes,
nothing deployed or activated; production unchanged at `6e36aa7`; the 205 imported records untouched.
**STOP.**

> Written for: the owner (Jeremy) and the external auditor reading from GitHub. Baseline: prod
> `6e36aa7`; secure-claim RC `c9a2d7d` (NOT deployed); governance `25d6aeb`.

## Method & what was actually inspected (Task: screenshots honesty)
- **Live rendered inspection (deployed):** the public Passport was fetched from the live site
  (`GET https://verify.secondchanceauthenticators.com/p/{token}`, HTTP 200, 194 KB) and its **actual
  rendered HTML/CSS/headers** analyzed. No browser/screenshot tooling was available, so **no visual
  screenshots were taken**; this is real rendered-markup inspection, not a picture.
- **Source-code review (read-only):** all collector surfaces (deployed) and all secure-claim
  surfaces (RC-only, read via `git show c9a2d7d:…`) were reviewed from source. The RC surfaces are
  undeployed and therefore not reachable as running pages.

---

## PHASE 4 — Findings (classified P0 / P1 / P2)

### P0 — Security / privacy / critical-flow blocker
**NONE.** Public Passport and collector pages render only allowlisted, owner-safe data (the Passport
presenter throws if any non-allowlisted key is emitted); logins are enumeration-safe; the transfer
invite token is reduced to a boolean on the item page; the claim token appears only in a form-action
URL. No owner/collector/staff PII, internal id, raw security token, or disk path reaches any customer
HTML. (Verified live: 0 emails, 0 "owner"/"collector"/COL-refs in the public Passport; the one 32-hex
value present is the public QR token in the image URL, which is already the public identifier.)

### P1 — Significant usability problems
| # | Route / page | Problem | Customer impact | Recommended correction | Prod or RC |
|---|---|---|---|---|---|
| P1-1 | `POST /collector/email/verify/request` → presale claim show | After clicking **"Send me a verification email"**, `request()` does `redirect()->back()` to the claim show page, which renders **no flash** — the "we've sent a link, check your inbox" message never appears. | The buyer sees nothing happen; likely re-clicks or assumes it's broken and abandons the claim. | Redirect to a page that renders the status flash (or add a `session('status')` block to the claim show view). | **RC only** |
| P1-2 | `POST /collector/claim/presale/{token}` → `unavailable.blade` (409 `BUYER_VERIFICATION_REQUIRED`) | The failure page says "sign in with the account whose VERIFIED email matches your order, then verify your email" but shows a bare **409**, has **no verify button**, and links only to **My Collection**. | A buyer who hits this path is told to verify but given no control to do so and is sent away from the claim — a dead-end. | Route this failure back to the claim/verify page (with the "Send me a verification email" control), not to My Collection; replace the raw 409 with plain-language copy. | **RC only** |
| P1-3 | `/collector/account`, `/collector/login` | There is **no email-verification entry point and no "email not verified" indicator** on the account or login pages; the only trigger is the presale claim show page. Yet `confirm()` tells users to "Request a new one after signing in." | A buyer who needs to (re)verify — e.g. the email didn't arrive — has nowhere to do it except by navigating back to the exact claim link. | Add an "email unverified → Verify now" affordance on the account page (and surface the status). | **RC only** |
| P1-4 | `GET /collector/email/verify/{token}` | `confirm()` redirects to the collector **login** page to show its success/expired flash, but login is behind `collector.guest`; an **already-signed-in** collector who clicks the link is redirected off login and **loses the flash** — no confirmation their email verified. | A signed-in buyer gets no feedback that verification succeeded (or failed). | Land verification outcomes on a page that renders the flash for both guest and authenticated collectors (e.g. account), not guest-only login. | **RC only** |
| P1-5 | Collector forms (`register`, `login`, profile, etc.) | Validation errors render **only** in one top-of-page `.err` list — no per-field messages, `aria-invalid`, or `aria-describedby`. Password rules aren't stated on the register form. | On an error, the customer must map a generic list back to fields; screen-reader users aren't told which field failed. | Render field-level errors beside inputs with `aria-describedby`; state password requirements inline. | Production |

### P2 — Minor usability / design / accessibility
| # | Route / page | Problem | Impact | Recommended correction | Prod or RC |
|---|---|---|---|---|---|
| P2-1 | Public Passport `/p/{token}` + collector pages | **Weak heading outline:** the only `<h1>` is the brand name on every page; section titles (SCA reference, warning headline, detail labels) are styled `<div>`/`<p>`, not `<h2>`. | Harder screen-reader/section navigation. | Promote section titles to real headings. | Both |
| P2-2 | Public Passport; collection grid | Item photos use **empty `alt=""`** (decorative); the actual frame image carries no description. | Blind users get no item image description. | Set `alt` to the item name for the main photo. | Both |
| P2-3 | Collector detail tabs (`collection/show`) | CSS-only tabs are radio inputs with **no `role="tab"/tablist/tabpanel"`** and no arrow-key semantics. | Announced as radios, not tabs. | Add tab ARIA (or accept as a known limitation). | Production |
| P2-4 | Collector flash messages | Success/error flash boxes are plain `<div>`s with **no `role="status"`/`alert"`** (except the transfer copy-confirmation). | Not announced to assistive tech. | Add `role="status"`/`role="alert"`. | Production |
| P2-5 | Dashboard / detail terminology | "**Registered**" stat vs "**registry** status" vs "**registered** owner" reuse one word for three meanings; "Needs attention", "Market Reference", "basis_label", "Superseded", "provenance", "SCA identity: Active" are jargon with light explanation. | Non-expert confusion. | Tighten labels; one meaning per term; brief inline glosses. | Production |
| P2-6 | Certification tab vs Overview | **Two document paths** — "Make my certificate available (PDF)" vs "Download provenance report (PDF)" — are easy to conflate. | Minor confusion about which doc is which. | Clarify the distinction in helper text. | Production |
| P2-7 | Transfer accept — expired/invalid link → `unavailable.blade` | An expired link collapses to a generic **404 "This transfer could not be found."** with no "ask the owner for a new link" guidance. | Recipient doesn't know the next step. | Add recovery guidance for expired/invalid transfers. | Production |
| P2-8 | Claim `unavailable.blade` (RC) | Shows the **raw HTTP status number** (404/409/410) in large type to the customer. | Technical, not customer-language. | Replace with plain-language messaging. | RC only |
| P2-9 | Claim views (RC) | Mixed naming "**Second Chance Authenticators**" (the SCA mark) vs "**Second Chance Eyewear order**"; `already_yours` uses a bare unstyled "View" link; claim views duplicate inline CSS and lack semantic headings/labels. | Name confusion; weak affordance; a11y gaps. | Unify naming; style the CTA; share a layout; add headings/labels. | RC only |
| P2-10 | Edge/app headers (public Passport) | Duplicate/conflicting security headers (`Referrer-Policy`, `X-Frame-Options`, `X-Content-Type-Options` each sent twice with differing values — edge Caddy + app both set them). | Harmless (browser picks one) but untidy; can trip security scanners. | Set each security header in one layer. | Production (infra) |
| P2-11 | Public Passport journey | By design there is **no CTA/on-ramp** (strict CSP forbids forms/JS) — a first-time scanner has no guided next step toward understanding ownership/registration. | A scanner can't self-navigate onward (intentional safety trade-off). | Optionally add a static, link-free informational line about what SCA is / where to learn more. | Production |

---

## 1. Current customer journey map (deployed vs RC)
```
[DEPLOYED — works today]
Scan QR → Public Passport /p/{token}
  • Sees: ✓ Authenticated & Certified · SCA ref · item · certification no./date ·
    condition · "SCA identity: Active" · "Registry: No adverse reports" ·
    disclaimer "authentication … does not establish who owns it".
  • Adverse items (stolen/invalidated/lost/retired): dominant warning FIRST.
  • No link onward (CSP-locked, PII-free, noindex).            ← journey ends here on the public page

Register / Login  (/collector/register, /collector/login)
  → My Collection (/collector/collection): stats, cards, filters, groups, empty states
  → Item detail (/collector/collection/{ref}): asset-first; Overview/Authentication/
    Certification/Documents/History tabs; "View public passport";
    "Download provenance report (PDF)"; "Make my certificate available (PDF)";
    Report-a-problem (lost/stolen/recovered).
  → Transfer when selling: owner generates a one-time link → Copy/Share out-of-band →
    recipient signs in & accepts → ownership moves; pending banner meanwhile.
    (Email-free; fully functional today.)

[RC ONLY — NOT deployed; gated on SMTP + owner deploy auth]
Buyer ownership claiming:
  Private presale/grant link → (collector.auth) claim show →
    if email unverified: "Verify your email to claim" + Send-verification button →
      challenge email → click link → (login flash) → sign in → claim → "Registered to you".
  Public QR claiming is RETIRED (410) by design — claims require the private link + verified-buyer email.
  ⚠ Dead-ends today in the RC: no "email sent" confirmation (P1-1), the verification-
    required failure is a dead-end (P1-2), no verify control on account/login (P1-3), and
    the verify-outcome flash can be lost for signed-in users (P1-4).
```

## 2. Top five improvements (ranked)
1. **Fix the RC email-verification/claim dead-ends (P1-1..P1-4).** This is the gating customer flow for
   self-service claiming; without it, real buyers get stuck with no feedback and no recovery. View/controller-only.
2. **Add a verify-email control + "unverified" indicator on the collector account page (P1-3).** Gives every
   buyer a reliable, discoverable path to (re)verify, independent of the claim link.
3. **Customer-friendly claim/transfer error pages (P1-2, P2-7, P2-8).** Replace raw HTTP codes and dead-end
   failures with plain-language copy and a clear next action ("request a new link", "verify your email here").
4. **Accessibility pass (P1-5, P2-1..P2-4):** real heading outline, per-field form errors with ARIA,
   descriptive image `alt`, and `role="status"/"alert"` on flashes — across both the public Passport and collector pages.
5. **Terminology & naming consistency (P2-5, P2-9):** one meaning for "register(ed)", gloss jargon
   ("provenance", "registry", "SCA identity"), and unify "Second Chance Authenticators" vs "…Eyewear order".

## 3. Screenshots
No visual screenshots were produced (no browser/screenshot tooling available in this read-only session).
The public Passport was analyzed from its **actual live rendered HTML/CSS/headers**; all other surfaces
were reviewed from source (the RC claim/email surfaces are undeployed and not reachable). No visual
inspection is claimed beyond the live public Passport markup.

## 4. Recommended next implementation task
**"Secure-claim RC — Claim & Email-Verification UX hardening"** (separate approval required; do NOT
implement here). Scope = view/controller/notification copy only, on the RC branch
`release/secure-claim-on-6e36aa7`, **no schema/migration/security-logic change**:
- Render the "verification email sent" confirmation where the buyer lands (P1-1); land `confirm()`
  outcomes on a page that shows the flash for signed-in users too (P1-4).
- Route `BUYER_VERIFICATION_REQUIRED` back to the claim/verify page with the Send-verification control,
  not to My Collection (P1-2).
- Add an "email unverified → Verify now" affordance + status on the account page (P1-3).
- Replace raw HTTP codes with plain-language copy; add expired-link recovery guidance (P2-7, P2-8);
  unify naming (P2-9).
This keeps the change inside the already-prepared, undeployed RC (deployment still blocked on
transactional email + separate owner authorization), is fully testable in the isolated sandbox, and
removes the main self-service-claim friction before launch. The production-side accessibility/
terminology polish (P1-5, P2-1..P2-6, P2-10) can follow as a smaller, code-only collector-UX slice.

## Safety posture (this task)
Read-only review. No production DB write; no customer email; no Shopify API call or store change; no
deployment/migration; no customer claim or ownership change; secure claiming NOT activated; no fixes
implemented. The one live request was a read-only GET of a public page. Production unchanged at
`6e36aa7`; the 205 imported inventory records untouched; secure-claim RC `c9a2d7d` remains undeployed.

**STOP — Customer-experience review complete. Deployed public Passport + collector surfaces are
launch-ready and PII-safe (NO P0). The significant usability problems (P1) are all in the UNDEPLOYED
secure-claim RC's claim/email-verification flow (no "email sent" confirmation, dead-end verification-
required failure, no verify control on account/login, lost verify flash) plus one production
accessibility gap (field-level form errors); the rest are P2 polish (headings/ARIA, image alt,
terminology, raw-HTTP-code pages, duplicate headers). Recommended next task: a view/controller-only
Claim & Email-Verification UX hardening on the RC branch before it deploys. Nothing changed; prod
`6e36aa7` intact; claiming not activated.**

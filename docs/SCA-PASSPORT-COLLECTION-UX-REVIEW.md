# SCA — Customer Passport & My Collection UX Review + One Improvement

**The customer-facing experience is already mature and launch-ready; the single highest-impact remaining
gap is that the one-time ownership-transfer link had no Copy/Share control, so I implemented exactly that
(view-only) and left everything else as deliberate backlog.** Development branch
`feature/sca-passport-collection-ux` = `19c3ca0` off production `a53eff3`; one view changed. No
production change, no DB write, no claim/transfer-security change, no email/Shopify. 2026-10-30. **STOP
for review.**

## Scope reviewed (read-only, at `a53eff3`)
Public QR Passport (`passport/show`, `layout`, `not_found`); collector `login` / `register` /
`password` / `home`; `collection/index` (My Collection), `collection/show` (item detail),
`collection/not_found`, `status-confirm`; `transfer/initiate` (manage), `transfer/accept`,
`transfer/unavailable`; collector `layout` (navigation); profile / account / public profile.

## What is already implemented and good (excluded from "gaps")
- **Public Passport:** renders only the PII-free `PassportPresenter` DTO — no owner identity/contact, no
  frame_serial, no QR/cert tokens, no internal ids, no Shopify refs, no staff data, no notes. Adverse
  registry status is the dominant, first signal (invalidated drops the green badge to a historical
  notice); authenticity badge, catalog image, current-item metadata, certification no./date, condition,
  and plain trust copy ("authentication ≠ current ownership"). Mobile-stacked. **[Step 6 PASS.]**
- **Collector auth:** `login` has Forgot-password and Create-account cross-links; a privacy-safe
  claim/transfer context banner appears mid-flow (opaque ref + safe brand/model only).
- **Home dashboard:** greeting, quick actions, owned/certified/brands stats, recent items, submissions
  summary, public-profile status.
- **My Collection:** browse-first image grid; search / brand / certification / status / sort; private
  CP-6 collections switcher + collapsed management; stats; true-empty and no-match empty states;
  pagination; cert + adverse badges per card.
- **Item detail:** asset-first (gallery with thumbnail strip), authenticity badge, Market Reference +
  value history, CSS-only tabs (Overview / Authentication / Certification / Documents / History),
  owner-safe DTOs only; **Transfer** with a **pending-transfer indicator** and manage/cancel; lost /
  stolen / recovered safety; public-profile visibility; private "organize". **[Step 7: transfer links &
  pending indicator present and accessible.]**
- **Navigation:** persistent, accessible, responsive collector nav (desktop pill bar + mobile fixed
  bottom tab bar, `aria-current`).
- Mobile usability is strong throughout (viewport-fit, no horizontal overflow at ~360px, focus-visible
  styles, lazy images).

## Prioritized genuine gaps (candidates)
1. **(CHOSEN) Transfer link had no Copy/Share control.** The one-time transfer link is the *entire*
   hand-off — SCA sends no email, so the owner must convey it out-of-band — yet it was only a read-only
   input with tap-to-select, which is fiddly and failure-prone on mobile. Highest impact for the lowest,
   safest change, and squarely in the step-7 transfer flow.
2. "Transfer pending" is only visible inside an item, not on the collection grid / home cards. (Would
   need a list-DTO field — a small service change, not view-only. Deferred.)
3. Item-detail CSS radio-tabs lack full ARIA `tab`/`tabpanel` roles (they are keyboard-operable as a
   radio group). Accessibility polish; risk of regressing a working no-JS pattern. Deferred.
4. When an item is not passport-eligible (uncertified) the detail page simply omits the passport
   button with no "why". Minor; edge case. Deferred.
5. Public-Passport share/copy would need inline script, but that page runs under a stricter CSP
   (style-src 'unsafe-inline', img-src 'self') than the collector pages — not a safe/small change.
   Deferred.

None of the above are launch blockers; #2–#5 are backlog, not defects.

## Implemented change (narrow, view-only)
**File:** `app/packages/Sca/Collector/src/Resources/views/transfer/initiate.blade.php` (only file
changed). On the owner's transfer page, when a one-time link is active:
- Added a **"Copy link"** button beside the existing read-only link input, and a **native "Share"**
  button injected by JS only where `navigator.share` exists (so no-JS users never see a dead button).
- An `aria-live="polite"` status line announces the copy/share result.
- Implementation is **progressive enhancement**: `navigator.clipboard.writeText` with a
  `select()`+`execCommand('copy')` fallback; with no JS, the read-only input + tap-to-select remains
  exactly as before. Collector pages already execute inline JS (the item gallery), so this is CSP-safe
  on this page.

**What it does NOT touch:** the transfer token, its single-use and expiry semantics, the recipient
accept flow, authorization, or any claim/transfer safeguard (R0/R0b/R0c untouched). It only copies a
link already rendered on the page. No controller/service/route/DB/migration change.

## Verification
- Only one file changed (`git status` = the transfer view alone).
- Blade compiles and the generated PHP passes `php -l` (checked against the production vendor,
  read-only). No live customer claim/transfer or production test was run.

## Safety posture
Read-only review + one view-only change on an isolated branch. No production deploy/merge/migration/DB
write; no Shopify API/store change; no real inventory import or order assignment; no customer claiming or
ownership change; no email configuration; no modification to R0/R0b/R0c buyer-verification; no Option C.
Secure-claim RC `4bd88d2` remains DEPLOYMENT-BLOCKED and untouched.

**STOP — review delivered; the customer Passport/My Collection experience is launch-ready and exposes no
owner PII, private claim tokens, or internal records; transfer links and the pending indicator are
present. One smallest-high-impact improvement implemented on `feature/sca-passport-collection-ux`
(`19c3ca0`): a Copy/Share control for the one-time transfer link (progressive enhancement, no
security/claim/transfer-logic change). Branch pushed; production unchanged at `a53eff3`. Awaiting review
before any regression/RC/deploy.**

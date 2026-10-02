# SCA Production App — end-to-end UX + functional gap audit (READ-ONLY)

**Date:** 2026-10-02 · **Production baseline:** deployed main `dff2781`, migrations **120**.
**Status: READ-ONLY AUDIT — zero changes made. For ChatGPT review. Do NOT auto-implement the first finding.**
**ACTIVE / NEXT_TASK remain unpromoted. SMTP/email explicitly DEFERRED (not touched).**

Method: three independent read-only code walkthroughs (Staff/Admin, Collector, Public-Passport + lifecycle)
over `/opt/sca-platform/app` (`packages/Sca/*`), plus live read-only security/boundary probes against
`https://verify.secondchanceauthenticators.com`. No code/DB/env/infra/provenance change. Finding IDs in
brackets trace to the per-area notes (A=Admin, C=Collector, P/B=Passport/lifecycle).

---

## 0. Headline verdict

- **No P0 code-level launch blocker found** on any of the three surfaces. The digital lifecycle is
  functionally complete and the governance/immutability model is sound (consistent with SCA-053).
- The real pre-rollout work is **P1 UX/flow + two functional gaps tied directly to the permanent-QR rollout
  and to resale**: QR reissue has no staff UI [B1], new-recipient transfer onboarding is missing [B6],
  destructive actions lack confirmation in two places [A-F3, C-F1], and staff owner identity is a raw DB id
  [A-F9].
- A pervasive **P2 theme**: the same lifecycle/registry status is worded differently (and sometimes as raw
  SCREAMING_SNAKE enums) across Admin, Collector and Passport — and two prose maps actually disagree. One
  shared label map is the fix.
- **Security/privacy posture is intact** (section 6): `/storage` denied, admin staff-IP+auth gated, passport
  allowlist + constant-shape 404 (SCA-038 Option A), no token/id/path/staff leak, Phase-B HTTPS/Secure
  cookies, :8080 retired, zero provenance mutation.
- **Almost every finding is view/controller-only, no schema change.** The handful needing backend/data or a
  governance decision are called out explicitly.

---

## 1. P0 — launch blocker

**None.** All three walkthroughs independently reached "no P0 code blocker"; remaining gaps are UX/flow
polish and feature-completeness, not correctness or safety defects. (If the business treats "a transferred or
revoked-cert item that silently 404s for the new owner" as unacceptable at launch, [B5]/[B6] escalate — see P1.)

## 2. P1 — should fix before permanent-QR / production rollout

**P1-1 [B1] — No staff UI to REISSUE a permanent QR.** `QrService::reissue()` exists and is
concurrency-safe but has no route/controller; admin can only download the SVG of the *existing* active QR
(`Registry/.../admin-routes.php:39`). A damaged/lost/reprinted permanent tag cannot be replaced through the
app. **Directly blocks real permanent-QR operations.** *Fix:* staff-ACL'd confirm→`reissue()` action (mint +
activate replacement, render new SVG), under the existing item lock. *Scope:* new Registry controller method +
route + confirm blade. *Schema:* **No** (reuses `sca_qr_identifiers`/`sca_qr_lifecycle_events`).

**P1-2 [A-F3] — Admin lost/stolen resolution is one-click, no confirmation.** `status/show.blade.php:27-38`
admin recover/**retire**/**invalidate** are inline single-click link-styled buttons with only a free-text
reason — while the *standard* terminal retire/invalidate route through a typed-word confirm interstitial
(`status/confirm.blade.php` + `TerminalStatusRequest`). Equally irreversible, inconsistent, easy to misfire.
*Fix:* route admin retire/invalidate through the same confirm + typed-confirmation. *Scope:* `StatusController`,
`status/show.blade.php`, reuse `status/confirm.blade.php`. *Schema:* **No**.

**P1-3 [C-F1] — Collector Report Lost / Report Stolen has no confirmation.** `collection/show.blade.php:151-159`
→ two prominent buttons apply a **public passport** safety warning on a single click, no "are you sure?", no
inline undo (only a separate "Mark as recovered"). High mis-click risk for a non-technical owner. *Fix:*
confirmation interstitial/typed-or-checkbox confirm before the state change; keep the reassuring "you stay the
owner" copy. *Scope:* `show.blade.php` (+ optional confirm view). *Schema:* **No**.

**P1-4 [B6] — Transfer-accept has no onboarding for a brand-new recipient.** Accept routes sit inside
`collector.auth` (`collector-routes.php:45,82-83`; `TransferController::acceptShow/accept` require a logged-in
collector). The common resale/gift case — recipient has **no SCA account yet** — bounces to login with no
"create an account to claim this item" flow, and it is unverified whether the invite URL survives through
*registration* back to accept. Legitimate transfers can be lost here. *Fix:* public accept landing that
recognizes the invite token and invites register-or-login, returning to accept after auth (preserve intended
URL across both). *Scope:* TransferController + accept view + collector guest→auth redirect. *Schema:* **No**.
*Priority:* **P1 for real resale; P2 only if the pilot cohort all pre-register.**

**P1-5 [A-F9] — Staff sees owner as a raw internal DB id, unlinked.** `eyewear/show.blade.php:183`
"Registered owner → `Collector #<id>`" (and ownership history), while the Collector Support surface addresses
collectors by opaque `COL-…` refs. Two staff surfaces use different identifiers for the same entity, and the
owner isn't a link to support. *Fix:* show the collector `COL-…` public ref and link to
`admin.sca.collector.support.show`. *Scope:* `EyewearItemController::show`/`ownershipHistory` (read join),
`show.blade.php`, `ownership-history.blade.php`. *Schema:* **No** (public ref exists; needs a join).

**P1-6 [A-F1] — Collector Support is an orphaned, unreachable surface.** `collector/support-index.blade.php`
has no menu entry and no link from anywhere; staff can only reach collector lookup by hand-typing the URL.
*Fix:* menu entry or a registry-toolbar button gated on `sca.collector.support`. *Scope:*
`Registry/src/Config/menu.php` or `eyewear/index.blade.php`. *Schema:* **No**.

**P1-7 [A-F2] — Certification has no call-to-action where operators look for it.** The only way to issue a
first cert is a link buried in a row of the **Authentication** tab (`show.blade.php:298-303`); the
**Certification** tab's uncertified state (`:320-325`) shows only prose and no action/pointer. *Fix:* explicit
"Issue certification" CTA (or a clear pointer to the Authentication tab) on the Certification tab uncertified
state. *Scope:* `eyewear/show.blade.php` (view only). *Schema:* **No**.

**P1-decide [C-F2] — "Report lost/stolen" cannot capture a reason though the backend supports one.**
`show.blade.php:151-159` supplies no field, but `ItemStatusController.php:50-56` reads/truncates an optional
`reason`. Dead parameter + lost capability. *Fix:* add an optional "What happened?" textarea **or** drop the
unused handling — decide so UI and data model agree before launch. *Scope:* `show.blade.php` (+ controller if
dropping). *Schema:* **No**.

## 3. P2 — UX / polish / consistency

**P2-1 [CROSS-CUTTING: A-F4/F10/F24, C-F5, B2, B3, B4] — Status/lifecycle terminology is inconsistent across
surfaces and sometimes raw enums; two prose maps disagree.** This is the single biggest polish theme:
- Admin shows **raw SCREAMING_SNAKE enums** in several places — lifecycle filter dropdown
  (`eyewear/index.blade.php:108`), Overview (`show.blade.php:181-182,196`), status page/queue
  (`status/show.blade.php:17,29`), collector support (`support-show.blade.php:52`), intake type — while the
  index *card* right beside the dropdown humanizes the same value. Admin is self-inconsistent (list
  "Registered" vs detail "REGISTERED") [B3].
- Collector list card shows raw `registry_state` via `ucfirst()` (`collection/index.blade.php:23-24`) while the
  detail humanizes it via `registryBanner()` [C-F5].
- The two prose maps **disagree**: passport `PassportPresenter::registryBanner()` vs collector
  `CollectionService::registryBanner()` give different wording for `disputed`/`invalidated`/`recovered` [B2];
  lifecycle reads four different ways across admin/collector/passport [B3].
- `ProjectionService::deriveLifecycleState()` returns `REGISTERED` from ownership alone, **before** considering
  certification — so a revoked-cert owned item still projects "registered/certified-flavored" to collector and
  admin (the passport independently 404s, so it isn't publicly shown) [B4].
*Fix:* extract ONE shared status→label and lifecycle→label map (in `Sca\Provenance` or `Sca\Foundation`),
decide the canonical public phrasing per state, and consume it from all three surfaces; humanize admin; make a
revoked-cert owned item distinguishable from a certified one. *Scope:* new shared support class + call sites +
admin views; [B4] also touches `ProjectionService` (projection is a rebuildable cache — a rebuild is a write/
deploy step, not a schema change). *Schema:* **No**.

**P2-2 [B5] — An item with no active certification can still be transferred.** `TransferService::accept()`
only gates on adverse *registry* status, never certification state. A revoked-cert item transfers normally;
the new owner then scans the permanent QR → bare 404, no explanation. *Fix:* decide intent — block/warn on
transfer of an item without a current issued cert, or surface a collector "no active certification" notice at
transfer time (data available via `ProjectionService::currentCertification`). *Scope:* `TransferService` guard
+ collector transfer views. *Schema:* **No**. (Pairs with [B6]/[B4].)

**P2-3 [A1] — Public passport has weak branding and almost no "what is SCA / what does this mean" trust
copy.** The most externally-facing, trust-critical page shows only a plain CSS "SCA" text mark + tagline, no
explanation of what authentication/certification means or who certified the item, and no real logo — while the
staff-only admin serves a real raster logo. *Fix:* short "About SCA verification" copy, render the real SCA
logo inline/data-URI (CSP-safe), optional non-interactive "learn more" line. *Scope:* passport blades + one
inline logo asset. *Schema:* **No**. *(Strongly recommended before marketing the permanent QR widely.)*

**P2-4 [A2] — Insider status wording on the consumer passport.** "SCA identity: Active" is internal
QR-lifecycle vocabulary (`show.blade.php:88-96`, presenter `qr_status=>'Active'`). *Fix:* relabel to consumer
language ("Verification status: Active/Live") or drop the row. *Scope:* `show.blade.php` + presenter string.
*Schema:* **No**.

**P2-5 [C-F3] — Account-anonymization success message is silently dropped.** After the most consequential
collector action, `PrivacyController.php:66-67` flashes `status_notice` but `login.blade.php:6` renders only
`session('status')` — user lands on sign-in with no confirmation it worked. Flash-key naming is inconsistent
app-wide (ItemStatusController uses `status_notice`, rendered on `show.blade.php:14`). *Fix:* standardize one
flash key. *Scope:* one line in `login.blade.php` or `PrivacyController`. *Schema:* **No**. *(Borderline P1
given gravity.)*

**P2-6 [C-F4] — No success confirmation after transfer accept / initiate / cancel.**
`TransferController.php:105/61/73` redirect with no flash; the landing views render no notice region. Recipient
accepts ownership and sees no "You now own X". *Fix:* add `status_notice` + render it on `collection/index`
and `transfer/initiate`. *Scope:* TransferController + two views. *Schema:* **No**.

**P2-7 [C-F7] — No persistent nav / sign-out on Collection and Item pages.** `layout.blade.php` brand header
is inert; sign-out lives only on `account.blade.php`. To sign out from an item a user must walk item →
collection → account → sign out. *Fix:* slim shared header (brand→home; Account + Sign out when authed).
*Scope:* `layout.blade.php`. *Schema:* **No**.

**P2-8 [C-F8] — Missing image files degrade to the browser broken-image glyph.** List thumbnail uses a
`has_image` boolean; if `image_path` is set but the file is absent (or an ordinal 404s via
`CollectionImageController.php:47`) the collector sees a broken-image icon instead of the clean "No catalog
image" placeholder. *Fix:* `onerror` fallback to `.sca-noimg`; drive the list off `image_count` (matching the
gallery route's truth). *Scope:* `index.blade.php` + `show.blade.php` (+ summary to carry `image_count`).
*Schema:* **No**.

**P2-9 [A-F12] — Catalog image management hidden in a collapsed accordion.** `show.blade.php:55` — the
upload/reorder/make-featured/delete manager renders collapsed behind "Edit catalog (SKU & images)"; a core
operator task is not discoverable. *Fix:* default-expand, or surface a "Manage images (N/8)" affordance.
*Scope:* `show.blade.php`. *Schema:* **No**.

**P2-10 [A-F15] — Icon-only gallery controls lack accessible names.** `show.blade.php:103,109` reorder
buttons are "↑"/"↓" with `title=` only, no `aria-label`. *Fix:* add `aria-label`; ensure buttons read as
buttons. *Scope:* `show.blade.php` (+ a broader a11y pass). *Schema:* **No**.

**P2-11 [A-F21/F22] — Status admin panel: three side-by-side reason inputs + link-styled buttons.**
`status/show.blade.php:26-39` — three inline forms each with its own required reason box; operator can type in
one and submit another; buttons are underline-links unlike the app's button styles → mis-click risk on
consequential actions. *Fix:* single reason + explicit action choice, proper button styling, per-action
confirm (ties to P1-2). *Scope:* `status/show.blade.php`, `StatusController`. *Schema:* **No**.

**P2-12 [A-F25] — No staff "assign/register owner" path — only a red "Correct ownership" tool.** Admin
ownership is otherwise only set by the buyer self-claim link; a staff operator who legitimately needs to
assign an owner finds only "Correct ownership…", framed as red error-fixing with a typed CONFIRM gate. *Fix:*
decide deliberately — make the self-serve claim link the prominent happy path (and document it), or add a
clearly-labeled "Register/assign owner" action distinct from "correction". *Scope:* `show.blade.php`,
`ownership-correct.blade.php`, possibly `OwnershipCorrectionController`. *Schema:* **No** (governance decision).

**P2-13 [A-F26] — `COL-…` ref inputs have no lookup/validation feedback.** `ownership-correct.blade.php:36`
and `support-index.blade.php:16` take a free-text opaque ref with no typeahead/"exists?" feedback until submit.
*Fix:* collector picker/typeahead over the existing read-only support lookup, or echo the resolved label
before applying. *Scope:* controllers + views. *Schema:* **No**.

**P2-14 [A-F32] — SCA 404/409 pages drop the operator out of admin chrome.** `error.blade.php` is a bare
standalone doc (no `x-admin::layouts`), returned by many Registry controllers; a mistyped id yields an
unbranded centered page with no sidebar. *Fix:* render as an in-layout error state, or at least brand the
standalone page (keep the deliberate explicit-Response-not-`abort()` choice for real HTTP status). *Scope:*
`error.blade.php` (+ optional in-layout variant). *Schema:* **No**.

**P2-15 [C-F6] — Registration email-uniqueness is an account-enumeration oracle.**
`RegisterCollectorRequest.php:32` (`unique:…`) surfaces "The email has already been taken.", undoing the
enumeration-safety deliberately maintained in login/forgot-password. *Fix:* security/product decision —
accept+document, or make registration enumeration-safe (generic message + notify-existing-owner). *Scope:*
`RegisterCollectorRequest` + register flow. *Schema:* **No** (unless adopting notify-existing, which needs
mail — deferred with SMTP).

## 4. P3 — future / minor

- **[A-F5]** Raw `intake_type` shown to no-view-permission users (`index.blade.php:195`). View.
- **[A-F6]** Registry index has no "showing X–Y of Z" count (`index.blade.php:203`). View.
- **[A-F13/F14]** Full raw cert/public tokens + internal ids ("From authentication #id", successor "#id")
  rendered on the staff item page (`show.blade.php:329,332,338,373`) — dev-ish; consider click-to-copy / hide
  long token. View.
- **[A-F17]** Authentication `condition_grade` not client-gated by result (server-enforced; operator learns on
  bounce). Small JS. View.
- **[A-F19]** Cert "Supersede/re-certify" uses the same red destructive button as "Revoke"
  (`certification-correct.blade.php:94`) though it's constructive. Styling.
- **[A-F29]** Document `kind` shown via raw `ucfirst()` (`show.blade.php:407`). View.
- **[A-F31]** Most admin sub-pages lack breadcrumbs (only `show.blade.php` has a mini-breadcrumb);
  inconsistent with Krayin core. Views.
- **[A-F33]** QR artifact is SVG-only download, no inline preview, no PNG for print workflows. Controller/view.
- **[A-F34]** Staff/actor shown as raw "Staff #<id>" (`show.blade.php:290`). NB memory SCA-040: human
  staff-name/email display **not authorized** → constrained; flagging only. **Schema/backend + governance
  sign-off** if ever changed.
- **[A-F8]** Create form allows an item with brand/model/serial all blank (only `intake_type` required) →
  unidentifiable rows. Consider requiring one identifier. Validation.
- **[C-F9]** Certification empty-state "no active certification" misreads for a **never-certified** item vs a
  revoked one; distinguish "not yet certified" from "no longer active". `CollectionService` + `show.blade.php`.
- **[C-F10]** "No ownership history yet." is effectively unreachable on an owned item; if it ever renders it
  signals a ledger gap — treat as an anomaly to monitor, not a benign empty state.
- **[C-F11]** Collection list ordered by opaque `public_ref` (`CollectionService::ownedItems():36`); order by
  recency or brand/model instead.
- **[C-F12]** Anonymization dead-end: blocked while owning items, and the only release is Transfer (needs a
  willing SCA-account recipient) — no "relinquish/retire to SCA" path. **Possibly schema/backend** (an
  ownerless transition) — defer.
- **[A3]** Passport has no "verified live on <date>" marker and no report-a-counterfeit/recourse line on
  success or 404 pages. Blades + presenter date.
- **[A4]** Passport `imageUrl()` gate keys off the **legacy mirror** `image_path` while the endpoint serves
  from the **gallery** table — consistent only because `CatalogGalleryService::normalize()` keeps the mirror in
  sync. **Becomes P1 the moment the legacy column is removed** (planned "legacy-col removal" slice) — flag for
  that cutover. *Fix:* gate on gallery count with legacy fallback, mirroring the controller.
- **[A5]** `passport.php:21` `SCA_PUBLIC_PREVIEW` defaults to **'1'** (banner ON) — a footgun if an env ever
  forgets to set 0. *Fix:* default 0 or tie to `APP_ENV !== 'production'`.
- **[A6]** Passport product image has empty `alt=""` and is read whole-into-memory
  (`PassportController::image():78`, bounded only by the 4MB upload cap on a 512M/no-swap host). *Fix:* `alt`
  = brand+model; optionally stream.
- **[B7]** `sca_certifications.state` is always `'issued'` even after revoke/supersede (lifecycle lives in
  events + projection). Safe today (resolver binds via `current_certification_id` AND `state='issued'`), but a
  **future query that treats `state='issued'` as "active"** would wrongly include predecessors. *Fix:* document
  the column's meaning / add a derived accessor; do NOT start filtering "active" by it. *Schema:* **No** (and
  changing it to track lifecycle is **not** recommended — fights the append-only design).

## 5. End-to-end business flow (mapped; gaps above in context)

`INTAKE (ItemService::create) → AUTHENTICATED / AUTH_FAILED (AuthenticationService draft→finalize) → CERTIFIED
(CertificationService::issue — also mints+activates the permanent QR and freezes a render snapshot) → QR
resolves publicly (PassportResolver) → ownership via claim (ClaimService: Shopify-sale or external-intake) →
REGISTERED → {transfer (TransferService) | lost/stolen/recovered (StatusService: collector + staff + admin
recovery valve) | service history (ServiceService) | commerce reversal → disputed (CommerceService) | staff
retire/invalidate}. Certification correction = revoke (no replacement) or supersede (new successor); QR
permanence preserved (CertificationCorrectionService).` All append-only; `sca_item_current_state` is a
rebuildable projection cache.

**Flow gaps that make real production use harder (all above):** QR cannot be reissued from the UI [B1];
new-recipient transfer onboarding missing [B6]; uncertified/revoked items transfer into a silent-404 dead-end
for the new owner [B5]+[B4]; lifecycle label conflates ownership with certification [B4]; no staff
assign-owner happy path, only "correction" [A-F25]; collector support unreachable [A-F1]; terminology drifts
across the three surfaces [P2-1].

## 6. Security / boundary regression — READ-ONLY confirmation (ALL PASS)

Live probes against `https://verify.secondchanceauthenticators.com` + read-only DB/host checks:

| Check | Result |
|---|---|
| Passport valid / unknown-32 / malformed | **200 / 404 / 404** — SCA-038 Option-A constant-shape 404 intact |
| `/storage/configuration/*` | **404** (edge-denied) |
| `/admin/login`, `/admin/sca/eyewear`, `/admin/sca/eyewear/1/qr` (non-staff source) | **403** (staff-IP + auth) |
| `/collector/login` | **200** (public) |
| default-deny `/ /api/x /up /install /sca/x` | **all 404** |
| `http://…` | **308 → https** |
| Set-Cookie on `/collector/login` | `XSRF-TOKEN … secure`; `sca_session … secure; httponly` (Phase B) |
| public `:8080` | **retired** — bound `127.0.0.1:8080` loopback only |
| Passport body (5681 B) | **no** 16+hex token, **no** `/storage` path, **no** `DEVELOPMENT PREVIEW`, **no** internal-leak words |
| Passport field allowlist | enforced by `PublicAllowlist` + `assertOnlyAllowlisted()`; dates day-granularity; image endpoint reuses the same resolver |
| Collector privacy/ownership scoping | every read keyed on `current_owner_collector_id`; detail/image/document/transfer/status fail-closed to identical privacy-safe 404; DTOs strip ids/tokens/paths/staff/reasons/other-owners |
| Provenance state (read-only) | tokens unchanged (`bee93d2b…` id1, `10c739b7…` id2), is_production **0,0**, items 2, certs 3, cert_events 4, gallery_images 3, migrations 120 — **zero mutation** |

No raw DB id / token / storage path / internal staff metadata leaks to collector or public surfaces. Gallery
remains single-source-of-truth (`sca_eyewear_item_images`, legacy mirror kept in sync by
`CatalogGalleryService::normalize()` — see [A4] for the one latent coupling). No QR/provenance/cert/auth/
ownership mutation occurred during the audit.

---

## 7. Recommended sequencing (for review — not a decision)

1. **Permanent-QR-rollout gating P1s:** [B1] QR reissue UI, [A-F3]+[C-F1] destructive-action confirmations,
   [B6] new-recipient transfer onboarding (if resale is in-scope for the pilot), [A-F9] owner `COL-…` ref,
   [A-F1] reach Collector Support, [A-F2] Certification CTA, decide [C-F2].
2. **Consistency sweep P2-1:** one shared lifecycle/registry label map across all three surfaces (fixes a
   large cluster at once), plus [B4]/[B5] certification-vs-ownership clarity and [A1]/[A2] passport trust copy
   + branding.
3. **P2 polish:** collector nav/flash/empty-image, admin accordion/a11y/error-page/assign-owner.
4. **P3** as capacity allows; **re-flag [A4] and [A5]** at the legacy-column-removal and any new-env cutovers.

Each item above is a candidate for its own governed task (read-only plan → GO → feature branch → pre-merge
review → governed merge/deploy). **No implementation is authorized by this audit.**

**AUDIT ONLY — zero changes. Awaiting ChatGPT review. ACTIVE/NEXT_TASK remain unpromoted. Do NOT auto-implement
the first finding.**

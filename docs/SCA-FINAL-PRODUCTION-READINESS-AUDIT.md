# SCA App — final production-readiness gap audit (READ-ONLY)

**Date:** 2026-10-02 · **Deployed baseline:** main `af84b0a`, migrations **120**.
**Status: READ-ONLY AUDIT — zero changes; no DB write / status action / QR reissue / projection rebuild /
mutation. For ChatGPT review. ACTIVE / NEXT_TASK remain unpromoted. SMTP intentionally deferred (not a
blocker — no shipped workflow requires it to function).**

Method: three fresh, independent read-only journey re-audits (Admin, Collector, Public-Passport) against the
*current* code at `af84b0a` (not the old finding list), plus a live security/invariant regression. Every old
candidate re-checked and classified.

---

## 1. LAUNCH VERDICT

**SCA is functionally ready for controlled real-customer use today.** The complete digital lifecycle —
intake → authentication → certification → permanent-QR (download + reissue) → catalog/gallery → status &
owner-orphaned recovery → sale/claim → ownership → transfer (incl. new-recipient onboarding) → lost/stolen/
recovered → retire/invalidate → public passport — is implemented end-to-end, ACL-gated, append-only, with
destructive-action confirmations, and the security/privacy invariants all hold. **No P0 found on any surface.**
The only P1 is a one-line discoverability fix (Collector Support menu link). Everything else is P2 post-pilot
UX or P3 cosmetic. **Launch is gated on operations, not code:** permanent-QR physical printing/attachment and
SMTP (password-reset email) are deferred operator decisions, and one product decision (how prominently the
public passport warns on an adverse-but-certified item) is worth settling before wide rollout.

## 2. Unresolved findings (ranked; conservative)

### P0 — cannot launch
**None.**

### P1 — fix before normal customer rollout
- **[A-P1] Collector Support surface is unreachable.** Routes (`admin.sca.collector.support.index/show`) +
  ACL (`sca.collector.support`) exist, but there is **no menu entry and no link** anywhere — reachable only
  by typing the URL (`Registry/src/Config/menu.php` contributes only `sca-eyewear`). The pilot handed collector
  support to human operators, and this is the shipped tool for it. *Fix:* one menu entry (or a registry-toolbar/
  owner-line link) gated on `sca.collector.support`. **No schema.** (P1 because it's the operator support tool;
  P2 only if collector lookup isn't in the pilot runbook.)

### P2 — worthwhile UX/product improvement after pilot
- **[C-P2] Anonymization success confirmation is silently dropped.** `PrivacyController::destroy` flashes
  `status_notice`, but the login view renders only `session('status')` — after an irreversible account
  anonymization the collector lands on sign-in with **no confirmation it worked**. *Fix:* one line (align the
  flash key). No schema. (Minor correctness/UX; the action itself succeeds.)
- **[A-P2] Admin owner shown as raw `Collector #<id>`.** `eyewear/show.blade.php:183` + ownership-history
  render the internal sequential DB id, inconsistent with the opaque `COL-…` ref used elsewhere on staff
  surfaces. *Fix:* render the collector `COL-…` public_ref (don't collapse to "Registered to a collector" on
  the ledger — the A→B→A distinction is needed). No schema (public_ref exists). Staff-only, not unsafe.
- **[A-P2] First-certification CTA discoverability.** Issuing a first cert is only reachable from a row inside
  the **Authentication** tab; the **Certification & QR** tab's uncertified state shows prose but no action.
  *Fix:* add an "Issue certification" CTA/pointer on the Certification tab. View-only, no schema.
- **[A-P2] Collector-Support surface still shows raw enums.** The one staff surface the `ItemStateLabels`
  rollout missed: raw account `status` (`support-index.blade.php:32`, `support-show.blade.php:15`) and raw
  `registry_status` (`support-show.blade.php:52`). *Fix:* route through `ItemStateLabels`. View-only, no schema.
- **[P-P2 — PRODUCT DECISION] Adverse registry status has no prominence on a certified passport.** The resolver
  does not gate on `registry_status`, so a **lost/stolen/disputed** item that still holds a current issued cert
  renders a normal 200 passport with a prominent green "✓ Authenticated & Certified" badge and the warning as a
  quiet trailing "Registry: …" row. Data is shown and nothing leaks — but a stolen-yet-certified item reading
  green is a trust/UX risk. *Fix (operator call):* surface an adverse `registry_status` as a visible colored
  banner near the top. View-only, data already in the DTO. **This is primarily a business/product decision on
  how loudly to warn** (and interacts with the deliberate *recovered-reads-clear* public-privacy rule).

### P3 — cosmetic / technical cleanup
- **[C-P3] Broken-image fallback.** `<img>` tags (list thumb, detail main + thumb strip) have no `onerror`
  placeholder; if a DB row's file is absent on disk the collector sees a broken-image glyph instead of the
  clean "No catalog image" placeholder. Edge case (gallery-stored images), view-only fix.
- **[C-P3 / A-P3] Accessibility.** Low-contrast muted text `#94a3b8` (~2.6:1, fails WCAG AA) on collector refs/
  dates/SKU; empty `alt=""` on product images (collector + passport); CSS-radio tabs lack ARIA
  tablist/tab/tabpanel roles. Cosmetic; journey works.
- **[C-P3] Never-certified vs revoked wording.** Collector Certification-tab banner reads identically for a
  never-certified and a revoked item (the authenticity badge *does* distinguish them). Wording-only.
- **[C-P3 / N2] List vs detail image-presence can disagree** for an un-backfilled legacy row (list `has_image`
  from legacy `image_path`; detail `image_count` from gallery rows). Latent (backfill + mirror cover it today).
- **[P-P3 — LATENT] Passport `imageUrl()` gates on the legacy `image_path`** while `PassportController::image()`
  serves from the gallery (`CatalogGalleryService`). Consistent only because `normalize()` mirrors the primary
  back to the legacy column on every gallery mutation. **Becomes a REAL public-image regression the moment the
  planned legacy-column-drop slice runs** — fix by gating `imageUrl()` on the gallery (with legacy fallback) at
  that time. Flag for the legacy-column cutover.
- **[P-P3 — DEFENSIVE] `SCA_PUBLIC_PREVIEW` default is fail-open.** `config/.../passport.php` defaults to `'1'`
  (banner ON); prod is safe only because `.env` explicitly sets `0`. If the env var is ever lost on a redeploy/
  new host the "DEVELOPMENT PREVIEW" banner would show publicly. *Fix:* default to `'0'` and set `'1'`
  explicitly only on the preview host. One-line config.
- **[A-P3] Bare standalone admin error page** (`Registry/.../error.blade.php` not in `x-admin::layouts`) — drops
  the admin shell; deliberate (real-Response, bypasses Krayin's handler), functional. Cosmetic.
- **[A-P3] Raw `intake_type`** (`sce_presale`/`external_intake`) on the item page/index while the create/filter
  dropdowns humanize it — inconsistent; duplicate Overview registry-status row; raw `Staff #<id>` (staff-only).

## 3. Old findings now classified ALREADY RESOLVED (removed from the active list)
- **Passport provenance/authenticity now derives from the current-certification fact** (not `lifecycle_state`),
  via the shared `ItemStateLabels`; never claims more than a finalized-passed-auth + current-issued-cert.
- **Cross-surface terminology** centralized in `ItemStateLabels` (registry/certification/ownership/QR/
  lifecycle); the two divergent registry prose maps are gone; admin raw SCREAMING_SNAKE on the index card,
  both filter dropdowns, Overview and status queue/detail is fixed.
- **Destructive-action confirmations** live: collector lost/stolen/recovered + admin resolve/adminRecover
  (Level-1 explicit confirm) and 024 adminRetire/adminInvalidate (Level-2 typed word) — no one-click mutation.
- **QR reissue** has a governed staff UI (dedicated ACL, typed-REISSUE confirm, under-lock expected-active
  guard, reprint via the existing download).
- **New-recipient transfer onboarding** works (invite survives register/login via session `url.intended`,
  bearer token, no email dependency, privacy-safe context on the auth screens).
- **Former-owner claim/`already_yours` + access** correct: canonical current-ownership, former owner →
  `already_owned`/404 everywhere; concurrency fail-closed under lock.
- **Uncertified/revoked-cert transfer** handled: transferable (only registry-adverse blocks), and the new
  owner is never dropped onto a bare 404 — the passport link is gated on active-QR + current cert, so a
  revoked item simply shows no passport link.
- **recovered-reads-clear** public-privacy policy preserved; **SCA-038** constant-shape 404 intact.
- Collector surfaces leak **no** DB ids/tokens/paths/staff refs (opaque `public_ref` + `DocumentHandle` only).

## 4. Journey assessment (Admin → Collector → Passport)
- **Admin:** complete and ACL-gated across the full lifecycle; confirmations + append-only semantics sound.
  Gaps are discoverability/labels only (Collector Support menu P1; owner `COL-ref`, first-cert CTA, support-
  surface enums P2; error-page/intake_type/staff-id P3).
- **Collector:** strong — authorization, privacy-safe 404s, canonical labels, onboarding, destructive-action
  interstitials, revoked-cert/transfer handling all correct. Only real gap is the dropped anonymization
  confirmation (P2); rest is P3 polish (broken-image, contrast/ARIA, wording).
- **Public Passport:** security/privacy posture intact (constant-shape 404, default-deny allowlist, cert-fact
  wording, locked CSP/headers, recovered-clear). Decision-worthy items are product/operations: adverse-status
  prominence (P2 product), trust copy/logo (P3 product), fail-open preview default (P3), legacy-image coupling
  (P3 latent). No public logo today (the admin logo route is under the staff-IP-restricted `/admin*`, so it
  can't be reused publicly — a public passport logo needs its own public route or an inline data-URI).

## 5. Security / invariant regression (live, read-only) — ALL PASS
| Invariant | Result |
|---|---|
| SCA-038 constant-shape passport | `/p` valid 200 / 200; bogus / malformed / traversal → 404/404/404 |
| revoked/reissued QR behavior | by design: non-active token → 404 (resolver active-QR check); covered by tests (SCA-038 / QrReissueTest); not live-exercised (no mutation) |
| current-owner authorization & previous-owner privacy | every owner-scoped read keyed on `current_owner_collector_id`; former owner → identical privacy-safe 404 (verified in code across all reads) |
| `/storage` denial | `/storage/configuration/*` → 404 |
| Admin staff-IP restriction | `/admin/login`, `/admin/sca/eyewear`, `/admin/sca/eyewear/1/qr` → 403 from non-staff source |
| HTTPS + Secure cookies (Phase B) | `http→https` 308; `XSRF-TOKEN` secure; `sca_session` secure+httponly |
| public `:8080` retired | bound `127.0.0.1:8080` loopback only |
| gallery authorization | collector ordinal route owner-scoped; admin gallery ACL-gated (code-verified) |
| destructive-action confirmations | live (collector + admin interstitials; code + prior deploy verified) |
| no token/path/DB-id leak (public/collector) | passport body (5881B): no `/storage` path, no non-self token, no collector/owner/staff id, no email; collector DTOs strip all internal data |
| default-deny edge | `/ /api /up /install /sca` → 404 |
| zero mutation during audit | migrations 120; QR tokens `bee93d2b…`/`10c739b7…` is_prod 0,0; qr_lifecycle 2×activated; status_events 6; certs 3 / cert_events 4 / ownership 4; gallery 3 — unchanged |

## 6. Recommended next 3 tasks (priority order)
1. **Make Collector Support reachable (P1).** Add the menu entry / link (ACL-gated). *Why:* it's the shipped
   operator support tool and is currently URL-only — the only thing gating a clean customer-support operation.
   Tiny, safe, view/config-only.
2. **Admin + Collector presentation hardening bundle (P2).** Owner `COL-…` ref instead of `Collector #<id>`,
   first-certification CTA on the Certification tab, Collector-Support surface through `ItemStateLabels`, and
   the dropped anonymization confirmation. *Why:* these are the real staff-usability + one collector-feedback
   gaps; all view/controller-only, no schema, and they finish the terminology/consistency work.
3. **Public passport trust + safety pass (P2 product, then P3 fixes).** Decide + implement adverse-status
   prominence on a certified passport, add "what is SCA / what this proves" trust copy + a public logo
   (data-URI), and flip `SCA_PUBLIC_PREVIEW` to fail-safe. *Why:* the passport is the most externally-facing,
   trust-critical surface; it's correct and safe but under-explains SCA to a first-time scanner and under-warns
   on adverse-but-certified items. Needs an operator product decision first.

## 7. Operator / business decisions (not code fixes)
- **Permanent-QR physical printing & attachment** — deferred; a manual operator step (SVG download → print →
  affix); not a code gap. Pilot item-1 artifact already prepared.
- **SMTP / password-reset email** — deferred; recommended plan (Postmark-over-SMTP + DNS) already audited. No
  shipped workflow is broken without it (reset is code-complete; mail just logs).
- **Adverse-status passport prominence** (how loudly to warn publicly on a stolen-but-certified item), and
  **how much to explain SCA publicly** (trust copy / logo) — product decisions.
- **Is collector-support lookup in the pilot operator runbook?** (determines whether [A-P1] is P1 vs P2.)

**AUDIT ONLY — no changes, nothing promoted to implementation. Awaiting ChatGPT review.**

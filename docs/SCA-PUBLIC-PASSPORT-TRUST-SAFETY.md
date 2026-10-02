# SCA Public Passport — Trust + Safety UX (PUSH-ONLY)

**Date:** 2026-10-02 · **Base:** deployed main `a594ea8`, migrations **120**.
**Status: DONE — reviewed (PASS), merged `--no-ff`, and DEPLOYED `cbde6d2` 2026-10-02.** (History below kept
as the push-only review record.) Implements `SCA-PUBLIC-PASSPORT-TRUST-SAFETY-AUDIT.md` (gov `f6de530`).
Presentation only.

---
## DEPLOYMENT RESULT (2026-10-02)
**Independent pre-merge review: PASS** (candidate `68f7a47`, base `a594ea8`).

**Fail-closed re-gate (all held):** origin/main `a594ea8`; candidate local==origin `68f7a47`; merge-base
`a594ea8`; ahead 1/behind 0; clean tree; exactly the reviewed 8-file scope; forbidden-change guards
(migrations/routes/**PassportResolver**/core/vendor/infra) all 0.

**Pre-merge full suite:** `tests/Feature/Sca` **784 passed (4328 assertions), 0 failed**.

**Governed merge + deploy:** `git merge --no-ff` → **MERGE_SHA `cbde6d2`**, pushed origin/main;
`scripts/deploy-preview.sh` exit 0 (full-suite gate re-passed under `set -e`), "Deployed main @ cbde6d2",
kr-app not recreated (code-only; Phase-B loopback intact). **MERGE_SHA == ORIGIN_MAIN == DEPLOYED_HEAD ==
`cbde6d2`; migrations 120.**

**Post-deploy verification (non-mutating; no production status mutation; stash not reapplied):**
- **Zero prod mutation:** `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4` (== baseline) · migrations 120 · gallery 3
  · status_events 6 · QR tokens unchanged is_production 0,0.
- **Live CLEAR passport (runtime, `/p/<valid>`):** green "Authenticated &amp; Certified" badge present; registry
  "No adverse reports on the SCA registry"; **no** adverse banner; trust copy (ownership disclaimer) present;
  **logo rendered as an inline `data:image/...` URI**; **zero leakage** — no `/storage` URL, no `configuration/`
  path, no active-QR token in body, no owner/collector/staff/email marker, no `<script>`.
- **ADVERSE presentation (structural + test evidence; no prod state mutated):** deployed `show.blade` renders the
  `role="alert"` warning banner (line 36, `registry_headline`/`registry_body`) **before** the authenticity badge
  (line 42) in the `@if ($adverse)` branch; the 14 `PublicPassportSafetyTest` cases (warning-before-authenticity
  via `assertSeeInOrder` for lost/stolen/disputed/retired/invalidated, stolen ownership disclaimer, recovered→
  publicly clear, retired/invalidated still 200, 404 paths, privacy absence, logo-data-URI-not-/storage,
  no-JS/CSP, preview-default-off, zero mutation) passed in both the pre-merge and deploy-gate full runs against
  this exact code. Deployed presenter carries the approved wording verbatim (REPORTED LOST / REPORTED STOLEN +
  "Authentication does not establish current ownership" / UNDER REVIEW / RETIRED FROM THE SCA REGISTRY / RECORD
  INVALIDATED); `recovered`→normalized CLEAR preserved; severity map deployed; `SCA_PUBLIC_PREVIEW` default `'0'`.
  **`PassportResolver` diff a594ea8→cbde6d2 = 0 lines (byte-identical).**
- **Live regression:** `/p/<valid>` 200, `/p/<bogus>` + `/p/<malformed>` 404 (SCA-038 constant shape);
  `/storage/x` 404; `/admin/login` 403 (staff-IP boundary); `/collector/login` 200; `http→https` 308; Secure
  cookies present; loopback `:8080` 302 while public `195.26.255.80:8080` 000 (retired); co-tenant smsrocket.io
  302; kr-app + kr-mariadb healthy.

**Outcome:** Public Passport trust+safety UX LIVE — adverse registry status is now the dominant signal. Zero
production provenance/domain mutation; resolver & 200-vs-404 policy unchanged. The Retired/Invalidated 200-vs-404
resolver-policy task remains a separate, unstarted operator/domain decision.

---

## Candidate
- **SHA (HEAD):** `68f7a47` · **Branch:** `origin/sca-passport-trust-safety`
- **Base / merge-base:** `a594ea8` (verified `git merge-base HEAD a594ea8 == a594ea8`), 1 commit, 8 files.
- **File scope (+452/−19):** `Passport/Config/passport.php`, `Passport/Http/Controllers/PassportController.php`,
  `Passport/Presenters/PassportPresenter.php`, `Passport/Support/PublicAllowlist.php`,
  `Passport/Resources/views/passport/{layout,show}.blade.php`,
  `Provenance/Support/ItemStateLabels.php`, `tests/Feature/Sca/PublicPassportSafetyTest.php` (new).
- **No** `PassportResolver` change, **no** route/migration/schema/ACL/core/vendor/env/`/storage`/infra change.

## What changed (presentation only)

1. **Registry safety is the dominant signal.** When the public-normalized registry status is adverse, the
   `show.blade` renders a **color-coded warning banner FIRST and strongest**, *before* the authenticity block, so
   a stolen/invalidated item can never read as all-clear just because it is authentic. Clear/recovered keep the
   positive green presentation. Severity tiers (new pure map `ItemStateLabels::registrySeverity()`): `warning`
   (lost, disputed), `danger` (stolen), `invalid` (invalidated), `retired` (retired), `clear` (normal/recovered).
2. **Approved public wording** (presenter `registryCopy()`): **REPORTED LOST** / **REPORTED STOLEN** (+ "Authentication
   does not establish current ownership") / **UNDER REVIEW** / **RETIRED FROM THE SCA REGISTRY** / **RECORD
   INVALIDATED** ("no longer valid … should not be relied upon"). Authenticity/certification/QR facts stay present
   and truthful, just secondary when adverse.
3. **Retired & invalidated still render 200** — the resolver and the 200-vs-404 policy are **unchanged** (that is a
   separate domain decision, explicitly out of scope).
4. **`recovered` privacy rule preserved** — normalized to CLEAR **once** in the presenter; every public registry
   field (label, severity, headline, body) derives from that same normalized value, so no loss/recovery history is
   exposed. Canonical stored status is untouched.
5. **SCA trust copy** added to `show.blade`: "This digital passport records authentication and certification
   information for this item. Authentication confirms the item examined by SCA; it does not establish who
   currently owns or possesses it." No owner info.
6. **SCA logo** served **inline as a `data:` URI** read server-side from the configured logo (same one the admin
   surface uses), via `PassportController::brandLogoDataUri()`. **Never** a `/storage` URL or disk path (the page
   carries only inert base64). CSP-compatible (`img-src 'self' data:`). Text-mark fallback when unconfigured and on
   the 404 page (so no per-404 disk read; every 404 stays byte-identical). *Rationale for data-URI over a route:
   `p13` forbids a tokenless route under `/p/`, and the edge only admits `/p/*`+`/collector/*`, so a logo route is
   blocked both ways — the audit's inline Option 2 is the only edge-safe + invariant-safe mechanism.*
7. **`SCA_PUBLIC_PREVIEW` default flipped `'1'`→`'0'`** (fail-safe) in `config/passport.php`. Prod already sets `0`
   explicitly, so **no prod behavior change** — defensive hardening only.
8. **New presenter keys** `registry_severity`/`registry_headline`/`registry_body` are derived/static, non-PII, and
   **added to `PublicAllowlist`** (the default-deny assertion still holds).

## Tests
- **New `PublicPassportSafetyTest` (14):** normal→clear; recovered→publicly clear + no history; lost/stolen/
  disputed/retired/invalidated → prominent warning rendered **before** authenticity (`assertSeeInOrder`), with the
  stolen ownership disclaimer and the retired/invalidated **200** (resolver unchanged); uncertified→404; reissued-
  old-QR + malformed + unknown→404; adverse page introduces **no** owner/collector/staff/internal/frame_serial/
  `configuration/`/`/storage` data; logo inlined as `data:image/...;base64,` and **never** a storage path;
  no-JS/CSP (`default-src 'none'`, no `script-src`, `no-store`); **preview default OFF when env unset**; adverse
  GET causes **zero** domain mutation.
- **Existing suites green & unchanged:** `PublicPassportTest` (18, incl. allowlist/404-shape/preview-toggle/no-
  enumeration), `PublicPassportPilotTest` (lost/stolen still SEE their registry label), `ItemStateLabelsTest`.
- **Results:** focused passport suites 46/46; **full `tests/Feature/Sca` → 784 passed (4328 assertions), 0 failed.**
  `php -l` clean on all changed PHP.

## Restoration + zero-production-mutation proof
Pilot restored to deployed main `a594ea8` after push: `git checkout main` (HEAD `a594ea8`, tree clean),
`composer install --no-dev`, `config:clear`+`route:clear`. Candidate **not live**: `show.blade`/presenter/
`ItemStateLabels` have no `registry_severity`/`registrySeverity`; config preview default is `'1'` (candidate's
`'0'` absent); `PublicPassportSafetyTest.php` absent from the working tree.
- Canonical prod fingerprint **byte-identical**: `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4` (== baseline) ·
  migrations **120** · gallery **3** · status_events **6** · QR tokens unchanged is_production 0,0.
- Restored-pilot smoke: loopback `:8080 → 302`; edge `/p/<valid> → 200`, `/p/<bogus> → 404` (SCA-038 constant
  shape), `/storage/x → 404`; the live valid passport shows no candidate banner markers.

## Boundaries honored
No resolver/eligibility/200-vs-404 change · no SCA-038 change · no status/QR/cert/auth/ownership/registry-state
change · no owner identity / collector-staff-id / PII / storage path exposure · no `/storage` change · no new
contact/reporting workflow · no SMTP · no schema/migration · no Caddy/Docker/firewall/DNS · no Collector/Admin
change · no QR regen. Branch from exactly `a594ea8`; **COMMIT + PUSH ONLY — not merged, not deployed.**

## Next
Independent pre-merge review of `68f7a47`. On GO: governed `--no-ff` merge + `scripts/deploy-preview.sh`, then
closeout. **Do not begin the Retired/Invalidated resolver-policy (200-vs-404) task** — that remains a separate
operator/domain decision (OP-DECISION-1 in the audit).

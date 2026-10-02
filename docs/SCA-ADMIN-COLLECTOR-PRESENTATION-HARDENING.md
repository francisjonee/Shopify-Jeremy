# SCA Admin + Collector presentation hardening (P2 bundle) — PUSH-ONLY

**Date:** 2026-10-02 · **Base:** deployed main `236acd9`, migrations **120**.
**Status: IMPLEMENTED + TESTED + PUSHED. NOT merged, NOT deployed. For independent review.**
Implements the four P2 findings from `SCA-ADMIN-COLLECTOR-PRESENTATION-HARDENING-AUDIT.md` (gov `455ef98`).

## Candidate
- **SHA (HEAD):** `c8f9410` · **Branch:** `origin/sca-presentation-hardening`
- **Base / merge-base:** `236acd9` (verified `git merge-base HEAD 236acd9 == 236acd9`).
- **Commit structure (2 commits, presentation-only):**
  - `011bf12` — **Finding 1** (the bundle's only controller/read-model change; kept isolated as required).
  - `c8f9410` — **Findings 2 + 3 + 4** + new test + existing-test wording updates.
- **File scope (12 files, `236acd9..c8f9410`):** 292 insertions / 34 deletions. No migration, no route, no
  ACL, no Krayin core/vendor, no env/Docker/Caddy.

## Findings implemented

### F1 — Admin owner shown by opaque `COL-…` ref, never the internal DB id
The four `Collector #<db id>` presentations (item overview, ownership-history current-owner + per-row, and the
ownership-correction confirm page) now render the collector's opaque `public_ref`. Smallest read-only join only
(`sca_collector_accounts.public_ref` keyed by id; a single batched `whereIn(...)->pluck('public_ref','id')` for
the history rows) — no extra collector fields, no PII. Where an owner ref is shown, it deep-links to the
**existing** Collector Support detail **only if** staff holds `sca.collector.support`; otherwise it is plain
text. The numeric DB id never appears in rendered Admin UI. Ownership-ledger semantics preserved, including the
canonical **A → B → A** case (both distinct owners appear by ref; the terminal `transfer_out` still renders
"ownership ended"; current owner unchanged).
- `EyewearItemController::show()` / `ownershipHistory()` + new private `collectorRef(?int)` helper;
  `presentOwnershipHistory()` now carries a per-row `owner_ref`.
- `OwnershipCorrectionController::confirm()` passes `currentOwnerRef` (replacing `currentOwnerLabel`).
- Views: `eyewear/show.blade.php`, `eyewear/ownership-history.blade.php`, `eyewear/ownership-correct.blade.php`.

### F2 — First-certification CTA surfaced on the Certification & QR tab
For an **uncertified** item the Certification & QR tab now surfaces the **existing** certification-issue action
when an eligible finalized **passed** authentication exists and no QR identity is present yet. It POSTs the
**same** `admin.sca.eyewear.certification.issue` endpoint behind the **same** `sca.eyewear.certify` ACL as the
Authentication tab — **no** second path/controller/route/service. Hidden when already certified, when no eligible
authentication exists, or when staff lacks `sca.eyewear.certify`.
- View only: `eyewear/show.blade.php`.

### F3 — Collector Support uses canonical item labels; account status humanized independently
The (now-reachable) Collector Support index/detail no longer echo raw enums. Item certification and registry
status render via the canonical `ItemStateLabels::certificationShort()` / `registryShort()`. Account **lifecycle**
status is humanized independently via `ucfirst()` (**not** routed through `ItemStateLabels`, which is for item
state). The raw `registry_status` value is retained only inside the red-highlight `@if in_array(...)` condition,
so colour logic is unchanged. No change to search/data/ACL/routes.
- Views only: `collector/support-index.blade.php`, `collector/support-show.blade.php`.

### F4 — Anonymization success reaches the collector-login success message
`PrivacyController::destroy()` now flashes under `status` (the key `collector/login.blade.php` renders) instead
of `status_notice`, so the confirmation is actually shown after the redirect to `collector.login.show`. Feedback
wiring only — anonymization behavior, privacy, auth, and DB mutation are unchanged (verified: `login.blade`,
`account.blade`, `password/forgot.blade` all read `session('status')`).
- Controller only: `Collector/.../PrivacyController.php` (one flash key).

## Tests
- **New:** `tests/Feature/Sca/PresentationHardeningTest.php` — 6 tests covering F1 (overview COL-ref + gated
  support link, numeric-id never rendered; ownership-history A→B→A distinction + gated link), F2 (CTA shown for
  uncertified+eligible-auth; hidden when certified or no eligible auth), F3 (canonical item labels + humanized
  account status), F4 (success flashes `status` → login screen shows "permanently anonymized").
- **Existing-test wording updates** (old raw presentation → new canonical wording; no behavior assertion
  removed): `OwnershipHistoryTest` (`Collector #<id>` → `public_ref` on admin surfaces; the one admin
  ownership-history assertion corrected from `assertDontSee` → `assertSee(public_ref)` + `/Collector #\d/`
  non-match; public-passport & collector-surface `assertDontSee` kept), `OwnershipCorrectionTest`,
  `CollectorSupportTest` (`cs8` raw `pseudonymized` → humanized `Pseudonymized`).
- **Results:** focused suites 63/63; **full `tests/Feature/Sca` → 770 passed (4264 assertions), 0 failed.**
  `php -l` clean on all changed PHP. (The historically flaky `QrReissue/QrArtifact` random-token QR decode
  passed on the green run.)

## Restoration + zero-production-mutation proof
Pilot restored to deployed main `236acd9` after push: `git checkout main` (HEAD `236acd9`, tree clean),
`composer install --no-dev`, `config:clear` + `route:clear`. Candidate code is **not live**:
- `show.blade` "Issue certification" CTA absent; `PrivacyController` still flashes `status_notice`;
  `support-show` still shows raw `{{ $collector['status'] }}` / "Not certified" / raw `registry_status`;
  `PresentationHardeningTest.php` absent from the working tree.

Canonical prod fingerprint (same combined `AFTER_FP` used at the `236acd9` deploy) **byte-identical**:
- `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4` (== the `236acd9` baseline) · migrations **120** · gallery **3**
  · status_events **6** · both QR tokens unchanged with **is_production 0,0**.
- Runtime smoke on the restored pilot: loopback `:8080 → 302` (healthy), edge `/p/<bad> → 404`
  (SCA-038 Option-A constant-shape), `/storage/x → 404` (edge-denied).

## Boundaries honored
No schema/migration · no ownership/certification/authentication/status/QR/gallery **semantic** change · no
projection rebuild · no new routes · no ACL modification or broadening · no Collector/public data expansion · no
Passport work · no SMTP · no env/Docker/Caddy/firewall/DNS · no Krayin core/vendor change. Feature branch from
exactly `236acd9`; **COMMIT + PUSH ONLY — not merged, not deployed.**

## Next
Independent pre-merge review of `c8f9410`. On GO: governed `--no-ff` merge + `scripts/deploy-preview.sh`, then
closeout. Do **not** begin the Passport trust/safety task.

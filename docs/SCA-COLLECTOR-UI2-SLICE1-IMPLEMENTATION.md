# SCA Collector Experience / UI 2.0 — Slice 1 Implementation Evidence (pre-merge, R1)

**Status:** R1 REMEDIATION pushed — awaiting ChatGPT re-audit. NOT merged, NOT deployed. Presentation / navigation / read-model only; **no migration**, no new domain capability.

| | |
|---|---|
| Governance promotion | `6e8cf9fd72c1c7d46b9091df679071bcd09696d9` |
| Pre-merge audit (FAIL R1) | `5a04ae1062702b7e458784f882f2c6464cbb1d8c` |
| Implementation branch | `feat/sca-collector-ui2-slice1` (one commit ahead of base, 0 behind) |
| Exact production base SHA | `9cf72728248cf3e36d0525de4520d69717dacd5d` (migration 138) |
| Prior candidate (FAILED R1) | `b69824f712ede30c159c444b7ca41946f05b7332` |
| **NEW candidate SHA** | **`0c8628d352f9a0fb843774bff5281bc808a9248c`** |
| Migration | **none** (138 unchanged — read-model/presentation only) |
| Focused tests | `CollectorExperienceTest` 15 + `AppPolishTest` 6 (p6 updated) → **21 passed** |
| Full `tests/Feature/Sca` | **1335 passed / 1 skipped / 0 failed** |
| Production provenance FP (unchanged) | `d15a5cbdfb8df52ba65628b276533cfe`, counts `3/3/4/4/5/2/1/1/7`, migration 138 |

## R1 remediation — truthful submission-progress summary (only this changed)
The accepted shell / Home architecture / navigation / ownership scoping / privacy / images / routes / domain behavior are **unchanged**. The sole fix is Home's user-visible submission metric.

**Defect:** the metric labelled "In progress" counted only `draft/submitted/awaiting_item`. But `received` is terminal only in the submission *state machine* — the bound item still proceeds through authentication / certification / claim / return after physical receipt. So a `received` submission (e.g. awaiting examination) was reported as not-in-progress — materially misleading.

**Fix (Option 2 — labels exactly true from canonical submission status; no downstream/result/payment invention, no new state):** the projection now exposes two active categories plus the total:
- **"Awaiting receipt by SCA"** = `draft` + `submitted` + `awaiting_item` (pre-receipt).
- **"Received & being processed"** = `received` — shown as its **own active category**, never as completed/inactive.
- **"Total submissions"** = all; `cancelled` is only part of the total and is never labelled "completed".

So a `received` submission is always presented as actively being processed regardless of the bound item's downstream stage, and nothing implies completion. `CollectorDashboardService` returns `{total, pre_receipt, received}`; the Home view renders the three truthful lines.

**R1 tests (assert user-visible label/count semantics, not just a constant):**
- `ce12` — full status matrix: draft/submitted/awaiting_item → pre_receipt; received → received; cancelled in neither (only total).
- `ce13` — a `received` submission with the collector's bound-item work at each downstream stage (awaiting examination / passed-not-certified / certified) stays counted as "Received & being processed"; the page never shows Completed/Finished/Done.
- `ce14` — a `received` submission with a failed/inconclusive authentication is still "received & being processed", not completed.
- `ce15` — another collector's submissions never affect counts.
- `ce8` updated to the new labels/keys; `ce10` keeps zero-mutation.

## What changed (7 files)
- `packages/Sca/Collector/src/Resources/views/layout.blade.php` — authenticated primary nav (Home/Collection/Authenticate/Profile/Account): desktop pill bar + mobile fixed bottom tab bar (CSS only, no JS), active section via `aria-current` derived from the route name, visible keyboard focus, body bottom-padding on mobile; rendered **only** under the `collector` guard.
- `packages/Sca/Collector/src/Services/CollectorDashboardService.php` *(new)* — bounded read-only dashboard projection over existing readers.
- `packages/Sca/Collector/src/Http/Controllers/HomeController.php` — `/collector` now renders the Home view for an active collector (was a redirect).
- `packages/Sca/Collector/src/Resources/views/home.blade.php` *(new)* — the Home dashboard.
- `packages/Sca/Collector/src/Routes/collector-routes.php` — `collector.home` route moved into the `collector.auth` group (same name + path `/collector`).
- `tests/Feature/Sca/CollectorExperienceTest.php` *(new, 11)*; `tests/Feature/Sca/AppPolishTest.php` — `p6` updated to the new Home contract.

## Information architecture
`/collector` = authenticated **Home** dashboard; **Collection** = existing My Collection; **Authenticate** = existing submissions area; **Profile** = existing profile; **Account** = existing security/privacy. Existing route names, controllers and the rich item-detail experience are preserved; Account is no longer the de-facto navigation hub.

## Home dashboard read model (existing readers only; no new table)
- greeting from the collector's `display_name`;
- owned / certified / distinct-brand counts straight from `CollectionService::collectionStats` (same semantics the Profile page uses);
- a small recent collection preview (≤4) from the same canonical `CollectionService::catalog` reader (membership = current ownership only), each card linking to canonical item detail with its image via the **authorized** `collector.collection.image` route (the item's real stored path is never emitted);
- external-authentication submission summary (total + in-progress over the canonical `draft/submitted/awaiting_item` set; `received`/`cancelled` are terminal) scoped to the collector; no payment/provider state invented;
- public-profile publication summary + link to Profile;
- primary actions: View collection / Submit eyewear.
- **Pending-transfer tile omitted**: no safe collector-wide pending-transfer read exists in Slice 1 (only a per-item `pendingInviteToken`), and the promotion explicitly allows omission rather than inventing one.

## Boundaries / privacy preserved
- Guest `/collector` → sign-in (via `collector.auth` → `redirect()->guest`); authenticated active collector → Home; disabled/pseudonymized session logged out and redirected (fail-closed) before Home renders.
- Nav never appears on guest auth pages (collector guard false there) and public pages use a separate layout.
- No change to CSRF/throttle/collector-guard/current-owner/opaque-ref/privacy rules, to transfer/status/submission/payment/claim/provenance semantics, or to Market Reference. No staff/admin nav or Krayin chrome. No public-profile/passport redesign. No SMTP/Stripe/notifications/analytics/backups.

## Test → evidence map (mandatory list)
| Requirement | Test |
|---|---|
| guest `/collector` → sign-in; authenticated → Home | ce1, ce2 (+ AppPolish p5/p6) |
| nav on authenticated pages, not on guest auth pages | ce3 |
| active nav state for child/detail routes | ce4 |
| dashboard stats collector-scoped + canonical semantics | ce5 |
| preview owned-only, authorized image route, no raw path | ce6 |
| preview excludes previous/non-owner items | ce7 |
| submission summary collector-scoped + truthful | ce8 |
| empty-state safe (no display name / no items / no submissions) | ce9 |
| dashboard GET zero provenance/current-state/domain mutation | ce10 |
| disabled/pseudonymized/unauthenticated fail-closed | ce11 |
| existing collection/item/profile/submission/transfer/status/auth suites green + full gate | full `tests/Feature/Sca` 1331 passed |

## Responsive / accessibility
Mobile-first ~360px→desktop with no horizontal shell/dashboard overflow (mobile bottom tab bar, 5 equal items; desktop pill bar); semantic `<nav aria-label>`, current page via `aria-current` + filled pill + weight (not colour alone); visible `:focus-visible` outlines; text nav labels (no ambiguous icons on security controls); images use the existing authorized/no-store route with empty `alt` + "No catalog image" fallback; no raw storage paths/internal IDs/secrets/PII rendered.

## Production-untouched proof
Live tree restored to `main@9cf7272`, vendor `--no-dev`, `/admin/login → 200`. Prod DB migration 138 (`…create_sca_market_reference_events`), provenance FP `d15a5cbd…` / counts `3/3/4/4/5/2/1/1/7` unchanged; no schema change (no migration added). All work ran on the disposable `sca_domain_test` DB only.

**STOP — awaiting ChatGPT R1 re-audit of candidate `0c8628d`. Do not merge or deploy; do not start another initiative.**

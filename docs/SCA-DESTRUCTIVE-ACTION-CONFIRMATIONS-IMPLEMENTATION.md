# SCA Destructive-action confirmations — implementation (PUSH-ONLY, awaiting pre-merge review)

**Date:** 2026-10-02 · **Base:** deployed main `daf7c65`, migrations **120**.
**Status: IMPLEMENTED + TESTED + PUSHED. NOT merged, NOT deployed. No production status action executed.**
**For independent pre-merge review.** Audit: gov `cb400d6`. Implemented exactly within the audited boundaries.

## Candidate identity
- **Candidate SHA:** `ed784073f5ad4d53dffb397df5b4db9a8bae37b0`
- **Branch:** `origin/sca-destructive-confirmations` (impl repo `francisjonee-sca-platform-private`)
- **Base / merge-base:** `daf7c65da0b44a0ec266c71e0b782d89bda0c326` (both equal → clean, 1 commit)

## Actions covered
- **Level 2 (typed word + required reason):** SCA-024 owner-orphaned **adminRetire** (typed `RETIRE`),
  **adminInvalidate** (typed `INVALIDATE`).
- **Level 1 (explicit `confirm`, no typed word):** Collector **Report Lost / Report Stolen / Report
  Recovered** (reason optional); Admin **Resolve** (reason now required); Admin **adminRecover** (reason
  already required).
- Standard admin **Retire/Invalidate** unchanged (already Level 2). No admin Lost/Stolen setter added.

## File scope (4 new + 12 modified; NO schema/migration, NO service/workflow semantic change, NO Krayin
core/vendor, NO permission broadening, NO QR/gallery/SMTP/infra/.env/Caddy/Docker)
New: `Sca/Collector/.../Http/Requests/CollectorStatusConfirmRequest.php`,
`Sca/Collector/.../views/collection/status-confirm.blade.php`,
`Sca/Registry/.../views/status/confirm-simple.blade.php`,
`tests/Feature/Sca/DestructiveActionConfirmationTest.php`.
Modified (source, 8): collector `ItemStatusController` (+confirm GET methods, POST→CollectorStatusConfirmRequest,
inject CollectionService for ownership-scoped GET), collector `collection/show.blade.php` (one-click forms →
confirm links), collector `collector-routes.php` (3 GET confirm routes), admin `StatusController` (+4 confirm
methods + 2 confirm helpers; adminRetire/Invalidate→TerminalStatusRequest; adminAct→FormRequest), admin
`StaffStatusRequest` (reason required + confirm), admin `AdverseRecoveryRequest` (+confirm), admin
`status/show.blade.php` (one-click forms → confirm links), admin `admin-routes.php` (4 GET confirm routes).
Modified (tests, 4): `LostStolenTest`/`StatusAdminTest`/`AdverseRecoveryTest` status POST helpers inject the
new `confirm`/typed-word/reason by default; `AdverseRecoveryTest`/`CollectorItemDetailParityTest`/
`StatusAdminTest` three `assertSee` routes → `.confirm`.

## Design notes (as audited)
- Server-enforced via the established SCA GET-interstitial + `FormRequest` pattern (never JS/`confirm()`).
  Level 2 reuses `status/confirm.blade.php` + `TerminalStatusRequest` (its `expectedConfirmation()` keys off
  the route name, so `…admin.retire`→`RETIRE`, `…admin.invalidate`→`INVALIDATE`). Level 1 POSTs require an
  explicit `confirm=1` field (supplied only by the interstitial), so a blind/one-click POST fails validation.
- The item pages now LINK to the interstitials; direct one-click mutation is gone from the UI, and the POST
  guard blocks a crafted direct POST.
- **No expected-state/version guard added** (per the audit): the workflows already lock the projection row,
  re-read status under the lock, enforce the transition matrix, and are idempotent — a stale GET→POST only
  no-ops or fails closed (409); the target is fixed by the route. A **previous owner's** stale confirmation
  after transfer still fails closed — the POST re-checks ownership under the lock, and the new confirm GET is
  itself ownership-scoped (opaque 404 via `CollectionService::ownedItemByRef`). The 024 valve confirm GET is
  offered only for an owner-orphaned lost/stolen item (`isAdministrativelyResolvable`), else 409.

## Tests
- **New `DestructiveActionConfirmationTest` — 13/13 (67 assertions):** collector confirm pages render the
  intended action/item + `confirm` field; unconfirmed collector POST → `confirm` validation error, no
  mutation; confirmed Lost then Recovered → exact transitions + exactly one `sca_status_events` append each +
  **zero collateral** (ownership / certification / QR identities+tokens+is_production / gallery unchanged);
  previous-owner-after-transfer → confirm GET 404 and POST 404 with no mutation; non-owner confirm → 404;
  unauthenticated → collector login redirect; admin 024 terminal confirm pages require the typed word; admin
  terminal POST with missing/wrong word or missing reason → no mutation; confirmed typed INVALIDATE+reason →
  exactly one event + zero collateral; valve confirm GET 409 for a non-orphaned item; adminRecover + Resolve
  require `confirm` (+reason); wrong-perm staff → 403.
- **Full `tests/Feature/Sca` — 753 passed (4155 assertions), exit 0** (baseline `daf7c65` 740/4074 → +13).
  Updated the existing status suites (LostStolen/StatusAdmin/AdverseRecovery/CollectorItemDetailParity) to the
  new confirmation contract; `PilotHardeningTest` (standard terminals) unchanged and green. `php -l` clean on
  all changed source. Tests run in-container as uid 33:33 on the disposable `sca_domain_test` DB (hard guard).

## Production restoration & no-candidate-live proof (after testing)
- Working tree restored to `main` = `daf7c65`; `composer install --no-dev`; `config:clear` + `route:clear`
  (uid 33:33). Code-only on the bind mount → kr-app not recreated; Phase-B loopback intact; no stash re-apply.
- Candidate code **absent on main:** the 4 new files absent; `route:list` shows **no** `…/confirm` status
  routes; `StaffStatusRequest` back to `reason` nullable (0 `confirm` occurrences); `AdverseRecoveryRequest`
  back to reason-only.
- **Live edge:** `/p/bee93d2b…` 200, `/p/bogus` 404 (SCA-038), `/collector/login` 200, `/storage` 404,
  `/admin/sca/status/*` 403 from a non-staff source; kr-app `127.0.0.1:8080` loopback-only, healthy; MariaDB
  private.
- **Production status/provenance unchanged (no status action executed; tests ran only on `sca_domain_test`):**
  `sca_status_events` = 6 (pre-existing operator history — item1 `normal`/owner none/activeQr 1; item3
  `recovered`/owner 1/activeQr 2); QR identities 2 (`bee93d2b…`, `10c739b7…`, is_production 0,0); QR lifecycle
  2; certifications 3; gallery 3; migrations 120.

**STOP after push. Not merged/deployed; next P1 not started. Awaiting independent pre-merge review of
`ed78407` (base `daf7c65`).**

---

## DONE — MERGED (--no-ff) + DEPLOYED 2026-10-02

Pre-merge review = PASS/GO. Fail-closed gate re-checked: origin/main `daf7c65`, candidate local+origin
`ed78407`, merge-base `daf7c65`, ahead 1 / behind 0, clean tree, reviewed 16-file scope, no
migration/service-semantic/ACL/core/vendor/QR/gallery/SMTP/env/infra change.

**MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `f85e8c5a3d935c6909f315cac4590f82d783e1bd`** (governed `--no-ff`
merge of `ed78407` onto base `daf7c65`). Deployed via `scripts/deploy-preview.sh` (exit 0): mandatory gate
**full tests/Feature/Sca 753 passed (4155 assertions)** incl. `DestructiveActionConfirmationTest` PASS, before
any production change; **`Nothing to migrate` — migrations remain 120**; `Deployed main @ f85e8c5`. Code-only on
the bind-mounted `app/` → kr-app NOT recreated (uptime unchanged); Phase-B loopback bind intact; public-bind
stash NOT re-applied.

**Deploy note (flaky gate, no production impact):** the FIRST `deploy-preview.sh` run aborted at the test gate
on `QrArtifactTest::rg2` with `DECODE_FAILED: checkAndNudgePoints …` — a known random-token QR rasterize/decode
flake, unrelated to this change (which touches no QR code). `set -e` aborted BEFORE any production migrate/
build/recreate, so production was untouched. Re-ran `QrArtifactTest` ×3 → 10/10 each (confirmed flaky), then
re-ran the deploy unchanged → clean pass (gate 753/4155). LESSON: this QR decode gate is occasionally flaky;
a bare deploy re-run clears it.

**Post-deploy verification (all PASS; NON-MUTATING — no status action executed):**
- All 7 confirm routes live: collector `status/{lost,stolen,recovered}/confirm` (→ `CollectorAuthenticate`);
  admin `resolve/confirm` + `admin/{recover,retire,invalidate}/confirm` (→ `ScaAuthorize:sca.eyewear.status`).
  No admin Lost/Stolen setter route exists. Standard `status/{ref}/{retire,invalidate}` (+confirm) and the QR
  download + reissue routes remain registered.
- Structural (deployed views): collector `collection/show.blade` has **0** direct status-POST forms and **3**
  confirm links; admin `status/show.blade` has **4** confirm links (resolve + the three 024 valve actions);
  `status/confirm.blade` carries the typed-word + reason contract. Behaviors (typed RETIRE/INVALIDATE,
  required reason, explicit confirm, previous-owner stale → 404, valve 409 for non-orphaned) are proven by the
  deploy gate's `DestructiveActionConfirmationTest`.
- Live regression: `/p/bee93d2b…` 200, `/p/10c739b7…` 200, `/p/bogus` 404, `/p/short` 404 (SCA-038 constant
  shape); `/storage` 404; `/admin/sca/status/*` 403 from a non-staff source; `/collector/login` 200;
  `http→https` 308; `secure` cookie present (Phase B); public `:8080` retired (`127.0.0.1:8080` loopback only);
  kr-app + kr-mariadb healthy.
- **ZERO production mutation — AFTER == BEFORE (`55ed32ebc5a27f7d592a2c4e02388c26`):** `sca_status_events` 6;
  projection (item1 normal/owner none/activeQr1/no-cert excluded; item3 recovered/owner1/activeQr2) unchanged;
  QR identities 2 (`bee93d2b…`, `10c739b7…`, is_production 0,0); QR lifecycle 2; certifications 3; cert events
  4; authentications 3; ownership events 4; gallery 3; migrations 120.

Phase-B production state preserved. **COMPLETE. STOP — next P1 not started.**

# SCA QR Reissue — staff UI implementation (PUSH-ONLY, awaiting pre-merge review)

**Date:** 2026-10-02 · **Base:** deployed main `dff2781`, migrations **120**.
**Status: IMPLEMENTED + TESTED + PUSHED. NOT merged, NOT deployed. No production reissue executed.**
**For independent pre-merge review.** Readiness audit: gov `7c597e1`. Design approved GO with the
expected-active concurrency guard REQUIRED.

## Candidate identity
- **Candidate SHA:** `83dbfdf1f64dd3b84f6f12889b82cf17cdf8d4e5`
- **Branch:** `origin/sca-qr-reissue-ui` (impl repo `francisjonee-sca-platform-private`)
- **Base / merge-base:** `dff27812d95698a54287d4268010d911cfe08b50` (both equal → clean fast-forwardable, 1 commit)

## Exact file scope (5 new + 8 modified; NO schema/migration, NO Krayin core/vendor, NO .env/infra)
New:
- `packages/Sca/Provenance/src/Exceptions/QrReissueRejection.php` — safe domain rejection (STALE / NO_ACTIVE).
- `packages/Sca/Registry/src/Http/Requests/QrReissueRequest.php` — reason + typed `REISSUE` + `expected_active_qr_id`.
- `packages/Sca/Registry/src/Http/Controllers/QrReissueController.php` — confirm() + reissue(); orchestrates only.
- `packages/Sca/Registry/src/Resources/views/eyewear/qr-reissue-confirm.blade.php` — typed-word interstitial.
- `tests/Feature/Sca/QrReissueTest.php` — 11 regression tests.

Modified (source):
- `packages/Sca/Provenance/src/Services/QrService.php` — new `reissue()` signature + under-lock guard (below).
- `packages/Sca/Registry/src/Config/acl.php` — new permission `sca.eyewear.qr.reissue` (sort 15).
- `packages/Sca/Registry/src/Routes/admin-routes.php` — GET confirm + POST, item `[0-9]+`, dedicated ACL.
- `packages/Sca/Registry/src/Resources/views/eyewear/show.blade.php` — "Reissue QR" link on the Cert & QR tab,
  gated on the new ACL, shown only when an active QR exists.

Modified (tests — updating the 4 existing `reissue()` callers to the new signature):
- `tests/Feature/Sca/PublicPassportTest.php`, `QrArtifactTest.php`, `PassportCatalogImageTest.php`,
  `ProvenanceDomainTest.php`.

`git diff --name-only dff2781..83dbfdf` touches **no** `*Migrations*`, `packages/Webkul`, `vendor`,
`composer.json/lock`, `.env`, Docker or Caddy. (SMTP untouched.)

## Behavior implemented (matches the approved design + locked requirements)
- Dedicated ACL `sca.eyewear.qr.reissue` (distinct from `sca.eyewear.view`/`sca.eyewear.certify`). Both verbs
  are gated by it; the "Reissue QR" link renders only with the permission.
- `GET sca/eyewear/{id}/qr/reissue/confirm` → interstitial: red irreversible warning, required reason, "type
  REISSUE", hidden `expected_active_qr_id` (the active QR the screen was built against). Shown only when the
  item has an active QR (else a constant 409 "unavailable" page; creates nothing). Soft amber advisory when
  there is no current issued certification. The raw active token is never printed.
- `POST sca/eyewear/{id}/qr/reissue` → `QrReissueRequest` validates server-side (reason required, `confirm`
  must equal `REISSUE`, `expected_active_qr_id` required int); the controller calls `QrService::reissue()` and
  maps `QrReissueRejection` to a privacy-safe redirect back to confirm. Staff ref is session-derived.
- **Reprint uses the EXISTING `admin.sca.eyewear.qr` download** (active-QR-driven) — no second mechanism added.

### Concurrency guard (REQUIRED — service-level, not controller-only)
`QrService::reissue(int $itemId, int $staffRef, int $expectedActiveQrId): QrIdentifier`, in ONE transaction:
1. `lockItem()` — `SELECT … FOR UPDATE` on the item's `sca_item_current_state` row.
2. read the active QR under the lock; `null` → `QrReissueRejection::NO_ACTIVE`.
3. **assert `active === expectedActiveQrId` under the lock**; mismatch → `QrReissueRejection::STALE` — BEFORE
   any identity is minted or any event appended.
4. only then `createIdentity($itemId, $prev->is_production)` **inside the transaction** (carries the previous
   active QR's `is_production`), append `revoked`(old) + `reissued_from`(new, `replaced_qr_identifier_id`=old)
   + `activated`(new), `rebuild()`, return the new identity.

So a stale/double POST (active already rotated) fails closed with **no second rotation and no orphan identity**
(the mint is after the guard and within the same txn, so a guard failure rolls back / never runs it). The
controller holds no QR lifecycle logic.

## Exact authorized mutation per successful reissue (verified by rg5/rg8)
QR identities **+1** (new immutable row, new token, `is_production` carried); lifecycle events **+3** =
`revoked`(old) / `reissued_from`(new→old) / `activated`(new); projection `active_qr_identifier_id` old→new;
old identity row **byte-identical**; new token **differs**; old public token immediately follows the
**SCA-038 constant-shape 404**; new token resolves the **same** item/passport; the existing download follows
the new active QR. **Unchanged:** `current_certification_id`, `current_owner_collector_id`, lifecycle_state,
`sca_certifications`, `sca_authentications`, `sca_ownership_events`, gallery, migrations/schema.

## Tests
- **Focused `QrReissueTest` — 11/11 (62 assertions):** rg1 confirm renders typed-word + expected-active (no
  raw token); rg2 ineligible 409 creates nothing without an active QR; rg3 unauth→login redirect & wrong-perm
  →403 on both verbs; rg4 missing reason / wrong confirm word / missing expected-active → no mutation; rg5 the
  exact before/after mutation + event sequence/semantics + old row immutable + one active interval; rg6
  old-token 404 / new-token 200 same item; rg7 existing download tracks the new active QR (recomputes; old
  token never plaintext); rg8 certification/authentication/ownership untouched (owner preserved via a real
  claim); rg9 **stale/double-submit fails closed — B stays active, no QR C, no extra identity, no extra
  events**; rg10 staging `is_production` carried; rg10b production `is_production` carried.
- **Full `tests/Feature/Sca` — 740 passed (4074 assertions), exit 0** (baseline `dff2781` was 729/4006 →
  +11 for QrReissueTest; the 4 updated callers pass). `php -l` clean on all new/changed source.
- Tests run in-container as uid 33:33 against the disposable `sca_domain_test` DB (hard guard).

## Production restoration & no-candidate-live proof (after testing)
- Working tree restored to `main` = `dff27812…` (`dff2781`); `composer install --no-dev` (phpunit/dev pruned);
  `config:clear` + `route:clear` as uid 33:33. Code-only change on the bind mount → kr-app **not** recreated;
  Phase-B loopback bind intact (no public-bind stash re-applied).
- Candidate code **absent on main:** QrReissueController / QrReissueRejection / qr-reissue-confirm.blade /
  QrReissueTest all absent; `route:list` shows **no reissue route**; `QrService::reissue` on disk is the old
  3-arg signature with **0** occurrences of the guard/exception.
- **Live edge:** `/p/bee93d2b… → 200`, `/p/bogus → 404`, `/admin/sca/eyewear/1/qr/reissue/confirm → 403`
  (edge /admin allowlist; route also absent on live), `/storage → 404`; kr-app `127.0.0.1:8080` loopback-only,
  healthy; MariaDB private.
- **Production provenance unchanged (zero mutation):** QR identities = 2 (`bee93d2b…`, `10c739b7…`),
  **is_production 0,0**; lifecycle events = 2, **both `activated`** (no reissue ever executed in prod);
  items 2, certs 3, cert_events 4, gallery 3, migrations 120. No QR regenerated; nothing printed.

**STOP after push. Not merged/deployed; next P1 not started. Awaiting independent pre-merge review of
`83dbfdf` (base `dff2781`).**

---

## DONE — MERGED (--no-ff) + DEPLOYED 2026-10-02

Pre-merge review = PASS/GO. Fail-closed gate re-checked: origin/main `dff2781`, candidate local+origin
`83dbfdf`, merge-base `dff2781`, exactly 1 candidate commit, clean tree, 13-file declared scope, no
migration/schema, no Krayin core/vendor, no .env/Docker/Caddy/firewall/SMTP/infra.

**MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `daf7c65da0b44a0ec266c71e0b782d89bda0c326`** (governed `--no-ff`
merge of `83dbfdf` onto base `dff2781`). Deployed via `scripts/deploy-preview.sh` (exit 0): mandatory gate
**full tests/Feature/Sca 740 passed (4074 assertions)** incl. `QrReissueTest` PASS (rg1–rg10b), run BEFORE any
production change; **`Nothing to migrate` — migrations remain 120**; `composer install --no-dev`; config/route
clear; `Deployed main @ daf7c65`. Code-only change on the bind-mounted `app/` → **kr-app NOT recreated**
(uptime unchanged), Phase-B loopback bind intact; **public-bind stash NOT re-applied**.

**Post-deploy verification (all PASS; NON-MUTATING — no reissue executed):**
- Routes live: `GET admin/sca/eyewear/{id}/qr/reissue/confirm` + `POST admin/sca/eyewear/{id}/qr/reissue`,
  both bound to `ScaAuthorize:sca.eyewear.qr.reissue`; existing `admin.sca.eyewear.qr` download still
  registered. ACL permission `sca.eyewear.qr.reissue` present.
- Structural (deployed code): confirm blade carries the typed `REISSUE` word + `reason` + hidden
  `expected_active_qr_id` fields; the "Reissue QR" control on the show Cert&QR tab is gated on the new ACL.
  (ACL-insufficient / confirmation-structure / reason-required behaviors are proven by the deploy gate's
  QrReissueTest rg1–rg4; a live staff-source admin exercise is an operator confirmation — this session cannot
  originate from a staff IP.)
- Live edge: `/p/bee93d2b…` 200, `/p/10c739b7…` 200, `/p/bogus` 404, `/p/short` 404 (SCA-038 constant-shape);
  `/storage` 404; `/admin/sca/eyewear/1/qr/reissue/confirm` and `/admin/sca/eyewear/1/qr` → 403 from a
  non-staff source (staff-IP boundary intact); `http→https` 308; `/collector/login` 200 with
  `secure`+`httponly` cookies (Phase B); public `:8080` retired (`127.0.0.1:8080` loopback only); kr-app +
  kr-mariadb healthy.
- **ZERO production provenance mutation — AFTER == BEFORE (`e913cb91cb14b79eed1c65b466d8a36d`):** QR
  identities 2 (tokens `bee93d2b…`, `10c739b7…`), is_production 0,0; lifecycle events 2 (both `activated` — no
  reissue performed); active assignments 1:1,3:2; certifications 3; certification events 4; authentications 3;
  ownership events 4 (owners 1:-, 3:1); gallery 3; migrations 120. The +1 identity/+3 events delta will occur
  only when an operator performs a real reissue later.

Phase-B production state preserved. **COMPLETE. STOP — next P1 not started.**

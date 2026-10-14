# SCA QR Reissue Reason — Audit-Integrity Fix — Implementation Evidence (pre-merge)

**Status:** CANDIDATE pushed — awaiting ChatGPT independent pre-merge audit. NOT merged, NOT deployed. The additive migration was applied to the **disposable `sca_domain_test` DB only**; **production was NOT migrated** and no production data changed.

| | |
|---|---|
| Governance task | `393bdddae6690e4714649e0c3e35d725c76eb4e6` (from audit `docs/SCA-STAFF-COLLECTOR-OPS-AUDIT.md` P1 #1) |
| Exact base (origin/main, reconfirmed) | `1c6c1e6cc0167cf1fc1d87f2a12446a219664f55` |
| Branch | `fix/sca-qr-reissue-reason` (1 ahead / 0 behind) |
| **Candidate SHA (head)** | **`7848b58573c9702ad2f76f45795d882929b97a1f`** |
| Files changed vs base | **4** (172 insertions, 3 deletions) |
| Focused tests | `QrReissueTest` **17 passed** (11 existing + 6 new reason tests), 96 assertions |
| Full `tests/Feature/Sca` | **1386 passed / 1 skipped / 0 failed** (7342 assertions) |
| Production | untouched — migration **138** / 0 pending, FP `d15a5cbdfb8df52ba65628b276533cfe`, loopback 200 |

## Problem (from the audit)
`QrReissueRequest` requires a staff reason for the irreversible QR rotation, but the reason was dropped: `QrReissueController::reissue` never passed it, `QrService::reissue` had no reason parameter, and `sca_qr_lifecycle_events` had no column for it — so operator justification for rotating a permanent QR identity was never persisted.

## Files changed (4) — bounded to migration + service + controller + tests
1. `app/packages/Sca/Provenance/src/Database/Migrations/2026_10_20_000001_add_reason_to_sca_qr_lifecycle_events.php` *(new)* — additive, forward-only.
2. `app/packages/Sca/Provenance/src/Services/QrService.php` — `reissue()` accepts + stores the reason.
3. `app/packages/Sca/Registry/src/Http/Controllers/QrReissueController.php` — threads the validated reason.
4. `app/tests/Feature/Sca/QrReissueTest.php` — 6 new regression tests (rr1–rr6).

No other files touched: no unrelated UX, no Stripe/mail/Shopify, no refactor of passport/ownership, no infrastructure.

## Design
- **Which event holds the reason:** exactly ONE per rotation — the canonical **`reissued_from`** replacement event (the new identity that records `replaced_qr_identifier_id`). The `revoked` (old QR) and `activated` (new QR) events of the same rotation carry `NULL`.
- **Migration (additive, forward-only):** adds a nullable, bounded `reason VARCHAR(500)` after `replaced_qr_identifier_id`, plus a defense-in-depth CHECK `chk_qr_reason_only_on_reissue` = `reason IS NULL OR event_type = 'reissued_from'`. It does not rewrite the create migration, does not backfill, does not alter existing rows, and relaxes no constraint. The QR lifecycle ledger is append-only by application contract (inserts only, no UPDATE/DELETE trigger); nothing here weakens that.
- **Service:** `reissue(int $itemId, int $staffRef, int $expectedActiveQrId, ?string $reason = null)` — the new 4th parameter is **nullable with a default**, so all existing 3-arg direct callers (7 tests across passport/artifact/print/provenance suites) remain valid and store `NULL` (the "careful adaptation"). The reason is trimmed and normalized to `NULL` when blank/absent, then stored on the `reissued_from` insert inside the **same rotation transaction**, under the existing `FOR UPDATE` lock and the expected-active STALE guard, so it is atomic with the rotation and rolls back with it. It is never written to the QR payload, public passport, collector views, or logs.
- **Controller / request:** the request already requires a trimmed non-empty `reason` (max 255, blank rejected in `prepareForValidation`); the controller now passes `$data['reason']` through. (Column 500 > validation 255, so no truncation.)

## Tests (new rr1–rr6, disposable `sca_domain_test`, hard DB guard)
- **rr1** — reason persisted on exactly the `reissued_from` event; `revoked`/`activated` carry NULL; certification/authentication/ownership counts unchanged by the rotation.
- **rr2** — whitespace-only reason rejected (`reason` validation error) with zero mutation (no identity, no event, active QR unchanged, no reason row).
- **rr3** — historic/backward compatibility: a 3-arg direct `QrService::reissue()` (no reason) is accepted and stores `NULL` (the nullable column + CHECK accept a reasonless rotation).
- **rr4** — defense-in-depth: a raw insert placing a `reason` on a non-`reissued_from` event is rejected by the CHECK (`QueryException`).
- **rr5** — stale/double POST appends no second `reissued_from`/reason (exactly one reason row remains; fails closed to the confirm screen with a flashed error).
- **rr6** — the staff reason never appears on the public passport (`/p/{new token}`) or the owner's collection detail.
- Existing rg1–rg10b (old QR 404 / new QR 200, exact event sequence, authorization, stale guard, cert/auth/ownership untouched, production-flag carry) remain green.

## Migration compatibility & deployment considerations (NOT executed on production)
- **Applied only to `sca_domain_test`** for the test gate (`php artisan migrate --force` with `DB_DATABASE=sca_domain_test`). Production `sca_krayin` remains at migration **138**, 0 pending, provenance FP `d15a5cbd…` unchanged, loopback `/admin/login` 200.
- **On a future owner-authorized deploy**, this is a single additive column + one CHECK. It is safe to apply online to the live table: every existing row satisfies the CHECK (all current rows have `reason = NULL` — non-`reissued_from` events trivially, and any historic `reissued_from` events were written before this column existed, so NULL). No backfill is performed or needed. Migration count would move **138 → 139**.
- **Rollback:** `down()` drops the CHECK then the column (reverses cleanly; any reasons captured post-deploy would be lost on rollback, as expected for an additive column).
- No deployment, production migration, live QR rotation, or pilot was performed. Deployment/migration requires separate owner authorization.

**STOP — awaiting ChatGPT independent pre-merge audit of candidate `7848b58`. Do not merge, deploy, run the production migration, or start another initiative.**

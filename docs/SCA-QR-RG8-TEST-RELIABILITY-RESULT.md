# SCA QR Reissue `rg8` Test Reliability — Implementation Evidence (pre-merge)

**Status:** CANDIDATE pushed — awaiting ChatGPT independent pre-merge audit. NOT merged, NOT deployed. **Test-only** change; no production PHP/service/projection/migration/config/dependency/infrastructure change; no production data mutation; no pilot.

| | |
|---|---|
| Governance promotion | `cc4cf4934b266235e398ecbd44618ef1c94eb292` |
| Exact baseline (origin/main) | `9a7db357572600ddaeff8caa4fde5c1a8b6d273c` (confirmed before branching) |
| Branch | `fix/sca-qr-rg8-test-reliability` (1 ahead / 0 behind) |
| **Candidate SHA** | **`1bc301eacc5b0d427a6f7e19e22ba201c3002216`** |
| Changed files | **1** — `app/tests/Feature/Sca/QrReissueTest.php` (+22 / −3) |
| Focused tests | `QrReissueTest` + `QrArtifactTest` → **21 passed**; `rg8` repeated **3× green** |
| Full `tests/Feature/Sca` | **1380 passed / 1 skipped / 0 failed** (7310 assertions) |
| Production | untouched; test DB `sca_domain_test` only |

## Root cause
`rg8_certification_authentication_and_ownership_are_untouched` snapshotted the entire `sca_item_current_state` row before and after a QR reissue, removed only `active_qr_identifier_id`, then `assertSame`d the remainder. `QrService::reissue()` (`app/packages/Sca/Provenance/src/Services/QrService.php:119`) calls `ProjectionService::rebuild()`, which unconditionally writes `'rebuilt_at' => now()` (`ProjectionService.php:36`). `rebuilt_at` is a second-precision recompute timestamp; when the reissue landed in a later whole second than the setup rebuild (more likely under full-suite load), the before/after values differed and `assertSame` failed — a false failure, since certification, authentication, ownership, lifecycle, and registry were all genuinely unchanged.

## Minimal diff (only `app/tests/Feature/Sca/QrReissueTest.php`)
- Capture `rebuilt_at` before/after, then **exclude it from the equality** alongside the already-excluded `active_qr_identifier_id`. Both are non-domain: the active-QR pointer legitimately rotates on reissue; `rebuilt_at` is projection recompute metadata, not a provenance fact.
- **All domain assertions preserved / strengthened:**
  - active QR pointer changed (`assertNotSame` — unchanged from before);
  - every **other** projection column byte-identical (`assertSame` on the row minus the two excluded keys — owner, current certification, lifecycle, registry status, `last_ownership_event_id`, …);
  - certifications rows unchanged (`assertEquals`);
  - authentications rows unchanged (`assertEquals`);
  - ownership-event count unchanged (`assertSame`);
  - current owner preserved (`assertNotNull`).
- **New monotonic check (no new flake):** `rebuilt_at` is present after reissue and `Carbon::parse(after) >= Carbon::parse(before)` — equal is allowed, so a whole-second boundary cannot make this assertion fail; it only catches a timestamp moving *backward*.

No test guard was weakened; no production invariant was masked. No other test was modified.

## Proof of no non-test changes
`git diff --name-only 9a7db35..1bc301e` ⇒ exactly `app/tests/Feature/Sca/QrReissueTest.php`. No change under `app/packages`, `app/database`, config, or infrastructure.

## Test results (disposable `sca_domain_test` only)
- Focused `QrReissueTest` (11) + `QrArtifactTest` (10) = **21 passed / 103 assertions**.
- `rg8` run in isolation **3 consecutive times → green** (9 assertions each; no production `sleep`).
- Full `tests/Feature/Sca`: **1380 passed / 1 skipped / 0 failed (7310 assertions)** — the +2 vs the prior 7308 is rg8's added monotonic/present checks; the previously load-sensitive failure did not recur in this full run.

## Remaining risks
- The fix removes the timing sensitivity by not asserting equality on a recompute timestamp; it does not (and should not) change `ProjectionService::rebuild()`’s documented behavior of stamping `rebuilt_at`. Residual risk is minimal and test-only.
- Full-suite timing flakes are inherently probabilistic; this run was clean and the targeted mechanism is removed, but ChatGPT may wish to note that a single green full run is strong, not absolute, evidence. The focused 3× repeat plus the mechanism analysis support determinism.

**STOP — awaiting ChatGPT independent pre-merge audit of candidate `1bc301e`. Do not merge or deploy; no application deployment is authorized for a test-only change; do not start another initiative.**

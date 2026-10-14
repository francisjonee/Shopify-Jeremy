# SCA QR Reissue `rg8` Test Reliability — Test-Only Merge Result

**Status:** Controlled test-only merge complete on `main`. Awaiting ChatGPT post-merge verification. **No application deployment**, no production data mutation, no pilot, no new initiative.

| | |
|---|---|
| Governance pre-merge PASS | `14941ed90463bdbcfcc2e255ea81fc31366e6cc3` |
| Approved candidate | `1bc301eacc5b0d427a6f7e19e22ba201c3002216` |
| Baseline (confirmed unmoved pre-merge) | `9a7db357572600ddaeff8caa4fde5c1a8b6d273c` |
| **MERGE_SHA** | **`1c6c1e6cc0167cf1fc1d87f2a12446a219664f55`** |
| **ORIGIN_MAIN** | **`1c6c1e6cc0167cf1fc1d87f2a12446a219664f55`** |
| Candidate → merge tree | **byte-identical** (`git diff --quiet 1bc301e..1c6c1e6` ⇒ TREE_IDENTICAL) |
| Files changed vs base | **1** — `app/tests/Feature/Sca/QrReissueTest.php` (+22 / −3); nothing else |
| Non-test `app/` delta (`app/packages`, `app/database`, `app/config`) | **none** |
| Deployment | **not performed / not authorized** (test-only change) |

## Procedure
1. Reconfirmed `origin/main` = local `main` = exact approved baseline `9a7db35` immediately before merge (did NOT move).
2. `--no-ff` merge of the approved candidate `1bc301e` into `main` → merge commit `1c6c1e6`.
3. Proved candidate → merge content identity: `git diff --quiet 1bc301e..1c6c1e6` ⇒ empty (byte-identical).
4. Proved single-file delta vs base: `git diff --name-only 9a7db35..1c6c1e6` ⇒ `app/tests/Feature/Sca/QrReissueTest.php` only; `git diff 9a7db35..1c6c1e6 -- app/packages app/database app/config` ⇒ empty (no production code/schema/config change).
5. Pushed `main`: `9a7db35..1c6c1e6`.

## Why no deployment
The change is confined to a test file; production PHP/services/projection/migrations/config are byte-identical to the deployed baseline. The running container (built from `3b30a0f` app code, unchanged through `9a7db35` and now `1c6c1e6`) is unaffected, so no redeploy was run and none is authorized for a test-only change.

## Test evidence (Claude-reported; ChatGPT did not independently execute)
Pre-merge, on the exact candidate tree (disposable `sca_domain_test`): focused `QrReissueTest` + `QrArtifactTest` = 21 passed; `rg8` repeated 3× green; full `tests/Feature/Sca` = **1380 passed / 1 skipped / 0 failed (7310 assertions)**. The merge tree is byte-identical to that candidate.

**STOP — awaiting ChatGPT post-merge verification of `1c6c1e6`. No application deployment, production data change, physical pilot, or new initiative is authorized.**

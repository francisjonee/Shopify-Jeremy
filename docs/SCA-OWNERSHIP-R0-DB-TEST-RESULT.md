# SCA — Ownership R0 Isolated Security Regression: RESULT

**Authorized single isolated DB-testing session for R0 (`feat/sca-ownership-r0-retire-public-claim` @ `ce74229`). VERDICT: R0 security contract PASS.** Public QR-token ownership claiming is rejected (410) with no mutation; private-grant claims, passport viewing, and ownership/transfer protections continue working. **One identified incompatibility (req 12):** a single pre-existing test, `ExternalClaimTest::e16_shopify_claim_path_is_unchanged`, depends on the retired public claim path and now errors — **reported, not repaired.** Disposable DB only; dropped + verified; production `sca_krayin` + SHA `cb8a8c3` unchanged. 2026-10-28. **STOP.**

## [1] Candidate & isolation
- Candidate `origin/feat/sca-ownership-r0-retire-public-claim` = **`ce7422984809dd9013cf68b03de3c60c1f71c9ae`** (== origin tip); isolated detached worktree; dev vendor (phpunit) built in it. Live tree stayed `main cb8a8c3`, clean.
- **[2]/[3] Disposable DB + isolation.** A uniquely-named DB (`sca_r0_test_…`) was first created after an existence check and isolation-verified. **Naming deviation (documented):** the four target suites hard-guard on the LITERAL `sca_domain_test` (they ignore `SCA_TEST_DB`), so they cannot run against a random-named DB without editing each guard (out of scope for the pre-existing `ExternalClaimTest`). `sca_domain_test` was **absent** from the baseline (`SHOW DATABASES` = information_schema, mysql, performance_schema, sca_krayin, sys) and **no other Claude session was running**, so a fresh `sca_domain_test` was created as the disposable DB for this session, isolation-verified, and dropped afterwards. Isolation probe: `getenv(DB_DATABASE)` == `DB::connection()->getDatabaseName()` == live `SELECT DATABASE()` == `SCA_TEST_DB` == `sca_domain_test`, and ≠ `sca_krayin` → `ISOLATION OK`. Production remained fully isolated throughout.

## [4] Migration + seed (disposable DB only)
Full schema migrated into the disposable DB (incl. the Phase 2 catalog/link migrations; R0 adds none). Krayin `db:seed --force` was then run so the `web`/collector/public routes resolve (a freshly-migrated-only DB lacks the baseline channel/config state the standard `sca_domain_test` carries; see [note] below).

## [5]–[11] Test results

Per-suite (authoritative) and a combined run on the seeded DB:

| Suite | Result |
|---|---|
| `OwnershipR0PublicClaimRetiredTest` | **OK — 7 tests, 29 assertions** |
| `ClaimWorkflowTest` (rewritten to R0 contract) | **OK — 11 tests, 44 assertions** |
| `ShopifySaleClaimVisibilityTest` | **OK — 12 tests** (ownership setup switched to the unchanged `ClaimService` primitive) |
| `ExternalClaimTest` | **18 tests, 17 pass, 1 error** → `e16_shopify_claim_path_is_unchanged` (see [12]) |
| **Combined (seeded DB)** | **48 tests, 228 assertions, 1 error, 0 failures, 0 skips** — the only red is `e16` |

Objective-by-objective:
- **[6] Every public QR-token claim → 410.** `OwnershipR0::public_token_claim_post_is_retired_410…`; `ClaimWorkflowTest::r0_eligible_public_claim_is_retired` and `r0_retired_regardless_of_sale_link_state` (missing / cancelled / revoked_refund all → 410, never 409/redirect). The service `ClaimWorkflow::claim()` throws `ClaimRejection::PUBLIC_CLAIM_RETIRED`.
- **[7] No ownership / claim / sale-link consumption on rejection.** Asserted: 0 `sca_ownership_events`, 0 `sca_claims`, and the eligible `sca_shopify_sale_links` row stays `eligible` (unconsumed).
- **[8] Malformed/unknown tokens reveal nothing.** `r0_bad_or_unknown_token_post_is_retired_without_enumeration`: both a malformed and a well-formed-but-unknown token return the SAME 410 (no 404 that would disclose token validity), no ownership.
- **[9] Valid private-grant claim still creates exactly one ownership.** `OwnershipR0::private_grant_claim_still_creates_exactly_one_ownership` (one `claim` ownership event, one completed claim) + the full `ExternalClaimTest` grant suite (17 pass).
- **[10] Expired/replayed/unauthorized grants rejected.** Covered by `ExternalClaimTest` (unknown/used token fails safely; single-use/replay/race; staff-ACL + collector-cannot-manufacture) — all pass.
- **[11] Passport viewing, collector access, transfer protections intact.** `OwnershipR0::public_passport_viewing_is_unchanged_and_privacy_safe`; `ClaimWorkflowTest` preview semantics incl. former-owner-after-transfer (ownership established via the surviving grant path) and passport privacy; collector routing guards (anon/staff → collector login) preserved.

## [12] Identified incompatibility (reported, NOT repaired)
A repo-wide sweep for callers of the retired public `ClaimWorkflow::claim()` found exactly four: the two R0 tests (asserting it is retired), `ClaimController` (handled → 410), and **`ExternalClaimTest::e16_shopify_claim_path_is_unchanged` (line 419)** — a pre-existing cross-check that the public Shopify sale claim still creates ownership. Under R0 it now throws `PUBLIC_CLAIM_RETIRED` → **1 error**. This is the intended consequence of R0 (it is the exact behavior R0 removes). No other test or route outside the updated suites depends on the retired path; the two public `ClaimController` routes are intentionally retired (GET → view-only, POST → 410). **Recommendation:** update or remove `e16` as part of finalizing the R0 branch (it asserts the now-removed capability). Not changed in this verification session per the "do not silently repair failures" instruction.

> [note] Combined-run `/install` artifact: when first run against a migrated-only disposable DB (`core_config`/channel state absent), several collector/public web-route tests redirected to `/install` in the combined run (they passed individually). Seeding the DB (`db:seed`) — matching the state the standard `sca_domain_test` carries — removed all such redirects, leaving only `e16`. This is an environment/seed artifact, not an R0 regression.

## [13] Exact totals
Combined on the seeded disposable DB: **48 tests, 228 assertions, 1 error (`ExternalClaimTest::e16`), 0 failures, 0 warnings, 0 skipped.** Per-suite: OwnershipR0 7/29 OK; ClaimWorkflow 11/44 OK; ShopifySaleClaimVisibility 12 OK; ExternalClaim 17 pass / 1 error. No failing code was repaired or masked.

## [14] Cleanup verified
`REVOKE ALL` + `DROP DATABASE sca_domain_test` → gone (existence 0), no residual grant (`mysql.db` 0), `SHOW DATABASES` back to baseline (only `sca_krayin`). Probe/env files and the worktree (with vendor) removed.

## [15] Production unchanged
Live SHA **`cb8a8c3`**; `kr-app` loopback `/admin/login → 200`. `sca_krayin` fingerprint: items 3 / ownership_events 5 / claims 2 / certifications 4 / qr 3 / external_claim_grants 1; migrations batch **29** / 145 rows — unchanged.

## Release dependency (carried forward)
R0 disables public-token claiming for `sce_presale` eyewear; it must NOT be deployed alone without a separately approved release decision covering the missing private SCE claim path (**R0b**: `sce_presale` private grant + staff fulfillment-release). `external_intake` paid-authentication grant claiming is unaffected and fully working.

**STOP — R0 security contract verified on a disposable DB; production untouched. Single reported incompatibility: `ExternalClaimTest::e16` (depends on the retired path) — for the reviewer to resolve on the R0 branch. No prod migration/merge/deploy, no live Shopify/customer-claim, no Option C bulk merge. Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification; and the R0b release decision.**

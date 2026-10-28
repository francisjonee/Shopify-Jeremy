# SCA — Ownership R0 FINAL Isolated Security Regression: RESULT

**Authorized single isolated DB-testing session for R0 (`feat/sca-ownership-r0-retire-public-claim` @ `bf77490`, post-E16 correction). VERDICT: PASS — all four suites green: 48 tests, 233 assertions, 0 errors / 0 failures / 0 warnings / 0 skips.** Disposable DB only; dropped + verified; production `sca_krayin` + SHA `cb8a8c3` unchanged. No merge/deploy, no prod DB change, no live customer claim/Shopify, no full regression. 2026-10-28. **STOP.**

## [1] Candidate & isolation
- Candidate `origin/feat/sca-ownership-r0-retire-public-claim` = **`bf774905dd3997abc4efcd5044b16d7db0d6272d`** (== origin tip; e16 renamed present); isolated detached worktree; dev vendor built in it. Live tree stayed `main cb8a8c3`, clean. No other Claude session running; no test containers.
- **[2] Disposable DB:** `sca_domain_test` — the four suites hard-pin that literal name (they ignore `SCA_TEST_DB`). It was **absent** at baseline and re-checked absent immediately before create (not in use); created fresh for this session and dropped afterwards.
- **[3] Isolation verified:** `getenv(DB_DATABASE)` == `DB::connection()->getDatabaseName()` == live `SELECT DATABASE()` == `SCA_TEST_DB` == `sca_domain_test`, and ≠ `sca_krayin` → `ISOLATION OK`. Env files held zero `sca_krayin` references.

## [4] Migration + seed (disposable DB only)
Full schema migrated into the disposable DB (R0 adds no migration); `db:seed --force` applied the baseline app configuration so the collector/public web routes resolve (the standard `sca_domain_test` carries this state).

## [5]–[7] Test results — **OK (48 tests, 233 assertions)**, 0 errors/failures/warnings/skips (PHPUnit 11.5.50, ~21.8 s):

| Suite | Result |
|---|---|
| `OwnershipR0PublicClaimRetiredTest` | 7 ✔ |
| `ClaimWorkflowTest` | 11 ✔ |
| `ShopifySaleClaimVisibilityTest` | 12 ✔ |
| `ExternalClaimTest` | 18 ✔ (incl. the corrected E16) |

- **[6] E16 corrected and green:** `e16_public_qr_token_claim_is_retired_even_with_eligible_sale_link` — with a certified `sce_presale` item + active QR + eligible Shopify sale link, `ClaimWorkflow::claim()` throws `PUBLIC_CLAIM_RETIRED`, **no ownership event / no claim** is created, the item stays unclaimed, and the eligible sale link remains `eligible` (unconsumed).
- **[7] Protections intact:** private-grant claiming creates exactly one ownership atomically (E6/E9); replay of a consumed token cannot reassign ownership (E10); issuance authorization server-derived + staff-ACL-gated, collector cannot manufacture (E3/E4); adverse-status-after-issuance fails closed (E13); unknown/used token fails safely (E14); completion/consumption failures roll back with no partial ownership (E11/E12); passport exposes no owner PII or grant token (E7, OwnershipR0 passport test); ownership-transfer + former-owner/current-owner preview semantics intact (E17/E18, ClaimWorkflow preview tests). Public passport viewing unchanged and privacy-safe.

## [8] Exact totals
**48 tests, 233 assertions, 0 errors, 0 failures, 0 warnings, 0 skipped/risky.** No failing code was repaired or masked during this verification.

## [9] Cleanup verified
`REVOKE ALL` + `DROP DATABASE sca_domain_test` → gone (existence 0), no residual grant (`mysql.db` 0), `SHOW DATABASES` back to baseline (only `sca_krayin`). Probe/env files and the worktree (with vendor) removed.

## [10] Production unchanged
Live SHA **`cb8a8c3`**; `kr-app` loopback `/admin/login → 200`. `sca_krayin` fingerprint: items 3 / ownership_events 5 / claims 2 / certifications 4 / qr 3 / external_claim_grants 1; migrations batch **29** / 145 rows — unchanged.

## Release safety (carried forward)
All suites pass, but **R0 must NOT be deployed alone.** R0 removes the public claim path; `sce_presale` (SCE-purchased) eyewear then has no customer claim path until **R0b** provides the private `sce_presale` grant (staff fulfillment-release gated). `external_intake` paid-authentication grant claiming is unaffected and fully working.

**STOP — R0 fully green on a disposable DB (48/48); production untouched. No merge/deploy. NEXT (owner): R0 merge decision paired with R0b before any release. Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification.**

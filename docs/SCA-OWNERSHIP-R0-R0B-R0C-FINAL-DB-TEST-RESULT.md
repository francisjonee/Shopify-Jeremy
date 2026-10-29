# SCA — R0 + R0b + R0c FINAL Integration & Security Regression: RESULT

**Authorized single isolated DB-testing session for R0c `b042125` (→ `539cd1f` after a disclosed test-assertion fix; includes R0 + R0b). VERDICT: all seven suites GREEN — 77 tests, 326 assertions, 0 errors / 0 failures / 0 warnings / 0 skips.** The complete Ownership-Passport claiming flow (public-QR retirement, private presale grants, verified Shopify buyer identity, trusted order-email propagation) passes. Disposable DB only; dropped + verified; production `sca_krayin` + SHA `cb8a8c3` unchanged. Two operational release dependencies remain (SMTP delivery + production order-email backfill). No merge/deploy, no prod DB change, no live Shopify, no prod backfill, no real emails/SMTP change, no Option C. 2026-10-29. **STOP.**

## [1]–[4] Candidate, isolation, migrate+seed
- Candidate `origin/feat/sca-ownership-r0c-verified-buyer` = **`b042125`** (suites run at this SHA; a disclosed test-assertion fix advanced the branch to **`539cd1fb96a308dd0eb3fcc2a6450fbe98211442`** — see [22]). Isolated detached worktree; dev vendor built. Live tree stayed `main cb8a8c3`, clean. No other Claude session running; no test containers.
- Disposable `sca_domain_test` (legacy suites hard-pin the literal name): confirmed **absent + 0 active processes** at baseline and re-checked absent immediately before create; created fresh, dropped afterwards.
- Isolation verified: `getenv(DB_DATABASE)` == `DB::connection()->getDatabaseName()` == live `SELECT DATABASE()` == `SCA_TEST_DB` == `sca_domain_test`, ≠ `sca_krayin` → `ISOLATION OK`. Migrated (incl. all R0b+R0c additive migrations) + `db:seed`.

## [5]–[11] Test results — **OK (77 tests, 326 assertions)**, 0 err/fail/warn/skip

| Suite | Result |
|---|---|
| `VerifiedBuyerClaimTest` | 10 ✔ |
| `PresaleClaimGrantTest` | **12 ✔** (the 4 previously-obsolete cases now pass with the verified-buyer setup) |
| `OwnershipR0PublicClaimRetiredTest` | 7 ✔ |
| `ClaimWorkflowTest` | 11 ✔ |
| `ShopifySaleClaimVisibilityTest` | 12 ✔ |
| `ExternalClaimTest` | 18 ✔ |
| `SaleLinkOrderEmailTest` | 7 ✔ (after the fix) |

## [12]–[21] Security checks (confirmed)
- **[12]** Legitimate buyer (verified email == sale link's trusted `order_email`, case-insensitive) claims the exact item → one ownership, grant consumed, sale link `claimed`.
- **[13]** Mismatched / missing-order-email / unverified-email all fail closed (`BUYER_VERIFICATION_REQUIRED`), no ownership.
- **[14]** Order email captured from trusted paid webhooks (`SaleLinkOrderEmailTest`: `webhook_paid_propagates…`, customer-email fallback) and authoritative order (`AuthoritativeOrder::fromShopify` parsing) — never a customer form field.
- **[15]** Duplicate paid event idempotent (one link, email set once, not overwritten); refund-then-paid and cancel-then-paid do **not** restore eligibility.
- **[16]** Private grants single-use / expiring / item-specific / concurrency-safe (`PresaleClaimGrantTest` + `VerifiedBuyerClaimTest`).
- **[17]** Public QR ownership claiming disabled (410) — `OwnershipR0…` + `ExternalClaimTest::e16`.
- **[18]** Fulfillment-release ACL-gated + idempotent; external-intake claiming intact (`ExternalClaimTest` 18/18).
- **[19]** Email-verification tokens hashed (SHA-256, raw never stored), 60-min expiring, single-use (`VerifiedBuyerClaimTest` request→confirm→stamp + bad/expired cases).
- **[20] Backfill safety (exercised on the disposable DB):** defaults to **DRY-RUN (no writes)**; scans only `order_email IS NULL` rows (a row with an existing email was never scanned → cannot be overwritten); `--apply` is required for writes and wrote nothing (no token → getOrder error → no write); **eligibility_state unchanged** for all rows before/after. Confirmed: dry-run default, no overwrite, no eligibility change, explicit `--apply` gate.
- **[21]** All relevant suites reflect the verified-buyer requirement (PresaleClaimGrantTest updated; VerifiedBuyerClaimTest + SaleLinkOrderEmailTest cover the gate + propagation).

## [22] Exact totals + disclosed test fix
**77 tests, 326 assertions, 0 errors, 0 failures, 0 warnings, 0 skipped.** One disclosed test-assertion fix (not a product repair): `SaleLinkOrderEmailTest::webhook_missing_email_stores_null_fails_closed` asserted `eligibility_state == 'linked'`, but `'linked'` is the `linkPaidLine` RETURN status while the stored DB state is `'eligible'` — corrected (branch `b042125 → 539cd1f`, test-only; the feature was correct throughout). No failing product code was repaired or masked.

## [23] Remaining release dependencies / blockers (operational, not code)
1. **SMTP delivery (BLOCKER for launch):** the collector email-verification challenge rides Mail (`log`; SMTP dormant). `email_verified_at` cannot be set in production until SMTP + a verified sender are live → the verified-buyer gate is unsatisfiable in prod until then. Mechanism is real + tested; delivery is not operational.
2. **Production order-email backfill:** new orders now propagate `order_email`; EXISTING sale links need the separately-authorized backfill run (`sca:shopify:backfill-sale-link-email --apply`) once SMTP/claims launch is approved.
3. **Latent:** email-change invalidation — add `email_verified_at` clearing if/when collector email becomes editable (no in-app change path today).
- **Residual:** grant + verification tokens travel in URL paths (access logs / browser history / `Referer`), as documented previously. No new code blockers found.

## [24] Cleanup verified
`REVOKE ALL` + `DROP DATABASE sca_domain_test` → gone (0), no residual grant (0), `SHOW DATABASES` back to baseline. Probe/env files + worktree removed.

## [25] Production unchanged
Live SHA **`cb8a8c3`**; loopback `/admin/login → 200`. `sca_krayin`: items 3 / ownership 5 / claims 2 / cert 4 / qr 3 / external_claim_grants 1; batch 29 / 145. R0c tables + `order_email` column **absent** in prod.

**STOP — the full R0+R0b+R0c claiming flow is GREEN (77/77) on a disposable DB; production untouched. RELEASE GATE: the combined regression now passes at `539cd1f`, but DO NOT merge/deploy until (a) operational SMTP delivery is verified with a verified sender, (b) the production order-email backfill is separately authorized + completed, and (c) separate deployment approval is granted. Do not release the bearer-only workflow. Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification.**

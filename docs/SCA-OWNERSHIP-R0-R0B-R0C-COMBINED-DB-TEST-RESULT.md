# SCA — Combined R0 + R0b + R0c Isolated Security Regression: RESULT

**Authorized single isolated DB-testing session for R0c `c1e252a` (→ `3148029` after a disclosed test-fixture fix; includes R0 + R0b).** The R0c verified-buyer enforcement is PROVEN CORRECT (`VerifiedBuyerClaimTest` 10/10) and R0/R0b/external/visibility suites are all green. **Two release-gating findings + obsoleted R0b tests reported (not silently repaired).** Disposable DB only; dropped + verified; production `sca_krayin` + SHA `cb8a8c3` unchanged. No merge/deploy, no prod DB change, no live Shopify/customer claim, no real emails/SMTP change, no Option C. 2026-10-29. **STOP.**

## [1]–[5] Candidate, isolation, migrate+seed
- Candidate `origin/feat/sca-ownership-r0c-verified-buyer` = **`c1e252a`** (tests run at this SHA; a disclosed fixture fix advanced the branch to **`3148029e8dead35912062d491d0a3dba0e39714f`** — see [23]). Isolated detached worktree; dev vendor built. Live tree stayed `main cb8a8c3`, clean. No other Claude session running; no test containers.
- Disposable DB `sca_domain_test` (legacy suites hard-pin the literal name): confirmed **absent + 0 active processes** at baseline and re-checked absent immediately before create; created fresh, dropped afterwards.
- Isolation verified: `getenv(DB_DATABASE)` == `DB::connection()->getDatabaseName()` == live `SELECT DATABASE()` == `SCA_TEST_DB` == `sca_domain_test`, ≠ `sca_krayin` → `ISOLATION OK`. Migrated (incl. all R0b+R0c additive migrations) + `db:seed`.

## [6]–[11] Test results (per-suite, authoritative)

| Suite | Result |
|---|---|
| `VerifiedBuyerClaimTest` (R0c) | **OK — 10 tests, 33 assertions** (after the fixture fix) |
| `OwnershipR0PublicClaimRetiredTest` | OK — 7 |
| `ClaimWorkflowTest` | OK — 11 |
| `ShopifySaleClaimVisibilityTest` | OK — 12 |
| `ExternalClaimTest` | OK — 18 |
| `PresaleClaimGrantTest` (R0b) | **12 tests, 4 RED** (2 errors + 2 failures) — obsoleted by the R0c gate; 8 pass |

Combined (at `c1e252a` + fixture fix): **70 tests, 294 assertions, 66 pass, 4 red** — all four red are the R0b success-path presale cases (see [FINDING-1]).

## [12]–[17] Security verifications (confirmed green via `VerifiedBuyerClaimTest` + inherited suites)
- **[12]** Legitimate buyer (collector `email_verified_at` set AND email == sale link `order_email`, case-insensitive) claims the exact item → one ownership, grant consumed, sale link `claimed`.
- **[13]** Wrong buyer (verified, different email) → `BUYER_VERIFICATION_REQUIRED` (409); unverified matching email → rejected; missing `order_email` → fail closed. No ownership in any case.
- **[14]** Expired → `NOT_FOUND`; cancelled/refunded → `NOT_ELIGIBLE` (before the buyer gate); replay + second buyer cannot double-assign (single-use); concurrency single-use invariant → one owner.
- **[15]** Fulfillment release ACL-gated + append-once idempotent (`PresaleClaimGrantTest` release cases still green).
- **[16]** Public QR tokens cannot claim (410) — `OwnershipR0PublicClaimRetiredTest` + `ExternalClaimTest::e16` green.
- **[17]** Email challenge is single-use, 60-min expiring, bound to collector+email, hashed (raw never stored) — `VerifiedBuyerClaimTest` request→confirm→stamp + bad/expired cases green.

## [18] FINDING-2 (latent) — email-change does not invalidate verification
Collector email is set **only at registration** (`RegisterCollectorRequest`, unique); `UpdateProfileRequest` explicitly accepts **no email**, and the account/profile pages show email **read-only** — there is **no in-app email-change path today**, so the invalidation scenario cannot occur now. However, `email_verified_at` is a bare timestamp not re-cleared on any email mutation. **Latent risk:** if an email-change feature is ever added without clearing `email_verified_at`, the gate would treat a newly-set (unverified) address as verified. `confirm()` and the gate both compare against the collector's CURRENT email, so a stale match is only exploitable via a future email-change. **Recommendation:** when/if collector email becomes editable, clear `email_verified_at` (and any pending challenge) on change. Not a current blocker.

## [19] Order-email source — trusted only
No code path sets `sca_shopify_sale_links.order_email` from request/form input; the only writer is `SaleLinkService::linkPaidLine($orderEmail)`, documented as verified-source-only (webhook/`getOrder`). ✓

## [20] FINDING-1 (RELEASE BLOCKER) — order email is never propagated by any call site
Both live callers of `linkPaidLine` pass only 6 args — **neither forwards the trusted order email**:
- `Shopify/src/Services/SaleLinkEventProcessor.php:62` (the order-webhook path)
- `Shopify/src/Services/ShopifyReconciliationService.php:100` (reconcile path)

So in production `order_email` is **always NULL**, and the R0c buyer gate therefore **fails closed for every presale claim** (safe, but the feature cannot function). **This is a release blocker for R0c activation:** the verified sale-link creation path must extract the order `email` from the trusted payload / `getOrder` and pass it into `linkPaidLine`, plus a one-time backfill for pre-existing sale links. Not wired in this slice (kept additive/back-compat) — reported per instruction 20.

## [21] Token exposure
No raw grant or verification token is written to application logs (services/controllers log only exception class). Tokens are not rendered on the public passport (`grant_token_never_appears_on_public_passport` + `ExternalClaimTest::e7` green). **Residual (documented):** grant + verification tokens travel in URL paths (`/collector/claim/presale/{token}`, `/collector/email/verify/{token}`), so web-server/proxy **access logs, browser history, and `Referer` may record them** (shared with the external-grant model). Mitigations: short TTLs (14d/60-min) + one-time consumption; optionally move tokens off the URL. Not changed here.

## [22] External/My-Collection/transfer unaffected
`ExternalClaimTest` 18/18 green (external_intake grant path intact, incl. e16 public-QR retirement); `ShopifySaleClaimVisibilityTest` 12/12; `ClaimWorkflowTest` 11/11 (preview/transfer/former-owner semantics). ✓

## [23] Disclosed test-fixture fix (not a product repair)
`VerifiedBuyerClaimTest::cancelled_or_refunded_sale_rejected_before_buyer_gate` created two collectors with the SAME email across its loop → UNIQUE(email) 1062. Fixed to a per-iteration unique email (branch `c1e252a → 3148029`, test-only). The R0c gate logic was correct throughout. No product code changed.

## [24] Missing integrations (explicitly identified)
1. **Order-email propagation (BLOCKER):** sale-link call sites don't pass `order_email` → see [20]. Must be wired + backfilled before R0c is effective.
2. **SMTP email delivery (BLOCKER for launch):** the verification challenge rides Mail (`log`; SMTP dormant). Collectors cannot receive challenges → `email_verified_at` cannot be set in prod → gate unsatisfiable until SMTP + a verified sender are live (Postmark preflight BLOCKED). Mechanism is real; delivery is not operational.
3. **Email-change invalidation (latent):** see [18]; add when email becomes editable.
4. **R0b `PresaleClaimGrantTest` update:** 4 success-path cases now require a verified-buyer setup (follow-up correction, like the earlier `e16` fix).

## [25] Cleanup verified
`REVOKE ALL` + `DROP DATABASE sca_domain_test` → gone (0), no residual grant (0), `SHOW DATABASES` back to baseline. Probe/env files + worktree removed.

## [26] Production unchanged
Live SHA **`cb8a8c3`**; loopback `/admin/login → 200`. `sca_krayin`: items 3 / ownership 5 / claims 2 / cert 4 / qr 3 / external_claim_grants 1; batch 29 / 145. R0c tables (`sca_presale_claim_grants`, `sca_collector_email_verifications`) and the `order_email` column are **absent** in prod.

**STOP — R0c enforcement verified correct on a disposable DB; production untouched. RELEASE GATE: R0+R0b+R0c combined regression passes for the verified-buyer path, but DO NOT merge/deploy until: (a) FINDING-1 order-email propagation is wired + backfilled, (b) SMTP delivery is operational with a verified sender, (c) R0b PresaleClaimGrantTest is updated to the verified-buyer contract, and (d) separate deployment approval is granted. Do not release the bearer-only workflow. Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification.**

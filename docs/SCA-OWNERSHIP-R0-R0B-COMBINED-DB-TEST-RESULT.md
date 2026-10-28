# SCA — Combined R0 + R0b Isolated Security Regression: RESULT

**Authorized single isolated DB-testing session for R0b `1592a78` (which includes R0). VERDICT: all five suites PASS — 60 tests, 277 assertions, 0 errors / 0 failures / 0 warnings / 0 skips.** Disposable DB only; dropped + verified; production `sca_krayin` + SHA `cb8a8c3` unchanged. **⚠️ ONE SECURITY BLOCKER for the release gate (item 21): the private presale grant is a BEARER token with no buyer-identity verification.** No merge/deploy, no prod DB change, no live Shopify/customer claim, no Option C, no full regression. 2026-10-29. **STOP.**

## [1]–[5] Candidate, isolation, migrate+seed
- Candidate `origin/feat/sca-ownership-r0b-private-sce-claim` = **`1592a78944c7709b56dc0cc37a5f4f76f1ff2e83`** (== origin tip); isolated detached worktree; dev vendor built in it. Live tree stayed `main cb8a8c3`, clean. Peer session `sca-85` was interactive/idle (not running tests).
- Disposable DB `sca_domain_test` (the legacy suites hard-pin that literal name): confirmed **absent** AND **0 active processes** at baseline and re-checked absent immediately before create; created fresh and dropped afterwards.
- Isolation verified: `getenv(DB_DATABASE)` == `DB::connection()->getDatabaseName()` == live `SELECT DATABASE()` == `SCA_TEST_DB` == `sca_domain_test`, ≠ `sca_krayin` → `ISOLATION OK`.
- Migrated (incl. both R0b additive migrations `2026_10_29_000001/000002`) + `db:seed` into the disposable DB only.

## [6]–[10] Test results — **OK (60 tests, 277 assertions)**, 0 err/fail/warn/skip (PHPUnit 11.5.50)

| Suite | Result |
|---|---|
| `PresaleClaimGrantTest` | 12 ✔ |
| `OwnershipR0PublicClaimRetiredTest` | 7 ✔ |
| `ClaimWorkflowTest` | 11 ✔ |
| `ShopifySaleClaimVisibilityTest` | 12 ✔ |
| `ExternalClaimTest` | 18 ✔ |

## [11]–[20] Security verifications (all confirmed green)
- **[11]** Only staff with `sca.eyewear.fulfillment.release` can release (403 without; redirect+release with).
- **[12]** Release is append-once idempotent (second call `released=false`; original actor/timestamp preserved) and auditable (`fulfillment_released_by`/`_at`).
- **[13]** An unreleased pair cannot get a usable grant — issuance rejects `fulfillment_released_at IS NULL` (`NOT_ELIGIBLE`); no grant row.
- **[14]** Grant bound to the exact `eyewear_item_id` and an ELIGIBLE sale link (re-validated at consumption); never inferred from a variant.
- **[15]** Valid private-grant claim → exactly one `claim` ownership event, one completed `shopify_sale` claim, sale link → `claimed`, grant → `consumed`.
- **[16]** Public QR claim remains **HTTP 410**, zero ownership — even for a released + grant-issued item (`public_qr_token_still_cannot_claim_under_r0b`).
- **[17]** Expired → 404; consumed/void/used → fail closed; unauthorized (no ACL) → 403; cancelled/refunded sale → 409 with grant NOT consumed; all create no ownership.
- **[18]** Double-claim is single-use (same collector idempotent; second collector → `ALREADY_OWNED`); concurrent (single-use invariant) → exactly one owner.
- **[19]** No application-level logging of the grant token in R0b code; the token is never rendered on the public passport (asserted) — **but see the URL-path caveat under the BLOCKER**.
- **[20]** `external_intake` claiming (full `ExternalClaimTest` 18 ✔), My Collection, and ownership-transfer protections unchanged.

## [21] SECURITY BLOCKER (release-gating) — bearer grant, no buyer verification
**The private presale claim link is a BEARER token.** Possession of `/collector/claim/presale/{token}` by ANY authenticated collector permits the claim; the grant is NOT bound to the legitimate Shopify buyer's identity. Confirmed by code + schema review:
- `PresaleClaimGrantService`/`ClaimWorkflow` contain no customer/buyer/email binding.
- `sca_shopify_sale_links` has **no customer/email column** to bind against (the sale link deliberately carries no customer identity), so the system has nothing to verify the claimant against.
- Delivery is **out-of-band by staff** after fulfillment release; the system cannot confirm the claimant purchased the eyewear.

Within the system the token is not leakable to an unrelated collector (opaque 128-bit, single-use, time-limited, never on the public passport, not in app logs). The exposure is the **delivery channel**: anyone who obtains the link first (misdelivery, forwarding, interception, or a shared device) and is a signed-in collector can claim. **Additional exposure:** the token travels in the URL path, so web-server/proxy **access logs, browser history, and `Referer` headers may record it** (shared with the external-intake grant model).

**Assessment:** per the explicit bar in item 21, this is a **SECURITY BLOCKER for releasing R0b**: possession alone permits a wrong buyer to claim, with no approved buyer-verification mechanism — only staff out-of-band delivery. It is not a defect in what was built (it faithfully mirrors the existing external-grant bearer model), but it must be resolved or explicitly risk-accepted by the owner before release. Options to consider (not implemented): (a) bind the grant to the Shopify order's customer email and require the claiming collector's verified email to match; (b) require the buyer to present an order number/confirmation at claim; (c) deliver via a verified channel (authenticated Shopify account / verified email) rather than a copyable staff link; (d) shorten TTL + add explicit staff revoke. **Recommendation: do NOT release R0b until a buyer-verification/delivery control is approved.**

## [22] Exact totals
**60 tests, 277 assertions, 0 errors, 0 failures, 0 warnings, 0 skipped.** No failing code repaired or masked. One security BLOCKER reported (item 21), not repaired.

## [23] Cleanup verified
`REVOKE ALL` + `DROP DATABASE sca_domain_test` → gone (0), no residual grant (0), `SHOW DATABASES` back to baseline. Probe/env files + worktree (with vendor) removed.

## [24] Production unchanged
Live SHA **`cb8a8c3`**; loopback `/admin/login → 200`. `sca_krayin`: items 3 / ownership 5 / claims 2 / cert 4 / qr 3 / external_claim_grants 1; batch 29 / 145 rows. `sca_presale_claim_grants` table **absent** in prod.

**STOP — R0+R0b all green on a disposable DB (60/60); production untouched. RELEASE GATE: R0 and R0b release together, but the item-21 BEARER-TOKEN / no-buyer-verification SECURITY BLOCKER must be resolved or explicitly risk-accepted by the owner FIRST. Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification.**

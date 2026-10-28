# SCA — Ownership R0 (GAP-1): Retire Public QR-Token Claiming

**Authorized R0 development on a NEW branch from production baseline `cb8a8c3`.** Public QR tokens are now view-only for ownership; the private single-use grant is the only ownership-acquisition path. Dev branch only — NO migration/schema change, NO deploy/merge, NO live Shopify, NO live customer claim, NO Option C bulk merge (reimplemented against the current codebase). Static checks PASS (`php -l` clean; Blade balanced). Focused tests written but **NOT run** (DB-changing; require separate disposable-DB authorization). 2026-10-28. **STOP for review.**

## SHA & files
- Branch `feat/sca-ownership-r0-retire-public-claim`: `cb8a8c3` → **`ce7422984809dd9013cf68b03de3c60c1f71c9ae`** (pushed `origin`). Live `main`/prod untouched.
- **7 files, no migration:** `ClaimRejection.php` (+const), `ClaimWorkflow.php` (retire `claim()`), `ClaimController.php` (410 + view-only), `show.blade.php` (additive `public_retired` branch), + 3 test files.

## What changed (requirements 1–8)
1. **Inspected** `ClaimWorkflow` (public `claim()` vs `claimByGrant`), `ClaimController`, `GrantClaimController`, `ClaimService`, and the claim routes. The public path was `ClaimController::claim` → `ClaimWorkflow::claim(token, collectorId)` → `ClaimService::openShopifyClaim`/`complete` (ownership from a Shopify sale-link, keyed only on the public QR token).
2. **Disabled ownership via the public token:** `ClaimWorkflow::claim()` now throws `ClaimRejection::PUBLIC_CLAIM_RETIRED` at the very top — before resolving the token or opening/completing any claim. The entire sale-link claim body is removed (not flag-gated). Since the public QR token is the method's only input, this retires the whole public ownership path.
3. **Public `/p/{token}` passport viewing preserved** — untouched (Passport package / `PassportController`); only the `/collector/claim/{token}` behavior changed.
4. **Collector registration/login and My Collection preserved** — untouched.
5. **`claimByGrant` preserved** — the private single-use grant path (`GrantClaimController` → `ClaimWorkflow::claimByGrant` → `ClaimService::complete`) is unchanged, including its entitlement/expiry/replay/authorization protections and the shared view's `eligible` form branch (still used by the grant flow).
6. **Ownership transfer preserved** — `TransferWorkflow`/`TransferService` untouched.
7. **Shopify sale links can no longer authorize public-token ownership** — `claim()` throws before any sale-link lookup, so an eligible sale link never yields ownership through the public token (tests assert the sale link stays `eligible`, unconsumed, and zero ownership/claim rows result).
8. **Clear, safe response:** POST → **410 Gone** with a PII-free message ("Ownership is no longer claimed from the public QR code. Use the private claim link from your Second Chance Eyewear purchase or authentication confirmation."). GET claim page → a view-only `public_retired` notice with **no claim form**. Malformed/unknown tokens also return 410 (no token-validity enumeration).

## Requirement 10 — no mutation on rejected claims
The retirement throw precedes `openShopifyClaim`/`verify`/`complete`, so a rejected public claim creates **no `sca_claims` row and no `sca_ownership_events` row**, and never consumes the sale link. Asserted by the new tests.

## Tests (NOT run — separate disposable-DB authorization required)
- **NEW `OwnershipR0PublicClaimRetiredTest`:** public POST on an eligible `sce_presale` item → 410 + 0 ownership/0 claims + sale link still `eligible`; `ClaimWorkflow::claim()` throws `PUBLIC_CLAIM_RETIRED`; retired for malformed/unknown tokens (no enumeration); claim page is view-only (no form); **private-grant claim still creates exactly one ownership**; `/p/{token}` viewing unchanged + privacy-safe.
- **`ClaimWorkflowTest` rewritten** to the R0 contract: public path retired across all sale-link states (missing/cancelled/refunded all → 410); routing guards preserved (anon/staff → collector login); view-only page; `preview()` semantics intact incl. former-owner-after-transfer (ownership established via the surviving grant path). Grant-path ownership invariants remain covered by `ExternalClaimTest`.
- **`ShopifySaleClaimVisibilityTest`:** its three ownership-setup sites switched from the retired `ClaimWorkflow::claim()` to the unchanged `ClaimService` primitive (identical completed-claim state) so the staff-visibility assertions still hold.

## Requirement 11 — not Option C
No file from the stale `feat/sca-optc-secure-claim` branch was copied or merged. R0 reimplements only the public-claim retirement against `cb8a8c3`, and deliberately **omits** the Option C `sce_presale` fulfillment-release migration/ACL (that is the proposed R0b follow-up).

## Safety / scope
Dev branch only; prod `main` (`cb8a8c3`) and the live bind-mount untouched. No migration (none added), no deploy/merge, no live Shopify/customer-claim. The DB-backed tests are deferred to a separate authorized disposable-DB run.

> Note for review: after R0, an `sce_presale` (SCE-purchased) item has **no live claim path** until R0b adds the private `sce_presale` grant (fulfillment-release gated). `external_intake` paid-authentication claiming (grant) is unaffected and fully working. This is expected: R0 closes the security gap; R0b restores the pre-sale claim path securely.

**STOP — R0 implemented on the dev branch (`ce74229`); review before any DB test, merge, or deploy. Separate OPEN: the first genuine `products/*` webhook verification; and the R0b `sce_presale` private-grant path.**

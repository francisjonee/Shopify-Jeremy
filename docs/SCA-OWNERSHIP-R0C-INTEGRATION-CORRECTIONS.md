# SCA — Ownership R0c Integration Corrections

**Authorized narrowly-scoped development task on the R0c branch.** Closes the combined-regression BLOCKER-1 (trusted order email was never propagated to sale links) and updates the four obsolete R0b presale success-path tests to the verified-buyer contract. Dev branch only — NO production migration/merge/deploy, NO live Shopify change, NO production backfill execution, NO real emails/SMTP change, NO Option C. Static checks PASS (`php -l` clean). DB-backed tests written/updated but **NOT run** (require separate disposable-DB authorization). 2026-10-29. **STOP for review.**

## SHA & files
- Branch `feat/sca-ownership-r0c-verified-buyer`: `3148029` → **`b0421252f4fabc1a1b8ce68f7bb1e499c014d842`** (pushed `origin`). Live `main`/prod (`cb8a8c3`) untouched. **7 files (5 modified, 2 new); no migration** (the R0c `order_email` column migration already exists on the branch).

## [1–4] Trusted order-email propagation (both sale-link creation paths)
- **`AuthoritativeOrder`** (reconciliation DTO) now carries a normalized `email` (top-level `email`, else `customer.email`; lower/trim; null when absent).
- **`ShopifyReconciliationService`** forwards `$order->email` as the trusted `$orderEmail` into `SaleLinkService::linkPaidLine` (authoritative `getOrder` path).
- **`SaleLinkEventProcessor::handlePaid`** extracts the email from the **already-HMAC-verified** webhook payload (top-level then `customer.email`), normalizes it, and forwards it. **Source is exclusively authenticated webhook data / verified `getOrder`** — never a customer-submitted field. Missing/empty → `null` → the R0c claim gate fails closed.
- **Normalization is consistent** (lower-case + trim) across webhook, reconciliation, `SaleLinkService`, and the claim-gate comparison.
- **Cancellation/refund cannot restore eligibility:** `handleCancelled`/`handleRefund` only revoke; `linkPaidLine` treats an existing `(shop,line)` row as authoritative and returns `exists` (never flips a `cancelled`/`revoked_refund` link back to `eligible`). A new test asserts this for both a replayed paid-after-refund and paid-after-cancel.

## [6] Shopify scope — unchanged
The order email is exposed by the existing `read_orders` scope (both the `orders/paid` webhook payload and `getOrder`). **No scope change is required or proposed; no production Shopify configuration altered.**

## [5][11-backfill] Backfill plan (dry-run first; NOT executed)
New console command **`sca:shopify:backfill-sale-link-email`** (registered console-only; not scheduled):
- Scans `sca_shopify_sale_links` where `order_email IS NULL` (bounded by `--limit`, default 500).
- For each, fetches the authoritative order via read-only `getOrder` and derives the trusted email (top-level/`customer.email`).
- **DRY-RUN by default** — reports counts and per-link what it WOULD set; writes nothing.
- **`--apply`** writes, but ONLY to rows where `order_email IS STILL NULL` (idempotent, re-runnable, never overwrites an existing value) and never changes `eligibility_state` or any other field. Orders with no trusted email are left NULL (fail closed).
- **Operational sequence (separately authorized, not run here):** (1) run dry-run against prod, review the report; (2) run `--apply`; (3) re-run dry-run to confirm residual NULLs are only orders genuinely lacking an email. Rollback: none needed (additive, idempotent); an erroneously-set value can be nulled by a targeted statement under separate authorization.

## [7] Obsolete R0b tests updated
`PresaleClaimGrantTest`: the 4 success-path cases (`valid_private_grant_claim…`, `double_claim…`, `second_collector…`, `concurrent…`) now establish a **verified buyer** (`email_verified_at` set, email == the sale link's trusted `order_email`) via a new `verifiedBuyer()` helper and a per-link `order_email`. Negative/setup cases (release ACL, idempotent release, grant-requires-release, expired, cancelled/refunded, public-QR-410, token-not-on-passport) are unchanged (they reject before the buyer gate).

## [8] Added tests (NOT run — separate disposable-DB authorization)
`SaleLinkOrderEmailTest`: webhook paid propagates the trusted email (normalized); customer-email fallback; missing email → NULL (fail closed); duplicate paid event idempotent (one link, email set once); refund-then-replayed-paid and cancel-then-replayed-paid cannot restore eligibility; and `AuthoritativeOrder::fromShopify` email parsing (top-level / customer fallback / null).

## Required database tests (to run under the next authorized disposable-DB session)
On a uniquely-created `sca_domain_test` at `b042125`, migrate + `db:seed`, then run all of:
`SaleLinkOrderEmailTest`, `PresaleClaimGrantTest` (now expected 12/12), `VerifiedBuyerClaimTest`, `OwnershipR0PublicClaimRetiredTest`, `ClaimWorkflowTest`, `ShopifySaleClaimVisibilityTest`, `ExternalClaimTest` — expecting the full combined suite GREEN (the 4 previously-obsolete cases now pass with the verified-buyer setup, and order-email propagation is covered by `SaleLinkOrderEmailTest`).

## Remaining release dependencies (unchanged by this task)
1. **SMTP delivery (BLOCKER for launch):** the collector email-verification challenge rides Mail (`log`; SMTP dormant) — `email_verified_at` cannot be set in production until SMTP + a verified sender are live (Postmark preflight BLOCKED). Mechanism is real; not operational.
2. **Backfill execution:** the propagation now fills `order_email` for NEW orders; EXISTING sale links need the (separately-authorized) backfill run.
3. **Latent:** email-change invalidation — add `email_verified_at` clearing if/when collector email becomes editable (no in-app change path today).
- **Residual:** grant/verification tokens travel in URL paths (access logs/history/`Referer`), as documented in the combined-regression result.

## Safety / scope
Dev branch only; prod `main` (`cb8a8c3`) + live bind-mount untouched; no migration run; no backfill executed; `read_orders` unchanged; external-intake/My-Collection/passport/transfer untouched. DB-backed tests deferred.

**RELEASE GATE:** do not merge/deploy R0+R0b+R0c until the combined security regression is GREEN at `b042125` (authorized DB session) AND the buyer-email delivery/integration requirements (SMTP operational + backfill run) are satisfied AND separate deployment approval is granted. Do not release the bearer-only workflow.

**STOP — R0c integration corrections implemented (`b042125`); review + an authorized combined DB regression next. Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification.**

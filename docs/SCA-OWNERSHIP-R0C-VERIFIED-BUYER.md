# SCA — Ownership R0c: Verified Buyer Claim Security

**Authorized R0c implementation on a new branch from R0b `1592a78`.** Only the VERIFIED purchaser of the exact Shopify order may redeem the private presale claim grant — closing the R0b bearer-token SECURITY BLOCKER. Dev branch only — NO production migration/merge/deploy, no live Shopify/customer claim/email, no Option C. Static checks PASS (`php -l` clean; Blade balanced). Focused tests written but **NOT run** (DB-changing; require separate disposable-DB authorization). 2026-10-29. **STOP for review.**

## SHA & files
- Branch `feat/sca-ownership-r0c-verified-buyer` off R0b `1592a78` → **`c1e252ab4c876dfda0315dc7d13d05427173651d`** (pushed `origin`). Live `main`/prod (`cb8a8c3`) untouched. **12 files (6 modified, 6 new), 2 additive migrations.** The external-intake grant table/service/controller and the external claim flow are **untouched** (requirement 12).

## [1] Audit (performed before any change)
- `sca_collector_accounts.email_verified_at` exists (nullable) but is **never set** anywhere (only reset to null by anonymization) — there was **no collector email-verification flow**.
- `sca_shopify_sale_links` carried `shopify_customer_ref` (a reference, not an email) and **no order email**; `SaleLinkService`/`SaleLinkEventProcessor` persist no customer PII — so the **trusted buyer email was not captured**.
- `ShopifyClient::getOrder` (read_orders scope, already granted) returns the order `email`; the order webhook payload also carries it.
- Conclusion: R0c must (a) capture the trusted order email, (b) add a real email-verification mechanism, (c) gate the claim on a verified match.

## [2,3,5,6] Buyer identity binding (server-side, trusted source, exact item)
- **Trusted order email:** additive nullable `sca_shopify_sale_links.order_email`, captured ONLY from trusted Shopify data (verified webhook / `getOrder`), never a form field; stored normalized. `SaleLinkService::linkPaidLine` gains an optional trailing `$orderEmail` (back-compat; verified source only).
- **Gate** (`ClaimWorkflow::claimByPresaleGrant`, inside the consumption transaction, after sale-link eligibility): require the sale link's `order_email` present AND the collector's `email_verified_at` NOT NULL AND a **normalized (case-insensitive) match** → else `ClaimRejection::BUYER_VERIFICATION_REQUIRED` (409, no ownership, grant not consumed). The grant remains bound to the exact `eyewear_item_id` + `source_sale_link_id` (never a Shopify variant).

## [4] Email verification — a REAL mechanism (not assumed complete)
- Additive table `sca_collector_email_verifications` (collector_id PK, SHA-256 `token_hash` — raw token never stored, `expires_at`, single-use). `CollectorEmailVerificationService::request()` issues a 60-min hashed token and sends `CollectorEmailVerification` (host-pinned link); `confirm()` validates the raw token against the hash for the collector's current email, unexpired, then stamps `email_verified_at` and consumes the challenge. Collector routes: `POST collector/email/verify/request` (auth, throttled) + public `GET collector/email/verify/{token}` (confirm). Enumeration-safe + transport-failure hardened (mirrors the password-reset flow).
- **Email ownership is NOT assumed from a profile address** — `email_verified_at` is set ONLY by a confirmed one-time challenge.

## [7] Preserved invariants
Fulfillment-release authorization, sale eligibility, exact item+sale-link binding, expiry, single-use, replay, and concurrency safety from R0b are all retained (the buyer gate is an ADDITIONAL check before consumption). [12] external_intake grants, My Collection, public passport viewing, and ownership transfers are untouched; the R0 public-QR retirement (410) still holds.

## [8] Fail-closed matrix
Missing order email → reject; collector email unverified → reject; verified but mismatched → reject; order email unretrievable/absent → reject. None create ownership or consume the grant.

## [9] Shopify API permissions
`read_orders` is already granted (current scope `read_orders,read_products`) and exposes the order email via `getOrder`/webhook — **no scope change is required or proposed**, and no production Shopify configuration was altered.

## [10] Token-leak hardening + residual limitations
- No raw verification token or grant token is written to application logs (services/controllers log only exception class on transport failure). Links pin to `config('app.url')` (host-header hardening).
- **RESIDUAL (documented):** the grant and verification tokens travel in URL paths (`/collector/claim/presale/{token}`, `/collector/email/verify/{token}`), so web-server/proxy **access logs, browser history, and `Referer` headers may record them** — shared with the existing external-grant model. Mitigations if desired: short TTL (already 14d grant / 60-min verify), one-time consumption (both), and optionally moving the token to a POST body / one-time exchange. Not changed in this slice.

## [11] Tests (NOT run — separate disposable-DB authorization)
`VerifiedBuyerClaimTest`: legitimate verified buyer claims (one ownership, grant consumed); case-insensitive match; wrong buyer (verified, different email) → `BUYER_VERIFICATION_REQUIRED`; unverified matching email → rejected; missing order email → fail closed; cancelled/refunded → `NOT_ELIGIBLE`; expired grant → `NOT_FOUND`; replay + second buyer cannot double-assign; and the challenge mechanism (request issues a hashed single-use token via `Notification::fake`, confirm stamps `email_verified_at`, replay/bad/expired token fail).

## [13] Delivery requirements, schema, assumptions, release dependencies
- **Schema (2 additive migrations):** `sca_shopify_sale_links.order_email` (nullable); `sca_collector_email_verifications` (new). Both reversible; no existing table/column/row altered. (R0c migrations are **not** applied to prod.)
- **Delivery requirement / RELEASE DEPENDENCY:** the verification challenge rides the Mail transport, currently **`log` (SMTP dormant** — see Postmark preflight). A collector **cannot receive** a challenge, so `email_verified_at` cannot be set in production, so the R0c gate cannot be satisfied in production **until SMTP is activated with a verified sender**. R0c implements the mechanism and enforcement but does **not** treat verification as operational.
- **Order-email capture activation:** the `order_email` column is populated only when the verified sale-link creation path passes the trusted email; wiring that into the live order-webhook/reconcile path (and/or a one-time backfill via `getOrder`) is a deployment step. Until then `order_email` is null and presale claims fail closed (safe).
- **Assumptions:** the Shopify order email is authoritative buyer identity for SCE purchases; a collector controls an email iff they completed the one-time challenge for that exact address; normalized (lowercase/trim) equality is the match rule.

## Safety / scope
Dev branch only; prod `main` (`cb8a8c3`) + live bind-mount untouched; no migration run anywhere; external flow untouched; no Option C. DB-backed tests deferred to a separate authorized disposable-DB run.

**RELEASE GATE:** R0, R0b, and R0c must pass COMBINED security regression and receive separate deployment approval. **Do not release the bearer-only workflow.** R0c's gate additionally depends on SMTP (challenge delivery) + the order-email capture activation before it is effective in production.

**STOP — R0c implemented on the dev branch (`c1e252a`); review before any DB test, merge, or deploy. Separate OPEN: the first genuine `products/*` webhook verification.**

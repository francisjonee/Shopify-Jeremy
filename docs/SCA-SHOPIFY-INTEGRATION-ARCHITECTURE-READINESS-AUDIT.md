# SCA Shopify Integration — Architecture + Readiness Audit (READ-ONLY)

**Date:** 2026-10-05 · **Production baseline:** `98ae654`, migrations **120**.
**Status: AUDIT / DESIGN ONLY. No Shopify app/token/webhook created, no `.env`/schema/DB change, no production
write, no test order. STOP for ChatGPT/operator review.** Traced against the deployed code (file:line verified);
current Shopify requirements verified against live Shopify docs (cited). Recommendation at the end: **GO to
ACTIVATE (not build)** + the business decisions required first.

## 0. Headline finding — the integration already exists, tested, deployed-dormant
A complete **inbound** Shopify integration is already merged, tested, and deployed on main as the first-class
package **`packages/Sca/Shopify`** (last commit `5914aab`, "SCA-SHOPIFY-SALELINK-010 (PR #12)"). `artisan
route:list` confirms all four routes are live in production:
`POST sca/shopify/webhook`, `GET sca/shopify/oauth/callback`, `GET admin/sca/shopify`, `GET admin/sca/shopify/connect`.
It is **dormant and fail-closed**: `sca_shopify_credentials`, `sca_shopify_webhook_receipts`,
`sca_shopify_sale_links` all have **0 rows**, and `SHOPIFY_SHOP_DOMAIN` / `SHOPIFY_CLIENT_ID` /
`SHOPIFY_CLIENT_SECRET` / `SHOPIFY_WEBHOOK_SECRET` are **all unset** (→ "not configured", every live path fails
closed). This matches the deferred [[shopify-connect-009-deferred]] state: code built, activation gated on a
permanent HTTPS domain — which now exists (`verify.secondchanceauthenticators.com`).

**So this is an ACTIVATION-readiness audit, not a build.** No parallel claim/ownership mechanism exists or is
proposed — the integration feeds the existing SCA domain workflows exactly as required.

## 1. What already exists and is reusable UNCHANGED (traced)
- **Webhook receiver** `Sca\Shopify\Http\Controllers\WebhookController@handle` + `public-routes.php` (`POST
  sca/shopify/webhook`, unauthenticated, outside web/admin groups, POST-only). Verifies HMAC on the **raw body
  before parsing**, enforces expected shop domain, topic allowlist, idempotent receipt + process in one
  transaction; returns real 401/200/500.
- **HMAC verifier** `WebhookVerifier::isValid` — header `X-Shopify-Hmac-Sha256`, base64-decode, require 32 bytes,
  `hash_hmac('sha256', rawBody, secret, true)`, `hash_equals` constant-time, fail-closed on missing secret.
- **Idempotent receipts** `WebhookAuditRecorder` + `sca_shopify_webhook_receipts` (`idempotency_key` **unique**,
  `payload_sha256`, status; **no PII, no raw body stored**).
- **Topic pipeline** `SaleLinkEventProcessor` (`orders/paid` → `linkPaidLine`, `orders/cancelled` → `cancelLine`,
  `refunds/create` → `revokeLine`/`refund`) → **`SaleLinkService`** → `sca_shopify_sale_links`.
- **Sale-link model** `sca_shopify_sale_links`: `eyewear_item_id` FK, `shopify_shop_id/order_id/line_item_id`,
  nullable `shopify_product_id/variant_id`, `shopify_customer_ref` (**always written null**), `eligibility_state`
  (CHECK `eligible|claimed|revoked_refund|revoked_return|cancelled`), **unique `webhook_idempotency_key`**, unique
  `(shop_id, line_item_id)`. Writes sale-link rows ONLY — never collector/ownership/claim/transfer.
- **Commerce reversal** `CommerceService::refund(saleLinkId, state)` — sets eligibility_state; and **only if the
  item is already owned**, appends a `disputed` status event (+ projection rebuild). Never deletes ownership.
- **Existing claim/ownership workflow (reused, not duplicated):** `ClaimWorkflow::claim(token, collectorId)`
  resolves the item from the **permanent QR token** (`PassportResolver`), requires an **`eligible`** sale-link,
  then `ClaimService::complete()` flips the sale-link to `claimed` and writes the single `sca_ownership_events`
  (`claim`) under the item lock. Ownership is created ONLY here, by the authenticated collector.
- **OAuth install + token store** `OAuthService` (authorization-code grant, callback HMAC, scope check) +
  `AccessTokenStore` (tokens **encrypted at rest** via `Crypt`/APP_KEY, auto-refresh, fail-closed) +
  `sca_shopify_credentials`. **Read-only** Admin client `ShopifyClient` (host-locked to the verified
  `*.myshopify.com`, pinned API version, no redirects, bearer token).
- **Diagnostics** `DiagnosticsController` + `ConnectivityVerifier` at `GET admin/sca/shopify`
  (not_configured/not_connected/connected + store-identity match, **non-secret fields only**).
- **Onboarding** (logged-out buyer) — Laravel-native `redirect()->guest()` → `url.intended` → `redirect()->
  intended()`, with privacy-safe `AuthContextResolver` context (SCA-COLLECTOR-AUTH-CONTEXT-032). Already handles
  both the existing-collector and new-collector journeys (§5).
- **Config** `config/shopify.php`: `SHOPIFY_SHOP_DOMAIN`, `SHOPIFY_CLIENT_ID/SECRET`, `SHOPIFY_WEBHOOK_SECRET`,
  `SHOPIFY_SCOPES` (default `read_orders,read_products`), `SHOPIFY_API_VERSION` (pinned `2026-07`),
  `SHOPIFY_LINE_ITEM_REF_PROPERTY` (`sca_item_ref`), `SHOPIFY_OAUTH_REDIRECT_URI`, `SHOPIFY_WEBHOOK_PATH`
  (`sca/shopify/webhook`), `SHOPIFY_OAUTH_CALLBACK_PATH`. Secrets env-only; absent → fail-closed.
- **Tests:** `ShopifyConnectionTest` (OAuth/callback-HMAC/token-encryption/connectivity/diagnostics-ACL +
  webhook raw-body HMAC accept/reject, unexpected-shop reject, unsupported-topic ignore, idempotent duplicate, no
  domain mutation) and `ShopifySaleLinkTest` (mapping MISSING/MALFORMED/AMBIGUOUS/NOT_FOUND/INELIGIBLE, idempotency,
  LINE_ITEM_CONFLICT, cancel/tombstone/refund/out-of-order, forged-event rejection, retry-safety 500-then-success,
  no ownership/PII). Both run in the full `tests/Feature/Sca` gate.

**Nothing in §1 needs to change for the pilot.**

## 2. Shopify → SCA item mapping (traced; recommendation)
The deterministic key is **the SCA `public_ref` carried as a Shopify line-item property**
(`SHOPIFY_LINE_ITEM_REF_PROPERTY = sca_item_ref`). `SaleLinkService::linkPaidLine` normalizes it, requires it to
match `/^SCA-[0-9A-Fa-f]{12}$/`, and resolves the item by `public_ref` — **SKU is deliberately NOT the mapping
key** (`sca_eyewear_items.sku` exists but gates nothing and is earmarked only for a future product sync). This is
the correct model for one-of-one authenticated eyewear: one physical item ↔ one SCA `public_ref` ↔ one Shopify
line item; the eligibility gate rejects a second active link (no double-sale), and `(shop, line_item)` is unique.
- **Recommended for the pilot:** list each item so its Shopify line item carries `sca_item_ref = <public_ref>`
  (via a line-item property / cart attribute). Each item is one-of-one, so product/variant need not be unique as
  long as the line-item property is present and correct. **Business/ops decision:** how the property is injected at
  checkout (theme cart attribute, per-product config, or a one-item-per-variant listing). `shopify_product_id`/
  `shopify_variant_id` are stored for audit but are **not** the key.
- **Unmatched mapping** (no property / unknown ref): `SaleLinkService` rejects (`SCA_SALE_MAPPING_MISSING/MALFORMED`
  / `SCA_SALE_ITEM_NOT_FOUND`); the webhook acks (receipt recorded) and nothing is created. For the controlled
  pilot the item is intake'd+certified in SCA **before** listing, so unmatched should not occur; an admin
  reconciliation view for unmatched events is a **future enhancement** (§Findings).

## 3. Eligibility event + cancel/refund (traced current behavior; ratify)
- **Eligibility is created on `orders/paid`** (topic allowlist `Support/WebhookTopics.php`), NOT `orders/create`.
  A placed-but-unpaid or failed order never creates eligibility. **Eligibility ≠ ownership:** a paid order only sets
  the sale-link `eligible`, which makes the item *claimable*; the customer must still complete the QR claim to
  create ownership. (Confirm `orders/paid` as the trigger — business ratification.)
- **Cancel / refund on an UNUSED (eligible, unclaimed) link:** `cancelLine` → `cancelled`; `refunds/create` →
  `revoked_refund`. The item becomes non-claimable. Out-of-order safe: a cancel before paid writes a `cancelled`
  tombstone so a later stale `paid` converges to cancelled.
- **Cancel / refund on an ALREADY-CLAIMED item (current deployed policy):** `CommerceService` sets the sale-link
  revoked **and appends a `disputed` status event** (passport shows UNDER REVIEW) — it **does NOT revoke
  ownership** (append-only provenance preserved; a commerce reversal is flagged for staff, not auto-unwound).
  **This is an existing baked-in policy that the operator must explicitly ratify** (OP-DECISION, §Findings): is
  "refund-after-claim → flag disputed, keep ownership, staff resolves" the desired behavior? (Recommended: yes —
  authenticity/provenance is independent of the commerce transaction.)

## 4. Customer identity / privacy (traced — already minimal)
The integration stores **no Shopify customer PII**: `shopify_customer_ref` is **always written null**; no email,
name, address, phone, or payment data is copied into SCA from the order payload. Eligibility is **item-keyed, not
customer-keyed**, and the claim is **bearer (QR + self-registered collector account), not email-bound** — so SCA
does not even need the buyer's Shopify email to complete a claim. Persisted Shopify data = commerce reference ids
only (shop/order/line-item/product/variant) + the SCA item id + the idempotency key. This already satisfies
"minimum data"; **no change needed**, and the design must stay this way (do not start persisting order email/
address/phone/payment).

## 5. Existing-account vs new-account journeys (traced — both already work)
- **Existing collector:** buys (orders/paid → `eligible`) → scans the item's QR / opens the claim URL → (already
  signed in, `collector.auth`) → `ClaimWorkflow::claim` → ownership → My Collection.
- **New collector:** buys → opens the claim URL while logged out → `CollectorAuthenticate` → `redirect()->guest()`
  stores `url.intended` → login **or** register (privacy-safe `AuthContextResolver` shows item context only while
  eligible) → `redirect()->intended()` returns to the exact claim → claim → My Collection.
Shopify only needs to **trigger the existing eligibility** (the sale-link); the entire buyer journey is already
built. (Open item: how the buyer is handed the claim entry point — scan the physical QR, or a claim link. The QR
is the natural entry for a shipped physical item; see §9/Findings.)

## 6. Shopify auth + webhook security (verified against current Shopify docs)
- **Integration type:** a **custom/own-store app** (single store). The deployed code implements the OAuth
  authorization-code install (`admin/sca/shopify/connect` → `sca/shopify/oauth/callback`), which works for a
  single store; a custom-app token may alternatively be seeded. Confirm the exact app type against current Shopify
  custom-app docs during setup.
- **Admin API scopes:** order webhooks require **`read_orders`** (verified). The config default also includes
  `read_products` (only needed for a future product sync) — **trim to `read_orders` for the pilot** to minimize
  access. No write scopes.
- **Webhook HMAC:** `X-Shopify-Hmac-SHA256` = base64(HMAC-SHA256(**raw body**, **app client secret**)); verify
  constant-time, over the unparsed body. (Implemented exactly.)
- **Dedup / idempotency:** each delivery carries **`X-Shopify-Webhook-Id`** (unique per delivery) and
  **`X-Shopify-Event-Id`** (same merchant action). Maps directly to the **unique** `webhook_idempotency_key` /
  receipts table. (Implemented.)
- **Response/timeout:** must return `200` within Shopify's **1s connection / 5s total** timeout; **8 retries over
  ~4 hours** on no-response/error; an Admin-API subscription is auto-deleted after 8 consecutive failures. The
  receiver's work is a short transaction; retries are idempotent. Keep processing fast/bounded.
- **API versioning:** Shopify ships **quarterly `YYYY-MM`** versions, each supported ≥12 months; **current stable
  is `2026-10`**. The app pins `2026-07` (one quarter back, still supported) → **optionally bump
  `SHOPIFY_API_VERSION` to `2026-10`** and review quarterly. Minor, not a blocker.
- **Secrets:** `SHOPIFY_CLIENT_SECRET` / `SHOPIFY_WEBHOOK_SECRET` / admin token live in **`app/.env` only**
  (tokens additionally encrypted at rest); never Git/governance/tests/logs. (Receipts store a SHA-256 digest, not
  the body.)
- **HTTPS endpoint:** the LE-HTTPS edge exists, but the webhook + OAuth-callback **paths are not yet reachable**
  (§Findings, edge).

## 7. Idempotency & concurrency (traced — already proven)
- **Same order webhook ×N → one action:** `X-Shopify-Webhook-Id` → unique receipt; and `linkPaidLine`'s key
  `shop:orders/paid:order:line` + unique `(shop,line_item)` → one `eligible` row (1062 races converge).
- **Duplicate line-item events → no duplicate ownership/grants:** webhook writes only the sale-link; ownership is
  created solely by `ClaimWorkflow::claim` under the item projection lock, with its own claim idempotency key.
- **Reordered events fail safely:** cancel-before-paid tombstones; terminal revoked/cancelled states are not
  re-eligibled.
- **Concurrent deliveries fail safely:** `lockForUpdate` on the item projection row serializes writers.
- **A retry cannot bypass ownership rules:** eligibility ≠ ownership; `ClaimService::complete` re-checks owner +
  requires `eligible` under the lock.
- **Webhook never mutates append-only ownership history directly:** it writes sale-link eligibility (and, only via
  `CommerceService` on a post-claim reversal, a `disputed` status event) — ownership rows are written only by the
  authorized claim workflow. (All covered by `ShopifySaleLinkTest` incl. retry-after-500.)

## 8. Failure / exception matrix (current behavior)
| Case | Behavior (traced) |
|---|---|
| Unknown SCA item / missing/malformed ref | `SaleLinkService` rejects (MAPPING_MISSING/MALFORMED/ITEM_NOT_FOUND); webhook acks; nothing created |
| Duplicate mapping (second active line for an owned/linked item) | `ITEM_INELIGIBLE` / `LINE_ITEM_CONFLICT`; no double-sale |
| Already-owned / already-claimed item | claim → `ALREADY_OWNED` (409) / `already_yours`; sale-link already `claimed` |
| Customer email missing | irrelevant — claim is not email-bound; no PII needed |
| Order unpaid | no `orders/paid` → no eligibility |
| Order cancelled (unclaimed) | `cancelled`; non-claimable |
| Refund partial | **OP-DECISION** — current `refunds/create` → `revokeLine` revokes the line; whether a *partial* refund should revoke needs ratification |
| Refund full (unclaimed) | `revoked_refund`; non-claimable |
| Refund/cancel after claim | sale-link revoked + `disputed` status event; **ownership preserved** (ratify, §3) |
| Webhook replay | idempotent (unique webhook id + unique sale-link key) |
| Malformed / invalid HMAC | 401, nothing recorded/processed (fail-closed) |
| Shopify outage | no delivery; nothing happens; buyer can still claim once eligibility arrives |
| SCA outage | Shopify retries 8× over 4h; idempotent on recovery; **consider**: after 8 failures the subscription auto-deletes (operational monitoring) |
| Multiple SCA items in one order | one sale-link per line item; each claimed independently |

## 9. Admin/operator UX (traced + gap)
Exists: `GET admin/sca/shopify` diagnostics (connection state + store identity, non-secret). Gaps for operability
(not pilot-blocking under controlled listing): no per-item sale-link/eligibility badge on the item detail is
confirmed present, and there is **no admin reconciliation view for unmatched/failed commerce events** (receipts
are recorded but not surfaced in a UI). → **future enhancement**. Avoid exposing Shopify PII in any such view
(none is stored anyway).

## 10. Activation plan (smallest path — mostly config/infra, ~zero code)
**Architecture (text):**
`Shopify store (orders/paid|cancelled, refunds/create)` → HTTPS `POST verify.secondchanceauthenticators.com/
sca/shopify/webhook` → `WebhookController` (HMAC verify raw body → idempotent receipt → `SaleLinkEventProcessor`
→ `SaleLinkService` writes `sca_shopify_sale_links.eligible` keyed by `sca_item_ref` line-item property) …
independently … `buyer scans item QR / claim URL` → `collector login/register (url.intended)` →
`ClaimWorkflow::claim` (requires `eligible`) → `sca_ownership_events(claim)` → My Collection.

**Required for the Shopify pilot (no schema change; no new services):**
1. **Edge (infra):** add `sca/shopify/webhook` **and** `sca/shopify/oauth/callback` to the Caddy `@public` matcher
   (currently `path /p/* /collector /collector/*`) so Shopify can reach them; recreate `sr-caddy` at a quiet hour
   (co-tenant smsrocket caution, per host rules). The OAuth *install start* (`/admin/sca/shopify/connect`) stays
   under staff-IP `/admin`.
2. **Shopify-side (operator):** create the custom/own-store app; set scopes to **`read_orders`**; set the webhook
   signing secret; register the three webhook subscriptions (`orders/paid`, `orders/cancelled`, `refunds/create`)
   to the public webhook URL at API version `2026-10`; obtain client id/secret.
3. **Config (operator, `app/.env` only — never Git):** `SHOPIFY_SHOP_DOMAIN`, `SHOPIFY_CLIENT_ID`,
   `SHOPIFY_CLIENT_SECRET`, `SHOPIFY_WEBHOOK_SECRET`, `SHOPIFY_OAUTH_REDIRECT_URI` (= the public callback URL);
   optionally `SHOPIFY_API_VERSION=2026-10` and trim `SHOPIFY_SCOPES=read_orders`. Then one-time OAuth install via
   `/admin/sca/shopify/connect` (staff) → verify `admin/sca/shopify` shows **connected** + correct store identity.
4. **Listing discipline (ops):** each pilot item intake'd + certified in SCA first; its Shopify listing carries
   `sca_item_ref = <public_ref>` as a line-item property.
5. **Tests/verification:** the full `tests/Feature/Sca` gate already covers the webhook + sale-link behavior; add a
   staging/sandbox store dry-run (a Shopify test order on a dev store) before the real sale — **not** a production
   order.

**Optional config-only code deltas (tiny, reviewable):** bump `SHOPIFY_API_VERSION` default to `2026-10`; default
`SHOPIFY_SCOPES` to `read_orders`. Neither is required to activate.

**Deployment sequence:** (a) edge change + recreate sr-caddy; (b) set `app/.env` Shopify secrets (code-only, no
recreate needed beyond config:clear); (c) OAuth install; (d) register webhooks; (e) dev-store dry-run; (f) first
real pilot sale. **Rollback:** unset the `app/.env` Shopify vars (→ fail-closed "not configured") and/or remove the
two edge paths and recreate sr-caddy; delete the Shopify webhook subscriptions. No schema to roll back (tables stay
empty/dormant). All reversible; zero provenance impact.

**Future Shopify enhancements (NOT pilot):** product/catalog sync (`read_products`, populate `sca_eyewear_items.
sku`), an admin reconciliation view for unmatched/failed commerce events, outbound order/QR write-back, fulfillment
handling, automatic claim-link delivery (needs SMTP — see [[sca-production-cutover-phase1]]).

## 11. GO / NO-GO + business decisions
**Recommendation: GO to ACTIVATE** — the software is complete, tested, deployed, and fail-closed; there are **no
software blockers**. Activation is **operational/infra + business ratification**, with a fully reversible rollout.

**Operator/business decisions required before activation:**
- **OP-1** Ratify `orders/paid` as the eligibility trigger (not order creation).
- **OP-2** Ratify the refund/cancel-after-claim policy: sale-link revoked + `disputed` flag, **ownership
  preserved** (recommended), vs any stronger action. And whether a **partial** refund should revoke eligibility.
- **OP-3** Choose how `sca_item_ref` (the SCA `public_ref`) is placed on each Shopify line item, and confirm the
  intake→certify→list ordering so mappings never go unmatched.
- **OP-4** Approve the **edge change** (adding the two public paths + sr-caddy recreate window) on the shared host.
- **OP-5** Confirm the Shopify **custom-app** setup (scopes `read_orders`, three webhook topics, API `2026-10`,
  secrets) and that secrets go only into `app/.env`.
- **OP-6** Confirm the buyer's claim entry point (physical QR scan vs emailed/printed claim link; note no SMTP yet).

**No code/DB/Shopify/.env/edge change performed in this audit.** Governance only; ACTIVE/NEXT unpromoted. STOP for
ChatGPT/operator review. See [[shopify-connect-009-deferred]], [[sca-pilot-readiness-operator-workflow-audit]],
[[sca-production-cutover-phase1]], [[sca-new-recipient-transfer-onboarding-audit]], [[report-to-github-first]].

Sources (current Shopify requirements): Shopify "Verify webhook deliveries" (shopify.dev/docs/apps/build/webhooks/
verify-deliveries), "Deliver webhooks through HTTPS", WebhookSubscriptionTopic (admin-graphql), and API versioning
(shopify.dev/docs/api/usage/versioning).

# SCA Shopify Activation — Pre-flight + Edge Design (READ-ONLY)

**Date:** 2026-10-05 · **Production baseline:** `98ae654`, migrations **120**.
**Status: PRE-FLIGHT / DESIGN ONLY. No activation, credentials, `.env`/Caddy change, webhook registration, OAuth
connect, order, or production mutation.** Traced against the deployed `Sca/Shopify` code (file:line); current
Shopify behavior verified against live docs (cited). Decision at the end: **GO/NO-GO with one conditional gate.**
Builds on the architecture audit (gov `cfcddc8`).

## 1. Exact webhook behavior (traced — `SaleLinkEventProcessor` + `WebhookController`)
Receiver `WebhookController@handle`: reads raw body → `WebhookVerifier::isValid(rawBody, X-Shopify-Hmac-Sha256,
config('sca-shopify.webhook_secret'))` (fail-closed 401 on missing/invalid) → expected-shop check
(`X-Shopify-Shop-Domain` must equal `expected_shop_domain`, else 401) → topic allowlist (unsupported → 200
ignored, not recorded) → **one transaction**: `WebhookAuditRecorder::record` (idempotent on `X-Shopify-Webhook-Id`)
and, **only for a newly-recorded receipt**, `SaleLinkEventProcessor::process`. Infra failure → 500 (rollback,
retryable); business rejection inside the processor → caught, safe no-op, still a recorded delivery.

- **`orders/paid`** → per `line_items[]`: extract `sca_item_ref` from the line's `properties[{name,value}]`; no
  ref → skip (ordinary non-SCA line); ref present → `SaleLinkService::linkPaidLine(shop, order, line, ref,
  product_id, variant_id)` → one `eligible` sale-link (idempotent key `shop:orders/paid:order:line`; unique
  `(shop,line)`); eligibility gate rejects a second active line / an already-owned item (fail-closed). Writes ONLY
  `sca_shopify_sale_links`; never ownership.
- **`orders/cancelled`** → per line: ref present → `cancelLine` (revoke active link to `cancelled`, or write a
  `cancelled` **tombstone** so a later stale `paid` converges to cancelled); no ref → `revokeLine(..., 'cancelled')`
  (revoke an existing active link only, no tombstone).
- **`refunds/create`** → per `refund_line_items[]`: take `line_item_id`, call `revokeLine(shop, lineId,
  'revoked_refund')` (revokes the active link **for that line id only**). No `restock`/returns topic handling;
  `revoked_return` is never emitted.
- **Revocation effect** (`CommerceService::refund`): always sets the sale-link `eligibility_state`; **and only if
  the item is already owned**, appends a `disputed` `sca_status_events` row (passport → UNDER REVIEW) + projection
  rebuild. **Never deletes ownership** (append-only preserved).

## 2. Full vs partial refund — the HARD-STOP determination (exact behavior)
**`handleRefund` keys purely on the presence of a `line_item_id` in `refund_line_items`; it ignores the refunded
`quantity` and amount.** Combined with Shopify's payload convention (verified against live docs):
- A **pure amount-only partial refund** (money back, item kept, no line returned) carries **no `refund_line_items`
  for the SCA line** (the refund is a transaction/order adjustment) → the processor loops over nothing for that
  line → **no-op → SCA eligibility/provenance untouched → no `disputed`.** ✓
- A refund that **returns the SCA item's line** populates `refund_line_items` with that `line_item_id` → the
  active link is revoked (`revoked_refund`), and if the item is already claimed, a `disputed` event is appended.
- Refunds of **other** lines never touch the SCA item: `revokeLine` matches on `shopify_line_item_id`; a non-SCA
  line has no matching sale-link → `n=0` → no-op.

**Determination against the ratified policy ("partial refunds must NOT auto-create an adverse decision"):**
- The implementation does **NOT** "mark a claimed item disputed for *any* refund amount." An amount-only partial
  refund (item kept) is a **safe no-op**. The adverse path fires **only** when the SCA item's own line appears in
  `refund_line_items` (i.e., the item is being returned).
- Because pilot items are strictly **one-of-one (quantity 1 per line)**, a `refund_line_items` entry for the SCA
  line is **always a full-line return** — there is no partial-vs-full ambiguity *within* the SCA line for the
  pilot. So "full refund/return after claim → disputed, ownership preserved" is exactly the ratified behavior, and
  partial (amount-only) refunds do not dispute.
- **Latent gap (NOT applicable to the one-of-one pilot):** the handler ignores `quantity`, so a partial-*quantity*
  refund of a **multi-unit** line would over-revoke the whole line. This cannot occur for one-of-one qty-1 items.

**Verdict on the hard stop: NOT a hard-stop code-change blocker for the controlled one-of-one pilot**, provided
two conditions hold (below). The strict blocker condition ("disputes for any refund amount") is **not** met — the
safety is real but *emergent* from Shopify's convention + one-of-one quantity, not from an explicit amount check.
Therefore it is gated, not free:
- **GATE-R1 (ops discipline):** every SCA item is listed as **quantity 1** (one-of-one); never attach an
  `sca_item_ref` to a multi-quantity line. (OP-decision.)
- **GATE-R2 (empirical HALT gate):** in the dev-store dry-run (§7), issue an **amount-only partial refund** on a
  claimed test item and **prove `refund_line_items` is empty → no `disputed`**, before any real sale. If that
  dry-run ever shows a partial amount refund populating `refund_line_items` for the kept item, **STOP** and apply
  the narrow change below.
- **Recommended future hardening (not pilot-blocking):** make `handleRefund` compare refunded `quantity` to the
  ordered quantity and only revoke on a **full-line** refund — a one-method change in `SaleLinkEventProcessor`, no
  schema, no domain change. Do this before selling any multi-quantity line.

## 3. Duplicate / out-of-order / already-claimed / multi-item (traced)
- **Duplicate webhook** (same `X-Shopify-Webhook-Id`): `WebhookAuditRecorder` unique `idempotency_key` → receipt
  recorded once; processing runs only for a NEW receipt → replay is a no-op. Sale-link also unique on
  `(shop,line)` + its own key → one `eligible` row regardless.
- **Out-of-order:** cancel-before-paid writes a `cancelled` tombstone; a later `paid` for that line converges to
  cancelled (unique-key conflict handled). Refund/cancel with no active link → `noop`. Terminal revoked/cancelled
  states are not re-eligibled.
- **Already-claimed item:** `orders/paid` eligibility gate rejects an already-owned item (`ITEM_INELIGIBLE`); the
  claim path itself re-checks owner under lock (`ALREADY_OWNED`/`already_yours`). A refund after claim → sale-link
  revoked + `disputed`, ownership preserved.
- **Multiple SCA items in one order:** one sale-link per `line_item`; each is linked/claimed/revoked
  independently.

## 4. API version (traced — no change required)
`ApiVersions`: SUPPORTED `{2025-10, 2026-01, 2026-04, 2026-07}`, pin `LATEST_STABLE = 2026-07`. `2026-07` released
2026-07-01 and is supported ≥12 months (through ~2027-07), so it remains **supported and compatible** with
everything this integration calls (only `/admin/api/{v}/shop.json` for identity + inbound webhooks; no
version-sensitive surface). Current latest stable is `2026-10`, but **no upgrade is required** — keep `2026-07`.
(Cosmetic: the SUPPORTED list may later add `2026-10`; not needed to activate.)

## 5. Edge design — expose ONLY the two external Shopify endpoints
Today the Caddy `verify.` site block has `@public path /p/* /collector /collector/*`; everything else is
default-denied (SCA-038 `/p/*` 200/404, `/storage` 404, `/admin*` staff-IP 403, `/collector/*` public), with
Phase-B HTTPS-only + Secure cookies and public `:8080` retired (kr-app loopback). The Shopify webhook + OAuth
callback are NOT in the allowlist → edge returns 404 (verified).

**Smallest change — add a path-EXACT matcher, never the `/sca/*` namespace:**
```
@shopify path /sca/shopify/webhook /sca/shopify/oauth/callback
handle @shopify { reverse_proxy kr-app:80 }    # same upstream as the public passport
```
- **Webhook path:** `POST /sca/shopify/webhook` — **permanent** public exposure (Shopify must reach it). Method:
  POST only (a GET returns the stack's 404; HMAC rejects anything unsigned with 401).
- **OAuth callback path:** `GET /sca/shopify/oauth/callback` — public, but needed **only transiently during the
  one-time install** (Shopify redirects the operator's browser here). It is state-nonce + query-HMAC + shop-domain
  validated. **Recommendation:** add it for the install window and **remove it afterward** (token refresh does not
  use the callback), leaving only the webhook path permanently public. (Keeping it is low-risk — fully validated —
  but removing minimizes surface.)
- **OAuth install start** `GET /admin/sca/shopify/connect` is **operator-initiated from a staff browser** → stays
  under `/admin` staff-IP; **no public exposure needed.**
- **Diagnostics** `GET /admin/sca/shopify` stays under `/admin` staff-IP → **remains protected.**
- **Path-exact, not wildcard:** do NOT expose `/sca/shopify/*` or `/sca/*` — only the two literal paths, so no
  other current/future `/sca/...` route is ever publicly reachable.
- **Interaction with existing policy (all preserved):** additive matcher; `/p/*` SCA-038 200/404 unchanged;
  `/storage` 404 unchanged; `/admin*` staff-IP unchanged; `/collector/*` unchanged; the webhook is stateless and
  outside the `web` group (no session/CSRF/cookies) so Phase-B Secure-cookie policy is irrelevant to it; traffic
  arrives via the edge:443 → kr-app, so public `:8080` stays retired/loopback. HMAC is the webhook's only
  authenticator (by design).
- **Shared-host / smsrocket:** the matcher lives in the `verify.` site block only; applying it needs an
  `sr-caddy` recreate which briefly drops smsrocket.io (known host caution) → do at a **quiet hour**; zero change
  to smsrocket's own routes.

## 6. Shopify-side activation checklist (no real values invented)
- **App type:** a single-store **custom/own-store app** (SCA's store). Install via the deployed OAuth
  authorization-code flow.
- **Minimum scopes:** **`read_orders`** (order webhooks). **Trim the config default's `read_products`** (only
  needed for a future product sync). No write scopes.
- **Callback URL:** `https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback`
  (= `SHOPIFY_OAUTH_REDIRECT_URI`).
- **Webhook URL:** `https://verify.secondchanceauthenticators.com/sca/shopify/webhook` (= `SHOPIFY_WEBHOOK_PATH`).
- **Three webhook topics:** `orders/paid`, `orders/cancelled`, `refunds/create`, at API version **`2026-07`**.
- **Required secrets/config keys (values set later, `app/.env` ONLY, never Git):** `SHOPIFY_SHOP_DOMAIN`,
  `SHOPIFY_CLIENT_ID`, `SHOPIFY_CLIENT_SECRET`, `SHOPIFY_WEBHOOK_SECRET` (= the app's client/API secret that signs
  webhooks — confirm it equals the client secret for app-created subscriptions), `SHOPIFY_OAUTH_REDIRECT_URI`;
  optionally `SHOPIFY_SCOPES=read_orders`. Also set `expected_shop_domain` to the store.
- **OAuth sequence:** staff opens `/admin/sca/shopify/connect` (staff-IP) → state nonce stored → redirect to
  `{shop}/admin/oauth/authorize` → operator approves → Shopify redirects to the public callback → state (single-use
  `hash_equals`) + query HMAC + shop-domain validated → code exchanged → token **encrypted at rest**.
- **Diagnostics success criteria:** `/admin/sca/shopify` shows **connected** + the store identity matches
  `expected_shop_domain` (via `ShopifyClient::getShop`), granted scopes satisfy `read_orders`, no secret values
  rendered.

## 7. SCA-side activation sequence (HALT gates + BEFORE/AFTER fingerprints + rollback)
Baseline fingerprints (prove unchanged where noted): provenance `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4`,
migrations **120**, gallery 3; shopify tables `credentials=0, receipts=0, sale_links=0`; edge `/sca/shopify/*` →
404.

1. **Edge change** — add the two path-exact matchers, recreate `sr-caddy` (quiet hour). **AFTER:** GET
   `/sca/shopify/webhook` reaches the app (no longer edge-404); `/p/*`, `/storage`, `/admin*`, `/collector/*`,
   smsrocket all unchanged; provenance FP + migrations unchanged (no DB touched). **HALT if** any existing edge
   invariant regresses. **Rollback:** remove the matchers, recreate `sr-caddy`.
2. **Secrets/config** — set `SHOPIFY_*` in `app/.env`; `config:clear`. **AFTER:** diagnostics flips
   not_configured→not_connected; shopify tables still 0; provenance FP unchanged. **Rollback:** unset the vars →
   fail-closed not_configured.
3. **OAuth install** — `/admin/sca/shopify/connect` → approve → callback. **AFTER:** `sca_shopify_credentials`
   `0→1` (encrypted token); diagnostics **connected** + store identity match. **HALT if** state/HMAC/shop checks
   fail or identity mismatches. **Rollback:** delete the credential row (operator-authorized) → not_connected.
   (Then optionally remove the callback edge path.)
4. **Webhook registration** — register the three topics → the webhook URL (API 2026-07). **AFTER:** Shopify shows
   three active subscriptions. **Rollback:** delete the subscriptions.
5. **Controlled product mapping** — create **ONE NEW dedicated test SCA item** (do NOT touch existing provenance
   pilot items), intake→authenticate→certify→download its QR; list it on a **dev/sandbox store** (not a live
   charge) with the line-item property `sca_item_ref = <that item's public_ref>`, **quantity 1**. **AFTER:** the
   new item exists + is certified; existing-items provenance FP unchanged.
6. **Controlled test order (dev store)** — place a **test** `orders/paid`. **HALT gates:** webhook receipt recorded
   (idempotent), `sca_shopify_sale_links` has exactly ONE `eligible` row for the test line, **no ownership/status
   writes**, HMAC-reject path returns 401 for a forged body. **GATE-R2:** also run an **amount-only partial
   refund** on the test item post-claim and confirm `refund_line_items` empty → **no `disputed`**. **Rollback:**
   cancel/refund the test order (sale-link → cancelled/revoked_refund); the test item is isolated.
7. **Claim** — a **test collector** claims via the item's QR (login/register → `url.intended` → claim). **AFTER:**
   one `sca_ownership_events(claim)` for the test item, sale-link → `claimed`; passport for the test item resolves.
   **Rollback:** none needed (test item only); do not mutate real items.
8. **Verify provenance** — the test item's passport + collector "My Collection" correct; **every existing
   provenance pilot item's FP unchanged** (`c3fea71a`), migrations still 120, QR/is_production unchanged.

At no stage does a Shopify event write ownership — only the authorized claim does. Real-customer sale happens only
after a clean dev-store dry-run.

## 8. Security re-verification (traced)
- **Webhook HMAC:** `WebhookVerifier` uses `config('sca-shopify.webhook_secret')`, computes `hash_hmac('sha256',
  rawBody, secret, true)` over the **raw request body**, base64-decodes the `X-Shopify-Hmac-Sha256` header, requires
  32 bytes, `hash_equals` constant-time; **missing secret or invalid signature → false → 401, no record, no
  mutation.** Secret never logged/rendered.
- **OAuth:** install generates `bin2hex(random_bytes(16))` state in the session; callback validates shop
  (`*.myshopify.com` regex + exact expected match), single-use state (`session->pull` + `hash_equals`), query HMAC
  (sorted params, hex, `hash_equals` keyed by client secret), then exchanges code. Tokens stored via
  `Crypt::encryptString` (APP_KEY) — **no plaintext token in DB/logs**; near-expiry refresh; fail-closed null.
- No secret values appear in this document.

## 9. GO / NO-GO
**GO to activate (conditional)** — there is **no hard-stop code-change blocker** for a controlled one-of-one
pilot: `orders/paid`/`cancelled`/`refunds/create`, idempotency, out-of-order, already-claimed, and multi-item all
behave per the ratified policy; an amount-only partial refund is a safe no-op; HMAC/OAuth/token security verified;
API `2026-07` supported (no change). Activation is gated on:
- **GATE-R1:** enforce one-of-one **quantity-1** listings (never an `sca_item_ref` on a multi-qty line).
- **GATE-R2:** the dev-store dry-run empirically confirms an amount-only partial refund yields empty
  `refund_line_items` → no `disputed`; if not, STOP and apply the narrow full-line-only refund change first.
- **Operator/business:** OP-1 ratify `orders/paid` trigger; OP-2 the refund/cancel-after-claim → disputed /
  ownership-preserved policy; OP-3 how `sca_item_ref` is placed + intake→certify→list ordering + qty-1; OP-4
  approve the edge change + `sr-caddy` recreate window; OP-5 custom-app setup + `app/.env`-only secrets (+ whether
  to remove the callback path post-install); OP-6 buyer claim entry point (QR; SMTP deferred).
- **Recommended (not blocking):** add the explicit full-line-only refund check as future hardening before any
  multi-quantity listing.

**No implementation, credentials, `.env`/Caddy change, webhook registration, OAuth connect, or order performed.**
Governance only; ACTIVE/NEXT unpromoted. STOP for ChatGPT/operator review. See
[[sca-shopify-integration-readiness-audit]], [[sca-production-cutover-phase1]] (edge/Phase-B),
[[sca-pilot-readiness-operator-workflow-audit]], [[report-to-github-first]].

Sources (current Shopify behavior): shopify.dev "Verify webhook deliveries", "WebhookSubscriptionTopic",
admin-rest/admin-graphql "Refund" / `refund_line_items`, and "API versioning".

# SCA — Activate Shopify Product Webhooks: RESULT + Owner Instructions

**The SCA receiver is validated and ready; the actual subscription registration is an owner-gated Shopify app-version action — exact instructions below, STOP before release.** No real Shopify product modified, no passport/ownership/authentication created, no reconciliation scheduled, no code deploy/migration. 2026-10-27. **STOP for owner.**

## [1] Preconditions (confirmed)

- Deployed SCA code **`905ea7d`**; Shopify credential `scope=read_orders,read_products`, `has_token=1`.

## [2] Current webhook subscriptions — the existing ones are APP-CONFIG (managed), not API-registered

A read-only Admin API `GET /admin/api/2026-07/webhooks.json` returned **0** webhooks. Yet order webhooks have been delivered historically (108 receipts recorded). Conclusion: the existing `orders/paid`, `orders/cancelled`, `refunds/create` subscriptions are **declared in the Shopify app configuration / app version** (app-managed subscriptions), which are **not** listed by the REST `webhooks.json` endpoint (that only lists Admin-API-created webhooks). Therefore the three product subscriptions must be added the **same way** — in the app version configuration — to stay consistent and app-managed.

## [3][6] Registration is an OWNER action (cannot be done from the server)

I did **not** register the subscriptions, because:
- The existing subs are app-config/managed — the product subs belong in the **same app-version configuration**, released via the **Dev Dashboard / Shopify CLI (`shopify app deploy`)**. That configuration is **not** on this server, and there are no Partner/CLI credentials here.
- The SCA `ShopifyClient` is deliberately **read-only** (no webhook-registration method), and this task forbids deploying code to add one.

So per the authorization's final clause, exact instructions are provided and I **STOP before release**.

### Exact change for the owner (additive; preserves the 3 existing)

If the app uses **`shopify.app.toml`** (Shopify CLI), add the three product subscriptions alongside the existing order/refund ones, all pointing at the same endpoint, then `shopify app deploy` and release:

```toml
[webhooks]
api_version = "2026-07"

  # --- existing (KEEP — do not remove) ---
  [[webhooks.subscriptions]]
  topics = ["orders/paid", "orders/cancelled", "refunds/create"]
  uri = "https://verify.secondchanceauthenticators.com/sca/shopify/webhook"

  # --- ADD (SCA inventory sync Phase 1) ---
  [[webhooks.subscriptions]]
  topics = ["products/create", "products/update", "products/delete"]
  uri = "https://verify.secondchanceauthenticators.com/sca/shopify/webhook"
```

Or via the **Dev Dashboard** (app → Configuration / Webhooks): add subscriptions for `products/create`, `products/update`, `products/delete` with endpoint `https://verify.secondchanceauthenticators.com/sca/shopify/webhook`, API version `2026-07`, format JSON; **keep** the three order/refund subscriptions; then **release the new app version**.

### [4][5] Preserved
- `orders/paid`, `orders/cancelled`, `refunds/create` — kept (additive change only).
- Endpoint unchanged (`…/sca/shopify/webhook`); API version `2026-07`; HMAC verification unchanged (Shopify signs with the app client secret = the SCA `SHOPIFY_WEBHOOK_SECRET`; the receiver already verifies it).

### [6] Verifying the active version has all six (owner)
After release, confirm in the Dev Dashboard app version that **all six topics** are subscribed to the SCA endpoint (3 order/refund + 3 product). Note: these app-managed subscriptions will **not** appear in `webhooks.json` — verification is in the app-version configuration, not the REST list.

## [7][8] SCA receiver validated end-to-end (local controlled test; no Shopify involvement, no inventory change)

Because a real Shopify delivery can't occur until the owner registers, the SCA endpoint was validated directly with a **synthetic, HMAC-signed** product webhook (secret used in-container, never printed; synthetic test IDs, cleaned up after):

| Test | Result |
|---|---|
| Bad signature → endpoint | **HTTP 401 "invalid signature"** — HMAC enforcement holds; nothing recorded/processed |
| Valid signed `products/update` | **HTTP 200 "ok"** — receipt recorded (`processing_outcome=processed`, `actionable_count=1`, `rejected=0`); catalog product + variant upserted |
| Replay (same `X-Shopify-Webhook-Id`) | **HTTP 200 "ok"** — **1** receipt only (idempotent); no second receipt, no duplicate catalog row |

So **signature enforcement, receipt recording, idempotency, and successful catalog processing all PASS** on the live receiver. (This mirrors the 21/67 isolated DB-test coverage, now confirmed against the production endpoint.)

## [9] Catalog counts valid; provenance unchanged; health OK

After cleanup of the synthetic test artifacts: `sca_shopify_products = 4565`, `sca_shopify_variants = 5330`, `sca_shopify_webhook_receipts = 108` (all back to pre-test values; no synthetic rows remain). Provenance unchanged: `items=3, state=3, ownership=5, certifications=4, qr_identifiers=3, external_claim_grants=1`. `/admin/login → 200`, `kr-app` running. **No eyewear item, certificate, ownership, QR, or claim-link was created or modified.**

## [10] Active version & merchant action needed

- **Active-version change required (owner):** add the three `products/*` subscriptions to the app version configuration (snippet above) and **release it**. The SCA side needs no change — the receiver, endpoint, API version, and HMAC are already in place and proven.
- After release, a quick confirmation run (separately) should: send one Shopify "test notification" (or edit a product) and confirm a new `sca_shopify_webhook_receipts` row with `processing_outcome=processed` and the catalog row updated — with provenance still unchanged.
- Reconciliation remains **unscheduled** (unchanged).

**STOP — SCA receiver is ready and proven; the three product webhook subscriptions must be added to the Shopify app version and released by the owner (instructions above). No real Shopify product modified, no passport/ownership/authentication created, no reconciliation scheduled, no code/migration.**

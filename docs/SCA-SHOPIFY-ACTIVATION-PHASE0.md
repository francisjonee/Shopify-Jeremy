# SCA Shopify Activation — Phase 0 (re-audit before mutation) — PASS

**Date:** 2026-10-06 · **Deployed app:** `98ae654`, migrations **120**.
**Status: Phase 0 COMPLETE — all checks PASS, no mutation performed. STOPPED at the Phase 0→1 boundary pending
operator secret entry.** Executes Phase 0 of `NEXT_TASK.md` (SCA Shopify Activation / existing-app connection).
No secrets recorded.

## Phase 0.1 — baseline state (PASS)
- DEPLOYED_HEAD `98ae6542294e42f3fd7dc86fbda5dc69a32e6d71` == origin/main; **clean tree**; no app code change.
- Containers: kr-app healthy, kr-mariadb healthy, sr-caddy up (post edge-activation).
- Provenance `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4`; migrations **120**; items 2, owners 4, certs 3.
- Shopify tables pre-activation: `credentials/receipts/sale_links = 0/0/0`.

## Phase 0.2 — exact env keys the deployed code consumes (PASS, no divergence)
`config/shopify.php` maps (config ⇐ env):
- `expected_shop_domain` ⇐ **`SHOPIFY_SHOP_DOMAIN`** (one key drives BOTH the webhook expected-shop check and the
  OAuth expected shop — there is no separate expected-shop env key).
- `api_version` ⇐ `SHOPIFY_API_VERSION` (default `ApiVersions::LATEST_STABLE` = `2026-07`).
- `client_id` ⇐ `SHOPIFY_CLIENT_ID`; `client_secret` ⇐ `SHOPIFY_CLIENT_SECRET` (SECRET).
- `scopes` ⇐ `SHOPIFY_SCOPES` (code default `read_orders,read_products` — the pilot will set `read_orders`).
- `line_item_ref_property` ⇐ `SHOPIFY_LINE_ITEM_REF_PROPERTY` (default `sca_item_ref`).
- `oauth_redirect_uri` ⇐ `SHOPIFY_OAUTH_REDIRECT_URI`.
- `webhook_secret` ⇐ **`SHOPIFY_WEBHOOK_SECRET`** (a DISTINCT key from `SHOPIFY_CLIENT_SECRET`, read by
  `WebhookVerifier`).
- Also read (safe defaults, not in the task's list): `SHOPIFY_APP_MODEL` (default `dev_dashboard_external`),
  `SHOPIFY_CONNECT_TIMEOUT`/`SHOPIFY_TIMEOUT`, `SHOPIFY_WEBHOOK_PATH` (`sca/shopify/webhook`),
  `SHOPIFY_OAUTH_CALLBACK_PATH` (`sca/shopify/oauth/callback`) — both path defaults match the live edge.

All 8 task-expected keys exist with the exact expected names → **no divergence, no STOP.**

## Phase 0.3 — Shopify tables pre-activation (PASS)
`sca_shopify_credentials`, `sca_shopify_webhook_receipts`, `sca_shopify_sale_links` = **0 / 0 / 0** (counts only;
no payloads).

## Phase 0.4 — edge behavior unchanged, no broad `/sca/*` (PASS)
Public probes: `POST /sca/shopify/webhook` → **401** (reaches app, HMAC fail-closed, secret still unset); `GET
/sca/shopify/oauth/callback` → **400** (reaches app, fails safe); wrong-method webhook/callback → **404**;
`/sca/shopify/install`, `/sca/anything-else` → **404**; `/admin/sca/shopify` → **403** (staff-IP); `/storage/x` →
**404**; `/p/<valid>` 200, `/p/<bogus>` 404 (SCA-038); `/collector/login` 200; `smsrocket.io` **302**; public
`:8080` **000** (retired).

## Phase 0.5 — no new app/code/schema required (PASS)
The `Sca/Shopify` package is a pure **receiver**: there is **no** in-app webhook registration/subscription code
(no `webhookSubscriptionCreate`, no artisan command). Webhooks are registered **operator-side via the existing
Shopify app** (`sca-shopify-activation-v2` app config / dev dashboard). This is by design, not a missing
capability → **no code/schema work; no STOP.**

### Determination for `SHOPIFY_WEBHOOK_SECRET` (for Phase 1/3)
`webhook_secret` is a separate env key and the receiver verifies HMAC with it. For webhooks **declared/registered
by the dev-dashboard app** (the `app_model=dev_dashboard_external` design), Shopify signs webhook deliveries with
the **app's Client Secret (API secret key)** → **`SHOPIFY_WEBHOOK_SECRET` should be set to the app's Client Secret
value.** Confirm against how version `sca-shopify-activation-v2` declares the webhooks; only if the webhooks were
instead created under the store's **Settings → Notifications** would a distinct store webhook signing secret apply.
(Not asserted as interchangeable without this confirmation, per the task.)

## Phase 0 verdict: PASS — cleared to proceed to Phase 1. No mutation performed.

## Operator hand-off (Phase 1 needs operator action — STOP here)
Phase 1 begins `.env` mutation and requires operator-entered secrets (the task forbids Claude recovering/echoing
secret values). To proceed, on the server (`app/.env`, never Git):
- Claude can set the **non-secret** values on your go: `SHOPIFY_SHOP_DOMAIN=second-chance-authenticators.myshopify.com`,
  `SHOPIFY_SCOPES=read_orders`, `SHOPIFY_API_VERSION=2026-07`, `SHOPIFY_LINE_ITEM_REF_PROPERTY=sca_item_ref`,
  `SHOPIFY_OAUTH_REDIRECT_URI=https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback`.
- **Operator must enter directly on the server** (not in chat): `SHOPIFY_CLIENT_ID` and `SHOPIFY_CLIENT_SECRET`
  from the existing **SCA Eyewear Registry** Shopify Dev app, and `SHOPIFY_WEBHOOK_SECRET` (= the app Client Secret
  for app-declared webhooks — confirm per the determination above).
Then Claude clears config safely and runs **Gate A** (diagnostics = configured-but-not-connected; FP/migrations/
edge/co-tenant unchanged) before any OAuth.

Governance recorded; ACTIVE task remains Shopify activation. **STOP for operator input (secrets/Shopify UI).** No
secrets, tokens, or PII in this document. See [[sca-shopify-activation-preflight]], [[sca-shopify-edge-activation]],
[[sca-shopify-integration-readiness-audit]].

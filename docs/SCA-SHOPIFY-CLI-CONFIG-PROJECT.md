# SCA Shopify CLI configuration project — created (for EXISTING app 424307752961)

**Date:** 2026-10-06 · **Gov repo:** `francisjonee/Shopify-Jeremy`. **Status: config project created + pushed. No
deploy/link/login/release, no Shopify-side mutation, no new app. STOP for operator.** No secrets committed.

## Decision: location
Placed under the **governance repo**, separate from the Laravel runtime (the receiver stays in
`francisjonee-sca-platform-private → packages/Sca/Shopify`): new directory **`shopify-app/`** in
`francisjonee/Shopify-Jeremy`. Rationale — it is under SCA governance (where ChatGPT/operator review), the
`github-sca` deploy key can write it, and it keeps Shopify app configuration cleanly separate from the PHP runtime.

## Exact files created
- `shopify-app/shopify.app.toml` — app configuration (non-secret).
- `shopify-app/.gitignore` — ignores `.shopify/` (CLI local/linked state) and any `.env`/`*.local.toml`/`*.secret`.
- `shopify-app/README.md` — purpose, safe-link instructions, validate/deploy, operator actions, no-secrets rule.

## Exact non-secret configuration (`shopify.app.toml`)
```toml
client_id = "64a260185ad3845818801c83d4e055f7"   # PUBLIC API key of app 424307752961 (non-secret)
name = "SCA Eyewear Registry"
application_url = "https://verify.secondchanceauthenticators.com"
embedded = false

[access_scopes]
scopes = "read_orders"
use_legacy_install_flow = true

[auth]
redirect_urls = [ "https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback" ]

[webhooks]
api_version = "2026-07"
  [[webhooks.subscriptions]]
  topics = [ "orders/paid", "orders/cancelled", "refunds/create" ]
  uri = "https://verify.secondchanceauthenticators.com/sca/shopify/webhook"
```
Validated locally with `python3 tomllib` (valid TOML; parsed scopes/api_version/topics/uri/redirect/embedded as
above). Full schema validation needs Shopify CLI (not installed on the server).

## How it links safely to the EXISTING Dev Dashboard app 424307752961 (no new app)
The committed **`client_id`** binds this config to the existing app, so Shopify CLI acts on app `424307752961` and
will not create a new one. On an operator machine: after `shopify auth login`, either `shopify app config use
shopify.app.toml` (deterministic, uses the committed client_id) or `shopify app config link` and **select the
existing "SCA Eyewear Registry"** — **never "Create a new app."** (Client ID is the app's public API key — it is
not a secret and is conventionally committed in `shopify.app.toml`.)

## Exact command that will eventually deploy it (OPERATOR, not run here)
```
shopify auth login
shopify app config link      # select existing SCA Eyewear Registry (424307752961); never create new
shopify app deploy           # registers scopes + redirect + the 3 webhook subscriptions
```
`shopify app deploy` is the step that creates the webhook subscriptions on the app. It must be run from an
operator machine, never from this server.

## Proof no secrets were committed
- Secret scan of `shopify-app/` for `client_secret|secret|token|password|shpat_|shpss_|shpca_|api_secret|
  access_token|SHOPIFY_CLIENT_SECRET|SHOPIFY_WEBHOOK_SECRET` (excluding the README/comment lines that merely
  explain the no-secrets rule) → **nothing found**.
- The only credential-adjacent value present is the **non-secret** `client_id`. The Client Secret, webhook signing
  secret, and OAuth token were **not read for this file** and do not appear; they remain only in the server
  `app/.env` (token encrypted at rest).
- `.gitignore` excludes `.shopify/` CLI state and any `.env`/local/secret files from ever being committed.

## Authentication / operator action required before deployment
1. Install Shopify CLI + `shopify auth login` to the correct SCA Shopify organization (interactive — cannot be
   done on this server; Shopify CLI is not installed here).
2. Link to the **existing** app `424307752961` (use the committed `client_id` / select the existing app; never
   create a new app).
3. `shopify app deploy`, then close Phase 3 / Gate C by read-only verifying exactly the three subscriptions
   (correct `uri`, `api_version 2026-07`, no duplicates) via the Dev Dashboard or `GET /admin/api/2026-07/
   webhooks.json` — no test delivery.

## Boundaries honored
No `shopify app deploy`/link/login/release, no Shopify-side mutation, no new Dev Dashboard app, no interactive app
creation, no change to OAuth credentials/scopes, no SCA schema/receiver-code/Caddy/.env change. Integration remains
**connected** (encrypted offline token, scope `read_orders`); webhook subscriptions pending the operator deploy;
receipts/sale_links `0/0`. STOP for ChatGPT/operator review. See [[sca-shopify-activation-preflight]].

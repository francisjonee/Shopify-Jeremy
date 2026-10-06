# SCA Eyewear Registry — Shopify CLI configuration project

Source-controlled **configuration only** for the **existing** Shopify Dev Dashboard app, kept under SCA
governance and intentionally **separate from the Laravel runtime** (the webhook receiver lives in
`francisjonee-sca-platform-private` → `packages/Sca/Shopify`; this project only manages the Shopify-side app
config/subscriptions).

- App: **SCA Eyewear Registry** (Dev Dashboard app ID **424307752961**)
- Store: `second-chance-eyewear-accessories.myshopify.com`
- Scope: **`read_orders`** only · API version: **`2026-07`**
- OAuth callback: `https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback`
- Webhook receiver: `https://verify.secondchanceauthenticators.com/sca/shopify/webhook`
- Topics: `orders/paid`, `orders/cancelled`, `refunds/create`

## Files
- `shopify.app.toml` — the app configuration (scopes, OAuth redirect, webhook subscriptions). `client_id` is the
  app's **public** API key (non-secret).
- `.gitignore` — ignores Shopify CLI local state (`.shopify/`) and any env/secret/local-override files.

## What must NEVER be committed here
Client Secret, webhook signing secret, OAuth access/refresh tokens, OAuth codes, session data, `.env`, or any
other credential. Those live only in the server's `app/.env` (token encrypted at rest). Only the non-secret
`client_id` is present.

## How this is safely linked to the EXISTING app (no new app)
This config targets the existing app by its **`client_id`** (`64a260185ad3845818801c83d4e055f7`), so Shopify CLI
operates on app **424307752961** — it will not create a new app. To attach the CLI on an operator machine:
- Preferred (deterministic): the committed `client_id` already binds this config to the existing app; run
  `shopify app config use shopify.app.toml` after `shopify auth login`.
- Or `shopify app config link` and **select the existing "SCA Eyewear Registry" app** — **never choose
  "Create a new app."**

## Validate (local)
TOML syntax is validated in CI/by hand with `python3 -c "import tomllib;tomllib.load(open('shopify.app.toml','rb'))"`.
Full schema validation requires Shopify CLI on an operator machine (not installed on the server).

## Deploy (OPERATOR-ONLY — not run here)
From an operator machine with Shopify CLI, authenticated to the SCA Shopify org:
```
shopify auth login
shopify app config link        # select existing "SCA Eyewear Registry" (424307752961); never create new
shopify app deploy             # pushes this config (scopes + redirect + the 3 webhook subscriptions)
```
`shopify app deploy` is the command that registers the webhook subscriptions. **Do not run it from this server.**
After deploy, verify read-only (Dev Dashboard webhooks list or `GET /admin/api/2026-07/webhooks.json`): exactly
the three topics, each `uri = …/sca/shopify/webhook`, `api_version 2026-07`, no duplicates. Do not trigger a test
delivery.

## Operator action required before deployment
1. Shopify CLI installed + `shopify auth login` to the correct SCA Shopify organization (interactive; not possible
   on this server).
2. Confirm the CLI selects/links app **424307752961** (existing), not a new app.
3. Run `shopify app deploy`, then close Phase 3 / Gate C with the read-only subscription verification above.

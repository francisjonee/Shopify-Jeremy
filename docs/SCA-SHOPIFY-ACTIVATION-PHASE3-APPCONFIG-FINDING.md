# SCA Shopify Activation — Phase 3 app-config (shopify.app.toml) investigation — ABSENT

**Date:** 2026-10-06 · **Deployed app:** `98ae654`, migrations **120** (unchanged).
**Status: Read-only investigation. The Shopify CLI app project (`shopify.app.toml`) for app ID `424307752961` is
NOT present on this repository/server. No file created, no change made, no deploy. STOP for operator.** No secrets.

## Question
Close the Shopify-side of Phase 3 by adding the `[webhooks]` block (topics + uri + api_version) to the existing
app's `shopify.app.toml`, since the Dev Dashboard "Create Version" UI exposes only the Webhooks API version (no
topic/URI fields).

## What was found (read-only, whole-server)
- `find /` for `shopify.app.toml` / `shopify.app.*.toml` → **none**.
- App ID `424307752961` appears **only** inside this session's chat transcript
  (`/root/.claude/projects/-opt-SCA/…jsonl`, 4×) — **not** in any config file.
- No Shopify CLI project markers anywhere: no `.shopify/` dir, no `shopify.web.toml`, no
  `shopify.extension.toml`, and no Node project depending on `@shopify/app` / `@shopify/cli`.
- **Shopify CLI is not installed** on this server (`command -v shopify` → none).
- The Laravel `Sca/Shopify` package contains **no `.toml`** — it is the PHP **receiver** only
  (`Config/Http/Models/Providers/Resources/Routes/Services/Support`, all PHP). It is not the Shopify app's
  source/config project.

## Conclusion
**This repository/server does NOT contain the Shopify CLI project linked to app ID `424307752961`.** There is no
`shopify.app.toml` here to edit, therefore **no config diff to present** and nothing to deploy from this machine.
Per instruction, **no replacement project was created and nothing was guessed.**

## Where the webhook declaration must actually happen (operator)
The `[webhooks]` subscription declaration lives in the Shopify app's own CLI project, which is **elsewhere** (the
operator's local Shopify CLI environment linked to app `424307752961`, where `shopify app dev/deploy` is run). The
intended config to apply there (unchanged from Phase 3):
```toml
[webhooks]
api_version = "2026-07"
  [[webhooks.subscriptions]]
  topics = ["orders/paid", "orders/cancelled", "refunds/create"]
  uri = "https://verify.secondchanceauthenticators.com/sca/shopify/webhook"
```
Preserve `read_orders` as the only requested scope and keep the existing OAuth redirect URI and all other app
config. Register via the **app config** (app-managed → HMAC signed with the app Client Secret = `SHOPIFY_WEBHOOK_
SECRET`), not via Settings → Notifications.

Options for the operator (no SCA code/schema/edge change, no new app):
1. **Locate the existing CLI project** linked to `424307752961` on the machine where it was created, add the
   `[webhooks]` block, and `shopify app deploy` a new version there. (If that project should live here, the
   operator must bring/link it — Claude will not scaffold a new one.)
2. Or declare the subscriptions via an authorized **Admin API `webhookSubscriptionCreate`** against the store using
   the operator's own tooling (not from SCA; SCA has no such code and none will be added).

## Boundaries honored
No new Shopify app, no OAuth credential/scope change, no SCA schema/receiver-code/Caddy change, no file created, no
deploy/release. Integration remains **connected** (encrypted offline token, scope `read_orders`); webhook
subscriptions still pending operator-side; receipts/sale_links `0/0`; provenance `c3fea71a` / migrations `120`
unchanged. STOP for ChatGPT/operator review. See [[sca-shopify-activation-preflight]].

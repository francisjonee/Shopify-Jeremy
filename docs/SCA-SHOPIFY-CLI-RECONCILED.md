# SCA Shopify CLI — reconciled with live app 424307752961 (NOT deployed) — awaiting ChatGPT audit

**Date:** 2026-10-06 · **Status: `shopify.app.toml` reconciled against the LIVE SCA Eyewear Registry app via
`shopify app config link` (operator-authorized device login). NOT deployed, NOT released. STOP for ChatGPT audit
before `shopify app deploy`.** No secrets committed; no Shopify-side mutation.

## What ran (on the VPS)
Installed host tooling: Node v22.22.1 + Shopify CLI 4.8.5 (apt + `npm -g`); Docker/Caddy/MariaDB/SCA/co-tenants
untouched (all containers verified up). Ran `shopify app config link --client-id=64a260185ad3845818801c83d4e055f7`
(binds to the EXISTING app — no app-selection prompt, no new app). Operator completed the **device-code** login
(`activate-with-code`, code consumed). CLI pulled the live app config into `shopify-app/shopify.app.toml` and set
it as the default config. `.shopify/` local state created but **git-ignored** (untracked). Exit 0.

## Reconciliation result (semantic comparison: committed `fdbb1cd` vs post-link)
All substantive fields are **identical** — confirming `fdbb1cd` already matched the live v2 app:
| field | value | result |
|---|---|---|
| client_id | `64a260185ad3845818801c83d4e055f7` | SAME |
| name | `SCA Eyewear Registry` | SAME |
| application_url | `https://shopify.dev/apps/default-app-home` | SAME (live v2) |
| embedded | `false` | SAME |
| access_scopes.scopes | `read_orders` | SAME |
| use_legacy_install_flow | `false` | SAME (live v2) |
| **access_scopes.optional_scopes** | absent → **`[]`** | only delta — live-canonical "no optional scopes" (benign) |
| auth.redirect_urls | `…/sca/shopify/oauth/callback` | SAME |
| webhooks.api_version | `2026-07` | SAME |
| webhooks topics | `orders/paid, orders/cancelled, refunds/create` | SAME (CLI reorders alphabetically) |
| webhooks uri | `https://verify.secondchanceauthenticators.com/sca/shopify/webhook` | SAME |

Non-field diff is cosmetic only: CLI replaced the comment header and reordered `[webhooks]` above `[access_scopes]`.

## Confirmations
- **Scope remains exactly `read_orders`** (no `read_products`; `optional_scopes = []`).
- **OAuth redirect unchanged** — the existing SCA callback.
- **App URL / embedded / install-flow unchanged** — the app's own config was preserved; only the webhook
  subscriptions are the intended Shopify-side addition.
- **No secrets committed** — secret scan of the toml clean; only the non-secret `client_id` is present. The Client
  Secret, webhook signing secret, and access token remain solely in server `app/.env` (token encrypted).
- **`.shopify/` not committed** — present locally, git-ignored.

## The only Shopify-side change a deploy would make
Register the three webhook subscriptions (`orders/paid`, `orders/cancelled`, `refunds/create`) at API `2026-07`
to `…/sca/shopify/webhook`. No scope/redirect/app-URL/install-flow change.

## Awaiting approval — exact deploy command (NOT run)
```
cd /opt/sca-gov/shopify-app && shopify app deploy    # OPERATOR, only after ChatGPT explicitly approves
```
`shopify app deploy` is the only step that writes to Shopify; it is **not** run. After approval + deploy,
read-only verify the three subscriptions (Dev Dashboard / `GET /admin/api/2026-07/webhooks.json`, no test trigger)
to close Phase 3 / Gate C.

STOP for ChatGPT audit. See [[sca-shopify-activation-preflight]], `docs/SCA-SHOPIFY-CLI-CONFIG-AUDIT.md`.

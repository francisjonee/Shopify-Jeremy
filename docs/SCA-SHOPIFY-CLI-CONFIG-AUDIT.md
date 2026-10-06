# SCA Shopify CLI config — audit vs active v2 + correction

**Date:** 2026-10-06 · **Status: read-only audit + source-TOML correction committed. No Shopify login/link/
deploy/release/mutation.** Audited `shopify-app/shopify.app.toml` against the active Dev Dashboard version
`sca-shopify-activation-v2`. Principle applied: **preserve the working v2 config exactly; add only the three
webhook subscriptions.**

## Field-by-field comparison
| Setting | committed (before) | active v2 | result |
|---|---|---|---|
| app name | `SCA Eyewear Registry` | same | keep (match) |
| client_id / identity | `64a260185ad3845818801c83d4e055f7` | app 424307752961's public API key (OAuth succeeded with it, Gate B) | keep (match) |
| application_url | `https://verify.secondchanceauthenticators.com` | `https://shopify.dev/apps/default-app-home` | **CORRECTED → v2 value** |
| embedded | `false` | not reported as differing | keep `false` — **confirm vs v2** |
| access_scopes.scopes | `read_orders` | `read_orders` (Gate B granted exactly `read_orders`) | keep (match) |
| use_legacy_install_flow | `true` | `false` | **CORRECTED → `false`** |
| auth.redirect_urls | `…/sca/shopify/oauth/callback` | already whitelisted (Gate B callback succeeded) | keep (match) |
| webhooks.api_version | `2026-07` | target | keep |

## Decision: `use_legacy_install_flow`
Set to **`false`** (match active v2). Although SCA runs its own OAuth authorization-code flow (which *resembles*
the "legacy" install), the active v2 value is `false` and OAuth **empirically worked under `false`** (Gate B:
authorize → callback → token stored → connected). Per the preserve-exactly principle, it must stay `false`; the
earlier `true` was an incorrect inference and would change a currently-working install behavior. (Omitting it would
also resolve to the modern default `false`, but it is set explicitly to mirror the displayed v2 value.)

## Decision: `application_url`
Set to **`https://shopify.dev/apps/default-app-home`** (the active v2 value — Shopify's untouched default app
home). The app URL is **not** changed to register webhooks; the earlier `verify.` value would have altered the
existing app URL unnecessarily.

## IMPORTANT caveat — `shopify app deploy` overwrites ALL config
A deploy pushes the **entire** TOML as the app config, so every field must equal the active v2 value or it will
change the app. This corrected TOML is the best-known end state, but two fields cannot be confirmed from the
server:
- **`embedded`** (kept `false`) — if v2 actually shows `embedded = true`, deploying this TOML would flip it.
- **`auth.redirect_urls`** — if v2 has additional redirect URLs beyond our callback, a deploy would remove them.

**Recommended safe method (operator):** on the operator machine, after `shopify auth login`, run
`shopify app config link` and **select the existing app** — this **pulls the live v2 config into the TOML**,
reconciling every field exactly. Then add **only** the `[webhooks]` block (the three subscriptions, api_version
`2026-07`, uri `…/sca/shopify/webhook`) to that pulled config, re-verify nothing else changed (git diff), and only
then `shopify app deploy`. This guarantees "preserve v2 exactly + add webhooks only" regardless of any field this
server cannot see. Do **not** deploy a hand-authored TOML blind.

## No secrets
Re-scanned the corrected TOML: no Client Secret / webhook secret / token / `shp*` prefixes — only the non-secret
`client_id`. Valid TOML (`python3 tomllib`).

## STOP
No Shopify CLI auth/link/deploy/release, no Shopify-side mutation, no new app. Correction committed to source
control. See [[sca-shopify-activation-preflight]], `docs/SCA-SHOPIFY-CLI-CONFIG-PROJECT.md`.

---
## Reconciliation readiness (2026-10-06) — CLI NOT installed on the prod host; operator-interactive from here
**Host check:** this server (the shared production edge, Ubuntu 26.04, 5.8 GB RAM / no swap) has **no Node/npm/
Shopify CLI**. Installing `@shopify/cli` here would add a Node toolchain to the production edge host, and the
decisive steps (`shopify auth login`, `shopify app config link`, app selection) are **interactive and operator-
run** regardless. Decision: **did not install a Node toolchain on the prod edge**; the gov repo can be reconciled
from any machine and pushed. (If you specifically want the CLI on this host instead, say so and I'll install
Node 18+ and `@shopify/cli` on your go — but auth/link stay interactive/operator.)

**Current committed config @ `fdbb1cd` (pre-reconciliation) verified:** scope == `read_orders`; redirect ==
`https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback`; webhooks api_version `2026-07` + the
three subscriptions → `…/sca/shopify/webhook`; `application_url` + `use_legacy_install_flow=false` match active v2;
no secret values; `.shopify/` not tracked.

**Operator reconciliation commands (recommended: on your own machine; HARD STOP before deploy):**
```
# 1. get the gov repo
git clone git@github.com:francisjonee/Shopify-Jeremy.git && cd Shopify-Jeremy/shopify-app
#    (install CLI if needed: Node 18+ then `npm i -g @shopify/cli@latest`, or `brew install shopify-cli`)

# 2. AUTH + LINK TO THE EXISTING APP ONLY (interactive) — select "SCA Eyewear Registry" (424307752961).
#    NEVER choose "Create a new app".
shopify app config link

# 3. `link` PULLS the live app config into shopify.app.toml. Ensure the ONLY difference vs the pulled config is
#    the [webhooks] block below (add it if the pull didn't include it; reconcile to EXACTLY these three):
#       [webhooks]
#       api_version = "2026-07"
#         [[webhooks.subscriptions]]
#         topics = ["orders/paid", "orders/cancelled", "refunds/create"]
#         uri = "https://verify.secondchanceauthenticators.com/sca/shopify/webhook"

# 4. PROVE only webhooks changed, confirm scope + redirect preserved, no secrets / no .shopify staged:
git --no-pager diff
git status --porcelain            # .shopify/ must stay untracked (it's git-ignored)

# 5. commit + push the reconciled toml (NO deploy yet)
git add shopify-app/shopify.app.toml && git commit -m "reconcile shopify.app.toml with live app 424307752961 + add 3 webhook subscriptions" && git push

# HARD STOP — do NOT run `shopify app deploy` until ChatGPT audits the reconciled config and explicitly approves.
```
After you push the reconciled toml, I will show the **sanitized git diff vs `fdbb1cd`** proving only the
`[webhooks]` subscriptions were added (scope still `read_orders`, redirect unchanged, no secrets / no `.shopify/`
committed), for ChatGPT's deployment audit. **No `shopify app deploy` / release will be run until explicit
approval.**

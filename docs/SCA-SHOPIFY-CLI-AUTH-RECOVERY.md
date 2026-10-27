# SCA — Shopify CLI Authentication & Config Recovery: Status + Owner Instructions

**Interactive Shopify CLI authentication cannot be completed from this automated/headless session; it must be run by the owner in an interactive terminal. The current `shopify.app.toml` was backed up. `config link`/`config pull` and the scope/webhook confirmation are PENDING that authentication. No deploy, no product-webhook add, no new app, no scope change, no credential exposed, no SCA production change. 2026-10-27. STOP.**

## [1] Project

Using the existing project **`/opt/sca-gov/shopify-app`** (tracked in gov; app `name = "SCA Eyewear Registry"`, `client_id` matches the SCA install — verified earlier).

## [5] Backup taken

`/opt/sca-gov/shopify-app/shopify.app.toml.bak.20261027T190333Z` (mode-preserving copy) — before any `config pull`/edit.

## [2][3] Interactive authentication — cannot run here; owner must do it

- The correct command is **`shopify auth login`** (CLI 4.8.5). It is **interactive-only**: run non-interactively it errors — *"This usually happens when running a command non-interactively… run the command in an interactive environment such as your local terminal."* (`--alias` only reuses an **already-existing** session; it cannot create one non-interactively.)
- Shopify CLI login also uses a **localhost loopback callback** (the browser redirects to `http://localhost:<port>` on the machine running the CLI), so the browser and the CLI must be able to reach the same loopback. On this headless VPS with a remote owner, that cannot complete unless the callback port is tunnelled.
- Per the authorization ("do not bypass interactive authentication"), I did **not** attempt any token/non-interactive workaround.

### Owner workflow — choose ONE (both use the existing app; do NOT create a new app)

**Option A (simplest — run on the owner's own workstation):**
```bash
# Get the project (the committed toml) locally, e.g. clone the gov repo's shopify-app/ folder.
cd <local>/shopify-app
shopify auth login                               # opens your browser; sign in to the Partner org that owns the app
shopify app config link --client-id <SCA_EYEWEAR_REGISTRY_CLIENT_ID>   # link to the EXISTING app; verify name shows "SCA Eyewear Registry"
shopify app config pull                          # refresh the toml to the CURRENT released config
```

**Option B (keep everything on the server — interactive SSH + tunnel the callback):**
```bash
# From your laptop, SSH in forwarding the CLI callback port so your local browser can reach it:
ssh -L 3456:localhost:3456  <server>             # (Shopify CLI's loopback port; adjust if the CLI prints a different one)
cd /opt/sca-gov/shopify-app
shopify auth login                               # it prints a URL — open it in YOUR browser; the redirect to localhost:3456 reaches the tunnel
shopify app config link --client-id <SCA_EYEWEAR_REGISTRY_CLIENT_ID>
shopify app config pull
```
(The `client_id` to link with is the one already in this project's `shopify.app.toml` / `app/.env SHOPIFY_CLIENT_ID` — both verified to match.)

## [4] After auth — verify the linked app identity

`shopify app config link` must resolve to **"SCA Eyewear Registry"** with the **existing client_id** (the one in the committed toml / SCA install). If it offers to create a new app or shows a different client_id, **abort** — do not proceed with another app.

## [6][7] `config pull` + confirmation — PENDING (owner runs it)

After `shopify app config pull`, confirm the refreshed `shopify.app.toml` retains all of:
- `[access_scopes] scopes = "read_orders,read_products"` — **both** scopes. ⚠️ The **currently-committed** toml is stale and shows only `read_orders`; the pull should bring `read_products` back (it is in the live install). **If the pulled config still lacks `read_products`, STOP and report** — the released app config and the granted token would be inconsistent.
- `[webhooks] api_version = "2026-07"`.
- The three existing webhook subscriptions `orders/paid`, `orders/cancelled`, `refunds/create` → `…/sca/shopify/webhook` (none removed).
- `[auth] redirect_urls = [ "https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback" ]`.

## [8] Expected configuration diff (committed → pulled) — to be produced by the owner's `config pull`

I cannot pull without a session, so the actual diff is PENDING. **Expected:** the committed (stale) toml shows `scopes = "read_orders"` and 3 webhooks; the pulled live config should differ by **adding `read_products` to `access_scopes`** (and otherwise match: same 3 webhooks, same API version, same redirect). After the pull, run `git -C /opt/sca-gov diff shopify-app/shopify.app.toml` to capture the exact diff and commit the refreshed toml so the gov copy matches the live app.

Still NOT done in this or the next step (explicitly out of scope here): adding the product webhooks and `shopify app deploy` — those come only after the pull confirms the baseline is correct.

## Guardrails honored

No `shopify app deploy`, no product-webhook subscription added, no new app, no scope downgrade, no credentials printed, no SCA production service/code/DB change. Only a read-only backup of the toml was made.

**STOP — interactive `shopify auth login` must be completed by the owner (Option A or B). Then `config link` (verify SCA Eyewear Registry) + `config pull`, confirm read_orders,read_products + the 3 order/refund webhooks + API 2026-07 + OAuth callback, capture the diff, and report before any deploy.**

# SCA Shopify Activation — Phase 1 + Gate A — PASS

**Date:** 2026-10-06 · **Deployed app:** `98ae654`, migrations **120** (unchanged).
**Status: Phase 1 (safe server configuration) COMPLETE; Gate A PASS. STOPPED before Phase 2 (OAuth) per operator.
No secrets/tokens/PII recorded. No OAuth run. No app code / schema change.** Executes Phase 1 + Gate A of
`NEXT_TASK.md`.

## Phase 1 — configuration applied (non-secret by Claude; secrets by operator)
- **Backups (server-local, git-ignored; NOT in Git):** `app/.env.bak.pre-shopify-phase1` (pre-change, sha
  `7e6903c6…`) + redundant `/root/sca-env-backup.app.env.pre-shopify-phase1`. `app/.env` owner `www-data:www-data`,
  mode `600` preserved throughout.
- **Five non-secret keys set by Claude** (none existed before): `SHOPIFY_SHOP_DOMAIN`, `SHOPIFY_SCOPES`,
  `SHOPIFY_API_VERSION`, `SHOPIFY_LINE_ITEM_REF_PROPERTY`, `SHOPIFY_OAUTH_REDIRECT_URI`.
- **Three secrets entered by the operator directly on the server** (`SHOPIFY_CLIENT_ID`, `SHOPIFY_CLIENT_SECRET`,
  `SHOPIFY_WEBHOOK_SECRET`) via a silent `read -rs` loop — values never echoed/committed/logged. Claude did not
  generate, view, or handle any secret value.
- Laravel config cleared after each change.

## Gate A — proof (no secret values exposed)
- **Non-secret config resolves exactly:** `expected_shop_domain = second-chance-authenticators.myshopify.com`
  (⇐ `SHOPIFY_SHOP_DOMAIN`, governs both webhook + OAuth expected-shop); `scopes = read_orders`; `api_version =
  2026-07`; `line_item_ref_property = sca_item_ref`; `oauth_redirect_uri = https://verify.secondchanceauthenticators
  .com/sca/shopify/oauth/callback`. (`webhook_path`/`oauth_callback_path` defaults match the live edge.)
- **Secrets SET (SET/UNSET only):** `client_id = SET`, `client_secret = SET`, `webhook_secret = SET`.
- **Diagnostics = configured but not connected:** `ConnectivityVerifier::verify()` → `configured=true`,
  `connected=false`, `error_category='not_connected'`, `verified_shop_domain=null`. (verify() short-circuits at
  `connected=false`, so it makes **no** outbound Shopify call — no reachability probe, no OAuth.)
- **Connection/token table unconnected:** `sca_shopify_credentials = 0` rows. `webhook_receipts/sale_links = 0/0`.
- **Zero provenance/domain change:** `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4` (== baseline), migrations
  **120**, items/owners/certs unchanged.
- **Webhook HMAC not weakened:** with `webhook_secret` now SET, an **unsigned** `POST /sca/shopify/webhook` still
  returns **401** (fail-closed — a valid secret does not admit unsigned traffic).
- **Edge unchanged / no broad exposure:** callback GET → 400 (reaches app, fails safe); wrong-method webhook →
  404; `/sca/anything-else` → 404; `/admin/sca/shopify` → 403 (staff-IP); `/storage/x` → 404.
- **SCA invariants healthy:** `/p/<valid>` 200, `/p/<bogus>` 404, `/p/<malformed>` 404 (SCA-038 constant shape);
  `/collector/login` 200; `http→https` 308; Secure cookie present (Phase-B); public `:8080` 000 (retired,
  loopback-only); **smsrocket.io 302** (co-tenant healthy).

## Co-tenant edge note (not ours)
Since the edge-activation change, an operator added an unrelated `mail3.relaytask.online` site block to
`/opt/smsrocket-stack/Caddyfile` (reverse_proxy to the sca_edge gateway `172.20.0.1:5000`), appended **after** the
`verify.` block. The SCA Shopify path+method-exact handles inside the `verify.` block are untouched and verified
working (probes above). No SCA action taken on that block.

## Rollback (ready, not needed)
Gate A passed, so no rollback was performed. If it had failed: restore `app/.env` from
`app/.env.bak.pre-shopify-phase1` (or the `/root` copy), `php artisan config:clear`, re-verify baseline.

## State / next
Integration is now **configured but not connected** (no OAuth, no token, no webhooks registered, no data). **STOP
per operator — did not proceed to Phase 2 (OAuth).** Next on operator go: Phase 2 OAuth connect via the staff-IP
`/admin/sca/shopify/connect` route (single-use state + callback HMAC + expected-shop), then Gate B.

Governance recorded; ACTIVE task remains Shopify activation. No secrets/tokens/PII in this document. See
[[sca-shopify-activation-preflight]], [[sca-shopify-edge-activation]].

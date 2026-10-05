# SCA Shopify Edge Activation — DONE (governed infra change)

**Date:** 2026-10-05 · **Deployed app:** `98ae654`, migrations **120** (unchanged by this change).
**Status: DONE — edge change applied + verified. No Laravel code, no `.env`, no Shopify app/credentials/webhook
registration, no OAuth connect, no test item/order, no provenance mutation.** Implements the reviewed edge
exposure from `SCA-SHOPIFY-ACTIVATION-PREFLIGHT-EDGE-DESIGN.md` (gov `302807a`).

## Scope (exactly what changed)
One edit to the shared-host Caddyfile (`/opt/smsrocket-stack/Caddyfile`), inside the
`verify.secondchanceauthenticators.com` site block only — **two path- AND method-exact handles added before the
default-deny catch-all**, reverse-proxied to `kr-app:80` over `sca_edge`:
- `@shopify_webhook { path /sca/shopify/webhook; method POST }` → kr-app (**permanent**)
- `@shopify_oauth_callback { path /sca/shopify/oauth/callback; method GET }` → kr-app (**temporary — remove after
  the one-time OAuth install**)

No existing matcher was broadened; `@public` (`/p/* /collector /collector/*`) and `@admin` (staff-IP) are
unchanged; the `smsrocket.io` block is untouched. **No `/sca/*` wildcard** — only the two literal paths.

- **Caddyfile checksum:** before `0faece7a53afaca69cbba9b2b757cf830b7bf29bfbd20497ab0e35f9eeaca5bf` → after
  `390353971b304877f9ce6dc0ffb154cd8da916cb6cf9e787cb122121376c7b4f`.
- **Rollback material:** `/opt/smsrocket-stack/Caddyfile.bak.pre-shopify-edge` (= the `0faece7a` pre-change file).
  (smsrocket-stack is not a git repo; this doc + the on-disk backup are the version record.)

## Procedure (governed)
1. Baseline recorded (below). Production matched the reviewed baseline (`98ae654`, FP `c3fea71a`, migrations 120).
2. Backed up the Caddyfile (`Caddyfile.bak.pre-shopify-edge`, checksum verified `0faece7a`).
3. Edited the Caddyfile (two handles inserted before the catch-all).
4. **Validated before applying:** `caddy validate --adapter caddyfile` in a throwaway `caddy:2` container against
   the exact file → **"Valid configuration"** (exit 0). The running edge was not touched until validation passed.
5. Applied via `docker compose up -d --force-recreate caddy` (the host's documented method — a bind-mount inode
   gotcha makes `caddy reload` a no-op). Brief, operator-approved co-tenant blip; kr-app and sr-app not recreated.

## Externally-observed responses (public Internet, after change)
**Newly exposed — reach Laravel and FAIL CLOSED (not edge 404; HMAC not weakened):**
- `POST /sca/shopify/webhook` (no/invalid HMAC) → **401** (reaches `WebhookController`, HMAC fail-closed; secret
  still unset).
- `GET /sca/shopify/oauth/callback` (no valid OAuth txn) → **400** (reaches `OAuthController`, fails safely).

**Wrong methods stay denied (edge 404):** `GET /sca/shopify/webhook` → **404**; `POST /sca/shopify/oauth/callback`
→ **404**.

**No broader exposure (edge 404):** `/sca/anything-else` → 404; `POST /sca/shopify/anything` → 404;
`/sca/shopify/webhook/extra` → 404; `/sca/shopify/install` → **404** (install stays under `/admin` staff-IP).

**Unchanged invariants:** `/admin/sca/shopify` (diagnostics) → **403**; `/admin/sca/shopify/connect` (install) →
**403** (both staff-IP only); `/storage/x` → 404; `/p/<valid>` → 200, `/p/<bogus>` → 404, `/p/<malformed>` → 404
(SCA-038 constant shape intact); `/collector/login` → 200; `http→https` → 308; Secure cookie present; public
`195.26.255.80:8080` → 000 (retired, kr-app loopback-only); `smsrocket.io` → **302** (co-tenant healthy).

## Zero-impact proof (before == after)
- Provenance fingerprint `AFTER_FP = c3fea71ad6ecf93345b2eefc5f5cbef4` — **unchanged**; migrations **120** —
  unchanged. Shopify tables still **0/0/0** (the 401/400 wrote nothing — fail-closed before any DB write).
- Shopify config still absent (`webhook_secret`/`shop_domain` unset) — the 401 is a genuine fail-closed, not a
  weakened check. App repo untouched (HEAD `98ae654`, no Laravel change).

## Rollback (ready, not needed)
If any validation/routing/co-tenant/security invariant had failed: `cp Caddyfile.bak.pre-shopify-edge Caddyfile`
then `docker compose up -d --force-recreate caddy`. All invariants passed, so no rollback was performed. The
backup remains on disk.

## State after this change
The two Shopify endpoints are now reachable from the Internet and fail closed (no credentials configured). The
integration remains **dormant** — no app, secrets, webhooks, OAuth connection, or data. Next steps (separate,
operator-gated, NOT done here): create the custom Shopify app, set `app/.env` secrets, OAuth install via
`/admin/sca/shopify/connect` (staff), register the three webhook topics, dev-store dry-run (incl. GATE-R2
partial-refund check), then a controlled first sale — per the pre-flight audit. After the OAuth install completes,
**remove the temporary `@shopify_oauth_callback` handle** (token refresh does not use it), leaving only the
permanent webhook path exposed.

Governance recorded; ACTIVE/NEXT unpromoted. **STOP — do not proceed to Shopify app creation or credentials.** See
[[sca-shopify-activation-preflight]], [[sca-shopify-integration-readiness-audit]], [[sca-production-cutover-phase1]],
[[sca-host-is-shared-with-production]], [[report-to-github-first]].

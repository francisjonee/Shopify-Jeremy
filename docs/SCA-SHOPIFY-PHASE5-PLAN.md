# Phase 5 — Shopify post-activation hardening / production closeout (PLAN ONLY)

**Date:** 2026-10-06 · **Status: PLAN ONLY. No production/Shopify mutation, no cleanup, no code/config/schema/scope change performed. For ChatGPT audit before any execution.** · Deployed app `98ae654` (unchanged), migrations **120**, `FINAL_FP = 62b2e42fe409b4ec91f3381b35da819e`.

Phase 4 (controlled dev-store dry-run) is formally complete and audited PASS (gov `de50ec03`). This plan defines the narrow, reversible closeout that moves the already-connected, already-tested Shopify integration to a steady production posture. It changes **no application code, schema, scope, or SCA config** — it is an **edge-exposure decision + Shopify-side test-fixture disposition + a documented acceptance checklist**.

---

## 1. Current architecture (verified read-only)

**Routes (deployed, `packages/Sca/Shopify/src/Routes/*`):**
| Route | Method | Auth | Exposure | Lifetime |
|---|---|---|---|---|
| `admin/sca/shopify` (diagnostics) | GET | admin + `sca.shopify.view` ACL | staff-IP `/admin` only | permanent (staff) |
| `admin/sca/shopify/connect` (OAuth **install** initiator) | GET | admin + `sca.shopify.view` ACL | staff-IP `/admin` only | permanent (staff) |
| `sca/shopify/oauth/callback` (OAuth **callback**) | GET | none (verifies `state`+query-HMAC+shop) | **public via temporary edge handle** | **TEMPORARY** |
| `sca/shopify/webhook` (webhook **receiver**) | POST | none (HMAC over raw body) | **public via permanent edge handle** | **PERMANENT** |

**Edge (`/opt/smsrocket-stack/Caddyfile`, `verify.secondchanceauthenticators.com`):** default-deny; `@public` (`/p/*`, `/collector`, `/collector/*`) → kr-app; `@admin` (`/admin`, `/admin/*`) → staff IPs `103.225.137.242`, `103.200.35.2` else 403; `@shopify_webhook {path /sca/shopify/webhook; method POST}` → kr-app (permanent); `@shopify_oauth_callback {path /sca/shopify/oauth/callback; method GET}` → kr-app (**marked temporary**); catch-all `respond "Not found" 404`. No `/sca/*` wildcard. sr-caddy (compose service `caddy`) owns 80/443 and is shared with live **smsrocket.io**. Backups on disk: `Caddyfile.bak.pre-shopify-edge`, `Caddyfile.bak-2026-10-05`.

**Token lifecycle (decisive for the callback decision):**
- Stored credential: shop `second-chance-eyewear-accessories.myshopify.com`, granted scope `read_orders`, access token **encrypted at rest**, **`expires_at = NULL` ⇒ offline, non-expiring**.
- `AccessTokenStore::valid()` refreshes **only** when `expires_at !== null` and within 300s of expiry. With a null expiry it returns the token unchanged — **no refresh is ever attempted in normal operation**.
- `OAuthService::refresh()` (the refresh path, unused here) is a **server→server** call to Shopify's token endpoint; it does **not** use the browser callback.
- **Webhook config:** `shopify.app.toml` declares api `2026-07` + 3 subscriptions (`orders/paid`, `orders/cancelled`, `refunds/create`) → `…/sca/shopify/webhook`; released `sca-eyewear-registry-4` (Gate C). `auth.redirect_urls` contains the callback URL.

---

## 2. Is removing the OAuth callback after install safe? — DETERMINATION

**The public callback is NOT needed for steady-state operation or for token refresh.** It is needed **only** for an interactive authorization-code round-trip, i.e. these (rare, planned, operator-initiated) events:
1. **Reinstall** after the app is uninstalled from the store.
2. **Scope change** (any change beyond `read_orders` requires fresh merchant consent).
3. **Re-authorization / token recovery** if the offline token is revoked/invalidated and a new browser grant is required.
4. **Moving to a different store**.

Routine webhook receipt, order mapping, claims, refunds, and even (hypothetical) token refresh all work with the callback **absent**.

**Conclusion:** removal is **reversible and safe for steady state**, but it is **not free** — any future event in the list above requires the callback to be publicly reachable again, which means re-adding the edge handle via a governed `docker compose up -d --force-recreate caddy` that **briefly drops the live smsrocket co-tenant**. Therefore:

- The **app-side `auth.redirect_urls` allowlist in `shopify.app.toml` must be RETAINED** regardless of the edge decision (removing it would need a redeploy and would break any future reauth). The only thing in question is the **Caddy edge exposure**, not the route or the app redirect allowlist.
- Two defensible postures:

**Option A — RETAIN the hardened callback edge handle (RECOMMENDED default).**
Rationale: the endpoint is already **path- and method-exact** (`GET` only), verifies `state` (single-use) + query-HMAC + expected `*.myshopify.com` shop, and **fails closed (400)**; it has **zero routine use** but is **instantly available** for reauth/token-recovery with no co-tenant blip. Because every Caddy recreate blips production smsrocket, removing-then-restoring costs **≥2 production blips** per future reauth vs **0** if retained, while the marginal attack-surface reduction is small (already fail-closed). **Recommend retain.**

**Option B — REMOVE the callback edge handle (optional, minimal-surface).**
Only after install is confirmed stable, and only with the committed restore runbook below. Removes a (hardened) public GET endpoint; accepts one co-tenant blip now + one blip to restore before any future reauth. **Keep the route in code and the redirect URL in `shopify.app.toml`** — remove only the Caddy `@shopify_oauth_callback` block.

> Recommendation: **Option A (retain).** Treat Option B as an operator preference; if chosen, follow §4 exactly.

---

## 3. What Phase 5 should (and should not) change

**In scope (narrow):**
1. **Edge callback decision** — execute Option A (retain; no edge change, just formally close the "temporary" marker as "retained, hardened") **or** Option B (remove the one `@shopify_oauth_callback` block).
2. **Shopify-side test-fixture disposition** — archive test order **#3281** and unpublish/delete the dedicated **test product/variant** (operator, Shopify only), preserving all SCA provenance.
3. **Production-ready acceptance sign-off** — run the §6 checklist and record it in gov.

**MUST remain permanently reachable (never change):**
- `POST /sca/shopify/webhook` (permanent receiver, fail-closed HMAC).
- Public `/p/*`, `/collector`, `/collector/*` (passport + collector).
- Staff-IP `/admin/*` (incl. the Shopify install initiator + diagnostics).
- The app-side `auth.redirect_urls` in `shopify.app.toml`.
- sr-caddy ownership of 80/443; smsrocket co-tenant.

**Explicitly OUT of scope (do NOT do under Phase 5):**
- Never remove the permanent POST webhook handle; never broaden to a `/sca/*` wildcard.
- No application code / migration / schema / ACL / CSP / Passport-semantics change.
- No scope change (stays `read_orders`); no new Shopify app/version.
- No deletion of **any** SCA provenance/audit row (test item id4, collector id3, receipts, events). Append-only registry of record.
- Unrelated SCA tracks (SMTP enablement, preview-code removal, QR-print production) are **separate tasks**, not this activation's Phase 5.

---

## 4. Execution steps (ONLY if/when each is separately authorized)

### 4.1 Edge callback — Option A (retain) — DEFAULT
No Caddy change. Update the Caddyfile comment to record the governed decision ("retained: hardened, fail-closed; required for future reauth") at the next planned Caddy edit — **no standalone recreate just for a comment** (avoid a needless co-tenant blip).

### 4.2 Edge callback — Option B (remove) — only if operator chooses
1. Back up current Caddyfile (already have `Caddyfile.bak.pre-shopify-edge`; also snapshot current).
2. Remove **only** the `@shopify_oauth_callback` matcher + its `handle` block. Leave `@shopify_webhook`, `@public`, `@admin`, catch-all untouched.
3. **Validate in a throwaway container before recreate** (bind-mount inode pinning makes `caddy reload` a no-op):
   `docker run --rm -v /opt/smsrocket-stack/Caddyfile:/etc/caddy/Caddyfile:ro caddy:2 caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile`
4. `cd /opt/smsrocket-stack && docker compose up -d --force-recreate caddy` (brief smsrocket blip — quiet hour).
5. Verify (§5 P5-2). **Restore runbook (for any future reauth):** re-add the exact `@shopify_oauth_callback` block (from `Caddyfile.bak.pre-shopify-edge`), validate, recreate; run the OAuth install from staff-IP `/admin/sca/shopify/connect`; after a successful connect, optionally remove again.

### 4.3 Shopify test-fixture disposition (operator, Shopify-only)
1. **Order #3281:** Shopify does not allow deleting a paid/refunded order → **Archive** (and it is already fully refunded). Do not delete. This emits no subscribed webhook; even if `orders/cancelled` fired, the item-4 sale-link is already `revoked_refund` (∉ `ACTIVE_STATES`) ⇒ handler no-op.
2. **Dedicated test product/variant:** unpublish then delete on Shopify. `products/*` is not a subscribed topic ⇒ no SCA webhook. This prevents any future order from carrying `sca_item_ref=SCA-A960A57D3124` on a new line.
3. **Do NOT** touch any SCA row. SCA is the registry of record; the Shopify order/product are external fixtures. After disposition, re-verify `FINAL_FP` unchanged (§5 P5-3).

---

## 5. Verification gates (for the eventual execution)

- **Gate P5-1 (pre-exec baseline):** `FP == 62b2e42f`; integration connected; granted scope `read_orders`; 3 webhooks present; `POST webhook` no-HMAC → 401; migrations 120; smsrocket 302.
- **Gate P5-2 (after Option B only):** `GET /sca/shopify/oauth/callback` → **404**; `POST /sca/shopify/webhook` no-HMAC → still **401** (reachable + fail-closed); `/collector` 302; `/storage/*` 404; `/admin` 403 from non-staff; no `/sca/*` wildcard; `shopify.app.toml` redirect URL **retained**; smsrocket 302. (For Option A: endpoints unchanged — callback still 400 on bad params, webhook 401.)
- **Gate P5-3 (after fixture disposition):** `FP == 62b2e42f` (no SCA mutation); receipts still **3**; sale-link still `revoked_refund`; item4 owner collector 3; pre-existing id1/id3 byte-identical; smsrocket 302.
- **Gate P5-4 (acceptance):** full §6 checklist green; commit evidence to gov.

**Rollback:** Option B → restore Caddyfile block from backup + validate + recreate (callback public again). Fixture disposition is non-reversible on Shopify but has **zero** SCA effect; nothing to roll back in SCA. No DB/code/schema touched anywhere, so no SCA rollback is ever needed.

---

## 6. Final production-ready acceptance criteria

1. Deployed app `98ae654` unchanged; migrations **120**; no code/schema/scope change.
2. Integration **connected**: shop `second-chance-eyewear-accessories.myshopify.com`, granted scope exactly `read_orders`, offline token **encrypted at rest**.
3. Webhook subscriptions = exactly `orders/paid`, `orders/cancelled`, `refunds/create` → `…/sca/shopify/webhook`, api `2026-07`; no extras.
4. **Permanent** `POST /sca/shopify/webhook` publicly reachable and **fail-closed** (401 on bad/absent HMAC).
5. OAuth callback: **Option A** (retained, hardened, `auth.redirect_urls` present) **or** **Option B** (edge handle removed, route+redirect URL retained, restore runbook committed). Either way reauth is possible on demand.
6. Public `/p/*` + `/collector` reachable; `/storage/*` denied (404); `/admin/*` staff-IP only (403 otherwise); **no `/sca/*` wildcard**; install initiator stays staff-only.
7. smsrocket co-tenant healthy (302); sr-caddy owns 80/443.
8. `FINAL_FP = 62b2e42f`; all Phase-4 test artifacts **retained** as audit record; pre-existing provenance byte-identical; no customer PII persisted by the integration.
9. Shopify test fixtures (#3281 archived, test product removed) dispositioned **without** any SCA provenance change — or explicitly deferred.
10. Governance: Phase 4 evidence (`de50ec03`) + this Phase 5 plan + its execution evidence committed to gov; memory/index updated.
11. **Operational go-live note (not a code gate):** first real sale uses a one-of-one (quantity 1) listing carrying line-item property `sca_item_ref=<public_ref>`; buyer claim-link delivery is manual (mailer=log; SMTP is a separate track).

---

## 7. Operator decisions required before any Phase 5 execution
- **D-EDGE:** Option A (retain callback — recommended) vs Option B (remove callback).
- **D-FIXTURES:** dispose Shopify #3281 (archive) + test product (delete) now, or defer.
- **D-WINDOW:** if Option B, pick a quiet hour for the sr-caddy recreate (brief smsrocket blip).

**No execution performed. Awaiting ChatGPT audit + operator decisions.** See [[sca-shopify-activation-preflight]], `docs/SCA-SHOPIFY-ACTIVATION-PHASE4-DRYRUN.md`.

---

## Phase 5 — EXECUTION (operator decisions applied)

**Date:** 2026-10-06 · **Operator decisions:** D-EDGE = **Option A (RETAIN callback; no Caddy change)**; D-FIXTURES = **dispose now (operator-only Shopify actions)**; D-WINDOW = N/A.

### D-EDGE = Option A — RETAIN (applied; no mutation)
No Caddy edit, no recreate. The callback route, the public exact-path `GET` edge handle, and `shopify.app.toml auth.redirect_urls` are retained; the permanent `POST` webhook is unchanged. Posture is already correct — recorded as the governed final decision (the "temporary" marker in the Caddyfile is now superseded by "retained: hardened, fail-closed, required for future reauth"; no standalone recreate performed to avoid a needless co-tenant blip).

### Gate P5-1 — pre-execution baseline (read-only, PASS)
- `P5-1_FP = 62b2e42fe409b4ec91f3381b35da819e` (== FINAL_FP). receipts **3**. migrations **120**.
- Connected: shop `second-chance-eyewear-accessories.myshopify.com`, scope `read_orders`, token SET (encrypted), **offline** (`expires_at` null). config scopes `read_orders`, api `2026-07`.
- item 4 `REGISTERED` / `disputed` / owner collector **3** / sale-link `revoked_refund`; public_ref `SCA-A960A57D3124`.
- **Edge posture (Option A, unchanged):** `POST /sca/shopify/webhook` no-HMAC → **401** (permanent, fail-closed); `GET /sca/shopify/oauth/callback` no-params → **400** (retained, fail-closed); `GET` webhook wrong-method → **404**; `/sca/shopify/connect` (non-staff) → **404** (install initiator stays staff-IP `/admin`); `/collector` 302; `/storage/*` 404; smsrocket.io **302**.

### D-FIXTURES — operator browser steps provided in chat; Shopify actions are operator-only.
Archive order #3281; unpublish+delete the `ZZ-SCA-DRYRUN-TEST (DO NOT SELL)` product only. STOPPED for operator; P5-3/P5-4 to run after completion. No SCA mutation; all provenance retained.

# SCA — Shopify Inventory Sync Phase 1: Release Readiness (READ-ONLY)

**Scope: read-only preparation only. Nothing merged, deployed, migrated, re-scoped, re-consented, registered, imported, restarted, or otherwise changed in production. Option C and the 139/140 incident are out of scope and untouched.** 2026-10-27. **STOP for independent ChatGPT review.**

## [1] Branch vs current main

- `origin/main` = **`6ebe968`**; branch `feat/sca-shopify-inventory-sync` = **`9f05c8a`**; `merge-base == 6ebe968` ⇒ the branch sits **directly on current main** (fast-forward/clean merge; `git merge-tree` shows **no conflict markers**).
- 4 commits (`312927d`→`5f53bec`→`e96700b`→`9f05c8a`); DB test passed at `9f05c8a` (21/67/0). `9f05c8a` adds only a test-only DB-guard parameterization over the reviewed `e96700b` product/service code.

## [2] Delta, conflicts, deployment dependencies

- **16 files, +1387/−4**, **entirely within `app/packages/Sca/Shopify/` + `app/tests/`** — nothing else in the app changes (verified by name filter). The order/refund sale-link path is untouched code-wise except the `WebhookController` dispatch line and the additive `WebhookAuditRecorder`/`WebhookTopics` entries.
- **2 additive migrations** (`2026_10_27_000001_create_sca_shopify_products`, `_000002_create_sca_shopify_variants`) — **`Schema::create` only, no `ALTER`/drop of any existing table**; `down()` drops just the two new tables. **No `composer.json`/dependency change**, no config/bootstrap change.
- **Conflicts:** none. **Deployment dependencies:** unlike the backup fix (0 migrations), this deploy **requires a production `migrate`** for the two new tables (prod is batch 27 → these become **batch 28**). The changed PHP files (`WebhookController`, `WebhookAuditRecorder`, `WebhookTopics`, `ShopifyServiceProvider`) need an **opcache graceful reload**. New classes/migrations are autoloaded/discovered with no extra wiring.
- **Decoupling (low risk):** deploying the code is **inert** until activation — the two tables are empty, no `products/*` webhook is registered yet (so no product events arrive), and `read_products` is not yet granted (so no import can read). Nothing in the deploy alters order processing or existing data.

## [3] Safe deployment sequence (owner-authorized; NOT executed here)

Preflight (read-only): confirm clean tree, `HEAD == origin/main == 6ebe968`, branch `9f05c8a` a fast-forward, delta == the 16 files, and `artisan migrate:status` shows **only** the two catalog migrations as *pending* (nothing else unexpected).

```bash
cd /opt/sca-platform && git fetch origin
# A. Merge (no reset / no force): advances main by exactly the 16-file delta.
git merge --no-ff --no-edit 9f05c8a -m "Merge Shopify inventory sync Phase 1 catalog mirror (9f05c8a)"
git diff --name-only HEAD@{1} HEAD   # must equal the 16 files
git push origin main
# B. Apply the TWO additive migrations to prod (creates 2 empty tables; batch 28).
#    NOTE the 139/140 gotcha: a bare `artisan migrate` in kr-app targets prod sca_krayin
#    (default connection) — which is INTENDED here. Verify status first:
docker compose exec -T -u 33:33 app php artisan migrate:status | grep 2026_10_27   # both "Pending"
docker compose exec -T -u 33:33 app php artisan migrate --force                     # applies ONLY pending (the 2)
# C. Controlled opcache reload for the changed webhook/provider files (zero-downtime, not a restart).
docker exec kr-app apachectl -k graceful
```
No composer install, no container rebuild/recreate, no config change in this step.

### Rollback plan (code-only + a safe additive-table drop)

- **Code:** revert-forward — `git revert --no-edit -m 1 <merge-sha> && git push origin main`, advance the live tree, `apachectl -k graceful`.
- **DB:** the two tables are additive and **empty until an import runs**, so `docker compose exec -T -u 33:33 app php artisan migrate:rollback --step=1` (batch 28 → drops exactly the two catalog tables) is safe with **no data loss**. If an import already populated them and the rollback is still wanted, export the catalog rows first (they are reproducible by re-import anyway). Never `reset`/force-push shared `main`; 139/140 batch 27 is never rolled back.

## [4] Existing OAuth setup & how to request `read_products` (no credential exposure)

Observed (names/non-secret only): `SHOPIFY_SHOP_DOMAIN=second-chance-eyewear-accessories.myshopify.com`, `SHOPIFY_API_VERSION=2026-07`, `SHOPIFY_OAUTH_REDIRECT_URI=https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback`, `SHOPIFY_CLIENT_ID` present, `SHOPIFY_CLIENT_SECRET` present, `SHOPIFY_WEBHOOK_SECRET` present. The live credential row holds a **`read_orders`-only** token (`has_token=1`). **`read_products` is NOT yet granted.**

To request `read_products` safely (owner action, a config change — not done in this read-only task):
1. In `app/.env`, change `SHOPIFY_SCOPES=read_orders` → `SHOPIFY_SCOPES=read_orders,read_products` (the scope string is **not a secret**; `client_id`/`client_secret`/tokens stay in env and are **never printed, logged, or committed** — `shopify.php` reads them from the environment only, and `AccessTokenStore` stores the token encrypted).
2. Re-run the app's OAuth install/authorize flow for the store; Shopify shows the merchant a consent screen listing the added "read products" permission. The merchant approves; the callback exchanges the code for a **new token carrying `read_products`**, stored encrypted. The old `read_orders`-only token is replaced.
3. Verify (non-secret): the `sca_shopify_credentials.scope` column now includes `read_products` and `has_token=1`. No token value is ever displayed.

Until this is done, `ShopifyClient::getProduct`/`listProducts` fail closed with `SHOPIFY_AUTH_ERROR` (403) — the import simply cannot read.

## [5] Product webhook registration checklist (owner action; NOT done here)

- **Topics to add:** `products/create`, `products/update`, `products/delete` (the allowlist already accepts them; order/refund topics remain registered — only ADD these three).
- **Delivery URL:** `https://verify.secondchanceauthenticators.com/sca/shopify/webhook` · **format** JSON · **API version** `2026-07`.
- **HMAC:** signed with the app's client secret (`SHOPIFY_WEBHOOK_SECRET`, already present) — `WebhookVerifier` checks it over the raw body; an invalid signature → 401, nothing recorded.
- **Edge:** verify the Caddy edge routes `/sca/shopify/webhook` to `kr-app` (added in the prior Shopify edge activation, gov `8bc04d5`) — not re-verified in this read-only pass (Caddyfile not readable from this context); confirm at registration.
- **Post-registration check:** send one test delivery per topic → expect HTTP 200 and one row per delivery in `sca_shopify_webhook_receipts` (topic recorded, idempotency key = shop:topic:webhook-id); a replay of the same delivery id → still 200, **no second row** (idempotent).

## [6] Initial import procedure & success verification (owner action; NOT done here)

Pre-reqs: deploy done (2 tables exist), `read_products` granted (re-consent complete), token valid.

```bash
docker compose exec -T -u 33:33 app php artisan sca:shopify:import-catalog   # explicit, not scheduled
```
Verify:
- Command prints bounded counts (`products / created / updated / unchanged / pages`), exit 0.
- `sca_shopify_products` / `sca_shopify_variants` row counts are > 0 and consistent with the store's catalog size; spot-check one known product + its variants.
- **Catalog-only invariant holds in prod:** provenance fingerprint unchanged — `sca_eyewear_items / sca_item_current_state / sca_ownership_events / sca_certifications` still `3 / 3 / 5 / 4`, batch unchanged; **no passport/QR/ownership/claim-link created**.
- **Idempotency:** re-run the import → all `unchanged`, **no duplicate rows** (DB UNIQUE).
- Optionally run `php artisan sca:shopify:reconcile-catalog` → zero unexpected drift; it remains **unscheduled** (activation of a schedule is a separate, deferred decision).

## [7] Required merchant actions (plain language)

1. **Approve one new permission.** We'll send a link (or you'll see a prompt in your Shopify admin) asking to let the authenticator **read your product list** — in addition to orders, which it already reads. Click **Approve/Install**. This is read-only: it does **not** change your products, your orders, your prices, or anything in your store, and it cannot edit or delete anything.
2. **That's the only click you need.** No passwords, API keys, or secret codes are ever shared with you or shown on screen — the approval is a single confirmation inside your own Shopify admin.
3. After you approve, your products will automatically copy into the authenticator's catalog. New or edited products keep syncing on their own. Copying a product into the catalog does **not** create a certificate, passport, QR code, or ownership record — those remain separate, staff-controlled steps.

## [8] Readiness verdict

| Gate | Status |
|---|---|
| Branch clean on current main, no conflicts | **READY** |
| Delta confined to Shopify package + tests; order path preserved | **READY** |
| Migrations additive (2 new tables; no ALTER; safe rollback) | **READY** |
| Isolated DB test evidence (21/67/0) | **READY** |
| Deployment sequence + rollback prepared | **READY** (owner-authorized execution) |
| `read_products` scope + merchant re-consent | **PENDING owner** (token is read_orders-only) |
| `products/*` webhook registration | **PENDING owner** |
| Initial import run | **PENDING** (after scope + webhooks) |
| **Overall** | **READY to release on owner approval; activation gated on scope re-consent + webhook registration + import.** |

**STOP — read-only release-readiness report delivered for owner + ChatGPT. No merge/deploy/migrate/scope/OAuth/webhook/import/restart/production change; Option C + 139/140 untouched.**

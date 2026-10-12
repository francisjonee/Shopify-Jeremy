# SCA Shopify Reconciliation & Operations — merge + governed deploy result

**Date:** 2026-10-12 · **Status: ✅ DONE — merged `--no-ff` + deployed (migration 135→136). Full gate green on the merge tree. Provenance row-data fingerprint byte-identical PRE/POST. Existing integration records unchanged; legacy receipts NOT backfilled. Stripe DORMANT; mail=log; Shopify OAuth scopes/credentials UNCHANGED; no Caddy/DNS/SMTP change. NOT declared closed — STOP for ChatGPT post-deployment audit.** Authorized after ChatGPT re-audit **PASS (R1 closed)** of candidate `682bbbc4779cbd688789685506c7f9f4309806e6` (gov PASS `2b04810`).

## SHAs
- **Approved candidate:** `682bbbc4779cbd688789685506c7f9f4309806e6`
- **Base / deployed-from:** `b9baa341060dda08144b57017ca59776b7062cb2`
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `9bc0907c486688c7acd0d22ad2ee9f5db37d93bb`**

## 1. Preflight — PASS (no drift)
origin/main == deployed head == base `b9baa34`; origin candidate == approved `682bbbc`; candidate **2 ahead / 0 behind**; diff = exactly the **14** audited files; **1 new migration** (135→136); prod migration **135**; reconciliation table + receipt outcome columns ABSENT pre-deploy; PRE provenance FP `d15a5cbdfb8df52ba65628b276533cfe` (counts 3/3/4/4/5/2/1/1/7); PRE integration counts: webhook_receipts **32**, sale_links **1**; effective Shopify scope `read_orders`; Stripe dormant; mail log.

## 2. Merge — file-identical tree
Merged `--no-ff` → MERGE_SHA `9bc0907`; `origin/main == 9bc0907`; **merged tree byte-identical to approved candidate `682bbbc`** (`git diff 682bbbc 9bc0907 --` → empty); 14 files; no extra content.

## 3. Test gate (exact merge tree, disposable `sca_domain_test`, migrated through 136)
`scripts/deploy-preview.sh` gate: **exit 0 · 1243 passed · 1 skipped (known WebP GD env) · 0 failed · 6488 assertions**. Includes `ShopifyReconciliationTest` (21, incl. the 3 R1 order-level atomicity proofs) + existing `ShopifyConnection`/`SaleLink`/`SaleClaimVisibility`/`ListingRefCopy`/`ClaimWorkflow` + full regressions. First gate run tripped the known unrelated `CertificateDocumentClassificationTest::d9` low-autoincrement-id `assertDontSee` flake ("Not to contain: 300"); `set -e` aborted BEFORE any prod migrate (prod stayed 135), and the standard re-run passed clean (0 failed).

## 4. Deploy — application + migration (135 → 136)
`git reset --hard origin/main` → `9bc0907`; composer install (dev) → gate PASS → chown → `php artisan migrate --force` → `2026_10_17_000001_add_shopify_reconciliation … DONE` (**135 → 136**); memory-capped rebuild + `docker compose up -d` (sca project only; kr-app + kr-mariadb Healthy); `--no-dev --optimize-autoloader` prune; caches cleared; `GET /admin/login → 200`. kr-app loopback-only. **No Caddy/DNS/edge change.**

### Schema verification (prod `sca_krayin`)
| Element | Result |
|---|---|
| prod migrations | **136** |
| `sca_shopify_webhook_receipts` new columns | `processing_outcome, outcome_code, line_count, actionable_count, noop_count, rejected_count, processed_at` (all present, nullable) |
| index `idx_receipt_topic_outcome` (topic, processing_outcome) | present |
| `sca_shopify_reconciliation_runs` table | present, **0 rows** |
| indexes `idx_recon_shop_order` (shop, order), `idx_recon_created` | present |
| no unexpected schema change | confirmed (two additive elements only) |

## 5. Integration records + legacy-row safety (additive migration must not mutate existing data)
| Check | PRE (135) | POST (136) |
|---|---|---|
| `sca_shopify_webhook_receipts` count | 32 | **32** (unchanged) |
| `sca_shopify_sale_links` count | 1 | **1** (unchanged) |
| receipts with non-null `processing_outcome` | — | **0** (legacy rows NOT backfilled — no fabricated outcomes) |
| `sca_shopify_reconciliation_runs` rows | — | **0** (initial production count) |

The migration only added nullable columns + an empty table; every existing receipt/sale-link row is untouched and legacy receipts carry a NULL processing outcome (= "not summarized"), exactly as designed.

## 6. Provenance invariants — PASS
| Check | PRE (135) | POST (136) |
|---|---|---|
| provenance row-data fingerprint | `d15a5cbdfb8df52ba65628b276533cfe` | `d15a5cbdfb8df52ba65628b276533cfe` (byte-identical) |
| canonical counts items/qr/certs/auth/ownership/claims/grants/sale/status | 3/3/4/4/5/2/1/1/7 | 3/3/4/4/5/2/1/1/7 |

## 7. OAuth scope / dormancy / infra
- **Shopify OAuth scopes UNCHANGED by this deploy.** Effective prod scope is **`read_orders`** (prod `app/.env` sets `SHOPIFY_SCOPES=read_orders`; the code config DEFAULT is `read_orders,read_products`). Reconciliation's read-only `getOrder` needs only `read_orders` (satisfied), and OAuth scope/credential changes are forbidden — so `app/.env` was NOT modified; PRE==POST scope = `read_orders`. **Reporting note for the audit:** this differs from the expected `read_orders,read_products` string, but it reflects pre-existing production configuration, not a change introduced by this slice; no code path requires `read_products` (the webhook reads product/variant ids from the delivered payload, and reconciliation uses only `read_orders`). No credential change.
- `STRIPE_ENABLED` unset (dormant); `MAIL_MAILER` log. No Caddy/DNS/SMTP change.

## 8. Production smoke — boundaries (read-only; no live reconciliation performed)
| Check | Result |
|---|---|
| operations + reconcile routes registered | `GET admin/sca/shopify/operations`, `POST admin/sca/shopify/reconcile` present |
| external `/admin/sca/shopify` (config) | **403 Caddy** (admin staff-IP edge restriction intact) |
| external `/admin/sca/shopify/operations` | **403 Caddy** (edge restriction intact; view/mutation ACL proven by gate tests rc8/rc9) |
| external `POST /admin/sca/shopify/reconcile` | **403 Caddy** (edge restriction; ACL+CSRF+throttle internal) |
| external `POST /sca/shopify/webhook` | **401 Apache** (HMAC fail-closed, reaches app — webhook route healthy/unchanged) |
| external `/collector/login` | **200 Apache** (collector unaffected) |
| external `/c/PUB-…`, `/u/ada`, `/p/{bogus}` | **404 Apache** (public/collector routes unaffected) |
| external `/admin/login` | **403 Caddy** (admin edge restriction unaffected) |
| loopback `:8080/admin/login` | **200** · co-tenant `smsrocket.io` → **302** |

No live reconciliation was run against a real production order.

**Outcome: DONE (merged `--no-ff` + deployed, `9bc0907`); deployed tree byte-identical to the audited candidate `682bbbc`; prod migrations 135→136 (additive receipt outcome columns + empty `sca_shopify_reconciliation_runs`); existing 32 receipts + 1 sale link unchanged and legacy outcomes NOT backfilled; provenance row-data fingerprint byte-identical PRE/POST; Shopify OAuth scopes/credentials unchanged (effective `read_orders`); Stripe DORMANT; mail log; no Caddy/DNS/SMTP change; staff boundaries + webhook route healthy.** **STOP for ChatGPT post-deployment audit. Not declared closed. No new initiative started.**

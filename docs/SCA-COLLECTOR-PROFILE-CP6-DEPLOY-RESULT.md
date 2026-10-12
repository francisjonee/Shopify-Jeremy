# SCA Collector Profile — CP-6 (Private Collection Organization) — merge + governed deploy result

**Date:** 2026-10-12 · **Status: ✅ DONE — merged `--no-ff` + deployed (migration 134→135). Full gate green on the merge tree. Provenance row-data fingerprint byte-identical PRE/POST. Stripe DORMANT; mail=log. No Caddy/DNS/Shopify/SMTP change. CP-6 NOT declared closed — STOP for ChatGPT post-deployment audit.** Authorized after ChatGPT CP-6 re-audit **PASS (R1 closed)** of candidate `2d15c6bb40b842c7368bd9bd08123a06e5df95d7` (gov PASS `62fd26b`).

## SHAs
- **Approved candidate:** `2d15c6bb40b842c7368bd9bd08123a06e5df95d7`
- **Base / deployed-from:** `0101755b03352305050b7b7290ad917b588112ff`
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `b9baa341060dda08144b57017ca59776b7062cb2`**

## 1. Preflight — all PASS (no drift)
origin/main == deployed head == base `0101755`; origin candidate head == approved `2d15c6b`; candidate **2 ahead / 0 behind**; diff = exactly the **17** audited CP-6 files; **1 new migration** (134→135); prod migration **134**; CP-6 tables ABSENT pre-deploy; PRE provenance row-data FP `d15a5cbdfb8df52ba65628b276533cfe` (counts 3/3/4/4/5/2/1/1/7); collectors 4 / private 0 / public-profiles 0 / public-items 0 / handle-bearing 0 / handle-tombstones 0; Stripe dormant; mail log.

## 2. Merge — file-identical tree
Merged `--no-ff` → MERGE_SHA `b9baa34`; `origin/main == b9baa34`; **merged tree byte-identical to approved candidate `2d15c6b`** (`git diff 2d15c6b b9baa34 --` → empty); 17 CP-6 files; no extra content.

## 3. Test gate (exact merge tree, disposable `sca_domain_test`, migrated through 135, no competing runner)
`scripts/deploy-preview.sh` gate: **exit 0 · 1222 passed · 1 skipped (known WebP GD env) · 0 failed · 6188 assertions**. Includes `CollectorCollectionTest` (29) + `CollectorCollectionConcurrencyTest` (5 — real two-connection add-vs-transfer / add-vs-correction via the production workflows in a separate OS process, deterministic) + CP-2/CP-4/CP-5/transfer/ownership-correction/privacy/Passport regressions. No `raw_sql` in any CP-6 collision test.

## 4. Deploy — application + migration (134 → 135)
`git reset --hard origin/main` → `b9baa34`; composer install (dev) → gate PASS → chown storage → `php artisan migrate --force` → `2026_10_16_000001_create_sca_collector_collections … DONE` (**134 → 135**); memory-capped rebuild (`--memory=1500m`) + `docker compose up -d` (sca project only; kr-app + kr-mariadb Healthy); `--no-dev --optimize-autoloader` prune; caches cleared; `GET /admin/login → 200`. kr-app stayed loopback-only. **No Caddy/DNS/edge change.**

### Schema verification (prod `sca_krayin`)
| Element | Result |
|---|---|
| prod migrations | **135** (CP-6 migration row present) |
| `sca_collector_collections` / `sca_collector_collection_items` | both present, **0 rows** |
| UNIQUE `uniq_collection_ref` (public_ref) | present |
| UNIQUE `uniq_collection_collector_name` (collector_account_id, name_normalized) | present |
| UNIQUE `uniq_collection_item` (collector_collection_id, eyewear_item_id) | present |
| foreign keys (collections→accounts RESTRICT; items→collections CASCADE, →accounts RESTRICT, →items RESTRICT) | **4** present |
| triggers | `trg_sca_collections_bu` (collector/public_ref immutable), `trg_sca_collection_items_bu` (membership identity immutable), `trg_sca_collection_items_bi` (membership collector pinned to collection owner) |

## 5. Production smoke — boundaries (read-only; no fixtures created)
| Check | Result |
|---|---|
| deployed head == origin/main == MERGE_SHA | `b9baa34` |
| migration | **135** |
| external `/c/PUB-…`(bogus) | **404 Apache** (reachable, app-level) |
| external `/u/ada` | **404 Apache** (CP-5 edge admits `/u/*`; reaches app) |
| external `/p/{bogus}` | **404 Apache** (passport reachable, identity-free) |
| external `/collector/login` | **200 Apache** |
| external `/admin/login` | **403 Caddy** (staff-IP restriction unchanged) |
| loopback `:8080/admin/login` | **200** |
| external `:8080` | refused/000 (loopback-only) |
| co-tenant `smsrocket.io` | **302** (healthy) |
| CP-6 public route | none (private only) |

## 6. Post-deploy invariants — all PASS
| Check | PRE (134) | POST (135) |
|---|---|---|
| provenance row-data fingerprint | `d15a5cbdfb8df52ba65628b276533cfe` | `d15a5cbdfb8df52ba65628b276533cfe` (byte-identical) |
| canonical counts items/qr/certs/auth/ownership/claims/grants/sale/status | 3/3/4/4/5/2/1/1/7 | 3/3/4/4/5/2/1/1/7 |
| collector accounts | 4 | 4 |
| private / public-profiles / public-items | 0 / 0 / 0 | 0 / 0 / 0 |
| handle-bearing / handle-tombstones | 0 / 0 | 0 / 0 |
| CP-6 collections / memberships | — | **0 / 0** |
| `STRIPE_ENABLED` / secret | unset (dormant) | unset (dormant) |
| `MAIL_MAILER` | log | log |
| Caddy / DNS / Shopify / SMTP | — | unchanged |

**Note on collector count:** collectors read **4** both PRE and POST (the deploy created none). This is organic production activity (one real collector registration on the live site since the CP-6 candidate was first pushed, when the count was 3); it is NOT provenance and does not affect the provenance fingerprint (which does not count `sca_collector_accounts`), and PRE==POST confirms the CP-6 deployment created zero collectors.

CP-6 is a presentation-only slice: the deployment created ZERO eyewear items, authentications, certifications, QR identities, ownership events, claims, grants, sale links, public profiles/items, handles, tombstones, collections, or memberships. Two additive empty tables + their constraints/triggers only.

**Outcome: DONE (merged `--no-ff` + deployed, `b9baa34`); deployed tree byte-identical to the audited candidate `2d15c6b`; prod migrations 134→135 (two additive empty tables `sca_collector_collections` + `sca_collector_collection_items`); provenance row-data fingerprint byte-identical PRE/POST; Stripe DORMANT; mail log; `/c`/`/u`/Passport/collector/admin boundaries healthy and unchanged; no Caddy/DNS/Shopify/SMTP change.** **STOP for ChatGPT CP-6 post-deployment audit. CP-6 NOT declared closed. CP-7 / post-CP6 work NOT started.**

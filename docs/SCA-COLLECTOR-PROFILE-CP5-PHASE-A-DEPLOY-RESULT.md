# SCA Collector Profile — CP-5 — Phase A (Public Handle / Profile URL) — merge + governed deploy result

**Date:** 2026-10-09 · **Status: ✅ DONE — merged `--no-ff` + deployed Phase A (migration 133→134). PRE==POST provenance row-data fingerprint byte-identical. `/u/*` still externally Caddy-404 (edge NOT activated). Stripe DORMANT; mail=log. No Caddy/DNS/Shopify/SMTP change. CP-5 NOT declared closed — STOP for ChatGPT Phase-A post-deployment audit.** Authorized after ChatGPT CP-5 R1 re-audit **PASS** of candidate `2d87c38dadb5af61a630805dc2da3a6e11eb2f02`.

## SHAs
- **Approved candidate:** `2d87c38dadb5af61a630805dc2da3a6e11eb2f02`
- **Base / deployed-from:** `7409a33baecf2ef6bd8c44413a27a9f77fa249f1`
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `0101755b03352305050b7b7290ad917b588112ff`**

## 1. Preflight — all PASS (no drift)
origin/main == deployed head == base `7409a33`; origin candidate head == approved `2d87c38`; candidate **2 ahead / 0 behind**; diff = exactly the audited **14** CP-5 files; **1 new migration** (133→134); prod migration **133**; handle columns + `sca_collector_handle_reservations` ABSENT pre-deploy; fingerprint procedure confirmed deterministic (identical on two consecutive read-only runs). Stripe dormant (`STRIPE_ENABLED`/secret unset in `app/.env`); mail log; `/u/ada` externally `404 server: Caddy`.

## 2. Merge — file-identical tree
Merged `--no-ff` → MERGE_SHA `0101755`; `origin/main == 0101755`; **merged tree byte-identical to approved candidate `2d87c38`** (`git diff 2d87c38 0101755 --` → empty); 14 CP-5 files; no extra content.

## 3. Deterministic READ-ONLY provenance row-data fingerprint procedure

New reproducible baseline (the historical `35e063282e004…` composite SQL was not preserved in governance evidence and was NOT reverified; the earlier `532ea48d…` was a rejected reduced count-hash). This procedure hashes ROW DATA, is pure-SELECT, and is recorded here verbatim.

**Definition.** Fixed ordered set of canonical PROVENANCE tables (data only; presentation/migration tables excluded):
`sca_eyewear_items, sca_item_current_state, sca_qr_identifiers, sca_qr_lifecycle_events, sca_certifications, sca_certification_events, sca_authentications, sca_ownership_events, sca_status_events, sca_claims, sca_external_claim_grants, sca_shopify_sale_links, sca_media_assets`.
Per table: every column in `ORDINAL_POSITION` order, each `COALESCE(CAST(col AS CHAR), CHAR(0))`, joined with `CHAR(31)` into a per-row string; rows ordered by that row-string and joined with separator `0x1e`; `group_concat_max_len` raised to 64 MiB; per-table `MD5`. Composite = `md5` over `"<table>:<per-table-md5>\n"` lines in the fixed table order. Script (recorded):

```bash
#!/usr/bin/env bash
set -euo pipefail
DB="${1:?usage: provfp.sh <DBNAME>}"
cd /opt/sca-platform
RP="$(grep -m1 MARIADB_ROOT_PASSWORD .env | cut -d= -f2)"
myq() { docker compose exec -T mariadb mariadb -uroot -p"$RP" --batch --skip-column-names "$DB" -e "$1"; }
TABLES=( sca_eyewear_items sca_item_current_state sca_qr_identifiers sca_qr_lifecycle_events \
  sca_certifications sca_certification_events sca_authentications sca_ownership_events \
  sca_status_events sca_claims sca_external_claim_grants sca_shopify_sale_links sca_media_assets )
composite_input=""
for t in "${TABLES[@]}"; do
  exists="$(myq "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB' AND table_name='$t';")"
  if [ "$exists" != "1" ]; then composite_input+="$t:MISSING"$'\n'; continue; fi
  cols="$(myq "SELECT GROUP_CONCAT(CONCAT(\"COALESCE(CAST(\`\", column_name, \"\` AS CHAR),CHAR(0))\") ORDER BY ordinal_position SEPARATOR ',') FROM information_schema.columns WHERE table_schema='$DB' AND table_name='$t';")"
  hash="$(myq "SET SESSION group_concat_max_len=67108864; SELECT COALESCE(MD5(GROUP_CONCAT(r ORDER BY r SEPARATOR 0x1e)),'EMPTY') FROM (SELECT CONCAT_WS(CHAR(31),$cols) AS r FROM \`$t\`) s;")"
  composite_input+="$t:$hash"$'\n'
done
printf '%s' "$composite_input" | md5sum | cut -d' ' -f1
```

**Per-table row-data MD5 (identical PRE and POST):**

| table | rows | md5 |
|---|---|---|
| sca_eyewear_items | 3 | `fbeab65bb7f1b8e4244f3631dfec79c3` |
| sca_item_current_state | 3 | `4ad1197a67cdebdbf80ff4e635a1a1d5` |
| sca_qr_identifiers | 3 | `7824e28681e518ccc93ba4c67ee67fa1` |
| sca_qr_lifecycle_events | 3 | `38c72a5f7879a075db900f62f9e4c796` |
| sca_certifications | 4 | `99f4882280bb455de4a2575d80666996` |
| sca_certification_events | 5 | `d9d15d4784ef6e270ac477fad253a62e` |
| sca_authentications | 4 | `a041917048a40ad4718084e4ad806a7d` |
| sca_ownership_events | 5 | `39c1ebd7358ea9adaa9dabcb83340b7a` |
| sca_status_events | 7 | `9127fb655e252fb6fbcb0a08309797a3` |
| sca_claims | 2 | `00d871cd6a53c9314273b8bb54b91f09` |
| sca_external_claim_grants | 1 | `8e531f0f66191c2fb8b250fbe7a50993` |
| sca_shopify_sale_links | 1 | `521344f6e0373c52ac1f31a006b6b6bd` |
| sca_media_assets | 2 | `92d15e56f13e8a536b11aa9a9236f221` |

| | PRE_DEPLOY (migration 133) | POST_DEPLOY (migration 134) |
|---|---|---|
| **COMPOSITE_PROVENANCE_ROWDATA_FP** | `d15a5cbdfb8df52ba65628b276533cfe` | `d15a5cbdfb8df52ba65628b276533cfe` |
| **CANONICAL_COUNTS** items/qr/certs/auth/ownership/claims/grants/sale/status | `3/3/4/4/5/2/1/1/7` | `3/3/4/4/5/2/1/1/7` |

**PRE == POST byte-for-byte.** Migration 134 touched only presentation/schema (handle columns + tombstone table); zero provenance row-data changed.

## 4. Test gate (exact merge tree, disposable `sca_domain_test`, migrated through 134, no competing runner)
- Focused required suites (`CollectorHandleTest`, `CollectorHandleConcurrencyTest`, CP-3 public-profile + concurrency, CP-4 public-item + concurrency, CP-1 profile + concurrency, Passport pilot): **147 passed / 1 skipped / 0 failed**; no `raw_sql` in the collision tests.
- Full `tests/Feature/Sca` on the exact merge tree: **exit 0 · 1188 passed · 1 skipped (known WebP GD env) · 0 failed · 6033 assertions**.
- Deploy-gate re-run of the full suite immediately before migrate (inside `scripts/deploy-preview.sh`): **1188 passed / 1 skipped / exit 0**. No `1205/1213` escaped any CP-5 collision test.

## 5. Deploy — application + migration (Phase A only)
`scripts/deploy-preview.sh`: `git reset --hard origin/main` → `0101755`; composer install (dev) → gate PASS → chown storage → `php artisan migrate --force` → `2026_10_15_000001_add_handle_to_sca_collector_public_profiles … DONE` (**133 → 134**); memory-capped rebuild (`--memory=1500m`) + `docker compose up -d` (sca project only; kr-app + kr-mariadb Healthy); `--no-dev --optimize-autoloader` prune (phpunit absent post-deploy); caches cleared; `GET /admin/login → 200`. kr-app stayed loopback-only (no public-bind stash re-applied). **No Caddy/DNS/edge change.**

### Schema verification (prod `sca_krayin`)
| Element | Result |
|---|---|
| prod migrations | **134** (CP-5 migration row present) |
| `handle`, `handle_normalized`, `handle_changed_at` on `sca_collector_public_profiles` | present |
| UNIQUE `uniq_public_profile_handle` | present |
| CP-3 immutability trigger `trg_sca_public_profiles_bu` | present, **unchanged** |
| `sca_collector_handle_reservations` table | present |
| UNIQUE `uniq_handle_reservation` | present |
| index `idx_handle_reservation_reusable_after` | present |
| tombstone columns | `id, handle_normalized, released_at, reusable_after, created_at, updated_at` — **no collector id / public_ref / PII linkage** |
| handle-bearing publication rows / tombstone rows created by migration | **0 / 0** |
| existing public-profile / public-item rows | **0 / 0** (unaffected) |

## 6. Phase-A production smoke — NO edge activation (read-only)
| Check | Result |
|---|---|
| app routes `GET /u/{handle}`, `/u/{handle}/avatar`, `/u/{handle}/items/{itemRef}/image` | registered, middleware `[web]` |
| app routes `POST`/`DELETE /collector/profile/handle` | middleware `[web, CollectorAuthenticate, throttle:10,1]` |
| GET `/collector/profile/handle` (availability probe) | **does not exist** (no availability/search/directory route) |
| `/c/{publicRef}`, `/c/{publicRef}/avatar`, `/c/{publicRef}/items/{itemRef}/image` | unchanged |
| external `/u/ada`, `/u/some-handle`, `/u/ada/avatar`, `/u/ada/items/SCA-X/image` | **404 `server: Caddy`** (edge-blocked — never reaches Apache/Laravel) ✅ expected Phase-A state |
| external `/collector/profile/handle` | 404 (Caddy; `/collector/profile/*` not an admitted public path) |
| external `/c/PUB-…` | 404 (app-level via admitted `/c/*`) |
| external `/p/{bogus}` | 404 (passport reachable, identity-free) |
| external `/collector/login` | 200 |
| external `/admin/login` | 403 (edge staff-IP restriction unchanged) |
| loopback `:8080/admin/login` | 200 |
| external `:8080` | refused/000 (loopback-only) |
| co-tenant `smsrocket.io` | 302 (healthy) |

No production collector/public fixtures were created for smoke.

## 7. Post-deploy invariants — all PASS
| Check | PRE (133) | POST (134) |
|---|---|---|
| provenance row-data fingerprint | `d15a5cbdfb8df52ba65628b276533cfe` | `d15a5cbdfb8df52ba65628b276533cfe` (byte-identical) |
| canonical counts items/qr/certs/auth/ownership/claims/grants/sale/status | 3/3/4/4/5/2/1/1/7 | 3/3/4/4/5/2/1/1/7 |
| collector accounts / private profiles / public profiles / public items | 3 / 0 / 0 / 0 | 3 / 0 / 0 / 0 |
| handle-bearing publications / tombstones | — | 0 / 0 |
| `STRIPE_ENABLED` / secret | unset (dormant) | unset (dormant) |
| `MAIL_MAILER` | log | log |
| Caddy / DNS / Shopify / SMTP | — | unchanged |

**Outcome: DONE (merged `--no-ff` + deployed, `0101755`); deployed tree byte-identical to the audited candidate `2d87c38`; prod migrations 133→134 (handle columns + additive tombstone table `sca_collector_handle_reservations`, 0 rows); provenance row-data fingerprint byte-identical PRE/POST; Stripe DORMANT; mail log; `/u/*` still externally Caddy-404 (edge NOT activated); no Caddy/DNS/Shopify/SMTP change.** **STOP for ChatGPT CP-5 Phase-A post-deployment audit. CP-5 NOT declared closed. `/u/*` NOT activated. CP-6 NOT started.**

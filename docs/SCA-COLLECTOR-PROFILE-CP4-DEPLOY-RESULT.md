# SCA Collector Profile — CP-4 (Public Collection Controls) — merge + governed deploy result

**Date:** 2026-10-09 · **Status: ✅ DONE — merged `--no-ff` + deployed (migration 132→133). Post-deployment verification PASS. Provenance byte-identical. Stripe DORMANT; mail=log. No Caddy/DNS/Shopify/SMTP change. CP-4 NOT declared closed — STOP for ChatGPT post-deployment audit.** Authorized after ChatGPT CP-4 R1 re-audit **PASS** of candidate `2836114ef5dd7b48e16f696c9195d52125725e11` (base `3e707582c21e40b97e909c8593987787fd4c33c4`, gov `862b3e4`).

## SHAs
- **Approved candidate:** `2836114ef5dd7b48e16f696c9195d52125725e11`
- **Base / deployed-from:** `3e707582c21e40b97e909c8593987787fd4c33c4`
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `7409a33baecf2ef6bd8c44413a27a9f77fa249f1`**

## 1. Preflight — all PASS (no drift)
origin/main == deployed head == base `3e70758`; candidate head == approved `2836114`; candidate **3 ahead / 0 behind**; diff = exactly the audited **14** files; **1 new migration** (132→133); prod migration **132**; `sca_collector_public_items` ABSENT pre-deploy; provenance DATA FP `35e063282e004eaabcc9240360ecc0e3` (items 3/qr 3/certs 4/auth 4/ownership 5/claims 2/grants 1/sale 1/status 7); collectors 3 / private-profiles 0 / public-profiles 0; Stripe dormant; mail log; edge `/c/*` still admitted (bogus `/c/PUB-…` → `server: Apache`, reaches kr-app from CP-3 Phase B).

## 2. Merge — file-identical tree
Merged `--no-ff` → MERGE_SHA `7409a33`; `origin/main == 7409a33`; **merged tree file-identical to candidate `2836114`** (`git diff 2836114 7409a33 --` → empty); 14 CP-4 files; no extra content.

## 3. Test gate (exact merge tree, disposable `sca_domain_test`, migrated through 133)
`scripts/deploy-preview.sh` gate: **1137 passed / 5864 assertions, 1 skipped**, exit 0. Only skip = known WebP GD environment skip. **No `QrReissueTest::rg8` flake this run** (no CP-4 causal signal). Includes `CollectorPublicItemTest` 29, `CollectorPublicItemConcurrencyTest` 2, CP-3 public-profile/concurrency, CP-2 My Collection, transfer/status/privacy/Passport regressions.

## 4. Deploy — app + migration
`git reset --hard origin/main` → `7409a33`; gate passed; `migrate --force` → `2026_10_14_000001_create_sca_collector_public_items … DONE` (**132 → 133**); memory-capped rebuild + `docker compose up -d` (sca project only; kr-mariadb Healthy); `--no-dev` prune; caches cleared; `GET /admin/login → 200`; `Deployed main @ 7409a33`. **No Caddy/DNS/edge change** (the nested public image route lives inside the already-admitted `/c/*` namespace).

### Schema verification (prod `sca_krayin`)
| Element | Result |
|---|---|
| prod migrations | **133** |
| `sca_collector_public_items` table | exists, **0 rows** |
| UNIQUE(collector_account_id, eyewear_item_id) | `uniq_public_item_collector_item` |
| indexes | `idx_public_item_item_visible`, `idx_public_item_collector_visible` |
| FKs | → `sca_collector_accounts`, → `sca_eyewear_items` (RESTRICT) |
| `is_visible` default | `0` (private) |
| immutability trigger | `trg_sca_public_items_bu` present |

## 5. Production smoke — read-only (no public fixtures created)
| Check | Result |
|---|---|
| deployed head == origin/main == MERGE_SHA | `7409a33` |
| migration | **133** |
| CP-4 private routes | `POST`/`DELETE collector/collection/{ref}/public` → middleware `[web, CollectorAuthenticate, throttle:30,1]` |
| CP-4 public image route | `GET c/{publicRef}/items/{itemRef}/image` → middleware `[web]` (unauthenticated) |
| external bogus nested CP-4 image `/c/PUB-…/items/SCA-NOPEREF/image` | **404, `server: Apache`** (reaches kr-app/Laravel ordinary 404 via the existing `/c/*` edge admission) |
| external bogus CP-3 profile `/c/PUB-…` | **404, `server: Apache`** (app-level) |
| `/collector/collection`, `/collector/profile` | **302** (collector-auth gated) |
| public Passport `/p/{bogus}` | **404, `server: Apache`** (reachable, identity-free) |
| `/admin/login` | **403** (edge staff-IP restriction unchanged) |
| unrelated `/unrelated-xyz` | **404, `server: Caddy`** (edge catch-all unchanged) |
| direct external `:8080` | **000** (loopback-only) |
| co-tenant `smsrocket.io` | **302** (healthy) |
| CP-5 routes | none |

No production collector/item publication was created for smoke; the bogus-ref app-level 404s prove route reachability + fail-closed resolution without any data.

## 6. Post-deploy invariants — all PASS
| Check | PRE (132) | POST (133) |
|---|---|---|
| provenance DATA fingerprint | `35e063282e004eaabcc9240360ecc0e3` | `35e063282e004eaabcc9240360ecc0e3` (byte-identical) |
| items/qr/certs/auth/ownership/claims/grants/sale/status | 3/3/4/4/5/2/1/1/7 | 3/3/4/4/5/2/1/1/7 |
| collector accounts / private profiles / public profiles / **public items** | 3 / 0 / 0 / — | 3 / 0 / 0 / **0** |
| `STRIPE_ENABLED` / secret | false / UNSET | false / UNSET |
| `MAIL_MAILER` | log | log |
| Caddy / DNS / Shopify / SMTP | — | unchanged |

CP-4 is a read-only presentation slice: the deployment created ZERO new eyewear items, authentications, certifications, QR identities, ownership events, claims, grants, Shopify sale links, collector accounts, private/public profiles, or public-item rows.

**Outcome: DONE (merged `--no-ff` + deployed, `7409a33`); deployed tree file-identical to the audited candidate; prod migrations 132→133 (one additive table `sca_collector_public_items`, 0 rows); provenance byte-identical; Stripe DORMANT; mail log; no Caddy/DNS/Shopify/SMTP change; nested public image route reachable within the existing `/c/*` edge namespace.** **STOP for ChatGPT CP-4 post-deployment audit. CP-4 NOT declared closed. CP-5 NOT started.**

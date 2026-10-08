# SCA Collector Profile — CP-2 (Rich My Collection) — merge + governed deploy result

**Date:** 2026-10-09 · **Status: ✅ DONE — merged `--no-ff` + deployed (NO migration; prod stays 131). Post-deployment verification PASS. Provenance byte-identical. Stripe DORMANT; MAIL_MAILER=log. CP-3 NOT started.** Authorized after ChatGPT CP-2 re-audit **PASS** of candidate `5ebe9591a530874f5376296a2e10f538772834e8` (base `8d8c35947d7c405124e0df4f09ff3ef4ee9e6bb8`, gov `9b6847a`).

## SHAs
- **Approved candidate:** `5ebe9591a530874f5376296a2e10f538772834e8`
- **Base / deployed-from:** `8d8c35947d7c405124e0df4f09ff3ef4ee9e6bb8`
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `a1e1d495d89d82fcfe921789e2b2bc4248874c0d`**

## 1. Preflight — all PASS (no drift)
`origin/main` == base `8d8c359`; candidate head == approved `5ebe959`; candidate **2 ahead / 0 behind** base; diff = exactly the **four** CP-2 files (`CollectionController.php`, `collection/index.blade.php`, `CollectionService.php`, new `RichMyCollectionTest.php`); **NO migration**; deployed tree head was still `8d8c359`; prod migration level **131**; Stripe dormant; mail log. Pre-deploy provenance DATA FP `35e063282e004eaabcc9240360ecc0e3` (items 3/qr 3/certs 4/auth 4/ownership 5/claims 2/grants 1/sale 1/status 7); collectors 3 / profiles 0.

## 2. Merge — file-identical tree
Merged `--no-ff` → MERGE_SHA `a1e1d49`; `origin/main == a1e1d49`; **merged tree file-identical to candidate `5ebe959`** (`git diff 5ebe959 a1e1d49 --` → empty); no additional commit/content.

## 3. Test gate (exact merge tree, disposable `sca_domain_test`)
`scripts/deploy-preview.sh` gate: **1085 passed / 5608 assertions, 1 skipped**, exit 0. The only skip is the known environment WebP GD skip (`CollectorProfileTest::av2`); no real failure, no flake. Focused suites within the gate: `RichMyCollectionTest` 27, `MyCollectionTest` 12, `CollectorProfileTest` 32 (+1 WebP skip).

## 4. Deploy
`git reset --hard origin/main` → `a1e1d49`; gate passed; `migrate --force` → **Nothing to migrate** (**131 → 131**); memory-capped rebuild + `docker compose up -d` (sca project only; kr-mariadb Healthy); `--no-dev` prune; caches cleared; `GET /admin/login → 200`; `Deployed main @ a1e1d49`. No schema create/alter/drop.

## 5. Production smoke — read-only (no fixtures manufactured) — all PASS
| Check | Result |
|---|---|
| unauth `GET /collector/collection` | **302 → collector login** |
| unauth `GET /collector/collection?...invalid params...` (`sort=brand_asc&cert=certified&brand=Zzz&registry=bogus&page=-9`) | **302** (route/middleware intact; no 500) |
| `GET /collector/collection/COL-BOGUSREF` (guess/non-owner) | **302** (behind `collector.auth`; privacy-safe) |
| public Passport `/p/{bogus}` | **404** (collector-identity-free) |
| `/storage/x` | **404** |
| `/admin/login` | **403** (edge staff-IP gate) |
| external `:8080` | **000** |
| co-tenant `smsrocket.io` | **302** (healthy) |
| collection routes | all under `collector.auth`; **no public collection route; no CP-3 route** |

Authenticated render behaviour (display-name header present/neutral, summary counts, GET search/filter/sort, invalid-query safe-normalize, filtered-no-result vs true-empty, card links → owner detail, card images via the existing authorized route, previous/non-owner ref privacy, no raw storage-path/internal-id/token/frame_serial/staff/Shopify leakage, Passport identity-free) is proven by the deploy-gate `RichMyCollectionTest`/`MyCollectionTest` exercising the **identical deployed code** on the disposable DB; no production collector credentials exist and the instructions forbid manufacturing production fixtures, so the authenticated surface is verified via the gate + the unauthenticated route/config boundaries above.

## 6. Post-deploy invariants — all PASS
| Check | PRE (131) | POST (131) |
|---|---|---|
| DEPLOYED_HEAD == MERGE_SHA == origin/main | — | `a1e1d49` |
| migration level | 131 | **131** (Nothing to migrate) |
| provenance DATA fingerprint | `35e063282e004eaabcc9240360ecc0e3` | `35e063282e004eaabcc9240360ecc0e3` (byte-identical) |
| items/qr/certs/auth/ownership/claims/grants/sale/status | 3/3/4/4/5/2/1/1/7 | 3/3/4/4/5/2/1/1/7 |
| collector accounts / profiles | 3 / 0 | 3 / 0 (unchanged) |
| `STRIPE_ENABLED` / secret / webhook secret | false / UNSET / UNSET | false / UNSET / UNSET |
| `MAIL_MAILER` | log | log |
| Stripe/SMTP/Shopify/Caddy/DNS | — | unchanged |

CP-2 is a read-only presentation slice: the deployment created ZERO new eyewear items, authentications, certifications, QR identities, ownership events, claims, grants, Shopify sale links, collector accounts, or collector profiles.

## 7. Flake / skip
One skip only: `CollectorProfileTest::av2` (WebP — environment GD lacks WebP), as accepted at promotion. No `QrReissueTest::rg8` flake this run; no reruns needed.

**Outcome: DONE (merged `--no-ff` + deployed, `a1e1d49`); deployed tree file-identical to the audited candidate; prod migrations 131 (no migration); provenance DATA byte-identical; collector accounts/profiles unchanged; Stripe DORMANT; mail log.** CP-2 (Rich My Collection) is LIVE. **STOP for ChatGPT post-deployment audit. CP-3 NOT started.**

# SCA Collector Profile — CP-3 — Phase A (application + migration) — deploy result

**Date:** 2026-10-09 · **Status: ✅ Phase A DONE — merged `--no-ff` + deployed (migration 131→132). Post-deploy verification PASS. Provenance byte-identical. Stripe DORMANT; mail=log. NO Caddy/DNS change. `/c/*` remains edge-blocked (expected Phase-A state). CP-3 is NOT yet publicly live / NOT closed.** Authorized after ChatGPT CP-3 R1 re-audit **PASS** of candidate `8aa8e8014ed2308f362972bb0c445ab1289dfb2f` (base `a1e1d495d89d82fcfe921789e2b2bc4248874c0d`, gov `afa9af9`).

## SHAs
- **Approved candidate:** `8aa8e8014ed2308f362972bb0c445ab1289dfb2f`
- **Base / deployed-from:** `a1e1d495d89d82fcfe921789e2b2bc4248874c0d`
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `3e707582c21e40b97e909c8593987787fd4c33c4`**

## 1. Preflight — all PASS (no drift)
`origin/main` == base `a1e1d49`; candidate head == approved `8aa8e80`; candidate **2 ahead / 0 behind**; diff = exactly **14** CP-3 files; **1 new migration** (131→132); deployed tree was still `a1e1d49`; prod migration **131**; `sca_collector_public_profiles` ABSENT pre-deploy. Pre-deploy provenance DATA FP `35e063282e004eaabcc9240360ecc0e3` (items 3/qr 3/certs 4/auth 4/ownership 5/claims 2/grants 1/sale 1/status 7); collectors 3 / profiles 0; Stripe dormant; mail log. Pre-deploy external edge `/c/PUB-…` and `/c/PUB-…/avatar` → **404** (blocked).

## 2. Merge — file-identical tree
Merged `--no-ff` → MERGE_SHA `3e70758`; `origin/main == 3e70758`; **merged tree file-identical to candidate `8aa8e80`** (`git diff 8aa8e80 3e70758 --` → empty); 14 CP-3 files; no extra content.

## 3. Test gate (exact merge tree, disposable `sca_domain_test`, migrated through 132)
`scripts/deploy-preview.sh` gate: **1106 passed / 5726 assertions, 1 skipped**, exit 0. Only skip = known WebP GD environment skip (`CollectorProfileTest::av2`); no real failure; no flake. Includes `CollectorPublicProfileTest` 19, `CollectorPublicProfileConcurrencyTest` 2, CP-1 profile/privacy, My Collection, Passport regressions.

## 4. Deploy — application + migration only
`git reset --hard origin/main` → `3e70758`; gate passed; `migrate --force` → `2026_10_13_000001_create_sca_collector_public_profiles … DONE` (**131 → 132**); memory-capped rebuild + `docker compose up -d` (sca project only; kr-mariadb Healthy); `--no-dev` prune; caches cleared; `GET /admin/login → 200`; `Deployed main @ 3e70758`. **No Caddy/DNS/edge change.**

### Schema verification (prod `sca_krayin`)
| Element | Result |
|---|---|
| prod migrations | **132** |
| `sca_collector_public_profiles` table | exists, **0 rows** |
| UNIQUE | `uniq_public_profile_collector` (collector_account_id) + `uniq_public_profile_ref` (public_ref) |
| index | `idx_public_profile_published` (+ PRIMARY) |
| FK `collector_account_id` → `sca_collector_accounts` | present (RESTRICT) |
| immutability trigger | `trg_sca_public_profiles_bu` present |

## 5. Phase A production verification — all PASS
| Check | Result |
|---|---|
| DEPLOYED_HEAD == origin/main == MERGE_SHA | `3e70758` |
| migration | **132** |
| CP-3 routes registered | `GET c/{publicRef}` (`collector.public.show`), `GET c/{publicRef}/avatar` (`collector.public.avatar`), `POST collector/profile/publish`, `DELETE collector/profile/unpublish` |
| public route middleware | `[web]` only (unauthenticated) — correct |
| private publish/unpublish middleware | `[web, CollectorAuthenticate, throttle:20,1]` — collector-auth gated |
| internal app-level bogus `/c/PUB-…` (host loopback 127.0.0.1:8080, pre-edge) | **404** rendering CP-3 "Profile not found" (route reaches CP-3 + returns its ordinary 404) |
| internal app-level bogus `/c/PUB-…/avatar` | **404** |
| **external edge** `/c/PUB-…` + `/c/PUB-…/avatar` | **404** — still NOT admitted (expected Phase-A state, not a defect) |
| external `/collector/profile` + `/collector/collection` | **302** (collector-auth) — My Collection stays authenticated |
| external public Passport `/p/{bogus}` | **404** (reachable + identity-free through its established edge path) |
| external `/admin/login` | **403** (edge staff-IP gate) |
| public directory/search route | none |
| CP-4 route | none |
| co-tenant `smsrocket.io` | **302** (healthy) |
| provenance DATA fingerprint | `35e063282e004eaabcc9240360ecc0e3` (byte-identical pre/post) |
| items/qr/certs/auth/ownership/claims/grants/sale/status | 3/3/4/4/5/2/1/1/7 (unchanged) |
| collector accounts / private profiles / **publication rows** | 3 / 0 / **0** |
| `STRIPE_ENABLED` / secret | false / UNSET |
| `MAIL_MAILER` | log |
| Caddy / DNS / Shopify / SMTP | unchanged |

No production publication was manufactured for smoke (per the gate); the internal loopback bogus-ref 404 proves the route/controller are live without creating any row.

## External `/c/*` edge behaviour (recorded, expected Phase-A state)
Pre-deploy and post-deploy, the external edge returns **404** for `/c/PUB-…` and `/c/PUB-…/avatar`. The production edge (Caddy) admits only `/p/*` and `/collector/*`; the new `/c/*` namespace is not admitted, so external requests hit the catch-all 404 and never reach kr-app. This is the intended Phase-A state — CP-3 is deployed app-side but not yet publicly reachable. **Phase B (a separate, minimal, audited production-edge activation of `/c/*`) is required before CP-3 is publicly live / closed, and is NOT part of this deployment.**

**Outcome: Phase A DONE (merged `--no-ff` + deployed, `3e70758`); deployed tree file-identical to the audited candidate; prod migrations 131→132 (one additive publication table, 0 rows); provenance byte-identical; Stripe DORMANT; mail log; NO Caddy/DNS change; `/c/*` edge-blocked as expected.** **STOP for ChatGPT Phase-A post-deployment audit. CP-3 NOT closed. CP-4 NOT started.**

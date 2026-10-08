# SCA Collector Profile — CP-1 (Private Profile Foundation) — merge + governed deploy result

**Date:** 2026-10-09 · **Status: ✅ DONE — merged `--no-ff` + deployed (migration 130→131). Post-deployment verification PASS. Provenance byte-identical. Stripe DORMANT; MAIL_MAILER=log. No CP-2 started.** Authorized after ChatGPT CP-1 pre-merge **PASS** (R1–R6 closed) of candidate `cc6d0537ecdb8df3ae5a5242298ab9c562d5d40e` (base `f461c17b7e0cbd5a5e5f026d5f5000870ef04752`, gov `4c80a4a`).

## SHAs
- **Approved candidate:** `cc6d0537ecdb8df3ae5a5242298ab9c562d5d40e`
- **Base / deployed-from:** `f461c17b7e0cbd5a5e5f026d5f5000870ef04752`
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `8d8c35947d7c405124e0df4f09ff3ef4ee9e6bb8`**

## 1. Merge gate — all PASS
`origin/main` == audited base `f461c17` (no drift); candidate head unchanged (`cc6d053`); candidate **4 ahead / 0 behind**; exactly **1 migration** added (`2026_10_12_000001_create_sca_collector_profiles`); 14 files, all CP-1 scope, no unrelated changes. Merged `--no-ff` (MERGE_SHA `8d8c359`). **Merged tree file-identical to candidate `cc6d053`** (`git diff cc6d053 8d8c359 --` → empty).

## 2. Deploy (`scripts/deploy-preview.sh`)
`git reset --hard origin/main` → `8d8c359`; SCA gate on `sca_domain_test` **1058 passed / 5476 assertions, 1 skipped (webp — env GD lacks WebP)**; `migrate --force` → `2026_10_12_000001_create_sca_collector_profiles … DONE` (**130 → 131**); memory-capped rebuild + `docker compose up -d` (sca project only; kr-mariadb Healthy); `--no-dev` prune; caches cleared; `GET /admin/login → 200`; `Deployed main @ 8d8c359`. No `QrReissueTest::rg8` flake this run.

## 3. Migration 130 → 131 + table/constraint/trigger verification (prod `sca_krayin`)
| Element | Result |
|---|---|
| prod migrations | **131** (`create_sca_collector_profiles` ran) |
| `sca_collector_profiles` table | exists |
| UNIQUE(collector_account_id) | `uniq_collector_profile` present |
| FK `collector_account_id` → `sca_collector_accounts` | present (ON DELETE RESTRICT) |
| immutability trigger | `trg_sca_collector_profiles_bu` present |
| profile rows | **0** |

## 4. Tests / smoke
- Deploy gate (disposable DB): **1058 passed / 5476 / 1 skipped**, exit 0. (Focused CP-1 within it: `CollectorProfileTest` 33 + `CollectorProfileConcurrencyTest` 4, 1 webp skip.)
- Production smoke (no destructive privacy/provenance actions): 5 CP-1 profile routes registered (`GET /collector/profile`, `PATCH /collector/profile`, `GET/POST/DELETE /collector/profile/avatar`); auth boundary — unauth `GET /collector/profile` → **302** (login), unauth `GET /collector/profile/avatar` → **302**, unauth `PATCH /collector/profile` → **419** (CSRF-first protected rejection, no mutation); public Passport `/p/{bogus}` → **404** (intact); `/storage/x` → **404**; `/collector` → **302**; `/admin/login` → **403** (edge staff-IP gate); external `:8080` → **000**; co-tenant `smsrocket.io` → **302** (healthy).

## 5. Provenance before/after — byte-identical
| Check | PRE (130) | POST (131) |
|---|---|---|
| provenance DATA fingerprint | `35e063282e004eaabcc9240360ecc0e3` | `35e063282e004eaabcc9240360ecc0e3` (identical) |
| items/qr/certs/auth/ownership/claims/grants/sale/status | 3/3/4/4/5/2/1/1/7 | 3/3/4/4/5/2/1/1/7 |
| collector accounts | 3 | 3 (unchanged) |
| collector profiles | (table absent) | **0** |

The deployment created ZERO new eyewear items, authentications, certifications, QR identities, ownership events, claims, external claim grants, Shopify sale links, or collector profile rows. Existing provenance + collector identities are byte-identical (only the migration metadata advanced 130→131 and the empty `sca_collector_profiles` table was added).

## 6. Stripe DORMANT + mail — verified post-deploy
`config('sca-stripe.enabled') === false`; `STRIPE_SECRET` **UNSET**; `STRIPE_WEBHOOK_SECRET` **UNSET**; webhook unactivated. `MAIL_MAILER` = **log** (no SMTP activation). No Stripe/SMTP/Shopify/Caddy/DNS change.

**Outcome: DONE (merged `--no-ff` + deployed, `8d8c359`); deployed tree file-identical to the audited candidate; prod migrations 130→131 (one additive `sca_collector_profiles` table, 0 rows); provenance DATA byte-identical; collector identities unchanged (3); Stripe DORMANT; mail in log mode.** CP-1 (Collector Profile — Private Profile Foundation) is LIVE. **STOP for ChatGPT post-deployment audit. CP-2 NOT started.**

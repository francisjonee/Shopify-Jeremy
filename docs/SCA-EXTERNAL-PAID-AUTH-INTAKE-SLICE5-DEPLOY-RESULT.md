# SCA External Paid Authentication Intake — Slice 5 (Result + Ownership Wiring) — merge + governed deploy result

**Date:** 2026-10-07 · **Status: ✅ DONE — merged `--no-ff` + deployed. NO migration (prod stays 129). Post-deployment verification PASS. Stripe remains DORMANT. No SMTP/MAIL/Shopify/Caddy/DNS change.** Authorized after ChatGPT re-audit PASS of head `116054eaeca10519830b7386c673b1a737875aeb` (gov evidence `494b464a9e7e05baf2c7919bf1ad82719079c8be`).

> **Slice 5 only. The overall External Paid Authentication capability is NOT closed.** Stripe activation and Slice 6 remain unpromoted.

## SHAs
- **Base / deployed-from:** `5b30120488d2d7b9975260a142c540ce0f2b843b`
- **Approved candidate head:** `116054eaeca10519830b7386c673b1a737875aeb` (unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `8c73e83d971486a541223c817a8c63c1a275f8e0`**

## Pre-merge gates (fail-closed) — all PASS
candidate head `116054e` unchanged; `origin/main` == merge-base == `5b30120`; tree clean.

## Candidate → deployed tree comparison
`git diff 116054eaeca10519830b7386c673b1a737875aeb 8c73e83d971486a541223c817a8c63c1a275f8e0 --` → **zero file differences** (IDENTICAL). The `--no-ff` merge changed only merge-commit mechanics; the deployed tree equals the audited candidate. **0 migrations in the diff.**

## Deploy (`scripts/deploy-preview.sh`)
`git reset --hard origin/main` → `8c73e83`; SCA gate on `sca_domain_test` **978 passed / 5187 assertions** (includes the focused `ExternalIntakeResultClaimTest` **19 / 94**); `migrate --force` → nothing to migrate (**129**); memory-capped rebuild + `docker compose up -d` (sca project only); `--no-dev` prune; caches cleared; healthy; `GET /admin/login → 200`; `Deployed main @ 8c73e83`. (No QR flake this run.)

## Production verification — all PASS
| Check | Result |
|---|---|
| deployed HEAD == merge SHA | `8c73e83d971486a541223c817a8c63c1a275f8e0` |
| deployed tree == audited candidate tree | **IDENTICAL** (zero file differences) |
| migration level | **129** (no migration for Slice 5) |
| focused Slice 5 | **19 passed / 94 assertions** (on the deploy gate) |
| full SCA regression | **978 passed / 5187 assertions** (on the deploy gate) — matches candidate baseline exactly |
| collector submission-bound claim route | `collector.submission.claim` **OK** |
| collector claim route guard | middleware `web, collector.auth, throttle:10,1` (collector-authenticated) |
| staff grant route | `admin.sca.submission.grant` **OK** |
| staff grant route guard | middleware `… sca.can:sca.eyewear.claim` (unchanged authority) |
| public bearer-token claim flow present | `collector.claim.grant.show` **OK** |
| Shopify claim flow present | `sca.shopify.webhook` **OK** (unsigned → 401) |

## Production invariants (deployment itself mutates nothing)
Provenance DATA fingerprint (migration count EXCLUDED) **byte-identical** before and after deploy: pre-merge `26852f4728d698b94627f316b597eb3a` == post-deploy `26852f4728d698b94627f316b597eb3a`. Deployment created **zero** new rows: counts unchanged — claims 2, external-claim grants 1, ownership events 5, authentications 4, certifications 4, Shopify sale links 1, submissions 0, payments 0 (the claims/grants/ownership figures are the pre-existing long-standing baseline from earlier phases, **not** created by this deploy — the identical fingerprint proves no new ownership/claim/grant/auth/cert/sale/submission row was written). No code deployment mutated business/provenance state.

## Smoke checks (no real grant/ownership created)
`/collector` **302** · `/collector/submissions` (unauth) **302 → login** · `POST /collector/submissions/{ref}/claim` (unauth, no token) **419** (CSRF-first rejection on the web-group POST — protected, no processing/mutation; with a token an unauthenticated request redirects to collector login) · bogus `/p/{token}` **404** · bearer claim surface `/collector/claim/grant/{token}` **302** (route intact) · `/storage/..` **404** · external `:8080` **000** · Shopify unsigned webhook **401** · smsrocket **302**.

## Stripe DORMANT verification
`config('sca-stripe.enabled') === false`; `STRIPE_SECRET` / `STRIPE_WEBHOOK_SECRET` **UNSET**; external `POST /sca/stripe/webhook` → **404** (edge unadmitted); no Stripe Checkout session initiated; no Stripe dashboard configuration; no Caddy admission change; no DNS change. Slice 5 deployment is NOT Stripe activation.

## Parked capabilities untouched
`MAIL_MAILER=log` unchanged; no SMTP activation; Shopify behavior unchanged; Caddy/DNS unchanged; no Slice 6; no unrelated cleanup.

**Outcome: DONE (merged `--no-ff` + deployed, `8c73e83`); deployed tree byte-identical to the audited candidate; prod migrations remain 129; provenance DATA byte-identical; Stripe DORMANT.** External Paid Authentication Intake **Slice 5 is deployed; the overall capability remains OPEN (Stripe activation + Slice 6 pending).** See `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE5-IMPLEMENTATION.md`.

# SCA Stripe webhook amount/currency hardening (R1) — merge + governed deploy result (Stripe DORMANT)

**Date:** 2026-10-08 · **Status: ✅ DONE — merged `--no-ff` + deployed (no migration; prod stays 129). Post-deployment verification PASS. Stripe remains DORMANT. No credentials entered; no runtime launched; no real/test payment.** Authorized after ChatGPT Phase-2 candidate PASS of head `c0c92816bd5fe376c77ecdc544c88a32a901879a` (base `8c73e83d971486a541223c817a8c63c1a275f8e0`).

## SHAs
- **Approved candidate:** `c0c92816bd5fe376c77ecdc544c88a32a901879a`
- **Base / deployed-from:** `8c73e83d971486a541223c817a8c63c1a275f8e0`
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `7ff176c4b36d0eba805e296d83326f6d0f998fc1`**

## Merge gate — all PASS
candidate SHA unchanged (`c0c92816`); `origin/main` == merge-base == `8c73e83` (audited base); candidate diff = exactly the 2 approved files (`StripeWebhookService.php`, `StripePaymentTest.php`); **0 migrations**; no unrelated changes. **Merged tree is file-identical to candidate `c0c92816`** (`git diff c0c92816 7ff176c --` → empty).

## Deploy (`scripts/deploy-preview.sh`)
`git reset --hard origin/main` → `7ff176c`; SCA gate on `sca_domain_test` **985 passed / 5221 assertions** (includes `StripePaymentTest` 26, `PaymentGuardMigrationTest` 2, `SubmissionDomainTest`/concurrency guards); `migrate --force` → nothing to migrate (**129 → 129**); memory-capped rebuild + `docker compose up -d` (sca project only); `--no-dev` prune; caches cleared; healthy; `GET /admin/login → 200`; `Deployed main @ 7ff176c`. (No QR flake.)

## Candidate → deployed tree comparison
`git diff c0c92816 7ff176c --` → **IDENTICAL** (zero file differences); deployed `StripeWebhookService` contains the audited `amountCurrencyMatches()` validator (grep = 2: definition + call).

## Migrations before/after
**129 → 129** (no migration ran).

## Test results (deploy gate, disposable DB)
- Focused `StripePaymentTest` **26 / 98** (incl. R1: `a1` exact-match succeeds; `a2`×4 wrong/missing amount+currency → not succeeded + no advance + zero provenance + acknowledged 200; `a3` replay idempotent; `a4` currency-case normalized).
- Payment concurrency + migration guard: `StripePaymentTest::c1–c4` + `PaymentGuardMigrationTest` 2 — green.
- **Full governed SCA regression: 985 passed / 5221 assertions**, exit 0.

## Production invariants — all PASS
| Check | Result |
|---|---|
| deployed HEAD == merge SHA | `7ff176c4b36d0eba805e296d83326f6d0f998fc1` |
| migration level | **129** |
| R1 validator deployed | `amountCurrencyMatches()` present (verified in deployed `StripeWebhookService`) |
| `STRIPE_ENABLED` | false/absent |
| `STRIPE_SECRET` | **UNSET** |
| `STRIPE_WEBHOOK_SECRET` | **UNSET** |
| external `/sca/stripe/webhook` | **404** (edge unadmitted) |
| Stripe Checkout session initiated | none |
| payment / Stripe receipt created by deploy | none (payments 0, receipts 0) |
| provenance DATA unchanged | DATA fingerprint byte-identical pre/post = `84e6339ecd6947ba5cfbd1efa6c86423` (items 3 / certs 4 / auth 4 / ownership 5 / claims 2 / grants 1 / sale 1) |
| submission/payment operational data unchanged | submissions 0, payments 0, receipts 0 |
| `MAIL_MAILER` | **log** |
| Shopify unsigned webhook | **401** (still rejects) |
| Caddy / DNS | unchanged |
| external `:8080` | **000** (inaccessible) |
| collector/passport surfaces | `/p/{bogus}` 404 · `/collector` 302 · `/collector/submissions` 302 · `/storage` 404 · smsrocket 302 |

## R1 deployment confirmation (no manufactured webhook)
The audited amount/currency snapshot validation is present in the deployed `StripeWebhookService` (`amountCurrencyMatches`), and its behavior is proven by the disposable-DB regression (`StripePaymentTest::a1–a4`). No production webhook was manufactured to test it (the automated regression is the gate).

**Outcome: DONE (merged `--no-ff` + deployed, `7ff176c`); deployed tree file-identical to the audited candidate; prod migrations 129 (no migration); provenance DATA byte-identical; Stripe DORMANT at both the edge (404) and the app (fail-closed without secret).** The real Stripe Test-Mode dry-run is the NEXT SEPARATE GATE. See `docs/SCA-STRIPE-TEST-MODE-PHASE2.md`.

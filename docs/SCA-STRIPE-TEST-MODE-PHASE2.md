# SCA Stripe Test Mode — Phase 2 — isolated-runtime design + R1 webhook amount/currency hardening candidate

**Date:** 2026-10-08 · **Status: PREPARATION ONLY. Part 1 = isolated-runtime DESIGN (not launched). Part 2 = R1 hardening CANDIDATE branch (tested, NOT merged/deployed). NO Stripe credentials present/entered; NO real/test payment; production UNCHANGED + Stripe DORMANT.** Production baseline `8c73e83d971486a541223c817a8c63c1a275f8e0`, migrations **129**. For ChatGPT audit. STOP before entering credentials / running Stripe.

---

## Part 1 — Isolated Stripe Test-Mode runtime (DESIGN; not executed here)

**Architecture:** `Stripe Test Mode → Stripe CLI (operator) → isolated SCA test runtime (distinct loopback port, disposable DB) → sca_domain_test`. The production runtime on `127.0.0.1:8080` (DB `sca_krayin`) is **never** the target and is not modified.

- **Exact test runtime service/port:** a **separate PHP process inside the existing `app` container** bound to **`127.0.0.1:8099`** (distinct from prod `:8080`), with an **env override `DB_DATABASE=sca_domain_test`** and the test Stripe vars set **only in that process's ephemeral environment** (never `app/.env`). Example (operator-gated; NOT run now):
  ```
  docker compose exec -u 33:33 \
    -e DB_DATABASE=sca_domain_test -e HOME=/tmp \
    -e STRIPE_ENABLED=true -e STRIPE_SECRET=sk_test_… -e STRIPE_WEBHOOK_SECRET=whsec_… \
    app php artisan serve --host=127.0.0.1 --port=8099
  ```
  then (operator) `stripe listen --forward-to http://127.0.0.1:8099/sca/stripe/webhook` in Stripe **test** mode.
- **Exact disposable database:** **`sca_domain_test`** (the synthetic hard-guard test DB; same MariaDB container, separate schema, no real customer/provenance data). Prod `sca_krayin` is not touched.
- **Safeguards proving it cannot use the production DB (fail closed):**
  1. **Distinct port + loopback only** — `:8099`, never added to Caddy, never publicly exposed; prod `:8080` serves `sca_krayin` and is left alone.
  2. **Explicit DB override** — the test process sets `DB_DATABASE=sca_domain_test`; it does not inherit prod's `sca_krayin`.
  3. **Fail-closed DB preflight (required before any Stripe traffic):** run, and refuse to proceed unless it prints the disposable DB:
     ```
     docker compose exec -u 33:33 -e DB_DATABASE=sca_domain_test -e HOME=/tmp app \
       php artisan tinker --execute="\$db=DB::connection()->getDatabaseName(); abort_if(\$db!=='sca_domain_test', 500, 'REFUSE: wrong DB '.\$db); echo 'OK '.\$db;"
     ```
     If the runtime cannot prove it is on `sca_domain_test`, it does not start / the dry-run does not begin.
  4. **Credentials ephemeral** — `sk_test_`/`whsec_` live only in the launched process env for the dry-run and are reverted after; never written to `app/.env`, Git, governance, logs, or test output (only SET/UNSET is ever recorded).
  5. **No Caddy/DNS change** — delivery is via the operator's Stripe CLI forwarder to loopback `:8099`, not the public edge; the production Stripe env stays absent (`enabled=false`).
- **Not executed in Phase 2** — this is the design + the exact commands; running it requires operator-supplied test credentials and explicit approval (Part 4 STOP).

---

## Part 2 — R1 webhook amount/currency hardening (candidate)

### Candidate identity
- **Branch:** `origin/feat/sca-stripe-webhook-amount-hardening`
- **Base SHA (= deployed `main`):** `8c73e83d971486a541223c817a8c63c1a275f8e0`
- **Head SHA:** `c0c92816bd5fe376c77ecdc544c88a32a901879a` (1 commit)
- **Migrations:** **0** (code-only; stays **129**). No migration necessary — no schema reason discovered.

### What changed
In `StripeWebhookService`, the success branch (`checkout.session.completed` / `async_payment_succeeded` with `payment_status=paid`) now, **before** marking the payment `succeeded`, verifies the Checkout Session's authoritative values against the stored snapshot via a new `amountCurrencyMatches($object, $payment)` helper:
- `amount_total` (integer minor units) **==** `sca_authentication_payments.amount_cents`;
- `currency` (lowercase-normalized both sides) **==** stored payment currency;
- the payment is already resolved by the session id (`provider_session_id`), so it IS the expected session.

**Fail-closed behavior:** a signed event with a **missing** `amount_total`, **missing** `currency`, **mismatched** amount, or **mismatched** currency does **NOT** mark the payment succeeded and does **NOT** advance the submission. The event is **ACKNOWLEDGED** — the receipt is still recorded (idempotent) and the controller returns **HTTP 200** — so a *permanent* semantic mismatch cannot become an uncontrolled Stripe retry storm (a 5xx would). The payment simply **stays `pending`**. No new payment status, no provenance, no architecture change. Idempotency (event-id INSERT gate), concurrency (row lock + `UNIQUE(active_pending)`), refunds, and the existing matched-success flow are unchanged.

### Exact changed files (2 modified, 0 migrations)
- `packages/Sca/Provenance/src/Services/StripeWebhookService.php` — `amountCurrencyMatches()` + the pre-success check.
- `tests/Feature/Sca/StripePaymentTest.php` — R1 tests + existing success events updated to carry matching `amount_total`/`currency`.

### Required regression coverage (all green)
`StripePaymentTest` **26 passed / 98 assertions**:
- `a1` exact amount + currency → succeeds + advances.
- `a2` (`#[DataProvider]` ×4): **wrong amount**, **wrong currency**, **missing amount**, **missing currency** → each: payment NOT succeeded (stays `pending`), submission NOT advanced (`submitted`), **zero provenance** (fingerprint unchanged), event acknowledged (200, one receipt) — no retry storm.
- `a3` valid replay still idempotent (one receipt, succeeded, advanced).
- `a4` currency case normalized (`USD` matches stored `usd`).
- Existing: `p8` success advances; `p10` failure/expiry no advance; `p12` refund preserves history; `p9`/`c4` duplicate idempotent; `c1`/`c2` concurrency guard; `p15` zero provenance — all remain green (success events updated with matching amount/currency).

Maps to the task's required proofs: 1 (`a1`), 2–5 (`a2`×4), 6–7 (`a2`), 8 (`a2` fingerprint + `p15`), 9 (`a3`/`p9`/`c4`), 10 (`c1`/`c2`), 11 (`p12`), 12 (`p8` + full suite).

- **Full governed SCA regression:** **985 passed / 5221 assertions**, exit 0 (978 baseline + 7).

### Production verification (post-restore)
Live tree restored to `main` @ `8c73e83`; vendor re-pruned `--no-dev`; caches cleared. Candidate code absent on main (0 `amountCurrencyMatches` occurrences). Prod migrations **129**; provenance counts byte-identical (items 3 / ownership 5); `config('sca-stripe.enabled')=false`; external `POST /sca/stripe/webhook` → **404**; `MAIL_MAILER=log`. No production mutation, no deploy, Stripe DORMANT.

---

## Part 3 — Test credentials
**None present or entered.** No `sk_`/`whsec_` material exists in Git, governance, `app/.env`, logs, or test output (grep-confirmed). The operator will supply `sk_test_…` + the Stripe-CLI/test endpoint `whsec_…` later, securely, into the **ephemeral test-runtime process env** only. Governance records SET/UNSET only. Current: **STRIPE_SECRET = UNSET, STRIPE_WEBHOOK_SECRET = UNSET.**

## Part 4 — STOP (no real Stripe yet)
Phase 2 stops before entering credentials / initiating Checkout. The isolated runtime is designed (Part 1) and the R1 safety hardening is a tested candidate (Part 2). **Awaiting ChatGPT audit** of the R1 candidate + operator provisioning of test credentials before launching the isolated runtime and running the real Test-Mode dry-run.

## Prohibited — confirmed NOT done
No Stripe credentials on production; `STRIPE_ENABLED` not set on production (absent → false); no Checkout run; no `sk_live_`; no real charge; no Caddy/DNS change; no Slice 6; no SMTP; no unrelated changes; R1 candidate NOT merged/deployed. **Production remains Stripe DORMANT.**

**STOP for ChatGPT audit.** See `docs/SCA-STRIPE-TEST-MODE-PHASE1-PREPARATION.md`, `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE4-*`.

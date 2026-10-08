# SCA Stripe Test Mode — Phase 1 (Preparation) — inspection + readiness + STOP for test-environment provisioning

**Date:** 2026-10-08 · **Status: PREPARATION ONLY — read-only inspection complete; NO production config/Caddy/DNS/.env change; NO Stripe credentials present or entered; NO real or test payment initiated; Stripe remains DORMANT.** Production baseline `8c73e83d971486a541223c817a8c63c1a275f8e0`, migrations **129**, governance base `d9f6c2dd447485c7bcd0bc78db011d4f0d642110`. For ChatGPT audit. **STOP for approval before any production activation** (per the task's STOP conditions).

## Headline
The deployed Stripe Checkout code is complete and **fully exercised by a deterministic in-process test harness** (`StripePaymentTest` 19 + `PaymentGuardMigrationTest` 2, in the disposable `sca_domain_test` DB, with faked Stripe HTTP + a test signing secret). However, a **real Stripe Test-Mode** run (actual hosted Checkout + actual Stripe-signed webhook over the wire) **cannot be performed now**: (1) **no `sk_test_`/`whsec_` test credentials are available** (none present anywhere; the operator must supply them securely), and (2) there is **no webhook-reachable isolated environment** — the only separate DB (`sca_domain_test`) shares the prod MariaDB container and is not internet-reachable, the edge does **not** admit `POST /sca/stripe/webhook` (external → 404), and **production Caddy changes are explicitly prohibited** in this task. Two of the task's own STOP conditions apply ("a required secret is missing"; "if an isolated environment is unavailable, document the safest alternative and STOP"). **Stopping for provisioning + approval.**

## Phase A — inspection (read-only; confirmed against deployed code)

### 1. Checkout implementation (`StripeCheckoutService`)
Stripe-hosted Checkout only (no raw card data). `createOrReuseSession(submission, collectorId)`: fails closed unless `config('sca-stripe.enabled')` AND a secret key; asserts owner + submission status `submitted`; **serializes per-submission under a `lockForUpdate` row lock**; reuses an existing pending session (no duplicate active session); snapshots the authoritative price; creates the session server-side via `POST {api_base}/v1/checkout/sessions` (Guzzle); inserts a `pending` payment with `active_pending = submission_id` (the one-pending guard). `unit_amount`/`currency` are set **server-side** from `SettingsService` (the customer cannot alter them).

### 2. Webhook verification + handling (`StripeWebhookService` + `StripeWebhookController`)
Unauthenticated `POST /sca/stripe/webhook`, authenticated by **Stripe's officially-documented signature scheme** over the raw body (parse `Stripe-Signature` `t`/`v1`, `HMAC-SHA256("t.payload", signing_secret)`, constant-time compare, timestamp tolerance = 300s) before parsing. Idempotency gate = the **UNIQUE `event_id` INSERT** (insert-first → apply; concurrent/replayed duplicate → `1062` → clean `duplicate`/200). Mapping: `checkout.session.completed|async_payment_succeeded` + `payment_status=paid` → payment `succeeded` (once; never downgraded) + advance submission **only `submitted → awaiting_item`**; `expired` → `expired`; `async_payment_failed|payment_intent.payment_failed` → `failed`; `charge.refunded|refund.created` → `refunded` (history preserved, no auto outcome). `active_pending` released on succeeded/failed/expired.

### 3. State transitions + idempotency
Payment `pending → succeeded|failed|cancelled|expired|refunded` (CHECK). Advance is webhook-driven only; late/out-of-order never downgrades; double-click/concurrent `/pay` cannot create two usable sessions (row lock + `UNIQUE(active_pending)`); duplicate webhook is idempotent. Ownership is still created ONLY by the canonical grant→claim path (Slice 5) — payment just advances the submission.

### 4. Caddy webhook admission (current)
The edge does **NOT** admit `POST /sca/stripe/webhook` — external request → **404** (verified). Only `/p/*`, `/collector/*`, `/admin` (staff-IP), and the Shopify webhook path are admitted. kr-app is loopback-only (`127.0.0.1:8080`). **No Caddy change is made or proposed here.**

### 5. Production environment configuration (verified; SET/UNSET only)
`STRIPE_ENABLED` absent (→ false), `STRIPE_SECRET` absent, `STRIPE_WEBHOOK_SECRET` absent, `STRIPE_API_BASE` absent (→ `https://api.stripe.com`), `STRIPE_SIGNATURE_TOLERANCE` default 300. `MAIL_MAILER=log`. Runtime `config('sca-stripe.enabled') = false`. **No `sk_`/`whsec_` material exists anywhere in `app/.env` or `config/`** (grep-confirmed). Prod DB `sca_krayin`; disposable test DB `sca_domain_test`.

### 6. Available isolated testing environment
**None suitable for real Stripe webhooks.** `sca_domain_test` is a separate DB with synthetic data (good for the in-process suite) but shares the prod MariaDB container and is not internet-reachable; nothing can receive a real Stripe webhook without either the prohibited Caddy admission or an operator-run forwarder (e.g. Stripe CLI `stripe listen --forward-to http://127.0.0.1:8080/sca/stripe/webhook`).

### 7. Existing payment regression tests
`tests/Feature/Sca/StripePaymentTest.php` (19/94) + `PaymentGuardMigrationTest.php` (2) — deterministic, fake Stripe HTTP (`Http::fake`) + a test signing secret, in `sca_domain_test`. Green at the deployed SHA on the Slice-5 deploy gate (full suite **978 / 5187**).

### 8. Rollback / recovery
Dormant by default: `STRIPE_ENABLED` false/unset + secrets unset ⇒ checkout fails closed (no session) and the webhook rejects everything (no signing secret, 400). Rollback from any future test activation = restore `app/.env` from a 0600 backup (unset `STRIPE_*`) + `php artisan config:clear` (uid 33:33); no schema/data touched (fully reversible). No Caddy admission exists to revert.

**Exact configuration requirements to run Test Mode (env-only; no code change):**
```
STRIPE_ENABLED=true
STRIPE_SECRET=sk_test_…            # operator-entered on the server; never committed/logged
STRIPE_WEBHOOK_SECRET=whsec_…      # the TEST endpoint's signing secret
# STRIPE_API_BASE stays https://api.stripe.com (test keys select test mode)
```
plus a webhook-reachable path for `POST /sca/stripe/webhook` (Stripe CLI forward to loopback, or an isolated host) — **NOT** a production Caddy change in this phase.

## Phase B — establish test environment → **BLOCKED / STOP**
Cannot proceed safely now: no `sk_test_`/`whsec_` supplied; no webhook-reachable isolated environment that avoids a prohibited production Caddy change. **Safest alternative (recommended, operator-gated):** operator provisions Stripe **test** keys and runs the real Test-Mode dry-run via **Stripe CLI `stripe listen --forward-to http://127.0.0.1:8080/sca/stripe/webhook`** (forwarding real Stripe-test-signed events to the loopback app) with `STRIPE_ENABLED=true` + the test `sk_test_`/`whsec_` set **only in `app/.env` on the server for the duration of the dry-run**, backed up and reverted after. This needs **no production Caddy/DNS change** and touches no prod provenance (synthetic collector + submission only). It requires explicit approval + operator-supplied secrets — **STOP here for that.**

## Phase C — payment scenarios: coverage map (deterministic harness today vs real-Stripe pending)
| # | Scenario | Automated coverage (simulated, `sca_domain_test`) | Real-Stripe-mode |
|---|---|---|---|
| 1 | Collector creates submission | `CollectorSubmissionUxTest`, `SubmissionDomainTest` | n/a (no Stripe) |
| 2 | Correct fee displayed | `StripePaymentTest::p1` (snapshot 4900/usd) + collector show fee | — |
| 3 | Checkout session created | `p1` (server-side create, faked HTTP) | **pending** (real `/v1/checkout/sessions`) |
| 4 | Successful test payment | `p8` (simulated paid) | **pending** (real test card) |
| 5 | Valid signed webhook received | `p8` (test-secret-signed) | **pending** (real Stripe signature) |
| 6 | Payment marked successful | `p8` | pending |
| 7 | Advances to `awaiting_item` | `p8`, `p15` | pending |
| 8 | Failed payment no advance | `p10` | pending |
| 9 | Cancelled Checkout no advance | cancel → no webhook → stays pending (informational return page); `p10` | pending |
| 10 | Expired Checkout handled | `p10` (expired→expired) | pending |
| 11 | Duplicate webhook idempotent | `p9`, `c4` | pending |
| 12 | Concurrent no duplicate sessions | `c1` (DB guard), `c2` (reuse-under-contention) | pending |
| 13 | Invalid signature rejected | `p7` (invalid/wrong/stale), `p13` (no secret) | pending |
| 14 | Wrong amount rejected | **by construction** — `unit_amount` fixed server-side; customer cannot alter it (see risk R1) | pending |
| 15 | Wrong submission association rejected | **by construction** — payment bound to our server-created session id + submission at creation; webhook resolves by that id | pending |
| 16 | Refund preserves history | `p12` | pending |
| 17 | No payment event creates provenance | `p12`, `p15` (fingerprint) | pending |
| 18 | No real payment | guaranteed (dormant; no creds) | — |

## Phase D — end-to-end lifecycle
Covered in two deterministic halves today: payment→`awaiting_item` (`StripePaymentTest`) and custody→authentication→certification→grant→**explicit collector claim**→My Collection (`ExternalIntakeResultClaimTest`, Slice 5). A single **real-Stripe** end-to-end run (submission → real test payment → … → claim) is **pending** the test environment + credentials. Ownership is created only by the canonical claim workflow (confirmed by `ExternalIntakeResultClaimTest::r9`).

## Phase E — regression + security (current)
Full governed SCA regression at the deployed SHA = **978 passed / 5187 assertions** (Slice-5 deploy gate, includes the payment suite). Shopify claim, collector auth, grant claims, and provenance invariants intact. **Production unchanged** by this phase.

## Phase F — governance / remaining risks / exact production state
- **Environment used:** read-only inspection on the deployed host; the deterministic in-process suite runs in `sca_domain_test` (synthetic). No real Stripe environment used.
- **Remaining risks / decisions for the real dry-run:** **R1 (defense-in-depth):** the webhook does not currently re-assert `amount_total`/`currency` on `checkout.session.completed` against the snapshot — amount integrity rests on server-side session creation (robust for hosted Checkout). Consider adding a snapshot-match assertion before marking `succeeded` as belt-and-suspenders. **R2:** a webhook-reachable path for the dry-run must avoid a production Caddy change (use the Stripe CLI forwarder). **R3:** secrets must be entered only on the server and reverted after the dry-run.
- **Rollback:** restore `app/.env` (unset `STRIPE_*`) + `config:clear`; fully reversible; no schema/data impact.
- **Exact production state (unchanged):** deployed `8c73e83`, migrations **129**, `STRIPE_*` absent, `config('sca-stripe.enabled')=false`, external `/sca/stripe/webhook` → 404, `MAIL_MAILER=log`; no Caddy/DNS change; no payment initiated.

## STOP
Phase A complete. Phase B blocked (no test credentials + no safe webhook-reachable isolated environment without a prohibited Caddy change). **No production config/Caddy/DNS/.env change made; no credentials present or entered; no real/test payment initiated; Stripe DORMANT.** Awaiting ChatGPT audit + operator provisioning of Stripe **test** credentials and an agreed safe dry-run path (Stripe CLI forwarder) **before** any activation. Explicitly NOT done: Live Mode, real charges, production Caddy change, production Stripe activation, Slice 6, SMTP.

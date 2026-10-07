# SCA External Paid Authentication Intake — Slice 4 (Stripe Checkout Payment) — implementation candidate (NOT merged/deployed/activated)

**Date:** 2026-10-07 · **Status: IMPLEMENTED + TESTED (TEST MODE) + PUSHED on a candidate branch. NOT merged, NOT deployed, Stripe NOT activated. Live tree restored to `main`; production byte-identical (prod stays 125 — new tables ABSENT).** For ChatGPT candidate audit. Approved: Slice 4 (Stripe Checkout, $49 provisional/configurable).

## Candidate identity
- **Branch:** `origin/feat/sca-external-paid-auth-slice4`
- **Base SHA (= deployed `main`, merge-base):** `1cf070db8e623a947c0b7c30c79b67299d2508fd`
- **Head SHA:** `ac12f470478feeb35a089fa77ec13d8713a0c092` (1 commit)
- **Migrations added:** **3** (additive, new standalone tables) → prod 125 → **128 at a future deploy** (NOT applied to prod; applied only to `sca_domain_test`).

## Preliminary design decision (documented, per the brief)
**SDK vs SDK-free.** On this shared host `composer.json` is **not writable by the app user (uid 33)**, so adding `stripe/stripe-php` would require root-level file ops in the production tree + packagist network — and the codebase already ships an **audited, deployed, SDK-free webhook receiver** (Shopify) using raw-body HMAC + idempotent receipts. **Decision: implement SDK-free**, mirroring that proven pattern:
- **Checkout Sessions** are created **server-side** via the already-present Guzzle/Laravel `Http` client against Stripe's REST API (`POST /v1/checkout/sessions`).
- **Webhook signatures** are verified with Stripe's **officially-documented** scheme — parse `Stripe-Signature` into `t`/`v1`, recompute `HMAC-SHA256("<t>.<rawBody>", signing_secret)`, constant-time compare (`hash_equals`), reject outside a timestamp tolerance (replay guard). This is the exact algorithm `Stripe\Webhook::constructEvent` performs internally.
This is not an unsafe shortcut — it uses officially-documented mechanisms, avoids a risky host-level composer change, and is consistent with the existing audited receiver. **Flagged here for the audit.**

## Boundaries / activation (NOT done here)
Stripe is **not activated**: `STRIPE_ENABLED` defaults false and `STRIPE_SECRET`/`STRIPE_WEBHOOK_SECRET` are UNSET in prod → the checkout service fails closed (no session) and the webhook receiver rejects everything (no signing secret). **Live activation is an operator step** and requires: Stripe account/merchant eligibility confirmed, credentials set in `app/.env`, the Stripe webhook endpoint registered, and the Caddy edge admitting `POST /sca/stripe/webhook` (mirroring the Shopify webhook edge). **None of that is performed in this candidate.** All work tested in **Stripe test mode** (faked HTTP + a test signing secret).

## Data model (3 additive tables; 125→128)
- **`sca_settings`** (DB-backed config — pricing changeable with no code change): `key` PK / `value` / `updated_at`, seeded `external_auth_fee_cents=4900`, `external_auth_currency=usd`. Read by `SettingsService`. Not provenance.
- **`sca_authentication_payments`** (mutable operational, NOT provenance): `submission_id` FK, `provider`, `provider_session_id` UNIQUE, `session_url`, `provider_payment_intent_id`, **`amount_cents`+`currency` SNAPSHOT at creation**, `status` CHECK(`pending|succeeded|failed|cancelled|expired|refunded`), `confirmed_at`, timestamps.
- **`sca_stripe_webhook_receipts`** (idempotency ledger, mirrors Shopify receipts): `event_id` UNIQUE, `type`, `payment_id`, `created_at`. No raw payload / card data stored.

## Services
- **`SettingsService`** — typed getters for the authoritative fee (cents) + currency; `set()` for operator/future-UI changes. Price is PROVISIONAL + configurable; callers snapshot.
- **`StripeCheckoutService::createOrReuseSession`** — fails closed if disabled/no key; asserts **owner** + status **`submitted`**; **snapshots** the authoritative price; **reuses** an existing pending session (no duplicate active session); creates the session server-side; inserts the `pending` payment. Creation advances nothing and touches no provenance.
- **`StripeWebhookService`** — `verifySignature` (documented scheme + tolerance); `process` (idempotent, keyed on Stripe event id, row-locked). Mapping: `checkout.session.completed|async_payment_succeeded` with `payment_status=paid` → payment `succeeded` (once; never downgraded) + advance submission **only `submitted → awaiting_item`**; `checkout.session.expired`→`expired`; `async_payment_failed|payment_intent.payment_failed`→`failed`; `charge.refunded|refund.created`→`refunded` (preserve history, **no** auto outcome/provenance). Late/out-of-order deliveries never downgrade a succeeded payment or a progressed submission.

## Routes / controllers / UI
- **Collector (collector.auth, owner-scoped, throttled):** `POST submissions/{ref}/pay` (`throttle:10,1` → create/reuse session → redirect to Stripe), `GET submissions/{ref}/pay/return` + `GET .../pay/cancel` (INFORMATIONAL — not confirmations). Pay CTA on the submission show (only while `submitted`; shows the DB fee; hidden/"coming soon" when disabled).
- **Public webhook (unauthenticated, signature-authenticated):** `POST /sca/stripe/webhook` → `StripeWebhookController` (registered outside auth/session/CSRF in the Collector provider, like the Shopify receiver; explicit 400/500/200 Responses). This is a provider callback, not a "submission route."
- **Staff (Slice-2 detail):** a read-only **Payment** summary (safe fields only — amount/currency/status/opaque session id/timestamps) and the retained manual advance now labelled an explicit **audited override**, visually distinguished from verified payment (requirement 13).

## Exact changed files (12 new, 7 modified; 3 migrations)
New: 3 migrations; `Collector/src/Config/stripe.php`; `Collector/.../PaymentController.php`, `Collector/.../StripeWebhookController.php`; `Collector/.../views/submissions/pay_return.blade.php`; `Provenance/.../Models/AuthenticationPayment.php`; `Provenance/.../Services/{SettingsService,StripeCheckoutService,StripeWebhookService}.php`; `tests/Feature/Sca/StripePaymentTest.php`.
Modified: `Collector/.../SubmissionController.php` (pay CTA context), `Collector/.../CollectorServiceProvider.php` (config merge + public webhook route), `Collector/.../collector-routes.php` (pay routes), `Collector/.../views/submissions/show.blade.php` (pay CTA), `Provenance/.../SubmissionRejection.php` (+PAYMENT_UNAVAILABLE/NOT_PAYABLE), `Registry/.../SubmissionController.php` (payment summary), `Registry/.../views/submissions/show.blade.php` (payment block + override labelling). **Untouched:** Shopify (API/OAuth/scope/webhook), auth/cert/QR/ownership/grant/claim semantics, SMTP/DNS/co-tenant.

## Security boundaries
- Stripe-hosted Checkout only — **no raw card data** handled/stored.
- Webhook authenticated by **signature over the raw body** before parsing; fails closed with no secret; replay-guarded by timestamp tolerance; idempotent + concurrency-safe (event-id receipt + row locks).
- Collector pay routes **authenticated + owner-scoped** (another collector's ref → explicit 404).
- Payment **never** creates eyewear/QR/cert/ownership/provenance; refund preserves history, triggers no automatic outcome.
- Success advances **only** the eligible submission (`submitted → awaiting_item`), never on failed/expired/cancelled/unverified; late/out-of-order never downgrades.
- No Shopify API/OAuth/webhook/scope change; no SMTP/DNS/co-tenant change.

## Provenance mutation matrix (entire payment lifecycle)
| Artifact | Created by start/success/failure/refund? |
|---|---|
| `sca_eyewear_items` / INTAKE projection | **0** |
| authentication / certification / QR | **0** |
| ownership / claim / external-claim grant | **0** |
| Shopify sale link / service event / status event | **0** |
Proven by `p12` (refund) + `p15` (full lifecycle) — provenance fingerprint over 10 tables byte-identical. Payment only progresses the submission's operational status via the existing centralized transition.

## Tests
- **`StripePaymentTest` — 15 passed / 50 assertions:** `p1` configured price + amount snapshot (immune to later price change); `p2` disabled/unconfigured fails closed; `p3` payment only from `submitted`; `p4` service owner-isolation; `p5` duplicate checkout reuses pending session (no 2nd row); `p6` HTTP pay route owner-scoped (A→B = 404, no payment); `p7` invalid + wrong-HMAC + **stale** signatures rejected (400, no receipt); `p8` valid success advances `submitted→awaiting_item`; `p9` idempotent (replayed event id processed once, single advance); `p10` expiry/failure never advance; `p11` late success never downgrades `received`/succeeded; `p12` refund recorded, history + provenance preserved; `p13` no configured secret rejects webhook; `p14` staff manual override works without payment (distinct); `p15` full lifecycle zero provenance.
- **Full governed gate:** `… -e DB_DATABASE=sca_domain_test … php artisan test tests/Feature/Sca` → **953 passed / 5066 assertions**, exit 0 (938 Slice-3 baseline + 15).

## Production-safety verification (post-restore)
- Live tree restored to `main` @ **`1cf070db8e623a947c0b7c30c79b67299d2508fd`**; vendor re-pruned `--no-dev`; caches cleared.
- **Candidate code absent on `main`:** `StripeWebhookService.php` not on disk; `sca.stripe.webhook` route ABSENT; payment config/exception/provider changes reverted.
- **Prod DB unchanged:** migrations **125**; `sca_authentication_payments` / `sca_settings` **ABSENT**; provenance counts byte-identical (items 3 / certs 4 / ownership 5 …).
- **Live HTTP invariants:** `POST /sca/stripe/webhook` 404 (route absent on main) · `/p/{bogus}` 404 · `/collector` 302 · `/collector/submissions` 302 · `POST /sca/shopify/webhook` 401 (Shopify untouched) · `/storage` 404 · smsrocket 302.
- **`MAIL_MAILER=log`; `STRIPE_SECRET`/`STRIPE_WEBHOOK_SECRET`/`SHOPIFY_API_SECRET` UNSET.** No production mutation, no deploy, Stripe not activated.

## Candidate gate
**NOT merged. NOT deployed. Stripe NOT activated. No production mutation.** Awaiting ChatGPT candidate audit of head `ac12f470478feeb35a089fa77ec13d8713a0c092`.

See `docs/SCA-EXTERNAL-PAID-AUTHENTICATION-INTAKE-DISCOVERY.md`, `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE3-DEPLOY-RESULT.md`.

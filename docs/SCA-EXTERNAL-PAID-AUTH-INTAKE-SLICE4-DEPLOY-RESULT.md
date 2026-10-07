# SCA External Paid Authentication Intake — Slice 4 (Stripe Checkout Payment) — merge + governed deploy result (CODE ONLY; Stripe DORMANT)

**Date:** 2026-10-07 · **Status: ✅ DONE — merged `--no-ff` + deployed CODE ONLY (3 additive migrations; prod 125→128). Stripe NOT activated (dormant/fail-closed). Post-deployment verification PASS. No Stripe credentials/dashboard/Caddy/Shopify/MAIL/DNS/co-tenant change.** Authorized after ChatGPT candidate PASS of head `ac12f470478feeb35a089fa77ec13d8713a0c092` (gov evidence `4710685bff5c29fca74d089b89c589f64bedcabc`).

> **Slice 4 CODE is deployed but Stripe is DORMANT. The overall capability is NOT closed.** Stripe activation (credentials, dashboard webhook registration, Caddy edge admission of `/sca/stripe/webhook`) is a **separate gate, not performed here.** Slice 5 not started.

## SHAs
- **Base / deployed-from:** `1cf070db8e623a947c0b7c30c79b67299d2508fd`
- **Audited candidate head:** `ac12f470478feeb35a089fa77ec13d8713a0c092` (unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `2aedebb734eab15cf26f4e8b43c8a8bc441d90d9`**

## Pre-merge gates (fail-closed) — all PASS
candidate head `ac12f470` unchanged; `origin/main` == merge-base == `1cf070db`; tree clean. Merge diff = exactly the 3 additive migrations + the Slice-4 services/controllers/config/views/tests.

## Migrations before/after
**Before: 125 · After: 128** — exactly the three approved additive migrations: `sca_settings`, `sca_authentication_payments`, `sca_stripe_webhook_receipts`.

## Deploy (`scripts/deploy-preview.sh`)
`git reset --hard origin/main` → `2aedebb`; SCA gate on `sca_domain_test` **953 passed / 5066 assertions**; `migrate --force` → the 3 migrations ran → **128**; memory-capped rebuild + `docker compose up -d` (sca project only); `--no-dev` prune; caches cleared; healthy; `GET /admin/login → 200`; `Deployed main @ 2aedebb`. (No QR flake this run.)

## Database verification — all PASS
| Check | Result |
|---|---|
| deployed HEAD == merge SHA | `2aedebb734eab15cf26f4e8b43c8a8bc441d90d9` |
| migration count | **128** |
| `sca_settings` exists | **PRESENT** |
| `sca_authentication_payments` exists | **PRESENT** |
| `sca_stripe_webhook_receipts` exists | **PRESENT** |
| payment status CHECK | `chk_payment_status` **PRESENT** |
| provider session id uniqueness | `…_provider_session_id_unique` **PRESENT** |
| Stripe event id uniqueness | `…_event_id_unique` **PRESENT** |
| seeded fee | `external_auth_fee_cents` = **4900** (unchanged during deploy) |
| seeded currency | `external_auth_currency` = **usd** |
| payment table rows | **0** |
| Stripe receipt table rows | **0** |
| submission tables rows | `sca_authentication_submissions` **0**, `sca_submission_status_events` **0** |
| no production payment/submission manufactured | confirmed — verification used schema/runtime inspection + loopback probe + the green disposable suite |

## Stripe dormant / fail-closed verification — all PASS
| Check | Result |
|---|---|
| `config('sca-stripe.enabled')` | **false** |
| `STRIPE_SECRET` set | **NO** (UNSET) |
| `STRIPE_WEBHOOK_SECRET` set | **NO** (UNSET) |
| Stripe account/dashboard configuration | none |
| Stripe webhook registration | none |
| Caddy admission of `/sca/stripe/webhook` | **none** — external `POST /sca/stripe/webhook` → **404** (edge does not admit it) |
| app-level webhook fails closed w/o signing secret | **400** (verified via host loopback `127.0.0.1:8080`, bypassing the edge — the route exists but rejects everything with no configured secret) |
| real/test payment from production | none initiated |

## Regression — PASS
Deploy gate **953 passed / 5066 assertions** (938 Slice-3 baseline + 15 `StripePaymentTest`). The Stripe payment tests are green, covering signature rejection (invalid/wrong-hmac/stale-replay), owner isolation, duplicate-session reuse + replay idempotency, successful `submitted→awaiting_item` transition, failure/expiry/cancel non-advance, late/out-of-order non-downgrade, refund history preservation, staff manual-override distinction, and zero-provenance behavior.

## Provenance counts / fingerprint analysis (migration-count vs data mutation)
- **Provenance DATA fingerprint (migration count EXCLUDED):** pre-merge `87247ca349f8747664a3526f9283eade` == post-deploy `87247ca349f8747664a3526f9283eade` — **byte-identical**. No authentication/certification/QR/ownership/claim/Shopify-sale/service/item record changed.
- **Counts unchanged:** items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3.
- The composite fingerprint that folds migration count legitimately moves 125→128 (three new EMPTY operational tables) — **schema-version movement, not data mutation** — which is why the DATA fingerprint is computed independently (as in earlier schema-changing slices). The new payment/settings/receipt tables are not folded by `ProjectionService`.

## Live edge / security checks — all PASS
`POST /sca/stripe/webhook` (external) **404** (not admitted) · `/p/{bogus}` **404** · `/collector` **302** · `/collector/login` **200** · `/collector/submissions` **302** · `/storage/..` **404** · `/admin/sca/submission` **403** (edge staff-IP gate) · `POST /sca/shopify/webhook` **401** (Shopify unsigned rejection, untouched) · external `:8080` **000** (Phase-B loopback) · `smsrocket.io` **302** (co-tenant healthy).

## Shopify / MAIL / co-tenant
Shopify untouched (no API/OAuth/scope/webhook change; unsigned rejection still 401). `MAIL_MAILER=log` unchanged; `STRIPE_*` + `SHOPIFY_API_SECRET` UNSET. No DNS/SMTP/SMS/shipping/Caddy change; smsrocket healthy.

## Boundaries confirmed
No Stripe credentials; no Stripe dashboard config; no Caddy change; no Shopify change; no SMTP/MAIL/DNS/SMS/shipping change; no real payment; no production submission. Only the 3 approved additive migrations applied; price not changed.

**Outcome: DONE (merged `--no-ff` + deployed CODE ONLY, `2aedebb`); provenance DATA byte-identical; prod migrations 125→128; Stripe dormant + fail-closed at both the edge (404) and the app (400 without secret).** External Paid Authentication Intake **Slice 4 code is deployed; Stripe activation is a separate gate; the overall capability remains OPEN (activation + Slices 5–6 pending).** See `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE4-IMPLEMENTATION.md`.

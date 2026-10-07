# NEXT TASK

**STATUS: IN PROGRESS — SCA EXTERNAL PAID AUTHENTICATION INTAKE. Slices 1–4 CODE DEPLOYED + payment concurrency hardening DEPLOYED; Stripe DORMANT; capability OPEN; Stripe activation / Slice 5 / Slice 6 remain unpromoted.**

Updated 2026-10-07.

## Current deployed baseline (authoritative — single source of truth)

- Deployed implementation `main` = **`5b30120488d2d7b9975260a142c540ce0f2b843b`** (impl repo `francisjonee/francisjonee-sca-platform-private`).
- Governance/evidence repo = `francisjonee/Shopify-Jeremy`.
- Prod migrations **129** (payment concurrency hardening: `active_pending` one-pending-per-submission UNIQUE guard, backfilled + fail-closed migration); provenance DATA byte-identical to the long-standing state (items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3; provenance-DATA FP `87247ca3…` with migration count excluded). The payment/settings/submission tables are empty operational tables.
- Public edge LIVE `https://verify.secondchanceauthenticators.com`; `:8080` loopback-only; `SESSION_SECURE_COOKIE=true`; `MAIL_MAILER=log`; `STRIPE_*`/`SHOPIFY_API_SECRET`/provider creds UNSET.

## External Paid Authentication Intake — slice status

Deployed: **Slice 1** (`6588054`, migr 122→124 — submission domain) · **Slice 2** (`c72530e`, migr 124→125 — staff worklist + custody bridge) · **Slice 3** (`1cf070d`, no migration — collector submission UX + status tracking) · **Slice 4** (`2aedebb`, migr 125→128 — Stripe Checkout CODE, **DORMANT**). Slice 4: SDK-free Stripe-hosted Checkout (Guzzle REST session + Stripe's documented signature verification); 3 tables `sca_settings` (DB-backed $49 fee, configurable) / `sca_authentication_payments` (amount+currency snapshot, status machine) / `sca_stripe_webhook_receipts` (event-id idempotency); collector `submission.pay/return/cancel`; public signed `POST /sca/stripe/webhook`; webhook-driven confirmation advances only `submitted→awaiting_item` (never downgrades), refund preserves history, payment creates ZERO provenance; staff payment summary + manual advance = audited OVERRIDE. **DORMANT: fail-closed at the app (400 w/o secret) AND the edge (external webhook 404, not admitted).** Evidence: `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE{1,2,3,4}-{IMPLEMENTATION,DEPLOY-RESULT}.md`, `docs/SCA-EXTERNAL-PAID-AUTHENTICATION-INTAKE-DISCOVERY.md`. **Capability NOT closed.**

**Payment concurrency hardening — DEPLOYED** (`5b30120`, migr 128→129): `active_pending` UNIQUE guard = one pending payment per submission (migration **fails closed** on legacy duplicate-pending + **backfills** existing pending rows before the unique becomes authoritative); `/pay` serialized under a submission row lock; webhook event-id INSERT idempotency gate (concurrent duplicate = clean 200, not a retryable 500). Provenance DATA byte-identical; Stripe stays DORMANT (edge 404 + app 400 w/o secret). Evidence: `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE4-CONCURRENCY-HARDENING-{IMPLEMENTATION,DEPLOY-RESULT}.md`. Full SCA gate **959 passed**.

## Open items (NOT promoted — promote exactly ONE at a time; Claude never starts autonomously)

- **STRIPE ACTIVATION gate (operator-led):** confirm Stripe account/merchant eligibility; set `STRIPE_ENABLED=true` + `STRIPE_SECRET` + `STRIPE_WEBHOOK_SECRET` in `app/.env` (operator enters secrets on the server); register the Stripe dashboard webhook; add Caddy `@`-matcher admission for `POST /sca/stripe/webhook` (mirroring the Shopify webhook edge) + recreate `caddy`; test-mode dry-run first. Do NOT perform without explicit promotion + Jeremy's go.
- **Slice 5** — result/ownership wiring (authentication outcome → on certify, offer/issue the grant to the submitting collector via the existing grant→claim path; result surfaced to the collector).
- **Slice 6** — exceptions/returns (cancel, not-received, wrong-item, counterfeit outcome, disputes, return/lost shipment).
- **Transactional Email / SMTP** — OPEN but PARKED/operator-gated (pre-activation hardening deployed; see `docs/SCA-TRANSACTIONAL-EMAIL-HARDENING-DEPLOY-RESULT.md`). Do not touch without promotion.
- Backlog (`TASK_QUEUE.md`): off-site backup (external) · post-core expansion.

## Most recently CLOSED (do NOT reopen / do NOT start a follow-on without promotion)

- **SCA Shopify Sale / Claim Staff Visibility — CLOSED** (`e4306e99`; read-only; migrations unchanged at the time).
- **SCA Inventory Onboarding / Bulk CSV — CLOSED** (`9760889`).
- **SCA Service / Repair History Staff UX — CLOSED** (zero-code).
- **Shopify Operational Listing SOP — CLOSED** (`1b029fd`).
- **SCA Staff Operational Dashboard / Worklists — CLOSED** (`0f86b4a`).
- **SCA Staff Navigation / Discoverability — CLOSED** (`703fbde`).
- **Production QR/Label Workflow — CLOSED** (`0ca7158`/`4d92ec9`/`30b680f`).
- **SCA Transactional Email pre-activation hardening — DEPLOYED** (`0815ea0`; SMTP activation itself still parked).
- **SCA Shopify Activation — CLOSED** (Phases 0–5).

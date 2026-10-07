# NEXT TASK

**STATUS: IN PROGRESS — SCA EXTERNAL PAID AUTHENTICATION INTAKE. Slices 1–4 CODE DEPLOYED; Stripe DORMANT (activation = separate gate); Slice 5 awaiting promotion.**

Updated 2026-10-07. Deployed: **Slice 1** (`6588054`, migr 122→124) · **Slice 2** (`c72530e`, migr 124→125) · **Slice 3** (`1cf070d`, no migration) · **Slice 4** (Stripe Checkout CODE, `2aedebb`, migr 125→128). Slice 4 added Stripe-hosted Checkout (SDK-free: Guzzle REST session create + Stripe's documented signature verification): 3 tables `sca_settings` (DB-backed $49 fee, configurable), `sca_authentication_payments` (amount/currency snapshot, status machine), `sca_stripe_webhook_receipts` (event-id idempotency); collector `submission.pay/return/cancel`; public signed `POST /sca/stripe/webhook`; webhook-driven confirmation advances only `submitted→awaiting_item` (never downgrades), refund preserves history, payment creates ZERO provenance; staff payment summary + manual advance relabelled audited OVERRIDE. **Stripe is DORMANT: `STRIPE_ENABLED` false + `STRIPE_*` UNSET → fail-closed at the app (400 w/o secret) AND the edge (external webhook 404, not admitted).** Provenance DATA FP byte-identical (`87247ca3…`); all operational tables empty. Evidence: `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE4-{IMPLEMENTATION,DEPLOY-RESULT}.md`. **Capability NOT closed.**

**Separate gate — STRIPE ACTIVATION (operator-led, NOT promoted):** confirm Stripe account/merchant eligibility; set `STRIPE_ENABLED=true` + `STRIPE_SECRET` + `STRIPE_WEBHOOK_SECRET` in `app/.env` (operator enters secrets on the server); register the Stripe dashboard webhook endpoint; add Caddy `@`-matcher admission for `POST /sca/stripe/webhook` (mirroring the Shopify webhook edge) + recreate `caddy`; test-mode dry-run before live. **Do not perform any of this without explicit promotion + Jeremy's go.**

**Next feature slices (NOT promoted):** per the discovery doc §15 —
- **Slice 5** — result/ownership wiring (authentication outcome → on certify, offer/issue the grant to the submitting collector via the existing grant→claim path; result surfaced to the collector).
- **Slice 6** — exceptions/returns (cancel, not-received, wrong-item, counterfeit outcome, disputes, return/lost shipment).

**Promote exactly one item at a time** (an activation gate OR a feature slice). Claude must not activate Stripe, start Slice 5, or start any item autonomously.

**Objective (reference):** let a collector submit a frame they already own to SCA for **paid authentication**, extending (not duplicating) the existing lifecycle. Design in `docs/SCA-EXTERNAL-PAID-AUTHENTICATION-INTAKE-DISCOVERY.md`.

- **Headline:** the entire back half already exists and is origin-neutral — `external_intake` is a first-class `intake_type` **and** `claim_source` wired end-to-end (item→authenticate→certify→QR→staff grant→collector claim→single ownership event→My Collection). Net-new = a **pre-registry front stage**: collector-initiated submission + payment + physical-custody tracking, which on success feeds the existing engine.
- **Provenance boundary: Option D** — a new **mutable** `sca_authentication_submissions` entity holds the pre-registry submission/payment/custody state; the permanent `eyewear_item` is created (via the existing `ItemService::create(external_intake)`) **only at custody acceptance**, so abandoned/unpaid submissions never pollute the append-only registry.
- **Ownership** established only AFTER successful authentication+certification, via the existing grant→claim path (`ClaimService::complete`, single-owner-guaranteed); never overwrites history; failed/inconclusive/counterfeit items never become owned/My-Collection.
- **Payment:** recommend Stripe hosted Checkout (independent of Shopify, serves non-SCE customers, no scope change; webhook mirrors the proven HMAC/idempotent pattern; payment never creates provenance); lean alt = reuse the existing Shopify `orders/paid` webhook with a submission-ref property (zero scope change). **Provider = Jeremy decision.** No Shopify scope/app/webhook change proposed.
- **Classification: B — Medium extension** (new front stage feeding an untouched provenance core), with explicit upper-end RISK on the payment + public-submission dimensions.
- **Slices (dep order):** 0 Jeremy policy/provider decisions → 1 submission entity+state machine → 2 staff worklist + receive-&-create-item bridge → 3 collector submission UX (no payment) → 4 payment (hardest; sequence last) → 5 result/ownership wiring → 6 exceptions/returns.
- **Next gate:** ChatGPT audits this discovery/domain plan. No implementation branch yet; promote individual slices only after audit + Jeremy's §12 policy decisions.

Claude must not start implementation autonomously — this file is at the discovery/plan stage only. (Transactional Email/SMTP remains OPEN but PARKED/operator-gated — see `docs/SCA-TRANSACTIONAL-EMAIL-HARDENING-DEPLOY-RESULT.md`; do not touch it.)

## Most recently CLOSED (do NOT reopen / do NOT start a follow-on without promotion)

- **SCA Shopify Sale / Claim Staff Visibility — CLOSED** (`e4306e99`).
- **SCA Inventory Onboarding / Bulk CSV — CLOSED** (`9760889`).
- **SCA Service / Repair History Staff UX — CLOSED** (zero-code).
- **Shopify Operational Listing SOP — CLOSED** (`1b029fd`).
- **SCA Staff Operational Dashboard / Worklists — CLOSED** (`0f86b4a`).
- **SCA Staff Navigation / Discoverability — CLOSED** (`703fbde`).
- **Production QR/Label Workflow — CLOSED** (`0ca7158`/`4d92ec9`/`30b680f`).
- **SCA Shopify Activation — CLOSED** (Phases 0–5).

## Current deployed baseline

- Deployed implementation `main` = **`0815ea0808b6ceac2bb82d88c891fdedc2b97bda`**
- Migrations **122** (no change — hardening is code/config only); provenance data byte-identical to the long-standing `62b2e42f` state (items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3).
- `MAIL_MAILER=log` (unchanged); `APP_URL=https://verify.secondchanceauthenticators.com`; `:8080` loopback-only; `SESSION_SECURE_COOKIE=true`.

Claude must not start implementation autonomously beyond the operator-gated steps above, and only on explicit promotion.

## Most recently CLOSED (do NOT reopen / do NOT start a follow-on without promotion)

- **SCA Shopify Sale / Claim Staff Visibility — CLOSED** (deployed `e4306e999e3a528a8126f9ede85cdc6d1b44eeac`; prod migrations remain **122**, no schema change). Read-only Option C: item-detail "Sale / claim" tab over `sca_shopify_sale_links` (not-linked / eligible / claimed / revoked_refund / cancelled; current active link + terminal history; safe non-PII fields; owner only as opaque `COL-…`; customer ref & idempotency key never selected); dashboard "Sold — awaiting claim" tile (strict `eligibility_state='eligible'` count, distinct from the unchanged "Certified — unclaimed" tile) drilling to the allowlisted `sale=awaiting_claim` Registry filter (`whereExists`; unknown values ignored). No Shopify API/scope/OAuth/webhook change; no mutation controls. **No second visibility/reconciliation slice.** Evidence: `docs/SCA-SHOPIFY-SALE-CLAIM-STAFF-VISIBILITY-{DISCOVERY,IMPLEMENTATION,DEPLOY-RESULT}.md`.
- **SCA Inventory Onboarding / Bulk CSV — CLOSED** (`976088944de0fd2883f12a0686fafaa708ce8b9e`; prod migrations 120→122).
- **SCA Service / Repair History Staff UX — CLOSED** (zero-code).
- **Shopify Operational Listing SOP — CLOSED** (`1b029fd`).
- **SCA Staff Operational Dashboard / Worklists — CLOSED** (`0f86b4a`).
- **SCA Staff Navigation / Discoverability — CLOSED** (`703fbde`).
- **Production QR/Label Workflow — CLOSED** (`0ca7158`/`4d92ec9`/`30b680f`).
- **SCA Shopify Activation — CLOSED** (Phases 0–5).

## Current deployed baseline

- Deployed implementation `main` = **`e4306e999e3a528a8126f9ede85cdc6d1b44eeac`**
- Migrations **122** (no change this task — read-only visibility feature); provenance data byte-identical to the long-standing `62b2e42f` state (items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3).
- Public edge LIVE: `https://verify.secondchanceauthenticators.com`; `:8080` loopback-only; `SESSION_SECURE_COOKIE=true`.

## Promotion rule

See `TASK_QUEUE.md` → "RECONCILED REMAINING WORK". Remaining candidates (unstarted): SMTP + notifications (external/DNS-gated) · off-site backup (external) · post-core expansion. **NOT promoted here.** Until explicit promotion: **ACTIVE = NONE, NEXT_TASK = NONE.**

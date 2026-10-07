# NEXT TASK

**STATUS: IN PROGRESS (OPERATOR-GATED) — SCA TRANSACTIONAL EMAIL / SMTP. Pre-activation hardening DEPLOYED; SMTP activation NOT started (external/DNS-gated).**

Updated 2026-10-07. The approved **pre-activation security hardening (Recommendation B)** is **merged + deployed** (`0815ea0`): (1) collector reset-URL origin pinned to `config('app.url')` (host-header-poisoning closed), (2) SMTP `verify_peer => false` removed (secure TLS default restored). Prod `MAIL_MAILER=log` unchanged, migrations 122, no email sent, no credentials. Evidence: `docs/SCA-TRANSACTIONAL-EMAIL-HARDENING-{IMPLEMENTATION,DEPLOY-RESULT}.md`. **The capability is NOT closed.**

**Remaining (operator-led, external/DNS-gated — NOT a Claude-autonomous implementation task):** per `docs/SCA-TRANSACTIONAL-EMAIL-SMTP-DISCOVERY.md` §11/§15 —
1. Operator creates Postmark (Transactional stream) + verifies the `send.secondchanceauthenticators.com` sending subdomain (DKIM/Return-Path/SPF, provider-generated values).
2. Operator enters SMTP credentials in `app/.env` on the server + switches `MAIL_MAILER=smtp` (Claude may do the non-secret `.env` edits + `config:clear` while the operator supplies secrets).
3. Run the §12 delivery test matrix (credential-free `Mail::raw` connectivity → SPF/DKIM/DMARC pass → throwaway Forgot-Password), then rollback-to-`log` proven.

**Do not** create Postmark, change DNS, change production MAIL settings, enter credentials, or send email without explicit operator promotion of the activation step. Until then this task waits on operator provisioning.

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

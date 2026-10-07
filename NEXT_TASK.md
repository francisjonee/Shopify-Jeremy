# NEXT TASK

**STATUS: ACTIVE (DISCOVERY/PLAN ONLY) — SCA TRANSACTIONAL EMAIL / SMTP.**

Promoted 2026-10-07. **Stage: discovery + production-readiness plan committed — awaiting ChatGPT audit. NO implementation, NO `.env`/DNS/provider/email/restart change.** Objective: make SCA reliably deliver essential transactional email to collectors; immediate business-critical case = **collector password reset** (built, but undelivered because prod `MAIL_MAILER=log`). Discovery + plan in `docs/SCA-TRANSACTIONAL-EMAIL-SMTP-DISCOVERY.md`.

- **Recommendation: B — small code hardening + configuration.** The reset flow is complete, synchronous (no worker), enumeration-safe, transport-hardened; delivery is a pure `.env`/provider/DNS switch with no functional code change — **except** one security item: the emailed reset-link host is request-derived (`url(route(...,false))`, no `URL::forceRootUrl`) with no app-level `TrustHosts` pin → latent host-header-poisoning (mitigated today only by edge topology: `MAIL_MAILER=log` + `TrustProxies` ignores forwarded-host + loopback-only kr-app behind Caddy Host match). Must pin the host to `config('app.url')` before enabling real delivery.
- **Provider plan:** Postmark over SMTP (no composer change); dedicated sending subdomain `send.secondchanceauthenticators.com` (domain DKIM); DNS = DKIM + Return-Path + subdomain SPF (provider-generated values, none fabricated); DMARC unchanged (relaxed alignment covers subdomain); apex/Shopify/`verify.` untouched (apex has no SPF/MX to break).
- **Hard constraints (verbatim intent):** no prod config change; no provider provisioned; no DNS change; no email sent; no code yet. Secrets entered only by the operator on the server (SET/UNSET recorded, never values). Claim/transfer send no email today (manual links) — enabling SMTP sends nothing for them; automating those is out of scope.
- **Next gate:** ChatGPT audits this discovery/plan. On approval, likely first implementation = the §3 host-pin hardening (candidate→audit→merge→deploy), then operator-led provider/DNS setup + `.env` switch + §12 delivery test matrix.

Claude must not start implementation autonomously — this file is at the discovery/plan stage only.

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

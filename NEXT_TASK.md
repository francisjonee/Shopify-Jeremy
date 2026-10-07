# NEXT TASK

**STATUS: NONE — awaiting promotion.**

Reconciled 2026-10-07. No executable task. ChatGPT/operator promotes exactly one item from `TASK_QUEUE.md` ("RECONCILED REMAINING WORK") into this file before any implementation begins. Claude must not start a feature autonomously.

## Most recently CLOSED (do NOT reopen / do NOT start a follow-on without promotion)

- **SCA Inventory Onboarding / Bulk CSV — CLOSED** (deployed `976088944de0fd2883f12a0686fafaa708ce8b9e`; prod migrations 120→**122**). Registry → Import CSV → preview → confirm; valid/acknowledged-warning rows become INTAKE-only items via `ItemService::create`; two append-only ledger tables give content-hash idempotency + per-row reconciliation/resume; duplicate/unsupported headers + malformed-width rows rejected; 500-row cap; `sca.eyewear.create`; insert-only. Importing real inventory is an operator action; no follow-on slice. Evidence: `docs/SCA-INVENTORY-ONBOARDING-BULK-CSV-{DISCOVERY,IMPLEMENTATION,DEPLOY-RESULT}.md`, `docs/SOP-INVENTORY-ONBOARDING-CSV.md`.
- **SCA Service / Repair History Staff UX — CLOSED** (zero-code; existing capability).
- **Shopify Operational Listing SOP — CLOSED** (`1b029fd`).
- **SCA Staff Operational Dashboard / Worklists — CLOSED** (`0f86b4a`).
- **SCA Staff Navigation / Discoverability — CLOSED** (`703fbde`).
- **Production QR/Label Workflow — CLOSED** (`0ca7158`/`4d92ec9`/`30b680f`).
- **SCA Shopify Activation — CLOSED** (Phases 0–5).

## Current deployed baseline

- Deployed implementation `main` = **`976088944de0fd2883f12a0686fafaa708ce8b9e`**
- Migrations **122**; provenance data fingerprint (at its own migration count) unchanged — items/qr/cert/auth/ownership/status/gallery/projection identical to the long-standing `62b2e42f` provenance state (the 2 new tables are empty operational ledgers).
- Public edge LIVE: `https://verify.secondchanceauthenticators.com`; `:8080` loopback-only; `SESSION_SECURE_COOKIE=true`.

## Promotion rule

See `TASK_QUEUE.md` → "RECONCILED REMAINING WORK (easiest → hardest, 2026-10-06)". Remaining candidates (unstarted): #6 SMTP + notifications (external/DNS-gated) · #7 off-site backup (external) · #8 post-core expansion. **NOT promoted here.** Until explicit promotion: **ACTIVE = NONE, NEXT_TASK = NONE.**

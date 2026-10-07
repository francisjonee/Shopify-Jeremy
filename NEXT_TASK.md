# NEXT TASK

**STATUS: NONE — awaiting promotion.**

Reconciled 2026-10-06. No executable task. ChatGPT/operator promotes exactly one item from `TASK_QUEUE.md` ("RECONCILED REMAINING WORK") into this file before any implementation begins. Claude must not start a feature autonomously.

## Most recently CLOSED (do NOT reopen / do NOT start a follow-on without promotion)

- **SCA Service / Repair History Staff UX — CLOSED (existing production capability; zero-code closure).** Discovery proved the scoped staff record+view workflow was already deployed (append-only events, `sca.eyewear.service` form + item-detail history table, owner-only collector history, no passport exposure). No implementation/merge/deploy. Correction/annotation semantics, evidence/media attachment, and audit-display enrichment are separate optional future features, **not** unfinished work. Evidence: `docs/SCA-SERVICE-REPAIR-HISTORY-STAFF-UX-{DISCOVERY,CLOSURE}.md`.
- **Shopify Operational Listing SOP — CLOSED** (`1b029fd`).
- **SCA Staff Operational Dashboard / Worklists — CLOSED** (`0f86b4a`).
- **SCA Staff Navigation / Discoverability — CLOSED** (`703fbde`).
- **Production QR/Label Workflow — CLOSED** (`0ca7158`/`4d92ec9`/`30b680f`).
- **SCA Shopify Activation — CLOSED** (Phases 0–5).

## Current deployed baseline (unchanged by the zero-code closure)

- Deployed implementation `main` = **`1b029fd981388da76b66d50c7a851f3254aa1e5d`**
- Migrations **120**; provenance fingerprint **`62b2e42fe409b4ec91f3381b35da819e`**
- Public edge LIVE: `https://verify.secondchanceauthenticators.com`; `:8080` loopback-only; `SESSION_SECURE_COOKIE=true`.

## Promotion rule

See `TASK_QUEUE.md` → "RECONCILED REMAINING WORK (easiest → hardest, 2026-10-06)". Remaining candidates (unstarted): #5 inventory onboarding · #6 SMTP + notifications (external/DNS-gated) · #7 off-site backup (external) · #8 post-core expansion. **NOT promoted here.** Until explicit promotion: **ACTIVE = NONE, NEXT_TASK = NONE.**

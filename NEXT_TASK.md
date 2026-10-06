# NEXT TASK

**STATUS: NONE — awaiting promotion.**

Reconciled 2026-10-06. No executable task. ChatGPT/operator promotes exactly one item from `TASK_QUEUE.md` ("RECONCILED REMAINING WORK") into this file before any implementation begins. Claude must not start a feature autonomously.

## Most recently CLOSED (do NOT reopen / do NOT start a follow-on without promotion)

- **SCA Staff Operational Dashboard / Worklists — CLOSED** (deployed `0f86b4af90134de6c60664e16aad440a1d111204`). Read-only "what needs my attention next?" dashboard: counts + drill-downs reusing the projection, the existing Registry filters, and the adverse-status queue. **No second dashboard/worklists slice.** The deferred draft-auth "awaiting finalize" worklist and the precise `qr=missing` Registry filter remain **optional future items only**. Evidence: `docs/SCA-STAFF-OPERATIONAL-DASHBOARD-{DISCOVERY,IMPLEMENTATION,DEPLOY-RESULT}.md`.
- **SCA Staff Navigation / Discoverability — CLOSED** (`703fbde`).
- **Production QR/Label Workflow — CLOSED** (`0ca7158`/`4d92ec9`/`30b680f`).
- **SCA Shopify Activation — CLOSED** (Phases 0–5). Do NOT reopen Phase 4 or Phase 5.

## Current deployed baseline

- Deployed implementation `main` = **`0f86b4af90134de6c60664e16aad440a1d111204`**
- Migrations **120**; provenance fingerprint **`62b2e42fe409b4ec91f3381b35da819e`**
- Public edge LIVE: `https://verify.secondchanceauthenticators.com`; `:8080` loopback-only; `SESSION_SECURE_COOKIE=true`.

## Promotion rule

See `TASK_QUEUE.md` → "RECONCILED REMAINING WORK (easiest → hardest, 2026-10-06)". Remaining candidates (unstarted): #3 Shopify operational listing SOP · #4 service/repair history staff UX · #5 inventory onboarding · #6 SMTP + notifications (external/DNS-gated) · #7 off-site backup (external) · #8 post-core expansion. **NOT promoted here.** Until explicit promotion: **ACTIVE = NONE, NEXT_TASK = NONE.**

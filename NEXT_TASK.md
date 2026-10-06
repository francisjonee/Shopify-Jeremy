# NEXT TASK

**STATUS: NONE — awaiting promotion.**

Reconciled 2026-10-06. There is **no executable task** right now. Claude must not start a feature; ChatGPT/operator promotes exactly one item from `TASK_QUEUE.md` ("RECONCILED REMAINING WORK") into this file before any implementation begins.

## Why this file was reset

The previous contents were the **SCA Shopify Activation — Phase 4 controlled dev-store dry-run** executable instruction. That work is **COMPLETE and CLOSED** (Phases 0–5 all passed), so the Phase 4 instruction is **stale and must not be re-executed**. It has been removed from this file; the full Phase 0–5 audit history is preserved in committed governance evidence (see below) — nothing was lost.

## Recently CLOSED (do NOT reopen or re-execute)

- **SCA Shopify Activation — CLOSED.** Phases 0–5 passed against the existing **SCA Eyewear Registry** app (not rebuilt); scope exactly **`read_orders`**; `orders/paid`, `orders/cancelled`, `refunds/create` operational; real paid-order → claim → shipping-only refund (no-op) → SCA-line refund (append-only `disputed`, ownership preserved) proven; OAuth callback intentionally **retained** (hardened). Evidence: `docs/SCA-SHOPIFY-ACTIVATION-PHASE0.md` … `PHASE4-DRYRUN.md`, `docs/SCA-SHOPIFY-PHASE5-PLAN.md`. **Do NOT reopen Phase 4 or Phase 5.**
- **Production QR/Label Workflow — CLOSED.** Slice 1 single print view (`0ca7158`), Slice 2 batch/sheet printing (`4d92ec9`), Slice 3 print polish (`30b680f`); final closure gov `15f62abec999dd04e3a417cd0c26024a501ec953`. Single + batch label printing complete. PDF export / size presets / cross-page selection / compact variants / printer-specific integrations are **optional future enhancements, not unfinished work**.

## Current deployed baseline

- Deployed implementation `main` = **`30b680f797bdcf0d9bf2e6031c32c4f80c41dfc4`**
- Migrations **120**; provenance fingerprint **`62b2e42fe409b4ec91f3381b35da819e`**
- Public edge LIVE: `https://verify.secondchanceauthenticators.com` (Let's Encrypt); `:8080` retired to loopback; `SESSION_SECURE_COOKIE=true`.

## Promotion rule

See `TASK_QUEUE.md` → "RECONCILED REMAINING WORK (easiest → hardest, 2026-10-06)". ChatGPT/operator promotes **one** item here with explicit authorization. Until then: **ACTIVE = NONE, NEXT_TASK = NONE.**

# SCA TASK QUEUE

This file is the ordered implementation backlog for Second Chance Authenticators.

## Authority and execution rule

- `NEXT_TASK.md` contains the **only executable task**.
- Items in this queue are planned only and are not authorization for Claude to start them.
- Claude must never skip ahead into this queue.
- After ChatGPT audits the current task, ChatGPT may promote exactly one queued item into `NEXT_TASK.md`.
- Every task must produce committed implementation evidence/findings before it can be accepted.

## Status legend

- `ACTIVE` — currently represented by `NEXT_TASK.md`; only one allowed.
- `QUEUED` — planned but not executable.
- `BLOCKED` — cannot begin until dependency is resolved.
- `DONE` — accepted after ChatGPT audit.
- `SUPERSEDED` — intentionally replaced.

> **Reconciliation note (2026-09-24):** this file was reconstructed from committed implementation evidence. Accepted tasks remain governed by their committed task reports and accepted merge SHAs.

---

## COMPLETED — accepted, merged to implementation `main`

- `SCA-KRAYIN-INSTALL-001` — Krayin foundation — **DONE** (merge `4d58551`).
- `SCA-KRAYIN-HARDEN-001` — foundation security hardening — **DONE** (merge `96cf2d0`).
- `SCA-DOMAIN-DESIGN-003` — provenance schema/invariants — **DONE** (merge `11f72ca`).
- `SCA-DEMO-IP-004` — governed living development preview — **DONE**.
- `SCA-DOMAIN-CORE-004` — core migrations/models/services — **DONE**.
- `SCA-ADMIN-ITEMS-005` — eyewear intake/search — **DONE**.
- `SCA-ADMIN-AUTH-006` — authentication + condition grading — **DONE**.
- `SCA-CERT-QR-007` — certification ID + permanent QR identity — **DONE**.
- `SCA-PUBLIC-PASSPORT-008` — public passport surface — **DONE**.
- `SCA-SHOPIFY-CONNECT-009` — least-privilege store connect scaffold — **DONE**; live OAuth/webhooks deferred.
- `SCA-SHOPIFY-SALELINK-010` — paid-order → item sale links — **DONE** (main `58b0d6c`).
- `SCA-COLLECTOR-AUTH-011` — collector authentication — **DONE** (main `500df27`).
- `SCA-CLAIM-012` — QR claim ownership workflow — **DONE** (main `0d69940`).
- `SCA-MY-COLLECTION-013` — collector My Collection portal — **DONE** (merge `ad62c65`).
- `SCA-TRANSFER-014` — collector-to-collector ownership transfer — **DONE** (merge `f27185a`).
- `SCA-SERVICE-015` — append-only service history — **DONE** (merge `bace893`).
- `SCA-LOST-STOLEN-016` — owner-reported lost/stolen/recovered registry status — **DONE** (merge `0ddfc99`).
- `SCA-DOCUMENTS-017` — document/evidence handling — **DONE** (merge `c4f43c2`).
- `SCA-COLLECTOR-PRIVACY-018` — collector PII pseudonymization/anonymization — **DONE** (merge `4eb1b98`).
- `SCA-BACKUP-019` — encrypted backup + restore-proof foundation — **DONE** (merge `3c80c20`); off-server backup deferred.
- `SCA-PRODUCTION-HARDENING-020` — pre-public application hardening — **DONE** (merge `0f5af00`).
- `SCA-STATUS-ADMIN-022` — staff registry-status administration — **DONE** (merge `14b4353`).
- `SCA-CERTIFICATE-PDF-023` — immutable certificate PDF + repair semantics — **DONE** (merge `4716329`).
- `SCA-ADVERSE-RECOVERY-024` — staff recovery of owner-orphaned adverse items — **DONE** (merge `a1ae15d`).
- `SCA-PILOT-HARDENING-025` — pre-pilot application hardening — **DONE** (merge `98a7ef2`).
- `SCA-EXTERNAL-CLAIM-027` — staff-issued external-intake claim entitlement — **DONE** (merge `90cd2dc`).
- `SCA-APP-POLISH-029` — SCA CSRF/current-ownership/root polish — **DONE** (merge `233fa2c`).
- `SCA-EXTERNAL-CLAIM-REVOKE-030` — external claim-grant revocation — **DONE** (merge `6f902f3`).
- `SCA-COLLECTOR-AUTH-CONTEXT-032` — privacy-safe claim/transfer auth context — **DONE** (merge `447093e`).
- `SCA-OWNERSHIP-PROVENANCE-033` — staff ownership provenance history — **DONE** (merge `f9385d7`).
- `SCA-PUBLIC-PASSPORT-PILOT-034` — live-pilot passport validation — **DONE** (merge `2029f09`).
- `SCA-ADMIN-OWNERSHIP-CORRECTION-035` — governed append-only staff ownership correction — **DONE** (merge `cf05b58`; manually pilot-validated Collector #2 → Collector #1).
- `SCA-COLLECTOR-PASSWORD-RECOVERY-037` — collector forgot/reset password (dedicated broker + `sca_collector_password_resets`) — **DONE** (merged+deployed `df80e4b`; real email delivery deferred until SMTP configured).
- `SCA-COLLECTOR-PASSWORD-CHANGE-036` — authenticated collector password change + account-security UX — **DONE** (merge/deployed `f362469`; manually pilot-validated: wrong current rejected, confirmation mismatch rejected, valid change succeeds, old password rejected, new password authenticates, ownership/My Collection preserved).
- `SCA-CERTIFICATION-CORRECTION-038` — governed staff certification **revoke + re-certify (supersede)**, append-only on the canonical certification-event ledger; dedicated `sca.eyewear.certification.correct` ACL; permanent QR identity preserved; Option A public-passport contract preserved (resolver/controller unchanged); **no schema migration** — **DONE** (`--no-ff` merge/deployed `bd5b2e7`; base `df80e4b`, feature `9d1c0e4`; deploy gate 21/99 focused + 498/2113 full; production baseline verified identical before/after).

### Non-code governance / validation activities

- `SCA-PILOT-E2E-026` — read-only end-to-end pilot trace.
- `SCA-PILOT-USABILITY-031` — read-only staff+collector usability audit.
- `SCA-CONTROLLED-PILOT-001` — controlled live pilot on temporary IP; ongoing.
- `SCA-EXPANSION-PLANNING-039` — read-only application expansion audit — **DONE** (accepted; roadmap + SCA-040 selection at `docs/SCA-EXPANSION-PLANNING-039.md`).
- Numbers `021` and `028` were unused.

---

## ACTIVE

- `SCA-STAFF-COLLECTOR-SUPPORT-040` — **ACTIVE** (READ-ONLY privacy-safe staff collector lookup). Implemented + pushed on branch `sca-staff-collector-support-040` (base `bd5b2e7`): `GET admin/sca/collectors` + `GET admin/sca/collectors/{ref}`, dedicated `sca.collector.support` read ACL, canonical owned-items projection, email withheld (not authorized), no schema migration. Focused 11/53; full SCA 509/2166. **Awaiting ChatGPT audit — NOT merged, NOT deployed.** SCA-041 must not start.

_SCA-039 (planning) and SCA-038 (deployed `bd5b2e7`) are DONE. SCA-PRODUCTION-CUTOVER remains BLOCKED/DEFERRED awaiting Jeremy._

## REMAINING BACKLOG (planned only — not authorization to start)

### SCA-PRODUCTION-CUTOVER — Permanent infrastructure & production cutover
**Phase:** 10 — Production
**Status:** BLOCKED / DEFERRED — awaiting Jeremy-provided permanent domain + access. Explicitly does NOT block continued application development (see SCA-EXPANSION-PLANNING-039).
**Depends on:** core provenance product accepted + Jeremy-provided permanent HTTPS domain

Permanent HTTPS/public-QR domain, DNS/Caddy cutover, Shopify live activation, permanent QR printing, production mail delivery configuration where required, temporary pilot exposure retirement, durable off-server backup/restore rehearsal, and production secrets remain infrastructure work and require explicit approval/input.

### SCA-EXPANSION — Post-core expansion planning
**Phase:** 11 — Expansion
**Status:** QUEUED
**Depends on:** production cutover complete

Plan market history/value tracking, collector profiles/privacy, notifications, external paid authentication intake, resale/marketplace concepts, and analytics. Must not block or destabilize the trusted provenance core.

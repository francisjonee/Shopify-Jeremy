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

> **Reconciliation note (2026-09-24):** this file was stale (it showed
> `SCA-MY-COLLECTION-013` as ACTIVE and mis-numbered later phases). It has been
> reconstructed from committed evidence in the implementation repo
> `francisjonee/francisjonee-sca-platform-private`: accepted `--no-ff` merges on
> `main` and committed `docs/task-reports/<TASK_ID>.md`. Each DONE entry cites its
> merge SHA. The actual accepted numbering diverged from the original roadmap
> numbering (e.g. registry-status shipped as `016`, documents as `017`,
> collector-privacy as `018`, backup as `019`, production-hardening as `020`); the
> old queue's `SCA-STATUS-016 / SCA-DOCUMENTS-017 / SCA-PRODUCTION-018 /
> SCA-EXPANSION-019` planning stubs are superseded below.

---

## COMPLETED — accepted, merged to implementation `main` (with evidence)

Foundation / domain / staff / QR / public / Shopify / collector-core (accepted earlier):

- `SCA-KRAYIN-INSTALL-001` — Krayin foundation — **DONE** (merge `4d58551`).
- `SCA-KRAYIN-HARDEN-001` — foundation security hardening — **DONE** (merge `96cf2d0`).
- `SCA-DOMAIN-DESIGN-003` — provenance schema/invariants — **DONE** (merge `11f72ca`).
- `SCA-DEMO-IP-004` — governed living development preview — **DONE** (report `SCA-DEMO-IP-004.md`).
- `SCA-DOMAIN-CORE-004` — core migrations/models/services — **DONE** (report `SCA-DOMAIN-CORE-004.md`).
- `SCA-ADMIN-ITEMS-005` — eyewear intake/search — **DONE** (report `SCA-ADMIN-ITEMS-005.md`).
- `SCA-ADMIN-AUTH-006` — authentication + condition grading — **DONE** (report `SCA-ADMIN-AUTH-006.md`).
- `SCA-CERT-QR-007` — certification ID + permanent QR identity — **DONE** (report `SCA-CERT-QR-007.md`).
- `SCA-PUBLIC-PASSPORT-008` — public passport surface — **DONE** (report `SCA-PUBLIC-PASSPORT-008.md`).
- `SCA-SHOPIFY-CONNECT-009` — least-privilege store connect scaffold — **DONE** (report `SCA-SHOPIFY-CONNECT-009.md`). *Live OAuth/webhook activation intentionally deferred — see Deferrals.*
- `SCA-SHOPIFY-SALELINK-010` — paid-order → item sale links — **DONE** (PR #12 head `5914aab`, main `58b0d6c`).
- `SCA-COLLECTOR-AUTH-011` — collector authentication — **DONE** (PR #13 head `2675d96`, main `500df27`).
- `SCA-CLAIM-012` — QR claim ownership workflow — **DONE** (PR #14 head `b94fce3`, main `0d69940`).

Collector portal / lifecycle / status / documents / privacy / backup / hardening:

- `SCA-MY-COLLECTION-013` — collector My Collection portal — **DONE** (PR #15 merge `ad62c65`, accepted `37925b6`). *(was ACTIVE in the stale queue)*
- `SCA-TRANSFER-014` — collector-to-collector ownership transfer — **DONE** (PR #16 merge `f27185a`, accepted `73347cb`).
- `SCA-SERVICE-015` — append-only service history — **DONE** (merge `bace893`).
- `SCA-LOST-STOLEN-016` — owner-reported lost/stolen/recovered registry status — **DONE** (merge `0ddfc99`).
- `SCA-DOCUMENTS-017` — document/evidence handling (`sca_media_assets`) — **DONE** (merge `c4f43c2`).
- `SCA-COLLECTOR-PRIVACY-018` — collector PII pseudonymization/anonymization — **DONE** (merge `4eb1b98`).
- `SCA-BACKUP-019` — encrypted backup + restore-proof foundation — **DONE** (merge `3c80c20`). *Off-server/off-site backup still deferred — see Deferrals.*
- `SCA-PRODUCTION-HARDENING-020` — pre-public application hardening (loopback binding, real HTTP statuses, etc.) — **DONE** (merge `0f5af00`).

Staff registry administration / certificates / recovery / pilot hardening:

- `SCA-STATUS-ADMIN-022` — staff registry-status administration & exception resolution — **DONE** (merge `14b4353`).
- `SCA-CERTIFICATE-PDF-023` — immutable certificate PDF + repair semantics — **DONE** (merge `4716329`).
- `SCA-ADVERSE-RECOVERY-024` — staff recovery of owner-orphaned adverse items — **DONE** (merge `a1ae15d`).
- `SCA-PILOT-HARDENING-025` — pre-pilot application hardening — **DONE** (merge `98a7ef2`).

External-intake claim family / polish / provenance inspection / passport validation:

- `SCA-EXTERNAL-CLAIM-027` — staff-issued external-intake claim entitlement (grant) — **DONE** (merge `90cd2dc`). *Closed the P0 discovered by the read-only `SCA-PILOT-E2E-026` trace.*
- `SCA-APP-POLISH-029` — SCA CSRF real-419, current-ownership claim messaging, `/collector` root — **DONE** (merge `233fa2c`).
- `SCA-EXTERNAL-CLAIM-REVOKE-030` — staff revocation (issued→void) of external claim grant — **DONE** (merge `6f902f3`).
- `SCA-COLLECTOR-AUTH-CONTEXT-032` — privacy-safe claim/transfer context on collector auth screens — **DONE** (merge `447093e`).
- `SCA-OWNERSHIP-PROVENANCE-033` — read-only staff ownership provenance history — **DONE** (merge `f9385d7`).
- `SCA-PUBLIC-PASSPORT-PILOT-034` — validate existing public passport across the live pilot lifecycle (audit + test only, zero runtime delta) — **DONE** (merge `2029f09`).
- `SCA-ADMIN-OWNERSHIP-CORRECTION-035` — governed append-only staff ownership correction (writes `admin_correction`; adds nullable `sca_ownership_events.reason`) — **DONE** (merge `cf05b58`; manually pilot-validated: Collector #2 → correction → Collector #1, history preserved, passport privacy intact). ← most recent accepted task.

### Non-code governance / validation activities (no merge; evidence is governance/pilot, not implementation `main`)

- `SCA-PILOT-E2E-026` — read-only end-to-end pilot trace; surfaced the external-intake claim gap that became 027. No code change.
- `SCA-PILOT-USABILITY-031` — read-only staff+collector usability audit. No code change; findings informed 032.
- `SCA-CONTROLLED-PILOT-001` — live controlled real-user pilot on the temporary host: one Ray-Ban `PILOT-TEST` (`SCA-F1B792AE4745`) taken through intake→auth→cert→QR→claim (Collector #1)→transfer (Collector #2)→ownership-history→lost→recovered→stolen→recovered/normal, and the public passport verified. Ongoing; no code change. Standing security items it introduced (temporary public exposure + rotated admin credential) are tracked under Deferrals.
- Numbers `021` and `028` were not used for accepted tasks (no report/merge); treat as skipped/superseded numbering, not missing work.

---

## ACTIVE

### SCA-COLLECTOR-PASSWORD-CHANGE-036 — Authenticated collector password change + minimal account-security UX
**Phase:** 6 — Collector Portal
**Status:** ACTIVE (promoted to `NEXT_TASK.md`)
**Depends on:** collector auth (011) accepted

Authenticated collector password change only (current + new + confirm; reuse the collector guard +
registration password policy; regenerate session on success) plus a minimal account-page reorg (Account
security → Change password; Danger zone → anonymize). No display-name edit. Forgot/reset password and
email change remain deferred — mail-infra-gated (`MAIL_MAILER=log`) + a collector broker/reset table.

---

## REMAINING BACKLOG (planned only — not authorization to start)

### SCA-PRODUCTION-CUTOVER — Permanent infrastructure & production cutover  *(recommended next; supersedes the old `SCA-PRODUCTION-018` stub)*
**Phase:** 10 — Production
**Status:** BLOCKED (needs a Jeremy-controlled production domain + credentials; business/infra input)
**Depends on:** core provenance product accepted (satisfied through 034) + Jeremy-provided permanent HTTPS domain

The trusted provenance core is complete and pilot-validated end to end. The dominant remaining product dependency is the **permanent Jeremy-controlled HTTPS/public-QR domain**, which gates permanent QR printing, Shopify live activation, and retiring the temporary-IP pilot exposure. This should begin as a **design/ADR + reversible-prep task** (no live cutover) because the actual DNS/Caddy/Shopify/QR-domain changes require Jeremy's domain and explicit approval. Detailed recommendation in `NEXT_TASK.md`'s recommendation block and the 034 reconciliation report.

### SCA-EXPANSION — Post-core expansion planning  *(supersedes the old `SCA-EXPANSION-019` stub)*
**Phase:** 11 — Expansion
**Status:** QUEUED
**Depends on:** production cutover complete

Plan market history/value tracking, collector profiles/privacy, notifications, external paid authentication intake, resale/marketplace concepts, and analytics. Must not block or destabilise the trusted provenance core.

---

## Outstanding deferrals / production gates (explicit; not changed by this reconciliation)

- **Permanent Jeremy-controlled HTTPS + public QR domain** — deferred since `SCA-CERT-QR-007`/`008`; permanent QR printing stays disabled and `SCA_PUBLIC_PREVIEW=1` (DEVELOPMENT PREVIEW banner) until a production domain is configured. The permanent QR must never bind to a temporary IP/host.
- **Shopify live activation** — `SCA-SHOPIFY-CONNECT-009` live OAuth + webhook registration deferred until a permanent publicly trusted SCA HTTPS endpoint + secure server-side credentials exist.
- **DNS / Caddy** — no production DNS record or reverse-proxy cutover performed; documented path routes the permanent domain to `kr-app` via `sr-caddy` over a shared container network (not the published host port).
- **Durable off-server / off-site backups** — `SCA-BACKUP-019` established encrypted backup + restore proof locally; off-server/off-site durability and a production restore rehearsal remain deferred.
- **Temporary pilot exposure cleanup** — the running pilot app is currently published on `195.26.255.80:8080`, IP-restricted via host firewall rules, for the live controlled pilot. Committed compose stays hardened to loopback. This ad-hoc exposure (and the rotated admin credential) must be retired at production cutover / when the pilot ends.
- **Secrets / credentials** — production secrets management and admin-credential rotation are part of the cutover gate.

---

## Queue maintenance rules

1. ChatGPT updates this file after every audit that changes task ordering, dependencies, status, or architecture.
2. Claude may recommend new tasks in its committed findings report, but must not self-promote them.
3. Security/data-integrity findings take priority over feature work.
4. Any architecture-changing task requires an ADR before implementation.
5. Tasks should remain small enough to audit independently.
6. `ROADMAP.md` describes phases; `TASK_QUEUE.md` describes ordered backlog; `NEXT_TASK.md` describes the single executable unit.

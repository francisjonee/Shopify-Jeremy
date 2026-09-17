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

---

## COMPLETED

### SCA-KRAYIN-INSTALL-001 — Install and validate Krayin foundation
**Phase:** 1 — CRM Foundation
**Status:** DONE

### SCA-KRAYIN-HARDEN-001 — Security hardening of Krayin foundation
**Phase:** 1 — CRM Foundation
**Status:** DONE

### SCA-DOMAIN-DESIGN-003 — Design SCA provenance schema and invariants
**Phase:** 2 — SCA Domain
**Status:** DONE

### SCA-DEMO-IP-004 — Governed living development preview
**Phase:** Delivery / Preview
**Status:** DONE

### SCA-DOMAIN-CORE-004 — Implement core SCA domain migrations and models
**Phase:** 2 — SCA Domain
**Status:** DONE

### SCA-ADMIN-ITEMS-005 — Build physical eyewear intake and search
**Phase:** 3 — Staff Admin
**Status:** DONE

### SCA-ADMIN-AUTH-006 — Build authentication and condition grading workflow
**Phase:** 3 — Staff Admin
**Status:** DONE

### SCA-CERT-QR-007 — Certification ID and permanent QR identity
**Phase:** 4 — Certification / QR
**Status:** DONE

### SCA-PUBLIC-PASSPORT-008 — Public SCA registry/passport
**Phase:** 4 — Public Registry
**Status:** DONE

### SCA-SHOPIFY-CONNECT-009 — Connect live Second Chance Eyewear Shopify store safely
**Phase:** 5 — Shopify Integration
**Status:** DONE

Live OAuth activation/webhook registration remain intentionally deferred until a permanent publicly trusted SCA HTTPS endpoint and secure server-side credentials are available.

### SCA-SHOPIFY-SALELINK-010 — Link paid order lines to exact physical SCA items
**Phase:** 5 — Shopify Integration
**Status:** DONE
**Depends on:** SCA-SHOPIFY-CONNECT-009 PASS

Accepted after ChatGPT audit/remediation. PR #12 accepted head `5914aabeb885ec544c0807d1fddd9ec5ddec6738` merged/deployed to implementation `main` at `58b0d6c8f36ba5d294a52378f5af3b9c0d05cd1c`.

### SCA-COLLECTOR-AUTH-011 — Collector account authentication
**Phase:** 6 — Collector Portal
**Status:** DONE
**Depends on:** stable claim-eligibility model

Accepted after ChatGPT audit. PR #13 accepted head `2675d9620775619aea7009c5258f0bac05fa4c5a` merged/deployed to implementation `main` at `500df276e33f6b102f69154b83c577eae8439d45`. Independent collector registration/login/session/logout is live and remains separate from Krayin staff authentication. Deployment verified zero collector accounts and zero ownership/claim/sale-link side effects.

---

## ACTIVE

### SCA-CLAIM-012 — QR claim ownership workflow
**Phase:** 6 — Claim
**Status:** ACTIVE
**Depends on:** SCA-COLLECTOR-AUTH-011 PASS + SCA-SHOPIFY-SALELINK-010 PASS

Implement scan/sign-in/eligibility verification/claim and append the initial registered ownership event. A Shopify sale alone must never register permanent ownership.

---

## QUEUED

### SCA-MY-COLLECTION-013 — Collector My Collection portal
**Phase:** 6 — Collector Portal
**Status:** QUEUED
**Depends on:** SCA-CLAIM-012 PASS

Show claimed authenticated eyewear, certification/provenance information, service history, and appropriate owner actions in an SCA-branded experience separate from Krayin staff admin.

### SCA-TRANSFER-014 — Ownership transfer lifecycle
**Phase:** 7 — Transfers
**Status:** QUEUED
**Depends on:** registered ownership stable

Implement authenticated transfer initiation/acceptance/cancellation/expiry and append new ownership history without erasing prior owners.

### SCA-SERVICE-015 — Service history
**Phase:** 8 — Lifecycle
**Status:** QUEUED
**Depends on:** ownership/provenance core stable

Implement append-only service events for repair, lens work, polish, tune-up, inspection, and approved service categories.

### SCA-STATUS-016 — Lost/stolen/recovered registry
**Phase:** 8 — Registry Status
**Status:** QUEUED
**Depends on:** ownership/public passport stable

Implement auditable lost/stolen/recovered transitions and public warnings without exposing private owner data.

### SCA-DOCUMENTS-017 — Certificates, provenance, and insurance reports
**Phase:** 9 — Documents
**Status:** QUEUED
**Depends on:** core provenance data stable

Generate versioned authentication certificates, ownership certificates, provenance reports, and insurance-oriented PDFs from trusted registry data.

### SCA-PRODUCTION-018 — Permanent infrastructure and production cutover
**Phase:** 10 — Production
**Status:** QUEUED
**Depends on:** core product acceptance

Harden permanent infrastructure, configure off-server backups/durable media, rehearse restore, configure Jeremy-controlled production QR route, perform DNS/cutover/rollback, and close standing hardening gates before real production use.

### SCA-EXPANSION-019 — Market history, collector profiles, paid external authentication
**Phase:** 11 — Expansion
**Status:** QUEUED
**Depends on:** production core platform stable

Plan post-core features including market history/value tracking, collector profiles/privacy, notifications, external paid authentication intake, resale workflows, marketplace concepts, and advanced analytics.

---

## Queue maintenance rules

1. ChatGPT updates this file after every audit that changes task ordering, dependencies, status, or architecture.
2. Claude may recommend new tasks in its committed findings report, but must not self-promote them.
3. Security/data-integrity findings take priority over feature work.
4. Any architecture-changing task requires an ADR before implementation.
5. Tasks should remain small enough to audit independently.
6. `ROADMAP.md` describes phases; `TASK_QUEUE.md` describes ordered backlog; `NEXT_TASK.md` describes the single executable unit.

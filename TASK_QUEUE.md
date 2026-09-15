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

Accepted after ChatGPT audit and merged into implementation `main`.

### SCA-KRAYIN-HARDEN-001 — Security hardening of Krayin foundation
**Phase:** 1 — CRM Foundation
**Status:** DONE
**Depends on:** SCA-KRAYIN-INSTALL-001 PASS

Accepted after ChatGPT security audit. Standing production gates remain: no real provenance data or production exposure until required backup/public-edge hardening is complete.

### SCA-DOMAIN-DESIGN-003 — Design SCA provenance schema and invariants
**Phase:** 2 — SCA Domain
**Status:** DONE
**Depends on:** hardened Krayin foundation — PASS

Accepted design defines the canonical 16-table SCA provenance model, append-only invariants, lifecycle rules, projection rules, and T1–T31 validation matrix. Implementation PR #3 merged to `main`.

### SCA-DEMO-IP-004 — Governed living development preview
**Phase:** Delivery / Preview
**Status:** DONE
**Depends on:** SCA-DOMAIN-DESIGN-003 PASS

Accepted and merged as PR #4. Implementation merge commit: `640f3d1b70066173f2e6bf681f819357c85396ce`.

### SCA-DOMAIN-CORE-004 — Implement core SCA domain migrations and models
**Phase:** 2 — SCA Domain
**Status:** DONE
**Depends on:** SCA-DOMAIN-DESIGN-003 PASS

Accepted after ChatGPT audit and remediation. PR #5 merged into implementation `main` at `0426bd6f9c9150b7ee728357e2c9c5830c75fc20`. Post-merge preview verification confirmed 16 canonical SCA tables and 22 integrity triggers with Krayin data intact.

### SCA-ADMIN-ITEMS-005 — Build physical eyewear intake and search
**Phase:** 3 — Staff Admin
**Status:** DONE
**Depends on:** SCA-DOMAIN-CORE-004 PASS

Accepted after ChatGPT audit/remediation. PR #6 accepted head `75af06aa0960c9990707b23a21acaf0e6e90b1c1` merged to implementation `main` at `14614d14ce6b35aa0d917a3a4227c474d574f257`.

Post-merge deployment verified on the living preview: SCA Eyewear Registry navigation, list, create, detail, search, real restricted-staff HTTP 403, real nonexistent-item HTTP 404, Foundation/WIP banner, 16 provenance tables, and 22 integrity triggers all pass. MariaDB remains private and the unrelated tenant/ports 80/443 are untouched. One clearly marked `DEMO-DO-NOT-USE` eyewear item is intentionally retained for preview demonstration.

---

## ACTIVE

### SCA-ADMIN-AUTH-006 — Build authentication and condition grading workflow
**Phase:** 3 — Staff Admin
**Status:** ACTIVE
**Depends on:** SCA-ADMIN-ITEMS-005 PASS

Add staff authentication inspection workflow against canonical SCA eyewear items: inspector/grader attribution, append-only authentication result/history, condition grade, inspection notes, approved inspection media references, and appropriate item-detail history/current-state presentation. Authentication and certification remain separate state machines; this task must not issue certifications or permanent QR identities.

**Exit gate:** Claude pushes implementation/report and stops; ChatGPT creates/audits the PR and remediation if needed; after explicit ChatGPT PASS, Claude may perform the governed merge/deployment when authorized; ChatGPT verifies post-merge preview evidence before promoting the next task.

---

## QUEUED

### SCA-CERT-QR-007 — Certification ID and permanent QR identity
**Phase:** 4 — Certification / QR
**Status:** QUEUED
**Depends on:** SCA-ADMIN-AUTH-006 PASS

Implement certification issuance and stable SCA QR identifiers with staging protection. Do not print/publish permanent lifetime QR until the Jeremy-controlled production route is approved.

### SCA-PUBLIC-PASSPORT-008 — Public SCA registry/passport
**Phase:** 4 — Public Registry
**Status:** QUEUED
**Depends on:** SCA-CERT-QR-007 PASS

Build the public verification surface with an explicit privacy allowlist, authenticity/certification status, approved item details, condition summary, provenance summary, registry status, and lost/stolen warning capability.

### SCA-SHOPIFY-CONNECT-009 — Connect live Second Chance Eyewear Shopify store safely
**Phase:** 5 — Shopify Integration
**Status:** QUEUED
**Depends on:** stable SCA physical-item/QR model

Verify exact live Shopify store identity, configure approved least-privilege scopes, install/connect the existing SCA Shopify app, and establish signed/idempotent webhook handling without unnecessary write access.

### SCA-SHOPIFY-SALELINK-010 — Link paid order lines to exact physical SCA items
**Phase:** 5 — Shopify Integration
**Status:** QUEUED
**Depends on:** SCA-SHOPIFY-CONNECT-009 PASS

Implement sale eligibility state, exact physical-item mapping, paid/cancelled/refunded/returned behavior, safe retries, and idempotent Shopify sale links.

### SCA-COLLECTOR-AUTH-011 — Collector account authentication
**Phase:** 6 — Collector Portal
**Status:** QUEUED
**Depends on:** stable claim-eligibility model

Build independent SCA collector accounts and secure sign-in. Shopify customer identity may be linked but must not become the canonical SCA ownership identity.

### SCA-CLAIM-012 — QR claim ownership workflow
**Phase:** 6 — Claim
**Status:** QUEUED
**Depends on:** collector auth + Shopify sale links

Implement scan/sign-in/eligibility verification/claim and append the initial registered ownership event. A sale alone must not register permanent ownership.

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

# SCA TASK QUEUE

This file is the ordered implementation backlog for Second Chance Authenticators.

## Authority and execution rule

- `NEXT_TASK.md` contains the **only executable task**.
- Items in this queue are **planned only** and are not authorization for Claude to start them.
- Claude must never skip ahead into this queue.
- After ChatGPT audits the current task, ChatGPT may promote exactly one queued item into `NEXT_TASK.md`.
- The queue may be reordered when implementation findings, security issues, architecture decisions, or Jeremy's priorities require it.
- Every task must produce committed implementation evidence/findings before it can be accepted.

## Status legend

- `ACTIVE` — currently represented by `NEXT_TASK.md`; only one allowed.
- `QUEUED` — planned but not executable.
- `BLOCKED` — cannot begin until dependency is resolved.
- `DONE` — accepted after ChatGPT audit.
- `SUPERSEDED` — intentionally replaced by another task/architecture decision.

---

## ACTIVE

### SCA-KRAYIN-INSTALL-001 — Install and validate Krayin foundation
**Phase:** 1 — CRM Foundation
**Status:** ACTIVE

Install a pinned MIT-licensed Krayin release on the temporary VPS, prove MySQL/MariaDB persistence, backup/restore, secure admin access, portable deployment, and a clean SCA extension point without modifying vendor core.

**Exit gate:** ChatGPT audits implementation PR, runtime evidence, security findings, backup/restore proof, and committed task report.

---

## QUEUED

### SCA-KRAYIN-HARDEN-002 — Harden and baseline the CRM foundation
**Phase:** 1 — CRM Foundation
**Status:** QUEUED
**Depends on:** SCA-KRAYIN-INSTALL-001 PASS

Apply approved hardening/remediation discovered during installation audit. Establish final staging service exposure, scheduler/queue strategy if required, logging, update policy, database backup automation design, and baseline operational runbook.

### SCA-DOMAIN-DESIGN-003 — Design SCA provenance schema and invariants
**Phase:** 2 — SCA Domain
**Status:** QUEUED
**Depends on:** hardened Krayin foundation

Define and document the exact SCA domain schema and state machines for physical eyewear, authentication, certification, QR identity, ownership, transfer, service, status, collector identity, and Shopify sale linkage. No UI-first shortcuts and no collapsing provenance into generic CRM records.

### SCA-DOMAIN-CORE-004 — Implement core SCA domain migrations and models
**Phase:** 2 — SCA Domain
**Status:** QUEUED
**Depends on:** SCA-DOMAIN-DESIGN-003 PASS

Implement version-controlled SCA migrations/models/services with append-only provenance rules, uniqueness constraints, current-state derivation, and automated tests.

### SCA-ADMIN-ITEMS-005 — Build physical eyewear intake and search
**Phase:** 3 — Staff Admin
**Status:** QUEUED
**Depends on:** SCA-DOMAIN-CORE-004 PASS

Add SCA staff module screens for creating/searching uniquely certified physical eyewear records and mapping optional Shopify product/variant/SKU references.

### SCA-ADMIN-AUTH-006 — Build authentication and condition grading workflow
**Phase:** 3 — Staff Admin
**Status:** QUEUED
**Depends on:** SCA-ADMIN-ITEMS-005 PASS

Add authentication result, grader/inspector, inspection notes, condition grade, inspection media references, audit events, and immutable historical inspection behavior.

### SCA-CERT-QR-007 — Certification ID and permanent QR identity
**Phase:** 4 — Certification / QR
**Status:** QUEUED
**Depends on:** authentication workflow PASS

Implement certification issuance and stable SCA QR identifiers with staging protection. Do not print/publish permanent lifetime QR until the Jeremy-controlled production route is approved.

### SCA-PUBLIC-PASSPORT-008 — Public SCA registry/passport
**Phase:** 4 — Public Registry
**Status:** QUEUED
**Depends on:** SCA-CERT-QR-007 PASS

Build the public verification surface with explicit privacy allowlist, authenticity/certification status, approved item details, condition summary, provenance summary, registry status, and lost/stolen warning capability.

### SCA-SHOPIFY-CONNECT-009 — Connect live Second Chance Eyewear Shopify store safely
**Phase:** 5 — Shopify Integration
**Status:** QUEUED
**Depends on:** stable SCA physical-item/QR model

Verify exact live Shopify store identity, configure approved least-privilege scopes, install/connect the existing SCA Shopify app, and establish signed/idempotent webhook handling without granting unnecessary write access.

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

Show claimed authenticated eyewear, certification/provenance information, service history, and appropriate owner actions in an SCA-branded customer experience separate from Krayin staff admin.

### SCA-TRANSFER-014 — Ownership transfer lifecycle
**Phase:** 7 — Transfers
**Status:** QUEUED
**Depends on:** registered ownership stable

Implement authenticated transfer initiation/acceptance/cancellation/expiry and append new ownership history without erasing prior owners.

### SCA-SERVICE-015 — Service history
**Phase:** 8 — Lifecycle
**Status:** QUEUED
**Depends on:** ownership/provenance core stable

Implement append-only service events for repair, lens work, polish, tune-up, inspection, and other approved service categories.

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

Harden permanent infrastructure, configure off-server backups/durable media, rehearse full restore, configure Jeremy-controlled production QR route, perform DNS/cutover/rollback plan, and migrate without regenerating permanent IDs or rewriting provenance.

### SCA-EXPANSION-019 — Market history, collector profiles, paid external authentication
**Phase:** 11 — Expansion
**Status:** QUEUED
**Depends on:** production core platform stable

Plan post-core features including market history/value tracking, collector profiles/privacy, notifications, external paid authentication intake, resale workflows, marketplace concepts, and advanced analytics.

---

## Queue maintenance rules

1. ChatGPT updates this file after every audit that changes task ordering, dependencies, status, or architecture.
2. Claude may recommend new tasks in its committed findings report, but must not add them to this queue unless the current task explicitly authorizes governance-file edits.
3. Findings that reveal security/data-integrity risk take priority over feature work.
4. Any architecture-changing task requires an ADR before implementation.
5. Tasks should be kept small enough to audit independently; if a queued task becomes too large, split it before promotion to `NEXT_TASK.md`.
6. `ROADMAP.md` describes phases and destination; `TASK_QUEUE.md` describes ordered actionable backlog; `NEXT_TASK.md` describes the single current executable unit.

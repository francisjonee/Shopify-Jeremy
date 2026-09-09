# Second Chance Authenticators — Architecture & Delivery Bridge

This repository is the canonical architecture, product-requirements, audit, and implementation-task bridge for **Jeremy's Second Chance Authenticators (SCA) business**.

## Business Ownership

This project is entirely for Jeremy's business: **Second Chance Eyewear / Second Chance Authenticators**.

The GitHub account or repository owner name is only a technical hosting detail. It does not represent business ownership, product ownership, or a separate stakeholder in this project.

## Roles

- **Jeremy / Business Owner** — owns the business vision, business requirements, product decisions, domains, billing, and production approvals.
- **ChatGPT / Architect + Auditor** — converts Jeremy's requirements and brainstorming into architecture, acceptance criteria, ADRs, audits, and exactly one current implementation task in `NEXT_TASK.md`.
- **Claude / Implementer** — reads `NEXT_TASK.md`, implements only the approved task, returns evidence, and then stops until ChatGPT audits the result and issues a new or revised task.
- **Authorized Technical Operator** — may operate the VPS, GitHub account, credentials, and infrastructure only when the current task/governance permits it. This is an operational role, not business ownership.
- **GitHub** — source of truth for architecture decisions and task state.

## Product Vision

SCA is not only an authentication service. It is a permanent ownership and provenance platform for collectible eyewear.

Every qualifying pair should receive a permanent SCA record before sale:

- Authentication completed
- Condition graded
- Registry record created
- Unique SCA Certification ID
- Permanent QR code

For Second Chance Eyewear purchases, the buyer scans the QR, creates/signs into an SCA account, and claims the already-authenticated pair for free. The pair then appears in **My Collection**. Future ownership transfers append to the provenance record rather than overwriting prior owners.

External eyewear not purchased from Second Chance Eyewear can later enter SCA through paid authentication.

## System Boundaries

### Shopify
Commerce source for:
- Products / variants / SKUs
- Inventory state
- Orders / sale events
- Original purchaser reference

### SCA Platform
Canonical system for:
- Certification ID
- Authentication record
- Condition grade
- Inspection images
- Permanent QR identity
- Current registered owner
- Ownership history
- Transfer history
- Service history
- Certification status
- Lost / stolen status
- Collector collection
- Insurance / document outputs
- Future market-history features

Shopify must not become the canonical provenance database.

## Interfaces

1. **SCA Admin / CRM** — inventory intake, authentication, grading, certificates, QR, customers, ownership, transfers, service events, reports.
2. **Collector Portal** — account, claim ownership, My Collection, certificate, transfer ownership, service history, lost/stolen actions.
3. **Public Registry / Passport** — QR verification, authenticity, condition, public provenance/status without exposing private personal data.

## Hosting Principle

A project VPS is now available. `ADR-0004-VPS-HOSTING-SUPERSEDES-ADR-0001.md` supersedes the earlier managed-only hosting direction. Hosting choice must not change the SCA system-of-record boundaries, permanent-record requirements, security requirements, or approval gates.

## Delivery Rules

- One current implementation task only in `NEXT_TASK.md`.
- ChatGPT is the authority that writes or replaces the current implementation task after architecture review.
- Claude must not expand scope beyond that task.
- Claude must stop after returning task evidence and wait for ChatGPT audit before doing additional implementation work.
- Claude must not self-approve completion or invent the next task.
- Every completed task must return evidence and commit SHA(s).
- Architecture changes require an ADR before implementation.
- Secrets, Shopify client secrets, access tokens, database credentials, and production keys must never be committed.
- Historical provenance records are append-only at the business-logic level; owner/service/transfer history must not be silently overwritten.

See `docs/EXECUTION_WORKFLOW.md` for the mandatory Architect → Claude → Audit → Next Task loop.

## Current State

- Shopify Dev app created for SCA.
- Intended Shopify scope baseline: `read_products,read_inventory,read_orders,read_customers`.
- SCA domain: `secondchanceauthenticators.com`.
- Arianee is rejected for the current SCA architecture.
- Project VPS path is available under ADR-0004.
- The current implementation source still needs to be recovered/established before feature development continues.

Read next:

- `docs/PRODUCT_REQUIREMENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/EXECUTION_WORKFLOW.md`
- `docs/ADR-0004-VPS-HOSTING-SUPERSEDES-ADR-0001.md`
- `NEXT_TASK.md`

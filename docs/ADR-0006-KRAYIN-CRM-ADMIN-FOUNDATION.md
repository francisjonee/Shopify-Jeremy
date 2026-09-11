# ADR-0006 — Adopt Krayin CRM as the SCA Admin Foundation

**Status:** ACCEPTED

**Date:** 2026-09-12

## Context

SCA needs a mature internal operations surface for staff while preserving the unique SCA product model: physical eyewear identity, authentication, certification, QR passport, claim eligibility, ownership, provenance, transfers, service history, and registry status.

The prior architecture in ADR-0005 authorized a greenfield Next.js + PostgreSQL + Prisma foundation. That remains a valid technical approach, but it requires SCA to build ordinary CRM/admin capabilities that already exist in mature open-source software: staff users, roles, contacts, notes, activities, files, search, filters, dashboards, and operational workflows.

Jeremy's team has approved changing direction to use a mature MIT-licensed CRM to reduce implementation time and avoid unnecessary custom CRM development.

Krayin CRM is selected as the initial admin/operations foundation because it is MIT licensed, Laravel based, self-hostable, extensible, and has a more mature ecosystem than the other MIT candidates reviewed for this project.

## Decision

SCA will use **Krayin CRM as the staff-facing admin and operational foundation**.

Krayin is not the business definition of SCA and must not become the canonical provenance model by accident.

SCA-specific capabilities will be implemented as controlled Laravel/Krayin modules and domain tables where appropriate.

### Initial platform direction

- Krayin CRM
- Laravel / PHP
- MySQL or MariaDB using Krayin's supported database path
- Docker / Docker Compose for portable deployment
- S3-compatible durable media abstraction where required
- Shopify as the commerce system of record
- SCA-controlled permanent QR identity and Jeremy-controlled domain
- Separate collector/public presentation layer where required for premium customer experience

## System boundaries

### Krayin provides reusable operational capabilities

- staff authentication and users;
- roles and permissions;
- people/customer records;
- notes and activities;
- file/document support where suitable;
- search, filters, forms, dashboards, and admin navigation;
- extension points for SCA modules.

### SCA owns the permanent business domain

At minimum, the architecture must preserve explicit SCA concepts equivalent to:

- `eyewear_items`
- `authentications`
- `certifications`
- `qr_identifiers`
- `collector_accounts`
- `ownership_events`
- `transfer_requests` / `transfer_events`
- `service_events`
- `status_events`
- `shopify_sale_links`

Names may be adjusted during schema design, but the business semantics may not be collapsed into generic CRM contacts, products, deals, or notes.

## Provenance rule

Historical provenance is append-only at the business-logic level.

A transfer must never erase the prior owner. Service history must not be silently rewritten. Status changes must remain auditable. The CRM may expose current-state convenience fields, but the authoritative history is derived from append-only SCA events.

## Customer-facing rule

Collectors must not be forced to use the Krayin admin interface.

The customer experience remains SCA-branded and purpose-built around:

- QR verification;
- claim ownership;
- My Collection;
- certificate/provenance viewing;
- ownership transfer;
- service history;
- lost/stolen actions;
- privacy controls.

The public registry/passport also remains an SCA interface with an explicit privacy allowlist.

## Database decision

The previous PostgreSQL + Prisma requirement is superseded for the initial CRM-based foundation.

The initial deployment should use the database engine officially supported by the selected Krayin release, currently MySQL/MariaDB. SCA must not introduce an additional PostgreSQL database merely to preserve the old stack unless a later ADR demonstrates a concrete need.

This does not weaken the SCA data ownership rule. SCA domain tables remain first-class application data even when stored in the same MySQL/MariaDB instance as Krayin.

## Portability

The temporary VPS remains construction/staging infrastructure only.

The deployment must remain reconstructable on another server from:

- implementation source repository;
- environment/secrets;
- database backup;
- durable media backup/storage;
- deployment documentation.

Permanent QR URLs must never depend on a temporary VPS IP or hostname.

## Security and upgradeability

Krayin adoption does not mean blindly modifying vendor core files.

Implementation must prefer packages/modules/extensions and isolated SCA code over invasive core edits. Any unavoidable core modification must be documented with upgrade impact.

Before production use, the selected Krayin release must be pinned, dependency-audited, hardened, backed up, and smoke-tested. Default credentials must never survive deployment.

## Shopify boundary

Shopify remains authoritative for products, variants, inventory, orders, payment/sale events, and original purchaser references.

SCA remains authoritative for certified physical item identity, authentication, condition, certification, permanent QR identity, claim state, registered ownership, provenance, transfers, service history, and registry status.

A Shopify purchase grants claim eligibility; it does not directly create permanent SCA registered ownership.

## Consequences

### Positive

- avoids rebuilding commodity CRM/admin functionality;
- accelerates staff-facing delivery;
- keeps the development team focused on SCA's differentiating provenance engine;
- uses a permissive MIT-licensed base;
- provides a Laravel ecosystem for custom SCA modules;
- reduces initial frontend/admin scaffolding work.

### Tradeoffs

- the backend stack changes from TypeScript/Next.js/Prisma/PostgreSQL to Laravel/Krayin/MySQL or MariaDB for the admin foundation;
- Krayin upgrades must be managed carefully;
- SCA modules must avoid becoming tightly coupled to undocumented vendor internals;
- collector/public interfaces may still require purpose-built frontend work;
- security review of the selected Krayin version remains mandatory.

## Supersedes

This ADR **partially supersedes ADR-0005** only where ADR-0005 mandates the initial greenfield application stack of Next.js + PostgreSQL + Prisma and building the admin foundation from scratch.

ADR-0005 remains authoritative for:

- greenfield freedom from the inaccessible old Ownership Bridge;
- temporary VPS portability;
- source control and backup discipline;
- Jeremy-controlled permanent QR domain;
- no hard-coded temporary host identity;
- separation of Shopify commerce from SCA provenance;
- controlled implementation/audit workflow.

## Implementation gate

No SCA product feature should be built until the Krayin foundation task proves:

- exact upstream version and license;
- repeatable installation;
- database persistence and backup/restore;
- secure admin initialization;
- extension/module path for SCA code;
- no vendor-core modification for the initial setup;
- portability from the temporary VPS;
- documented upgrade strategy.

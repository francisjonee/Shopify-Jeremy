# SCA Target Architecture

## Objective

Separate commerce from provenance, reuse mature MIT-licensed CRM capabilities for staff operations, and keep the SCA-specific business domain portable and under SCA control.

```text
Second Chance Eyewear / Shopify
        |
        | products, variants, inventory, orders, purchaser reference
        v
SCA Shopify Integration
        |
        v
SCA Platform — Laravel / Krayin Foundation
        |
        +--> Krayin Staff Admin / CRM
        |      +--> users / roles / permissions
        |      +--> customers / contacts
        |      +--> notes / activities / files
        |      +--> search / filters / dashboards
        |
        +--> SCA Domain Modules
        |      +--> physical eyewear identity
        |      +--> authentication / certification
        |      +--> QR identity
        |      +--> claims / ownership / provenance
        |      +--> transfers / service / registry status
        |
        +--> SCA Collector Portal
        +--> SCA Public QR Registry / Passport
        |
        +--> MySQL or MariaDB
        +--> S3-compatible durable media storage
        +--> background jobs as required
```

## Build Direction

The inaccessible prior Ownership Bridge is not a prerequisite. SCA remains authorized as a greenfield implementation, but the project will no longer rebuild commodity CRM/admin capabilities from scratch.

Per `ADR-0006-KRAYIN-CRM-ADMIN-FOUNDATION.md`, Krayin CRM is the initial staff-facing admin/operations foundation.

Initial implementation direction:

- Krayin CRM;
- Laravel / PHP;
- MySQL or MariaDB on Krayin's supported path;
- Docker / Docker Compose;
- modular SCA Laravel/Krayin extensions rather than invasive vendor-core edits;
- S3-compatible durable media abstraction;
- purpose-built SCA collector/public surfaces where required;
- Shopify integration as a separate commerce boundary.

The current VPS remains temporary construction/staging infrastructure. The implementation must be portable to a future permanent server.

Application source belongs in a separate private implementation repository. This repository remains the public architecture/task/audit bridge.

## Core Architectural Rule

**Krayin is the operational shell; SCA is the product.**

Generic CRM entities must not replace SCA's permanent business concepts. A CRM product/deal/contact record is not a substitute for a uniquely certified physical eyewear item, an ownership event, or a provenance record.

## System of Record Boundaries

### Shopify is authoritative for

- product and variant commerce data;
- SKU references;
- inventory quantity/state;
- orders and payment/sale events;
- original sale linkage;
- purchaser reference used for initial claim eligibility.

### Krayin provides reusable operational capabilities

- staff accounts;
- roles and permissions;
- people/customer records;
- notes and activities;
- files where suitable;
- search, filters, forms, dashboards, and admin navigation;
- extension points for SCA modules.

### SCA is authoritative for

- unique certified physical eyewear identity;
- SCA Certification ID;
- authentication result;
- condition report;
- inspection media references;
- permanent QR identity;
- claim state;
- registered ownership;
- ownership/provenance events;
- transfer events;
- service events;
- registry and lost/stolen status;
- collector collection;
- generated certificates/insurance records.

Neither Shopify nor generic Krayin CRM records may become the canonical provenance database.

## Physical Item vs Shopify/Krayin Records

A Shopify product/variant is a commerce definition. A Krayin product/contact/deal is an operational CRM concept. An SCA `eyewear_item` represents one uniquely certified physical pair.

```text
Shopify Product A / Variant A / Qty 5
   |
   +--> SCA physical pair 001 / Certification ID / QR 001
   +--> SCA physical pair 002 / Certification ID / QR 002
   +--> SCA physical pair 003 / Certification ID / QR 003
   +--> SCA physical pair 004 / Certification ID / QR 004
   +--> SCA physical pair 005 / Certification ID / QR 005
```

## SCA Domain Model

The implementation must preserve explicit first-class concepts equivalent to:

### `collector_accounts`
Independent SCA collectors. A Shopify customer or Krayin person may be linked but is not automatically the permanent ownership identity.

### `eyewear_items`
One uniquely certified physical eyewear item with internal identifier, human-readable Certification ID, optional commerce references, and registry state.

### `authentications`
Appendable authentication/inspection records including result, date, condition grade, notes, and media references.

### `certifications`
Certification issuance/version/status information when separated from authentication.

### `ownership_events`
Append-only ownership lifecycle. Transfers never erase prior owner history.

### `transfer_requests` / `transfer_events`
Pending/accepted/expired/cancelled ownership-transfer workflow and resulting provenance events.

### `service_events`
Repairs, lens work, polishing, tune-up, inspection, and other service history.

### `status_events`
Lost, stolen, recovered, certification changes, and other registry transitions.

### `shopify_sale_links`
Links a Shopify order line to the exact physical SCA item and controls initial claim eligibility.

### `qr_identifiers`
Permanent public identity for a physical item. QR payloads contain no secret or private customer data.

Exact table/package names may change during implementation, but these semantics must remain explicit and testable.

## Provenance Integrity

Historical provenance is append-only at the business-logic level.

The CRM may maintain convenient current-state fields such as current owner or current registry status, but those values must be derived from or reconciled with the authoritative SCA event history. Staff must not be able to silently rewrite historical ownership, transfer, service, or status history through generic CRM editing.

## Claim State Machine

```text
UNCLAIMED
   |
   | eligible paid Shopify sale linked to exact physical item
   v
SOLD_AWAITING_CLAIM
   |
   | customer receives item, scans QR, signs into SCA, claim verified
   v
REGISTERED
   |
   | registered owner initiates transfer
   v
TRANSFER_PENDING
   |
   | recipient accepts
   v
REGISTERED (new active owner, prior owner retained in history)
```

A Shopify purchase makes someone eligible to claim. It does not itself create permanent registered SCA ownership.

## Permanent QR Model

Canonical QR generation belongs to SCA, not Shopify or generic Krayin functionality.

1. Staff authenticates and grades a physical pair through the SCA admin module.
2. SCA creates the provenance record and Certification ID.
3. SCA creates a permanent QR identity.
4. Staff prints and includes it with the eyewear.
5. Shopify later records the sale.
6. SCA links the exact physical pair to the eligible order/purchaser.
7. Customer receives and scans the QR.
8. SCA public/collector experience opens.
9. Customer signs in or creates an SCA collector account.
10. SCA verifies eligibility and appends ownership.
11. Item becomes REGISTERED and appears in My Collection.

Permanent printed QR codes must use a Jeremy-controlled production route such as `https://secondchanceauthenticators.com/p/<id>` or another approved Jeremy-controlled subdomain. Never hard-code the temporary VPS IP/hostname.

## Customer-facing Surfaces

Collectors must not be required to use Krayin's staff/admin interface.

### Collector Portal

- sign up/sign in;
- claim eligible pair;
- My Collection;
- view provenance/certificate;
- initiate/accept transfer;
- service history;
- lost/stolen actions;
- privacy settings.

### Public Registry / Passport

- authenticity status;
- Certification ID;
- approved public specifications;
- approved condition summary;
- approved provenance summary;
- lost/stolen warning;
- claim CTA when eligible;
- secure transfer CTA only when authorized.

The collector/public UI may initially be implemented within Laravel or as a separate frontend later. The boundary is an experience/security requirement, not a mandate for a second framework on day one.

## Shopify Integration

Initial least-privilege scope baseline remains:

```text
read_products
read_inventory
read_orders
read_customers
```

Webhook processing must be signature verified, idempotent, retry safe, and auditable. No Shopify write scope is added until a separately approved feature requires mutation.

## Security Baseline

- pin and document the selected Krayin release;
- verify upstream MIT license before adoption;
- audit dependencies before production;
- never retain default admin credentials;
- secrets remain outside Git;
- prefer SCA modules/packages over vendor-core modification;
- document every unavoidable vendor-core patch and its upgrade impact;
- server-side Shopify API calls only;
- verified webhooks;
- rate-limit public QR, login, claim, and transfer endpoints;
- authorization tests for admin/owner/public boundaries;
- audit ownership/transfer/service/status mutations;
- explicit public registry field allowlist;
- no private customer data in QR payloads or public routes.

## Database and Backup Boundary

The initial CRM-based architecture uses MySQL/MariaDB instead of the previously mandated PostgreSQL/Prisma stack.

Before production provenance data is trusted:

- database backups must exist outside the temporary VPS;
- restore must be tested;
- durable media must have a recoverable storage strategy;
- migrations for SCA modules must be version controlled;
- upgrade and rollback procedures must be documented.

Do not add PostgreSQL merely to preserve the old architecture unless a later ADR identifies a concrete requirement.

## Upgradeability Rule

SCA must be able to update or replace Krayin without destroying the SCA provenance model.

Therefore:

- custom SCA domain code belongs in isolated modules/packages where practical;
- vendor core modifications are strongly discouraged;
- SCA schema/migrations are version controlled;
- integration boundaries are documented;
- backups and migration procedures are tested.

## Deployment Boundary

The current VPS is temporary. The system must be reconstructable on a fresh server from:

```text
Private implementation Git repository
+ pinned Krayin/Laravel dependencies
+ environment/secrets
+ MySQL/MariaDB backup
+ durable object/media storage
+ deployment documentation
```

Moving to permanent infrastructure must not require permanent QR regeneration, customer reset, or ownership-history rewriting.

## Governing Decisions

- ADR-0005 remains authoritative for greenfield freedom, portability, backup discipline, and separation from the inaccessible old implementation.
- ADR-0006 supersedes ADR-0005's initial Next.js/PostgreSQL/Prisma/admin-from-scratch stack and establishes Krayin as the initial CRM/admin foundation.

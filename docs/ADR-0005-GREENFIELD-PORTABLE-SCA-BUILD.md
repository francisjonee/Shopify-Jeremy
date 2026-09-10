# ADR-0005 — Greenfield Portable SCA Build on Temporary VPS

**Status:** ACCEPTED

**Date:** 2026-09-10

## Context

The prior SCA Ownership Bridge implementation is not reachable from the current VPS or connected GitHub account. Jeremy's team has now explicitly decided **not to recover that implementation**. SCA will be built again from scratch using the currently available blank VPS as a temporary construction/staging environment.

The current VPS is **not** the permanent home of SCA. The application must be designed so it can later be moved to a permanent server without rebuilding the product, regenerating permanent QR codes, resetting ownership history, or coupling customer records to the temporary machine.

The Shopify Dev app that already exists is an integration/admin entry point. It does not make Shopify the provenance database and does not make Shopify responsible for canonical SCA QR generation.

## Decision

### 1. Build greenfield

The inaccessible prior implementation is no longer a prerequisite. New implementation work is authorized from a clean baseline.

The application source will live in a **separate private implementation repository**. `francisjonee/Shopify-Jeremy` remains the public architecture, audit, and task bridge.

### 2. Temporary VPS is a construction environment

The current VPS may host development/staging runtime while the product is built. Nothing in the application may depend permanently on that VPS hostname, IP address, filesystem layout, or local-only state.

Assume the temporary VPS can disappear and the application must still be recoverable from:

- private Git repository;
- PostgreSQL backup;
- object/media storage;
- protected environment/secrets backup;
- deployment and restore documentation.

### 3. Portable stack

Initial implementation stack:

- TypeScript
- Node.js
- Next.js
- PostgreSQL
- Prisma ORM and migrations
- Docker / Docker Compose
- Caddy or equivalent TLS reverse proxy when a staging hostname is available
- S3-compatible object storage abstraction for authentication photos, generated documents, and other durable media

The initial application should be a **modular monolith**, not microservices. A background worker may run as a separate process/container from the same codebase when needed.

### 4. Shopify remains commerce; SCA remains provenance

Shopify is authoritative for products, variants, SKUs, inventory quantity/state, orders, sale/payment events, and purchaser reference.

SCA is authoritative for each unique certified physical eyewear item, Certification ID, authentication, condition, permanent QR identity, claim state, registered ownership, provenance history, transfers, service history, registry status, and collector collection.

A Shopify product/variant is **not automatically the same thing as one physical SCA item**. Each uniquely certified physical pair receives its own `eyewear_item` and permanent SCA identifier even when multiple physical units relate to the same Shopify product or variant.

### 5. QR ownership and delivery

Canonical QR codes are generated and owned by SCA, **not by Shopify**.

Operational flow:

1. Staff authenticates/grades a physical pair in SCA.
2. SCA creates its Digital Provenance Record and unique Certification ID.
3. SCA creates the permanent QR identity.
4. The QR is printed and physically included with the eyewear before shipment.
5. Shopify records the sale/order.
6. SCA links the sold physical pair to the Shopify order and purchaser and moves it to `SOLD_AWAITING_CLAIM` when claim eligibility is valid.
7. Customer receives the eyewear and scans the physical QR.
8. Customer lands on the SCA public/collector application, signs in or creates an independent SCA collector account, and claims the pair.
9. SCA records ownership and the item appears in My Collection.

An email containing the same QR/claim link may be added later as a convenience, but **email and checkout are not the canonical ownership-claim event**.

### 6. No checkout ownership registration

A paid Shopify purchase makes the buyer **eligible to claim**. It does not automatically become permanent registered ownership. Claim occurs after receipt/possession through the SCA claim flow.

This protects the registry from cancellations, refunds, returns, failed delivery, and other commerce reversals.

### 7. Shopify app role

The Shopify app may later provide staff-facing convenience inside Shopify Admin, for example:

- linked SCA Certification ID;
- SCA status;
- open SCA record;
- view/print QR action;
- sale-to-physical-item mapping status.

These are integrations or mirrors. Shopify is not the canonical store for the QR/provenance record.

Write scopes or Shopify metafield writes require a separately approved task/decision. Initial integration remains least privilege.

### 8. Permanent QR independence

Permanent printed QR codes must use a Jeremy-controlled domain, never the temporary VPS IP/hostname.

The application must use configuration such as `PUBLIC_QR_BASE_URL` rather than hard-coded hostnames. The exact production route/subdomain can be finalized before permanent QR printing is enabled.

Development/staging QR codes must be clearly non-production and must never be printed as lifetime identifiers.

### 9. Permanent-server migration is a design requirement

The migration path must be rehearsable:

1. provision permanent server;
2. install Docker/runtime prerequisites;
3. clone private implementation repository;
4. restore PostgreSQL backup;
5. configure environment/secrets;
6. connect durable object storage;
7. start application and worker;
8. run migrations and health checks;
9. validate login, QR resolution, Shopify integration, claim flow, and background jobs;
10. switch Jeremy-controlled DNS;
11. keep temporary environment available briefly for rollback;
12. decommission temporary environment only after verification.

No permanent QR should need regeneration during this move.

## Consequences

- Recovery of the old Ownership Bridge is no longer on the critical path.
- Implementation can start immediately from a clean codebase.
- The temporary VPS must never become an accidental single point of truth.
- Application portability, backups, object storage, and configuration discipline are first-class requirements.
- Shopify integration and SCA provenance remain deliberately separated.
- QR generation, physical-item identity, claims, and ownership live in SCA.

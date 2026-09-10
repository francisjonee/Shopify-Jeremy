# SCA Infrastructure Blueprint

## Goal

Build SCA on the current blank VPS without making that machine permanent. The implementation must be portable to a future permanent server with no product rebuild and no permanent QR regeneration.

## Environment Model

### Temporary build/staging environment

Purpose: development, integration testing, QA, controlled demonstrations.

Rules:

- treat the VPS as disposable;
- do not use its IP or hostname as a permanent identifier;
- do not store irreplaceable data only on its local disk;
- keep application source in a private Git repository;
- keep secrets outside Git;
- maintain restorable PostgreSQL backups;
- keep durable media in S3-compatible object storage or an explicitly migratable storage layer;
- do not print lifetime QR codes using a staging URL.

### Permanent production environment

Purpose: trusted long-term SCA registry.

Requirements before cutover:

- permanent server provisioned and hardened;
- tested PostgreSQL backup/restore;
- durable media/object storage configured;
- production secrets configured outside Git;
- TLS and Jeremy-controlled domain configured;
- monitoring, logging, alerting, firewalling, patching, process supervision, and recovery procedures active;
- production QR base URL configured on a Jeremy-controlled domain;
- Shopify integration verified against the actual Second Chance Eyewear store;
- rollback procedure tested.

## High-Level Topology

```text
Second Chance Eyewear Shopify
    |
    | products / variants / inventory / orders / purchaser references
    v
SCA Shopify Integration Layer
    |
    v
SCA Modular Monolith
    |-- Admin / CRM
    |-- Collector Portal
    |-- Public Registry / QR Passport
    |-- Authentication / authorization
    |-- Provenance domain modules
    |-- Shopify webhook handlers
    |-- Document generation
    |
    +--> PostgreSQL
    +--> S3-compatible Object Storage
    +--> Background Worker / Job Queue as required
```

## Initial Technical Stack

- **Language:** TypeScript
- **Runtime:** Node.js
- **Web framework:** Next.js
- **Database:** PostgreSQL
- **ORM/migrations:** Prisma
- **Packaging:** Docker
- **Local/server composition:** Docker Compose
- **Reverse proxy/TLS:** Caddy or equivalent
- **Durable media:** S3-compatible object storage abstraction
- **Application style:** modular monolith

The architecture may evolve through later ADRs, but implementation must not introduce microservices simply for separation of concerns.

## Container Layout

Initial deployment target:

```text
sca-web       Next.js web/API application
sca-worker    background tasks from same codebase when needed
sca-db        PostgreSQL during temporary staging if external managed DB is not used
caddy         reverse proxy/TLS when a hostname is assigned
```

Production may move PostgreSQL or object storage to managed services without changing application domain logic.

## Portability Rules

1. No hard-coded server IPs, hostnames, absolute VPS paths, or temporary domains in business records.
2. Runtime configuration is environment-driven.
3. Database schema changes are migration-controlled.
4. Application containers are stateless except for explicitly mounted temporary caches.
5. Authentication photos and generated documents do not live only inside the application container.
6. Permanent QR records store stable identifiers, not infrastructure locations.
7. `PUBLIC_QR_BASE_URL` or equivalent determines public QR routing by environment.
8. Staging and production credentials are separate.
9. A fresh server must be rebuildable from repository + environment/secrets + database backup + object storage + deployment documentation.
10. Backups are not considered valid until a restore has been tested.

## Domain and QR Strategy

Jeremy controls `secondchanceauthenticators.com`.

Production QR examples may eventually use either:

```text
https://secondchanceauthenticators.com/p/SCA-2026-000001
```

or:

```text
https://passport.secondchanceauthenticators.com/p/SCA-2026-000001
```

The final production route will be selected before lifetime QR printing is enabled.

The current temporary server IP/hostname must never be printed in a permanent QR.

## Shopify Integration Boundary

The Shopify Dev app is the authorized integration surface between Shopify and SCA. It does not replace the SCA backend.

### Shopify owns

- product/variant definitions;
- SKUs;
- commerce inventory state;
- orders/payment events;
- original purchaser reference.

### SCA owns

- unique physical eyewear item;
- SCA Certification ID;
- authentication and condition;
- QR identity;
- claim state;
- registered owner and ownership events;
- transfer, service, lost/stolen, and registry history;
- collector collection.

### Mapping rule

A Shopify product or variant may relate to one or more physical SCA eyewear items. SCA must explicitly map the sold order line to the exact certified physical item. Never derive permanent ownership solely from a Shopify product ID.

### Shopify Admin convenience

Later, the Shopify app may display or link to SCA data such as Certification ID, status, record URL, or View/Print QR. This is a staff convenience only. SCA remains canonical.

## Customer Claim Flow

```text
SCA authenticates physical pair
        |
        v
SCA creates Certification ID + permanent QR identity
        |
        v
QR printed and included with physical eyewear
        |
        v
Shopify order is paid
        |
        v
SCA links order/purchaser to exact physical pair
        |
        v
SOLD_AWAITING_CLAIM
        |
        v
Customer receives item and scans QR
        |
        v
SCA public record / collector portal
        |
        v
Sign in or create independent SCA collector account
        |
        v
Verify claim eligibility
        |
        v
REGISTERED + My Collection
```

A checkout does not create permanent SCA ownership. Email delivery of the same QR/claim link may be added later as convenience, not as the canonical claim event.

## Data Protection

- no tokens, passwords, Shopify secrets, database URLs, or customer data in the public architecture repository;
- secrets stored outside Git;
- server-side Shopify API calls only;
- verify Shopify webhook signatures;
- rate-limit public/login/claim/transfer endpoints;
- public registry uses an explicit field allowlist;
- owner, admin, and public authorization boundaries require automated tests;
- append-only provenance events are enforced in application logic and protected by database constraints where appropriate.

## Backup Blueprint

At minimum:

- scheduled PostgreSQL logical backups;
- encrypted backup destination separate from the temporary VPS;
- retention policy;
- backup success/failure logging;
- periodic restore test into an isolated database;
- object-storage durability/versioning policy where available;
- documented secret recovery process without storing raw secrets in Git.

Before the registry is trusted for permanent ownership, database restore must be proven.

## Observability

Initial foundation should expose:

- application health endpoint;
- database readiness check;
- structured application logs;
- startup/migration failures clearly logged;
- later: uptime checks, exception tracking, resource monitoring, job failures, backup failures, webhook failure/retry metrics.

## Permanent Migration Runbook

```text
1. Freeze risky schema/product changes.
2. Take verified source database backup.
3. Provision/harden permanent server.
4. Install Docker/runtime prerequisites.
5. Clone private SCA implementation repo.
6. Configure production secrets and object storage.
7. Restore PostgreSQL.
8. Run migrations.
9. Start web/worker/reverse proxy.
10. Run health and smoke tests.
11. Verify public QR, login, claim, admin, Shopify webhooks, and background jobs.
12. Point Jeremy-controlled DNS to the permanent environment.
13. Observe and keep temporary environment available for rollback.
14. Decommission temporary environment only after acceptance.
```

The migration must not require QR regeneration, ownership-history rewriting, or application reconstruction.

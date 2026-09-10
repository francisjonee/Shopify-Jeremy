# SCA Target Architecture

## Objective

Separate commerce from provenance while keeping the customer experience simple and keeping the application portable from the current temporary VPS to a future permanent server.

```text
Second Chance Eyewear / Shopify
        |
        | products, variants, inventory, orders, purchaser reference
        v
SCA Shopify Integration Layer
        |
        v
SCA Modular Monolith
        |
        +--> SCA Admin / CRM
        +--> Collector Portal
        +--> Public QR Registry
        |
        +--> PostgreSQL
        +--> S3-compatible durable media storage
        +--> background worker/jobs as required
```

## Build Direction

The inaccessible prior Ownership Bridge is no longer a prerequisite. The project is authorized as a **greenfield build from scratch**.

The current VPS is a temporary construction/staging environment. The implementation must be portable to a future permanent server. See `ADR-0005-GREENFIELD-PORTABLE-SCA-BUILD.md` and `INFRASTRUCTURE_BLUEPRINT.md`.

Initial implementation stack:

- TypeScript
- Node.js
- Next.js
- PostgreSQL
- Prisma
- Docker / Docker Compose
- modular monolith
- Caddy or equivalent reverse proxy when needed
- S3-compatible object storage abstraction for durable media

Application source belongs in a separate **private implementation repository**. This repository remains the public architecture/task/audit bridge.

## Production Shopify Store Requirement

The SCA Shopify app is intended to connect to and be installed on the **actual live Second Chance Eyewear Shopify store**, not merely a Shopify development store.

Before any production installation, identify and record the exact live store identity using Shopify's canonical `*.myshopify.com` identity. Do not guess the store from the public storefront domain.

Use Custom distribution for the actual Second Chance Eyewear store unless a later ADR changes this.

## System of Record Boundaries

### Shopify is authoritative for

- product and variant commerce data;
- SKU references;
- inventory quantity/state;
- orders and payment/sale events;
- original sale linkage;
- Shopify purchaser reference used for initial claim eligibility.

### SCA is authoritative for

- unique certified physical eyewear identity;
- SCA Certification ID;
- authentication result;
- condition report;
- inspection media references;
- QR identity;
- claim state;
- registered ownership;
- ownership events;
- transfer events;
- service events;
- registry status;
- lost/stolen status;
- collector collection;
- generated certificates/insurance records.

Shopify must never become the canonical provenance database.

## Physical Item vs Shopify Product

A Shopify product/variant is a commerce definition. An SCA `eyewear_item` represents one uniquely certified physical pair.

Do not assume one Shopify product ID or variant ID equals one permanent provenance record.

Examples:

```text
Shopify Product A / Variant A / Qty 5
   |
   +--> SCA physical pair 001 / Certification ID / QR 001
   +--> SCA physical pair 002 / Certification ID / QR 002
   +--> SCA physical pair 003 / Certification ID / QR 003
   +--> SCA physical pair 004 / Certification ID / QR 004
   +--> SCA physical pair 005 / Certification ID / QR 005
```

If Jeremy lists each collectible pair as its own quantity-1 Shopify product, the mapping can be one-to-one, but the SCA data model must still support the more general case.

## Core Data Model

### `collector_accounts`
Independent SCA users/collectors. A Shopify customer ID may be linked but is not the SCA identity source of truth.

### `eyewear_items`
One uniquely certified physical eyewear item.

Suggested identifiers:

- internal UUID;
- unique human-readable `sca_certification_id`;
- optional Shopify product/variant/SKU references;
- stable registry status.

### `authentications`
Appendable authentication/inspection records with result, date, grade, notes, and media references.

### `ownership_events`
Append-only ownership lifecycle events. Never erase prior owner history during transfer.

### `transfer_requests`
Pending/accepted/expired/cancelled ownership-transfer workflows.

### `service_events`
Repairs, lens work, polishing, tune-up, inspection, and other service history.

### `status_events`
Lost, stolen, recovered, certification changes, and other registry status transitions.

### `shopify_sale_links`
Links a paid Shopify order line to the exact physical SCA eyewear item and controls initial claim eligibility.

### `qr_identifiers`
Permanent public identity for a physical item. The QR contains no secret or raw customer data.

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

Returns, cancellations, refunds, failed delivery, and other commerce reversals must be handled explicitly before claim eligibility is considered final.

A Shopify purchase makes someone **eligible to claim**. It does not itself create permanent registered SCA ownership.

## Final QR Operational Model

Canonical QR generation belongs to SCA, **not Shopify**.

Flow:

1. Staff authenticates and grades a physical pair in SCA.
2. SCA creates the Digital Provenance Record and Certification ID.
3. SCA creates a permanent QR identity for that physical pair.
4. Staff prints the QR and physically includes it with the eyewear.
5. Shopify later records the sale/order.
6. SCA links the exact sold physical pair to the order/purchaser and moves it to `SOLD_AWAITING_CLAIM` when eligible.
7. Customer receives the eyewear and scans the physical QR.
8. SCA public/collector application opens.
9. Customer signs in or creates an independent SCA account.
10. SCA verifies claim eligibility and appends ownership.
11. Item becomes `REGISTERED` and appears in My Collection.

Emailing the same QR or claim link may be added later as a convenience. Ownership registration does not happen at checkout.

## Shopify App Role

The Shopify Dev app is the integration/admin surface between Shopify and SCA. It does not generate the canonical provenance QR and does not replace the SCA application/database.

Later Shopify Admin conveniences may include:

- linked SCA Certification ID;
- SCA authentication/claim status;
- Open SCA Record action;
- View/Print QR action;
- mapping status between a Shopify sale line and a physical SCA item.

Any Shopify metafield write or other mutation requires an approved write scope/task. Initial integration remains least privilege.

## Shopify Integration

Initial least-privilege scope baseline:

```text
read_products
read_inventory
read_orders
read_customers
```

Purpose:

- read/map commerce product data;
- reference inventory;
- detect relevant order/sale events;
- associate purchaser references with initial claim eligibility.

Do not add Shopify write scopes until an approved feature explicitly requires Shopify mutation.

### Webhooks

Expected initial events include the minimum needed for:

- paid order/sale event;
- cancellation;
- refund/return-related eligibility changes;
- app uninstalled;
- product update only if required for sync.

Webhook processing must be:

- signature verified;
- idempotent;
- retry safe;
- auditable;
- resistant to duplicate sale-link or ownership events.

## Public QR Route

Jeremy controls `secondchanceauthenticators.com`.

Permanent printed QR codes must use a Jeremy-controlled production route, for example:

```text
https://secondchanceauthenticators.com/p/SCA-2026-000001
```

or:

```text
https://passport.secondchanceauthenticators.com/p/SCA-2026-000001
```

The exact production route is finalized before lifetime QR printing is enabled.

The implementation must use environment configuration such as `PUBLIC_QR_BASE_URL`; never hard-code the temporary VPS IP/hostname. Staging QR codes must be clearly non-production and must not be printed as permanent lifetime identifiers.

## Application Surfaces

### Admin / CRM

- dashboard;
- physical eyewear inventory/mapping;
- authentication workflow;
- condition grading;
- certification record;
- QR generation/printing;
- collector/customer lookup;
- claims;
- ownership history;
- transfers;
- service history;
- registry status;
- reporting.

### Collector Portal

- sign up/sign in;
- claim eligible pair;
- My Collection;
- view provenance record;
- certificates;
- initiate/accept transfer;
- service history;
- lost/stolen actions;
- privacy settings.

### Public Registry

- authenticity status;
- Certification ID;
- approved public item specifications;
- approved condition summary;
- approved provenance summary;
- lost/stolen warning;
- claim CTA when eligible;
- secure transfer CTA only when transfer flow authorizes it.

## Security Baseline

- production secrets only outside Git;
- never commit Shopify secret/access token, DB URL, session secret, or magic-link secret;
- server-side Shopify API calls only;
- verified webhooks;
- established authentication libraries/provider;
- hashed passwords if password authentication is used;
- rate-limit public QR, login, claim, and transfer endpoints;
- audit ownership/transfer/service/status mutations;
- authorization tests for owner/admin/public boundaries;
- explicit public registry field allowlist;
- no customer private data in public QR payloads or routes.

## Deployment Boundary

The current VPS is temporary and may host development/staging. It is not the permanent identity of the platform.

The application must be reconstructable on a fresh server from:

```text
Private implementation Git repository
+ environment/secrets
+ PostgreSQL backup
+ durable object/media storage
+ deployment documentation
```

Before permanent provenance data is trusted in production:

- PostgreSQL backups must exist outside the temporary VPS;
- a restore must be tested;
- TLS/firewall/patching/monitoring/process supervision must be active;
- durable media must not depend only on the temporary application disk;
- production QR domain must be Jeremy-controlled;
- migration/rollback procedure must be tested.

Moving to the permanent server must not require application rebuilding, QR regeneration, or ownership-history rewriting.

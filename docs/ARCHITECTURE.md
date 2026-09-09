# SCA Target Architecture

## Objective

Separate commerce from provenance while keeping the customer experience simple.

```text
Second Chance Eyewear / Shopify
        |
        | products, inventory, orders, purchaser reference
        v
SCA Integration Layer / API
        |
        +--> SCA Admin / CRM
        +--> Collector Portal
        +--> Public QR Registry
        |
        v
Managed PostgreSQL
```

## System of Record Boundaries

### Shopify is authoritative for

- Product and variant commerce data
- Inventory state
- Orders / payment events
- Original sale linkage
- Shopify customer reference used for initial claim eligibility

### SCA is authoritative for

- SCA Certification ID
- Authentication result
- Condition report
- Inspection media references
- QR identity
- Claim state
- Registered ownership
- Ownership events
- Transfer events
- Service events
- Registry status
- Lost / stolen status
- Collector collection
- Generated certificates / insurance records

## Core Data Model

### collector_accounts
Represents SCA users/collectors. Shopify customer ID may be linked when available but is not the SCA identity source of truth.

### eyewear_items
One physical collectible eyewear item. Must be distinct from a Shopify product definition when necessary.

Suggested identifiers:
- `id` internal UUID
- `sca_certification_id` unique human-readable ID
- `shopify_product_id`
- `shopify_variant_id`
- optional inventory / SKU references

### authentications
Appendable authentication/inspection records with result, date, grade, notes, and media references.

### ownership_events
Append-only ownership lifecycle events. Never erase prior owner history when a transfer occurs.

### transfer_requests
Pending/accepted/expired/cancelled ownership-transfer workflows.

### service_events
Repairs, lens work, polish, tune-up, inspection, or other service history.

### status_events
Lost, stolen, recovered, certification status changes, or other registry state transitions.

### shopify_sale_links
Links paid Shopify order line items to the corresponding physical SCA eyewear item and controls claim eligibility.

### qr_identifiers
Permanent public identifier / route token for the physical item. QR identity must not contain secrets or raw customer data.

## Important Modeling Rule: Physical Item vs Product

Jeremy’s business sells collectible physical pieces. A Shopify product/variant is not always enough to represent one unique physical frame. The implementation must support one physical SCA item per uniquely certified piece.

Do not assume that one Shopify product ID always equals one provenance record.

## Claim State Machine

```text
UNCLAIMED
   |
   | paid Shopify sale linked
   v
SOLD_AWAITING_CLAIM
   |
   | eligible collector verifies and claims
   v
REGISTERED
   |
   | owner initiates transfer
   v
TRANSFER_PENDING
   |
   | recipient accepts
   v
REGISTERED (new active owner, prior owner retained in history)
```

Returns/cancellations/refunds must be handled explicitly before automatic claim eligibility is considered final.

## Shopify Integration

Initial least-privilege scope baseline:

```text
read_products
read_inventory
read_orders
read_customers
```

Purpose:
- import/map product information
- reference inventory
- detect sales/order line items
- associate original purchaser information for claim eligibility

Do not add Shopify write scopes until an approved feature specifically requires Shopify mutation.

## Webhooks

The integration should eventually consume the minimum required Shopify events, expected examples:

- paid order event
- cancellation event
- refund/return-relevant events as required by final claim rules
- product update events only if required for sync
- app uninstalled

Webhook processing requirements:

- verify Shopify signatures
- idempotent processing
- retry-safe
- persistent event/audit evidence
- no duplicate ownership or sale-link events

## Public QR Route

Jeremy controls `secondchanceauthenticators.com`.

Because the root website may remain separate from the application host, the preferred production approach is to use a Jeremy-controlled permanent route or subdomain, for example:

```text
https://passport.secondchanceauthenticators.com/p/SCA-2026-000001
```

or a permanent route on the root domain if routing ownership is available:

```text
https://secondchanceauthenticators.com/p/SCA-2026-000001
```

The permanent printed QR must never depend on a temporary Render hostname.

## Application Surfaces

### Admin / CRM
- dashboard
- eyewear inventory / mapping
- authentication workflow
- condition grading
- certification record
- QR generation
- collector/customer lookup
- claims
- ownership history
- transfers
- service history
- registry status
- reporting

### Collector Portal
- sign up / sign in
- claim eligible pair
- My Collection
- view provenance record
- certificates
- initiate/accept transfer
- service history
- lost/stolen actions
- privacy settings

### Public Registry
- authenticity status
- certification ID
- public item specifications
- condition summary as approved
- public provenance summary as approved
- lost/stolen warning
- claim CTA when eligible
- transfer CTA only when a secure transfer flow authorizes it

## Security Baseline

- production secrets only in managed secret storage/environment variables
- never commit Shopify client secret, access tokens, DB URL, session secrets, or magic-link secrets
- server-side Shopify API calls only
- signed/verified webhooks
- hashed passwords if passwords are used; prefer established auth libraries/provider
- rate-limit public claim, login, transfer, and QR endpoints
- audit ownership/transfer/service state changes
- authorization tests for owner/admin boundaries
- public registry has an explicit allowlist of fields

## Deployment Boundary

No owner-operated server is required. Use managed hosting for web/API and managed PostgreSQL. See ADR-0001.

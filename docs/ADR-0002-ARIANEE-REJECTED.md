# ADR-0002 — Arianee Rejected for SCA Core Platform

## Status

REJECTED

## Decision

Arianee will not be used as the core platform, self-hosted foundation, or required dependency for Jeremy's Second Chance Authenticators (SCA) system.

## Reason

Jeremy's required MVP is a direct Shopify-connected SCA platform with:

- SCA Admin / CRM
- Collector Portal / My Collection
- Public QR registry
- Permanent certification records
- Claim ownership
- Ownership transfer
- Service history
- Lost/stolen state
- Managed PostgreSQL

Arianee introduces blockchain, wallet, smart-contract, key-management, and protocol complexity that is not required to deliver the current SCA business requirements.

The complete admin/customer experience Jeremy needs is also not treated as a drop-in self-hosted replacement for the SCA application.

## Approved Direction

Use the SCA application architecture already defined in this repository:

```text
Second Chance Eyewear Shopify
        |
        v
SCA Application / API
        |
        +--> Admin / CRM
        +--> Collector Portal
        +--> Public QR Registry
        |
        v
Managed PostgreSQL
```

The production app must connect to Jeremy's real Second Chance Eyewear Shopify store.

## Consequences

- Do not install Arianee.
- Do not add Arianee SDKs, wallets, contracts, tokens, nodes, or services to the SCA codebase.
- Do not make Arianee part of the MVP roadmap.
- If blockchain-backed provenance is ever reconsidered, it requires a new ADR and explicit business justification before implementation.

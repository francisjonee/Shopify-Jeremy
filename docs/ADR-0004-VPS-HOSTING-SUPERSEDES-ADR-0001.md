# ADR-0004 — VPS Hosting Is Now Available

**Status:** ACCEPTED

**Supersedes:** `ADR-0001-MANAGED-HOSTING.md` for the current deployment direction.

## Context

ADR-0001 was written when Jeremy did not have a usable server path for SCA, so managed hosting was selected to avoid requiring Jeremy to operate infrastructure.

That constraint has changed. A project VPS is now available and will be operated by an authorized technical operator. Jeremy remains the business owner; the existence or operation of the VPS does not create a separate business stakeholder.

## Decision

SCA may use the project VPS for the application/controller/runtime when that is the most practical deployment path.

The following requirements remain mandatory:

1. Run application and controller processes under non-root service accounts.
2. Keep secrets outside Git and outside the public architecture repository.
3. Use durable PostgreSQL storage with tested backup and restore procedures before permanent production provenance is trusted.
4. Use TLS, firewalling, patching, monitoring, process supervision, and recovery procedures appropriate for production.
5. Keep `secondchanceauthenticators.com` under Jeremy/authorized business control.
6. Permanent QR URLs must use a Jeremy-controlled domain and must not depend on a temporary VPS hostname.
7. Hosting must not change the SCA system-of-record boundaries: Shopify remains commerce source; SCA remains provenance/ownership source.
8. Production deployment still requires the explicit production approval required by the current task/governance rules.

## Consequences

- A separate managed PaaS is no longer required just because Jeremy has no server.
- Managed services may still be used where they reduce risk, especially for database backups or other infrastructure components.
- VPS availability does not authorize deployment by itself.
- ADR-0001 remains in Git history as the prior decision, but it no longer controls the current hosting direction.

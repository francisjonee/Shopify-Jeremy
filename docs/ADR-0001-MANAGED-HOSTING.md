# ADR-0001 — Managed Hosting, No Owner-Managed Server

**Status:** SUPERSEDED

**Superseded by:** `ADR-0004-VPS-HOSTING-SUPERSEDES-ADR-0001.md`

> Historical decision retained for context. The original constraint changed when a project VPS became available. ADR-0004 now governs the current hosting direction.

## Context

Jeremy owns the SCA domain but did not operate a server when this ADR was written. SCA requires an external web application/API and durable relational storage for permanent authentication, claim, ownership, transfer, and service records.

A self-managed VPS would add operating-system patching, firewall configuration, database administration, backups, TLS, process supervision, uptime monitoring, and recovery work that did not create product value under the original constraint.

## Original Decision

SCA would use managed cloud infrastructure rather than a Jeremy-operated server.

For the original production architecture:

1. **Application hosting:** managed PaaS/web service capable of running the selected SCA application stack.
2. **Database:** managed PostgreSQL with production-grade backups/recovery.
3. **Source:** GitHub repository is the deployment source.
4. **Secrets:** provider-managed environment variables/secrets; never Git.
5. **Domain:** Jeremy-controlled `secondchanceauthenticators.com` and/or a dedicated subdomain points to the managed application.
6. **QR permanence:** printed QR URLs use the Jeremy-controlled domain, never a temporary provider hostname.

### Original Provider Preference

Render was considered acceptable for an initial production deployment if the implementation stack and account capabilities supported the required runtime and managed PostgreSQL.

## Domain Principle That Still Applies

The root website can remain independent from the application host.

Potential application/public-record options include:

- `passport.secondchanceauthenticators.com`
- `app.secondchanceauthenticators.com`
- a permanent root-domain path such as `secondchanceauthenticators.com/p/<certification-id>`

The final public QR pattern must be selected before production QR codes are printed at scale.

## Requirements That Still Apply

- Production must not rely on an expiring/free database for permanent provenance records.
- Backups and restore procedures must be tested before treating SCA records as durable production history.
- DNS ownership must remain under Jeremy/authorized business control.
- Provider-specific behavior must not leak into permanent QR identifiers.

See ADR-0004 for the current VPS-based hosting direction.

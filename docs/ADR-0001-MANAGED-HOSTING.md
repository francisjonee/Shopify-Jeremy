# ADR-0001 — Managed Hosting, No Owner-Managed Server

**Status:** ACCEPTED

## Context

Jeremy owns the SCA domain but does not currently operate a server. SCA requires an external web application/API and durable relational storage for permanent authentication, claim, ownership, transfer, and service records.

A self-managed VPS would add operating-system patching, firewall configuration, database administration, backups, TLS, process supervision, uptime monitoring, and recovery work that does not create product value.

## Decision

SCA will use managed cloud infrastructure rather than a Jeremy-operated server.

For the initial production architecture:

1. **Application hosting:** managed PaaS/web service capable of running the selected SCA application stack.
2. **Database:** managed PostgreSQL with production-grade backups/recovery.
3. **Source:** GitHub repository is the deployment source.
4. **Secrets:** provider-managed environment variables/secrets; never Git.
5. **Domain:** Jeremy-controlled `secondchanceauthenticators.com` and/or a dedicated subdomain points to the managed application.
6. **QR permanence:** printed QR URLs use the Jeremy-controlled domain, never a temporary provider hostname.

### Initial Provider Preference

Render is acceptable for the first production deployment if the implementation stack and current account capabilities support the required runtime and managed PostgreSQL. The code should remain portable enough to move to another managed provider later without changing permanent QR identities.

## Recommended Domain Layout

The root website can remain independent from the application host.

Preferred application/public-record options:

- `passport.secondchanceauthenticators.com` — public QR/passport and collector-facing routes
- `app.secondchanceauthenticators.com` — admin/portal/API if separation is useful

A root-domain path such as `secondchanceauthenticators.com/p/<certification-id>` is also acceptable if routing can be made permanent.

The final public QR pattern must be selected before production QR codes are printed at scale.

## Consequences

### Benefits

- No physical or self-managed server required
- Faster deployment
- Managed TLS and platform operations
- Managed database backups/recovery
- Easier scaling and monitoring
- Hosting can be replaced without changing the SCA product model

### Requirements

- Production must not rely on an expiring/free database for permanent provenance records.
- Backups and restore procedures must be tested before treating SCA records as durable production history.
- DNS ownership must remain with Jeremy/authorized business administrators.
- Application portability must be preserved; provider-specific behavior must not leak into permanent QR identifiers.

## Rejected Alternative

**Self-managed VPS/server** — rejected for the initial system because it creates unnecessary operational risk and maintenance burden for Jeremy.

# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-DEMO-IP-004

## Title

Expose the existing Krayin staging CRM on the temporary VPS through a safe public IP demo endpoint

## Implementer

Claude

## Authority

ChatGPT accepted and merged `SCA-DOMAIN-DESIGN-003` PR #3 into `francisjonee/francisjonee-sca-platform-private` main.

Implementation merge commit:

`11f72ca2aa3b0c52badf8e4abfac431b378ebd7f`

The user needs a temporary public demo endpoint now, before SCA domain/DNS access is available.

This task temporarily takes priority over `SCA-DOMAIN-CORE-004`.

Authoritative implementation repository:

`francisjonee/francisjonee-sca-platform-private`

Existing staging facts from the accepted installation/hardening reports:

- Krayin v2.2.6 is already installed at `/opt/sca-platform`;
- app container currently publishes only to `127.0.0.1:8080`;
- MariaDB has no host port and must remain private;
- the VPS also hosts an unrelated live production tenant;
- ports 80/443 may already be owned by that other tenant/proxy;
- no real SCA/customer/provenance data may be added;
- current permanent SCA domain is not available for this task.

## Goal

Produce one externally reachable temporary development/demo URL using the VPS public IPv4 and a dedicated safe TCP port, for example:

`http://<PUBLIC_IPV4>:8080`

or another non-conflicting port if 8080 cannot be used safely.

The endpoint must show the existing Krayin admin login and allow an authorized presenter to sign in. It is explicitly a temporary staging/demo endpoint, not the production architecture.

## Required Work

1. Pull latest `Shopify-Jeremy/main` and this `NEXT_TASK.md`.
2. Pull/sync latest implementation `main` including merge commit `11f72ca2aa3b0c52badf8e4abfac431b378ebd7f`.
3. Before changing anything, inspect and record:
   - current VPS public IPv4 (`curl -4 ifconfig.me` or equivalent);
   - `ss -lntp` for 80, 443, 8080 and candidate alternate ports;
   - `docker ps` port mappings;
   - active host firewall rules (`ufw status`, nftables/iptables as applicable);
   - what currently owns ports 80/443;
   - enough information to prove the unrelated live tenant will not be disturbed.
4. Choose the least invasive demo exposure method. Preferred approach for this temporary task:
   - keep MariaDB private;
   - publish only the Krayin web app on one explicit non-conflicting host port;
   - do NOT take over ports 80/443 from the other tenant;
   - do NOT reconfigure the other tenant's reverse proxy unless absolutely unavoidable; if unavoidable, STOP and report instead of making the change;
   - do NOT require DNS.
5. Update only the minimum SCA-owned deployment configuration needed so the app listens on the chosen public host port rather than loopback-only. Prefer an explicit mapping such as `<PUBLIC_INTERFACE_OR_0.0.0.0>:<DEMO_PORT>:80` at the Docker publish layer, while preserving the database private network and existing container isolation.
6. If a host firewall is active, open only the chosen demo TCP port. Do not broadly disable the firewall.
7. Ensure Laravel/Krayin configuration is compatible with access by IP and the chosen port. Do not set or generate permanent QR URLs from this IP; `PUBLIC_QR_BASE_URL` remains out of scope.
8. Restart only the SCA containers/services required for this change. Do not restart the unrelated tenant.
9. Verify locally on the VPS:
   - `GET /` redirects to `/admin/login`;
   - `/admin/login` returns 200;
   - authenticated admin login still reaches `/admin/dashboard`;
   - SCA Foundation page still works;
   - MariaDB still has no public host port.
10. Verify externally against the PUBLIC IP and selected port, not only localhost. Confirm the login page is reachable from outside the VPS.
11. Do not print or commit the administrator password. If credentials need rotation, store them securely as already established and report only where the operator can retrieve them, never the secret itself.
12. Create a task report:

`docs/task-reports/SCA-DEMO-IP-004.md`

The report must include:
   - public IPv4;
   - exact demo URL;
   - selected public port and why;
   - before/after Docker port mappings;
   - firewall change, if any;
   - evidence ports 80/443 and unrelated tenant were untouched;
   - external HTTP verification results;
   - admin login/dashboard verification;
   - DB privacy verification;
   - rollback instructions;
   - security limitations of HTTP/IP staging;
   - exact commit SHA(s).
13. Make logical checkpoint commits for any repository configuration changes and the report. Push a branch:

`chore/sca-demo-ip-004`

Open/provide a PR into `main`, leave it unmerged for ChatGPT audit, then STOP.

## Security / Safety Rules

This is a temporary staging exposure. Therefore:

- NO real customer data;
- NO real provenance records;
- NO permanent QR codes/certificates;
- NO Shopify live-store connection;
- NO DNS changes;
- NO changes to `secondchanceauthenticators.com`;
- NO public MariaDB port;
- NO port ranges; expose one TCP port only;
- NO disabling the host firewall;
- NO weakening admin credentials;
- NO default `admin@example.com/admin123` account;
- NO APP_DEBUG=true;
- keep `APP_ENV=production` and debug off;
- do not disturb the unrelated production tenant;
- if safe exposure cannot be achieved without modifying/taking over that tenant's 80/443 proxy, STOP and report the blocker instead of proceeding.

## Acceptance Criteria

PASS only if all are true:

- a concrete externally reachable demo URL using the VPS public IPv4 exists;
- Krayin login page is reachable externally;
- authorized admin login/dashboard still works;
- SCA Foundation route still works;
- MariaDB remains private with no host/public port;
- only one explicit demo TCP port is exposed for SCA;
- ports 80/443 and the unrelated live tenant are untouched;
- APP_ENV remains production and debug remains off;
- no domain/DNS/Shopify/real-data/provenance work is introduced;
- changes are documented with rollback instructions;
- branch/PR is left unmerged for ChatGPT audit.

## Completion Rule

When finished, report the exact externally reachable URL in the task report and STOP.

Do not start `SCA-DOMAIN-CORE-004` until ChatGPT audits this demo deployment task.
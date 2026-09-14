# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-DEMO-IP-004

## Title

Expose the existing Krayin staging CRM on the temporary VPS as a governed living development preview

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
- app container originally published only to `127.0.0.1:8080`;
- MariaDB has no host port and must remain private;
- the VPS also hosts an unrelated live production tenant;
- ports 80/443 may already be owned by that other tenant/proxy;
- no real SCA/customer/provenance data may be added;
- current permanent SCA domain is not available for this task.

## Goal

Produce one externally reachable temporary development/demo URL using the VPS public IPv4 and a dedicated safe TCP port, for example:

`http://<PUBLIC_IPV4>:8080`

or another non-conflicting port if 8080 cannot be used safely.

This endpoint is not a one-time static demo. It becomes the governed **SCA Development Preview** that Jeremy/client stakeholders can revisit to see approved progress while the product is being built.

The preview must clearly identify itself as work in progress and must ultimately reflect only accepted/merged implementation work from `main`, never arbitrary unfinished feature branches.

## Living Preview Rule

After this task is accepted and merged:

`Claude implements -> PR -> ChatGPT audits -> accepted PR merges to main -> merged main is deployed to the same preview environment.`

Requirements:

- keep the same preview endpoint while this temporary IP environment remains in service;
- future accepted SCA milestones must be deployable to this same preview environment;
- do not auto-deploy unmerged branches or arbitrary commits;
- do not expose a feature merely because Claude has pushed it;
- the preview must represent governed/accepted work from `main` after the demo PR itself is merged;
- deployment/update procedure must be repeatable and documented;
- deployment must not reset/destroy required application state or permissions;
- deployment must preserve upload/storage functionality needed by the preview;
- the temporary IP must never become the permanent QR/public identity base URL.

## Required Work

1. Pull latest `Shopify-Jeremy/main` and this `NEXT_TASK.md` before completion. This amendment is authoritative even if implementation work began under the earlier task text.
2. Pull/sync latest implementation `main` including merge commit `11f72ca2aa3b0c52badf8e4abfac431b378ebd7f`.
3. Before changing anything, inspect and record:
   - current VPS public IPv4 (`curl -4 ifconfig.me` or equivalent);
   - `ss -lntp` for 80, 443, 8080 and candidate alternate ports;
   - `docker ps` port mappings;
   - active host firewall rules (`ufw status`, nftables/iptables as applicable);
   - what currently owns ports 80/443;
   - enough information to prove the unrelated live tenant will not be disturbed.
4. Choose the least invasive demo exposure method:
   - keep MariaDB private;
   - publish only the Krayin web app on one explicit non-conflicting host port;
   - do NOT take over ports 80/443 from the other tenant;
   - do NOT reconfigure the other tenant's reverse proxy unless absolutely unavoidable; if unavoidable, STOP and report instead of making the change;
   - do NOT require DNS.
5. Update only the minimum SCA-owned deployment configuration needed so the app listens on the chosen public host port rather than loopback-only. Prefer an explicit mapping such as `<PUBLIC_INTERFACE_OR_0.0.0.0>:<DEMO_PORT>:80` at the Docker publish layer, while preserving database private-network isolation.
6. If a host firewall is active, open only the chosen demo TCP port. Do not broadly disable the firewall.
7. Ensure Laravel/Krayin configuration is compatible with access by IP and chosen port. Do not set or generate permanent QR URLs from this IP; `PUBLIC_QR_BASE_URL` remains out of scope.
8. Add a visible development notice to the preview, using wording equivalent to:

   **SCA Development Preview — Work in Progress**

   `Features may be incomplete or temporarily unavailable while the platform is being built.`

   It must be visible enough that Jeremy/client stakeholders understand this is an active build, not a finished production system.
9. Restart only SCA containers/services required for the change. Do not restart the unrelated tenant.
10. Verify locally on the VPS:
   - `GET /` redirects to `/admin/login`;
   - `/admin/login` returns 200;
   - authenticated admin login reaches `/admin/dashboard`;
   - SCA Foundation page works;
   - development/WIP notice is present;
   - MariaDB has no public host port.
11. Verify externally against the PUBLIC IP and selected port, not only localhost. Confirm the login page and WIP identification are reachable from outside the VPS.
12. Do not print or commit the administrator password. If credentials need rotation, store them securely as already established and report only where the operator can retrieve them, never the secret itself.
13. Make the preview deployment repeatable. Add or update an SCA-owned deployment/update procedure or script so a future accepted `main` can be deployed safely to this same environment without manually re-creating demo fixes. It must include any required persistent permission repair/self-healing needed for uploads and runtime storage.
14. Create/update the task report:

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
   - WIP banner verification;
   - DB privacy verification;
   - upload/storage verification;
   - exact repeatable procedure for deploying future accepted `main` changes to this same preview;
   - proof that the procedure deploys governed `main`, not arbitrary feature branches;
   - rollback instructions;
   - security limitations of HTTP/IP staging;
   - exact commit SHA(s).
15. Make logical checkpoint commits for repository configuration/code/report changes. Push branch:

`chore/sca-demo-ip-004`

16. **Creating the pull request is part of the task, not an optional follow-up.** Open an actual GitHub PR into `main` with:
   - head: `chore/sca-demo-ip-004`
   - base: `main`
   - title containing `SCA-DEMO-IP-004`
   - task report included in the branch.

   Confirm the PR exists in GitHub and record/provide its PR number or URL. Do not merely push the branch and say a PR is ready to be created.
17. Leave the PR unmerged for ChatGPT audit and STOP.

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
- do not auto-deploy unmerged feature branches;
- if safe exposure cannot be achieved without modifying/taking over the other tenant's 80/443 proxy, STOP and report the blocker instead of proceeding.

## Acceptance Criteria

PASS only if all are true:

- a concrete externally reachable demo URL using the VPS public IPv4 exists;
- Krayin login page is reachable externally;
- authorized admin login/dashboard works;
- SCA Foundation route works;
- visible Development Preview / Work in Progress identification exists;
- MariaDB remains private with no host/public port;
- only one explicit demo TCP port is exposed for SCA;
- ports 80/443 and the unrelated live tenant are untouched;
- APP_ENV remains production and debug remains off;
- uploads/runtime permissions survive the documented redeploy process;
- a repeatable procedure exists for deploying future accepted `main` changes to the same preview;
- preview governance explicitly prevents arbitrary unmerged branch deployment;
- no domain/DNS/Shopify/real-data/provenance work is introduced;
- rollback is documented;
- an actual GitHub PR exists and its number/URL is provided;
- PR is left unmerged for ChatGPT audit.

## Completion Rule

When finished, report:

1. exact externally reachable preview URL;
2. exact implementation commit/head SHA;
3. actual GitHub PR number/URL;
4. confirmation that the PR remains unmerged.

Then STOP.

Do not start `SCA-DOMAIN-CORE-004` until ChatGPT audits and accepts this demo deployment task.
# NEXT TASK

**STATUS: CP-5 PHASE-A POST-DEPLOY AUDIT — PASS. Promote Phase B ONLY: minimal /u/* edge admission. Application baseline `0101755b03352305050b7b7290ad917b588112ff`, migrations 134. Do not change application/schema/DNS. Do not start CP-6.**

Updated 2026-10-09.

## Phase-A final verdict
**PASS.**

Independent audit verified:
- approved candidate `2d87c38dadb5af61a630805dc2da3a6e11eb2f02`;
- production/main/deployed `0101755b03352305050b7b7290ad917b588112ff`;
- candidate→merge = one merge commit, **zero changed files**;
- exact merge-tree full gate: 1188 passed / 6033 assertions / 1 accepted WebP skip / exit 0;
- production migration 134 and intended CP-5 schema;
- zero handle-bearing publication rows and zero tombstones created by migration;
- CP-3 immutability trigger unchanged;
- deterministic provenance row-data procedure now preserved in governance evidence;
- PRE == POST fingerprint `d15a5cbdfb8df52ba65628b276533cfe`;
- canonical counts unchanged `3/3/4/4/5/2/1/1/7`;
- collector/private/public/public-item counts 3/0/0/0;
- Stripe dormant, mail log;
- no Caddy/DNS/Shopify/SMTP change in Phase A;
- /u/* still externally Caddy-404 while application routes exist internally.

## CP-5 Phase B — edge admission only

Goal: admit the already-deployed `/u/*` namespace through the existing SCA public edge to the SAME `kr-app:80` upstream used by `/c/*`.

### Allowed change
Modify only the existing `verify.secondchanceauthenticators.com` public-path matcher in the live Caddyfile.

Current CP-3/CP-4 matcher is expected to include:
`@public path /p/* /collector /collector/* /c/*`

Add exactly:
`/u/*`

Expected result:
`@public path /p/* /collector /collector/* /c/* /u/*`

No other matcher, route, upstream, TLS, header, DNS, app, Docker app service, database, or co-tenant change.

### Preflight — STOP on drift
Before editing:
- implementation origin/main == deployed head == `0101755b03352305050b7b7290ad917b588112ff`;
- migration 134;
- exact current Caddyfile backed up with timestamp;
- verify current matcher and same `kr-app:80` upstream;
- external /u/ada = Caddy 404;
- external bogus /c/PUB ref = Apache/Laravel 404;
- /collector/login reachable;
- /admin/login restricted externally;
- external :8080 closed;
- co-tenant health;
- provenance fingerprint `d15a5cbdfb8df52ba65628b276533cfe` and canonical counts baseline;
- presentation counts including handle/tombstone 0 unless legitimate production activity has occurred; report any drift before proceeding.

### Validate before activation
Validate the edited Caddy config using the established safe validation method before applying it.
The config delta must be exactly the addition of `/u/*` to the existing public matcher.

### Activate
Use the established safe Caddy activation procedure for this host. If ordinary reload is known ineffective because of the readonly single-file mount, use the already-established Caddy-only force-recreate procedure.

Only the Caddy container may be recreated/reloaded.
Do not restart/recreate kr-app or MariaDB.

### External verification
Use syntactically valid bogus values; do NOT create production collector/profile/handle fixtures.

After activation:
- `GET /u/ada` → ordinary **Apache/Laravel 404**, proving /u reaches kr-app;
- `GET /u/ada/avatar` → Apache/Laravel 404;
- `GET /u/ada/items/<syntactically-valid-bogus-item-ref>/image` → Apache/Laravel 404;
- no redirect;
- no PUB ref/internal identity emitted in 404 body/headers;
- existing bogus `/c/PUB-...` remains Apache/Laravel 404;
- Passport bogus /p remains app-level reachable/404;
- /collector/login remains reachable;
- external /admin/login remains restricted;
- unrelated unknown path remains **Caddy 404**;
- external :8080 remains closed;
- co-tenant health unchanged.

### Invariants
After edge activation:
- implementation origin/main/deployed still exact `0101755b...`;
- migration still 134;
- run exact documented provenance fingerprint procedure: still `d15a5cbdfb8df52ba65628b276533cfe`;
- canonical counts still `3/3/4/4/5/2/1/1/7`;
- report collector/private/public/public-item/handle-bearing/tombstone counts;
- Stripe dormant;
- mail log;
- no DNS/Shopify/SMTP changes;
- only intended Caddy matcher delta.

### Evidence + STOP
Write CP-5 Phase-B edge-activation evidence including:
- before/after exact Caddy matcher;
- backup path;
- validation result;
- activation procedure and which container changed;
- external /u origin evidence (Caddy before → Apache/Laravel after);
- /c, /p, collector, admin, catch-all, :8080 and co-tenant regressions;
- implementation/deployed SHA and migration;
- provenance fingerprint/counts;
- presentation counts;
- Stripe/mail state;
- confirmation no app/schema/DNS/Shopify/SMTP change.

Then STOP for ChatGPT final CP-5 audit.
Do NOT declare CP-5 closed yourself.
Do NOT start CP-6.

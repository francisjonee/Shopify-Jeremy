# NEXT TASK

**STATUS: CP-3 PHASE-A POST-DEPLOY AUDIT — PASS. Promote Phase B: minimal production-edge activation for /c/* only. No application/schema/DNS changes. Do not start CP-4.**

Updated 2026-10-09.

## Phase-A closure
Authoritative implementation/deployed baseline:
`3e707582c21e40b97e909c8593987787fd4c33c4`
Production migrations: **132**.

ChatGPT independently verified:
- implementation `main == 3e707582...`;
- approved candidate `8aa8e801...` → merge has one merge commit and **zero file differences**;
- Phase-A deployment evidence documents exact audited 14-file scope and migration 131→132;
- `sca_collector_public_profiles` exists with required FK/uniques/index/immutability trigger and 0 rows;
- deploy gate 1106 passed / 5726 assertions / 1 accepted WebP skip;
- internal loopback /c bogus refs reach CP-3 ordinary 404;
- external /c remains edge-blocked as intentionally required;
- provenance fingerprint/counts unchanged;
- collector/private-profile/publication counts 3/0/0;
- Stripe dormant; mail log;
- no Caddy/DNS/Shopify/SMTP change in Phase A.

**Phase A PASS.**

## Phase B objective
Make the already-deployed CP-3 public routes externally reachable through the existing production Caddy site:
- `/c/{publicRef}`
- `/c/{publicRef}/avatar`

This is an **EDGE-ONLY** activation. The app and schema are already deployed and audited.

### Hard scope
Allowed:
- minimal Caddy routing change needed to admit `/c/*` to the same kr-app upstream/path handling used by existing public app routes;
- Caddy config validation/reload;
- rollback backup;
- read-only smoke;
- governance evidence.

Forbidden:
- NO implementation repo commit/code change;
- NO migration/schema/data mutation;
- NO DNS change;
- NO TLS/certificate policy redesign;
- NO broad catch-all admission;
- NO change to /admin restrictions;
- NO change to /p/* or /collector/* semantics except proving they remain intact;
- NO Stripe/SMTP/Shopify change;
- NO production collector/publication fixture creation just for smoke;
- NO CP-4.

## 1. Preflight — STOP on drift
Before touching Caddy:
- verify implementation `origin/main == deployed head == 3e707582c21e40b97e909c8593987787fd4c33c4`;
- verify production migration 132;
- verify publication table exists and report row count;
- capture provenance DATA fingerprint/counts and collector/private-profile/publication counts;
- verify Stripe dormant and mail log;
- capture current external results for:
  - bogus `/c/PUB-<32hex>`;
  - bogus `/c/PUB-<32hex>/avatar`;
  - bogus Passport `/p/...`;
  - unauthenticated `/collector/profile`;
  - `/admin/login`;
- capture matching internal loopback CP-3 bogus profile + avatar responses;
- capture current active Caddy config and identify the exact site/routing block responsible for admitting /p/* and /collector/*.

If implementation/deployment/schema state drifted, STOP.

## 2. Backup + proposed diff
Create a timestamped backup of the active Caddy configuration before editing.

Prepare the smallest possible diff:
- admit only path namespace `/c/*` (including `/c/{ref}` itself);
- send it to the same application upstream as the established public SCA app routes;
- preserve all existing admin/IP restrictions, catch-all behavior, headers, TLS, co-tenant routes, and unrelated site blocks.

Do not broaden to a generic application catch-all.

Record the exact before/after diff in the deployment evidence.

## 3. Validate before reload
Run the established Caddy formatter/validator against the candidate config.
Require validation success before reload.

If validation fails:
- restore/leave active config unchanged;
- STOP and report.

## 4. Activate with rollback ready
Reload Caddy using the established safe procedure.
Do not restart unrelated application/database services.

If reload fails or health checks regress:
- restore the exact backup;
- validate;
- reload rollback;
- verify prior edge behavior restored;
- STOP and report failure.

## 5. External smoke — no production fixture required
Use a syntactically valid bogus `PUB-` ref so the request can safely reach the CP-3 resolver without creating data.

Require externally:
- `GET /c/PUB-<32hex>` reaches the app-level CP-3 404;
- `GET /c/PUB-<32hex>/avatar` reaches the app-level 404;
- response status/body characteristics match the corresponding internal loopback CP-3 404 closely enough to prove Caddy is forwarding rather than serving its old edge catch-all;
- no internal path/upstream information leaks.

Because publication rows are currently expected to be 0, **do not create a real published collector solely to obtain a 200**. App tests already prove the 200 lifecycle on the identical deployed tree.

Regression smoke:
- public Passport behavior unchanged;
- unauthenticated collector profile/collection remain auth-redirected;
- /admin/login remains under its existing edge restriction;
- unknown/unadmitted unrelated paths retain existing catch-all behavior;
- co-tenant(s) remain healthy;
- direct external :8080 remains unavailable/loopback-only.

## 6. Post-change invariants
Verify:
- implementation deployed head/main unchanged at `3e707582...`;
- migration remains 132;
- publication row count unchanged by edge activation;
- provenance fingerprint/counts byte-identical;
- collector/private-profile/publication counts unchanged except independently occurring legitimate production activity (investigate/report any drift);
- Stripe dormant;
- mail log;
- DNS unchanged;
- no app/container rebuild/redeploy occurred;
- active Caddy config contains only the intended /c admission change relative to backup.

## 7. Evidence + STOP
Create `docs/SCA-COLLECTOR-PROFILE-CP3-PHASE-B-EDGE-ACTIVATION.md` (or equivalent) recording:
- baseline/deployed SHA;
- migration;
- preflight state;
- Caddy backup identifier/path (do not include secrets);
- exact sanitized before/after routing diff;
- validation/reload result;
- pre/post external + internal smoke;
- regression smoke;
- provenance/counts;
- Stripe/mail/DNS state;
- rollback status (not used, or exact evidence if used).

Update governance `NEXT_TASK.md` to report Phase B result and STOP.

Do not call CP-3 closed yourself. STOP for ChatGPT final CP-3 post-edge audit.
Do not start CP-4.

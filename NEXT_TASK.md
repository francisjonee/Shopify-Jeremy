# NEXT TASK

**STATUS: CP-5 FINAL AUDIT — PASS / CLOSED / PUBLICLY LIVE. Production app baseline `0101755b03352305050b7b7290ad917b588112ff`, migrations 134. `/u/*` edge admission LIVE. CP-6 may be architecture-audited next, but do not implement until ChatGPT promotes a new task.**

Updated 2026-10-09.

## CP-5 final closure verdict
**PASS — CP-5 CLOSED.**

### Authoritative production state
- Implementation repo: `francisjonee/francisjonee-sca-platform-private`
- Approved CP-5 candidate: `2d87c38dadb5af61a630805dc2da3a6e11eb2f02`
- Production/main/deployed app: `0101755b03352305050b7b7290ad917b588112ff`
- Production migrations: **134**
- Phase-A evidence: `docs/SCA-COLLECTOR-PROFILE-CP5-PHASE-A-DEPLOY-RESULT.md`
- Phase-B evidence: `docs/SCA-COLLECTOR-PROFILE-CP5-PHASE-B-EDGE-ACTIVATION.md`
- Phase-B governance evidence commit: `367edc7263fd4cdd85b4f38aecd5c9302bfa989d`

### Independent final audit findings
ChatGPT independently verified:
- implementation `main == 0101755b...` after Phase B;
- Phase-A merge tree was file-identical to the exact audited candidate;
- production migration 134 contains the intended CP-5 handle/tombstone presentation schema;
- CP-5 R1 collision contract was fixed and independently audited before merge;
- exact merge-tree gate was 1188 passed / 6033 assertions / 1 accepted WebP skip / exit 0;
- Phase B was edge-only;
- live Caddy matcher changed exactly from
  `@public path /p/* /collector /collector/* /c/*`
  to
  `@public path /p/* /collector /collector/* /c/* /u/*`;
- same `kr-app:80` upstream retained;
- Caddy config validated before activation;
- only `sr-caddy` recreated; kr-app and MariaDB untouched;
- external /u profile/avatar/item-image bogus requests changed from Caddy 404 to Apache/Laravel 404, proving correct app admission;
- no redirect and no PUB/COL/internal identity leak in the shared not-found response;
- /c and /p remain app-routed;
- collector login remains reachable;
- external admin restriction remains intact;
- unrelated unknown paths remain Caddy 404;
- external :8080 remains closed;
- co-tenant health unchanged;
- application SHA and migration unchanged during Phase B;
- reproducible provenance row-data fingerprint remains `d15a5cbdfb8df52ba65628b276533cfe`;
- canonical provenance counts remain `3/3/4/4/5/2/1/1/7`;
- collectors/private-profile/public-profile/public-item/handle-bearing/tombstone counts = `3/0/0/0/0/0` at final verification;
- Stripe remains dormant;
- `MAIL_MAILER=log`;
- no app/schema/DNS/Shopify/SMTP change in Phase B.

## CP-5 delivered boundary
CP-5 now provides:
- human-readable public handles as mutable aliases;
- immutable high-entropy PUB public_ref remains permanent identity/fallback;
- /u/{handle} public profile namespace;
- /u/{handle}/avatar;
- /u/{handle}/items/{itemRef}/image;
- lowercase conservative normalized syntax;
- centralized reserved names/prefixes;
- account-first lifecycle serialization;
- DB-backed collision authority;
- bounded concurrency retry + generic unavailable error contract;
- atomic rename/removal;
- no old-handle redirect;
- 90-day PII-free tombstones;
- unpublish preserves handle reservation and closes public route;
- republish restores same handle;
- pseudonymization tombstones then removes publication state atomically;
- no public availability/search/directory endpoint;
- handle routes reuse CP-3/CP-4 eligibility rather than forking privacy logic;
- opaque /c/PUB routes remain valid and unchanged;
- zero provenance coupling.

Core invariant:
**Handle = mutable presentation alias. PUB ref = permanent publication identity. Ownership ≠ publicity.**

## Reproducible provenance baseline
Use the exact 13-table row-data fingerprint procedure recorded in the CP-5 Phase-A deployment evidence for future deployment gates.

Current production baseline:
- fingerprint: `d15a5cbdfb8df52ba65628b276533cfe`
- canonical counts: `3/3/4/4/5/2/1/1/7`.

## Collector Profile roadmap
- CP-1 Private Profile Foundation — CLOSED
- CP-2 Rich My Collection — CLOSED
- CP-3 Public Profile Foundation — CLOSED / LIVE
- CP-4 Public Collection Controls — CLOSED / LIVE
- CP-5 Public Handle / Profile URL — **CLOSED / LIVE**
- CP-6 Collection Organization — NEXT, NOT STARTED

## Next initiative
Before implementation, ChatGPT must architecture-audit CP-6 against production baseline `0101755b...` / migration 134.

CP-6 must explicitly decide what “organization” means without duplicating provenance or public-visibility state. Audit at minimum:
- private collections/folders vs tags vs favorites;
- whether an item can belong to multiple user-defined groups;
- ordering/ranking semantics;
- rename/delete behavior;
- transfer/ownership-loss cleanup;
- reacquisition behavior;
- interaction with CP-4 public visibility;
- whether organization is private-only initially or any public grouping is in scope;
- pseudonymization cleanup;
- concurrency and stale-membership prevention;
- bounded queries/indexes;
- mobile/private My Collection UX;
- zero provenance mutation.

Do not infer CP-6 implementation from old roadmap notes.
Do not start coding until ChatGPT writes a promoted CP-6 task after architecture inspection.

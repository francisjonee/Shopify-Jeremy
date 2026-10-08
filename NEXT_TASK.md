# NEXT TASK

**STATUS: CP-3 PRE-MERGE RE-AUDIT — PASS. Exact candidate approved for application/schema merge + deployment. CP-3 is NOT CLOSED until a separate audited production-edge activation makes /c/* reachable. Do not start CP-4.**

Updated 2026-10-09.

## Exact audited candidate
Implementation repo: `francisjonee/francisjonee-sca-platform-private`
Branch: `feat/sca-collector-profile-cp3`
Production base: `a1e1d495d89d82fcfe921789e2b2bc4248874c0d`
**APPROVED CANDIDATE: `8aa8e8014ed2308f362972bb0c445ab1289dfb2f`**

Audit:
- 2 commits ahead / 0 behind exact production base;
- full candidate = exactly 14 intended CP-3 files;
- R1 delta from `76057cb...` = exactly 2 files: CollectorPublicProfileService + CollectorPublicProfileTest;
- R1 closes the identifying-avatar leak: page and avatar now share published + active + nonblank display-name eligibility;
- R1 uses real CP-1 `CollectorProfileService::saveProfile()`, keeps publication row/ref stable, and proves same ref reopens after restoring display name;
- migration remains the single additive CP-3 publication table, expected 131→132;
- original publication/privacy/concurrency/Passport/My Collection boundaries remain accepted.

Reported gates:
- CollectorPublicProfileTest 19 passed;
- CollectorPublicProfileConcurrencyTest 2 passed;
- focused CP-3 total 110 assertions;
- full SCA 1106 passed / 5726 assertions / 1 accepted WebP environment skip;
- production untouched at `a1e1d495...`, migration 131;
- provenance fingerprint `35e063282e004eaabcc9240360ecc0e3`;
- Stripe dormant; mail log.

## Important release split
The app defines `/c/{publicRef}` and `/c/{publicRef}/avatar`, but the current production edge does not yet admit the new `/c/*` namespace. CP-3 implementation explicitly forbade Caddy/DNS changes.

Therefore this approval is for **Phase A: application + migration deployment only**.
Do NOT change Caddy/DNS in this deployment.
Do NOT claim CP-3 publicly live or closed after Phase A.

After Phase A passes post-deploy audit, ChatGPT will promote a separate, minimal **Phase B production-edge activation** for `/c/*`, with edge rollback/smoke requirements. CP-4 remains blocked until CP-3 is fully closed.

## Phase A deployment gate

### 1. Preflight — STOP on drift
Verify before merge:
- `origin/main == a1e1d495d89d82fcfe921789e2b2bc4248874c0d`;
- branch/head == exact approved candidate `8aa8e8014ed2308f362972bb0c445ab1289dfb2f`;
- candidate is 2 ahead / 0 behind;
- diff remains exactly 14 intended CP-3 files;
- exactly one new migration, 131→132;
- deployed head still `a1e1d495...`;
- production migration 131;
- `sca_collector_public_profiles` absent pre-deploy;
- capture provenance DATA fingerprint/counts and collector/profile counts;
- Stripe dormant; mail log;
- capture current edge behavior for a safe bogus `/c/PUB-...` request.

Any drift => STOP.

### 2. Merge exact audited tree
Merge exact candidate using established no-ff process.
Record MERGE_SHA.
Require:
- origin/main == MERGE_SHA;
- candidate↔merge tree diff empty;
- no extra implementation content.

### 3. Test exact merge tree
Disposable DB:
- migrate through 132;
- CollectorPublicProfileTest;
- CollectorPublicProfileConcurrencyTest;
- CP-1 profile/privacy regressions;
- My Collection + Passport regressions;
- full `tests/Feature/Sca`.
Report exact counts. Only known WebP environment skip accepted.

### 4. Deploy application + migration only
Deploy exact MERGE_SHA using established process.
Run migration 131→132.
Verify:
- `sca_collector_public_profiles` exists;
- required FK/unique/index/defaults/immutability trigger exist;
- table initially contains zero rows unless legitimate production collector activity occurred after deployment; investigate/report any row rather than assuming;
- NO Caddy/DNS/edge configuration change.

### 5. Phase A production verification
Because `/c/*` is not yet edge-admitted, do NOT manufacture a production publication just for smoke.

Verify safely:
- deployed head == origin/main == MERGE_SHA;
- migration 132;
- application route list contains the two CP-3 public routes and private publish/unpublish routes with intended middleware;
- internal/loopback app-level request for bogus public ref reaches CP-3 and returns its ordinary 404 if safely possible without bypassing production security assumptions;
- unauthenticated private publish/unpublish remains collector-auth gated;
- existing Passport remains reachable/identity-free through its established public edge path;
- My Collection remains collector-authenticated;
- no public directory/search route;
- no CP-4 route;
- current external edge still does NOT admit /c/*; record exact status as expected Phase-A state, not a defect;
- provenance fingerprint/counts unchanged;
- collector/private-profile counts unchanged except ordinary production activity;
- publication table row count reported;
- Stripe dormant;
- mail log;
- no Caddy/DNS/Shopify/SMTP changes.

### 6. Report and STOP
Update/create CP-3 Phase-A deployment result documentation with:
- base/candidate/MERGE_SHA/origin-main/deployed-head;
- candidate↔merge tree identity;
- migration/schema verification;
- focused/full tests;
- app route/middleware verification;
- internal CP-3 route smoke if available;
- external edge /c/* still blocked, with observed result;
- Passport/My Collection checks;
- provenance pre/post fingerprint + counts;
- collector/profile/publication counts;
- Stripe/mail state;
- confirmation no Caddy/DNS change.

Then STOP for ChatGPT Phase-A post-deployment audit.
Do NOT modify Caddy/DNS.
Do NOT start CP-4.

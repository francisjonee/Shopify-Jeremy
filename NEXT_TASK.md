# NEXT TASK

**STATUS: CP-4 (Public Collection Controls) MERGED + DEPLOYED (prod main `7409a33`, migrations 133). Provenance byte-identical; Stripe DORMANT; mail=log; no Caddy/DNS change. STOP for ChatGPT CP-4 post-deployment audit. CP-4 NOT declared closed. Do not start CP-5.**

Updated 2026-10-09.

## Current deployed baseline (authoritative — single source of truth)
- Deployed implementation `main` = **`7409a33baecf2ef6bd8c44413a27a9f77fa249f1`** — CP-4 merged `--no-ff` + deployed; tree file-identical to audited candidate `2836114ef5dd7b48e16f696c9195d52125725e11` (base `3e70758`). Prior deployed: CP-3 Phase A+B `3e70758`.
- Governance/evidence repo = `francisjonee/Shopify-Jeremy`.
- Prod migrations **133** (132→133: additive `sca_collector_public_items`, **0 rows**; UNIQUE(collector,item) + 2 indexes + both FKs RESTRICT + is_visible default 0 + immutability trigger). Provenance DATA byte-identical pre/post (FP `35e063282e004eaabcc9240360ecc0e3`; items 3/qr 3/certs 4/auth 4/ownership 5/claims 2/grants 1/sale 1/status 7). Collector accounts 3 / private profiles 0 / public profiles 0 / public items 0.
- Public edge LIVE; admits `/p/*` + `/collector/*` + `/c/*` (CP-3 Phase B); `:8080` loopback-only; `MAIL_MAILER=log`; `STRIPE_*` UNSET.

## CP-4 — Public Collection Controls — DEPLOYED
`7409a33`, migr 132→133. Explicit per-item opt-in public visibility (ownership≠publicity; profile-publication≠item-publication). `CollectorPublicItemService` sole writer/resolver; ONE centralized eligibility predicate (CP-3 published + active + non-blank name + preference visible + current owner + non-adverse) backs the public collection list + image; `setVisible` serializes on the shared `sca_item_current_state` FOR UPDATE boundary and re-reads owner/registry under it (TOCTOU closed, R1); transactional reset at `ProjectionService::rebuild` covers all ownership+status writers; read predicate is defense-in-depth. Public `/c/{ref}` Collection section (allowlisted cards, no Passport link, empty hides totals) + `GET /c/{ref}/items/{itemRef}/image` (nosniff/no-store; within existing `/c/*` edge). Private toggle `POST`/`DELETE /collector/collection/{ref}/public`. Pseudonymization deletes CP-4 rows; CP-3 unpublish closes the surface, republish restores still-safe items. Deploy gate **1137 passed / 5864** (1 webp skip, no rg8 flake). Prod data byte-identical, public_items 0; Stripe DORMANT; mail=log. Evidence: `docs/SCA-COLLECTOR-PROFILE-CP4-{IMPLEMENTATION,DEPLOY-RESULT}.md`. **STOP for ChatGPT CP-4 post-deployment audit of `7409a33`. CP-4 NOT closed; CP-5 NOT started.**

### Prior deployed baseline (superseded by CP-4 `7409a33`)
- `3e707582c21e40b97e909c8593987787fd4c33c4` — CP-3 Public Profile Foundation (app + edge), migr 132. Prior: CP-2 `a1e1d49` (131), CP-1 `8d8c359` (131).

## Exact audited candidate
Implementation repo: `francisjonee/francisjonee-sca-platform-private`
Branch: `feat/sca-collector-profile-cp4`
Production base: `3e707582c21e40b97e909c8593987787fd4c33c4`
**APPROVED CANDIDATE: `2836114ef5dd7b48e16f696c9195d52125725e11`**

GitHub audit:
- full candidate: 3 commits ahead / 0 behind exact base;
- 14 files total: original 13 CP-4 files plus the dedicated concurrency test;
- R1 delta from `e041eea...`: exactly CollectorPublicItemService + CollectorPublicItemConcurrencyTest;
- migration unchanged, single additive 132→133.

## R1 closure
PASS.

`CollectorPublicItemService::setVisible()` now:
1. locks active collector account;
2. requires CP-3 publication;
3. resolves item ref;
4. locks the canonical `sca_item_current_state` row FOR UPDATE;
5. re-reads current owner + registry status under that lock;
6. only then writes visibility=true.

This closes the stale-eligibility TOCTOU:
- if visibility holds item-state first, ownership/status rebuild must wait and then resets visibility in its transaction;
- if ownership/status mutation commits first, visibility's locked re-read sees new owner/adverse state and fails closed.

Public reads independently retain current-owner/non-adverse checks.

### Lock-order audit
Accepted:
- Claim and Transfer take collector account before their item-state synchronization boundary;
- CP-3 publish/unpublish and privacy use account-first lifecycle serialization;
- OwnershipCorrection/Commerce/status paths do not acquire a collector account lock after item-state, so no account↔item inversion is introduced;
- setPrivate only makes state more private and does not participate in eligibility publication.

Note: do not describe every writer as universally account→item-state; some item-only writers exist. The accepted property is **no writer acquires account after item-state**.

### Concurrency proof
Accepted:
- dedicated second MariaDB connection;
- racer holds the exact `sca_item_current_state` FOR UPDATE boundary;
- main `setVisible()` demonstrably blocks with lock-wait timeout and writes no preference;
- after racer commits ownership/status state + visibility reset, retry re-reads under lock and fails closed;
- transfer case proves recipient inherits no preference and reacquisition stays private until explicit opt-in;
- adverse case proves recovery stays private until explicit opt-in;
- original sequential pi18/pi19 real-writer tests remain.

The concurrency harness directly exercises the synchronization boundary rather than invoking full TransferService/StatusService on the racer connection. This is accepted because inspected production writers converge on that same locked projection row/rebuild boundary, while sequential integration tests exercise the real writers end-to-end.

## Reported test gate
- CollectorPublicItemTest: 29 passed;
- CollectorPublicItemConcurrencyTest: 2 passed;
- focused total: 31 passed;
- full SCA: 1137 passing, 1 accepted WebP environment skip;
- one run hit known unrelated QrReissueTest::rg8 rebuilt_at timing flake; isolated rerun 11/11. Treat any materially different/repeated failure as STOP, not automatically accepted.

## Deployment gate

### 1. Preflight — STOP on drift
Verify:
- origin/main == deployed head == `3e707582c21e40b97e909c8593987787fd4c33c4`;
- branch/head == exact approved `2836114ef5dd7b48e16f696c9195d52125725e11`;
- candidate remains 3 ahead / 0 behind;
- diff remains exactly the audited 14 files;
- exactly one new migration, expected 132→133;
- production migration 132;
- `sca_collector_public_items` absent pre-deploy;
- capture provenance fingerprint/counts;
- capture collector/private-profile/public-profile counts;
- Stripe dormant; mail log;
- active Caddy still admits /c/* from CP-3.

Any drift => STOP.

### 2. Merge exact audited tree
Merge using established no-ff process.
Record MERGE_SHA.
Require:
- origin/main == MERGE_SHA;
- candidate↔merge tree diff empty;
- no extra implementation content.

### 3. Test exact merge tree
Disposable DB migrated through 133.
Run:
- CollectorPublicItemTest;
- CollectorPublicItemConcurrencyTest;
- CP-3 public profile + concurrency;
- CP-2 My Collection;
- transfer/status/privacy/Passport regressions;
- full tests/Feature/Sca.
Report exact pass/assertion/skip counts.
Known WebP environment skip accepted.
QrReissue rg8 may only be classified as known timing flake if isolated rerun is clean and there is no CP-4 causal signal; otherwise STOP.

### 4. Deploy app + migration
Deploy exact MERGE_SHA using established procedure.
Run migration 132→133.
Verify:
- `sca_collector_public_items` exists;
- FK/unique/index/default-private/immutability trigger present;
- row count initially 0 unless legitimate production activity occurred after deploy; investigate/report nonzero;
- no Caddy/DNS change required.

### 5. Production smoke without creating public fixtures
Because production currently has 0 CP-3 public-profile rows, do not create collector/item publication solely for smoke.

Verify:
- deployed head == origin/main == MERGE_SHA;
- migration 133;
- CP-4 private POST/DELETE routes registered behind collector auth;
- nested public image route under /c/* registered unauthenticated at app layer;
- external syntactically valid bogus nested CP-4 image URL reaches kr-app/Laravel ordinary 404 through existing /c/* edge admission;
- bogus CP-3 profile behavior remains app-level 404;
- /collector collection/profile remain auth gated;
- Passport remains identity-free/reachable;
- /admin restriction unchanged;
- unrelated edge catch-all unchanged;
- direct :8080 remains unavailable externally;
- no CP-5 routes;
- provenance fingerprint/counts unchanged;
- collector/private-profile/public-profile/public-item counts reported;
- Stripe dormant; mail log;
- no Caddy/DNS/Shopify/SMTP changes.

### 6. Evidence + STOP
Create/update CP-4 deployment result documentation with:
- base/candidate/MERGE_SHA/origin-main/deployed-head;
- candidate↔merge tree identity;
- migration/schema;
- focused/full tests;
- route/middleware and external nested-image 404 origin evidence;
- CP-3/Passport/collector/admin/edge regression smoke;
- provenance/counts;
- Stripe/mail state;
- confirmation no Caddy/DNS/Shopify/SMTP change.

Then STOP for ChatGPT CP-4 post-deployment audit.
Do NOT declare CP-4 closed yourself.
Do NOT start CP-5.

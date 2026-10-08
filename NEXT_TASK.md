# NEXT TASK

**STATUS: CP-2 PRE-MERGE AUDIT PASS — exact candidate approved for merge/deployment. CP-3 remains forbidden.**

Updated 2026-10-09.

## Exact audited candidate
Implementation repo: `francisjonee/francisjonee-sca-platform-private`
Branch: `feat/sca-collector-profile-cp2`
Audited production base: `8d8c35947d7c405124e0df4f09ff3ef4ee9e6bb8`
**APPROVED CANDIDATE: `5ebe9591a530874f5376296a2e10f538772834e8`**

GitHub audit:
- candidate is 2 commits ahead / 0 behind exact base;
- candidate contains only the four intended CP-2 files;
- no migration/schema change;
- remediation delta from `eddac539` is exactly the same four CP-2 files;
- R1 admin-correction chronology uses real `OwnershipCorrectionService::correct()`;
- R2 header name is derived only from authenticated collector canonical `display_name`, trimmed with neutral fallback;
- R3 `collectionStats()` is one bounded SQL aggregate preserving current-owner/current-cert/distinct-known-brand semantics;
- original CP-2 current-owner isolation, search/filter/sort, pagination, safe card DTO, authorized image route, Passport privacy and no-N+1 design remain intact.

Reported gates accepted for promotion:
- RichMyCollectionTest 27 passed;
- MyCollectionTest 12 passed;
- CollectorProfileTest 32 passed / 1 WebP environment skip;
- full SCA 1085 passed / 5608 assertions / 1 WebP skip.
Production reported untouched at `8d8c359`, migration 131, provenance fingerprint `35e063282e004eaabcc9240360ecc0e3`, Stripe dormant, mail log.

## Deployment instructions
Deploy ONLY the exact audited candidate above.

### 1. Preflight — STOP on any drift
Before merge:
- fetch origin;
- verify `origin/main == 8d8c35947d7c405124e0df4f09ff3ef4ee9e6bb8`;
- verify branch/head == exact approved candidate `5ebe9591a530874f5376296a2e10f538772834e8`;
- verify candidate is 2 ahead / 0 behind base;
- verify diff remains exactly the four CP-2 files and NO migration;
- verify production deployed head is still `8d8c359...`;
- verify prod migration level 131;
- capture pre-deploy provenance DATA fingerprint/counts;
- verify Stripe remains dormant and mail remains log.

If ANY value differs, STOP without merge/deploy and report drift.

### 2. Merge exact audited tree
Merge the exact candidate to main using the established no-ff process.
After merge:
- record MERGE_SHA;
- verify `origin/main == MERGE_SHA`;
- verify merged tree is file-identical to approved candidate (empty tree diff candidate↔merge);
- no additional commit/content may enter the deployment.

### 3. Test gate before production cutover
On the exact merge tree / disposable test DB:
- run RichMyCollectionTest;
- run MyCollectionTest;
- run CollectorProfileTest;
- run full `tests/Feature/Sca` gate;
- report exact pass/assertion/skip counts.
Only the known environment WebP skip is acceptable. Any real failure => STOP before production deploy.

### 4. Deploy
Deploy exact MERGE_SHA using the established production deployment procedure.
There is NO migration in CP-2:
- production migration level must remain 131;
- do not create/alter/drop schema.

### 5. Production smoke — read-only / safe
Verify at minimum:
- unauthenticated `/collector/collection` redirects to collector login;
- authenticated collector collection page loads;
- header shows canonical display name when present or neutral My Collection when absent;
- summary counts render;
- search/filter/sort GET controls work;
- invalid query values fail safely;
- filtered-no-result state differs from true-empty state where safely testable;
- card links go to existing owner detail;
- card images continue through existing authorized route;
- previous/non-owner refs remain privacy-safe;
- public Passport remains collector-identity-free;
- no raw storage path/internal id/token/frame_serial/staff/Shopify data appears;
- no CP-3/public collector route exists.

Do not create production provenance merely to manufacture smoke fixtures. Use existing safe records/accounts where available; otherwise prove route/config/render boundaries without mutation.

### 6. Post-deploy invariants
Verify:
- DEPLOYED_HEAD == MERGE_SHA == origin/main;
- migration remains 131;
- provenance DATA fingerprint/counts are byte-identical to pre-deploy;
- collector account/profile counts unchanged except ordinary pre-existing production activity not caused by deployment (if any drift exists, investigate and report rather than hand-wave);
- Stripe remains DORMANT (`STRIPE_ENABLED=false`, secrets unset as expected);
- mail remains `MAIL_MAILER=log`;
- no Stripe/SMTP/Shopify/Caddy/DNS changes.

### 7. Report and STOP
Create/update a CP-2 deployment result document in governance and report:
- approved candidate;
- base;
- MERGE_SHA / origin main / deployed head;
- exact diff/tree identity proof;
- migration pre/post;
- focused/full test counts;
- production smoke;
- provenance pre/post fingerprint + counts;
- collector account/profile counts;
- Stripe/mail state;
- any flake/skip and rerun evidence.

Then **STOP for ChatGPT post-deployment audit. Do NOT start CP-3.**

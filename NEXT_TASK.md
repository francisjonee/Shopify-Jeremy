# NEXT TASK

**STATUS: CP-5 PHASE A DEPLOYED — awaiting ChatGPT Phase-A post-deployment audit. MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `0101755b03352305050b7b7290ad917b588112ff` (merged `--no-ff` from approved candidate `2d87c38`, tree-identical; base `7409a33`). Prod migration 133→134 (handle columns + additive tombstone table `sca_collector_handle_reservations`, 0 rows); CP-3 immutability trigger unchanged. Provenance row-data fingerprint `d15a5cbdfb8df52ba65628b276533cfe` byte-identical PRE/POST; canonical counts `3/3/4/4/5/2/1/1/7` unchanged. Full gate exit 0 / 1188 passed / 1 skipped(webp) / 0 failed. `/u/*` still externally **Caddy-404** (edge NOT activated); routes verified at app layer only. Stripe DORMANT; mail=log; no Caddy/DNS/Shopify/SMTP change. Evidence: `docs/SCA-COLLECTOR-PROFILE-CP5-PHASE-A-DEPLOY-RESULT.md`. Do NOT activate `/u/*` edge. Do NOT declare CP-5 closed. Do NOT start CP-6. STOP for Phase-A post-deployment audit; Phase B (`/u/*` edge admission) is a separate task after this audit.**

Updated 2026-10-09.

## Exact audited candidate
Implementation: `francisjonee/francisjonee-sca-platform-private`
Branch: `feat/sca-collector-profile-cp5`
Base: `7409a33baecf2ef6bd8c44413a27a9f77fa249f1`
Approved candidate: `2d87c38dadb5af61a630805dc2da3a6e11eb2f02`
Migration: 133→134.

GitHub audit:
- candidate is 2 commits ahead / 0 behind exact base;
- original bounded CP-5 change remains 14 files;
- R1 delta `681bc45 → 2d87c38` is exactly 2 files: CollectorHandleService + CollectorHandleConcurrencyTest.

## R1 closure — PASS
The collision/error contract is now accepted.

`setHandle()`:
- runs each write attempt as one transaction;
- bounded `MAX_ATTEMPTS=3`;
- Laravel transaction retry is confirmed against the exact locked framework dependency, Laravel v12.66.0 / framework ref `82a53323c701a668f9054cbeb1d6b6cdbb6a5e10`;
- that framework's ConcurrencyErrorDetector explicitly recognizes MariaDB deadlock text and `Lock wait timeout exceeded; try restarting transaction`;
- after retries, 1062/1205/1213 map to the same domain-safe `HandleRejection::UNAVAILABLE`;
- other DB errors are not broadly swallowed;
- rollback prevents partial handle/tombstone state.

The strengthened cc1 no longer accepts raw SQL as PASS:
- terminal result must be exactly generic UNAVAILABLE;
- raw QueryException is classified as failure;
- losing handle remains unset;
- no partial tombstone;
- exactly one winner.
cc2 retains rename/tombstone no-window proof.

Accepted clean gate evidence:
**1188 passed / 6033 assertions / 1 known WebP environment skip / 0 failed / exit 0** after competing runner stood down.

## Provenance reconciliation
Canonical production counts match the independently closed CP-4 baseline exactly:
`items/qr/certs/auth/ownership/claims/grants/sale/status = 3/3/4/4/5/2/1/1/7`.

The earlier `532ea48d...` was a different reduced count-hash and is rejected as a provenance fingerprint.

Historical `35e063282e004eaabcc9240360ecc0e3` was a composite row-DATA fingerprint, but its exact SQL was not preserved in current governance evidence and was not independently reproducible in this audit. Do not claim it was reverified.

### Restore stronger reproducible fingerprinting now
Before Phase-A deployment, create and document a deterministic READ-ONLY provenance row-data fingerprint procedure:
- include the canonical provenance tables used by the prior invariant;
- deterministic column selection and row ordering;
- exclude migrations/presentation tables;
- record the SQL/script itself in deployment evidence;
- capture PRE_DEPLOY fingerprint and canonical counts.
Run the exact same documented procedure POST_DEPLOY and require byte-identical fingerprint + counts.
This becomes the reproducible baseline for future slices.
Do not mutate provenance to manufacture a match with the historical hash.

## CP-5 Phase A deployment gate

### 1. Preflight — STOP on drift
Verify:
- origin/main == deployed head == exact base `7409a33baecf2ef6bd8c44413a27a9f77fa249f1`;
- branch/head == exact approved `2d87c38dadb5af61a630805dc2da3a6e11eb2f02`;
- candidate remains 2 ahead / 0 behind;
- full candidate remains exactly the audited 14 CP-5 files;
- exactly one migration 133→134;
- production migration 133;
- handle columns + reservation table absent;
- canonical provenance counts exact baseline above;
- capture NEW documented reproducible row-DATA fingerprint;
- collector/private-profile/public-profile/public-item counts;
- Stripe dormant; mail log;
- /u/* externally edge-blocked by Caddy;
- /c/*, /p/*, /collector/* current behavior intact.

Any drift => STOP.

### 2. Merge exact candidate
Merge using established no-ff process.
Record MERGE_SHA.
Require:
- origin/main == MERGE_SHA;
- candidate↔merge tree diff empty;
- no extra content.

### 3. Test exact merge tree
Use isolated disposable DB through migration 134, with no competing test runner.

Run:
- CollectorHandleTest;
- CollectorHandleConcurrencyTest;
- CP-3 public profile + concurrency;
- CP-4 public item + concurrency;
- CP-1 privacy/profile;
- Passport regressions;
- full `tests/Feature/Sca`.

Report exact pass/assertion/skip/exit counts.
A raw 1205/1213 escaping CP-5 collision tests is STOP.

### 4. Deploy Phase A application + schema only
Deploy exact MERGE_SHA.
Run migration 133→134.

Verify schema:
- handle, handle_normalized, handle_changed_at present on publication table;
- unique `uniq_public_profile_handle`;
- CP-3 public_ref/account immutability trigger unchanged;
- `sca_collector_handle_reservations` present;
- unique normalized tombstone;
- reusable_after index;
- no collector/public_ref/PII linkage in tombstone;
- existing public-profile/public-item rows unaffected;
- no handle/tombstone rows unexpectedly created by migration.

### 5. Phase-A production smoke — NO edge activation
Do NOT edit/reload/recreate Caddy.

Verify app internally/loopback:
- /u/{handle}, /u/{handle}/avatar, /u/{handle}/items/{itemRef}/image routes registered;
- malformed/unknown app-level requests fail closed;
- private POST/DELETE handle routes collector-authenticated + throttle 10/min;
- no availability/search/directory route;
- /c opaque routes unchanged;
- CP-4 opaque image route unchanged;
- Passport identity-free;
- collector auth unchanged.

Verify externally:
- /u/ada remains **Caddy 404** (not Apache/Laravel) — expected Phase-A state;
- /c/* and /p/* remain routed as before;
- collector auth behavior unchanged;
- admin restriction unchanged;
- unrelated edge catch-all unchanged;
- external :8080 closed;
- co-tenant health unchanged.

Do not create production collector/public fixtures solely for smoke.

### 6. Invariants
POST_DEPLOY run the exact same newly documented row-DATA fingerprint procedure and canonical count query.
Require:
- PRE == POST fingerprint byte-for-byte;
- canonical provenance counts unchanged `3/3/4/4/5/2/1/1/7`;
- report collector/private-profile/public-profile/public-item counts;
- report handle-bearing publication count + tombstone count;
- Stripe dormant;
- mail log;
- no Shopify/SMTP/DNS/Caddy changes.

### 7. Evidence + STOP
Write CP-5 Phase-A deployment evidence containing:
- base/candidate/MERGE_SHA/origin-main/deployed-head;
- candidate↔merge tree identity;
- migration/schema;
- exact reproducible provenance fingerprint SQL/script + PRE/POST values;
- canonical counts PRE/POST;
- focused/full tests;
- route/middleware smoke;
- proof external /u remains Caddy-blocked;
- /c, /p, collector/admin/edge/co-tenant regressions;
- Stripe/mail state;
- confirmation no Caddy/DNS/Shopify/SMTP change.

Then STOP for ChatGPT Phase-A post-deployment audit.

Do NOT activate /u/*.
Do NOT declare CP-5 closed.
Do NOT start CP-6.

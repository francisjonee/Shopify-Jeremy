# NEXT TASK

**STATUS: CP-5 PRE-MERGE AUDIT — FAIL. R1 collision/error-contract remediation + clean gate required. Do not merge/deploy or start CP-6.**

Updated 2026-10-09.

## Audited candidate
Implementation repo: `francisjonee/francisjonee-sca-platform-private`
Branch: `feat/sca-collector-profile-cp5`
Base: `7409a33baecf2ef6bd8c44413a27a9f77fa249f1`
Candidate: `681bc45`
GitHub compare: 1 ahead / 0 behind, exactly 14 intended CP-5 files, one migration 133→134.

## Accepted architecture
The following is accepted:
- handle remains mutable alias; immutable PUB ref unchanged;
- separate /u namespace;
- centralized normalizer/reserved policy;
- handle state on publication identity;
- PII-free 90-day tombstones;
- no old-handle redirect;
- unpublish preserves handle;
- privacy tombstones handle in same privacy transaction;
- handle routes resolve to public_ref then reuse CP-3/CP-4 eligibility;
- no directory/search/availability endpoint;
- /u remains edge-blocked in Phase A;
- migration remains presentation-only.

## R1 BLOCKER — concurrency test accepts raw DB errors instead of required generic unavailable contract

The promoted CP-5 requirement was:
**real two-connection simultaneous same-handle claim: exactly one wins, loser receives the same generic handle-unavailable domain result, no SQL/owner details leak, no partial state.**

Current `CollectorHandleConcurrencyTest::claimIsBlocked()` explicitly treats raw MariaDB lock-wait/deadlock exceptions 1205/1213 as the PASS outcome.

But `CollectorHandleService::setHandle()` catches only duplicate-key 1062 and maps that to `HandleRejection::UNAVAILABLE`. It rethrows 1205/1213.

Therefore the current test proves that under its contention schedule the loser can receive a raw QueryException rather than the required domain-safe unavailable result. Through the controller this can become a 500 instead of the generic handle-unavailable flash response.

This is not merely test wording: the test's accepted outcome contradicts the CP-5 external error contract.

### Required remediation
Implement and prove a bounded contention policy.

Preferred:
- use a small bounded transaction retry for deadlock/serialization failures if Laravel/MariaDB semantics permit safely, then let the committed winner be observed and map the losing claim to generic UNAVAILABLE;
- OR safely map only contention outcomes that can occur during handle-claim arbitration to generic UNAVAILABLE, with no SQL details exposed;
- preserve atomic rollback: no partial tombstone/current-handle state;
- do not hide unrelated DB/infrastructure errors broadly.

The exact implementation may differ, but the externally observable result for a genuine same-handle race must be:
- one claimant succeeds;
- the other gets `HandleRejection::UNAVAILABLE` (or controller-equivalent generic unavailable), NOT QueryException/500;
- one active handle owner;
- no partial rows/tombstones.

## Mandatory concurrency remediation test
Replace/strengthen cc1 so BOTH contenders execute the real handle-claim service path as far as technically possible.

The assertion must NOT accept 1205/1213 as final success criteria.

After contention settles:
- exactly one service claim succeeds;
- loser resolves to generic UNAVAILABLE;
- exactly one publication row owns normalized handle;
- losing collector handle remains null/unchanged;
- no unintended tombstone;
- no raw SQL exception escapes.

If a deterministic harness must hold the unique key with a second connection, after releasing/committing the racer the service-side contender must complete/retry into the domain-safe unavailable result; a raw lock timeout is only an intermediate observation, never the final asserted API outcome.

Retain cc2 rename/tombstone no-window proof, but ensure any service-side contention also has domain-safe behavior.

## R2 RELEASE-GATE EVIDENCE — clean full suite required after peer process stopped
The report explains that a second Claude session was concurrently using the SAME bind-mounted tree and disposable DB, causing random deadlocks. That explanation is plausible, but the candidate report does not provide one authoritative clean full-suite pass/count after the peer stood down.

After remediation and with no competing process:
- reset/recreate disposable test DB as established;
- verify only one test runner owns it;
- run focused CP-5 tests;
- CP-3/CP-4/public-profile/concurrency/privacy/Passport regressions;
- run ONE clean full `tests/Feature/Sca` gate to completion;
- report exact passed/assertion/skipped counts and exit code.
Do not aggregate isolated reruns into the release gate.

## R3 EVIDENCE RECONCILIATION — production provenance baseline
The candidate report states production provenance FP `532ea48d…` and shorthand counts `3/3/4/4/5/2/7`, while the independently closed CP-4 production baseline was:
- DATA fingerprint `35e063282e004eaabcc9240360ecc0e3`
- items/qr/certs/auth/ownership/claims/grants/sale/status = `3/3/4/4/5/2/1/1/7`.

Do NOT mutate production.
Re-run the exact established CP-4 provenance fingerprint/count command against production and reconcile whether the CP-5 report used a different fingerprint algorithm/column set or whether actual drift exists.
- If same established command returns `35e063...` and canonical counts, document the earlier CP-5 shorthand as reporting-method mismatch.
- If canonical production data actually changed, STOP and report the exact drift before any merge.

Also reconfirm production is restored to `main@7409a33...`, migration 133, CP-5 schema absent, Stripe dormant, mail log, /u edge-blocked.

## Re-run
Migration may remain 133→134.
Push remediation on SAME CP-5 branch.
Report:
- new head;
- exact delta from 681bc45;
- collision/error-handling design;
- concurrency outcomes;
- focused counts;
- ONE clean full-suite count/assertions/skips/exit;
- reconciled canonical production provenance baseline;
- production untouched;
- no Caddy/DNS/Stripe/SMTP/Shopify changes.

Then STOP for ChatGPT re-audit.
Do not merge/deploy.
Do not start CP-6.

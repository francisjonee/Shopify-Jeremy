# NEXT TASK

**STATUS: CP-1 RE-AUDIT — FAIL / FINAL LIFECYCLE CONSISTENCY REMEDIATION. Do not merge/deploy or start CP-2.**

Updated 2026-10-09.

## Audit target
Base: `f461c17b7e0cbd5a5e5f026d5f5000870ef04752`
Candidate: `bd32988ead30ada09a36726be165c3ef8aebe5d0`
Branch: `feat/sca-collector-profile-cp1`
Head 3 ahead / 0 behind base. Migration unchanged 130→131. Production untouched.

## Re-audit
R1–R5 core fixes are accepted. Account-first locking in `withProfile()` correctly serializes saveProfile/setAvatar against pseudonymization and removes the broad 1062 retry.

**One remaining blocker: `removeAvatar()` is still a separate profile mutation path that does NOT acquire/revalidate the canonical collector account row.**

The R5 requirement was every profile mutation at the service/write boundary. `removeAvatar()` currently locks only `sca_collector_profiles`. This creates an inconsistent lock order with `pseudonymize()` (privacy locks account then profile), and an already-authorized in-flight remove request can still mutate profile state without proving the account remains active. Even though removal cannot resurrect PII, leaving one mutation outside the lifecycle boundary defeats the single serialization rule and can create avoidable account/profile lock-order contention.

## R6 — required
Bring `removeAvatar()` under the SAME account-first lifecycle serialization rule:
- lock canonical collector account first;
- require `status='active'` inside the transaction;
- then lock/mutate profile;
- on lifecycle rejection, controlled fail-closed behavior in controller (same logout/redirect policy is acceptable);
- preserve pointer-first then post-commit byte deletion semantics;
- no provenance mutation.

Prefer reusing the same internal lifecycle/write primitive rather than duplicating account-status logic, but do not create a profile row merely to remove a nonexistent avatar.

Add focused coverage proving:
1. remove works for active collector and deletes pointer/bytes;
2. disabled/pseudonymized/in-flight-after-privacy remove is rejected cleanly and does not recreate/mutate profile;
3. lock ordering is account-first and compatible with privacy (two-connection test if needed to prove the race);
4. provenance unchanged.

Retain R1–R5 tests and full SCA gate. Migration stays 130→131.

Push on SAME branch, update implementation report, report new head/test counts, then STOP for re-audit.

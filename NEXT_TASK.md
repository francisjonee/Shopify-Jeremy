# NEXT TASK

**STATUS: CP-1 R6 REMEDIATED (removeAvatar lifecycle consistency) — CANDIDATE awaiting ChatGPT final re-audit. Do not merge/deploy or start CP-2.**

Updated 2026-10-09.

## Re-audit target
Base: `f461c17b7e0cbd5a5e5f026d5f5000870ef04752`
Candidate: **`cc6d0537ecdb8df3ae5a5242298ab9c562d5d40e`** (R6 fix on `bd32988`; branch `feat/sca-collector-profile-cp1`, now 4 commits ahead / 0 behind base). Migration remains 130→131 (one additive table; prod still 130). Production untouched; Stripe DORMANT.

### R6 remediation summary (final lifecycle-consistency blocker addressed; 4 files changed from `bd32988`)
`removeAvatar()` now goes through the SAME account-first lifecycle gate as the other mutations: the account-lock+`status='active'` check is extracted into one shared primitive `assertActiveAccountLocked()` called first by both `withProfile()` and `removeAvatar()`, giving all profile mutations the identical account→profile lock order as `pseudonymize()`. `removeAvatar` fails closed (`ProfileLifecycleException`) on a disabled/pseudonymized/raced account, preserves pointer-first→post-commit byte deletion, and does NOT create a profile row to clear a nonexistent avatar; the controller catches the exception and fails closed (logout+redirect). Coverage: `av9` (no-op remove on nonexistent profile → no row, zero provenance), `av10` (disabled account remove rejected, profile/avatar intact), `cc4` (two-connection: remove racing a committed pseudonymization fails closed, account→profile ordering, no recreation, zero provenance). R1–R5 retained.

Focused `CollectorProfileTest` **33 passed / 1 skip (webp)** + `CollectorProfileConcurrencyTest` **4 passed**; full SCA gate **1057 passed / 5472** (+ known `QrReissueTest::rg8` timing flake, passes 11/11 on isolated re-run). Evidence: `docs/SCA-COLLECTOR-PROFILE-CP1-IMPLEMENTATION.md` (R6 section). **STOP for ChatGPT final re-audit of `cc6d053`.**

---

## Prior re-audit (FAIL — R6 removeAvatar lifecycle) — addressed above
Prior candidate: `bd32988ead30ada09a36726be165c3ef8aebe5d0` (R1–R5 remediation)

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

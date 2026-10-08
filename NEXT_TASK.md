# NEXT TASK

**STATUS: CP-1 RE-AUDIT — FAIL / PRIVACY-RACE REMEDIATION REQUIRED. Do not merge/deploy or start CP-2.**

Updated 2026-10-08.

## Audit target
Base: `f461c17b7e0cbd5a5e5f026d5f5000870ef04752`
Original candidate: `5eddb141d175b5cbfa7e409a46f44fefd8617d98`
Re-audit candidate: `3c422fe669bc6b14ee8bb476cf6c798cc0a35273`
Branch: `feat/sca-collector-profile-cp1`
Head is 2 commits ahead / 0 behind deployed base. Migration remains 130→131. Production untouched.

## Re-audit result
R1 avatar compensation: addressed.
R2 first-create race: reproduced and addressed for competing profile creates.
R3 genuine disabled account: addressed.
R4 pseudonymization provenance assertion: addressed.

**New blocker discovered while auditing the race fix: profile mutation is not serialized against the collector privacy lifecycle.**

### R5 — BLOCKER: prevent profile resurrection after pseudonymization

`CollectorPrivacyService::pseudonymize()` locks `sca_collector_accounts`, deletes `sca_collector_profiles`, then commits `status='pseudonymized'`.

But `CollectorProfileService::withProfile()` does not lock/revalidate the collector account status before creating/updating the profile. In particular:
- `setAvatar()` can create/update a profile without touching/locking the account row.
- `saveProfile()` updates `display_name` by id without requiring `status='active'`.
- `lockOrNew()` explicitly allows a missing profile to fall through to creation if pseudonymization deleted it.

Therefore an already-admitted/in-flight request can race privacy pseudonymization and recreate `sca_collector_profiles` (bio/location/avatar pointer) after privacy committed; `saveProfile()` can also repopulate `display_name` on a pseudonymized account. Route middleware alone cannot prevent this because authorization can occur before the concurrent privacy transaction commits.

### Required fix
At the service/write boundary, serialize every profile mutation against the canonical collector account row and require it to remain `status='active'` inside the same DB transaction before profile create/update.

Requirements:
- acquire the collector account row with `FOR UPDATE` (or an equivalently strong established pattern) before profile mutation;
- fail closed if account missing or status is not active;
- do not recreate profile data after pseudonymization;
- do not repopulate display_name after pseudonymization;
- avatar failure path must delete newly written bytes when lifecycle rejection occurs;
- preserve first-create concurrency correctness without uncontrolled 500/deadlock behavior;
- preserve UNIQUE profile binding + immutability trigger;
- no provenance mutation.

### Mandatory real concurrency proof
Add a deterministic two-connection MariaDB test that races profile/avatar mutation against pseudonymization and proves the privacy operation wins cleanly according to serialization:
- after pseudonymization commits: account remains pseudonymized;
- display_name remains null;
- no profile row exists;
- no reachable/new avatar remains;
- no provenance mutation;
- the losing profile operation is controlled/fail-closed, not a 500 from null dereference/constraint accident.

Also retain the existing first-create race test and R1–R4 coverage.

### 1062 scope
While touching `withProfile()`, keep 1062 handling narrowly attributable to the profile first-create UNIQUE race. Do not broadly convert an unrelated duplicate-key failure into a retry. If account-row serialization makes the 1062 convergence unnecessary, simplify rather than retain speculative retry machinery.

## Boundaries
No schema redesign unless strictly required. No public profiles/handles, Passport changes, stats redesign, Stripe/SMTP/Shopify work, provenance changes, deployment, or CP-2.

## Handoff
Push to the SAME branch and update the CP-1 implementation report. Run focused profile/concurrency suites and full `tests/Feature/Sca/` gate. Report exact head/base, changed files, test counts, the privacy-race mechanism/result, migration delta, and production/Stripe state. Then STOP for ChatGPT re-audit.

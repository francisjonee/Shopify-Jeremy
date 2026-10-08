# NEXT TASK

**STATUS: CP-1 PRE-MERGE AUDIT — FAIL / REMEDIATION REQUIRED. Do not merge/deploy or start CP-2.**

Updated 2026-10-08.

## Audit target
Base: `f461c17b7e0cbd5a5e5f026d5f5000870ef04752`
Candidate: `5eddb141d175b5cbfa7e409a46f44fefd8617d98`
Branch: `feat/sca-collector-profile-cp1`
Candidate is 1 commit ahead / 0 behind base. Migration remains proposed 130→131. Production untouched; Stripe DORMANT.

## Verdict
**FAIL — required failure-path/concurrency evidence is missing.** Reviewed architecture is otherwise directionally correct: separate one-to-one profile table, canonical display_name retained on collector account, private avatar route/storage, canonical ownership-derived stats, Passport privacy retained, profile row removed during pseudonymization.

### R1 — Avatar DB-failure compensation
Add a deterministic test that forces the DB portion of `CollectorProfileService::setAvatar()` to fail AFTER new bytes are written. Prove: new file is removed; existing old pointer/file remains valid; profile never points to failed new path; zero provenance mutation. Use a real failure mechanism; do not weaken production code to ease testing.

### R2 — Concurrent first-profile creation
`lockOrNew()` cannot row-lock a profile that does not yet exist. Run a real two-connection MariaDB concurrency test for two first creates for the SAME collector. Prove exactly one row, correct binding, no corruption/cross-write/provenance mutation, and controlled request/service behavior. If current behavior can surface a UNIQUE exception/500, make the smallest service-level race fix while preserving UNIQUE + immutability trigger. Also retain sequential replay/one-row proof.

### R3 — Disabled-account coverage
Current ps3 proves pseudonymized access rejection but is named disabled. Add a genuinely `status=disabled` collector test covering profile GET, avatar GET, and at least one mutation route, with zero profile mutation.

### R4 — Pseudonymization provenance proof
Around a successful pseudonymization with profile/avatar, snapshot the established provenance surfaces before/after and explicitly prove they remain unchanged. Existing ps1 checks profile/account/avatar effects but not provenance despite the promoted requirement.

## Boundaries
Do not redesign schema, Passport, stats, public profile/handles, Stripe, SMTP, Shopify, provenance, or CP-2. Migration must remain additive 130→131 unless an audited necessity is discovered.

## Handoff
Push remediation to the SAME CP-1 branch. Update `docs/SCA-COLLECTOR-PROFILE-CP1-IMPLEMENTATION.md`. Rerun focused CP-1 and full `tests/Feature/Sca/`.

Report new head SHA, exact base, changed files, focused/full pass+assertion+skip counts, observed concurrency behavior before/after, avatar failure mechanism, migration delta, and production/Stripe state. **STOP for ChatGPT re-audit.**

# NEXT TASK

**STATUS: CP-1 REMEDIATED (audit R1–R4) — CANDIDATE awaiting ChatGPT re-audit. Do not merge/deploy or start CP-2.**

Updated 2026-10-08.

## Re-audit target
Base: `f461c17b7e0cbd5a5e5f026d5f5000870ef04752`
Candidate: **`3c422fe669bc6b14ee8bb476cf6c798cc0a35273`** (remediation of `5eddb141`; branch `feat/sca-collector-profile-cp1`, now 2 commits ahead / 0 behind base). Migration remains 130→131 (one additive table; prod still 130). Production untouched; Stripe DORMANT.

### Remediation summary (all four findings addressed; 3 files changed from `5eddb141`)
- **R1** `av8`: forces a real model-save exception AFTER the avatar bytes are written → new file compensated/removed, old pointer+file intact, zero provenance (production code unchanged).
- **R2**: gap-lock-free create path + `withProfile()` 1062-convergence in `CollectorProfileService` (UNIQUE + immutability trigger unchanged); new NON-transactional `CollectorProfileConcurrencyTest` — `cc1` real two-connection MariaDB race converges to one correctly-bound row with no 500/corruption; `cc2` sequential one-row replay. Before/after: lost first-create was a 1062/500 → now a single-row update.
- **R3** `pa2b`: genuine `status='disabled'` account rejected on profile GET / avatar GET / a mutation route, zero profile mutation; prior `ps3` renamed to the pseudonymized case.
- **R4** `ps1`: snapshots provenance before/after a successful pseudonymization (with provenance owned by another collector) and asserts it byte-identical.

Focused `CollectorProfileTest` **31 passed / 1 skipped (webp)** + `CollectorProfileConcurrencyTest` **2 passed**; full SCA gate **1054 passed / 5458**. Evidence: `docs/SCA-COLLECTOR-PROFILE-CP1-IMPLEMENTATION.md` (Remediation section). **STOP for ChatGPT re-audit of `3c422fe`.**

---

## Original audit (FAIL — remediation required) — addressed above
Prior candidate: `5eddb141d175b5cbfa7e409a46f44fefd8617d98`

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

# NEXT TASK

**STATUS: CP-3 PRE-MERGE AUDIT — FAIL / one bounded remediation required. Do not merge/deploy or start CP-4.**

Updated 2026-10-09.

## Audited candidate
Implementation repo: `francisjonee/francisjonee-sca-platform-private`
Branch: `feat/sca-collector-profile-cp3`
Base: `a1e1d495d89d82fcfe921789e2b2bc4248874c0d`
Candidate: `76057cb388726b139345fe4ff7fbe5aeaf4c4360`
GitHub compare: 1 ahead / 0 behind, exactly 14 intended CP-3 files, migration 131→132.

## Audit result
The CP-3 architecture is otherwise accepted:
- dedicated explicit publication state;
- ownership does not imply publication;
- opaque stable PUB ref distinct from account ref;
- account-first publish/unpublish lifecycle serialization;
- pseudonymization deletes publication atomically;
- minimal public allowlist;
- Passport/My Collection remain private;
- no CP-4 scope;
- migration constraints/immutability are appropriate.

### R1 BLOCKER — public avatar can remain reachable when the public profile no longer resolves
`CollectorPublicProfileService::resolvePublic()` requires:
- publication exists + published;
- account active;
- **nonblank canonical display_name**.

But `resolvePublicAvatar()` currently requires only:
- publication exists + published;
- account active;
- avatar exists.

Existing CP-1 profile editing allows `display_name` to be cleared while already published. Therefore:
1. collector publishes with a valid display name;
2. collector has an avatar;
3. collector edits display_name to blank/null;
4. `GET /c/{ref}` correctly returns 404 because the public profile no longer resolves;
5. **`GET /c/{ref}/avatar` can still return the identifiable avatar bytes.**

This violates the promoted CP-3 requirement: public avatar must succeed **only if the public profile itself currently resolves as published + active**, including the meaningful-display-name gate. It also creates an inconsistent privacy boundary where the page is closed but its identifying asset remains public.

## Required remediation
Make the public-avatar resolver enforce the SAME public-profile eligibility gate as the page:
- publication exists;
- is_published=true;
- account status active;
- canonical display_name trims to nonblank;
- private avatar exists.

Prefer centralizing/reusing a single eligibility predicate/read boundary so page and avatar cannot drift again. Do not expose display_name from the avatar resolver; it is only a gate.

Preserve:
- ordinary indistinguishable 404;
- no-store;
- nosniff;
- raw avatar path never emitted;
- current unpublish/disable/pseudonymization behavior;
- zero provenance.

## Required tests
Add focused regression proving:
1. publish named collector with avatar → page 200 + avatar 200;
2. clear display_name through the REAL existing CP-1 profile service/edit path while still published;
3. page becomes ordinary 404;
4. avatar becomes ordinary 404 at the same time;
5. publication row/ref remains stable/published (this is eligibility closure, not implicit unpublish);
6. restoring a nonblank display name makes the same public ref + avatar resolvable again;
7. no provenance mutation from this presentation edit/public read sequence.

Also strengthen the 404-equivalence coverage as practical so the closed-avatar response does not reveal why it is unavailable.

Run:
- CollectorPublicProfileTest;
- CollectorPublicProfileConcurrencyTest;
- CP-1 profile/privacy regressions;
- full `tests/Feature/Sca` gate.
Report exact pass/assertion/skip counts.

No migration change: candidate migration remains 131→132.
No Caddy/DNS work in this remediation. Production remains untouched at `a1e1d495...`, migration 131.
No CP-4.

Push remediation on the SAME CP-3 branch, update implementation report, report exact new head and delta from `76057cb`, then STOP for ChatGPT re-audit.

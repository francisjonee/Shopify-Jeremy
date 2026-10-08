# NEXT TASK

**STATUS: CP-5 CANDIDATE PUSHED — Public Handle / Profile URL — awaiting ChatGPT pre-merge audit. Branch `feat/sca-collector-profile-cp5`, head `681bc45ee38ce6b12f34a32b129d19de0ca54c07`, base `7409a33baecf2ef6bd8c44413a27a9f77fa249f1`, migration 133→134, 14 files. NOT merged / NOT deployed / production untouched (prod migration 133) / `/u/*` edge-blocked / Caddy+DNS+Stripe+SMTP+Shopify unchanged. Full write-up: `docs/SCA-COLLECTOR-PROFILE-CP5-IMPLEMENTATION.md`. STOP for ChatGPT pre-merge audit; do not merge/deploy/activate the `/u/*` edge or start CP-6.**

Updated 2026-10-09.

## Architecture audit
ChatGPT audited live CP-3/CP-4 routing, publication lifecycle, public profile/image resolvers, and private profile controls at baseline `7409a33...`.

### Existing contract that CP-5 must preserve
- `sca_collector_public_profiles.public_ref` is a stable, immutable, high-entropy `PUB-` identity.
- Existing public routes use `/c/{publicRef}`, `/avatar`, and CP-4 nested item image URLs.
- Existing shared opaque URLs must never break because a collector chooses/renames/removes a handle.
- CP-3 publication/unpublication and privacy serialize account-first.
- CP-4 collection visibility remains independent of profile URL choice.
- Public profile is intentionally noindex/no directory/search.

## CP-5 architectural decision
**A human-readable handle is a mutable ALIAS, not a replacement identity.**

The opaque `PUB-` route remains permanent, canonical authority and backward-compatible share URL.

Add a separate handle namespace:
- profile: `/u/{handle}`
- avatar: `/u/{handle}/avatar`
- CP-4 item image: `/u/{handle}/items/{itemRef}/image`

Do NOT overload `/c/{publicRef}` with handles. This keeps opaque-ref parsing, old shared links, and future reserved route words unambiguous.

A valid active handle route resolves server-side to the same publication record/public_ref, then reuses the existing CP-3/CP-4 public eligibility services. Do not fork presentation/privacy logic.

## Handle state
Preferred: add handle fields to `sca_collector_public_profiles` because handle belongs to the one publication identity:
- `handle` nullable
- `handle_normalized` nullable UNIQUE
- `handle_changed_at` nullable
- timestamps already exist.

If MariaDB collation can safely provide exact desired case-insensitive uniqueness, a single normalized column may be sufficient; otherwise keep display + normalized separately.

Migration expected 133→134.

Do NOT mutate `public_ref`; its existing immutability trigger must continue protecting it.

### Normalization / syntax
Conservative v1:
- user input trimmed;
- normalized to lowercase;
- stored/displayed canonical handle is lowercase;
- ASCII only;
- 3–30 chars;
- first and last char must be alphanumeric;
- allowed internal characters: lowercase `a-z`, digits `0-9`, single hyphen `-`;
- reject consecutive hyphens;
- no underscores, periods, spaces, Unicode/confusables, URL escapes or slashes.

Examples:
- `Ada-Lovelace` → canonical `ada-lovelace`
- `ada--lovelace` reject
- `-ada`, `ada-`, `ab` reject.

## Reserved names
Maintain a centralized explicit reserved set, tested case-insensitively after normalization.

At minimum reserve platform/system/security/support terms and route-like names:
`admin, administrator, api, app, auth, avatar, billing, c, collector, collection, dashboard, help, login, logout, mail, payments, privacy, profile, register, reset, root, sca, secondchance, second-chance, secondchanceauthenticators, settings, staff, support, system, u, user, users, verify, webhook, www`.

Also reject any handle beginning with reserved identifier prefixes used by SCA public refs/tokens, including normalized forms beginning `pub-`, `col-`, `sca-`, `sub-`.

Do not attempt an enormous trademark/profanity system in CP-5. The centralized set must be easy to extend.

## Availability / ownership semantics
Handle claim/change/removal is collector-authenticated self-service only.
- collector id from session, never request;
- active account required;
- a CP-3 publication row must already exist;
- handle may be chosen while profile is published OR unpublished;
- handle reservation belongs to the publication identity, not to current publication visibility;
- unpublishing profile does NOT release the handle;
- republishing restores the same handle route;
- profile-public eligibility still gates whether the route returns 200.

### Removal and reuse
Privacy-first v1 rule:
- collector may explicitly REMOVE their handle;
- after removal, old handle immediately returns ordinary 404 and does NOT redirect;
- old handle is **NOT immediately reusable**.

Add a durable tombstone/reservation table, preferred:
`sca_collector_handle_reservations`
- id
- handle_normalized UNIQUE
- former_public_profile_id nullable or opaque/non-PII linkage if needed
- released_at
- reusable_after nullable
- created_at/updated_at.

For CP-5, choose a fixed **90-day cooling period** after rename/removal before another collector may claim that normalized handle.
- same collector also should not use old handle as an automatic redirect;
- if reclaim behavior during cooling is implemented, only the same publication identity may reclaim it; simplest acceptable v1 is nobody can claim until expiry.
- after expiry the name may be claimed by another collector.
- no public endpoint reveals whether a 404 handle is tombstoned, never existed, unpublished, disabled, or pseudonymized.

Do not retain PII in tombstones. A former publication-id linkage is acceptable only if needed for same-owner reclaim and must be removed by pseudonymization; simplest is no linkage.

### Rename
Rename is one atomic transaction:
1. account-first lifecycle lock;
2. lock publication row;
3. validate/normalize new handle;
4. verify no active handle or unexpired tombstone owns it;
5. tombstone old normalized handle for 90 days;
6. update publication to new canonical handle.

Old `/u/old` becomes ordinary 404 immediately.
New `/u/new` resolves only if profile is otherwise publicly eligible.
Existing `/c/PUB-...` remains unchanged throughout.

No old→new redirect.
No redirect chain/history.
Do not expose old handle on the new profile.

## Collision/concurrency
Database UNIQUE constraints are ultimate authority.

All handle mutations use account-first lock and publication-row lock.
Cross-collector same-handle claims can still race because accounts differ. Must handle the normalized UNIQUE collision safely:
- exactly one claimant succeeds;
- loser receives the same generic “handle unavailable” result;
- no SQL/owner details leak;
- no partial tombstone/current-handle state.

Real two-connection concurrency test required for simultaneous claim of the same normalized handle by two collectors.

Also test rename A→X racing B claim X if meaningful under implementation.

## Public route semantics
Handle route must use the same fail-closed public eligibility as opaque route.

Preferred service architecture:
- add resolver `resolvePublicRefByHandle($handle)` that validates canonical syntax and returns public_ref only when the publication/account/profile is currently publicly resolvable;
- then call existing CP-3/CP-4 resolvers using public_ref;
OR centralize an internal publication identity resolver reused by both route families.

Do not duplicate CP-3/CP-4 eligibility predicates in controllers.

For public HTML rendered through `/u/{handle}`:
- profile content identical to `/c/{PUB}`;
- collection content identical;
- avatar/item-image URLs should remain within the same handle route family for user-facing consistency, OR use opaque URLs if simpler/privacy-equivalent. Pick one and test it.
- do not emit internal ids/account COL ref/raw paths.

### Canonical/SEO behavior
Keep `noindex,nofollow` for CP-5. This slice does NOT create discovery/search/SEO indexing.

Do NOT automatically redirect opaque `/c/PUB` → handle.
Do NOT redirect handle → opaque URL for the main profile page if that unnecessarily exposes the opaque identifier in browser history; render directly after server-side resolution.
Opaque route remains valid forever while profile is published.

## Private UX
On authenticated profile page:
- show current handle if set;
- show share URL `/u/{handle}` when profile is published and handle exists;
- retain the opaque public URL as a stable fallback/share link (may label it “Permanent link”);
- form to set/change/remove handle;
- clear syntax guidance;
- generic unavailable validation;
- removal/rename warning: old handle stops working immediately and is not redirected.

Mutations CSRF protected and throttled, e.g. 10/min.

No unauthenticated “check availability” endpoint in CP-5; that would create enumeration/squatting assistance.

## Unpublish / disable / pseudonymization
- unpublish: handle remains reserved but all `/u/*` profile/avatar/item-image routes 404;
- republish: same handle works again if unchanged;
- disabled/non-active account: routes 404; handle remains reserved unless privacy lifecycle explicitly releases it;
- pseudonymization: remove active handle from publication state and tombstone it for 90 days in the SAME privacy transaction before publication deletion; old handle immediately 404;
- opaque public route remains governed by existing pseudonymization behavior (publication deletion).

No handle string should be copied into provenance.

## Rate limiting / enumeration
Public GET routes may use a reasonable read throttle only if consistent with existing public profile/Passport behavior; do not introduce a user-visible aggressive limit without need.
Mutation routes MUST be throttled.

Unknown/malformed/reserved/tombstoned/unpublished/disabled/pseudonymized handle requests return indistinguishable ordinary 404.

No public handle directory/search/autocomplete/availability API.

## Mandatory tests
At minimum prove:

1. handle absent by default; opaque PUB route unchanged;
2. valid mixed-case input canonicalizes to lowercase;
3. syntax min/max/edge hyphen/consecutive hyphen/invalid chars/Unicode rejected;
4. reserved names/prefixes rejected after normalization;
5. handle requires authenticated session collector, active account, existing publication identity;
6. setting handle does not itself publish profile;
7. published profile + handle renders same allowlisted profile data as opaque route;
8. handle avatar and CP-4 item-image routes enforce SAME CP-3/CP-4 eligibility and 404 behavior;
9. unpublish closes all handle routes but preserves handle reservation; republish restores;
10. rename atomically moves current handle; old route 404; new route works; PUB route unchanged;
11. rename/removal creates 90-day tombstone; old handle no redirect;
12. another collector cannot claim tombstoned handle before expiry;
13. expiry permits a new claim, with deterministic clock test;
14. removal leaves no handle route and PUB route remains unchanged;
15. pseudonymization removes active handle/publication and creates non-PII tombstone; all old public routes 404;
16. no handle copied to provenance; provenance fingerprint/event counts unchanged by handle mutations;
17. real two-connection simultaneous same-handle claim: exactly one wins, one generic unavailable, one active owner, no partial rows;
18. case variants collide after normalization;
19. malformed/unknown/reserved/tombstoned/unpublished handle routes are indistinguishable 404;
20. no public availability/search/directory endpoint;
21. existing CP-3 opaque avatar and CP-4 opaque item-image routes remain valid/unchanged;
22. old handle does not appear in new handle page/HTML after rename;
23. private profile shows handle controls and both appropriate share/permanent-link semantics without leaking refs when unpublished contrary to existing policy;
24. mutation replay/idempotency defined and tested (setting same canonical handle is safe);
25. migration UNIQUE/FKs/default/null behavior and tombstone uniqueness proven;
26. concurrency with privacy/unpublish follows account-first serialization and cannot resurrect a handle after pseudonymization.

Run focused CP-5 tests + real concurrency, CP-3 public profile/concurrency, CP-4 public item/concurrency, CP-1 privacy/profile, Passport regressions, and full `tests/Feature/Sca`. Report exact counts/skips.

## Production edge
Existing Caddy currently admits only `/c/*` and collector paths for SCA public profile traffic. New `/u/*` will require a **separate deployment phase** after application/schema deployment and audit, exactly like CP-3:
- Phase A: app + migration 134 only; NO Caddy/DNS changes; /u remains externally edge-blocked.
- Phase B: after ChatGPT Phase-A post-deploy audit, minimal edge admission for `/u/*`; no DNS expected.

Do not modify Caddy in the CP-5 implementation candidate.

## Forbidden / out of scope
- NO replacing/removing PUB identity;
- NO redirect from old handle to new;
- NO opaque→handle redirect;
- NO public handle availability endpoint;
- NO directory/search/discovery;
- NO SEO indexing;
- NO social/follow/comment;
- NO vanity domains;
- NO CP-6 organization;
- NO marketplace/resale/valuation;
- NO provenance changes;
- NO Stripe/SMTP/Shopify/Caddy/DNS work;
- NO production deployment.

## Handoff
Create NEW branch from exact `7409a33baecf2ef6bd8c44413a27a9f77fa249f1`.
Implement complete bounded CP-5.
Expected migration 133→134.
Push candidate and report:
- branch/base/head;
- changed files;
- migration/schema;
- handle normalization/reserved-name implementation;
- tombstone/reuse semantics;
- lock/concurrency design;
- private/public routes;
- focused/full test counts;
- production untouched at `7409a33`, migration 133;
- provenance fingerprint/counts;
- collector/private-profile/public-profile/public-item counts;
- Stripe dormant/mail log;
- confirmation no Caddy/DNS changes and external /u remains edge-blocked.

Then STOP for ChatGPT pre-merge audit.
Do not merge/deploy.
Do not start CP-6.

# NEXT TASK

**STATUS: CP-3 PROMOTED — Public Profile Foundation. Implement on a NEW branch from exact production baseline `a1e1d495d89d82fcfe921789e2b2bc4248874c0d`. Do not merge/deploy. STOP for ChatGPT pre-merge audit.**

Updated 2026-10-09.

## Architecture audit / invariant
ChatGPT audited the deployed CP-1/CP-2 profile/privacy boundary before promotion.

Current facts:
- `sca_collector_accounts` is canonical account identity/lifecycle; `display_name` lives there.
- `sca_collector_profiles` is explicitly PRIVATE presentation data (bio/location/private avatar), one-to-one and deleted by pseudonymization.
- CP-1 profile writes serialize on the collector account row and require `status='active'`.
- private avatar bytes live on a non-web-served disk and are currently streamable only through an authenticated self route.
- collector pseudonymization locks the account, refuses while canonical current ownership remains, deletes the profile row, clears display_name/credentials, marks pseudonymized, then deletes avatar bytes.
- My Collection membership is canonical current ownership and remains private.
- Public Passport deliberately exposes no collector identity.
- There is currently NO public collector-profile route.

**Critical invariant: Ownership ≠ publicity.**
Having an account, profile row, avatar, bio, location, certified item, current ownership, Passport, claim, transfer, or collection MUST NOT make a collector public.

CP-3 creates only an explicit opt-in PUBLIC PROFILE surface. It does **not** publish the collection or owned items; that belongs to CP-4.

## Objective
Allow an active collector to explicitly publish/unpublish a minimal public profile, addressed by an opaque non-guessable public profile reference, while preserving the private profile as the source of presentation content and preserving Passport/ownership privacy.

A public profile in CP-3 may show:
- display name;
- bio;
- coarse location;
- avatar if present;
- collector-since month/year.

It MUST NOT show collection items, owned count, certified count, brands, ownership/provenance, email, collector account public_ref, internal ids, submissions, transfer history, Passport links, or other private data.

## Data model
Add a dedicated publication-state table, not public flags mixed into provenance and not implicit publication from `sca_collector_profiles`.

Preferred table: `sca_collector_public_profiles` (name may vary only with a documented reason):
- id
- collector_account_id UNIQUE, FK → collector accounts, RESTRICT
- public_ref UNIQUE, server-generated high-entropy opaque identifier; immutable after creation
- is_published boolean, default false
- published_at nullable
- timestamps.

Rules:
- publication row is presentation/privacy state, NOT provenance.
- no public handle/slug in CP-3.
- no ownership/item ids.
- public_ref must not be the existing collector account public_ref.
- creating publication state starts UNPUBLISHED.
- once allocated, public_ref remains stable across publish/unpublish cycles.
- collector_account_id and public_ref immutable at storage layer.
- one publication row per collector.

Migration additive from 131 → expected 132. No changes to provenance tables.

## Private collector controls
On the existing authenticated profile page:
- show a clearly separated “Public profile” section;
- default/off state is private;
- collector must explicitly choose Publish;
- Unpublish must be available and immediately make the public route unavailable;
- show the public profile URL/link only while published (or clearly label a preview if you deliberately provide authenticated preview; do not make an unpublished URL publicly resolvable);
- publication actions target SESSION collector only; no collector id/ref from request;
- CSRF + reasonable throttle;
- publication mutation must use the SAME account-first lifecycle serialization pattern as CP-1 profile writes and pseudonymization;
- require canonical account status active inside the transaction;
- no profile row should be created merely by toggling publication state.

Publishing with no private profile row is allowed only if the resulting public presentation is meaningful (e.g. nonblank display_name). Prefer fail-closed validation requiring a nonblank display_name before publish. Bio/location/avatar remain optional.

## Public route
Create a dedicated unauthenticated public collector profile route using ONLY the publication `public_ref`, e.g. `/c/{publicRef}` or another clearly documented namespace that does not collide with Passport.

Public read must resolve in one fail-closed query/read boundary:
- publication row exists;
- `is_published=true`;
- canonical collector account exists and `status='active'`;
- then join/read optional private profile presentation.

Unknown, malformed, unpublished, disabled, or pseudonymized collector => the SAME ordinary 404 response. Do not reveal which condition failed.

No public directory/search/index in CP-3. The URL is share-by-link only.

## Public avatar
Do NOT expose `avatar_path`, filesystem path, or `/storage`.

Add a public avatar stream route bound to the PUBLIC PROFILE reference, not collector id/account ref:
- only succeeds if the public profile itself currently resolves as published + active;
- then reads that collector's current private avatar pointer;
- JPEG/PNG/WebP only as already validated by CP-1;
- `X-Content-Type-Options: nosniff`;
- choose a privacy-safe cache policy. Because unpublish must take effect immediately, default to `Cache-Control: no-store` unless a stronger revocation-safe design is proven;
- unpublished/disabled/pseudonymized/missing-avatar => same 404;
- raw path never emitted.

The existing private authenticated avatar route remains unchanged.

## Publication lifecycle / concurrency
Create a dedicated service as the sole writer/resolver for public-profile publication state.

Mutation lock order:
1. canonical `sca_collector_accounts` row FOR UPDATE;
2. require status active;
3. publication-state row FOR UPDATE / create if necessary;
4. mutate publish/unpublish.

It must serialize with CP-1 profile mutation and `CollectorPrivacyService::pseudonymize()`.

### Privacy pseudonymization integration
Pseudonymization must remove/disable public publication state atomically in the SAME privacy transaction before the account becomes pseudonymized. Prefer deleting the publication row (presentation/privacy data) unless there is a documented need to retain the opaque public_ref; CP-3 has no requirement to preserve a public URL after account anonymization.

After pseudonymization commits:
- public profile route 404;
- public avatar route 404;
- no publication state may resurrect;
- private profile/avatar deletion behavior remains intact;
- provenance behavior remains unchanged.

Maintain consistent lock order account → publication/profile as needed and prove no deadlock-prone inverse ordering.

## Public presentation
Use a deliberately minimal public layout/card. Render only:
- display_name;
- optional avatar;
- optional bio;
- optional coarse location;
- “Collector since Month YYYY”.

Do NOT render private collection stats in CP-3. Even counts can disclose ownership/collection information and are reserved for later explicit visibility work.

No email, account public_ref, public-profile DB id, collector id, raw avatar path, submission info, ownership status, item refs, certification/brand counts, service/transfer history, social links, or staff data.

Add a short privacy-safe statement such as “Collector profile on Second Chance Authenticators.” Do not imply SCA endorses the collector or that profile publication proves ownership of any particular item.

## Publish/unpublish semantics
- First publish allocates publication row/ref if absent and sets published.
- Repeated publish is idempotent; no ref rotation and no duplicate row.
- Unpublish is idempotent and immediately closes public profile/avatar.
- Republish restores the SAME public_ref.
- Editing private display_name/bio/location or replacing/removing avatar while published should naturally change the public render because public reads use current canonical/private presentation data; do not duplicate snapshot content into publication table.
- Profile editing remains allowed while published and uses existing CP-1 concurrency rules.
- publication itself creates ZERO provenance.

## Mandatory tests
Add focused CP-3 tests proving at minimum:
1. no publication row/profile is public by default;
2. authenticated self-only publish/unpublish; staff session insufficient; payload cannot retarget another collector;
3. publish requires active account and meaningful nonblank display_name;
4. first publish allocates one high-entropy opaque public_ref distinct from account public_ref; replay does not duplicate/rotate;
5. unpublished public route and avatar return ordinary 404;
6. published route exposes only allowlisted presentation fields;
7. public HTML contains no email, collector account public_ref, internal ids, avatar path, collection stats, item/provenance/submission/transfer data;
8. public avatar streams only for published+active profile, with correct MIME/nosniff/no-store and no raw path;
9. unpublish immediately closes profile + avatar; republish restores same public_ref;
10. display_name/bio/location/avatar edits while published reflect current presentation without publication snapshot duplication;
11. disabled/non-active account public route/avatar fail closed;
12. pseudonymization atomically removes publication state and profile/avatar become 404; provenance privacy guarantees unchanged;
13. owning-item privacy rejection leaves publication/profile intact (pseudonymization still fails closed before deletion);
14. deterministic real two-connection race proof: privacy wins vs publish/unpublish cannot resurrect publication; account-first serialization proven;
15. concurrent/replayed first publish converges to one row/ref;
16. public Passport remains collector-identity-free and gains no profile link;
17. My Collection remains authenticated/private and publication does not expose owned items/counts;
18. publish/unpublish/profile browsing creates zero provenance/domain rows;
19. malformed/unknown/unpublished/pseudonymized references are indistinguishable 404s;
20. migration constraints/immutability/uniqueness proven.

Run focused CP-3 + CP-1 privacy/profile + My Collection/Passport regressions and full `tests/Feature/Sca` gate. Report exact pass/assertion/skip counts.

## Forbidden / out of scope
- NO public collection/items or per-item visibility controls (CP-4);
- NO public handle/custom slug (CP-5);
- NO custom collections/tags/favorites (CP-6);
- NO social/follow/friends/comments;
- NO directory/search/discovery;
- NO marketplace/resale;
- NO valuation/market-price;
- NO ownership/provenance model changes;
- NO Passport identity/profile link;
- NO Stripe/SMTP/Shopify/Caddy/DNS work;
- NO production deployment;
- NO CP-4+.

## Handoff
Create a new CP-3 branch from exact `a1e1d495d89d82fcfe921789e2b2bc4248874c0d`.
Implement the complete bounded slice, migration expected 131→132, documentation, focused tests and full SCA gate.
Push candidate and report:
- branch/base/head;
- changed files;
- migration;
- exact public/private route and publication semantics;
- focused/full test counts;
- production untouched/deployed SHA still `a1e1d495...`;
- production migration still 131 until deployment;
- provenance fingerprint/counts unchanged;
- Stripe dormant/mail log.

Then STOP for ChatGPT pre-merge audit. Do not merge/deploy or start CP-4.

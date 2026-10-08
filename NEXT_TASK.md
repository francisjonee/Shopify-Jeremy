# NEXT TASK

**STATUS: CP-2 PRE-MERGE AUDIT — FAIL / bounded remediation required. Do not merge/deploy or start CP-3.**

Updated 2026-10-09.

## Audited candidate
Implementation repo: `francisjonee/francisjonee-sca-platform-private`
Branch: `feat/sca-collector-profile-cp2`
Base: `8d8c35947d7c405124e0df4f09ff3ef4ee9e6bb8`
Candidate: `eddac539c8c66f00c07d5adb54ffbc1a9d53e4b6`
GitHub compare currently shows candidate tree 1 commit ahead / 0 behind base, four CP-2 files, no migration. Production remains migrations 131.

## Audit result
Core CP-2 architecture is accepted:
- current-owner membership is preserved;
- filters narrow only inside current ownership;
- search values are bound and LIKE metacharacters escaped;
- brand choices are collector-scoped;
- current-certification and adverse registry filters are canonical;
- pagination is bounded at 24;
- card DTO remains owner-safe;
- existing authorized image route is reused;
- no per-card history/detail/image DB lookup was introduced;
- the latest ownership-event subquery matches the canonical `ProjectionService::currentOwner()` ordering rule and is valid for claim / transfer_in / admin_correction terminal ownership events.

Three bounded gaps remain before merge.

## R1 — mandatory admin-correction chronology proof is missing
The promoted task explicitly required default recent ordering proof for claim, transfer-in, **and admin-correction where supported**. Admin correction is supported by `OwnershipCorrectionService` and is canonical ownership.

Add a real test using the established ownership-correction service (not a fabricated projection update):
- create item owned by A;
- create other acquisition(s) for B with controlled chronology;
- perform canonical admin correction assigning the item to B;
- prove B's default recent ordering treats the correction event as the acquisition event;
- prove A immediately loses membership;
- no reason/staff/internal data leaks.

Do not change the tail-event query merely to satisfy the test unless the real test reveals a defect.

## R2 — required collector presentation name omitted from header
The CP-2 promoted header required the collector display name where appropriate. Current controller/catalog/view never provides or renders it.

Add the authenticated collector's canonical `sca_collector_accounts.display_name` to the private collection header:
- derive it server-side from the authenticated collector only;
- presentation-only; no new stored state;
- if null/blank, render a neutral “My Collection” header with no awkward placeholder;
- never expose email/public_ref or another collector's identity;
- pseudonymized/disabled accounts remain governed by existing collector auth middleware and must not gain a bypass.

Add focused tests for display name present and absent, and no cross-collector identity leakage.

## R3 — collection summary must be aggregate/bounded for CP-2 scale
`collectionStats()` currently fetches every currently-owned row into PHP and then counts owned/certified/distinct brands. CP-2's explicit goal is collections larger than today's test data and the promoted task required bounded aggregate/read queries.

Refactor the summary to bounded SQL aggregate reads (or equivalent constant-size result), preserving EXACT semantics:
- owned = canonical current-owner item count;
- certified = non-null canonical current certification count;
- brands = distinct KNOWN brands, trim/case-insensitive semantics consistent with the existing CP-1 contract;
- null/empty/whitespace-only brand is not counted;
- transferred-away and unclaimed items excluded.
Do not add stored counters or schema.

Add focused proof for duplicate brand casing/whitespace, null/empty brand, certified/uncertified, transferred-away/unclaimed membership, and bounded query/result behavior.

## Retain / re-run
Retain all existing 19 RichMyCollection tests and MyCollection regression coverage. Add the R1–R3 tests, run focused suites and full `tests/Feature/Sca` gate, and report exact pass/assertion/skip counts.

No migration expected; remain 131. No item-detail redesign. No public profile/collection, handle, social, favorites, marketplace, valuation, Stripe, SMTP, Shopify, Caddy/DNS, provenance redesign, deployment, or CP-3.

Push remediation on the SAME CP-2 branch, update CP-2 implementation report, report exact new head and delta from `eddac539`, then STOP for ChatGPT re-audit.

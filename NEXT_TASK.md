# NEXT TASK

**STATUS: CP-2 R1–R3 REMEDIATED — CANDIDATE awaiting ChatGPT re-audit. NOT merged / NOT deployed. Deployed baseline unchanged (prod main `8d8c359`, migr 131, Stripe DORMANT, mail=log). Do not start CP-3.**

Updated 2026-10-09.

## Re-audit target
Branch `feat/sca-collector-profile-cp2`, base `8d8c35947d7c405124e0df4f09ff3ef4ee9e6bb8`, candidate **`5ebe9591a530874f5376296a2e10f538772834e8`** (R1–R3 remediation of `eddac539`). No migration (stays 131). Production untouched.

### Remediation summary (all three gaps closed; 4 files changed from `eddac539`, no migration)
- **R1**: new `o4` proves default recent ordering treats a canonical `OwnershipCorrectionService` admin_correction as the acquisition event (B newest-first `[corrected,mid,early]`), A loses membership immediately, no reason/staff/internal leak. Real service used; no tail-query change needed.
- **R2**: controller derives the authenticated collector's canonical `display_name` server-side (trim; null/blank → neutral "My Collection"), view renders "<name>'s Collection"; never email/public_ref/other-collector; `collector.auth` still gates disabled/pseudonymized. Tests r2a/r2b/r2c.
- **R3**: `collectionStats()` is now ONE SQL aggregate (COUNT(*) / COUNT(cert) / COUNT(DISTINCT CASE … LOWER(TRIM(brand)))) — exact CP-1 semantics (null/empty/whitespace excluded, case-insensitive, transferred-away/unclaimed excluded), constant-size result. Tests r3a/r3b/r3c/r3d. Shared with CP-1; its stats tests still pass.

Focused `RichMyCollectionTest` **27** + `MyCollectionTest` **12** + `CollectorProfileTest` **32 (+1 webp skip)**; full SCA gate **1085 passed / 5608**. Evidence: `docs/SCA-COLLECTOR-PROFILE-CP2-IMPLEMENTATION.md` (R1–R3 section). **STOP for ChatGPT re-audit of `5ebe959`.**

---

## Prior pre-merge audit (FAIL — R1–R3) — addressed above
Prior candidate: `eddac539c8c66f00c07d5adb54ffbc1a9d53e4b6`

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

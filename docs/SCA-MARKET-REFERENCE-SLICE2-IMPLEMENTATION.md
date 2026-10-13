# SCA Market Reference / Value History — Slice 2 Implementation Evidence (pre-merge)

**Status:** CANDIDATE pushed — awaiting ChatGPT pre-merge audit. NOT merged, NOT deployed. Read/presentation expansion over the EXISTING append-only Market Reference ledger: collector-facing owner-safe value history on Eyewear Detail. **No migration, no new authoritative state, no marketplace, no automated/AI/external valuation, no FX/delta, no provenance mutation.**

| | |
|---|---|
| Governance promotion | `ad637cf400d88ffdd730082908c0db515e667f13` |
| Implementation branch | `feat/sca-market-reference-slice2` (1 ahead / 0 behind base) |
| Exact production base SHA | `6ca15958844dace74f7d087a10a3355a6497dd00` (migration 138) |
| Candidate SHA | `9e8453e2bad54ed24ef22a151c881e539b9dc8be` |
| Merge base vs base SHA | exactly `6ca15958844dace74f7d087a10a3355a6497dd00` |
| Migration | **none** (138 unchanged) |
| Changed files vs base | 5 (463 insertions, 12 deletions) |
| Focused tests | `MarketReferenceHistoryTest` **13 passed / 73 assertions** |
| Full `tests/Feature/Sca` | **1380 passed / 1 skipped / 0 failed** (7308 assertions) |
| Production provenance FP (unchanged) | `d15a5cbdfb8df52ba65628b276533cfe`, counts `3/3/4/4/5/2/1/1/7`, migration 138 |

## Changed files (5)
- `app/packages/Sca/Provenance/src/Services/MarketReferenceService.php` — `collectorHistory()` becomes the canonical owner-safe value-history reader (+44/−… lines).
- `app/packages/Sca/Collector/src/Services/CollectionService.php` — new `marketReferenceHistoryForOwnedItem()` (owner-gated privacy/display projection).
- `app/packages/Sca/Collector/src/Http/Controllers/CollectionController.php` — passes `marketReferenceHistory` to the detail view (4 lines).
- `app/packages/Sca/Collector/src/Resources/views/collection/show.blade.php` — secondary "Value history" disclosure next to the current reference.
- `app/tests/Feature/Sca/MarketReferenceHistoryTest.php` *(new, 13 tests)*.

No migration, no route, no new authoritative state, no staff-writer change. All reads flow through the existing canonical `MarketReferenceService` fold.

## Architecture
### 1. One canonical owner-safe history reader
`MarketReferenceService::collectorHistory(itemId)` folds the ledger once (`currentReference`/`foldCurrent` ordering `(created_at,id)`) to resolve the current event **id**, then returns every record/supersede observation (voids are clearing actions, not observations) flagged `is_current` by matching that id, **newest-first**, plus `has_current`. The current id is computed internally and **stripped** — it never leaves the service. "Current" is decided by event id, never by comparing value fields, so a fresh post-void record that repeats an earlier value is not mistaken for it. Exposed fields: `currency`, `low_amount_minor`, `high_amount_minor`, `as_of_date`, `basis`, `is_current`. Never event/internal ids, actor/staff refs, supersede/void reasons, predecessor ids, `source_reference`, DB timestamps, or any Shopify/payment/token data.

`CollectionService::marketReferenceHistoryForOwnedItem(collectorId, publicRef)` applies the SAME current-owner gate as the current reference (`ownedItemId`), then maps to display fields (`minorToDisplay` — integer math, no float; `dateOnly`; `MR_BASIS_LABELS`) plus the `is_current` flag. Returns `{has_current:false, observations:[]}` for any non-owner (never confirms another collector's item).

### 2. Truthful void semantics
`has_current` is false exactly when the fold yields no current (voided/absent). Proven cases (tests m1–m5): record-only → one current; record→supersede → latest current + prior historical; record→supersede→void → no current, both historical; record→void→fresh record → only the fresh one current, pre-void historical; repeated equal value across a post-void chain → exactly the newest is current.

### 3. Collector authorization
Current owner only, via the existing ownership boundary. Non-owner and former owner (after transfer) receive the empty/no-current shape from the service and a privacy-safe **404** on the detail page; guest → sign-in; adverse status does not rewrite historical evidence (existing item-detail authorization unchanged). (test m7, m8)

### 4. Collector UX
A secondary **"Value history (Market Reference)"** `<details>` disclosure sits in the existing Slice-2 left asset panel, directly after the current advisory card (which is preserved). Newest-first; each observation carries a **text** "Current" / "Historical" label (meaning never colour-only); when the current reference is voided it states there is **"no current Market Reference"** and retains prior observations as historical evidence; advisory/non-guarantee wording ("not a guarantee of sale price or an offer") retained; no appreciation/investment/resale/sale-price language. No redesign of My Collection/Profile/Account/Authenticate/public profile/Passport/staff Market Reference UI. Mobile-friendly (`flex-wrap`, column, `overflow-wrap`); no fixed overflow widths. (tests m8, m9, m10)

### 5. Delta — deliberately omitted
No numeric change/delta is shown. Any cross-observation comparison risks ambiguity (differing currencies/bases/as-of gaps), so per the promotion's "if any ambiguity, omit delta entirely" it is omitted outright. No FX conversion anywhere.

### 6. No schema
No migration was needed — the existing ledger already holds the required history. Baseline remains migration 138.

## Privacy / no-leak proof (test m11)
The DTO exposes exactly `['currency','low_display','high_display','as_of','basis_label','is_current']`. The rendered detail page contains none of: `SECRET-SRC-REF-*` (source_reference), `SECRET-SUPERSEDE-REASON` (reason), `actor_staff_ref`, `supersedes_event_id`, `voids_event_id`, the distinctive staff ref `900001`, or an internal item id attribute.

## Public surfaces value-free (test m12)
For a certified, QR-active, owned item carrying a Market Reference history, the public passport `/p/{token}` contains neither "Value history", "Market Reference", nor any of the range figures. Public profile/collection/certificate PDF/QR remain value-free (existing Slice-1 exclusions unchanged).

## Zero mutation (test m13)
History read + detail GET leave `sca_market_reference_events`, `sca_ownership_events`, and `sca_item_current_state` byte-identical.

## Mandatory-test → evidence map
| Requirement | Test |
|---|---|
| 1 current owner sees owner-safe history | m1, m8 |
| 2 non-owner + former owner cannot obtain history | m7, m8 (404) |
| 3 record-only current marker | m1 |
| 4 supersede → latest current, prior historical | m2 |
| 5 void → no current, historical retained | m3, m9 |
| 6 fresh record after void is only current | m4 |
| 7 repeated equal value no identity confusion | m5 |
| 8 newest-first deterministic incl equal-timestamp by id | m2, m6 |
| 9 no actor/reason/predecessor/event-id/source_reference/token/Shopify leak | m11 |
| 10 public Passport/profile/collection/cert/QR value-free | m12 |
| 11 history read / detail GET zero mutation | m13 |
| 12 existing Slice-1 Market Reference + Collector UI tests green | full gate (MarketReferenceTest/ConcurrencyTest + CollectorCollectionUi2Test green) |
| 13 full `tests/Feature/Sca` passes | 1380 passed / 1 skipped / 0 failed |
| 14 no migration; baseline migration 138 | migrate:status 138 / 0 pending; 5 changed files, none a migration |

## Production-untouched proof
All work ran on disposable `sca_domain_test`. Live tree restored to `main@6ca1595`, vendor re-pruned `--no-dev`; prod DB migration **138**, provenance FP `d15a5cbd…` / counts `3/3/4/4/5/2/1/1/7` unchanged; no schema change; `/admin/login` → 200. No Caddy/DNS/Shopify OAuth/Stripe/SMTP change (Stripe dormant, MAIL_MAILER=log, SHOPIFY_SCOPES=read_orders).

**STOP — awaiting ChatGPT pre-merge audit of candidate `9e8453e`. Do not merge or deploy; do not start another initiative.**

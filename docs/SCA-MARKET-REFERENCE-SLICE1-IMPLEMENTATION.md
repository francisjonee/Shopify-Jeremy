# SCA Market Reference / Value History — Slice 1 Implementation Evidence (pre-merge)

**Status:** CANDIDATE pushed — awaiting ChatGPT pre-merge audit. NOT merged, NOT deployed.

| | |
|---|---|
| Governance promotion | `6d8d6fecece750d78e6070d5a7251373871dcc1e` |
| Implementation branch | `feat/sca-market-reference` (one commit ahead of base) |
| Exact production base SHA | `b4b51b7bb0244da6e1624c1095239c80cc206bb9` (migration 137) |
| Candidate SHA | `26a572a4c60e8a0820de24ca62582df38389a6c9` |
| Expected migration | 137 → **138** (`2026_10_19_000001_create_sca_market_reference_events`) |
| Changed files vs base | 17 (1852 insertions, 1 deletion) |
| Focused tests | `MarketReferenceTest` 26 + `MarketReferenceConcurrencyTest` 1 → **27 passed** |
| Full `tests/Feature/Sca` | **1312 passed / 1 skipped / 0 failed** |
| Production provenance FP (unchanged) | `d15a5cbdfb8df52ba65628b276533cfe`, counts `3/3/4/4/5/2/1/1/7` |
| Production schema | migration 137, `sca_market_reference_events` absent (Slice 1 un-deployed) |

## Core invariant upheld
Market Reference is advisory, append-only, NON-provenance evidence. record/supersede/void mutate NO item identity, authentication, certification/snapshot/PDF, QR, ownership, claim/transfer, registry status, service history, Shopify sale links, collector accounts, or `sca_item_current_state`. No mutable `estimated_value` column on `sca_eyewear_items`. No AI/marketplace/external/auto-Shopify pricing. Slice 1 visibility = staff + current canonical owner only.

## Schema (migration 137→138) — `sca_market_reference_events`
`id`; `eyewear_item_id` FK→`sca_eyewear_items` RESTRICT; `disposition` ∈ {record, supersede, void}; `currency` CHAR(3) (allowlist USD/PHP); `low_amount_minor`/`high_amount_minor` BIGINT **integer minor units** (never float); `as_of_date` DATE; `basis` ∈ {comparable_sales, market_observation, documented_appraisal, other}; `source_summary` VARCHAR(1000) (required record/supersede; VARCHAR so it is CHECK-expressible); `source_reference` VARCHAR(500) optional; `reason` VARCHAR(255) (required supersede/void); `supersedes_event_id`/`voids_event_id` self-FK RESTRICT; `actor_staff_ref` soft; `created_at`. Indexes `(eyewear_item_id,created_at,id)`, `(eyewear_item_id,id)`.

**9 CHECK constraints** make malformed/contradictory raw rows impossible: disposition/currency/basis allowlists; `low>=0,<=1e15`; `high>=0,<=1e15`; `high>=low`; disposition↔payload-presence (record/supersede require currency+low+high+as_of+basis+source_summary; void forbids all payload incl. source_reference); disposition↔predecessor-linkage (record→none; supersede→supersedes only; void→voids only); disposition↔reason (record→none; supersede/void→required).

**3 triggers:** `trg_mre_no_update` / `trg_mre_no_delete` (append-only); `trg_mre_bi` BEFORE INSERT enforces that `COALESCE(supersedes_event_id,voids_event_id)` exists AND belongs to the same item (no cross-item linkage/rebinding).

## Event semantics (ONE canonical MarketReferenceService)
Deterministic fold over `(created_at,id)`: record/supersede set current; void clears it → **at most one effective current** per item. First event must be record; record is rejected (`CURRENT_EXISTS`) while a current exists; supersede/void target the exact current event (`NO_CURRENT`/`STALE` otherwise); supersede rejects a NOOP (values equal current); after void a fresh record starts a new chain; history is never deleted. Amounts validated as non-negative integer minor units (≤1e15); currency/basis allowlisted; `as_of_date` not future beyond a 1-day clock tolerance.

**Concurrency:** every writer runs in one `DB::transaction`, locks `sca_item_current_state` FOR UPDATE, resolves current + event-count UNDER the lock, and enforces an optimistic token = per-item event count === the screen's `expected_event_count` (plus exact `expected_current_event_id` for supersede/void) → `STALE` else. A real two-connection proof (`cc_mr1`) shows two overlapping supersedes yield exactly one winner and one clean `STALE` (never two currents, never raw SQL).

## Staff / collector / public surfaces
- **Staff:** dedicated ACL `sca.eyewear.market_reference.manage`; item-detail "Market Reference" tab shows current reference + full chronological audit (currency, low/high range, as-of, basis, source summary/reference, actor/time/reason for supersede/void, current flag) + a Manage link; a GET confirm/review interstitial with Record/Supersede/Void forms + disclaimer "Informational estimate based on recorded market evidence; not a guarantee of sale price"; throttled CSRF POST; server-derived actor; decimal major-unit inputs converted to integer minor units with pure string math.
- **Collector (current owner only):** My Collection item detail shows the owner-safe current reference (range/currency/as-of/basis/source summary + non-guarantee wording) via `collectorCurrent` — a privacy projection that exposes NO actor/staff ref, reason, internal/predecessor ids, Shopify data or tokens. Non-owner/previous-owner/unauthenticated get nothing.
- **Public:** Passport, public profile/collection, certificate PDF/snapshot and QR are untouched; regression tests prove no value text/amount appears on any of them.

## Mandatory-test → evidence map
1 first record current (mr1); 2 minor-unit + currency (mr1, mr2); 3 range/negative/overflow/currency/basis/date/text fail closed (mr3); 4 supersede appends, original byte-identical, new current (mr5); 5 chronology deterministic + predecessor exact (mr6); 6 NOOP supersede rejected (mr7); 7 void removes current, history retained (mr8); 8 cannot supersede/void non-current (mr9); 9 fresh record after void (mr10); 10 wrong-item/cross-item predecessor in service + DB (mr13, mr24); 11 stale token zero partial (mr12); 12 **real two-connection proof** (cc_mr1); 13 server-derived actor (mr15); 14 dedicated ACL (mr14); 15 staff history actor/time/reason + evidence (mr16); 16 owner sees safe / others denied (mr18); 17 collector leaks nothing (mr19); 18 public Passport no value (mr20); 19 public profile/collection no value (mr21); 20 cert PDF/snapshot + QR unchanged (mr22); 21 ledger UPDATE/DELETE blocked (mr23); 22 malformed/cross-item/impossible rows blocked at DB (mr24, mr25); 23 zero provenance/current-state mutation + fingerprint gate (mr26 + prod FP `d15a5cbd` unchanged); 24/25 existing suites + full gate green (1312/1 skip/0 fail). Also: no_current supersede/void (mr11), record-twice→CURRENT_EXISTS (mr4), GET read-only (mr17).

## Production-untouched proof
Live tree restored to `main@b4b51b7`, vendor `--no-dev`, `/admin/login → 200`. Prod DB `sca_krayin`: migration 137 (`…create_sca_service_event_corrections`), migration count 137, `sca_market_reference_events` **absent**, 13-table provenance fingerprint `d15a5cbd…` / counts `3/3/4/4/5/2/1/1/7` byte-identical to baseline. All work ran on the disposable `sca_domain_test` DB only. (The market-reference table is outside the 13-table provenance fingerprint; its production row count is N/A until deploy, and will be 0 immediately after.)

## Boundaries honored
No Krayin core edits. No Caddy / DNS / Shopify OAuth / Stripe / SMTP changes. No AI/marketplace/external pricing, no public value exposure, no resale. `ServiceService::record` / `ProjectionService::rebuild` / certification / QR paths unchanged.

**STOP — awaiting ChatGPT pre-merge audit of candidate `26a572a`. Do not merge or deploy.**

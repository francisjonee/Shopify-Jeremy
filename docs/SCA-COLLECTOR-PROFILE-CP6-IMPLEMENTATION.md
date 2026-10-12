# SCA Collector Profile — CP-6 — Private Collection Organization — CANDIDATE

**Date:** 2026-10-12 · **Status: CANDIDATE — R1 REMEDIATED (real add-vs-transfer/correction concurrency proof), re-pushed. NOT merged / NOT deployed / production untouched (migration 134) / Stripe DORMANT / mail=log / no Caddy/DNS/Shopify/SMTP change. STOP for ChatGPT re-audit.**

- **Impl repo:** `francisjonee/francisjonee-sca-platform-private` · **Governance:** `francisjonee/Shopify-Jeremy`
- **Branch:** `feat/sca-collector-profile-cp6`
- **Base (exact deployed baseline):** `0101755b03352305050b7b7290ad917b588112ff` (prod HEAD, migration 134)
- **Candidate head:** `2d15c6bb40b842c7368bd9bd08123a06e5df95d7` (R1 remediation of `82c8192`; 2 commits ahead of base)
- **Migrations:** candidate **134 → 135** (one additive migration, two new tables + triggers); **prod stays 134**.

## 0. Pre-merge audit R1 remediation (head `2d15c6b`)

**Finding (accepted):** mandatory concurrency proof #25 was not real — the previous
`CollectorCollectionConcurrencyTest::cc1` manually locked/updated `sca_item_current_state` and manually
deleted CP-6 membership rows instead of invoking the real `TransferWorkflow`/`ProjectionService::rebuild()`.

**Fix (2 files, delta from `82c8192`; NO production code change):** `tests/Support/cp6_worker.php` (new,
test-only; not autoloaded in prod) + rewritten `CollectorCollectionConcurrencyTest`. `pcntl_fork` is
unavailable in this image, so genuine overlap of two REAL service calls is achieved by running one side in
a separate OS process (its own DB connection) against COMMITTED `sca_domain_test` fixtures, coordinated by
a deterministic DB row-lock barrier:
- **cc1a (transfer wins):** the worker runs the REAL `TransferWorkflow::accept()`; the parent holds a barrier
  on the old-owner membership row so the transfer blocks mid-flight AT its real CP-6 delete while HOLDING
  `sca_item_current_state`; a concurrent old-owner `addItem()` (second worker) blocks on item-state; on
  release the real transfer commits (owner=B, real rebuild deleted the membership) and the add then ends in
  the generic **NOT_ELIGIBLE** — never a raw 1205/1213/SQL — writing no membership; old owner cannot group-read.
- **cc1b (add wins):** `addItem()` committed the membership first; the REAL transfer worker is held mid-flight
  at the CP-6 delete and the parent OBSERVES the membership still present + owner still A (delete is inside
  the uncommitted transfer txn); on release the real `rebuild()` deletes it and the transfer commits; B→A
  reacquisition does not resurrect it.
- **cc2 (admin correction):** same proof driving the REAL `OwnershipCorrectionService::correct()`.
- **cc3/cc4** unchanged (same-name DB-UNIQUE collision → generic DUPLICATE_NAME no raw SQL; pseudonymization
  account-first, cannot resurrect).

**No production behaviour changed** — the genuine overlap exposed NO defect: the existing lock order
(account→collection→item-state) and the `ProjectionService::rebuild()` CP-6 cleanup behave correctly under
real contention. The test is non-transactional (cross-process visibility) and **fully self-cleans**:
ownership is seeded by a single direct `claim` event (only `sca_ownership_events` + `sca_transfer_events`
append-only tables are touched), and tearDown briefly drops those two `no_delete` guard triggers around a
scoped delete, recreating them in a `finally` and self-healing in setUp — so it never pollutes neighbouring
tests' global-count assertions. Deterministic across repeated runs (5×). **Full `tests/Feature/Sca`: exit 0
· 1222 passed · 1 skipped (webp) · 0 failed · 6188 assertions.**

## 1. Invariant honoured
**Organization is presentation state only. Canonical current ownership remains the SOLE membership authority for My Collection.** CP-6 adds private user-defined collections (named groups) with many-to-many item membership and manual ordering. It NEVER grants ownership, NEVER makes an item public, NEVER becomes provenance. PRIVATE ONLY — no public route, no CP-4 grouping, no handle/public-profile change. No tag system, no first-class favorites.

## 2. Changed files (17: 10 new, 7 modified) — +`tests/Support/cp6_worker.php` (R1)
**NEW** — migration `2026_10_16_000001_create_sca_collector_collections.php`; `Models/CollectorCollection.php`; `Models/CollectorCollectionItem.php`; `Support/CollectionName.php`; `Exceptions/CollectionRejection.php`; `Services/CollectorCollectionService.php`; `Http/Controllers/CollectionGroupController.php`; `tests/Feature/Sca/CollectorCollectionTest.php`; `tests/Feature/Sca/CollectorCollectionConcurrencyTest.php`.
**MODIFIED** — `Services/ProjectionService.php` (ownership-loss cleanup hook); `Services/CollectorPrivacyService.php` (pseudonymization purge); `Http/Controllers/CollectionController.php` (group filter + organize state); `Services/CollectionService.php` (CP-2 catalog group filter); `Routes/collector-routes.php` (CP-6 routes); `Resources/views/collection/index.blade.php` (Collections section); `Resources/views/collection/show.blade.php` (Organize control).

## 3. Data model (migration 134 → 135)
`sca_collector_collections`: `id`; `collector_account_id` FK→accounts RESTRICT; `public_ref` (opaque immutable `CCL-`+12hex) UNIQUE; `name` VARCHAR(80); `name_normalized` VARCHAR(80); `position`; timestamps. UNIQUE(`collector_account_id`,`name_normalized`) = the collision authority; index (collector, position, id). Trigger `trg_sca_collections_bu` makes collector_account_id + public_ref immutable (name/position mutable).

`sca_collector_collection_items`: `id`; `collector_collection_id` FK→collections **CASCADE** (deleting a group deletes memberships only); `collector_account_id` FK→accounts RESTRICT (denormalized for safe collector-scoped cleanup/queries); `eyewear_item_id` FK→items RESTRICT; `position`; timestamps. UNIQUE(collection,item); indexes (collector,item) + (collection,position,id). Trigger `trg_sca_collection_items_bu` makes the identity columns immutable (position mutable); trigger `trg_sca_collection_items_bi` **pins the denormalized collector to the owning collection's collector** (robust DB guarantee against any cross-collector membership). NO brand/model/cert/status/ownership/visibility copied.

## 4. Name semantics
`CollectionName::normalize` — trim outer whitespace; collapse internal whitespace runs to a single space; reject empty/all-whitespace and control characters; 1–80 Unicode chars for display; normalized key = Unicode-aware `mb_strtolower(display)`. No reserved-name list (names are private, addressed by opaque ref). Duplicate = generic `DUPLICATE_NAME`; the DB UNIQUE(collector, name_normalized) is the ultimate authority. Rename changes only name/name_normalized; public_ref stable.

## 5. Service (`CollectorCollectionService`, sole writer/resolver)
All mutations are session-collector-only and account-first serialized (lock `sca_collector_accounts` FOR UPDATE + require active). Caps: **50 collections**, reorder payloads **50 groups / 100 items** (`PAYLOAD_TOO_LARGE`). Collision/contention: the write transaction runs with bounded retries (`MAX_ATTEMPTS=3`) on InnoDB concurrency errors, and the terminal catch maps `1062`/`1205`/`1213` to the generic `DUPLICATE_NAME` (create/rename) — never a raw QueryException/500, never partial state.

**Add mutation lock order (serializes against ownership mutation):** (1) lock active account; (2) lock the target collection (must belong to collector) FOR UPDATE; (3) resolve item by opaque ref; (4) lock the canonical `sca_item_current_state` row FOR UPDATE; (5) re-read `current_owner_collector_id` UNDER that lock (≠ collector → `NOT_ELIGIBLE`); (6) insert membership (idempotent; appended position). Lock order account→collection→item-state matches every ownership writer (no inversion → deadlock-safe). Contention with an in-flight ownership mutation surfaces as the generic `NOT_ELIGIBLE` (never raw SQL). Remove is always privacy-safe/idempotent/non-disclosing (unknown/non-owned collection or non-member item = silent no-op). Reorder rewrites only the collector's own rows, ignoring foreign/unknown refs.

Reads always intersect canonical current ownership (defense in depth): `listForCollector` (one bounded aggregate with current-ownership-intersected counts), `membershipStateForOwnedItem` (owner-scoped), and the CP-2 catalog group filter.

## 6. Ownership-loss cleanup (ProjectionService::rebuild) — mandatory
After the projection determines the current owner, in the SAME ownership-changing transaction: delete CP-6 membership rows for the item whose `collector_account_id != current owner` (ALL if owner is null). So transfer / admin ownership correction strips the old owner's organization atomically; the recipient inherits none; reacquisition does not resurrect (the collector must re-organize). **UNLIKE CP-4 public visibility, adverse registry status does NOT remove organization** — ownership is unchanged, so the current owner's rows are never deleted; lost/stolen frames stay privately organized/searchable. No account lock is taken (reset by item under the writer's held item transaction → no inversion).

## 7. Privacy / CP-4 separation
Pseudonymization (still refuses while the collector owns items) purges ALL CP-6 memberships then collections in the SAME privacy transaction, before pseudonymizing the account; no CP-6 name/ref reaches provenance. Strict CP-4 independence (proven both directions): a CP-6 add/remove never touches `sca_collector_public_items`; a CP-4 visibility change never touches CP-6; deleting a group changes nothing public; CP-6 names/refs never appear on `/c/*` or `/u/*`.

## 8. Routes / UX
Under `collector.auth` + web/CSRF, throttled: `POST /collector/collections` (create), `PATCH`/`DELETE /collector/collections/{CCL}` (rename/delete), `POST /collector/collections/reorder`, `POST`/`DELETE /collector/collections/{CCL}/items/{SCA}` (add/remove), `POST /collector/collections/{CCL}/items/reorder`. Refs are regex-constrained to their opaque shapes and `…/items/reorder` is registered before `…/items/{itemRef}` so the literal is never captured as an item ref. **No public routes; no availability/directory endpoint.** My Collection index gains a private Collections section (chips → `?group=CCL`, All-items default, create/rename/delete/reorder) and the item detail gains an Organize multi-select; selecting a group filters the CP-2 catalog to current-owned items in that group, preserving search/brand/cert/registry/sort/pagination.

## 9. Tests
- `CollectorCollectionTest` — **29 passed**: defaults + CP-2 unchanged (c1, c32); create + normalized-duplicate + invalid + cross-collector-name-OK (c2/c2b); 50-cap (c3); rename preserves ref/memberships (c4); delete removes only group+memberships, provenance+CP-4 intact (c5); group order + collector-scoped reorder + item reorder + payload cap (c6/c6b); add eligibility (active/collection-ownership/current-ownership/disabled→lifecycle) (c7); multi-group + idempotent add (c8/c9); remove idempotent/non-disclosing (c10); group catalog intersects ownership + preserves CP-2 filters (c11); counts from current-ownership intersection (c12); owner-scoped membership state (c13); transfer deletes memberships + no resurrection (c14/c15); admin correction cleanup (c16); **adverse does NOT delete organization** (c17); CP-4 independence both ways (c18); pseudonymization purge (c19); zero provenance (c20); opaque-refs-only HTML + HTTP roundtrip (c21/c21b); cross-collector guesses privacy-safe (c22); identity immutability + cross-collector-membership-blocked-at-DB (c23/c23b); normalized-name DB uniqueness (c24); bounded/no-N+1 (c29); no CP-6 on public surfaces/routes (c30/c31).
- `CollectorCollectionConcurrencyTest` — **5 passed** (R1), REAL two-connection via a separate OS process
  driving the UNMODIFIED production workflows (see §0), non-transactional + fully self-cleaning,
  deterministic across repeated runs (5×): cc1a REAL transfer wins → concurrent add generic NOT_ELIGIBLE;
  cc1b add wins → REAL rebuild deletes membership inside the transfer txn, no resurrection; cc2 REAL admin
  correction racing add; cc3 same-name collision (DB UNIQUE → generic DUPLICATE_NAME, no raw SQL); cc4
  pseudonymization-vs-mutation (account-first; cannot resurrect).
- **Full `tests/Feature/Sca`: exit 0 · 1221 passed · 1 skipped (known WebP GD env) · 0 failed · 6159 assertions.** Focused required regressions (CP-6 + CP-2 + CP-4 + concurrency + transfer + ownership correction + ownership history + CP-5 handle + CP-3 public profile + Passport) = 198 passed.

## 10. Production state (verified at restored baseline)
Live tree restored to `main` = `0101755` (deployed SHA unchanged), `--no-dev` re-pruned, caches cleared, `/admin/login` loopback → 200.
- Prod `sca_krayin` migrations **134**; `sca_collector_collections` + `sca_collector_collection_items` **ABSENT** (CP-6 migration applied only to the disposable `sca_domain_test`).
- Provenance row-data FP `d15a5cbdfb8df52ba65628b276533cfe` (CP-5 Phase-A documented procedure) — **unchanged**; canonical counts `3/3/4/4/5/2/1/1/7`.
- collectors **3** / private-profiles **0** / public-profiles **0** / public-items **0** / handle-bearing **0** / handle-tombstones **0**; `STRIPE_ENABLED` unset (dormant); `MAIL_MAILER` log.
- No Caddy/DNS/Shopify/SMTP change. `/u/*` edge admission (CP-5 Phase B) unchanged.

**STOP for ChatGPT re-audit of head `2d15c6b`.** Do not merge/deploy; no Caddy/DNS; do not start any post-CP6 initiative.

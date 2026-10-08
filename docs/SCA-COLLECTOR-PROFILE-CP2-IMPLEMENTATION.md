# SCA Collector Profile — CP-2 — Rich My Collection — CANDIDATE (remediated R1–R3)

**Date:** 2026-10-09 · **Status: CANDIDATE remediated (pre-merge audit R1–R3), NOT merged / NOT deployed / production untouched / Stripe DORMANT / mail=log. STOP for ChatGPT re-audit.**

- **Branch:** `feat/sca-collector-profile-cp2`
- **Base (exact production baseline):** `8d8c35947d7c405124e0df4f09ff3ef4ee9e6bb8`
- **Candidate head:** `5ebe9591a530874f5376296a2e10f538772834e8` (R1–R3 remediation of `eddac539`)
- **Impl repo:** `francisjonee/francisjonee-sca-platform-private` · **Governance:** `francisjonee/Shopify-Jeremy`
- **Migrations:** **NONE** — stays **131** (all display state derived at read time; no schema/model change)

## Pre-merge audit remediation (R1–R3) — head `5ebe959`

Four files changed from `eddac539` (`CollectionService.php`, `CollectionController.php`, `collection/index.blade.php`, `RichMyCollectionTest.php`); no migration. Core CP-2 architecture unchanged.

- **R1 — admin-correction chronology proof.** New `o4` uses the real `OwnershipCorrectionService::correct(itemId, 'collector', B.public_ref, reason, expectedEventCount)` (not a fabricated projection write) to reassign an item from A to B. Proves A loses membership immediately; B's default recent ordering treats the `admin_correction` event as the acquisition (newest first, `[corrected, mid, early]`); no reason/staff/internal data leaks into the card DTO or the rendered page. No tail-event query change was needed — the existing windowed max(effective_at,id) sub-join already treats the admin_correction terminal event as the acquisition.
- **R2 — collector presentation name in header.** `CollectionController::index` derives the authenticated collector's canonical `display_name` server-side (`trim`; null/blank → null) and passes it to the view; the header renders `"<name>'s Collection"` when present, else a neutral `"My Collection"`. Never email/public_ref/another collector. Presentation-only, no stored state; pseudonymized/disabled accounts remain gated by `collector.auth` (no bypass). Tests `r2a` (present), `r2b` (null + whitespace-only → neutral), `r2c` (no sensitive/cross-collector leak).
- **R3 — bounded aggregate summary.** `collectionStats()` refactored from fetch-all-rows-into-PHP to ONE SQL aggregate: `COUNT(*)` owned, `COUNT(current_certification_id)` certified, `COUNT(DISTINCT CASE WHEN brand IS NOT NULL AND TRIM(brand)<>'' THEN LOWER(TRIM(brand)) END)` brands. Exact CP-1 semantics preserved (null/empty/whitespace-only brand excluded; case-insensitive; transferred-away + unclaimed excluded by the current-owner join). Constant-size single-row result regardless of collection size. Tests `r3a` (casing/whitespace/null), `r3b` (certified vs uncertified), `r3c` (transferred-away + unclaimed excluded), `r3d` (single bounded query as the collection grows). Shared with CP-1 — the existing `CollectorProfileTest` stats tests (st1–st6) still pass.

Focused: `RichMyCollectionTest` **27 passed** (19 original + 8 remediation) + `MyCollectionTest` **12 passed** + `CollectorProfileTest` **32 passed / 1 skipped** (stats semantics under the new aggregate). Full governed SCA regression: **1085 passed / 5608 assertions, 1 skipped (webp)**, exit 0. Production re-verified untouched (deployed SHA still `8d8c359`, migr **131**, provenance DATA byte-identical FP `35e06328…`, collectors 3 / profiles 0, `STRIPE_ENABLED=false`/secret UNSET, `MAIL_MAILER=log`). **STOP for ChatGPT re-audit of head `5ebe959`.**

---

## Original candidate detail (head `eddac539`) — unchanged except as remediated above

## Scope delivered
Collection-LEVEL experience only. Item detail is untouched (no rebuild). `/collector/collection` becomes a responsive private catalog: summary header, owner-safe cards, GET-only search/filter/sort, canonical "recently added" ordering, clear empty/no-result states, bounded queries. No public surface, no favorites/tags/social/marketplace/valuation, no handles.

## Changed files (4: 3 modified, 1 new) — no migration
- `Sca/Collector/src/Services/CollectionService.php` — added `catalog()`, `collectionBrands()`, `normalizeCatalogFilters()`, private `catalogQuery()`/`applyCatalogFilters()`/`applyCatalogSort()`/`escapeLike()`/`card()`; `CATALOG_PAGE_SIZE=24`. Reuses CP-1 `collectionStats()`. **`ownedItems(int)` preserved** (existing call sites/tests unchanged).
- `Sca/Collector/src/Http/Controllers/CollectionController.php` — `index(Request)` passes `catalog($collectorId, $request->query())` to the view. `show()`/`passport()` unchanged.
- `Sca/Collector/src/Resources/views/collection/index.blade.php` — responsive card grid (wide collector layout), summary header, GET filter/sort form with retained state, result-context line, true-empty vs filtered-no-result states, filter-preserving pagination.
- `tests/Feature/Sca/RichMyCollectionTest.php` — new (19 tests).

## UX / query semantics
**Summary header** (from canonical current ownership via CP-1 `collectionStats`): registered / certified / distinct-brand counts.

**Cards** (owner-safe only): primary owner-authorized catalog image (existing `collector.collection.image` route) or a stable "No catalog image" placeholder; brand + model; SCA public reference; SKU (when present); year (when present); condition grade/label (when present); truthful current-certification badge (**Certified** ⇔ `current_certification_id` present, else **Not currently certified**); adverse registry warning when applicable. The whole card links to the existing owner-authorized detail route. The DTO carries **no** internal id, image path, QR/cert token, staff ref, frame_serial, Shopify data, or any other collector's data (`item_id`/`image_path` are selected server-side only, for the `has_image` boolean + authorized image route).

**GET-only controls**, allowlisted/normalized server-side in `normalizeCatalogFilters()` (invalid → safe fallback, never interpolated into SQL):
- `q` — free-text (trimmed, ≤100 chars), LIKE-escaped + bound, across **brand / model / public_ref / SKU**;
- `brand` — validated against THIS collector's own brands (`collectionBrands()`); any other value (incl. another collector's brand) is ignored;
- `cert` — all | certified | uncertified (canonical `s.current_certification_id`);
- `registry` — all | normal | attention (attention = `StatusService::ADVERSE_STATUSES`; normal excludes them);
- `sort` — recent (default) | brand_asc | brand_desc | ref; every sort has a deterministic tie-breaker (`public_ref`, and for recent the ownership-event id).

**"Recently added"** derives from canonical ownership provenance: the effective date of the TAIL ownership event (the event that made this collector the current owner — claim / transfer_in / admin_correction), via a single windowed sub-join on `sca_ownership_events` (`row_number() … partition by eyewear_item_id order by effective_at desc, id desc`, `rn=1`). No `item.created_at` substitute; **no stored `added_to_collection_at`** field.

**Pagination** fixed page size 24, filters preserved across pages; result-context line shown when filters/search are active; reset-filters action distinguishes "no matches" from "you own none".

**Filters never broaden membership** beyond `current_owner_collector_id`; search/filter/sort are read-only.

## Performance / query discipline
`catalog()` issues a bounded, constant number of queries regardless of collection size: collector brands (1) + stats (1) + matching count (1) + page fetch (1). The page fetch is a single statement (windowed sub-join for the added-date; no per-card image/history/cert queries). Image presence is a server-derived boolean; the image itself streams through the existing owner-authorized route. Proven by `n1` (query count identical for 2 vs 5 items, ≤ 6 total).

## Privacy / authorization invariants (unchanged)
Membership only from canonical current ownership; a prior owner loses list/detail/image access immediately after transfer (`m3`); guessed/non-owned refs remain privacy-safe (existing `show()`/image route, unchanged); collector guard required, staff session alone insufficient (`m1`); public Passport receives no collector/profile identity (`z2`); no public collection/profile route added; all browsing read-only / zero provenance mutation (`z1`).

## Tests
`RichMyCollectionTest` — **19 passed**: `m1` auth/staff separation, `m2` owner-scoped membership, `m3` prior-owner-drops-after-transfer, `s1` search brand/model/ref/SKU + cross-collector isolation, `s2` LIKE-wildcard escaping, `f1` collector-scoped brand choices + invalid-brand fallback, `f2` brand narrowing, `f3` canonical cert filter incl. revoked/no-current, `f4` registry attention/normal, `f5` invalid filter/sort/brand/page normalization, `f6` retained control state in HTML, `o1` recent order = ownership chronology incl. transfer-in, `o2` brand/ref sort determinism, `o3` same-brand tie-break, `e1` true-empty vs filtered-no-result, `c1` cards expose no internal/token/frame_serial/cross-collector data, `z1` zero provenance mutation, `z2` Passport privacy, `n1` bounded/no-N+1 queries.
Regression: `MyCollectionTest` **12 passed** (unchanged behavior — `ownedItems()` + detail + empty-state wording preserved).
Full governed SCA regression (`tests/Feature/Sca`): **1077 passed / 5573 assertions, 1 skipped (webp — env GD)**, exit 0 (1058 prior + 19 new). No `QrReissueTest::rg8` flake this run.

## Production state (verified at the restored baseline)
Live tree restored to `main` = `8d8c359` (deployed SHA unchanged), `--no-dev` re-pruned. Prod `sca_krayin` migrations **131** (CP-2 adds none); provenance DATA byte-identical (FP `35e063282e004eaabcc9240360ecc0e3`); collector accounts 3 / profiles 0 (unchanged); `STRIPE_ENABLED=false`, `STRIPE_SECRET` UNSET; `MAIL_MAILER=log`. No merge, no deploy, no Stripe/SMTP/Shopify/Caddy/DNS change, no CP-3.

**STOP for ChatGPT pre-merge audit of head `eddac53`.**

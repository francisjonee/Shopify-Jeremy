# SCA Collector Profile — CP-2 — Rich My Collection — CANDIDATE

**Date:** 2026-10-09 · **Status: CANDIDATE pushed, NOT merged / NOT deployed / production untouched / Stripe DORMANT / mail=log. STOP for ChatGPT pre-merge audit.**

- **Branch:** `feat/sca-collector-profile-cp2`
- **Base (exact production baseline):** `8d8c35947d7c405124e0df4f09ff3ef4ee9e6bb8`
- **Candidate head:** `eddac539c8c66f00c07d5adb54ffbc1a9d53e4b6`
- **Impl repo:** `francisjonee/francisjonee-sca-platform-private` · **Governance:** `francisjonee/Shopify-Jeremy`
- **Migrations:** **NONE** — stays **131** (all display state derived at read time; no schema/model change)

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

# SCA Shopify Sale / Claim — Staff Visibility — implementation candidate (NOT merged/deployed)

**Date:** 2026-10-07 · **Status: IMPLEMENTED + TESTED + PUSHED on a candidate branch. NOT merged, NOT deployed. Live tree restored to `main`; production byte-identical (prod DB NOT migrated — stays 122).** For ChatGPT candidate audit. Approved architecture: **Option C** (discovery gov `2b7ba70`).

## Candidate identity
- **Branch:** `origin/feat/sca-shopify-sale-claim-visibility`
- **Base SHA (= deployed `main`, merge-base):** `976088944de0fd2883f12a0686fafaa708ce8b9e`
- **Head SHA:** `31b22c594b3d19ceac7693a24918ed08ef1eacde` (1 commit)

## What was implemented (read-only, Option C)

### 1. Item-detail "Sale / claim" panel
A new `x-admin::tabs.item` "Sale / claim" on the eyewear item-detail page, rendering `eyewear/partials/sale-claim.blade.php` from a controller DTO (`$saleClaim`). `EyewearItemController::show()` adds **one SELECT** (`saleClaimPanel($id)`) over `sca_shopify_sale_links` for the item, ordered newest-first, exposing per the discovery contract:
- **Current state headline:** not linked / **sold — awaiting collector claim** (`eligible`) / **claimed by collector** (`claimed`, owner shown as opaque `COL-…`) / **no active link, prior sale ended** (when only terminal rows exist).
- **Current active link** (the single `eligible`|`claimed` row) with safe fields: Shopify order ID, line-item ID, product ID (if present), variant ID (if present), state label, **Recorded/Updated** timestamps.
- **Sale link history**: compact table of terminal rows (`revoked_refund`|`cancelled`), newest first.
- **Timestamps explicitly labelled** as "SCA record / webhook-processing times … not Shopify order payment dates."
- `revoked_return` handled defensively in the label map for display robustness only; it is never produced by the domain and is not presented as an operational state.

**Safe-field enforcement:** the `saleClaimPanel` SELECT lists only the 7 safe columns; `shopify_customer_ref` (always null) and `webhook_idempotency_key` are **never selected**, so they cannot reach the view. Owner is rendered only via the existing opaque `COL-…` `public_ref` (reusing `$currentOwnerRef`), never an email or internal id.

### 2. Dashboard "Sold — awaiting claim" tile
`DashboardController::index()` adds one count, **derived strictly** from `DB::table('sca_shopify_sale_links')->where('eligibility_state','eligible')->count()` — NOT the lifecycle projection. The view adds a tile linking to `admin.sca.eyewear.index` with `sale=awaiting_claim`. **The existing `certified_unclaimed` tile is left unchanged** in query, label, and meaning — it is **not** relabelled "not yet sold" (its projection count still includes sold-awaiting-claim items, which the new tile precisely separates).

### 3. Registry `sale=awaiting_claim` filter
`EyewearItemController::index()` adds an allowlisted single value `sale=awaiting_claim` that applies a **`whereExists`** on `sca_shopify_sale_links` (`eligibility_state='eligible'`, correlated on `eyewear_item_id`) — not a row-multiplying join, so each item appears once and existing pagination/sorting/`withQueryString` are preserved. Any unknown `sale` value is **ignored** (never broadens the result set, never reaches SQL). A visible, clearable `<select>` control was added to the index filter form; the dashboard tile links to this exact filter.

## Exact changed files (5 modified, 2 new)
Modified:
- `packages/Sca/Registry/src/Http/Controllers/EyewearItemController.php` — `show()` + new private `saleClaimPanel()`; `index()` allowlisted `sale=awaiting_claim` `whereExists` + pass-through.
- `packages/Sca/Registry/src/Http/Controllers/DashboardController.php` — `sold_awaiting_claim` count (eligible sale-links only); `certified_unclaimed` untouched.
- `packages/Sca/Registry/src/Resources/views/eyewear/show.blade.php` — new "Sale / claim" tab including the partial.
- `packages/Sca/Registry/src/Resources/views/eyewear/index.blade.php` — visible `sale` filter control.
- `packages/Sca/Registry/src/Resources/views/dashboard/index.blade.php` — "Sold — awaiting claim" tile + drill-down link.

New:
- `packages/Sca/Registry/src/Resources/views/eyewear/partials/sale-claim.blade.php` — read-only panel.
- `tests/Feature/Sca/ShopifySaleClaimVisibilityTest.php` — 12 tests.

**Untouched (verified in the diff):** `SaleLinkService`, `CommerceService`, `ClaimService`, `ClaimWorkflow`, `SaleLinkEventProcessor`, all Shopify app/config/scopes/OAuth/webhook registration, QR/certification/authentication/ownership/service/media, ACL definitions, routes, and every migration. **No migration added — prod stays 122.**

## Boundaries honored
- **Zero schema / zero migration** — read-only SELECT over existing tables; migration count unchanged (122).
- **Read-only** — no INSERT/UPDATE/DELETE; no mark-paid/claim/refund/cancel/reconcile controls; no Shopify API calls.
- **No PII / no secrets** — customer ref & idempotency key never selected; owner only as `COL-…`; no token/secret/billing data anywhere.
- **`certified_unclaimed` unchanged** — definition and label preserved; not relabelled.

## Tests
- **Focused `ShopifySaleClaimVisibilityTest` — 12 passed / 67 assertions:** `v1` no-link; `v2` eligible + safe-field presence + **explicit absence of the idempotency-key sentinel / `shopify_customer_ref` / `webhook_idempotency_key` in HTML** + timestamp-labelling (not "paid date"); `v3` claimed shows opaque `COL-…` and **no collector email**; `v4` refund-after-claim → `revoked_refund` shown + ownership preserved + no longer eligible; `v5` cancelled tombstone history/no-active; `v6` historical terminal + new eligible resale (one active + history); `v7` dashboard count = strict `eligible` count (parity with raw query; cancelled & no-link excluded); `v8` `certified_unclaimed` unchanged/not-relabelled + conflation demonstrated; `v9` filter set-equality (exactly eligible-linked items; cancelled & no-link excluded); `v10` unknown `sale` value ignored (not broadened) vs allowlisted value narrows; `v11` ACL (unauth→login, no `sca.eyewear.view`→403, with-view→200, dashboard needs only `sca.eyewear` not `sca.eyewear.status`); `v12` zero mutation (fingerprint of sale-links/claims/ownership/status/projection unchanged across rendering every surface).
- **Full governed gate:** `… -e DB_DATABASE=sca_domain_test … php artisan test tests/Feature/Sca` → **883 passed / 4784 assertions**, exit 0 (871 baseline + 12 new).

## Production-safety verification (post-restore)
- Live tree restored: `git checkout main` + `reset --hard origin/main` → app HEAD **`976088944de0fd2883f12a0686fafaa708ce8b9e`**; vendor re-pruned `--no-dev --optimize-autoloader`; `config:clear`+`route:clear`.
- **Candidate code absent on `main`:** `eyewear/partials/` and `ShopifySaleClaimVisibilityTest.php` do not exist on disk; `DashboardController` has zero `sold_awaiting_claim` occurrences.
- **Prod DB unchanged:** migrations **122**; provenance counts byte-identical to the deploy-result baseline — items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3 (pre-existing `claims` 2 / `sale_links` 1 from the earlier Shopify dry-run/dispose phase; `eligible` sale-links 0). No prod migration, no prod mutation.
- **Live HTTP invariants:** `/p/{bogus}` 404 · `/collector` 302 · `/admin/sca/dashboard` 403 (edge staff-IP gate for external requests) · unsigned `/sca/shopify/webhook` 401 · `/storage/..` 404 · `smsrocket.io` 302. All as baseline.
- **Shopify untouched:** no Shopify API/scope/app/OAuth/webhook change; no Shopify action taken.

## Candidate gate
**NOT merged. NOT deployed. No production mutation. Shopify untouched.** Awaiting ChatGPT candidate audit of head `31b22c594b3d19ceac7693a24918ed08ef1eacde`.

See `docs/SCA-SHOPIFY-SALE-CLAIM-STAFF-VISIBILITY-DISCOVERY.md`.

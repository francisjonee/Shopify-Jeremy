# Shopify Operational Listing SOP — implementation candidate (NOT merged/deployed)

**Date:** 2026-10-06 · **Status: IMPLEMENTED + TESTED + PUSHED on a candidate branch; SOP committed. NOT merged, NOT deployed. Live tree restored to `main`; production byte-identical. Shopify untouched.** For ChatGPT pre-merge audit. Approved discovery gov `28a01e4` (Option B).

## Candidate identity (SCA copy helper)
- **Branch:** `origin/feat/sca-shopify-listing-ref-copy`
- **Base SHA:** `0f86b4af90134de6c60664e16aad440a1d111204` (= deployed `main`; merge-base; clean 1-commit, fast-forwardable)
- **Head SHA:** `e81d7ef934ab05dd0e34f771e51863bbcfa23c2a`

## Changed files (exactly one view + one test)
- **MOD** `packages/Sca/Registry/src/Resources/views/eyewear/show.blade.php` (+59/-1) — copy-to-clipboard affordance beside the existing "SCA public reference" value + a self-contained client-side script.
- **NEW** `tests/Feature/Sca/ShopifyListingRefCopyTest.php` — 4 focused tests.

`git diff --name-only 0ca…→e81d7ef` touches only those two paths. **Receiver / `SaleLinkService` / `SaleLinkEventProcessor` / controllers / routes / ACL definitions / schema — all UNTOUCHED.** No Shopify mutation.

## Behavior (exactly Option B)
- Copies the item's **exact existing `public_ref`** (held in `data-sca-ref` + shown text) — never a generated/derived/alternate identifier.
- Visible only on the already-protected item-detail page; reuses existing **`sca.eyewear.view`** authorization; **no new ACL**, no controller/route change.
- **Progressive enhancement:** the `public_ref` stays visible and selectable with no JS; the button is a pure client-side read of the rendered value (no request, no mutation).
- **No external JS dependency:** Clipboard API with a legacy `execCommand` fallback and, failing both, a text-selection fallback; clear success ("Copied") / failure ("Press Ctrl/Cmd+C to copy") feedback via an `aria-live` status span.

## Tests
- **Focused `ShopifyListingRefCopyTest` 4/4:** `sl1` item detail shows the exact `public_ref` + the copy control; `sl2` the copy target equals `public_ref` (shape `SCA-<12hex>`), and is **not** the internal numeric id and **not** the QR `public_token`; `sl3` item-detail ACL intact (unauth → login redirect; staff without `sca.eyewear.view` → 403); `sl4` zero provenance mutation.
- **Full governed gate:** `… -e DB_DATABASE=sca_domain_test … php artisan test tests/Feature/Sca` → **855 passed / 4600 assertions**, exit 0 (851 prior + 4 new). No schema change.

## Zero-mutation evidence
`sl4` renders item detail and asserts the projection + item/QR/ownership fingerprint is unchanged (the helper is a client-side read of the already-rendered value).

## Production-safety verification (post-restore)
Tree **restored to `main`** @ `0f86b4a`; vendor re-pruned `--no-dev`; `PROD_FP = 62b2e42fe409b4ec91f3381b35da819e` (unchanged); migrations **120**; the copy helper (`sca-copy-ref`) is **absent** from the main `show.blade.php` (0); phpunit pruned; `/collector` 302, smsrocket.io 302, Shopify webhook POST → **401**. No merge, no deploy, no DB/schema/Shopify change.

## Operator SOP (committed)
Final operator-facing SOP: **`docs/SOP-SHOPIFY-OPERATIONAL-LISTING.md`** — states the permanent contract (line-item property `sca_item_ref` = `public_ref`, shape `SCA-XXXXXXXXXXXX`, qty 1, copy-never-type), the end-to-end flow, the storefront mechanisms, the pre-publish verification (no Bogus-Gateway transaction required to close — Phase-4 already proved the receiver), the fail-closed behavior table, and the hard don'ts.

### Metafield convention (storefront, NOT an SCA contract)
The SCA receiver consumes **only** the line-item property `sca_item_ref`; it reads **no** Shopify metafield. The SOP designates a product metafield **`custom.sca_item_ref`** (single-line text) as a **recommended storefront/theme convention** for supplying the hidden line-item property — explicitly labelled **operator/storefront convention, separate from the SCA integration contract**, and flagged to **validate against the store/theme before finalizing** (no Shopify mutation performed in this candidate).

## Pilot verification correction (applied)
The SOP's pre-publish check establishes: correct physical frame; correct `public_ref` copied; product/variant corresponds to that frame; inventory 1 / tracked / oversell off; the storefront/cart produces `properties.sca_item_ref` with the exact value; quantity 1. **A Bogus-Gateway transaction is NOT required to close this task; a live real-inventory sale is operator-gated** and not part of this software candidate.

## Scope boundary honored / NOT done
No Shopify API/scope change; no `read_products`/write scope; no product creation/sync; no OAuth/webhook change; no Shopify mutation; no receiver/`SaleLinkService`/`SaleLinkEventProcessor` change; no schema/migration; no lifecycle/provenance/claim/ownership change; no bulk onboarding; dry-run artifacts untouched. No merge, no deploy.

## Closure
On passing candidate + deployment audit, governance will state **Shopify Operational Listing SOP — CLOSED**; no second SOP slice; a future real-inventory sale is an operator action, not unfinished implementation.

See `docs/SCA-SHOPIFY-OPERATIONAL-LISTING-SOP-DISCOVERY.md`, `docs/SOP-SHOPIFY-OPERATIONAL-LISTING.md`.

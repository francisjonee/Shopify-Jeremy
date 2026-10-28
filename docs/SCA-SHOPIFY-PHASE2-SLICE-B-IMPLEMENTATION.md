# SCA — Shopify Phase 2 Slice B: Product→Physical-Eyewear Linking (UI + backend)

**Authorized development-branch implementation. Dev branch only — NO production migration, merge, or deployment; NO Shopify product modification; NO authentication / certificate / QR / ownership created by linking.** Static checks PASS (`php -l` clean on all changed PHP; Blade directives balanced). Focused tests written but **NOT run** here — they change the database and require a separate disposable-DB authorization. 2026-10-28. **STOP for independent review.**

## SHA & changed files

- Branch `feat/sca-shopify-phase2-linking`: **`5c1aa23` → `2343e044b5d801985b381ef022311dc1a2b45dcd`** (pushed `origin`/impl). Built in an isolated worktree; live `main 905ea7d` untouched. **17 files** (7 modified, 10 new):

Modified:
- `Sca/Registry/src/Http/Controllers/EyewearItemController.php` — `store()` routes create-with-link through the intake service + server-side link-ACL re-check; `create()` mints the idempotency key + `canLinkShopify`; `show()` adds the read-only link panel.
- `Sca/Registry/src/Http/Requests/StoreEyewearItemRequest.php` — optional `sku`, Shopify triplet (all-or-nothing `required_with`), idempotency key; `shopifyLink()` + `itemAttributes()` helpers.
- `Sca/Registry/src/Resources/views/eyewear/create.blade.php` — catalog search/select, prefill (overridable), hidden idempotency key, SKU field.
- `Sca/Registry/src/Resources/views/eyewear/show.blade.php` — new "Shopify link" tab.
- `Sca/Shopify/src/Config/acl.php` — repoint `sca.eyewear.shopify.link` → `admin.sca.shopify.catalog-search`.
- `Sca/Shopify/src/Routes/admin-routes.php` — catalog-search (GET) + link/relink/unlink (POST) under the link ACL + CSRF + throttle.
- `Sca/Shopify/src/Services/ShopifyProductLinkService.php` — append an immutable audit row on link/relink/unlink (inside the same transaction).

New:
- `Sca/Shopify/src/Services/EyewearShopifyIntakeService.php` + `LinkRejectedException.php`
- `Sca/Shopify/src/Http/Controllers/ProductLinkController.php`
- `Sca/Shopify/src/Models/EyewearShopifyLinkAudit.php`, `EyewearIntakeIdempotency.php`
- `Sca/Shopify/src/Database/Migrations/2026_10_28_000002_create_sca_eyewear_shopify_link_audit.php`
- `Sca/Shopify/src/Database/Migrations/2026_10_28_000003_create_sca_eyewear_intake_idempotency.php`
- `tests/Feature/Sca/EyewearShopifyIntakeTest.php`, `tests/Feature/Sca/ShopifyProductLinkRouteTest.php`

## How each objective is met

1. **Searchable, paginated catalog selector in the intake interface** — `ProductLinkController::search` (JSON, 20/page, bound LIKE over product title/vendor, variant SKU/title, escaped wildcards); consumed by a dependency-free selector in `create.blade.php` (search, paging, select).
2. **Shows title, vendor, variant, SKU, status** — each selector row renders all five; variant-level status gates linkability (`linkable = status==='active'`).
3. **Prefill brand/model/SKU with staff override** — selecting a variant fills empty brand/model/SKU inputs only (never clobbers staff edits); all remain editable and are validated/persisted as submitted.
4. **Physical-item details stay staff-controlled** — frame serial, intake type, year/country/materials/specs are the existing staff fields; the catalog never sets them.
5. **Create + link in ONE transaction** — `EyewearShopifyIntakeService::createLinked` calls the canonical `ItemService::create` then `ShopifyProductLinkService::link` inside a single `DB::transaction`. A rejected link throws `LinkRejectedException` → the whole transaction rolls back (no orphan item).
6. **Durable per-submission idempotency** — `sca_eyewear_intake_idempotency` (UNIQUE `idempotency_key`). The create form mints the key on render; a retry/double-click resubmits the SAME key. Fast-path returns the prior item; a true concurrent race loses the UNIQUE insert (QueryException 1062) → rollback → re-resolve to the winner's item. Exactly one physical item per submission.
7. **Authenticated link / unlink / explicit relink endpoints with `sca.can` enforcement** — three POST routes under `sca.can:sca.eyewear.shopify.link` + CSRF (web group) + `throttle:60,1`; relink is a distinct, audited operation (never a silent overwrite).
8. **Append-only audit history** — `sca_eyewear_shopify_link_audit` (actor, item, old+new shop/variant, action, timestamp); immutability DB-enforced by BEFORE UPDATE/DELETE triggers (SIGNAL 45000). Written atomically with the link.
9. **Server-side authorization (not UI-hiding)** — route middleware on all Shopify link routes; additionally `store()` re-checks `sca.eyewear.shopify.link` before any create-with-link and returns a real 403 (no item created) if absent. The create form hides the selector for non-linkers only as a convenience.
10. **Existing behavior preserved** — linking writes only the link + audit + idempotency tables; it never invokes authentication/certification/QR/ownership/claim code. Catalog sync, order/sale-link processing, and the plain create path (no key, no link) are unchanged. Two additive migrations; no change to existing tables.
11. **Focused tests** — permissions, selector behavior, prefill override, transaction rollback, idempotency, audit history (written; see below).

## Tests (written, NOT run — require separate disposable-DB authorization)

- `EyewearShopifyIntakeTest` (service): create-only; create+link+audit; **rollback on rejected link** (no orphan item/ledger/audit); **idempotency** (same key → same single item, one ledger row); missing-key rejected; staff override persistence; no-provenance-beyond-canonical; **audit immutability** (UPDATE & DELETE rejected).
- `ShopifyProductLinkRouteTest` (HTTP): catalog-search + link/relink/unlink **403 without the link ACL**; selector returns product/vendor/variant/SKU/status; query filter narrows; link→relink→unlink with audit; **create-with-link forbidden for create-only staff and creates nothing**; **double-submit yields one item**; override persistence; plain create still works.

Both carry the `SCA_TEST_DB` hard guard (refuse to run outside the disposable DB; never `sca_krayin`).

## Static verification performed (non-destructive)

- `php -l` clean on all 12 changed PHP source files **and** both test files (PHP 8.3.33).
- Blade directive balance verified for all three touched views (`@if/@endif`, `@foreach/@endforeach`).
- No DB connection, no app boot against production, no dev-vendor build in this worktree. Runtime/route-registration and the DB-backed tests are deferred to the authorized DB-test session.

## Production safety

Worktree-only; live `main 905ea7d` untouched. No `migrate` run anywhere (the two migrations exist only on the branch). No merge/deploy. No Shopify API call or product change. No Option C or unrelated migration-history change. The Phase-1 first-genuine-`products/*`-webhook verification remains a separate open task.

**STOP — Slice B implemented on the dev branch; review before any DB test, merge, or deploy.**

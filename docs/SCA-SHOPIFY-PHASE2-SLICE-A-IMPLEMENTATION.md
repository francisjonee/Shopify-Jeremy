# SCA — Shopify Phase 2 Slice A: Implementation (link layer, no UI)

**Approved Slice A implemented on `feat/sca-shopify-phase2-linking` (base `905ea7d`). Non-destructive checks only; DB-changing tests written but NOT run (await separate authorization + a uniquely-created disposable DB). No production migration/deploy, no live Shopify change, no UI, no Option C, no unrelated migration-history change. Catalog sync + order processing untouched.** 2026-10-28. **STOP for independent review.**

## Implementation SHA & files

- Branch `feat/sca-shopify-phase2-linking`: `905ea7d` → **`5c1aa23e45f78f33a5cd8c590b907dd049595417`** (pushed `origin`). Worktree-built; live tree stayed `main 905ea7d`, clean.
- 5 files (4 new / 1 edited):

| File | Δ |
|---|---|
| `…/Shopify/src/Database/Migrations/2026_10_28_000001_create_sca_eyewear_item_shopify_variant.php` | new (additive) |
| `…/Shopify/src/Models/EyewearItemShopifyVariant.php` | new |
| `…/Shopify/src/Services/ShopifyProductLinkService.php` | new (sole writer) |
| `…/Shopify/src/Config/acl.php` | edit (+`sca.eyewear.shopify.link`) |
| `app/tests/Feature/Sca/ShopifyProductLinkTest.php` | new (DB test) |

## How each authorized item is met

1. **Separate dev branch** — `feat/sca-shopify-phase2-linking` off `905ea7d`.
2. **Relationship table** — `sca_eyewear_item_shopify_variant` (additive `Schema::create`; `down` drops only it): `eyewear_item_id`, `shop_domain`, `shopify_product_id`, `shopify_variant_id`, `variant_sku_snapshot`/`variant_title_snapshot` (audit), `linked_by`, `linked_at`, timestamps.
3. **UNIQUE `eyewear_item_id`** (one variant per physical item) + **non-unique** `(shop_domain, shopify_variant_id)` index → many physical items may reference the same variant. FK `eyewear_item_id → sca_eyewear_items` (cascade on item delete); **no FK to the catalog tables** (so a soft-archived variant can't break an existing physical link).
4. **`ShopifyProductLinkService`** (sole writer): `link`, `unlink`, and explicit `relink`. `link` is idempotent (same variant → `exists`); linking an item already linked to a *different* variant → `rejected (already_linked_to_other_variant)`; `relink` is the explicit, audited re-point; `unlink` deletes only the join row.
5. **Validation** — rejects fail-closed unless: the physical item exists (`sca_eyewear_items`), the shop equals the expected verified store (`wrong_shop` otherwise), and the catalog variant exists for that `shop+product` and is `status='active'` (`variant_not_eligible` for missing/archived/wrong-product/wrong-shop). Ids are digit-normalized.
6. **ACL `sca.eyewear.shopify.link`** — a dedicated mutation permission added to the Shopify ACL config (placeholder `route` = the integration index until Slice B wires the link/unlink UI routes). `all`-permission roles already cover it; no seed needed.
7. **Duplicate-submission prevention + idempotency strategy** — the DB `UNIQUE(eyewear_item_id)` guarantees an item can never acquire two links; `link` is idempotent on re-send. The **future staff-intake double-submit** strategy is documented in the service: Slice B's create-with-link runs item-create + link in one transaction keyed on a per-submit idempotency token, so a double POST yields exactly one item and one link.
8. **No provenance side effects** — the service writes only the join table and only *reads* `sca_eyewear_items` to validate existence. It never creates/edits an authentication, certificate, QR identifier, ownership event, or claim link. Linking a product to a pair does not authenticate it.
9. **Focused tests** (disposable DB; `SCA_TEST_DB`-guarded; **not run**): one-to-many linking; UNIQUE duplicate prevention; idempotent re-link + explicit relink; wrong-shop / archived / unknown-variant / unknown-item rejection; non-interference (link **and** unlink create/touch zero ownership/auth/cert/QR/claim rows and never delete the item); and the ACL permission is defined.
10. **Catalog sync + order processing preserved** — no change to `ProductCatalogService`, `ProductSyncEventProcessor`, the importer/reconcile, `SaleLinkService`, or the webhook boundary. The link layer is strictly additive and invoked only by (future) staff intake.

## Non-destructive evidence

- `php -l`: **5/5 clean**.
- `acl.php` parses and contains `sca.eyewear.shopify.link`.
- Logic smoke (no DB): id digit-normalization (valid id kept; empty/`abc`/`../x` → null) and case-insensitive shop match — **OK**.
- DB feature tests **not executed** (they create the new table + rows and need the dev vendor + a database) — gated on separate authorization with a uniquely-created disposable DB.

## Remaining (future, separately authorized)

- Run the DB tests on an isolated unique disposable DB.
- Slice B: staff UI (create-form Shopify selector + prefill `brand←vendor`, `model_name←title(+options)`, `sku←variant.sku`; create-with-link in one txn with the idempotency token; link/unlink on item detail; wire the real link/unlink routes + repoint the ACL `route`).
- Slice C: surface the reference on item/auth screens + advisory linked-pair-count view.
- **Separate open task preserved:** the Phase-1 first-genuine-`products/*`-webhook delivery verification (not touched here).

**STOP — Slice A implemented (`5c1aa23`); non-destructive checks pass; DB tests written, not run. Awaiting independent review and separate authorization before any database-changing test. No production migration/deploy, no live Shopify change, no UI, catalog/order behavior unchanged.**

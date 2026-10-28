# SCA — Shopify Phase 2 Slice B: Isolated DB Test RESULT

**Authorized single isolated DB-testing session for Slice B (`2343e044b5d801985b381ef022311dc1a2b45dcd`). VERDICT: tests PASS — 28 tests, 96 assertions, 0 failures / 0 warnings / 0 skips.** One concrete finding for review (DEFECT-1: product-level status not enforced on link); one behavior note (idempotency key reuse). Uniquely-named disposable DB only; dropped + verified; production `sca_krayin` unchanged and the Slice A/B tables NOT migrated to prod. No prod migration/merge/deploy, no Shopify change, no live webhook, no Option C, no full regression. 2026-10-28. **STOP for independent review.**

## [1] Candidate & isolation

- Candidate `origin/feat/sca-shopify-phase2-linking` = **`2343e044b5d801985b381ef022311dc1a2b45dcd`**; built in an isolated detached worktree at that SHA. Live tree stayed `main 905ea7d`, clean. Dev vendor (phpunit) built in the worktree (live vendor is `--no-dev`).
- **[2] Disposable DB:** `sca_p2b_test_7860c4e3e7b0` — created only after an existence check returned 0; granted to `sca_app` on that DB only. Baseline `SHOW DATABASES` before = `information_schema, mysql, performance_schema, sca_krayin, sys` (no stray disposable DB).
- **[3] Isolation verified** (booted-app probe): `getenv(DB_DATABASE)` == `DB::connection()->getDatabaseName()` == live `SELECT DATABASE()` == `SCA_TEST_DB` == `sca_p2b_test_7860c4e3e7b0`, and ≠ `sca_krayin` → `ISOLATION OK`. Isolated test env (`.env.testing`/`.env`) contained zero `sca_krayin` references.

## [4] Migration (disposable DB only)

Full schema migrated into the disposable DB, including Slice A `2026_10_28_000001_create_sca_eyewear_item_shopify_variant` and Slice B `..._000002_create_sca_eyewear_shopify_link_audit` + `..._000003_create_sca_eyewear_intake_idempotency` (all DONE). These three tables are **absent from prod** (see [13]).

## [5]–[7] Test results

`vendor/bin/phpunit` over the three files → **OK (28 tests, 96 assertions)**, 0 failures/warnings/skips, PHPUnit 11.5.50 / PHP 8.3.33, ~8.9 s:

**EyewearShopifyIntakeTest (service) — 8 ✔**
- create-without-link → one item + INTAKE projection, no link; create-and-link commit together with one `link` audit row (actor/variant correct).
- **rejected link rolls back the whole intake** (ineligible variant → 0 orphan item / 0 ledger / 0 audit).
- **idempotency**: same key twice → `created` then `exists`, SAME item, exactly one item, one ledger row.
- missing key rejected (`missing_idempotency_key`, no item).
- staff attribute overrides persist (brand/model/sku as submitted, not catalog).
- intake creates no provenance beyond canonical (ownership/cert/qr/grant/subs unchanged).
- **audit rows immutable** (UPDATE and DELETE both rejected by the DB triggers).

**ShopifyProductLinkRouteTest (HTTP) — 10 ✔**
- catalog-search + link/relink/unlink **403 without the `sca.eyewear.shopify.link` ACL**.
- selector returns product title / vendor / variant title / SKU / status (+`linkable`); query filter narrows (total=1).
- link → relink → unlink via routes, with `link`/`relink`/`unlink` audit rows all present.
- **create-with-link 403 for create-only staff and creates nothing** (server-side enforcement, not UI-hiding).
- **double-submit yields exactly one item**; override persistence; plain create still works for creator.

**ShopifyProductLinkTest (Slice A compatibility) — 10 ✔** — all Slice A behavior intact under the new audit writes (1:N linking, no silent relink, idempotent, explicit relink, wrong-shop/archived/unknown rejected, non-interference, permission defined).

## [8] FINDING — inactive PRODUCT with an ACTIVE variant CAN be linked (for review)

Probe: product `status='archived'`, its variant `status='active'` → `ShopifyProductLinkService::link` returned **`{"outcome":"linked"}`**. The eligibility check (`variantEligibility`) validates only the **variant** row's `status='active'`; it does **not** consider the parent product's status. The selector surfaces `product_status` in its JSON but gates `linkable` on the variant status only.

- **Impact:** a physical item can be linked to a variant of an archived/draft product if the mirrored variant row happens to carry `status='active'`. Not a safety/provenance issue (linking creates no authentication/cert/QR/ownership/claim), but it diverges from the implicit "link only to live catalog entries" expectation.
- **Not repaired** (per instruction). Options for review: (a) also require product `status='active'` in `variantEligibility` + the selector's `linkable`; (b) accept variant-only gating as intended and document it. Reported, not expanded.

## [9] NOTE — idempotency key reuse with different details (working as designed)

Probe: `createLinked` called twice with the SAME key but DIFFERENT brand/model and a DIFFERENT variant → second call returned **`{"outcome":"exists","item":<same>,"link":"prior"}`**; the first item was returned unchanged (`brand='FirstBrand'`, linked variant `9601`), exactly one item total. The divergent second payload is **silently ignored**.

- This is **correct idempotency** — the key is the idempotency token and is machine-minted per form render (`bin2hex(random_bytes(16))`), so two genuinely different submissions never share a key in the real flow; the behavior guarantees a retry can't create a duplicate. No incorrect/duplicate item, no corruption.
- Minor observation: on key reuse the new payload is dropped without any signal. Acceptable given the auto-minted key; flagged only for awareness. **Not a defect.**

## [10] Provenance unaffected

Service test `intake_creates_no_provenance_beyond_canonical` + Slice A `linking_and_unlinking_never_touch_provenance` both PASS: authentication-submission, certification, QR, ownership, and claim-grant counts are identical before/after on the disposable DB; the physical item is never deleted by unlink.

## [11] Exact counts

28 tests · 96 assertions · **0 failures · 0 errors · 0 warnings · 0 skipped/risky** (plus a throwaway 2-test probe for [8]/[9], since removed — not committed). No failures were repaired or masked.

## [12] Cleanup verified

`REVOKE ALL` on the disposable DB from `sca_app`, then `DROP DATABASE` → the DB is gone (existence check 0), no residual grant references it (`mysql.db` count 0), `SHOW DATABASES` back to the baseline set. Throwaway probe/env files removed; the DB-test worktree (and its built vendor) removed; live tree `main 905ea7d`, clean.

## [13] Production unchanged

`sca_krayin` fingerprint == baseline: `items 3 / current_state 3 / ownership 5 / certifications 4 / qr 3 / claim_grants 1 / catalog_products 4565 / catalog_variants 5330`, max migration batch **28** (142 migration rows). The three link/audit/idempotency tables are **absent** in prod (0/0/0 — correctly not migrated). App health: `kr-app` loopback `/admin/login → 200`; edge `/admin/login → 403` (expected owner-IP allowlist, not a regression).

**STOP — Slice B DB tests PASS on a disposable DB; disposable DB dropped; production untouched. One finding (DEFECT-1, product-status not enforced on link) and one behavior note (key reuse) reported for review — not repaired. No prod migration/merge/deploy, no Shopify change, no live webhook, no Option C, no full regression. Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification.**

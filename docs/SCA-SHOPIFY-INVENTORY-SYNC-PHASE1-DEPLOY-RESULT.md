# SCA — Shopify Inventory Sync Phase 1: Deployment RESULT

**Authorized controlled production deployment of candidate `9f05c8a` executed. VERDICT: DEPLOYED — all gates and post-checks PASS.** Exactly the two additive catalog migrations ran; production eyewear/ownership data unchanged; the catalog tables are live but **dormant** (no webhooks registered, no `read_products`, no import run). No OAuth/scope change, no merchant reauthorization, no webhook registration, no import, no reconciliation scheduling, no Option C change, no unrelated migration, no Docker recreation, no DB rollback. 2026-10-27. **STOP and report for independent ChatGPT review.**

## Deployment SHA

- Prior `main`: `6ebe968`.
- **Deployed `main` (merge commit): `905ea7d09661994a7aa22b0e9a5c966a8b4c2a95`** (push `6ebe968..905ea7d`), second parent = reviewed candidate `9f05c8a`. Live working-tree HEAD = `905ea7d` on `main`.
- Rollback reference pinned: branch `shopify-p1-prerelease-pin → 6ebe968`.

## [1][2] Preflight re-confirmation (gates passed)

- `HEAD == origin/main == 6ebe968`, worktree clean, candidate `== 9f05c8a`, clean fast-forward ancestry.
- Verified backup available: `backups/sca-backup-20261027T021703Z.tar.gz.gpg` (checksum **MATCH**).
- **Pending set == exactly the two Shopify catalog migrations** (branch-files vs applied-rows diff). Baseline: items/state/owns/certs `3/3/5/4`, 140 migration rows, batch 27.

## [3] Merge (non-fast-forward) + push

`git merge --no-ff 9f05c8a` → merge commit `905ea7d`; the on-disk change set was **exactly the 16 approved files, all under `app/packages/Sca/Shopify/` + `app/tests/`** (asserted). Pushed `6ebe968..905ea7d`.

## [4] Migrations — exactly the two approved, scope re-gated

`migrate:status` (case-sensitive `Pending`) showed **only** `2026_10_27_000001_create_sca_shopify_products` and `_000002_create_sca_shopify_variants` as Pending. `migrate --force` then ran **both, DONE, exit 0** (prod batch 27 → 28). (A first status check used a case-insensitive match that falsely flagged a migration whose *name* contains "pending"; detection corrected — no migration had run at that point.)

## [5] Apache graceful reload

`apachectl configtest` → `Syntax OK`; `apachectl -k graceful` → issued OK. **Container not recreated** — `kr-app` `StartedAt` unchanged at `2026-10-18T21:54:33Z` (zero-downtime worker reload, not a restart).

## [6] Post-deployment verification (all PASS)

- **App health:** `/admin/login` → 200; public passport `/p/{token}` → 200 (new `WebhookController`/provider code loaded cleanly; no error pages).
- **New catalog tables:** `sca_shopify_products` and `sca_shopify_variants` **exist and are EMPTY** (0 rows each) — dormant, as intended.
- **Migration history:** exactly two new rows at **batch 28** (`…shopify_products`, `…shopify_variants`); total 142 rows; max batch 28; `rows_at_batch28 = 2`. Nothing else migrated.
- **Eyewear/ownership fingerprint UNCHANGED:** items/state/owns/certs = **3 / 3 / 5 / 4** (== baseline). The 139/140 batch-27 rows are untouched.
- Deployed `main` `905ea7d` == `origin/main`.

## [7] Backup & rollback preserved

- The verified recovery point (`sca-backup-20261027T021703Z`, batch-27 snapshot) is retained and unchanged; no backup was created or deleted.
- **Data-preserving rollback remains available** and is NOT `migrate:rollback`: `git revert -m 1 905ea7d` + advance tree + `apachectl -k graceful`, **leaving both tables and any future imported rows in place** (they become inert orphan rows like migr 140; the old code never references them). Dropping the tables is a separate, explicit owner decision — not part of rollback. `shopify-p1-prerelease-pin → 6ebe968` records the pre-merge state.

## [8] What is live vs still gated

- **Live now:** the catalog code and two empty tables; product-sync, importer, and reconciliation services are deployed but **inert** — no `products/*` webhook is registered, `read_products` is not granted, and no import/reconcile has run. The order/refund sale-link path is unchanged.
- **Still owner-gated (NOT authorized under this task, not done):** `read_products` scope + merchant re-consent; `products/*` webhook registration; initial import; reconciliation scheduling.

**STOP — Phase 1 deployed (`905ea7d`); exactly two additive migrations applied (batch 28); production data unchanged; tables live-but-dormant. No OAuth/webhook/import/reconcile/Option-C/rollback action. Reported for independent ChatGPT review.**

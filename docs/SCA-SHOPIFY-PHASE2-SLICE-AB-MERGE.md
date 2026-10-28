# SCA — Shopify Phase 2 Slice A+B: Controlled CODE-ONLY Merge

**Authorized code-only merge of `feat/sca-shopify-phase2-linking` (`a477dc4`) into `main`. DONE — origin/main `905ea7d` → `91b88f1`.** Merge only: NOT deployed, no migration applied, no restart/infra change, no live Shopify change, no Option C, no DB change. The live bind-mount (`/opt/sca-platform/app`) is unchanged and still serves `905ea7d`. 2026-10-28. **STOP.**

## [1] SHAs & status

- **Candidate** `origin/feat/sca-shopify-phase2-linking` = **`a477dc4f7dbd2c07b95368c6534a35eb315e2b90`** (== origin tip, verified).
- **main before** = `905ea7d09661994a7aa22b0e9a5c966a8b4c2a95` (local == origin/main == the final-regression baseline; had not advanced).
- Working trees clean. `merge-base(main, candidate)` = `905ea7d` → candidate is a clean linear descendant of main (no divergence).

## [2] Scope — approved Slice A+B + exactly three additive migrations

3 commits merged: `5c1aa23` (Slice A link layer), `2343e04` (Slice B UI+backend), `a477dc4` (Slice B corrections). Full diff `main..candidate` = 20 files, **all within `app/packages/Sca/` + `app/tests/Feature/Sca/`** — nothing outside. Exactly three migrations, all newly ADDED (`A`), none modifying an existing migration:
- `2026_10_28_000001_create_sca_eyewear_item_shopify_variant`
- `2026_10_28_000002_create_sca_eyewear_shopify_link_audit`
- `2026_10_28_000003_create_sca_eyewear_intake_idempotency`

Each is additive: `Schema::create` (+ append-only triggers on the new audit table) in `up()`, `dropIfExists` only in `down()`. No `ALTER`/`DROP`/`DELETE`/`UPDATE`/`TRUNCATE` on existing tables. No `composer.json`/lock, `.env`, Docker, Caddy, or core-config change.

## [3] Conflicts / unexpected changes

No conflicts (clean linear descendant). The merge commit's tree is **byte-identical** to the candidate tree (`git diff a477dc4 91b88f1` empty). No unrelated changes.

## [4] Regression evidence ↔ exact commit

The final regression (37 tests / 131 assertions / 0 fail/err/warn/skip, disposable DB) was run against **`a477dc4`** — the exact commit merged. Evidence: `docs/SCA-SHOPIFY-PHASE2-SLICE-B-FINAL-REGRESSION-RESULT.md`.

## [5] Protected-branch rules / workflow

`gh` is not installed on the host; the repository's established merge workflow (as with prior SCA merges) is a local `--no-ff` merge pushed to `origin main` over the `github-sca-platform` deploy key. The push was a **non-force fast-forward** (`905ea7d..91b88f1`) and was accepted by the remote — no protection rule rejected it. No force, no history rewrite.

## [6]–[7] Merge performed + resulting SHA

Merged in an **isolated temporary worktree** on a throwaway branch (`merge-tmp` at `905ea7d`), NOT in the live checkout, to avoid mutating the live bind-mount. `git merge --no-ff a477dc4` → merge commit **`91b88f1a7754e8589893fccfcd393cc4e0cfde74`** (parents `905ea7d` + `a477dc4`). Pushed `merge-tmp:main` → `origin/main`. Temp worktree + branch removed afterward.

## [8] main contains the approved changes

`origin/main` = `91b88f1`; `a477dc4` is an ancestor; the three migrations, `ShopifyProductLinkService`, `EyewearShopifyIntakeService`, `ProductLinkController`, the models, and the `shopify-link` partial are all present in the `origin/main` tree.

## NOT deployed (strict boundary honored)

- The live tree `/opt/sca-platform` remains on `905ea7d` (its local `main` was intentionally NOT advanced; origin/main is ahead in history only). The live docroot still lacks the new code (`shopifyLinkPanel` absent).
- Production DB `sca_krayin` unchanged: the three new tables are **absent** (idempotency table count 0); no migration run. App health unaffected (merge touched nothing live).
- Deploying this (fast-forward the live tree + `migrate --force` the three additive migrations + graceful reload) is a **separate authorization**, not performed here. Note for that step: the new code reads the link/audit tables on the item-detail view, so the migrations MUST be applied in the same deploy to avoid missing-table errors.

**STOP — Slice A+B merged to `origin/main` (`91b88f1`), code-only, not deployed, production untouched. Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification; and a future (separately authorized) deploy of `91b88f1` + its three additive migrations.**

# SCA — Shopify Phase 2 Slice C: Controlled CODE-ONLY Merge

**Authorized code-only merge of `feat/sca-shopify-phase2-visibility` (`aaa21a6`) into `main`. DONE — origin/main `91b88f1` → `cb8a8c3`.** Merge only: NOT deployed, no restart, no DB migration/change (Slice C adds none), no live Shopify, no Option C. The live checkout (`/opt/sca-platform`, bind-mounted to `kr-app`) is unchanged and still serves `91b88f1`. 2026-10-28. **STOP.**

## [1] SHAs
- **Candidate** `origin/feat/sca-shopify-phase2-visibility` = **`aaa21a6fc978e1fa4fd5be6e105e677d313e806d`** (== origin tip).
- **main before** = `91b88f1a7754e8589893fccfcd393cc4e0cfde74` (local == origin/main == live). No drift.
- `merge-base(main, candidate)` = `91b88f1` → candidate is a clean linear descendant (conflict-free).

## [2] Scope — exactly the four approved Slice C files
`git diff --name-status main..aaa21a6` = 4 files, nothing outside:
- `Sca/Registry/src/Http/Controllers/EyewearItemController.php` (M — read-query methods)
- `Sca/Registry/src/Resources/views/eyewear/index.blade.php` (M — registry indicator)
- `Sca/Registry/src/Resources/views/eyewear/partials/shopify-link.blade.php` (M — detail panel)
- `tests/Feature/Sca/ShopifyLinkVisibilityTest.php` (A — tests)

## [3] Test correction included; feature code unchanged from the tested implementation
Two commits merged: `992e048` (Slice C implementation) and `aaa21a6` (the disclosed test-assertion fix). `git diff 992e048 aaa21a6` touches **only** the test file; the product code under `app/packages` is **byte-identical** between `992e048` (DB-tested) and `aaa21a6`. The correction (`Physical pairs linked to this variant:</span> 2`) is present in `aaa21a6`.

## [4] No drift, conflict-free
main had not advanced (still `91b88f1`); the merge is a fast-forward-eligible linear merge with no conflicts.

## [5]–[7] Merge performed + SHA
Established process: merged in an **isolated temporary worktree** on a throwaway branch (`merge-c-tmp` at `91b88f1`) — NOT the live checkout — with `git merge --no-ff aaa21a6`, then pushed `merge-c-tmp:main`. The push was a **non-force fast-forward** (`91b88f1..cb8a8c3`) accepted by the remote (no protection rule rejected it). Resulting merge SHA: **`cb8a8c3277f4319bc7c2ebdb8e0238426400bc7a`** (parents `91b88f1` + `aaa21a6`). Temp worktree + branch removed afterward.

## [8] Merged tree matches the candidate
`git diff aaa21a6 cb8a8c3` is empty — the merge tree is identical to the approved candidate. `aaa21a6` is an ancestor of `origin/main`, and the Slice C files are present in the `origin/main` tree.

## [9] Production unchanged
Live tree `/opt/sca-platform` remains `91b88f1` (its local `main` was intentionally NOT advanced; origin/main is ahead in history only). The live docroot still lacks the new code (`pairsLinked` absent). `kr-app` loopback `/admin/login → 200`. Production DB `sca_krayin` untouched — Slice C introduces no migration, so there is nothing to apply.

## Not deployed (strict limits honored)
Code merge only. No deployment/restart, no DB migration/change, no live Shopify, no Option C, no unrelated code. Activating Slice C later (a separate step) is just: fast-forward the live tree `91b88f1 → cb8a8c3` + `apachectl graceful` — **no new migration** (the Slice A/B tables it reads already exist in prod). Rollback would be the reverse tree move + graceful.

**STOP — Slice C merged to `origin/main` (`cb8a8c3`), code-only, not deployed, production untouched. Separate OPEN: the first genuine `products/*` webhook verification on the next normal Shopify product change.**

# SCA — Transfer Status Clarity: Controlled Code-Only Merge — RESULT

**Authorized code-only merge of candidate `a44103a` (branch `feat/sca-transfer-status-clarity`) into
`main`. DONE: origin/main `e644c9c` → `a397a7e07762a6a98c210979a9cd3c4984f8d6a8` (--no-ff;
non-force fast-forward push).** Presentation-only change; no migration/schema/service change. Merge
performed in an isolated temp worktree — the live production checkout was never touched and remains
`cb8a8c3`, clean and healthy. NOT deployed. No prod DB change, no restart, no Shopify/email/live-
transfer/Option-C change. 2026-10-29. **STOP.**

## [1] SHAs verified
- Candidate `origin/feat/sca-transfer-status-clarity` = **`a44103ab0009bfedeef7830f3abedaf2270d6485`**.
- Pre-merge `origin/main` = **`e644c9cc87f3a388af73de00c38cba5fd57597a3`**.
- Production live checkout = **`cb8a8c3`** (unchanged throughout).
- `git merge-base origin/main candidate` = `e644c9c` → candidate is a clean **linear descendant** of
  main (branched off `e644c9c`, which already contains R0/R0b/R0c), so there is **no conflict** and
  **no overlapping-collector-code conflict with R0c**.

## [2] Changed files limited to the approved scope (6 files)
`git diff --name-status e644c9c..a44103a`:
- `M app/packages/Sca/Collector/src/Http/Controllers/CollectionController.php` (+6: inject
  `TransferWorkflow`, boolean `transferPending`)
- `M app/packages/Sca/Collector/src/Http/Controllers/TransferController.php` (+9/−5: status flashes)
- `M .../Resources/views/collection/index.blade.php` (+8: flash slot)
- `M .../Resources/views/collection/show.blade.php` (+15/−2: pending banner)
- `M .../Resources/views/transfer/initiate.blade.php` (+7: flash slot)
- `A app/tests/Feature/Sca/TransferStatusClarityTest.php` (new, 189 lines)

Total **229 insertions / 5 deletions**, all within `packages/Sca/Collector` + tests. **No migration,
no schema, no service file, nothing unrelated.** One commit (`a44103a`).

## [3] Test evidence corresponds to `a44103a`
`docs/SCA-OWNERSHIP-TRANSFER-STATUS-CLARITY-DB-TEST-RESULT.md` records the disposable-DB regression at
candidate **`a44103a`**: `TransferStatusClarityTest` 8/24 + `TransferWorkflowTest` 15/52 =
**23 tests / 76 assertions / 0 err/fail/warn/skip.**

## [4][5] Conflict check + isolated-worktree merge
- Conflict-free (linear descendant). Merge done in a throwaway worktree on branch `tmp-merge-xfer`
  created at `origin/main`, `git merge --no-ff candidate` → merge commit
  **`a397a7e`** with parents **`e644c9c`** (main) + **`a44103a`** (candidate).
- **Merged tree is byte-identical to the candidate** (`git diff a44103a a397a7e` empty), and vs old
  main shows **only the 6 approved files**.

## [6] Protections preserved
- **Non-force** push `HEAD:main` → `e644c9c..a397a7e` (fast-forward; `e644c9c` is the first parent).
  No `--force`, no history rewrite, protected-branch rules intact. Temp worktree + branch removed.

## [7] Resulting main contains BOTH R0/R0b/R0c AND the transfer-status enhancement
Spot-checked on the merged tree: all 4 additive R0c migrations present
(`2026_10_29_000001/000002`, `2026_10_30_000001/000002` under
`packages/Sca/Provenance/src/Database/Migrations`), the email-verification stack
(`CollectorEmailVerificationService`, `EmailVerificationController`, `CollectorEmailVerification`
notification), and the verified-buyer gate (`BUYER_VERIFICATION_REQUIRED` / `claimByPresaleGrant`
across `ClaimWorkflow`, `ClaimRejection`, `PresaleGrantClaimController`, `PresaleClaimGrantService`);
plus the new transfer-status banner + confirmations.

## [8] Merge SHA + expected changes
- **Merge SHA: `a397a7e07762a6a98c210979a9cd3c4984f8d6a8`** (origin/main now at this SHA).
- Parents: `a397a7e` ← `e644c9c` (main) + `a44103a` (candidate). Exactly the 6 approved files.

## [9] Production checkout unchanged + healthy
- Live `/opt/sca-platform`: SHA **`cb8a8c3`**, branch `main`, working tree clean. **Local `main` ref
  intentionally left at `cb8a8c3`** (not advanced) → the bind-mounted docroot gets NO new code until a
  separate, authorized deploy.
- Loopback `/admin/login → 200`. `sca_krayin` fingerprint unchanged: migrations **batch 29 / 145**;
  items **3** / ownership **5** / claims **2** / cert **4** / qr **3** / sale_links **1**; R0c
  `sca_presale_claim_grants` table + `sca_shopify_sale_links.order_email` column both **absent (0/0)**.

**STOP — merge complete; origin/main = `a397a7e`. ⚠️ DO NOT DEPLOY this main to production: it carries
R0/R0b/R0c, whose customer-claiming activation requires operational email verification (provider token
+ verified sender + SPF/DKIM — see `SCA-OWNERSHIP-EMAIL-DELIVERY-READINESS`). A deploy of the
transfer-status change alone, if ever desired, would still be a SEPARATE authorization (fast-forward
live tree + `apachectl graceful`, no migration needed for this change — but the 4 R0c migrations would
need migrate-before-code handling since they are now on main). Separate OPEN: Phase-1 first genuine
`products/*` webhook receipt verification.**

# SCA — Ownership R0+R0b+R0c: Controlled CODE-ONLY Merge

**Authorized code-only merge of `feat/sca-ownership-r0c-verified-buyer` (`539cd1f`) into `main`. DONE — origin/main `cb8a8c3` → `e644c9c`.** Merge only: NOT deployed, no migration applied, no restart, no SMTP/Shopify change, no Option C. The live checkout (`/opt/sca-platform`, bind-mounted to `kr-app`) is unchanged and still serves `cb8a8c3`; prod DB stays batch 29. 2026-10-29. **STOP.**

## [1] SHAs
- **Candidate** = **`539cd1fb96a308dd0eb3fcc2a6450fbe98211442`** (== origin tip, verified).
- **main before** = `cb8a8c3277f4319bc7c2ebdb8e0238426400bc7a` (local == origin/main == live; clean). `merge-base(main, candidate)` = `cb8a8c3` → clean linear descendant.

## [2] Scope — approved R0/R0b/R0c only
7 commits (R0 `ce74229`/`bf77490`, R0b `1592a78`, R0c `c1e252a`/`3148029`/`b042125`/`539cd1f`). Diff = **33 files, all within `app/packages/Sca/` + `app/tests/Feature/Sca/`** — no unrelated changes.

## [3] Regression evidence ↔ candidate
Combined 77 tests / 326 assertions / 0 fail was run at `539cd1f` (gov `SCA-OWNERSHIP-R0-R0B-R0C-FINAL-DB-TEST-RESULT.md`).

## [4] Conflict-free + four additive migrations
Clean linear merge, no conflicts. Exactly four additive, reversible migrations (would apply as **batch 30**): `2026_10_29_000001` (fulfillment cols on `sca_eyewear_items`), `2026_10_29_000002` (`sca_presale_claim_grants`), `2026_10_30_000001` (`order_email` on `sca_shopify_sale_links`), `2026_10_30_000002` (`sca_collector_email_verifications`). No existing table/data altered.

## [5]–[8] Merge performed + SHA
Established process: merged in an **isolated temporary worktree** on a throwaway branch (`merge-r0c-tmp` at `cb8a8c3`) — NOT the live checkout — with `git merge --no-ff 539cd1f`, then pushed `merge-r0c-tmp:main`. **Non-force fast-forward** (`cb8a8c3..e644c9c`), accepted by the remote (repository protections preserved; no force-push). Resulting merge SHA: **`e644c9cc87f3a388af73de00c38cba5fd57597a3`** (parents `cb8a8c3` + `539cd1f`). Temp worktree + branch removed afterward.

## [9] origin/main contains the approved changes; tree matches candidate
`origin/main` = `e644c9c`; `539cd1f` is an ancestor; `git diff 539cd1f origin/main` is **empty** (tree identical). R0c artifacts (`PresaleClaimGrantService`, `CollectorEmailVerificationService`, the 4 migrations, the new test suites) are present in the `origin/main` tree.

## [10] Production unchanged + healthy
Live tree `/opt/sca-platform` remains `cb8a8c3` (its local `main` intentionally NOT advanced; origin ahead in history only); the live docroot lacks the new code (`buyerIsVerified` absent). `kr-app` loopback `/admin/login → 200`. Prod `sca_krayin`: items 3 / ownership 5 / claims 2, **batch 29 / 145 rows**; the R0c tables (`sca_presale_claim_grants`, `sca_collector_email_verifications`) and the `order_email` column are **absent** in prod (migrations not applied).

## Not deployed / not activated (strict limits honored)
Code merge only. No deployment/restart, no DB migration/schema change, no SMTP config, no Shopify change, no live customer claim, no Option C. The claiming workflow is **inert until email delivery is configured** (verified-buyer gate fails closed; email verification deferred by the owner).

## Deploying this later (separate authorization)
Per the merge-readiness + email-readiness docs: **migrate-before-code** (the new code writes `order_email`/fulfillment columns — apply the 4 additive migrations from a separate `e644c9c`/`539cd1f` mount first, then fast-forward the live tree + `apachectl graceful`), **operational email delivery** (provider token + verified sender + SPF/DKIM) so `email_verified_at` can be set, grant the `sca.eyewear.fulfillment.release` ACL (Administrator `all` already holds it), and the order-email backfill (no-op; skippable). Never release the bearer-only workflow.

**STOP — R0+R0b+R0c merged to `origin/main` (`e644c9c`), code-only, not deployed, production untouched. Separate OPEN: the first genuine `products/*` webhook verification; and a future (separately authorized) deploy gated on email delivery.**

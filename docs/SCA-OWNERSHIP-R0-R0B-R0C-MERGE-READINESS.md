# SCA — Ownership R0+R0b+R0c Code-Only Merge Readiness (READ-ONLY)

**VERDICT: SAFE TO MERGE (code-only, no deployment).** Read-only review of candidate `539cd1f` into `main` (`cb8a8c3`). No merge/deploy/migrate/prod change performed. Merging the code advances `origin/main` history only; the live checkout + prod DB stay on `cb8a8c3`, and the feature is **inert until email delivery is configured** (fails closed). 2026-10-29. **STOP.**

## [1] SHAs — no drift
- Candidate `origin/feat/sca-ownership-r0c-verified-buyer` = **`539cd1fb96a308dd0eb3fcc2a6450fbe98211442`** (== target).
- `origin/main` = local `main` = live `HEAD` = **`cb8a8c3`** (production baseline; unchanged).
- `merge-base(main, candidate)` = `cb8a8c3` → candidate is a **clean linear descendant** (fast-forward-eligible; conflict-free).

## [2] Complete R0+R0b+R0c implementation present
7 commits: R0 (`ce74229` retire public-QR claim, `bf77490` e16 fix), R0b (`1592a78` private presale grant), R0c (`c1e252a` verified-buyer gate, `3148029` + `539cd1f` disclosed test fixes, `b042125` order-email propagation). Verified in the candidate tree: `ClaimWorkflow` carries `PUBLIC_CLAIM_RETIRED` + `claimByPresaleGrant` + `buyerIsVerified`; `FulfillmentReleaseService`, `PresaleClaimGrantService`, `CollectorEmailVerificationService` all present.

## [3] Tests correspond to the candidate
The combined regression (77 tests / 326 assertions / 0 fail) in `SCA-OWNERSHIP-R0-R0B-R0C-FINAL-DB-TEST-RESULT.md` was run at this exact candidate (`539cd1f`, the post-fix tip). The 7 suites (`VerifiedBuyerClaimTest`, `PresaleClaimGrantTest`, `OwnershipR0PublicClaimRetiredTest`, `ClaimWorkflowTest`, `ShopifySaleClaimVisibilityTest`, `ExternalClaimTest`, `SaleLinkOrderEmailTest`) are all in the candidate diff.

## [4] Conflicts / migrations / unrelated changes
- **Conflict-free** (linear descendant). **33 files**, every one under `app/packages/Sca/` or `app/tests/Feature/Sca/` — **no unrelated changes**, no composer/env/Docker/Caddy/core-config touched.
- **4 additive migrations** (would apply as **batch 30**), all new files (`A`):
  - `2026_10_29_000001` add nullable `fulfillment_released_at`/`_by` to `sca_eyewear_items`
  - `2026_10_29_000002` create `sca_presale_claim_grants` (CHECKs on the NEW table only)
  - `2026_10_30_000001` add nullable `order_email` to `sca_shopify_sale_links`
  - `2026_10_30_000002` create `sca_collector_email_verifications`
  Each is `Schema::table add-nullable-column` or `Schema::create`; `down()` drops the added column/table. **No `ALTER`/`DROP`/`DELETE`/`UPDATE`/`TRUNCATE` on existing tables or data.** They depend only on pre-existing tables (`sca_eyewear_items`, `sca_shopify_sale_links`, `sca_collector_accounts`, `sca_claims`); no inter-migration ordering hazard.

## [5] Safe to merge code into main without deployment — YES
Merging via the established isolated-temp-worktree + `push origin main` advances `origin/main` to a new merge commit but **does not** run migrations, **does not** touch the live bind-mount, and **does not** deploy. Production code + DB remain `cb8a8c3` / batch 29. The additive migrations simply sit in history until a separately-authorized deploy applies them.

## [6] Live production checkout remains unchanged
As with every prior SCA merge, the merge is performed in an isolated scratch worktree; `/opt/sca-platform` (the live RW bind-mount) stays on `cb8a8c3` and its local `main` is intentionally NOT advanced (origin ahead in history only). Verified pre-review: live `HEAD` = `cb8a8c3`, clean.

## [7] Future deployment prerequisites (when separately authorized)
1. **MIGRATE-BEFORE-CODE (mandatory):** the new `SaleLinkService`/`SaleLinkEventProcessor`/`ShopifyReconciliationService` write `order_email`, and `FulfillmentReleaseService` writes `fulfillment_released_at` — activating the code before the 4 migrations would cause "unknown column" failures on the next order webhook/reconcile/release. Apply the 4 additive migrations (batch 30) first (from a separate `539cd1f` mount, as in the Phase-2 deploy), then fast-forward the live tree + `apachectl graceful`.
2. **Email delivery (BLOCKER for customer claims):** provider token + verified sender + SPF/DKIM + prod `MAIL_MAILER=postmark` (see `SCA-OWNERSHIP-EMAIL-DELIVERY-READINESS.md`). Until live, `email_verified_at` cannot be set → the presale claim gate is unsatisfiable (feature inert but safe).
3. **ACL:** grant `sca.eyewear.fulfillment.release` to the intended staff role (the single Administrator `all` role already holds it).
4. **Order-email backfill:** no-op (0 eligible rows); safely skippable.
5. Combined regression green (done) + separate deployment approval. Never release the bearer-only workflow (R0c must be the active path).

## [8] Accidental customer-claim activation paths — NONE
A repo-wide review confirms the presale/shopify-sale ownership path cannot activate before email delivery is configured:
- `ClaimService::openShopifyClaim()` has **exactly one** app caller — `ClaimWorkflow::claimByPresaleGrant()` (line 340), strictly **after** the `buyerIsVerified` gate (requires sale link `order_email` present + collector `email_verified_at` NOT NULL + normalized match; fails closed otherwise).
- The public-QR `ClaimWorkflow::claim()` is retired (throws `PUBLIC_CLAIM_RETIRED`).
- `email_verified_at` is set **only** by `CollectorEmailVerificationService::confirm()` (the one-time challenge), which needs email delivery (blocked); collector registration never sets it, and anonymization only nulls it.
- Therefore, even if `539cd1f` were merged **and deployed** without email configured, **no customer presale claim can succeed** (gate fails closed). External-intake claiming (separate, cert-based) is unchanged; public QR remains 410.

## Conclusion
A code-only merge of `539cd1f` to `origin/main` is **safe and non-activating**: conflict-free linear history, additive reversible migrations, no unrelated changes, live checkout + prod DB untouched, and the customer-claim feature is inert-until-email by design. Deployment remains separately gated on migrate-before-code + email delivery + approval.

**STOP — READ-ONLY merge-readiness review complete; no merge/deploy/migrate/prod change made. Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification.**

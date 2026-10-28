# SCA — OWNERSHIP R0 e16 CORRECTED (branch bf77490); test-only; DB re-run pending (sep auth); UNMERGED/undeployed. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** Authorized test-only fix of the sole R0 DB-test incompatibility. Evidence: `docs/SCA-OWNERSHIP-R0-E16-CORRECTION.md`.
- **SHA ce74229→`bf774905dd3997abc4efcd5044b16d7db0d6272d`** (pushed origin). 1 file (ExternalClaimTest.php, e16 only).
- e16 renamed → e16_public_qr_token_claim_is_retired_even_with_eligible_sale_link; setup kept (certified sce_presale + active QR + eligible sale link); now asserts ClaimWorkflow::claim()→PUBLIC_CLAIM_RETIRED, 0 ownership/0 claim, item unclaimed, sale link stays eligible. No private grant substituted (covered by e-series). php -l clean; only ExternalClaimTest changed.
- Expected on next authorized disposable-DB run: full ExternalClaimTest passes (prior 1 error resolved) → all four suites green.

**STOP — e16 fixed. NEXT (sep auth): re-run the four suites on a disposable DB at bf77490 (expect 0 errors) → merge decision → R0b (sce_presale private grant + fulfillment-release; R0 must NOT deploy alone). SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification.**

---

# SCA — OWNERSHIP R0 DB TEST PASS (security contract; disposable DB); 1 reported incompatibility (ExternalClaimTest::e16); prod unchanged; AWAITING review. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** Authorized isolated DB-test of R0 (ce74229). Evidence: `docs/SCA-OWNERSHIP-R0-DB-TEST-RESULT.md`. Disposable DB only; dropped+verified; prod sca_krayin + SHA cb8a8c3 UNCHANGED. No prod migrate/merge/deploy/live-Shopify/live-claim/Option-C.
- Isolation verified (getenv==getDatabaseName==live SELECT DATABASE()==SCA_TEST_DB==disposable, ≠sca_krayin). NAMING DEVIATION (documented): the 4 suites hard-guard the LITERAL `sca_domain_test` (ignore SCA_TEST_DB) → used a FRESH `sca_domain_test` (absent at baseline; no other session), dropped after. Migrated + `db:seed` (web routes need channel/config state).
- **Combined (seeded): 48 tests / 228 assertions / 1 error / 0 failures / 0 skips.** Per-suite: OwnershipR0PublicClaimRetiredTest 7/29 OK; ClaimWorkflowTest 11/44 OK; ShopifySaleClaimVisibilityTest 12 OK; ExternalClaimTest 17 pass + 1 ERROR.
- R0 contract CONFIRMED: [6] every public claim→410 (eligible/missing/cancelled/refunded); [7] 0 ownership/0 claim/sale-link stays eligible; [8] malformed+unknown both 410 (no enumeration); [9] private grant → exactly one ownership; [10] expired/used/unauthorized grants rejected (ExternalClaim grant suite); [11] passport viewing + collector routing + transfer/former-owner preview intact.
- **[12] ONLY incompatibility (REPORTED, not repaired): `ExternalClaimTest::e16_shopify_claim_path_is_unchanged` (line 419) calls retired ClaimWorkflow::claim()→now throws PUBLIC_CLAIM_RETIRED. Recommend update/remove e16 when finalizing R0.** No other test/route depends on the retired path (ClaimController handled→410; public routes intentionally retired).
- Combined-run /install redirects were an unseeded-DB artifact (gone after db:seed), NOT an R0 regression.
- prod fingerprint: items3/own5/claims2/cert4/qr3/grant1; batch 29/145; loopback /admin/login 200.

**STOP — R0 verified. ⚠️ RELEASE DEPENDENCY: do NOT deploy R0 alone without approved R0b (sce_presale private grant + fulfillment-release) — R0 leaves sce_presale with no claim path; external_intake unaffected. NEXT (owner): fix e16 on R0 branch → merge decision → R0b. SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification.**

---

# SCA — OWNERSHIP R0 IMPLEMENTED (branch ce74229): public QR-token claiming RETIRED; static PASS; DB tests NOT run; AWAITING review. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** R0 (GAP-1) on feat/sca-ownership-r0-retire-public-claim off prod cb8a8c3. Evidence: `docs/SCA-OWNERSHIP-R0-RETIRE-PUBLIC-CLAIM.md`. Worktree-only; prod/main cb8a8c3 untouched. No migration/deploy/merge/live-Shopify/live-claim/Option-C.
- **SHA cb8a8c3→`ce7422984809dd9013cf68b03de3c60c1f71c9ae`** (pushed origin). 7 files, NO migration.
- ClaimWorkflow::claim() throws new ClaimRejection::PUBLIC_CLAIM_RETIRED at the very top (before resolve/open/complete) → public QR token NEVER acquires ownership, even with an eligible Shopify sale link (sale link stays eligible, 0 claim/ownership rows). Old sale-link claim body removed (no flag).
- ClaimController: public POST → 410 Gone (PII-free msg → use private link); GET claim page → view-only `public_retired` notice, NO form (additive branch in shared show.blade; grant flow's `eligible` form untouched). Malformed/unknown token → 410 (no enumeration).
- PRESERVED: /p/{token} passport viewing, collector register/login, My Collection, transfer, claimByGrant (private grant path + all protections), preview() (unchanged).
- Reimplemented against cb8a8c3; NO Option C file copied/merged. Omits sce_presale fulfillment-release migr/ACL (= proposed R0b).
- Tests WRITTEN NOT run (sep disposable-DB auth): NEW OwnershipR0PublicClaimRetiredTest; ClaimWorkflowTest rewritten to retired contract; ShopifySaleClaimVisibilityTest 3 setup sites moved to ClaimService primitive. php -l clean; Blade balanced.
- ⚠️ NOTE: after R0, sce_presale items have NO live claim path until R0b (private sce_presale grant); external_intake grant claiming unaffected.

**STOP — R0 for review. NEXT (sep auth): run OwnershipR0PublicClaimRetiredTest + ClaimWorkflowTest + ShopifySaleClaimVisibilityTest + ExternalClaimTest on a unique disposable DB at ce74229; then merge decision (code-only, NO migration); then R0b (sce_presale private grant + fulfillment-release). SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification.**

---

# SCA — CUSTOMER OWNERSHIP PASSPORT AUDIT (read-only) delivered; recommend R0 (retire public-token claiming). Prod cb8a8c3. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** READ-ONLY audit of the customer QR Ownership-Passport system at prod cb8a8c3. Evidence: `docs/SCA-CUSTOMER-OWNERSHIP-PASSPORT-AUDIT.md`. No code/DB/merge/migration/deploy/Shopify/live-claim.
- INVENTORY: QR (QrService), public passport /p/{token} (PassportResolver), collector register/login, claiming (ClaimWorkflow→ClaimService; public-token ClaimController + private GrantClaimController), My Collection (Collector UI2), transfer (TransferWorkflow invite token), Shopify sale→item (SaleLinkService via public_ref only; dormant), Phase 2 variant links (ShopifyProductLinkService, reference/visibility only) — ALL deployed.
- FREE claim = sce_presale, entitlement=Shopify sale link (openShopifyClaim), no charge. PAID = external_intake, pay for authentication, entitlement=issued cert→staff grant (openExternalClaim). Both → ClaimService ownership under item lock; terminal claims immutable.
- ⚠️ SECURITY GAP-1 (central): on main, public /p/{token} doubles as a claim credential — a signed-in collector who sees the passport can claim an item with an eligible unclaimed Shopify sale link. LATENT (0 sale links) but activates when sales flow. Option C closes it (public-token claiming retired → private grants + sce_presale staff fulfillment-release gate).
- Option C branch 0f41e2e UNMERGED + STALE vs cb8a8c3 (161 files; reverts deployed backup/DR + test harness) → do NOT merge as-is; re-cut the claim-flow intent onto cb8a8c3.
- Phase 2 variant link NOT wired to sale matching; must NOT be (1 variant→N pairs ambiguity).
- **RECOMMENDED SMALLEST NEXT TASK (R0): on a fresh branch off cb8a8c3, retire public-QR-token ownership claiming in ClaimWorkflow::claim (→NOT_ELIGIBLE; claimByGrant sole path), CODE-ONLY no schema; fulfillment-release gate = R0b follow-up.** Dev+disposable-DB only.

**STOP — audit delivered; awaiting owner prioritization. SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification on next organic product change.**

---

# SCA — SHOPIFY PHASE 2 SLICE C DEPLOYED to prod (cb8a8c3); healthy; prod data UNCHANGED. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** Authorized controlled release of Slice C (cb8a8c3) DONE + verified. Evidence: `docs/SCA-SHOPIFY-PHASE2-SLICE-C-DEPLOY-RESULT.md`.
- Prod code `91b88f1`→`cb8a8c3` (live tree ff-only + `apachectl graceful`; NO Docker recreate; NO migration — Slice C adds none). 4-file read-only visibility delta.
- Verified: deployed SHA cb8a8c3; /admin/login 200, registry/detail 302 (auth, not 500); new index linked-map + detail pair-count queries run clean read-only against prod; logs clean (no Laravel/apache errors); edge 403 (owner allowlist).
- **PROD DATA UNCHANGED:** items3/state3/auth4/cert4/qr3/own5/grant1; catalog 4565/5330; batch 29/145; link/audit/idempotency 0/0/0 (unchanged). No new records.
- Rollback (if needed): live tree→91b88f1 + graceful (code-only; no DB action). Not needed — all checks passed.

**STOP — Slice C live + healthy. SEPARATE OPEN: first genuine products/* webhook receipt verification on next organic Shopify product change (unaffected by this release).**

---

# SCA — SHOPIFY PHASE 2 SLICE C MERGED to origin/main (cb8a8c3); CODE-ONLY, NOT deployed; prod still 91b88f1. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** Authorized CODE-ONLY merge of feat/sca-shopify-phase2-visibility (aaa21a6) into main. Evidence: `docs/SCA-SHOPIFY-PHASE2-SLICE-C-MERGE.md`. No deploy/restart/migration/Shopify/Option-C.
- **origin/main `91b88f1`→`cb8a8c3277f4319bc7c2ebdb8e0238426400bc7a`** (--no-ff merge commit; parents 91b88f1 + aaa21a6; non-force FF push). Merge tree byte-identical to candidate; conflict-free; exactly 4 approved files; product code byte-identical to DB-tested 992e048 (only the test file differs between 992e048 and aaa21a6).
- Merge done in ISOLATED temp worktree, NOT the live checkout → live /opt/sca-platform still 91b88f1 (docroot lacks new code; loopback /admin/login 200). Prod sca_krayin UNCHANGED (Slice C adds NO migration). Temp worktree+branch removed. ⚠️ live local main intentionally left at 91b88f1 (origin ahead in history only).
- Slice C = read-only linked-product visibility (DB-tested 7/7, gov 109074a).

**STOP — merge complete. NEXT (SEPARATE auth): OPTIONAL deploy of cb8a8c3 = ff live tree 91b88f1→cb8a8c3 + `apachectl graceful` (NO new migration — tables already in prod; no Docker recreate). SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification on next organic product change.**

---

# SCA — SHOPIFY PHASE 2 SLICE C DB TEST PASS (7/7, disposable DB); branch aaa21a6; prod unchanged; AWAITING merge decision. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** Authorized ONE isolated DB-test for Slice C (992e048). Evidence: `docs/SCA-SHOPIFY-PHASE2-SLICE-C-DB-TEST-RESULT.md`. Disposable DB `sca_p2c_test_f1e008cde238` only; dropped+verified (0 residual); prod sca_krayin + SHA 91b88f1 UNCHANGED. No prod migrate/merge/deploy/Shopify/ownership/Option-C/full-regression.
- Isolation verified (getenv==getDatabaseName==live SELECT DATABASE()==SCA_TEST_DB==disposable, ≠sca_krayin). Slice C adds NO migration (schema = Slice A/B 000001-3).
- **ShopifyLinkVisibilityTest 7 tests / 29 assertions / 0 fail/warn/skip** (after 1 DISCLOSED test-only fix). Covers [6] linked product title/vendor/variant/SKU/ref/linked-at; [7] pair count=2 (re-confirmed); [8] archived→inactive + link preserved; [9] deleted→unavailable from snapshot + preserved; [10] registry linked/inactive/unlinked indicators (1 bounded query, no N+1); [11] viewer sees read-only info, NOT relink/unlink controls; [12] no link/provenance mutation.
- DISCLOSED FIX (not silent): test #2 expected contiguous "Physical pairs linked to this variant: 2" but markup splits label/value with </span>; FEATURE correct (count=2 verified). Test-only one-line fix → branch 992e048→**`aaa21a6fc978e1fa4fd5be6e105e677d313e806d`** (product code byte-identical).
- prod fingerprint baseline: items3/state3/auth4/cert4/qr3/own5/grant1; catalog 4565/5330; batch 29/145; Slice A/B tables empty. loopback /admin/login 200.

**STOP — Slice C verified. NEXT (owner/ChatGPT): merge decision for Slice C branch aaa21a6 (code-only presentation, NO migration; if merged, deploy = ff live tree + apachectl graceful, NO new migration needed). SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification on next organic product change.**

---

# SCA — SHOPIFY PHASE 2 SLICE C IMPLEMENTED (branch 992e048); read-only visibility; static PASS; DB tests NOT run; AWAITING review. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** Slice C (staff visibility of linked Shopify product) on feat/sca-shopify-phase2-visibility off deployed 91b88f1. Evidence: `docs/SCA-SHOPIFY-PHASE2-SLICE-C-IMPLEMENTATION.md`. Worktree-only; prod/main 91b88f1 untouched. No migration/deploy/live-Shopify/ownership/Option-C.
- **SHA 91b88f1→`992e048b1a6991aca3f7fae1f760a4dfb72fd309`** (pushed origin). 4 files (+78/-5): controller 2 READ methods, 2 views, 1 test. NO migration/route/ACL/service change.
- Detail "Shopify link" panel: live product name+vendor, variant, SKU (live→snapshot fallback), Shopify ref (product/variant ids), pairs-linked count; LEFT JOIN live catalog → archived/draft="Inactive in catalog", deleted="Unavailable in catalog" (from snapshot), link PRESERVED (never auto-unlink).
- Registry index cards: "Shopify ✓" / "Shopify (inactive)" / "No Shopify link" — ONE bounded query over current page's ≤20 ids (no N+1).
- Read-only; link/relink/unlink still gated by sca.eyewear.shopify.link (viewer sees info, not controls). Provenance untouched.
- Tests ShopifyLinkVisibilityTest WRITTEN, NOT run (SCA_TEST_DB guard; need sep disposable-DB auth): linked display, pair count, archived→inactive+preserved, deleted→unavailable, unlinked, index indicators, viewer-vs-linker controls. php -l clean; Blade balanced.

**STOP — Slice C for review. NEXT (sep auth): run ShopifyLinkVisibilityTest on a unique disposable DB at 992e048; then merge decision (code-only, NO migration). SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification on next organic product change.**

---

# SCA — SHOPIFY LINK PERMISSION ROLE ASSESSMENT (read-only): only 1 role (Administrator, all) → already holds sca.eyewear.shopify.link; NO grant needed. Awaiting approval. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** READ-ONLY staff role/permission review at prod 91b88f1. Evidence: `docs/SCA-SHOPIFY-LINK-PERMISSION-ROLE-ASSESSMENT.md`. No role/user/permission/code/config change.
- Only ONE role in prod: **Administrator (id1, permission_type=all, 1 user)**. No separate intake/authenticator role.
- sca.eyewear.create → held by Administrator (via all). sca.eyewear.shopify.link REGISTERED (leaf; route admin.sca.shopify.catalog-search). "Ungranted by default" applies only to CUSTOM roles — the all-role ALREADY effectively holds it, so the feature is usable now; no grant action required.
- RECOMMENDATION: no grant needed (Administrator already has it). A dedicated least-privilege custom role (sca.eyewear+view+create+shopify.link[+catalog], EXCLUDING certify/QR/ownership/status/authenticate) is only worth creating if/when non-admin intake staff are added — separate approval-gated role change.
- SCOPE CONFIRMED: sca.eyewear.shopify.link is a distinct leaf; grants NO ownership(.ownership.correct/.claim)/certification(.certify/.certificate)/QR(.qr.reissue)/authenticate/status — each a separate key.

**STOP — read-only; awaiting owner approval before any grant or role creation. SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification on next organic product change.**

---

# SCA — SHOPIFY PHASE 2 SLICE A+B DEPLOYED to prod (91b88f1); healthy; prod data UNCHANGED. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** Authorized controlled release of 91b88f1 DONE + verified. Evidence: `docs/SCA-SHOPIFY-PHASE2-DEPLOY-RESULT.md`.
- Prod code `905ea7d`→`91b88f1` (live tree ff-only + `apachectl graceful`; NO Docker recreate). 3 ADDITIVE migrations applied to prod sca_krayin via SEPARATE target-code mount (migrate:status gate = exactly 3 pending) → batch 28→**29** (142→145 rows). Fresh pre-deploy backup 20261028T171117Z verified (sha256 MATCH + decrypts).
- Verified: 3 new tables exist + 2 append-only triggers; item-detail show() canary reads new tables OK (migrate-before-code satisfied); routes catalog-search/link/relink/unlink registered w/ ScaAuthenticate+ScaAuthorize:sca.eyewear.shopify.link; unauth POST link=419; loopback /admin/login 200; edge 403 (owner allowlist, expected).
- **PROD DATA UNCHANGED:** items3/state3/auth4/cert4/qr3/own5/grant1; catalog 4565/5330; 3 new tables EMPTY (live-but-dormant). No eyewear/ownership created; feature NOT exercised with live data.
- ⚠️ OPERATOR ACTION: ACL `sca.eyewear.shopify.link` is ungranted by default — grant to intended staff role before use.
- ROLLBACK (if needed): live tree→905ea7d + graceful (code-only; no DB rollback — additive tables ignored by old code; optional migrate:rollback --step=1 w/ separate approval).

**STOP — Phase 2 deployed + healthy. SEPARATE OPEN: first genuine products/* webhook receipt verification on next organic Shopify product change (unchanged by this release).**

---

# SCA — SHOPIFY PHASE 2 DEPLOY READINESS: READY FOR RELEASE APPROVAL (read-only; nothing deployed). Prod 905ea7d; target origin/main 91b88f1. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** READ-ONLY production deploy-readiness assessment of 91b88f1 over prod 905ea7d. Evidence: `docs/SCA-SHOPIFY-PHASE2-DEPLOY-READINESS.md`. VERDICT **READY FOR RELEASE APPROVAL — no NO-GO blockers**. Nothing deployed/migrated/checked-out/restarted.
- State verified: origin/main 91b88f1; prod+live tree 905ea7d (clean). kr-app bind-mounts /opt/sca-platform/app RW; opcache validate_timestamps=On (~2s) → release = tree swap + `apachectl graceful` (zero-downtime, NO Docker recreate; zero dep changes).
- 3 ADDITIVE migrations (000001 link FK→items; 000002 audit+triggers no FK; 000003 idempotency FK→items) → batch 29; no inter-dependency; referenced tables exist in prod; names absent from the 142-row/batch-28 history (appends cleanly, no repair).
- ⚠️ **MANDATORY migrate-BEFORE-code:** EyewearItemController::show() (item detail) reads sca_eyewear_item_shopify_variant + _link_audit on EVERY load → activating code first = 500s. Recommended zero-downtime: migrate from a SEPARATE 91b88f1 mount (prod app/.env) while old app runs, THEN swap live tree + graceful. Fallback: artisan down→swap→migrate→graceful→up.
- Backup current+usable: daily cron; latest 20261028T021702Z (~4.6GB today), gpg+sha256 (bare-hash sidecar, integrity MATCH), key secrets/backup.key present; restore tooling + prior restore-proof PASS. ROLLBACK = code-only (live tree→905ea7d + graceful); NO DB rollback needed (additive tables ignored by old code); optional migrate:rollback --step=1. Residual (non-blocker): off-host backup + key escrow still outstanding.
- Health now: kr-app loopback /admin/login 200.

**STOP — read-only; READY FOR RELEASE APPROVAL. NEXT (SEPARATE deploy auth): execute migrate-before-code deploy of 91b88f1 + 3 migrations per readiness doc §4/§7, with pre-deploy backup + post-deploy smoke tests §8. SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification.**

---

# SCA — SHOPIFY PHASE 2 SLICE A+B MERGED to origin/main (91b88f1); CODE-ONLY, NOT deployed; prod untouched. (Phase-1 webhook verification still OPEN; deploy = separate auth.)

**STATUS (2026-10-28):** Authorized CODE-ONLY merge of feat/sca-shopify-phase2-linking (a477dc4) into main. Evidence: `docs/SCA-SHOPIFY-PHASE2-SLICE-AB-MERGE.md`. No deploy/migration/restart/infra/Shopify/Option-C/DB change.
- **origin/main `905ea7d`→`91b88f1a7754e8589893fccfcd393cc4e0cfde74`** (--no-ff merge commit; parents 905ea7d + a477dc4; non-force FF push accepted). Merge tree byte-identical to candidate; no conflicts; 20 files ALL within Sca packages + Sca tests; exactly 3 ADDITIVE migrations (000001/000002/000003, all new, additive only). Regression evidence (37/37) is for the exact merged commit a477dc4.
- Merge done in an ISOLATED temp worktree (branch merge-tmp at 905ea7d), NOT the live checkout → live bind-mount /opt/sca-platform/app UNCHANGED (still 905ea7d; shopifyLinkPanel absent). Prod sca_krayin UNCHANGED (3 new tables absent; no migration run). Temp worktree+branch removed.
- ⚠️ LIVE local main intentionally left at 905ea7d (origin/main ahead in history only) — merged, NOT deployed.

**STOP — merge complete. NEXT (SEPARATE auth required): deploy 91b88f1 — fast-forward the live tree + `migrate --force` the 3 additive migrations (MUST apply together: new code reads link/audit tables on item-detail) + graceful reload (no Docker recreate). SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification on next organic product change.**

---

# SCA — SHOPIFY PHASE 2 SLICE B FINAL REGRESSION PASS (37/37, disposable DB; corrected a477dc4); prod unchanged; AWAITING review→merge. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** Authorized ONE isolated DB-test session for corrected Slice B (a477dc4). Evidence: `docs/SCA-SHOPIFY-PHASE2-SLICE-B-FINAL-REGRESSION-RESULT.md`. Disposable DB `sca_p2bf_test_c4d7872d1e07` only; dropped+verified (0 residual); prod sca_krayin UNCHANGED; 3 link/audit/idempotency tables NOT in prod. No prod-migrate/merge/deploy/Shopify/live-webhook/Option-C/full-regression.
- Isolation verified (getenv==getDatabaseName==live SELECT DATABASE()==disposable, ≠sca_krayin). Migrated 000001/000002/000003 incl fingerprint column.
- **EyewearShopifyIntakeTest 12 + ShopifyProductLinkTest 12 + ShopifyProductLinkRouteTest 13 = 37 tests / 131 assertions / 0 fail/err/warn/skip** (phpunit 11.5.50).
- BOTH corrections CONFIRMED: [6] archived/draft parent NOT newly link/relinkable w/ active variant (svc rejects link+relink, intake rollback, HTTP no item, selector not linkable); [7] existing link PRESERVED after product archived (no auto-unlink); [8] identical retry → same item, no dup; [9] reused key w/ changed attrs OR link selection → explicit conflict (idempotency_key_reused_with_different_details), no data change; [10] permissions/rollback/audit-immutability/provenance-isolation still pass.
- prod fingerprint baseline: items3/state3/own5/cert4/qr3/grant1, catalog 4565/5330, batch 28 (142 rows); 3 tables absent in prod. App loopback /admin/login 200. Cleanup: DB dropped, grant revoked (0 residual), test worktree removed; live main 905ea7d clean.

**STOP — corrected Slice B verified green. NEXT (owner/ChatGPT): review → merge decision for a477dc4 (code-only + 3 additive migrations 000001/000002/000003; deploy would need a separate authorization). SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification on next organic product change.**

---

# SCA — SHOPIFY PHASE 2 SLICE B CORRECTIONS COMMITTED (branch a477dc4); static PASS; DB tests NOT run; AWAITING review + authorized DB re-test. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** Authorized narrow correction of the two Slice B DB-test findings on feat/sca-shopify-phase2-linking. Evidence: `docs/SCA-SHOPIFY-PHASE2-SLICE-B-CORRECTIONS.md`. Worktree-only; live main 905ea7d untouched. No prod migrate/merge/deploy/live-Shopify/Option-C.
- **SHA 2343e04→`a477dc4f7dbd2c07b95368c6534a35eb315e2b90`** (pushed origin). 9 files (6 src, 3 tests).
- **DEFECT-1 FIX:** ShopifyProductLinkService::variantEligibility now requires parent ShopifyProduct active (status=active) AND variant active — gates link() AND relink(). ProductLinkController::search linkable = product active && variant active (+exposes product_status). Eligibility checked ONLY on new link/relink → EXISTING links preserved if product later archived (NO auto-unlink).
- **IDEMPOTENCY FIX:** sca_eyewear_intake_idempotency +`fingerprint` char(64) (migration extended in place, not in prod). EyewearShopifyIntakeService computes canonical sha256(item attrs + link selection, key-sorted); reused key → identical fingerprint=`exists` (returns existing item), different=`conflict` (reason idempotency_key_reused_with_different_details, creates/modifies NOTHING); applied on fast-path + 1062 race; null legacy fingerprint treated as match. store() surfaces conflict as form error (no item).
- Tests UPDATED (fixtures create active product) + ADDED (archived-product rejected link+relink, link preserved after archive, identical-retry idempotent, key-reuse-different-details conflict svc+HTTP, attr-only divergence conflict, selector marks archived not linkable). php -l 9/9 clean. **DB tests NOT run (need sep disposable-DB auth).**

**STOP — corrections for review. NEXT (sep auth): re-run EyewearShopifyIntakeTest + ShopifyProductLinkRouteTest + ShopifyProductLinkTest on a UNIQUE disposable DB at a477dc4 (prod untouched); then merge decision. SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification on next organic product change.**

---

# SCA — SHOPIFY PHASE 2 SLICE B DB TEST PASS (28/28, disposable DB); prod unchanged; 1 finding for review; AWAITING review. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** Authorized ONE isolated DB-test session for Slice B (2343e04). Evidence: `docs/SCA-SHOPIFY-PHASE2-SLICE-B-DB-TEST-RESULT.md`. Disposable DB `sca_p2b_test_7860c4e3e7b0` only; dropped+verified (0 residual grant); prod sca_krayin UNCHANGED; link/audit/idempotency tables NOT in prod. No prod-migrate/merge/deploy/Shopify/live-webhook/Option-C/full-regression.
- Isolation verified (getenv==getDatabaseName==live SELECT DATABASE()==SCA_TEST_DB==disposable, ≠sca_krayin). Migrated incl 000001/000002/000003.
- **EyewearShopifyIntakeTest 8 + ShopifyProductLinkRouteTest 10 + ShopifyProductLinkTest 10 = 28 tests / 96 assertions / 0 fail/err/warn/skip** (phpunit 11.5.50). Covers permissions (route + server-side create-with-link 403), selector+pagination+filter, prefill override persistence, one-txn create+link, rollback-on-rejected-link (no orphan), duplicate-submit=1 item, link/relink/unlink, append-only audit immutability (UPDATE+DELETE rejected), no-provenance, Slice A compatibility.
- **FINDING (DEFECT-1, for review, NOT repaired):** archived PRODUCT + active VARIANT → link SUCCEEDS; variantEligibility gates on VARIANT status only, ignores product status (selector shows product_status but doesn't gate on it). Not a safety/provenance issue. Options: enforce product status OR document variant-only gating.
- **NOTE (working-as-designed):** idempotency key reused with DIFFERENT details → returns prior item (outcome 'exists'), new payload silently ignored; 1 item, no corruption. Key is machine-minted per render → cross-submission reuse not a real path. NOT a defect.
- prod fingerprint baseline: items3/state3/own5/cert4/qr3/grant1, catalog 4565/5330, batch 28 (142 rows); 3 Slice A/B tables absent in prod. App: loopback /admin/login 200; edge 403 (owner-IP allowlist, expected). Cleanup: DB dropped, grant revoked (0 residual), DB-test worktree removed; live main 905ea7d clean.

**STOP — Slice B verified. NEXT (owner/ChatGPT): decide on DEFECT-1 (product-status gating), then review→merge decision for 2343e04. SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification on next organic product change.**

---

# SCA — SHOPIFY PHASE 2 SLICE B IMPLEMENTED (branch 2343e04); static PASS; DB tests NOT run; AWAITING review. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** Slice B (staff linking UI + backend) on feat/sca-shopify-phase2-linking. Evidence: `docs/SCA-SHOPIFY-PHASE2-SLICE-B-IMPLEMENTATION.md`. Worktree-only; live main 905ea7d untouched. No prod migrate/merge/deploy/Shopify/Option-C.
- **SHA 5c1aa23→`2343e044b5d801985b381ef022311dc1a2b45dcd`** (pushed origin). 17 files (7 mod, 10 new).
- EyewearShopifyIntakeService::createLinked = canonical ItemService::create + ShopifyProductLinkService::link in ONE DB::transaction; rejected link throws LinkRejectedException → whole intake rolls back (no orphan). Durable idempotency sca_eyewear_intake_idempotency (UNIQUE key; fast-path prior; 1062 race→re-resolve) → exactly one item/submission.
- Append-only sca_eyewear_shopify_link_audit (BEFORE UPDATE/DELETE SIGNAL 45000); ShopifyProductLinkService appends audit on link/relink/unlink in-txn. Two ADDITIVE migrations (000002/000003); existing tables unchanged.
- ProductLinkController: paginated catalog-search (title/vendor/variant/SKU/status) + link/relink/unlink, ALL under sca.can:sca.eyewear.shopify.link + CSRF + throttle. ACL route repointed→admin.sca.shopify.catalog-search. store() re-checks link ACL server-side (create-only staff → real 403, no item). UI: create-form selector+prefill(overridable)+hidden idem key; item-detail "Shopify link" tab.
- Static: php -l 14/14 clean; Blade balanced. DB-changing tests EyewearShopifyIntakeTest + ShopifyProductLinkRouteTest WRITTEN, NOT run (SCA_TEST_DB guard). No app boot/DB connection; no dev-vendor build in worktree.

**STOP — Slice B for review. NEXT (sep auth): run the two feature tests on a UNIQUE disposable DB (isolation-verified; prod sca_krayin untouched) + any Slice C surfacing. SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification on next organic product change.**

---

# SCA — SHOPIFY PHASE 2 SLICE A DB TEST PASS (10/10, disposable DB); prod unchanged; AWAITING review. (Phase-1 webhook verification still OPEN.)

**STATUS (2026-10-28):** Authorized ONE isolated DB-test session for Slice A (5c1aa23). Evidence: `docs/SCA-SHOPIFY-PHASE2-SLICE-A-DB-TEST-RESULT.md`. Disposable DB only; dropped+verified; prod sca_krayin UNCHANGED; link table NOT in prod. No prod-migrate/merge/deploy/Shopify/live-webhook/Option-C/full-regression.
- Worktree at 5c1aa23 (live main 905ea7d untouched); dev vendor built in worktree. Unique DB `sca_p2link_test_a2996cc08156` (existence-checked); isolation verified (getenv==getDatabaseName==live SELECT DATABASE()==disposable, ≠sca_krayin); migrated incl 2026_10_28_000001 link table.
- **ShopifyProductLinkTest: OK 10 tests / 29 assertions / 0 fail/skip/warn** (phpunit 11.5.50): 1:N linking, one-item-no-silent-relink (already_linked_to_other_variant), idempotent, explicit relink, wrong-shop/archived/unknown rejected, non-interference (link+unlink touch 0 ownership/cert/qr/grant/subs + item not deleted), permission defined.
- [10] route-level auth + relink audit history = Slice B. [11] DB dropped + grant revoked (0 residual) + worktree removed. [12] prod diff empty (3/3/5/4/3/1, cat 4565/5330, batch 28); link table absent in prod; admin 200.

**STOP — Slice A verified. NEXT (sep auth): Slice B (staff UI selector + prefill + create-with-link one-txn + per-submit idempotency token + wire link/unlink routes + sca.can enforcement + repoint ACL route + relink audit); Slice C surfacing. SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification on next organic product change.**

---

# (PRIOR) SCA — SHOPIFY PHASE 2 SLICE A IMPLEMENTED (branch 5c1aa23); non-destructive PASS; DB tests NOT run

**STATUS (2026-10-28):** Slice A (link layer, no UI) on feat/sca-shopify-phase2-linking off 905ea7d. Evidence: `docs/SCA-SHOPIFY-PHASE2-SLICE-A-IMPLEMENTATION.md`. Worktree (live main 905ea7d untouched). No prod migration/deploy/live-Shopify/UI/Option-C.
- **SHA 905ea7d→`5c1aa23e45f78f33a5cd8c590b907dd049595417`** (pushed origin). 5 files.
- NEW migration sca_eyewear_item_shopify_variant (UNIQUE eyewear_item_id = 1 variant/item; NON-unique (shop,variant) index = N items/variant; FK item→sca_eyewear_items cascade; NO FK to catalog). Model EyewearItemShopifyVariant. ShopifyProductLinkService (sole writer: link/unlink/explicit relink; validates item exists + expected shop + ACTIVE variant belongs to product+shop; idempotent same-variant='exists', other-variant=rejected; writes ONLY join table, never creates item/touches provenance). ACL sca.eyewear.shopify.link (placeholder route until Slice B). Test ShopifyProductLinkTest (disposable DB, SCA_TEST_DB guard, NOT run).
- Non-destructive: php -l 5/5 clean; id/shop logic smoke OK. DB tests written NOT run (sep auth + unique disposable DB).
- Idempotency strategy for Slice-B intake double-submit documented (per-submit token + item-create+link in one txn; UNIQUE eyewear_item_id hard guard).
- Catalog sync + order processing UNCHANGED.

**STOP — Slice A for review. NEXT (sep auth): run DB tests on unique disposable DB; then Slice B (UI selector+prefill+create-with-link, wire link/unlink routes, repoint ACL route); Slice C surfacing. SEPARATE OPEN: Phase-1 first genuine products/* webhook receipt verification on next organic product change.**

---

# (PRIOR) SCA — SHOPIFY PHASE 2 (product→physical-eyewear LINKING) AUDIT+PLAN (READ-ONLY)

**STATUS (2026-10-28):** READ-ONLY Phase 2 audit + plan. Evidence: `docs/SCA-SHOPIFY-PHASE2-LINKING-PLAN.md`. No code/DB/deploy/Shopify/activation.
- **AUDIT:** intake = `ItemService::create` (canonical) via `EyewearItemController` (ACL sca.eyewear.create; StoreEyewearItemRequest: brand+model_name req, frame_serial, intake_type sce_presale|external_intake, year, country, materials, original_specs) + InventoryImportController (bulk). Auth→Cert→QR→Ownership chain services present (unchanged by P2). NO existing eyewear↔variant link (clean slate).
- **DESIGN:** NEW additive table `sca_eyewear_item_shopify_variant` (eyewear_item_id UNIQUE → ≤1 variant/item; index shop+variant NOT unique → N items/variant = multiple pairs per variant §3). NEW sole-writer `ShopifyProductLinkService` (link/unlink/relink, validates item + active variant, UNIQUE guard, txn; never creates item or touches auth/cert/QR/ownership). New ACL sca.eyewear.shopify.link.
- **WORKFLOW:** optional "Link to Shopify product" on create form → search active sca_shopify_products/variants → prefill brand←vendor, model_name←title(+options), sku←variant.sku (staff-editable; year/country/materials/serial staff-entered; no images in P1) → submit = ItemService::create + link in ONE txn; double-submit idempotency token; link/unlink from item detail too.
- **INVARIANT PRESERVED:** catalog sync/webhook/import NEVER create item/link (only staff intake does); linking never auto-authenticates/passports/owns. History additive/untouched.
- **TESTS+ROADMAP:** Slice A (migration+service+ACL+DB tests), B (UI selector+prefill+create-with-link), C (surface ref + ops linked-count); future image/metafield sync + advisory stock reconcile. Catalog-only invariant test (webhook/import → 0 items/0 links).

**STOP — Phase 2 plan for review; implement only on approval (Slice A first). SEPARATE OPEN TASK: re-verify first genuine products/* webhook receipt (processed + catalog change + provenance unchanged) on next organic product change — see activation-verification doc. Reconcile stays disabled.**

---

# (PRIOR) SCA — SHOPIFY INVENTORY SYNC ACTIVATION VERIFIED (v6 live); PRODUCT WEBHOOK DELIVERY PENDING (no genuine products/* receipt yet)
(Still OPEN + separate: confirm first genuine products/* receipt on the next organic store product change; do NOT trigger artificially.)

**STATUS (2026-10-28):** READ-ONLY activation verification after owner released sca-eyewear-registry-6. Evidence: `docs/SCA-SHOPIFY-INVENTORY-SYNC-ACTIVATION-VERIFICATION.md`. No product create/modify, no re-import, no deploy/migration, no Shopify config change, no passport.
- **[1] SHA 905ea7d, admin 200, kr-app up. [2] scope read_orders,read_products. [4] live getShop/listProducts(5+next)/getOrder(refunded) all OK (read_products+read_orders work).**
- **[3] 6 subs:** owner Dashboard confirms v6 active (scopes both, 6 managed subs, api 2026-07, callback preserved). Server-side webhooks.json=0 EXPECTED for managed/config-based subs (not enumerable server-side) — definitive server proof = first genuine products/* receipt.
- **[5][6] ⚠️ WEBHOOK DELIVERY PENDING:** 0 receipts with topic products/* (synthetic sca-selftest cleaned, not counted). No real product create/update/delete since release (not triggered per instruction). Order webhooks DO deliver (latest orders/paid 2026-10-27 20:38, 109 total) → pipeline/edge/HMAC healthy; receiver already PROVEN (gov 8faa1fa). END-TO-END PRODUCT SYNC NOT CLAIMED PASSED.
- **[7] catalog 4565/5330 + provenance 3/3/5/4/3/1 consistent. [8] reconciliation DISABLED (no cron/schedule:run/Console-Kernel entry).**

**STOP — activation in place; SCA side healthy+proven. RE-VERIFY when a product is next created/updated/deleted in the store during normal business: expect a sca_shopify_webhook_receipts row topic products/* processing_outcome=processed + catalog change + no duplicates + provenance unchanged. Do NOT trigger a product change artificially. Reconcile stays disabled.**

---

# (PRIOR) SCA — SHOPIFY CLI AUTH RECOVERY: interactive `shopify auth login` must be owner-run; toml backed up; config pull PENDING
(Note: owner has since completed auth + released v6; the CLI-auth-recovery task is resolved.)

**STATUS (2026-10-27):** Prepared auth recovery; interactive login cannot run headless. Evidence: `docs/SCA-SHOPIFY-CLI-AUTH-RECOVERY.md`. No deploy, no product-webhook add, no new app, no scope change, no credential exposed, no SCA prod change.
- **[1][5] DONE:** project /opt/sca-gov/shopify-app; backed up `shopify.app.toml.bak.20261027T190333Z`.
- **[2][3] Auth = `shopify auth login` (CLI 4.8.5), INTERACTIVE-ONLY** — CLI refuses non-interactive ("run in an interactive environment"); also uses localhost loopback callback → must run where owner's browser reaches the CLI. Cannot do from this automated/headless session; did NOT bypass. Owner runs it: Option A (own workstation, clone gov shopify-app/) or Option B (interactive SSH with `ssh -L 3456:localhost:3456` tunnel for the callback). Then `shopify app config link --client-id <SCA Eyewear Registry client_id>` (verify name) → `shopify app config pull`.
- **[4][6][7][8] PENDING auth:** after pull, confirm toml retains scopes=read_orders,read_products (⚠️ committed toml STALE=read_orders only; pull must restore read_products, else STOP), 3 order/refund webhooks, api 2026-07, OAuth callback. Expected diff = committed(read_orders)→pulled(+read_products). Then `git -C /opt/sca-gov diff shopify-app/` + commit refreshed toml.
- client_id to link = the one in committed toml / app/.env SHOPIFY_CLIENT_ID (verified match).

**STOP — owner completes interactive `shopify auth login` + config link/pull + confirms baseline; report diff. NOT YET: add product webhooks or `shopify app deploy`.**

---

# (PRIOR) SCA — SHOPIFY PRODUCT WEBHOOK RELEASE BLOCKED: no Partner auth on host + committed toml STALE

**STATUS (2026-10-27):** App identity verified; release NOT performed. Evidence: `docs/SCA-SHOPIFY-PRODUCT-WEBHOOK-RELEASE-BLOCKED.md`. No app version released, no new app, no other app's creds, no SCA code/schema/service/inventory/product change.
- **Found:** shopify CLI 4.8.5 present; app-config project at `/opt/sca-gov/shopify-app/shopify.app.toml` (tracked in gov); name "SCA Eyewear Registry", client_id MATCHES app/.env SHOPIFY_CLIENT_ID (same app, verified; no new app).
- **⛔ BLOCKER A:** no ~/.config/shopify / no Partner session → `shopify app deploy` can't run non-interactively → STOP+instruct (per final clause).
- **⛔ BLOCKER B:** committed toml is STALE — `[access_scopes] scopes="read_orders"` (NO read_products) + only the 3 order/refund webhooks. Live install granted read_orders,read_products (owner's earlier Dashboard fix). **Deploying this toml as-is would DOWNGRADE scopes and strip read_products** → must reconcile first. (Webhooks part is fine: 3 present, endpoint + api 2026-07 + redirect correct.)
- **OWNER STEPS (authenticated workstation):** `shopify login` (correct Partner org) → `shopify app config link` (SCA Eyewear Registry, verify client_id) → **`shopify app config pull`** (reconcile stale scopes — MUST then show scopes=read_orders,read_products + 3 webhooks; if not, read_products missing from released config → STOP) → append product `[[webhooks.subscriptions]]` block (products/create|update|delete, same uri) → `shopify app deploy` (diff MUST show +3 product topics ONLY, scopes keep read_products, nothing removed) → release (sca-eyewear-registry-6). Did NOT edit the gov toml (editing could mislead a deploy; authoritative config via config pull).
- SCA side healthy/unchanged (admin 200, scope read_orders,read_products, catalog 4565/5330, prov 3/3/5/4/3/1); receiver proven.

**STOP — owner must authenticate + reconcile (config pull) + add product webhooks + deploy/release. After release: confirm 6 subs in active version + a delivered products/* receipt (processed) + provenance unchanged. Reconcile UNscheduled.**

---

# (PRIOR) SCA — SHOPIFY PRODUCT WEBHOOK CONFIG PROPOSAL ready (shopify.app.toml)

**STATUS (2026-10-27):** Config proposal prepared (NOT released). Evidence: `docs/SCA-SHOPIFY-PRODUCT-WEBHOOK-CONFIG-PROPOSAL.md`. No app version deployed/released, no new app, no SCA server/inventory change.
- **[4] Reuse existing app** (active version sca-eyewear-registry-5): adding subs = edit same app config + new version (auto sca-eyewear-registry-6), NOT a new app. Reuse the linked shopify.app.toml project (or Dev Dashboard).
- **[5] Change = append ONE `[[webhooks.subscriptions]]` block:** topics=["products/create","products/update","products/delete"], uri=https://verify.secondchanceauthenticators.com/sca/shopify/webhook. Keep existing orders/paid|cancelled+refunds/create block(s). `[webhooks] api_version="2026-07"` unchanged; `[access_scopes] scopes="read_orders,read_products"` unchanged; `[auth] redirect_urls=[.../sca/shopify/oauth/callback]` unchanged.
- **Deploy (owner):** `shopify app config link` (existing app) → edit toml → `shopify app deploy` (review diff: +3 product topics ONLY, scopes/api/redirect unchanged) → release. Dev Dashboard alt = add 3 subs to same endpoint, keep order subs, release.
- **[1][2][3] preserved:** 3 order/refund subs, scopes, api 2026-07, oauth callback, endpoint. [6] no new app. [7] not released. [8] no SCA change (catalog 4565/5330).
- SCA receiver already proven (bad-sig 401 / valid 200 processed+upsert / replay idempotent) → deliveries will work once released.

**STOP — owner reviews diff + releases the new app version (6 managed subs). After release: confirm a delivered products/* receipt (processed) + catalog update + provenance unchanged. Reconcile UNscheduled.**

---

# (PRIOR) SCA — SHOPIFY PRODUCT WEBHOOKS: SCA receiver PROVEN; registration is owner app-version action

**STATUS (2026-10-27):** Receiver validated; subscription registration owner-gated. Evidence: `docs/SCA-SHOPIFY-PRODUCT-WEBHOOK-ACTIVATION.md`. No real Shopify product change, passport/ownership/auth, reconcile schedule, code deploy/migration.
- **[1] confirmed:** SHA 905ea7d; scope read_orders,read_products.
- **[2] KEY FINDING:** Admin API `webhooks.json` = 0 → existing orders/refunds subs are APP-CONFIG (managed), NOT API-registered (config-based subs don't appear in webhooks.json). So product subs must be added in the APP VERSION config too.
- **[3][6] OWNER ACTION (cannot do server-side):** add products/create|update|delete to the app version (shopify.app.toml `[[webhooks.subscriptions]]` topics + uri=https://verify.secondchanceauthenticators.com/sca/shopify/webhook, api 2026-07; OR Dev Dashboard) KEEPING orders/paid|cancelled+refunds/create → `shopify app deploy`/release → verify 6 topics in active version (won't show in webhooks.json). SCA client is read-only by design + no-deploy → can't register from server. STOP before release.
- **[4][5] preserved:** 3 order/refund subs, endpoint, api 2026-07, HMAC (client secret).
- **[7][8] SCA RECEIVER PROVEN (local synthetic signed test, secret not printed, synthetic ids cleaned):** bad-sig→401; valid products/update→200 receipt processed + catalog upsert; replay→200 1 receipt (idempotent). Signature+receipt+idempotency+catalog processing PASS.
- **[9] counts restored** (products 4565 / variants 5330 / receipts 108) + provenance UNCHANGED (3/3/5/4/3/1); app 200.

**STOP — owner adds the 3 product subscriptions to the Shopify app version + releases (instructions in gov doc). After release: confirm a delivered products/* receipt (processed) + catalog update + provenance unchanged. Reconcile stays unscheduled.**

---

# (PRIOR) SCA — INITIAL SHOPIFY CATALOG IMPORT DONE: 4565 products / 5330 variants; prod provenance UNCHANGED

**STATUS (2026-10-27):** Authorized ONE import executed + verified. Evidence: `docs/SCA-SHOPIFY-CATALOG-IMPORT-RESULT.md`. No webhook register / reconcile schedule / code / migration / Shopify modification / Option C.
- **Preflight:** SHA 905ea7d; scope read_orders,read_products; catalog empty 0/0; baseline prov items3/state3/own5/cert4/qr3/grant1/batch28; backup OK; app 200.
- **[4][5] `sca:shopify:import-catalog` (once, exit 0):** products 4565 / created 4565 / updated 0 / unchanged 0 / stale 0 / rejected 0 / pages 46.
- **[6] No duplicates:** sca_shopify_products 4565 rows = 4565 distinct pid; sca_shopify_variants 5330 rows = 5330 distinct vid; dup 0/0. Status (mirrors Shopify): active1697/archived2788/draft80. 173 variants qty>1 = 1 catalog row each (NOT physical items).
- **[7] PROVENANCE UNCHANGED (diff empty):** items3/state3/own5/cert4/qr3/grant1/batch28 == baseline. NO eyewear/cert/ownership/QR/claim-link created. Catalog-only invariant held in prod.
- **[8] Health:** admin/login 200; getShop OK; getOrder(8019293831455) OK (read_orders intact).

**STOP — catalog import complete + verified for independent review. REMAINING owner-gated: register products/create|update|delete webhooks (incremental sync; edge routes POST /sca/shopify/webhook, HMAC=client_secret); reconcile-catalog stays UNscheduled.**

---

# (PRIOR) SCA — SHOPIFY PRODUCT ACCESS VERIFIED (read_products LIVE); connection activated

**STATUS (2026-10-27):** READ-ONLY post-OAuth verification PASS. Evidence: `docs/SCA-SHOPIFY-OAUTH-PRODUCT-ACCESS-VERIFICATION.md`. No import/webhook/product-change/migration; no token/credential/PII revealed.
- **[1] Credential:** sca_shopify_credentials scope=`read_orders,read_products`, has_token=1, updated_at 2026-10-27 18:22:03 (re-consent stored both-scope token). Owner's Dev Dashboard scope declare+release worked.
- **[2][3][4] Products:** ShopifyClient::isConfigured=yes; listProducts(null,5) → first_page_count=5, pagination_next=yes, NO auth error; getShop OK (domain match, plan professional); sample product id 9789314269471 variants=1.
- **[5] Orders still work:** getOrder(8019293831455) OK (financial_status=refunded, 1 line item) — read_orders intact, no PII printed.
- **[6] Catalog tables still EMPTY (0/0)** — nothing imported; live-but-dormant.
- **Connection-level activation VERIFIED.** Remaining owner-gated (NOT done): register products/create|update|delete webhooks → run `sca:shopify:import-catalog` (idempotent) → verify catalog rows + provenance unchanged; reconcile-catalog stays unscheduled.

**STOP — product access live & verified. Next activation steps (each separate auth): [A] register products/* webhooks (edge already routes POST /sca/shopify/webhook; verify HMAC=client_secret); [B] run initial catalog import.**

---

# (PRIOR) SCA — SHOPIFY OAUTH "INSUFFICIENT SCOPE" DIAGNOSED (READ-ONLY): app-config missing read_products

**STATUS (2026-10-27):** READ-ONLY diagnosis of the callback "insufficient scope". Evidence: `docs/SCA-SHOPIFY-OAUTH-INSUFFICIENT-SCOPE-DIAGNOSIS.md`. No app-scope/config/deploy/OAuth/uninstall/prod change; no secrets printed; order integration preserved.
- **ROOT CAUSE:** token exchange SUCCEEDED but Shopify's returned token `scope` omitted read_products → `grantedScopesSatisfyRequired` false → OAuthController callback step 5 `fail(403,'insufficient scope')` BEFORE `tokens->put()` (token NOT stored). SCA side is CORRECT (config scopes=read_orders,read_products; authorizeUrl requests both).
- **[4] CREDENTIAL INTACT:** sca_shopify_credentials scope=read_orders, has_token=1 (len 256), updated_at 2026-10-05 UNCHANGED → failed callback did NOT overwrite/damage; orders unaffected.
- **[2][5] WHY:** modern Shopify apps use CONFIG-BASED (managed) scopes — granted scopes come from the app's declared Access scopes (shopify.app.toml/Dev Dashboard), authorize `scope` param ignored/capped. read_products almost certainly NOT declared+released in the app config → not granted. (read_products is not protected data, so not an approval restriction.)
- **[6] FIX (owner, no SCA change):** (1) add read_products to the Shopify app's Access scopes (keep read_orders); (2) DEPLOY/RELEASE the app config version; (3) re-run connect from allowlisted IP 103.200.35.3 → store admin approves (now shows read products) → callback stores both-scope token; (4) verify sca_shopify_credentials.scope includes read_products + read-only product probe. Do NOT uninstall/reinstall unless dashboard requires; do NOT weaken grantedScopesSatisfyRequired. SHOPIFY_SCOPES already correct.

**STOP — diagnosis delivered; owner updates the Shopify app config (declare+release read_products) then re-consents. No secrets exposed; order integration intact.**

---

# (PRIOR) SCA — ADMIN ACCESS RESTORED: owner IP 103.200.35.3/32 added to Caddy @staff allowlist

**STATUS (2026-10-27):** Authorized minimal change EXECUTED + verified. Evidence: `docs/SCA-ADMIN-403-ALLOWLIST-FIX-RESULT.md`. Allowlist NOT disabled; both existing staff IPs preserved; admin NOT public; no recreate/restart; smsrocket uninterrupted; no Shopify change.
- Added `103.200.35.3/32` (valid public IPv4) to `@staff remote_ip` (2→3 IPs, append-only). Backup `/opt/smsrocket-stack/Caddyfile.bak.20261027T172637Z`.
- Procedure: validate edited copy (`caddy validate`=Valid) → `cat new > Caddyfile` IN PLACE (inode 777641 preserved) → `docker exec sr-caddy caddy reload` (graceful, no recreate; StartedAt 2026-10-18 unchanged).
- Verified: admin API /config/ 200; running config contains 103.200.35.3/32 + both existing (3 staff IPs; the 4th IPv4 in JSON = admin 127.0.0.1); NO 0.0.0.0/0; smsrocket.io 302 healthy; verify passport /p 200; /admin/login from a NON-staff IP still 403 (allowlist intact). Rollback = cat backup > Caddyfile + caddy reload.
- **ZERO-DOWNTIME CADDY RELOAD CONFIRMED WORKING** (admin API localhost:2019; in-place cat> preserves inode → reload sees it). Supersedes the force-recreate gotcha (that only applies when an edit REPLACES the inode).

**NEXT (owner): from 103.200.35.3 open https://verify.secondchanceauthenticators.com/admin/sca/shopify/connect → merchant approves read_products → then verify sca_shopify_credentials.scope includes read_products + read-only product probe (NO import). Then (separate auth) register products/* webhooks; run import.** OAuth scope already live (read_orders,read_products); token still read_orders pending approval.

---

# (PRIOR) SCA — ADMIN 403 FIX PROPOSAL (READ-ONLY): add owner IP to Caddy @staff allowlist

**STATUS (2026-10-27):** Change proposal prepared, NOTHING applied. Evidence: `docs/SCA-ADMIN-403-ALLOWLIST-FIX-PROPOSAL.md`. No config change/recreate/restart/reload; allowlist NOT disabled; admin NOT opened to all.
- **[1] Owner IP:** NOT in edge logs (deny handler logs no harvestable IP) → owner must self-capture from their device/network (`curl -s https://api.ipify.org`), provide for approval. NOT guessed.
- **[2] Compare:** `@staff remote_ip` currently = the 2 authorized staff IPs (values redacted). On approval confirm owner IP is valid, not already listed, add as /32.
- **[3][4] Change:** append ONLY the owner IP to that one line: `@staff remote_ip <IP_A> <IP_B> <OWNER_IP>`; both existing preserved; allowlist stays default-deny.
- **[5] Reload WITHOUT recreate = YES:** admin API enabled (localhost:2019 /config/→200), `caddy reload` is graceful/atomic/zero-downtime, smsrocket NOT interrupted. CLAUDE.md force-recreate gotcha ONLY applies if the edit REPLACES the inode (sed -i/mv/editor) — Caddyfile is a file bind mount (inode 777641). AVOID by editing IN PLACE (`cat new > Caddyfile` or `cp`, preserves inode) then `docker exec sr-caddy caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile`.
- **[6] Validate first:** `caddy validate` works (current=Valid); validate the EDITED copy before writing live.
- **[7] Apply procedure + risk** in the doc (backup → awk-append → validate copy → `cat > ` in place → reload → verify). Risk: smsrocket none (graceful); validate gates syntax; inode foot-gun avoided by cat>; fallback force-recreate only if reload says "unchanged".

**STOP — await owner's verified public IP + approval. Then apply per [7] (or owner adds a stable office/VPN /32). After admin reachable: resume OAuth Step 1 approval (scope already read_orders,read_products; token still read_orders pending merchant approve).**

---

# (PRIOR) SCA — ADMIN /admin/login 403 DIAGNOSED (READ-ONLY): edge IP-allowlist by design

**STATUS (2026-10-27):** READ-ONLY diagnosis of the /admin/login "Forbidden". Evidence: `docs/SCA-ADMIN-LOGIN-403-DIAGNOSIS.md`. No firewall/auth/config/permission/code/service change; no protection disabled.
- **ROOT CAUSE (working-as-designed, NOT a bug):** sr-caddy verify.* block has `@admin path /admin /admin/*` → `@staff remote_ip <two authorized staff IPs>`; non-staff IPs get edge `respond "Forbidden" 403` BEFORE kr-app. Public /admin/login = 403 (server: Caddy, text/plain "Forbidden"); loopback 127.0.0.1:8080/admin/login = 200 (Apache/Laravel full Sign In). So 403 is at the EDGE, not Apache/Laravel/ACL.
- **OAuth impact:** /admin/sca/shopify/connect is UNDER /admin → 403 at edge for non-staff IP (loopback 302). The callback /sca/shopify/oauth/callback is edge-allowed (any IP) → reachable (400 fail-closed). So only INITIATING connect is blocked; CSRF state→callback same-domain session requires the initiator's browser to finish Shopify approval.
- **SMALLEST SAFE FIX (do NOT weaken allowlist):** (1) PREFERRED no-change — staff on an authorized IP opens /admin/login + /admin/sca/shopify/connect; store admin authenticates+approves on Shopify's own domain in that session; public callback completes. (2) If operator IP must be allowed: owner adds that specific IP to the Caddy `@staff remote_ip` line + `docker compose up -d --force-recreate sr-caddy` (⚠️ briefly drops smsrocket.io — quiet hour; single-file bind, plain reload won't work). (3) NEVER broaden to 0.0.0.0/0.

**STOP — diagnosis delivered; owner action to access /admin from a staff IP (or scope-add the IP). Then resume OAuth Step 1 approval (scope change already live: SHOPIFY_SCOPES=read_orders,read_products; stored token still read_orders pending merchant approval).**

---

# (PRIOR) SCA — SHOPIFY OAUTH ACTIVATION STEP 1: scope change DONE; merchant approval PENDING (interactive)

**STATUS (2026-10-27):** Authorized scope change applied; OAuth re-consent is interactive + PENDING. Evidence: `docs/SCA-SHOPIFY-INVENTORY-SYNC-PHASE1-OAUTH-ACTIVATION-RESULT.md`. No webhook register/import/reconcile/deploy/migrate/ownership change; no credential exposed; Option C+139/140 untouched.
- **[2] DONE:** app/.env `SHOPIFY_SCOPES=read_orders`→`read_orders,read_products` (ONE line; backup `app/.env.bak.preoauth.20261027T155210Z` 0600 kept; verified only that line differs, secrets untouched).
- **[4] Verified:** effective config scopes=read_orders,read_products; OAuthService::requiredScopes=[read_orders,read_products]. Config not cached → live immediately (no restart).
- **[3] Preserved:** credential row unchanged (scope=read_orders, has_token=1, token 2026-10-05); order webhooks + sale-link path untouched.
- **[5] Callback:** GET /sca/shopify/oauth/callback → 400 (public + loopback) = reachable + fail-closed + edge-routed.
- **[6] CONNECTION URL:** `https://verify.secondchanceauthenticators.com/admin/sca/shopify/connect` (staff ACL sca.shopify.view opens → app 302s to Shopify authorize requesting read_orders,read_products → STORE ADMIN approves).
- **[7][8][9] PENDING:** merchant has NOT re-consented (stored scope still read_orders). Cannot bypass. After approval, re-run: verify sca_shopify_credentials.scope includes read_products (+newer updated_at), then read-only getProduct/listProducts probe (NO import).
- **ROLLBACK:** `cp -p app/.env.bak.preoauth.20261027T155210Z app/.env` (reverts scope; no token/DB change).

**STOP — scope live, approval PENDING. Owner: have the Shopify admin open the connection URL + approve, then re-run steps 8–9. NOT AUTHORIZED next: webhook registration, import, reconcile scheduling.**

---

# (PRIOR) SCA — SHOPIFY ACTIVATION STEP 1: OAuth read_products PREP (READ-ONLY); AWAITING APPROVAL

**STATUS (2026-10-27):** READ-ONLY OAuth preparation. Evidence: `docs/SCA-SHOPIFY-INVENTORY-SYNC-PHASE1-OAUTH-PREP.md`. No scope change/reauth/webhook/import/migrate/merge/restart; no credential exposed; Option C untouched.
- **[1] Observed:** SHOP second-chance-eyewear-accessories.myshopify.com; SHOPIFY_SCOPES=read_orders; api 2026-07; redirect https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback; client_id/secret/webhook_secret present (values NOT shown). Credential row scope=read_orders, has_token=1. Config NOT cached (env read live; config:clear only if ever cached).
- **[2] Minimal change (prepared, NOT applied):** app/.env one line `SHOPIFY_SCOPES=read_orders`→`read_orders,read_products` (ADDITIVE; not a secret; no code change — flow already supports multi-scope; OAuthService::authorizeUrl emits SHOPIFY_SCOPES).
- **[3] Verify:** shop domain matches credential; redirect path route resolves (sca.shopify.oauth.callback), HTTPS exact. OWNER must confirm (external): Dev Dashboard redirect-URL allowlist includes the exact URL + edge Caddy routes /sca/shopify/oauth/callback→kr-app (gov 8bc04d5).
- **[4] Authorize + approval:** staff (ACL sca.shopify.view) opens `https://verify.secondchanceauthenticators.com/admin/sca/shopify/connect` → app 302s to `https://<shop>/admin/oauth/authorize?client_id=<CLIENT_ID>&scope=read_orders,read_products&redirect_uri=<callback>&state=<nonce>` → MERCHANT (store admin) approves added "read products" → callback verifies state+HMAC+shop, exchanges code→new token (read_orders,read_products) stored ENCRYPTED → verify sca_shopify_credentials.scope includes read_products.
- **[5] Preserved:** additive → read_orders + order webhooks (orders/paid|cancelled, refunds/create) + sale-link path untouched. [6] No token/secret/client-id value revealed.

**STOP — prep delivered; await approval before editing SHOPIFY_SCOPES or initiating OAuth. Next activation steps after this: register products/* webhooks; run initial import.**

---

# (PRIOR) SCA — SHOPIFY INVENTORY SYNC PHASE 1 DEPLOYED (main 905ea7d, batch 28); tables live-but-dormant; prod data unchanged

**STATUS (2026-10-27):** Authorized controlled deploy of candidate 9f05c8a DONE. Evidence: `docs/SCA-SHOPIFY-INVENTORY-SYNC-PHASE1-DEPLOY-RESULT.md`. No OAuth/scope/reauth, webhook register, import, reconcile schedule, Option C, unrelated migration, Docker recreate, or rollback.
- **Deployed:** main `6ebe968`→merge **`905ea7d09661994a7aa22b0e9a5c966a8b4c2a95`** (2nd parent 9f05c8a; push 6ebe968..905ea7d). Rollback pin `shopify-p1-prerelease-pin→6ebe968`.
- **Gates:** preflight reconfirmed (main/clean/backup/pending==2); merge --no-ff (on-disk change = EXACTLY 16 files, Shopify pkg + tests); migrate:status (case-sensitive) = ONLY the 2 Pending → `migrate --force` ran BOTH DONE (batch 27→28). [GOTCHA: case-insensitive grep 'pending' falsely matched migration NAME add_active_pending_guard; use case-sensitive 'Pending' for status — no migration ran at that false gate.]
- **Post-checks PASS:** configtest Syntax OK + `apachectl -k graceful` (container NOT recreated, StartedAt 2026-10-18); admin/login 200 + passport /p 200; sca_shopify_products/variants EXIST + EMPTY (0/0); migrations 142 rows, maxbatch 28, exactly 2 rows@batch28; eyewear fingerprint UNCHANGED 3/3/5/4; 139/140 batch-27 untouched.
- **LIVE-BUT-DORMANT:** catalog code + 2 empty tables live; product-sync/import/reconcile services inert (no products/* webhook registered, no read_products, no import run); order/sale-link path unchanged.
- **Rollback (preserved, data-preserving, NOT migrate:rollback):** `git revert -m1 905ea7d` + advance tree + graceful reload; LEAVE tables+rows.
- **Still owner-gated (NOT done):** read_products scope + merchant re-consent; products/* webhook registration; initial import; reconcile scheduling.

**STOP — Phase 1 deployed; reported for ChatGPT review. No activation action; no further changes.**

---

# (PRIOR) SCA — SHOPIFY INVENTORY SYNC PHASE 1 MIGRATION PREFLIGHT (READ-ONLY): scope PROVEN SAFE

**STATUS (2026-10-27T15:36Z):** READ-ONLY production migration preflight. Evidence: `docs/SCA-SHOPIFY-INVENTORY-SYNC-PHASE1-MIGRATION-PREFLIGHT.md`. No merge/deploy/migrate/restart/OAuth/webhook/import/prod change; Option C+139/140 untouched (not resolved).
- **[1][2][3] MIGRATION SCOPE PROVEN SAFE:** diffed branch 9f05c8a migration files (141) vs prod sca_krayin applied rows (140). PENDING = EXACTLY the 2 Shopify catalog migrations (2026_10_27_000001/000002) → migrate runs ONLY these (batch 27→28; additive Schema::create). 139 (2026_10_20 qr reason) on-branch+applied→skipped. **140 (2026_10_21 activity_last_seen) = orphan-applied row with NO file on branch → migrate never attempts it (inert); 139/140 incident triggers NO extra migration.** NOT BLOCKED.
- **[4] Recovery point:** backups/sca-backup-20261027T021703Z.tar.gz.gpg (sha 42e7aadd… MATCH; 10 artifacts; key present; 317G free; cron intact) = clean sca_krayin batch-27 snapshot, restore-proven 2026-10-27 (gov 016bd1c). First post-deploy nightly (10-28 02:17Z) not yet run (not required).
- **[5] Minimal deploy:** migrate:status gate → `git merge --no-ff 9f05c8a→main` → push → `migrate --force` (ONLY the 2, batch 28) → `apachectl -k graceful`. No composer/rebuild/config.
- **[6] ROLLBACK = CODE-ONLY, DATA-PRESERVING (NOT migrate:rollback):** `git revert -m1 <merge>` + advance tree + graceful reload; LEAVE both tables + imported rows (becomes inert orphan rows like 140; old code never references them). migrate:rollback would DROP tables+data → do NOT use. Table removal = separate owner decision. Never reset main.
- **[7] main 6ebe968 clean; app/login 200; sca_krayin 3/3/5/4, 140 rows, batch 27.**

**STOP — preflight PASS (not blocked) for owner + ChatGPT. Await explicit deploy approval. No release action.**

---

# (PRIOR) SCA — SHOPIFY INVENTORY SYNC PHASE 1 RELEASE READINESS (READ-ONLY): READY on owner approval

**STATUS (2026-10-27):** READ-ONLY release prep. Evidence: `docs/SCA-SHOPIFY-INVENTORY-SYNC-PHASE1-RELEASE-READINESS.md`. No merge/deploy/migrate/scope/OAuth/webhook/import/restart/prod change; Option C+139/140 untouched.
- **[1][2] Branch 9f05c8a directly on main 6ebe968 (clean merge, NO conflict); delta 16 files +1387/−4 CONFINED to app/packages/Sca/Shopify + app/tests; 2 ADDITIVE migrations (CREATE only, no ALTER); NO composer/config change. Code deploy is INERT until activation (empty tables, no product webhooks, no read_products).**
- **[3] Deploy seq:** merge --no-ff 9f05c8a→main; advance live tree; **`artisan migrate --force` (2 new tables, batch 27→28; pre-check migrate:status shows ONLY the 2 pending; GOTCHA bare migrate=prod sca_krayin, intended here)**; `apachectl -k graceful` (changed WebhookController/Recorder/Topics/Provider). NO composer/rebuild. Rollback: revert-forward + `migrate:rollback --step=1` (drops the 2 empty tables, no data loss); never reset main.
- **[4] OAuth:** prod SHOPIFY_SCOPES=read_orders; live credential token read_orders-only. Add read_products → set SHOPIFY_SCOPES=read_orders,read_products (scope string NOT secret; creds/token env-only, never printed; token stored encrypted) + merchant RE-CONSENT → new token. SHOP_DOMAIN second-chance-eyewear-accessories.myshopify.com, redirect .../sca/shopify/oauth/callback, api 2026-07; client_id/secret/webhook_secret present.
- **[5] Webhooks:** add products/create|update|delete → https://verify.secondchanceauthenticators.com/sca/shopify/webhook (JSON, 2026-07, HMAC=client_secret); verify edge Caddy routes it (prior gov 8bc04d5); test delivery→200 + 1 receipt, replay→no 2nd row. Keep order/refund topics.
- **[6] Import:** `php artisan sca:shopify:import-catalog` (explicit); verify counts + catalog rows>0 + provenance UNCHANGED (3/3/5/4) + no passport/QR + idempotent re-run (all unchanged). reconcile-catalog stays UNscheduled.
- **[7] Merchant:** one click to approve "read products" (read-only; changes nothing in store); no secrets shared.
- **VERDICT: READY to release on owner approval; activation gated on read_products re-consent + webhook registration + import.**

**STOP — readiness report delivered for owner + ChatGPT. No release action; no further tests unless a concrete issue is found.**

---

# (PRIOR) SCA — SHOPIFY INVENTORY SYNC PHASE 1 DB TEST PASS (21/21, disposable DB); prod unchanged

**STATUS (2026-10-27):** Authorized ONE isolated DB-test session executed. Evidence: `docs/SCA-SHOPIFY-INVENTORY-SYNC-PHASE1-DB-TEST-RESULT.md`. Disposable DB only; dropped+verified; prod sca_krayin UNCHANGED. No prod-migrate/merge/deploy/live-Shopify/OAuth/webhook; no full-regression/baseline; Option C+139/140 untouched.
- **Run SHA `9f05c8a`** = reviewed `e96700b` + TEST-ONLY DB-guard parameterization (SCA_TEST_DB; refuses sca_krayin); product/service code byte-identical to e96700b. Worktree; live main 6ebe968 untouched. Pushed origin.
- **Isolation:** unique DB `sca_shopify_p1_74d640a161a9` created after existence-check; verified effective getDatabaseName()==live SELECT DATABASE()==disposable (not sca_krayin). Dev vendor built in worktree (live vendor is --no-dev); ephemeral container reached kr-mariadb on sca_internal with DB_DATABASE injected.
- **Result: PASS — 21 tests / 67 assertions / 0 fail / 0 skip / 0 warn** (phpunit 11.5.50, PHP 8.3.33). Migrated full schema incl. 2 new catalog migrations. Verified: dup prevention, update+no-provenance, stale, incomplete/null/malformed/empty/partial-malformed/non-array/duplicate-id snapshots (no wrongful archive) + fully-valid still archives, reversible delete+revive, reconciliation-confirm-only-when-absent, missing/invalid/per-variant-unorderable ts fail-closed, variant qty>1→1 row+0 items, webhook replay idempotent, bad-sig 401 writes nothing.
- **[7] Catalog-only:** disposable DB 0 rows in eyewear_items/state/ownership/certs/qr/claim_grants AND catalog tables (rollback) → no physical/passport/ownership/claim records.
- **[9] Cleanup:** disposable DB dropped, grant revoked (0 residual), DBs back to baseline; worktree+vendor removed.
- **[10] Prod UNCHANGED:** sca_krayin 3/3/5/4 batch 27; kr-app 200.
- **Remaining activation (owner):** read_products scope + OAuth re-consent; register products/* webhooks; deploy (code + 2 additive migrations) via minimal-deploy; initial import; optional reconcile schedule.

**STOP — DB test PASS delivered for ChatGPT review. No further DB runs / merge / deploy / scope / webhook action under this authorization.**

---

# (PRIOR) SCA — SHOPIFY INVENTORY SYNC PHASE 1 FINAL SNAPSHOT CORRECTION (branch e96700b)

**STATUS (2026-10-27):** Final variant-snapshot fix on feat/sca-shopify-inventory-sync (worktree; live main 6ebe968 untouched). Evidence: `docs/SCA-SHOPIFY-INVENTORY-SYNC-PHASE1-SNAPSHOT-CORRECTION.md`. No prod/merge/deploy/live-Shopify/OAuth/webhook-register; all other Phase 1 behavior preserved.
- **SHA:** `5f53bec`→**`e96700b9a369ac259cd8a14c1162622fb16e6898`** (pushed). 2 files (ProductCatalogService::syncVariants + test).
- **FIX:** removed-variant archival now requires ENTIRE snapshot complete+valid. New `snapshotComplete` flag (seeded from trustedSnapshot) → ANY non-array entry / missing-invalid id / DUPLICATE id disables archival for that event; archive gated on `snapshotComplete && count(seen)>0`. Valid variants still upsert (fail-closed per-variant freshness). Empty/null/missing/malformed protection intact; fully-valid snapshot still archives removed variant. Added 'duplicate' counter.
- **Non-destructive:** php -l clean (2 files); snapshot-completeness logic smoke 8/8. +4 DB tests (partially-malformed, non-array entry, duplicate id, fully-valid regression) WRITTEN NOT RUN.
- **Remaining activation (owner):** run DB tests on disposable DB (SEP AUTH); read_products scope + OAuth re-consent; register products/* webhooks; deploy+import; reconcile schedule later.

**STOP — correction delivered for ChatGPT review. Do NOT run DB tests / merge / deploy / change scopes / reauth / register webhooks until authorized.**

---

# (PRIOR) SCA — SHOPIFY INVENTORY SYNC PHASE 1 CORRECTIONS applied (branch 5f53bec)

**STATUS (2026-10-27):** 3 reviewed correctness fixes on feat/sca-shopify-inventory-sync (worktree; live main 6ebe968 untouched). Evidence: `docs/SCA-SHOPIFY-INVENTORY-SYNC-PHASE1-CORRECTIONS.md`. No prod/merge/deploy/live-Shopify/OAuth-scope/webhook-register; order webhooks+sale-link UNCHANGED; Option C+139/140 untouched.
- **SHA:** `312927d`→**`5f53bec1b30049d4272c1019831c38e8f781a45a`** (pushed). 6 files.
- **(1) Trusted snapshot:** syncVariants archives removed-variant ONLY when variants is a PRESENT array w/ ≥1 valid variant seen on a FRESH event; missing/null/malformed/EMPTY never archives existing variants.
- **(2) Reversible delete + authoritative reconcile:** products/delete (no Shopify ts) → reversible `pending_delete`+delete_requested_at (NOT archive, variants kept); later fresh event → `revived`; new `ProductCatalogService::archiveConfirmedDeletions(shop,seenIds)` (called by reconcile after live sweep) archives ONLY pending_delete still-absent → old/out-of-order delete can't overwrite newer state. status col adds pending_delete + delete_requested_at (migration still unmerged).
- **(3) Fail-closed freshness:** new tsOrNull()+freshness()→fresh|stale|indeterminate; overwrite ONLY on fresh (valid incoming updated_at ≥ stored); missing/invalid/unorderable→indeterminate (no overwrite), older→stale; applies product-level AND per-variant. Replaces permissive isStale(). WebhookAuditRecorder: +revived/pending_delete actionable, +indeterminate noop.
- **Non-destructive:** php -l clean (6 files); freshness+trusted-snapshot logic smokes 11/11. DB tests WRITTEN NOT RUN (+7 new: incomplete/empty variant collections, reversible delete, revive, reconcile-confirm absent-only, missing/invalid ts no-overwrite, per-variant unorderable ts).
- **Remaining activation (owner):** run DB tests on disposable DB (SEP AUTH); read_products scope + OAuth re-consent; register products/* webhooks; deploy+import; reconcile schedule later.

**STOP — corrections delivered for ChatGPT review. Do NOT run DB tests / merge / deploy / change scopes / reauth / register webhooks until authorized.**

---

# (PRIOR) SCA — SHOPIFY INVENTORY SYNC PHASE 1 IMPLEMENTED (branch 312927d)

**STATUS (2026-10-27):** Phase 1 catalog sync implemented on feat/sca-shopify-inventory-sync (worktree; live tree main 6ebe968 untouched). Evidence: `docs/SCA-SHOPIFY-INVENTORY-SYNC-PHASE1-IMPLEMENTATION.md`. No prod/merge/deploy/live-connect/webhook-register/scope-change/OAuth-reauth; Option C + 139/140 untouched.
- **SHA:** `6ebe968`→**`312927ddc0a8de7c8b64415a837cf9c59931a70d`** (pushed origin). 16 files (10 new/5 edit/1 test).
- **New:** migrations sca_shopify_products/variants (UNIQUE shop+product/variant id); Models; ProductCatalogService (sole writer: txn idempotent upsert, stale-event guard via shopify_updated_at, removed-variant + delete SOFT-archive, missing-id fail-closed, content_hash); ProductSyncEventProcessor; ProductCatalogImporter + ImportCatalogCommand (explicit, not scheduled); ProductReconciliationService + ReconcileCatalogCommand (PREPARED, NOT scheduled/activated). **Edit:** ShopifyClient +getProduct/listProducts (cursor/Link pagination, 429→RATE_LIMITED, host-locked); WebhookTopics +product topics+isProductTopic; WebhookController routes product topics inside existing atomic/idempotent/replay boundary (order/sale-link path PRESERVED); WebhookAuditRecorder catalog outcomes; ServiceProvider registers 2 console cmds (console-only, no schedule).
- **CATALOG-ONLY INVARIANT:** writes ONLY the 2 catalog tables; NEVER creates eyewear item/passport/QR/ownership/auth/cert/claim-link; ItemService NOT invoked by any sync path. Variant qty>1 → 1 catalog row + 0 items.
- **Non-destructive evidence:** php -l 16/16 clean; WebhookTopics + Link-header parser logic smokes OK. **DB feature test `ShopifyProductCatalogSyncTest` WRITTEN, NOT RUN** (dup/update+no-provenance/stale/missing-ids/archival/removed-variant/qty>1/replay/bad-sig).
- **Remaining activation (owner):** (1) run DB tests on isolated unique disposable DB — SEPARATE AUTH needed; (2) add read_products scope + merchant OAuth re-consent (token is read_orders-only→403 until then); (3) register products/* webhooks (deploy-time); (4) deploy (code + 2 additive migrations) via minimal-deploy, then import once, then optionally schedule reconcile; (5) read_inventory/read_locations only if authoritative stock sync later.

**STOP — implementation delivered for ChatGPT review. Do NOT run DB tests / merge / deploy / change scopes / reauth / register webhooks until authorized.**

---

# (PRIOR) SCA — SHOPIFY INVENTORY SYNC PHASE 1: AUDIT + PLAN delivered (no code)

**STATUS (2026-10-27):** Read-only audit + implementation plan for Shopify product→SCA sync. Evidence: `docs/SCA-SHOPIFY-INVENTORY-SYNC-PHASE1-PLAN.md`. Branch `feat/sca-shopify-inventory-sync` created at `6ebe968` (LOCAL ref, NO code, live tree stays on main). No code written, no DB test, no merge/deploy/live-connect/webhook-register/prod-migrate.
- **CORE DECISION (needs sign-off):** Shopify variant = catalog SKU w/ qty ≠ physical pair. Phase 1 = CATALOG sync into NEW tables `sca_shopify_products`+`sca_shopify_variants` (UNIQUE shop+product_id / shop+variant_id = DB dup protection); sync NEVER creates sca_eyewear_items/passport/QR/ownership/auth/claim-link (objective #6 + IMPORTANT). Physical-pair individuation + item↔variant link DEFERRED. ItemService reused only at that future step.
- **Reuse:** WebhookController atomic/idempotent/replay boundary (idempotency_key UNIQUE), WebhookVerifier HMAC, receipts table — all inherited; add product topics to WebhookTopics + new ProductSyncEventProcessor (mirrors SaleLinkEventProcessor). ShopifyClient: add read-only getProduct/listProducts (cursor pagination, same fail-closed contract).
- **⚠️ PERMISSION BLOCKER:** prod app/.env `SHOPIFY_SCOPES=read_orders` — read_products NOT granted → product reads 403 until **SHOPIFY_SCOPES=read_orders,read_products + merchant OAuth RE-CONSENT/RE-INSTALL** (owner action). read_inventory/read_locations only if authoritative stock-level sync later (deferred). Webhook topic registration = deploy-time (not this task). SHOP_DOMAIN=second-chance-eyewear-accessories.myshopify.com, api 2026-07 unchanged.
- **Tests planned (AFTER approval, disposable DB):** duplicates, updates (+assert no item/ownership touched), missing ids, archival soft, failure recovery/replay, variant qty>1 → 1 catalog row + 0 items.

**STOP — plan delivered for owner + ChatGPT. Do NOT write code or run DB-changing tests until approved (esp. §2 catalog-vs-item decision + §7 read_products re-consent).**

---

# (PRIOR) SCA — FIRST POST-DEPLOY NIGHTLY = PENDING (read-only); re-check after 2026-10-28 02:17 UTC
(Still open: re-verify the first post-deploy nightly backup after 2026-10-28 02:17 UTC — see `docs/SCA-OPTC-BACKUP-FIRST-NIGHTLY-OBSERVATION.md`.)

**STATUS (2026-10-27T14:14Z):** READ-ONLY observation of the first nightly after deploy 6ebe968. Evidence: `docs/SCA-OPTC-BACKUP-FIRST-NIGHTLY-OBSERVATION.md`. No backup triggered; no restore/merge/deploy/restart/config.
- **PENDING:** deploy landed ~14:09 UTC 2026-10-27; cron `17 3 * * *` = host TZ UTC+1 ⇒ **02:17 UTC** daily. Last run 2026-10-27 02:17 UTC was BEFORE deploy (old code). **First post-deploy nightly = 2026-10-28 02:17 UTC (not yet occurred).** Did NOT trigger a manual backup.
- **[2] Deployed backup-run.sh READY:** 2× backup_document_stage + sources lib-docsnapshot.sh → next run uses snapshot_documents + verify_db_document_refs (R1 cleared → expected pass).
- **[5] schedule/retention INTACT:** cron unchanged; RETAIN_DAYS=14/RETAIN_MIN=7; 10 artifacts; newest 20261027T021703Z sidecar sha MATCH.
- **[6] prod health + migration baseline UNCHANGED:** admin/login 200, passport /p 200; DB 3/3/5/4, migrations 140/batch 27, migrations-sha 3b38ae24==baseline; HEAD 6ebe968.

**STOP — PENDING reported (no trigger). RE-OBSERVE after 2026-10-28 02:17 UTC: expect START/OK docs=N/DONE for sca-backup-20261028T0217…, no snapshot/doc-ref error, matching .sha256; then optionally restore-proof the new artifact (disposable, separate auth, run plain+background).**

---

# (PRIOR) SCA — BACKUP FIX DEPLOYED (main 6ebe968); all checks PASS; prod unchanged; AWAITING CHATGPT

**STATUS (2026-10-27):** Authorized controlled standalone deploy of backup-consistency release 95c15d3 via the MINIMAL plan (deploy-preview.sh NOT used). Evidence: `docs/SCA-OPTC-BACKUP-FIX-DEPLOY-RESULT.md`. NO reset --hard/force-push, NO migration/DB-test/composer/Docker-rebuild/recreate/config/Option-C/Shopify/Stripe/SMTP; NO backup/restore started.
- **Deployed SHA:** prior main `6022b75` → **merge `6ebe9686a5ad3cecf115eb058f98c0dfc52fa3f9`** (push 6022b75..6ebe968; 2nd parent 95c15d3). Live working-tree HEAD=6ebe968 (bind-mount → app live).
- **Preflight PASS:** clean tree, HEAD==origin/main==6022b75, branch==95c15d3 ff-descendant, delta==6 files no migration, containers up.
- **Rollback prepared+pinned** `backup-prerelease-pin→6022b75` (verified pre-images) BEFORE merge; primary = `git revert -m 1 6ebe968`+push+graceful; code-only NO DB. Not needed (all passed).
- **Deploy PASS:** `git merge --no-ff 95c15d3` (on-disk change = EXACTLY the 6 files, asserted) → push → `apachectl configtest`=Syntax OK → `apachectl -k graceful` (container NOT recreated; StartedAt 2026-10-18 unchanged).
- **[7] Health PASS:** `/p/{token}` 200 (194KB, content rendered); `/p/{token}/image` 200 image/png (document access OK); `/admin/login` 200; no 5xx.
- **[8] DB UNCHANGED:** items/state/owns/certs 3/3/5/4; migrations 140 rows/batch 27; migrations-sha 3b38ae24 == baseline. No migrate ran; 139/140 untouched; Option C 0f41e2e unmerged.
- **[9] cron/retention/artifacts INTACT:** cron 03:17; 10 artifacts; sha-list 1790976606 == baseline. backup-run.sh now has doc-consistency stage → **FIRST NIGHTLY 03:17 UTC = first-backup validation (pending; not run under this auth)**.
- **B5 (doc-consistency) now CLOSED+DEPLOYED.** Off-host B1–B4 + key escrow remain separate open DR item.

**STOP — controlled backup-fix deploy PASS delivered for independent ChatGPT review. Next: observe first post-deploy nightly (03:17 UTC) logs OK + optionally restore-proof the first new artifact (disposable, separate auth). No further action under this authorization.**

---

# (PRIOR) SCA — BACKUP FIX MINIMAL DEPLOY PLAN (READ-ONLY, commands for review): deploy-preview.sh REJECTED; AWAITING OWNER + CHATGPT

**STATUS (2026-10-27):** READ-ONLY corrected deployment plan (deploy-preview.sh NOT approved — it does reset --hard/composer/tests/migrate/rebuild). Evidence: `docs/SCA-OPTC-BACKUP-FIX-MINIMAL-DEPLOY-PLAN.md`. Commands for review only, NOT executed. No merge/deploy/reload/restart/DB/backup-config change.
- **Delta = 6 files, NO migration** (verified), Option C `0f41e2e` DISJOINT (no overlap), 6022b75 ancestor of 95c15d3 (clean merge touches only the 6). Live app = bind-mounted working tree → file update IS the deploy (no rebuild/recreate/composer/migrate).
- **Minimal deploy:** (A) `git merge --no-ff --no-edit 95c15d3` (updates ONLY the 6 files in live working tree; NO reset --hard, NO deploy-preview.sh); (A') verify `git diff --name-only HEAD@{1} HEAD`==6 paths; (B) `git push origin main`; (C) `docker exec kr-app apachectl -k graceful` (controlled opcache reload, zero-downtime, NOT restart/recreate). No chown needed.
- **Preflight:** clean tree + HEAD==6022b75==origin/main; branch tip==95c15d3 & ancestor; delta==6 files & no migrations; containers up; record batch 27 baseline.
- **Rollback (code-only, NO DB):** revert-forward `git revert -m 1 <merge>` + push + graceful reload; emergency `git checkout 6022b75 -- <6 paths>` + reload. Never reset/force-push main.
- **Post-deploy:** curl 200 + passport render; existing doc stream; `apachectl configtest`; batch still 27 (no migrate ran); first nightly logs OK w/ new verify stage; then restore-proof first new artifact (disposable, plain+background).
- **Failure-stop:** any preflight fail→STOP; merge conflict/>6 files→`git merge --abort`; push rejected→re-preflight; graceful nonzero→configtest/retry, do NOT restart container; health fail→rollback.
- **[7] PRESERVES 139/140 (no migrate, no migration file) + Option C (never checked out/merged, disjoint).**

**STOP — read-only corrected deploy plan delivered for owner + ChatGPT. Commands for review only; nothing executed. Await explicit owner approval.**

---

# (PRIOR) SCA — BACKUP FIX RELEASE PREFLIGHT (READ-ONLY): GO to merge+deploy; AWAITING EXPLICIT OWNER APPROVAL

**STATUS (2026-10-27):** READ-ONLY final release preflight for the backup-hardening delta. Evidence: `docs/SCA-OPTC-BACKUP-FIX-RELEASE-PREFLIGHT.md`. Nothing merged/deployed/restarted/migrated/reconfigured; no backup created.
- **[1] SHAs:** main=`6022b75`, branch=`95c15d3`, merge-base==main ⇒ branch directly on current main (clean merge). Live app = bind-mounted working tree = main 6022b75.
- **[2] Standalone diff = 6 files (+877/−57), ONLY intended backup-hardening:** DocumentService.php (app write-atomicity) + BackupDocumentAtomicityTest + backup-run.sh + lib-docsnapshot.sh(new) + backup-verify-restore.sh + test-restore-verify-safety.sh(new). NO migration/composer/config/bootstrap/.env; retention unchanged.
- **[3] Rollback:** code-only, NO DB rollback (no migration); revert 6 files→6022b75 + re-run deploy-preview.sh + graceful reload; DocumentService.php forward-safe (may stay). Revert-forward only, never reset shared main.
- **[4] Deploy:** (A) `git merge --no-ff 95c15d3`→main, push. (B) `scripts/deploy-preview.sh` (reset --hard origin/main advances app/+scripts/ together; composer no-op; suite vs sca_domain_test; `migrate --force`=NO-OP no pending migration; config/route clear). (C) **required opcache reload `docker exec kr-app apachectl -k graceful`** (zero-downtime, NOT restart; opcache enable=On validate_timestamps=On freq=2 → graceful makes pickup deterministic).
- **[5] Post-deploy:** app 200 + passport renders; existing doc stream loads; **first nightly (03:17 UTC) logs OK with new snapshot+verify_db_document_refs** (R1 cleared → should pass; fail-closed→no artifact); then `backup-verify-restore.sh verify <new-artifact>` (disposable).
- **[6] Safeguards:** run verify PLAIN + BACKGROUND, never `bash -x|grep` or kill -9 (SIGKILL skips EXIT final_cleanup → orphan `*_restore_verify_<hex>` DB + multi-GB staging; create happens only AFTER decrypt). Orphan ID: schemata LIKE restore_verify/backup_selftest + grants + backups/.work; remove only disposable names (never sca_krayin). Follow-up: add `trap final_cleanup INT TERM`.
- **[7] GO/NO-GO: GO** to merge+deploy on explicit owner approval; off-host B1–B4 remains separate open DR item (not a blocker for this code-only release).

**STOP — read-only preflight delivered. Await EXPLICIT owner approval before release execution. No merge/deploy/restart/migration/config/backup action.**

---

# (PRIOR) SCA — CONTROLLED RESTORE-VERIFICATION EXECUTED: PASS (R1 cleared); prod unchanged; AWAITING CHATGPT

**STATUS (2026-10-27):** Authorized ONE controlled restore-verification of the 2026-10-27 encrypted backup via branch `95c15d3` in an isolated worktree, disposable DB only. Evidence: `docs/SCA-OPTC-BACKUP-RESTORE-VERIFICATION-RESULT.md`. NO prod DB restore/modify, NO backup create/delete, NO merge/deploy/migration/service-restart/config/integration change.
- **Pre-flight PASS:** identity sca_krayin; kr-mariadb+kr-app up; no stray disposable DBs; checksum 42e7aadd…==sidecar==log; key 0600; 317G free; cron 17 3 * * *; 10 artifacts; baseline items=3 state=3 owns=5 certs=4 batch=27.
- **Selftests PASS:** `selftest` (tamper-detect, rows=2, trigger enforced, doc sha match) + `doc-consistency-selftest` (A–M fail-closed).
- **Real restore PASS** into disposable `sca_krayin_restore_verify_dfe153bc9551`: artifact sha verified; db vs manifest; tables=100 triggers=46 FK=129; referential OK; **app read PINNED to disposable (items=3 state=3)**; docs 4605 intact; **verify_db_document_refs OK on restored artifact ⇒ R1 CLEARED**; disposable DB dropped; exit 0.
- **Cleanup PASS:** only sca_krayin+system DBs remain; no restore_verify grant; backups/.work 0 entries; worktree removed; live main 6022b75 clean.
- **Prod unchanged PASS:** sca_krayin fingerprint identical (3/3/5/4, batch 27); containers up; cron/retention/10-artifacts/artifact-sha all unchanged; 139/140 untouched.
- **Note:** a first `bash -x|grep` trace was stopped mid-restore (SIGKILL skipped EXIT cleanup) → left 1 orphan disposable DB + staging; both manually removed/verified gone before the clean run. No prod object touched.

**STOP — controlled restore-verification PASS delivered for independent ChatGPT review. Backup-DR restore-proof gate (R1) satisfied. No merge/deploy/migration/prod-mutation/service/config/integration change.**

---

# (PRIOR) SCA — RESTORE-VERIFY FINAL TWO SAFETY CHECKS DONE (branch 95c15d3; mocked 35/35); NO real restore; AWAITING CHATGPT + OWNER AUTH

**STATUS (2026-10-27):** Two more isolated corrections to `scripts/backup-verify-restore.sh` (after conditionally-accepted review of b14439c). Evidence: `docs/SCA-OPTC-BACKUP-FIX-RESTORE-SAFETY-CORRECTIONS-2.md`. Done in a git WORKTREE (live checkout untouched = main 6022b75 clean). NO real restore/merge/deploy/migration/service/backup-config change.
- **SHA:** branch `b14439c`→**`95c15d3f5dde1162f6ede442b87a007b87835ccd`** (pushed origin). Changed backup-verify-restore.sh + test-restore-verify-safety.sh. backup-run.sh/lib-docsnapshot.sh/DocumentService.php UNTOUCHED.
- **Correction 1 (cleanup fatal):** `cleanup_created_dbs` drops `2>/dev/null||true` (shows original mysql error), records CLEANUP_ERR, returns nonzero. Shared `final_cleanup` EXIT trap (both selftest+verify): shred WORK → cleanup; on failure prints `CLEANUP INCOMPLETE` + leftover DB name + `(original failure preserved: body exited N)` and exits nonzero EVEN IF body succeeded. Success lines (SELFTEST PASS / RESTORE VERIFICATION PASS) deferred to RESULT_MSG, printed ONLY after DB actually dropped → success never reported on incomplete cleanup.
- **Correction 2 (app-read DB pin):** php guard asserts `getenv(DB_DATABASE)`==`DB::connection()->getDatabaseName()`==live `SELECT DATABASE()` all == injected TARGET before reading tables; else emits DB_IDENTITY_MISMATCH + exit 3; shell aborts unless output exactly `items=N state=N`. Catches app reading live sca_krayin via stale .env.
- **Mocked tests 35/35 PASS** (`bash scripts/test-restore-verify-safety.sh scripts/backup-verify-restore.sh`): preserved T1-T6 + new T7a-d (cleanup fatal/no-false-success/reason-preserved/revoke-fatal) + T8 (identity mismatch abort / match pass) + static asserts. bash -n clean.
- Procedure unchanged except staged tip now 95c15d3; `CLEANUP INCOMPLETE`/`DB identity mismatch` = hard stop.

**STOP — corrected tooling + mocked tests delivered for independent ChatGPT review. Do NOT execute real restore; await explicit owner authorization. No merge/deploy/migration/service/backup-config change.**

---

# (PRIOR) SCA — RESTORE-VERIFY TOOLING SAFETY CORRECTIONS DONE (branch b14439c; mocked tests 22/22); NO real restore; AWAITING CHATGPT + OWNER AUTH

**STATUS (2026-10-27):** Isolated safety corrections to `scripts/backup-verify-restore.sh` + mocked tests. Evidence: `docs/SCA-OPTC-BACKUP-FIX-268C637-RESTORE-SAFETY-CORRECTIONS.md`. Done in a git WORKTREE (live checkout untouched = main 6022b75 clean). NO real restore/merge/deploy/migration/service/backup-config change.
- **SHA:** branch `fix/sca-backup-document-consistency` `268c637`→**`b14439cf819ac25a3dea07dfd8412671d00f009e`** (pushed origin github-sca-platform). Changed `scripts/backup-verify-restore.sh` (+77/−19); added `scripts/test-restore-verify-safety.sh`. backup-run.sh/lib-docsnapshot.sh/DocumentService.php UNTOUCHED.
- **10 corrections:** (1) unique per-run DB names `*_<12hex RUN_TAG>`; (2) CREATE no-DROP + abort-if-exists (pre-check + CREATE-no-IF-NOT-EXISTS); (3) register CREATED_DBS only after success; (4) cleanup drops only CREATED_DBS; (5) can't touch pre-existing DB (1-4 + guard_target); (6) scoped `REVOKE SELECT` on own per-run DB only if granted — removed `REVOKE ALL`; (7) doc extraction fail-closed (removed `2>/dev/null||true`→`||die`); (8) nonzero verify_db_document_refs→die (EXIT trap still cleans); (9) verify mode now runs verify_db_document_refs on the RESTORED artifact; (10) off-checkout staging via SCA_ENV_FILE + app-read via `docker exec kr-app` (not `docker compose exec`).
- **Mocked tests 22/22 PASS** (`bash scripts/test-restore-verify-safety.sh scripts/backup-verify-restore.sh`): T1 pre-exist collision→no CREATE/DROP; T2 CREATE race→no DROP; T3 cleanup drops only created + scoped revoke + no REVOKE ALL; T4 unique names; T5 extraction fail-closed; T6 nonzero-refs stop; static asserts. bash -n clean.
- **Corrected procedure:** worktree-staged (outside live app/), pre-flight (MARIADB_DATABASE==sca_krayin, kr-mariadb+kr-app running), selftest + doc-consistency-selftest + `verify <artifact>` (self-runs verifier on restored artifact), auto-cleanup, worktree remove. Current artifact sca-backup-20261027T021703Z (sha 42e7aadd…).

**STOP — corrected tooling + mocked tests delivered for independent ChatGPT review. Do NOT execute real restore; await explicit owner authorization. No merge/deploy/migration/service/backup-config change.**

---

# (PRIOR) SCA — BACKUP FIX 268c637 RESTORE-VERIFICATION PREP (READ-ONLY): procedure ready; AWAITING EXPLICIT OWNER AUTH before any DB restore

**STATUS (2026-10-27):** READ-ONLY preparation of the isolated restore-verification for the current encrypted backup. Evidence: `docs/SCA-OPTC-BACKUP-FIX-268C637-RESTORE-VERIFICATION-PREP.md`. NO restore executed; no merge/deploy/migration/prod/service/backup-setting/integration change.
- **[1] Current artifact:** `backups/sca-backup-20261027T021703Z.tar.gz.gpg`, 4,576,491,854 B, sha256 `42e7aadd…875fed` (sidecar + backup.log match; docs=4605; nightly OK, OFFSITE_DEFERRED). Prereqs: key 0600 present; 317G free; DB kr-mariadb (project sca); repo-root .env supplies MARIADB_*; disk-backed staging `backups/.work`. **Script-version prereq: main's backup-verify-restore.sh has 0 `verify_db_document_refs` → MUST use BRANCH (268c637) scripts, staged read-only.**
- **[2] Modes/isolation:** branch `verify`(real→disposable `sca_krayin_restore_verify`)/`selftest`(`sca_backup_selftest`)/`doc-consistency-selftest`/`offsite-selftest`. `guard_target` refuses live name; only DROPs target disposable; `trap cleanup EXIT` shred+rm+REVOKE+DROP on success&failure; integrity gates (artifact sha vs sidecar, db sha vs manifest, tables>0, referential, app-read, doc-byte checksums); TMPDIR=backups/.work not tmpfs.
- **[3] No clobber:** disposable names only; pre-flight asserts disposable DB does NOT already exist (script does DROP IF EXISTS→could drop a pre-existing same-name DB); live sca_krayin only read indirectly (restores EXISTING artifact, never re-dumps/writes live).
- **[4] Procedure:** Step0 stage branch scripts read-only (lib-docsnapshot.sh=new untracked, nightly unaffected; backup-verify-restore.branch.sh distinct name→no overwrite; runs from live root so .env/backups/secrets/`docker compose` project sca resolve). Step1 pre-flight asserts. Step2 selftest+doc-consistency-selftest. Step3 `verify "$ART"`. Step4 EXPLICIT verify_db_document_refs on restored db.sql.gz+docout (root=docout contains sca/). Step5 teardown staged scripts→clean tree.
- **[5] Stop conditions:** .env missing/MARIADB_DATABASE≠sca_krayin; kr-mariadb down; disposable DB already exists; artifact sha≠sidecar; db≠manifest; guard_target trip/app-read ERR; verify_db_document_refs rc≠0 (5 non-canonical/mismatch,6 missing,8 corrupt); selftest assertion fail.
- **[6] Verifier vs restored artifact:** FINDING branch `verify` mode does NOT call verify_db_document_refs (proves doc bytes vs manifest only); Step4 closes this → runs it over the RESTORED artifact (rc=0 proves current prod data passes the new fail-closed gate ⇒ clears R1 pre-deploy). Optional: add the call into verify-mode (owner decision; not changed).
- **[7] Expected evidence:** selftest PASS; doc-consistency A–M PASS; verify → sha/manifest verified, tables≈100/triggers≈46/FK≈129, referential OK, app-read items=3 state=3 (prov FP 3/3/4/4/5/2/1/1/7), docs 4605 intact, disposable dropped; Step4 rc=0. Rollback: nothing vs prod (read-only); disposable auto-dropped (manual DROP IF EXISTS + shred backups/.work if interrupted); remove staged scripts; cron+retention 14d/min7 unchanged.

**STOP — read-only prep delivered. Do NOT execute restore; await EXPLICIT owner authorization before any DB restore. No merge/deploy/prod/config/service/integration change.**

---

# (PRIOR) SCA — BACKUP FIX 268c637 STANDALONE RELEASE ALIGNMENT: isolability GO, deploy CONDITIONAL; MATERIAL FINDING live app = 6022b75 (not 3b30a0f); AWAITING OWNER+CHATGPT

**STATUS (2026-10-26):** READ-ONLY release alignment of backup fix `268c637` vs current main + deployed prod. Evidence: `docs/SCA-OPTC-BACKUP-FIX-268C637-RELEASE-ALIGNMENT.md`. Nothing implemented/cherry-picked/merged/deployed/restored/migrated/restarted; no prod config change.
- **⚠️ MATERIAL FINDING — "prod = 3b30a0f" is STALE.** Production `kr-app` bind-mounts `/opt/sca-platform/app` → `/var/www/html` **rw** (live docroot); working tree = `main 6022b75`, CLEAN; spot-check of 8 post-3b30a0f UX-Phase-1 files (63177b1) all match 6022b75, differ from 3b30a0f ⇒ **LIVE APP CODE IS 6022b75, not 3b30a0f.** The 3b30a0f/migr138 figure is a stale deploy-baseline label. DB-migration axis separate (backup fix has NO migration).
- **[1] SHAs:** impl origin/main = local main = working-tree HEAD = `6022b75` (clean); branch (local==origin) = `268c637`; gov main `07caa1c`.
- **[8] Ancestry:** linear `3b30a0f`→pilot-docs→rg8→QR-reason(139)→auth/cert→UX-P1(73b6c22)→backup-staging(ee3b014/6022b75). `merge-base(main,branch)=6022b75` ⇒ branch sits DIRECTLY on current main ⇒ diff-vs-main == diff-vs-original-baseline (identical 5 files, +629/−27).
- **[2,3,4] Isolation:** DocumentService.php + lib-docsnapshot.sh + BackupDocumentAtomicityTest byte-IDENTICAL at 3b30a0f & 6022b75 → apply to either; backup-run.sh (24+/1-) + backup-verify-restore.sh (7+/0-) differ ONLY by already-merged/already-live staging fix ee3b014 (ancestor) → NO conflict. NO migration/composer/config/bootstrap. Only 5 files; NO unexpected app change. **Conflicts: NONE.**
- **[5] Standalone:** because live app already = 6022b75, advancing to merged backup fix introduces ONLY the 5-file delta (NO UX-P1/auth-cert/QR-reason drag — already live). Deploy surfaces: DocumentService.php live via bind-mount on working-tree advance + **opcache/PHP reload**; 3 host scripts for next cron. Deploy together.
- **[6] Pre-deploy:** restore-proof current `.gpg` via `backup-verify-restore.sh selftest`+`verify`→disposable DB (guard refuses sca_krayin) BEFORE stricter verify goes live (clears R1). Separately authorized.
- **[7] Preserved:** cron 03:17 UTC unchanged; retention 14d/min7 byte-identical (only `.part` cleanup added, no artifact deleted); live DB untouched.
- **GO/NO-GO:** isolability/standalone/preservation = **GO**; deploy execution = **CONDITIONAL/NO-GO** until (a) restore-proof PASSES, (b) owner reconciles stale 3b30a0f label + accepts opcache reload, (c) owner authorizes.

**STOP — read-only alignment delivered for owner + ChatGPT. No implement/cherry-pick/merge/deploy/restore/migrate/restart/config change.**

---

# (PRIOR) SCA — BACKUP FIX 268c637 FINAL VERIFICATION GATE: PASS (11/11 synthetic verify); recommend MERGE+deploy, gate on restore-proof; AWAITING CHATGPT

**STATUS (2026-10-26):** Non-destructive FINAL verification gate (tasks 1–8) on backup doc-consistency fix `268c637` vs main `6022b75`. Evidence: `docs/SCA-OPTC-BACKUP-FIX-268C637-FINAL-GATE.md`. Nothing merged/deployed; no prod backup/restore, no DB test/migration, no config/restart/activation; prod untouched (app 3b30a0f/migr138, DB sca_krayin).
- **[1] Realistic dump formats — `verify_db_document_refs` 11/11 synthetic fixtures PASS** (A zero-ref, B multi-row extended, C one-per-insert, D escaped values, E traversal→5, F missing→6, G corrupt→8, H NULL/unquoted path count-mismatch→5, I mixed disks, J generated, K missing-among-many→6). No DB touched (offline gzipped-dump fixtures).
- **[2] No silent omission PASS:** `localcount==pathcount` guard → mismatch fails closed (H); missing doc among many caught (K); PIPESTATUS checks → "no refs" can't disguise a read error.
- **[3] Syntax/self-tests PASS:** `bash -n` clean on backup-run.sh / lib-docsnapshot.sh / backup-verify-restore.sh; 11-fixture run = synthetic self-test. DB-touching selftest/verify deferred to Task 6 (separately authorized).
- **[4] Atomic publication PASS:** fail-closed put/move (delete temp, throw); attach/generated use unique random final names (no same-path concurrency); only `restoreGeneratedMedia` has a shared `.part` (fixed recorded path) — rare, admin-serialized, idempotent canonical bytes → benign; FLAGGED minor hardening (`.part.<rand>`), not a blocker.
- **[5] Retention unchanged PASS:** only `rm -f "${OUT}.part"` added; mapfile/RETAIN_DAYS(14)/RETAIN_MIN(7) loop byte-identical to main; no existing artifact deleted.
- **[6] Restore-proof PREPARED** (selftest + `verify <artifact>` → disposable DB, guard_target refuses live; capture counts/refs; drop) — separately authorized, not run.
- **[7] Rollback PREPARED:** code-only → `git revert`/checkout 3 scripts to pre-268c637; NO DB rollback; DocumentService change forward-safe (may stay); revert-forward only, never reset shared main.
- **[8] Recommendation: MERGE 268c637→main (code-only) → deploy app+scripts together → gate on Task-6 restore-proof vs current prod data FIRST (R1).** Independent of Option C + 139/140 (zero overlap, no migration). Closes B5; off-host B1–B4 + B6 remain. One HARNESS (not product) correction: `$'…'` quote-escaping bug in first fixture builder → rebuilt with double-quoted SQL → 11/11.

**STOP — final verification (PASS) delivered for independent ChatGPT review. No merge/deploy/backup/restore/config/migration/restart/activation.**

---

# (PRIOR) SCA — BACKUP FIX 268c637 READ-ONLY VERIFICATION: PASS, releasable independently; recommend MERGE+deploy (owner); AWAITING CHATGPT

**STATUS (2026-10-26):** READ-ONLY diff review of backup document-consistency fix `268c637` vs main `6022b75`. Evidence: `docs/SCA-OPTC-BACKUP-FIX-268C637-VERIFICATION.md`. Nothing merged/deployed; no backup/restore/config/rclone/credential/migration/restart/activation; prod untouched.
- **Diff:** branch sits directly on `6022b75` (merge-base=6022b75); 6 commits; **5 files, +629/−27**: `DocumentService.php` (app, +50), new `BackupDocumentAtomicityTest`, `backup-run.sh`, `backup-verify-restore.sh`, new `lib-docsnapshot.sh`. **NO migration/schema/composer/config/bootstrap change; retention unchanged.**
- **[2] app change** = narrow/intended ONLY: document writes (attach/generated/restore) publish via `.part`+`Storage::move` (rename, local same-fs) fail-closed; final path layout/DB rows/reads/ACL/Option-C logic unchanged.
- **[3] PASS:** atomic publication (`publishAtomically` temp→rename, fail-closed); snapshot consistency (`snapshot_documents` non-.part only, enumeration + cp fail-closed incl source-vanished, .part-leak check, symlinks excluded); fail-closed verify (`verify_db_document_refs`: corrupt-dump/read-error/non-canonical/traversal/missing-ref all fail closed; traversal-safe canonical grammar; 0 refs⇒pass).
- **[5] independent:** disjoint files from Option C; no migration → 139/140 untouched; mergeable standalone either order.
- **[4] risks:** R1 new fail-closed verify could reject a backup if existing prod data has a non-canonical path/missing doc → run restore-proof FIRST; R2 `.part` orphans harmless; R3 rename assumes local disk; R4 app deploy (no restart).
- **[6] recommendation:** MERGE 268c637→main (code-only) → deploy app+scripts together → gate on `backup-verify-restore.sh selftest`+`verify` (disposable DB, separately authorized) → closes backup blocker B5; off-host (B1-B4)+restore-from-offhost (B6) remain separate.

**STOP — read-only verification (PASS) delivered for owner + ChatGPT. No merge/deploy/backup/config/migration/restart/activation.**

---

# (PRIOR) SCA-OPTC — READ-ONLY BACKUP/RELEASE-SAFETY PREFLIGHT DELIVERED; backup/DR NO-GO; AWAITING OWNER + CHATGPT

**STATUS (2026-10-26):** READ-ONLY backup & release-safety preflight. Evidence: `docs/SCA-OPTC-BACKUP-RELEASE-SAFETY-PREFLIGHT.md`. No backup/restore run, no DB test, no config/merge/deploy/migrate/restart/activation; `main 6022b75`+`sca_krayin`+139/140 untouched.
- **On-host nightly backup HEALTHY (corrects prior "not installed" note):** `/etc/cron.d/sca-backup` INSTALLED; `secrets/backup.key` present; daily 03:17 UTC; today `20261026T021703Z OK 4.3G` (db=sca_krayin, docs=4605MB); GPG AES-256; disk 322G free; retention 14d/min7. restore tool `backup-verify-restore.sh` (verify/selftest/offsite-selftest) exists.
- **Blockers to a VERIFIED OFF-HOST backup:** B1 `SCA_BACKUP_REMOTE` unset (every run OFFSITE_DEFERRED, local-only→not durable); B2 no uploader (rclone AND aws absent); B3 no remote creds/config; B4 recovery key NOT escrowed — `secrets/backup.key`+`app/.env`APP_KEY co-located with backups on the single host; B5 doc-consistency fix `268c637` UNMERGED (running backup lacks publishAtomically/snapshot_documents/verify_db_document_refs → deletion-window race); B6 no recent restore-proof vs a real artifact.
- **Smallest plan:** install rclone + Hetzner Storage Box sftp remote → set SCA_OFFSITE_UPLOADER=rclone + SCA_BACKUP_REMOTE; escrow backup.key+APP_KEY SEPARATELY; merge+deploy 268c637; run `backup-verify-restore.sh verify` + restore-FROM-off-host (disposable DB, separately authorized). Owner decisions: provider/account/creds + escrow location + 268c637 merge.
- **GO/NO-GO:** on-host nightly PASS; doc-consistency BLOCKED (268c637); restore-proof NO-GO; off-host copy BLOCKED; key escrow BLOCKED; restore-from-off-host NO-GO → **overall backup/DR NO-GO.**
- **Recorded unresolved test concerns:** rate-limit ×2 (env, both runs) + QrPrintLabelTest::ql3 QR-decoder flake (unconfirmed, not re-run). Option C forward-recovery preserved; 139/140 untouched.

**STOP — read-only assessment delivered for owner + ChatGPT. No create/restore backup, DB test, config change, or release action.**

---

# (PRIOR) SCA-OPTC — AUTHORIZED FULL REGRESSION + BASELINE EXECUTED (post-remediation); NO OPTION-C REGRESSION; AWAITING CHATGPT REVIEW

**STATUS (2026-10-26):** Owner-authorized full candidate suite + clean `6022b75` baseline executed on separate per-run disposable DBs. **No genuine Option-C application regression.** Evidence: `docs/SCA-OPTC-FULL-REGRESSION-EVIDENCE-2.md`. Not merged/deployed; `main 6022b75`+`sca_krayin`+139/140 untouched (loopback 302; migrations 27/140 unchanged).
- **Candidate `0f41e2e`** on unique `sca_optcfull_test_cb83eb4a` (effective-conn verified x2, admin-seed verified id=1 active all-perm): **3 failed / 0 skipped / 7595 assertions**. **Baseline `6022b75`** on fresh exclusive `sca_domain_test`, EQUIVALENT harness (same APP_URL/file-cache/admin-seed/vendor): **8 failed / 0 skipped / 7507 assertions**.
- **Diff:** SHARED 2 = `AuthenticationHardeningTest` rate-limit ×2 (throttle doesn't trip in harness even w/ file-cache; env, not Option C, present on baseline). BASELINE-only 6 = candidate **FIXES** them: `d9` (context-aware id assertion) + 5 concurrency (cc1a/cc1b/cc2/ccmr1/ccsc1, per-run parameterization). CANDIDATE-only 1 = `QrPrintLabelTest::ql3` `DECODE_FAILED: checkAndNudgePoints…` = known non-deterministic QR-decoder FLAKE (same class as rg2/rg8); **Option C diff touches NO QR code** → not a regression; NOT re-run (authorization = no additional DB runs); classified w/ evidence, not dismissed.
- **Concurrency/workers (pt 4):** 7 concurrency tests + 3 workers passed on the single per-run DB → bound only to the assigned disposable DB.
- **Cleanup:** both disposable DBs dropped; only `sca_krayin` remains. **Prod unchanged.**
- The admin-seed/APP_URL/id-assertion remediation resolved the prior candidate failures (AuthenticationTest×2/HelpTest/h8/h7/d9); rate-limit remains an env limitation (both runs); ql3 is a flake.

**STOP — full-regression + baseline evidence delivered for independent ChatGPT review. No merge/deploy/migrate/restart/activation. Release still gated on backup/DR + ops (release-readiness audit); candidate UNMERGED.**

---

# (PRIOR) SCA-OPTC — FULL-REGRESSION PREFLIGHT PASSED; HOLDING FOR EXPLICIT OWNER AUTH TO RUN FULL + BASELINE

**STATUS (2026-10-26):** Full-regression gate received "subject to explicit owner authorization" + "Do not execute full or baseline database tests without explicit owner authorization" → read-only preflight done; **NOT executed. Holding for the explicit go** (same pattern as the earlier full-regression gate). No worktree left; `main 6022b75`+`sca_krayin`+139/140 untouched.
- **Preflight PASS (read-only):** candidate SHA `0f41e2e` in an isolated non-mounted worktree; kr-mariadb mariadb:10.11.18 on sca_internal; only `sca_krayin` present (no disposable DB to collide/delete); prod healthy (6022b75, loopback 302, migrations max_batch=27/total=140); runner create-not-drop + reject sca_krayin/sca_domain_test intact.
- **On explicit authorization, execute ONLY:** `scripts/run-optc-tests.sh full` (own unique `sca_optcfull_test_<rand>`; captures failures/warnings/skips; concurrency workers + secondary connections isolated to that DB) → then a clean `6022b75` baseline via a manual invocation on a **freshly-created, confirmed-absent, exclusively-owned** `sca_domain_test` (never overwrite an existing DB) → diff, separating harness-config differences from real app regressions → confirm cleanup + `sca_krayin` unchanged → record in gov. Build dev vendor (composer install, no DB) at run time. Fail closed on any isolation check.
- **Prior authorized result (accepted):** selftest 65/0; focused 68/333/0; assert 60/182/0 (h7+d9 pass); both disposable DBs cleaned (gov `ff8dd7b`, `docs/SCA-OPTC-FOCUSED-ASSERT-TEST-EVIDENCE.md`).

**STOP — preflight delivered; awaiting the owner's EXPLICIT authorization to run the full suite + baseline. No merge/deploy/migrate/restart/activation.**

---

# (PRIOR) SCA-OPTC — AUTHORIZED FOCUSED + ASSERT TESTS EXECUTED + PASSED; AWAITING CHATGPT REVIEW (full/baseline still unauthorized)

**STATUS (2026-10-26):** Owner-authorized `selftest`+`focused`+`assert` executed on candidate `0f41e2e`; all PASSED. Evidence: `docs/SCA-OPTC-FOCUSED-ASSERT-TEST-EVIDENCE.md`. Not merged/deployed; `main 6022b75`+`sca_krayin`+139/140 untouched.
- **Preflight PASS:** SHA 0f41e2e isolated worktree; kr-mariadb mariadb:10.11 sca_internal; only sca_krayin pre-existed; prod migrations baseline max_batch=27/total=140. selftest **65/0** (no DB).
- **focused** → DB `sca_optc_test_fd9692cc` (own unique; created+verified+dropped): effective-conn verified x2 + XML-clean + admin-seed verified (id=1 active role_id=1 permission_type=all); 141 migrations incl. `2026_10_23_000001`; **68 tests/333 assertions/0 fail**, exit 0.
- **assert** → DB `sca_optcassert_test_b3531254` (SEPARATE unique; created+verified+dropped): **60 tests/182 assertions/0 fail**, exit 0 — **h7 (CollectorHandleTest) + d9 (CertificateDocumentClassificationTest) now PASS** on a real DB.
- **Cleanup:** only `sca_krayin` remains (both disposable DBs dropped). **Prod unchanged:** 6022b75; loopback 302; sca_krayin.migrations max_batch=27/total=140 (identical to baseline).
- **NOT run (unauthorized):** full regression + clean baseline DB tests. No merge/deploy/migrate/restart/activation.

**STOP — focused+assert evidence delivered for independent ChatGPT review. Full suite + baseline remain a separate authorization.**

---

# (PRIOR) SCA-OPTC — SEEDER VERIFICATION HARDENED; AWAITING OWNER DB-EXECUTION AUTH (focused+assert ONLY, then STOP)

**STATUS (2026-10-26):** Minor ChatGPT correction applied — `seed-test-admin.php` now fail-closes (exit 3) unless admin **id=1 EXISTS + is ACTIVE (status=1) + its role EXISTS + role permission_type='all'**. Test harness only (2 files: seed-test-admin.php + runner selftest [14]); no app logic/auth change. All DB safety, id-exposure (context-aware detector), and per-run tmpfs cache isolation PRESERVED. Candidate `5eb8708`→**`0f41e2e`** (pushed). Evidence: bash -n OK; php -l clean; **selftest 65/0**. NO DB test executed; `main 6022b75`+`sca_krayin`+139/140 untouched. Gov evidence: `docs/SCA-OPTC-TEST-AUDIT-CORRECTIONS.md` (+ this entry).
- **NEXT TESTING GATE (owner-stated):** once owner EXPLICITLY authorizes DB execution, run the isolated **focused** + **assert** phases FIRST (`scripts/run-optc-tests.sh focused` then `… assert`). Do NOT run full or baseline in the same authorization. Preflight (SHA/worktree, kr-mariadb identity, create-not-drop, prod/shared excluded, no existing disposable DB deleted) then STOP after reporting test results + DB cleanup + production-isolation evidence. No app change/merge/deploy/migrate/restart/activation.
- **Expected:** focused 68/0; assert = h7 (CollectorHandleTest) + d9 (CertificateDocumentClassificationTest) PASS (admin seed + context-aware id assertions + file cache). Build dev vendor (composer install, no DB) at run time.

**STOP — seeder correction + non-destructive evidence delivered. Awaiting owner EXPLICIT DB-execution authorization for focused+assert only.**

---

# (PRIOR) SCA-OPTC — FINAL TEST-ONLY AUDIT CORRECTIONS APPLIED (context-aware detector + seed verify + cache isolation); AWAITING CHATGPT REVIEW

**STATUS (2026-10-26):** Three ChatGPT audit corrections implemented (test files + runner only; no app logic). **NO focused/assert/full/baseline DB test executed.** Evidence: `docs/SCA-OPTC-TEST-AUDIT-CORRECTIONS.md`. Not merged/deployed; `main 6022b75`+`sca_krayin`+139/140 untouched. Candidate `1361357`→**`5eb8708`** (pushed; 3 files: id_exposure.php, seed-test-admin.php, run-optc-tests.sh).
- **(1) context-aware `sca_detect_id_exposure`:** added (c) numeric JSON id field `"..._id":<id>`/`"id": <id>` and (d) unquoted id attr `id=`/`data-id=`/`item-id=`/`item_id=` (name must be id/…-id/…_id, opt data-); keeps (a) quoted + (b) alpha-route path; still ignores width=/count:/maxlength=/data-count=/grid:/CSS/date/version. Genuine sensitive-string checks unchanged. selftest [13] controls extended (9 positive + 11 negative) → CONTROLS-OK.
- **(2) seed verify:** seed-test-admin.php ALWAYS fail-closes (exit 3) unless `User::find(1)` exists with a valid role (both create + already-present paths). No auth logic changed.
- **(3) cache isolation:** `--tmpfs /var/www/html/storage/framework/cache` → throttle/cache state per-run only, discarded on exit, no leak between runs/worktree; limiter/thresholds unchanged.
- Unchanged: create-not-drop, effective-conn verify, XML validator, cleanup. **selftest 65/0; bash -n OK; php -l clean.**
- **Verification sequence when authorized:** selftest(65/0)→focused(68/0)→assert(h7/d9)→full(expect 0; residuals investigated)→baseline manual re-diff (fresh exclusive sca_domain_test).

**STOP — final test-only corrections + non-destructive evidence for independent ChatGPT review before DB-test authorization. No merge/deploy/migrate/restart/activation.**

---

# (PRIOR) SCA-OPTC — TEST-ONLY REMEDIATION IMPLEMENTED (h7/d9 + harness); NON-DESTRUCTIVE EVIDENCE; AWAITING CHATGPT AUDIT

**STATUS (2026-10-26):** Authorized TEST-ONLY remediation implemented on the candidate branch. **NO focused/full/baseline DB test executed; no app logic changed** (6 files, all under app/tests/ or scripts/). Evidence: `docs/SCA-OPTC-TEST-REMEDIATION-RESULT.md`. Not merged/deployed; `main 6022b75`+`sca_krayin` untouched; 139/140 untouched. Candidate `1df81d5`→**`1361357`** (pushed).
- **§1 h7/d9 (test-only):** new pure DB-free `app/tests/Support/id_exposure.php::sca_detect_id_exposure` (flags id only as a quoted `"<id>"` value OR alpha-route `/<route>/<id>` path; ignores CSS/px/scale/version/slash-date); `TestCase::assertIdNotExposed()`; h7 + d9 use it for numeric PKs; ALL genuine checks ($ref/email/public_ref/catalog/storage_path/checksum/subject_id/qr_token) unchanged.
- **§2 controls:** selftest [13] runs the REAL detector in a `--network none` no-DB container — positives (data-id="id", /items/id/, "collector_id":"id") detected; negatives (max-width:Npx, initial-scale=1, 2026/10/26, v4.2.N, z-index:N}, padding:N 0) pass → CONTROLS-OK.
- **§3 harness (runner env/seed only; NO weakening):** `scripts/seed-test-admin.php` seeds canonical default admin (user id 1; idempotent; disposable-DB-guarded; random pw→actingAs) → AuthenticationTest×2+HelpTest; `CACHE_STORE=file` so the RateLimiter accumulates (limiter/thresholds unchanged) → 2 AuthenticationHardening rate-limit tests; `APP_URL=https://verify.secondchanceauthenticators.com` → h8.
- **§5 isolation preserved:** create-not-drop, verify_effective, XML validator, perRunDbName/sca_is_per_run_db untouched; selftest 63/0.
- **§6 verify plan:** h7/d9 NOT in the 5-file focused set → NEW `assert` runner phase runs them separately. Baseline run stays a manual invocation on a fresh exclusive `sca_domain_test` (never drop an existing DB); comparability explained.
- **Evidence:** bash -n OK; **selftest 63/0** (incl [13] controls + [14] wiring); php -l clean on all 6 files.
- **Verification sequence to run when authorized:** selftest(63/0)→focused(68/0)→assert(h7/d9 pass)→full(expect 0; residuals investigated)→baseline manual re-diff.

**STOP — test-only remediation + non-destructive evidence for independent ChatGPT audit before DB-test authorization. No merge/deploy/migrate/restart/activation; backup/DR + ops readiness are separate workstreams.**

---

# (PRIOR) SCA-OPTC — RELEASE-REMEDIATION PLAN DELIVERED (PLAN ONLY); AWAITING OWNER + CHATGPT APPROVAL

**STATUS (2026-10-22):** NO-GO confirmed; Option C code accepted at `1df81d5`. Minimal non-production remediation **PLAN** delivered: `docs/SCA-OPTC-RELEASE-REMEDIATION-PLAN.md`. **PLAN ONLY — nothing implemented, no tests run, no merge/deploy/migrate/restart/activation; no app-logic change in scope.** `main 6022b75` + `sca_krayin` untouched.
- **§1 assertion fixes (test-only):** `CollectorHandleTest::h7` + `CertificateDocumentClassificationTest::d9` — keep all real-exposure checks ($ref/email/public_ref/path/checksum/subject_id); replace ONLY the bare-numeric-id substring checks with a context-bounded `assertDoesNotMatchRegularExpression` (`[/"'=:>]<id>(?![0-9A-Za-z])`) that still catches id-as-URL/JSON/attr but ignores `220px`.
- **§2 harness (runner env/seed only; NO weakening):** seed canonical Krayin admin (user id 1) post-migrate (`getDefaultAdmin()`=`User::find(1)`); `-e CACHE_STORE=file` so the login throttle actually counts (observe real 429, successful-login test still passes); `-e APP_URL=https://verify.secondchanceauthenticators.com` for h8; isolation safeguards untouched (selftest stays 56/0).
- **§3 verify sequence (when authorized):** selftest 56/0 → focused 68/0 → full (expect 0 after §1+§2) → baseline `6022b75` re-diff; residuals investigated, not dismissed.
- **§4 rollback revised:** generic `migrate:rollback` is batch-scoped → can reach fragile batch 27 (139/140, orphaned 140 down() absent) → unsafe; Option C `down()` DROPS the fulfillment-release attestation (audit loss). Prefer FORWARD recovery / code-only rollback leaving the additive columns; targeted column-drop only if separately authorized + backed up; never touch 139/140.
- **§5 backup checklist:** verified pre-deploy backup + restore-test + off-host copy (Hetzner rclone-sftp) + separate key/APP_KEY escrow + restore-from-offhost evidence (off-host DR = residual BLOCKER).
- **§6 operational gates (distinct):** ACL grant `sca.eyewear.fulfillment.release`; private claim-card out-of-band delivery (no SMTP); live QR-to-claim acceptance.
- **GO/NO-GO checklist G1-G9:** G1 code PASS; G5 migration-plan PASS; G2(verdict)/G3(h7+d9)/G4(backup-DR) NO-GO; G6-G9 DEFERRED. Overall NO-GO until G2-G4 clear + G6-G8 operational.

**STOP — remediation plan delivered for owner + ChatGPT review. No implementation/tests/merge/deploy/migrate/restart/activation.**

---

# (PRIOR) SCA-OPTC — READ-ONLY RELEASE-READINESS AUDIT DELIVERED; VERDICT NO-GO (code ready; release gated on ops/DR); AWAITING OWNER + CHATGPT

**STATUS (2026-10-22):** READ-ONLY release-readiness audit of candidate `1df81d5`. Evidence: `docs/SCA-OPTC-RELEASE-READINESS-AUDIT.md`. No code/merge/deploy/migration/test/restart/activation; `main 6022b75` + `sca_krayin` untouched. **VERDICT: NO-GO for deploy now — the CANDIDATE CODE is accepted/ready (no Option-C regression; focused 68/0), NO-GO is on release-dependency/ops gates.**
- **(1) h7 verified:** bare-numeric-id substring fragility (`Not to contain: 220` vs `max-width:220px`); proposed narrow correction = contextual id check keeping the real-exposure assertions ($ref/email/public_ref/catalog/); NOT applied. Same pattern = `CertificateDocumentClassificationTest::d9` (`Not to contain: 10`, bare cert PK).
- **(2) 7 shared failures classified:** 6 ENVIRONMENT (3 missing-admin-seed `getDefaultAdmin()` null→TypeError: AuthenticationTest×2+HelpTest; 2 throttle/cache rate-limit 429→200; 1 APP_URL-canonical h8) + 1 TEST-FRAGILITY (d9, same as h7). NONE a real app defect. Minimal harness fixes: seed admin; real throttle cache; set APP_URL; narrow d9/h7 assertions → reliable verdict.
- **(3) Migration:** Option C `2026_10_23_000001` (additive/nullable) deploys as a NEW batch via `migrate` up; 139/140 (batch 27) rows untouched; branch lacks the orphaned 140 file → `migrate` up ignores it (no error); rollback of Option C needs only its own down(). Do NOT bundle with any batch-27 rollback. SAFE.
- **(4) Diff scope:** only `app/packages/Sca/*` (15 prod files) + `app/tests/*` (100) + `scripts/*`; nothing outside; no dep/config/bootstrap/phpunit change. ✓
- **(5/6) Checklist:** PASS = Option C code/behavior, diff scope, migration up-safety, rollout order, rollback. BLOCKED = backup/off-host-DR readiness ([[sca-backup-dr-remediation]]); reliable full-suite PASS (needs the 4 harness corrections). DEFERRED = ACL grant for `sca.eyewear.fulfillment.release`; private claim-card delivery (no SMTP, out-of-band); live QR-to-claim acceptance test; h7/d9 assertion hardening; separate 139/140 owner decision.

**STOP — read-only NO-GO assessment delivered for owner + ChatGPT. No code/merge/deploy/migrate/test/restart/activation. Candidate `1df81d5` UNMERGED/undeployed.**

---

# (PRIOR) SCA-OPTC — AUTHORIZED FULL REGRESSION + BASELINE EXECUTED; NO OPTION-C REGRESSION; AWAITING CHATGPT REVIEW

**STATUS (2026-10-22):** Owner-authorized full suite (candidate `1df81d5`) + clean `6022b75` baseline executed on isolated per-run disposable DBs. **No Option-C-attributable regression.** Evidence: `docs/SCA-OPTC-FULL-REGRESSION-EVIDENCE.md`. Not merged/deployed; `main 6022b75` + `sca_krayin` untouched (loopback 302; `sca_krayin.migrations` unchanged max_batch=27/total=140). STILL NO-GO.
- **Candidate** full on unique `sca_optcfull_test_e59e2e91` (verified host-decision + in-container re-verify + XML-override-clean): **8 failed, 0 skipped, 7573 assertions**. **Baseline** `6022b75` on separate fresh `sca_domain_test`: **12 failed, 0 skipped, 7490 assertions**. (The ~1449/1437 "warnings" are pre-existing PHPUnit risky/deprecation warnings on passing tests, both runs.)
- **Diff:** SHARED 7 env/fragility (auth dashboard/logout TypeError, Help, cert-doc d9, email-canonical h8, 2× rate-limit). **BASELINE-only 5 = candidate FIXED them** (CollectorCollection cc1a/cc1b/cc2, MarketReference cc mr1, ServiceCorrection cc sc1 — parameterized concurrency/workers now pass on the per-run DB). **CANDIDATE-only 1 = `CollectorHandleTest::h7`**, investigated: `Not to contain: 220` (bare id vs `max-width:220px` preview CSS); pre-existing numeric-id-substring fragility (also fails isolated on id 1); Option C touches NO collector-handle code; added test rows shift the id → surfaces the coincidence. Tracked separately, out of scope.
- **Secondary/workers (auth pt 3):** the 7 concurrency tests + 3 workers ran+passed on `sca_optcfull_test_e59e2e91` → every secondary connection + worker bound only to the assigned disposable DB.
- **Cleanup:** both disposable DBs dropped; only `sca_krayin` remains. **Prod untouched.**

**STOP — full-regression + baseline evidence delivered for independent ChatGPT review. No merge/deploy/migrate/restart/activation.**

---

# (PRIOR) SCA-OPTC — FULL-REGRESSION PREFLIGHT PASSED; HOLDING FOR EXPLICIT OWNER AUTHORIZATION TO RUN FULL + BASELINE

**STATUS (2026-10-22):** ChatGPT accepted the focused-test evidence (68/333/0). Owner sent the full-regression scope as an AUTHORIZATION REQUEST whose controlling line is "Do not execute full or baseline database tests until the owner explicitly authorizes." → Read-only preflight done; **NOT executed. Holding for explicit owner go.** No worktree left behind; `main 6022b75` + `sca_krayin` untouched (loopback 302; only `sca_krayin` present).
- **Preflight (read-only, passed):** candidate SHA `1df81d5` in an isolated non-mounted worktree; `kr-mariadb` = mariadb:10.11.18 (id b36c8e36e041) on `sca_internal`, root creds verified; only `sca_krayin` exists (no `sca_optc*_test_*` → the full-run unique DB cannot collide with or delete an existing disposable DB); runner full phase uses `sca_optcfull_test_<rand>` with CREATE-not-drop + register-after-create + reject sca_krayin/sca_domain_test; `selftest` 56/0.
- **On explicit authorization, execute ONLY:** `scripts/run-optc-tests.sh full` (per-run unique DB; exercises the parameterized concurrency tests + secondary connections + spawned workers), then a clean `6022b75` baseline run in the same isolated harness on an INDEPENDENT disposable DB; diff failing sets; investigate any candidate-only failure with evidence (do not dismiss); confirm cleanup (no residual disposable DBs); record in governance. Prerequisite at run time: build the dev vendor in the worktree (composer install; no DB). Fail closed on any isolation check.

**STOP — preflight delivered; awaiting the owner's EXPLICIT authorization to run the full suite + baseline. No merge/deploy/migrate/restart/activation.**

---

# (PRIOR) SCA-OPTC — AUTHORIZED FOCUSED TEST EXECUTED + PASSED; AWAITING CHATGPT REVIEW BEFORE FULL-SUITE AUTHORIZATION

**STATUS (2026-10-22):** Owner-authorized isolated focused run executed (only `scripts/run-optc-tests.sh focused`) on candidate `1df81d5`. **PASSED: 68 tests / 333 assertions / 0 failures.** Full suite NOT run. Evidence: `docs/SCA-OPTC-FOCUSED-TEST-EVIDENCE.md`. Not merged/deployed; `main 6022b75` + `sca_krayin` untouched (prod `migrations` unchanged max_batch=27/total=140; loopback 302).
- **Preflight (all passed):** SHA 1df81d5 in isolated worktree; only `sca_krayin` pre-existed (no disposable DB to collide/delete); `kr-mariadb` mariadb:10.11 on sca_internal, root creds verified; assert_disposable + verify_effective reject sca_krayin AND sca_domain_test; create-not-drop + register-after-create (no existing DB deleted); focused set spawns NO workers; selftest 56/0.
- **Run:** disposable DB `sca_optc_test_8e70d5c6` (created+dropped). Effective-conn verified (host decision) + XML override check (`no DB override`) + in-container re-verify, all `db=sca_optc_test_8e70d5c6 host=kr-mariadb live=sca_optc_test_8e70d5c6`. Migrations applied incl. `2026_10_23_000001_add_fulfillment_release … DONE`. **phpunit 68/333/0, exit 0.** Cleanup: only `sca_krayin` remains (disposable dropped).
- **NEXT (needs explicit owner authorization):** full suite `scripts/run-optc-tests.sh full` on a per-run unique DB (exercises the parameterized concurrency tests + workers) + clean `6022b75` baseline re-diff (F3 reproducible confirmation; the pre-existing `CollectorHandleTest::h7` id-substring fragility).

**STOP — focused-test evidence delivered for independent ChatGPT review. Do NOT run the full suite until authorized. No merge/deploy/migrate/restart/activation.**

---

# (PRIOR) SCA-OPTC — COMPLETE TEST-SAFETY PREP (XML-AWARE OVERRIDE VALIDATOR + IN-CONTAINER RE-VERIFY + FULL PER-RUN PARAMETERIZATION); AWAITING FINAL CHATGPT REVIEW

**STATUS (2026-10-22):** Final review of `254d876` accepted the DB lifecycle/cleanup/effective-check in principle, with a complete-preparation list before DB tests are authorized. Done; pushed. **NO focused/full DB test executed; no Option C app logic changed** (all files under app/tests/ or scripts/). Evidence: `docs/SCA-OPTC-REMEDIATION-RESULT-4.md`. Not merged/deployed; `main 6022b75` + `sca_krayin` untouched; candidate `feat/sca-optc-secure-claim` `254d876`→**`1df81d5`** (1 commit, 16 files).
- **(1) XML-aware override validator:** new `scripts/assert-no-db-override.php` (DOMDocument) rejects any `DB_*`/`DATABASE_URL` `<env>/<server>/<const>/<var>` regardless of quote style/attr order/multiline; unparseable→fail closed. Replaces the text regex; invoked in-container before migrate.
- **(2) In-container re-verify:** the migrate/test container re-boots the migrator's kernel and asserts effective host==DB_HOST==kr-mariadb, schema==live==DB_DATABASE, not sca_krayin/sca_domain_test — immediately before `artisan migrate` (plus the host-side gather+decide).
- **(3-5) Parameterization:** 7 concurrency tests guard via new `TestCase::perRunDbName()` (per-run unique only; rejects sca_krayin AND sca_domain_test) + assert each secondary connection == per-run default DB; 3 worker-spawning tests pass exact per-run DB + host/port/creds; 3 workers bind `database` from env DB_DATABASE and fail closed via shared pure `app/tests/Support/per_run_db_guard.php::sca_is_per_run_db`. EyewearRegistry/ProvenanceDomain `$db`-guards → guardDisposableDb(); ProvenanceDomain info_schema query → effective per-run schema (bound param). No code-literal sca_domain_test TARGET remains (only reject-guards).
- **(6) Non-destructive demos:** selftest [10] XML detection (quote/order/multiline fixtures + real phpunit.xml) + [11] per-run rule (accept per-run; reject sca_krayin/sca_domain_test/empty) via php in `--network none` no-DB/no-live container; [12] static wiring. **selftest 56/0; bash -n OK; php -l clean on all 16 files.**
- **Unresolved (needs authorized DB run):** full correctness of the parameterized concurrency/worker tests on a per-run unique DB; F3 reproducible re-diff vs baseline (the pre-existing `CollectorHandleTest::h7` id-substring fragility, documented not dismissed).

**STOP — complete test-safety prep + non-destructive evidence available for independent ChatGPT review before DB-test authorization. No merge/deploy/migrate/restart/activate.**

---

# (PRIOR) SCA-OPTC — FINAL RUNNER SAFETY (EFFECTIVE HOST MATCH + PHPUNIT-OVERRIDE REFUSAL) + GUARD-CONVERSION PREP; AWAITING FINAL CHATGPT REVIEW

**STATUS (2026-10-22):** Independent review of `5766f4e` accepted the lifecycle/ownership/cleanup/behavioral selftests at source level, with one final runner correction + a separate test-only guard-conversion prep. Done; pushed. **NO focused/full DB test executed.** Evidence: `docs/SCA-OPTC-REMEDIATION-RESULT-3.md`. Not merged/deployed; `main 6022b75` + `sca_krayin` untouched; candidate `feat/sca-optc-secure-claim` `5766f4e`→**`254d876`** (2 commits: runner `d1984aa`, test-only guard conversion `254d876`).
- **Runner `d1984aa` (runner only, +110/−51):** F1.1 effective HOST match — run_suite now GATHERS the effective Laravel connection (real kernel boot, config cache removed) = name+host+live SELECT DATABASE(), then DECIDES on the host via pure `verify_effective()` requiring effective host==kr-mariadb AND effective/live schema==the uniquely-created per-run DB, fail-closed BEFORE a second migrate/test container. F1.2 `assert_no_phpunit_db_override()` fails closed on any `DB_*` `<env>/<server>` in phpunit.xml/.dist (candidate's is clean). F1.3 selftest adds behavioral host/db/forbidden/live-mismatch coverage + phpunit-override fixtures. F1.4 all prior safeguards preserved. **selftest 46/0, no DB/container; `bash -n` OK.**
- **Guard conversion `254d876` (TEST-ONLY, 81 files, +81/−243, NO app logic):** mechanical 3-line inline `sca_domain_test` guard → `$this->guardDisposableDb();` (1 replacement/file; byte-identical). EXCLUDED (non-mechanical follow-up — hardcode sca_domain_test via named 2nd connections / worker DB_DATABASE / config()): 7 concurrency tests + 2 `$db`-variant files (EyewearRegistry, ProvenanceDomain) + 3 `tests/Support/*_worker.php`. Validated: exactly 1 block/file; no canonical guard outside the 7 excluded; `php -l` all 81 (container `--network none`, ro mount, no DB).
- **Deferred (still unauthorized):** focused+full on per-run unique DBs + baseline re-diff (fresh logs); non-mechanical parameterization of the 7 concurrency tests + 2 $db files + 3 workers to the per-run DB.

**STOP — final runner + non-destructive safety evidence + guard-conversion prep available for independent ChatGPT review before DB-test authorization. No merge/deploy/migrate/restart/activate.**

---

# (PRIOR) SCA-OPTC — RE-AUDIT REMEDIATION (EFFECTIVE-LARAVEL VERIFY + BEHAVIORAL SELFTESTS); AWAITING CHATGPT REVIEW

**STATUS (2026-10-22):** ChatGPT re-audit of `54c848e` → 3 findings (runner/self-test only; DB tests still NOT authorized). Addressed; revised runner + non-destructive evidence pushed. **NO focused/full DB test executed.** Evidence: `docs/SCA-OPTC-REMEDIATION-RESULT-2.md` + updated `docs/SCA-OPTC-REGRESSION-EVIDENCE.md`. Not merged/deployed; `main 6022b75` + `sca_krayin` untouched; candidate `feat/sca-optc-secure-claim` `54c848e`→**`5766f4e`** (pushed; 1 file, +91/−22, runner only, no app logic).
- **F1 (effective Laravel conn):** in-container pre-migrate now `rm -f bootstrap/cache/config.php` (kill cached redirect; worktree only, live app never mounted) → boots the SAME kernel as the migrator (`bootstrap/app.php` + `Console\Kernel::bootstrap()`) → reads EFFECTIVE resolved DB name+host → live `SELECT DATABASE()` via that Laravel connection → requires EXACT == uniquely-created per-run DB, fail-closed (exit 3) before migrate; forbidden effective name (sca_krayin/sca_domain_test) also aborts.
- **F2 (behavioral selftests):** `selftest` now runs REAL provision()/drop_db()/cleanup() vs a MOCKED db_sql (no docker/mysql/DB) proving: collision→abort+NO DROP+not registered; success→registers exactly created DB; cleanup drops only created; failed drop→fatal exit 4; prior test-failure status preserved over cleanup failure; forbidden name aborts before any DB op. Static audits retained, not sole evidence.
- **F3:** regression-evidence doc keeps the 13-vs-12 comparison, reworded to NOT declare full PASS / NOT conclusively dismiss — status "failures present; no Option-C attribution demonstrated, pending reproducible confirmation" on the remediated runner once DB runs authorized.
- **Evidence:** `selftest` → **35 passed / 0 failed, no DB/container touched**; `bash -n` OK.
- **Deferred (still unauthorized):** focused+full on per-run unique DBs + baseline re-diff w/ fresh logs; migrate remaining ~93 inline guards→`guardDisposableDb()`.

**STOP — revised runner + non-destructive safety evidence available for independent ChatGPT review. DO NOT run focused/full DB tests until this runner is independently reviewed. No merge/deploy/migrate/restart/activate.**

---

# (PRIOR) SCA-OPTC — REVISED RUNNER + NON-DESTRUCTIVE SAFETY EVIDENCE DELIVERED; AWAITING CHATGPT AUDIT

**STATUS (2026-10-22):** ChatGPT approved the remediation plan with a required F1 DB-isolation correction (ownership by creation). The revised runner + its non-destructive safety self-tests are implemented and pushed. **NO focused/full database test executed** (per boundary). Evidence: `docs/SCA-OPTC-REMEDIATION-RESULT.md` + `docs/SCA-OPTC-REGRESSION-EVIDENCE.md`. Not merged/deployed; `main 6022b75` + `sca_krayin` untouched; candidate branch `feat/sca-optc-secure-claim` advanced `7b41e8d`→**`54c848e`** (pushed).
- **F1 (ownership by creation):** runner CREATEs (no `IF NOT EXISTS`, abort on collision), never DROPs before CREATE, registers for cleanup only after successful create (drops only what it created), uses per-run unique DBs both phases (`sca_optc_test_<rand>` / `sca_optcfull_test_<rand>`), NEVER creates/targets/drops `sca_domain_test` or `sca_krayin`, and verifies the actual in-container connection schema/host before migrate.
- **F2 (fatal cleanup):** EXIT trap captures incoming `$?`; `drop_db` returns real status; failed drop = loud + fatal (exit 4), but preserves a prior test-failure status.
- **F4 (semantics):** docs-only — release documented as STAFF AUTHORIZATION attestation, not independent purchase/payment verification (service/controller/migration/confirm-view). No behaviour change.
- **F3 (evidence):** `docs/SCA-OPTC-REGRESSION-EVIDENCE.md` — full candidate-13 vs baseline-12 failing-test diff + classification (all env/fragility; sole delta `CollectorHandleTest::h7` pre-existing id-substring fragility). NOT declared full PASS.
- **Non-destructive evidence:** `scripts/run-optc-tests.sh selftest` → **26 passed / 0 failed, no DB or container touched**; `bash -n` OK.
- **Deferred to the authorized DB-run task:** migrate the remaining ~93 SCA inline `sca_domain_test` setUp guards → `guardDisposableDb()`; then run focused + full on per-run unique DBs + baseline re-diff.

**STOP — revised runner + non-destructive safety evidence available for independent ChatGPT audit. DO NOT run focused/full DB tests until the DB-isolation safeguards are independently reviewed. No merge/deploy/migrate/restart/activate.**

---

# (PRIOR) SCA-OPTC — AUDIT REMEDIATION PLAN DELIVERED; AWAITING OWNER + CHATGPT APPROVAL (PLAN ONLY)

**STATUS (2026-10-22):** ChatGPT audit of candidate `7b41e8d` returned 4 findings (CHANGES REQUIRED). A minimal remediation **plan** + proposed test commands is delivered: `docs/SCA-OPTC-REMEDIATION-PLAN.md`. **PLAN ONLY — nothing implemented, no code changed, no test run executed.** Per the restriction, **no further destructive test run** until the revised DB-isolation safeguards are independently reviewed (the plan adds a no-DB `selftest` for that review first). Candidate branch `feat/sca-optc-secure-claim @ 7b41e8d` unchanged; `main 6022b75` + `sca_krayin` untouched.
- **F1 (runner drops shared `sca_domain_test`):** runner → per-run unique DB for BOTH phases (`sca_optc_test_<rand>` + `sca_optcfull_test_<rand>`), remove `sca_domain_test` entirely; migrate the ~98 SCA inline `!== 'sca_domain_test'` setUp guards → existing fail-closed `guardDisposableDb()` (accepts per-run names, still hard-rejects `sca_krayin`). Rejected the advisory-lock-on-shared-DB alt (not "uniquely named").
- **F2 (cleanup can exit 0 on drop failure):** EXIT trap captures incoming `$?`, `drop_db` returns real status; drop failure → loud + fatal (exit 4) when tests passed, preserves prior non-zero test status.
- **F3 (13 vs 12 failures):** evidence doc with full failing-test diff + per-test classification (all pre-existing env/fragility; the sole delta `CollectorHandleTest::h7` is a numeric-id-substring fragility, also fails in isolation on id `1`, no collector-handle code touched). Verdict wording: "no Option-C-attributable failure" — NOT "full PASS".
- **F4 (fulfillment semantics):** docs-only — state release = STAFF AUTHORIZATION attestation (sold/ready-to-ship), NOT independent purchase/payment verification (no Shopify/Stripe check). Manual design preserved, no behavior change.

**STOP — awaiting owner + ChatGPT approval of the plan. On approval: implement on the candidate branch in a fresh non-mounted worktree, starting with the no-DB `selftest` for independent safeguard review BEFORE any DB-touching run.**

---

# (PRIOR) SCA-OPTC — SECURE QR PASSPORT CLAIMING: CANDIDATE IMPLEMENTED + PUSHED; AWAITING CHATGPT AUDIT

**STATUS (2026-10-21):** Option C implemented as a candidate and pushed. Evidence: `docs/SCA-OPTC-SECURE-CLAIM-CANDIDATE-RESULT.md`. **NOT merged / NOT deployed / NO production migration / NO restart / NO integration activation.** `main 6022b75` + `sca_krayin` untouched; production never used as a test target.
- **Impl branch `feat/sca-optc-secure-claim`, head `7b41e8d38b7f34b3186925120737b4463a81baeb`** (on `6022b75`; pushed, UNMERGED). 22 files, +978/−279. **ZERO dependency changes**; one additive nullable migration `2026_10_23_000001` (`fulfillment_released_at`/`by`; no backfill/CHECK/index).
- **Fix:** public-QR-token ownership claiming PERMANENTLY disabled (no flag) — `ClaimWorkflow::claim()` fails closed (owned→ALREADY_OWNED privacy-safe, else NOT_ELIGIBLE; `already_yours` idempotent kept); `preview()`→`claim_via_link`; retired Shopify sale-link path left inert. All ownership flows ONLY through the private single-use grant.
- **Grant gate:** `sce_presale` grantable ONLY after an explicit staff **fulfillment release** (new append-once service/controller/FormRequest/view + dedicated ACL `sca.eyewear.fulfillment.release` + typed-RELEASE confirm + session-derived audited actor), on top of certified/unowned/non-adverse. `external_intake` unchanged. `claim_source='external_intake'` kept for all grant redemptions (labels the PATH, not intake type; documented). Import never auto-releases/grants.
- **Tests (ephemeral container; prod never a target; runner `scripts/run-optc-tests.sh`, drops DBs on exit):** FOCUSED pass on an isolated uniquely-named `sca_optc_test_<rand>` → **68/68, 333 assertions, 0 fail**; migration DONE. FULL suite on fresh `sca_domain_test` → 13 env/fragility failures, verified vs a clean `6022b75` baseline run (12 failures) — identical set except `CollectorHandleTest::h7` (pre-existing numeric-id-substring fragility; also fails in isolation on id `1`; Option C touches no collector-handle code). NONE in Option C's blast radius.
- **Deploy note (if later approved):** app code + migration deploy together (gate reads the new column).

**STOP — awaiting independent ChatGPT audit of `7b41e8d`. Do not merge/deploy/migrate/restart/activate. Prod-migration-incident (139/140), Phase-2 candidate `0ba09fa`, and off-host DR remain separate open gates; production NO-GO.**

---

# (PRIOR) SCA — PROD MIGRATION INCIDENT: READ-ONLY RECONCILIATION DELIVERED; AWAITING CHATGPT REVIEW + OWNER DECISION

**STATUS (2026-10-21T15:32:34Z):** Independent READ-ONLY reconciliation of the 139/140 production-migration incident delivered → `docs/SCA-PHASE2-PROD-MIGRATION-INCIDENT-RECONCILIATION.md`. **Evidence collection only — no migrate/rollback/fresh, no DDL/DML, no prod data/schema change, no restart/checkout/deploy, no backup/restore, no merge/deploy, no Stripe/SMTP/pilot.** Only SELECT/information_schema queries against live `sca_krayin` (modify nothing); root pw never printed; only COUNTs/schema metadata (no values/PII/secrets).
- **Independently verified (fresh read-only, 15:32:34Z):** migrations `139=2026_10_20_000001_add_reason_to_sca_qr_lifecycle_events` + `140=2026_10_21_000001_add_collector_activity_last_seen`, BOTH batch 27; `138=…market_reference_events`=batch 26 (pre-incident HEAD); MAX(batch)=27, total=140, batch 27 = exactly these 2. Schema objects EXIST: `reason` varchar(500) NULL + CHECK `chk_qr_reason_only_on_reissue (reason IS NULL OR event_type='reissued_from')`; `activity_last_seen_at` timestamp NULL; indexes `idx_oe_collector_effective`, `idx_tr_from_collector`. Populated values: reason 0/3, activity_last_seen_at 0/4 → **zero data in the new columns**. Candidate 141 NOT deployed (0 source-watermark cols, 0 migration row).
- **Impl repo:** 139 present on `main`; **140 ABSENT on main (candidate-only/orphaned)**; 141 candidate-only.
- **Operator-reported / NOT DB-verifiable:** the cause (accidental `artisan migrate --force` on the default `sca_krayin` conn) and its exact time/actor — the migrations table has no timestamp/actor column.
- **Inference (NOT executed):** rollback of batch 27 drops the 2 cols + 2 indexes with ZERO data loss, BUT must run with a tree containing BOTH 139+140 `down()` (main lacks the 140 file → rollback from main would fail on the missing class).
- **No discrepancy** vs the prior assessment (gov `3cdda3c`); all its read-only claims re-verified.
- **Disposition (owner decision pending):** (a) LEAVE additive schema — a future authorized deploy sees 139/140 already recorded (batch 27) and SKIPS them; preferred, needs nothing now. (b) owner-authorized `migrate:rollback` batch 27→138 (clean, zero data loss) with the candidate tree checked out. Prod `main 6022b75` is forward-compatible (ignores 140 col/indexes; CHECK satisfied). Release remains NO-GO.

**STOP — read-only only; production untouched. Awaiting ChatGPT review + owner's 139/140 decision. Phase 2 candidate `0ba09fa` + off-host DR remain separate open gates.**

---

# (PRIOR) SCA UX PHASE 2 — TEST-RUNNER HARDENED (VALIDATED DB TARGETS + VISIBLE CLEANUP); AWAITING CHATGPT REVIEW

**STATUS (2026-10-21):** Re-audit of `fbbfdeb` (CHANGES REQUIRED on the runner's DB-target safeguards) remediated. Evidence: `docs/SCA-STAFF-COLLECTOR-UX-PHASE2-TEST-RUNNER-HARDENING-RESULT.md`. **NOT merged / NOT deployed.** No prod migrate/rollback/write, live-tree checkout, restart, backup/restore, Stripe/mail, pilot; production never used as a test target. `main 6022b75` + migr 139/140 untouched.
- **New candidate branch `fix/sca-ux-phase2-test-runner-2`, head `0ba09faf9af1c6c56998b991912eeab40d9a10de`** (on `fbbfdeb`; pushed, UNMERGED). 1 file: `scripts/run-sca-feature-tests.sh` (+159/−49).
- **Finding 1 (target override→prod) FIXED:** `validate_targets()` runs BEFORE any docker/mysql op and aborts (exit 2, nothing touched) unless both targets safe — `SCA_TEST_DB` = valid identifier, `*_test`, NOT `sca_krayin` (regardless of override); `SCA_LOCK_DB` must match explicit disposable allowlist `^sca_lock_test(_<suffix>)?$` (never prod/shared/arbitrary), differ from SCA_TEST_DB. Strict identifier regex also closes SQL-identifier injection. Cleanup trap armed only AFTER validation passes.
- **Finding 2 (hidden cleanup failure) FIXED:** `resolve_cleanup()` surfaces a drop failure (stderr FAIL) and resolves to non-zero, PRESERVING original status (rc0→1; rc2 kept); replaces `|| true`.
- **Negative safety tests (new `selftest` mode, no DB touched):** 17 checks — safe accepted; prod/non-_test/bad-id/arbitrary/injection/shared/equal rejected; rejection occurs BEFORE any destructive command (recording `docker` shim never invoked for unsafe config → exit 2, empty sentinel); cleanup-failure surfacing + status preservation.
- **Evidence (this host):** `selftest` → 17 passed/0 failed, exit 0 (no DB). Hardened `run` end-to-end (safe defaults): migrated disposable DB; locking `Tests: 2 passed` (k1+k2 EXECUTED); full `tests/Feature/Sca` 1442 passed / 1 skipped / 0 failed; runner exit 0; disposable DB dropped (SHOW DATABASES→0); sca_domain_test/prod untouched.

**STOP — awaiting ChatGPT review of `0ba09fa`. Candidate unmerged/inactive; production NO-GO; prod-migration-incident (139/140) and off-host/DR remain separate open release gates.**

---

# (PRIOR) SCA UX PHASE 2 — REPRODUCIBLE FAIL-CLOSED LOCKING-TEST RUNNER DELIVERED; AWAITING CHATGPT REVIEW

**STATUS (2026-10-21):** `8656a40` source changes ACCEPTED by re-audit; the remaining "durable test execution" item is addressed with a committed, reproducible, fail-closed runner. Evidence: `docs/SCA-STAFF-COLLECTOR-UX-PHASE2-TEST-RUNNER-RESULT.md`. **NOT merged / NOT deployed.** No prod migrate/rollback/write, live-tree checkout, restart, backup/restore, Stripe/mail, pilot. `main 6022b75` + migr 139/140 untouched; no production DB touched.
- **New candidate branch `fix/sca-ux-phase2-test-runner`, head `fbbfdebc3950ef083fb65f51862975bfd1a66355`** (on `8656a40`; pushed, UNMERGED). One new file: `scripts/run-sca-feature-tests.sh` (no app/source change).
- **Entry point:** `scripts/run-sca-feature-tests.sh` — provisions + migrates a DEDICATED DISPOSABLE DB (default `sca_lock_test`; refuses `sca_krayin`/`sca_domain_test`), runs `CollectorActivityLockingTest` with `SCA_LOCK_DB` and **FAILS CLOSED unless k1+k2 executed & passed (any skip = hard fail)**, runs the full `tests/Feature/Sca` suite, and ALWAYS drops the disposable DB (trap). Migrates in `APP_ENV=testing` (no prompt, no `--force`); never touches `sca_domain_test`/prod; preserves append-only model. Env-overridable for CI.
- **Evidence (this host; auditor to re-run):** fail-closed verified (without `SCA_LOCK_DB` → `2 skipped`); via the runner (exit 0): disposable DB migrated, locking phase `Tests: 2 passed` (k1+k2 EXECUTED), full suite `1442 passed / 1 skipped / 0 failed` (k1/k2 also pass inside it; the 1 skip is the pre-existing unrelated one), disposable DB dropped afterward (SHOW DATABASES → 0).
- **Full Phase 2 chain status:** id-watermark unread (same-second/backdated fixed) + migration backfill (b1–b4) + uniform `CollectorAccountLock` invariant closing the out-of-order-commit race (all eligible writers; accounts-first incl. transfer accept) + reproducible fail-closed concurrency execution. Prior docs: unread-semantics `d878820`; re-audit `cd0281e`; locking `8ed2528`; evidence/accounts-first `26018ef`; this runner result.

**STOP — awaiting ChatGPT review of `fbbfdeb` (runner + evidence). Candidate unmerged/inactive; production NO-GO; prod-migration-incident (139/140) and off-host/DR remain separate open release gates.**

---

# (PRIOR) SCA UX PHASE 2 — UNREAD-LOCK RE-AUDIT: EVIDENCE STRENGTHENED + ACCOUNTS-FIRST TRANSFER LOCK; AWAITING CHATGPT RE-AUDIT

**STATUS (2026-10-21):** Re-audit of `7344d75` (CHANGES REQUESTED; Finding 1 accepted) answered — the three Finding-2 evidence/clarity items are addressed. Evidence: `docs/SCA-STAFF-COLLECTOR-UX-PHASE2-UNREAD-LOCKING-REAUDIT-RESULT.md`. **NOT merged / NOT deployed.** No prod migrate/rollback/write, live-tree checkout, restart, backup/restore, Stripe/mail, pilot. `main 6022b75` + migr 139/140 untouched.
- **New candidate branch `fix/sca-ux-phase2-unread-locking-2`, head `8656a40af6a0eaada4928ac6bd63e3ec6a48304e`** (on `7344d75`; pushed, UNMERGED). 3 files: `CollectorActivityService` docblock, `TransferService::accept` lock order, rewritten `CollectorActivityLockingTest`.
- **Item 1 (stale comment):** CollectorActivityService CONCURRENCY docblock no longer says "KNOWN OPEN"/"writers do not uniformly serialize"; it now states the implemented invariant (every eligible writer holds the collector account lock before insert+until commit; markSeen takes same lock → race closed; accounts-before-other-rows → no deadlock).
- **Item 2 (test strengthened):** `CollectorActivityLockingTest` rewritten to use a DEDICATED DISPOSABLE DB (`SCA_LOCK_DB`, created/migrated/dropped by runner) so real append-only events commit without polluting `sca_domain_test`; skips if absent. Two real connections, real txns, REAL writer (`SubmissionService::create`): k1 real writer blocks on a held account lock (timeout); k2 real e1 committed→markSeen; uncommitted e2 held on 2nd conn → markSeen BLOCKS and the SUBMISSION WATERMARK is unchanged; after commit markSeen captures e2; subsequent real e3 unread with feed is_new+count agreeing. No mocks.
- **Item 3 (lock-order audit):** `TransferService::accept` now locks sender+recipient accounts (ascending) BEFORE the request row (peek immutable from_collector_id unlocked → lock accounts → lock+revalidate request → item); global order accounts(asc)→request→item. Audit: ONLY accept locks `sca_transfer_requests`; `CollectorPrivacyService` (pseudonymization) locks account→item_current_state and never touches transfer_requests → no inverse order/cycle.
- **Item 4:** all eligible writers rechecked; backfill b1–b4, first-visit, CAP+1, exact count, privacy, ack, a14–a19 all preserved (no domain-outcome change).
- **Validation (verified DB=sca_domain_test; disposable sca_lock_test migrated through 141):** focused locking+backfill+Phase2 **35 passed (157 assn)**; full `tests/Feature/Sca` **1442 passed / 1 skipped / 0 failed (7620 assn)**, exit 0, no deadlock/regression; disposable DB dropped after. Diff reviewed vs `7344d75` (no secrets/debug/unrelated). Isolated worktree (removed); live stayed on `main 6022b75`.

**STOP — awaiting ChatGPT independent RE-AUDIT of `8656a40`. Candidate unmerged/inactive; production NO-GO; prod-migration-incident (139/140) and off-host/DR remain separate open gates.**

---

# (PRIOR) SCA UX PHASE 2 — UNREAD CONCURRENCY CLOSED (OPTION B); AWAITING CHATGPT RE-AUDIT

**STATUS (2026-10-21):** Approved Option B implemented — the out-of-order-commit race is closed by a uniform collector-account lock invariant; Finding 1 docblock cleanup done. Evidence: `docs/SCA-STAFF-COLLECTOR-UX-PHASE2-UNREAD-LOCKING-RESULT.md`. **NOT merged / NOT deployed.** No prod migrate/rollback/write, live-tree checkout, restart, backup/restore, Stripe/mail, pilot. `main 6022b75` + migr 139/140 untouched.
- **New candidate branch `fix/sca-ux-phase2-unread-locking`, head `7344d7507559cbffcaa687a9e11150df230a5adb`** (on `1e3f2b7`; pushed, UNMERGED). New `CollectorAccountLock`, 4 writer services, migration docblock, new `CollectorActivityLockingTest`.
- **Invariant:** every transaction appending a feed-eligible event holds that collector's `sca_collector_accounts` row lock BEFORE the insert and until commit; `markSeen` takes the SAME lock before snapshotting `MAX(id)` → mark-seen is serialized behind every in-flight eligible writer and can never advance past an uncommitted event; two eligible writers for one collector cannot overlap. Helper `CollectorAccountLock::lockAscending` locks accounts in ascending id order, BEFORE any item/submission lock (global order accounts(asc)→item/submission; matches the existing collector→item convention).
- **Writers audited + compliant:** ClaimService (claimant — already); TransferService.accept (NOW sender+recipient ascending, was recipient-only); OwnershipCorrectionService (NOW destination before item; rejection precedence preserved); SubmissionService create/transition/submitDraft/staffAdvance (NOW owner account before submission row; updateDraft appends no event); CustodyAcceptanceService (NOW owner account first). TransferWorkflow.accept delegates to TransferService. Non-eligible writes (initiated/cancelled, NULL transfer_out) need no lock.
- **Deadlock review:** single-account writers trivially ordered; only Transfer locks 2 (ascending → no reverse-transfer cycle); all lock accounts before items/submissions (disjoint groups) → no cycle. Full suite showed no deadlock/timeout.
- **Concurrency test (`CollectorActivityLockingTest::k1`, two real connections, no mocks, non-`DatabaseTransactions`):** while a writer connection holds the account lock, (a) NOWAIT acquisition fails and (b) `markSeen` blocks (lock_wait_timeout) and advances NO watermark; after release it proceeds. Commits no event rows (writer rolls back — event tables are append-only, can't be cleaned), uses one deletable throwaway account, restores `innodb_lock_wait_timeout`. Post-commit correctness stays in the sequential a/b tests. (Env note: a committing interleave can't persist events without polluting append-only tables / global-count tests; the chosen setup proves the exact safety property without that pollution.)
- **Validation (verified DB=sca_domain_test):** focused locking+backfill+Phase2 **34 passed (149 assn)**; full `tests/Feature/Sca` **1441 passed / 1 skipped / 0 failed (7612 assn)**, exit 0, no deadlock/regression. CAP+1/exact-count/first-visit/privacy/ack + Finding-1 b1–b4 + a14–a19 all preserved. Diff reviewed vs `dae6072` (no secrets/debug/unrelated). Isolated worktree (removed); live stayed on `main 6022b75`.

**STOP — awaiting ChatGPT independent RE-AUDIT of `7344d75`. Candidate unmerged/inactive; production NO-GO; prod-migration-incident (139/140) and off-host/DR remain separate open gates.**

---

# (PRIOR) SCA UX PHASE 2 — RE-AUDIT: FINDING 1 FIXED; FINDING 2 DESIGN PROPOSAL; AWAITING CHATGPT REVIEW

**STATUS (2026-10-21):** Re-audit of `ece24f1` (CHANGES REQUESTED, 2 findings) answered. Evidence: `docs/SCA-STAFF-COLLECTOR-UX-PHASE2-UNREAD-REAUDIT-RESULT.md`. **NOT merged / NOT deployed.** No prod migrate/rollback/write, live-tree checkout, restart, backup/restore, Stripe/mail, pilot. `main 6022b75` + migr 139/140 untouched.
- **New candidate branch `fix/sca-ux-phase2-unread-semantics-2`, head `1e3f2b705f6386a7edf715c8010ae76a4cea39dd`** (on `ece24f1`; pushed, UNMERGED). 4 files vs `ece24f1`: service doc comment, migration (+backfill call), new `ActivityWatermarkBackfill`, new `CollectorActivityWatermarkBackfillTest`.
- **Finding 1 (existing-account watermark init) — FIXED.** Migration `2026_10_22_000001` now runs a one-time backfill (`ActivityWatermarkBackfill::backfillVisitedAccounts`, shared by migration + test, no drift): VISITED accounts (`activity_last_seen_at` NOT NULL) → each per-source watermark = `COALESCE(MAX(eligible id),0)` using the service's exact collector-scoped filters; never-visited (NULL marker) left NULL (first-visit preserved); empty sources → 0; subsequent events stay unread; idempotent. Tests b1–b4 (all-three-sources/first-visit/partial-sources/subsequent-unread).
- **Finding 2 (out-of-order commit) — NOT closed; DESIGN PROPOSAL (per audit's stop-before-broad-change instruction).** Writer inspection: NO uniform per-collector-account serialization (ClaimService locks claimant, TransferService.accept locks recipient; OwnershipCorrectionService locks item state, submission writers lock the submission row, sender-feed transfer_event locks recipient) → `MAX(id)` is raceable; no scalar fix closes it (commit time is not stored in any column). Proposed: **Option B (recommended)** uniform collector-account lock in the feed-event writers (+ lock-ordering discipline + a two-connection concurrency test; no new table) or **Option A** per-event read-state table (fully safe, broader). Service doc comment now marks this a KNOWN OPEN limitation (not a closed guarantee). Requesting approval of the approach before implementing (touches provenance-critical write paths).
- **Validation (verified DB=sca_domain_test):** focused backfill+Phase2 **33 passed (145 assn)**; full `tests/Feature/Sca` **1440 passed / 1 skipped / 0 failed (7608 assn)**, exit 0; lint clean; diff reviewed vs `dae6072` (no secrets/debug/unrelated). Isolated worktree (removed); live stayed on `main 6022b75`.

**STOP — awaiting ChatGPT review of Finding 1 + a decision on the Finding 2 design proposal (Option B vs A). Candidate unmerged/inactive; production NO-GO; prod-migration-incident (139/140) and off-host/DR remain separate open gates.**

---

# (PRIOR) SCA UX PHASE 2 — UNREAD SEMANTICS FIX DELIVERED; AWAITING CHATGPT RE-AUDIT

**STATUS (2026-10-21):** Blocking unread-semantics finding on `dae6072` (gov audit `5da1b65`) remediated on a clean candidate branch. Evidence: `docs/SCA-STAFF-COLLECTOR-UX-PHASE2-UNREAD-SEMANTICS-RESULT.md`. **NOT merged / NOT deployed.** No production migration/rollback/write, live-tree checkout, restart, backup/restore, Stripe/mail.
- **Candidate branch `fix/sca-ux-phase2-unread-semantics`, head `ece24f18aaf4608d167ed606f23907360ecd7c02`** (built on `dae6072`; baseline `6022b75`; pushed, UNMERGED). 3 files: `CollectorActivityService.php`, new migration `2026_10_22_000001_add_collector_activity_source_watermarks`, `StaffCollectorUxPhase2Test.php`.
- **Git state checked first:** experimental `fix/sca-ux-phase2-unread-id-watermarks` is EMPTY (== `dae6072`). A second experimental `fix/sca-ux-phase2-source-watermarks` (`4fe1571`) was an INCOMPLETE `MAX(id)` attempt that also removed the CAP+1/`window_capped` logic and shrank the test → rejected as a base (reference only).
- **Fix:** unread now keyed on RECORDING IDENTITY = per-source append-only auto-increment event `id`, not timestamps. `unreadCount`/feed `is_new` use `id > seen_source_id` (strict integer → no same-second tie; immune to backdated `effective_at`); both use the identical rule so count/feed/badge agree. `markSeen` snapshots `MAX(id)` per source under a row lock and advances each watermark + `activity_last_seen_at` MONOTONICALLY (replay-/concurrent-safe; an uncommitted row is invisible to MAX and stays unread once it commits). `activity_last_seen_at` is now only the first-visit marker. CAP+1 truncation, exact COUNT, first-visit, privacy, ownership-ack, submission-labels all PRESERVED.
- **Migration:** additive, 3 nullable columns, sequenced AFTER 140; **139/140 files untouched**; applied ONLY to disposable `sca_domain_test` after verifying the target (`db:show`); no prod migrate/`--force`/rollback.
- **Honest concurrency limit documented:** a per-source scalar id watermark leaves one bounded residual (two overlapping inserts to the SAME source for the SAME collector committing out of id order); strictly narrower than the timestamp scheme; full closure would need per-event read tracking (a new event system, which the task directed against).
- **Tests (added, not weakened):** a14 same-second, a15 backdated-recorded-after, a16 feed/count/badge agree, a17 cross-collector count isolation, a18 id-watermark replay idempotence, a19 delayed-insert-older-timestamps-higher-id-not-lost; A–C/CAP boundary retained. Focused **29 passed (129 assn)**; full `tests/Feature/Sca` **1436 passed / 1 skipped / 0 failed (7592 assn)**; email-hardening **9/9 ×3** isolated. Password-reset flake investigated → shared `throttle:6,1` budget under dense runs, isolated by the `dae6072` setUp limiter reset (preserved); not reproduced here.
- Isolated worktree (removed); live stayed on `main 6022b75`; diff = exactly the 3 files, no secrets/debug.

**STOP — awaiting ChatGPT independent RE-AUDIT of `ece24f1`. Candidate unmerged/inactive; production NO-GO; prod-migration-incident (139/140) and off-host/DR remain separate open release gates.**

---

# (PRIOR) SCA UX PHASE 2 — UNREAD SEMANTICS AUDIT: CHANGES REQUESTED; PRODUCTION NO-GO

**Independent source review: 2026-10-21.** Latest candidate reviewed: `dae60728312fa1238bc733eb671540a444dcd807` on `fix/sca-ux-phase2-correction`; baseline `6022b75c021069bde332b4a10cd5806ae9065aaf`. GitHub compare reports 3 commits ahead / 0 behind, 27 files changed. Full report: `docs/SCA-STAFF-COLLECTOR-UX-PHASE2-UNREAD-SEMANTICS-AUDIT.md` (governance commit `5da1b65b8f581da499ae08e2bd4ae37362a839c6`).

**Disposition: CHANGES REQUESTED. No merge/deploy.** Source review confirms the latest candidate contains the CAP+1 truncation correction, exact unread COUNT queries, and “Recent activity” disclosure. A new blocking finding remains: unread semantics compare event timestamps strictly with `activity_last_seen_at`. Same-second events may compare equal, and ownership uses `effective_at`, which can be backdated and is not necessarily event-recording time. New events can therefore be missed by both the feed and unread count.

## Authorized next candidate task (candidate branch only)

1. Define unread semantics as “recorded after mark-seen” or otherwise document the intended behavior; inspect available authoritative ledger columns before choosing the boundary.
2. Fix same-second precision and late-recorded/backdated ownership-event behavior without broadening activity sources or weakening collector scoping.
3. Add regression tests for same-second event recording and late-recorded ownership events with an older `effective_at`; assert feed `is_new` and exact unread count agree.
4. Preserve CAP+1 truncation behavior, exact COUNT queries, ownership acknowledgements, read-only GET activity, explicit authenticated/CSRF POST mark-seen, and migration filenames 139/140.
5. Run focused and full SCA feature tests only against verified disposable `sca_domain_test`; record exact SHA, diff, commands, target DB, and output. Update a governance result report, then STOP for ChatGPT independent re-audit.

## Production migration incident — read-only evidence still required

The existing incident report says migrations 139 and 140 were applied to production `sca_krayin` in batch 27, with additive schema and no observed data mutation. This audit did **not** connect to the live production host or database, so those live observations remain operator-reported, not independently verified here. Before any release decision, obtain fresh, safely redacted read-only evidence of migration rows/batches, exact columns/indexes/constraint, and whether the new columns have populated values. If direct read-only access is unavailable, keep the limitation explicit. Do not run `migrate`, `migrate:rollback`, or any production write.

**Hard prohibitions:** no merge, deploy, production migration/rollback/write, live-tree checkout, restart, backup/restore execution, Stripe/mail activation, or pilot. Keep candidate unmerged. Production remains **NO-GO**; off-host recovery remains a separate release gate. No production action was taken by this audit.

---

# SCA OFF-HOST/DR ASSESSMENT — REVIEWED; DIRECTION CONDITIONALLY ACCEPTED, IMPLEMENTATION NOT AUTHORIZED

**ChatGPT review: 2026-10-21.** Reviewed `docs/SCA-OFFHOST-DR-ASSESSMENT.md` and inspected the current `main` implementation of `scripts/lib-offsite.sh` and relevant `backup-run.sh` references. The read-only assessment is useful and the Storage Box + SFTP/rclone approach is a reasonable primary option for recovery from loss of the production VPS. **This is not approval to provision, configure, upload production backups, merge, deploy, or change production.** No production action was taken by this review.

## Required clarifications before implementation approval

1. **Describe snapshots accurately.** Hetzner documents Storage Box snapshots as change-tracking snapshots stored on the same Storage Box, not full backups; the BX11 plan has 10 snapshot slots. They can provide rollback protection against VPS-level deletion when access is isolated, but they are not WORM/object-lock and do not protect against loss/compromise of the Storage Box account/provider. Do not describe them as absolute immutability. Official docs: https://docs.hetzner.com/storage/storage-box/snapshots/ and https://docs.hetzner.com/storage/storage-box/general/.
2. **Remote verification is a release requirement.** Current `offsite_publish()` promotes `.part` to final and returns success without comparing the remote bytes to the local artifact checksum. Add a narrowly scoped, tested post-promotion verification before logging publication as durable. Confirm what checksum capabilities the SFTP/rclone backend actually supports; if remote-side SHA-256 is unavailable, use a safe read-back verification approach or document an owner-approved alternative. Audit the code and deterministic failure cases before enabling off-site publication.
3. **Candidate consistency fix is a separate gate.** `268c637` remains unmerged/inactive; current production `main 6022b75` does not yet contain the candidate's DB-reference-integrity proof. The backup rollout gate is therefore not “off-host only”: it also includes a separately owner-approved, independently reviewed merge/deploy of the exact candidate app+scripts, with migration/production safeguards preserved. Do not rely on off-host artifacts as meeting the candidate's consistency guarantee until the exact approved code is deployed and verified.
4. **Secrets escrow must be a separately tested recovery dependency.** Escrow `secrets/backup.key`, `.env`, `app/.env` (including `APP_KEY`), and any credentials needed to retrieve the off-host artifact in a secure store that the VPS and backup destination cannot delete. Document who can access it and how access is recovered during a total VPS loss. Do not put secrets or secret values in Git/governance.
5. **Define operational objectives and retention behavior.** Owner must approve RPO/RTO, restore-test frequency, retention, snapshot schedule/slot limits, and whether a second cross-provider copy is needed. The proposed 14 daily + 8 weekly + 6 monthly full artifacts require about 125–130 GB at the observed artifact size; confirm actual box tier, growth headroom, and how pruning interacts with snapshots. Storage Box is a reasonable VPS-loss recovery destination, but a second provider is needed for stronger independence from a Hetzner account/provider incident.
6. **Prove the full cold-recovery path.** After owner approval and implementation, a restore must retrieve the backup from off-host storage and obtain the decryption/application secrets from the separate escrow, then pass in an isolated host. The latest nightly artifact is not itself proof of restore; the assessment reports the last restore-verified artifact as 2026-10-14.

## Current disposition

- **Assessment quality:** accepted as a useful read-only plan, with the clarifications above.
- **Preferred direction:** Hetzner Storage Box in a different location, restricted sub-account, client-side encrypted artifacts, separate secrets escrow, and a tested off-host restore; consider Backblaze B2 as a second copy based on owner risk/budget decision.
- **Release status:** **NO-GO**. Candidate `268c637` stays unmerged/inactive. Production `main 6022b75` and migrations 139/140 stay untouched. No provisioning, installation, credential change, upload, merge/deploy, production backup/restore, DB mutation, restart, Stripe, or mail activation.
- **Next step:** owner decisions on destination, separate escrow, retention/immutability expectations, RPO/RTO, host-change approval, second-provider policy, and the separate candidate rollout gate. Only then create a narrowly scoped implementation task and STOP for independent audit.

---

# SCA OFF-HOST BACKUP & DR — READ-ONLY ASSESSMENT DELIVERED; AWAITING CHATGPT REVIEW + OWNER DECISIONS

**STATUS (2026-10-20):** Planning-only off-host/DR assessment delivered → `docs/SCA-OFFHOST-DR-ASSESSMENT.md`. **Nothing provisioned/installed/configured/uploaded/merged/deployed/executed.** No storage account, no credential change, no cron/script/`.env` change, no prod backup/restore, no DB mutation, no restart. Candidate `268c637` stays UNMERGED/inactive; `main 6022b75` + migr 139/140 untouched; Stripe/mail off.
- **Context:** backup candidate `268c637503883007622c58a94232fcc9d05dfe1f` independently audited **PASS** (section below); production release remains **NO-GO** solely because off-host recovery is not established.
- **Findings (observed read-only):** nightly cron 03:17 UTC produces one AES-256 `.gpg` (~4.3G, docs=4605; newest 2026-10-20 OK) but **only on the single VPS filesystem** `/dev/sda1`; `SCA_BACKUP_REMOTE` unset → `OFFSITE_DEFERRED` nightly. `offsite_publish` (rclone/aws, atomic `.part`→promote) is code-ready + unit-proven, just has no destination. No rclone/aws/restic/borg installed; **rsync/ssh/sftp/gpg present**. **The GPG key `secrets/backup.key` + app secrets `.env`/`app/.env` (APP_KEY) are co-located on the SAME VPS** → copying only ciphertext off-host is insufficient; key+secrets need separate out-of-band escrow. Host is QEMU/KVM (Hetzner-consistent). Last restore-verified artifact = 10-14; disposable restore-proof (`backup-verify-restore.sh`, `guard_target` refuses live DB) exists.
- **Recommendation:** **Hetzner Storage Box via rclone `sftp` remote** (uses existing SSH/SFTP tooling + the audited `offsite_publish` rclone path with NO code change; cheapest; sub-account least-privilege + server-side snapshot immutability; selectable different location). Optional later 2nd copy = Backblaze B2 (cross-provider). Non-negotiable companion: separate escrow of key + `.env`/`app.env`.
- **Doc also specifies:** off-host flow, GFS retention (14d+8w+6m ≈ ~125G → ~1TB box) + snapshot immutability, total-loss restore procedure, 5 durability verification criteria, DB+document transfer/verification + honest reference-integrity limits (proof NOT point-in-time snapshot; private-disk only), a safe isolated restore test (throwaway Hetzner VM fetching the OFF-HOST copy; on-host disposable verify as minimum), outstanding owner decisions, and exact later implementation steps.
- **Blocker clears when:** destination + least-privilege creds provisioned; key+secrets escrowed separately; nightly off-host upload enabled + verified; a restore FROM the off-host copy passes on an isolated host — ideally after `268c637` is deployed.

**STOP — awaiting ChatGPT review of the assessment + OWNER decisions (destination, escrow, retention/immutability, host-change approval, deploy order). No provisioning/activation performed.**

---

# SCA BACKUP — INDEPENDENT RE-AUDIT OF 268c637: CODE REVIEW PASS; RELEASE STILL NO-GO

**Audit date: 2026-10-20.** Independent source review of implementation candidate `268c637503883007622c58a94232fcc9d05dfe1f` found the two prior findings on `0f38626` addressed in the inspected code. **No new blocking source-level finding identified in this review.** This is a code review of the pushed candidate, not a claim that ChatGPT executed the candidate's shell tests or verified a production restore.

- **Path containment:** `verify_db_document_refs()` now extracts the whole quoted path token, validates it against an anchored traversal-free canonical grammar before any filesystem probe, and independently rejects absolute paths and `.`/`..` components. Test (L) creates a real file outside the snapshot and uses a traversal reference; the stage must fail and leave no document archive. Near-miss malformed paths are also tested.
- **Extraction fail-closed:** the local-count grep status and both statuses from the path-extraction grep/sed pipeline are captured and checked. Only grep's documented no-match status is accepted; grep read errors and sed errors return non-zero. Test (M) injects a no-output grep error specifically at the extraction stage and asserts stage failure/no archive.
- **Prior protections retained in inspected source:** the shared checked `backup_document_stage()` remains the runner's single decision path; DB-reference integrity check; snapshot enumeration/copy failure handling; atomic app publication and `.part` exclusion; checked manifest inputs and local artifact publication to `.part` before rename.
- **Evidence reported by implementation:** `DOC-CONSISTENCY-SELFTEST PASS (A–M)`, `offsite-selftest` PASS, shell syntax checks clean; app unchanged this round. These are candidate-reported results, not independently executed in this audit.
- **Candidate remains UNMERGED / NOT ACTIVATED.** Production `main 6022b75c021069bde332b4a10cd5806ae9065aaf` and migrations 139/140 must remain untouched until separate owner-approved release steps. Off-host replication/recovery is absent; production release remains **NO-GO**. The option-B reference-integrity check is not a coordinated DB/document point-in-time snapshot.
- **Safety:** no production action taken by this audit. No merge/deploy, DB mutation, migration/rollback, restart, production backup/restore, or Stripe/mail activation.

**Next action:** keep the candidate frozen pending explicit owner decision on the remaining operational release gates, especially off-host recovery and an approved deployment/restore-verification plan. Do not infer production readiness from this source-level pass.

---

# SCA BACKUP — REFERENCE-PATH GRAMMAR / EXTRACTION-STATUS REMEDIATION DELIVERED; AWAITING CHATGPT RE-AUDIT

**STATUS (2026-10-20):** Re-audit findings on `0f38626` (gov `b6ac62e`: reference-path escape + unchecked extraction-stage statuses in `verify_db_document_refs()`) remediated. Evidence in `docs/SCA-BACKUP-REFPATH-GRAMMAR-EXTRACTION-RESULT.md`. **NOT activated** — live app/scripts/cron/DB unchanged. No merge/deploy/prod-backup/restore/DB-mutation/live-tree-checkout.
- **New candidate head `268c637503883007622c58a94232fcc9d05dfe1f`** on `fix/sca-backup-document-consistency` (prev audited `0f38626`; **scripts-only** diff, 2 files +102/−24 — `lib-docsnapshot.sh` + `backup-verify-restore.sh`, `backup-run.sh` unchanged this round; pushed, UNMERGED).
- **Fix 1 (path containment):** each extracted `local` path is validated against the EXACT canonical grammar DocumentService emits — `^sca/(documents|generated)/[0-9]+/[0-9a-f]{40}\.(pdf|jpg|jpeg|png)$` (re-confirmed vs source: attachToItem/putGenerated/restoreGeneratedMedia; ext∈{pdf,jpg,jpeg,png}) — **before any filesystem probe**, so a traversing/absolute/corrupt path (e.g. `sca/../../etc/passwd`) is REJECTED (fail closed) and can never resolve via `[ -f "$root/$p" ]` to a file outside the snapshot. Defence-in-depth absolute-path + `.`/`..`-component rejection. Extractor now captures `'<disk>','[^']*'` so a malformed path is captured+rejected, not silently dropped. Containment established by the traversal-free grammar, not the `sca/` prefix/charset.
- **Fix 2 (extraction statuses):** local-count grep status (`gc1=$?`), path-extraction grep+sed statuses (`PIPESTATUS`) are all captured immediately and checked — only grep "no match" (exit 1) permitted; any grep/sed READ/processing error fails closed (8). An errored extraction producing no output can no longer be read as "zero references".
- **Tests:** added (L) traversal to a REAL out-of-snapshot file + near-miss non-canonical paths → fail closed, no `documents.tar.gz`; (M) extraction-stage grep read error (keyed on `-oaE`, only the extraction uses it) → fail closed, no archive, not a false 0-ref pass (trace-verified it reaches the extraction only after the isolation grep succeeds). A–K retained, updated to canonical 40-hex names. `DOC-CONSISTENCY-SELFTEST PASS (A–M)`, `offsite-selftest` PASS, `bash -n` clean.
- **App unchanged** (publishAtomically + PART_SUFFIX + BackupDocumentAtomicityTest + full SCA 1409/1/0 from 1a22d8c stand; scripts-only). Guarantee remains option-B reference-integrity proof, NOT point-in-time quiescence. Isolated worktree (removed); live stayed on `main 6022b75`; loopback 200; no throwaway `.env` committed.
- **Must deploy app+scripts together** (owner-approved); interim recovery = 2026-10-14T22:06Z backup. **Off-host absent → release NO-GO.** Phase 2 `dae6072` frozen; `main 6022b75` + migr 139/140 untouched.

**STOP — awaiting ChatGPT independent RE-AUDIT of `268c637`. No merge/deploy/migrate/rollback/restart/live-backup/restore/Stripe/mail/pilot.**

---

# (PRIOR) SCA BACKUP — RE-AUDIT OF 0f38626: CHANGES REQUESTED (REFERENCE-PATH ESCAPE + UNCHECKED EXTRACTION STATUS)

**Verdict (2026-10-20): CHANGES REQUESTED; DO NOT MERGE OR ACTIVATE.** Independent inspection of implementation candidate `0f386266bf34d436b9a61d4271abf26953640163` confirms the earlier caller-level empty-archive probe is removed and the shared staging function is used by the runner. Two fail-closed gaps remain in `scripts/lib-docsnapshot.sh` inside `verify_db_document_refs()`.

## Blocking finding 1 — a malformed `storage_path` can escape the snapshot root

The path extractor accepts `'local','sca/[A-Za-z0-9._/-]+'`; this character class permits arbitrary `..` path segments. The subsequent check is only `[ -f "$root/$p" ]`, which follows path traversal. A dumped local row such as `sca/../../../../etc/passwd` (depth adjusted to the runtime path) can therefore pass by resolving to a regular file outside `$root`, even though that referenced document is NOT in the snapshot/archive. This contradicts the stated proof that every private-disk reference exists inside the snapshot and the claim that corrupted/ambiguous paths fail closed.

**Required fix:** validate each extracted path against the actual canonical path grammar emitted by `DocumentService` (report states `sca/{documents|generated}/<id>/<40-hex>.<ext>`; confirm against current source and encode the exact accepted grammar), explicitly reject `.`/`..` path components and any non-canonical/absolute path, and verify containment without following a path outside the snapshot root. Do not merely rely on the safe-character set or a `sca/` prefix.

**Required deterministic test:** create a synthetic dumped `local` row whose path traverses out of the snapshot to a real file outside the snapshot root; the verifier and `backup_document_stage` must fail closed (non-zero) and produce no `documents.tar.gz`. Include near-miss/invalid canonical paths too. Retain H–K and A–G.

## Blocking finding 2 — second-stage grep/extraction errors are not checked

The function's initial `gzip -dc | grep` pipeline correctly captures both statuses in `PIPESTATUS`. But the later extraction block runs:
- `grep -oaE "'local'," "$ins" > "$dcs"`
- `grep -oaE "'local','sca/[A-Za-z0-9._/-]+'" "$ins" | sed ... > "$paths"`

inside `set +e`, then immediately restores `set -e`, without capturing/checking either command's status. If both reads fail before producing output, both count files can be empty (`localcount == pathcount == 0`) and the verifier can return success despite being unable to establish the inventory. This violates the advertised fail-closed behavior for grep/read errors.

**Required fix:** capture statuses immediately for each extraction pipeline (including both `grep` and `sed` where applicable); distinguish only the expected “no match” status for a truly empty/no-local-row table from actual read/processing errors. On any unhandled error, clean temporary files and return non-zero. Avoid a broad `set +e` block that discards status.

**Required deterministic test:** inject a grep/read failure specifically in the local-count/path-extraction stage (not only the earlier gzip→grep pipeline), including the zero-output case; assert verifier/stage failure and no archive. Keep the existing corrupt-gzip, parse-ambiguity, missing-reference, positive, and genuinely-empty cases passing.

## Safety / release boundary

Work only in the isolated candidate worktree with synthetic/disposable data. Commit the fix + deterministic tests + evidence, update this queue/report, then STOP for another independent audit. No live-tree checkout, production backup/restore, merge/deploy, DB mutation, migration/rollback, restart, or Stripe/mail activation. Keep Phase 2 `dae6072` frozen. Production release remains **NO-GO** while off-host recovery is absent; do not alter production `main 6022b75` or migrations 139/140.

**STOP — awaiting remediation of these two findings and independent re-audit.**

---

# SCA BACKUP — EMPTY-ARCHIVE FAIL-OPEN / DELETION-WINDOW REMEDIATION DELIVERED; AWAITING CHATGPT RE-AUDIT

**STATUS (2026-10-20):** Re-audit findings on `1a22d8c` (gov `6202edc`: caller-level empty-archive fail-open + DB-dump→document-inventory deletion window) remediated. Evidence in `docs/SCA-BACKUP-EMPTY-ARCHIVE-FAILOPEN-RESULT.md`. **NOT activated** — live app/scripts/cron/DB unchanged. No merge/deploy/prod-backup/restore/DB-mutation/live-tree-checkout.
- **New candidate head `0f386266bf34d436b9a61d4271abf26953640163`** on `fix/sca-backup-document-consistency` (prev audited `1a22d8c`; **scripts-only** diff, 3 files +238/−23, no app delta; pushed, UNMERGED).
- **Fix:** (1) removed the `if [ -n "$(find … -print -quit 2>/dev/null)" ]` pre-probe that conflated a FAILED enumeration with an empty corpus (could publish a successful EMPTY archive while the DB referenced docs). A single shared `backup_document_stage()` (used verbatim by backup-run.sh AND the selftest) makes ONE checked snapshot decision, fails the whole backup closed on any inability to establish the inventory, and represents an existing-but-empty tree as empty ONLY after a successful complete enumeration. (2) `verify_db_document_refs()` proves every PRIVATE-disk (`local`) document reference in the just-dumped DB is present in the snapshot — closing the deletion window snapshot_documents alone cannot see (file deleted before its enumeration). Table-scoped extraction over the safe server-generated `storage_path` charset; corrupt dump / decompress-or-grep read error / parse ambiguity (non-`sca/` local path) / any missing referenced file all FAIL CLOSED. Append-only media model ⇒ normal runs pass; guards out-of-band removal/corruption + mid-backup deletion. Honest limitation: this is option B (reference-integrity proof), NOT a coordinated point-in-time quiescence protocol — sufficient for fail-closed correctness, does NOT by itself change the verdict.
- **Other runner fail-open paths hardened:** manifest component checksums into CHECKED vars (no silent empty/garbage hash); encrypted artifact published ATOMICALLY to a local `*.part` then renamed after checksum (interrupted encryption leaves only a `*.part`, swept by cleanup; never a final-named backup). `set -euo pipefail` preserved; fragile extraction uses a bounded `set +e` with explicit `PIPESTATUS` capture.
- **Deterministic tests through the REAL decision path (`backup_document_stage`):** (H) positive end-to-end + other-disk ref ignored + restore-verified; (I) deletion window → fail closed (rc 12); (J) enumeration failure → fail closed (rc 11), NO empty archive; (K) genuinely empty tree → succeeds only after successful enumeration (count 0). Retained A–G + direct `verify_db_document_refs` edge checks. `DOC-CONSISTENCY-SELFTEST PASS (A–K)`, `offsite-selftest` PASS, `bash -n` clean.
- **App unchanged since c6fc97b/1a22d8c** (publishAtomically + PART_SUFFIX + BackupDocumentAtomicityTest + full SCA 1409/1/0 stand; scripts-only). Isolated worktree (removed); live stayed on `main 6022b75`; loopback 200; no throwaway `.env` committed.
- **Must deploy app+scripts together** (owner-approved); interim recovery = 2026-10-14T22:06Z backup. **Off-host absent → release NO-GO.** Phase 2 `dae6072` frozen; `main 6022b75` + migr 139/140 untouched.

**STOP — awaiting ChatGPT independent RE-AUDIT of `0f38626`. No merge/deploy/migrate/rollback/restart/live-backup/restore/Stripe/mail/pilot.**

---

# (PRIOR) SCA BACKUP — RE-AUDIT OF 1a22d8c: CHANGES REQUESTED (PRE-ENUMERATION DELETION / EMPTY-ARCHIVE FAIL-OPEN)

**Verdict (2026-10-20): CHANGES REQUESTED; DO NOT MERGE OR ACTIVATE.** Candidate `1a22d8c8da5572232cf2f019f9a2207adf1932b6` correctly hardens the snapshot helper's copy and enumeration paths, but a caller-level fail-open remains in `scripts/backup-run.sh`.

**Blocking finding:** `backup-run.sh` dumps the DB first, then checks whether documents exist using `if [ -d "$DOCS_DIR" ] && [ -n "$(find "$DOCS_DIR" -type f -print -quit 2>/dev/null)" ]; then ... else ... empty archive ... fi`. If a document referenced by the DB dump is deleted after the DB dump but before this preliminary `find`, the probe can return no files and the runner creates a valid empty document archive without ever calling `snapshot_documents()`. The helper cannot detect a file already missing before its own enumeration. This can publish a successful backup whose DB still references a missing document. A failed/permission-denied initial `find` may also be misclassified as an empty corpus.

**Required remediation:**
1. Remove the fail-open preliminary existence probe. Do not decide that the corpus is empty based on command substitution that collapses `find` failure and empty output into the same state.
2. Make one explicit, checked enumeration/snapshot decision. Any inability to establish the document inventory must fail the whole backup. Ensure an actually empty document tree can still be represented as empty without masking an enumeration error.
3. Address the DB-dump-to-document-snapshot deletion window honestly. Fail-closed copy/enumeration only catches deletion after enumeration starts; it cannot detect deletion between DB dump and first enumeration. Either implement a genuinely coordinated DB/document point-in-time protocol/quiescence covering deletes, or provide a reliable integrity check that proves every document reference in the dumped DB is present in the archived snapshot. Do not claim DB/document consistency without this guarantee. If the safe solution is out of scope, explicitly mark the design insufficient for release and keep NO-GO; do not label this candidate fully remediated.
4. Add deterministic tests through the actual backup-run decision path: (a) initial source enumeration failure must fail, never produce an empty archive; (b) a document deleted after DB dump but before first inventory must not yield a successful backup; (c) a genuinely empty tree succeeds only after a successful, complete enumeration; (d) retain tests D–G and A–C.
5. Audit other relevant fail-open paths in the runner: ensure `find`, manifest generation, archive creation, and artifact publication errors cannot be converted to success. Preserve `set -euo pipefail`, but verify conditional/subshell/command-substitution behavior explicitly.
6. Update evidence and `NEXT_TASK.md`, commit/push the candidate and tests, then STOP for independent re-audit.

**Safety:** isolated worktree and synthetic/disposable data only. No live script/app/cron change, production backup/restore, merge/deploy, database mutation, migration/rollback, restart, Stripe/mail activation, or live-tree checkout. Keep Phase 2 frozen. Off-host recovery is absent and production release remains **NO-GO**.

---
# SCA BACKUP — VANISHED/ENUMERATION FAIL-CLOSED REMEDIATION DELIVERED; AWAITING CHATGPT RE-AUDIT

**STATUS (2026-10-20):** Re-audit findings (`43260e6`: unsafe vanished-skip + masked enumeration failure) remediated. Evidence in `docs/SCA-BACKUP-VANISHED-ENUM-FAILCLOSED-RESULT.md`. **NOT activated** — live app/scripts/cron/DB unchanged. No merge/deploy/prod-backup/restore/DB-mutation/live-tree-checkout.
- **New candidate head `1a22d8c8da5572232cf2f019f9a2207adf1932b6`** on `fix/sca-backup-document-consistency` (prev audited `77e4023`; **scripts-only** diff, 2 files +67/−33, no app delta; pushed, UNMERGED).
- **Fix (`snapshot_documents`):** (1) disappearance now FAIL CLOSED (no skip) — ANY cp failure incl. source vanished after enumeration → rm partial dest + non-zero (deletion-safety would need a coordinated DB+doc point-in-time snapshot; out of scope; write-ordering NOT relied upon). (2) enumeration status captured via temp list + checked (`if ! (cd src && find…) > listf`) → failed/incomplete `find` fails closed (process-substitution status-drop removed). mkdir checked; inventory copied==enumerated==present; symlinks excluded; backup-run.sh still `|| fail` so no .gpg on failure.
- **Deterministic fault-injection:** (D) copy-fail-source-present→fail-closed; (E) REVISED disappearance→fail-closed (no dangling-row backup); (F) NEW enumeration-failure (find shim)→fail-closed; (G) NEW mkdir-failure→fail-closed. Retains (A) paused .part excluded, (B) atomic-rename boundary, (C) concurrent in-flight. `DOC-CONSISTENCY-SELFTEST PASS` (A–G); bash -n clean.
- **App unchanged since c6fc97b** (publishAtomically + PART_SUFFIX + BackupDocumentAtomicityTest + full SCA 1409/1/0 stand; scripts-only). Isolated worktree; live stayed on main; loopback 200.
- **Must deploy app+scripts together** (owner-approved); interim recovery = 2026-10-14T22:06Z backup. **Off-host absent → release NO-GO.** Phase 2 `dae6072` frozen; `main 6022b75` + migr 139/140 untouched.

**STOP — awaiting ChatGPT independent RE-AUDIT of `1a22d8c`. No merge/deploy/migrate/rollback/restart/live-backup/restore/Stripe/mail/pilot.**

---

# (PRIOR) SCA BACKUP — RE-AUDIT OF 77e4023: CHANGES REQUESTED (VANISHED FILE CAN BREAK DB/DOCUMENT CONSISTENCY)

**Audit verdict (2026-10-20): CHANGES REQUESTED; DO NOT MERGE OR ACTIVATE.** Candidate 77e40230524a7456b9d43198ac5351acb0a011aa correctly fixes the prior `cp ... || true` fail-open when the source still exists. Independent code inspection found that the newly accepted “source vanished → skip” policy is not safe given the backup ordering.

**Blocking finding — database dump precedes document snapshot.** If a published document is deleted after the DB dump but before its copy, the snapshot helper can skip the missing file while the database dump still contains a row referencing it. “Rows are written only after publication” only establishes create ordering; it does not protect against deletion after the dump. Test (E) currently declares success for this potentially inconsistent backup.

**Required remediation:**
1. Safest default: if an enumerated published file disappears or cannot be copied, fail the entire backup closed and publish no final artifact. Do not skip disappearance unless the implementation proves a real DB/document point-in-time consistency protocol covering both create and delete operations (for example, an appropriately enforced shared lock/quiescence or storage snapshot coordinated with the DB snapshot). Do not infer safety from write ordering alone.
2. Extend deterministic fault injection: (D) copy failure while source remains present fails closed; revise (E) disappearance after enumeration to fail closed/no successful artifact under the default policy. If a stronger coordinated consistency protocol is implemented instead, test deletion during the snapshot and prove the DB dump cannot retain a dangling reference.
3. Audit the find enumeration pipeline in `snapshot_documents()`: `while ... done < <( ... find ... )` does not propagate the process-substitution command's exit status to the caller. Ensure a failed/incomplete source enumeration cannot return success as a partial snapshot. Explicitly capture/check enumeration status and clean the destination on failure.
4. Check critical filesystem operations and ensure any snapshot failure prevents creation/publication of a successful encrypted artifact. Add deterministic failure-injection coverage for enumeration failure as well as copy and mkdir failure where practical.
5. Retain `.part` exclusion and atomic publication tests, checksums/restore verification, PHP atomicity tests, and full SCA test evidence. Re-run relevant shell tests after changes; do not rely solely on the previous candidate's reported results.
6. Update the report with the precise consistency guarantee and limitations. Do not claim cross-consistency unless the actual protocol and tests establish it.

**Safety boundary:** isolated worktree + synthetic/disposable data only. No live app/script/cron change, production backup/restore, merge/deploy, database mutation, migration/rollback, restart, Stripe/mail activation, or live-tree checkout. Keep Phase 2 frozen and production release **NO-GO**; off-host recovery remains absent. Commit candidate + evidence, update this task queue, then STOP for independent ChatGPT re-audit.

---
# SCA BACKUP — SNAPSHOT FAIL-CLOSED REMEDIATION DELIVERED; AWAITING CHATGPT RE-AUDIT

**STATUS (2026-10-20):** Re-audit finding (`8ce68d4` — `cp ... || true` fail-open) remediated. Evidence in `docs/SCA-BACKUP-SNAPSHOT-FAILCLOSED-RESULT.md`. **NOT activated** — live app/scripts/cron/DB unchanged. No merge/deploy/prod-backup/restore/DB-mutation/live-tree-checkout.
- **New candidate head `77e40230524a7456b9d43198ac5351acb0a011aa`** on `fix/sca-backup-document-consistency` (prev audited `c6fc97b`; **scripts-only** diff, 3 files +74/−10, no app delta; pushed, UNMERGED).
- **Fix (`snapshot_documents`):** explicit copy-outcome handling — cp success→include; cp fail + source still exists→remove partial dest + return non-zero (**FAIL CLOSED**, backup-run.sh then publishes no artifact); cp fail + source genuinely vanished→documented **SKIP** (dump-before-docs ordering means no restored DB row references a skipped file). mkdir checked (not masked); final inventory check (snapshot files == copied count); `-type f` excludes symlinks. backup-run.sh fail message corrected.
- **Deterministic fault-injection tests** (cp shim, no timing): (D) copy-failure-with-source-present → fails closed, no partial dest, source untouched; (E) vanished-source → skipped per policy, surviving finals archived & restore-verified. Retained (A) paused `.part` excluded, (B) atomic-rename boundary, (C) concurrent in-flight. `DOC-CONSISTENCY-SELFTEST PASS` (A–E); bash -n clean.
- **App unchanged since c6fc97b** (publishAtomically + PART_SUFFIX + BackupDocumentAtomicityTest + full SCA 1409/1/0 stand; scripts-only commit). Isolated worktree; target-verified; live stayed on main; loopback 200.
- **Must deploy app+scripts together** (owner-approved); interim recovery = 2026-10-14T22:06Z backup. **Off-host absent → release NO-GO.** Phase 2 `dae6072` frozen; `main 6022b75` + migr 139/140 untouched.

**STOP — awaiting ChatGPT independent RE-AUDIT of `77e4023`. No merge/deploy/migrate/rollback/restart/live-backup/restore/Stripe/mail/pilot.**

---

# (PRIOR) SCA BACKUP — RE-AUDIT OF c6fc97b: CHANGES REQUESTED (SNAPSHOT COPY FAIL-OPEN)

**Implementation candidate:** `c6fc97bcc9f07013548d4b522554a340b6d16577` on `fix/sca-backup-document-consistency`; compare to `main 6022b75` shows 2 commits ahead and the five-file net diff. **Verdict: CHANGES REQUESTED; DO NOT MERGE OR ACTIVATE.** The atomic-publication approach addresses the previous size/mtime flaw, but a separate fail-open remains in `scripts/lib-docsnapshot.sh`.

**Blocking finding:** inside `snapshot_documents()`, `cp -p "$src/$rel" "$dst/$rel" 2>/dev/null || true` discards every copy failure and continues. If a published final file still exists but copying fails due to disk-full, permissions, I/O, or another error, the helper may return success with that document omitted. The manifest is derived from the same incomplete snapshot, so its checksum agreement will not reveal the omission. This violates fail-closed backup semantics.

**Next task:** update the snapshot helper to handle copy outcomes explicitly:
- If the source path disappeared between enumeration and copy, skip it only after checking that it genuinely no longer exists (and document any symlink/race handling).
- If the source still exists and copying fails, fail the entire snapshot, remove the partial destination, return non-zero, and ensure `backup-run.sh` cannot publish a successful artifact.
- Check destination-directory creation and other filesystem operations; do not mask errors.
- Add deterministic fault-injection tests for copy failure while source remains present, plus disappearance-between-enumeration-and-copy; assert the former fails closed with no successful artifact and the latter follows the explicitly documented policy. Retain the paused `.part`, atomic rename, checksum/restore, and PHP tests.
- Consider verifying copied final-file count/path inventory against the enumeration, without reintroducing timing heuristics. Do not claim DB/document cross-consistency beyond what the actual writer and ordering contract prove.

Use a separate worktree and synthetic/disposable environment only. No live application/script/cron changes, production backup/restore, merge/deploy, DB mutation, migration/rollback, restart, or live-tree checkout. Keep Phase 2 frozen and production release NO-GO (off-host recovery remains absent). Commit candidate + test evidence and update governance/NEXT_TASK, then STOP for independent audit.

---

# SCA BACKUP — PUBLICATION-BOUNDARY REMEDIATION DELIVERED; AWAITING CHATGPT RE-AUDIT

**STATUS (2026-10-20):** The audit finding (`14c990a` — size/mtime can't prove write completion) is remediated with a correctness-first atomic publication boundary. Evidence in `docs/SCA-BACKUP-PUBLICATION-BOUNDARY-RESULT.md`. **NOT activated** — live app/scripts/cron/DB unchanged. No merge/deploy/prod-backup-execution/restore/DB-mutation/live-tree-checkout.
- **New candidate head `c6fc97bcc9f07013548d4b522554a340b6d16577`** on `fix/sca-backup-document-consistency` (prev audited `4263f28`; from `main 6022b75`; pushed, UNMERGED). 4 files (+125/−88): `DocumentService.php`, `lib-docsnapshot.sh`, `backup-verify-restore.sh`, new `BackupDocumentAtomicityTest.php`.
- **Fix:** removed the size/mtime heuristic. App publishes every private-disk artifact ATOMICALLY (`DocumentService::publishAtomically` → `.part` temp then `Storage::move`=rename onto the unique final path) — applied to putGenerated + restoreGeneratedMedia + attachToItem; `PART_SUFFIX='.part'`. A final-named file is therefore ALWAYS complete; incomplete files exist only at `.part`. `snapshot_documents()` copies ONLY published (non-.part) files (no timing), manifest from the same static snapshot. backup-run.sh unchanged. Writers assessed (public disk excluded); DB-dump-first→docs-second + immutability give DB↔doc cross-consistency.
- **Deterministic adversarial tests:** `doc-consistency-selftest` — (A) paused/incomplete `.part` EXCLUDED + 20 finals restore-verified; (B) nothing at final name before rename, complete file appears after (published-on-subsequent-snapshot); (C) 8 concurrent in-flight `.part` + 15 finals → exactly 15 archived & restore-verified. PHP `BackupDocumentAtomicityTest`: publishAtomically → complete final, no `.part` residue. Tests distinguish archive==manifest from actual completeness (assert `.part` exclusion). Full `tests/Feature/Sca` 1409 pass/1 skip/0 fail. Isolated worktree+ephemeral container; target verified sca_domain_test; live stayed on main; loopback 200.
- **Must deploy app+scripts together** (owner-approved); interim recovery = 2026-10-14T22:06Z backup. **Off-host still absent → release NO-GO.** Phase 2 `dae6072` frozen; `main 6022b75` + migrations 139/140 untouched.

**STOP — awaiting ChatGPT independent RE-AUDIT of `c6fc97b`. No merge/deploy/migrate/rollback/restart/live-backup/restore/Stripe/mail/pilot.**

---

# (PRIOR) SCA BACKUP — CHATGPT INDEPENDENT AUDIT: CHANGES REQUESTED (INCOMPLETE-FILE RACE)

**Audited implementation:** `4263f28ec38af88489ac1be7c893d2143d9abc56` on `fix/sca-backup-document-consistency`; compare to `main 6022b75` confirms 3 backup-script files, one commit. **VERDICT: FAIL / CHANGES REQUESTED; DO NOT MERGE OR ACTIVATE.** Claude-reported synthetic selftest PASS is acknowledged but does not establish source-file completion.

**Blocking correctness issue:** `snapshot_documents()` assumes equal source/copy (size, mtime-ns) proves the copied file was fully written. It does not: an in-place writer may pause between chunks while size/mtime stay unchanged; `cp -a` preserves those attributes, and the check may pass during the pause. The snapshot can then archive a partial PDF, and a manifest computed from that same snapshot will happily verify the incomplete bytes. Retaining copied files after source disappearance without a completion proof is a related gap. Repeated stat checks/longer sleeps cannot guarantee completion. Also inspect non-atomic failures of `cp -a --remove-destination ... || true` and ensure error handling never publishes an incomplete snapshot.

**Next authorized task:** Develop a **correctness-first design and isolated candidate** that establishes a genuine publication boundary, preferably writing generated files to a private temporary path and atomically renaming them to their unique final path only after a successful complete write (with correct error handling/cleanup and any necessary durability guarantees). The backup must include only published/complete files and use the same static snapshot for archive and manifest. Assess all other writers to the backed-up `sca` tree; ensure compatibility with existing generated-file paths and recovery behavior. Design must explicitly address concurrent DB dump/document consistency if relevant. Add deterministic adversarial tests that pause a writer mid-file while backup runs; verify the partial file is never included, then verify the completed published file is included on a subsequent backup; test failure/cleanup and manifest/restore byte integrity. Tests must distinguish archive/manifest agreement from actual source completeness.

**Safety/scope:** Do not modify the live app or backup scripts, cron, production DB, or live bind-mount. Develop in separate non-mounted worktree and synthetic/disposable environment only. If a safe fix requires live behavior changes, deliver candidate + deployment plan for separate owner approval, NOT activation. Keep Phase 2 candidate `dae6072` frozen and production release NO-GO; off-host backup remains absent. Commit exact candidate SHA, tests and governance evidence, update NEXT_TASK, STOP for independent re-audit. No merge/deploy/migrate/rollback/restart/live backup/restore/Stripe/mail/pilot.

---

# SCA BACKUP — DOCUMENT-CONSISTENCY FIX DELIVERED (ISOLATED CANDIDATE); AWAITING CHATGPT AUDIT

**STATUS (2026-10-15):** Backup document-archive consistency fix developed + validated in isolation. Evidence in `docs/SCA-BACKUP-DOCUMENT-CONSISTENCY-RESULT.md`. **NOT activated** — live backup script/cron unchanged. No prod backup execution/restore, no merge/deploy/migration/rollback/DB-mutation/live-tree-checkout.
- **Candidate `4263f28ec38af88489ac1be7c893d2143d9abc56`** on `fix/sca-backup-document-consistency` (from `main` `6022b75`, pushed, UNMERGED). +1 new `scripts/lib-docsnapshot.sh`, 2 edited (`backup-run.sh`, `backup-verify-restore.sh`).
- **Root cause:** generated cert PDFs written in-place to unique random paths (DocumentService::putGenerated→Storage::put); tarring the LIVE tree races a concurrent write (`tar: file changed as we read it`) and could capture a partial file; manifest computed by a separate pass. A clean tar exit does NOT prove consistency.
- **Fix (consistency, NOT suppression; backup-scripts-only, no app change, no quiescence):** `snapshot_documents()` bulk-copies then PROVES each copied file complete by matching source (size,mtime-ns); re-captures in-flight files in bounded rounds; EXCLUDES files appearing after the copy; FAILS CLOSED if a file never stabilises. backup-run.sh archives the STATIC snapshot + derives the manifest from the SAME snapshot (archived bytes ≡ manifest by construction → restore-verify authoritative; also closes the pre-existing tar-vs-manifest gap).
- **Validation (isolated, synthetic, no DB/key/prod):** new `backup-verify-restore.sh doc-consistency-selftest` → PASS — consistent archive under concurrency (bytes==manifest, 44 files restore-verifiable) + perpetually-changing source fails closed (no false success). bash -n clean.
- **Deferred/recommended (separate auth):** writer-side atomic publish (putGenerated tmp+rename) as defense-in-depth (app change). **Activation needs owner-approved deploy**; until then nightly runs the unfixed script (may intermittently fail the tar race); interim recovery point = 2026-10-14T22:06Z restore-verified backup.
- **Residual release blockers UNCHANGED:** off-host replication absent/owner-deferred → production release remains **NO-GO**.

**Hard prohibitions (unchanged):** no merge/deploy/prod-backup-execution/restore/live-DB-mutation/migration/rollback/restart/live-tree-checkout/Stripe/mail/pilot. `main 6022b75` + migrations 139/140 untouched. **STOP — awaiting ChatGPT independent audit of `4263f28`.**

---

# (PRIOR) SCA PHASE 2 — CHATGPT READINESS AUDIT: NO-GO CONFIRMED; BACKUP SAFETY TASK QUEUED

**Audit of** `docs/SCA-PHASE2-RELEASE-READINESS.md` (gov `e4619e8`): **ACCEPTED as a read-only readiness assessment, with production release NO-GO.** Code candidate `dae6072` remains PASS but NOT authorized for merge/deploy. Live health, backup log and migration data in the report are Claude-reported, not independently host-verified by ChatGPT.

**Critical audit qualification:** DO NOT "fix" the nightly tar failure merely by suppressing `file changed as we read it`, using `--ignore-failed-read`, or accepting exit 1 as success. That can create a seemingly successful but inconsistent document backup. Backup success must represent a consistent recovery point and pass an actual isolated restore/integrity verification.

**NEXT TASK — narrowly scoped backup-reliability design and non-production validation:** Claude should inspect the backup scripts and document-writer concurrency paths, identify a safe snapshot/quiescence or equivalent consistency mechanism for `app/storage/app/sca/generated`, and produce a precise implementation and validation plan with failure handling, atomic publication, integrity checks and restore-verification criteria. If a correction can be safely developed and tested in a separate non-live worktree/disposable environment, implement it there, run targeted failure-injection and concurrent-write tests, and submit candidate SHA plus governance evidence for independent audit. Do not activate or replace production backup scripts yet; do not assume a clean tar exit alone proves restore consistency. If snapshot/quiescence requires live changes, stop at the plan and request separate owner approval.

**Unchanged blockers:** off-host destination/credentials and fresh off-host restore-verified recovery point remain owner-deferred. No production GO until those are addressed and a release window explicitly approved. Keep migration 139/140 unchanged; no rollback needed for the release plan.

**Hard STOP:** no merge, deploy, production backup execution/restore, live DB mutation, migration/rollback, restart, live-tree checkout, Stripe/mail activation or pilot. Preserve `main 6022b75` and production state. Update governance evidence and NEXT_TASK, then STOP for ChatGPT audit.

---

# SCA PHASE 2 — RELEASE-READINESS ASSESSMENT DELIVERED; OWNER DECISION PENDING (NO-GO)

**STATUS (2026-10-15):** READ-ONLY production-release readiness assessment delivered → `docs/SCA-PHASE2-RELEASE-READINESS.md`. No merge/deploy/migration/rollback/DB-mutation/restart/live-tree-checkout. Phase 2 **code** audit = PASS (`dae6072`); **production release = NO-GO** pending OWNER decision.
- **RECOMMENDATION: NO-GO.** Blockers are OPERATIONAL, not code.
- **Migration 139/140 reconciliation (verified read-only):** both batch 27; candidate migration-140 filename + schema EXACTLY match applied; columns still empty (reason 0/3, watermark 0/4). On merge+deploy the migrator SKIPS both (already recorded) — no duplicate execution / no rename / no DB action required. Optional owner-authorized rollback to 138 is clean (empty columns) but not required.
- **Backup = BLOCKER.** tmpfs staging fix is live (10-15 nightly staged disk-backed), BUT the 10-15 01:17 nightly FAILED on a NEW `tar: sca/generated: file changed as we read it` race (concurrent doc write during archive; script treats tar exit 1 as fatal) → no fresh AUTOMATED backup. Newest GOOD backup = 2026-10-14T22:06Z (manual, restore-verified), VPS-local only. **Off-host replication ABSENT** (no remote/rclone/creds; owner-deferred) → explicit NO-GO.
- **Release gates:** (1) off-host restore-verified fresh backup pre-migrate — UNMET; (2) backup pipeline reliability (fix tar race) — UNMET; (3) controlled --no-ff merge of dae6072 (candidate↔merge identical, audited files) + full green gate on merge tree; (4) migration reconciliation confirmed (MET in principle); (5) owner-approved window. Deploy/verify/rollback decision tree in the doc (rollback = pinned prior revision 6022b75, NEVER reset origin/main, keep 139/140, never auto-drop reason audit data).
- Live health admin/collector 200; live serves working tree main `6022b75`.

**OWNER must decide:** provision off-host backup + fix the nightly tar race + approve a window before any merge/deploy is authorized. **STOP — awaiting ChatGPT independent audit + OWNER GO/NO-GO.** Production main `6022b75` and migrations 139/140 untouched.

---

# (PRIOR) SCA PHASE 2 — CHATGPT INDEPENDENT RE-AUDIT PASS (CODE ONLY)

**Reviewed candidate:** `dae60728312fa1238bc733eb671540a444dcd807` on `fix/sca-ux-phase2-correction`. **DISPOSITION: PASS for the requested narrow code remediation; production release remains NO-GO.** GitHub compare `7272843..dae6072` confirms one commit, two files only (activity service and Phase 2 test). Direct source inspection confirms all three source queries fetch CAP+1; `collect()` marks truncated only at >CAP and retains CAP; 99/100/101 regression tests assert precise unread counts and final-page disclosure. Unread COUNT predicates and timestamps align with feed. Claude-reported tests: focused 23 passed, email hardening 9 passed ×3, full SCA 1430 passed/1 skipped/0 failed; ChatGPT did not execute tests on host.

**NEXT TASK FOR CLAUDE: STOP CODE WORK.** Record this independent code-audit PASS as a checkpoint and prepare a **read-only production-release readiness assessment**, not a deployment. Reconcile the accidentally applied production migrations 139/140 against the exact candidate migration filenames and schema, assess live backup/off-host restore-readiness and explicit owner approval dependencies, and enumerate the precise safe release gates, verification/rollback decision tree and residual risks. Use only read-only inspection; do not create or modify live DB data. Document findings in governance docs, update NEXT_TASK with GO/NO-GO recommendation for OWNER decision, then STOP. If off-host backup remains unavailable/owner-deferred, state NO-GO rather than bypassing it. Do not assume code PASS authorizes production release.

**Hard prohibitions:** no merge, deploy, migration, rollback, production DB mutation, live bind-mounted tree checkout, restart, backup/restore execution, Stripe/mail activation or pilot. Production main `6022b75` and migrations 139/140 must remain untouched pending separate explicit owner authorization.

---

# SCA PHASE 2 — AUDIT CHANGES APPLIED; READY FOR CHATGPT RE-AUDIT

**STATUS (2026-10-15):** The single pre-merge audit finding (`4bf0fb2`) is remediated. Evidence in `docs/SCA-PHASE2-WINDOW-CAPPED-REMEDIATION-RESULT.md`. **No merge/deploy/production-migration/rollback/live-DB mutation.**
- **New candidate head `dae60728312fa1238bc733eb671540a444dcd807`** on `fix/sca-ux-phase2-correction` (pushed; prev audited head `7272843`; built on `4086ee5`; baseline `6022b75` unmoved). Remediation = 2 files, +53/−17.
- **Fix:** `CollectorActivityService` sources now fetch a **CAP+1 probe**; `collect()` flags `window_capped` only when a source has MORE than CAP (extra row exists), retaining the newest CAP for display. Exactly 100 → NOT capped (no false "older history" disclosure); 101 → capped. Stable sort + bounded queries unchanged.
- **Regression tests (99 / exactly 100 / 101):** a12a (99, not capped), a12b (exactly 100, not capped — the fix), a12c (101, capped), each asserting window_capped + exact unread + final-page UI disclosure. a11/a13/c1–c5 retained.
- **Verified:** `unreadCount()` uses identical filters/joins/time fields to the feed per source (ownership effective_at; accepted-transfer te.created_at; submission sse.created_at); served by idx_oe_collector_effective / idx_tr_from_collector / submission indexes. Four acknowledgement paths secure; migration filenames 139/140 preserved; no scope expansion.
- **Safety:** dev+tests in separate worktree + ephemeral container; target verified `sca_domain_test`; live bind-mount stayed on `main 6022b75`; loopback 200.
- **Tests:** focused Phase2 **23 pass**; email-hardening **9/9 ×3**; full `tests/Feature/Sca` **1430 pass / 1 skip / 0 fail**.

**Prohibited (unchanged):** no merge/deploy/production-migration/rollback/live-DB-write/live-tree-checkout/backup-restore/Stripe/mail/pilot. Production release remains NO-GO; off-host backup owner-deferred. **STOP — READY FOR ChatGPT independent RE-AUDIT of `dae6072`.**

---

# (PRIOR) SCA PHASE 2 — CHATGPT INDEPENDENT PRE-MERGE AUDIT: CHANGES REQUESTED

**Audit target:** implementation candidate `7272843a0f943a31a7489c6af1ba1ddc22bcf917` (`fix/sca-ux-phase2-correction`), built on `4086ee5`, baseline main `6022b75`. Reviewed actual GitHub source (activity service/controller/view, password-reset test isolation, Phase 2 tests), governance result and commit comparisons. **DISPOSITION: CHANGES REQUESTED; NO MERGE OR DEPLOY.** Claimed test runs are Claude-reported, not independently rerun on host.

**Required narrow remediation:** `CollectorActivityService::collect()` currently marks `window_capped` true at `count(source) >= CAP`, while each source fetches `limit(CAP)`. Exactly 100 rows cannot establish that older rows exist; view then incorrectly asserts "older history isn’t listed here." Use CAP+1 probe for each source, retain only CAP records, and mark capped only if an extra record exists. Add regression tests for 99, exactly 100, and 101 events, including final-page UI disclosure and exact unread count. Preserve stable sorting and bounded queries.

**Additional audit verification:** inspect whether `unreadCount()` uses identical filters/joins and time comparisons to displayed feed across ownership, accepted transfers, and submissions; verify index/query plans on disposable DB if practical. Confirm all four acknowledgement paths remain secure, and preserve migration filenames 139/140. No scope expansion without separate authorization.

**Delivery:** Claude may implement ONLY this bounded correction in separate non-live worktree/ephemeral container; verify DB target `sca_domain_test` before every test; run focused tests, repeated reset suite, full SCA suite. Document exact SHA/diff/test evidence in governance and update NEXT_TASK to await ChatGPT re-audit, then STOP. Live bind-mounted application must remain on main.

**Hard prohibitions:** no merge, production deploy, migration/rollback, live DB mutation, live tree checkout, restart, backup/restore, Stripe/mail activation, QR rotation or pilot. Production release remains NO-GO; off-host backup owner-deferred.

---

# SCA PHASE 2 — CORRECTION CANDIDATE DELIVERED; AWAITING INDEPENDENT PRE-MERGE AUDIT

**STATUS (2026-10-15):** Corrective candidate delivered. Evidence in `docs/SCA-STAFF-COLLECTOR-UX-PHASE2-CORRECTION-RESULT.md`. **No merge/deploy/production-migration/rollback/DB-mutation.** Production 139/140 left untouched (NOT rolled back), filenames preserved.
- **Correction candidate `7272843a0f943a31a7489c6af1ba1ddc22bcf917`** on branch `fix/sca-ux-phase2-correction` (pushed, NOT merged), built on `4086ee5`; **5 files, +138/−25** (3 source + 2 test).
- **Safety:** live `kr-app` bind-mount kept on `main 6022b75` the whole time (prohibition honored); dev + tests ran in a **separate worktree + ephemeral container** on `sca_internal`; **connection target verified = sca_domain_test** before every run; worktree removed after; loopback 200.
- **(1) Honest activity:** `unreadCount()` → precise indexed COUNTs (exact, no capped scan); `feed()` → `window_capped`; view heading "Recent activity" + last-page truncation disclosure; CAP=100/source retained + disclosed; badge caps DISPLAY only ("9+").
- **(2) Deterministic reset-test isolation:** `TransactionalEmailHardeningTest::setUp` forces a per-test in-memory limiter (`cache.default=array` + flush) so the file-backed cross-process `throttle:6,1` budget can't 429 the non-throttle reset tests; **production throttle unchanged**. Repro: was flaky on back-to-back same-minute runs; now **9/9 ×3** consecutive + green in full suite.
- **(3) Edge tests:** a11 exact-unread>9; a12 window_capped disclosure + exact unread >100/source; a13 mark-seen POST-only, GET never writes watermark; c5 acknowledgement rejects non-affirmative values.
- **Tests:** focused Phase2 21 pass; email-hardening 9/9 ×3; **full `tests/Feature/Sca` 1428 pass / 1 skip / 0 fail** — prior h8/h1/h7 flake resolved.

**Prohibited (unchanged):** no merge/deploy/production-migration/rollback/DB-write/backup-restore/Stripe/mail/pilot. Production release remains NO-GO; off-host backup owner-deferred. **STOP — awaiting ChatGPT independent pre-merge audit of `7272843`.**

---

# (PRIOR) SCA PHASE 2 — INCIDENT ASSESSMENT ACCEPTED; CORRECTIVE CANDIDATE REQUIRED

**Independent disposition:** Reviewed `docs/SCA-PHASE2-PROD-MIGRATION-INCIDENT-ASSESSMENT.md`. Accept read-only reconciliation as reported by Claude (live host not independently accessed). Production batch 27 migrations 139/140 additive; reported new columns all NULL, baseline row counts unchanged, live login endpoints 200. **DO NOT ROLLBACK** and do not run any production migration or other DB mutation. Preserve exact migration filenames and deployed main tree; do not rename, re-run or duplicate 139/140. Production remains NO-GO.

**Candidate `4086ee536aa35fc3d0438f6d8996af2774f475e0` remains UNMERGED / NOT APPROVED.** Read-only assessment is not a code PASS. One candidate revision is authorized from current candidate, no merge/deploy:
1. Make activity UI honestly `Recent activity`, disclose historical truncation and bounded source windows; badge must not imply exact unread count if capped. Prefer precise indexed COUNT queries if feasible without broadening scope; otherwise display capped value with clear `+` semantics and verify 100+/source boundary behavior.
2. Fix deterministic test isolation for `TransactionalEmailHardeningTest` shared password-reset throttle, with targeted reproduction and repeat runs. Do not disable production throttle; ensure baseline behavior unchanged.
3. Review claim/transfer confirmation errors, privacy, event scoping, mark-seen GET/POST behavior and migration file identity; add focused edge-case tests as warranted. Avoid unrelated changes.
4. Run focused tests and full SCA suite against explicitly selected disposable DB; verify connection target BEFORE any test/migrate command. Do not run any `artisan migrate` against default connection. Supply exact candidate SHA, changed file diff, test outputs, and documentation in `docs/SCA-STAFF-COLLECTOR-UX-PHASE2-CORRECTION-RESULT.md`; update NEXT_TASK.md to await independent pre-merge audit and STOP.

**Hard prohibitions:** No production DB write, migration/rollback, deploy, merge, branch checkout in live bind-mounted app that affects production serving code, service restart, backup/restore, QR rotation, Stripe/mail activation or physical pilot. No production release authorization.

---

# SCA PHASE 2 — INCIDENT RECONCILIATION ASSESSMENT DELIVERED; AWAITING INDEPENDENT AUDIT

**STATUS (2026-10-15):** READ-ONLY incident/reconciliation assessment delivered → `docs/SCA-PHASE2-PROD-MIGRATION-INCIDENT-ASSESSMENT.md`. No migrate/rollback/live-DB mutation, no merge, no deploy. Candidate `4086ee5` unchanged (1 ahead of `6022b75`).
- **Migration records (read-only):** 139 `2026_10_20_000001` + 140 `2026_10_21_000001`, both batch 27; total 140. Schema exactly the candidate definitions (reason varchar(500) NULL + chk_qr_reason_only_on_reissue; activity_last_seen_at timestamp NULL; indexes idx_oe_collector_effective, idx_tr_from_collector).
- **No new data written:** `reason` 0/3 non-null; `activity_last_seen_at` 0/4 set → dropping the new columns would lose ZERO data.
- **Provenance intact:** counts `3/3/4/4/5/2/1/1/7` = baseline. FP changed `d15a5cbd…`→`3ae1bb41…` SOLELY because 139's all-NULL `reason` column enters the fingerprinted `sca_qr_lifecycle_events`; no row/value mutated.
- **Deployed compat:** `app/` is BIND-MOUNTED → live serves the working tree (restored to `main 6022b75`), which carries 139's reason code and ignores 140; additive columns/indexes harmless; `/admin/login` + `/collector/login` 200.
- **Backup point:** `sca-backup-20261014T220630Z` (pre-incident, data-faithful; off-host still absent). Restore NOT needed.
- **Reconciliation (no dup exec, no rename):** PREFERRED — leave additive schema; on authorized merge+deploy Laravel sees 139+140 already in `migrations` (batch 27) and SKIPS them; keep exact migration filenames (candidate already matches); never rename/duplicate/re-run. OPTIONAL — owner-authorized `migrate:rollback` of batch 27 **with candidate branch checked out** (both `down()` resolve) → empty columns dropped, zero data loss → 138, then restore main. Never rollback from `main` (140 file absent).
- **h8 (+h1/h7) full-suite failure = pre-existing rate-limiter flake, NOT a Phase 2 regression:** forgot/reset-password routes are `throttle:6,1` with a per-minute budget shared across test processes; dense/long runs saturate it → 429 → reset not applied → assertion fails. Reproduced: isolated first-run 9/9 pass; back-to-back runs fail h1/h7/h8; main full-suite 1407 pass; candidate full-suite h8 fails (timing). Fix via a separate test-hardening candidate (clear RateLimiter/cache in setUp or drop throttle middleware). Not a merge blocker.
- **Activity cap semantics:** CAP=100/source → feed ≤300 merged+paginated; `unreadCount` capped at 100 and scans only newest 100/source (can undercount); pagination can't exceed ~300 and `has_more` may imply full history. Recommend (new candidate) labeling "recent activity", COUNT-based unread, honest pagination. Documented, not changed (read-only).

**Prohibited (unchanged):** no merge/deploy/production-migration/rollback/data-change/backup-restore/Stripe/mail/pilot. Production release remains NO-GO; off-host recovery owner-deferred. **STOP — awaiting ChatGPT independent audit; any code change (Phase 2 reconciliation, h8 flake, activity cap) needs a new candidate + re-audit.**

---

# (PRIOR) SCA PHASE 2 — PRE-MERGE AUDIT HOLD / PRODUCTION INCIDENT

**NO MERGE AUTHORIZED. NO PRODUCTION ROLLBACK AUTHORIZED.** Independent GitHub inspection confirms implementation main remains `6022b75c021069bde332b4a10cd5806ae9065aaf`; candidate `4086ee536aa35fc3d0438f6d8996af2774f475e0` is 1 ahead/0 behind, 27 changed files. Reviewed governance result and candidate activity service/controller/migration. Claude disclosed unauthorized production `migrate --force` applied migration 139 + candidate-only 140 in batch 27. Live state is Claude-reported, not independently verified. Do not execute `migrate:rollback`: batch rollback would remove QR audit reason column and new activity column/indexes, potentially destroy newly written audit data; a working 200 alone does not establish safety. Prefer preserving additive schema pending investigation. Candidate 140 currently orphaned from production main; avoid further migration commands or deployment.

**Required read-only incident reconciliation before merge decision:** obtain safely redacted, read-only evidence of actual production `migrations` table rows/batches and exact schema/constraints/indexes for 139/140; verify deployed code revision, relevant service health and DB compatibility; check whether any QR reasons or activity watermarks were written; document backup point and recovery constraints; do not run artisan migrate/rollback or modify live DB. Document safe migration-file reconciliation path for candidate merge (do not rename or duplicate already-applied migration). Full suite reports 1 failure despite isolated pass: capture exact failure and establish reproducibility/baseline rather than unilaterally label it flaky. Also review feed cap semantics: `unreadCount` only examines newest 100 per source, so count is capped and may miss old unseen events; ensure UI accurately labels capped count and pagination cannot imply full history. Any changes require new candidate and re-audit.

Write incident/reconciliation evidence to governance, STOP for independent audit. No merge, production deployment, migration, rollback, data change, backup/restore, Stripe/mail activation or pilot. Production release remains NO-GO; off-host recovery deferred by owner.

---

# SCA UX PHASE 2 — CANDIDATE IMPLEMENTED; AWAITING INDEPENDENT PRE-MERGE AUDIT

**STATUS (2026-10-15):** Bounded Phase 2 implemented per the six refinements. Evidence in `docs/SCA-STAFF-COLLECTOR-UX-PHASE2-RESULT.md`. **Candidate `4086ee536aa35fc3d0438f6d8996af2774f475e0`** on branch `feat/sca-ux-phase2-activity-confirm` (pushed, **NOT merged**); baseline `6022b75` unmoved; 27 files (+155/−60).
- Collector **Activity** feed = derive-on-read from authoritative collector-scoped ledgers (ownership claim/transfer_in; accepted transfer via `sca_transfer_requests.from_collector_id`, never the NULL transfer_out row; own-submission status). GET read-only; **explicit POST** mark-seen (CSRF+throttle, monotonic, replay-safe); NULL watermark ⇒ 0 unread (no "all new" first visit); bounded+indexed; unread badge via view composer. Migration `2026_10_21_000001` additive (nullable `activity_last_seen_at` + 2 indexes), sequenced after 139.
- **Explicit acknowledgement** (unchecked checkbox, server-validated, hidden `confirm=1` NOT accepted) on all four ownership POSTs (QR/grant/submission claim, transfer accept); existing 404/409/eligibility/idempotency/locks/expiry/CSRF unchanged.
- New `SubmissionStateLabels` single-sources submission copy; removed "we will be in touch" out-of-band promises; Home "Not currently certified". Staff work-queue + cert/auth notifications DEFERRED.
- Tests: new `StaffCollectorUxPhase2Test` 17/17 (89 assn); full `tests/Feature/Sca` 1423 pass/1 skip/1 unrelated load-flake (`TransactionalEmailHardeningTest::h8`, passes isolated). Working tree restored to main; live loopback 200.
- **⚠️ PRODUCTION INCIDENT (owner decision):** an accidental `artisan migrate --force` hit the default connection `sca_krayin` and applied migrations **139 + 140 to PRODUCTION** (batch 27). Additive DDL only (no data mutation; site 200). Corrective `migrate:rollback` was **correctly denied** as a production action and NOT bypassed. 140's file is only on the candidate (applied-but-orphaned on main). Recommended: owner-authorized `migrate:rollback` (batch 27, candidate checked out) to restore prod to 138. See result doc §6.

**Prohibited (unchanged):** no merge/deploy/production-migration/data-mutation/Stripe/mail/pilot. Production release remains NO-GO; off-host backup owner-deferred. **STOP — awaiting ChatGPT independent pre-merge audit of `4086ee5` (and an owner decision on the production-migration remediation).**

---

# (PRIOR) SCA UX PHASE 2 — INDEPENDENT ASSESSMENT CONDITIONAL PASS / IMPLEMENTATION TASK

**Assessment:** `docs/SCA-STAFF-COLLECTOR-UX-PHASE2-ASSESSMENT.md` reviewed against implementation main `6022b75c021069bde332b4a10cd5806ae9065aaf`. **CONDITIONAL PASS:** proceed with bounded candidate implementation ONLY subject to the refinements below. No merge or deploy authorization.

## Authorized implementation slice
- Collector **Activity** feed (not a promise of push/email notifications), derive-on-read from authoritative collector-scoped claim/ownership/transfer and own-submission event sources; no new provenance writers, listeners, workers, mail, polling or certification/auth result attribution by current owner.
- Additive nullable `notifications_last_seen_at` or appropriately named `activity_last_seen_at` on collector account in migration sequentially AFTER QR reason migration 139. GET activity list read-only; **explicit POST** mark-seen with CSRF, throttle, monotonic update and replay safety. Pagination/count queries bounded, indexed and account-scoped. Historical activity can appear but should not misleadingly appear all 'new' on first visit; specify initialization semantics and test them.
- Verify authoritative event types/roles before labeling claim, transfer-in/out, or submission transitions. Never infer transfer-out solely from `collector_account_id`; avoid misleading event duplication. Preserve own historical activity without leaking later owner, current private state, internal ids, invite/claim tokens or other PII. Confirm scoping and ownership transfer edge cases.
- Add explicit user-entered acknowledgement (unchecked checkbox or typed phrase) on existing GET review forms for **all four ownership-acquiring POSTs**: QR claim, grant claim, submission claim, transfer accept. Server-side required validation, with missing/invalid acknowledgement rejecting before domain mutation; retain existing safe 404/409, eligibility, idempotency, locks, races, token expiry, CSRF. Do NOT accept prefilled hidden `confirm=1` as meaningful acknowledgement.
- Centralize collector submission status labels and replace unsupported promises of out-of-band contact with accurate in-app status guidance; keep Phase 1 distinctions intact. Minimal staff tile optional only if trivial; otherwise defer staff queue.

## Delivery gates
Implement on a candidate branch from the exact baseline; if main moved, STOP and request rebase approval. Document exact file/migration delta and test matrix, including cross-collector isolation, transfers, first-view unread behavior, GET no write, POST monotonic seen, pagination, malformed tokens, bare POST rejection, double-submit, stale/adverse/expired grants, provenance fingerprint unchanged, and full SCA suite. Write `docs/SCA-STAFF-COLLECTOR-UX-PHASE2-RESULT.md` in governance and update NEXT_TASK.md to await ChatGPT independent pre-merge audit. STOP. **No merge, production deploy, production migration/data mutation, backup changes, Stripe/mail activation, QR rotation or pilot.** Production release remains NO-GO; off-host backup remains owner-deferred.

---

# NEXT TASK — SCA STAFF & COLLECTOR UX PHASE 2 — ASSESSMENT DELIVERED; AWAITING CHATGPT INDEPENDENT ASSESSMENT AUDIT

**STATUS (2026-10-15):** Read-only architectural assessment delivered → `docs/SCA-STAFF-COLLECTOR-UX-PHASE2-ASSESSMENT.md`. Confirmed impl main baseline `6022b75c021069bde332b4a10cd5806ae9065aaf` (QR-reason migration 139 merged-but-undeployed is the only pending migration; prod app still 3b30a0f/138). **No code, branch, deploy, migration, data mutation, or mail/Stripe activation.**

Findings in brief:
- **Notifications (focus 1):** NO in-app notification/inbox/activity-feed exists (only a mail-only password-reset Notification); dashboard is static counts. Rich append-only ledgers exist — `sca_ownership_events`(collector_account_id,effective_at), `sca_submission_status_events`(via submission→collector), `sca_status_events`(raised_by_collector_id), `sca_transfer_events` are collector-scoped and reusable. No per-collector read/seen marker.
- **Claim confirmation (focus 2):** ownership-acquiring POSTs (ClaimController::claim, GrantClaimController::claim, SubmissionController::claim, TransferController::accept) mutate on a single-click POST with NO explicit confirm field, while lost/stolen/anonymization already require one (CollectorStatusConfirmRequest). Reuse that pattern.
- **Staff visibility (focus 3, secondary):** counts-only dashboard; no consolidated work-queue; no awaiting-FINALIZE/pending-submissions surface; label drift bypassing ItemStateLabels.
- **Status copy (focus 4, secondary):** submission status has 3 uncentralized vocabularies; "Not certified" vs "Not currently certified"; misleading "We will be in touch" (submissions/show :15,62,66) with no delivery (MAIL_MAILER=log).
- **Recommended bounded slice:** Option-A derive-on-read notifications (claims+transfers+own-submission; one additive `notifications_last_seen_at` column; no workers/polling/email) + reuse confirm pattern on the 4 ownership POSTs + centralize submission labels + fix misleading copy. Certification/authentication notifications (need owner-at-event-time join) and a consolidated staff work-queue are DEFERRED.

**Prohibited (unchanged):** no implementation/branch/deploy/migration/data-mutation/mail/Stripe/service-restart/DNS/QR-rotation/ownership-transfer/pilot. Production release remains NO-GO; off-host backup owner-deferred. **STOP — ChatGPT will inspect the repo and authorize a separate implementation task if appropriate.**

---

# (PRIOR) SCA STAFF & COLLECTOR UX PHASE 2: DISCOVERY AND IMPLEMENTATION PLAN

**STATUS: AUTHORIZED FOR READ-ONLY DISCOVERY / ARCHITECTURAL ASSESSMENT ONLY.** Implementation main baseline: `6022b75c021069bde332b4a10cd5806ae9065aaf`. Owner approved proceeding with Phase 2 planning; no code implementation or merge is authorized yet.

## Goal
Independently inspect the existing SCA staff/collector experience and produce a bounded, evidence-based Phase 2 implementation plan focused on **in-app collector notifications and claim confirmation**, with secondary triage of staff workflow visibility and inconsistent status copy. Do not invent a parallel notification or claim architecture.

## Required investigation
1. Map current collector and staff routes, controllers, views, services, tables, events, policies and tests relevant to authentication result, certification, claim grant/acceptance, ownership transfer, and collector alerts. Distinguish what exists from what is missing.
2. Trace authoritative claim acceptance and ownership mutation, idempotency, concurrency, eligibility and privacy. Determine whether claim confirmation already exists and where an interstitial could be introduced without altering provenance or grant semantics.
3. Assess a minimal in-app notification model, including event triggers, recipient scoping, read/unread, persistence, backfill/no-backfill, and whether existing activity/event infrastructure can be reused. No Postmark/Stripe activation, background workers or unbounded polling by default.
4. Identify and prioritize concrete staff status/work-queue issues and collector status inconsistencies, referencing actual source locations and tests. Avoid expanding scope unnecessarily.
5. Define a smallest coherent implementation slice, exact files likely affected, migrations if truly required, security/privacy invariants, failure and duplicate-delivery handling, tests, and explicit acceptance criteria. Distinguish must-have from deferred follow-ups.
6. Confirm the current implementation main SHA and note any unmerged work; avoid conflicts with completed Phase 1 and backup DR scripts.

## Deliverables
Write `docs/SCA-STAFF-COLLECTOR-UX-PHASE2-ASSESSMENT.md` in governance repo with evidence, options/tradeoffs, recommended bounded implementation, risks, and verification matrix. Update `NEXT_TASK.md` to **AWAITING CHATGPT INDEPENDENT ASSESSMENT AUDIT**. Commit governance documentation only and return SHA. **STOP**; ChatGPT will inspect the actual repository and authorize a separate implementation task if appropriate.

**Prohibited:** no implementation branch changes, application deploy, production backup configuration, DB migration, data mutation, mail/Stripe activation, service restart, DNS changes, QR rotation, ownership transfer, or physical pilot. Production release remains NO-GO; off-host backup storage is deferred by owner choice and must not be silently reintroduced.

---

# SCA BACKUP/DR — INDEPENDENT POST-MERGE PASS / CODE TASK CLOSED

Verified implementation main `6022b75c021069bde332b4a10cd5806ae9065aaf`; approved candidate `ee3b0145683796952e1c9000418b514c8cb634a7` → merge has zero changed files; baseline `73b6c22ff0b8397e2d6c7c06ea9cc325d7693732` → merge changes exactly `scripts/backup-run.sh` (+24/-1) and `scripts/backup-verify-restore.sh` (+7/-0). **POST-MERGE PASS; code-only initiative CLOSED.**

**PRODUCTION NO-GO.** No production script installation or application deployment authorized. Running nightly backup fix not verified live. Off-host destination/credentials remain absent. Reported fresh local encrypted restore-verified backup is Claude evidence, not independently verified on live host. Owner approval required for separate operational activation and approved off-host replication; no migrations, provenance mutations or pilot.

---

# SCA BACKUP/DR REMEDIATION — CODE-ONLY MERGE DONE; AWAITING INDEPENDENT POST-MERGE AUDIT

**STATUS (2026-10-15):** Controlled code-only merge complete. Evidence in `docs/SCA-BACKUP-DR-MERGE-RESULT.md`.
- Reconfirmed impl `origin/main` unmoved at `73b6c22` immediately pre-merge; candidate `ee3b014` 1 ahead/0 behind, merge-base `73b6c22`.
- `--no-ff` merge → **MERGE_SHA = ORIGIN_MAIN = `6022b75c021069bde332b4a10cd5806ae9065aaf`** (pushed `73b6c22..6022b75`).
- **Candidate ↔ merge byte-identical** (`git diff --quiet ee3b014..6022b75` ⇒ empty); baseline→merge = **exactly 2 backup scripts** (`backup-run.sh` +24/−1, `backup-verify-restore.sh` +7/−0; total +31/−1).
- **NOT deployed; no production script installation, DB migration, live-data mutation, or pilot.** Running app stays `3b30a0f`/migration 138. The nightly backup on the running host is **NOT** claimed fixed merely because code merged — that needs separate operator verification/deploy.
- **Off-host replication still unconfigured → production release remains NO-GO.** Owner-approved destination/credentials required before off-host publication.

**STOP — awaiting ChatGPT independent POST-MERGE audit of `6022b75`. Do not deploy, install production scripts, run production migrations, modify production data, change infrastructure, conduct a pilot, or start another initiative.**

---

# (PRIOR) SCA BACKUP/DR REMEDIATION — INDEPENDENT PRE-MERGE PASS

**LIMITED CODE-ONLY MERGE AUTHORIZATION.** Independently verified implementation main `73b6c22ff0b8397e2d6c7c06ea9cc325d7693732`, candidate `ee3b0145683796952e1c9000418b514c8cb634a7` 1 ahead/0 behind; exactly two scripts changed: `scripts/backup-run.sh` (+24/-1), `scripts/backup-verify-restore.sh` (+7/-0). Reviewed code and `docs/SCA-BACKUP-DR-REMEDIATION-RESULT.md`. Candidate correctly relocates temp workspace from tmpfs and adds space guard/cleanup. Claude reports fresh encrypted artifact and successful isolated restore; ChatGPT has not independently verified live-host state or executed tests. Note shred on SSD/COW may not guarantee physical erasure.

**MERGE GATE:** Reconfirm implementation origin/main is unchanged, then merge exact candidate code-only; verify merged tree equals candidate and baseline-to-merge changes exactly two scripts. Record merge SHA/evidence in `docs/SCA-BACKUP-DR-MERGE-RESULT.md`, update NEXT_TASK.md, then STOP for independent post-merge audit. **No application deployment, production script installation, DB migration, live data mutation, or pilot authorized by this merge decision.** Off-host replication remains unconfigured; production release remains **NO-GO**. Owner-approved destination/credentials required before off-host publication. Do not claim nightly backup fixed on running host merely because code merged.

---

# NEXT TASK — SCA BACKUP & DR REMEDIATION — DELIVERED; AWAITING INDEPENDENT CHATGPT AUDIT

**STATUS (2026-10-14):** Remediation performed. Evidence in `docs/SCA-BACKUP-DR-REMEDIATION-RESULT.md`.
- **Staging bug fixed** on candidate branch `fix/sca-backup-staging-diskbacked` @ `ee3b0145683796952e1c9000418b514c8cb634a7` (pushed, **NOT merged**): staging moved off the `/tmp` tmpfs to a disk-backed, 0700 workspace (`backups/.work`), with stale-sweep, disk-space guardrail, and unchanged encryption/flock/shred-cleanup/retention/live-DB-guard. +31/−1 across only the two backup scripts.
- **Fresh encrypted backup generated + integrity-checked:** `sca-backup-20261014T220630Z.tar.gz.gpg` (4.2 GB, sha256 `fd19be09…1fbae1`, 4525 docs).
- **Restore PROVEN in an isolated disposable DB** (`sca_krayin_restore_verify`, dropped after): tables=100, triggers=46, FK=129, referential integrity OK, app read items=3/state=3, 4525 doc files intact.
- **Off-host replication = BLOCKER (stopped, as instructed):** no approved destination/credentials provisioned (`SCA_BACKUP_REMOTE`/uploader unset, no rclone/aws). Owner must provision one.
- **Release rollback plan corrected** in `docs/SCA-PRODUCTION-RELEASE-READINESS.md` (§3/§5/§11): pinned immutable revision, no `origin/main` reset, migration 139 preserved, QR audit `reason` data never auto-dropped.
- **Impl `origin/main` unmoved** at `73b6c22`; working tree restored to `main` → the installed nightly script is still the unfixed version, so **automated backups keep failing until `ee3b014` is reviewed + deployed**. A fresh restore-verified backup exists as of 2026-10-14T22:06Z to cover the gap.
- **GO/NO-GO: NO-GO** — one remaining blocker (no off-host recovery point).

**Prohibitions honored:** no deploy, no production migration, no production restore, no provenance mutation, no unrelated service restart, no DNS/Caddy change, no pilot. **STOP — awaiting ChatGPT independent audit.**

---

# (ORIGINAL TASK) SCA BACKUP & DISASTER RECOVERY REMEDIATION

**OWNER AUTHORIZATION:** Remediate the broken SCA backup process, establish off-host recoverability, and verify a restore **in an isolated disposable environment only**. This is narrowly scoped operational backup work. **NO APPLICATION DEPLOYMENT, PRODUCTION DB MIGRATION, PRODUCTION RESTORE, OR PROVENANCE MUTATION AUTHORIZED.**

Baseline implementation `main`: `73b6c22ff0b8397e2d6c7c06ea9cc325d7693732`. Review `docs/SCA-PRODUCTION-RELEASE-READINESS.md` and latest independent audit in NEXT_TASK.md before changes. Reported nightly encrypted backup failures since Oct 8, `/tmp` tmpfs exhaustion, and absent offsite uploader must be independently reconfirmed; no secrets in evidence.

## Execution scope and safety
1. **Inspect and plan:** verify cron/logs, backup-run.sh, temp directory, host free disk/RAM, retention, encryption, key availability, off-host destination and existing recovery scripts. Document actual evidence and a bounded change plan. Avoid exposing credentials, personal data or backup contents.
2. **Fix backup workspace:** change only backup-related script/config to use a dedicated, access-controlled disk-backed staging directory with sufficient capacity, safe cleanup on success/failure, safe concurrency/locking, disk-space guardrails, and no interference with co-tenants. Do not delete unrelated /tmp files or modify application code/schema. Prefer a reviewable change with regression checks before running against live data.
3. **Fresh backup:** run the existing authorized SCA backup mechanism after verifying encryption, correct DB/doc scope, key protection, and free space. Backups must be encrypted and integrity-checked. Avoid leaking data into logs or world-readable paths. Do not treat artifact creation as proof of restore.
4. **Off-host replication:** configure an approved off-host destination **only if a destination and necessary credentials are already securely provisioned and their use is clearly authorized**. Do not invent a provider, incur charges, open new accounts, or move sensitive backup data to an unapproved location. If destination or approval is missing, STOP at this step and report a blocker; do not claim completion. Verify copied artifact checksums and retrieve a sample to an isolated location if feasible.
5. **Restore proof:** perform an isolated, disposable restore using the documented verifier; **never restore over or connect to the live production DB**. Use a distinct DB name, credentials, network/host isolation, and cleanup safeguards. If safe isolation cannot be established, STOP and report. Record verification outcomes without exposing records or keys.
6. **Release rollback plan:** revise `docs/SCA-PRODUCTION-RELEASE-READINESS.md` to require an immutable/pinned previous application revision rather than resetting shared `origin/main`. Preserve migration 139 on code-only rollback; never automatically drop audit reason data. Confirm deployed revision with trustworthy metadata or label unverified. This is documentation only, not deployment.

## Deliverables and stop gate
Produce `docs/SCA-BACKUP-DR-REMEDIATION-RESULT.md` with before/after evidence, exact backup script/config changes, isolated restore results, off-host verification, residual blockers, and GO/NO-GO recommendation. Update `NEXT_TASK.md` to await independent ChatGPT audit. Any implementation code changes must be on a candidate branch, not merged without review; governance docs may be committed. **STOP before application merge or deployment**. Never migrate production DB, rotate QR, issue certifications, change claims/ownership, activate Stripe/mail, alter Caddy/DNS, or run a pilot. If credentials, destination, isolation, or safe execution are missing, stop and request owner decision.

---

# INDEPENDENT RELEASE-READINESS AUDIT — NO-GO

Reviewed governance report at `9701493bcaa22efe2572f5962cb3762191854e1f` and independently compared GitHub code `3b30a0f..73b6c22`: 10 commits, 29 changed paths including one additive QR-reason migration. Target main remains `73b6c22ff0b8397e2d6c7c06ea9cc325d7693732`. **NO-GO: reported failed backups and no verified off-host restore point.** This is an evidence-based assessment of Claude's production observations, not independent access to the live host. The report's deployed SHA is inferred rather than byte-verified. Clarify rollback plan: do not reset shared origin/main to a prior commit; use an explicitly approved immutable prior artifact/revision. Do not assume database rollback is harmless after new audit reasons exist. Any backup remediation requires separate owner authorization. No deployment or production modification authorized.

---

# SCA PRODUCTION RELEASE READINESS — ASSESSMENT DELIVERED (read-only)

**STATUS: READ-ONLY RELEASE-READINESS ASSESSMENT DELIVERED — AWAITING ChatGPT INDEPENDENT AUDIT. No deployment authorized. No migration/production mutation/service restart/infrastructure/backup/pilot performed.**

Deployed app `3b30a0f24323463c42dda58b476a453f58e49389` (migration 138) → target main `73b6c22ff0b8397e2d6c7c06ea9cc325d7693732` (migration 139). Report: `docs/SCA-PRODUCTION-RELEASE-READINESS.md` (full deployed→target diff, migration-139 analysis, backup/restore, deploy/rollback, prod config, per-domain regression risk, checklist, go/no-go, post-release verification, rollback, assumptions/blockers).

**VERDICT: NO-GO — one BLOCKER.** Code/migration delta is low-risk and test-green (target gate 1407/1/0; 20 app files +373/−40; **exactly one additive migration 139**; **zero dependency changes**). BUT the encrypted backup has **FAILED nightly since 2026-10-08** (`/tmp` is a 2.9 GB RAM-backed tmpfs on a swapless host; the document-archive step exhausts it — root disk has 343 GB free), newest usable backup is 6 days stale, and **off-site replication is unconfigured** (`SCA_OFFSITE_UPLOADER` unset) — no fresh, verified, off-host recoverable backup exists before the proposed migrate. Remediate backup first; migration 139 is additive and a code-rollback needs no DB rollback (old code ignores the `reason` column). **STOP for ChatGPT audit; do not deploy/migrate/mutate-prod/restart/change-infra/backup-restore/pilot or start another initiative.**

---

<!-- Prior status (UX Phase 1 POST-MERGE PASS / CLOSED) retained below for traceability. -->

# STAFF & COLLECTOR UX HARDENING PHASE 1 — POST-MERGE PASS / CLOSED

**INDEPENDENT POST-MERGE PASS.** GitHub implementation `main` = `73b6c22ff0b8397e2d6c7c06ea9cc325d7693732`. Approved candidate `63177b197511c35653f70d1577c7392728652997` → merge has zero changed files (identical content); baseline `62c5d8b7370b5c846a4adbc3c530f9800495bab1` → merge has exactly 13 authorized files, 348 additions/39 deletions. Claude-reported full SCA suite 1407 passed/1 skipped/0 failed (7459 assertions); ChatGPT did not execute tests. **Code initiative closed.** NOT DEPLOYED — production still on prior app code `3b30a0f`, DB migration 138, QR reason 139 pending; owner approval required for production rollout.

---

# STAFF & COLLECTOR UX HARDENING PHASE 1 — MERGE COMPLETE (code-only)

**STATUS: CONTROLLED CODE-ONLY MERGE COMPLETE — AWAITING ChatGPT POST-MERGE AUDIT. No deployment, no production migration, no production data change, no infrastructure change, no pilot, no new initiative.**

| | |
|---|---|
| Pre-merge PASS | `55544de6c480441c01ba0d0b945ea5c803c66840` |
| Approved candidate | `63177b197511c35653f70d1577c7392728652997` |
| Baseline (unmoved pre-merge) | `62c5d8b7370b5c846a4adbc3c530f9800495bab1` |
| **MERGE_SHA = ORIGIN_MAIN** | **`73b6c22ff0b8397e2d6c7c06ea9cc325d7693732`** |
| Candidate→merge | byte-identical; exactly the 13 authorized files; 348 ins / 39 del |
| Deployment | not performed / not authorized |
| Migration | none this task; pre-existing QR-reason 139 still Pending/undeployed (unchanged) |

Code-only merge: the seven UX fixes are on `main` but not live; running container unchanged (app `3b30a0f`). Evidence: `docs/SCA-STAFF-COLLECTOR-UX-PHASE1-MERGE-RESULT.md`. Prod non-mutating check unchanged (FP `d15a5cbd…`, loopback 200, 1 pending migration = reason 139). **STOP for ChatGPT post-merge audit of `73b6c22`; do not deploy, run production migrations, mutate production, change infrastructure, conduct a pilot, or start another initiative.**

---

<!-- Prior pre-merge PASS decision retained below for traceability. -->

# STAFF & COLLECTOR UX HARDENING PHASE 1 — INDEPENDENT PRE-MERGE PASS

**LIMITED MERGE AUTHORIZATION ONLY.** Independently verified implementation main = baseline `62c5d8b7370b5c846a4adbc3c530f9800495bab1`; approved candidate `63177b197511c35653f70d1577c7392728652997` is 1 ahead/0 behind; exactly 13 authorized changed files (9 app, 4 tests). Reviewed collector result logic, claim grant eligibility versus authoritative service, manual intake request validation, safe error mapping, profile/payment copy and governance evidence. Seven scoped fixes conform to task. Claude reports full SCA 1407 passed/1 skipped/0 failed (7459 assertions); ChatGPT did not run tests.

Claude may perform a **controlled code-only merge of this exact candidate into this exact unchanged baseline**. Reconfirm origin/main before merge; if moved STOP. Verify candidate-to-merge tree identical and baseline-to-merge diff exactly the authorized 13 files. Record merge SHA and evidence in `docs/SCA-STAFF-COLLECTOR-UX-PHASE1-MERGE-RESULT.md` and update NEXT_TASK.md, then **STOP for independent post-merge audit**. No deployment, production migration (QR-reason 139 still pending per Claude), production data change, provider/infra change, pilot, or next initiative. Production release requires separate owner approval.

---

# NEXT TASK — SCA STAFF & COLLECTOR UX HARDENING (PHASE 1)

**STATUS: CANDIDATE PUSHED — AWAITING ChatGPT PRE-MERGE AUDIT. NOT merged, NOT deployed; no migration/schema/provider; no production change.**

## Candidate under audit
| | |
|---|---|
| Task promotion | `7f0d4806e836a942b4df6be942a42e78d8ed346d` |
| Exact base | `62c5d8b7370b5c846a4adbc3c530f9800495bab1` |
| Branch | `fix/sca-staff-collector-ux-phase1` (1 ahead / 0 behind) |
| **Candidate SHA** | **`63177b197511c35653f70d1577c7392728652997`** |
| Files changed | 13 (9 app + 4 test) |
| Full `tests/Feature/Sca` | 1407 passed / 1 skipped / 0 failed (7459 assertions) |
| Production | migration 138 (QR-reason 139 still pending/undeployed), FP `d15a5cbd…`, loopback 200 — untouched |

Seven bounded fixes (no provenance/cert/QR/ownership/payment/ACL/public-route/schema/migration change): (1) collector profile no longer advertises the edge-blocked `/u/{handle}` as a clickable link (canonical `/c/` shown); (2) collector copy distinguishes inconclusive from failed; (3) safe operator error copy for CSV-import preview + finalize (no raw codes/exceptions); (4) honest `year.max` message; (5) brand+model required on the MANUAL-create request only (custody/import/service/legacy unaffected); (6) staff "Make claimable" mirrors authoritative grant eligibility (adds external_intake + no-completed-claim); (7) honest staff+collector payment copy while Stripe dormant (no implied charge). New `StaffCollectorUxPhase1Test` + adjusted CollectorUi3Test/EyewearRegistryTest/CollectorHandleTest. Evidence: `docs/SCA-STAFF-COLLECTOR-UX-PHASE1-RESULT.md`. **STOP for ChatGPT pre-merge audit; do not merge/deploy/run migrations/mutate production/pilot/start another initiative.**

---

<!-- Task promotion brief retained below for traceability. -->

**STATUS (promotion): OWNER-AUTHORIZED CANDIDATE IMPLEMENTATION; STOP BEFORE MERGE.**

Implementation repository: `francisjonee/francisjonee-sca-platform-private`. **Exact baseline `62c5d8b7370b5c846a4adbc3c530f9800495bab1`.** Reconfirm remote main matches baseline before work; if not, STOP and report. Create dedicated candidate branch; no direct commits to main.

## Goal and bounded scope
Address the seven previously audited staff/collector usability defects without changing provenance, certification, QR, ownership, payment, or permission semantics. **First inspect the actual routes, controllers, views, validators, service eligibility and existing tests; document evidence and exact paths before editing.** Implement only grounded corrections:

1. **Collector profile link:** UI currently advertises friendly `/u/{handle}` while edge intentionally blocks `/u/*`. Show only a verified working canonical collector profile URL (or no clickable share URL if none is confirmed). Preserve edge restrictions, public privacy/visibility and existing routing; do not open `/u/*` or invent redirects.
2. **Failed vs inconclusive:** Distinguish authentication results in staff/collector copy wherever currently conflated. Do not modify underlying result values or publish private authentication details.
3. **Raw operator error codes:** Map known domain errors to safe actionable language at identified staff surfaces; log internal diagnostic detail server-side only if already supported and safe. Do not expose exceptions, tokens or identifiers in rendered UI; preserve HTTP error status and validation semantics.
4. **Year validation mismatch:** Align help/error text with actual server-side year constraints; do not silently relax rules.
5. **Manual intake brand/model:** Review actual workflow and enforce appropriate brand/model completeness for staff manual intake at request validation, with helpful errors and old-input preservation; **do not impose requirements on external/legacy/import pathways or rewrite existing items**. If field optionality is a deliberate domain rule, report conflict and propose narrowly rather than changing it unilaterally.
6. **Claim action eligibility:** Hide/disable misleading staff/collector claim controls when existing service/registry eligibility rejects the action. Derive from the authoritative current eligibility logic; preserve service enforcement, adverse-status rules, permissions and no accidental grant.
7. **External authentication payment copy:** Correct misleading Stripe/payment language to accurately distinguish manual staff progression from verified payment while Stripe is dormant. Do not imply a charge, receipt or verified payment; do not activate Stripe or change payment state machine.

## Security, compatibility, and scope controls
No new features, migrations, schema, public URL opening, collector privacy expansion, payment processing, Shopify/mail changes, ACL loosening, provenance mutation semantics, production edits, infrastructure changes or physical pilot. Keep fixes minimal, focused and accessible. Preserve escaping, CSRF, old input, actual HTTP 403/404, server-side validation, item/collector binding and no public leakage. Do not convert internal errors into false success.

## Evidence and tests
Create focused regression tests per changed behavior: broken link not advertised and canonical link correctness; failed/inconclusive differentiation; safe error messages; exact year constraints; manual intake missing brand/model validation without affecting external/legacy paths; claim control visibility vs service eligibility; honest payment copy. Include negative/security cases and existing workflows. Use disposable `sca_domain_test` hard guard for DB tests. Run focused and full `tests/Feature/Sca` suites; provide exact commands/counts, any skipped tests, and explain gaps. Review any impact on prior merged QR-reason and auth/cert safeguards; ensure no regression.

## Delivery / STOP
Commit and push candidate branch only. Record findings, exact changed files, base and candidate SHAs, before/after behavior, tests, risks, and any deliberately deferred item in `docs/SCA-STAFF-COLLECTOR-UX-PHASE1-RESULT.md` in governance repository. Update `NEXT_TASK.md` to awaiting independent ChatGPT pre-merge audit. **STOP BEFORE MERGE**; no deployment, production migration (QR-reason migration 139 remains pending), production data changes, pilot, or next initiative. If scope conflicts or cannot be safely bounded, stop and ask for review instead of broadening.

---

# AUTHENTICATION & CERTIFICATION SAFEGUARDS — POST-MERGE PASS / CODE TASK CLOSED

Independent GitHub verification: implementation `main` = merge `62c5d8b7370b5c846a4adbc3c530f9800495bab1`; approved candidate `d21f08703051448ec9a77da741a74ac1daea858b` → merge has zero changed files (content identical); baseline `0afc68b2d6a18688e367daa66e304c96c147dbf1` → merge has exactly 12 authorized files (501 additions, 29 deletions). **POST-MERGE PASS; IMPLEMENTATION TASK CLOSED.** Claude reported full SCA 1397 passed/1 skipped/0 failed; ChatGPT did not rerun tests.

**NOT DEPLOYED.** No production mutation authorized. Earlier QR reason migration 139 remains pending according to Claude; live server state not independently checked. Await owner instruction before any production deployment, migration, pilot, or new initiative.

---

# AUTHENTICATION & CERTIFICATION SAFEGUARDS — MERGE COMPLETE (code-only)

**STATUS: CONTROLLED MERGE COMPLETE — AWAITING ChatGPT POST-MERGE AUDIT. No deployment, no production migration, no production data change, no pilot, no new initiative.**

| | |
|---|---|
| Pre-merge PASS | `4e448c69a9a08c1a2beeeb10e62e2bedadd2e0e2` |
| Approved candidate | `d21f08703051448ec9a77da741a74ac1daea858b` |
| Baseline (unmoved pre-merge) | `0afc68b2d6a18688e367daa66e304c96c147dbf1` |
| **MERGE_SHA = ORIGIN_MAIN** | **`62c5d8b7370b5c846a4adbc3c530f9800495bab1`** |
| Candidate→merge | byte-identical; exactly the 12 authorized files; 501 ins / 29 del |
| Deployment | not performed / not authorized |
| Migration | none this task; pre-existing QR-reason 139 still Pending/undeployed (unchanged) |

Code-only merge: no-default-result + typed-confirm finalize/issue interstitials are on `main` but not live; running container unchanged (app `3b30a0f`). Evidence: `docs/SCA-AUTH-CERT-SAFEGUARDS-MERGE-RESULT.md`. Prod non-mutating check unchanged (FP `d15a5cbd…`, loopback 200). **STOP for ChatGPT post-merge audit of `62c5d8b`; do not deploy, run production migrations, mutate production, conduct a pilot, or start another initiative.**

---

<!-- Prior pre-merge PASS decision retained below for traceability. -->

# AUTHENTICATION & CERTIFICATION SAFEGUARDS — PRE-MERGE AUDIT PASS

**PASS — LIMITED MERGE AUTHORIZATION ONLY.** Independent GitHub review of candidate `d21f08703051448ec9a77da741a74ac1daea858b` against exact implementation baseline `0afc68b2d6a18688e367daa66e304c96c147dbf1`: main remains base, candidate 1 ahead/0 behind; exactly 12 authorized files changed (501 insertions/29 deletions). Inspected both controllers, two FormRequests, both confirmation views, authentication create select, admin routes, item links, and new feature tests. No default Passed; required typed FINALIZE/ISSUE checked server-side; read-only GET, ACL and exact-item binding, existing service guards retained. Claude reports focused 47 passing and full SCA 1397 passing/1 skipped/0 failed (7403 assertions); ChatGPT did not execute tests. Note: server-side typed-word confirmation does not cryptographically prove GET page visit; this is the specified confirmation contract.

Claude may merge **only candidate `d21f08703051448ec9a77da741a74ac1daea858b` into unchanged base `0afc68b2d6a18688e367daa66e304c96c147dbf1`**. Reconfirm origin/main equals base; if moved STOP. After controlled merge, verify candidate-to-merge content identical and base-to-merge diff exactly the 12 authorized files; record merge SHA and evidence in governance. **STOP for independent post-merge audit.** NO deployment, production migration (QR reason 139 still pending), production data changes, pilot, or new initiative. Production rollout requires separate owner authorization.

---

# NEXT TASK — AUTHENTICATION & CERTIFICATION SAFEGUARDS

**STATUS: CANDIDATE PUSHED — AWAITING ChatGPT PRE-MERGE AUDIT. NOT merged, NOT deployed; no migration/schema; no production change.**

## Candidate under audit
| | |
|---|---|
| Task promotion | `c0251ccbb0f77098aa9bdb4a55412318c2795d82` |
| Exact base | `0afc68b2d6a18688e367daa66e304c96c147dbf1` |
| Branch | `fix/sca-auth-cert-safeguards` (1 ahead / 0 behind) |
| **Candidate SHA** | **`d21f08703051448ec9a77da741a74ac1daea858b`** |
| Files changed | 12 (controllers + 2 requests + create.blade + 2 confirm views + show.blade + routes + new test + 2 adjusted tests), 501 ins / 29 del |
| Focused | `AuthCertSafeguardsTest` 10 + adjusted Auth/Cert workflow tests (47 across the three) |
| Full `tests/Feature/Sca` | 1397 passed / 1 skipped / 0 failed (7403 assertions) |
| Production | migration 138 (QR-reason 139 still Pending/undeployed), FP `d15a5cbd…`, loopback 200 — untouched |

Scope A: authentication Result select leads with a disabled empty "Select inspection result" placeholder (no default Passed); server allowlist unchanged. Scope B: read-only typed-confirmation GET interstitials for finalize (typed FINALIZE) and issue (typed ISSUE), server-enforced via new FormRequests; item-view actions now link to the confirm GET; confirm GETs read-only + ACL + exact-item/eligibility (404/redirect, no leak); missing/wrong word, stale/duplicate, ineligible → no new finalize/cert/QR. No migration/schema/provider/infra. Evidence: `docs/SCA-AUTH-CERT-SAFEGUARDS-RESULT.md`. **STOP for ChatGPT pre-merge audit; do not merge/deploy/run migrations/mutate production/pilot/start another initiative.**

---

<!-- Task promotion brief retained below for traceability. -->

**STATUS (promotion): OWNER-AUTHORIZED IMPLEMENTATION — CANDIDATE ONLY; AWAIT CHATGPT PRE-MERGE AUDIT.**

Implementation repo: `francisjonee/francisjonee-sca-platform-private`; exact base `0afc68b2d6a18688e367daa66e304c96c147dbf1`. Confirm origin/main equals this SHA before beginning; if not, STOP and report. Origin: staff/collector operations audit P1 irreversible finalize/certify and P2 default-Passed result.

**Scope A — deliberate authentication selection.** In `app/packages/Sca/Registry/src/Resources/views/authentication/create.blade.php`, make Result initially unselected with a disabled empty placeholder (e.g. “Select inspection result”), preserve `old('result')` after validation errors, and keep required server-side allowlist validation. Never default to Passed. Ensure condition-grade requirements remain enforced. Test a blank result fails without draft mutation and a deliberately selected Passed/Failed/Inconclusive behaves as before.

**Scope B — irreversible-action confirmation.** Add explicit staff confirmation interstitials for (1) finalize an authentication and (2) issue a certification. Display item reference and relevant authentication result/grade and consequences in safe escaped text, provide Cancel, and require deliberate typed confirmation (choose clear distinct words, e.g. FINALIZE and ISSUE) checked **server-side**, not merely browser JS. Confirmation GET must be read-only. Final POST must remain bound to exact item/authentication, existing admin ACL, draft/finalized eligibility, issued-cert eligibility, session-derived actor, and service-level locking/idempotency. A stale/invalid/duplicate confirmation must fail closed with no new provenance event/certificate/QR identity. Do not leak cross-item or missing records. Prefer explicit routes/controller methods and small focused views; reuse existing style and avoid JS-only modals. Inspect current item view POST forms/routes/ACL/test coverage before design; update links/forms to lead to confirmation GET rather than accidentally breaking existing flows. Ensure existing direct POST tests/callers are reviewed and adjusted only for intentional new confirmation contract.

**Tests:** Add focused feature coverage for GET no mutation, unauthorized access, missing/cross-item 404, blank/wrong typed word no mutation, successful confirmed finalize/issue, stale/double submit no second mutation, passed-only certification, and unaffected authentication/ownership/QR invariants. Preserve existing test database hard guard `sca_domain_test`. Run focused and full `tests/Feature/Sca` suites; record exact commands, counts and limitations.

**Boundaries:** No QR reason migration/deployment (migration 139 still pending production), no schema changes unless essential and justified, no Stripe/mail/Shopify, no collector profile UX, no public route changes, no production data, no pilot, no infra, no unrelated refactors. No deployment.

**Delivery:** Commit and push candidate branch only. In governance repo write `docs/SCA-AUTH-CERT-SAFEGUARDS-RESULT.md` with design, exact baseline/candidate SHAs, diff and routes, tests, security/compatibility review, and any remaining risks. Update `NEXT_TASK.md` status to awaiting independent pre-merge audit. **STOP BEFORE MERGE**. ChatGPT audits GitHub candidate and decides PASS/FAIL; no merge or deploy without separate approval.

---

# QR REISSUE REASON — POST-MERGE PASS / CODE TASK CLOSED

Independent GitHub verification: implementation `main` = merge `0afc68b2d6a18688e367daa66e304c96c147dbf1`; approved candidate `7848b58573c9702ad2f76f45795d882929b97a1f` → merge comparison has zero changed files (content identical); baseline `1c6c1e6cc0167cf1fc1d87f2a12446a219664f55` → merge has exactly four authorized files (new migration, QrService, QrReissueController, QrReissueTest), 172 insertions / 3 deletions. **POST-MERGE PASS, IMPLEMENTATION TASK CLOSED.** Tests reported by Claude (1386 pass, 1 skip) were not rerun by ChatGPT.

**NOT DEPLOYED.** Production migration 139 remains pending per Claude's report; production live state not independently verified by ChatGPT. No deployment, migration, pilot, or new initiative is authorized. Future production rollout requires separate owner approval and migration/deployment plan. Await owner instruction.

---

# QR REISSUE REASON — MERGE COMPLETE (code-only)

**STATUS: CONTROLLED MERGE COMPLETE — AWAITING ChatGPT POST-MERGE VERIFICATION. No deployment, no production migration, no production data change, no pilot, no new initiative.**

| | |
|---|---|
| Pre-merge PASS | `819b7bd6eb9caaee9321f9082cbcc0cf19184c74` |
| Approved candidate | `7848b58573c9702ad2f76f45795d882929b97a1f` |
| Baseline (unmoved pre-merge) | `1c6c1e6cc0167cf1fc1d87f2a12446a219664f55` |
| **MERGE_SHA = ORIGIN_MAIN** | **`0afc68b2d6a18688e367daa66e304c96c147dbf1`** |
| Candidate→merge | byte-identical; exactly the 4 authorized files; 172 ins / 3 del |
| Deployment | not performed / not authorized |
| Production migration | **Pending, NOT applied** (prod at migration 138; `2026_10_20_000001` pending) |

Merge is code-only: the new reason-persist behavior is on `main` but not live; production DB stays migration 138; running container unchanged. A future deploy (138→139 + new code) needs separate owner authorization. Evidence: `docs/SCA-QR-REISSUE-REASON-MERGE-RESULT.md`. Prod non-mutating check unchanged (FP `d15a5cbd…`, loopback 200). **STOP for ChatGPT post-merge verification of `0afc68b`; do not deploy, run the production migration, mutate production, execute a pilot, or start another initiative.**

---

<!-- Prior pre-merge PASS decision retained below for traceability. -->

# PRE-MERGE AUDIT DECISION — QR REISSUE REASON

**PASS — LIMITED MERGE AUTHORIZATION ONLY.** Independently verified implementation `main` = exact base `1c6c1e6cc0167cf1fc1d87f2a12446a219664f55`, candidate `7848b58573c9702ad2f76f45795d882929b97a1f` 1 ahead / 0 behind. Exactly four files changed: additive migration `2026_10_20_000001_add_reason_to_sca_qr_lifecycle_events.php`, `QrService.php`, `QrReissueController.php`, `QrReissueTest.php`. Inspected migration CHECK/nullable compatibility, canonical `reissued_from` reason, atomic writer, request plumbing, stale guard and six new regression tests. Claude-reported focused 17 pass/96 assertions and full SCA 1386 pass/1 skip/0 fail/7342 assertions; ChatGPT did not execute tests.

Claude may merge **only this exact candidate into this exact unchanged base** after reconfirming `origin/main` is still the base. Verify candidate-to-merge trees identical and base-to-merge diff exactly the four authorized files. Record merge SHA and evidence in governance, then STOP for ChatGPT independent post-merge audit. If base or candidate differs, STOP. **NO deployment, production migration, production data change, live QR reissue, physical pilot, or new initiative authorized.** Production migration (138→139) requires separate explicit owner authorization and deployment planning; no guarantee of zero-lock online migration is established.

---

# NEXT TASK — QR REISSUE REASON AUDIT INTEGRITY

**STATUS: CANDIDATE PUSHED — AWAITING ChatGPT PRE-MERGE AUDIT. NOT merged, NOT deployed; migration applied to disposable test DB only; production NOT migrated.**

## Candidate under audit
| | |
|---|---|
| Task promotion | `393bdddae6690e4714649e0c3e35d725c76eb4e6` |
| Exact base | `1c6c1e6cc0167cf1fc1d87f2a12446a219664f55` |
| Branch | `fix/sca-qr-reissue-reason` (1 ahead / 0 behind) |
| **Candidate SHA** | **`7848b58573c9702ad2f76f45795d882929b97a1f`** |
| Files changed | 4 (migration + QrService + QrReissueController + QrReissueTest), 172 ins / 3 del |
| Focused | `QrReissueTest` 17 pass (rr1–rr6 new), 96 assertions |
| Full `tests/Feature/Sca` | 1386 passed / 1 skipped / 0 failed (7342 assertions) |
| Production | migration 138 / 0 pending, FP `d15a5cbd…`, loopback 200 — untouched |

Additive forward-only migration `2026_10_20_000001` (nullable `reason VARCHAR(500)` + CHECK `reason IS NULL OR event_type='reissued_from'`, all historic rows NULL-compatible, 138→139 on a future deploy); `QrService::reissue(...,?string $reason=null)` stores it on the canonical `reissued_from` event under the existing lock/guard, trimmed, never in payload/passport/collector/log; controller threads the validated required reason. Evidence: `docs/SCA-QR-REISSUE-REASON-RESULT.md`. **STOP for ChatGPT pre-merge audit; do not merge/deploy/run the production migration/start another initiative.**

---

<!-- Task promotion brief retained below for traceability. -->

**STATUS (promotion): OWNER-AUTHORIZED IMPLEMENTATION TASK; CANDIDATE ONLY, AWAIT CHATGPT PRE-MERGE AUDIT.**

Implementation repo: `francisjonee/francisjonee-sca-platform-private`. Exact audited base `1c6c1e6cc0167cf1fc1d87f2a12446a219664f55`. Reconfirm main before work; if changed STOP. Governance audit: `docs/SCA-STAFF-COLLECTOR-OPS-AUDIT.md` finding P1 #1.

**Problem:** `QrReissueRequest` requires a staff reason, but `QrReissueController::reissue` drops it, `QrService::reissue` does not accept it, and `sca_qr_lifecycle_events` cannot store it. This breaks operator justification traceability for irreversible QR rotation.

**Implement a bounded fix in a candidate branch only:**
1. Design a forward-only, additive migration for a nullable, bounded reason on the append-only QR lifecycle ledger. Do NOT rewrite prior migration, backfill invented reasons, alter existing events, or weaken append-only constraints. Preserve compatibility with historical rows and existing activation. Choose and document precisely which reissue event holds the reason (prefer `reissued_from` only, one canonical justification per rotation).
2. Thread the validated, trimmed nonempty reason from request through controller to `QrService::reissue`, store it atomically with the three reissue events. Preserve the under-lock expected-active guard, one-active QR invariant, rollback, immutable identities, actor, and current projection. Do not put staff reason in public passport, collector views, QR payload, or logs.
3. Add targeted regression tests proving exact reason persistence, no reason on unrelated lifecycle events, historic nullable compatibility, missing/blank reason rejects with zero mutation, stale/double POST creates no identity/event/reason, old QR 404/new QR 200, and certification/authentication/ownership unaffected. Adapt existing direct `reissue()` callers carefully. Tests only in disposable `sca_domain_test` with hard DB guard. Run focused tests and full SCA suite; record results honestly.
4. Document migration compatibility and deployment considerations. **Do not execute migration on production or deploy.** No live QR rotations or pilot.

**Boundaries:** No unrelated UX fixes, no Stripe/mail/Shopify changes, no refactors of public passport or ownership, no infrastructure. Commit and push candidate branch, provide exact base and head SHAs, diff/files changed, tests and any limitations in `docs/SCA-QR-REISSUE-REASON-RESULT.md` (governance repo), update NEXT_TASK.md to awaiting ChatGPT independent pre-merge audit. **STOP BEFORE MERGE.** No deployment or production data changes. ChatGPT must independently verify candidate and authorize any merge; deployment/migration requires separate owner authorization.

---

# NEXT TASK

**STATUS: STAFF OPS & COLLECTOR EXPERIENCE AUDIT (READ-ONLY) DELIVERED — AWAITING ChatGPT INDEPENDENT REVIEW. No code/schema/config/infra/production change; no fixes implemented; no deployment; no pilot; no new initiative.**

Read-only audit of baseline `1c6c1e6cc0167cf1fc1d87f2a12446a219664f55` (deployed app `3b30a0f`, migration 138) across (1) staff intake/auth/cert/QR/custody, (2) collector registration/claims/My-Collection/transfer/privacy, (3) external submissions + staff processing, (4) public passport/errors/nav. Report: `docs/SCA-STAFF-COLLECTOR-OPS-AUDIT.md` (prioritized P1/P2/P3 + ON-HOLD + REAL-WORLD-TESTING-ONLY, exact `file:line` anchors, verification tags).

P1 (pre-pilot, trust/audit-integrity): (1) QR reissue required reason collected but never stored (no param/column) — audit gap; (2) collector profile advertises a clickable `/u/{handle}` link while `/u/*` is edge-blocked (Phase A) → non-resolvable externally; (3) no collector notification anywhere in the submission lifecycle vs copy promising "we'll be in touch" → silent parked states; (4) certify + finalize-auth are irreversible yet single-click with no confirm interstitial (status/QR/corrections all require typed confirm). P2/P3 + intentional ON-HOLD (Stripe dormant, MAIL=log, /u edge, Shopify live-configured but stale "deferred" config comments) and real-world-only items (QR print scan, custody paper-chain, live Shopify/Stripe/email, mobile) enumerated in the report. **STOP — awaiting ChatGPT independent review; do not implement fixes, change code, deploy, mutate production, or start another initiative.**

---

<!-- Prior status (QR rg8 CLOSED, independent post-merge audit PASS) retained below for traceability. -->

**STATUS (rg8 CLOSED): SCA QR rg8 TEST RELIABILITY CLOSED — INDEPENDENT POST-MERGE AUDIT PASS.** GitHub main = merge `1c6c1e6cc0167cf1fc1d87f2a12446a219664f55`; candidate `1bc301e` → merge files=[] (identical); baseline `9a7db35` → merge one file `app/tests/Feature/Sca/QrReissueTest.php` (+22/-3), no production app changes; evidence `docs/SCA-QR-RG8-TEST-RELIABILITY-MERGE-RESULT.md`. Running app code remains `3b30a0f`, migration 138. Initiative CLOSED; physical pilot on hold pending owner approval.

## Merge result (rg8, post-merge audit PASS)
| | |
|---|---|
| Pre-merge PASS | `14941ed90463bdbcfcc2e255ea81fc31366e6cc3` |
| Approved candidate | `1bc301eacc5b0d427a6f7e19e22ba201c3002216` |
| Baseline (unmoved pre-merge) | `9a7db357572600ddaeff8caa4fde5c1a8b6d273c` |
| **MERGE_SHA = ORIGIN_MAIN** | **`1c6c1e6cc0167cf1fc1d87f2a12446a219664f55`** |
| Candidate→merge | byte-identical; only `app/tests/Feature/Sca/QrReissueTest.php` (+22/−3); no non-test `app/` delta |
| Deployment | not performed / not authorized (test-only) |

Evidence: `docs/SCA-QR-RG8-TEST-RELIABILITY-MERGE-RESULT.md`. **STOP for ChatGPT post-merge verification of `1c6c1e6`; do not deploy, mutate production, execute the physical pilot, or start another initiative.**

---

<!-- Prior pre-merge PASS brief retained below for traceability. -->

**STATUS (pre-merge PASS): QR rg8 TEST RELIABILITY — INDEPENDENT PRE-MERGE AUDIT PASS.** Candidate `1bc301eacc5b0d427a6f7e19e22ba201c3002216`, exact base `9a7db357572600ddaeff8caa4fde5c1a8b6d273c`. GitHub comparison 1 ahead / 0 behind; exactly one file changed: `app/tests/Feature/Sca/QrReissueTest.php` (+22/-3). Inspected rg8: excludes legitimately mutable `active_qr_identifier_id` and `rebuilt_at` from domain projection equality, asserts QR pointer changes, all other projection fields identical, certification/authentication rows unchanged, ownership count unchanged, current owner present, and timestamp monotonic. No production code/config/schema changed. Claude reports focused 21 pass, rg8 3 repeated green, full SCA 1380 pass / 1 skip / 0 fail (7310 assertions); ChatGPT did not independently execute tests.

**LIMITED MERGE AUTHORIZATION:** Reconfirm origin/main remains exact base `9a7db357572600ddaeff8caa4fde5c1a8b6d273c`. Merge only exact audited candidate, prove candidate→merge tree content identical and base→merge only that test file. Record merge SHA, GitHub evidence and test results in governance. STOP for independent post-merge verification. **No production deployment**, production data mutation, pilot, Stripe/mail/backup/Shopify activity, or next initiative authorized. If main moved or diff changed, STOP and request re-audit.

---

# NEXT TASK — SCA QR REISSUE rg8 TEST RELIABILITY

**STATUS: QR REISSUE rg8 TEST RELIABILITY — CANDIDATE PUSHED — AWAITING ChatGPT PRE-MERGE AUDIT. NOT merged, NOT deployed. Test-only change; no production/infra/pilot.**

## Candidate under audit
| | |
|---|---|
| Governance promotion | `cc4cf4934b266235e398ecbd44618ef1c94eb292` |
| Exact baseline (origin/main, confirmed) | `9a7db357572600ddaeff8caa4fde5c1a8b6d273c` |
| Branch | `fix/sca-qr-rg8-test-reliability` (1 ahead / 0 behind) |
| **Candidate SHA** | **`1bc301eacc5b0d427a6f7e19e22ba201c3002216`** |
| Changed files | 1 — `app/tests/Feature/Sca/QrReissueTest.php` (+22/−3); no production/infra |
| Focused | `QrReissueTest`+`QrArtifactTest` 21 pass; rg8 3× green |
| Full `tests/Feature/Sca` | 1380 passed / 1 skipped / 0 failed (7310 assertions) |

Fix excludes the recompute timestamp `rebuilt_at` from rg8's before/after projection equality (like `active_qr_identifier_id`), preserving all domain assertions (active-QR changed; other projection columns identical; cert/auth rows unchanged; ownership-count unchanged; owner preserved) and adding a safe monotonic `rebuilt_at` present/≥ check. Evidence: `docs/SCA-QR-RG8-TEST-RELIABILITY-RESULT.md`. **STOP for ChatGPT pre-merge audit; do not merge/deploy; no deployment authorized for a test-only change; do not start another initiative.**

---

<!-- Promotion brief retained below for traceability. -->

**STATUS (promotion): OWNER-APPROVED TEST-ONLY REMEDIATION PROMOTED; AWAITING CLAUDE CANDIDATE.** This supersedes the closed pilot-readiness documentation task. Owner authorized preparing/fixing the QR timing test while physical frames are unavailable, **not** merging, deploying, or executing a pilot.

## Immutable baseline and scope
- Implementation repo: `francisjonee/francisjonee-sca-platform-private`.
- Require origin/main exactly `9a7db357572600ddaeff8caa4fde5c1a8b6d273c` before branching. If it moved, STOP and report.
- One narrowly bounded **test-only** change to `app/tests/Feature/Sca/QrReissueTest.php`, specifically `rg8_certification_authentication_and_ownership_are_untouched`. Do not change production PHP, services, projection, migrations, configs, dependencies, infrastructure, or unrelated tests.
- No Stripe, Postmark, backups, Shopify activity, production mutation, physical pilot, or new initiative.

## Verified defect
`rg8` captures entire `sca_item_current_state` before and after QR reissue, removes only `active_qr_identifier_id`, then `assertSame`. `QrService::reissue()` calls `ProjectionService::rebuild()`, which intentionally updates `rebuilt_at = now()`. Whole-second timestamp differences under load trigger false failures, even when certification, authentication, ownership and registry remain unchanged.

## Required implementation
1. Exclude `rebuilt_at` from the before/after equality comparison, as with the legitimately changed active QR ID. Keep assertion that active QR ID changed.
2. Preserve meaningful invariant checks: other projection columns must remain identical; certification/authentication rows unchanged; ownership-event count unchanged; current owner preserved. Explicitly assert that the rebuild timestamp is present and not earlier than before, with safe date-time comparison (avoid introducing another precision/timing flake).
3. Do not weaken other QR reissue guards or tests. If a genuine domain invariant fails, do not mask it.
4. Run focused `QrReissueTest` and `QrArtifactTest`, then full `tests/Feature/Sca` suite in disposable `sca_domain_test` only. If test infra unavailable, report exact limitations; never substitute production DB. Capture test counts and failure details. If feasible repeat focused rg8 under varying timing/load without sleeping in production tests.
5. Document root cause, minimal diff, proof of no non-test changes, test results, and remaining risks in a concise governance evidence file `docs/SCA-QR-RG8-TEST-RELIABILITY-RESULT.md` in Shopify-Jeremy. Update `NEXT_TASK.md` with branch, full candidate SHA, exact baseline, tests, and STOP status.
6. Push candidate branch from exact baseline. **STOP BEFORE MERGE/DEPLOY.** ChatGPT independently audits candidate and records PASS/FAIL. Only after explicit PASS may Claude perform a controlled merge of exact audited candidate against exact audited base; post-merge verification is separate. No application deployment automatically authorized for a test-only change.

## Acceptance
Only `app/tests/Feature/Sca/QrReissueTest.php` differs in implementation repo; timestamp comparison corrected without loss of domain assertions; focused and full tests green or blockers transparently reported; no production changes; no pilot executed.

---

# NEXT TASK

**STATUS: REAL-WORLD PILOT READINESS DOCUMENTATION CLOSED — POST-MERGE AUDIT PASS.**

Independent GitHub comparison verified approved candidate `bebd18139f008c29fc78c27bc1f4e27a34869ecb` → merge/main `9a7db357572600ddaeff8caa4fde5c1a8b6d273c` has **files=[]**; original application baseline `3b30a0f24323463c42dda58b476a453f58e49389` → merge changes exactly one file, `docs/SCA-REAL-WORLD-PILOT-READINESS.md` (199 insertions), and no `app/` files. Deployment was neither necessary nor authorized. Claude-reported non-mutating production checks remain unchanged; ChatGPT independently verified GitHub tree comparisons, not the production server.

**Documentation initiative CLOSED.** Repo main `9a7db35`; deployed app code `3b30a0f`; migration 138. No physical pilot has been executed or authorized. To proceed, owner must explicitly approve exact consented frames, staff/collector participants, pilot window, and optional Shopify order; permanent provenance implications must be understood. No new initiative promoted. Do not merge/deploy/mutate production or execute pilot without separate authorization.

---

# NEXT TASK

**STATUS: PILOT READINESS DOCS — DOCUMENTATION-ONLY MERGE COMPLETE — AWAITING ChatGPT POST-MERGE VERIFICATION. No application deployment, production data change, physical pilot, or new initiative authorized. Physical pilot still requires separate explicit owner approval of exact frames/participants/window.**

## Merge result (awaiting post-merge verification)
| | |
|---|---|
| Pre-merge PASS | `3b0a7ef47dfdbbf40cd331c1a56e10b7e01bd201` |
| Approved candidate | `bebd18139f008c29fc78c27bc1f4e27a34869ecb` |
| Baseline (unmoved pre-merge) | `3b30a0f24323463c42dda58b476a453f58e49389` |
| **MERGE_SHA = ORIGIN_MAIN** | **`9a7db357572600ddaeff8caa4fde5c1a8b6d273c`** |
| Candidate→merge | byte-identical; only `docs/SCA-REAL-WORLD-PILOT-READINESS.md` added (199 ins); `app/` delta none |
| Deployment | not performed / not authorized (docs-only) |
| Prod (non-mutating check) | FP `d15a5cbd…`, counts `3/3/4/4/5/2/1/1/7`, migration 138/0 pending, loopback 200 — unchanged |

Evidence: `docs/SCA-PILOT-READINESS-MERGE-RESULT.md`. **STOP for ChatGPT post-merge verification of `9a7db35`; do not deploy, mutate production, execute the physical pilot, or start another initiative.**

---

<!-- Prior pre-merge RE-AUDIT PASS brief retained below for traceability. -->

**STATUS (pre-merge PASS): SCA REAL-WORLD PILOT READINESS R1 — PRE-MERGE RE-AUDIT PASS.** Docs-only candidate `bebd18139f008c29fc78c27bc1f4e27a34869ecb` approved against exact production baseline `3b30a0f24323463c42dda58b476a453f58e49389` (GitHub 1 ahead / 0 behind; one added Markdown document, no code/schema/config).

Independent audit confirmed R1 corrections: Shopify sale-link-backed `ClaimWorkflow::claim()` distinguished from independent `claimByGrant()` (source inspected), per-chain PASS/DEFERRED/FAIL criteria, owner-designated sacrificial pilot frame with permanent adverse-event history, and Claude-reported environment verification properly qualified.

**AUTHORIZATION LIMITED TO CONTROLLED DOCS-ONLY MERGE:** Recheck origin/main exact baseline; merge only approved candidate; prove merge tree content-identical to candidate and only doc added. No application deployment required for documentation-only merge; no production data mutation, no pilot execution, no live Shopify transaction, no Stripe/mail/backup activation. Record merge SHA and evidence, then STOP for ChatGPT post-merge verification. **Physical pilot still requires separate explicit owner approval of exact frames, participants and window.**

---

# NEXT TASK

**STATUS: PILOT READINESS DOCS — R1 REMEDIATION PUSHED — AWAITING ChatGPT PRE-MERGE RE-AUDIT. NOT merged, NOT deployed, pilot NOT executed; no owner authorization inferred.**

## R1 remediation candidate (awaiting re-audit)
| | |
|---|---|
| Prior R1 FAIL (docs remediation only) | `2ec508165ef90710d564aa982f32743b7c0003b7` |
| Baseline | `3b30a0f24323463c42dda58b476a453f58e49389` (migration 138, unchanged) |
| **R1 candidate SHA** | **`bebd18139f008c29fc78c27bc1f4e27a34869ecb`** (amended single docs commit; supersedes `f78f981`; 1 ahead / 0 behind) |
| Changed files | 1 (`docs/SCA-REAL-WORLD-PILOT-READINESS.md`) — docs only, no code/schema/config |

Three content fixes + source validation applied (docs only): (1) Shopify sale→claim (`ClaimWorkflow::claim`, sale-link-gated) split from the independent staff grant (`claimByGrant`); a manual grant never validates the Shopify chain; Shopify chain NOT VALIDATED without a live order. (2) Success scored per chain — core / external-unpaid / optional-Shopify — pass/deferred/fail, optional-unexecuted = DEFERRED not PASS, Stripe paid flow excluded. (3) Adverse negative testing confined to an owner-designated consented sacrificial frame (`PILOT-SAC`) with permanent-history consequences documented (no erasable cleanup). (4) Routes/ACLs/services validated against source at `3b30a0f`; ENVIRONMENT-CONFIRMED tier marked Claude-reported, not ChatGPT-verified. Evidence: `docs/SCA-PILOT-READINESS-AUDIT.md`. **STOP for ChatGPT pre-merge re-audit + owner authorization; do not merge/deploy/execute the pilot; do not start another initiative.**

---

<!-- Prior R1 FAIL brief retained below for traceability. -->

**STATUS (R1 FAIL): PILOT READINESS DOCS — PRE-MERGE AUDIT FAIL (DOCUMENTATION REMEDIATION ONLY).** Candidate `f78f981d3351dcd45aec7f108ef6838518442e65` based exactly on production `3b30a0f24323463c42dda58b476a453f58e49389`; GitHub comparison 1 ahead / 0 behind, only `docs/SCA-REAL-WORLD-PILOT-READINESS.md` added (183 lines), no code/schema/config. Do not merge, deploy or execute pilot yet.

**Required fixes on same docs branch, no code changes:**
1. Separate the **Shopify-derived claim entitlement** from the **staff-issued external grant**. In Chain A, explicitly name the real Shopify sale→claim eligibility→claim path, its authority and evidence, and distinguish any independent manual grant pilot fallback. Never claim a manual external grant validates a Shopify sale/claim chain. If a real Shopify order is deferred, mark Shopify chain NOT VALIDATED, even if the independent grant→ownership path passes.
2. Split pilot success into **core inventory/auth/cert/QR/owner-claim/transfer**, **external manual unpaid submission/custody/auth/return**, and **optional Shopify-integrated paid-order/reconciliation/claim**. State precise pass/deferred/fail per chain; do not label an optional unexecuted step end-to-end passed. Keep Stripe paid flow explicitly excluded.
3. Restrict lost/stolen negative tests and permanent adverse events to an **owner-designated, consented sacrificial pilot frame** with documented permanent-history consequences and pre-approved recovery. No such mutations on ordinary saleable/customer inventory. Also avoid presenting permanent certification/ownership events as erasable test cleanup.
4. Validate any runbook claims of route names, ACLs, services, and compensating actions against deployed code; correct inaccuracies. Clarify that production health evidence is reported by Claude, not independently verified by ChatGPT.
5. Update implementation document and governance evidence, push revised docs-only candidate, and STOP for independent ChatGPT re-audit. Exact production baseline unchanged; no merge/deploy/production mutation; no owner authorization of physical pilot inferred.

---

# NEXT TASK

**STATUS: REAL-WORLD PILOT READINESS — DOCS-ONLY CANDIDATE PUSHED — AWAITING ChatGPT PRE-MERGE AUDIT + OWNER AUTHORIZATION OF THE PHYSICAL PILOT. NOT merged, NOT deployed, pilot NOT executed.**

## Candidate under audit
| | |
|---|---|
| Governance promotion | `0995dd48b02eab927e29a69846c5e16dac36867a` |
| Production baseline | `3b30a0f24323463c42dda58b476a453f58e49389` (migration 138) |
| Branch | `docs/sca-real-world-pilot-readiness` (1 ahead / 0 behind) |
| Candidate SHA | `f78f981d3351dcd45aec7f108ef6838518442e65` |
| Changed files | 1 (`docs/SCA-REAL-WORLD-PILOT-READINESS.md`, 183 ins) — docs only, no code/schema/config |
| Migration / provenance | 138 unchanged; FP `d15a5cbd…`, counts `3/3/4/4/5/2/1/1/7` unchanged |

Implementation doc `docs/SCA-REAL-WORLD-PILOT-READINESS.md` (candidate) + governance summary `docs/SCA-PILOT-READINESS-AUDIT.md` (here). Workflow readiness matrix (CODE-COMPLETE vs ENVIRONMENT-CONFIRMED vs NOT-YET-HUMAN-PILOT-VALIDATED — all stages NHV), controlled pilot runbook, operator checklists/incident/privacy/metrics, ranked gap register, and rg8 timing-flake diagnosis (test-only fix proposed, NOT patched). Blockers are human-process only (no pilot executed; owner approval pending); no code blocker. **STOP for ChatGPT pre-merge audit + owner authorization; do not merge/deploy/execute the pilot; do not start another initiative.**

---

<!-- Promotion brief retained below for traceability. -->

**STATUS (promotion): REAL-WORLD PILOT READINESS — ARCHITECTURE AUDIT COMPLETE; CONTROLLED PILOT PREPARATION PROMOTED.** Baseline `3b30a0f24323463c42dda58b476a453f58e49389`, migration 138. No production mutation, merge, deployment, or live pilot authorized by this task. Claude must first prepare evidence and a practical runbook; stop for ChatGPT audit.

## Audit findings
- Existing production code/test coverage already implements staff intake/authentication/certification, permanent QR/passport, collector claim/ownership/transfer, Shopify sale links, external submissions/custody/return, status safety, staff dashboard, and Market Reference. Do NOT rebuild these.
- `PilotHardeningTest` and `PublicPassportPilotTest` already cover important safety/privacy scenarios, but automated tests do not establish that real people and physical frames have completed a pilot.
- Existing `docs/RUNBOOK.md` contains historical staging language and operational commands. Treat it as reference, not proof of current live setup; verify production-specific details from authoritative evidence without revealing secrets.
- External paid-auth payment remains dormant; manual submission advance is explicitly NOT payment confirmation. Shopify is read_orders only. Mail is log, so do not promise working outbound password-reset or notification emails. Off-site backup/restore and Stripe activation remain owner-parked.
- `QrReissueTest::rg8` intermittently fails due to projection rebuilt_at timing under load. Investigate reproducibly and propose a narrowly scoped fix separately; never weaken the domain assertion or suppress a failure to pass deployment.

## Claude task: substantial pilot-readiness package (documentation/evidence first)
1. Inspect the exact deployed baseline and build a **workflow-by-workflow readiness matrix**: SCE-owned inventory intake→authentication→certification→QR printing→public scan→Shopify sale-link→grant/claim→current ownership→transfer; external collector submission→manual pilot advance (NOT paid)→physical custody→authentication result (passed/failed/inconclusive)→certification where eligible→grant→claim→return. Include lost/stolen/recovery, invalidation, staff corrections, and Market Reference as bounded safety cases.
2. For each stage identify actual staff UI/route/service, actor, permissions, required physical artifact, irreversible mutation, safe rollback/correction, test evidence, and external dependency. Distinguish code-complete, environment-confirmed, and **not yet human-pilot-validated**. Do not claim a live Shopify transaction or Stripe payment without evidence.
3. Create a **controlled pilot execution runbook** with 2–3 real or consented test frames, distinct staff and collector roles, unique traceable item references, paper custody chain, printed QR label/scan, verification on the canonical public domain, safe negative scenarios, checkpoints, screenshots/log evidence with PII redacted, and explicit stop/go criteria. Avoid manipulating real ownership or statuses until owner approves the exact pilot and participants.
4. Draft operator checklists, incident/rollback boundaries, data handling/privacy, pilot success metrics, and a gap register ranked blocker/high/medium. Separate product defects from environment dependencies and human-process gaps.
5. Analyze QR rg8 timing flake: inspect assertion and ProjectionService/QrService rebuild timestamps, identify likely race/precision source, suggest safe test/implementation correction and regression plan. Do NOT patch it in this preparation task without a separate approved scope.
6. Verify no app code/schema/provider/infra edits; no production data mutation. Documentation and evidence only. Do not trigger Stripe, Postmark, backup activation, or live Shopify writes.
7. Write `docs/SCA-REAL-WORLD-PILOT-READINESS.md` in implementation repo and a governance evidence summary `docs/SCA-PILOT-READINESS-AUDIT.md` here. Update `NEXT_TASK.md` with exact candidate SHA, matrix, blockers and next decision. Run documentation/static validation where applicable.
8. Push a **docs-only** candidate based on exact `3b30a0f24323463c42dda58b476a453f58e49389`; if main moved STOP. Do not merge/deploy. STOP for independent ChatGPT audit and owner authorization of actual physical pilot.

**No Marketplace, no new valuation features, no pilot execution, no code changes, no new initiative.**

---

# NEXT TASK

**STATUS: MARKET REFERENCE / VALUE HISTORY — SLICE 2 CLOSED + LIVE. Independent ChatGPT post-deployment audit PASS.**

Production/main/deployed: `3b30a0f24323463c42dda58b476a453f58e49389`. Approved candidate: `9e8453e2bad54ed24ef22a151c881e539b9dc8be`. GitHub candidate→merge comparison: **1 ahead / 0 behind / files=[]** (exact content identity).

Deployment evidence: `docs/SCA-MARKET-REFERENCE-SLICE2-DEPLOY-RESULT.md`. Deployed-tree full SCA gate **1380 pass / 1 skip / 0 fail, 7308 assertions** (documented execution evidence; not independently run by ChatGPT). First pre-migrate gate aborted on existing load-sensitive QrReissueTest::rg8 flake; production was untouched; isolated 11/11 green and clean full rerun preceded deployment. This flake remains a separate technical-debt item; do not silently treat it as resolved.

Migration **138**, 0 pending; provenance fingerprint **d15a5cbdfb8df52ba65628b276533cfe**, canonical counts **3/3/4/4/5/2/1/1/7** unchanged PRE/POST. Health /admin/login 200, healthy app and DB, guest collector fail-closed, public Passport value-free on merge-tree tests. Stripe dormant, MAIL_MAILER=log, Shopify read_orders, no Caddy/DNS/provider drift.

**Slice 2 CLOSED + LIVE.** Current-owner-only advisory Market Reference history, newest-first, correct current/historical/void/re-record identity, no staff/internal/private leakage, no provenance/marketplace/payment mutations.

**NO NEXT INITIATIVE PROMOTED.** Reassess and architecture-audit the next roadmap priority before assigning Claude implementation. Marketplace remains unpromoted. Mail, backups, and Stripe activation remain parked unless owner reopens.

---

# NEXT TASK

**STATUS: SCA MARKET REFERENCE / VALUE HISTORY — SLICE 2 DEPLOYED TO PRODUCTION — AWAITING ChatGPT INDEPENDENT POST-DEPLOYMENT AUDIT. Slice 2 NOT closed; no other initiative started.**

## Deployment result (awaiting post-deploy audit)
| | |
|---|---|
| Deploy approval | `8b389ccfd3d30fb1c6bf9cd379fb0ddce2e40b9c` |
| Approved candidate | `9e8453e2bad54ed24ef22a151c881e539b9dc8be` |
| Audited baseline (unmoved pre-merge) | `6ca15958844dace74f7d087a10a3355a6497dd00` |
| **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD** | **`3b30a0f24323463c42dda58b476a453f58e49389`** |
| Candidate→merge tree | byte-identical (no unreviewed delta) |
| Migration | 138 (PRE/POST; "Nothing to migrate"; 0 pending) |
| Deployed-tree full gate | 1380 passed / 1 skipped / 0 failed (7308 assertions) |
| PRE==POST provenance FP | `d15a5cbd…`, counts `3/3/4/4/5/2/1/1/7` (unchanged) |
| Health | `/admin/login` 200; guest `/collector[/collection]` → 302 /collector/login; public value-free via merge-tree m12 |
| Dormancy/no-drift | Stripe dormant; MAIL_MAILER=log; SHOPIFY_SCOPES=read_orders; Caddy/DNS/provider/infra unchanged |

First gate run aborted BEFORE prod migrate on the documented unrelated `QrReissueTest::rg8` flake (11/11 green isolated); prod untouched; re-run clean per fail-before-migrate policy. Evidence: `docs/SCA-MARKET-REFERENCE-SLICE2-DEPLOY-RESULT.md`. **STOP for ChatGPT independent post-deployment audit; do not declare Slice 2 closed; do not begin another initiative.**

---

<!-- Prior PRE-MERGE PASS gate retained below for traceability. -->

**STATUS (pre-merge PASS): SCA MARKET REFERENCE / VALUE HISTORY — SLICE 2 PRE-MERGE PASS.**

Approved candidate: `9e8453e2bad54ed24ef22a151c881e539b9dc8be`
Exact production base: `6ca15958844dace74f7d087a10a3355a6497dd00`
Branch: `feat/sca-market-reference-slice2`
Migration: 138 unchanged; 5 files, no schema/route/provider/infra change.

ChatGPT independently inspected GitHub comparison, canonical MarketReferenceService reader, owner gate, controller/view and all 13 new tests. Exact base/merge-base confirmed (1 ahead, 0 behind). Event-id current marker, void semantics, owner/former-owner scoping, privacy projection and advisory UI PASS. Focused 13/73 and full 1380/7308 with 1 skip are **Claude-reported execution results**, supported by governance evidence, not independently rerun by ChatGPT. No identified pre-merge blocker.

**DEPLOYMENT GATE — CLAUDE MAY PROCEED WITH CONTROLLED MERGE/DEPLOY OF EXACT APPROVED SHA ONLY.**
1. Recheck origin/main equals exact base; if moved STOP.
2. Merge approved candidate only; prove merge tree content-identical to candidate (empty diff).
3. Run full SCA suite on merge tree; abort on any failure.
4. Confirm no migration (138), production provenance fingerprint `d15a5cbdfb8df52ba65628b276533cfe` and canonical counts `3/3/4/4/5/2/1/1/7` unchanged before/after.
5. Confirm guest/privacy smoke, public value-free boundary, app health, and no Caddy/DNS/OAuth/SMTP/Stripe drift.
6. Write deployment evidence and STOP for independent ChatGPT post-deploy audit. Do not declare Slice 2 closed until that audit.

---

# NEXT TASK

**STATUS: SCA MARKET REFERENCE / VALUE HISTORY — SLICE 2 CANDIDATE PUSHED — AWAITING ChatGPT PRE-MERGE AUDIT. NOT merged, NOT deployed.**

## Candidate under audit
| | |
|---|---|
| Governance promotion | `ad637cf400d88ffdd730082908c0db515e667f13` |
| Branch | `feat/sca-market-reference-slice2` (1 ahead / 0 behind) |
| Production base SHA | `6ca15958844dace74f7d087a10a3355a6497dd00` (migration 138) |
| Candidate SHA | `9e8453e2bad54ed24ef22a151c881e539b9dc8be` |
| Migration | none (138 unchanged) |
| Changed files | 5 (MarketReferenceService, CollectionService, CollectionController, collection/show.blade, new MarketReferenceHistoryTest), 463 ins / 12 del |
| Focused tests | `MarketReferenceHistoryTest` 13 passed / 73 assertions |
| Full `tests/Feature/Sca` | 1380 passed / 1 skipped / 0 failed (7308 assertions) |
| Prod provenance FP (unchanged) | `d15a5cbd…`, counts `3/3/4/4/5/2/1/1/7`, migration 138 |

Read/presentation expansion over the existing append-only ledger: owner-safe value history on Eyewear Detail (secondary "Value history" disclosure next to the current reference; newest-first; Current/Historical text labels by canonical fold event id; "no current Market Reference" after void; advisory-only, no delta/FX/appreciation/resale). No migration, no new authoritative state, no marketplace, no provenance mutation, no public value exposure. Evidence: `docs/SCA-MARKET-REFERENCE-SLICE2-IMPLEMENTATION.md`. **STOP for ChatGPT pre-merge audit; do not merge/deploy/start another initiative.**

---

<!-- Promotion brief retained below for traceability. -->

**STATUS (promotion): SCA MARKET REFERENCE / VALUE HISTORY — SLICE 2 PROMOTED. Production baseline is `6ca15958844dace74f7d087a10a3355a6497dd00`, migration 138. Build the collector-facing historical value timeline over the EXISTING append-only Market Reference ledger. This is a read/presentation expansion only: no marketplace, no automated valuation, no public value exposure, no provenance mutation. Push candidate and STOP for ChatGPT pre-merge audit.**

## Architecture audit conclusion
Slice 1 already has the hard domain foundation:
- append-only `sca_market_reference_events`
- canonical `MarketReferenceService` with record/supersede/void fold
- staff current + full audit history
- current-owner-safe current reference
- an existing owner-safe `collectorHistory()` projection for historical record/supersede observations
- public Passport/profile/collection/certificate/QR surfaces deliberately exclude Market Reference.

The collector currently consumes only the CURRENT reference through `CollectionService::marketReferenceForOwnedItem()`. The historical owner-safe projection exists but is not wired into the collector detail experience. Slice 2 therefore closes a real product gap without inventing another valuation system.

Marketplace/resale is deliberately NOT part of this slice. Marketplace has materially larger transaction, listing, seller-authority, adverse-status, transfer, payment and dispute architecture and must be audited separately later.

## Slice 2 goal
On an eyewear item the authenticated collector CURRENTLY owns, show a clear **Market Reference history** beneath/adjacent to the existing current advisory reference so the collector can understand how SCA's recorded market observations changed over time.

The feature must remain advisory evidence, never an appraisal guarantee, sale offer, asking price, listing price, or automated valuation.

## Required architecture

### 1. One canonical owner-safe history reader
Use/extend `MarketReferenceService` as the canonical fold/privacy boundary. Do NOT query the ledger ad hoc from Blade.

The collector history DTO must expose only:
- currency
- formatted/format-ready low/high range
- as-of date
- basis label/value
- safe source summary only if explicitly justified for collector history
- a truthful current/historical marker if needed for presentation.

It must NEVER expose:
- event/internal IDs
- actor/staff refs
- supersede/void reasons
- predecessor IDs
- source_reference unless architecture explicitly proves it is collector-safe (default: keep excluded)
- DB timestamps as operational audit data
- any Shopify/payment/provider/token data.

If distinguishing the current observation from prior observations requires internal event IDs, use them internally inside the canonical service and strip them before returning the collector DTO. Do not infer “current” by comparing value fields because a fresh record after a void may legitimately repeat an earlier value.

### 2. Truthful void semantics
A void means **there is no current Market Reference**. Historical observations may still be shown as past evidence, but none may be visually or textually represented as current.

Required cases:
- record only → one current observation
- record → supersede → latest successor current, predecessor historical
- record → supersede → void → no current; both observations historical
- record → void → fresh record → fresh record current; pre-void record historical
- repeated equivalent values across separate post-void chains must not confuse current identity.

### 3. Collector authorization
History is available only to the authenticated CURRENT owner using the same canonical ownership boundary as item detail/current Market Reference.
- non-owner → privacy-safe denial/no confirmation
- historical owner → no access after transfer
- guest/staff collector guard boundaries unchanged
- adverse registry status does not rewrite historical market evidence; follow the existing item-detail authorization/status presentation rather than inventing new ownership semantics.

### 4. Collector UX
Integrate into the existing Slice-2 Eyewear Detail hierarchy. Preserve the current Market Reference near the asset.

Add a secondary **Value history / Market Reference history** disclosure/section that:
- is easy to understand on mobile
- orders observations deterministically, newest first for collector reading
- clearly labels Current vs Historical where a current reference exists
- when current is voided, says there is **no current Market Reference** while retaining prior observations as historical evidence
- retains the existing advisory/non-guarantee wording
- never implies appreciation, investment return, guaranteed resale value, or a sale price
- does not expose staff correction/void rationale.

Do not redesign My Collection, Profile, Account, Authenticate, public profile, Passport, or staff Market Reference UI in this slice.

### 5. Optional change indicator — only if semantically safe
A numeric change/delta may be shown ONLY between adjacent observations of the SAME currency and only if it can be derived without floats or misleading cross-currency comparison. If there is any ambiguity, omit delta entirely. Do not add FX conversion.

### 6. No schema unless STOP
This slice is expected to need **no migration**. Existing ledger contains the required history.

If implementation concludes a schema change or new authoritative state is necessary, STOP and return to ChatGPT with the architectural reason before implementing it.

## Invariants that MUST NOT change
- Market Reference remains non-provenance advisory evidence.
- Existing append-only ledger lifecycle and DB constraints/triggers.
- Staff record/supersede/void behavior and ACL.
- current-reference semantics.
- ownership, authentication, certification, QR, claim, transfer, service history, registry and Shopify state.
- public Passport/profile/public collection/certificate PDF remain value-free.
- Stripe/mail/provider/infra unchanged.
- no automated external market lookup, scraping, AI valuation or marketplace behavior.

## Mandatory tests/evidence
At minimum prove:
1. current owner sees owner-safe history.
2. non-owner and former owner cannot obtain history.
3. record-only current marker.
4. supersede marks only latest current and prior historical.
5. void yields NO current while retaining historical observations.
6. fresh record after void becomes the only current observation.
7. repeated equivalent value in a later chain does not cause identity confusion.
8. newest-first deterministic presentation, including equal timestamp ordering by id internally.
9. no actor/staff ref, reason, predecessor/internal event id, source_reference, token, Shopify/provider data leaks.
10. public Passport/public profile/public collection/certificate/QR remain unchanged/value-free.
11. collector history GET/item detail is zero mutation.
12. existing Slice-1 Market Reference tests and Collector UI tests remain green.
13. full `tests/Feature/Sca` gate passes.
14. no migration; production baseline remains migration 138.

## Delivery discipline
- Branch from exact production baseline `6ca15958844dace74f7d087a10a3355a6497dd00`. If main moved, STOP.
- Prefer narrowly scoped changes in `MarketReferenceService`, `CollectionService`, collector item-detail view, and dedicated tests only.
- Do not alter staff writer semantics merely to support presentation.
- Do not weaken existing tests.
- Record exact changed files, focused tests, full SCA totals, privacy proof, zero-mutation proof and no-migration proof.
- Push candidate only.
- **Do not merge/deploy. STOP for ChatGPT pre-merge audit.**


<!-- Prior status (pre-merge PASS gate for candidate dba6c4d) retained below for traceability. -->

## ChatGPT pre-merge audit verdict — PASS
Independent GitHub audit verified:
- exact compare is **1 ahead / 0 behind**, merge base exactly `e20e549948ecbf5c967d48a7444275280dafb97c`
- exactly four changed files:
  - `collection/index.blade.php`
  - `collection/show.blade.php`
  - new `CollectorCollectionUi2Test.php`
  - narrow assertion update in `CollectorItemDetailParityTest.php`
- no migration, route, controller, service, DTO, domain writer, provider or infrastructure change
- My Collection is browse-first; private collection administration is secondary; active group/filter context preserved
- item detail is asset-first; adverse warning remains dominant; Market Reference uses the existing owner-safe DTO and retains advisory/non-guarantee semantics
- Passport/transfer eligibility remains conditional; transfer remains absent while adverse
- lost/stolen/recovered safety actions remain separated and continue through existing confirmation routes
- CP-4 visibility and CP-6 organization keep their existing routes/CSRF/domain semantics
- gallery remains owner-authorized and now exposes selected thumbnail state with `aria-pressed`; existing keyboard-focusable CSS-radio tabs and focus-visible treatment remain intact
- sensitive frame serial/QR token/storage/staff/internal data remains excluded by existing + new regression coverage
- GET catalog/detail zero-mutation coverage added
- existing parity assertion change from old “Manage item” to “Transfer” + “Report a problem” is consistent with the promoted Slice-2 architecture
- governance evidence reports focused 12/12 and full SCA gate 1347 passed / 1 skipped / 0 failed.

## Approved deployment gate
Claude may now:
1. Merge **only** approved candidate `dba6c4d7b83b674615f461d081f64d9c07e2077d` into current production main. If main moved from audited baseline before merge, STOP and return to ChatGPT.
2. Prove candidate→merge content identity (merge commit only / no unreviewed file delta).
3. Deploy the resulting merge SHA using the established controlled production procedure.
4. Confirm migration remains **138**; no migration is expected or permitted for this slice.
5. Run the full `tests/Feature/Sca` production/merge-tree gate and report exact pass/skip/fail/assertion totals.
6. Verify authenticated collector Collection index/detail and the Slice-1 shell boundary; include responsive/mobile evidence if available.
7. Record PRE/POST provenance fingerprint + canonical counts and prove unchanged.
8. Confirm no Caddy/DNS/Shopify OAuth/Stripe/SMTP/provider/infrastructure change.
9. Record exact `MERGE_SHA`, `ORIGIN_MAIN`, and `DEPLOYED_HEAD` plus deployment evidence in governance.
10. **STOP for ChatGPT post-deployment audit. Do not call Slice 2 closed and do not start another initiative.**

## Post-deployment audit targets
ChatGPT will independently verify:
- deployed SHA and candidate-identical tree
- migration 138
- full SCA gate
- collector shell/index/detail availability
- owner/privacy/security boundaries
- provenance fingerprint/counts unchanged
- no unrelated infrastructure/provider change.

**Only a post-deployment PASS closes Collector Experience / UI 2.0 Slice 2.**


<!-- Prior status (Slice 2 promotion) retained below for traceability. -->

## Architecture audit findings
Production already has strong collector capabilities but their presentation hierarchy is fragmented.

### My Collection today
Already correct/capable:
- canonical current-owner-only catalog
- stats: registered/certified/brands
- GET-only search/filter/sort with allowlisted service semantics
- private collection groups with create/rename/delete/reorder
- cards with authorized images, brand/model/ref/SKU/year/condition/certification/registry warning
- pagination and safe empty/filter states.

UX debt:
- private-group **management forms dominate the top of the catalog** before the eyewear itself
- collection browsing and collection administration are visually mixed
- controls are dense on mobile
- cards are functional but should align with the new premium collector shell/Home hierarchy
- obsolete “Back to account” remains despite persistent Slice-1 navigation.

### Eyewear Detail today
Already exposes owner-safe:
- authorized image gallery
- SCA ref + metadata/specifications
- authenticity status / condition / auth date
- certification current/history
- public Passport access
- public documents/downloads
- ownership/transfer history
- service history + corrections/annotations
- current Market Reference advisory value
- public-profile visibility control
- private collection organization
- transfer ownership
- lost/stolen/recovered controls
- adverse registry warning.

UX debt:
- Public-profile visibility and Organize cards appear **before the item identity/gallery**, so secondary management precedes the product.
- Market Reference is buried under History although it is a high-value current-item summary.
- “Manage item” mixes normal transfer with safety/destructive lost/stolen controls.
- important current facts are spread across five tabs and separate cards, making the item feel like an admin record rather than a collector asset.
- many inline styles and dense rows reduce mobile hierarchy.
- CSS-radio tabs are functional but should not hide the most important current state/value.
- imagery/brand/model should lead the experience.

## Slice 2 goal
Redesign **My Collection + Eyewear Detail presentation hierarchy** so the collector experiences owned eyewear as a premium digital collection while preserving every existing service, route, authorization and mutation rule.

This is primarily Blade/CSS/presentation composition. Reuse existing owner-safe DTOs/readers. Prefer **no controller/service changes** unless a narrowly necessary presentation composition is justified. **No migration.**

## A. My Collection — browse first, manage second
1. Keep the canonical current-owner catalog and all existing filters/sorts/pagination semantics.
2. Make eyewear the visual focus: strong responsive image cards, brand/model primary, SCA reference secondary, concise certification/registry/condition state.
3. Keep collection-group chips as the browsing switcher (All items + named groups).
4. Move create/rename/reorder/delete collection administration into a clearly secondary **Manage collections** area/disclosure below or beside browsing; it must not precede/domininate the eyewear grid on normal use.
5. Preserve active-group context and filter query behavior.
6. Mobile ~360px: controls must stack/wrap cleanly; no horizontal overflow; card tap targets remain clear.
7. Remove obsolete “Back to account” navigation; Slice-1 shell is authoritative.
8. Do not add favorites/tags/new grouping semantics.

## B. Eyewear Detail — asset-first hierarchy
The first viewport should answer:
**What is this? Is it authenticated/certified? Is it mine/currently safe? What is its current recorded market reference (if any)? What can I do next?**

Required composition:
1. **Asset hero**: gallery/image + brand/model + SCA ref + concise authenticity/certification/registry/ownership state. Preserve authorized image routes and gallery behavior.
2. **Current Market Reference**: when present, surface the existing owner-safe current advisory range near the primary summary (not buried only in History), retaining as-of, basis/source summary where appropriate and the exact non-guarantee/advisory meaning. Do not invent value, appreciation, currency conversion, comparables or history.
3. **Primary trusted actions**: Public Passport when eligible; normal ownership action such as Transfer may be reachable without hunting, but eligibility/authorization semantics remain unchanged.
4. **Details/history sections**: Authentication, Certification, Documents, Ownership history, Service history remain available and readable. Reorganizing tabs/sections is allowed; data semantics are not.
5. **Personal organization/sharing**: public-profile visibility and private-collection membership should be clearly secondary controls associated with the item, not cards that appear before identity.
6. **Safety actions**: Lost/Stolen/Recovered and staff-managed adverse state must be visually separated from ordinary actions. Preserve confirmation pages and all existing adverse transfer restrictions.
7. Do not duplicate the public Passport or certification PDF. Existing canonical routes remain authoritative.
8. Do not expose frame serial, QR token, internal IDs, storage paths, staff refs/reasons, private docs, another collector identity or any new PII.

## C. Interaction/accessibility requirements
- Continue the Slice-1 authenticated shell; Collection stays active on catalog/detail/transfer/status child routes.
- Mobile-first from ~360px through desktop; no horizontal overflow.
- Useful image alt text/fallback behavior; gallery thumbnail controls expose selected state to assistive technology, not visual class alone.
- Visible keyboard focus.
- Sections/tabs must remain usable by keyboard. If JS is used for presentation, progressive fallback must leave all essential information/actions reachable.
- Do not hide destructive/safety actions behind ambiguous icon-only controls.
- Flash success/error/status remains prominent and readable.
- Avoid introducing a frontend framework.

## D. Domain/security invariants — MUST NOT CHANGE
- current-owner authorization and privacy-safe 404
- authorized/no-store image and document routes
- public-profile item visibility semantics
- private collection membership/order semantics
- transfer workflow/token/eligibility semantics
- lost/stolen/recovered workflow + adverse restrictions
- authentication/certification/history semantics
- Market Reference Slice-1 advisory semantics
- Passport/QR/certificate semantics
- CSRF/throttle/collector guard/opaque refs
- zero new provenance/current-state writers.

No Market Reference Slice 2, marketplace/resale, analytics, notifications, SMTP, Stripe activation, backups, staff UI or public-profile/passport redesign.

## Mandatory tests / evidence
Add a focused Collector UI Slice-2 presentation test suite (or extend CollectorExperience cleanly) proving at minimum:
- catalog/detail remain current-owner scoped; previous/non-owner access remains safe
- Collection shell active state remains correct on index/detail and transfer/status child pages
- active private-group browse context and GET filters remain intact
- catalog cards use authorized image routes and never emit storage paths/internal ids
- detail hero renders owner-safe brand/model/ref and truthful current auth/cert/registry/ownership states
- Market Reference appears prominently only when canonical owner-safe current reference exists; absent/voided reference is not fabricated; advisory wording remains
- public Passport action only under existing eligibility
- visibility and private-collection controls retain exact existing route/CSRF/eligibility behavior
- transfer link/action hidden/blocked under the same adverse rules as before
- lost/stolen/recovered confirmation workflow remains intact
- documents remain owner-authorized/public-only
- gallery uses authorized ordinal image routes and selected thumbnail state is accessible
- no sensitive fields/QR token/storage path/staff refs leak into detail HTML
- GET index/detail remains zero provenance/current-state mutation
- ~360px responsive evidence (automated browser if available; otherwise deterministic markup/CSS assertions + documented manual viewport evidence)
- existing CP-2/CP-4/CP-6, item-detail parity/gallery, transfer/status, Market Reference and Collector Experience tests remain green
- full `tests/Feature/Sca` gate passes.

## Delivery discipline
- Branch from exact production `e20e549948ecbf5c967d48a7444275280dafb97c`. If main moved, STOP.
- **No migration.** If schema/new authoritative state seems necessary, STOP and return architecture rationale.
- Do not refactor domain services merely for aesthetics.
- Keep changes narrowly in collector presentation/tests unless a presentation DTO composition change is justified and documented.
- Record changed files, focused/full tests, responsive evidence, and zero-mutation/privacy proof in governance implementation evidence.
- Push candidate only. **Do not merge/deploy. STOP for ChatGPT pre-merge audit.**


<!-- Prior status (pre-merge PASS gate for candidate 0c8628d) retained below for traceability. -->

## ChatGPT R1 re-audit — PASS
Independently verified actual GitHub candidate `0c8628d352f9a0fb843774bff5281bc808a9248c`:
- exact production base `9cf72728248cf3e36d0525de4520d69717dacd5d`
- exactly **1 ahead / 0 behind**
- no migration
- original accepted Slice-1 shell/Home/navigation/privacy/current-owner/image/route boundaries preserved
- R1 submission summary is now derived only from canonical collector-scoped submission status:
  - `draft|submitted|awaiting_item` → **Awaiting receipt by SCA**
  - `received` → **Received & being processed**
  - `cancelled` → total only; never represented as active or completed
- no downstream authentication/payment/claim/return state is invented by the Home projection
- a received frame remains represented as being processed regardless of awaiting-exam / passed-not-certified / certified / failed-auth examples
- cross-collector submissions do not affect the summary
- dashboard GET remains zero-mutation
- accepted reported gate: focused 21 passed; full `tests/Feature/Sca` 1335 passed / 1 skipped / 0 failed.

R1 is CLOSED. No further remediation required before merge.

## Controlled merge + deployment gate
Deploy **only** the exact approved candidate `0c8628d352f9a0fb843774bff5281bc808a9248c`.

1. Merge the approved branch to `main`.
2. Prove the merge tree is candidate-identical (merge commit only; no unexpected file/content delta from the approved candidate).
3. Deploy the resulting exact `main` merge commit using the established production procedure.
4. Confirm migration remains **138**; there is no migration in this slice.
5. Run the focused CollectorExperience/AppPolish tests and the full `tests/Feature/Sca` gate on the deployed/merge tree.
6. Confirm production health, including `/admin/login → 200`, collector guest `/collector` → sign-in, and an authenticated collector Home renders successfully.
7. Verify canonical provenance fingerprint/counts are unchanged from pre-deploy baseline:
   - fingerprint `d15a5cbdfb8df52ba65628b276533cfe`
   - counts `3/3/4/4/5/2/1/1/7`
8. Confirm no schema/provider/infrastructure drift: no Caddy/DNS/OAuth/SMTP/Stripe change.
9. Record merge SHA, deployed SHA, test results, migration, fingerprint/counts and smoke results in governance evidence.

If any gate fails, restore production to the pre-deploy baseline and STOP.

After successful deployment, **STOP for ChatGPT independent post-deployment audit. Do not declare Slice 1 closed and do not begin Slice 2 or another initiative.**


<!-- Prior status (pre-merge FAIL R1 of candidate b69824f) retained below for traceability. -->

## ChatGPT independent audit
Verified actual GitHub candidate:
- exact base `9cf72728248cf3e36d0525de4520d69717dacd5d`
- exactly **1 ahead / 0 behind**
- exactly 7 expected presentation/read-model/test files
- no migration
- authenticated shell/route guard boundaries intact
- guest auth pages remain without authenticated nav
- active nav grouping is coherent for Home/Collection/transfer/status/Submissions/Profile/Account
- dashboard collection data reuses canonical current-owner catalog/stats; catalog itself is bounded to page size 24 before Home slices to 4
- preview uses authorized image/detail routes and no raw storage path
- publication state is collector-scoped
- dashboard is read-only; no observed provenance/current-state writer introduced
- accepted candidate report: focused 17 pass; full SCA 1331 pass / 1 skip / 0 fail.

Do NOT reopen these accepted areas in R1.

## R1 blocker — Home's “In progress” submission count becomes false after physical receipt
`CollectorDashboardService::ACTIVE_SUBMISSION_STATUSES` is:
`['draft', 'submitted', 'awaiting_item']`.

The Home view renders that count under the consumer-facing label **“In progress.”**

But the canonical `SubmissionService` deliberately makes `received` terminal only for the submission-state machine; later External Paid Authentication slices keep the submission status at `received` while the bound item proceeds through authentication, certification, grant/claim, and physical-return handling. Slice 6 explicitly preserves submission status `received` and tracks return separately.

Therefore “terminal in SubmissionService” does NOT mean “authentication work complete” to the collector. A received frame can still be actively under examination / passed-not-certified / certified-pending-grant / claimable / return-pending, while the new Home dashboard reports it as not in progress. Example: one collector submission at `received`, bound item awaiting examination → Home shows Total=1, In progress=0. That is materially misleading.

The promotion required a **truthful meaningful active/pending summary** and prohibited invented provider/payment state.

## Required R1 remediation
Do not solve this by merely adding `received` blindly to a constant without defining the user-facing meaning.

Choose one coherent projection and document it:
1. Prefer a collector-facing **“Needs attention / In progress / Completed”** summary derived from existing submission + bound-item/result/return state, reusing the already-established safe result semantics where practical; OR
2. If Slice 1 should stay intentionally simpler, change the metric/label to something whose semantics are exactly true from the canonical submission status (for example a narrowly named pre-receipt metric), and ensure received work is not presented as completed/inactive by implication.

Whichever approach is chosen:
- no new authoritative state/table/migration
- no payment/provider invention
- collector-scoped only
- no extra PII/internal ids
- no mutation
- keep the dashboard bounded
- preserve all existing domain workflows.

### Mandatory R1 tests
Add focused proof covering at least:
- draft/submitted/awaiting_item semantics
- a `received` submission with bound item **awaiting examination**
- a received item **passed but not certified**
- a received item **certified / claimable or registered-to-you** as applicable to the chosen projection
- failed/inconclusive + return state where relevant to the chosen labels
- cancelled submission
- another collector's submissions never affect counts
- dashboard GET remains zero-mutation.

The assertions must test the **user-visible label/count semantics**, not only a private constant.

Re-run focused Collector Experience/AppPolish and full `tests/Feature/Sca`.

Push remediation candidate only. **Do not merge/deploy. STOP for ChatGPT R1 re-audit.**


<!-- Prior status (Collector UI 2.0 Slice 1 promotion) retained below for traceability. -->

## Architecture audit findings
The collector domain is already broad: account/security, private/public profile + handle/avatar, My Collection, rich item detail/gallery/passport, certification/authentication/ownership/transfer/service histories, private collection groups, public-item visibility, lost/stolen/recovered, transfer, documents, external-auth submissions/payment/claim, and current-owner Market Reference.

The experience layer has not caught up:
- `/collector` is a pure redirect rather than a collector home.
- The shared layout is fundamentally a narrow ~420px form shell; only item detail opts into a wider layout.
- There is no persistent authenticated primary navigation. Discovery relies heavily on contextual text links among Account/Profile/My Collection/Submissions.
- Account currently doubles as a landing/navigation page while also containing password and irreversible privacy controls.
- Profile is long and mixes identity, stats, editing, avatar, publication and handle management in one vertical form.
- Submission list is functional but isolated from a unified collector overview.
- Item detail is already the strongest experience and should be preserved/refined rather than rebuilt.
- Existing route/controller authorization and privacy boundaries are strong; UI work must not weaken them.

## Slice 1 goal
Create a **mobile-first Collector Home + shared authenticated application shell** that makes the already-built product understandable and reachable. Do NOT add new domain capabilities in this slice.

Target information architecture:
- **Home** — new authenticated `/collector` dashboard.
- **Collection** — existing My Collection.
- **Authenticate** — existing submissions area / new-submission entry.
- **Profile** — existing collector profile.
- **Account** — existing security/privacy settings.

Desktop: compact persistent top/side navigation appropriate to the existing SCA visual language.
Mobile: touch-friendly persistent navigation/header with no horizontal overflow; key actions reachable without hunting through text links. Do not introduce a JS framework solely for navigation.

## Home dashboard read model
Build a dedicated, bounded dashboard projection from existing canonical/read services; no new authoritative tables.
Show only truthful collector-scoped information already authorized elsewhere:
- greeting/display identity
- owned-item count, certified count, distinct brands (reuse existing profile stats semantics)
- a small recent/current collection preview with image only through existing authorized image route and links to canonical item detail
- external authentication submission summary: meaningful active/pending states + link to submissions; do not invent payment/provider state
- pending ownership-transfer attention only if existing workflow/read model can expose it safely
- profile/publication state summary + link to Profile
- primary actions: View collection / Submit eyewear.
Do not fabricate an activity feed by querying unrelated audit/provenance tables in this slice.

## Shell/navigation requirements
1. Guest auth pages (login/register/forgot/reset) remain simple and must NOT expose authenticated navigation.
2. Authenticated shell gets consistent nav and active-state semantics across Home, Collection/detail, Submissions, Profile and Account.
3. `GET /collector`: guest behavior remains redirect-to-login; authenticated collector now renders Home rather than redirecting to Collection.
4. Preserve existing route names where possible; add only the minimum home route/controller/view/read-model changes.
5. Account stops acting as the primary navigation hub; keep password/security/privacy behavior intact.
6. Preserve every CSRF/throttle/collector-guard/current-owner/opaque-ref/privacy rule.
7. No staff/admin navigation or Krayin chrome.
8. No public-profile/public-passport redesign in Slice 1.
9. No changes to transfer/status/submission/payment/claim/provenance mutation semantics.
10. No Market Reference expansion, automated pricing, marketplace/resale, notifications, analytics, SMTP, Stripe activation or backup work.

## Responsive/accessibility quality gate
- Design for ~360px mobile through desktop; no horizontal overflow in shell/dashboard.
- Visible keyboard focus; semantic nav; current page indicated beyond color alone; adequate touch targets.
- Preserve readable labels/errors/status messages and form semantics.
- Avoid hiding security/destructive controls behind ambiguous icons.
- Images must have useful alt/fallback behavior and retain current authorization/no-store behavior.
- No raw storage paths/internal IDs/secrets/PII leakage.

## Mandatory tests
Add focused Collector Experience tests proving at minimum:
- guest `/collector` still reaches sign-in safely; authenticated `/collector` renders Home.
- authenticated nav appears on Home/Collection/item/Submissions/Profile/Account; guest auth pages do not receive it.
- active navigation state is correct for child/detail routes.
- dashboard stats are collector-scoped and reuse canonical semantics.
- collection preview cannot leak previous/non-owner items; images use authorized routes.
- submission summary is collector-scoped and truthful.
- dashboard GET causes zero provenance/current-state/domain mutation.
- disabled/pseudonymized/unauthenticated boundary behavior remains fail-closed.
- existing item-detail, collection, profile, submission, transfer/status and auth tests remain green.
- full `tests/Feature/Sca` gate passes.

## Delivery discipline
- Branch from exact production `9cf72728248cf3e36d0525de4520d69717dacd5d`. If main moved, STOP.
- Prefer no migration. If implementation believes schema is required, STOP and return architecture rationale before adding one.
- Keep changes inside collector presentation/read-model/test surfaces unless a narrowly necessary shared presentation helper is justified.
- Record changed files, focused/full test results, screenshots or viewport evidence if available, and zero-domain-mutation proof in a task report.
- Push candidate only. **Do not merge/deploy. STOP for ChatGPT pre-merge audit.**


<!-- Prior status (controlled activation promotion) retained below for traceability. -->

## Audited production architecture
- Collector forgot/reset uses dedicated `sca_collectors` broker, hashed account-bound 60-minute single-use token, active-only eligibility, CSRF and throttle, enumeration-safe generic response, no auto-login or provenance mutation.
- ForgotPasswordController catches mail transport exceptions without exposing account status/PII; intentionally retains token because SMTP failure may occur after provider acceptance.
- Collector reset notification URL origin was hardened to trusted `config('app.url')` rather than request Host.
- `app/config/mail.php` no longer disables SMTP TLS peer verification.
- Docker app loads `app/.env` directly (no injected env_file); app is loopback-only behind existing Caddy.
- Production `MAIL_MAILER=log`, so real delivery remains inactive.
- No SMTP provider credential or verified sender/domain is established by this audit. Do not invent either.
- Public canonical application origin: `https://verify.secondchanceauthenticators.com`. Verify actual effective `APP_URL` before activation; do not assume it matches.

## Provider decision
Use **Postmark Transactional SMTP**, not Broadcast SMTP or API transport. Official Postmark SMTP host `smtp.postmarkapp.com`, port 587 STARTTLS. Prefer a dedicated per-Transactional-stream SMTP Token (access key username, secret key password) rather than account-wide credentials. Postmark must verify the sender domain/signature and DNS DKIM + custom Return-Path; check DMARC alignment. Follow provider-generated DNS values exactly; never fabricate DKIM or credential values.

Proposed sender identity: a dedicated mailbox at `send.secondchanceauthenticators.com` (e.g. `no-reply@send.secondchanceauthenticators.com`) ONLY if verified and accepted by the owner/provider. If the owner chooses a different sender/domain, record that decision before changing DNS. Do not modify MX, existing mail routing, or unrelated DNS.

## One controlled activation work package

### Phase 0 — read-only preflight and external prerequisites
1. Verify production main/deployed SHA `9cf7272...`, migration 138, clean tree, existing reset/mail tests, current effective `APP_URL`, `MAIL_MAILER`, `MAIL_FROM_ADDRESS`, config cache state, PHP SMTP transport availability, egress to Postmark TCP 587, and authoritative DNS control.
2. Identify Postmark account/server/Transactional stream availability, SMTP enabled, verified sender/domain, provider-supplied DKIM/Return-Path DNS, and authorized safe recipient inbox for real test. **Do not print/commit/mail/log secrets or reset tokens.**
3. If provider access, DNS authority, test inbox, or SMTP credentials are missing, **STOP WITH BLOCKED PREREQUISITES** and return a precise owner action list. Do not silently switch to another provider or claim activation.

### Phase 1 — provider/DNS readiness (only with explicit owner authorization)
4. Create/use a dedicated Postmark Transactional stream and scoped SMTP Token; never use broadcast host/stream.
5. Configure ONLY provider-issued DKIM TXT and custom Return-Path CNAME for approved sending domain; verify status in Postmark and validate DNS propagation, SPF/DMARC alignment. Preserve existing DNS/MX and other tenants.
6. Validate trusted `APP_URL` and From identity before real mail. Keep `MAIL_MAILER=log` until prerequisites and test transport are proven.
7. Record sanitized evidence of provider stream status, DNS verification, and SMTP TLS reachability (never credentials).

### Phase 2 — safe isolated delivery proof
8. Use a disposable isolated runtime/config or non-production test account/inbox to prove Postmark SMTP auth and STARTTLS with certificate verification ON, correct sender/recipient, provider acceptance and actual mailbox receipt. No production customer email during setup.
9. Validate delivered headers: DKIM pass, SPF/Return-Path alignment as configured, DMARC pass, trusted HTTPS reset origin; verify no Host-header poisoning. Provider acceptance alone is NOT inbox delivery proof.
10. Exercise a controlled collector password reset end-to-end using an authorized test collector/inbox: active account gets link, single use, expiry, no auto-login; unknown/disabled generic responses and no usable reset; mail failure stays enumeration-safe; no provenance/identity mutation.
11. Ensure logs, screenshots, governance evidence and tests do not contain SMTP tokens, collector emails, reset links, plaintext tokens or personal data.

### Phase 3 — production cutover / rollback
12. Only after Phase 2 PASS and owner-authorized change window, securely set production `MAIL_MAILER=smtp`, `MAIL_HOST=smtp.postmarkapp.com`, `MAIL_PORT=587`, `MAIL_ENCRYPTION=tls`, scoped `MAIL_USERNAME`/`MAIL_PASSWORD`, verified `MAIL_FROM_ADDRESS`/`MAIL_FROM_NAME`, canonical HTTPS `APP_URL`; retain TLS peer verification.
13. Reload/clear config safely and confirm effective transport WITHOUT printing secrets. Do not change application code/schema unless a separately reviewed defect truly requires it.
14. Controlled production delivery smoke only to authorized test inbox; confirm real receipt and one successful test-account reset. Confirm no customer blast.
15. Re-check app health, collector/guest boundary, canonical provenance fingerprint/counts, current-state and integration config. No Caddy/edge/Shopify/Stripe/DB migration changes.
16. On any authentication/TLS/DNS/delivery/reset/security failure, rollback `MAIL_MAILER=log` and restore previous safe mail config, then re-check health and report BLOCKED. Do not leave partially activated SMTP or pretend log delivery is success.

### Evidence and stop
- Run focused existing `TransactionalEmailHardeningTest`, `CollectorPasswordRecoveryTest`, and full `tests/Feature/Sca` before production cutover if runtime permits.
- Record exact deployed SHA/migration, prerequisite states, sanitized provider/DNS/TLS checks, authorized test mailbox receipt and authentication results, reset lifecycle matrix, PRE/POST invariants, config change/rollback evidence.
- Commit governance report `docs/SCA-TRANSACTIONAL-EMAIL-ACTIVATION-RESULT.md` (no secrets).
- **STOP for ChatGPT independent activation audit.** Do not declare email LIVE until independent audit PASS. Do not start backups, Stripe, pricing, resale or other initiative.


<!-- Prior status (pre-merge PASS gate for candidate d880e12) retained below for traceability. -->

## ChatGPT pre-merge audit verdict
**PASS.**

Independent audit of actual GitHub candidate confirms:
- exact production base `b4b51b7bb0244da6e1624c1095239c80cc206bb9`
- candidate exactly 1 commit ahead / 0 behind
- Slice 1 remains scoped to the audited 17 implementation/test files
- expected migration 137→138
- dedicated append-only, non-provenance Market Reference ledger
- record/supersede/void lifecycle
- integer minor-unit range + USD/PHP and basis allowlists
- strict exact calendar-date validation
- immutable UPDATE/DELETE blocking
- same-item predecessor enforcement
- DB lifecycle enforcement against actual current effective event
- DB monotonic append-order enforcement consistent with canonical `(created_at,id)` fold
- equal timestamps valid and deterministically ordered by higher id
- service item-state FOR UPDATE + optimistic token STALE protection
- genuine two-connection production-service concurrency proof
- dedicated ACL/auth/CSRF/throttle + server-derived actor
- staff full audit history
- current-owner-only safe collector projection
- public Passport/profile/collection, certificate snapshot/PDF and QR remain valuation-free
- no automated/AI/external pricing or Shopify-price ingestion
- zero intended provenance/current-state mutation.

R1 and R2 direct proofs are accepted:
- impossible/non-exact dates fail closed; valid leap date accepted; future policy preserved
- raw second-current record rejected
- raw historical predecessor supersede/void rejected
- valid lifecycle rows accepted
- backdated current supersede rejected
- backdated current void rejected
- backdated post-void fresh record rejected
- equal-timestamp successor accepted and proven canonical current
- normal production-service record→supersede→void remains correct.

Reported focused gate: **35 passed**.
Reported full SCA gate: **1320 passed / 1 skipped / 0 failed**.

## Controlled merge/deployment gate
Claude may merge/deploy **only exact approved candidate `d880e128e0713d60e42a2d821206cf663c09be43`**.

1. Reconfirm main/production is still exact baseline `b4b51b7bb0244da6e1624c1095239c80cc206bb9`. If it moved, STOP.
2. Reconfirm candidate is 1 ahead / 0 behind and candidate tree unchanged.
3. Merge with an auditable merge commit. Prove candidate→merge has **zero changed files** / content-identical tree. Any drift = STOP.
4. Run the exact merge-tree full `tests/Feature/Sca` gate before production migration. Any real failure = STOP before migrate. Existing documented unrelated flakes may only be handled under the established fail-before-migrate/rerun policy and must be disclosed.
5. Capture PRE production:
   - migration number 137
   - reproducible provenance fingerprint and canonical counts
   - Market Reference table absent
   - relevant baseline integration/config state.
6. Apply migration 138 once.
7. Verify production schema exactly:
   - `sca_market_reference_events`
   - all CHECK constraints
   - append-only UPDATE/DELETE triggers
   - BEFORE INSERT same-item + lifecycle + monotonic-order trigger
   - self/item FKs and expected indexes.
8. Immediately after deploy, Market Reference ledger must contain **0 rows** unless a real independently authorized staff action occurred. Do not fabricate production Market Reference evidence for smoke testing.
9. Run production-safe route/boundary smoke:
   - app/admin health
   - routes registered
   - unauthenticated mutation fail-closed
   - dedicated ACL/CSRF/throttle already proven by exact merge-tree tests
   - collector/public surfaces remain healthy without creating evidence.
10. Capture POST provenance fingerprint/counts and prove byte/count identity to PRE.
11. Confirm no unexpected changes to service history, ownership/current state, authentication, certification/PDF/snapshot, QR, registry status, claim/transfer, Shopify sale links, collector accounts.
12. Confirm no Caddy/DNS/Shopify OAuth/Stripe/SMTP changes; Stripe remains dormant and mail remains current production configuration.
13. Record exact merge/main/deployed SHA, migration 138, exact merge-tree test results, schema verification, PRE/POST invariants, ledger count, boundary smoke, and integration/config evidence in a governance deployment result document.

**STOP after deployment evidence. Do not declare Slice 1 closed. Do not start automated pricing, public value exposure, resale, or another initiative. Return to ChatGPT for independent post-deployment audit.**

<!-- Prior status (R1 re-audit FAIL R2 of candidate 23c28eb) retained below for traceability. -->

## ChatGPT independent R1 re-audit
Verified actual GitHub candidate:
- exact production base `b4b51b7bb0244da6e1624c1095239c80cc206bb9`
- candidate `23c28ebc78754e82dfc37e082d04ca983dcdc234`
- exactly 1 commit ahead / 0 behind base
- rewritten single candidate commit relative to prior failed SHA is acceptable
- accepted Slice-1 architecture remains intact.

### R1 blocker B — CLOSED
`MarketReferenceService::normAsOfDate()` now:
- requires exact `YYYY-MM-DD`;
- uses strict createFromFormat + exact round-trip;
- rejects impossible/non-exact dates;
- retains future tolerance.

`mr27` directly exercises the production service and proves impossible/non-exact rejection, valid leap date, zero invalid writes, and preserved future rejection.

Do not change this area in R2.

### R1 blocker A — PARTIALLY CLOSED; narrow R2 remains
`trg_mre_bi` now correctly derives the existing stream's current event by `(created_at,id)` and rejects:
- record while a current exists;
- supersede whose predecessor is not the existing current;
- void whose predecessor is not the existing current;
- cross-item predecessors.

The direct-DB tests genuinely prove those normal-order cases.

## R2 blocker — NEW row can be backdated behind the event it supersedes/voids
The canonical fold order is `(created_at,id)`. The BEFORE INSERT trigger validates lifecycle against the stream **before** NEW is inserted, but it does not constrain NEW.created_at relative to the existing last event.

Therefore a raw insert can:
1. have current `e1`;
2. insert a structurally valid `supersede e2 -> e1` with `NEW.created_at < e1.created_at`;
3. pass the trigger because e1 is current before the insert;
4. after insertion, canonical `foldCurrent()` orders e2 before e1, so e1 remains effective even though immutable e2 says it supersedes e1.

The same ordering defect applies to a backdated void. It also allows a fresh record inserted after a void to be backdated before that void, so the trigger accepts it while the fold still ends at the void.

This means the DB still permits immutable lifecycle evidence whose predecessor/action semantics disagree with the canonical fold.

### Required R2 remediation
At the DB insert boundary, guarantee that every newly appended market-reference event sorts after the existing last event for that item under the canonical `(created_at,id)` ordering.

A narrow acceptable implementation is to reject a NEW row whose `created_at` is earlier than the existing last event's `created_at`. Equal timestamps are valid because the auto-increment NEW id sorts after the prior id.

Preserve:
- canonical fold order `(created_at,id)`;
- service-created `now()` timestamps;
- current lifecycle trigger logic;
- append-only semantics;
- all accepted R1 behavior.

Do not redesign the ledger or change the product policy.

### Mandatory R2 direct-DB proof
Add raw DB tests showing:
1. backdated supersede of the actual current event is rejected;
2. backdated void of the actual current event is rejected;
3. after a valid void, a backdated fresh record that would sort before the void is rejected;
4. equal-timestamp valid successor remains accepted and becomes current by higher id;
5. normal service record/supersede/void remains unchanged.

For accepted inserts, assert the canonical `currentReference()` result agrees with the lifecycle action/predecessor.

Re-run focused MarketReference tests including the real two-connection concurrency test and full `tests/Feature/Sca`.

Update `docs/SCA-MARKET-REFERENCE-SLICE1-IMPLEMENTATION.md` with R2 evidence, push a NEW candidate SHA, and STOP.

**DO NOT merge. DO NOT deploy. DO NOT begin another initiative.**

<!-- Prior status (pre-merge FAIL R1 of candidate 26a572a) retained below for traceability. -->

## ChatGPT independent pre-merge audit
Actual GitHub candidate verified:
- exact base `b4b51b7bb0244da6e1624c1095239c80cc206bb9`
- candidate exactly 1 commit ahead / 0 behind
- 17 changed files
- expected migration 137→138
- dedicated append-only market-reference ledger
- record/supersede/void application lifecycle
- integer minor units + bounded USD/PHP and basis allowlists
- item-state FOR UPDATE + event-count/current-id STALE protection
- genuine two-process/two-connection production-service concurrency proof
- dedicated ACL + staff auth/CSRF/throttle
- server-derived actor
- canonical service reader + collector privacy projection
- current-owner-only collector integration
- public Passport/profile/collection exclusion
- certificate snapshot/PDF + QR exclusion
- zero intended provenance/current-state mutation
- append-only UPDATE/DELETE triggers and same-item predecessor trigger.

Those areas are accepted for R1 and should not be redesigned.

## R1 blocker A — immutable DB ledger permits semantically impossible histories
The DB currently enforces row shape and **same-item** predecessor linkage, but not lifecycle validity.

A direct/raw insert can still persist structurally valid but impossible immutable history, for example:
1. `record → record` while the first record is still current;
2. `record(e1) → supersede(e2→e1) → supersede(e3→e1)`, where e3 targets the historical/non-current e1;
3. `void` targeting a historical/non-current same-item event.

The application service correctly rejects these paths, but the canonical reader `foldCurrent()` trusts every persisted row and simply treats any record/supersede as current and any void as clearing current. Therefore one malformed raw row can permanently alter effective Market Reference state even though the ledger is append-only and cannot be repaired.

This conflicts with the promoted invariants:
- at most one effective current per item;
- supersede/void must target the current effective event;
- no supersede/void of historical target;
- malformed raw rows must fail closed at the DB boundary;
- immutable evidence must not permit impossible event histories.

### Required remediation A
Add insert-time DB enforcement (trigger or equivalent DB boundary) that validates the lifecycle against the existing immutable stream for NEW.eyewear_item_id:
- `record` allowed only when the current effective state is null (first ever or after a valid current void);
- `supersede` predecessor must equal the actual current effective event for that item;
- `void` predecessor must equal the actual current effective event for that item;
- preserve same-item predecessor enforcement;
- after a valid void, a fresh record remains allowed.

Keep the production service locking/token logic unchanged. The DB rule is defense-in-depth for raw/malformed rows, not a replacement for service serialization.

Add direct-DB tests proving:
- second record while current exists is rejected;
- supersede of historical same-item predecessor is rejected;
- void of historical same-item predecessor is rejected;
- valid current supersede and valid current void still work;
- fresh record after valid void still works.

## R1 blocker B — canonical service accepts impossible calendar dates
`MarketReferenceService::normAsOfDate()` uses permissive `Carbon::parse()`. Inputs such as an impossible calendar date can normalize to another real date rather than fail, even though the architecture requires invalid dates to fail closed and MarketReferenceService is the canonical writer/validator.

The FormRequest's `date` rule protects the HTTP UI, but direct callers of the production service are part of the domain boundary and current focused tests explicitly exercise the service directly.

### Required remediation B
Use strict YYYY-MM-DD validation in `MarketReferenceService` itself:
- exact format only;
- reject impossible calendar dates rather than normalize them;
- retain the existing future-tolerance policy after strict parsing.

Add service-level tests for at least:
- impossible date such as `2026-02-31` rejected with INVALID and zero write;
- malformed but parseable/non-exact date rejected;
- valid leap/calendar date accepted as appropriate;
- existing future-date rejection preserved.

## R1 scope guard
Do NOT redesign:
- record/supersede/void product policy;
- staff/collector UI;
- amount/currency/basis model;
- ACL/routes;
- owner privacy;
- public exposure policy;
- concurrency mechanism;
- provenance boundaries;
- automated pricing/public value/resale.

Re-run focused MarketReference tests including real concurrency and full `tests/Feature/Sca`. Update `docs/SCA-MARKET-REFERENCE-SLICE1-IMPLEMENTATION.md` with R1 evidence, push a NEW candidate SHA, and **STOP**.

**DO NOT merge. DO NOT deploy. DO NOT begin another initiative.**

<!-- Prior status (pre-merge PASS gate for candidate 2d578feb) retained below for traceability. -->

### ChatGPT pre-merge audit verdict
**PASS.** Actual GitHub candidate `2d578feb5f429d9e7549d968c21fbfc879ba0885` satisfies the promoted Service History Correction & Annotation architecture after R1/R2 remediation.

Verified:
- exactly 1 commit ahead / 0 behind production base `9bc0907...`
- scoped 15-file slice; no unrelated initiative
- migration 136→137 creates dedicated append-only `sca_service_event_corrections`
- original `sca_service_events` remains immutable and untouched
- sparse factual evidence uses explicit per-field change flags
- nullable notes/grade support unambiguous explicit clear via flag=1 + NULL
- non-nullable service_type/occurred_at require a value when flagged
- DB CHECKs now enforce sparse-row self-consistency; contradictory raw rows fail closed
- non-correct rows cannot carry corrected factual payload
- DB cross-item trigger + service exact item/event binding prevent rebinding
- correction ledger UPDATE/DELETE blocked
- deterministic fold applies only flagged fields in `(created_at,id)` order
- selected-but-equal values are omitted; all-NOOP rejects
- staff chronology renders exact changed fields old→new plus actor/time/reason
- item current-state `FOR UPDATE` serialization + correction-count token provide STALE protection
- real two-connection concurrency proof remains present
- terminal void behavior preserved
- dedicated `sca.eyewear.service.correct` ACL, admin auth/CSRF/throttle boundary preserved
- collector path is a privacy projection over the same canonical fold; voided events and staff-only audit data excluded
- public passport remains service-free
- `ServiceService::record()` and `ProjectionService::rebuild()` unchanged
- zero intended ownership/current-state/authentication/certification/QR/status/claim/transfer/Shopify mutation
- R2 raw-DB tests prove unflagged payload rejection, required flagged values, and valid nullable clears
- explicit condition-grade clear-to-NULL is proven through production controller/service
- reported focused result: 42 passed
- reported full SCA result: 1285 passed / 1 skipped / 0 failed.

### Controlled merge/deployment gate
Claude may now merge/deploy **only this exact approved candidate** `2d578feb5f429d9e7549d968c21fbfc879ba0885`.

Before merge/deploy:
1. Reconfirm production/main baseline is still `9bc0907c486688c7acd0d22ad2ee9f5db37d93bb`; if main/production moved, STOP for ChatGPT.
2. Reconfirm approved candidate is exactly 1 ahead / 0 behind baseline and candidate tree is unchanged.
3. Merge with a normal auditable merge commit; after merge, prove candidate→merge tree has **zero changed files**. Any content drift = STOP.
4. Run the exact merge tree full `tests/Feature/Sca` gate before production migration. Known unrelated low-ID document-classification flake may be rerun only under the established policy; any real failure = STOP before migrate.
5. Capture PRE production migration number, provenance fingerprint/counts, service-event count, and confirm correction table absent.
6. Apply migration 137 once. Verify table, all CHECK constraints, append-only triggers, cross-item trigger and indexes exist.
7. Run production-safe health/boundary smoke only; do not fabricate or mutate real service/correction evidence merely to demonstrate the feature.
8. Capture POST provenance fingerprint/counts and service-event count; they must be byte/count identical to PRE. New correction table should contain 0 rows immediately after deploy unless a real authorized staff action occurs independently.
9. Confirm no Caddy/DNS/Shopify OAuth/Stripe/SMTP changes; Stripe remains dormant and mail remains current production configuration.
10. Record exact merge SHA, main SHA, deployed SHA, migration 137, exact merge-tree test result, schema evidence, PRE/POST invariants and health/boundary results in a governance deployment evidence document.

**STOP after deployment evidence. Do not declare the initiative closed. Do not start another initiative. Return to ChatGPT for independent post-deployment audit.**

Updated 2026-10-13.

## Why this is next
Shopify Reconciliation & Operations is CLOSED. ChatGPT audited the live service-history architecture at production `9bc0907`.

The existing service-history foundation is intentionally strong and must be preserved:
- `sca_service_events` is append-only and storage-immutable.
- service recording is staff-only and session-attributed.
- service type and condition observations are validated.
- service events never rewrite authentication grade, certification, ownership, registry status, QR identity, or lifecycle.
- the current owner sees owner-safe service history; non-owners fail closed.
- public Passport does not expose service notes/staff data.

The operational integrity gap is correction: if staff records the wrong service type/date/condition/notes, there is currently no governed way to correct the record. Editing/deleting the immutable event is forbidden and must remain forbidden.

## Initiative
**SCA Service-History Correction & Annotation**

Build an append-only correction/annotation layer over immutable service events.

### Core invariant
**A recorded service event is permanent historical evidence. Correction never edits or deletes it. A correction appends new evidence that explicitly supersedes/corrects presentation of the target event while preserving the original forever. Service-history correction must never mutate ownership, authentication, certification, QR, registry status, claim, Shopify state, or any other provenance domain.**

### Architecture requirements
1. Preserve the existing `sca_service_events` rows and immutability trigger unchanged. No UPDATE/DELETE escape hatch.
2. Add a dedicated append-only service-history correction/annotation ledger, preferably migration **136→137**.
3. Corrections target one exact existing service event and exact eyewear item. The target relationship must be server-validated; cross-item correction must fail closed.
4. Do NOT create a replacement `sca_service_events` row pretending the corrected facts were another real service occurrence. Keep the original service occurrence immutable and attach correction evidence to it.
5. Support a bounded correction snapshot for the displayable service facts:
   - service type
   - occurred_at
   - condition_grade_after
   - notes
   A correction should carry the effective corrected values plus mandatory reason, actor staff ref, and created_at.
6. Prefer **full corrected snapshot per correction row** rather than one row per changed field, because service history is one coherent historical occurrence and reads need deterministic latest-effective presentation.
7. Corrections themselves are append-only. If a correction is wrong, append another correction against the same original service event. Latest valid correction wins for effective presentation; the entire correction chain remains auditable.
8. Add storage-level immutability for correction rows (UPDATE/DELETE rejected).
9. Add storage-level same-item integrity where practical: correction.eyewear_item_id must match the target service event's eyewear_item_id. If MariaDB CHECK cannot enforce cross-table identity, use a BEFORE INSERT trigger plus service validation.
10. Add a dedicated mutation ACL, e.g. `sca.eyewear.service.correct`, separate from ordinary `sca.eyewear.service` recording and `sca.eyewear.view`.
11. Staff correction must use a GET confirmation/review interstitial + POST mutation. The target event must be server-resolved; never accept staff id, item id, or prior values from the client as authoritative evidence.
12. Require a nonblank correction reason, bounded length. Normalize corrected notes safely and preserve nullable semantics.
13. The correction screen must show the immutable original event and the current effective presentation so staff understands what is being corrected.
14. Use optimistic concurrency. The POST must prove the correction chain is still the one the staff reviewed. Prefer expected correction-count or latest-correction opaque/version token; re-check under lock. A concurrent correction must produce safe STALE rejection, never last-write-wins silently.
15. Transaction lock order: lock the canonical item/current-state row first, then resolve/lock the target service event/correction chain as needed. Keep consistent with other SCA correction workflows.
16. Reject a semantic no-op: if submitted effective values equal the current effective presentation, no correction row is appended.
17. Existing service recording remains unchanged and may continue after a corrected historical event.
18. Owner-facing My Collection service history must show the **effective corrected presentation**, not stale original values, while preserving privacy. It may show a simple non-sensitive “Corrected” indicator/date, but must not expose correction reason, staff identity, internal ids, or correction-chain metadata.
19. Staff item detail should show effective service history and a correction affordance to authorized staff. Staff audit view may show original + correction history/reasons/actor refs as appropriate behind staff ACL.
20. Public Passport remains unchanged: no service notes/corrections/reasons/staff data become public.
21. Transfer behavior: service history follows the item as it does today. The new current owner sees effective corrected service history; former owner loses access under existing ownership authorization.
22. Correction does NOT change `condition_grade_after` into an authentication grade or current condition projection. It remains a historical observation only.
23. No hard delete. No “undo” by deleting correction rows. Re-correction is another append.
24. No collector/public mutation route. No Caddy/DNS/edge change.
25. No SMTP/Stripe/Shopify/OAuth changes.

## Suggested schema
Prefer a table such as `sca_service_event_corrections`:
- id BIGINT
- service_event_id FK → `sca_service_events.id` RESTRICT
- eyewear_item_id FK → `sca_eyewear_items.id` RESTRICT
- corrected_service_type VARCHAR(24)
- corrected_condition_grade_after nullable VARCHAR(8)
- corrected_notes nullable TEXT
- corrected_occurred_at timestamp/date consistent with canonical event semantics
- reason bounded text/string
- actor_staff_ref nullable/soft ref
- created_at
Indexes:
- (service_event_id, id)
- (eyewear_item_id, service_event_id, id)
Immutability trigger: reject UPDATE/DELETE.
Insert integrity trigger: target event must exist and belong to eyewear_item_id.
Canonical type/grade constraints should mirror `ServiceService::TYPES/GRADES`.

Do not copy unrelated provenance/current-state data.

## Effective read rule
For each original service event:
- if no correction exists → render original values;
- if corrections exist → render the latest correction row's corrected snapshot;
- original event identity/occurrence remains canonical historical anchor.

Implement the effective read in one domain/read service and reuse it for staff + collector presentation. Avoid duplicate “latest correction” logic in controllers/views.

Queries must be bounded and avoid N+1. Service history per item is expected to be modest, but use a deterministic join/subquery/window/latest-id strategy rather than issuing one correction query per event.

## Staff UX
From item service history:
- existing “Record service” remains.
- authorized staff see “Correct” per service event.
- GET correction screen shows item opaque ref, immutable original, current effective values, prior correction count/history, and mandatory warning that original evidence will remain.
- POST submits corrected snapshot + reason + optimistic concurrency token.
- success returns to item detail with clear “correction appended” message.
- stale/no-op/not-found/cross-item failures are safe and generic; no raw SQL/internal details.

## Mandatory tests
At minimum prove:
1. Original `sca_service_events` row remains byte-identical after correction.
2. Correction appends exactly one immutable correction row.
3. UPDATE and DELETE on correction row fail at DB layer.
4. Direct cross-item correction insert fails at DB layer.
5. invalid corrected service type fails validation + DB constraint.
6. invalid corrected condition grade fails validation + DB constraint.
7. performer/actor is derived from authenticated staff; client spoof ignored.
8. correction requires dedicated ACL; ordinary service-record permission alone cannot correct.
9. GET correction interstitial is read-only and CSRF-safe POST performs mutation.
10. missing item/event and cross-item target fail closed.
11. reason required/bounded.
12. no-op correction rejected with zero new row.
13. first correction changes effective presentation while original stays unchanged.
14. second correction supersedes first for effective presentation; both correction rows remain immutable/auditable.
15. optimistic concurrency: two staff review same chain; first commits; second gets STALE and appends nothing.
16. real two-connection concurrency proof if practical: overlapping corrections cannot both silently win.
17. correction changes zero ownership/current-state/authentication/certification/QR/status/claim/grant/Shopify rows.
18. corrected condition remains observation only; authentication grade unchanged.
19. current owner My Collection sees corrected type/date/condition/notes.
20. owner view leaks no reason/staff/internal/correction ids.
21. former owner loses service history after transfer; new owner sees effective corrected history.
22. public Passport still exposes no service notes/correction/reason/staff data.
23. staff item detail uses effective values and authorized correction link.
24. staff audit view/history can distinguish original and corrections without editing them.
25. service-history reads use bounded queries/no N+1.
26. existing ordinary service-recording tests remain green.
27. existing ownership/transfer/collector/privacy/passport/auth/cert/status/Shopify suites remain green.
28. full `tests/Feature/Sca` green.
29. established 13-table provenance fingerprint procedure remains unchanged by deployment; note that service-event/correction tables are outside that historical fingerprint, so additionally record PRE/POST service-event counts and correction counts at deploy.

## Audit/deployment discipline
- NEW branch from exact production `9bc0907c486688c7acd0d22ad2ee9f5db37d93bb`.
- Expected migration 136→137.
- Do not alter existing service-event immutability.
- Do not touch Caddy/DNS/SMTP/Stripe/Shopify/OAuth.
- Do not merge/deploy.
- Push candidate + governance implementation evidence.
- STOP for ChatGPT pre-merge audit.

# SCA — Secure Ownership Claim: Release Candidate (RELEASE-PREPARED / DEPLOYMENT-BLOCKED)

**Authorized production-based RC for the integrated R0/R0b/R0c secure ownership-claiming system. DONE:
branch `release/sca-secure-claim` = `4bd88d2102da5fddaf6f91c4b1285ce611e649ee`, built off production
`4faf84d`, with a tree byte-identical to the tested development head `7da38b8` (final regression 19
suites / 245 tests / 1141 assertions / 0 failures).** NOT deployed. Status:
**RELEASE-PREPARED / DEPLOYMENT-BLOCKED** until transactional email is configured + verified and
separate deployment authorization is granted. `php -l` clean. No deploy/merge/migration/prod-DB/Shopify/
email change. 2026-10-29. **STOP for independent review.**

## [1][2] Baseline + dev head
- Production/live `4faf84d`, `main`, clean, loopback 200.
- Tested dev head `feat/sca-secure-claim-integration` = `7da38b8` (already a linear descendant of
  `4faf84d`; merge-base = `4faf84d`).

## [3][4][5] RC built off production, byte-identical to the tested tree
- Isolated worktree at **`4faf84d`**; `git merge --no-ff 7da38b8` → **RC `4bd88d2`** (parents
  `4faf84d` + `7da38b8`), integrating only the tested secure-claim changes.
- `git diff 7da38b8 4bd88d2` is **empty** → the RC tree is byte-identical to the tested dev tree.

## [6] Production features intact
Vs `4faf84d` the RC changes **38 files** — all additive to the claim subsystem + the order-email wiring
+ tests; no deployed feature file was removed or rewritten. Present/intact: Shopify catalog sync
(`ProductCatalogService`), staff order assignment (`OrderItemAssignmentService` — only gains the
trusted `order_email` 7th arg), QR labels (`EyewearItemController`), My Collection
(`CollectionController`), transfers (`TransferController`). Changed non-test files are the R0c additions
(Claim/Provenance/Registry/Collector claim-side + 4 migrations) plus `SaleLinkService`,
`SaleLinkEventProcessor`, `ShopifyReconciliationService`, `AuthoritativeOrder`,
`OrderItemAssignmentService`, `ShopifyServiceProvider`, two ACL/route files — none remove existing
behavior.

## [7] Public-QR retired + verified-buyer mandatory
`ClaimWorkflow::claim` → `ClaimRejection::PUBLIC_CLAIM_RETIRED` (public-token claiming cannot grant
ownership). `claimByPresaleGrant` gates on `buyerIsVerified` → `BUYER_VERIFICATION_REQUIRED` otherwise.
The only ownership paths are external-intake `claimByGrant` and the verified presale `claimByPresaleGrant`.

## [8] Exactly four additive migrations, no unexpected schema change
Vs `4faf84d`: `2026_10_29_000001_add_fulfillment_release_to_sca_eyewear_items` (nullable
`fulfillment_released_at/_by`), `2026_10_29_000002_create_sca_presale_claim_grants` (new table),
`2026_10_30_000001_add_order_email_to_sca_shopify_sale_links` (nullable `order_email`),
`2026_10_30_000002_create_sca_collector_email_verifications` (new table). All additive (new tables +
nullable columns); no alteration/drop of existing columns, no data migration, no other migration.

## [9] Migrate-before-code compatibility with batch 30/146
Production is batch **30 / 146**; none of these four are applied. They are additive and independent of
existing rows → compatible with the batch-30 schema; on deploy they become **batch 31**. Migrate-before-
code is required because always-on code reads these new tables/columns (e.g. `SaleLinkService` writes
`order_email`; `buyerIsVerified` reads `order_email` + `sca_collector_email_verifications`-driven
`email_verified_at`), so the schema must exist before the new code is activated.

## [10] Email unavailability prevents verification — no bypass
`CollectorEmailVerification` is `via(['mail'])`; with no provider (`MAIL=log`) no challenge is
delivered, so `email_verified_at` is never set. `buyerIsVerified` returns false unless BOTH the sale
link's trusted `order_email` is non-null AND an active collector has `email_verified_at` NOT NULL with a
matching normalized email → `BUYER_VERIFICATION_REQUIRED`, no ownership. **Email unavailability fails
closed; it is not a bypass.** (Covered by VerifiedBuyerClaimTest.)

## [11] Pre-deployment configuration & operational checks
1. **Transactional email delivery (BLOCKER):** provider account + server token (Postmark recommended —
   `pm` DKIM selector already published) in prod `app/.env` as `MAIL_MAILER=postmark` + `POSTMARK_TOKEN`
   + verified sender `MAIL_FROM_ADDRESS=no-reply@secondchanceauthenticators.com`; SPF added + DKIM/
   Return-Path confirmed at GoDaddy; a controlled challenge→confirm smoke test to an SCA-owned inbox.
2. **Trusted order-email propagation:** new webhook/reconcile/staff-assignment links now capture
   `order_email` from the authoritative order; the (separately-authorized, idempotent, dry-run-first)
   `sca:shopify:backfill-sale-link-email` fills legacy links (prod currently 0 eligible → near no-op).
3. **Fulfillment-release permission:** grant `sca.eyewear.fulfillment.release` to the appropriate staff
   role (and confirm the order-assign / manager-override ACLs are granted as intended).
4. **First claim:** a genuine paid order + a real certified, unowned pair (current records are all
   test/demo; the one sale link is refunded) — staff assign order→pair, buyer verifies email, buyer
   claims.

## [12] Open test-reliability observation (preserved)
`ExternalClaimTest` showed one transient failure in a combined loop (18/91) and then passed 18/93 on
three immediate retries and the definitive full pass. It is untouched by this work; recorded as an
**open test-reliability observation** (shared-DB claim/QR transient flake), not a product defect and
not fixed here.

## [13] Static validation
`php -l` clean on the key changed code files (`OrderItemAssignmentService`, `ClaimWorkflow`,
`PresaleClaimGrantService`, `SaleLinkService`); the full tree matches the regression-green `7da38b8`.

## [14][15] Release SHA, migration plan, rollback plan, deployment blockers
- **RC SHA:** `4bd88d2102da5fddaf6f91c4b1285ce611e649ee` on `release/sca-secure-claim` (parents
  `4faf84d` + `7da38b8`), pushed to origin. `origin/main` (`a397a7e`) and the live checkout (`4faf84d`,
  clean, 200) are untouched.
- **Changed files:** 38 (see repository diff `4faf84d..4bd88d2`) — R0c Claim/Provenance/Registry/
  Collector additions + 4 migrations + `SaleLinkService`/`SaleLinkEventProcessor`/
  `ShopifyReconciliationService`/`AuthoritativeOrder`/`OrderItemAssignmentService`/`ShopifyServiceProvider`
  + ACL/route files + 11 test files (7 new, 4 modified).
- **Deploy plan (separately authorized; migrate-before-code, no Docker recreate):** (1) verify prod
  backup; (2) migrate the 4 additive migrations → batch 31 from a separate mount, against `sca_krayin`,
  BEFORE code; (3) set `MAIL_MAILER=postmark` + token + verified sender in prod `app/.env`; (4) fast-
  forward the live tree to `4bd88d2`, preserving `.env`/`vendor`; (5) `config:clear` + `view:clear` +
  `apachectl graceful`; (6) grant the fulfillment-release ACL; (7) smoke: health 200, Operations/
  order-assign reachable, email challenge delivers to an SCA inbox, one verified-buyer claim end-to-end.
- **Rollback plan:** code — restore the previous snapshot `4faf84d` on the live tree + `view:clear` +
  `apachectl graceful`. DB — the 4 migrations are additive; code rollback needs no DB rollback (the new
  tables/columns simply go unused; `down()` exists to drop them under separate approval if ever
  required). No data loss (new tables start empty).
- **DEPLOYMENT BLOCKERS (must clear first):** (a) transactional email configured + verified (else the
  verified-buyer gate is unsatisfiable → claims impossible); (b) separate deployment authorization;
  (c) fulfillment-release ACL grant; (d) order-email backfill for any eligible legacy links; (e) a real
  paid order + certified pair for the first controlled claim.

**STOP — RC `4bd88d2` prepared off production (byte-identical to the regression-green `7da38b8`; public-
QR retired + verified-buyer mandatory + no email-bypass; exactly 4 additive migrations; features
intact). Marked RELEASE-PREPARED / DEPLOYMENT-BLOCKED: do NOT deploy until transactional email is
configured + verified and separate deployment authorization is granted. ExternalClaimTest intermittent
failure retained as an open test-reliability observation. Phase-1 webhook verification COMPLETE.**

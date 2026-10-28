# SCA — Ownership Passport R0b: Secure Private SCE Claim

**Authorized R0b development on top of the tested R0 branch.** Legitimate Second Chance Eyewear buyers can claim ownership of `sce_presale` items through a PRIVATE, staff-release-gated entitlement — the public QR token is never an ownership credential (R0 preserved). Dev branch only — NO production migration/merge/deploy, no live Shopify/customer claim, no Option C. Static checks PASS (`php -l` clean; Blade balanced). Focused tests written but **NOT run** (DB-changing; require separate disposable-DB authorization). 2026-10-29. **STOP for independent review.**

## SHA & files
- Branch `feat/sca-ownership-r0b-private-sce-claim` off R0 `bf77490` → **`1592a78944c7709b56dc0cc37a5f4f76f1ff2e83`** (pushed `origin`). Live `main`/prod (`cb8a8c3`) untouched.
- **12 files (4 modified, 8 new), 2 additive migrations.** The external-intake grant table/service/flow are **entirely untouched** (requirement 10).

## Design: reuse the grant architecture via a parallel table
The `sca_claims` CHECK forces a `shopify_sale` claim to carry a sale-link and NO certification, while `sca_external_claim_grants.source_certification_id` is NOT NULL — so shoehorning the sale-backed presale grant into the external (cert-backed) table would mean modifying that shared table + its CHECK and destabilizing the external flow. Instead R0b adds a **parallel additive table `sca_presale_claim_grants`** that mirrors the proven external-grant architecture (opaque CSPRNG bearer token; `issued`→single `consumed`, or `void`; one-active-grant-per-item via the item projection-row lock; RESTRICT FKs; `issued_by_staff_ref` with no DB FK, F12) and reuses the canonical consumption primitive `ClaimService::openShopifyClaim`. It differs by binding to the **sale link** (not a cert) and by being **time-limited** (`expires_at`).

## [Requirement 14] Migrations
1. **`2026_10_29_000001_add_fulfillment_release_to_sca_eyewear_items`** — adds nullable `fulfillment_released_at` (timestamp) and `fulfillment_released_by` (unsigned bigint, no FK). Additive; no data change. Down: drops the two columns.
2. **`2026_10_29_000002_create_sca_presale_claim_grants`** — new table: `id`, `eyewear_item_id` (FK RESTRICT → sca_eyewear_items), `source_sale_link_id` (FK RESTRICT → sca_shopify_sale_links), `grant_token` char(32) UNIQUE, `state` (CHECK `issued|consumed|void`), `issued_by_staff_ref` (nullable, no FK), `consumed_by_claim_id` (nullable, FK RESTRICT → sca_claims), `expires_at` (NOT NULL), timestamps; CHECK `consumed ↔ consumed_by_claim_id`; index on `eyewear_item_id`. Down: drops the table.

Both are additive and reversible; no existing table/column/row is altered.

## [Requirement 14] Permissions
- New ACL key **`sca.eyewear.fulfillment.release`** (Registry `Config/acl.php`, sort 19) — dedicated authority to release an sce_presale item and issue its private claim link; separate from intake/return/claim. Ungranted by default (fail-closed); on this prod the single Administrator (`all`) role holds it implicitly.

## [Requirement 14] Release sequence (operator)
1. Item is authenticated + certified (existing SCE intake) and sold via Shopify (sale link `eligible`, mapped by `sca_item_ref`).
2. Staff open the item detail → **Release for fulfillment** (GET confirm → POST `admin.sca.eyewear.fulfillment.release`, ACL-gated). This (a) stamps `fulfillment_released_at/_by` append-once, then (b) issues/reuses a private presale grant and flashes the buyer-facing URL `/collector/claim/presale/{token}`.
3. Staff deliver that private link to the buyer out-of-band.
4. Buyer opens the link while signed in as a collector → `PresaleGrantClaimController` → `ClaimWorkflow::claimByPresaleGrant` → `openShopifyClaim` + `complete`: exactly one ownership event, the sale link flips to `claimed`, the grant is `consumed` (single-use).

## [Requirement 14] Rollback behavior
- **Code rollback:** drop the R0b branch / revert — no production deployment occurred. The R0b migrations are not applied to prod.
- **Schema rollback (if ever deployed):** both migrations are reversible (`down()` drops the added columns / the table); because they are purely additive and nothing else references them until the feature is live, a code-only rollback needs no DB rollback (the unused table/columns are inert). A grant is never destructively mutated — `void` is a terminal evidence state; consumed grants reference their claim. Revoking a grant is a conditional `issued→void` update (mirrors the external revoke pattern; a revoke endpoint can be added if needed — not in this slice).

## Requirement-by-requirement
1. Audited `ClaimWorkflow`/`claimByGrant`, `ExternalClaimGrantService`, sale links, `SaleLinkService`, and the claim schema before changing anything (findings above).
2. Reused the grant architecture (parallel table + the same patterns + `openShopifyClaim`).
3. Private claim entitlement for sce_presale items linked to an eligible Shopify sale (`PresaleClaimGrantService` + `sca_presale_claim_grants`).
4. Requires an explicit, ACL-authorized staff **fulfillment release** before a grant can be issued (`FulfillmentReleaseService`; issuance rejects `fulfillment_released_at IS NULL`).
5. Validates exact physical identity (grant bound to `eyewear_item_id`), eligible sale-link status (at issuance AND re-checked at consumption), and current ownership state (unowned + no completed claim).
6. Never infers the pair from a Shopify variant — the grant references the exact `eyewear_item_id`; the sale maps to the item via `public_ref` (existing).
7. Fulfillment release is idempotent (append-once, lock-guarded) and auditable (actor + timestamp on the item row).
8. Grants are opaque (128-bit CSPRNG `Token::opaque`), time-limited (`expires_at`, 14d default), single-use (`issued→consumed` conditional update), and replay-protected (consumed/void/expired all fail closed; concurrent duplicate resolves to one owner).
9. Cancelled/refunded purchases cannot acquire ownership — issuance requires an `eligible` sale link, and consumption re-validates it is still `eligible` (else `NOT_ELIGIBLE` → 409); an unreleased item has no grant; an expired/void/used grant is unusable.
10. External_intake paid-authentication claim is preserved — its table, service, and flow are untouched.
11. Public passport viewing, registration/login, My Collection, and transfers are untouched.
12. Claim tokens are never exposed in public passport pages/catalog/logs — the grant token appears only in the staff flash (for out-of-band delivery) and the private claim URL; a test asserts it is absent from `/p/{token}`.
13. Tests added (below).
14. This document.

## Tests — `PresaleClaimGrantTest` (NOT run; needs separate disposable-DB authorization)
Release ACL enforcement + release→issue; duplicate release idempotent (attribution preserved); grant-requires-release; issuance idempotent; **valid claim** → one `shopify_sale` ownership + sale link `claimed` + grant `consumed`; double-claim single-use (same collector idempotent); **second collector** cannot claim a consumed grant / owned item; **expiry** → 404, no ownership; **cancelled/refunded** sale → 409, no ownership, grant not consumed; concurrent (single-use invariant → one owner); **public QR token still 410** under R0b; **grant token absent from public passport**.

## Safety / scope
Dev branch only; prod `main` (`cb8a8c3`) + live bind-mount untouched; no migration run anywhere; external flow untouched; no Option C. DB-backed tests deferred to a separate authorized disposable-DB run.

**RELEASE GATE:** R0 and R0b must undergo COMBINED security regression testing and receive separate merge/deployment authorization. **R0 must not be released alone** — R0b provides the private sce_presale claim path that R0's retirement removed.

**STOP — R0b implemented on the dev branch (`1592a78`); review before any DB test, merge, or deploy. Separate OPEN: the first genuine `products/*` webhook verification.**

# SCA — Customer QR Ownership Passport: Read-Only Audit & Roadmap

**Read-only audit at production baseline `cb8a8c3277f4319bc7c2ebdb8e0238426400bc7a` (Phase 2 Slices A/B/C deployed).** No code, DB, merge, migration, deploy, Shopify, or live-claim action taken. 2026-10-28. Purpose: inventory the existing customer Ownership-Passport capability, place the Option C claiming branch, surface security gaps, and recommend the smallest safe next step. **STOP after recording.**

Written for: the product owner (Jeremy) and the reviewing assistant auditing from GitHub.

## 1. What already exists (deployed on `cb8a8c3`)

The customer passport/ownership system is **substantially built and live**, spread across seven `Sca/*` packages:

| Capability | Where | State |
|---|---|---|
| **QR identity + lifecycle** | `Provenance/QrService` (+ `sca_qr_identifiers`, `sca_qr_lifecycle_events`) | Live. Immutable identity rows; append-only activate/revoke/reissue; exactly one active QR per item under the projection-row lock. Reissue stores a reason (migr 139). |
| **Public passport** | `Passport/PassportResolver` + `PassportController` at `/p/{token}` | Live. Token → active QR → item → current ISSUED certification → source authentication; any break → constant-shape 404 (no token/field leak). Read-only. |
| **Collector registration + sign-in** | `Collector/RegisterController`, `SessionController` (`/collector/register`, `/login`), `sca_collector_accounts`, password resets | Live. Self-service; throttled; enumeration-safe password reset even with mail in `log` mode. |
| **Claiming (two entitlement sources)** | `Claim/ClaimWorkflow` → `Provenance/ClaimService` (`sca_claims`), `ClaimController` (`/collector/claim/{token}`) and `GrantClaimController` (`/collector/claim/grant/{token}`) | Live. See §4. Ownership is created ONLY by completing a claim, under the item lock; terminal claims immutable (DB trigger). |
| **My Collection** | `Collector/CollectionService`, `CollectionController`, `CollectionGroupController`, public profiles/handles (`sca_collector_collections`, `_public_profiles`, `_public_items`) | Live (Collector UI 2.0 Slices 1–3). Browse-first collection, custom collection groups, per-item owner passport view, optional public profile at `/u/{handle}`. |
| **Ownership transfer** | `Collector/TransferWorkflow` → `Provenance/TransferService` (`sca_transfer_requests`, `_events`, `sca_ownership_events`) | Live (SCA-032). Owner mints a single-use opaque INVITE token shared out-of-band; recipient accepts while authenticated; optimistic version + expiry + stale-ownership guards; collector DB never enumerated. |
| **Shopify purchase → eyewear matching** | `Provenance/SaleLinkService` (`sca_shopify_sale_links`), `Shopify/SaleLinkEventProcessor`, `ShopifyReconciliationService` | Live-but-dormant. A paid Shopify line maps to a physical item ONLY via the item's SCA `public_ref` (line-item property `sca_item_ref`) — never brand/title/customer/fuzzy data. Sale = eligibility evidence, NOT ownership. `read_orders` scope. |
| **Phase 2 catalog variant link** | `Shopify/ShopifyProductLinkService` (`sca_eyewear_item_shopify_variant`), `EyewearShopifyIntakeService`, Slice C visibility | Live (A/B/C). Links a physical item to a catalog VARIANT for reference + staff visibility. See §5. |
| **Paid external authentication** | `Provenance/SubmissionService`, `CustodyAcceptanceService`, `AuthenticationService`, `CertificationService`, `AuthenticationPayment`/`StripeCheckoutService` | Submission + custody + authenticate + certify live; **Stripe dormant** (`MAIL`/payment integrations off). |

## 2. The Option C claiming branch (reviewed, NOT merged/deployed)

Branch `feat/sca-optc-secure-claim` @ **`0f41e2e`** (UNMERGED; gov `91a5a19`). Design intent:

- **Public-QR-token ownership claiming is PERMANENTLY RETIRED** (no runtime flag). In `ClaimWorkflow::claim()` the public `/p/{token}` path returns `NOT_ELIGIBLE` — possession of the public passport token, even with an eligible Shopify sale, can no longer create ownership. All ownership claiming is routed through a **private single-use grant** (`ExternalClaimGrantService` → `GrantClaimController` → `claimByGrant`), whose token is independent of the public passport token.
- **New precondition for pre-sale (`sce_presale`) grants:** a staff **fulfillment release** (`FulfillmentReleaseService`, new ACL `sca.eyewear.fulfillment.release`, additive migration `2026_10_23_000001` adding `fulfillment_released_at`/`_by` to `sca_eyewear_items`). Release is an explicit staff *attestation* that the frame is sold and ready to ship — offline, no automated Shopify/Stripe check — and is the gate before a private claim grant can be issued for that pre-sale item. Append-once, idempotent, lock-guarded.
- `external_intake` items are unaffected (no release concept; claimable once certified, via grant).

**Status of the branch itself:** selftest 65/0 and a full regression showed no Option-C regression. BUT the branch is **stale against current main**: its diff vs `cb8a8c3` is 161 files / +1834 / −5092 because it predates and *reverts* later main work — it rewrites `backup-verify-restore.sh`, deletes `scripts/lib-docsnapshot.sh` and `test-restore-verify-safety.sh` (both since changed on main), and rebases the whole test harness (`TestCase.php`, per-run DB guard). **Option C cannot be merged as-is** without clobbering the deployed backup/DR and test-runner work. The *claim-flow intent* is sound and small; the *branch* needs re-cutting onto `cb8a8c3`.

## 3. Implemented / tested / incomplete

- **Implemented + live:** QR, public passport, collector accounts, both claim paths, My Collection, transfer, sale-link matching (dormant), Phase 2 variant links + visibility.
- **Tested:** broad feature suite on `sca_domain_test` (claim, grant-claim, transfer, sale-link, QR artifact/reissue, submissions, Phase 2 A/B 37/37, Slice C 7/7). Public-passport trust/safety, retired/invalidated policy, destructive-action confirmations all have audited tests.
- **Incomplete / dormant / pending:**
  - **Option C** (secure-claim) — designed + branch-tested, **not merged/deployed**, and stale vs main.
  - **Shopify sale→claim end-to-end** — code live but **no genuine `products/*` or order flow exercised in prod** (sale_links 0; the separate pending first-webhook verification).
  - **Stripe paid-authentication checkout** — dormant (no creds).
  - **Email** — `MAIL_MAILER=log`; no transactional mail (claim/transfer invites rely on out-of-band token sharing).
  - **Phase 2 variant link is NOT wired into sale→item matching** (see §5).

## 4. Free SCE-purchase claim vs paid external authentication

Two distinct entitlement sources converge on the SAME canonical ownership mechanism (`ClaimService` → one ownership event under the item lock):

- **FREE ownership claim — eyewear bought from Second Chance Eyewear (`sce_presale`).** The item is authenticated/certified by SCE before sale. Entitlement = a **Shopify sale link** (`openShopifyClaim`, eligibility from `sca_shopify_sale_links`). The buyer claims at no charge — they are registering a pair SCE already authenticated. (Option C adds: a staff fulfillment-release gate + private grant instead of the public token.)
- **PAID authentication — externally-owned glasses (`external_intake`).** The owner submits their own glasses and **pays for authentication** (submission → custody → authenticate → certify; `sca_authentication_payments`/Stripe). Entitlement = an **issued certification**, surfaced to the collector as a staff-issued **external claim grant** (`openExternalClaim`). The fee is for the authentication service, not for claiming.

Both: ownership is never created by the sale or the certification alone — only by completing a claim; `sce_presale` vs `external_intake` (`sca_eyewear_items.intake_type`) selects the entitlement source.

## 5. How Phase 2 variant links integrate with sale / auth / QR / ownership

- **Today they are deliberately SEPARATE from ownership.** `sca_eyewear_item_shopify_variant` ties a physical item to a catalog *variant* for staff reference + visibility (Slice C). `ShopifyProductLinkService` never creates authentication/cert/QR/ownership/claim. The variant link does **not** feed `SaleLinkService`: a sale still maps to an item ONLY via `public_ref`/`sca_item_ref`, not via the variant.
- **The integration opportunity (and its hazard):** the variant link could help match a Shopify *purchase* to a physical pair when the line lacks an `sca_item_ref`. But the cardinality is **one variant → many physical pairs** (by design), so a variant link alone **cannot uniquely identify which pair was sold** — using it for auto-ownership would create ambiguous/duplicate-claim risk. Any future use must resolve that ambiguity (e.g. staff disambiguation, or a per-unit SKU), and must still go through the claim mechanism, never auto-assign ownership.
- **QR/passport are unaffected** by the variant link; the passport chain remains token → active QR → certification.

## 6. Security gaps, duplicate-claim protection, unauthorized-transfer risk

- **GAP-1 (the core one Option C targets): public passport token doubles as a claim credential.** On `cb8a8c3`, a signed-in collector who merely *sees* `/p/{token}` (it is printed on the frame/QR and shown publicly) can claim an item that has an eligible, unclaimed Shopify sale link (`ClaimWorkflow::claim` → `openShopifyClaim`). The passport token is discoverable by design, so it is a weak ownership credential. **Latent today** (0 sale links in prod) but it activates the moment Shopify sales flow. Option C closes it by retiring public-token claiming in favor of private grants. **This is the central finding.**
- **Duplicate-claim protection (present, good):** ownership is created only by `ClaimService::complete` under the item's projection-row lock; `openShopifyClaim`/`openExternalClaim` carry an idempotency key; terminal claims are immutable (DB trigger); "exactly one initial owner; retries/concurrency converge; already-owned fails closed." Grants are one-active-per-item (reused, not re-minted). Sale links are one-per-(shop,line) and never rebind to a different item.
- **Unauthorized-transfer protection (present, good):** only the current owner initiates; sender can't accept their own transfer; single-use opaque invite token shared out-of-band; optimistic version + expiry + stale-ownership guards; collector DB never enumerated; no recipient lookup by email/Shopify data.
- **Residual gaps (not code bugs):** no transactional email → claim/transfer invites depend on out-of-band token delivery (operationally fragile); Stripe dormant → paid-auth entitlement can't be collected online yet; the Phase 2 variant link, if ever wired to sales, introduces the §5 ambiguity risk.

## 7. Phased roadmap (reuse, don't rebuild)

- **Phase R0 — Secure the claim credential (Option C intent).** Re-cut the Option C claim-flow changes onto `cb8a8c3` as a SMALL branch (drop the stale backup/test-harness churn): retire public-token claiming in `ClaimWorkflow::claim`, keep claiming on private grants, add the `sce_presale` fulfillment-release gate (service + ACL + additive migration). Reuses `ExternalClaimGrantService`, `GrantClaimController`, `ClaimService` unchanged. Highest security value, smallest real code.
- **Phase R1 — Prove Shopify sale→claim end-to-end** (depends on the separate first-webhook verification): confirm an organic order with `sca_item_ref` creates a sale link, then a grant, then a claim. No new code if R0 landed; otherwise read-only verification.
- **Phase R2 — Fulfillment/grant issuance UX for staff:** a staff action to release a pre-sale item and surface its private grant link for buyer delivery (reuses `FulfillmentReleaseService` + `ExternalClaimGrantService`).
- **Phase R3 — Transactional email (gated on SMTP/DNS; see Postmark preflight):** deliver claim-grant and transfer-invite links by email instead of out-of-band only.
- **Phase R4 — Optional variant-assisted matching:** only if a per-unit identifier removes the one-variant-many-pairs ambiguity; always via the claim mechanism, never auto-ownership.
- **Phase R5 — Paid-authentication checkout (Stripe):** activate when credentials exist; reuses the dormant `StripeCheckoutService`/payment tables.

## 8. Smallest safe next development task (recommended)

**R0, scoped to the claim credential only:** on a fresh branch off `cb8a8c3`, **retire public-QR-token ownership claiming** in `ClaimWorkflow::claim()` (return `NOT_ELIGIBLE`, point buyers to the private grant), keeping `claimByGrant` as the sole ownership path. Defer the fulfillment-release migration/ACL to a follow-up so the first task is **code-only, no schema change** — it hardens the one live security gap with the least surface, reuses existing grant/claim services, and leaves `external_intake` and transfers untouched. (The fulfillment-release gate is the natural R0b once R0 is reviewed.) Dev-branch + disposable-DB test only; no deploy without separate authorization.

## 9. NO-GO / cautions
- Do **not** merge the Option C branch as-is (stale; reverts deployed backup/DR + test-harness work).
- Do **not** wire the Phase 2 variant link into automatic ownership/sale matching (one-variant-many-pairs ambiguity → duplicate/unauthorized claims).
- Keep the **first genuine `products/*` webhook verification** open and separate.

**STOP — read-only audit recorded. No code/DB/merge/migration/deploy/Shopify/live-claim action taken. Awaiting owner prioritization before any implementation (recommended first step: R0 above).**

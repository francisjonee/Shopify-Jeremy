# SCA Collector Profile — CP-4 — Public Collection Controls — CANDIDATE (remediated R1)

**Date:** 2026-10-09 · **Status: CANDIDATE remediated (pre-merge audit R1 — concurrency), NOT merged / NOT deployed / production untouched / Stripe DORMANT / mail=log. STOP for ChatGPT re-audit.**

- **Branch:** `feat/sca-collector-profile-cp4`
- **Base (exact deployed baseline):** `3e707582c21e40b97e909c8593987787fd4c33c4`
- **Candidate head:** `2836114ef5dd7b48e16f696c9195d52125725e11` (R1 remediation of `e041eea`; `c237a8d` + one extra `cc1` assertion that recipient B inherits no visible preference)
- **Impl repo:** `francisjonee/francisjonee-sca-platform-private` · **Governance:** `francisjonee/Shopify-Jeremy`
- **Migrations:** candidate **132 → 133** (one additive table `sca_collector_public_items`, unchanged); **prod stays 132** until deployment.

## Pre-merge audit remediation (R1 — concurrency / TOCTOU) — head `c237a8d`

Delta from `e041eea`: 2 files (`CollectorPublicItemService.php` + new `CollectorPublicItemConcurrencyTest.php`); migration unchanged.

**Finding (correct):** the sequential "both orderings" tests did not cover the real TOCTOU — `setVisible()` read canonical ownership/status WITHOUT a lock shared with the ownership/status writers, so a transfer/adverse transaction could perform its reset + commit between `setVisible`'s eligibility read and its `is_visible=true` write. The centralized read predicate prevented immediate disclosure, but a stale `true` preference could auto-resurrect on reacquisition/recovery.

**Lock design / fix.** `setVisible()` now, inside its transaction and AFTER the account lock, acquires `FOR UPDATE` on the SAME `sca_item_current_state` row that every ownership writer (Claim/Transfer/OwnershipCorrection) and status writer (StatusService/Commerce) locks + updates via `ProjectionService::rebuild`, and **re-reads canonical current owner + registry UNDER that lock**, gating on them before writing. So the write is impossible between a writer's reset and commit: either `setVisible` holds the row (the writer's rebuild then resets the preference) or the writer committed first (`setVisible`'s re-read sees the new owner / adverse status and fails closed). No stale `true` can survive.

**Deadlock safety (proven by audit of all writers).** Global lock order is **account → item-state**: writers that lock both do so in that order (ClaimService account L74 → item-state L118; TransferService account L61 → item-state L113; `pseudonymize` account L54 → item-state L67); OwnershipCorrection/Commerce/Status lock only item-state. No writer locks the account AFTER the item-state row, so `setVisible`'s account→item-state order introduces no inversion.

**Real overlapping two-connection proof.** New `CollectorPublicItemConcurrencyTest` (non-transactional; fixtures built WITHOUT append-only provenance — a bare `ItemService` item + a directly-seeded `current_state` projection row — so the graph is fully deletable and self-cleans): `cc1` visibility-publish racing a real transfer and `cc2` racing a real adverse transition. In each, a racer connection holds the `sca_item_current_state` row `FOR UPDATE` (the writers' synchronization boundary) and performs exactly what the writer's rebuild does under that lock (change current owner / set adverse + reset CP-4 rows); the main-connection `setVisible` **blocks on that lock (observed via a 1s `innodb_lock_wait_timeout` → 1205) and writes nothing**, then after the racer commits, `setVisible` re-reads under the released lock and **fails closed**. `cc1` additionally asserts the recipient B inherits no visible preference and that B→A reacquisition stays private (no auto-restore) until explicit opt-in; `cc2` proves recovery stays private likewise. The sequential `pi18`/`pi19` remain. Deadlock/lock-order proof = the documented audit of all writers above (the audit accepts a precise code audit in lieu of a test).

Focused: `CollectorPublicItemTest` **29** + `CollectorPublicItemConcurrencyTest` **2** = **31 passed**. Full governed SCA regression: **1137 passing / ~5863 assertions, 1 skipped (webp)** — one run surfaced the known unrelated `QrReissueTest::rg8` `rebuilt_at` timing flake (passed **11/11** on isolated re-run; prod untouched). Production re-verified untouched (deployed `3e70758`, prod migr **132**, `sca_collector_public_items` absent, provenance DATA byte-identical FP `35e06328…`, Stripe DORMANT, mail=log). **STOP for ChatGPT re-audit of head `2836114`.**

---

## Original candidate detail (head `e041eea`) — unchanged except R1 above

## Invariants honoured
**Ownership ≠ publicity. Profile publication ≠ item publication. An old owner's visibility never survives transfer as public authority. A new owner never inherits the old owner's choice.** Public item visibility requires explicit per-item opt-in and ALL of (rechecked at read time): CP-3 profile published + account active + non-blank display_name + this collector+item preference visible + canonical current owner == that collector + non-adverse registry.

## Changed files (13: 5 new, 8 modified)
NEW: migration `2026_10_14_000001_create_sca_collector_public_items.php`; `Models/CollectorPublicItem.php`; `Exceptions/VisibilityRejection.php`; `Services/CollectorPublicItemService.php`; `tests/Feature/Sca/CollectorPublicItemTest.php`.
MODIFIED: `Services/ProjectionService.php` (the shared reset hook); `Services/CollectorPrivacyService.php` (pseudonymization cleanup); `Http/Controllers/CollectionController.php` (private toggle + state); `Http/Controllers/PublicProfileController.php` (public collection + item image); `Providers/CollectorServiceProvider.php` (public image route); `Routes/collector-routes.php` (private toggle routes); `Resources/views/public/profile.blade.php` (public Collection section); `Resources/views/collection/show.blade.php` (private control).

## Data model (migration 132 → 133)
`sca_collector_public_items`: `id`; `collector_account_id` FK → accounts RESTRICT; `eyewear_item_id` FK → items RESTRICT; `is_visible` default FALSE; `visible_since` nullable; timestamps. UNIQUE(collector_account_id, eyewear_item_id); indexes (eyewear_item_id, is_visible) + (collector_account_id, is_visible); trigger `trg_sca_public_items_bu` makes the binding immutable. Presentation/privacy only — NO copied brand/model/cert/image/ownership/status fields; NOT provenance; a row is NEVER proof of ownership.

## Service (`CollectorPublicItemService`, sole writer/resolver)
One centralized predicate `eligibleQuery($publicRef)` (the five conditions above) backs BOTH `publicCollection()` and `publicItemImage()`, so the list and the image can never diverge. Private mutations are session-collector-only, account-first locked + status=active:
- `setVisible($cid,$itemRef)`: requires active account + CP-3 published + canonical current ownership + non-adverse; **no row created on failed eligibility**; idempotent.
- `setPrivate($cid,$itemRef)`: safe, idempotent, non-disclosing (never reveals whether the item exists/is owned/had a stale pref).
- `ownerVisibilityState()`: private display (visible? + can_toggle = publish-would-succeed).

## Ownership/status integration — SINGLE shared boundary
Every canonical ownership writer (`ClaimService`, `TransferService`, `OwnershipCorrectionService`) and status writer (`StatusService` collector/staff/admin, `CommerceService` refund) calls **`ProjectionService::rebuild($itemId)` inside its own transaction** (audited: all 5 confirmed). CP-4 hooks the reset THERE, conditional on the POST-rebuild state (not on why rebuild ran): flip CP-4 preferences for the item to private when the item is now adverse, when there is no current owner, or for any collector who is no longer the current owner. It never makes anything visible, so an ordinary owner-unchanged non-adverse rebuild (cert/QR issuance) leaves the current owner's preference intact; a transfer / admin correction / adverse transition resets the stale/old-owner/adverse preference atomically with the change. No account lock is taken (reset is by item under the writer's already-held item transaction → no account↔item lock inversion). Transfer/correction reset the OLD owner (recipient gets nothing); adverse resets all; recovery/normalization never auto-restores (the reset already made it private → explicit re-opt-in required). The public read predicate independently intersects current ownership + non-adverse, so even an integration gap cannot authorise an old owner (defense in depth).

## Routes
- Private (collector.auth, CSRF, throttle 30/min): `POST /collector/collection/{ref}/public` (make visible), `DELETE /collector/collection/{ref}/public` (make private) — session collector only, item by opaque ref.
- Public (unauth, within the already-admitted `/c/*` edge namespace): `/c/{publicRef}` gains an opt-in **Collection** section; `GET /c/{publicRef}/items/{itemRef}/image` streams a visible item's catalog image (nosniff, no-store; every fail-closed case → the same ordinary 404). No standalone public item-detail page; no Passport link.

## Public presentation (allowlist)
Per visible item: SCA public reference, brand, model, optional year, current-certification label ("Certified"/"Not currently certified") + certification number when currently certified, and the image via the public item-image route. **Omitted** (conservative CP-4): SKU, condition, ownership/acquisition dates, service/transfer/registry history, documents, internal ids, QR/Passport token, frame_serial, staff/Shopify data. Empty public collection → neutral "No items shared publicly." (never reveals hidden totals). Deterministic order (brand, model, ref); bounded single query capped at 48 (no per-card ownership/cert/status/image query — no N+1).

## CP-3 unpublish / pseudonymization
CP-3 unpublish closes the public collection + all item images immediately (reads require publication); preferences survive and a republish restores still-eligible items. Pseudonymization (still refuses while owning items) deletes CP-4 rows in the SAME privacy transaction as the publication/profile deletion.

## Tests
`CollectorPublicItemTest` — **29 passed / 118 assertions**: eligibility matrix (pi1–pi3); auth/self-only/no-retarget (pi4); not-owned (pi5); unpublished/non-active (pi6); idempotency (pi7); public allowlist (pi8); public image MIME/nosniff/no-store (pi9); indistinguishable image 404s (pi10); transfer removes A + B no inherit (pi11); reacquisition stays private (pi12); admin correction resets (pi13); adverse ×5 suppress+reset (pi14 DataProvider over lost/stolen/disputed/retired/invalidated); recovery no auto-republish (pi15); unpublish closes + republish restores (pi16); pseudonymization cleanup + owning-item rejection intact (pi17); **race proofs both orderings for transfer (pi18) and adverse (pi19)**; bounded/no-N+1 (pi20); Passport identity-free (pi21); My Collection private + complete (pi22); zero provenance (pi23); migration UNIQUE/FK/immutability/default-private (pi24); malformed/unknown refs fail closed (pi25).

**Race-test note:** a literal second-connection race is infeasible to tear down here — canonical ownership/status writes are append-only provenance with RESTRICT FKs (undeletable outside a rolled-back transaction) and all writers share one DB connection. Unlike CP-1's UNIQUE lock race, the CP-4 invariant is NOT lock-timing dependent: the `ProjectionService::rebuild` reset is atomic with the ownership/status change and the public read predicate ALWAYS intersects current ownership + non-adverse. `pi18`/`pi19` therefore prove BOTH orderings deterministically with the real writers (visible-then-change → closed + reset; change-then-publish → rejected), leaving no publicly resolvable window.

CP-3 public-profile/concurrency, CP-2 My Collection, transfer/status/privacy/Passport regressions retained. Full governed SCA regression: **1135 passed / 5850 assertions, 1 skipped (webp — env GD)**, exit 0. No flake.

## Production state (verified at restored baseline)
Live tree restored to `main` = `3e70758` (deployed SHA unchanged), `--no-dev` re-pruned. Prod `sca_krayin` migrations **132** (CP-4 migration applied only to the disposable test DB); `sca_collector_public_items` absent from prod; provenance DATA byte-identical (FP `35e063282e004eaabcc9240360ecc0e3`); collector accounts 3 / public_profiles 0; `STRIPE_ENABLED=false`; `MAIL_MAILER=log`. No merge, no deploy, no Caddy/DNS/Stripe/SMTP/Shopify change, no public item-detail/Passport-link/search/handles/social, no CP-5. The public image route is nested in the already-admitted `/c/*` edge namespace (no Caddy change needed; reachability proven at deploy).

**STOP for ChatGPT pre-merge audit of head `e041eea`.**

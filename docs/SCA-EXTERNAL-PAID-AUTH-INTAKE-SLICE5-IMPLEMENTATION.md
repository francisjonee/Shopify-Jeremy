# SCA External Paid Authentication Intake — Slice 5 (Result + Ownership Wiring) — implementation candidate (NOT merged/deployed)

**Date:** 2026-10-07 · **Status: IMPLEMENTED + TESTED + PUSHED on a candidate branch. NOT merged, NOT deployed, Stripe NOT activated. Live tree restored to `main`; production byte-identical (prod stays 129 — NO new migration).** For ChatGPT candidate audit. Promoted: Slice 5 only.

## Candidate identity
- **Branch:** `origin/feat/sca-external-paid-auth-slice5`
- **Base SHA (= deployed `main`, merge-base):** `5b30120488d2d7b9975260a142c540ce0f2b843b`
- **Head SHA:** `f9e9ed6dccf9c77c8303718c4c78178f3a3e499b` (1 commit)
- **Migrations:** **0** (no schema change — all result/ownership state derived from canonical provenance). **Migrations stay 129.**

## Discovered existing lifecycle (reused unchanged)
`ExternalClaimGrantService::issueForItem(itemId, staffRef)` (item-locked eligibility: current issued cert, no owner, non-adverse; idempotent reuse; no collector identity on the grant) · `currentIssuedToken(itemId)` · `ClaimWorkflow::claimByGrant(grantToken, collectorId)` → `ClaimService::openExternalClaim` → `verify` → `complete` (single owner-creation point, item+collector locked) → `sca_ownership_events` (`event_type='claim'`) → `ProjectionService` rebuild, atomically consuming the grant. Authentication vocabulary = `passed|failed|inconclusive`; certification via `CertificationService::issue`. **Slice 5 adds the submission-bound integration on top; it does not change these contracts.**

## Design decision
Derive Slice-5 result/ownership state from the **bound item's canonical provenance** (projection + authentications + certifications + current issued grant) — **no new submission status, no schema**. Ownership is created **only** by the canonical grant→claim path, invoked through a submission-scoped collector action that resolves the item + grant token **server-side**. Staff get a submission-detail action that delegates to the existing grant service. Certification never auto-creates ownership (the collector performs an explicit claim).

## Routes / actions added
- **Collector (collector.auth, owner-scoped, throttled):** `POST /collector/submissions/{SUB-ref}/claim` → `collector.submission.claim`.
- **Staff (admin):** `POST /sca/submission/{id}/grant` → `admin.sca.submission.grant`, gated by the **existing** `sca.eyewear.claim` (no new ACL key; route added to that key's mapping).
- No change to the existing public bearer-token grant routes or the Shopify claim path.

## Authorization derivation (nothing trusted from request)
The `{SUB-ref}` resolves only within the authenticated collector's own submissions (`SubmissionService::forCollectorByRef` → privacy-safe 404 for another collector). From the owned submission the server reads `eyewear_item_id`; from that item it resolves the **currently issued grant token** (`currentIssuedToken`); then calls `claimByGrant(token, session-collector-id)`. **No** collector id / item id / certification id / grant id / grant token is accepted from form or query. Staff attribution for the grant action is `auth()->guard('user')->id()` (attribution only).

## Result derivation (collector, canonical, safe)
`SubmissionController::boundItemResult()` returns a stable `state` from the bound item: `pre_custody` (no item yet) · `awaiting_examination` (no finalized auth) · `not_passed` (latest finalized auth is `failed`/`inconclusive` — NO claim) · `passed_not_certified` (passed, no cert — NO claim) · `certified_pending_grant` (certified, no issued grant) · `claimable` (certified + issued grant + unowned → explicit claim offered) · `registered_to_you` (owned by this collector → link to My Collection) · `unavailable` (owned elsewhere). Display uses authoritative item brand/model, certification number, and SCA public_ref — **never** the collector's declared fields, staff ids, staff notes, other-collector identity, or internal numeric ids.

## Grant issuance path (staff)
`SubmissionController::issueGrant()` resolves `submission.eyewear_item_id` and calls `ExternalClaimGrantService::issueForItem(itemId, staffRef)` — its existing item-lock eligibility + idempotent reuse (an already-issued grant is reused, not duplicated). Creates eligibility only; no ownership; no collector identity on `sca_external_claim_grants`.

## Claim / ownership path
`claim()` → `claimByGrant(server-resolved token, session collector)` → canonical open/verify/complete → **initial ownership event** + projection + grant consumed. On `claimed`/`already_yours` the collector is redirected into the **existing** My Collection item page (`collector.collection.show` by the item's public_ref) — no duplicate collector item page. On `ClaimRejection` (ALREADY_OWNED / NOT_ELIGIBLE / NOT_FOUND) → privacy-safe redirect with a safe message, no ownership.

## Concurrency / idempotency (unchanged — delegated to `claimByGrant`)
Double-click → one ownership (idempotency key `extclaim:item:collector` + `already_yours` short-circuit); retry after success → `already_yours`; adverse status re-checked at consumption → fail closed; already-owned → fail closed; consumed/void grant → unusable; 1062 duplicate-key → converge or ALREADY_OWNED; infra failure propagates (not mislabeled). The controller does NOT reimplement these.

## Provenance boundaries preserved
Payment/submission/edit create zero provenance; custody acceptance creates the one `external_intake` item (Slice 2); authentication/certification use canonical records; grant issuance = eligibility only; **claim completion alone creates initial ownership**; Shopify sale/claim + transfers + ownership-correction untouched. **No parallel tables** for auth/cert/claims/ownership. Proven by `r9` (one claim + one ownership + consumed grant + **no Shopify sale link** + no duplicate auth/cert).

## Exact changed files (7 modified, 1 new; 0 migrations)
Modified: `Collector/.../SubmissionController.php` (result derivation + `claim()`), `Collector/.../views/submissions/show.blade.php` (result/claim UI), `Collector/.../collector-routes.php` (claim route), `Registry/.../SubmissionController.php` (bound-item lifecycle + `issueGrant()`), `Registry/.../views/submissions/show.blade.php` (lifecycle card + grant action), `Registry/.../admin-routes.php` (grant route), `Registry/.../Config/acl.php` (grant route added to `sca.eyewear.claim`). New: `tests/Feature/Sca/ExternalIntakeResultClaimTest.php`. **Untouched:** ClaimWorkflow/ClaimService/ExternalClaimGrantService/CertificationService/AuthenticationService, Shopify, transfers, ownership-correction; no schema.

## Tests
- **`ExternalIntakeResultClaimTest` — 15 passed / 52 assertions:** `r1` result states (awaiting examination); `r2` cross-collector submission 404; `r4` non-passing → no claim; `r5` passed-not-certified → no claim; `r6` claimable shows the claim action; `r7` staff issue + idempotent reuse (single issued grant); `r7b` staff without `sca.eyewear.claim` → 403; `r8` claim with no bound item/grant → safe, zero claims; `r9` successful claim → canonical external_intake claim + completed + ownership + projection owner + consumed grant + **no Shopify sale link** + no duplicate auth/cert; `r12` double-claim idempotent (one owner, one claim); `r13` other collector cannot claim via the submitter's SUB-ref (grant untouched); `r14` consumed grant cannot create another owner; `r15` adverse item not claimable; `r16` already-owned-elsewhere privacy-safe (no claim action, forced POST grants nothing); `r17` after claim the item is reachable in the existing My Collection + submission shows "Registered to you".
- **Full governed gate:** `… -e DB_DATABASE=sca_domain_test … php artisan test tests/Feature/Sca` → **974 passed / 5145 assertions**, exit 0 (959 baseline + 15). The existing bearer-token grant claim flow (ExternalClaimTest) and the Shopify claim regression remain green within this total.

## Production-safety verification (post-restore)
- Live tree restored to `main` @ **`5b30120488d2d7b9975260a142c540ce0f2b843b`**; vendor re-pruned `--no-dev`; caches cleared.
- **Candidate code absent on `main`:** `collector.submission.claim` + `admin.sca.submission.grant` routes **ABSENT**; `ExternalIntakeResultClaimTest` not on disk.
- **Prod DB unchanged:** migrations **129** (no new migration); provenance counts byte-identical (items 3 / certs 4 / ownership 5 …).
- **Live HTTP invariants:** `POST /collector/submissions/{ref}/claim` **404** (route absent on main) · `/p/{bogus}` 404 · `/collector` 302 · `/collector/submissions` 302 · Stripe webhook **404** (dormant/unadmitted) · Shopify unsigned webhook **401** · `/storage` 404 · smsrocket 302.
- **Stripe DORMANT** (`enabled=false`), **`MAIL_MAILER=log`**, Caddy/DNS untouched. No production mutation, no deploy.

## Candidate gate
**NOT merged. NOT deployed. Stripe NOT activated. No production mutation. No Slice 6. No SMTP.** Awaiting ChatGPT candidate audit of head `f9e9ed6dccf9c77c8303718c4c78178f3a3e499b`.

See `docs/SCA-EXTERNAL-PAID-AUTHENTICATION-INTAKE-DISCOVERY.md`, `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE{1,2,3,4}-*`.

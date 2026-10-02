# SCA Former-owner claim-state correctness — readiness audit (READ-ONLY, DO NOT IMPLEMENT)

**Date:** 2026-10-02 · **Deployed baseline:** main `f85e8c5`, migrations **120**.
**Status: AUDIT ONLY — zero changes; no claim/transfer executed; no DB/schema/QR/cert/status/gallery touch.**
**For ChatGPT review. ACTIVE / NEXT_TASK remain unpromoted. SMTP remains deferred.**

## Headline finding

**The alleged defect is NOT present in the deployed baseline.** A former owner who transferred an item away
is **not** treated as `already_yours`. The `already_yours` basis is **canonical current ownership**, decided
at the authoritative service/domain boundary — not historical claim participation. This was fixed by
**SCA-APP-POLISH-029** (commit `362131d`, merged `233fa2c`, an ancestor of the deployed `f85e8c5`) and is
locked by an existing, passing regression test. **No code change is required.** (One optional test addition is
noted in §6; it is test-only and not a defect fix.)

## 1. Authoritative source of "current ownership" (traced)

`ProjectionService::currentOwner(itemId)` = the **latest** `sca_ownership_events` row by
`(effective_at DESC, id DESC)`; if that latest event is `transfer_out`, owner = `null`, else owner =
`collector_account_id`. This is the single source of truth, cached into
`sca_item_current_state.current_owner_collector_id` by `rebuild()`. **Historical ownership/claim events are
immutable and are never consulted to decide "current owner."**

`TransferService::accept()` (under `lockForUpdate` on the request + recipient + item projection row) appends
`transfer_out`(collector_id null) **then** `transfer_in`(collector_id = new owner) and rebuilds — so after a
transfer the **latest** event names the new owner, and `currentOwner()` returns the new owner. The former
owner is immediately non-current.

## 2. Where `already_yours` is decided — correct

`ClaimWorkflow::isCurrentOwner(itemId, collectorId)` (`ClaimWorkflow.php:282`) returns
`currentOwner(itemId)['collector_id'] === collectorId`. **Every** `already_yours` return in the workflow
(preview `:44`, claim idempotent short-circuit `:72`, dup-race `:104`, grant preview `:148`, grant claim
`:199`/`:241`) routes through this. The explicit SCA-APP-POLISH-029 docblock (`:276-281`) states a former
owner sees the privacy-safe `already_owned`, never `already_yours`. There is **no** path that infers ownership
from a completed `sca_claims` row for the collector.

- `ClaimController::show/claim/result` are pass-throughs of the service `$status`; `show.blade.php` only
  switches on `$status` (no independent owner derivation). **So the correctness is in the service, not hidden
  in Blade** — matching the task's correctness rule.
- `result.blade.php` "✓ Registered to you" is rendered only when `preview` returns `already_yours` (current
  owner); `result()` returns a privacy-safe not-found for anyone else, so a former owner never sees it.

## 3. State matrix (current, verified behavior)

| # | Case | Claim/grant state | Historical relationship | Current owner | Expected UI | Acceptance allowed? | HTTP / privacy | Mutation |
|---|---|---|---|---|---|---|---|---|
| 1 | Never-owner, valid claim | eligible sale-link / issued grant | none | none | **Eligible** (claim button) | **Yes** | 200 | on POST: 1 claim + initial `ownership_events`; projection → claimant |
| 2 | Current owner opens own claim | — | is current owner | self | **"You already own this item"** (`already_yours`) | n/a (idempotent) | 200, no owner PII | none |
| 3 | **Former owner after transfer** | — | past completed claim | **someone else** | **"Already registered"** (`already_owned`) — never `already_yours` | **No** (`ALREADY_OWNED`) | **409**, no owner identity | none |
| 4 | Intended recipient opens transfer | transfer request `pending` | recipient | prior owner | Transfer-accept flow (collector.auth) | **Yes** (accept) | 200 | `transfer_out`+`transfer_in`; projection → recipient |
| 5 | Unrelated collector opens/guesses claim URL | item owned | none | someone else | `already_owned` | **No** | **409**, no owner identity | none |
| 5b | Unrelated collector, item unowned+eligible | eligible | none | none | **Eligible** | Yes (becomes first owner) | 200 | initial ownership |
| 6 | Claim already consumed (grant) | grant `consumed` | varies | the consumer (or none) | current owner → `already_yours`; else `already_owned`; unowned+used → `not_found` | No (for non-owner) | 409 / 404, no PII | none |
| 7 | Grant expired/revoked/cancelled | grant `void` | varies | varies | owner → `already_yours`; else opaque `not_found` | No | 404, no PII | none |
| 8 | Ownership changes between claim GET and acceptance POST | eligible at GET | none | becomes someone else by POST | — | **No** — fails closed | **409** (`ALREADY_OWNED`) | none (rolled back) |

All "no owner identity" cells are enforced: the workflow returns only a status + safe item fields
(`public_ref`, `brand`, `model`, cert number); never the owner's identity, collector DB id, ownership-event
id, token, or internal claim metadata.

## 4. Collector collection/detail & passport (former-owner access)

- `CollectionService::ownedItems()` / `ownedItemByRef()` gate strictly on
  `current_owner_collector_id = collectorId`. **A former owner, after transfer, cannot list or open the item**
  — every owner-scoped read (detail, images, documents, service/cert/ownership history, passport redirect,
  status actions) returns the identical privacy-safe 404. Former ownership grants **no** continuing access.
  (Existing tests confirm "previous owner after transfer → 404": `CollectorGalleryTest:234`,
  `CollectorCatalogTest:138`, `CertificatePdfTest:231`, `ItemOwnershipHistoryTest:223`,
  `DestructiveActionConfirmationTest:173`.)
- The "You" badge on the collector **ownership-history timeline** (`show.blade.php:247`, `CollectionService`
  `mine = collector_account_id === collectorId`) is accurate **per-entry** historical labeling, visible only
  to the **current** owner viewing their item. It does not grant access and is not the `already_yours` signal.
- **Public passport** exposes no owner identity and no claim/"registered to you" wording; its only
  ownership-adjacent output is the status banner (lost/stolen/disputed/retired/invalidated), already audited.
  Transfer does not change passport content (certification/QR identity unchanged).

## 5. Concurrency — already fail-closed (no guard needed)

`ClaimWorkflow::claim()` / `claimByGrant()` perform the whole open→verify→complete in one transaction, and
`ClaimService::complete()` (`ClaimService.php`) takes `lockForUpdate` on the claimant + the claim row and
**re-checks `currentOwner(...) !== null` under the lock, throwing if the item already has an owner**. So a
stale claim page whose item gained an owner between GET and POST fails closed (mapped to a privacy-safe 409),
with the transaction rolled back (no partial claim/ownership). `TransferService::accept()` locks the request,
recipient and item projection row and rebuilds atomically; two racers converge to exactly one owner. **There
is no stale-acceptance hole** — per the task, no redundant version guard is recommended.

## 6. Smallest recommended scope

- **Code: NONE.** The behavior is already correct at the authoritative boundary (`ProjectionService::
  currentOwner` → `ClaimWorkflow::isCurrentOwner`), consistent across the claim, grant, transfer, collection,
  and passport surfaces, and never derived from historical claims or hidden in Blade.
- **Existing regression (deployed, passing):** `ClaimWorkflowTest::k_polish_former_owner_after_transfer_is_
  not_already_yours` proves case 3 end to end — A claims → transfer A→B → A sees `already_owned` (not
  `already_yours`) and cannot re-claim (`ALREADY_OWNED`), B sees `already_yours`, and transfer B→A restores
  `already_yours` for A. `k11_already_owned_page_leaks_no_owner_pii` covers the privacy of case 5.
- **Optional test-only hardening (not a defect fix), if the reviewer wants the matrix fully pinned:** add a
  focused regression for **case 8** that mutates ownership *between* a `preview()` (GET) and a `claim()` (POST)
  and asserts the POST fails closed with `ALREADY_OWNED` and zero mutation — exercising the under-lock
  re-check in `ClaimService::complete()` explicitly (today it is covered implicitly via the former-owner
  re-claim rejection). Scope: one test method in `ClaimWorkflowTest`, no production code, no schema.

## 7. Observation (not a defect; no action)

`ExternalClaimGrantService` (the STAFF issue-a-new-external-claim-link path) blocks issuance when
`currentOwner != null` **OR** a completed `sca_claims` row exists for the item. The `OR completed-claim` arm
is a *conservative* guard specific to the external-intake first-registration path (don't mint a fresh
claim-link around an item that has ever completed a claim). It only makes issuance **more** restrictive; it
never grants a former owner access and never produces `already_yours`. It is out of scope for this defect and
needs no change.

**Conclusion: the former-owner `already_yours` defect is already resolved and regression-tested as of
`f85e8c5`. Recommend NO implementation; at most the optional case-8 regression test above. AUDIT ONLY —
awaiting ChatGPT review; ACTIVE/NEXT_TASK remain unpromoted.**

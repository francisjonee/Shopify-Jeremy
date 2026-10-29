# SCA — Ownership Passport Transfer Experience Audit (READ-ONLY)

**The collector-to-collector ownership transfer experience is COMPLETE and fully DEPLOYED (prod
`4faf84d`); it works end-to-end with no email provider and needs no further development to launch.**
Read-only review; no code/DB/Shopify/email/deploy change. 2026-10-29. **STOP.**

## [1] My Collection & Passport (context, deployed)
- **My Collection** (`/collector/collection`, `collector.auth`): owned-pair cards + item detail
  (`/collection/{ref}`) with image, brand/model, cert/registry badges, market reference, adverse banner,
  and status flashes.
- **Public Passport** (`/p/{token}`): mobile, safe DTO only (no owner PII / token / storage path).
- The item detail hosts the transfer entry point + the deployed **transfer-status-clarity** UX (pending
  banner + confirmation flashes).

## [2] Initiating a transfer (owner only) — DEPLOYED
`TransferController::initiate` → `TransferWorkflow::initiate(ownerId, publicRef)`:
- **Owner-authorized** by `public_ref` (`ownedItemId` fails closed `NOT_FOUND` for a non-owner — the
  collector database is never enumerated, and no recipient is looked up by email/Shopify/customer data).
- **Blocked if adverse** (lost/stolen/disputed/retired/invalidated) → `NOT_AVAILABLE` (no silent
  transfer of a flagged item).
- Generates a **single-use opaque invite token** (`Token::opaque()`, 128-bit) with a **14-day expiry**
  (`TransferService::initiate`, `expiryDays=14`), `state=pending`, `version=0`.
- **No duplicates:** an existing non-expired pending transfer for the item is reused rather than creating
  a second one.
- The owner is shown the shareable single-use link (to convey out-of-band) + a confirmation flash.

## [3] Recipient receives & accepts — DEPLOYED
- The owner shares the single-use link (`/collector/transfer/{token}`) **out-of-band** (SCA sends
  nothing — see [8]).
- The accept routes are inside the **`collector.auth`** group, so the recipient **must be a signed-in
  collector**. A new/unauthenticated recipient is redirected to login (intended-URL preserved) and can
  **register or sign in**, then returns to accept (new-recipient onboarding, SCA-032 — works without
  email).
- `acceptShow` → `previewAccept` renders the item for confirmation (no sender identity/PII; a sender
  opening their own link gets a 409 "you started this transfer"). `accept` POST performs the
  ownership-changing step and redirects to My Collection with a "now in your collection" confirmation.

## [4] Unauthorized / expired / duplicate / replayed protections — STRONG, DEPLOYED
`TransferWorkflow::accept` + `TransferService::accept` (serialized under the item lock, optimistic
version + expiry guard):
- **Unauthorized:** non-owner cannot initiate (`NOT_FOUND`); the recipient must be an authenticated
  collector (`collector.auth`); staff sessions do not satisfy the collector guard.
- **Self-transfer:** the sender cannot accept their own invite (`SELF` → 409).
- **Expired:** `expires_at` checked in both `pendingByToken` (query) and `TransferService::accept` (14-day
  TTL) → expired tokens are not acceptable.
- **Single-use / replayed:** only a `state=pending` request is acceptable; on accept it flips to
  `accepted` (and on cancel to `cancelled`), so re-presenting a consumed/cancelled token →
  `NOT_FOUND`/`NOT_AVAILABLE`. `TransferService::accept` re-checks `state==='pending'` under
  `lockForUpdate` → a concurrent double-accept yields exactly one transfer.
- **Stale owner:** if ownership changed since initiation, accept fails closed (`NOT_AVAILABLE`).
- **Adverse mid-flight:** a lost/stolen/disputed item is rejected even if flagged after initiation.
- **Infra vs domain failure:** an infrastructure error propagates (transaction rolled back) and is never
  disguised as a business rejection. (All covered by `TransferWorkflowTest` 15/15.)

## [5] Cancellation & pending status — DEPLOYED
- `TransferController::cancel` → `TransferWorkflow::cancel`: owner-only; under `lockForUpdate`; flips a
  pending request to `cancelled` + appends a `cancelled` transfer event; **idempotent** (no-op if none
  pending); invalidates the shared link.
- **Pending status** is surfaced on the item detail via the deployed transfer-status-clarity banner
  ("⏳ Transfer pending — awaiting acceptance … you remain the owner until they accept") with a
  Manage/cancel action; generate/cancel/accept each show a confirmation flash. The invite token is never
  rendered on the item-detail page.

## [6] Ownership history preserved on success — YES
`TransferService::accept` appends **append-only** `transfer_out` + `transfer_in` ownership events and
rebuilds the projection; the original `claim` event and all prior history are untouched
(`TransferWorkflowTest::t5`). The recipient becomes the single current owner (one
`sca_item_current_state` row), the sender no longer sees the item in My Collection, and the
owner-facing timeline folds the transfer pair neutrally (no PII).

## [7] QR Passport after ownership change — UNCHANGED
The transfer path touches **no** QR identity or lifecycle (verified: `TransferService`/`TransferWorkflow`
reference no `qr_*`). The QR is **item-bound and immutable**, not owner-bound — so after a transfer the
same permanent QR still resolves to `/p/{token}` for the same item, now reflecting the new owner's
context (publicly PII-free). **No re-mint, re-activation, or re-print is needed**; the physical QR the
collector holds keeps working.

## [8] Recipient notifications require an email provider? — NO
The transfer path sends **no email and no notification** (verified: no `Mail`/`Notification`/`notify`
anywhere in `TransferController`/`TransferWorkflow`/`TransferService`). The owner conveys the single-use
link out-of-band (message/in person). **Transfer therefore works fully today without any email provider**
— unlike the verified-buyer *claim* flow, which is email-blocked. This is also a privacy property (SCA
never enumerates or emails collectors to broker a transfer).

## [9] Gaps (customer-experience / operational) — minor, none blocking
1. **No automatic recipient notification:** the owner must manually share the invite link; SCA does not
   email/notify the recipient. By design (privacy, email-independence), but a future *opt-in* "email this
   invite to a recipient" would need the (currently blocked) email provider + a recipient-email input —
   defer; not required.
2. **No owner "transfer accepted" confirmation:** after the recipient accepts, the owner sees it only by
   the item leaving their My Collection on next visit — there is no proactive confirmation to the owner
   (again email-dependent). Minor UX nicety, optional, email-gated.
3. Everything else (initiate / share / accept / cancel / pending banner / confirmations / history / QR
   continuity / fail-closed guards / new-recipient onboarding) is present and deployed.

## [10] Deployed vs development-only
**All transfer functionality is DEPLOYED at prod `4faf84d`** — initiate, out-of-band single-use invite,
recipient accept (with onboarding), cancel, pending-status banner + confirmations, append-only history,
and QR continuity. **Nothing transfer-related is development-only.** (The undeployed `4bd88d2` release is
about secure *claiming* (R0/R0b/R0c), not transfer; transfers are independent of the claim gate — an
owner can transfer regardless of how they acquired ownership.)

## [11] Smallest necessary next task
**None required** — the transfer experience is complete, hardened, and launch-ready without email. The
only candidate enhancements (an opt-in "email the invite to a recipient" and an owner "transfer accepted"
confirmation) are **optional, email-gated**, and should be considered only after transactional email is
live (the same blocker as claims) and only if the owner wants them. Recommend **no transfer work before
wider use**; proceed on the existing out-of-band flow.

**STOP — collector-to-collector ownership transfer is complete and fully deployed at `4faf84d`:
owner-only initiate, single-use 14-day opaque invite shared out-of-band, authenticated-recipient accept
with onboarding, strong unauthorized/expired/duplicate/replay/stale/adverse guards, cancellation +
pending-status UX, append-only history, and an unchanged item-bound QR Passport — all working WITHOUT an
email provider. No gaps block wider customer use; the only (optional) enhancements are email-gated. No
code/DB/Shopify/email/deploy change made. Secure-claim RC `4bd88d2` remains DEPLOYMENT-BLOCKED and is
unrelated to transfer. Phase-1 webhook verification COMPLETE.**

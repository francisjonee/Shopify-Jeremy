# SCA New-recipient transfer onboarding — readiness / design audit (READ-ONLY, DO NOT IMPLEMENT)

**Date:** 2026-10-02 · **Deployed baseline:** main `f85e8c5`, migrations **120**.
**Status: AUDIT / DESIGN ONLY — zero changes; no transfer/account/DB mutation; no schema/QR/cert/status/
gallery/SMTP/infra touch. For ChatGPT review. ACTIVE / NEXT_TASK remain unpromoted.**

Addresses app-audit P1 [B6] ("transfer-accept has no onboarding for a brand-new recipient; unverified whether
the invite URL survives registration").

## Headline finding

**The new-recipient onboarding flow is ALREADY implemented end-to-end and regression-tested** — by
SCA-COLLECTOR-AUTH-CONTEXT-032. A logged-out recipient with no account can open a shared transfer invite,
**register** (or sign in), be returned to the same invite, review it, and accept ownership — the invite
survives registration via Laravel's session `url.intended` (never a query param), and the token is never
exposed in the auth screens. **[B6] is effectively already resolved; no implementation is required for the
core ask.** Optional, non-blocking items are in §6.

## 1. Current flow (traced)

Transfer routes live under `collector.auth` (`collector-routes.php:79-83`):
`GET/POST collection/{ref}/transfer` (+`/cancel`, owner-only) and `GET transfer/{token}` (acceptShow) /
`POST transfer/{token}` (accept).

1. **Owner initiates** (`TransferController::initiate` → `TransferWorkflow::initiate` → `TransferService::
   initiate`): authorizes current ownership by `public_ref`; rejects an adverse-status item; reuses an
   existing pending invite or creates one; shows the shareable link on `transfer/initiate.blade`.
2. **Invite token** (`sca_transfer_requests`): `invite_token char(32) UNIQUE` (opaque 128-bit, **bearer**),
   `state pending→accepted|cancelled|expired|rejected` (CHECK), `expires_at` (14 days),
   `version` (optimistic lock), `to_collector_id` **null until accept** — **no recipient-email binding**.
3. **Recipient opens the link while logged OUT** → `collector.auth` (`CollectorAuthenticate`) →
   `redirect()->guest(route('collector.login.show'))`, which stores the exact transfer URL in session
   `url.intended` (server-side; the token is held there, not re-emitted).
4. **Login / register screens** (`SessionController::show` / `RegisterController::show`) build
   `AuthContextResolver::fromIntended(session('url.intended'))`, which re-resolves the token LIVE via
   `TransferWorkflow::previewAccept(token, 0)` and returns **only** `{flow:'transfer', reference, brand,
   model}` — never the owner identity, token, or ids. The shared `layout.blade:93-99` renders a banner
   "Accept your SCA item transfer … accept ownership of <item> (SCA reference …)". `login.blade` surfaces a
   prominent **"Create an account"**; `register.blade` links back to Sign in; the context persists across the
   switch because it lives in the session, not the URL.
5. **Recipient registers** (`RegisterController::store`): creates an active collector, logs them in, rotates
   the session, and `return redirect()->intended(route('collector.account'))` → **returns to the transfer
   URL** `GET transfer/{token}`. (Login does the same, `SessionController::store`.)
6. **Review + accept** (`TransferController::acceptShow` → `transfer/accept.blade`): shows item brand/model/
   `sca_reference`/certification number + an "Accept ownership" button; `self`→409. `POST accept` →
   `TransferWorkflow::accept` → `TransferService::accept`.
7. **Ownership event + projection** (`TransferService::accept`, under `lockForUpdate` on request+recipient+
   item projection): appends `transfer_out`(collector null) + `transfer_in`(new owner), rebuilds →
   `currentOwner()` returns the recipient; redirect to My Collection.
8. **Previous-owner access after accept:** the sender is no longer current owner → all owner-scoped reads
   return the identical privacy-safe 404 (verified across suites in the former-owner audit). **New owner**:
   full collection/detail access (ownedItems/ownedItemByRef gate on `current_owner_collector_id`).

**No-account case today:** fully handled — step 3→5 route a brand-new recipient through registration and back
to the invite. (The earlier "unverified" concern in [B6] is resolved: `RegisterController::store` uses
`redirect()->intended()`, identical to the proven claim path.)

## 2. Does the existing registration/auth architecture support return-to safely? — YES, already

- The mechanism is **session `url.intended`**, set by `redirect()->guest()` from the *actual requested
  same-app path*, consumed by `redirect()->intended()` on successful login **and** register. It is **not** a
  query-param `return_to`, so there is **no open-redirect surface** (an attacker cannot inject an arbitrary
  destination; `intended()` only honors the stored same-origin path, and `AuthContextResolver` further
  validates it is a `/collector/...` path). **No server-side transfer-context store is needed** — the invite
  token already encodes the transfer, and the session already carries the return destination.

## 3. State matrix (current = proposed; already correct)

| Recipient state | Transfer state | Current behavior | Proposed | Authorization | Expected mutation | Failure / privacy |
|---|---|---|---|---|---|---|
| Logged out, **no account** | pending, valid | → login (intended stored); context banner + "Create an account"; register → back to invite → review → accept | **same** | token possession + new authenticated non-sender | on accept: `transfer_out`+`transfer_in`, projection→recipient | no token in HTML; no owner PII; 404 if token dead |
| Logged out, has account | pending, valid | → login; → intended → review → accept | same | same | same | same |
| Logged in as **intended** recipient | pending, valid | acceptShow review → accept | same | authenticated non-sender | ownership → recipient | — |
| Logged in as a **different** collector | pending, valid | acceptShow review → accept (bearer: any non-sender) | same (bearer by design) | token possession + non-sender | ownership → that collector | **by design** any holder may accept; see §4 |
| Logged in as the **sender** | pending | `self` → 409, no accept | same | — | none | "You started this transfer" |
| Any | **accepted/consumed** | `unavailable`/NOT_AVAILABLE | same | — | none | privacy-safe 404/409 |
| Any | **cancelled / expired** | not pending / past `expires_at` → unavailable | same | — | none | privacy-safe 404 |
| Any | **stale** (owner changed since initiate) | `ownershipUnchanged` false → NOT_AVAILABLE | same | — | none (fail closed) | 409 |
| Any | item **adverse** (lost/stolen/disputed/retired/invalidated) | NOT_AVAILABLE | same | — | none | 409 |
| Unrelated collector **guesses** a token | — | 32-hex format gate + exact pending lookup; unknown → unavailable | same | — | none | opaque 404, no existence leak |

## 4. Security answers (explicit)

- **Possession of the link authorizes acceptance:** YES — the invite is a **bearer token** (intended, so it
  can be shared out-of-band incl. manual copy — satisfying the no-email constraint). Acceptance additionally
  requires an authenticated collector who is **not the sender** (`self`→409).
- **Bound to a specific email/recipient:** NO — `to_collector_id` is null until accept; no email is stored,
  so the invite is not addressed to anyone.
- **Can any authenticated collector accept a leaked valid token:** YES (except the sender). This is the
  current model.
- **Should registration bind the new account to an intended recipient:** not possible today (nothing to bind
  to). **Design option, NOT recommended now:** an email-bound invite (store a recipient email hash on the
  request, require the accepting collector's verified email to match) would narrow a leaked link — but it
  needs a schema column **and** an email channel, so it is **DEFERRED with SMTP**. For manual-share pilot use,
  **keep the bearer model** (documented, matching how the claim grant tokens already work).
- **Single-use:** YES — unique token + `state` transitions to `accepted`; accept is idempotent and fails
  closed on a non-pending request.
- **Expiration / revocation:** 14-day `expires_at`; owner **cancel** → `cancelled`; a stale request (owner
  changed) and an adverse item → NOT_AVAILABLE.
- **Token storage / hash:** stored **plaintext** in `invite_token char(32) unique` (NOT hashed), unlike the
  hashed password-reset tokens. Mitigated by single-use + short expiry + bearer-by-design + never logged.
  Optional future hardening (hash-at-rest) is a schema/behavior change — **out of scope, deferred**.
- **Token in logs / URLs / HTML / redirects:** it is in the shareable URL and the accept-form action (both
  necessary); held server-side as `url.intended`; **not** rendered into the auth-context HTML (test a6
  asserts `assertDontSee($token)`); no controller logs it. `redirect()->intended()` targets the recipient's
  own invite URL.
- **Open redirect via return-after-login:** **NO** — session-based intended (not a query param), same-origin
  only, path-validated. This is the safer design.

## 5. Concurrency — already fail-closed (no guard missing)

`TransferService::accept()` runs under `lockForUpdate` on the request + recipient + item projection row with
an **optimistic `version` + `expires_at` guard**, and `TransferWorkflow::accept` re-checks `ownershipUnchanged`
+ pending + not-adverse, mapping a domain race to NOT_AVAILABLE (rollback on infra failure). Therefore:
- **double submit** → second sees non-pending → NOT_AVAILABLE;
- **two collectors racing one token** → row locked; exactly one wins, the other NOT_AVAILABLE;
- **owner cancels / changes state while the recipient registers** → re-check at accept → NOT_AVAILABLE;
- **stale transfer page then accept** → same re-check → fail closed.
No redundant version guard is recommended (the existing one already covers it).

## 6. Smallest scope & recommendation

- **Core onboarding: NO implementation and NO schema change required** — it already works and is tested
  (`CollectorAuthContextTest` a6 logged-out transfer context, a7 login↔register context retention, a8
  login→transfer return, a11 no owner PII, a12 zero mutation; a3 proves the register→`intended()` return for
  the equivalent claim path; `TransferWorkflowTest` covers accept/stale/self/concurrency).
- **Optional (test-only, no code):** add one regression that a **brand-new recipient REGISTERS** from a
  transfer invite and is returned to `transfer/{token}` and then accepts → becomes owner (a8 covers login→
  transfer; a3 covers register→claim; this would pin register→transfer→accept explicitly). One method in
  `CollectorAuthContextTest` or `TransferWorkflowTest`; no schema, no production code.
- **Deferred design options (document only):** email-bound invites + a recipient notification email — both
  **DEFERRED with SMTP**; the onboarding deliberately works with a manually-shared link and must not depend on
  outbound email. **Email plug-in point:** a notification could be emitted after `TransferWorkflow::initiate`
  (and acceptance) once SMTP + (optionally) email-binding land — no change to the token/authorization model.
- **Optional hardening (deferred):** hash the invite token at rest (schema change).

**Conclusion: the new-recipient transfer onboarding is already supported end-to-end, privacy-safe, concurrency
-safe, and regression-tested as of `f85e8c5`. Recommend NO implementation; at most the optional
register→transfer→accept regression test. Keep the bearer invite model for manual sharing; defer
email-binding/notification with SMTP. AUDIT ONLY — awaiting ChatGPT review; ACTIVE/NEXT_TASK remain
unpromoted.**

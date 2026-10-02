# SCA QR Reissue — staff UI readiness / design audit (READ-ONLY, DO NOT IMPLEMENT)

**Date:** 2026-10-02 · **Production baseline:** deployed main `dff2781`, migrations **120**.
**Status: AUDIT / DESIGN ONLY — zero changes, no reissue executed, no route/code/data/is_production touched.**
**For ChatGPT review. ACTIVE / NEXT_TASK remain unpromoted. SMTP remains deferred.**

Addresses the P1 from the production-app audit (gov `1b09455`): `QrService::reissue()` exists and is
concurrency-safe but has **no staff route/controller/UI**. This documents the ACTUAL implementation (traced,
not inferred) and designs the smallest governed staff UI to expose it.

**Boundaries honored:** no route created, no code/DB/env/infra change, no QR regenerated, no is_production
change, no certification/authentication/ownership/gallery mutation. All findings from reading code + read-only
DB introspection.

---

## 1. Actual QR lifecycle (traced from code + live DB)

**Tables (migrations `…120006`/`…120007`, triggers `…120017`):**
- `sca_qr_identifiers`: `id`, `eyewear_item_id`, `public_token char(32) UNIQUE`, `is_production bool
  default 0`, `created_at`. **Identity rows are immutable** — live triggers `trg_sca_qr_identifiers_no_update`
  / `_no_delete` (BEFORE UPDATE/DELETE → block). No lifecycle columns on the identity row.
- `sca_qr_lifecycle_events`: append-only (`id`, `qr_identifier_id`, `eyewear_item_id`, `event_type varchar(16)`,
  `replaced_qr_identifier_id` nullable, `actor_staff_ref`, `created_at`). CHECK constraint
  `event_type IN ('activated','revoked','reissued_from')`. Live triggers `trg_sca_qr_lifecycle_events_no_update`
  / `_no_delete` → INSERT-only.
- Active QR is **derived**, not stored as truth: `ProjectionService::activeQrIdentifier()` folds events in
  `(created_at, id)` order — `activated` opens an interval, `revoked` closes it; exactly one open interval =
  the active QR (throws on >1). `reissued_from` is a **lineage/audit marker only — it does not affect the
  active-interval fold.** The result is cached in `sca_item_current_state.active_qr_identifier_id` via
  `ProjectionService::rebuild()`.

**`QrService` (`packages/Sca/Provenance/src/Services/QrService.php`) — exact behavior:**
- `createIdentity($itemId, $isProduction=false)` → INSERTs one immutable `sca_qr_identifiers` row with a fresh
  `Token::opaque()` (32-hex) and `is_production` (**defaults false**). Not yet active.
- `activate($itemId,$qrId,$staffRef)` → locks the projection row (`lockForUpdate`), **rejects if an active QR
  already exists** ("use reissue"), inserts one `activated` event, rebuilds the projection. Only ever called by
  `CertificationService::issue()` (`createIdentity` then `activate`) — i.e. **a QR is first minted+activated at
  certification issuance.**
- `reissue($itemId,$newQrId,$staffRef)` → in ONE transaction: `lockItem()` (`SELECT … FOR UPDATE` on the
  item's `sca_item_current_state` row); read `$currentActive = activeQrIdentifier()`; **throw "no active QR to
  reissue; use activate" if null**; then INSERT three events at one timestamp — (a) `revoked` on
  `$currentActive`, (b) `reissued_from` on `$newQrId` with `replaced_qr_identifier_id=$currentActive`,
  (c) `activated` on `$newQrId`; then `projection->rebuild()`. **The caller must `createIdentity()` the
  replacement first and pass its id as `$newQrId`.** Concurrency: the `FOR UPDATE` lock + re-read of the active
  QR under lock guarantees the "exactly one active QR" invariant even under concurrent writers (F9 contract).

**Live production state (read-only):** `sca_qr_lifecycle_events` = 2 rows, both `activated` (qr 1 → item 1,
qr 2 → item 3); **no reissue has ever been exercised in production.** Both pilot QRs `is_production=0`.

## 2. Determinations (each item the task asked)

| Question | Answer (from the code) |
|---|---|
| **Eligibility** | Item exists **and** has a current ACTIVE QR (`activeQrIdentifier()!=null`, else `reissue()` throws). Because a QR is only ever activated at certification issuance, "has an active QR" ⇒ the item was certified. **Design adds a soft gate:** only offer reissue when an active QR exists; recommend also requiring a **current issued certification** (`current_certification_id != null`) so the reissued token actually resolves (a revoked-cert item would 404 on either token). |
| **What happens to the previous QR** | Its identity row is untouched/immutable; a `revoked` lifecycle event is appended, closing its active interval. It becomes a permanent historical identity. |
| **Does the previous public token become invalid immediately** | **Yes, immediately.** After `rebuild()`, `active_qr_identifier_id` ≠ old id, so `PassportResolver::resolve()` returns null at the active-QR check (`PassportResolver.php:49`) → the controller renders the **constant-shape 404** (identical to SCA-038 revoked). No grace period. |
| **Does the new QR point to the same certified item/passport** | **Yes.** New identity is for the same `eyewear_item_id`; it becomes active; the token resolves through the same projection to the same item + same `current_certification_id` + same authentication → same passport content (only the token differs). |
| **Does certification change** | **No.** `reissue()` writes only QR events; `current_certification_id`, `sca_certifications`, `sca_certification_events`, and the frozen render snapshot are untouched. |
| **Does ownership change** | **No.** `current_owner_collector_id` and `sca_ownership_events` untouched. |
| **Does is_production change** | The **old** row's `is_production` is immutable (unchanged). The **new** row's value is whatever `createIdentity()` is given (**defaults false**). **Design recommendation: carry forward the previous active QR's `is_production`** so a production tag's replacement stays `is_production=1` and a pilot/staging reissue stays 0. (`is_production` is read by no app logic — a print-safety governance marker only — but carrying it forward preserves the "staging tokens never printed" semantics.) |
| **New QR record vs mutating existing** | **New record.** One new immutable `sca_qr_identifiers` row (new unique token). No existing row is mutated (triggers forbid it). |
| **Provenance/audit recorded** | 3 appended `sca_qr_lifecycle_events` rows: `revoked`(old), `reissued_from`(new, `replaced_qr_identifier_id`=old), `activated`(new) — all carrying `actor_staff_ref`. Full forward+backward lineage is reconstructable. |
| **Repeated/concurrent submission** | `reissue()` is safe for the "one active" invariant (lock + re-read). **But a naive double-POST rotates the QR twice** (each request `createIdentity`+`reissue`: 2nd request sees the 1st's new QR as active and rotates again → an orphaned mint + 3 extra events + token changes twice). **Design MUST add an optimistic-concurrency guard** (below) so a resubmit/stale screen is rejected, not silently double-rotated. |
| **What staff sees/downloads/prints after success** | Redirect to the item detail with a success flash; the **existing** `GET admin/sca/eyewear/{id}/qr` download (`EyewearItemController::qr`) already serves the SVG of the **current active** token, so after reissue it automatically renders the NEW token's QR — **no new download code needed.** Flash should direct staff to re-download and reprint. |
| **Reuse existing QR PDF/download/print** | **Yes — reuse `EyewearItemController::qr()` verbatim.** It is active-QR-driven, self-contained scannable SVG (ECC H, ≥4 quiet zone, `svgUseFillAttributes`), filename = `public_ref` only, token never in URL/filename/headers/body. Nothing to change. (It is SVG-only; a PNG/print option is a separate P3 from the app audit, not part of reissue.) |
| **Privacy/security of old & new tokens** | Old token stays in the immutable table forever but no longer resolves (no enumeration: exact-token lookup only, constant-shape 404). Neither token may appear in the reissue route (`{id}` numeric), confirm/apply URLs, filename, flash, logs, or response body — reuse the existing `qr()` privacy contract. New token is a fresh opaque 32-hex, present only inside the QR modules of the downloaded SVG. |

## 3. Physical-tag scenario (explicit)

Original permanent QR printed and affixed → tag lost/damaged → staff opens the item, chooses **Reissue QR**,
confirms (typed word + reason) → `createIdentity`(carry is_production) + `QrService::reissue()` in one txn →
**old token 404s immediately** (per the SCA-038 governance contract for a no-longer-active QR), **new token is
the authoritative QR** resolving to the same certified item/passport → staff clicks the existing **Download QR
(SVG)** which now emits the new token's artifact → reprint and affix. Certification, authentication, ownership,
snapshot, gallery all unchanged; full lineage recorded (`reissued_from`).

## 4. Smallest governed staff UI (design — NOT implemented)

Mirror the established **typed-word confirm** pattern (Terminal Status / Certification Correction): a dedicated
ACL, a GET confirm interstitial, a server-validated FormRequest (reason + typed word + optimistic token), a
thin controller that **reuses `QrService::reissue()`**, redirect to the item with a success flash.

- **ACL (new, dedicated):** `sca.eyewear.qr.reissue` in `packages/Sca/Registry/src/Config/acl.php` — a distinct
  authority from `sca.eyewear.view` (which only gates the download) and from `sca.eyewear.certify`, consistent
  with how `sca.eyewear.certification.correct` is separated from `certify`. Route list:
  `['admin.sca.eyewear.qr.reissue.confirm','admin.sca.eyewear.qr.reissue']`.
- **Routes** (Registry `admin-routes.php`, `{id}` `[0-9]+`, middleware `sca.can:sca.eyewear.qr.reissue`):
  - `GET  sca/eyewear/{id}/qr/reissue/confirm` → `qrReissueConfirm` (name `…qr.reissue.confirm`)
  - `POST sca/eyewear/{id}/qr/reissue`         → `qrReissue`        (name `…qr.reissue`)
- **Controller** (new `QrReissueController`, or two methods on `EyewearItemController`; inject `QrService` +
  `ProjectionService`):
  - `confirm($id)`: load item; if no active QR → the constant `qrNotFound()`/error (ineligible); else render
    the interstitial with the item `public_ref`, the current active QR's `public_ref`/short identity (NEVER the
    raw token), a prominent irreversible-warning, and a hidden **`expected_active_qr_id`** (the current active
    id — the optimistic-concurrency token). Soft-warn if `current_certification_id` is null.
  - `apply($id, QrReissueRequest)`: load item; **optimistic guard** — compare the submitted
    `expected_active_qr_id` to the current `active_qr_identifier_id`; if different → redirect back to confirm
    with a STALE error, **creating nothing**; else derive `$prev = current active QrIdentifier`,
    `createIdentity($id, $prev->is_production)`, then `QrService::reissue($id, $newId, staffRef)` (staffRef =
    `auth()->guard('user')->id()`), catch the "no active QR" RuntimeException → STALE error; redirect to
    `admin.sca.eyewear.show` with success "QR reissued — the previous tag no longer verifies; download and
    reprint the new QR." **No QR lifecycle logic in the controller — it only orchestrates `createIdentity` +
    `reissue`.**
  - **Concurrency hardening decision (for ChatGPT):** the controller pre-check narrows the double-submit
    window but is not airtight across the `createIdentity`→`reissue` boundary. The robust option is to give
    `QrService::reissue()` an **optional** `?int $expectedCurrentActiveId = null` and assert it **under the
    existing `FOR UPDATE` lock** (exactly mirroring `CertificationCorrectionService`'s `expected_event_count`).
    This is a 2-line, backward-compatible service addition — **not schema, not a reimplementation of lifecycle
    logic.** Recommended; present both options and let review choose.
- **Request** (new `QrReissueRequest`, mirror `TerminalStatusRequest`): `reason` required string max 255;
  `confirm` required, `Rule::in(['REISSUE'])` (upper-cased in `prepareForValidation`); `expected_active_qr_id`
  required integer. `authorize()` returns true (route ACL enforces). Invalid input ⇒ no mutation (validation
  runs before the action).
- **View** (new `eyewear/qr-reissue-confirm.blade.php`, mirror `status/confirm.blade.php`): amber/red callout —
  "This replaces the item's permanent QR. The previously printed tag will STOP verifying immediately and cannot
  be restored. Certification and ownership are unchanged." + reason field + "Type REISSUE to confirm" + submit;
  Cancel back to item.
- **Entry point:** a "Reissue QR" button on `eyewear/show.blade.php` **Certification & QR** tab, beside the
  existing "Download printable QR" link, rendered only when an active QR exists and gated on the new ACL (so
  operators without the authority never see it).

## 5. Test scope (regression coverage — implementation-time)

New `tests/Feature/Sca/QrReissueTest.php`:
- **Eligibility:** item with no active QR → confirm ineligible / apply blocked, no mutation; item with active
  QR → confirm renders.
- **Authorization:** unauth → login redirect; user lacking `sca.eyewear.qr.reissue` → 403; the download/view
  permission alone does NOT grant reissue.
- **Confirmation:** confirm interstitial shows the typed word + `expected_active_qr_id`, no raw token; missing/
  wrong `reason` or `confirm` word → validation fails, **no** identity row and **no** lifecycle event created.
- **Successful reissue (exact before/after — see §6):** identities +1, events +3 of the correct types/order,
  `active_qr_identifier_id` flips old→new.
- **Old-token behavior:** old token → `PassportResolver` null → passport 404 (constant shape); old identity row
  byte-identical (token preserved).
- **New-token behavior:** new token → passport 200, same item + same `current_certification_id` + same
  authentication; the existing `GET {id}/qr` download now encodes the NEW token's canonical passport URL
  (decode-verified, as in `QrArtifactTest`).
- **Preservation:** `sca_certifications` / `sca_certification_events` / snapshot, `sca_authentication*`,
  `sca_ownership_events` / `current_owner_collector_id`, `lifecycle_state`, gallery rows — all unchanged.
- **Projection:** `active_qr_identifier_id` old→new; one open interval only (no `>1 active` exception).
- **Double-submit / concurrency:** replaying the same `expected_active_qr_id` after a reissue → STALE, **no**
  second rotation, **no** extra identity/events; (if the service guard is adopted) a direct second `reissue`
  with a stale expected id throws/rejects under lock.
- **is_production:** reissuing a production QR → new row `is_production=1`; a staging QR → new row `0` (carried).
- **Privacy:** neither old nor new raw token appears in any confirm/apply URL, the download filename, flash,
  logs, or response body text.

## 6. Authorized before/after mutation (replaces the "zero QR mutation" invariant)

Because reissue is **intentionally** a provenance mutation, the implementation test asserts an EXACT authorized
delta and that nothing else moves. For the target item:

| Fact | Before | After (authorized) |
|---|---|---|
| `sca_qr_identifiers` rows | N | **N+1** (one new immutable row, new unique 32-hex token, `is_production` carried) |
| `sca_qr_lifecycle_events` rows | M | **M+3** (`revoked` old; `reissued_from` new, replaced=old; `activated` new) |
| projection `active_qr_identifier_id` | OLD id | **NEW id** |
| OLD identity row (token, is_production) | — | **byte-identical** (immutable) |
| `current_certification_id` | C | **C (unchanged)** |
| `current_owner_collector_id` | O | **O (unchanged)** |
| `lifecycle_state`, cert/auth/ownership/snapshot/gallery tables | — | **unchanged** |
| other items' QR/state | — | **unchanged** |

Everything outside this delta must prove unchanged: certification/authentication/ownership fingerprints,
migrations count, gallery count, `/storage` policy, SCA-038 constant-shape 404, and all other items.

## 7. Schema verdict & scope summary

- **No schema change required.** All effects are append-only INSERTs into existing tables; the
  `event_type` CHECK already permits `revoked`/`reissued_from`/`activated`; the append-only triggers permit
  INSERT. The optional `reissue()` expected-active param (§4) is code, not schema.
- **Scope:** 1 ACL entry, 2 routes, 1 controller (2 methods), 1 FormRequest, 1 confirm blade, 1 button on the
  existing show view, 1 feature test. **Reuse** `QrService::reissue()`, `createIdentity()`, `ProjectionService`,
  and the existing `EyewearItemController::qr()` download. Optional 2-line `QrService::reissue()` concurrency
  param (recommended; decide at review).

**Recommendation: GO for the design above** (push-only → pre-merge review → governed merge/deploy), with the
concurrency-guard option resolved by review. **AUDIT ONLY — no implementation. Awaiting ChatGPT review;
ACTIVE/NEXT_TASK remain unpromoted.**

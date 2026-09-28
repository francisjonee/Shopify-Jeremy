# SCA-049 — Collector Ownership & Transfer History — READ-ONLY PLANNING / ARCHITECTURE AUDIT

**Type:** planning / architecture audit only. **No** implementation, feature branch, migration, production
mutation, deployment, or SCA-050 promotion was performed. **Audit target:** deployed `main`
`96cc584556c78b009ccb8e88afe228f08891e7ba` (SCA-048 DONE).

**Goal being scoped:** the smallest privacy-safe way for the **current** collector to see the
ownership/transfer history of an item in My Collection, using existing canonical provenance only.

---

## 1. Canonical ownership/transfer provenance (what exists)

All under `packages/Sca/Provenance/src`. Every FK is `restrictOnDelete`; the event ledgers are append-only
(`_no_update`/`_no_delete` triggers from migration …120017).

- **`sca_ownership_events`** (…120010; `reason` added …09_24) — the canonical ownership ledger. Columns:
  `id`, `eyewear_item_id`, `event_type` CHECK(`claim` | `transfer_in` | `transfer_out` | `admin_correction`),
  `collector_account_id` (nullable — **null on terminal `transfer_out`**), `prior_event_id`, `source_claim_id`
  (FK `sca_claims`), `source_transfer_event_id`, `effective_at`, `created_at`, `reason` (nullable — only
  `admin_correction` sets it, SCA-035).
- **`sca_transfer_requests`** (…120011) — `from_collector_id`, `to_collector_id` (null until accepted),
  `invite_token` char(32) **single-use secret**, `state`, `expires_at`, `version`.
- **`sca_transfer_events`** (…120012) — `transfer_request_id`, `event_type` CHECK(`initiated`|`accepted`|
  `cancelled`|`expired`|`rejected`), `actor_collector_id` (null for system `expired`), `created_at`.
- **`sca_claims`** (…120009) / **`sca_external_claim_grants`** (…09_23) — claim state + `grant_token`
  char(32) **secret**; the acquisition source behind a `claim` ownership event.

**How ownership is written** (verified):
- `ClaimService` writes ONE `claim` ownership event (`collector_account_id` = claimant, `source_claim_id`).
- `TransferService::accept` writes an `accepted` transfer_event, then **TWO** ownership events sharing the same
  `source_transfer_event_id`: a `transfer_out` (`collector_account_id = null`, `effective_at = now`) **and** a
  `transfer_in` (`collector_account_id = recipient`, `effective_at = now+1µs`). → a transfer is a *pair* keyed
  by `source_transfer_event_id`.
- `OwnershipCorrectionService` writes ONE `admin_correction` event (`collector_account_id` = corrected owner,
  `reason` recorded — SCA-035).

**How current ownership is derived** — `ProjectionService::currentOwner($itemId)`: takes the latest
`sca_ownership_events` row by `(effective_at DESC, id DESC)`; if it is `transfer_out` (or none) → no current
owner, else the owner is that row's `collector_account_id`. This is the same fold cached on
`sca_item_current_state.current_owner_collector_id` and is the authorization source for all of My Collection.

**Sufficiency:** the ledgers + `ProjectionService` are **fully sufficient. No schema change is required.**

---

## 2. What can safely be shown to the current collector

The current owner may see, for an item **they currently own**, a neutral chronological ownership timeline built
from `sca_ownership_events` for that item:

- **event dates** (`effective_at`, rendered date-only) — non-identifying;
- **neutral event descriptions** that never identify any collector (see §4);
- a **`mine` flag** marking the event(s) that are the *viewer's own* acquisition (safe — it is about the
  viewer themselves, e.g. "Added to your collection").

Nothing else. The timeline is derived, non-persisted, read-only.

---

## 3. What MUST be withheld (default: withhold unless an accepted contract authorizes)

Withhold from the collector-facing read model **and** the rendered HTML:

- any **other collector's identity** — `display_name`, `email`, `public_ref` (COL-…), or `collector_account_id`;
- **internal DB ids** — ownership-event id, transfer-request/event id, claim id, prior_event_id;
- **staff actor** — `raised_by_staff_ref` / any staff ref;
- **correction reason** — `sca_ownership_events.reason` (SCA-035) and any status/cert reason;
- **secrets/tokens** — `invite_token`, `grant_token`, claim tokens, QR `public_token`, cert `public_token`,
  snapshot checksum;
- **Shopify** identifiers / `shopify_customer_ref`.

**Evidence this is the correct default:** the existing My Collection detail deliberately shows ownership only
as **"Registered to you"** (`CollectionService::detail`, no other identity); the public passport hides owner
identity entirely (owner-private, Option A); PRODUCT_REQUIREMENTS §206 forbids exposing email/phone/address/
credentials and requires owner display to be privacy-controlled; and the *identified* ownership chain is a
**staff-only** capability (SCA-033 `ownershipHistory`, `sca.eyewear.view`). No accepted collector-facing
contract authorizes showing another collector's identity, so it is withheld.

---

## 4. Neutral event representation (never identifies another collector)

| Ledger event | Condition | Neutral collector-facing label | `mine` |
|---|---|---|---|
| `claim` | `collector_account_id` == viewer | **Added to your collection** | true |
| `claim` | other collector (pre-ownership) | **First registered to a collector** | false |
| transfer pair (by `source_transfer_event_id`) | `transfer_in.collector` == viewer | **Transferred to your collection** | true |
| transfer pair | not involving viewer | **Ownership transferred** | false |
| `admin_correction` | assigns to viewer | **Ownership assigned to you by SCA** | true |
| `admin_correction` | other collector | **Ownership updated by SCA** | false |

- **Transfer-pair collapse:** the `transfer_out` + `transfer_in` that share a `source_transfer_event_id` render
  as **one** timeline entry (represented by the `transfer_in`; `mine` = recipient == viewer). A lone terminal
  `transfer_out` with no paired `transfer_in` renders as the neutral "Ownership transferred".
- **SCA-035 corrections** appear ONLY as the neutral "Ownership updated by SCA" / "Ownership assigned to you by
  SCA" — **never** the `reason` text or the staff actor. The fact that SCA administratively adjusted ownership
  is itself neutral and non-identifying.

---

## 5. Decision: should the current owner see history from *before* they owned the item?

**Recommendation: YES — but only non-identifying facts (neutral label + date), never identity.**

Evidence: PRODUCT_REQUIREMENTS §110 lists **Ownership history** and **Transfer history** as content of the
Digital Provenance Record; chain-of-custody is a core value of the product. Showing prior events as neutral,
dated, unattributed entries exposes **no** collector identity, so it does not breach §206 (which targets
email/phone/address/credentials and owner-identity display) and is consistent with the "Registered to you"
posture (which withholds *identity*, not the *existence* of provenance). Residual consideration: exact transfer
dates could, in a tiny pilot, invite correlation guesses — but no identity, ref, or contact is attached, and
the existing certificate/service histories already surface dates, so date-only prior entries are within the
accepted privacy envelope. **If ChatGPT prefers maximum caution,** a strict fallback (Option A) is to show only
the viewer's own tenure (their acquisition event + "currently in your collection") and omit pre-ownership
entries entirely; this is smaller but delivers little beyond SCA-048. The recommended slice is the neutral full
timeline.

## 6. Decision: do transferred-away previous owners keep history access?

**Recommendation: NO — default to the existing My Collection authorization boundary.** Access derives strictly
from **current** canonical ownership (`current_owner_collector_id` == viewer). Once a collector transfers an
item away they are no longer the canonical owner, so `ownedItemId(...)` returns null and the detail returns the
existing privacy-safe 404 — identical to SCA-048 and every other My Collection surface. No requirement
authorizes retained post-ownership access, so none is granted.

---

## 7. Read-only enrichment — no new route

This is a **read-only enrichment of the existing My Collection item detail** (`collector.collection.show` →
`sca-collector::collection.show`). Add one owner-authorized read method on `CollectionService` (mirroring
`serviceHistoryForOwnedItem` / `certificationHistoryForOwnedItem`) and one view section. **No new route
(public or collector), no new ACL, no schema, no migration, no mutation.**

---

## 8. Proposed collector-safe read-model shape

```
ownershipHistory = [
  'entries' => [                    // chronological, oldest → newest
     [ 'label' => <neutral string from §4>,
       'date'  => 'F j, Y' | null,  // effective_at, date-only
       'mine'  => bool ],           // true only for the viewer's own acquisition/assignment
     ...
  ],
]
```

Derivation (all reads): resolve `itemId` via `ownedItemId($collectorId, $ref)` (returns `[]`-shape for any
non-owner → the controller still 404s first); load `sca_ownership_events` for the item ordered
`(effective_at, id)`; collapse transfer pairs by `source_transfer_event_id`; map each to a neutral label per
§4 with `mine = (collector_account_id === viewer)`. **Selected columns:** `event_type`,
`collector_account_id` (compared to the viewer only — never returned), `source_transfer_event_id`,
`effective_at`. **Never selected:** `reason`, `prior_event_id`, `source_claim_id`, ids, tokens, staff refs.
Returned entries contain **exactly** the keys `label`, `date`, `mine`.

---

## 9. Acceptance-test matrix (define before implementation)

Focused suite (disposable `sca_domain_test`, `DatabaseTransactions`, DB-name guard), mirroring
`ItemCertificationHistoryTest`:

1. **oh1 initial claim** → one entry "Added to your collection", `mine=true`, dated.
2. **oh2 transferred-in from another collector** → prior owner's registration renders as neutral "First
   registered to a collector" (`mine=false`) + "Transferred to your collection" (`mine=true`); **no** prior
   collector identity/ref/email anywhere.
3. **oh3 transfer-pair collapse** → a single accepted transfer yields exactly **one** timeline transfer entry,
   not two.
4. **oh4 SCA-035 admin correction** → neutral "Ownership updated by SCA"/"…assigned to you by SCA"; the
   correction `reason` and staff ref are absent from the read model and the rendered HTML.
5. **oh5 privacy key-set** → each entry has exactly `['label','date','mine']`; rendered page shows no other
   collector's `display_name`/`email`/`public_ref`, no staff ref, no reason, no invite/grant/claim/QR/cert
   token, no internal ids.
6. **oh6 current-owner authorization** → owner sees the timeline.
7. **oh7 non-owner + previous-owner denial** → non-owner gets the empty shape + detail 404; a collector who
   transferred the item away loses access (empty + 404).
8. **oh7b unauthenticated** → redirect to collector login.
9. **oh8 neutral language** → HTML contains "Ownership transferred"/"Added to your collection"/"Ownership
   updated by SCA" and never another collector's identifier.
10. **oh9 zero mutation** → viewing the timeline (service + GET) leaves an identical DB snapshot.
11. **oh10 independence** → SCA-048 certification history, SCA-041 passport access, and SCA-042 document
    classification behave unchanged on the same page.

Plus the full `tests/Feature/Sca` suite must stay green (current baseline 586/3150 at `96cc584`; the new focused
tests add to it).

---

## 10. Independence of neighbouring features & invariants

- **SCA-048 certification history** and **SCA-042 document classification** read `sca_certifications` /
  `sca_certification_events` / `sca_media_assets`; **SCA-049** reads `sca_ownership_events` / transfer tables —
  disjoint sources, additive view section, no shared state. Independent.
- **SCA-041 passport access / SCA-038 Option A** are untouched — no change to `PassportResolver`/
  `PassportController`, no new token exposure (the timeline emits no QR/cert token).
- **Append-only provenance invariants** are unaffected — SCA-049 is pure read; it writes nothing, and touches
  no projection rebuild or ledger.

---

## 11. Recommendation (smallest useful slice)

Implement a **read-only "Ownership history" section on the existing My Collection item detail**: an
owner-authorized, neutral, dated chronological timeline built from `sca_ownership_events` (transfer pairs
collapsed), labelling only the viewer's own acquisition and otherwise using non-identifying phrasing
("First registered to a collector" / "Ownership transferred" / "Ownership updated by SCA"). Withhold every
identity, ref, staff actor, reason, token, and internal id. No schema, no route, no mutation. This is the
smallest slice that delivers the §110 ownership/transfer-history value without becoming a provenance
dashboard, and it composes cleanly beside SCA-048's certification history on the same page.

---

## 12. Governance state (unchanged by this audit)

- **ACTIVE = NONE; NEXT_TASK = NONE.** This planning audit is recorded as DONE in `TASK_QUEUE.md` (matching the
  SCA-039 / SCA-047 convention); no implementation task is promoted.
- **SCA-050 not promoted / not started.** The §11 recommendation is a candidate only; ChatGPT may promote one
  implementation task after reviewing this report.
- **SCA-PRODUCTION-CUTOVER remains BLOCKED/DEFERRED.**
- Production and the pilot are exactly as found; this audit made no code, config, container, network, or data
  change.

# NEXT TASK

**STATUS:** ACTIVE — `SCA-COLLECTOR-OWNERSHIP-TRANSFER-HISTORY-049` **implemented and pushed for ChatGPT audit**
(push only — NOT merged, NOT deployed, production NOT migrated). Base = deployed `main`
`96cc584556c78b009ccb8e88afe228f08891e7ba`; feature branch `sca-collector-ownership-transfer-history-049` @
`e3abf76695d3539ab59a5afe24a0bcb020b02a5a`. Focused `ItemOwnershipHistoryTest` 11/50; full `tests/Feature/Sca`
597/3201 (586/3150 baseline + 11 new + 1 assertion from the SCA-033 `o14` update). Read-only (no schema/route/
mutation); SCA-048/041/042 + SCA-038 Option A preserved. Pilot restored to deployed `96cc584`. Must not be
merged/deployed and SCA-050 must not start until ChatGPT authorizes. Evidence in the implementation repo
`docs/task-reports/SCA-COLLECTOR-OWNERSHIP-TRANSFER-HISTORY-049.md`.

*Prior: `SCA-048` DONE (deployed `96cc584`); `SCA-049` planning audit DONE
(`docs/SCA-049-COLLECTOR-OWNERSHIP-TRANSFER-HISTORY.md`). `SCA-PRODUCTION-CUTOVER` remains BLOCKED/DEFERRED.
SCA-050 must not start.*

## Title

SCA-COLLECTOR-OWNERSHIP-TRANSFER-HISTORY-049 — read-only owner-facing Ownership history on My Collection

## Goal

Let the authenticated **current owner** see the ownership/transfer history of an item they own, on the
existing My Collection item-detail page, as a neutral non-identifying timeline built from the existing
canonical provenance. Smallest approved slice from the SCA-049 audit.

## Executable directive (as governed)

Add a read-only "Ownership history" section to the existing collector item-detail surface
(`collector.collection.show` → `sca-collector::collection.show`). **No new route, ACL, table, migration, or
mutation endpoint.** Prefer one owner-authorized `CollectionService` read method + the existing
`CollectionController::show` + the existing blade view. Do NOT create another ownership ledger/projection, and
do NOT broaden into certification/status/service history (SCA-048 owns certification history).

### Authorization boundary
Only the collector who **canonically owns the item now** (`sca_item_current_state.current_owner_collector_id`
== authenticated collector, via the existing `ownedItemId(...)` path) may obtain the history. Previous owners,
unrelated collectors, and unauthenticated users get the existing privacy-safe denial (empty read model +
detail 404 / login redirect). No historical-access rights for former owners.

### Canonical source
Derive the timeline from `sca_ownership_events` (the accepted ownership ledger) using the same canonical
ownership semantics as `ProjectionService`. Transfer, claim, and correction rows are read; nothing is written.

### Read model — each entry EXACTLY `{label, date, mine}`
- `label`: a neutral, non-identifying string (see Presentation).
- `date`: `effective_at` rendered date-only (or null).
- `mine`: derived from the authenticated collector's **actual relationship to that provenance event**
  (`collector_account_id` of that event == the viewer) — **never** inferred from ordering, label, or position.
No other identifiers or metadata in the entry.

### Privacy hard gate — never return or render
collector name/email; any other collector's `COL-…` ref; `collector_account_id`; internal event/transfer/
claim/grant IDs; `prior_event_id`; staff references; SCA-035 `admin_correction` **reason**; transfer/claim/
grant/invite/QR/cert **tokens**; checksums; or any other hidden provenance field. Pre-ownership events MAY be
shown, but only as **date + neutral label**.

### Presentation (neutral language)
"Added to your collection" (viewer's own claim/transfer-in), "First registered to a collector" (another
collector's initial claim), "Ownership transferred" (a transfer not involving the viewer), "Ownership updated
by SCA" / "Ownership assigned to you by SCA" (SCA-035 `admin_correction` — **never** its reason or actor).
Never identify previous or subsequent collectors.

### Transfer-pair folding
A canonical transfer writes `transfer_out` + `transfer_in` sharing `source_transfer_event_id`. Collapse that
pair into **one** collector-facing timeline event (represented by the `transfer_in`; `mine` = recipient ==
viewer). Folding must NOT: render duplicate transfer entries; lose the viewer's acquisition semantics;
mark someone else's historical transfer as `mine`; or expose `source_transfer_event_id`. Order deterministically
by canonical chronology (`effective_at`, then `id`).

### Tests (focused suite) — must independently prove
current owner sees history; unrelated collector denied; previous owner denied after transfer; unauthenticated
denied; pre-ownership events neutral/non-identifying; own acquisition correctly marked `mine`; transfer pair
collapses once; SCA-035 correction neutral (no reason/actor); exact read-model key set = `{label,date,mine}`;
sensitive identifiers/reasons/tokens/PII absent from returned data AND rendered HTML; GET/detail viewing = zero
domain mutation; SCA-048 certification history intact; SCA-041 passport access intact; SCA-042 document
classification intact. Inspect the real event semantics first and add any edge-case test discovered (do not
assume every chain is claim→transfer).

Run the focused SCA-049 suite AND the full `tests/Feature/Sca` suite on the disposable `sca_domain_test` DB;
record exact totals.

### Delivery
Implement on a governed feature branch off `96cc584`; **push only**; restore the pilot to deployed `96cc584`
(clean tree, `--no-dev`, existing exposure/IP-lock, private MariaDB); push governance evidence; STOP for
ChatGPT audit. **Do NOT merge or deploy. Do NOT start/promote SCA-050.**

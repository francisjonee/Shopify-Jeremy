# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-OWNERSHIP-PROVENANCE-033

## Title

Add staff-visible append-only ownership provenance history

## Implementer

Claude

## Why this task now

Live pilot testing on 2026-09-24 proved the collector ownership flow end to end: an externally-intaken certified item was claimed by Collector #1, transferred to Collector #2, disappeared from the former owner's My Collection, appeared for the new owner, the old transfer capability became unusable, and the staff item projection correctly changed to `REGISTERED` / `normal` / `Collector #2` while the original authentication, certification, QR identity, certificate PDF, and registry state remained intact.

The staff item page also reports `Ownership events: 3`, proving ownership provenance records exist, but staff currently have no usable surface to inspect those events. The existing admin registry implementation intentionally exposes only a provenance-count summary. This is now an operational/audit gap: staff can see the current owner and event count but cannot answer how ownership reached the current state.

Do not guess what the three live events mean. Inspect the canonical ownership event schema/services and render the actual stored semantics truthfully.

## Authority and safety boundary

This task is a **read-only staff ownership provenance inspection feature**.

It must expose the canonical append-only ownership chain to authorized SCA staff without creating, editing, deleting, repairing, synthesizing, or reinterpreting ownership events. It must not change transfer, claim, collector, certification, authentication, status, service, document, Shopify, QR, or projection semantics.

Ownership history is evidence. Historical rows are immutable. If the accepted architecture later needs correction events, that is a separate mutation task; this task must not add an edit/delete/rewrite mechanism.

## Required Work

1. Pull latest governance `main` and latest implementation `main` before coding. Treat current implementation `main` as source of truth; do not assume the stale historical task numbering/content in older governance files reflects deployed state.
2. Create branch `feat/sca-ownership-provenance-033` from latest accepted implementation `main`.
3. Audit the relevant canonical ownership/current-state implementation before changing code: ownership event table/model/schema, claim workflow, transfer service/workflow, projection rebuild/current-owner logic, staff eyewear detail presenter/controller/view, SCA staff ACL/middleware, collector My Collection authorization, and focused tests/task reports for claim and transfer. Reuse accepted structures; do not build a parallel ledger.
4. Determine and document the **actual canonical ownership event vocabulary and fields** already stored. The UI must represent those stored semantics faithfully. Do not invent rows such as “claim link issued” unless that is genuinely an ownership event in the canonical ledger.
5. Add a staff-visible **Ownership history** inspection surface reachable naturally from the SCA Eyewear Registry item detail. The existing `Ownership events: N` provenance count may become a link or gain a nearby `View ownership history` action. Keep the current item detail useful and uncluttered.
6. The history must be scoped server-side to exactly the selected canonical physical item. Do not trust item/event IDs supplied by the client beyond route resolution, and do not allow one item's history to leak into another.
7. Prefer the existing staff item identity/route conventions unless a safer opaque route is already established. Do not redesign the whole registry routing layer in this task.
8. Render events in deterministic chronological order with enough information for staff to audit the ownership chain. At minimum, where canonical data supports it, expose: event timestamp, canonical event type, previous/from collector reference, resulting/to collector reference, and the mechanism/context that is actually represented by canonical data. If a field is not stored, do not fabricate it.
9. Collector identity must remain privacy-conscious. Use the accepted safe staff-facing collector label/reference (for example `Collector #2` if that is the established representation). Do not expose passwords, sessions, email addresses, raw PII, security tokens, claim tokens, transfer invite tokens, Shopify customer/order identifiers, or other secrets merely to make the history more descriptive.
10. Do not expose internal ownership-event primary keys unless an existing accepted staff audit convention explicitly requires them. The useful audit record is the event semantics, parties/references, and timestamp, not database internals.
11. Make the append-only nature explicit in the staff UI. There must be **no edit or delete action** for ownership history.
12. Preserve historical owners/events after transfer. The current owner projection must continue to derive from the accepted canonical ledger/projection rules; this feature must not recompute ownership differently or introduce a second source of truth.
13. A transferred item must show a truthful chain sufficient for staff to distinguish the initial acquisition/claim evidence from subsequent transfer-out/transfer-in evidence according to the actual canonical event model. Do not collapse away events merely to make the display prettier.
14. If paired transfer-out/transfer-in events are separate canonical records, display them as separate evidence unless the accepted domain already has a canonical presenter that groups them without losing evidence. Do not silently merge or rewrite provenance.
15. Staff authorization must use the accepted SCA staff authentication/ACL boundary. Unauthorized/unauthenticated users, collector sessions, and staff lacking the required SCA permission must not gain access. Reuse an existing appropriate registry-view permission if that is the established contract; add a new permission only if architecture/security requires it and document why.
16. Direct requests for a nonexistent item or invalid history target must return the established real privacy-safe 404 behavior, not Krayin's masked-200 error behavior.
17. The collector portal and public passport must **not** gain this staff history automatically. This task is staff inspection only. Do not expose former/current owner identity or private ownership chain on `/p/{token}`. Do not broaden My Collection data.
18. The history view itself must be read-only and produce zero domain mutations: zero ownership events, transfer events/requests, claims, current-state changes, status events, service events, certification/authentication/QR events, document changes, or Shopify/sale-link changes.
19. Do not alter the semantics of the successful claim/transfer flow already pilot-tested. Claim remains the initial registration mechanism; transfer remains collector-to-collector via the accepted single-use capability flow; current ownership remains projection-backed.
20. Add focused automated tests covering at minimum: initial claimed ownership history is visible to authorized staff; completed transfer preserves and displays the full canonical ownership chain; chronological ordering; current owner agrees with canonical projection after transfer; historical owner remains in history but is not current owner; history is item-scoped; another item's events never appear; zero edit/delete actions/routes; unauthenticated denied; collector session denied; restricted staff denied; nonexistent item real 404; no PII/security/claim/transfer/Shopify token leakage; public passport unchanged/owner-private; collector My Collection privacy unchanged; viewing history creates zero domain mutations.
21. Include a direct invariant test proving the rendered history is derived from canonical ownership events rather than reconstructed from current-state, transfer requests, Shopify sale evidence, or UI assumptions.
22. Run focused ownership-history tests plus relevant provenance, registry, claim, transfer, collector authorization/My Collection, passport/privacy, and mandatory SCA regressions. Run `composer validate`, `composer audit`, and repository secret-safety checks.
23. Create `docs/task-reports/SCA-OWNERSHIP-PROVENANCE-033.md` documenting: actual canonical ownership event schema/vocabulary discovered; route/ACL contract; displayed fields and privacy boundary; ordering and item-scoping; append-only/no-mutation evidence; claim→transfer example semantics based on tests; test/assertion results; changed files; base SHA; final branch SHA; findings/deferrals.
24. Make logical checkpoint commits and push `feat/sca-ownership-provenance-033`.
25. STOP after push for ChatGPT audit. Do not create/merge a PR, do not deploy the feature branch, and do not begin unrelated status/service/Shopify work.

## Acceptance Gate

PASS requires:

- authorized SCA staff can inspect the actual canonical ownership-event chain for one item from the item registry;
- the display is derived from canonical append-only ownership events, not reconstructed guesses;
- the pilot pattern of initial ownership followed by transfer is truthfully auditable;
- current owner and historical chain remain consistent with the canonical projection;
- historical evidence is never edited/deleted/rewritten;
- no edit/delete ownership-history capability exists;
- no cross-item leakage;
- no collector PII, credentials, tokens, Shopify internals, or security secrets leak;
- collector portal and public passport privacy remain unchanged;
- viewing history creates zero domain mutations;
- SCA staff ACL/auth and real-404 conventions hold;
- claim and transfer behavior/regressions remain intact;
- no live Shopify mutation/dependency;
- no Krayin core/vendor change;
- focused tests, relevant regressions, mandatory checks, task report, commits, and push all pass.

## Explicit non-goals

Do not implement ownership correction, manual reassignment, admin transfer, event deletion/editing, collector PII expansion, public ownership history, blockchain/external ledger work, new certificate generation, lost/stolen workflow changes, service-event changes, Shopify customer synchronization, or QR redesign.

## Completion Rule

When complete, report only:

1. branch and final HEAD SHA;
2. task report path;
3. actual canonical ownership event vocabulary/schema discovered;
4. staff route + ACL contract;
5. displayed ownership-history fields and privacy boundary;
6. claim→transfer chain behavior proven by tests;
7. append-only/read-only/no-domain-mutation evidence;
8. focused/regression test counts and mandatory checks;
9. blocker/deferral, if any;
10. confirmation everything is pushed.

Then STOP for ChatGPT audit.

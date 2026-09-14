# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-DOMAIN-DESIGN-003

**RETRY_GENERATION:** 2

## Title

Close the remaining provenance-integrity gaps in PR #3 before domain migrations

## Implementer

Claude

## Authority

ChatGPT re-audited implementation PR #3 after remediation generation 1.

The major architecture corrections are accepted: certification and QR history are now append-only, claims are first-class, Shopify IDs are store-scoped, owner projection semantics are corrected, and the approved business defaults are encoded. The design is close, but several remaining integrity claims are still not implementation-safe.

Authoritative implementation repository:

`francisjonee/francisjonee-sca-platform-private`

Authoritative implementation PR:

`#3`

Continue on the existing branch:

`design/sca-domain-design-003`

PR #3 is open and must remain unmerged. This remains DESIGN ONLY. Do not start `SCA-DOMAIN-CORE-004`.

## Preserve Accepted Generation-1 Work

Do not undo these accepted decisions:

- issued certification rows are immutable; revoke/supersede is append-only via `sca_certification_events`;
- QR identity rows are immutable; lifecycle is append-only via `sca_qr_lifecycle_events`;
- `sca_claims` is first-class;
- `current_owner_collector_id` is not unique; one collector may own many items;
- Shopify uniqueness is scoped by shop;
- external intake requires explicit claim and never auto-registers ownership;
- post-claim refund keeps ownership and raises `disputed`;
- transfer expiry defaults to 14 days configurable;
- frame serial is advisory/non-unique;
- media is private by default with explicit public opt-in;
- PII may be pseudonymized without deleting provenance;
- certification uses opaque permanent public identity;
- QR reissue is staff/admin only and preserves old history.

## Remaining Audit Findings

### F9 — Active-QR event history can still disagree with the projection

The design says the current active QR is derived from `sca_qr_lifecycle_events`, but also says exactly one active QR per item is guaranteed by the single projection row.

The projection alone does not make the append-only event history internally unique. It is possible, unless the write contract forbids it, to append `activated` events for two different QR identifiers on the same item while the projection points at only one. That would make a rebuild from events ambiguous and violate the claim that the projection is rebuildable from canonical history.

Required correction:

- define the QR activation/reissue transaction precisely;
- lock `sca_item_current_state` for the item with `SELECT ... FOR UPDATE`;
- ordinary activation must reject if another active QR exists for that item, unless the same transaction also revokes/replaces it under the approved reissue path;
- reissue must append the new activation/reissue event(s), append revocation of the prior active QR, and update the projection in the same transaction;
- define a deterministic event fold/order so rebuild produces exactly one active QR or raises an integrity error rather than silently picking one;
- add a negative test for attempting to activate a second QR without revoking/reissuing the current active QR.

Do not claim the projection by itself proves canonical-history uniqueness.

### F10 — External-intake claim does not record the provenance record that authorized entitlement

`sca_claims(external_intake)` currently has no sale-link, which is correct, but the design says entitlement is granted after successful authentication/certification without storing which certification/authentication authorized that claim.

For a permanent provenance registry, the initial ownership claim must retain auditable authorization evidence even if certification later changes.

Required correction:

- add an explicit source reference for external-intake entitlement, preferably `source_certification_id` FK to the exact issued certification that authorized the claim;
- if a different explicit entitlement entity is chosen, justify it and keep the provenance chain equally auditable;
- enforce source-specific nullability/consistency: Shopify claims require `source_sale_link_id` and no external certification source; external-intake claims require the approved external source and no sale link;
- completed external claims must prove that source certification belonged to the same eyewear item and was valid/issued at claim time;
- preserve the source reference forever after claim finalization.

### F11 — Claim terminal-state immutability is incomplete

`sca_claims` has states `pending`, `verified`, `completed`, `rejected`, but `finalized_at` is described as set only at completion. That leaves `rejected` ambiguous: it could remain mutable indefinitely even though rejection is a terminal business outcome.

Required correction:

- define legal transitions explicitly, e.g. `pending -> verified -> completed` and `pending|verified -> rejected`;
- use a terminal timestamp (`finalized_at` is fine) for BOTH `completed` and `rejected`, or otherwise define an equivalent terminal mechanism;
- completed/rejected claims must be immutable after terminalization;
- a rejected claim cannot later become completed by mutating the same row; retry is a new claim record/idempotency attempt under defined rules;
- add tests for mutation of completed/rejected claims and rejected->completed mutation attempts.

### F12 — Krayin staff attribution is called “soft” while schema declares hard FKs

Several SCA tables declare fields such as `performed_by_user_id` / `actor_user_id` as FK to Krayin `users`, but §18 says these are “soft staff attribution” and would simply become historical ids if Krayin is replaced.

A database FK to a Krayin-owned table is not a soft reference and can couple SCA provenance to Krayin user-row deletion/migration.

Choose one coherent separability model. Preferred architecture:

- keep the staff actor id as a nullable unsigned historical reference without a database FK to Krayin core, OR introduce an SCA-owned staff-actor snapshot/reference abstraction;
- provenance validity must not depend on the continued existence of a Krayin user row;
- if retaining hard FKs, explicitly justify the replacement/deletion migration contract and stop calling them soft references.

Reconcile every affected schema row and §18.

### F13 — Current-state duplication must have one clear cache contract

`sca_eyewear_items` stores `lifecycle_state` and `registry_status`, while `sca_item_current_state` also stores those mirrors. Both are described as derived/rebuildable.

Two writable cache locations for the same derived values create avoidable drift risk.

Required correction:

- choose one canonical current-state projection location for lifecycle/registry status, preferably `sca_item_current_state`;
- if fields remain duplicated on `sca_eyewear_items`, explicitly define them as denormalized read caches updated atomically from the same transaction and included in drift checks; otherwise remove them from the proposed item table;
- the event log remains source of truth either way;
- update migration/schema/test language consistently.

### F14 — Reconcile stale task-report current-state wording

The task report still contains generation-0 current-state text such as:

- `PR: to be opened into main` even though PR #3 is already open;
- an `Unresolved questions` section and follow-on recommendation saying Q1-Q8 still require decisions, while generation 1 says those decisions are approved and encoded.

Historical notes may remain only if clearly labeled as historical. Current-state sections must not contradict the final design.

## Required Remediation Work

1. Pull latest `Shopify-Jeremy/main` and read this `NEXT_TASK.md`.
2. Stay on `design/sca-domain-design-003`; do not create another task branch.
3. Edit only:
   - `docs/SCA-DOMAIN-DESIGN.md`
   - `docs/task-reports/SCA-DOMAIN-DESIGN-003.md`
4. Resolve F9-F14 without changing the accepted generation-1 architecture except where required for integrity.
5. Keep the final authoritative entity/table list synchronized if fields or an SCA-owned actor/entitlement abstraction changes it.
6. Update migration order and test matrix as needed. Add at minimum tests for:
   - second QR activation without revoking/reissuing current active QR -> rejected;
   - QR event-log rebuild produces exactly the projection or flags integrity violation;
   - external-intake claim references the exact authorizing certification/entitlement for the same item;
   - source-type mismatch on claim (Shopify claim without sale link, external claim with wrong/no approved source) -> rejected;
   - completed and rejected claims are immutable;
   - rejected claim cannot be mutated to completed;
   - provenance remains valid if the referenced Krayin staff user is absent/replaced according to the chosen separability model;
   - duplicated current-state cache drift, if duplication is retained, is detected/rebuilt.
7. Update the task report with a clearly labeled remediation generation 2 section, exact architecture changes, commit SHAs, and correct current PR #3 status.
8. No migrations, models, services, controllers, UI, dependencies, Docker, middleware, Shopify connection, QR issuance, or real data.
9. Leave PR #3 open and unmerged.
10. STOP for ChatGPT re-audit. Do not start `SCA-DOMAIN-CORE-004`.

## Acceptance Criteria

PASS only if:

- QR canonical event history and projection cannot silently disagree about active QR;
- external-intake ownership claims retain immutable evidence of what authorized the claim;
- claim terminal states are explicit and immutable;
- Krayin staff attribution is genuinely consistent with the stated separability model;
- derived current-state caching has one coherent drift/rebuild contract;
- task report current-state wording is reconciled;
- generation-1 accepted decisions remain preserved;
- no implementation code is introduced;
- PR #3 remains open/unmerged.

## Prohibited Changes

Do not:

- merge PR #3;
- start `SCA-DOMAIN-CORE-004`;
- create migrations/models/services/controllers/UI;
- alter Krayin core/vendor;
- change Docker/dependencies/security middleware;
- connect Shopify or create real data;
- issue QR/certificates;
- expose the app publicly/change DNS;
- advance the task queue yourself;
- self-approve.

## Completion Rule

After pushing the design-only remediation to PR #3:

**STOP.**

Wait for ChatGPT re-audit.
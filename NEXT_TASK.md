# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-DOMAIN-DESIGN-003

**RETRY_GENERATION:** 1

## Title

Resolve SCA provenance design inconsistencies in PR #3 before domain implementation

## Implementer

Claude

## Authority

ChatGPT audited implementation PR #3 for `SCA-DOMAIN-DESIGN-003`.

The design direction is accepted in principle, but the document is not yet implementation-safe because several invariants contradict the proposed table behavior or leave ownership/claim semantics ambiguous.

Authoritative implementation repository:

`francisjonee/francisjonee-sca-platform-private`

Authoritative implementation PR:

`#3`

Continue on the existing branch:

`design/sca-domain-design-003`

PR #3 is open and must remain unmerged. This is still a DESIGN-ONLY task. Do not start `SCA-DOMAIN-CORE-004`.

## Accepted Design Direction — Preserve

Do not discard the strong parts of the current design:

- the physical frame is the canonical durable identity;
- SCA tables remain `sca_`-prefixed and separable from Krayin core/vendor;
- collectors are SCA-native, separate from Krayin staff users and Shopify customers;
- Shopify sale creates claim eligibility, not registered ownership;
- provenance/history is append-oriented and must not be silently rewritten;
- public passport uses an explicit allowlist and excludes PII/internal/Shopify identifiers;
- MariaDB 10.11 constraints must drive the schema instead of assuming PostgreSQL features;
- current-state projection may be used as a rebuildable transactional cache, never the sole provenance source;
- no migrations/models/UI/QR/Shopify implementation in this task.

## Audit Findings Requiring Remediation

### F1 — Certification model contradicts append-only semantics

The current design simultaneously says:

- issued/finalized certification history is immutable/append-only;
- `sca_certifications` has mutable `state`, `updated_at`, and a prior certification may be set to `superseded`.

Choose and document one coherent model. Preferred architecture:

- a certification row may be mutable only while `draft`;
- transition `draft -> issued` is one-way finalization;
- once issued, the certification row is immutable;
- later revocation/supersession must preserve the issued row and be represented by an explicit append-only mechanism, either a dedicated `sca_certification_events` table or a clearly-defined successor/version row whose relationship does not require updating the prior issued row;
- certification number/public identity must never change after issuance.

If adding a certification-event table is cleaner, the total table count may increase. Integrity is more important than preserving the original count of 13.

### F2 — QR lifecycle contradicts QR immutability

The design currently treats `sca_qr_identifiers` as both immutable provenance and a mutable lifecycle row (`reserved -> active -> revoked`).

Clarify the contract. Required invariant:

- `public_token` is permanently immutable;
- history of activation/revocation/reissue must never be lost;
- if row state is mutable, explicitly classify which fields/state transitions are narrowly mutable and why they are not provenance rewriting;
- preferred architecture is an immutable QR identity row plus append-only QR lifecycle/status events if that makes the invariant clearer;
- replacement QR activation must preserve the prior token/history.

### F3 — Current-state projection does not enforce owner uniqueness the way described

Correct the wording and constraints around `sca_item_current_state`.

A single projection row per item provides exactly one `current_owner_collector_id` slot for that item. Do NOT add `UNIQUE(current_owner_collector_id)`, because one collector may own many eyewear items.

Required design statement:

- PK/UNIQUE on `eyewear_item_id` guarantees one projection row per item;
- the owner field itself is a normal FK and may repeat across many item rows;
- one current owner per item is enforced by serialized transactional writes to the single item projection row plus ownership-event invariants;
- `UNIQUE(active_qr_identifier_id)` may be used to prevent one active QR row from being assigned to multiple items, but it is not the mechanism that creates one owner per item.

### F4 — `source_claim_id` is dangling/ambiguous

`sca_ownership_events.source_claim_id` currently references `claims/sale_link`, but no canonical claim table exists.

Resolve intentionally before migrations.

Preferred architecture: introduce an SCA-native claim entity/event because claim is a business event distinct from Shopify commerce. Define a table such as `sca_claims` or `sca_claim_events` with enough fields to audit:

- eyewear item;
- claimant collector;
- claim source/type (`shopify_sale`, `external_intake`, future approved source);
- optional source sale-link id;
- state/result;
- idempotency key/token where applicable;
- created/finalized timestamps;
- ownership event reference or transactional linkage.

Then `sca_ownership_events` should reference that exact claim record, not an ambiguous `claims/sale_link` target.

If you choose not to add a claim table, justify why and rename the FK unambiguously (for example `source_sale_link_id`), while proving external-intake claim auditability is still complete. Do not leave a polymorphic/dangling pseudo-FK.

### F5 — Shopify line-item uniqueness must be store-scoped

Do not assume Shopify numeric/reference IDs are globally unique across every Shopify shop SCA may ever integrate.

Add a canonical Shopify shop/store identifier to the linkage boundary and define composite uniqueness, for example:

`UNIQUE(shopify_shop_id, shopify_line_item_id)`

Also scope any order/webhook idempotency assumptions appropriately. The initial deployment may use one store, but the provenance schema should not bake in a false global-ID invariant.

### F6 — External-intake initial ownership authorization is underspecified

Make the non-Shopify path implementation-safe.

Accepted policy for this design:

- external intake does NOT automatically create ownership merely because someone submitted or paid for authentication;
- after authentication/certification, the authorized submitting/paying collector receives an explicit SCA claim entitlement/claim source;
- registered ownership is still created only by an explicit successful claim event;
- no Shopify sale link is required for that path;
- the claim model must therefore support both Shopify-backed and external-intake-backed eligibility without conflating them.

### F7 — Resolve the surfaced business decisions now where architecture can safely choose defaults

Use the following approved defaults in the design so `SCA-DOMAIN-CORE-004` does not have to invent them:

1. **External intake claim:** explicit claim entitlement after successful authentication/certification; never auto-register ownership.
2. **Post-claim Shopify refund/return:** never erase or auto-unregister ownership; record commerce reversal and raise `disputed` for staff resolution.
3. **Transfer expiry:** default 14 days, configurable; store concrete `expires_at` on each request.
4. **Frame serial:** advisory/non-unique by default; optional non-unique search index such as `(brand, frame_serial)` is allowed. No blanket unique constraint.
5. **Inspection media:** private by default; explicit per-asset public opt-in only.
6. **Collector PII deletion/privacy:** preserve de-identified provenance and ownership-event references; collector PII may be pseudonymized/anonymized subject to later legal/privacy implementation. Never delete provenance merely to delete PII.
7. **Certification identity:** use an opaque permanent public identifier/token as canonical security identity. A human-readable certificate number may exist as a display/reference number, but must not be the security boundary and must remain immutable after issue.
8. **QR reissue authority:** staff/admin only initially; activating a replacement must retire/revoke the previous active QR in the same transaction while preserving both histories.

If a genuinely legal/compliance-specific question still requires counsel or Jeremy input, keep it marked as an implementation/policy note, but do not leave the core schema unable to represent the approved safe behavior above.

### F8 — Reconcile every affected section, not just the table list

After changing the schema contract, update all dependent sections so the document has no stale contradictions:

- ER overview;
- table count and table-by-table schema;
- append-only invariants;
- authentication/certification state machines;
- QR lifecycle/reissue semantics;
- claim/ownership semantics;
- transfer semantics if claim references change;
- Shopify linkage/idempotency;
- migration order;
- integrity/concurrency section;
- test/invariant matrix;
- unresolved-decisions section;
- task report recommendations.

## Required Remediation Work

1. Pull latest `Shopify-Jeremy/main` and read this `NEXT_TASK.md`.
2. Stay on `design/sca-domain-design-003`; do not create a new task branch.
3. Edit only design/task-report documentation. No product code, migrations, models, services, controllers, UI, dependencies, Docker, security middleware, QR issuance, Shopify connection, or real data.
4. Resolve F1–F8 above in `docs/SCA-DOMAIN-DESIGN.md`.
5. Update `docs/task-reports/SCA-DOMAIN-DESIGN-003.md` with a clearly labeled remediation generation 1 section summarizing the changed architecture decisions, files changed, commit SHA(s), and PR #3 reference.
6. Explicitly state the final authoritative table/entity list after remediation. It may exceed 13 tables if claim/certification/QR event integrity requires it.
7. Expand/adjust the invariant test matrix to cover at minimum:
   - issued certification cannot be mutated;
   - certification revoke/supersede preserves original issued row;
   - QR token cannot change;
   - QR reissue preserves previous token/history and leaves exactly one active QR projection for the item;
   - one collector may own multiple items;
   - concurrent claims on one item yield one owner;
   - external-intake claim works without Shopify sale linkage but still requires explicit claim;
   - two Shopify shops may contain the same line-item id without collision;
   - post-claim refund cannot delete ownership;
   - public output remains PII-free after claim/transfer/status changes.
8. Keep PR #3 open and unmerged.
9. STOP for ChatGPT re-audit. Do not start `SCA-DOMAIN-CORE-004`.

## Acceptance Criteria

Return PASS only if:

- certification and QR history semantics are internally consistent with append-only provenance;
- the projection guarantees are technically accurate and do not prevent collectors owning multiple items;
- claim is modeled with an unambiguous auditable source for both Shopify and external intake;
- Shopify uniqueness/idempotency is store-scoped;
- the approved business defaults above are encoded into the design rather than left for the implementation task to invent;
- all dependent sections/migration order/tests are reconciled;
- the design remains separable from Krayin;
- no product implementation code is introduced;
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
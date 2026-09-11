# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-DOMAIN-DESIGN-003

## Title

Design the canonical SCA provenance domain schema, invariants, and lifecycle state machines

## Implementer

Claude

## Authority

ChatGPT accepted `SCA-KRAYIN-HARDEN-001` after final audit and merged implementation PR #2 into `francisjonee/francisjonee-sca-platform-private` main.

This task is DESIGN ONLY. It defines the data and lifecycle contract that the next implementation task must follow. Do not create product-domain migrations, models, controllers, UI, QR issuance, Shopify integration, collector authentication, or production infrastructure in this task.

Authoritative implementation repository:

`francisjonee/francisjonee-sca-platform-private`

Start from current `main`, including merge commit:

`96cf2d055c9615305a8d80b9c2c25f8899c1b105`

Create a new task branch using the task ID, e.g.:

`design/sca-domain-design-003`

## Product Contract

SCA is a permanent authentication, ownership, and provenance registry for collectible eyewear.

The physical frame is the durable identity. The collector account belongs to a person; the Digital Passport belongs to the physical frame. Shopify is commerce, not the ownership registry. Krayin is the staff operational shell, not the SCA business model.

For eyewear sold by Second Chance Eyewear, authentication and the SCA record exist before sale. A Shopify sale creates claim eligibility but does not itself create registered ownership. Registered ownership begins only after the eligible buyer scans the permanent SCA QR, authenticates to SCA, and successfully claims the frame.

For eyewear already owned by an external collector, a future paid authentication intake may create the SCA item/authentication/certification path without a Shopify sale.

Ownership, service, status, authentication, and certification history must preserve provenance. Historical events must not be overwritten as mutable CRM fields.

## Required Domain Concepts

At minimum, design the canonical purpose, identifiers, relationships, constraints, lifecycle, and privacy classification for:

- `eyewear_items`
- `authentications`
- `certifications`
- `qr_identifiers`
- `collector_accounts`
- `ownership_events`
- `transfer_requests` and/or `transfer_events`
- `service_events`
- `status_events`
- `shopify_sale_links`
- inspection/media references needed for authentication and condition evidence

You may recommend additional SCA-owned tables/value objects only when needed to preserve integrity or make lifecycle boundaries explicit. Do not substitute generic Krayin leads, contacts, activities, or custom fields for these concepts.

## Required Design Work

1. Inspect the accepted architecture, ADR-0006, roadmap, queue, prior task reports, and current implementation foundation before proposing schema.
2. Produce a domain-design document under `docs/` in the implementation repository. It must include an ER-style relationship description and a table-by-table schema proposal with key fields/types, primary keys, foreign keys, unique constraints, indexes, nullability, and delete/update behavior.
3. Define identifier policy. Distinguish internal database IDs from public permanent identifiers, certification numbers, QR tokens/paths, Shopify IDs, and collector identifiers. Permanent public IDs must not depend on a VPS hostname or mutable Shopify identifiers.
4. Define append-only provenance invariants. State exactly which records/events may never be updated or deleted after finalization, what corrections look like, and how current state is derived without destroying history.
5. Define the physical-item lifecycle from intake through authentication, certification, sale eligibility, claim, ownership, transfer, service, lost/stolen/recovered, and retirement/invalid states where applicable.
6. Define authentication and certification state machines separately. A failed/rejected authentication must remain historical evidence and must not silently become a successful certification record.
7. Define ownership semantics. A Shopify checkout/order/customer must never equal registered SCA ownership. Specify how initial claim and later transfer append ownership history, how one current owner is derived, and how unclaimed/sold/returned/refunded states interact with claim eligibility.
8. Define transfer state machine including initiation, acceptance, cancellation, expiry, rejection if needed, concurrency/idempotency rules, and the exact event that changes registered ownership.
9. Define status-event semantics for lost, stolen, recovered, disputed, retired, invalidated, or other justified registry states. Separate registry status from ownership.
10. Define service-event semantics so repairs, lens work, polishing, tune-ups, inspections, and similar lifecycle events accumulate without rewriting earlier condition/authentication history.
11. Define Shopify linkage boundaries and idempotency keys for future webhook processing. Include order, line-item, product/variant/SKU references where useful, but keep SCA physical identity canonical.
12. Define collector identity/privacy boundaries. Specify what may be public on the Digital Passport versus owner/staff-only data. Public provenance must not expose private PII or unnecessary Shopify/customer data.
13. Define media/document reference strategy for inspection photos and future certificates without storing binary blobs directly in core provenance tables. Account for future S3-compatible durable storage.
14. Define database integrity and concurrency requirements that should be enforced in MySQL/MariaDB where practical: uniqueness, foreign keys, immutable/finalized record protection strategy, transactions, locking/versioning, and idempotency.
15. Provide the proposed migration order for `SCA-DOMAIN-CORE-004`, but DO NOT create the migrations in this task.
16. Provide a test/invariant matrix for the next task. Include negative cases such as duplicate permanent IDs, two simultaneous owners, duplicate claim, replayed Shopify webhook, transfer races, mutation/deletion of finalized provenance, and invalid state transitions.
17. Explicitly list unresolved business decisions. Do not invent business policy where Jeremy/ChatGPT has not decided it. For each unresolved decision, state the safe default or implementation-blocking question.
18. Reconcile the design against Krayin upgradeability: SCA-owned tables/modules must remain separable from Krayin core/vendor and survive future Krayin update/replacement.

## Deliverables

Commit at minimum:

- `docs/SCA-DOMAIN-DESIGN.md`
- `docs/task-reports/SCA-DOMAIN-DESIGN-003.md`

The task report must record:

- files inspected;
- important Krayin/MySQL constraints discovered;
- design decisions and alternatives considered;
- unresolved questions;
- exact commit SHAs;
- no-code/scope confirmation;
- recommended follow-on notes for `SCA-DOMAIN-CORE-004`.

Make logical checkpoint commits rather than one giant final commit. Push the branch and open or provide the branch ready for an implementation PR into `main`. Leave it unmerged for ChatGPT audit.

## Standing Safety Gates

The accepted hardening report still prohibits real provenance/customer data and public exposure until its production prerequisites are closed. This design task may use documentation and synthetic examples only. Do not weaken or bypass those gates.

## Prohibited Changes

Do not:

- create or run SCA product-domain migrations;
- create production domain models/services/controllers/UI;
- alter Krayin core/vendor;
- change the accepted security middleware or dependency pins without a new audit finding;
- expose the application publicly or change DNS;
- connect the live Shopify store;
- create collector accounts or real provenance records;
- issue permanent QR codes/certificates;
- add real customer data;
- start `SCA-DOMAIN-CORE-004`;
- modify `TASK_QUEUE.md`, `ROADMAP.md`, or this task to self-advance;
- merge your own PR;
- self-approve.

## Acceptance Criteria

PASS only if the design is sufficiently exact that `SCA-DOMAIN-CORE-004` can implement migrations/models without inventing core ownership/provenance semantics; append-only history and current-state derivation are explicit; physical-item identity remains canonical; Shopify sale is separated from registered ownership; privacy/public boundaries are explicit; concurrency/idempotency/integrity rules are specified; unresolved business choices are clearly surfaced; no product-domain implementation is started; and the branch/PR remains unmerged for ChatGPT audit.

## Completion Rule

After committing the design and task report and pushing the task branch:

**STOP.**

Wait for ChatGPT audit. Do not begin domain implementation.

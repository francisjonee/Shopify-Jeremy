# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-DOMAIN-CORE-004

## Title

Implement the canonical SCA provenance domain core

## Implementer

Claude

## Last completed

`SCA-DEMO-IP-004` — PASS.

PR #4 merged into implementation `main` with merge commit:

`640f3d1b70066173f2e6bf681f819357c85396ce`

Post-merge VPS verification confirmed:

- deployed `HEAD == origin/main == 640f3d1b70066173f2e6bf681f819357c85396ce`;
- preview remains at `http://195.26.255.80:8080`;
- login/dashboard/Foundation/WIP banner pass;
- uploads/storage writable;
- MariaDB private;
- ports 80/443 and unrelated tenant untouched;
- `APP_ENV=production`, `APP_DEBUG=false`.

The governed preview rule now applies: Claude builds and pushes branches; ChatGPT owns PR creation/audit/merge; accepted `main` is then deployed to the same preview when application changes require it.

## Authority

The accepted domain design is:

`docs/SCA-DOMAIN-DESIGN.md`

in:

`francisjonee/francisjonee-sca-platform-private`

That document is authoritative for this task. Do not redesign the domain model during implementation unless a genuine implementation blocker is discovered. If a material contradiction/blocker appears, document it and STOP rather than silently changing architecture.

## Objective

Implement the accepted SCA provenance schema as real Laravel/Krayin-compatible application code with database migrations, models/domain services, database-level integrity enforcement, deterministic current-state behavior, and automated tests proving the accepted invariants.

This is a domain-core task only. Do not jump ahead into staff UI, authentication workflow screens, QR/public passport UI, Shopify integration, collector portal, transfers UI, or production cutover.

## Canonical domain tables

Implement the accepted 16-table model:

1. `sca_eyewear_items`
2. `sca_authentications`
3. `sca_certifications`
4. `sca_certification_events`
5. `sca_qr_identifiers`
6. `sca_qr_lifecycle_events`
7. `sca_collector_accounts`
8. `sca_claims`
9. `sca_ownership_events`
10. `sca_transfer_requests`
11. `sca_transfer_events`
12. `sca_service_events`
13. `sca_status_events`
14. `sca_shopify_sale_links`
15. `sca_media_assets`
16. `sca_item_current_state`

Also implement the integrity/immutability trigger set or equivalent database-enforced mechanism accepted by the design.

## Required invariants

At minimum preserve these accepted rules:

- issued certification rows are immutable; revoke/supersede via append-only certification events;
- QR identity is immutable; QR lifecycle is append-only;
- active QR consistency follows deterministic event fold order `(created_at, id)`;
- reissue is atomic: revoke old active QR, create replacement linkage/event sequence, repoint projection in one transaction;
- more than one active QR interval for an item is an integrity error;
- `sca_item_current_state` is the only canonical current lifecycle/registry projection and must be rebuildable from history;
- projection owner FK is not unique;
- ownership history is append-only and must never overwrite prior ownership events;
- claims are first-class records;
- claim lifecycle: `pending -> verified -> completed`, and `pending|verified -> rejected`;
- completed/rejected claims are terminal and immutable; retry after rejected requires a new claim;
- Shopify claims require the correct sale-link source path;
- external-intake claims require a valid source certification for the same item at claim time;
- source entitlement references are retained permanently;
- post-claim refund does not erase ownership history; disputed state is represented through status/event logic;
- Shopify line-item uniqueness is shop-scoped;
- frame serial is advisory/nonunique;
- media private by default; explicit public opt-in only;
- staff attribution uses soft historical refs with no hard DB FK to Krayin core users;
- collector PII pseudonymization must preserve deidentified provenance;
- certificate public opaque identifier is canonical; human-readable number is display-only;
- transfer expiry default is 14 days but configurable;
- temporary preview IP must not become a permanent QR/public identity base URL.

## Required Work

1. Pull latest `Shopify-Jeremy/main`, this `NEXT_TASK.md`, and implementation `main` before starting.
2. Create branch:

`feat/sca-domain-core-004`

3. Re-read `docs/SCA-DOMAIN-DESIGN.md` completely before writing migrations.
4. Implement version-controlled Laravel migrations for all 16 tables and required indexes/constraints/FKs.
5. Implement database-level immutability/integrity enforcement where the design requires history to be append-only or immutable after issuance/finalization.
6. Implement Laravel models and the minimum domain services/repositories needed to exercise the accepted lifecycle behavior cleanly. Keep SCA-owned code outside Krayin core/vendor packages.
7. Implement deterministic projection/rebuild logic for `sca_item_current_state` from canonical event history.
8. Implement transactional QR activation/reissue behavior with locking consistent with the accepted design.
9. Implement claim entitlement validation for Shopify vs external-intake sources.
10. Implement terminal claim-state enforcement and append-only ownership behavior.
11. Add automated tests covering the accepted T1–T31 matrix from the design. If one design test maps to multiple concrete tests, document the mapping.
12. Run a clean migration path on a disposable/test database and prove migrations apply successfully from the accepted base.
13. Test rollback strategy where safe/applicable. Do not use destructive rollback against the stakeholder preview database.
14. Run the full relevant application/domain test suite and capture exact results.
15. Run dependency/security checks already established for the project and record results; do not opportunistically upgrade unrelated packages unless required to make this task work.
16. Confirm no Krayin core/vendor modifications under `app/packages/Webkul/**` or tracked `app/vendor/**`.
17. Confirm no UI-first work, Shopify live connection, permanent QR generation, real customer/provenance data, DNS, or production-infrastructure changes were introduced.
18. Create/update:

`docs/task-reports/SCA-DOMAIN-CORE-004.md`

The report must include:
- exact implementation base SHA;
- migration/table/index/constraint summary;
- trigger/integrity enforcement summary;
- model/service summary;
- T1–T31 mapping with PASS/FAIL evidence;
- clean migration result;
- projection rebuild test evidence;
- QR atomicity/locking test evidence;
- claim entitlement and terminality test evidence;
- append-only ownership/certification evidence;
- security/dependency check results;
- known limitations/technical debt;
- exact changed-file list;
- exact branch head SHA;
- scope confirmation.

19. Make logical checkpoint commits throughout implementation. Do not collapse all work into one final commit.
20. Push branch `feat/sca-domain-core-004` to GitHub.
21. STOP after push and report the branch/head SHA, task-report path, tests, and any blockers. ChatGPT will create the PR and perform the audit/merge gate.

## Test / Acceptance Gate

PASS requires all of the following:

- all 16 canonical tables implemented;
- accepted indexes/uniqueness/FKs implemented correctly;
- accepted immutable/append-only behaviors enforced, not merely documented;
- deterministic `sca_item_current_state` rebuild works from history;
- QR active/reissue invariants enforced transactionally;
- claim source entitlement rules enforced;
- terminal claim states enforced;
- ownership history cannot be overwritten as a mutable owner field;
- certification event model preserves immutable issued certification rows;
- staff refs remain soft historical references to avoid Krayin-core FK coupling;
- media defaults private;
- Shopify line-item uniqueness is shop-scoped;
- T1–T31 accepted design matrix is implemented and passing or any unavoidable exception is explicitly documented as a blocker;
- clean migration on disposable/test DB succeeds;
- no SCA preview/production real data is destroyed;
- no Krayin core/vendor code is modified;
- no UI/Shopify/public-passport/collector-portal scope creep;
- no permanent QR URL derives from `195.26.255.80` or any temporary IP;
- task report is committed;
- branch is pushed for ChatGPT audit.

## Prohibited Changes

Do NOT:

- redesign the accepted 16-table architecture without stopping for architecture review;
- collapse provenance into generic Krayin CRM entities;
- add a mutable `current_owner` history replacement that bypasses ownership events;
- make collector accounts depend on Krayin staff/admin users;
- build staff UI beyond what is strictly required for automated/domain testing;
- connect live Shopify;
- create permanent public QR URLs;
- change DNS/domain configuration;
- add real customer/provenance data;
- expose MariaDB publicly;
- modify the unrelated production tenant;
- start `SCA-ADMIN-ITEMS-005` or any later queue task;
- create or merge the PR yourself under the normal workflow.

## Completion Rule

When complete, report only the implementation handoff:

1. branch name;
2. final branch head SHA;
3. task report path;
4. migration/test summary including T1–T31 result;
5. important findings/blockers;
6. confirmation everything is pushed.

Then STOP for ChatGPT audit.

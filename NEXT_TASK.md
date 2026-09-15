# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-ADMIN-ITEMS-005

## Title

Build the first SCA staff physical-eyewear intake, detail, and search workflow

## Implementer

Claude

## Last completed

`SCA-DOMAIN-CORE-004` — PASS.

PR #5 merged into implementation `main` with merge commit:

`0426bd6f9c9150b7ee728357e2c9c5830c75fc20`

Post-merge preview verification confirmed:

- deployed `HEAD == origin/main == 0426bd6f9c9150b7ee728357e2c9c5830c75fc20`;
- 17 provenance migrations applied;
- 16 canonical SCA provenance tables present;
- 22 integrity triggers present;
- existing Krayin data intact (60 base + 16 SCA tables);
- no real customer/provenance data present;
- preview/login/dashboard/Foundation/WIP banner healthy;
- storage writable;
- MariaDB private;
- ports 80/443 and unrelated tenant untouched.

Operational note: `scripts/deploy-preview.sh` lacks its executable bit; `bash scripts/deploy-preview.sh` works. Do not make an unrelated standalone change for this unless needed while touching that script in an approved task.

## Authority

Use the accepted SCA domain implementation on implementation `main` and `docs/SCA-DOMAIN-DESIGN.md` as the source of truth for physical-item fields and invariants.

Krayin is the staff operational shell. SCA remains the product/domain. Do not replace `sca_eyewear_items` with Krayin leads/products/contacts or duplicate canonical SCA provenance data into generic CRM entities.

## Objective

Create the first usable SCA staff workflow inside the existing authenticated Krayin admin experience so authorized staff can:

1. create a physical eyewear item;
2. view its SCA item detail;
3. search/filter existing eyewear items;
4. optionally record Shopify reference metadata already supported by the accepted item schema, without connecting to Shopify;
5. see enough current-state/provenance context to understand that this is a physical SCA registry record, not a generic CRM record.

This task should make visible progress on the living preview while remaining strictly an intake/search task. Authentication/grading, certification issuance, QR publication, collector ownership, and Shopify live integration are later tasks.

## Required Work

1. Pull latest `Shopify-Jeremy/main`, this `NEXT_TASK.md`, and implementation `main` before starting.
2. Create branch:

`feat/sca-admin-items-005`

3. Re-read the accepted item/domain schema before implementing UI. Do not invent a parallel item table.
4. Build SCA-owned staff/admin routes/controllers/services/views integrated into the authenticated Krayin admin shell. Keep SCA code under SCA-owned packages/modules; do not modify `app/packages/Webkul/**` or tracked vendor code.
5. Add an obvious SCA staff navigation entry for the eyewear registry/intake workflow using the supported extension mechanism rather than hard-editing Krayin core navigation.
6. Build an eyewear list/search page. At minimum support practical search/filtering by fields that exist in the accepted schema such as SCA public reference, brand, model, frame serial, and relevant optional Shopify/SKU references where available. Avoid unbounded or unsafe query construction.
7. Build a create/intake form using the canonical `sca_eyewear_items` fields. Validate required fields, lengths/types, accepted enum/state values where applicable, and normalize optional values appropriately.
8. Persist new items through SCA-owned application/domain logic. Do not bypass accepted database constraints/invariants.
9. Generate any SCA item `public_ref` through the established SCA token/reference mechanism rather than user-entered arbitrary identity.
10. Build an item detail page showing the canonical physical-item data and appropriate read-only current-state/provenance summary if available. Empty provenance should be represented clearly for newly created items.
11. Staff/admin pages must require authenticated Krayin staff access. Verify unauthenticated access redirects/rejects appropriately.
12. Respect Krayin authorization/permissions. Do not assume every authenticated staff role should automatically gain destructive or administrative access. Document the permission strategy and test at least an authorized vs unauthorized/restricted path if the current Krayin role model supports it.
13. Do not add hard-delete behavior for physical SCA items. Provenance records must not become disposable CRM rows. If no delete workflow is required, omit delete entirely.
14. Add automated feature/integration tests covering at minimum:
    - unauthenticated access protection;
    - authorized list page;
    - create form display;
    - successful valid item creation;
    - generated unique public reference;
    - validation failure does not create an item;
    - duplicate/advisory frame serial behavior remains allowed according to accepted design;
    - search by public ref;
    - search by brand/model;
    - search by frame serial;
    - item detail displays the correct item;
    - one item cannot expose another item's data through route/query mistakes;
    - no hard-delete staff action is exposed;
    - existing provenance-domain tests remain passing.
15. Test against a disposable/test database. Do not seed real customer/provenance data into the living preview as part of implementation/testing.
16. Run the full relevant test suite including the accepted provenance-domain suite and capture exact results.
17. Run `composer validate` and `composer audit` and record results.
18. Confirm no Krayin core/vendor changes, no live Shopify connection, no QR/permanent URL generation, no collector portal, no authentication/certification workflow scope creep, no DNS/infrastructure changes, and no real customer data.
19. Create/update:

`docs/task-reports/SCA-ADMIN-ITEMS-005.md`

The report must include:
- exact implementation base SHA;
- routes/controllers/services/views/navigation changed;
- exact item fields exposed for create/list/detail and why;
- permission/authentication strategy;
- validation rules;
- search/filter behavior;
- public-ref generation behavior;
- test mapping and exact PASS/FAIL results;
- regression result for provenance-domain tests;
- dependency/security checks;
- known limitations/technical debt;
- exact changed-file list;
- branch/head SHA;
- scope confirmation.
20. Make logical checkpoint commits throughout implementation.
21. Push `feat/sca-admin-items-005` to GitHub.
22. STOP after push. Do not create/merge a PR and do not start `SCA-ADMIN-AUTH-006`. ChatGPT owns PR creation, audit, merge, queue promotion, and post-merge deployment gate.

## Acceptance Gate

PASS requires:

- staff can create a real canonical `sca_eyewear_items` record through SCA-owned UI/application logic;
- staff can list/search and open the correct physical item detail;
- no duplicate/parallel item storage is introduced;
- generated SCA public reference is unique and not arbitrary user input;
- validation is enforced;
- unauthenticated access is blocked;
- authorization strategy is appropriate for staff roles and tested;
- no hard-delete UI/action is introduced;
- existing domain/provenance tests still pass;
- no Krayin core/vendor modification;
- no live Shopify connection;
- no certification/authentication/QR/collector workflow scope creep;
- no permanent identity URL derives from the temporary IP;
- task report is committed and branch pushed.

## Preview rule

Do not deploy the feature branch directly to the living preview. After Claude pushes and stops, ChatGPT audits it. Only accepted/merged implementation `main` may then be deployed to `http://195.26.255.80:8080`.

## Completion Rule

When complete, report only:

1. branch name;
2. final branch head SHA;
3. task report path;
4. test summary;
5. important findings/blockers;
6. confirmation everything is pushed.

Then STOP for ChatGPT audit.

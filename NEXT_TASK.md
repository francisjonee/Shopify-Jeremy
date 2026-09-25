# NEXT TASK

**STATUS:** ACTIVE — `SCA-STAFF-COLLECTOR-SUPPORT-040` implemented and pushed for ChatGPT audit (NOT merged, NOT deployed).

Feature branch `sca-staff-collector-support-040` pushed to the implementation repo from accepted base
`bd5b2e795c21c0828413554ac78f47216a982fa4`. Awaiting ChatGPT audit; must not be merged, deployed, or
promoted onward (SCA-041 must not start) until ChatGPT authorizes.

*Prior task `SCA-EXPANSION-PLANNING-039` is DONE (read-only audit accepted; roadmap + SCA-040 selection at
`docs/SCA-EXPANSION-PLANNING-039.md`). `SCA-PRODUCTION-CUTOVER` remains BLOCKED/DEFERRED awaiting Jeremy.*

## Title

SCA-STAFF-COLLECTOR-SUPPORT-040 — privacy-safe staff collector lookup and support view (read-only)

## Implementer

Claude

## Why this task now

The controlled pilot exposed a concrete operational failure: determining which collector an opaque
reference (`COL-…`) belonged to during ownership-correction testing required a raw database lookup. Normal
staff operations must not require DB/CLI access.

## Executable directive (as governed)

Add a staff-only, **read-only** collector-support search/list/detail workflow so authorized staff can
locate a collector by the opaque reference already used in staff workflows (e.g. `COL-87A586B3903E`) and
establish: collector reference; safe display label/name where permitted; account state; number of
currently owned items; the currently owned SCA items (SCA reference, brand/model, registry/certification
state); and links into the existing staff item-detail / ownership-history surfaces.

Before implementation, inspect the actual collector schema, existing privacy contracts, 018/032/033/035
behavior, current ACL vocabulary, and admin navigation/search conventions. Determine whether staff email
search/display is already authorized by the accepted privacy model before implementing it — do not assume.
Fail closed and STOP if the requested surface would violate an accepted privacy contract.

**Privacy boundary:** authenticated staff support surface only (not public/collector directory). Must not
expose password hashes; reset/claim/transfer/grant tokens; QR public tokens; Shopify customer/order ids
(unless an already-accepted staff requirement needs them); deleted/pseudonymized PII contrary to 018;
unnecessary internal identifiers. Public passport and collector privacy behavior remain unchanged.
Pseudonymized/anonymized collectors keep the 018 contract; do not reconstruct deleted PII from provenance.

**Read-only hard boundary:** zero business-domain mutation — no collector editing, email/name change,
staff password reset, account enable/disable, ownership correction, claim issue/revoke, transfer,
certification/status change, deletion/anonymization, provenance append, or schema migration (STOP for
review if inspection finds an unavoidable schema need). Reuse existing dedicated workflows for actions.

**ACL:** do not reuse an ownership-changing permission. Choose the smallest semantically-correct staff
read permission (reuse an existing collector/support/view permission if one exists; else a dedicated read
permission). Search/list/detail all fail closed; collector/public auth never grants access; unknown
references use the established safe not-found behavior.

**Search:** deliberately small; no generic CRM-wide people search; prefer exact/controlled lookup over
fuzzy PII search; bounded/paginated if it can return multiple records.

**Provenance:** ownership/certification/status shown must derive from the canonical current-state
projection/ledger, never a newly invented owner relationship or duplicated support table.

**Tests:** authorized staff locate by opaque reference; collector/public/unauthenticated cannot access;
unknown collector fails safely; owned items correct after claim; ownership updates after transfer;
ownership correction reflected without support-view mutation; previous owner not shown as current;
pseudonymized privacy preserved; sensitive tokens/secrets/internal fields never render; GET/search/detail
zero mutation; item links use existing staff routes; public passport / My Collection unchanged. Run
focused + full `tests/Feature/Sca` + validation/audit/lint/secret checks.

## Completion state (recorded)

Implemented on branch `sca-staff-collector-support-040` (base `bd5b2e7`). Routes: `GET admin/sca/collectors`
(exact `COL-…` lookup) + `GET admin/sca/collectors/{ref}` (detail), both `sca.can:sca.collector.support`
(new dedicated read ACL). **Email withheld** (no accepted staff-display precedent → not authorized).
Owned items from the canonical `current_owner_collector_id` projection. No schema migration. Focused
`CollectorSupportTest` 11/53; full SCA suite 509/2166. Full evidence in
`docs/task-reports/SCA-STAFF-COLLECTOR-SUPPORT-040.md` (implementation repo). **Push only — awaiting ChatGPT
audit before any merge/deploy. SCA-041 must not start.**

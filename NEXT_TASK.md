# NEXT TASK

**STATUS:** ACTIVE — `SCA-ITEM-METADATA-CORRECTION-046` implemented and pushed for ChatGPT audit (NOT merged, NOT deployed, production NOT migrated).

Feature branch `sca-item-metadata-correction-046` pushed to the implementation repo from accepted base
`17854a86f12d16485c7eb05ffa5418d7036a8eee`. Awaiting ChatGPT audit; must not be merged, deployed, or
promoted onward (SCA-047 must not start) until ChatGPT authorizes.

*Prior task `SCA-CERTIFICATE-SNAPSHOT-VERSIONING-045` is DONE (deployed `17854a8`). `SCA-PRODUCTION-CUTOVER`
remains BLOCKED/DEFERRED awaiting Jeremy.*

## Title

SCA-ITEM-METADATA-CORRECTION-046 — append-only correction of eyewear identity metadata

## Executable directive (as governed)

Support append-only correction of the 5 always-correctable fields (`frame_serial`, `year`,
`country_of_origin`, `materials`, `original_specifications`) for all items, plus `brand`/`model_name` only
when the item has no current certification OR its current certification has an SCA-045 snapshot; reject
brand/model change for a snapshot-less legacy certification (no reconstruction, no PDF render). Mixed
unsafe+safe requests fail atomically. Append one `sca_item_metadata_events` row per changed field (grouped
by correction_group_id; field CHECK-restricted; append-only triggers); item row is the current projection.
Atomic service (lock item-state, stale guard = metadata-event count, NOOP rejection). Dedicated
`sca.eyewear.metadata.correct` ACL; staff item-detail GET-confirm + POST workflow; typed `CORRECT`
confirmation; mandatory reason; SCA-044 validation reused. Correction reasons/actor/old-values staff-only.
Snapshotted certificate + PDF + checksum + certification history untouched; broad provenance isolation.
Additive migration only; disposable-DB migration only; no production migration/backfill.

## Completion state (recorded)

Implemented on branch `sca-item-metadata-correction-046` (base `17854a8`). New migration
`2026_09_28_000003_create_sca_item_metadata_events` (ran only on the disposable test DB; **production not
migrated** — table absent, migration recorded 0×). New `ItemMetadataCorrectionService` +
`ItemMetadataCorrectionRejection` + `ItemMetadataCorrectionRequest` + `ItemMetadataCorrectionController` +
`metadata-correct.blade`; ACL `sca.eyewear.metadata.correct`; routes + item-detail entry point; SCA-044
`m12` test updated (046 adds the correction route it previously asserted absent). Focused
`ItemMetadataCorrectionTest` 18/93; full SCA suite 575/3099. Full evidence in
`docs/task-reports/SCA-ITEM-METADATA-CORRECTION-046.md` (implementation repo). Legacy brand/model
reconstruction remains a **separate future prerequisite** task. **Push only — awaiting ChatGPT audit before
any merge/deploy/migration. SCA-047 must not start.**

# NEXT TASK

**STATUS:** ACTIVE — `SCA-MY-COLLECTION-ENRICHMENT-042` implemented and pushed for ChatGPT audit (NOT merged, NOT deployed).

Feature branch `sca-my-collection-enrichment-042` pushed to the implementation repo from accepted base
`223cc40a8928af9b70ff2ab711b18c3fa4c31b38`. Awaiting ChatGPT audit; must not be merged, deployed, or
promoted onward (SCA-043 must not start) until ChatGPT authorizes.

*Prior task `SCA-COLLECTOR-PASSPORT-ACCESS-041` is DONE (deployed `223cc40`). `SCA-PRODUCTION-CUTOVER`
remains BLOCKED/DEFERRED awaiting Jeremy; it does not block application development.*

## Title

SCA-MY-COLLECTION-ENRICHMENT-042 — collector certificate-document current/historical classification

## Implementer

Claude

## Why this task now

Pilot validation exposed a concrete ambiguity: the collector sees an immutable certificate PDF belonging to
a predecessor certification without being told it is historical, while the item shows the newer current
certification. Fixed by classifying certificate documents **at read time** from existing certification
linkage + the canonical current-certification projection — no evidence is regenerated, deleted, mutated, or
hidden.

## Executable directive (as governed)

On the collector-owned item detail page, certificate PDFs must identify **Current certificate** vs
**Superseded / historical certificate**, derived from `subject_type='certification'` + the media asset's
`subject_id` vs the item's canonical `current_certification_id` (not persisted). Where safely available,
show the document's **public** certification number. Never render `subject_id` or any internal id.

Critical evidence rules: do not modify/delete/replace the predecessor PDF; do not alter its `is_public`
merely because superseded; do not generate a successor PDF; do not change certificate generation or
supersede/revoke behavior; do not mutate certification/media/provenance. If both current and historical PDFs
exist, both remain available to the authorized current owner and are distinguishable; if only a historical
PDF exists (present pilot condition), show it explicitly as historical and never imply a current PDF exists.

Authorization/privacy: preserve the current-owner boundary of My Collection; expose only already-authorized
document info + safe derived classification + optional public certification number; never internal/media
ids, `subject_id`, storage paths, checksums, QR/claim/reset/transfer/grant tokens, staff identity,
correction/supersede reasons, or previous-owner PII; do not broaden `is_public`/current-owner visibility.

Boundary: prefer modifying only the collector document read model/service + item-detail presentation +
focused tests/report. No schema/migration expected. Full non-goals: no successor/auto PDF generation, no
certification/authentication/ownership/transfer/registry-status history, no insurance report, no
notifications, no new schema, no domain/cutover work.

Tests (focused + full `tests/Feature/Sca` + php lint + composer validate/audit + secret scan) prove the
classification, coexistence, pilot condition, download authorization, privacy (no ids/paths/checksums/
tokens), zero mutation, and unchanged SCA-041 passport behavior.

## Completion state (recorded)

Implemented on branch `sca-my-collection-enrichment-042` (base `223cc40`). Changed the collector document
read model (`CollectionService::visibleDocumentsForOwnedItem`, constructor-injected `ProjectionService`) +
`collection/show.blade.php` + focused test + report. **No schema migration; no PDF generated; no evidence
mutated.** Focused `CertificateDocumentClassificationTest` 11/33; full SCA suite 532/2231. Full evidence in
`docs/task-reports/SCA-MY-COLLECTION-ENRICHMENT-042.md` (implementation repo). **Push only — awaiting ChatGPT
audit before any merge/deploy. SCA-043 must not start.**

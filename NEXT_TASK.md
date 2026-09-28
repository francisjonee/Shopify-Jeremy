# NEXT TASK

**STATUS:** ACTIVE — `SCA-CERTIFICATE-SNAPSHOT-VERSIONING-045` implemented and pushed for ChatGPT audit (NOT merged, NOT deployed, production NOT migrated).

Feature branch `sca-certificate-snapshot-versioning-045` pushed to the implementation repo from accepted base
`fdf8595828e618b8a65742134836c2e914c67d3e`. Awaiting ChatGPT audit; must not be merged, deployed, or
promoted onward (SCA-046 must not start) until ChatGPT authorizes.

*Prior task `SCA-EYEWEAR-METADATA-EXPANSION-044` Slice 1 is DONE (deployed `fdf8595`). `SCA-PRODUCTION-CUTOVER`
remains BLOCKED/DEFERRED awaiting Jeremy.*

## Title

SCA-CERTIFICATE-SNAPSHOT-VERSIONING-045 — per-certification immutable render snapshot + template versioning

## Executable directive (as governed)

Add an append-only `sca_certificate_snapshots` table (one row per certification, UNIQUE `certification_id`)
holding only the certificate render inputs (item public_ref, certification number/date, the certification's
opaque token, brand, model, condition grade+label, authentication date) plus `template_version`, `source`,
`captured_at`, and a deterministic `snapshot_checksum`; no owner/PII, registry status, correction reason,
staff identity, QR token, or frame_serial. Every newly issued certification (first issue AND SCA-038
supersede successor) captures exactly one snapshot in the same transaction (data only; capture failure rolls
back issuance; no PDF rendered in-transaction). Revoke touches no snapshot. Preserve today's semantics as
template `v1` via an explicit version→renderer map (unknown version fails closed). `CertificatePdfService`
renders EXCLUSIVELY from the frozen snapshot when present (never re-reading current brand/model/etc.), with a
v1 live-read fallback for grandfathered pre-045 certs; repeated generation idempotent; missing-file repair
reproduces the stored checksum from the snapshot. No production backfill; no snapshot public exposure;
QR/ownership/status/claim/transfer and SCA-042/043/044 behavior preserved.

## Completion state (recorded)

Implemented on branch `sca-certificate-snapshot-versioning-045` (base `fdf8595`). New migration
`2026_09_28_000002_create_sca_certificate_snapshots` (append-only triggers; UNIQUE certification_id) — ran
**only** on the disposable test DB; **production not migrated** (`sca_certificate_snapshots` absent). New
`CertificateSnapshotService`; capture wired into `CertificationService::issue` +
`CertificationCorrectionService::supersede`; `CertificatePdfService` version dispatch +
render-from-snapshot/legacy fallback; `CertificateRejection::UNKNOWN_TEMPLATE_VERSION`. Focused
`CertificateSnapshotTest` 12/714; full SCA suite 557/3001. Full evidence in
`docs/task-reports/SCA-CERTIFICATE-SNAPSHOT-VERSIONING-045.md` (implementation repo). This unlocks the future
append-only metadata-correction slice. **Push only — awaiting ChatGPT audit before any merge/deploy/migration.
SCA-046 must not start.**

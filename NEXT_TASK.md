# NEXT TASK

**STATUS:** NONE — no executable task is authorized.

`SCA-CERTIFICATE-SNAPSHOT-VERSIONING-045` is **DONE** (ChatGPT-audited, governed `--no-ff` merge, and deployed
to production `main` at `17854a86f12d16485c7eb05ffa5418d7036a8eee`; base `fdf8595`, feature HEAD `c5aeb95`).
Every newly issued certification (first issue AND SCA-038 supersede successor) now freezes an immutable
per-certification render snapshot in the issuing transaction; the certificate PDF is generated/repaired from
the frozen snapshot (v1 template dispatch; unknown version fails closed), with a v1 live-read fallback for
grandfathered pre-045 certifications. This unlocks the future append-only metadata-correction slice.

## Deployment evidence
- SHAs: base `fdf8595` → feature `c5aeb95` → **merge/deployed `17854a8`** (MERGE == ORIGIN == DEPLOYED).
- Deploy test gate: `CertificateSnapshotTest` 12 passed / 714 assertions; full `tests/Feature/Sca` 557 passed
  / 3001 assertions. Pre-merge included an independent base↔candidate v1 PDF byte comparison (identical
  checksum) and a forced-capture-failure rollback proof.
- **Production migration** `2026_09_28_000002_create_sca_certificate_snapshots` applied **exactly once**
  (batch 9): table created with PRIMARY, UNIQUE(`certification_id`), FK→`sca_certifications`,
  CHECK(`chk_cert_snapshot_source`), and both append-only triggers (`_no_update`, `_no_delete`).
- **Legacy boundary honored: ZERO snapshot rows created** for the existing production certifications (no
  backfill, no reconstruction).
- Before/after production baseline **identical** apart from the new empty table + migration record:
  certifications, cert events, media assets **and their checksums** (`0f74aee3…`, `bc01e71e…`), QR
  identifiers/lifecycle, ownership/claims/transfers/status, collectors, item metadata, and current-cert
  projections all unchanged (count/fingerprint verified). No production PDF generated or repaired.
- Post-deploy (non-mutating): certified public passport, staff/collector login all healthy; SCA-043
  `admin.sca.certificate.generate` route present; no snapshot endpoint exists; existing media/checksums
  unchanged. SCA-042 classification and SCA-044 metadata behavior intact.

## Accepted limitation (recorded)
`snapshot_checksum` is currently stored as **tamper-evidence only — it is NOT revalidated during
rendering/repair**. Snapshot-row integrity is enforced by the append-only triggers; PDF-byte integrity by
the media checksum on repair. Any future consumption-time snapshot-checksum validation would be a separate
task.

`SCA-PRODUCTION-CUTOVER` remains **BLOCKED/DEFERRED** awaiting Jeremy.

*Full evidence: implementation report `docs/task-reports/SCA-CERTIFICATE-SNAPSHOT-VERSIONING-045.md`.*

ChatGPT promotes exactly one next task here when ready. **SCA-046 is not activated.**

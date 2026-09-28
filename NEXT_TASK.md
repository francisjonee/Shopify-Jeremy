# NEXT TASK

**STATUS:** NONE — no executable task is authorized.

`SCA-EYEWEAR-METADATA-EXPANSION-044` (Slice 1) is **DONE** (ChatGPT-audited, governed `--no-ff` merge, and
deployed to production `main` at `fdf8595828e618b8a65742134836c2e914c67d3e`; base `50c54ad`, feature HEAD
`1be55a9`). Nullable current-item identity metadata (`year`, `country_of_origin`, `materials`,
`original_specifications`) is now captured at intake and shown on staff detail + collector My Collection;
the public passport exposes `year`/`country_of_origin`/`materials` only (`original_specifications` is
owner/staff-only; `frame_serial` stays sensitive). The certificate PDF is unchanged. Create-time only — no
edit/correction path, no metadata ledger, no certificate snapshotting.

## Deployment evidence
- SHAs: base `50c54ad` → feature `1be55a9` → **merge/deployed `fdf8595`** (MERGE == ORIGIN == DEPLOYED).
- Deploy test gate: `EyewearMetadataTest` 13 passed / 56 assertions; full `tests/Feature/Sca` 545 passed /
  2287 assertions.
- **Production migration** `2026_09_28_000001_add_metadata_to_sca_eyewear_items` applied **exactly once**
  (batch 8): `sca_eyewear_items` now = original 8 columns + nullable `year` (smallint), `country_of_origin`
  (varchar 100), `materials` (varchar 255), `original_specifications` (text). No unrelated schema change.
- Existing production items intact: both items have **NULL** for all four new fields; the item-content
  fingerprint is identical before/after; provenance/domain baseline (items, certifications, cert_events,
  media_assets, ownership, claims, transfers, QR, qr_lifecycle, status, collectors) is **identical**
  before/after — no values/history/media altered. No backfill.
- Post-deploy health (non-destructive): staff/collector logins and the certified pilot passport all 200;
  passport exposes no `original_specifications`/`frame_serial`; certificate PDFs/media untouched.

`SCA-PRODUCTION-CUTOVER` remains **BLOCKED/DEFERRED** awaiting Jeremy.

*Full evidence: implementation report `docs/task-reports/SCA-EYEWEAR-METADATA-EXPANSION-044.md`. Later slices
(certificate per-cert snapshot-freezing; append-only metadata correction) remain planned, not active.*

ChatGPT promotes exactly one next task here when ready. **SCA-045 is not activated.**

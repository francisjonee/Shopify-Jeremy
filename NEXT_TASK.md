# NEXT TASK

**STATUS:** ACTIVE — `SCA-EYEWEAR-METADATA-EXPANSION-044` (Slice 1) implemented and pushed for ChatGPT audit (NOT merged, NOT deployed).

Feature branch `sca-eyewear-metadata-expansion-044` pushed to the implementation repo from accepted base
`50c54ad2ce0afe8f993e11d8b1979e5d667c7935`. Awaiting ChatGPT audit; must not be merged, deployed, or
promoted onward (SCA-045 must not start) until ChatGPT authorizes.

*Prior tasks 042/043 are DONE. `SCA-PRODUCTION-CUTOVER` remains BLOCKED/DEFERRED awaiting Jeremy; it does not
block application development.*

## Title

SCA-EYEWEAR-METADATA-EXPANSION-044 (Slice 1) — additive nullable current-item identity metadata

## Implementer

Claude

## Executable directive (as governed — Slice 1 only)

Add four nullable current-item metadata fields — `year`, `country_of_origin`, `materials`,
`original_specifications` — to `sca_eyewear_items` via an additive migration (all nullable, no backfill,
bounded scalar types, no JSON), preserving the existing brand/model_name/frame_serial/intake_type identity
model. Extend the existing staff intake to optionally capture them with explicit bounded validation (year
validated as a plausible year that does not block vintage eyewear; sensible length limits on the rest); add
**no** UPDATE/edit/correction route. Display the four on staff item detail and (as current facts) in
collector My Collection, gracefully omitting NULLs. Extend `PublicAllowlist` deliberately so the public
passport exposes `year`/`country_of_origin`/`materials` only; **do NOT expose `original_specifications`
publicly** (staff/owner-visible only); `frame_serial` remains sensitive/non-public. **Do NOT modify the
certificate PDF template or `CertificatePdfService`** — existing certificate PDFs and deterministic
repair/checksum behavior stay byte-compatible.

Invariants: create-time metadata only; no destructive item editing; no `sca_item_metadata_events`; no
metadata correction; no certificate snapshotting/template versioning; authentication observations
(condition/grade/findings/inspection) stay on authentication records; NULL-metadata items behave normally;
QR/certification/ownership/registry-status/transfer/claim/passport behavior unchanged; no backfill of
production records.

## Completion state (recorded)

Implemented on branch `sca-eyewear-metadata-expansion-044` (base `50c54ad`). Migration
`2026_09_28_000001_add_metadata_to_sca_eyewear_items` (additive nullable columns; ran only on the disposable
test DB — **production schema untouched**). Public passport exposes year/country/materials only;
original_specifications is owner/staff-only; frame_serial stays sensitive. Certificate PDF untouched. Focused
`EyewearMetadataTest` 13/56; full SCA suite 545/2287. Full evidence in
`docs/task-reports/SCA-EYEWEAR-METADATA-EXPANSION-044.md` (implementation repo). **Push only — awaiting ChatGPT
audit before any merge/deploy. SCA-045 must not start.**

# SCA — Pending Correctness Defects

Open defects discovered during audits/reviews, recorded so they are not lost. Each must be scheduled as (or
folded into) a governed task; none is fixed except through the normal governed flow.

---

## DEFECT-001 — Collector "✓" authenticity badge shows green on revoked/uncertified items

- **Discovered:** SCA-050 product/operations audit (deployed `ec2b2ef`).
- **Where:** `app/packages/Sca/Collector/src/Resources/views/collection/show.blade.php` — the top authenticity
  badge is hard-coded green with a "✓". `CollectionService::detail` sets `authenticity_status` to `'Recorded'`
  when the item is uncertified OR its current certification was **revoked** (`current_certification_id` null).
- **Symptom:** a revoked/uncertified owned item still renders a green "✓ Recorded" badge, directly
  contradicting the SCA-048 "This item currently has no active certification." notice a few rows below on the
  same page. It **overstates authenticity** and undercuts the SCA-048 honesty fix.
- **Correct behavior:** the badge must be neutral/greyed (no ✓, non-green) when the item is not currently
  certified; green ✓ only when there is a current issued certification.
- **Scope/risk:** view-only fix, trivial, low risk, read-only, no schema.
- **Status:** OPEN. Explicitly **NOT** fixed in SCA-051 (per the SCA-051 authorization). To be scheduled as its
  own small governed correctness task (or folded into a future collector-detail cleanup, e.g. the SCA-050 C2
  sectioning item).

# NEXT TASK

**STATUS: ACTIVE — SCA SERVICE / REPAIR HISTORY STAFF UX. Executable stage: DISCOVERY/PLAN ONLY (DONE, awaiting audit).**

Promoted 2026-10-06. Deployed baseline `1b029fd981388da76b66d50c7a851f3254aa1e5d`, migrations **120**, FP **`62b2e42fe409b4ec91f3381b35da819e`**. Shopify Operational Listing SOP remains CLOSED.

## Objective

Smallest complete staff workflow to record + view legitimate service/repair history while preserving append-only provenance.

## Current stage — DISCOVERY/PLAN (complete; STOP for audit)

Plan committed at `docs/SCA-SERVICE-REPAIR-HISTORY-STAFF-UX-DISCOVERY.md`. **Do not implement yet.** Verified findings:

- The staff **record + view workflow ALREADY EXISTS and is complete**: ACL-gated (`sca.eyewear.service`) "Record service" form (GET `…service.create` + POST `…service.store`) **and** a full service-history table on the item-detail History tab (Date/Type/Condition/Notes) + a count. Append-only (DB `no_update`/`no_delete` triggers), projection-untouched, owner-visible in My Collection, **never** on the public passport.
- `sca_service_events` fields: `service_type` (CHECK repair/lens/polish/tuneup/inspection/other), `performed_by_staff_ref` (soft), `condition_grade_after` (A–D observation), `notes`, `occurred_at`, `created_at` (no `updated_at`). **No cost/provider/condition-before/parts/media columns.**
- **No correction/void/supersede path** for a mistaken service event; **no service-evidence media UX** (schema permits `subject_type='service'` but nothing wires it).

## Recommendation — **Option E (existing functionality is sufficient)**

No new recording/viewing feature/route/service/schema is required; the item-context add-form + history table already deliver the complete staff workflow. **Closes with zero code.** One **optional**, view-only micro-polish is offered: add **Performer + Recorded-at** columns to the staff service-history table (staff-only; reuse `sca.eyewear.view`; no schema). Deferred (separate future slices, NOT this task): an append-only service **correction** semantic, and service-**evidence media** UX.

## Hard constraints

Append-only must hold — **no edit/delete of historical service events**. No Shopify/dashboard/QR/ownership/transfer/certification/SMTP/bulk-onboarding/analytics/infra change. No public/collector exposure change. **Prefer zero schema — none is required.**

## Stage gate

**Executable stage is DISCOVERY/PLAN ONLY — complete and committed. STOP for ChatGPT audit.** Either accept E (close immediately, no code) or approve the single optional view-only enrichment — **either closes Service/Repair History Staff UX with no follow-on slice.** Implementation (if any) is a separate promoted stage.

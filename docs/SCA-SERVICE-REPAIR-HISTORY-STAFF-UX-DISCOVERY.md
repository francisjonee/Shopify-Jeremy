# SCA Service / Repair History — Staff UX — discovery + plan (PLAN ONLY)

**Date:** 2026-10-06 · **Status: DISCOVERY/PLAN ONLY. No implementation-repo, production, DB, migration, or deployment change.** · Deployed baseline `1b029fd`, migrations **120**, FP `62b2e42f`. Promoted task; executable stage = DISCOVERY/PLAN ONLY. For ChatGPT audit.

**Goal:** smallest complete staff workflow to record + view legitimate service/repair history while preserving append-only provenance.

**Headline verdict: the staff record+view workflow ALREADY EXISTS and is complete (append-only form + full history table on item detail, ACL-gated). Recommend Option E — existing functionality is sufficient; NO new recording/viewing feature is required.** One optional, tiny, view-only staff-audit enrichment is offered (show performer + append-time on the staff table). Two genuine but out-of-scope gaps (no correction path; no service-evidence media UX) are documented as separate, evidence-gated future items — not part of "staff UX for recording/viewing."

---

## 1. Exact current service-event schema (`sca_service_events`, migration `2026_09_14_120013`)

| Column | Type | Null | Notes |
|---|---|---|---|
| `id` | bigIncrements | — | PK |
| `eyewear_item_id` | unsignedBigInteger | no | FK → `sca_eyewear_items.id` `restrictOnDelete`; indexed |
| `service_type` | string(24) | no | CHECK `chk_service_type` IN (`repair`,`lens`,`polish`,`tuneup`,`inspection`,`other`) |
| `performed_by_staff_ref` | unsignedBigInteger | yes | soft ref, **no FK** |
| `condition_grade_after` | string(8) | yes | observation only (A/B/C/D); "never rewrites auth" |
| `notes` | text | yes | free text |
| `occurred_at` | timestamp | no | when the service happened |
| `created_at` | timestamp (useCurrent) | — | append timestamp; **no `updated_at`** |

**Append-only DB triggers** (`2026_09_14_120017_create_sca_integrity_triggers`): `sca_service_events` is in `$immutableEventTables` → `trg_sca_service_events_no_update` + `trg_sca_service_events_no_delete` both `SIGNAL SQLSTATE '45000'`. Rows are pure-append at the storage layer.

**Fields that do NOT exist (do not invent):** no cost/price; no provider/vendor; no "condition before" (only `condition_grade_after`); no structured parts/work (only `notes`); no media/evidence column on the table.

## 2. Model + domain semantics
- **Model** `Models/ServiceEvent.php`: `$table='sca_service_events'`, `$guarded=[]`, `$timestamps=false`, no casts/relationships. (The record path uses the query builder, not the model.)
- **`ServiceService::record(int $itemId, string $serviceType, ?int $staffRef, ?string $conditionGradeAfter=null, ?string $notes=null, ?string $occurredAt=null): int`** — validates `service_type`∈TYPES and grade∈`A,B,C,D`, then a single `insertGetId`. **Append-only (insert only).** **Touches the projection NOT at all** — recording a service event changes no ownership/certification/authentication/lifecycle/`sca_item_current_state` (confirmed by test `v6`). `condition_grade_after` is an observation at service time; it never rewrites the authentication grade.
- **No correction/void/reverse/supersede path exists for service events** (correction services exist only for Certification, Ownership, and Item-metadata). A mistaken service event cannot be edited or removed today.

## 3. Append-only protections
DB triggers (no UPDATE/no DELETE, SQLSTATE 45000) + CHECK on `service_type`; the service layer only inserts. Tests `v5` (UPDATE/DELETE throw) and `v13` (DB CHECK rejects bad type) confirm.

## 4. Existing staff / collector / public UX

**Staff (already implemented):**
- Routes `admin.sca.eyewear.service.create` (GET) + `.store` (POST), prefix `sca/eyewear/{id}`, middleware `sca.can:sca.eyewear.service`.
- `ServiceController@create` renders `service/create.blade.php` (service_type select, occurred_at date, condition_grade_after A–D, notes ≤5000); `@store` validates via `StoreServiceRequest`, derives the performer from the session (`auth()->guard('user')->id()` — never client; test `v7`), calls `record(...)`, flashes "appended to the immutable service history", redirects to item detail. Missing item → 404.
- **Item-detail (`eyewear/show.blade.php`)** already shows: a **count** (`Service events` row) **and** a full **"Service history" section** in the History tab — a **"Record service" button** (gated `sca.eyewear.service`) + a **table of every event** (Date `occurred_at`, Type, Condition after, Notes), or "No service events recorded" when empty. Data loaded in `EyewearItemController::show` (`$services` ordered by `occurred_at desc, id desc`). **So staff can already add and view service history from item context.**
- ACL key `sca.eyewear.service` ("Record SCA Service Event").

**Collector (already implemented):** owner-only My Collection item view shows a "Service history" section (`CollectionService::serviceHistoryForOwnedItem` → selects only `service_type, condition_grade_after, notes, occurred_at` — no staff ref / internal ids / email; tests `v9`/`v10`/`v11`).

**Public Digital Passport: NOT exposed** (zero service references in the Passport package; test `v12` asserts service notes are not shown).

**Media/evidence:** `sca_media_assets` CHECK permits `subject_type='service'`, so the data model *could* link evidence to a service event — but **no service-layer or UX code attaches/reads media for service events today** (the staff "documents" list queries media by `eyewear_item_id` only, not by service subject).

## 5. Operational flow today (traced) — already works
item → **inspect service history** (History tab table) → **record service/repair** ("Record service" → create form → store) → **verify event** (redirect to item detail; the new row appears in the table) → **later view provenance** (same table; owner also sees it in My Collection). Each step is implemented, ACL-gated, append-only, and does not touch provenance/projection.

## 6. Actual operational gaps
1. **(Core workflow) NONE.** Recording and viewing are complete and discoverable from item context. There is **no missing record/view UI**.
2. **(Out-of-scope gap) No correction path** for a mistaken service event — append-only with no supersede/void. Per the provenance rule, the fix must NOT be ordinary edit/delete; it would require a **new append-only correction/annotation semantic** (a distinct future feature), not part of "staff UX for recording/viewing."
3. **(Optional gap) No service-evidence media UX** — schema-ready (`subject_type='service'`) but unwired. A future optional enhancement; not required for record/view.
4. **(Optional micro-polish) Staff history table omits the performer + append time.** The staff table shows occurred_at/type/condition/notes but not `performed_by_staff_ref` or `created_at`, which exist in the data and are legitimately staff-relevant for audit/accountability (the collector view deliberately hides them; the staff view may show them).

## 7. Recommended smallest complete workflow — **Option E (sufficient), with one optional micro-polish**

- **Primary recommendation: E — existing functionality is already sufficient.** The item-context add-form + full history table already deliver the complete staff record+view workflow, append-only and ACL-gated. **No new recording/viewing feature, route, service, or schema is required to satisfy the stated goal.** This closes the task with zero code.
- **Optional micro-polish (only if the operator wants richer staff-side audit visibility):** a **view-only** enrichment of the staff item-detail service-history table to also display the **performer** (`performed_by_staff_ref`) and the **recorded-at** (`created_at`) columns. Read-only, reuses existing data + the `sca.eyewear.view` gate on item detail, **no schema, no new route/service**. This is the single smallest possible improvement; it is **not required** for closure. (It must remain staff-only — the collector view and public passport stay as-is.)
- **Not recommended:** a dedicated service-history page (item-context is sufficient; no evidence of need); any edit/delete of historical events (violates append-only); building service-evidence media UX or a correction semantic within this task (separate, larger, evidence-gated).

Preferred decision order: **E (close as-is)**, or **E + the optional performer/recorded-at columns** if the operator wants staff audit visibility.

## 8. If the optional micro-polish is approved — exact files / ACL / tests
- **Modified (1):** `packages/Sca/Registry/src/Resources/views/eyewear/show.blade.php` — add Performer + Recorded-at columns to the existing staff "Service history" table (values already loaded or trivially added to the existing `$services` query select; if the select must widen, that is a read-only query change in `EyewearItemController::show` — **no schema**). Decide at implementation whether `$services` already carries the fields; if not, widen the existing select only.
- **New (1):** `tests/Feature/Sca/ServiceHistoryStaffColumnsTest.php` (or extend `ServiceHistoryTest`) — staff item-detail shows performer + recorded-at for an event; collector My Collection still does NOT (no staff ref leak); public passport unchanged; zero provenance mutation; append-only unaffected.
- **ACL:** existing `sca.eyewear.view` (item detail) + `sca.eyewear.service` (record) — unchanged, no new key.
- **No** controller logic change beyond (possibly) widening a read-only select; no route/schema/migration/service change.

## 9. Correction / error-handling semantics (gap, provenance-safe recommendation)
Today a wrong service event is permanent (append-only, no supersede). **Do NOT make service events editable/deletable.** If/when correction is genuinely needed, the smallest provenance-safe approach mirrors the existing append-only correction pattern (Certification/Ownership/Metadata): an **appended** correction/annotation record that references the prior event id (e.g. a `corrects_service_event_id` or a note-type service event), leaving the original row intact. This is a **separate future slice** with its own discovery (it introduces new semantics and possibly a nullable column) — **explicitly deferred; not part of this task.**

## 10. Schema changes required? — **NONE**
The existing `sca_service_events` fully supports the current (complete) record+view workflow and the optional performer/recorded-at display. No migration.

## 11. Test matrix (only if the optional micro-polish is built)
Staff item detail shows performer + recorded-at for a recorded event; collector view still omits staff ref/internal ids (no leak); public passport still omits service history; append-only + projection-untouched invariants unchanged; full `tests/Feature/Sca` green; migrations 120.

## 12. Explicit scope exclusions
No Shopify changes; no dashboard/worklist reopening; no QR/ownership/transfer/certification change; no SMTP/notifications; no bulk inventory onboarding; no reporting/analytics; no infrastructure; **no edit/delete of historical service events**; no service-correction semantic in this task; no service-evidence media UX in this task; no public/collector exposure change. **Prefer zero schema — none is required.**

## 13. Does one implementation CLOSE "Service / Repair History Staff UX" without follow-on slices?
**Yes.** Either (a) accept **E** and close immediately (the record+view staff workflow is already complete), or (b) ship the single optional view-only performer/recorded-at enrichment and close — **neither requires a follow-on slice.** The correction semantic and service-evidence media are distinct, separately-justified future features, not components of the staff record/view UX this task covers.

**DISCOVERY/PLAN ONLY — no code/DB/migration/deploy change performed.** See `TASK_QUEUE.md` (RECONCILED REMAINING WORK #4), `docs/SCA-050-PRODUCT-EXPERIENCE-OPERATIONS-AUDIT.md`.

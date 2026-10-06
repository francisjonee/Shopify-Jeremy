# SCA Staff Operational Dashboard / Worklists — discovery + plan (PLAN ONLY)

**Date:** 2026-10-06 · **Status: DISCOVERY + PLAN ONLY. No implementation-repo, deployment, or DB change.** · Deployed baseline `703fbde`, migrations **120**, FP `62b2e42f`. Promoted task; executable stage = DISCOVERY/PLAN ONLY. For ChatGPT audit.

**Purpose:** operational action, not analytics — let staff answer **"what items need my attention next?"** Not reporting/charts/KPIs/market-value.

**Headline recommendation:** build a **small read-only dashboard (counts + links to pre-filtered worklists)** that **reuses the existing Eyewear Registry index filters and the existing adverse-status queue** for drill-down. **Zero schema.** It CLOSES the task area in one pass. Do **not** add lifecycle worklists for states that are never populated.

---

## 1. Current staff operational flow (verified)

Real lifecycle (the projected `lifecycle_state` is **derived**, not a stored machine; it is orthogonal to `registry_status`):

| Step | Projection result | Next staff action |
|---|---|---|
| Intake (`ItemService::create`) | `lifecycle=INTAKE`, `registry=normal` | authenticate (`sca.eyewear.authenticate`) |
| Authentication finalize (`AuthenticationService::finalize`) | passed → `AUTHENTICATED`; failed → `AUTH_FAILED` (while still unowned+uncertified) | certify (passed) / decide: retry or retire (failed) |
| Certification (`CertificationService::issue`) | `CERTIFIED`; **always mints + activates a QR in the same txn** | sell (Shopify sale-link) or issue external claim link |
| Sale-link (`SaleLinkService`) | **no lifecycle change** (stays `CERTIFIED`, unowned); `sca_shopify_sale_links.eligibility_state='eligible'` | none required (claim is collector-driven) |
| Claim (`ClaimService`, collector-driven) | owner set → `REGISTERED` | none (steady state) |
| Transfer | ownership events → recomputes owner → stays/returns `REGISTERED`; `sca_transfer_requests.state='pending'` tracked separately | none (recipient-collector accepts) |
| Retire / invalidate | sets `registry_status` `retired`/`invalidated` (NOT lifecycle) | handled via adverse queue |

**`deriveLifecycleState()` can only ever return 5 values: `INTAKE, AUTH_FAILED, AUTHENTICATED, CERTIFIED, REGISTERED`.** The other 4 CHECK-allowed tokens (`SOLD_AWAITING_CLAIM, TRANSFER_PENDING, RETIRED, INVALIDATED`) are **never written by any code** → any worklist keyed on them would always be empty. `registry_status` is the separate 7-value axis (`normal, lost, stolen, recovered, disputed, retired, invalidated`).

## 2. Existing list/filter/worklist capabilities

- **Eyewear Registry index** (`admin.sca.eyewear.index`, ACL `sca.eyewear`) already filters by: `search`, `intake_type`, `cert_number`, `registry_status`, `lifecycle`, `owned|unowned`, `date_from/date_to`, `sort/dir` — all via GET params, preserved across pagination. So these worklists are **already URL-achievable today**: `?lifecycle=INTAKE`, `?lifecycle=AUTHENTICATED`, `?lifecycle=CERTIFIED&owned=unowned`, `?lifecycle=AUTH_FAILED`, `?registry_status=lost|stolen|disputed|…`. Per-card badges already show lifecycle, registry, Certified, QR.
- **Adverse-status queue** (`admin.sca.status.queue`, ACL `sca.eyewear.status`) already lists `registry_status ∈ {disputed,lost,stolen,retired,invalidated}` with a per-row "Manage" action and an `admin_resolvable` flag — it **already is** the adverse worklist.
- **No dashboard / aggregate / counts / badges exist anywhere** (verified: no `->count()` aggregates, no landing beyond the index; the admin header links to Krayin's own dashboard, not an SCA one). Green-field.

## 3. Genuine operational-visibility gaps

The worklists are *achievable* but **not discoverable or aggregated**: staff must know the URL params, and there is **no single "what needs attention" surface with counts**. Concretely:
- **Gap 1 (primary):** no landing surface showing, at a glance, **how many** items sit in each actionable state, with one-click links. This is the real gap (SCA-050 "S5", SCA-053 LOW/ops).
- **Gap 2 (exception):** **"certified but has no active QR"** — a legitimately reachable (rare, transient/integrity) state (a QR `revoked` event without a re-`activated`). The index **cannot** express it (it filters `lifecycle`, not `active_qr_identifier_id IS NULL`; it only shows a QR badge). Worth surfacing as an exception indicator.
- **Gap 3 (weak):** "authentications awaiting finalize" (draft `sca_authentications.finalized_at IS NULL`) — not projection/index-queryable and has **no list surface**; low operational value (drafts rarely linger). Considered, deferred (see §5).

## 4. Exact actionable states to surface (recommended worklist set)

Each tile = label + live count + link (reusing existing surfaces; no new filtering unless noted):
1. **Awaiting authentication** → `?lifecycle=INTAKE`. Next: authenticate.
2. **Authentication failed (decide)** → `?lifecycle=AUTH_FAILED`. Next: retry or retire.
3. **Authenticated — not yet certified** → `?lifecycle=AUTHENTICATED`. Next: certify.
4. **Certified — unclaimed (ready to sell / claim-link)** → `?lifecycle=CERTIFIED&owned=unowned`. Next: sale-link / external claim link.
5. **Needs attention (adverse)** → link to the **existing** `admin.sca.status.queue` (lost/stolen/disputed/retired/invalidated). Reused, not duplicated.
6. **Exception — certified with no active QR** → count-only indicator; if `> 0`, flag "investigate" and link to `?lifecycle=CERTIFIED` (precise `qr=missing` filter is **optional/deferred**, §5). Query: `current_certification_id IS NOT NULL AND active_qr_identifier_id IS NULL`.

Plus a small non-analytics **orientation header** (total items; registered/claimed count) purely for context — not KPIs/charts.

## 5. States considered and REJECTED (with reasons)

- **`SOLD_AWAITING_CLAIM`, `TRANSFER_PENDING`, `RETIRED`, `INVALIDATED` lifecycle worklists** — REJECT: these lifecycle tokens are **never written**; tiles would always show 0 (verified). (Retire/invalidate live in `registry_status`, already covered by the adverse tile.)
- **`REGISTERED` (claimed) worklist** — REJECT as a worklist: steady state, no pending staff action (may appear only as the orientation "registered" count).
- **Shopify "eligible sale-link awaiting claim"** — REJECT as a separate tile: the pool is the same certified-unclaimed items (tile 4); claim is **collector-driven**; there is **no direct staff claim action** (only reminder / claim-link reissue). Keeps the dashboard decoupled from Shopify internals.
- **Transfer-pending (`sca_transfer_requests.state='pending'`)** — REJECT: transfers are accepted by the recipient **collector**; not a staff action queue.
- **Authentications awaiting finalize (draft auths)** — DEFER: no existing list surface; would need a new draft-listing view; low value (drafts normally finalized in one sitting). Optional future.
- **Precise `qr=missing` index filter** for the exception drill-down — OPTIONAL/DEFER: the exception tile's count + a link to the certified list is sufficient for a rare state; a precise one-param index filter can be added later if volume warrants.

## 6. Schema changes required? — **NONE**

Everything is read from the existing `sca_item_current_state` projection (+ a bounded join to `sca_eyewear_items` for labels, mirroring the index/queue). All counts are `COUNT(*)` over projection predicates already used by the index. **Zero migrations, zero new tables/columns, no lifecycle-semantics change.**

## 7. Recommended UX — **a small dashboard (counts + links); filters already suffice**

**Dashboard, not new index filters** (the index already yields the drill-downs). The dashboard is the missing "attention" surface; it **links** to the existing filtered index and the existing adverse queue. (The only index gap — certified-no-QR — is surfaced as a dashboard count; a precise index filter is optional/deferred.) So: **dashboard = primary; existing index filters = reused for drill-down; adverse queue = reused.** Not "both" in the sense of new index filters — the smallest useful is the dashboard alone.

## 8. Proposed routes / controllers / views / queries

- **Route:** `GET admin/sca/dashboard` → `DashboardController@index`, name `admin.sca.dashboard.index`, middleware `sca.can:sca.eyewear` (the existing broad registry read gate). `Registry/src/Routes/admin-routes.php`.
- **Controller (new):** `packages/Sca/Registry/src/Http/Controllers/DashboardController.php` — read-only; one method computing the counts in §4 via `DB::table('sca_item_current_state')` predicates (+ the adverse count via `StatusService::ADVERSE_STATUSES`, reused). No writes.
- **View (new):** `packages/Sca/Registry/src/Resources/views/dashboard/index.blade.php` — tiles (label + count + link), extending `x-admin::layouts`; links built with `route('admin.sca.eyewear.index', [...params])` and `route('admin.sca.status.queue')`.
- **Menu (modified):** `packages/Sca/Registry/src/Config/menu.php` — add a sidebar entry "SCA Dashboard" → `admin.sca.dashboard.index`, **mirroring the existing proven Registry entry structure exactly** (single-segment key e.g. `sca-dashboard`, ACL effectively `sca.eyewear`, appropriate sort so it sits above "SCA Eyewear Registry"). *(If, during implementation, the menu ACL/key behaviour is not byte-for-byte reproducible from the existing entry, fall back to an index-toolbar "Worklists / Dashboard" link — decided at implementation, not here.)*
- **No `EyewearItemController`/index change** in the recommended (smallest) scope.

## 9. ACL model

Reuse existing read ACLs — **no new ACL keys, no broadening.** Dashboard route gated `sca.eyewear`. Tiles whose target needs a narrower permission are shown permission-aware where cheap (e.g. the adverse tile gated on `sca.eyewear.status`; drill-down to item detail uses the existing `sca.eyewear.view`-gated routes). Navigation visibility never grants authorization — every linked surface keeps its own guard.

## 10. Expected files

**New (3):** `DashboardController.php`; `dashboard/index.blade.php`; `tests/Feature/Sca/StaffDashboardTest.php`.
**Modified (2):** `admin-routes.php` (one GET route); `Config/menu.php` (one sidebar entry).
**Not touched:** `EyewearItemController`, projection/services, ACL definitions, schema/migrations, Shopify, collector, QR, certification, ownership, SMTP, public routes, Caddy/Docker.

## 11. Test matrix

- **ACL/auth:** dashboard 200 for `sca.eyewear` staff; unauthenticated → login redirect; staff without `sca.eyewear` → 403.
- **Count correctness:** seed items in each state (INTAKE, AUTH_FAILED, AUTHENTICATED, CERTIFIED-unclaimed, REGISTERED, an adverse item) → each tile count equals the matching projection query; registered/total orientation counts correct.
- **Exception count:** construct a certified item whose active QR is then revoked (via the existing QR lifecycle events) → the "certified, no active QR" count = 1; a normally-certified item does **not** count.
- **Links:** each tile's `href` equals the expected pre-filtered index URL (`?lifecycle=…`, `&owned=unowned`) / the adverse-queue route.
- **No dead-enum tiles:** dashboard does **not** render worklists for `SOLD_AWAITING_CLAIM/TRANSFER_PENDING/RETIRED/INVALIDATED` lifecycle.
- **Adverse parity:** adverse count matches `StatusService::ADVERSE_STATUSES` (same set as the queue).
- **Zero mutation:** rendering the dashboard leaves the provenance fingerprint + counts unchanged.
- **Regression:** full `tests/Feature/Sca` green; no schema change (migrations 120).

## 12. Scope exclusions (explicit)

No analytics/charts/KPIs/management reporting/market-value; no new schema/migrations; **no lifecycle-semantics change** (specifically: do NOT start writing `SOLD_AWAITING_CLAIM`/`TRANSFER_PENDING`/etc. merely to populate tiles); no mutation from reads; no change to Shopify, collector workflows, QR, certification, ownership, SMTP, public routes, Caddy/Docker, or infrastructure; no new ACL keys / no permission broadening; draft-auth "awaiting finalize" list and the precise `qr=missing` index filter are **deferred** (optional future, not part of closing this area).

## 13. Does the recommended implementation CLOSE the task area?

**Yes.** A read-only dashboard with counts + links for the real actionable states (INTAKE, AUTH_FAILED, AUTHENTICATED, CERTIFIED-unclaimed, adverse) — reusing the existing index filters and adverse queue, plus the certified-no-QR exception indicator — completely answers "what needs my attention next?" for the verified 5-state lifecycle + adverse axis. The deferred items (awaiting-finalize list, precise qr filter, transfer-pending) are low-value/optional, not required to close the area. One task closes Staff Operational Dashboard / Worklists.

**DISCOVERY/PLAN ONLY — no code/deploy/DB/production change performed.** See `TASK_QUEUE.md` (RECONCILED REMAINING WORK #2), `docs/SCA-050-PRODUCT-EXPERIENCE-OPERATIONS-AUDIT.md`, `docs/SCA-053-PILOT-READINESS-AUDIT.md`.

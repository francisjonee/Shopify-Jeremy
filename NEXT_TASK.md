# NEXT TASK

**STATUS: ACTIVE — SCA STAFF OPERATIONAL DASHBOARD / WORKLISTS. Executable stage: DISCOVERY/PLAN ONLY (DONE, awaiting audit).**

Promoted 2026-10-06. Deployed baseline `703fbde9884ddeb9219c0cf54d34f5fe9e3f48a8`, migrations **120**, FP **`62b2e42fe409b4ec91f3381b35da819e`**.

## Objective

A small, read-only staff operational surface answering **"what items need my attention next?"** — operational action, **not** analytics/reporting/charts/KPIs/market-value.

## Current stage — DISCOVERY/PLAN (complete; STOP for audit)

Plan committed at `docs/SCA-STAFF-OPERATIONAL-DASHBOARD-DISCOVERY.md`. **Do not implement yet.** Key verified findings:

- `lifecycle_state` is effectively a **5-value** enum in practice (`INTAKE, AUTH_FAILED, AUTHENTICATED, CERTIFIED, REGISTERED`); the 4 other CHECK tokens (`SOLD_AWAITING_CLAIM, TRANSFER_PENDING, RETIRED, INVALIDATED`) are **never written** → worklists on them are always empty. `registry_status` is the separate 7-value adverse axis.
- The **Eyewear Registry index already** makes most worklists URL-achievable (`?lifecycle=…`, `&owned=unowned`, `?registry_status=…`); the **adverse-status queue already** exists; there is **no dashboard/aggregate/counts** anywhere. Gap = a single "attention" surface with counts + links.
- Recommended product: a **dashboard (counts + links)** reusing the existing index filters + adverse queue. **Zero schema.**

## Recommended implementation scope (for the NEXT executable stage, if approved)

Tiles (count + link): Awaiting authentication (`?lifecycle=INTAKE`) · Authentication failed (`?lifecycle=AUTH_FAILED`) · Authenticated-not-certified (`?lifecycle=AUTHENTICATED`) · Certified-unclaimed (`?lifecycle=CERTIFIED&owned=unowned`) · Needs-attention adverse (link to existing `admin.sca.status.queue`) · Exception "certified, no active QR" (count indicator). Non-analytics orientation header (total / registered counts).

Files: **new** `DashboardController.php` + `dashboard/index.blade.php` + `StaffDashboardTest.php`; **modified** `admin-routes.php` (one `GET admin/sca/dashboard`, ACL `sca.eyewear`) + `Config/menu.php` (one sidebar entry mirroring the existing Registry entry). No `EyewearItemController`/index change in the smallest scope.

## Hard constraints

Reuse existing read ACLs (`sca.eyewear` / `sca.eyewear.status`); no new ACL keys, no broadening. No provenance mutation from reads. **Do NOT change lifecycle semantics to populate tiles** (never start writing the dead enum tokens). No analytics/charts/KPIs/market-value. No change to Shopify, collector workflows, QR, certification, ownership, SMTP, schema/migrations, public routes, Caddy/Docker, or infrastructure. Deferred (optional, not part of closing): draft-auth "awaiting finalize" list; precise `qr=missing` index filter; transfer-pending.

## Stage gate

**Executable stage is DISCOVERY/PLAN ONLY — complete and committed. STOP for ChatGPT audit.** Implementation is a separate stage requiring explicit promotion. Completing the recommended scope would **CLOSE** Staff Operational Dashboard / Worklists.

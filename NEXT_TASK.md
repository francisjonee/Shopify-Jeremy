# NEXT TASK

**STATUS: ACTIVE — SCA INVENTORY ONBOARDING / BULK CSV. Executable stage: DISCOVERY/PLAN ONLY (DONE, awaiting audit).**

Promoted 2026-10-07. Deployed baseline `1b029fd981388da76b66d50c7a851f3254aa1e5d`, migrations **120**, FP **`62b2e42fe409b4ec91f3381b35da819e`**. Service / Repair History Staff UX remains CLOSED.

## Objective

Smallest safe workflow to onboard real inventory at scale (CSV/bulk) **without bypassing the provenance lifecycle** — each imported frame becomes a normal `INTAKE` SCA item and nothing else.

## Current stage — DISCOVERY/PLAN (complete; STOP for audit)

Plan committed at `docs/SCA-INVENTORY-ONBOARDING-BULK-CSV-DISCOVERY.md`. **Do not implement yet.** Verified findings:

- Intake = `ItemService::create($attrs)` (one transaction): mints `public_ref` (`SCA-`+12-hex, system-only) + one `INTAKE/normal` projection row; nothing else. Field contract = `StoreEyewearItemRequest` rules (`intake_type` required `sce_presale|external_intake`; brand/model_name/frame_serial/year/country_of_origin/materials/original_specifications optional). ACL `sca.eyewear.create`.
- The **only** item uniqueness is the random `public_ref` — `frame_serial` is advisory/non-unique; **two items can share brand/model/serial**, so **re-importing the same CSV would silently duplicate inventory** (the central safety problem).

## Recommendation — **Option B** (upload → preview/validate → confirm)

Reuse `ItemService::create` per **valid** row (never raw inserts); dry-run preview classifies valid / invalid / duplicate-warning (no mutation); confirm imports valid rows with a rejected-row report; each frame gets its own system `public_ref` + `INTAKE` projection. **One small standalone append-only `sca_inventory_imports` ledger** (content-hash UNIQUE for re-import idempotency + actor/filename/counts/generated-public_refs for audit + reconciliation) — touches **no** existing/provenance table; justified because the item table has no natural key. ACL reuse `sca.eyewear.create`; batch cap ≤500 rows. (Zero-schema fallback documented — weaker re-import protection. Option A only if volume is truly low. Options C and D rejected.)

## Hard constraints

Bulk intake must reuse the domain service; must NOT authenticate/certify/mint-QR/create-ownership/sale-links/set-catalog or skip lifecycle; must never overwrite existing items (insert-only) or make provenance/history editable; partial failure must be explicit + auditable. No Shopify/scope/product-sync; no auth/cert/QR/ownership/service-history/SMTP/dashboard/analytics/infra change. **Prefer zero schema — only the one standalone ledger is proposed, and only if ChatGPT approves it over the zero-schema fallback.**

## Stage gate

**Executable stage is DISCOVERY/PLAN ONLY — complete and committed. STOP for ChatGPT audit.** Implementation is a separate promoted stage. One implementation closes bulk onboarding **to INTAKE** (downstream authenticate/certify/QR stay the normal per-item staff flow); no follow-on onboarding slice.

# SCA Inventory Onboarding / Bulk CSV — discovery + plan (PLAN ONLY)

**Date:** 2026-10-07 · **Status: DISCOVERY/PLAN ONLY. No implementation-repo, production, DB, migration, Shopify, or deployment change.** · Deployed baseline `1b029fd`, migrations **120**, FP `62b2e42f`. Promoted task; executable stage = DISCOVERY/PLAN ONLY. For ChatGPT audit.

**Goal:** smallest safe workflow to onboard real inventory at scale (CSV/bulk) **without bypassing the provenance lifecycle** — each imported frame becomes a normal `INTAKE` SCA item and nothing else.

**Headline recommendation: Option B (upload → preview/validate → confirm), reusing `ItemService::create` per valid row, with ONE small standalone append-only audit/idempotency ledger table (`sca_inventory_imports`) — justified because the item table has NO natural key, so re-importing the same CSV would otherwise silently duplicate inventory.** A zero-schema variant is presented as the fallback.

---

## 1. Exact current single-item intake contract

- **`ItemService::create(array $attrs): EyewearItem`** — in ONE `DB::transaction`: `EyewearItem::create(['public_ref'=>Token::publicRef(),'intake_type'=>'sce_presale', ...$attrs])` then inserts exactly **one** `sca_item_current_state` row (`lifecycle_state='INTAKE'`, `registry_status='normal'`, `rebuilt_at=now()`). **It writes nothing else** — no authentication, certification, QR identity, ownership, media, or status event. The model has `$guarded=[]`, so whitelisting is the FormRequest's job (the controller passes only `$request->validated()`).
- **Identity:** `Token::publicRef()` = `'SCA-'` + 12 uppercase hex (6 CSPRNG bytes). **Always system-generated** (a client-supplied `public_ref` is dropped — test `i5`). **No collision retry** — relies on entropy + the DB UNIQUE; a collision would surface as a unique-violation inside the transaction.
- **Lifecycle result:** `INTAKE` / `normal`, nothing else created (test `i4` — exactly one projection row).
- **Staff UX:** `admin.sca.eyewear.create` (GET) + `.store` (POST), ACL **`sca.eyewear.create`**. `StoreEyewearItemRequest` rules (the intake field contract): `intake_type` **required** `in:sce_presale,external_intake`; `brand`/`model_name`/`frame_serial` nullable string ≤255; `year` nullable int 1800..(currentYear+1); `country_of_origin` nullable ≤100; `materials` nullable ≤255; `original_specifications` nullable ≤2000. **No rule for `public_ref`, `sku`, or image** (sku/images are a separate catalog path, post-intake). Normalization = trim + blank→null (no uppercasing).

## 2. Item schema + constraints (final effective)
`sca_eyewear_items`: `id`; `public_ref` **char(20) UNIQUE** (only unique); `model_name`, `brand`, `frame_serial` (all nullable); `intake_type` NOT NULL (CHECK `sce_presale|external_intake`); `year`, `country_of_origin`, `materials`, `original_specifications` (nullable, SCA-044); `sku`, `image_path`, `image_mime` (nullable, catalog); non-unique index `(brand, frame_serial)`. **No unique on frame_serial, sku, or (brand,model,serial).**

## 3. Duplicate / uniqueness protections that exist today — essentially NONE
The only uniqueness is the random system `public_ref`. **Two items can share identical brand/model/frame_serial** (test `i7` proves both persist). There is **no dedup, no "already-exists" guard, no external/source-id column**. `frame_serial` is explicitly advisory/non-unique and optional. **Consequence for bulk: every CSV row always mints a new item, so re-running the same import silently duplicates inventory** — the central safety problem to solve.

## 4. What an imported item must become
Exactly a single-item intake: a new `sca_eyewear_items` row + one `INTAKE`/`normal` projection row, via `ItemService::create`. **Bulk import must NOT authenticate, certify, mint/activate QR, create ownership, create Shopify sale-links, set catalog sku/images, or skip any lifecycle stage.** Downstream authenticate→certify→QR→sell remain the normal per-item staff flow, unchanged.

## 5. Realistic CSV field contract
Columns mirror the intake field contract (case-insensitive headers; values trimmed; blank→null):
- **`intake_type`** — required, `sce_presale` or `external_intake` (per-row; or a form-level default applied to blank cells).
- `brand`, `model_name`, `frame_serial`, `year`, `country_of_origin`, `materials`, `original_specifications` — optional, same validation as `StoreEyewearItemRequest` (reused verbatim).
- **`public_ref` is NOT accepted** (always system-generated; a column, if present, is ignored).
- **`sku`/images NOT accepted at import** (catalog is a separate post-intake path) — keeps bulk = pure intake. *(Optional extension, deferred: allow a `sku` column written through the existing catalog field; not recommended for the smallest slice.)*
- **External/source identifier:** none is stored today. **Reconciliation is via the import result report (CSV row → generated `public_ref`)**, not a new column. The operator maps their spreadsheet from that report (and/or the persisted ledger, §7).

Minimum useful columns in practice: `intake_type` + `brand` + `model_name` (+ `frame_serial` when known). Strictly, only `intake_type` is required by validation.

## 6. Validation / preview / error-report design (Option B)
- **Upload** a CSV (staff). **Parse in memory — NO mutation.**
- **Per-row validation** reusing the `StoreEyewearItemRequest` rule set (one `Validator` per row) → classify each row **valid / invalid (with field errors) / duplicate-warning**.
- **Duplicate-warning (soft, not a hard block — duplicates are legitimately allowed):** flag rows whose `brand`+`model_name`+`frame_serial` match (a) another row in the same file, or (b) an existing item. Staff decide; the preview makes it visible rather than silently creating doubles.
- **Preview screen** shows counts (valid / invalid / duplicate-warning) + a per-row table (line number, parsed values, status, errors). **Dry-run is REQUIRED** — no row is written at preview.
- **Error report:** on-screen per-row; downloadable CSV of rejected rows (line, reason) is a reasonable addition.
- **Confirm** imports only the previously-validated **valid** rows.

## 7. Duplicate / retry / idempotency strategy (the safety core)
- **No silent overwrite is possible** — import is insert-only; every row mints a NEW `public_ref`; there is no update path. ("Not overwriting existing items" holds by construction.)
- **Double-submit of a preview** (refresh / double-click): the confirm carries a **server-issued single-use token** bound to the exact validated payload → a repeated confirm of the same preview is rejected.
- **Re-upload of the same file (different session):** this is where zero-schema cannot help — nothing durably remembers a prior import. **Recommended guard = a standalone append-only `sca_inventory_imports` ledger** storing a **`content_sha256` UNIQUE** of the normalized CSV; on confirm, insert the hash first → an identical already-committed file is rejected ("this file was already imported on <date>: N items"). The ledger also persists **actor_staff_ref, filename, row_count, imported_count, rejected_count, generated public_refs (JSON), created_at** — giving durable **audit** + **reconciliation** (row→public_ref) in one place, **without altering `sca_eyewear_items` or any provenance table**.
- **Zero-schema fallback (if ChatGPT prefers):** preview+confirm-token + soft duplicate warnings + a downloadable result report, and **no durable re-import guard** (a fresh-session re-upload would duplicate; mitigated only by the soft "matches existing item" warning). Weaker but no migration.

## 8. Transaction / partial-failure strategy
**Valid-row import with a rejected-row report** (not all-or-nothing): the preview already filters invalid rows; on confirm, each valid row is created via `ItemService::create` (which is itself transactional). A rare per-row failure (e.g. a `public_ref` collision) is caught, that row is reported `failed` with a reason, and the others proceed. The whole batch's outcome (imported public_refs + any failures) is recorded in the `sca_inventory_imports` ledger → **explicit + auditable partial failure**. (An all-or-nothing single-transaction variant is possible but less useful for onboarding, where one bad row shouldn't block hundreds of good ones.)

## 9. Maximum sensible batch size
Cap per CSV (host is swapless, ~5.8 GB shared with the live co-tenant). Recommend **≤ 500 rows per import** (configurable); larger files → "split and import in batches." Preview parses the whole file in memory once; inserts are tiny. The cap protects memory and keeps the preview responsive.

## 10. Options compared
- **A — single-item intake only:** sufficient only if real onboarding volume is genuinely low. For "onboard real inventory at scale" it is **not** sufficient; keep as the fallback if the operator says volume is small.
- **B — upload → preview/validate → confirm (RECOMMENDED):** safe, auditable, reuses `ItemService::create`; dry-run prevents committing bad data; the ledger prevents accidental re-import. Smallest workflow that safely handles volume.
- **C — direct CSV import (no preview):** **rejected** — no dry-run, higher risk of committing invalid/duplicate rows; idempotency alone doesn't make blind import safe.
- **D — Shopify-driven/product-sync onboarding:** **out of scope** — would require Shopify product scopes / reopening the integration. Not pursued.

## 11. Proposed routes / controllers / services / views (Option B)
- **Routes** (admin, prefix `sca/eyewear/import`, ACL `sca.can:sca.eyewear.create`): `GET import` (upload form) · `POST import/preview` (parse+validate, no mutation → preview) · `POST import/confirm` (commit valid rows). POST-only mutation; CSRF.
- **Controller:** `InventoryImportController` (upload/preview/confirm) — thin; delegates to the service; derives actor from the session.
- **Service:** `InventoryImportService` — CSV parse + per-row validation (reusing `StoreEyewearItemRequest::rules()`), duplicate classification, content-hash, and on confirm: loop `ItemService::create($validatedRow)` + write the `sca_inventory_imports` ledger row. No raw item inserts — **reuse the domain service**.
- **Views:** `eyewear/import/upload.blade.php`, `import/preview.blade.php` (valid/invalid/duplicate table + confirm form with the single-use token), `import/result.blade.php` (per-row result incl. generated public_refs; downloadable).
- **(Recommended) Migration:** `create_sca_inventory_imports` — standalone append-only ledger (see §7); append-only triggers consistent with the project's `_no_update`/`_no_delete` convention. **Touches no existing table.**

## 12. ACL
Reuse **`sca.eyewear.create`** (bulk import *is* item creation). No new ACL key, no broadening. (A dedicated `sca.eyewear.import` is optional, not recommended for the smallest slice.)

## 13. Schema / migration necessary?
**One small standalone table is recommended and justified** (`sca_inventory_imports`) — durable re-import idempotency (content hash) + auditable batch metadata + row→public_ref reconciliation, which zero-schema cannot durably provide given the item table's lack of a natural key. It does **not** alter `sca_eyewear_items` or any provenance/projection table. If ChatGPT rules the zero-schema fallback (§7) acceptable, no migration is needed (at the cost of weaker re-import protection and no durable audit). **Recommendation: the one ledger table.**

## 14. Test matrix
- ACL: import routes require `sca.eyewear.create` (unauth → login; no-perm → 403).
- Preview is non-mutating (no items/projection rows created; FP unchanged).
- Valid rows → on confirm, each becomes exactly one item + one `INTAKE/normal` projection row via `ItemService::create`; **no auth/cert/QR/ownership/media/sale-link created**; each gets a distinct system `public_ref`.
- Invalid rows (bad `intake_type`, year out of range, over-length) → rejected in preview, not imported; error report lists them.
- Duplicate-warning rows (same brand/model/serial in-file or vs existing) → flagged, still importable on confirm (duplicates allowed), surfaced not silently created.
- Idempotency: re-submitting the same preview token → rejected (no double import); re-uploading the identical file → rejected by the ledger `content_sha256` unique (with ledger) **or** soft-warned (zero-schema).
- Partial failure: a forced row failure is reported, others import; ledger records imported/rejected counts + public_refs.
- Batch cap: a CSV over the limit is rejected with a clear message.
- `public_ref` never client-supplied (a CSV `public_ref` column is ignored).
- Zero mutation to EXISTING items; migrations unchanged except the one additive ledger (if chosen); full `tests/Feature/Sca` green.

## 15. Explicit exclusions
No Shopify changes/scopes/product sync; no authentication/certification/QR/ownership/claim/service-history automation or change; no catalog sku/image at import (separate path); no SMTP/notifications; no dashboard/analytics/reporting; no infrastructure; **no edit/delete of committed items or any provenance history** (CSV correction = fix the source and import corrected rows as new items, or rely on the pre-commit preview rejecting bad rows); no alteration of `sca_eyewear_items` or provenance tables (only the optional standalone ledger).

## 16. Recommended smallest complete implementation
**Option B + the `sca_inventory_imports` ledger:** upload → preview/validate (reusing the intake rules) → confirm → per-valid-row `ItemService::create` → result report + append-only ledger row (content-hash idempotency + audit + reconciliation). ACL `sca.eyewear.create`. One standalone additive table; no change to intake semantics or provenance.

## 17. Closure criteria for SCA Inventory Onboarding
Closed when: (1) this plan is ChatGPT-audited; (2) the chosen option is implemented + deployed under the governed flow with the §14 tests green, **zero provenance mutation to existing items**, and each imported frame carrying its own system `public_ref` + `INTAKE` projection via the normal service; (3) a short operator note on the CSV contract + reconciliation. One implementation closes bulk onboarding **to INTAKE**; downstream per-item authenticate/certify/QR remain the normal staff flow and are **not** part of this task — no follow-on onboarding slice. (If the operator determines volume is low and accepts Option A, the task closes zero-code like the service-history area.)

**DISCOVERY/PLAN ONLY — no code/DB/migration/Shopify/deploy change performed.** See `TASK_QUEUE.md` (RECONCILED REMAINING WORK #5).

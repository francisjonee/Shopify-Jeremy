# SCA — First Genuine Inventory Onboarding Pilot SOP (10 pairs)

**A step-by-step, read-only runbook for onboarding the first 10 genuine physical eyewear pairs using the
newly deployed CSV import + optional Shopify variant-linking feature, through to certification, QR
Passports, and batch labels.** No real CSV was uploaded and nothing was imported in preparing this — it
is procedure only. Grounded in the live production code at `a53eff3`. 2026-10-30. **STOP.**

> Audience: SCA operators/staff running the pilot (and the owner who authorizes it). Every route, field,
> and ACL below is verified against the deployed application at `a53eff3`.

## 0. Before you start — authorization & roles
- **The first genuine inventory import must be approved by the business owner (Jeremy).** This is a
  governance gate, not a code gate: the application will allow any staff member with the right permission
  to import. Do not run the first real import without the owner's explicit go-ahead.
- **Staff permissions (SCA ACLs, server-enforced):**
  - `sca.eyewear.create` — required to upload/preview/confirm a CSV import.
  - `sca.eyewear.shopify.link` — **additionally** required if the CSV assigns any `shopify_variant_id`
    (a linking import is blocked without it; see §2).
  - `sca.eyewear.authenticate` — to record and finalize authentication (§5).
  - `sca.eyewear.certify` — to certify an item (which mints its QR) (§6).
  - `sca.eyewear.view` — to view/print QR labels (§7).
- The pilot touches **only SCA**. It makes **no** Shopify API request and **no** change to Shopify
  products, variants, inventory, orders, customers, themes, or webhooks (§9).

## 1. CSV format (exact, as deployed)
Header row required. Columns accepted (the 8 intake fields + 1 optional link field):

| Column | Required | Format / rule |
|---|---|---|
| `intake_type` | **Yes** (every row) | exactly `sce_presale` **or** `external_intake` |
| `brand` | No | text, ≤ 255 |
| `model_name` | No | text, ≤ 255 |
| `frame_serial` | No | text, ≤ 255 |
| `year` | No | whole number **1800–2027** (current year + 1) |
| `country_of_origin` | No | text, ≤ 100 |
| `materials` | No | text, ≤ 255 |
| `original_specifications` | No | text, ≤ 2000 |
| `shopify_variant_id` | **No (optional)** | numeric Shopify **variant** id, `^[0-9]{1,24}$`; see §3 |

Rules enforced by the app:
- Only these column names are accepted. **Any other column blocks the whole import** ("unsupported
  columns"); a **repeated** column name also blocks it ("duplicate columns").
- A data row whose cell count ≠ the header count is marked **INVALID** (never shifted/truncated).
- **Max 500 data rows per file** (the pilot uses 10). You preview before anything is created.
- Only the 8 intake fields ever reach item creation; `shopify_variant_id` is used solely to make the
  catalog link.

## 2. The optional `shopify_variant_id` field
- Leave it **blank** (or omit the column entirely) to onboard a pair **unlinked** — identical to the
  behaviour before this feature. Blank cells are fine on a per-row basis.
- Put a **numeric Shopify variant id** to link that pair to its exact catalog variant during import.
- A CSV that assigns **any** variant id requires the operator to hold `sca.eyewear.shopify.link`;
  otherwise the preview shows a block notice and **confirm is disabled** (the links are never silently
  dropped — fix the permission or remove the column).
- The reference is validated against **SCA's local synced catalog mirror only** — SCA never contacts
  Shopify during import.

## 3. How staff obtain the exact Shopify variant ID (local catalog, no Shopify call)
Use the deployed staff catalog selector (the same one the per-item link panel uses):
- Route: **`GET /admin/sca/shopify/catalog-search`** (name `admin.sca.shopify.catalog-search`, ACL
  `sca.eyewear.shopify.link`). It searches the **synced** `sca_shopify_products` / `sca_shopify_variants`
  tables by product / vendor / SKU and returns each matching variant's **exact variant id**, SKU, and
  title. No Shopify API is called.
- Procedure: search for the product/SKU → read the exact **variant** id (not the product id) → paste that
  numeric id into the row's `shopify_variant_id` cell.
- The id must resolve to an **active variant of an active product** in the **configured** store. Anything
  unknown, archived, from another store, malformed, or ambiguous will make that row INVALID at preview
  (§6, validation), so you catch a wrong id before import.

## 4. Prepare the pilot CSV
- Start from the template: `docs/templates/sca-inventory-pilot-10pair-TEMPLATE.csv` (10 rows,
  placeholders only). Replace every `REPLACE_…` placeholder with real data; set each
  `shopify_variant_id` to a real variant id from §3 **or leave it blank** to onboard that pair unlinked.
- Keep `intake_type` to `sce_presale` or `external_intake` on every row. Remove the placeholder rows you
  don't need (the pilot is 10 pairs; fewer is fine).
- Save as UTF-8 `.csv` (a `.txt` is also accepted). Do **not** add a `public_ref`, `sku`, image, or any
  other column — the SCA reference is system-generated and extra columns block the import.

## 5. Staff procedure — end to end
**A. Upload & preview (no mutation).** Go to **`/admin/sca/eyewear/import`** (ACL `sca.eyewear.create`).
Upload the CSV → the preview page classifies every row **VALID / WARNING / INVALID**, shows the Shopify
variant mapping per row (valid / invalid / none) and the valid/invalid/missing-mapping counts. **Nothing
is created at this stage.**

**B. Validation & warning acknowledgment.** Review the preview:
- **INVALID** rows (bad `intake_type`, bad `year`, an unresolved `shopify_variant_id`, wrong column
  count) are skipped — fix them in the CSV and re-upload if you want them in.
- **WARNING** rows are likely duplicates (same brand + model + frame_serial as an earlier row in the file
  or an already-existing SCA item). They import **only if** you tick **"acknowledge warnings"** on the
  confirm form. SCA legitimately allows genuine duplicate frames, so acknowledge only if you mean it.
- If a block notice appears (unsupported/duplicate columns, > 500 rows, or a variant-linking CSV without
  `sca.eyewear.shopify.link`), confirm is disabled until you resolve it.

**C. Confirm import.** Submit the confirm form (single-use token). The app creates one SCA item per
importable row via the canonical intake path — each gets a system-generated `public_ref` and one INTAKE
projection row. For rows with a valid variant id, it also creates the item↔variant link **in the same
transaction** (reusing the audited, one-variant-per-item link writer). **Imported items are UNCERTIFIED:
no QR, no ownership, no sale-link.** The result page lists each row's status (imported / already imported
/ failed) and its Shopify link outcome.

**D. Item-to-variant verification.** For each linked pair, open the item detail and confirm the Shopify
catalog link shows the intended variant (SKU/title). Cross-check against §7's counts. (Unlinked pairs
simply have no link — expected.)

**E. Individual authentication (per item, human judgment).** For each pair: **`/admin/sca/eyewear/{id}/
authenticate`** (ACL `sca.eyewear.authenticate`) → record the authenticity assessment → **finalize** via
`/admin/sca/eyewear/{id}/authentications/{authId}/finalize` (there is a typed-confirm screen first). Only
a finalized **PASSED** authentication qualifies a pair for certification. This step is deliberately
per-item and cannot be batched.

**F. Certification & QR generation (per item).** For each PASSED pair:
**`/admin/sca/eyewear/{id}/certify`** (ACL `sca.eyewear.certify`; typed-confirm screen first). Certify
**requires a same-item finalized PASSED authentication** and, in one transaction, **mints and activates
the single QR identity** for that item (exactly one active QR per item). Certifying **is** the
QR-generation step — there is no separate "make QR" action.

**G. Batch QR label printing.** Once pairs are certified, print labels in a sheet:
**`POST /admin/sca/eyewear/qr/labels`** (ACL `sca.eyewear.view`) with the selected item ids — it renders a
printable sheet of each item's **active** QR and safely skips any item without one. Single-item views
exist too: `GET /admin/sca/eyewear/{id}/qr` (SVG) and `/qr/label` (print one).

## 6. Checks for the known failure modes
| Situation | What the app does | Operator action |
|---|---|---|
| **Duplicate frame** (brand+model+serial matches earlier row or existing item) | Row → **WARNING**; imported only if "acknowledge warnings" is ticked | Acknowledge only if it's a genuinely distinct physical pair; otherwise fix the CSV |
| **Invalid variant** (malformed / unknown / archived variant / archived product) | Row → **INVALID** (`invalid_format` / `variant_not_found` / `variant_not_eligible`); not imported | Correct the id via §3 and re-upload |
| **Cross-store variant** (id only exists under another store) | Row → **INVALID** (`variant_not_found` for the configured store) | Use a variant id from the configured store |
| **Ambiguous variant** | Row → **INVALID** (`variant_ambiguous`) | Resolve to a single exact variant |
| **Incorrect mapping** (valid id, wrong pair) | App links as instructed (it can't know intent) | Catch it in §5-D verification; a staff member with `sca.eyewear.shopify.link` can `relink`/`unlink` from the item detail |
| **Partial failure** (e.g. a variant archived between preview and confirm) | **That row fails and rolls back** (no orphan item, no partial link); sibling rows still import; `complete=false` | Fix the catalog/id, re-upload the same file — already-imported rows are **skipped** via the durable ledger (tick "acknowledge warnings" so the now-duplicate sibling rows are recognised and skipped), the failed row imports |
| **Re-upload of the same file** | Durable ledger (content hash + per-row unique) prevents duplicate items/links | Safe to re-run to resume; it never double-creates |

## 7. Post-import verification checklist
After confirm (and again after certification), verify (read-only; staff UI or an operator DB read):
- **Item count:** `sca_eyewear_items` increased by exactly the number of imported rows; each new row is
  lifecycle **INTAKE**, registry **normal**.
- **Variant links:** `sca_eyewear_item_shopify_variant` has exactly one row per **linked** pair, pointing
  at the intended variant id; unlinked pairs have none. (Many pairs may share one variant — expected.)
- **Link audit:** `sca_eyewear_shopify_link_audit` has one `link` row per link created, attributed to the
  importing staff id.
- **Still uncertified at this point:** no new rows in `sca_certifications`, `sca_qr_identifiers`,
  `sca_ownership_events`, or any sale-link table. (These appear only after §5-F/§5-G, per item.)
- **After certification:** each certified pair has exactly **one active** QR identity; counts in
  `sca_certifications` and `sca_qr_identifiers` increase by the number certified; **ownership is still
  not set** (ownership is a separate claim/transfer flow, out of scope for onboarding).
- **No duplicates:** re-running preview on the same file shows the pairs as WARNING (already exist); a
  re-confirm skips them (no new items/links).

## 8. Who approves the first genuine inventory import
The **business owner (Jeremy)** authorizes the first real import (and the pilot as a whole). Operationally
it is run by a staff member holding `sca.eyewear.create` (plus `sca.eyewear.shopify.link` if the CSV
links variants). Authentication and certification are performed by staff holding
`sca.eyewear.authenticate` and `sca.eyewear.certify` respectively. Record the owner's approval alongside
the pilot results.

## 9. Confirmation: the pilot does not touch Shopify
- CSV import and variant validation read **only** the local synced catalog mirror
  (`sca_shopify_products` / `sca_shopify_variants`); the import service makes **no outbound HTTP** and the
  catalog selector (`catalog-search`) reads the mirror, not Shopify.
- Linking writes **only** SCA's own link + audit tables. Authentication, certification, QR, and label
  printing touch **no** Shopify surface.
- Therefore the pilot makes **zero** Shopify API requests and **no** change to Shopify products,
  variants, inventory, orders, customers, themes, or webhooks. Existing background webhook processing is
  unaffected.

## 10. Safety posture of this preparation
Read-only. No real CSV uploaded or imported; no production DB write; no Shopify API request or store
change; no certification/QR issuance; no order assignment or ownership change; no code/deploy/migration/
restart; no email configuration. Secure-claim RC `4bd88d2` not deployed and untouched.

**STOP — pilot SOP + reusable 10-row placeholder template prepared and documented
(`docs/templates/sca-inventory-pilot-10pair-TEMPLATE.csv`). Covers exact CSV format, variant-id lookup
from the local catalog, the full upload→preview→confirm→verify→authenticate→certify(QR)→batch-label
procedure, failure-mode checks, a post-import verification checklist, owner approval, and confirmation of
zero Shopify impact. Nothing was imported or changed; production remains at `a53eff3`. Awaiting owner
approval to run the first genuine import.**

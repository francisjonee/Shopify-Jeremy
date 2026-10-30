# SCA — Inventory Pilot Operational Handover (first 10 genuine pairs)

**Everything is ready for the first genuine 10-pair onboarding pilot; this is the owner-approval and
staff-execution packet.** It sits on top of the full runbook
(`docs/SCA-INVENTORY-ONBOARDING-PILOT-SOP.md`) and the CSV template
(`docs/templates/sca-inventory-pilot-10pair-TEMPLATE.csv`), both committed to governance. Read-only: no
import was run and production is unchanged at `a53eff3`. 2026-10-30. **STOP — awaiting owner approval.**

> Two audiences: **Part A** is for the owner (Jeremy) — what to provide and approve. **Part B** is for
> staff — how to execute. Routes/ACLs are verified against the live app at `a53eff3`.

## 0. Governance assets (committed & accessible)
- Full runbook: `docs/SCA-INVENTORY-ONBOARDING-PILOT-SOP.md`
- CSV template (placeholders only, reusable): `docs/templates/sca-inventory-pilot-10pair-TEMPLATE.csv`
- This handover: `docs/SCA-INVENTORY-PILOT-OPERATIONAL-HANDOVER.md`
All three are on `origin/main` of the governance repo.

---

# Part A — Owner summary (for Jeremy)

**What this pilot does:** onboards 10 real eyewear pairs into SCA as individual, system-referenced
records; optionally links each to its exact Shopify catalog entry; then authenticates and certifies each
pair, which generates its permanent QR Passport, and prints the QR labels. It is the first genuine use of
the newly deployed CSV import + variant-linking feature.

**What it does NOT do:** it does not change your Shopify store in any way — no products, variants,
inventory, orders, customers, themes, or webhooks are touched (see §B6). It also does not set ownership
or transfer anything to a customer; that is a separate flow done later.

**What you need to PROVIDE:**
1. The **10 physical pairs** for the pilot.
2. For each pair, the catalogue details (brand, model, serial if any, year, country, materials, notes) —
   staff will collect these (Part B, step 1).
3. **Optional:** for pairs that correspond to a Shopify product, whether you want them **linked** to the
   Shopify catalogue entry now. If yes, staff look up the exact variant from SCA's local catalogue (no
   Shopify access needed). If you'd rather not link yet, that's fine — pairs onboard unlinked and can be
   linked later.

**What you need to APPROVE (explicitly, before anything is created):**
1. **Go-ahead to run the first genuine import** at all (this is the business gate).
2. **The preview** — staff will upload the CSV and SCA shows a preview that creates nothing yet; you (or
   your designated approver) confirm the 10 rows look correct **before** staff click "Confirm import"
   (the mandatory checkpoint, §B3).
3. **Which staff** hold the needed permissions (below). If any are missing, those must be granted first.

**Permissions the executing staff need (SCA roles):** `sca.eyewear.create` (import), plus
`sca.eyewear.shopify.link` **only if** any pair is linked to Shopify, `sca.eyewear.authenticate`,
`sca.eyewear.certify`, and `sca.eyewear.view` (labels). Granting roles is an admin action; confirm who is
assigned before the pilot day.

**Your decision:** approve the pilot and the staff assignments, provide the 10 pairs and their details,
and sign off on the preview before import. Nothing is created until that sign-off.

---

# Part B — Staff execution

## B1. Collect the 10 pairs' details (data-collection checklist)
For each of the 10 physical pairs, record (one row per pair in the CSV template):

- [ ] **intake_type** — `sce_presale` or `external_intake` (ask the owner which applies; required).
- [ ] **brand** — e.g. the maker (optional but strongly recommended).
- [ ] **model_name** — model/reference (optional).
- [ ] **frame_serial** — the physical serial if present (optional; helps distinguish duplicates).
- [ ] **year** — a whole number 1800–2027, or leave blank if unknown.
- [ ] **country_of_origin** — optional, ≤ 100 chars.
- [ ] **materials** — e.g. Acetate / Metal / Titanium (optional).
- [ ] **original_specifications** — free-text notes, ≤ 2000 chars (optional).
- [ ] **shopify_variant_id** — **optional.** Leave blank to onboard unlinked. To link, get the exact id
      per B2.

Do **not** add any other column (e.g. `public_ref`, `sku`, image) — the SCA reference is generated
automatically and extra columns will block the whole import.

## B2. Get the exact Shopify variant IDs (only for pairs you're linking)
- Open **`/admin/sca/shopify/catalog-search`** (needs `sca.eyewear.shopify.link`). It searches SCA's
  **local synced catalogue** (by product / vendor / SKU) — it does **not** call Shopify.
- Find the product, then copy the exact **variant** id (the numeric id — not the product id) for the
  matching SKU/size. Paste it into that pair's `shopify_variant_id` cell.
- The id must be an **active variant of an active product** in the configured store; anything unknown,
  archived, from another store, or malformed will show as INVALID at preview, so you'll catch a wrong id
  before import.
- Several pairs of the same SKU may share one variant id — that's allowed; each pair still gets its own
  SCA identity.

## B3. Upload, MANDATORY preview-and-approval checkpoint, then confirm
1. **Upload:** go to the SCA admin import page — **`/admin/sca/eyewear/import`** (needs
   `sca.eyewear.create`; if any row has a `shopify_variant_id`, also `sca.eyewear.shopify.link`). Choose
   the completed CSV and submit for **preview**.
2. **Preview (creates nothing):** SCA classifies each row **VALID / WARNING / INVALID**, shows each row's
   Shopify variant mapping (valid / invalid / none) and the counts.
3. **⛔ CHECKPOINT — do NOT click "Confirm import" yet.** Review every row:
   - All 10 rows should be **VALID** (or intended **WARNING** duplicates). Fix any **INVALID** row in the
     CSV and re-upload.
   - Each linked row should show the **intended** variant mapping.
   - **Get the owner's (or designated approver's) explicit sign-off on this preview.** Record who
     approved and when. Only then proceed.
4. **Confirm:** click **Confirm import** (tick "acknowledge warnings" only if the WARNING rows are
   genuinely distinct pairs you intend to add). SCA creates the 10 records (and any variant links) and
   shows a result page with each row's status and link outcome.

## B4. Per-pair authentication, certification (QR), and labels
For each of the 10 imported pairs (these steps are per-item by design — they cannot be batched):
1. **Verify the link** (linked pairs): open the item detail, confirm the Shopify catalogue link shows the
   intended variant.
2. **Authenticate:** `/admin/sca/eyewear/{id}/authenticate` (needs `sca.eyewear.authenticate`) — record
   the authenticity assessment — then **finalize** it (typed-confirm). Only a finalized **PASSED**
   authentication qualifies the pair to be certified.
3. **Certify (generates the QR):** `/admin/sca/eyewear/{id}/certify` (needs `sca.eyewear.certify`;
   typed-confirm). This mints and activates the pair's single permanent QR Passport. Certifying **is**
   the QR step — there is no separate "make QR" action.
4. **Print labels:** once pairs are certified, print a sheet via **`/admin/sca/eyewear/qr/labels`** (needs
   `sca.eyewear.view`) with the selected item ids; it skips any pair without an active QR. (Single-pair
   `…/qr` and `…/qr/label` also exist.)

## B5. Expected results for the first 10 genuine records
After **import** (before authentication/certification):
- **10 new SCA items**, each with a unique system `public_ref`, in lifecycle **INTAKE** / registry
  **normal**.
- **One variant link per linked pair** (none for unlinked pairs) plus one link-audit entry per link,
  attributed to the importing staff member.
- **No certification, no QR, no ownership, no sale-link yet** — imported pairs are **uncertified**.

After **authentication + certification** of all 10:
- Each pair has **exactly one active QR Passport** (certification and QR counts increase by 10).
- A printable **label sheet** with all 10 QR labels.
- **Ownership is still not set** — onboarding does not assign a customer owner (that is the separate
  claim/transfer flow, out of scope for the pilot).

## B6. Shopify is NOT changed — be clear with the owner
The pilot creates **SCA records and QR Passports only**. CSV import and variant validation read **only**
SCA's local synced catalogue mirror; linking writes **only** SCA's own tables; authentication,
certification, QR, and label printing touch **no** Shopify surface. The pilot therefore makes **zero**
Shopify API calls and **no** change to Shopify products, variants, inventory, orders, customers, themes,
or webhooks. Existing background webhook processing is unaffected.

## B7. How to report completion, failures, and exceptions
Report back to the owner (and append to this governance folder) after the pilot:
- **Completion report:** the 10 SCA `public_ref`s created; for each — linked variant (or "unlinked"),
  authentication result, certification done (QR active) yes/no, and label printed yes/no. Confirm the
  expected counts in §B5 were met.
- **Failures:** any row that showed **INVALID** at preview (with the reason SCA gave), or **failed** at
  confirm (with the reason), and what you did (fixed the CSV / re-uploaded / skipped). Note: re-uploading
  the same corrected file is safe — SCA **skips** already-imported rows and never double-creates.
- **Exceptions / judgment calls:** any pair you chose **not** to link, any **WARNING** (possible
  duplicate) you acknowledged and why, any authentication that did **not** pass (and so was not
  certified), and anything the owner should decide before a larger run.
- **Who/when:** record the staff who ran each stage and the approver who signed off the preview (§B3).

## 7. Safety posture of this handover
Read-only preparation. No CSV uploaded or imported; no production DB write; no Shopify API call or store
change; no certification/QR issuance; no ownership/transfer; no code/deploy/migration/restart; no email
configuration. Secure-claim RC `4bd88d2` remains DEPLOYMENT-BLOCKED and untouched.

**STOP — operational handover prepared: owner summary (what to provide and approve), staff
data-collection + variant-ID checklist, the exact upload page (`/admin/sca/eyewear/import`), a mandatory
preview-and-approval checkpoint before confirm, expected results for the 10 records, a clear statement
that Shopify is not changed, and a completion/failure/exception reporting format. Nothing imported;
production unchanged at `a53eff3`. Awaiting the owner's approval to execute.**

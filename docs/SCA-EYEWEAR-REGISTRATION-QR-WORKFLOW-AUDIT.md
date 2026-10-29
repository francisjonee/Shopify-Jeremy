# SCA — Real Eyewear Registration & QR Passport Workflow Audit (READ-ONLY)

**VERDICT: the complete staff workflow for preparing genuine eyewear inventory before a Shopify sale is
ALREADY implemented and deployed end-to-end — register → authenticate → certify (which mints+activates
the QR Passport) → print QR label → link Shopify variant → assign to a paid order → verify QR for
packing. No step requires new development.** One minor, non-blocking cosmetic copy issue is noted ([12]).
Read-only inspection at prod `eb137bf905758e7bfa2a9b13a2ce68384340c54f`; no Shopify API, no DB write, no
record creation. 2026-10-29. **STOP.**

## [1] Registering a genuine physical pair — IMPLEMENTED
- Primary path: **`GET /admin/sca/eyewear/create` → `POST /admin/sca/eyewear`** (store), ACL
  `sca.eyewear.create`. Creates one physical eyewear record (brand/model/metadata).
- Alternatives (same `ItemService`): **bulk import** `/admin/sca/eyewear/import` (form → preview →
  confirm, `sca.eyewear.create`); and the **customer submission** intake for `external_intake`
  (`/admin/sca/submission/{id}` accept → advance). For SCE inventory prepared ahead of a sale, the direct
  create (or import) path applies.

## [2] Unique `public_ref` — IMPLEMENTED (automatic)
`ItemService::create()` sets `'public_ref' => Token::publicRef()` (opaque `SCA-`+12 hex), the single
create path, so every pair gets a unique, immutable public reference at creation. Staff never type it.

## [3] Authentication — IMPLEMENTED
- **`GET/POST /admin/sca/eyewear/{id}/authenticate`** (ACL `sca.eyewear.authenticate`) records the
  authentication; then **`GET …/authentications/{authId}/finalize/confirm` → `POST …/finalize`** finalizes
  it (typed-confirm interstitial). A certificate can be issued only from a finalized "passed"
  authentication (eligibility enforced in the certify screen/service).

## [4] Certification + QR Passport generation — IMPLEMENTED (one atomic step)
- **`GET /admin/sca/eyewear/{id}/certify/confirm` → `POST …/certify`** (ACL `sca.eyewear.certify`).
- `CertificationService::issue()` writes the certificate AND, in the SAME transaction, **mints and
  activates the canonical one-active QR identity** (`QrService::createIdentity` + `activate`), captures
  the immutable certificate snapshot, and rebuilds the projection — fail-closed (any failure rolls back
  the whole issuance). Flash: "Certification … issued; SCA QR identity activated." **There is no separate
  "generate QR" action — the QR Passport is created by certifying.** (`reissue` exists only to rotate an
  existing active QR.)

## [5] Printing / retrieving the QR label — IMPLEMENTED
From the item detail **Certification & QR** tab:
- **`GET /admin/sca/eyewear/{id}/qr`** — downloadable printable QR (SVG).
- **`GET /admin/sca/eyewear/{id}/qr/label`** — print QR label (opens print view).
- **`POST /admin/sca/eyewear/qr/labels`** — batch labels. All ACL `sca.eyewear.view`.
- The encoded payload is the canonical public passport URL for the item's **active** QR; scanning opens
  the public passport. These are pure reads — they never create/rotate/revoke a QR.

## [6] Connecting the item to an imported Shopify variant — IMPLEMENTED
- Item detail **Shopify catalog link** panel (`eyewear/partials/shopify-link`): search the **synced local
  catalog** (product/vendor/SKU — no Shopify API) and **Select** the exact variant; link/relink/unlink via
  `/admin/sca/shopify/link|relink|unlink` (ACL `sca.eyewear.shopify.link`). The link is by exact Shopify
  variant id (never by product name); one pair → at most one variant; many pairs may share a variant.
- Prerequisite: the variant must be present in the synced catalog mirror (Inventory Sync Phase 1; 4574
  products / 5344 variants currently synced).

## [7] Can staff complete all steps on existing admin screens? — YES
Every step above is a deployed admin screen/route behind an ACL. The chain is navigable entirely in the
SCA admin: **SCA Eyewear** (create/list/detail, authenticate, certify, QR label, Shopify-link panel) and
**SCA Shopify Integration → Order → Eyewear Assignment**.

## [8] Missing features / permissions / operational prerequisites
- **No missing feature in the inventory-prep chain** — all seven steps exist and are deployed.
- **Permissions:** the steps require `sca.eyewear.create`, `sca.eyewear.authenticate`, `sca.eyewear.certify`,
  `sca.eyewear.view` (QR label), `sca.eyewear.shopify.link`, and `sca.eyewear.shopify.order-assign`. The
  single **Administrator** role (`all`) holds all of them; restricted operator/manager roles are a later
  rollout choice (see the staff SOP).
- **Operational prerequisites (not code):** the purchased variant must be in the synced catalog
  (products sync is live); real QR labels must be physically printed and affixed; and a genuine paid
  order + a real unowned pair are needed for the assignment (per the eligibility audit — none exist yet).
- **Downstream, out of this chain:** customer-claim email (R0c/SMTP) is deferred, but that is AFTER the
  sale/claim, not part of inventory preparation.

## [9] Demo/test vs legitimate inventory
All three current eyewear records are **test/demo**, not legitimate inventory: `SCA-3C35D669ACBE`
(DEMO-DO-NOT-USE), `SCA-F1B792AE4745` (Ray-Ban / PILOT-TEST), `SCA-A960A57D3124`
(SCA-SHOPIFY-DRYRUN / PHASE4-TEST-DO-NOT-SELL). There is **no system flag** distinguishing test from
production inventory — only the brand/model naming convention. Staff must **create fresh real records**
for genuine inventory and must **not** reuse these test items.

## [10] Exact end-to-end procedure (all steps IMPLEMENTED)
1. **Register physical pair** — `/admin/sca/eyewear/create` → store (`sca.eyewear.create`). `public_ref`
   auto-assigned.
2. **Authenticate** — `/admin/sca/eyewear/{id}/authenticate` → record → `…/finalize` (`sca.eyewear.authenticate`).
3. **Certify** — `/admin/sca/eyewear/{id}/certify` (`sca.eyewear.certify`). **This also generates +
   activates the QR Passport** in the same transaction.
4. **QR Passport** — produced by step 3; retrieve/print via `/admin/sca/eyewear/{id}/qr` (SVG) or
   `…/qr/label` (print), or batch `qr/labels` (`sca.eyewear.view`).
5. **Link Shopify variant** — item detail → Shopify catalog-link panel → search the synced catalog →
   Select the exact variant (`sca.eyewear.shopify.link`).
6. **Assign to paid order** — `/admin/sca/shopify/order-assign` → enter order id → Look up (authoritative
   read-only `getOrder`) → select line → enter `public_ref` → Assign (`sca.eyewear.shopify.order-assign`;
   no-variant-link needs manager override).
7. **Verify QR label for packing** — `/admin/sca/eyewear/{id}/qr/label`; pack that exact pair with that QR.

## [11] Implemented vs needs development
| Step | Status |
|---|---|
| Register | IMPLEMENTED (`eyewear.create` / import / submission) |
| Authenticate | IMPLEMENTED (`authenticate` + `finalize`) |
| Certify | IMPLEMENTED (`certify`) |
| Generate QR Passport | IMPLEMENTED — automatic within certify |
| Print/retrieve QR label | IMPLEMENTED (`qr`, `qr/label`, `qr/labels`) |
| Link Shopify variant | IMPLEMENTED (Phase-2 link panel) |
| Assign to paid order | IMPLEMENTED (deployed `eb137bf`) |
| Verify QR for packing | IMPLEMENTED (`qr/label`) |

**No step requires development.** The workflow is complete end-to-end.

## [12] Smallest necessary next development task
**None is required for the workflow.** One OPTIONAL, cosmetic-only follow-up (not a blocker): certify
mints the QR with `is_production = false` (the default; `createIdentity` is never called with `true`), so
every certified item's QR is `is_production = 0`. The QR **label/print routes ignore `is_production`**
and render the real passport QR regardless (verified: their code "never touches is_production"), so
printing and scanning work normally. However, the **order-assignment confirmation** message reads the
flag and shows "QR ready for packing (staging — not for print)" for a normally-certified item —
misleading wording. If desired, the smallest fix is a one-line copy/flag correction (either stop
surfacing the staging/production distinction in that confirmation, or set `is_production = true` when
certifying production inventory). This is cosmetic; it does not affect the ability to print or scan the
QR. Recommend deferring unless the wording confuses operators.

**STOP — the full real-inventory preparation workflow (register → authenticate → certify+QR → label →
link variant → assign → verify) is implemented and deployed; no development is needed to run it. The only
prerequisites are operational: create genuine (non-test) inventory, print/affix real QR labels, and (for
the assignment) a genuine paid order + real pair per the eligibility audit. OPTIONAL cosmetic: the
assignment confirmation's staging/production QR wording. No records/API/DB changes were made. SEPARATE
OPEN: Phase-1 first genuine `products/*` webhook receipt verification.**

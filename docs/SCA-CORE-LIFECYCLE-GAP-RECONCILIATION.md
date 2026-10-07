# SCA Core Lifecycle Gap Reconciliation — audit (DISCOVERY/AUDIT ONLY)

**Date:** 2026-10-07 · **Status: READ-ONLY audit of the deployed product. No implementation/branch/migration/DB/production/Shopify/SMTP/infra change.** · Deployed baseline `976088944de0fd2883f12a0686fafaa708ce8b9e`, migrations **122**. For ChatGPT audit. NEXT_TASK stays NONE.

**Method:** traced the actual implementation at the deployed baseline (routes + controllers + views + ACL + where each is reachable), not old queue text. The business test applied to every stage: *could Jeremy and his staff operate this with real frames/customers today, without a developer touching the DB, CLI, or source?* Schema/service without a usable UI is scored **PARTIAL**, not DONE.

**Headline:** the end-to-end digital lifecycle is **software-complete and UI-operable**. The only genuine gaps are: (1) **transactional email/SMTP** (collector password recovery is non-functional; claim/transfer links are shared manually) — external/DNS-gated; (2) **no in-app notifications**; (3) **no staff visibility of Shopify sale→claim status** (schema+service exist, no UI); (4) **off-site backup not configured** (scripts present, external). No developer-only step is required to run the core lifecycle **except** these.

---

## Lifecycle matrix

| Area | Current implementation (deployed) | Real-world operability | Status | Exact gap | Recommended action |
|---|---|---|---|---|---|
| Inventory intake (single) | `admin.sca.eyewear.create/store`, form, "New Eyewear Item" on index; ACL `sca.eyewear.create` | Staff add items via UI | **DONE** | — | none |
| Inventory intake (bulk CSV) | `admin.sca.eyewear.import.*` preview→confirm + append-only ledger; "Import CSV" on index | Staff onboard at scale via UI | **DONE** | — | operator imports real CSV (operator action) |
| Authentication + pass/fail + condition grade | `admin.sca.eyewear.authentication.create/store/finalize`, item-detail form; ACL `sca.eyewear.authenticate` | Staff authenticate + grade + finalize via UI | **DONE** | — | none |
| Photography / media | gallery images store/reorder/delete + documents; item-detail forms; ACL `sca.eyewear.catalog`/`.document` | Staff upload/manage photos + docs via UI | **DONE** | — | none |
| Certification | `admin.sca.eyewear.certification.issue`, item-detail; ACL `sca.eyewear.certify`; mints+activates QR | Staff certify via UI | **DONE** | — | none |
| Certificate presentation / download | `admin.sca.certificate.generate` (POST) → immutable PDF (snapshot); owner-downloadable in My Collection Documents | Staff generate; owner downloads | **DONE** | printing is browser-side (acceptable) | none |
| QR activation / print | auto-activate at certify; SVG download + single Print label + batch labels + reissue; item-detail + index | Staff download/print QR via UI | **DONE** | physical printing is a human step | none |
| Shopify listing linkage | receiver maps `sca_item_ref` line-item property = `public_ref`; copy-helper on item detail; SOP | Software done; **storefront** attaches the property via a one-time theme/metafield setup (operator, Shopify-side) | **DONE (software)** / operator-config | storefront theme/metafield is an operator Shopify setup, not SCA code (SOP documents it) | operator configures the store per SOP |
| Shopify purchase → sale-link eligibility | `orders/paid` → eligible sale-link (HMAC, idempotent); dry-run proven | Automatic once a real sale occurs | **DONE** | — | none |
| Buyer claim eligibility | eligible sale-link (or staff external grant) enables claim | Works | **DONE** | — | none |
| **Shopify sale / claim status — staff visibility** | `sca_shopify_sale_links` has model+services only; **no staff controller/view** renders eligible/claimed / "sold-awaiting-claim" | Staff **cannot see** per-item that a Shopify sale occurred and awaits claim; dashboard "certified-unclaimed" conflates never-sold with sold-unclaimed | **MISSING (schema+service, no UI)** | no read-only staff surface over sale-links | **→ recommended next task** (read-only, no schema) |
| Shopify webhook reconciliation | public HMAC receiver; diagnostics shows only config presence + receipt count | No staff page to inspect/reconcile receipts | **PARTIAL** | no reconcile UI | POST-CORE (diagnostics suffice for pilot) |
| Collector registration / login | `collector.register/login`, views | Collector self-serves | **DONE** | — | none |
| Collector password recovery | `collector.password.*` full route+view+broker; sync `CollectorResetPassword` mail notification | **Non-functional in prod:** `MAIL_MAILER=log` → reset link is logged, not emailed | **PARTIAL (SMTP-blocked)** | no transactional email provider; the ONLY email-dependent journey | **SMTP activation (CORE, external/DNS-gated)** |
| QR scan + claim (collector) | `collector.claim.*` (QR/passport) + external-grant path; views | Works via scanning / opening a token link | **DONE** | claim link distribution is manual (no email) | SMTP would automate link delivery |
| My Collection + item detail | `collector.collection.*`; cert history, ownership history, service history, authenticity badge | Collector sees everything via UI | **DONE** | — | none |
| Service / repair history | staff record + item-detail table; owner view in My Collection; append-only | Staff record; collector views | **DONE** | (correction/annotation of a mistaken event is a separate deferred feature) | none |
| Collector→collector transfer | `collector.transfer.*` initiate/accept (bearer token, single-use), new-recipient onboarding | Owner initiates; recipient accepts via shared link | **DONE** | transfer invite shared manually (no email) | SMTP would automate invite delivery |
| Lost / stolen / recovered | collector report + staff adverse queue + resolve/retire/invalidate/recover (confirm interstitials) | Fully UI-operable both sides | **DONE** | — | none |
| Ownership / provenance history + correction | staff provenance history + governed append-only ownership-correction (now linked from item detail) + collector ownership history | Fully UI-operable | **DONE** | — | none |
| Staff transfer (staff-initiated) | none (transfer is collector-driven; staff use governed ownership-correction) | n/a | **by design** | not a gap | none |
| Staff dashboard / worklists | `admin.sca.dashboard.index` + sidebar; count tiles → filtered registry + adverse queue | Staff triage via UI | **DONE** | — | none |
| Staff navigation / discoverability | 3 sidebar entries + item-context buttons; ownership-correction reachable | Operable | **DONE** | — | none |
| Public Digital Passport | `/p/{token}`, adverse banner dominant, Option-A 404, invalidated presentation, mobile UX | Live, correct | **DONE** | — | none |
| Notifications (in-app / email) | none in-app; only password-reset email (SMTP-blocked) | Collector never proactively notified of transfer/claim/status by any channel | **MISSING** | no notification system; email blocked | POST-CORE (needs SMTP + likely a new table) |
| Backup / recovery | local encrypted backup + restore-proof scripts present; off-site **default-off** (`SCA_BACKUP_REMOTE` empty → logged "NOT durable") | Local backups run; off-site not configured | **PARTIAL (external-config)** | off-site remote + uploader creds unprovisioned | operator configures off-site (SMALL code/none) |
| Staff permissions (ACL) | comprehensive dotted ACL across all actions | Enforced | **DONE** | — | none |

---

## Business-test summary
Jeremy and staff **can** run the full physical-frame lifecycle for real frames/customers today through the UI — intake (single/bulk) → authenticate+grade → photograph → certify → print QR → (Shopify sale) → buyer claim → My Collection → service → transfer → lost/stolen/recovered → provenance — **without a developer touching the DB/CLI/source**, with these caveats that currently need a non-code/external or manual step:
- **Password recovery** for collectors is the one journey that is broken without SMTP (reset email is logged, not sent).
- **Claim links and transfer invites** are distributed **manually** (copy the opaque link and send via the operator's own channel) — operable, not automated.
- **Shopify storefront** needs a one-time operator theme/metafield setup to attach `sca_item_ref` to real orders (SOP documented).
- **Staff have no in-app view** of which items have a Shopify sale awaiting claim (visibility gap, workaround via the dashboard).
- **Off-site backup** is not configured (local backups exist; DR gap).

---

## Reconciled remaining roadmap (easiest/highest-value → hardest)

### CORE — needed to operate SCA's intended lifecycle well

1. **Shopify Sale / Claim staff visibility** — *SMALL; no external dependency; implementable now.*
   - Business reason: close the staff side of the Shopify→claim loop; let staff see per item that a sale occurred and is awaiting claim (today only services know; the dashboard conflates never-sold with sold-unclaimed).
   - Missing capability: a read-only staff surface over `sca_shopify_sale_links` (eligible/claimed/revoked) — e.g. an item-detail "Sale / claim status" panel and/or a dashboard "sold, awaiting claim" worklist.
   - Implementation surface: a read-only controller/view (or extend the dashboard + item detail); reuse `sca.eyewear.view`/`sca.eyewear`. **No schema.**
   - External dependency: none. Blocks production: **No** (operability). Complexity: **SMALL**.

2. **Transactional email / SMTP activation** — *MEDIUM (code tiny; the work is external); external/DNS-gated.*
   - Business reason: make collector **password recovery** actually work, and enable **automated** claim-link + transfer-invite delivery instead of manual sharing. This is the top real-world operational dependency (recurring across SCA-053 and the SMTP readiness audit).
   - Missing capability: a live mail transport (provider) + verified sending domain; the app code is already present (reset notification) and hardened (enumeration-safe on transport failure).
   - Implementation surface: `.env` `MAIL_*` switch (no code), after provisioning an email provider (plan: Postmark over SMTP) + **DKIM/SPF on a dedicated SCA send subdomain** (the Shopify apex untouched). Optionally add transfer/claim notifications later.
   - External dependency: **YES** — email provider account + DNS records (operator/registrar). Blocks production: **Partially** (password recovery; the rest is operable manually). Complexity: **MEDIUM** (mostly external/ops, not code).

3. **Off-site backup configuration** — *SMALL (no app code); external-config.*
   - Business reason: durable disaster recovery; today backups are local-only ("NOT durable").
   - Missing capability: an off-site destination + credentials (`SCA_BACKUP_REMOTE` + rclone/S3) + a restore rehearsal.
   - Implementation surface: operator config + the existing scripts; no SCA app code. External dependency: **YES** (off-site storage + creds). Blocks production: **No** (risk, not function). Complexity: **SMALL**.

### POST-CORE — useful expansion, not required to operate SCA

4. **In-app collector notifications** — *MEDIUM/LARGE.* A notifications inbox/table so collectors are proactively told of transfers/claims/status. Pairs with SMTP for email. New table + UI. Not required (manual link-sharing + My Collection visibility suffice). Complexity **MEDIUM–LARGE**.
5. **Shopify webhook reconciliation UI** — *SMALL–MEDIUM.* A staff page to inspect/reconcile receipts/sale-links beyond the diagnostics count. POST-CORE. Complexity **SMALL–MEDIUM**.
6. **Service-event correction/annotation** — *MEDIUM.* Append-only correction of a mistaken service event (never edit/delete). Deferred from the service-history audit. Complexity **MEDIUM**.
7. **Post-core EXPANSION** — market value history, collector profiles, external paid-auth intake, resale/marketplace, analytics. **LARGE**; must not destabilize the provenance core. Lowest urgency.

---

## Recommended next task (ONE — not promoted)

**Shopify Sale / Claim staff visibility** (CORE, roadmap #1). It is the single highest-value change that is **implementable now with no external dependency**, read-only, no schema, and completes the staff side of the already-live Shopify→claim loop (removing the dashboard's never-sold vs sold-awaiting-claim conflation). It is independently auditable with the established zero-mutation gate.

**Caveat for the operator/ChatGPT:** the highest *business* dependency is **SMTP activation** (password recovery + automated link delivery), but it is **external/DNS-gated** (provider account + DKIM/SPF) and is therefore an operator-led provisioning task, not a self-contained Claude software feature — its code is already present/hardened and reduces to an `.env` switch once DNS is ready. If the operator can provision email+DNS, promote SMTP; otherwise the sale/claim staff-visibility task is the best implementable next step. **Neither is promoted here.**

**NEXT_TASK.md remains NONE / awaiting promotion.** No implementation performed. See `TASK_QUEUE.md`, `docs/SCA-PRODUCTION-CUTOVER-SMTP-READINESS-AUDIT.md`, `docs/SCA-053-PILOT-READINESS-AUDIT.md`.

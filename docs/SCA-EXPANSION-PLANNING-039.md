# SCA-EXPANSION-PLANNING-039 — Application Expansion Audit

**Type:** READ-ONLY planning/design. No product code, no schema, no migration, no deploy.
**Audited against:** implementation `main` @ `bd5b2e795c21c0828413554ac78f47216a982fa4` (accepted, pilot-validated).
**Method:** inspected live routes (`route:list`), controllers, services, migrations (schema), projections, views, and `docs/PRODUCT_REQUIREMENTS.md` (Jeremy Vision). Findings below cite actual code, not the historical roadmap.

**Deferred and untouched** (remain under `SCA-PRODUCTION-CUTOVER`, BLOCKED awaiting Jeremy): permanent domain/DNS/Caddy, permanent QR printing, Shopify live OAuth/webhooks, SMTP/provider config, off-server backup infra, retirement of the temporary `IP:8080` pilot exposure, production secrets/cutover.

## Legend
- **[JEREMY]** explicit requirement in `docs/PRODUCT_REQUIREMENTS.md`.
- **[ROADMAP]** existing backlog idea (`TASK_QUEUE.md` SCA-EXPANSION).
- **[GAP]** implementation gap vs. an existing requirement/feature.
- **[REC]** my recommendation (not previously stated).

---

## 1. Current-state inventory (what already exists)

| Area | Exists (evidence) | Missing |
|---|---|---|
| Staff collector lookup/support | — (no route; during the SCA-035 pilot, resolving "Collector #1" required a raw production DB query) | No in-app way to find a collector or list their items **[GAP]** |
| Collector profile/account mgmt | `collector/account` shows `display_name`+`email` (read-only); password change (036); password reset (037); privacy anonymize (018) | No **edit** of `display_name`/`email` (set only at register) **[GAP]** |
| Notifications | Only `CollectorResetPassword` notification; `MAIL_MAILER=log` | No claim/transfer/status/certification/service/security notifications; no in-app notification center; no prefs **[GAP]/[JEREMY-adjacent]** |
| Item metadata correction/editing | Intake `create`/`store`; no edit/update route | Cannot correct `brand`/`model`/`frame_serial` in-app; schema also **lacks** required Year, Country of origin, Materials, Original specifications **[GAP vs JEREMY]** (Digital Provenance Record §110) |
| Registry search/filtering | `admin/sca/eyewear` index: `search` (public_ref/brand/model LIKE) + `intake_type` filter | No status/certified/owner/date filters; no pagination surface; no saved views **[GAP]** |
| Reporting/export | — | No reports or export; **Insurance Report** PDF not built **[JEREMY future §175]** |
| Market/value history | — (no table) | **Market Information** fields absent **[JEREMY future §179]** |
| External authentication intake | `sca_external_claim_grants` + `external_intake` item type + staff claim-link issuance | No **customer-facing paid submission** flow **[JEREMY §101]** |
| Resale/listing/marketplace | — | Nothing **[ROADMAP]** |
| Collector documents/certificate access | `collector/collection/{ref}/documents/{handle}` download (certificate PDF surfaces here per 023) | Works for stored docs |
| Public passport from collector surfaces | My Collection detail *describes* the public passport in text | No **link** for the owner to view their item's public passport **[GAP vs JEREMY consumer "Digital Passport" §130]** |
| Staff dashboards/operational queues | Status queue (`admin/sca/status`, 022/024) | No broader operational dashboard/metrics **[GAP]** |
| Audit/history visibility | Ownership history (033); certification history (038); append-only ledgers | Present for ownership/certification; service/transfer history not surfaced to collectors |

Schema (21 tables) contains **no** table for notifications, valuation/market, marketplace/listings, or staff support notes.

---

## 2. Candidate family evaluation

### A. Collector experience
- **Exists:** account view, password change/reset, privacy anonymize, My Collection list+detail, document/certificate download, transfer, owner status actions.
- **Missing:** profile edit (`display_name`/`email`) **[GAP]**; "view my public passport" link **[GAP vs JEREMY §130]**; richer My Collection (brands-owned, service history, transfer history, downloadable records) **[JEREMY §189]**; notification prefs.
- **Value:** self-service correctness; trust (owner sees the public scan); dashboard completeness.
- **Dependencies:** none (data exists). Email edit interacts with login identity + reset.
- **Risks:** LOW. Email/display_name are non-provenance; SCA-036/037 already proved credential/attribute changes leave ownership byte-identical. `collector_account_id` is the immutable owner key.
- **Schema:** none for profile edit / passport link / history surfacing.
- **Complexity:** passport link/cert TRIVIAL; profile edit LOW; dashboard enrichment LOW–MED.
- **Sequencing:** NOW/NEXT.

### B. Staff operations
- **Exists:** registry index (basic search), item detail, ownership history+correction (033/035), certification correction (038), status queue+admin actions (022/024), documents, certificate, claim-link.
- **Missing:** collector support lookup **[GAP]**; item metadata correction **[GAP]** AND missing required descriptive fields (Year/Country/Materials/Specs) **[GAP vs JEREMY §110]**; advanced filters + pagination **[GAP]**; reports/export incl. Insurance Report **[JEREMY §175]**; operational dashboard **[GAP]**.
- **Value:** support efficiency; **eliminates raw-DB intervention** (integrity/security win); data accuracy; oversight.
- **Dependencies:** none for read-only lookup/filters; metadata correction needs an append-only audit design.
- **Risks:** collector lookup exposes collector PII to staff → must be ACL-gated, exact-match only (no enumeration/bulk export). Item metadata edit touches public-passport `brand`/`model` → must be append-only-audited + ACL. Filters/reports read-only.
- **Schema:** lookup/filters none; metadata correction likely an audit column/table + new descriptive columns; reports none (or read-model).
- **Complexity:** collector lookup LOW; filters LOW; metadata correction MED; reports/Insurance PDF MED.
- **Sequencing:** NOW (lookup) → NEXT (metadata correction, filters) → LATER (reports).

### C. Market/value history **[JEREMY future §179]**
- **Exists:** nothing.
- **Missing:** append-only MSRP / avg / high / low / last verified sale, "explicitly not an appraisal system" (Jeremy's words).
- **Value:** collector/market insight.
- **Dependencies:** none technical; product definition of "verified sale."
- **Risks:** MUST be a **separate informational ledger** that never affects provenance truth or the passport's certification validity. Flag: do not let value data enter ownership/certification projections.
- **Schema:** NEW append-only table.
- **Complexity:** MED. **Sequencing:** LATER.

### D. External paid authentication **[JEREMY §101]**
- **Exists:** external-intake item type + staff-issued claim grants (the *back half*: certify + claim).
- **Missing:** customer-facing **submission** (submit piece for paid authentication), payment, logistics/status tracking.
- **Value:** revenue; core Jeremy flow.
- **Dependencies:** payment + SMTP/notifications + (likely) production cutover.
- **Risks:** payment/identity/logistics; must funnel into the existing certification+claim ledgers, never a parallel ownership path.
- **Schema:** NEW (submissions, payments).
- **Complexity:** HIGH. **Sequencing:** DEFERRED (depends on deferred infra).

### E. Resale/marketplace **[ROADMAP]**
- **Exists:** nothing; transfer semantics exist (014).
- **Missing:** listing an owned certified item for resale.
- **Value:** marketplace expansion.
- **Risks:** HIGH. **Must reuse the existing append-only transfer ledger** for any ownership change on sale — a marketplace that writes ownership by any other path would violate the ownership/transfer contract. Payments/escrow/disputes are large product+infra.
- **Schema:** NEW (listings, offers).
- **Complexity:** HIGH. **Sequencing:** DEFERRED.

### F. Notifications **[GAP; JEREMY-adjacent]**
- **Exists:** `CollectorResetPassword` only; mail is `log`.
- **Missing:** claim/transfer/status/certification/service/security notifications; in-app notification center; preferences.
- **Value:** engagement + **security** (e.g., "your item was reported stolen", "a transfer was initiated on your item").
- **Dependencies:** **email delivery is blocked on SMTP (DEFERRED infra)** — but an **in-app notification center (persisted records)** is buildable now with no email.
- **Risks:** must not leak PII/provenance in notification bodies; security notifications must be reliable.
- **Schema:** NEW notifications table.
- **Complexity:** MED. **Sequencing:** NEXT (in-app center) → LATER (email delivery once SMTP exists).

---

## 3. Architectural boundary check

None of the NOW/NEXT items redefine permanent SCA item identity, the ownership ledger, the certification ledger, QR permanence, claim semantics, transfer semantics, or the public-passport privacy/security contract. Two flags for LATER/DEFERRED families:
- **C (market/value):** keep as a separate informational ledger; it must never feed ownership/certification projections or alter passport certification validity.
- **E (marketplace):** any sale-driven ownership change must go through the existing append-only transfer workflow, never a new ownership-write path.
- **Note (not a change request):** `PRODUCT_REQUIREMENTS.md` §136 lists a `CERTIFICATION_CHANGED` public scan state; the accepted SCA-038 decision is **Option A** (revoked → constant-shape 404, superseded → resolves successor). Any future desire for a distinguishable "certification changed" public state is a **change to the accepted SCA-020/034 passport contract** and must be raised as such, not designed around.

---

## 4. Ranked application roadmap

**NOW** (smallest, high-value, low-risk, infra-independent, read-only or provenance-neutral)
1. **[REC]** Collector "view my public passport" access from My Collection detail. ← recommended **SCA-040** (§5)
2. **[GAP]** Staff collector support lookup (read-only, ACL-gated, exact-match).
3. **[GAP/JEREMY §130,189]** My Collection enrichment: surface certificates, service history, transfer history (read-only; data exists).
4. **[GAP]** Collector profile edit (`display_name`, then `email`).

**NEXT**
5. **[GAP/JEREMY §110]** Staff item metadata: add required descriptive fields (Year/Country/Materials/Specs) + append-only correction with ACL + audit.
6. **[GAP]** Advanced registry filters + pagination (status, certified/uncertified, owner, dates).
7. **[GAP/security]** In-app notification center (persisted; claim/transfer/status/certification/service/security) — no email dependency.

**LATER**
8. **[JEREMY §175]** Insurance Report PDF (composed from existing provenance).
9. **[JEREMY §179]** Market/value informational ledger (separate; non-appraisal; provenance-neutral).
10. Reports/export + operational dashboard/metrics.
11. Email delivery for notifications (**needs SMTP — deferred infra**).

**DEFERRED** (require deferred infra or are large product bets)
- **[JEREMY §101]** External paid authentication submission (payments + logistics + SMTP).
- **[ROADMAP]** Resale/marketplace (payments/escrow; must reuse transfer ledger).
- All `SCA-PRODUCTION-CUTOVER` infrastructure (domain/DNS/Caddy, permanent QR printing, Shopify live, SMTP, off-server backup, pilot-exposure retirement, production secrets).

---

## 5. Recommended SCA-040 (smallest task) — do NOT activate

### SCA-COLLECTOR-PASSPORT-ACCESS-040 — collector "View public passport" from My Collection

**Problem statement.** A collector cannot see their own item's public passport from the app. `PRODUCT_REQUIREMENTS.md` treats the public "Digital Passport" as the consumer-facing verification surface (§130) and expects My Collection to expose certificates/records (§189), but My Collection detail only *describes* the passport in text with no link. Owners cannot verify what a scanner sees, reducing trust.

**Exact scope.** For a collector-owned item that currently has an active QR + current certification, add a read-only "View public passport" action in My Collection detail that opens the existing public passport for that item. Implemented as a collector-guarded redirect route (`GET collector/collection/{ref}/passport`) that server-side resolves the owned item's active QR `public_token` and redirects to the existing `/p/{token}` — so the raw token is not templated into the page and the URL keeps the opaque item `ref` convention.

**Non-goals.** No change to the public passport itself, its resolver, presenter, or privacy/security contract (SCA-020/034/038 Option A). No new public data. No QR/token changes. No exposure for items the collector does not currently own. No mutation of any kind. No certificate/document changes. No new descriptive fields.

**Routes/UI affected.** New: `GET collector/collection/{ref}/passport` (guard `collector.auth`, owner-only by `ref`). Modified: `sca-collector::collection.show` gains a conditional link (shown only when the owned item is currently certified with an active QR). No admin/public route changes.

**Data/schema impact.** **None.** Reads `sca_item_current_state` (active QR + current cert) and `sca_qr_identifiers` (public_token) for the owned item. No migration.

**ACL/privacy.** Reuses the existing collector guard; authorization is "the authenticated collector currently owns this item" (same rule as the existing collection detail/documents). Not exposed to staff or the public. The passport it links to is already the vetted, enumeration-safe public surface; showing an owner their own item's passport is not a new disclosure (the owner holds the physical QR). If the item is not currently certified/active, the action is not offered (and the route fails closed to the collection detail), so it never leaks a constant-404 path.

**Acceptance criteria.**
- Owner of a currently-certified, active-QR item sees the link and following it lands on that item's public passport (HTTP 200).
- A collector who does not currently own the item cannot reach the route (fails closed, no token disclosed).
- Unauthenticated/staff cannot use the collector route.
- Item not currently certified / no active QR → link not shown and route fails closed to My Collection.
- Zero mutation; ownership/provenance/QR/claims/transfers byte-identical before/after.
- Public passport behavior and privacy unchanged (same resolver/presenter).

**Regression boundaries.** No change to: public passport resolver/controller/presenter, ownership/certification/QR ledgers, claim/transfer workflows, collector auth/credentials, admin surfaces. Full `tests/Feature/Sca` suite must remain green; add focused tests for the new route's authorization + the conditional link.

**Alternative (if ChatGPT prefers operational over consumer value):** promote the read-only **staff collector support lookup** (NOW #2) instead — comparably small, read-only, and it eliminates the raw-DB intervention observed during the SCA-035 pilot.

---

**STOP — audit for ChatGPT review. SCA-040 recommended but NOT activated.**

# SCA-APPLICATION-EXPANSION-AUDIT-047 — READ-ONLY EXPANSION AUDIT

**Type:** Read-only planning / architecture audit. **No** implementation, branch, migration, schema change,
production mutation, PDF, or deployment was performed. SCA-048 is **not** promoted.

**Audit target:** deployed application `main` @ `bb52a9dae425a97e601f4e0ea88f063b5994401d` (SCA-046 merged +
deployed). Working tree clean; production untouched by this audit.

**Method:** read-only inspection of deployed routes/controllers/services/views/migrations/tests across four
domains (collector experience, staff operations, data/schema + cross-cutting infra, product vision/roadmap),
cross-referenced against `docs/PRODUCT_REQUIREMENTS.md`, `TASK_QUEUE.md`, `docs/SCA-EXPANSION-PLANNING-039.md`,
and the accepted ADRs.

---

## 1. Executive summary

The trusted append-only provenance **core** is built and pilot-validated: item identity + SCA-044 metadata,
authentication/condition grading, certification + immutable per-cert render snapshots (045) + deterministic
certificate PDF (023/045), permanent QR identity, event ledgers for ownership/transfer/status/certification/
QR/service, the collector portal (claim, My Collection, transfer, lost/stolen), the public passport (Option A
privacy contract), and governed staff corrections for ownership (035), certification (038) and item metadata
(046). SCA-039's entire NOW tier and most of its NEXT tier have since shipped (040/041/042/044/045/046).

The highest-value remaining work is **not** more certificate/metadata architecture. It is **surfacing
canonical data that already exists but is never shown**, on both sides:

- **Collector side:** the append-only ledgers hold each owner's acquisition, transfer, status-report and
  certification timeline, but the My Collection detail shows only the *current* snapshot. Most sharply, a
  **revoked certification is a silent downgrade** — the "View public passport" button just disappears with no
  explanation (collector "GAP D"). Ownership/transfer history (a named PRODUCT_REQUIREMENTS §110 field) is not
  surfaced at all.
- **Staff side:** there is **no operational dashboard** and the registry index has **no status/owner/date
  filter and no sorting**, so common worklists ("all lost items", "certified-but-unclaimed", "authentications
  awaiting finalize") require raw DB queries today.

Both classes are read-only, reuse `ProjectionService` + the existing event tables, and need no schema. That is
where the best value-to-risk sits.

**Single recommended next candidate (SCA-048, NOT promoted):** a **read-only collector "item history" timeline
on the My Collection item detail**, assembled from the canonical ledgers and privacy-scoped to the
authenticated owner — including an **explicit certification-status / revocation notice** so a de-verified item
is never a silent dead-end. Rationale and minimal scope in §5.

---

## 2. State of the product (what is already built)

- **Schema (confirmed):** append-only ledgers `sca_ownership_events`, `sca_transfer_events`, `sca_status_events`,
  `sca_certification_events`, `sca_qr_lifecycle_events`, `sca_service_events`, plus append-only
  `sca_certificate_snapshots` (045) and `sca_item_metadata_events` (046), each protected by `_no_update`/
  `_no_delete` triggers. Canonical projection `sca_item_current_state` is a rebuildable cache folded from the
  ledgers by `ProjectionService` (the lock target that serializes every mutating service). Identity metadata
  lives (mutable, current-value) on `sca_eyewear_items`; corrections are audited in `sca_item_metadata_events`.
- **Certificate artifacts:** deterministic, public-safe certificate PDF via `CertificatePdfService` (renders
  from the frozen snapshot when present, else v1 live-read fallback for pre-045 legacy certs). No PII/owner/
  staff/registry-status in the PDF by design.
- **Notifications:** effectively **absent**. The only SCA notification class is `CollectorResetPassword`
  (`['mail']` only); `MAIL_MAILER=log` (no SMTP). No `notifications` table, no in-app notification surface, no
  event→notify listeners on claim/transfer/status/certification.
- **Reporting/export:** only the certificate PDF. **No** provenance/ownership record, insurance report, or
  history bundle exists; all the underlying data is read-model-friendly and already folded by `ProjectionService`.
- **Market/value:** **none** (grep-confirmed zero valuation/price columns or code).
- **Shopify + external paid auth:** full scaffold built (OAuth, webhooks, sale-link processor) but **not live**
  (no `SHOPIFY_*` configured); external-intake is a label only — no payment/checkout code anywhere.
- **Legacy cert reconstruction (Option B):** **no code stub** beyond a passive `source='reconstructed'` CHECK
  value never written. Brand/model correction is blocked only on snapshot-less legacy certs; all 3 production
  certs are snapshot-less.

---

## 3. Classified gap register

Each gap: **user problem → reusable capability → missing capability → privacy/security → schema/migration →
mutation vs read-only → size/risk → dependencies → classification.**

### 3A. Collector experience  *(user-visible — the customer)*

**A1 — Certification-status transparency + honest revocation notice.** `NOW`
- *Problem:* when a cert is revoked with no successor, `current_certification_id` goes null and the item
  silently stops verifying (button vanishes, status downgrades to "Recorded") with no explanation to the owner —
  a trust dead-end on the product's core "does this verify?" promise.
- *Reusable:* `sca_certifications` (state, supersedes chain), `sca_certification_events` (issued/revoked/
  superseded + reason), `sca_certificate_snapshots`; `ProjectionService::currentCertification`.
- *Missing:* an owner-facing certification status/history read model + an explicit "certification no longer
  active" notice.
- *Privacy:* cert numbers/dates are already public (passport/PDF) → low; exclude staff refs/notes/internal ids.
- *Schema:* none. *Mutation:* read-only. *Size/risk:* SMALL / low. *Deps:* none.

**A2 — Ownership / transfer history for the owner.** `NOW`
- *Problem:* My Collection never shows "how/when I acquired this" or the owner's own transfer activity;
  PRODUCT_REQUIREMENTS §110 lists Ownership history + Transfer history as required record fields.
- *Reusable:* `sca_ownership_events` (claim/transfer_in/transfer_out/admin_correction + effective_at + reason),
  `sca_transfer_events`, `sca_transfer_requests`.
- *Missing:* an owner-scoped `ownershipHistoryForOwnedItem`-style read projection + view section.
- *Privacy:* **must** expose only the authenticated owner's own events/dates — never prior/next owner identity
  (`collector_account_id` of others) or `raised_by_staff_ref`. Acquisition method + dates are safe.
- *Schema:* none. *Mutation:* read-only. *Size/risk:* SMALL–MEDIUM / low (privacy scoping is the only care).
  *Deps:* none.

**A3 — Status-change history (lost/stolen/recovered).** `NOW`
- *Problem:* only the current registry banner shows; after report-lost-then-recovered the owner has no record of
  what they did or when. *Reusable:* `sca_status_events` filtered to item + `raised_by_collector_id`.
- *Missing:* owner-scoped status timeline. *Privacy:* own reports only; exclude `raised_by_staff_ref`.
  *Schema:* none. *Mutation:* read-only. *Size/risk:* SMALL / low. *Deps:* none.
- *(A1+A2+A3 are the natural components of one "item history" feature — see §5.)*

**A4 — Certificate PDF self-service.** `NEXT`
- *Problem:* the PDF exists only if staff manually clicked "generate"; a certified owner with no generated PDF
  sees no Documents section and no affordance. *Reusable:* deterministic `CertificatePdfService.ensureForItem`
  renders idempotently from the snapshot. *Missing:* an owner-triggered generate/stream affordance.
- *Privacy:* PDF is already PII-free → low. *Schema:* none. *Mutation:* on-demand generate persists one
  `sca_media_assets` row (mutation) — a read-only alternative is to stream the rendered snapshot without
  persisting. *Size/risk:* SMALL–MEDIUM / low–med (decide persist vs stream). *Deps:* none.

**A5 — Change email / display name.** `NEXT (display_name) / DEFERRED (email)`
- *Problem:* no self-service to change email or display name (only password + anonymize). *Missing:* profile
  edit. *Privacy/security:* email change needs re-verification to stay enumeration-safe — and verification email
  cannot send while SMTP is deferred, so **email change is blocked on SMTP**; display-name change is independent.
  *Schema:* none. *Mutation:* yes. *Size/risk:* SMALL (display_name) / MED (email). *Deps:* email→SMTP (cutover).

**A6 — Persistent navigation.** `LATER`
- *Problem:* no global nav; only inline "Back to…" links. Pure UX. *Schema:* none. *Mutation:* read-only.
  *Size/risk:* SMALL / low. *Deps:* none.

### 3B. Staff operations

**B1 — Operational dashboard.** `NEXT`
- *Problem:* no staff landing surface with registry totals, counts by lifecycle/registry status, pending-
  authentication / uncertified / unclaimed queues, or recent-activity feed; the paginated raw list is the de
  facto home. *Reusable:* `sca_item_current_state` (GROUP BY status/cert/owner), `sca_authentications`
  (draft/finalized), the `*_events` tables (created_at feeds). *Missing:* a dashboard controller/view + nav
  entry. *Privacy:* staff-only, aggregate. *Schema:* none. *Mutation:* read-only. *Size/risk:* MEDIUM / low
  (new surface, all data queryable). *Deps:* none.

**B2 — Registry index filters + sorting.** `NOW`
- *Problem:* index has only a search box + intake_type filter; cannot filter by lifecycle/registry status,
  owner, or date, and cannot sort — so status worklists ("all lost/certified/unclaimed/INTAKE") require raw DB.
  *Reusable:* index already joins `sca_item_current_state`; add bound WHERE + a sort whitelist. *Missing:* filter
  inputs + bound clauses. *Privacy:* staff-only. *Schema:* none. *Mutation:* read-only. *Size/risk:* SMALL / low.
  *Deps:* none.

**B3 — Admin lookup by QR / cert / grant token.** `NOW`
- *Problem:* staff scanning a physical QR (or holding a cert number/grant token) cannot reach the admin item
  page — index search excludes those tokens and the public passport resolves to the *collector* page. *Reusable:*
  bound search / a token→item resolver. *Missing:* extend search or add resolver. *Privacy:* staff-only.
  *Schema:* none. *Mutation:* read-only. *Size/risk:* SMALL / low. *Deps:* none.

**B4 — Ownership-correction discoverability.** `NOW`
- *Problem:* "Correct ownership" is linked only from the ownership-history page, which is itself linked only when
  ownership events exist → for a zero-event item the workflow is reachable only by hand-typing the URL. Also the
  registered owner shows as "Collector #\<id\>" with no link to collector-support. *Reusable:* existing
  quick-action link pattern; SCA-040 support view. *Missing:* a guarded item-detail link + owner→support pivot.
  *Privacy:* staff-only. *Schema:* none. *Mutation:* the link targets an existing mutation workflow; the link
  itself is read-only. *Size/risk:* TRIVIAL / low. *Deps:* none.

**B5 — Cross-item worklists.** `NEXT`
- *Problem:* "authentications awaiting finalize", "passed-but-uncertified", "certified external-intake with no
  claim link", "recent corrections/events" are all raw DB queries today. *Reusable:* the event/projection
  tables. *Missing:* saved read-only list views (largely subsumed by B1+B2). *Privacy:* staff-only. *Schema:*
  none. *Mutation:* read-only. *Size/risk:* SMALL–MEDIUM each / low. *Deps:* overlaps B1/B2.

**B6 — Collector lookup by email / name.** `NEXT (policy-gated)`
- *Problem:* SCA-040 finds collectors only by exact COL- ref; a collector who emails/phones support cannot be
  located → email→ref is a raw DB query. *Reusable:* SCA-040 `safeCollector` projection. *Missing:* a
  privacy-reviewed email→ref resolver (return the ref, not necessarily display email). *Privacy/security:* email
  lookup/display was **deliberately withheld** (SCA-040 docblock, PRODUCT_REQUIREMENTS §205) → needs an explicit
  privacy decision before building. *Schema:* none. *Mutation:* read-only. *Size/risk:* SMALL code / MEDIUM
  policy. *Deps:* privacy ruling.

### 3C. Notifications

**C1 — In-app notification center (no email).** `NEXT`
- *Problem:* collectors are never notified of transfer received/accepted, status changes, or certification
  changes. *Reusable:* existing events already fire in the mutating services. *Missing:* a persisted in-app
  notification store + surface + write hooks. *Privacy:* per-collector; no PII beyond the item context.
  *Schema:* **NEW** (`notifications`-style table) → this is the one high-value candidate that needs schema, so it
  is not the smallest read-only option. *Mutation:* yes. *Size/risk:* MEDIUM. *Deps:* none for in-app.
- **Email delivery:** `LATER` — blocked on SMTP (cutover). Do not design email delivery now.

### 3D. Collector records / reporting

**D1 — Downloadable provenance / ownership record (history bundle).** `LATER`
- *Problem:* no exportable provenance document. *Reusable:* all ledgers + snapshots are render-ready read models.
  *Missing:* a bundle renderer. *Privacy:* owner-scoped; reuse the certificate PDF's PII-free discipline.
  *Schema:* none. *Mutation:* read-only (or persist like the cert PDF). *Size/risk:* MEDIUM. *Deps:* best built
  **after** the on-screen collector history (A1–A3), which establishes the privacy-safe read projections.

**D2 — Insurance report PDF.** `LATER`
- PRODUCT_REQUIREMENTS §175 future feature; builds on D1. *Schema:* none required initially; value figures would
  depend on the market/value ledger (E1). *Size/risk:* MEDIUM. *Deps:* D1 (+ E1 for any value line).

### 3E. Market / value functionality

**E1 — Informational market/value history.** `LATER`
- PRODUCT_REQUIREMENTS §179, explicitly **not an appraisal system** (MSRP/avg/high/low/last-verified-sale).
  *Missing:* a **separate append-only** ledger (e.g. `sca_item_valuations`: item, amount, currency,
  valuation_type/source, effective_at, actor). *Privacy/security:* subjective/time-varying — **must not** touch
  `sca_certifications`, `sca_certificate_snapshots`, `sca_ownership_events`, or `sca_item_current_state`, and
  must never be folded into the canonical projection or the frozen certificate render inputs. *Schema:* **NEW**
  table. *Mutation:* yes (append-only). *Size/risk:* MEDIUM. *Deps:* explicit product sign-off on scope.

### 3F. External authentication / marketplace

**F1 — External paid-authentication intake (customer-facing).** `DEFERRED`
- Back half exists (external_intake type + staff claim grants); missing customer submission + payment + logistics.
  *Deps:* payment integration + SMTP + production cutover. *Size/risk:* HIGH.

**F2 — Resale / marketplace.** `DEFERRED`
- Nothing built; any ownership change **must** route through the existing append-only transfer workflow.
  Payments/escrow/disputes are large. *Deps:* cutover + payments. *Size/risk:* HIGH.

### 3G. Legacy certificate reconstruction (Option B)

**G1 — Verified legacy-snapshot reconstruction.** `DEFERRED (no current operational need)`
- *Reassessment:* the only thing blocked today is **in-place brand/model editing of an item whose current cert
  is a snapshot-less legacy cert**. All 3 production certs are snapshot-less, but there is **no demonstrated
  request** to correct brand/model on any of them, and two governed workarounds already exist without
  reconstruction: **revoke** the cert (leaves the item uncertified → fields unlock) or **supersede** to a new
  cert (successor gets a fresh 045 snapshot → fields unlock). *Recommendation:* **keep DEFERRED** — do not build
  Option B until a real correction need on a legacy-certified item is presented. *Schema:* would reuse the
  existing `source='reconstructed'` CHECK value (no new table). *Size/risk:* MEDIUM–HIGH / high (must produce a
  verifiable, non-fabricated snapshot). *Deps:* a demonstrated operational trigger.

---

## 4. Ranked roadmap

- **NOW (user-visible, read-only, existing data, no schema):**
  1. **Collector item-history timeline** (A1 revocation/cert-status + A2 ownership/transfer + A3 status) — *the
     recommendation, §5.*
  2. Staff registry index filters + sorting (B2) and admin token lookup (B3) — remove raw-DB worklists.
  3. Ownership-correction discoverability link + owner→support pivot (B4) — trivial.
- **NEXT:** staff operational dashboard (B1) & cross-item worklists (B5); collector certificate self-service
  (A4); in-app notification center (C1, needs schema); collector display-name edit (A5); collector email→ref
  support lookup (B6, policy-gated).
- **LATER:** downloadable provenance/insurance bundle (D1/D2); market/value informational ledger (E1, separate
  table); persistent collector nav (A6); email delivery (needs SMTP).
- **DEFERRED:** external paid-auth submission (F1), resale/marketplace (F2), legacy Option B reconstruction (G1),
  and everything under SCA-PRODUCTION-CUTOVER (permanent HTTPS domain, DNS/Caddy, Shopify live, permanent QR
  printing, SMTP, off-server backup rehearsal, pilot retirement).

---

## 5. Single recommendation (SCA-048 candidate — NOT promoted)

**Candidate: Collector read-only "item history" on the My Collection item detail.**

Surface, on the authenticated owner's item-detail page, a chronological history assembled from the canonical
append-only ledgers, privacy-scoped to that owner:
- **certification status** incl. an **explicit revocation / "no longer active" notice** (A1) — the sharpest fix,
  ending the silent-downgrade dead-end;
- **ownership / transfer** acquisition + the owner's own transfer activity (A2) — delivers PRODUCT_REQUIREMENTS
  §110 fields currently unmet;
- **status reports** the owner made (lost/stolen/recovered) (A3).

**Why this, on value-to-risk:**
- *User-visible* and central to the product's trust promise; directly fills named §110 record fields and closes
  a real dead-end (silent revocation).
- *Uses only existing canonical data* (`ProjectionService` + the event ledgers) — **no new infrastructure, no
  schema, no migration**; entirely **read-only** (no mutation, no production data risk).
- *Low, well-understood risk:* the only real care is privacy scoping — show **only the authenticated owner's own
  events**, never other owners' identities or any staff ref, reusing the codebase's established privacy-safe
  patterns (owner 404, allowlist DTOs, staff-ref exclusion). Cert numbers/dates are already public.

**Smallest viable first slice (if ChatGPT wants it minimal):** ship **A1 alone** — the certification-status +
revocation notice — as the tiniest, lowest-privacy-risk unit (cert data is already public, no cross-owner
concern), then add A2/A3 as a follow-on. This keeps the "smallest" option open while the timeline is the
coherent target.

**Explicitly preferred over:** the staff dashboard (B1, higher value but staff-facing and MEDIUM), the in-app
notification center (C1, needs a new table), and any market/marketplace/reconstruction work (new infra or
deferred). Per the directive, a user-visible improvement on existing canonical data wins.

**Architectural boundaries to honor when it is eventually built:** read-only only; must not alter the SCA-038
Option A public-passport contract (a distinguishable public `CERTIFICATION_CHANGED` scan state would be a change
to that accepted contract and must be raised as such, not designed around); owner-scoped privacy; no email.

---

## 6. Governance state (unchanged by this audit)

- **ACTIVE = NONE.** No task is executable.
- **NEXT_TASK.md = NONE.** No item promoted. ChatGPT may promote exactly one candidate after auditing this report.
- **SCA-048 not promoted / not started.** The §5 recommendation is a candidate only.
- **SCA-PRODUCTION-CUTOVER = BLOCKED / DEFERRED** (awaiting Jeremy's permanent HTTPS domain + access).
- Mail/SMTP and Shopify live activation remain deferred.
- Production and the temporary pilot exposure are **exactly as found**; this audit made no code, config,
  container, network, or data change.

# SCA-050 — Product Experience & Operations Audit — READ-ONLY PLANNING ONLY

**Type:** planning audit only. **No** implementation, feature branch, schema change, migration, mutation,
deployment, or SCA-051 promotion. **Audit target:** deployed `main`
`ec2b2efcaab6f9f8d4c8c236645285dd8158ec37` (SCA-049 DONE). **Method:** independent read-only re-inspection of
the deployed staff and collector surfaces end-to-end, cross-referenced against `docs/PRODUCT_REQUIREMENTS.md`,
the SCA-047 expansion audit, and everything shipped through SCA-049.

---

## 1. Executive summary

Through SCA-049 the **append-only provenance core and both actor workflows are complete**: staff
intake→authenticate→certify→claim-link→correct is fully wired and discoverable from the item detail; the
collector portal now has identity metadata (044), certification history + honest revocation notice (048),
ownership/transfer history (049), service history, documents (042), transfer, status reporting, and passport
access (041). No mutation-side workflow gap was found on either side.

The remaining high-value work is **not more provenance features**. It is **read-only staff operability** —
aggregate/filter/lookup surfaces over data the canonical projection (`sca_item_current_state`) already holds —
because today several *normal* staff operations have no in-app path and force **raw DB queries or hidden-URL
knowledge**. Plus a small collector-side correctness bug and some polish.

**Recommended SCA-051 (not promoted):** **Staff registry operational filtering & item lookup** — extend the
existing eyewear index with `lifecycle_state`/`registry_status`/owner/date filters and certification-number
search. It removes the single most frequent raw-DB operation ("which items are in state X?") and the
"physical item → admin page" dead-end, is read-only, small, and reuses the projection + the existing
paginated index. Rationale vs alternatives in §5.

---

## 2. What is already solid (no action)

- **Staff workflows** are complete and inline-discoverable from `eyewear/show.blade.php`: authenticate →
  finalize → "Certify from this authentication", claim-link issue/show/revoke, certificate PDF generate,
  metadata correction, certification correction. Intake redirects to the detail.
- **Adverse-status exception queue** (`StatusController@queue`) is projection-driven and actionable
  (resolve/retire/invalidate + SCA-024 admin-recover paths, with confirm interstitials).
- **Collector portal** is functionally complete for the core journey (claim → collect → transfer → status →
  passport), with privacy-safe 404s, enumeration-safe auth, and neutral 048/049 history labels.

---

## 3. Classified gap register

Each gap: user problem → reusable capability → missing capability → read-only/mutation → schema →
size/risk → dependency → **classification**.

### 3A. Staff operations *(the directive's priority: raw-DB / hidden-knowledge gaps)*

**S1 — Registry index cannot filter by status/lifecycle/owner/date; no sort.** `NOW`
- *Problem:* the index (`EyewearItemController@index`) offers only a free-text search over
  `public_ref/brand/model_name/frame_serial` + an `intake_type` dropdown, fixed `orderByDesc('id')`. Staff
  cannot pull "all CERTIFIED / all disputed / all INTAKE / this collector's items" — every such question is a
  **raw DB query**. *Reusable:* `sca_item_current_state` already holds `lifecycle_state`, `registry_status`,
  `current_owner_collector_id` (one JOIN); the index already paginates with `withQueryString`. *Missing:* bound
  WHERE clauses + filter inputs (+ optional sort whitelist). *Read-only. No schema.* SMALL / low. *Dep:* none.

**S2 — No lookup from a physical item (cert number / QR) to the admin detail.** `NOW`
- *Problem:* the admin item detail is addressed by numeric `{id}` only; scanning a QR resolves to the *public
  passport* (and only for currently-certified items), and a paper certificate number matches nothing in the
  index. An operator holding a physical item must run a **raw DB query** to map cert-number/QR-token → item.
  *Reusable:* `sca_certifications.certification_number`, `sca_qr_identifiers.public_token`; the index search.
  *Missing:* extend the bound search to certification_number (QR-token match needs a small security decision —
  tokens are otherwise never surfaced in list views). *Read-only. No schema.* SMALL / low. *Dep:* none.
  *(S1 + S2 are one coherent index enhancement — the recommendation, §5.)*

**S3 — Ownership-correction unreachable from the item detail.** `NOW`
- *Problem:* "Correct ownership" is linked ONLY from the ownership-history page, which is itself linked from the
  detail ONLY when `ownership events > 0`. So for a zero-ownership item (e.g. needing an initial administrative
  ownership correction) there is **no discoverable path** — staff must hand-type
  `sca/eyewear/{id}/ownership/correct`. *Reusable:* the existing inline quick-action link pattern.
  *Missing:* a guarded "Correct ownership" link on the detail (and/or always link ownership history).
  *Read-only template change.* TRIVIAL / low. *Dep:* none.

**S4 — Collector-support tool is not in any menu or linked anywhere.** `NOW`
- *Problem:* `CollectorSupportController` (SCA-040) has no admin-menu entry and is linked from nowhere; staff
  must know the `/admin/sca/collectors` URL (hidden knowledge). *Reusable:* the ACL/route already exist.
  *Missing:* a menu entry and/or a link from the item detail's owner row. *Read-only.* TRIVIAL / low. *Dep:* none.

**S5 — No operational dashboard / aggregate worklists.** `NEXT`
- *Problem:* no staff landing surface with registry totals, counts by status, or the worklists
  "authentications awaiting finalize", "passed-but-uncertified", "certified-but-unclaimed / no claim link".
  The *per-item* certified-unclaimed logic already exists on the detail (`EyewearItemController` lines
  ~165-177) — only the **aggregation** is missing; `SOLD_AWAITING_CLAIM` is even a defined lifecycle enum that
  `deriveLifecycleState` never emits. *Reusable:* projection GROUP BY + `sca_authentications.finalized_at`.
  *Missing:* a dashboard controller/view + nav entry. *Read-only. No schema.* MEDIUM / low. *Dep:* builds
  naturally on S1's filter plumbing.

**S6 — Collector lookup limited to exact COL- ref (no name/email).** `LATER (policy-gated)`
- *Problem:* a collector who contacts support without quoting their COL- ref cannot be found in-app → raw DB.
  *Missing:* a privacy-reviewed email→ref resolver. *Read-only.* SMALL code / MEDIUM policy — email/name lookup
  was **deliberately withheld** (SCA-040, PRODUCT_REQUIREMENTS §205), so it needs an explicit privacy ruling
  before building. *Dep:* privacy decision.

**S7 — No surfacing of integrity anomalies.** `LATER`
- `ProjectionService` can throw `ProvenanceIntegrityException` (>1 active QR) only on rebuild; nothing monitors
  or queues such conditions. Read-only; low frequency. LATER.

### 3B. Collector experience

**C1 — Misleading green "✓" authenticity badge on revoked/uncertified items.** `NOW (correctness)`
- *Problem:* the top badge in `collection/show.blade.php` is hard-coded green with a ✓; `authenticity_status`
  falls to `'Recorded'` when the item is uncertified or **revoked** (`current_certification_id` null), so a
  revoked item still shows a green "✓ Recorded" badge — directly contradicting the SCA-048 "no active
  certification" notice a few rows below. This overstates authenticity and undercuts the whole 048 honesty
  fix. *Missing:* neutral/greyed badge when not currently certified. *Read-only view fix.* TRIVIAL / low.
  *Dep:* none.

**C2 — Item-detail redundancy/clutter after stacking 044/048/049.** `NEXT`
- *Problem:* one flat card with pseudo-headings; registry status shown ~3×, certification ~3× (identity rows
  duplicate the 048 "Current" entry), ownership 2× ("Registered to you" duplicates the 049 "Added to your
  collection"). Long single scroll, weak scannability. *Missing:* sectioning + pruning the now-duplicated
  single-line rows. *Read-only view change.* SMALL / low. *Dep:* none.

**C3 — No collector status-report history (lost/stolen/recovered timeline).** `NEXT`
- *Problem:* SCA-049 folded *ownership* only; the collector sees the current registry state but not the dated
  sequence of their own lost→recovered reports, though `sca_status_events` records them. *Reusable:*
  `sca_status_events` scoped to item + `raised_by_collector_id`. *Read-only. No schema.* SMALL / low. *Dep:*
  none. **Note:** the brief explicitly warned not to assume "another history feature" is next — so despite
  being a legitimate gap, this is **NEXT, not the recommendation**.

**C4 — Cannot edit display_name (or email).** `NEXT (display_name) / DEFERRED (email)`
- *Problem:* the account page shows name+email but offers no edit (only password + anonymize). *display_name*
  edit is a small mutation with no SMTP dependency; *email* is the login identifier + reset target, so a
  proper change needs verification → **SMTP-blocked**. *Schema:* none. SMALL / MED. *Dep:* email→SMTP.

**C5 — No global navigation header.** `NEXT`
- *Problem:* `layout.blade.php` has only a brand mark; each page hand-rolls a "Back to X" link; reaching
  Account/Sign-out from the detail is indirect. *Missing:* a shared header (Collection · Account · Sign out).
  *Read-only view change.* SMALL / low. *Dep:* none.

**C6 — No self-service certificate PDF; silent empty Documents state.** `LATER`
- *Problem:* the certificate PDF appears only if staff generated it; otherwise the Documents section is hidden
  with no explanation. *Missing:* either an owner-triggered render (heavier; on-demand render = mutation; builds
  on the 045 snapshot pipeline) or, minimally, an empty-state note. *Read-only copy* (small) vs *render feature*
  (larger). *Dep:* none for copy; cert-render for full. LATER.

**C7 — Transfer edges: guest-recipient round-trip + silent sender completion.** `LATER`
- Verify the transfer-accept token/intended-URL survives the login round-trip for a brand-new recipient (the
  Claim flow documents this; the transfer flow doesn't); and consider a one-line "Ownership transferred" notice
  to the sender whose item silently vanishes. Read-only to verify / session-flash. LATER.

### 3C. Notifications & delivery — `DEFERRED (SMTP / cutover)`

**D1 — Password recovery is effectively non-functional in production.** `DEFERRED`
- `MAIL_MAILER=log`: the SCA-037 reset email only writes to the log, so **password recovery does not work in
  production until SMTP cutover** — the single most user-impacting SMTP-blocked item. The forgot-password page
  promises a reset link it cannot send. Not fixable before cutover; flagged for SCA-PRODUCTION-CUTOVER.

**D2 — No collector notifications** (transfer received/accepted, status change, certification change). All
depend on SMTP. The 048/049 history sections are the deliberate in-app compensation. A future **in-app**
notification centre could work without email but needs a new table (NEXT-tier, its own task); **email delivery
is DEFERRED** to cutover.

### 3D. Carried forward from SCA-047 — `LATER / DEFERRED`
Downloadable provenance/insurance bundle (LATER), market/value informational ledger (LATER, separate append-only
table, non-appraisal), external paid-auth submission / resale-marketplace / legacy Option-B reconstruction
(DEFERRED, unchanged — no new operational trigger), and everything under SCA-PRODUCTION-CUTOVER (DEFERRED).

---

## 4. Ranked roadmap

- **NOW (small, read-only, high value, no schema):** **S1+S2 staff index filter & item lookup [→ SCA-051]**;
  S3 ownership-correction link; S4 collector-support menu/link; C1 fix the misleading green badge.
- **NEXT:** S5 staff operational dashboard + aggregate worklists (built on S1); C2 detail sectioning/prune;
  C3 collector status-report history; C4 edit display_name; C5 global nav; in-app notification centre (new table).
- **LATER:** S6 collector lookup by email/name (privacy ruling); S7 integrity-anomaly surfacing; C6 certificate
  self-service / empty-state copy; C7 transfer edges; downloadable provenance/insurance bundle; market/value
  ledger; QR-token admin lookup (security decision).
- **DEFERRED (SMTP / cutover / big infra):** D1 functional password recovery, D2 email notifications, email
  change; external paid-auth, marketplace, legacy Option-B reconstruction; SCA-PRODUCTION-CUTOVER.

---

## 5. Single recommendation (SCA-051 candidate — NOT promoted)

**Candidate: Staff registry operational filtering & item lookup (S1 + S2).** Extend the existing
`EyewearItemController@index` / `eyewear/index.blade.php` with: (a) filters on `lifecycle_state` and
`registry_status` (and owner + created-date), driven by a JOIN to `sca_item_current_state`; (b) certification-
number search in the bound search. Read-only, no schema, reuses the already-paginated index; a QR-token match is
explicitly out of this slice pending a security decision.

**Evidence it beats the alternatives:**
- *Highest-frequency real-world value / removes raw-DB dependence:* "which items are in state X?" and "find the
  item for this physical certificate" are core daily staff operations that **today have no in-app path** and
  force raw DB queries — exactly the class of gap the brief prioritises. S1+S2 close both.
- *Smallest useful slice on existing surface:* one controller + one view, all data already in the projection —
  no new route/table/mutation, low risk. It is strictly smaller and lower-risk than the operational dashboard
  (S5), which it also **unblocks** (the dashboard's status counts/worklists reuse the same projection filter
  plumbing) — so S1+S2 is the correct first step, S5 the natural NEXT.
- *Higher value than the trivial discoverability fixes (S3/S4/C1):* those are worth doing but each is narrow;
  the index filter has broad, everyday reach across all staff sessions. (C1 the green-badge bug is a genuine
  correctness item and should be scheduled soon regardless — it is tiny — but it is lower-frequency than the
  filter and does not, by itself, remove a raw-DB workflow.)
- *Not a collector-history feature:* per the brief, SCA-051 deliberately does **not** extend collector history
  (C3), and it prioritises the staff operability the app most lacks now that the collector journey is built out.

---

## 6. Governance state (unchanged by this audit)

- **ACTIVE = NONE; NEXT_TASK = NONE.** Recorded DONE in `TASK_QUEUE.md` (SCA-039/047/049 planning convention);
  no implementation task promoted. **SCA-051 not promoted / not started** — the §5 recommendation is a candidate
  only; ChatGPT may promote one after review.
- **SCA-PRODUCTION-CUTOVER remains BLOCKED/DEFERRED** (permanent HTTPS domain + SMTP + Shopify live, incl. the
  D1 password-recovery dependency).
- Production and the pilot are exactly as found; this audit made no code, config, container, network, or data
  change.

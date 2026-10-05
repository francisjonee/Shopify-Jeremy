# SCA Real-World Pilot Readiness + Operator Workflow Audit (READ-ONLY)

**Date:** 2026-10-05 · **Production baseline:** `98ae654`, migrations **120**.
**Status: AUDIT / SOP ONLY. No code, no DB write, no production customer/item/QR/status/claim created. STOP for
ChatGPT / operator review.** Traced against the deployed implementation (routes/controllers/services/views cited);
behavior is not inferred.

Purpose: document the complete operator+customer workflow end-to-end for SCA's first real physical-item pilot in
the Naga office, with a staff SOP, a deep-dive on the permanent physical QR, and a categorized blocker list.

---
## 1. End-to-end lifecycle (traced)

Legend — **Who**; **UI/route**; **Prereq**; **Writes**; **Reversible?**; **Mistake/recovery**; **Customer sees**;
**Physical (outside software)**; **Blocker**.

### Stage 1 — Admin intake (create item)
- **Who:** staff (`sca.eyewear.create`). **UI:** `GET admin.sca.eyewear.create` form → `POST
  admin.sca.eyewear.store` (`EyewearItemController@create/@store`, `create.blade`). **Prereq:** physical item in
  hand. **Writes:** `sca_eyewear_items` (auto `public_ref`) + `sca_item_current_state` (lifecycle `INTAKE`,
  registry `normal`). Fields: `intake_type` (**`sce_presale`|`external_intake`**, required), nullable
  `brand/model_name/frame_serial`, optional `year/country_of_origin/materials/original_specifications`.
- **Reversible:** no hard-delete route exists by design; field errors fixed via append-only
  `admin.sca.eyewear.metadata.correct` (brand/model lock once a cert snapshot exists). **Recovery:** metadata
  correction. **Customer sees:** nothing. **Physical:** receive/inspect item. **Blocker:** none.

### Stage 2 — Evidence / photos
- **Who:** staff (`sca.eyewear.catalog` for gallery, `sca.eyewear.document` for private evidence). **UI:** gallery
  manager on the item detail (`images.store`/`images.reorder`/`images.delete`, ≤8 images, ≤4 MB, jpg/png/webp,
  ≤10000px/≤50 MP) + documents (`document.store`/`document.download`, opaque handle, `is_public` opt-in). **Writes:**
  `sca_eyewear_item_images`, `sca_media_assets`. **Reversible:** images reorder/delete; documents append-only.
  **Customer sees:** gallery images later appear on their collector item view + the primary image on the public
  passport. **Physical:** photograph the item. **Blocker:** none.

### Stage 3 — Authentication
- **Who:** staff (`sca.eyewear.authenticate`). **UI:** `authentication.create` → `authentication.store`
  (draft, mutable) → `authentication.finalize` (`authentication/create.blade`). **Writes:** `sca_authentications`
  (`result` **passed|failed|inconclusive**, `condition_grade` **A–D** if passed, private `notes`, `finalized_at`).
  **Reversible:** draft editable until finalize; finalized rows are immutable (DB trigger). **Recovery:** record a
  fresh authentication / later supersede the cert. **Customer sees:** after certification, condition grade +
  authenticated date on the passport. **Physical:** the actual expert authentication of the eyewear. **Blocker:**
  none in software (business: who is the qualified authenticator — see §5).

### Stage 4 — Certification (mints the QR)
- **Who:** staff (`sca.eyewear.certify`). **UI:** "Issue certification" on the Cert&QR tab → `POST
  admin.sca.eyewear.certification.issue` (input: `authentication_id` only). **Prereq:** a same-item **passed +
  finalized** authentication; item not already certified. **Writes:** `sca_certifications` (`state=issued`,
  `certification_number SCA-CERT-YYYY-XXXXXXXX`) + `sca_certification_events(issued)` + **mints & activates the QR**
  (`sca_qr_identifiers` + `sca_qr_lifecycle_events(activated)`) + immutable cert snapshot. Lifecycle → `CERTIFIED`.
  **Reversible:** `certification.revoke` (→ passport 404) or `certification.supersede` (new cert) via
  `sca.eyewear.certification.correct`. **Customer sees:** the public passport now resolves (200). **Physical:**
  none. **Blocker:** none.

### Stage 5 — Permanent QR generation / download
- **Who:** staff (`sca.eyewear.view`). **UI:** "Download printable QR (SVG)" on the Cert&QR tab → `GET
  admin.sca.eyewear.qr` (`EyewearItemController@qr`). **Read-only** — never mints/rotates a QR. Returns a
  standalone **SVG** (`sca-qr-<public_ref>.svg`, `no-store`) encoding `app.url + /p/{token}` of the item's current
  active QR. **Reversible:** re-download the same artifact anytime; rotate only via reissue (§Stage 11).
  **Customer sees:** nothing (internal). **Physical:** **print the SVG and attach to the item/case/card** (§2).
  **Blocker:** none in software; printing/label is operational (§5).

### Stage 6 — Public scan
- **Who:** anyone with a phone. **UI:** `GET /p/{token}` (`PassportController@show`). 200 iff token = the item's
  active QR **and** a current issued cert exists; otherwise one constant-shape 404. Shows SCA logo, authenticity/
  certification, item facts, primary image, and (deployed) registry warnings; invalidated shows a historical,
  non-current notice. **Customer sees:** the verification passport. **Physical:** scan the printed QR. **Blocker:**
  none.

### Stage 7 — Collector (customer) account
- **Who:** the customer, **self-service** (`collector.guest`). **UI:** `collector.register` / `collector.login`.
  **Writes:** `sca_collector_accounts` ONLY (opaque `COL-…` ref, `email`, optional `display_name`, hashed password,
  `status=active`). **No email-verification gate** (column exists, unenforced) — login + claim work without email.
  **Reversible:** self-anonymization via `collector.privacy.destroy`. **Customer sees:** their account + "My
  collection". **Physical:** none. **Blocker:** none for login/claim; **operational:** `mailer=log` → password-
  reset emails are only written to the log, never sent (§5).

### Stage 8 — Claim / ownership (external-intake pilot path)
- **Who:** staff issues the grant (`sca.eyewear.claim`); the customer claims. **UI (staff):** "Issue claim link"
  on the item detail → `admin.sca.eyewear.claimlink`; the claim URL is shown in a **copyable field** ("Copy it and
  send it to the buyer… works once"), with "Show link again" and "Revoke claim link…". **Prereq:**
  `intake_type=external_intake` + current issued cert + no current owner + non-adverse. **Writes:**
  `sca_external_claim_grants(issued, grant_token)`. **UI (customer):** `GET/POST collector.claim.grant.show/perform`
  (requires collector login; anonymous → redirected through login/register then back). **Writes on claim:**
  `sca_claims` + `sca_ownership_events(claim)`, grant → `consumed`, lifecycle → `REGISTERED`. **Reversible:**
  append-only; staff `ownership.correct` for mistakes; grant `revoke` before use. **Customer sees:** "added to your
  collection". **Physical:** operator must **deliver the claim link to the customer manually** (no SMTP) — printed
  on the card, or via a messaging channel. **Blocker:** operational (link delivery); the `sce_presale` claim path
  depends on a Shopify sale-link (`sca_shopify_sale_links`) that is **not wired for the pilot** → use
  **external_intake + staff grant** (business/path choice, §5).

### Stage 9 — Transfer (owner → new owner)
- **Who:** the owning collector initiates; the recipient accepts. **UI:** `collector.transfer.show/initiate`
  (owner, by item ref) → single-use `invite_token`; `collector.transfer.accept.show/accept` (recipient).
  **Writes:** `sca_transfer_requests` + `sca_transfer_events(accept)` + `sca_ownership_events(transfer_out/in)`.
  **Reversible:** `collector.transfer.cancel` while pending; after accept, a new transfer back. Stale/self/adverse
  fail closed. **Customer sees:** transfer screens; the new owner's passport/collection. **Physical:** owner shares
  the invite link manually (no SMTP). **Blocker:** operational (link sharing) — not required for a first single-item
  pilot.

### Stage 10 — Lost / stolen / recovered / disputed
- **Who:** owner (collector) for lost/stolen/recovered; staff for disputed/resolve and the owner-orphaned recovery
  valve. **UI (owner):** `collector.status.{lost,stolen,recovered}.confirm` → POST (explicit confirm). **UI
  (staff):** `admin.sca.status.*` queue/show/resolve + SCA-024 `admin.recover/retire/invalidate`. **Writes:**
  `sca_status_events` (append-only); ownership/cert/QR untouched. **Reversible:** recovered clears lost/stolen;
  disputed→normal. **Customer sees:** color-coded passport warnings (REPORTED LOST/STOLEN / UNDER REVIEW).
  **Physical:** none. **Blocker:** none.

### Stage 11 — QR damage / reissue
- **Who:** staff (dedicated `sca.eyewear.qr.reissue`, not view/certify). **UI:** "Reissue QR (lost / damaged tag)"
  → `qr.reissue.confirm` (typed `REISSUE` + reason + hidden `expected_active_qr_id`) → `POST qr.reissue`
  (`QrService::reissue`). **Prereq:** item has a current active QR (else 409). **Writes:** new `sca_qr_identifiers`
  + three `sca_qr_lifecycle_events` atomically — `revoked`(old), `reissued_from`(new→old), `activated`(new) — under
  the item lock with an optimistic-concurrency guard (stale/double POST fails closed, no orphan). **Reversible:**
  append-only (reissue again). **Customer sees:** the **old printed QR stops resolving (404)**; the **new QR
  resolves the same provenance record** (same item/cert/history). **Physical:** download + print + attach the NEW
  label; retire the old tag. **Blocker:** none in software; reprint/reattach is operational.
- **Reprint vs reissue (important):** a merely *damaged-but-not-compromised* tag does **not** need a reissue —
  just **re-download the same SVG** (Stage 5) and reprint; the token is unchanged. Use **reissue** only when the old
  physical tag must be invalidated (lost, cloned, or security concern).

### Stage 12 — Retirement / invalidation
- **Who:** staff (`sca.eyewear.status`), L2 typed confirm (`RETIRE`/`INVALIDATE`) + required reason. **Writes:**
  `sca_status_events` (terminal, **irreversible** — no reactivation). **Customer sees:** Retired → 200 historical
  passport with RETIRED warning + authenticity retained; Invalidated → 200 historical notice, **no** green badge
  (just deployed). **Physical:** none. **Blocker:** none.

## 2. Permanent physical QR — deep dive (traced + guidance)

**Artifact (traced, `EyewearItemController@qr` + `chillerlan/php-qrcode ^6.0`):**
- A **standalone SVG** (`image/svg+xml`, attachment `sca-qr-<public_ref>.svg`), vector → **prints at any size with
  no quality loss**. Self-contained: explicit per-module `#000`/`#fff` fills (scannable without any external CSS).
- **Error correction: level H** (~30% recovery) — the most damage-tolerant level; good for a small, handled eyewear
  tag and tolerant of a modest logo overlay.
- **Quiet zone: 4 modules** (QR-spec minimum) built in.
- **Payload:** `config('app.url') + /p/{token}` = `https://verify.secondchanceauthenticators.com/p/<32-hex token>`.
- **No caption, no logo, no human-readable text** in the artifact — it is a bare QR.

**Suitable to print as-is?** Yes as a scannable code (vector, ECC-H, correct quiet zone). But because it carries
**no human-readable text**, SCA should design a label *around* it. The artifact itself needs no change to be
scannable.

**Recommended accompanying text (label design — operator/business choice):** the SCA public reference
(`public_ref`), a short instruction ("Scan to verify authenticity — Second Chance Authenticators"), and optionally
the domain (`verify.secondchanceauthenticators.com`). Keep the token OUT of any printed text (it's inside the QR
only).

**Minimum practical size (guidance — confirm by scan test):** the SVG is module-based (no fixed mm). A ~60-char
HTTPS URL at ECC-H yields a moderately dense symbol, so print the **code area at ≥ ~20 mm square (≈25 mm target),
plus the built-in 4-module quiet zone**, on a label of roughly **25–30 mm**. **Do a real phone scan test at the
intended size/material/lighting before committing to a label run** — this is the authoritative check, not a
computed dimension.

**Material / adhesive / tamper (eyewear-specific):** frames are small, curved, oily (skin contact), and cleaned
with solvents; flat area is limited to the inner temple arm. Options and trade-offs:
- **Certificate / card (recommended primary):** a printed SCA card is the most durable, highest-print-quality,
  professional home for the QR and human-readable text; it does not alter the item. Downside: separable from the
  item.
- **Case (interior):** safe, non-damaging, roomy; also separable.
- **Directly on the frame (temple interior):** smallest footprint but hardest to adhere (curved/oily), risks
  **materially altering a collectible** and may not survive cleaning; needs a durable laminated PET/polyester
  tamper-evident micro-label and owner consent.
Recommended default: **QR on the SCA certificate/card** (authoritative) **plus optionally a tamper-evident label
inside the case**; avoid adhering to a collectible frame unless the owner consents. **Attachment location is a
business decision** (§5).

**Damage / lost / reprint / reissue (traced):**
- Damaged-but-trusted tag → **reprint the same SVG** (Stage 5), token unchanged, passport unchanged.
- Compromised/lost tag → **reissue** (Stage 11): old token → constant-shape **404**, new token → the **same**
  `eyewear_item_id` + same cert/auth/ownership → same passport. **Proof (no production mutation):** the resolver
  honors only the token equal to `active_qr_identifier_id` and binds every step to the QR's own item; the deployed
  test **`PublicPassportTest::p7` (`stale_qr_cannot_resolve_after_reissue`)** asserts old→404 and new→200 with the
  same `public_ref`. Reissue carries the `is_production` marker and links new→old via `reissued_from`.

## 3. Customer information — obtain vs. do-not-enter

**Must obtain from the customer (minimum):** an **email address** they will use to self-register the collector
account (login + the only account-recovery handle). Optionally a **display name** they choose. That is all the
account requires.

**Operator does NOT enter customer PII into SCA:** the collector account is **self-registered** by the customer;
there is no staff "create collector" path, and staff collector-support is read-only (staff email display is not
authorized). The operator's customer-facing action is to **hand over the claim link** — not to type the customer's
details into SCA.

**Must NOT be entered unnecessarily:** no phone, postal address, legal name, ID number, or payment data anywhere —
no fields exist for them and they must not be shoehorned into `display_name`, item fields, authentication `notes`,
`original_specifications`, or documents. `frame_serial`/`notes`/`original_specifications` are private/internal and
must never contain customer-identifying data.

## 4. Proposed Naga-office SOP — first pilot item (staff checklist)

Prerequisites: a staff admin account reaching `/admin` from an allowlisted office IP; a printer + label/card stock;
a phone to scan-test.

1. **Receive & record.** Create the item: Admin → SCA → Eyewear → Create. Set **intake_type = external_intake**.
   Enter brand/model and any public facts (year/country/materials). Do **not** enter any customer data. (→ item
   `public_ref`.)
2. **Photograph.** Add gallery images (clear, well-lit; the first/featured becomes the public primary image). Add
   any private evidence as a Document (leave `is_public` off unless intended).
3. **Authenticate.** Record an authentication; if genuine, set result **passed** + condition grade (A–D), then
   **Finalize** it. (Finalized = immutable.)
4. **Certify.** On the Cert&QR tab, **Issue certification** from the finalized passed authentication. This creates
   the certificate number and **activates the permanent QR**.
5. **Generate the QR.** Click **"Download printable QR (SVG)"**. Place it on the SCA **card/certificate** (and/or a
   case label) with the human-readable text (SCA ref + "Scan to verify"). **Scan-test** the printed label with a
   phone before handing it over.
6. **Verify publicly.** Scan the printed QR → confirm the passport shows 200, correct item, "Authenticated &
   Certified", and the correct image.
7. **Issue the claim link.** On the item detail, **Issue claim link**, copy the shown URL, and give it to the
   customer (printed on the card or via a messaging channel). Tell them: create/sign in to a collector account at
   `/collector`, then open the link to register ownership. (It works once.)
8. **Customer registers ownership.** Customer self-registers (email + password), opens the claim link, claims →
   item appears in "My collection"; passport unchanged (ownership is private).
9. **Hand-off note.** Explain that if the tag is ever damaged, SCA can reprint it; if lost/compromised, SCA can
   reissue (old tag stops working, provenance preserved); and that lost/stolen can be reported from their account.

Do **not**, during the pilot: enter customer PII into SCA; attach a label to a collectible frame without consent;
reissue a QR for a merely damaged (still-trusted) tag (reprint instead); retire/invalidate except deliberately
(irreversible).

## 5. Findings (categorized)

**Software blockers:** **none identified.** The digital lifecycle intake→passport→claim→transfer→status→reissue→
terminal is complete, ACL-gated, append-only, and covered by the full `tests/Feature/Sca` suite. (Consistent with
the earlier pilot-readiness verdict.)

**Operational blockers (must be solved in the office, not in code):**
- **QR label production:** printer + durable label/card stock + a label design (QR + human-readable text) + a
  scan-test step. The downloadable artifact is QR-only; the label is a physical deliverable.
- **Claim/transfer link delivery is manual** (no SMTP): the operator copies the claim link from the item detail and
  gives it to the customer; transfers rely on the owner sharing the invite link. Fine for a single-item pilot.
- **No outbound email** (`mailer=log`): customers cannot self-serve password reset by email; handle recovery
  operator-assisted until SMTP is configured.
- **Authentication process/standards:** who performs the expert authentication and what evidence is required is an
  office process, not software.

**Business decisions (operator/leadership):**
- **QR attachment policy:** card/certificate vs case vs direct-to-frame (recommended: card primary, optional case
  label; avoid frame without consent) + the minimum label size/material spec (sign off after the scan test).
- **Accompanying printed text/branding** on the label.
- **Pilot path:** use **external_intake + staff grant** for the pilot (the `sce_presale`/Shopify sale-link claim
  path is not wired); confirm.
- **Permanent-domain commitment:** printed QRs hard-code `verify.secondchanceauthenticators.com` — this domain must
  remain the SCA verification host **permanently** (changing it would break already-printed tags). Confirm as a
  standing commitment.
- Pilot cohort/selection and any authentication fee/pricing (out of software scope).

**Optional future enhancements (not needed for the pilot):**
- **SMTP** → claim/transfer notifications + customer-self-serve password reset (branch/plan already audited).
- **Richer QR artifact:** optionally embed the human-readable caption + SCA logo and/or offer a PNG/PDF label-sheet
  layout directly from the download (today it is a bare SVG; the label is assembled manually).
- **In-app "copy claim link" affordance** is already present; a QR-of-the-claim-link for in-person hand-off could
  be added.
- **Shopify sale-link claim path** (deferred; OAuth branch preserved) for the `sce_presale` retail flow.

---
**No code/DB/status/QR/claim/customer mutation performed.** Governance only; ACTIVE/NEXT unpromoted. STOP for
ChatGPT/operator review. See [[sca-053-pilot-readiness-audit]], [[sca-production-cutover-phase1]] (SMTP/edge),
[[sca-public-passport-trust-safety-audit]], [[shopify-connect-009-deferred]], [[report-to-github-first]].

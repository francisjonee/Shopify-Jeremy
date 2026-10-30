# SCA — Collector Document-Management Gap Analysis (read-only)

**Collectors already have a complete, practical document experience for the scope Jeremy requires —
securely VIEW and DOWNLOAD SCA-authoritative documents — and collector document UPLOAD is neither
required by Jeremy nor safe to add, so no capability was built.** Read-only review; no code change, no
branch, no production change (prod `b007606`). 2026-10-30. **STOP.**

## 1. Requirements evidence (what Jeremy asks for)
From `docs/PRODUCT_REQUIREMENTS.md` / `docs/ROADMAP.md`:
- Digital Provenance Record includes **inspection images** (staff-captured), certification status,
  ownership/transfer/service history.
- My Collection "should eventually include … Certificates, Service history, Transfer history,
  **Downloadable records**, Optional purchase/insured-value summaries." ("Downloadable" = retrieve, not
  upload.)
- Insurance Report (PDF).
- Roadmap Phase 9 `SCA-DOCUMENTS-017` = "authentication/ownership/provenance/insurance documents,"
  under the goal **"produce durable documents from trusted SCA data."**

**There is no requirement — explicit or implied — for collectors to upload their own item documents.**
The provenance model is that SCA/staff author authoritative records from trusted data; collectors view
and download. The word "upload" never appears for collectors in the requirements (the only collector
upload anywhere is the profile avatar, unrelated to item documents).

## 2. What already exists (implemented — excluded from development)
- **Documents tab** (`collection/show`): lists an item's **collector-visible** media
  (`visibleDocumentsForOwnedItem`, `is_public=1` only), labelled by kind — **Certificate (PDF)**
  (with current / superseded badge + public certification number), **Photo**, **Document** — each with a
  date and a **Download** link (`CollectionDocumentController` → `ownerVisibleDocument`). No
  collector-wide document enumeration; reachable only from the owner's own item.
- **Certificate access:** the immutable per-certification certificate PDF, downloadable here; plus the
  just-added **owner-triggered on-demand availability** (`a923dfd`) so an owner can make a missing
  certificate downloadable via the existing idempotent service.
- **Digital Provenance / Insurance Report** (`ba2da33`): on-demand owner PDF of the full record.
- **Authentication findings:** shown read-only in the Authentication tab (condition grade, date); not a
  separate uploadable document, and also summarised in the provenance report.
- **Service history:** shown in the History tab; any staff `is_public` service media appears under
  Documents.
- **Document uploads are staff-only:** `POST /admin/sca/eyewear/.../documents` (ACL
  `sca.eyewear.document`). `DocumentService` sets the canonical `kind`/`is_public`/checksum; collectors
  have no upload path.

## 3. Display of authentication / service / collector documents (req 4)
All collector-visible documents are generic `sca_media_assets` rows attached to the item and surfaced in
one Documents list, categorised by **kind label** (Certificate (PDF) / Photo / Document) with
current/superseded classification for certificates. There is no per-source ("Authentication" vs
"Service") grouping — a minor presentation nicety, **not** an essential gap and not required. There is
no collector-uploaded-document category because collectors cannot upload (by design).

## 4. Can collectors securely upload / categorise / view / manage documents? (req 5, 7)
- **View / download / categorise (by kind):** yes — complete for the required scope.
- **Upload / manage (add/delete/edit):** no — and this is **by design**, not an oversight. It is **not
  explicitly required by Jeremy** (roadmap = "durable documents from trusted SCA data"), so it is
  **optional at most**.

## 5. Ownership-transfer document access (req 6) — verified correct & privacy-safe
All collector document surfaces (`visibleDocumentsForOwnedItem`, `ownerVisibleDocument`, the certificate
availability workflow, and the provenance report) are gated on **canonical current ownership**. After a
transfer: the **new owner** gains access to the item's `is_public` documents + certificate (media keyed
to `eyewear_item_id`, not to an owner); the **previous owner** and any non-owner get the shared
privacy-safe real 404. Document listings expose only kind / date / public certification number — **no
owner identity or PII**, so no previous-owner personal information is ever exposed. (Reviewed in
`docs/SCA-RESALE-DOCUMENTATION-GAP-ANALYSIS.md`; re-confirmed here.)

## 6. Conclusion — no essential gap; do NOT build collector upload
The collector document experience is **complete for the required scope** (securely view + download
SCA-authoritative documents, with certificate on-demand and a consolidated provenance report), and
ownership-transfer access is correct and privacy-safe.

A collector document-**upload / management** capability is **not required by Jeremy** and should **not**
be built — and certainly not now — because it would:
- blur the provenance-integrity model (collector-authored files could be mistaken for authoritative SCA
  records) and risk conflicting with the immutable certificate and append-only provenance invariants
  (reqs 9–10);
- introduce content-moderation, abuse, malware-scanning, storage-quota, and takedown obligations with no
  requirement driving them;
- duplicate nothing of value the trusted-data documents and the provenance report don't already provide
  (req 11).

**Therefore no code was changed.** (The task authorises implementing only a *genuinely missing essential*
capability; none exists here.)

## 7. Optional, non-essential enhancements (NOT built; for the owner to prioritise later, if ever)
- Group the Documents list by source (Certificate / Authentication / Service) — cosmetic.
- Surface the provenance-report download from the Documents tab as well as Overview — discoverability.
- If the owner ever explicitly wants collectors to attach **personal** (clearly non-authoritative,
  owner-private) supporting files, that would be a **separate, explicitly-scoped** feature with its own
  category, strict separation from SCA-authoritative records, validation/scanning, and a visible
  "collector-provided, not verified by SCA" label — out of scope here and only on owner request.

## 8. Security considerations
No change made, so all invariants stand: current-owner authorization, staff-only document privacy
(`is_public=0` never collector-visible), immutable certificate integrity, append-only provenance, and
the privacy-safe 404 for non-owners. No collector path can alter official certifications, authentication
findings, or ownership history.

## 9. Deferred tests
None (no code change). The deferred-test lists for the stacked document features remain as recorded in
`docs/SCA-PROVENANCE-REPORT-FEATURE.md`, `docs/SCA-RESALE-DOCUMENTATION-GAP-ANALYSIS.md`, and
`docs/SCA-COLLECTOR-CERTIFICATE-AVAILABILITY.md` — to be run under a separately-authorized isolated
regression before any RC/deploy, once the owner lifts the testing freeze.

## 10. Safety posture (this task)
Read-only. No production merge/migration/deploy/DB change; no Shopify API or store change; no email
configuration; no live document upload / claim / transfer; no secure-claim RC (`4bd88d2`) deploy; no
Option C; no tests. Production unchanged at `b007606`. Stacked unmerged document branches remain
`ba2da33` ← `63b5808` ← `a923dfd`.

**STOP — read-only gap analysis delivered: the collector document-management experience is complete for
the scope Jeremy requires (secure view + download of SCA-authoritative documents, certificate on-demand,
consolidated provenance report), and ownership-transfer document access is correct and exposes no
previous-owner PII. Collector document UPLOAD is not required by Jeremy and would undermine provenance
integrity, so NO new capability was built and no code was changed. Production unchanged at `b007606`;
secure-claim RC `4bd88d2` untouched.**

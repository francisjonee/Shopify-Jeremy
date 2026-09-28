# SCA TASK QUEUE

This file is the ordered implementation backlog for Second Chance Authenticators.

## Authority and execution rule

- `NEXT_TASK.md` contains the **only executable task**.
- Items in this queue are planned only and are not authorization for Claude to start them.
- Claude must never skip ahead into this queue.
- After ChatGPT audits the current task, ChatGPT may promote exactly one queued item into `NEXT_TASK.md`.
- Every task must produce committed implementation evidence/findings before it can be accepted.

## Status legend

- `ACTIVE` — currently represented by `NEXT_TASK.md`; only one allowed.
- `QUEUED` — planned but not executable.
- `BLOCKED` — cannot begin until dependency is resolved.
- `DONE` — accepted after ChatGPT audit.
- `SUPERSEDED` — intentionally replaced.

> **Reconciliation note (2026-09-24):** this file was reconstructed from committed implementation evidence. Accepted tasks remain governed by their committed task reports and accepted merge SHAs.

---

## COMPLETED — accepted, merged to implementation `main`

- `SCA-KRAYIN-INSTALL-001` — Krayin foundation — **DONE** (merge `4d58551`).
- `SCA-KRAYIN-HARDEN-001` — foundation security hardening — **DONE** (merge `96cf2d0`).
- `SCA-DOMAIN-DESIGN-003` — provenance schema/invariants — **DONE** (merge `11f72ca`).
- `SCA-DEMO-IP-004` — governed living development preview — **DONE**.
- `SCA-DOMAIN-CORE-004` — core migrations/models/services — **DONE**.
- `SCA-ADMIN-ITEMS-005` — eyewear intake/search — **DONE**.
- `SCA-ADMIN-AUTH-006` — authentication + condition grading — **DONE**.
- `SCA-CERT-QR-007` — certification ID + permanent QR identity — **DONE**.
- `SCA-PUBLIC-PASSPORT-008` — public passport surface — **DONE**.
- `SCA-SHOPIFY-CONNECT-009` — least-privilege store connect scaffold — **DONE**; live OAuth/webhooks deferred.
- `SCA-SHOPIFY-SALELINK-010` — paid-order → item sale links — **DONE** (main `58b0d6c`).
- `SCA-COLLECTOR-AUTH-011` — collector authentication — **DONE** (main `500df27`).
- `SCA-CLAIM-012` — QR claim ownership workflow — **DONE** (main `0d69940`).
- `SCA-MY-COLLECTION-013` — collector My Collection portal — **DONE** (merge `ad62c65`).
- `SCA-TRANSFER-014` — collector-to-collector ownership transfer — **DONE** (merge `f27185a`).
- `SCA-SERVICE-015` — append-only service history — **DONE** (merge `bace893`).
- `SCA-LOST-STOLEN-016` — owner-reported lost/stolen/recovered registry status — **DONE** (merge `0ddfc99`).
- `SCA-DOCUMENTS-017` — document/evidence handling — **DONE** (merge `c4f43c2`).
- `SCA-COLLECTOR-PRIVACY-018` — collector PII pseudonymization/anonymization — **DONE** (merge `4eb1b98`).
- `SCA-BACKUP-019` — encrypted backup + restore-proof foundation — **DONE** (merge `3c80c20`); off-server backup deferred.
- `SCA-PRODUCTION-HARDENING-020` — pre-public application hardening — **DONE** (merge `0f5af00`).
- `SCA-STATUS-ADMIN-022` — staff registry-status administration — **DONE** (merge `14b4353`).
- `SCA-CERTIFICATE-PDF-023` — immutable certificate PDF + repair semantics — **DONE** (merge `4716329`).
- `SCA-ADVERSE-RECOVERY-024` — staff recovery of owner-orphaned adverse items — **DONE** (merge `a1ae15d`).
- `SCA-PILOT-HARDENING-025` — pre-pilot application hardening — **DONE** (merge `98a7ef2`).
- `SCA-EXTERNAL-CLAIM-027` — staff-issued external-intake claim entitlement — **DONE** (merge `90cd2dc`).
- `SCA-APP-POLISH-029` — SCA CSRF/current-ownership/root polish — **DONE** (merge `233fa2c`).
- `SCA-EXTERNAL-CLAIM-REVOKE-030` — external claim-grant revocation — **DONE** (merge `6f902f3`).
- `SCA-COLLECTOR-AUTH-CONTEXT-032` — privacy-safe claim/transfer auth context — **DONE** (merge `447093e`).
- `SCA-OWNERSHIP-PROVENANCE-033` — staff ownership provenance history — **DONE** (merge `f9385d7`).
- `SCA-PUBLIC-PASSPORT-PILOT-034` — live-pilot passport validation — **DONE** (merge `2029f09`).
- `SCA-ADMIN-OWNERSHIP-CORRECTION-035` — governed append-only staff ownership correction — **DONE** (merge `cf05b58`; manually pilot-validated Collector #2 → Collector #1).
- `SCA-COLLECTOR-PASSWORD-RECOVERY-037` — collector forgot/reset password (dedicated broker + `sca_collector_password_resets`) — **DONE** (merged+deployed `df80e4b`; real email delivery deferred until SMTP configured).
- `SCA-COLLECTOR-PASSWORD-CHANGE-036` — authenticated collector password change + account-security UX — **DONE** (merge/deployed `f362469`; manually pilot-validated: wrong current rejected, confirmation mismatch rejected, valid change succeeds, old password rejected, new password authenticates, ownership/My Collection preserved).
- `SCA-CERTIFICATION-CORRECTION-038` — governed staff certification **revoke + re-certify (supersede)**, append-only on the canonical certification-event ledger; dedicated `sca.eyewear.certification.correct` ACL; permanent QR identity preserved; Option A public-passport contract preserved (resolver/controller unchanged); **no schema migration** — **DONE** (`--no-ff` merge/deployed `bd5b2e7`; base `df80e4b`, feature `9d1c0e4`; deploy gate 21/99 focused + 498/2113 full; production baseline verified identical before/after).
- `SCA-STAFF-COLLECTOR-SUPPORT-040` — READ-ONLY privacy-safe staff collector lookup (`GET admin/sca/collectors` + `{ref}`); dedicated `sca.collector.support` read ACL; email withheld (not authorized); owned items from canonical current-ownership projection; **no schema migration** — **DONE** (`--no-ff` merge/deployed `ec75d4f`; base `bd5b2e7`, feature `cb4f357`; deploy gate 11/53 focused + 509/2166 full; production baseline verified identical before/after).
- `SCA-COLLECTOR-PASSPORT-ACCESS-041` — owned-item access to the canonical public passport (`GET collector/collection/{ref}/passport`, `collector.auth`) → owner+eligibility-authorized read-only redirect to existing `/p/{token}`; eligibility-gated UI; no raw token in HTML; `PassportResolver`/`PassportController` unchanged (Option-A preserved); **no schema migration** — **DONE** (`--no-ff` merge/deployed `223cc40`; base `ec75d4f`, feature `1a72d65`; deploy gate 12/32 focused + 521/2198 full; production baseline verified identical before/after).

### Non-code governance / validation activities

- `SCA-PILOT-E2E-026` — read-only end-to-end pilot trace.
- `SCA-PILOT-USABILITY-031` — read-only staff+collector usability audit.
- `SCA-CONTROLLED-PILOT-001` — controlled live pilot on temporary IP; ongoing.
- `SCA-EXPANSION-PLANNING-039` — read-only application expansion audit — **DONE** (accepted; roadmap + SCA-040 selection at `docs/SCA-EXPANSION-PLANNING-039.md`).
- `SCA-MY-COLLECTION-ENRICHMENT-042` — collector certificate-document Current vs Superseded/historical classification (read-time, from media `subject_id` vs canonical `current_certification_id`; public cert number; no evidence mutated/regenerated; **no schema migration**) — **DONE** (`--no-ff` merge/deployed `50c54ad`; base `223cc40`, feature `29715de`; isolated deploy gate 11/33 focused + 532/2231 full; migrate → Nothing to migrate; production baseline incl. media_assets verified identical before/after). Planning doc at `docs/SCA-MY-COLLECTION-ENRICHMENT-042.md`.
- `SCA-SUCCESSOR-CERTIFICATE-PDF-043` — successor-certificate-PDF lifecycle — **DONE (zero-code lifecycle validation / architecture decision)**. Accepted lifecycle = **Option B (explicit staff-triggered)** via the existing idempotent `admin.sca.certificate.generate` → `ensureForItem`; automatic generation rejected (certification integrity must not depend on PDF rendering). Manually pilot-validated end-to-end (item `SCA-F1B792AE4745`): successor `SCA-CERT-2026-5AC07F22` (Current) + predecessor `SCA-CERT-2026-FEE6D3D8` (Superseded) both immutable + downloadable; read-only verification confirmed exactly two per-cert PDFs (no duplicate), permanent QR + current-cert projection unchanged. B1 staff "missing PDF" hint remains an optional future UX task. Decision doc at `docs/SCA-SUCCESSOR-CERTIFICATE-PDF-043.md`.
- `SCA-EYEWEAR-METADATA-EXPANSION-044` — Slice 1 (additive nullable identity metadata: year/country_of_origin/materials/original_specifications) — **DONE** (`--no-ff` merge/deployed `fdf8595`; base `50c54ad`, feature `1be55a9`; deploy gate 13/56 focused + 545/2287 full; production migration applied once — schema = original 8 + 4 nullable cols; existing items intact + NULL new fields; provenance baseline identical before/after; certificate PDF untouched). Public passport exposes year/country/materials only; original_specifications owner/staff-only; frame_serial stays sensitive. Planning at `docs/SCA-EYEWEAR-METADATA-EXPANSION-044.md`. Later slices (certificate per-cert snapshot-freezing; append-only metadata correction) remain deferred/planned.
- `SCA-CERTIFICATE-SNAPSHOT-VERSIONING-045` — per-certification immutable render snapshot + template versioning — **DONE** (`--no-ff` merge/deployed `17854a8`; base `fdf8595`, feature `c5aeb95`; deploy gate 12/714 focused + 557/3001 full; production migration applied once — table + PRIMARY/UNIQUE/FK/CHECK + both append-only triggers; **0 snapshot rows** (no backfill); base↔candidate v1 PDF bytes verified identical; production baseline incl. media checksums/projections identical before/after). Accepted limitation: snapshot_checksum is tamper-evidence only, not revalidated on render. Unlocks the future append-only metadata-correction slice. Planning at `docs/SCA-CERTIFICATE-SNAPSHOT-VERSIONING-045.md`.
- `SCA-ITEM-METADATA-CORRECTION-046` — append-only eyewear identity-metadata correction — **DONE** (`--no-ff` merge/deployed `bb52a9d`; base `17854a8`, feature `fa96863`; deploy gate 18/93 focused + 575/3099 full; production migration applied once, batch 10 — `sca_item_metadata_events`: FK `eyewear_item_id`→`sca_eyewear_items(id)`, `correction_group_id` index + composite `(eyewear_item_id,created_at,id)` index, exact 7-field CHECK `field IN (brand,model_name,frame_serial,year,country_of_origin,materials,original_specifications)`, old/new_value + reason + actor_staff_ref + created_at, both append-only triggers `_no_update`/`_no_delete`; **0 metadata-event rows** (no backfill/rewrite); production before/after identical — counts (items/certs/cert_events/snapshots/media/ownership/owners/claims/transfers/QR/qr_lifecycle/status/authentications/service/collectors) unchanged, item-metadata fingerprint `c38c04a5…` MATCH, media+PDF-checksum fingerprint `a63a00db…` MATCH, current-state projection fingerprint `2324acd3…` MATCH; no metadata correction performed / no PDF generated / no cert or snapshot change). Routes GET-confirm + POST-apply both gated by `sca.eyewear.metadata.correct` (ScaAuthenticate + ScaAuthorize); no generic PUT/PATCH; no collector/public metadata route; unauthenticated fails closed (GET→login 302, POST→419). **Legacy policy (recorded):** brand/model_name are PDF render inputs → correction blocked (`LEGACY_PDF_FIELD_LOCKED`) when the current certification is snapshot-less legacy; allowed only when no current cert OR the current cert has an SCA-045 snapshot; the 5 non-PDF fields (frame_serial/year/country_of_origin/materials/original_specifications) remain always-correctable; **no automatic or reconstructed legacy snapshot** is created. All 3 production certs are snapshot-less, so brand/model on them stays locked. Legacy brand/model reconstruction (verified Option B) remains a **separate future prerequisite** task. Planning at `docs/SCA-ITEM-METADATA-CORRECTION-046.md`; full evidence in the implementation repo `docs/task-reports/SCA-ITEM-METADATA-CORRECTION-046.md`.
- `SCA-APPLICATION-EXPANSION-AUDIT-047` — read-only application expansion audit @ deployed `bb52a9d` — **DONE** (planning only; no code/branch/migration/mutation). Found the provenance core complete (039's NOW tier + most of NEXT shipped via 040–046); highest remaining value = surfacing canonical data that already exists but is never shown, on both sides — collector item history (esp. the **silent-revocation dead-end**: a revoked cert drops the passport button with no notice) and staff operations (no dashboard; registry index has no status/owner/date filter or sorting → status worklists need raw DB). **Recommended next candidate (SCA-048, NOT promoted):** read-only collector "item history" timeline on My Collection detail (certification-status + honest revocation notice, ownership/transfer, own status reports), privacy-scoped to the authenticated owner, reusing `ProjectionService` + the event ledgers — no schema, read-only; smallest viable slice = the certification-status/revocation notice alone. Confirmed DEFERRED with no current operational need: legacy Option-B cert reconstruction (revoke/supersede already unblock brand/model), external paid-auth, resale/marketplace; market/value = separate append-only ledger, LATER; in-app notifications = NEXT (needs a new table); email = LATER (SMTP). Full report at `docs/SCA-APPLICATION-EXPANSION-AUDIT-047.md`.
- Numbers `021` and `028` were unused.

---

## ACTIVE

- `SCA-COLLECTOR-CERTIFICATION-HISTORY-048` — **ACTIVE — implemented + pushed** (promoted by ChatGPT from the SCA-047 audit recommendation). Read-only collector-facing certification history on the My Collection item detail (current / superseded-with-successor / revoked→neutral "no active certification" notice), derived from `sca_certifications` + `sca_certification_events` via `ProjectionService`; owner-authorized; SCA-038 Option A + SCA-041 passport + SCA-042 doc classification all preserved; no schema/mutation. Base `bb52a9d`, feature branch `sca-collector-certification-history-048` @ `52e01aa`; focused 11/51 + full 586/3150. Pilot restored to `bb52a9d`. Executable contract in `NEXT_TASK.md`; evidence in impl repo `docs/task-reports/SCA-COLLECTOR-CERTIFICATION-HISTORY-048.md`. **Push only — awaiting ChatGPT audit; NOT merged, NOT deployed.** SCA-049 must not start.

_SCA-046 is DONE (deployed `bb52a9d`); SCA-047 audit is DONE (planning). `SCA-PRODUCTION-CUTOVER` remains BLOCKED/DEFERRED awaiting Jeremy._

## REMAINING BACKLOG (planned only — not authorization to start)

### SCA-PRODUCTION-CUTOVER — Permanent infrastructure & production cutover
**Phase:** 10 — Production
**Status:** BLOCKED / DEFERRED — awaiting Jeremy-provided permanent domain + access. Explicitly does NOT block continued application development (see SCA-EXPANSION-PLANNING-039).
**Depends on:** core provenance product accepted + Jeremy-provided permanent HTTPS domain

Permanent HTTPS/public-QR domain, DNS/Caddy cutover, Shopify live activation, permanent QR printing, production mail delivery configuration where required, temporary pilot exposure retirement, durable off-server backup/restore rehearsal, and production secrets remain infrastructure work and require explicit approval/input.

### SCA-EXPANSION — Post-core expansion planning
**Phase:** 11 — Expansion
**Status:** QUEUED
**Depends on:** production cutover complete

Plan market history/value tracking, collector profiles/privacy, notifications, external paid authentication intake, resale/marketplace concepts, and analytics. Must not block or destabilize the trusted provenance core.

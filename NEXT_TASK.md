# NEXT TASK

**STATUS:** ACTIVE — `SCA-COLLECTOR-CERTIFICATION-HISTORY-048` promoted for implementation (push only —
NOT merged, NOT deployed, production NOT migrated). Base = deployed `main`
`bb52a9dae425a97e601f4e0ea88f063b5994401d`.

*Prior task `SCA-ITEM-METADATA-CORRECTION-046` is DONE (deployed `bb52a9d`); the read-only
`SCA-APPLICATION-EXPANSION-AUDIT-047` is DONE (planning). `SCA-PRODUCTION-CUTOVER` remains BLOCKED/DEFERRED
awaiting Jeremy. SCA-049 must not start.*

## Title

SCA-COLLECTOR-CERTIFICATION-HISTORY-048 — read-only collector-facing certification history on My Collection

## Goal

Make certification state understandable to the authenticated **current owner** from My Collection, without
changing any provenance or public-passport behavior. Today a revoked certification is a *silent* downgrade —
the "View public passport" button simply disappears with no explanation. This task adds an owner-facing,
read-only certification history + an honest neutral notice, derived entirely from existing canonical records.

## Executable directive (as governed)

On the collector item-detail surface (`/collector/collection/{ref}`, reusing the existing
`sca-collector::collection.show` view — do **not** create a new public provenance page unless inspection
proves a separate collector route is strictly necessary; inspection at `bb52a9d` shows the existing owner-
authorized detail is sufficient), present a **read-only Certification history** derived from
`sca_certifications` + `sca_certification_events`, folded by the canonical `ProjectionService`
(`currentCertification`). At minimum distinguish:

- **current** certification;
- **superseded / historical** certification — clearly identify the historical cert AND its current
  successor using the canonical `supersedes_certification_id` / `superseded` event
  `successor_certification_id`; must **not** imply the historical certificate is currently valid;
- **revoked** certification / item currently having **no active certification** — show a neutral
  explanation such as "This item currently has no active certification." The disappearing passport button
  must no longer be the only signal.
- certification **date/number** only where already collector/public-safe.

### Hard constraints

- **SCA-038 Option A preserved:** the public passport is untouched. A revoked permanent QR continues to
  return the existing constant-shape 404. Revocation is **never** exposed through `/p/{token}`; no change to
  `PassportResolver` / `PassportController` semantics.
- **Privacy boundary:** the current owner may see certification numbers, dates, and collector-safe
  status/history for an item they **currently own**. **Never** expose: revocation/correction `reason`,
  `actor_staff_ref`, event/internal DB IDs, snapshot checksum, QR token, previous-owner PII, correction
  groups, or any other staff-only provenance.
- **Authorization from canonical current ownership only** (`sca_item_current_state.current_owner_collector_id`
  = the authenticated collector). Previous owners, unrelated collectors, public users, and unauthenticated
  users must not gain access (privacy-safe 404 / empty, exactly as the existing detail behaves).
- **Read-only — no mutation of any kind:** no schema/migration; no certification/event mutation; no PDF
  generation/repair; no QR mutation; no ownership/status/authentication/service mutation; no snapshot
  creation/reconstruction.

### Tests (focused suite)

Cover at least: (1) first/current certification; (2) superseded predecessor + current successor (predecessor
labelled historical, successor identified as current); (3) revoked current state → neutral "no active
certification" notice; (4) privacy — no reason/staff ref/internal IDs/tokens/checksums/correction groups in
the read model or rendered HTML; (5) current-owner authorization succeeds; (6) previous-owner / non-owner /
unauthenticated denial; (7) SCA-041 passport behavior unchanged; (8) SCA-042 certificate-document
classification unchanged; (9) viewing the history performs zero mutation.

Then run the focused suite AND the full `tests/Feature/Sca` suite on the disposable `sca_domain_test` DB and
record exact totals in the task report.

### Delivery

Implement on a governed feature branch off `bb52a9d`; **push only**; restore the pilot to deployed `main`;
STOP for ChatGPT audit. **Do NOT merge or deploy. Do NOT start SCA-049.**

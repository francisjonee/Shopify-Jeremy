# NEXT TASK

**STATUS:** ACTIVE — `SCA-COLLECTOR-AUTHENTICITY-BADGE-052` promoted for implementation (DEFECT-001 fix; push
only — NOT merged, NOT deployed, production NOT migrated). Base = deployed `main`
`c8e3f5943e9b8e6ecd22accdce9db7719bab97ba`. Implementation contract = the accepted DEFECT-001 root-cause audit
recorded at governance `636216c` (`docs/PENDING-DEFECTS.md`).

*Prior: `SCA-051` DONE (deployed `c8e3f59`); DEFECT-001 root-cause audit DONE. `SCA-PRODUCTION-CUTOVER` remains
BLOCKED/DEFERRED. SCA-053 must not start.*

## Title

SCA-COLLECTOR-AUTHENTICITY-BADGE-052 — correct the My Collection authenticity/certification badge (DEFECT-001)

## Objective

The collector item-detail badge must never present a green ✓ (or equivalent positive certification signal)
unless the item has a **current active certification**. Authentication evidence and certification status remain
**semantically independent**.

## Executable directive (as governed)

### Hard invariant
**green ✓ ⇔ current active certification.** A historical passed authentication MUST NOT by itself produce the
green certification indicator. Do not infer current certification from authentication.

### Required display matrix
| Current certification | Passed finalized authentication | Display |
|---|---|---|
| yes | yes | **green ✓ Authenticated & Certified** |
| no (revoked) | yes | neutral **Authenticated — no active certification** |
| no (never certified) | yes | neutral **Authenticated — not certified** |
| no | no | neutral non-certified / **Recorded** |
| failed / not authenticated | no | neutral **Recorded** |

### Canonical sources
- **Certification** state from the canonical current-certification projection (`current_certification_id` /
  `ProjectionService::currentCertification`); "currently certified" = that current cert is `issued`.
- **Authentication** state derived **independently** from `sca_authentications` (a row with `result='passed'`
  AND `finalized_at IS NOT NULL` for the item) — NOT via the current certification's `source_authentication`.
- **Authentication date**, when shown, likewise from that independent authentication evidence, so a
  certification **revocation does not erase** genuine historical authentication/date evidence.
- "ever certified" (revoked vs never-certified label) = an `issued` certification row has ever existed for the
  item.

### Scope (read-model + presentation ONLY)
Expected: `CollectionService` (`detail()` + a small pure badge-mapping helper + the independent authentication
reads) and `collection/show.blade.php` (badge driven by tone/certified, not hard-coded green), plus focused
regression tests and the task report. Controller change only if the data flow requires it. **No schema, no
migration, no event/projection mutation, no certification/QR/PDF/ownership/status mutation.** If any of those
appears necessary, **STOP** and return to ChatGPT.

### Required regression cases (focused)
Active cert + passed auth → green ✓ "Authenticated & Certified"; revoked + historical passed auth → no green ✓,
neutral "Authenticated — no active certification"; authenticated but never certified → no green ✓,
"Authenticated — not certified"; never authenticated/never certified → no positive certification claim; failed
authentication → no green ✓ and no false Authenticated claim; superseded predecessor with active successor →
current item still positively certified; revocation does NOT erase historical authentication date; the SCA-048
"This item currently has no active certification." notice stays consistent with the badge; viewing the page is
zero-domain-mutation; no new PII / internal ids / tokens / reasons / staff refs / checksums / provenance
internals exposed. Run the focused suite AND full `tests/Feature/Sca` on the disposable `sca_domain_test` DB;
record exact totals.

### Hard regression boundaries (do NOT change)
SCA-038 Option A / `PassportResolver`; public passport behavior/terminology (its "Authenticated & Certified" is
valid — resolver already requires current certification — and is **out of scope**); SCA-041 passport access;
SCA-042 certificate-document classification; SCA-048 certification history; SCA-049 ownership history; SCA-051
staff registry operations.

### Delivery
Implement on a governed feature branch off `c8e3f59`; **push only**; restore the pilot to deployed `c8e3f59`
(clean tree, `--no-dev`, existing exposure/IP-lock, private MariaDB); push governance evidence; STOP for ChatGPT
audit. **Do NOT merge or deploy. Do NOT mark DEFECT-001 fixed yet. Leave SCA-053 unpromoted.**

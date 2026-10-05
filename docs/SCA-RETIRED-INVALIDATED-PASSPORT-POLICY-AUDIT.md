# SCA Retired / Invalidated — Public Passport Policy Audit (READ-ONLY)

**Date:** 2026-10-05 · **Baseline:** deployed production `f78e31d`, migrations **120**.
**Status: AUDIT / DECISION ONLY. No code, DB write, production status action, QR regen/revocation, or
ACTIVE/NEXT promotion. STOP for ChatGPT / operator review with a recommendation.**

Goal: decide how the public Passport should behave when an item becomes **Retired** or **Invalidated**. Both
can currently resolve **HTTP 200** (with the deployed trust/safety warning) because `PassportResolver` is
intentionally unchanged. Traced against the deployed code, not assumptions.

Files traced: `Passport/Services/PassportResolver.php`, `Passport/Presenters/PassportPresenter.php`,
`Passport/Resources/views/passport/show.blade.php`, `Provenance/Services/{StatusService,ProjectionService,
CertificationCorrectionService,QrService}.php`, `Registry/Services/StaffStatusWorkflow.php`,
`Registry/Http/Controllers/EyewearItemController.php` (adminRetire/adminInvalidate),
`Provenance/Support/ItemStateLabels.php`.

## 1. What "Retired" means (domain)
- **Who / when:** staff only. Two entry points, both server-derived `staffRef`, both L2 typed-word confirmation
  (`RETIRE`) + reason (SCA-destructive-confirmations): `StaffStatusWorkflow::apply` (from `normal`/`recovered`/
  `disputed`), and `EyewearItemController::adminRetire` via `StatusService::recordAdministrativeStatus`
  (SCA-ADVERSE-RECOVERY-024) which additionally admits the **owner-orphaned** `lost`/`stolen` safety-valve case
  (else 409). Transition matrix forbids `lost`/`stolen` → terminal through the normal staff path.
- **Reversible:** **No.** `retired` is **TERMINAL** (`StaffStatusWorkflow::TERMINAL`; `assertTransitionAllowed`
  rejects any transition out). The underlying log is append-only, so the `retired` event is permanent.
- **Effect:** appends ONE `sca_status_events` row; `ProjectionService` recomputes `registry_status → retired`.
  **Certification, authentication, ownership, QR identity/token, `current_certification_id`,
  `active_qr_identifier_id`, and all provenance/evidence are untouched.** `lifecycle_state` derives to `RETIRED`
  for admin display only.

## 2. What "Invalidated" means (domain)
- **Who / when:** identical mechanics to Retired — staff, `StaffStatusWorkflow::apply` or
  `adminInvalidate`/`recordAdministrativeStatus`, L2 typed-word `INVALIDATE` + reason, same transition matrix,
  same owner-orphaned valve.
- **Reversible:** **No.** `invalidated` is **TERMINAL**.
- **Effect:** identical — appends one `sca_status_events` row, `registry_status → invalidated`, everything else
  (cert, QR, auth, ownership, provenance) **untouched**.

**Retired and Invalidated are mechanically identical today** (only the status string and the deployed warning
copy/severity differ). The audit does **not** assume they should *behave* the same publicly — see §7.

## 3. Does either revoke certification or QR? — NO
Neither implicitly nor explicitly. `StatusService` writes only `sca_status_events`; `ProjectionService` derives
the three facts independently: `current_certification_id` from `sca_certification_events`
(`issued` opens / `revoked`|`superseded` closes), `active_qr_identifier_id` from `sca_qr_lifecycle_events`,
`registry_status` from the latest `sca_status_events`. Retiring/invalidating writes none of the cert/QR events, so
it cannot change cert or QR state.

## 4. What happens when the QR is scanned today
`PassportResolver` invariant: **200 ⟺ well-formed token AND it is the item's active QR AND the item has a current
issued certification AND that cert's source authentication is passed+finalized.** Registry status is **never
consulted.** So for a Retired or Invalidated item whose cert is still current and QR still active:
- **200** is returned, rendering the deployed trust/safety page: Retired → neutral-strong **RETIRED FROM THE SCA
  REGISTRY** banner (first/dominant); Invalidated → strongest red **RECORD INVALIDATED** banner — **each followed
  by the green "✓ Authenticated & Certified" badge** and the full detail rows.
- If the cert were ever separately **revoked** (`CertificationCorrectionService::revoke`) or the QR reissued, the
  item would already **404** regardless of registry status.

## 5. The existing "cease to validate" path (central to the recommendation)
`CertificationCorrectionService::revoke` appends one `revoked` cert event → `currentCertification()` returns null
→ resolver sees `current_certification_id === null` → returns null → **constant-shape 404**, with the QR token
**preserved** (no QR event written). This is the deployed **SCA-038 Option-A** behavior: append-only,
privacy-safe, and already part of the constant-shape 404 set. **A domain-consistent way to make an item's passport
stop validating already exists — via the certification axis, not the resolver or the registry axis.**

## 6. State matrix (all assume an item that was certified; cert/QR not separately revoked)

| State | QR active? | Current cert? | Ownership preserved? | Passport today | Warning shown today | Recommended public behavior | Rationale |
|---|---|---|---|---|---|---|---|
| **Normal** | yes | yes | yes | 200 green | none (clear) | **Unchanged** — 200, green clear | Authentic + certified + active, no adverse fact |
| **Lost** | yes | yes | yes | 200 | amber REPORTED LOST (dominant), green retained | **Unchanged** | Loss is independent of authenticity; green stays truthful |
| **Stolen** | yes | yes | yes | 200 | red REPORTED STOLEN + ownership disclaimer, green retained | **Unchanged** | Authenticity ≠ lawful possession; already stated |
| **Disputed** | yes | yes | yes | 200 | amber UNDER REVIEW, green retained | **Unchanged** | Provisional registry issue; authenticity fact unchanged |
| **Recovered** | yes | yes | yes | 200 publicly **clear** | none (recovered→clear) | **Unchanged** | Deliberate privacy: resolved loss reads clear publicly |
| **Retired** | yes | yes | yes | 200 | RETIRED banner (neutral-strong), green retained | **KEEP 200 historical page, strong RETIRED warning, green retained** | Item *was and remains* authentically certified; retirement is an administrative registry withdrawal, not a repudiation of authenticity. Destroying public provenance is undesirable. |
| **Invalidated** | yes | yes | yes | 200 | RECORD INVALIDATED banner (strongest), **green retained** ← ambiguity | **CHANGE — remove the green "Authenticated & Certified" treatment** (see §7). Default: 200 historical/invalid page, **no green badge**. | A record SCA has declared invalid should not simultaneously present a green all-clear certification affirmation. |

## 7. Recommendation (challenge the preliminary direction)

**Retired — KEEP today's behavior (no change needed).** Preliminary direction confirmed. Retirement withdraws the
item from the *active* registry but does not repudiate the authentication/certification that genuinely happened;
the green badge beneath a RETIRED banner is not contradictory ("this was authenticated & certified; its registry
record is retired"). Keeping the 200 historical page preserves append-only provenance and leaks nothing new.
(Optional, presentation-only, operator's call: a one-line clarifier that the certification remains historically
valid.)

**Invalidated — the green all-clear is the real problem; fix it with the smallest presentation change.** The
ambiguity the preliminary direction names is specifically the green "Authenticated & Certified" badge sitting
under a red "RECORD INVALIDATED" banner. The smallest, invariant-preserving fix is **presentation-only: when
`registry_severity === 'invalid'`, suppress the green badge and render an explicit invalid/historical treatment**
(red dominant, no green affirmation; the detail rows may remain as historical record). This:
- requires **no `PassportResolver` change** (the 200 ⟺ active-QR + current-cert invariant stays intact),
- adds **no new 404 reason** (so SCA-038 constant-shape is entirely unaffected),
- is append-only/provenance-preserving and privacy-neutral (uses only already-allowlisted fields),
- directly removes the ambiguity without the heavier consequences of a 404.

**Why NOT resolver-404-on-invalidated.** Special-casing the resolver to 404 when `registry_status === 'invalidated'`
would (a) couple the independent registry axis into resolution, breaking the clean "200 ⟺ cert+QR" invariant and
the trust/safety architecture's deliberate choice to express adverse states as presentation, not resolution;
(b) set a precedent ("why not 404 stolen too?"); and (c) destroy public access to historical provenance — all to
reach a constant-shape 404 that the **certification-revocation path already provides** without touching the
resolver. It does **not** leak state (the 404 stays constant-shape), but it is the wrong layer.

**If the operator's intent is stronger** — "an invalidated SCA record must present NO public verification page at
all" — then the correct domain-consistent mechanism is **not** a resolver/registry hack but **coupling invalidation
to a certification revocation**: append a `revoked` cert event (the existing `CertificationCorrectionService`
mechanism) as part of invalidation, so the passport 404s through the **existing** cert-null→404 path, append-only
and SCA-038-consistent, QR token preserved. Trade-off: this also marks the item not-currently-certified on the
collector/admin surfaces and removes the public historical page.

## 8. OPERATOR DECISION (the one real fork)
For **Invalidated**, choose the intended meaning:
- **(A) "The active record is withdrawn, but the history is real"** → **Option 2 (recommended default):**
  presentation-only, 200 historical page, **no green badge**, red invalid treatment. No resolver/domain change.
- **(B) "The record is void / must not verify or present publicly"** → **Option 4:** make invalidation also revoke
  the certification (existing append-only path) → constant-shape **404**; history no longer public. A domain
  decision with cross-surface effects; needs its own implementation task + review.
Retired is **not** part of this fork — recommended to stay as-is (A-style, green retained).

Security/privacy summary: (A) continuing a warned 200 and the no-green variant both expose only already-public
allowlisted fields — no owner/collector/staff identity, no internal id/path/token. (B) 404 exposes strictly less
and remains constant-shape. None of the options weakens SCA-038. Changing a registry state to 404 **in the
resolver** would not leak state (constant shape) but is rejected on architectural grounds (§7).

## 9. Interactions (confirmed non-breaking)
- **QR reissue:** independent (QR axis); a reissued item still resolves on its new active token; retired/invalidated
  unaffected.
- **Ownership/transfer:** independent; ownership preserved through retire/invalidate; public page never shows owner.
- **Lost/stolen/recovered:** independent registry transitions; only the owner-orphaned admin-recovery valve can take
  lost/stolen → retired/invalidated.
- **Certification correction/revocation:** the cert axis is the sanctioned "cease to validate" lever (Option B).
- **Authentication history:** untouched by any registry action.

## 10. Scope if (and only if) the operator later approves
- **Option 2 (recommended):** view/presenter-only — in `show.blade`/`PassportPresenter`, treat
  `registry_severity === 'invalid'` as "no green badge + explicit invalid treatment"; keep the resolver, allowlist,
  CSP, SCA-038, QR, and all domain services unchanged; add focused tests (invalidated 200 shows invalid treatment
  and **no** "Authenticated & Certified"; retired still shows green; SCA-038 404 set unchanged; zero mutation).
- **Option 4 (only if chosen):** domain change — invalidation appends a `revoked` cert event in-transaction; routes
  through existing cert-null→404; separate task, its own review, cross-surface test coverage.

**No code/DB/status/QR change in this audit.** Governance only. ACTIVE/NEXT unpromoted. STOP for ChatGPT/operator
review. See [[sca-public-passport-trust-safety-audit]], [[sca-038-certification-correction]],
[[sca-status-terminology-consistency-audit]], [[report-to-github-first]].

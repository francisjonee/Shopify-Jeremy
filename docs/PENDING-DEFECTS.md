# SCA — Pending Correctness Defects

Open defects discovered during audits/reviews, recorded so they are not lost. Each must be scheduled as (or
folded into) a governed task; none is fixed except through the normal governed flow.

---

## DEFECT-001 — Collector "✓" authenticity badge shows green on revoked/uncertified items

- **Discovered:** SCA-050 product/operations audit (deployed `ec2b2ef`).
- **Where:** `app/packages/Sca/Collector/src/Resources/views/collection/show.blade.php` — the top authenticity
  badge is hard-coded green with a "✓". `CollectionService::detail` sets `authenticity_status` to `'Recorded'`
  when the item is uncertified OR its current certification was **revoked** (`current_certification_id` null).
- **Symptom:** a revoked/uncertified owned item still renders a green "✓ Recorded" badge, directly
  contradicting the SCA-048 "This item currently has no active certification." notice a few rows below on the
  same page. It **overstates authenticity** and undercuts the SCA-048 honesty fix.
- **Correct behavior:** the badge must be neutral/greyed (no ✓, non-green) when the item is not currently
  certified; green ✓ only when there is a current issued certification.
- **Scope/risk:** view-only fix, trivial, low risk, read-only, no schema.
- **Status:** OPEN. Explicitly **NOT** fixed in SCA-051 (per the SCA-051 authorization). To be scheduled as its
  own small governed correctness task (or folded into a future collector-detail cleanup, e.g. the SCA-050 C2
  sectioning item).

### Root-cause audit (READ-ONLY planning; deployed `c8e3f5943e9b8e6ecd22accdce9db7719bab97ba`)

**Exactly where the badge is rendered / what controls it.** `collection/show.blade.php:27` renders the top
badge with a **hard-coded** green style (`background:#dcfce7;color:#166534;border:#86efac`) and a literal `✓`,
interpolating only the *text* `$item['authenticity_status']`. So the green + ✓ **visual is fixed**; only the
words change. The text is derived in `CollectionService::detail` (`CollectionService.php:423`):
`($r->cert_state === 'issued' && $r->auth_result === 'passed') ? 'Authenticated & Certified' : 'Recorded'`.
`cert_state`/`auth_result` come from `baseQuery` (`:382-394`), which LEFT-JOINs the **current** certification
(`s.current_certification_id`) and *that cert's* `source_authentication`. Therefore on revoke/no-current-cert
both are null → text `'Recorded'`, **but the badge stays green with ✓** → the false-positive. (Also: because
`auth_result`/`authentication_date` are read only via the *current cert's* source auth, a revoked item's
genuine historical authentication evidence disappears from the view entirely.)

**Derived, not hard-coded (text) — but hard-coded (visual).** The misleading element is the fixed green/✓
markup, not the label logic.

**Semantic distinctions (established by existing product evidence — do NOT equate them).** The staff item
detail states it outright (`eyewear/show.blade.php:86`): *"A passed authentication is evidence only — it does
not issue a certification."* So:
1. **Authenticated / passed inspection** — a finalized passed authentication exists (`sca_authentications`,
   `result='passed'` AND `finalized_at IS NOT NULL`). Durable historical evidence; **survives** revocation;
   does **not** by itself imply a live certification.
2. **Currently certified** — `ProjectionService::currentCertification(item)` is non-null (projection
   `current_certification_id`; the cert is `issued`). The live attestation.
3. **Superseded certification** — a predecessor closed by a `superseded` event whose **successor is current**;
   the item is therefore **still currently certified** (by the successor) — a positive state, not adverse.
4. **Revoked / no active certification** — `current_certification_id` null though a cert previously existed.
   SCA-048 already shows the neutral "This item currently has no active certification."
5. **Never certified** — no certification ever (may or may not be authenticated).
6. **Failed / not authenticated** — no finalized passed authentication (or latest relevant result not passed);
   no positive claim is truthful.

**What the badge is supposed to claim / canonical source of truth.** The strong green ✓ is a *certification*
claim and must be driven by the **certification projection** (`currentCertification` non-null) — NOT by
authentication. "Authenticated" is a distinct, weaker, historical claim sourced independently from
`sca_authentications`. The badge should be a **deliberately derived combination** of the two canonical sources,
never treating authenticated == certified (no product requirement equates them; the staff UI and passport
distinguish them).

**Cross-surface terminology check.**
- *Public passport* (`PassportPresenter.php:50`) hard-codes `'Authenticated & Certified'`, but is **truthful**
  because `PassportResolver` only resolves an item that has a current *issued* cert + active QR (else constant
  404). **Already correct; out of scope for DEFECT-001; must stay unchanged (SCA-038 Option A).**
- *Staff item detail* already separates authentication ("Not authenticated"/result) from certification and
  states the evidence-vs-attestation rule. Consistent.
- *SCA-048 certification history* and *SCA-049 ownership history* use neutral labels; the badge fix makes the
  badge **consistent** with the SCA-048 no-active-cert notice (aligns them; does not couple them).
- *Registry status* banner is a separate adverse-state signal (lost/stolen/…); unaffected.

**Recommended display-state matrix (collector My Collection item-detail badge).**

| Canonical state | currently certified? | passed finalized authentication exists? | Badge tone | Suggested label | ✓ |
|---|---|---|---|---|---|
| Currently certified (incl. active successor after supersede) | yes | yes | **positive / green** | Authenticated & Certified | ✓ |
| Revoked — no active cert, was authenticated | no | yes | neutral | Authenticated — no active certification | — |
| Never certified, authenticated (passed, not yet certified) | no | yes | neutral | Authenticated — not certified | — |
| Never certified, never a passed authentication | no | no | neutral | Recorded — not certified | — |
| Failed / not authenticated | no | no | neutral | Recorded | — |

Rule: **green ✓ ⟺ currently certified**; every non-certified state is neutral (no ✓, non-green), with an
optional truthful authentication sub-claim when a passed finalized authentication exists.

**Smallest correction — presentation / read-model ONLY (no STOP condition).** (a) In `CollectionService::detail`
replace the single `authenticity_status` string with a small derived structure: `certified` (from the current
cert / projection), `authenticated` (from an added **read** of `sca_authentications` for a finalized passed row —
independent of the current cert, so historical evidence is preserved through revocation), a `tone`
(positive|neutral) and a truthful `label`; keep `authentication_date` derivable from the item's qualifying
authentication so it survives revocation. (b) In `collection/show.blade.php:27` drive the badge colour and the
`✓` from `tone`/`certified` instead of the hard-coded green markup. **No schema, migration, event, projection,
or mutation is required** — both canonical sources (`sca_authentications`, `current_certification_id` via
`ProjectionService`) already exist and are read-only; the added authentication check is a read, not a new
projection. Confirmed: the fix **can be presentation/read-model only**.

**Test cases to add (all read-only, disposable DB).** currently certified → green ✓ "Authenticated &
Certified"; **revoked (SCA-048 case)** → neutral, no ✓, "Authenticated — no active certification", and the
SCA-048 notice + badge agree; superseded with active successor → green ✓ (still certified); authenticated-not-
yet-certified → neutral "Authenticated — not certified"; never authenticated → neutral "Recorded"; failed
authentication → neutral (no positive claim); plus regression that SCA-038 Option A passport, SCA-041 passport
access, SCA-042 documents, SCA-048 certification history and SCA-049 ownership history are unchanged/independent.

**Independence.** The fix touches only the collector item-detail badge (`detail()` read model + `show.blade`).
Public passport / Option A (separate resolver-gated surface), SCA-041 `passportEligible` gating, SCA-042
document classification, SCA-048 certification history, and SCA-049 ownership history are all independent and
unaffected.

**Planning status:** root-cause audit COMPLETE; DEFECT-001 remains **OPEN / not fixed**. Recommended as a small
read-model + presentation correctness task for ChatGPT to promote when it chooses (candidate id e.g.
`SCA-COLLECTOR-AUTHENTICITY-BADGE-052`). ACTIVE = NONE / NEXT_TASK = NONE; SCA-052 not started.

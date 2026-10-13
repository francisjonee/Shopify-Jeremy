# SCA Collector Experience / UI 2.0 — Slice 3 Implementation Evidence (pre-merge)

**Status:** CANDIDATE pushed — awaiting ChatGPT pre-merge audit. NOT merged, NOT deployed. Final collector UX slice: Authenticate/Submissions + Profile + Account presentation & journey-coherence redesign over EXISTING capabilities. **No migration**, no controller/service/route/DTO change, no new domain behavior, no Stripe activation.

| | |
|---|---|
| Governance promotion | `d285d2e621f82142eb48347e1b351a260c42c496` |
| Implementation branch | `feat/sca-collector-ui2-slice3` (1 ahead / 0 behind base) |
| Exact production base SHA | `ffef6dedfdd21d865c73bb809bf81c917b367dda` (migration 138) |
| Candidate SHA | `8ea5094519281c61a2b288aff9f96eecd1975fc8` |
| Merge base vs base SHA | exactly `ffef6dedfdd21d865c73bb809bf81c917b367dda` |
| Migration | **none** (138 unchanged) |
| Changed files vs base | 7 (576 insertions, 98 deletions) |
| Focused tests | `CollectorUi3Test` **18 passed / 171 assertions** |
| Full `tests/Feature/Sca` | **1365 passed / 1 skipped / 0 failed** (7212 assertions) |
| Production provenance FP (unchanged) | `d15a5cbdfb8df52ba65628b276533cfe`, counts `3/3/4/4/5/2/1/1/7`, migration 138 |

## Changed files (7)
- `app/packages/Sca/Collector/src/Resources/views/submissions/index.blade.php` — Authenticate index: lifecycle-first.
- `app/packages/Sca/Collector/src/Resources/views/submissions/show.blade.php` — Submission detail: stage-first hierarchy.
- `app/packages/Sca/Collector/src/Resources/views/submissions/form.blade.php` — "Step 1 of 2" journey indicator.
- `app/packages/Sca/Collector/src/Resources/views/submissions/review.blade.php` — "Step 2 of 2" journey indicator.
- `app/packages/Sca/Collector/src/Resources/views/profile.blade.php` — private-identity-first / public-sharing split.
- `app/packages/Sca/Collector/src/Resources/views/account.blade.php` — security-focused; hub nav removed.
- `app/tests/Feature/Sca/CollectorUi3Test.php` *(new, 18 tests)*.

**No controller, service, route, request, config, migration or DTO change.** Every rendered value comes from the existing controller view-data (`SubmissionController` result/return/payEnabled/events already in place, `ProfileController` publication/handle/stats data, `AccountController` identity) and existing owner-safe services. No new reader or writer was added; no authoritative state is produced by any GET.

## A. Authenticate / Submissions — lifecycle-first journey
- **Index** leads with a bold "Authenticate your eyewear" + a brief service explanation + the primary **Submit eyewear** CTA to the existing `collector.submission.create` route. Submissions render as cards: declared brand/model primary, opaque **SUB ref** secondary, a **collector-friendly truthful label derived ONLY from the canonical submission status** (draft → "Draft — not yet submitted", submitted → "Submitted — awaiting next steps", awaiting_item → "Ready to send your frame in", received → "Received by SCA — in authentication", cancelled → "Cancelled"), and a "View status →" affordance. No downstream/result data is invented on the index (none is available there). Empty state explains Submit eyewear and keeps the CTA. The obsolete "← Back to your account" link is removed (the Slice-1 shell is authoritative).
- **Detail** hierarchy: (1) submitted **frame identity** (declared brand/model, else "Eyewear submission") + muted "Submission {ref}"; (2) **Current stage → {status}** and a "**What happens next:**" explanation; (3) the **primary eligible action** — the payment CTA appears only while genuinely `submitted` AND provider-enabled (dormant message otherwise), the claim action only under canonical `claimable`, the "View it in My Collection" link only under `registered_to_you`; (4) **physical return** section when present; (5) **declared frame** block (explicitly "not yet authenticated") and **Progress history** chronology labelled as secondary **evidence**. The result switch, payment block, claim form (existing submission-bound grant→claim POST) and return switch are preserved verbatim.
- **Create → Review** now read as one journey via step indicators ("Authenticate · Step 1 of 2 — your details" / "Step 2 of 2 — review & submit"). POST/PATCH routes and transitions are untouched.
- **Payment stays dormant and truthful**: with `sca-stripe.enabled` false the submitted state says only "Online payment will be available shortly" and renders no pay form; the browser pay-return page still states "This page is not itself a confirmation of payment." No provider secret/state is exposed.
- **Failed/inconclusive** renders "did not pass", offers no claim and never reads as certified/claimable. Certified-pending-grant / claimable / registered-to-you remain distinct and exact.
- **Return** copy remains operational and independent — it never implies the return changes authentication/certification/ownership.

## B. Profile — private identity first, sharing second
- Leads with a **private identity card**: avatar (via the authenticated `collector.profile.avatar` route, never a raw storage URL) or initial, display name, email, "Collector since", optional location/bio, and the canonical collection stats (Registered frames / Certified / Distinct brands).
- **Private profile settings** card groups the Edit-profile form (`collector.profile.update`, PATCH) and Profile-photo controls (`avatar.upload` / `avatar.remove`, DELETE) — routes/validation/upload/remove semantics verbatim.
- **Public sharing** card combines publication + handle conceptually: default/private semantics, publish eligibility (display-name required), opaque permanent URL shown **only while published**, optional mutable handle with its reserved/cooling copy, and the exact unpublish/handle-remove warnings. An **unpublished profile never advertises a resolvable public link** (no "Public link" row, no Unpublish control). Publish/unpublish share one URI (`profile/publish`, POST vs DELETE); unpublished state is proven by branch text, not the URL.
- Navigation to the other sections is left to the persistent shell; the profile body no longer duplicates Collection/Authenticate/Account hub links.

## C. Account — security-focused
- Signed-in identity + **Sign out** (`collector.logout`, CSRF); an "**Account security**" password-change card (`collector.password.update`, all three fields, CSRF/validation/throttle unchanged); a visually separated final **Danger zone** linking the explicit anonymization confirmation (`collector.privacy.confirm`), eligibility/confirmation behavior unchanged.
- Redundant Profile/Collection/Authenticate hub links removed — each section route now appears exactly once (the single persistent shell nav link), proven by body occurrence count.

## D. Responsive / accessibility
- Slice-1 shell + active **Authenticate/Profile/Account** states retained (any `collector.submission.*` route marks Authenticate active across index/create/edit/review/show/pay-return).
- No fixed ≥100px widths in the changed views; flex children use `min-width:0`/`overflow-wrap:anywhere`; the 420px shell keeps a 16px gutter — no horizontal overflow at ~360px.
- Semantic headings/labels; status/stage meaning carried by **text**, not colour alone; flash/error blocks remain prominent; destructive/unpublish/remove/anonymize actions remain explicitly named; no frontend framework introduced.

## Domain/security invariants — unchanged
Collector guard + active-account boundary (guest/disabled/pseudonymized/staff fail-closed); collector-scoped submissions + privacy-safe 404; SubmissionService transitions + immutable status-event history; payment/webhook truth and Stripe dormant state; canonical bound-item result/claim eligibility + grant→claim workflow; physical-return semantics; profile/avatar/publication/handle concurrency + privacy rules; password security/throttle/recovery; privacy pseudonymization fail-closed; CSRF + opaque refs; zero new provenance/current-state writers; GET reads mutate nothing.

## Mandatory-test → evidence map
| Requirement | Test |
|---|---|
| Authenticate index/detail collector-scoped; other-collector SUB ref privacy-safe | a4 (+ existing CollectorSubmissionUxTest u8/u9, ExternalIntakeResultClaimTest r2/r13) |
| shell Authenticate active across index/create/edit/review/show/pay-return | a1, a5 |
| index/empty CTA + no obsolete Back-to-account | a1, a2 |
| draft/submitted/awaiting_item/received/cancelled wording truthful | a3 |
| downstream result cases distinct/truthful (awaiting exam, failed, passed-not-cert, certified-pending-grant, claimable, registered-to-you) | a7 |
| payment-disabled submitted doesn't claim availability; browser return doesn't claim confirmation | a8 |
| claim CTA only under claimable | a7 |
| return pending/in-transit/returned separate from auth/cert/ownership | a9 (+ existing SubmissionReturnTest) |
| declared-vs-authenticated visible | a6 |
| Profile private/public hierarchy preserves publish/unpublish/handle/avatar routes + eligibility | b1, b3 |
| unpublished profile/handle not advertised resolvable | b2 |
| Account retains password/logout/privacy, removes hub-nav role | c1 |
| anonymization Danger zone + confirmation explicit | c1 (+ existing CollectorPrivacyTest) |
| guest/pseudonymized/staff fail closed | c2 (+ existing CollectorExperienceTest ce11, CollectorSubmissionUxTest u2) |
| GET zero provenance/current-state mutation | a11, b4 |
| no internal id / grant / QR token / storage path / staff ref / other-collector identity / provider secret leak | d1 |
| existing External Paid Auth 3–6, profile CP-1/3/5, password/privacy, Collector Experience + shell green + full gate | full `tests/Feature/Sca` 1365 passed / 1 skipped / 0 failed |

## Existing-test change
`CollectorPasswordTest` lines 171/182 assert the account page contains "Account security". The redesigned Account card heading is named **"Account security"** precisely so those existing security assertions (and their `assertSeeInOrder` of Account security → Change password → Danger zone → anonymize) remain green with **no test modification**. No existing test file was edited in this slice.

## Production-untouched proof
All work ran on the disposable `sca_domain_test` DB only. The live tree is restored to `main@ffef6de`, vendor re-pruned `--no-dev`; prod DB migration **138**, provenance FP `d15a5cbd…` / counts `3/3/4/4/5/2/1/1/7` unchanged; no schema change; health 200. No Caddy/DNS/Shopify OAuth/Stripe/SMTP/infrastructure change.

**STOP — awaiting ChatGPT pre-merge audit of candidate `8ea5094`. Do not merge or deploy; do not start another initiative.**

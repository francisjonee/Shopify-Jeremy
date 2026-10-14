# NEXT TASK

**STATUS: MARKET REFERENCE / VALUE HISTORY — SLICE 2 CLOSED + LIVE. Independent ChatGPT post-deployment audit PASS.**

Production/main/deployed: `3b30a0f24323463c42dda58b476a453f58e49389`. Approved candidate: `9e8453e2bad54ed24ef22a151c881e539b9dc8be`. GitHub candidate→merge comparison: **1 ahead / 0 behind / files=[]** (exact content identity).

Deployment evidence: `docs/SCA-MARKET-REFERENCE-SLICE2-DEPLOY-RESULT.md`. Deployed-tree full SCA gate **1380 pass / 1 skip / 0 fail, 7308 assertions** (documented execution evidence; not independently run by ChatGPT). First pre-migrate gate aborted on existing load-sensitive QrReissueTest::rg8 flake; production was untouched; isolated 11/11 green and clean full rerun preceded deployment. This flake remains a separate technical-debt item; do not silently treat it as resolved.

Migration **138**, 0 pending; provenance fingerprint **d15a5cbdfb8df52ba65628b276533cfe**, canonical counts **3/3/4/4/5/2/1/1/7** unchanged PRE/POST. Health /admin/login 200, healthy app and DB, guest collector fail-closed, public Passport value-free on merge-tree tests. Stripe dormant, MAIL_MAILER=log, Shopify read_orders, no Caddy/DNS/provider drift.

**Slice 2 CLOSED + LIVE.** Current-owner-only advisory Market Reference history, newest-first, correct current/historical/void/re-record identity, no staff/internal/private leakage, no provenance/marketplace/payment mutations.

**NO NEXT INITIATIVE PROMOTED.** Reassess and architecture-audit the next roadmap priority before assigning Claude implementation. Marketplace remains unpromoted. Mail, backups, and Stripe activation remain parked unless owner reopens.

---

# NEXT TASK

**STATUS: SCA MARKET REFERENCE / VALUE HISTORY — SLICE 2 DEPLOYED TO PRODUCTION — AWAITING ChatGPT INDEPENDENT POST-DEPLOYMENT AUDIT. Slice 2 NOT closed; no other initiative started.**

## Deployment result (awaiting post-deploy audit)
| | |
|---|---|
| Deploy approval | `8b389ccfd3d30fb1c6bf9cd379fb0ddce2e40b9c` |
| Approved candidate | `9e8453e2bad54ed24ef22a151c881e539b9dc8be` |
| Audited baseline (unmoved pre-merge) | `6ca15958844dace74f7d087a10a3355a6497dd00` |
| **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD** | **`3b30a0f24323463c42dda58b476a453f58e49389`** |
| Candidate→merge tree | byte-identical (no unreviewed delta) |
| Migration | 138 (PRE/POST; "Nothing to migrate"; 0 pending) |
| Deployed-tree full gate | 1380 passed / 1 skipped / 0 failed (7308 assertions) |
| PRE==POST provenance FP | `d15a5cbd…`, counts `3/3/4/4/5/2/1/1/7` (unchanged) |
| Health | `/admin/login` 200; guest `/collector[/collection]` → 302 /collector/login; public value-free via merge-tree m12 |
| Dormancy/no-drift | Stripe dormant; MAIL_MAILER=log; SHOPIFY_SCOPES=read_orders; Caddy/DNS/provider/infra unchanged |

First gate run aborted BEFORE prod migrate on the documented unrelated `QrReissueTest::rg8` flake (11/11 green isolated); prod untouched; re-run clean per fail-before-migrate policy. Evidence: `docs/SCA-MARKET-REFERENCE-SLICE2-DEPLOY-RESULT.md`. **STOP for ChatGPT independent post-deployment audit; do not declare Slice 2 closed; do not begin another initiative.**

---

<!-- Prior PRE-MERGE PASS gate retained below for traceability. -->

**STATUS (pre-merge PASS): SCA MARKET REFERENCE / VALUE HISTORY — SLICE 2 PRE-MERGE PASS.**

Approved candidate: `9e8453e2bad54ed24ef22a151c881e539b9dc8be`
Exact production base: `6ca15958844dace74f7d087a10a3355a6497dd00`
Branch: `feat/sca-market-reference-slice2`
Migration: 138 unchanged; 5 files, no schema/route/provider/infra change.

ChatGPT independently inspected GitHub comparison, canonical MarketReferenceService reader, owner gate, controller/view and all 13 new tests. Exact base/merge-base confirmed (1 ahead, 0 behind). Event-id current marker, void semantics, owner/former-owner scoping, privacy projection and advisory UI PASS. Focused 13/73 and full 1380/7308 with 1 skip are **Claude-reported execution results**, supported by governance evidence, not independently rerun by ChatGPT. No identified pre-merge blocker.

**DEPLOYMENT GATE — CLAUDE MAY PROCEED WITH CONTROLLED MERGE/DEPLOY OF EXACT APPROVED SHA ONLY.**
1. Recheck origin/main equals exact base; if moved STOP.
2. Merge approved candidate only; prove merge tree content-identical to candidate (empty diff).
3. Run full SCA suite on merge tree; abort on any failure.
4. Confirm no migration (138), production provenance fingerprint `d15a5cbdfb8df52ba65628b276533cfe` and canonical counts `3/3/4/4/5/2/1/1/7` unchanged before/after.
5. Confirm guest/privacy smoke, public value-free boundary, app health, and no Caddy/DNS/OAuth/SMTP/Stripe drift.
6. Write deployment evidence and STOP for independent ChatGPT post-deploy audit. Do not declare Slice 2 closed until that audit.

---

# NEXT TASK

**STATUS: SCA MARKET REFERENCE / VALUE HISTORY — SLICE 2 CANDIDATE PUSHED — AWAITING ChatGPT PRE-MERGE AUDIT. NOT merged, NOT deployed.**

## Candidate under audit
| | |
|---|---|
| Governance promotion | `ad637cf400d88ffdd730082908c0db515e667f13` |
| Branch | `feat/sca-market-reference-slice2` (1 ahead / 0 behind) |
| Production base SHA | `6ca15958844dace74f7d087a10a3355a6497dd00` (migration 138) |
| Candidate SHA | `9e8453e2bad54ed24ef22a151c881e539b9dc8be` |
| Migration | none (138 unchanged) |
| Changed files | 5 (MarketReferenceService, CollectionService, CollectionController, collection/show.blade, new MarketReferenceHistoryTest), 463 ins / 12 del |
| Focused tests | `MarketReferenceHistoryTest` 13 passed / 73 assertions |
| Full `tests/Feature/Sca` | 1380 passed / 1 skipped / 0 failed (7308 assertions) |
| Prod provenance FP (unchanged) | `d15a5cbd…`, counts `3/3/4/4/5/2/1/1/7`, migration 138 |

Read/presentation expansion over the existing append-only ledger: owner-safe value history on Eyewear Detail (secondary "Value history" disclosure next to the current reference; newest-first; Current/Historical text labels by canonical fold event id; "no current Market Reference" after void; advisory-only, no delta/FX/appreciation/resale). No migration, no new authoritative state, no marketplace, no provenance mutation, no public value exposure. Evidence: `docs/SCA-MARKET-REFERENCE-SLICE2-IMPLEMENTATION.md`. **STOP for ChatGPT pre-merge audit; do not merge/deploy/start another initiative.**

---

<!-- Promotion brief retained below for traceability. -->

**STATUS (promotion): SCA MARKET REFERENCE / VALUE HISTORY — SLICE 2 PROMOTED. Production baseline is `6ca15958844dace74f7d087a10a3355a6497dd00`, migration 138. Build the collector-facing historical value timeline over the EXISTING append-only Market Reference ledger. This is a read/presentation expansion only: no marketplace, no automated valuation, no public value exposure, no provenance mutation. Push candidate and STOP for ChatGPT pre-merge audit.**

## Architecture audit conclusion
Slice 1 already has the hard domain foundation:
- append-only `sca_market_reference_events`
- canonical `MarketReferenceService` with record/supersede/void fold
- staff current + full audit history
- current-owner-safe current reference
- an existing owner-safe `collectorHistory()` projection for historical record/supersede observations
- public Passport/profile/collection/certificate/QR surfaces deliberately exclude Market Reference.

The collector currently consumes only the CURRENT reference through `CollectionService::marketReferenceForOwnedItem()`. The historical owner-safe projection exists but is not wired into the collector detail experience. Slice 2 therefore closes a real product gap without inventing another valuation system.

Marketplace/resale is deliberately NOT part of this slice. Marketplace has materially larger transaction, listing, seller-authority, adverse-status, transfer, payment and dispute architecture and must be audited separately later.

## Slice 2 goal
On an eyewear item the authenticated collector CURRENTLY owns, show a clear **Market Reference history** beneath/adjacent to the existing current advisory reference so the collector can understand how SCA's recorded market observations changed over time.

The feature must remain advisory evidence, never an appraisal guarantee, sale offer, asking price, listing price, or automated valuation.

## Required architecture

### 1. One canonical owner-safe history reader
Use/extend `MarketReferenceService` as the canonical fold/privacy boundary. Do NOT query the ledger ad hoc from Blade.

The collector history DTO must expose only:
- currency
- formatted/format-ready low/high range
- as-of date
- basis label/value
- safe source summary only if explicitly justified for collector history
- a truthful current/historical marker if needed for presentation.

It must NEVER expose:
- event/internal IDs
- actor/staff refs
- supersede/void reasons
- predecessor IDs
- source_reference unless architecture explicitly proves it is collector-safe (default: keep excluded)
- DB timestamps as operational audit data
- any Shopify/payment/provider/token data.

If distinguishing the current observation from prior observations requires internal event IDs, use them internally inside the canonical service and strip them before returning the collector DTO. Do not infer “current” by comparing value fields because a fresh record after a void may legitimately repeat an earlier value.

### 2. Truthful void semantics
A void means **there is no current Market Reference**. Historical observations may still be shown as past evidence, but none may be visually or textually represented as current.

Required cases:
- record only → one current observation
- record → supersede → latest successor current, predecessor historical
- record → supersede → void → no current; both observations historical
- record → void → fresh record → fresh record current; pre-void record historical
- repeated equivalent values across separate post-void chains must not confuse current identity.

### 3. Collector authorization
History is available only to the authenticated CURRENT owner using the same canonical ownership boundary as item detail/current Market Reference.
- non-owner → privacy-safe denial/no confirmation
- historical owner → no access after transfer
- guest/staff collector guard boundaries unchanged
- adverse registry status does not rewrite historical market evidence; follow the existing item-detail authorization/status presentation rather than inventing new ownership semantics.

### 4. Collector UX
Integrate into the existing Slice-2 Eyewear Detail hierarchy. Preserve the current Market Reference near the asset.

Add a secondary **Value history / Market Reference history** disclosure/section that:
- is easy to understand on mobile
- orders observations deterministically, newest first for collector reading
- clearly labels Current vs Historical where a current reference exists
- when current is voided, says there is **no current Market Reference** while retaining prior observations as historical evidence
- retains the existing advisory/non-guarantee wording
- never implies appreciation, investment return, guaranteed resale value, or a sale price
- does not expose staff correction/void rationale.

Do not redesign My Collection, Profile, Account, Authenticate, public profile, Passport, or staff Market Reference UI in this slice.

### 5. Optional change indicator — only if semantically safe
A numeric change/delta may be shown ONLY between adjacent observations of the SAME currency and only if it can be derived without floats or misleading cross-currency comparison. If there is any ambiguity, omit delta entirely. Do not add FX conversion.

### 6. No schema unless STOP
This slice is expected to need **no migration**. Existing ledger contains the required history.

If implementation concludes a schema change or new authoritative state is necessary, STOP and return to ChatGPT with the architectural reason before implementing it.

## Invariants that MUST NOT change
- Market Reference remains non-provenance advisory evidence.
- Existing append-only ledger lifecycle and DB constraints/triggers.
- Staff record/supersede/void behavior and ACL.
- current-reference semantics.
- ownership, authentication, certification, QR, claim, transfer, service history, registry and Shopify state.
- public Passport/profile/public collection/certificate PDF remain value-free.
- Stripe/mail/provider/infra unchanged.
- no automated external market lookup, scraping, AI valuation or marketplace behavior.

## Mandatory tests/evidence
At minimum prove:
1. current owner sees owner-safe history.
2. non-owner and former owner cannot obtain history.
3. record-only current marker.
4. supersede marks only latest current and prior historical.
5. void yields NO current while retaining historical observations.
6. fresh record after void becomes the only current observation.
7. repeated equivalent value in a later chain does not cause identity confusion.
8. newest-first deterministic presentation, including equal timestamp ordering by id internally.
9. no actor/staff ref, reason, predecessor/internal event id, source_reference, token, Shopify/provider data leaks.
10. public Passport/public profile/public collection/certificate/QR remain unchanged/value-free.
11. collector history GET/item detail is zero mutation.
12. existing Slice-1 Market Reference tests and Collector UI tests remain green.
13. full `tests/Feature/Sca` gate passes.
14. no migration; production baseline remains migration 138.

## Delivery discipline
- Branch from exact production baseline `6ca15958844dace74f7d087a10a3355a6497dd00`. If main moved, STOP.
- Prefer narrowly scoped changes in `MarketReferenceService`, `CollectionService`, collector item-detail view, and dedicated tests only.
- Do not alter staff writer semantics merely to support presentation.
- Do not weaken existing tests.
- Record exact changed files, focused tests, full SCA totals, privacy proof, zero-mutation proof and no-migration proof.
- Push candidate only.
- **Do not merge/deploy. STOP for ChatGPT pre-merge audit.**


<!-- Prior status (pre-merge PASS gate for candidate dba6c4d) retained below for traceability. -->

## ChatGPT pre-merge audit verdict — PASS
Independent GitHub audit verified:
- exact compare is **1 ahead / 0 behind**, merge base exactly `e20e549948ecbf5c967d48a7444275280dafb97c`
- exactly four changed files:
  - `collection/index.blade.php`
  - `collection/show.blade.php`
  - new `CollectorCollectionUi2Test.php`
  - narrow assertion update in `CollectorItemDetailParityTest.php`
- no migration, route, controller, service, DTO, domain writer, provider or infrastructure change
- My Collection is browse-first; private collection administration is secondary; active group/filter context preserved
- item detail is asset-first; adverse warning remains dominant; Market Reference uses the existing owner-safe DTO and retains advisory/non-guarantee semantics
- Passport/transfer eligibility remains conditional; transfer remains absent while adverse
- lost/stolen/recovered safety actions remain separated and continue through existing confirmation routes
- CP-4 visibility and CP-6 organization keep their existing routes/CSRF/domain semantics
- gallery remains owner-authorized and now exposes selected thumbnail state with `aria-pressed`; existing keyboard-focusable CSS-radio tabs and focus-visible treatment remain intact
- sensitive frame serial/QR token/storage/staff/internal data remains excluded by existing + new regression coverage
- GET catalog/detail zero-mutation coverage added
- existing parity assertion change from old “Manage item” to “Transfer” + “Report a problem” is consistent with the promoted Slice-2 architecture
- governance evidence reports focused 12/12 and full SCA gate 1347 passed / 1 skipped / 0 failed.

## Approved deployment gate
Claude may now:
1. Merge **only** approved candidate `dba6c4d7b83b674615f461d081f64d9c07e2077d` into current production main. If main moved from audited baseline before merge, STOP and return to ChatGPT.
2. Prove candidate→merge content identity (merge commit only / no unreviewed file delta).
3. Deploy the resulting merge SHA using the established controlled production procedure.
4. Confirm migration remains **138**; no migration is expected or permitted for this slice.
5. Run the full `tests/Feature/Sca` production/merge-tree gate and report exact pass/skip/fail/assertion totals.
6. Verify authenticated collector Collection index/detail and the Slice-1 shell boundary; include responsive/mobile evidence if available.
7. Record PRE/POST provenance fingerprint + canonical counts and prove unchanged.
8. Confirm no Caddy/DNS/Shopify OAuth/Stripe/SMTP/provider/infrastructure change.
9. Record exact `MERGE_SHA`, `ORIGIN_MAIN`, and `DEPLOYED_HEAD` plus deployment evidence in governance.
10. **STOP for ChatGPT post-deployment audit. Do not call Slice 2 closed and do not start another initiative.**

## Post-deployment audit targets
ChatGPT will independently verify:
- deployed SHA and candidate-identical tree
- migration 138
- full SCA gate
- collector shell/index/detail availability
- owner/privacy/security boundaries
- provenance fingerprint/counts unchanged
- no unrelated infrastructure/provider change.

**Only a post-deployment PASS closes Collector Experience / UI 2.0 Slice 2.**


<!-- Prior status (Slice 2 promotion) retained below for traceability. -->

## Architecture audit findings
Production already has strong collector capabilities but their presentation hierarchy is fragmented.

### My Collection today
Already correct/capable:
- canonical current-owner-only catalog
- stats: registered/certified/brands
- GET-only search/filter/sort with allowlisted service semantics
- private collection groups with create/rename/delete/reorder
- cards with authorized images, brand/model/ref/SKU/year/condition/certification/registry warning
- pagination and safe empty/filter states.

UX debt:
- private-group **management forms dominate the top of the catalog** before the eyewear itself
- collection browsing and collection administration are visually mixed
- controls are dense on mobile
- cards are functional but should align with the new premium collector shell/Home hierarchy
- obsolete “Back to account” remains despite persistent Slice-1 navigation.

### Eyewear Detail today
Already exposes owner-safe:
- authorized image gallery
- SCA ref + metadata/specifications
- authenticity status / condition / auth date
- certification current/history
- public Passport access
- public documents/downloads
- ownership/transfer history
- service history + corrections/annotations
- current Market Reference advisory value
- public-profile visibility control
- private collection organization
- transfer ownership
- lost/stolen/recovered controls
- adverse registry warning.

UX debt:
- Public-profile visibility and Organize cards appear **before the item identity/gallery**, so secondary management precedes the product.
- Market Reference is buried under History although it is a high-value current-item summary.
- “Manage item” mixes normal transfer with safety/destructive lost/stolen controls.
- important current facts are spread across five tabs and separate cards, making the item feel like an admin record rather than a collector asset.
- many inline styles and dense rows reduce mobile hierarchy.
- CSS-radio tabs are functional but should not hide the most important current state/value.
- imagery/brand/model should lead the experience.

## Slice 2 goal
Redesign **My Collection + Eyewear Detail presentation hierarchy** so the collector experiences owned eyewear as a premium digital collection while preserving every existing service, route, authorization and mutation rule.

This is primarily Blade/CSS/presentation composition. Reuse existing owner-safe DTOs/readers. Prefer **no controller/service changes** unless a narrowly necessary presentation composition is justified. **No migration.**

## A. My Collection — browse first, manage second
1. Keep the canonical current-owner catalog and all existing filters/sorts/pagination semantics.
2. Make eyewear the visual focus: strong responsive image cards, brand/model primary, SCA reference secondary, concise certification/registry/condition state.
3. Keep collection-group chips as the browsing switcher (All items + named groups).
4. Move create/rename/reorder/delete collection administration into a clearly secondary **Manage collections** area/disclosure below or beside browsing; it must not precede/domininate the eyewear grid on normal use.
5. Preserve active-group context and filter query behavior.
6. Mobile ~360px: controls must stack/wrap cleanly; no horizontal overflow; card tap targets remain clear.
7. Remove obsolete “Back to account” navigation; Slice-1 shell is authoritative.
8. Do not add favorites/tags/new grouping semantics.

## B. Eyewear Detail — asset-first hierarchy
The first viewport should answer:
**What is this? Is it authenticated/certified? Is it mine/currently safe? What is its current recorded market reference (if any)? What can I do next?**

Required composition:
1. **Asset hero**: gallery/image + brand/model + SCA ref + concise authenticity/certification/registry/ownership state. Preserve authorized image routes and gallery behavior.
2. **Current Market Reference**: when present, surface the existing owner-safe current advisory range near the primary summary (not buried only in History), retaining as-of, basis/source summary where appropriate and the exact non-guarantee/advisory meaning. Do not invent value, appreciation, currency conversion, comparables or history.
3. **Primary trusted actions**: Public Passport when eligible; normal ownership action such as Transfer may be reachable without hunting, but eligibility/authorization semantics remain unchanged.
4. **Details/history sections**: Authentication, Certification, Documents, Ownership history, Service history remain available and readable. Reorganizing tabs/sections is allowed; data semantics are not.
5. **Personal organization/sharing**: public-profile visibility and private-collection membership should be clearly secondary controls associated with the item, not cards that appear before identity.
6. **Safety actions**: Lost/Stolen/Recovered and staff-managed adverse state must be visually separated from ordinary actions. Preserve confirmation pages and all existing adverse transfer restrictions.
7. Do not duplicate the public Passport or certification PDF. Existing canonical routes remain authoritative.
8. Do not expose frame serial, QR token, internal IDs, storage paths, staff refs/reasons, private docs, another collector identity or any new PII.

## C. Interaction/accessibility requirements
- Continue the Slice-1 authenticated shell; Collection stays active on catalog/detail/transfer/status child routes.
- Mobile-first from ~360px through desktop; no horizontal overflow.
- Useful image alt text/fallback behavior; gallery thumbnail controls expose selected state to assistive technology, not visual class alone.
- Visible keyboard focus.
- Sections/tabs must remain usable by keyboard. If JS is used for presentation, progressive fallback must leave all essential information/actions reachable.
- Do not hide destructive/safety actions behind ambiguous icon-only controls.
- Flash success/error/status remains prominent and readable.
- Avoid introducing a frontend framework.

## D. Domain/security invariants — MUST NOT CHANGE
- current-owner authorization and privacy-safe 404
- authorized/no-store image and document routes
- public-profile item visibility semantics
- private collection membership/order semantics
- transfer workflow/token/eligibility semantics
- lost/stolen/recovered workflow + adverse restrictions
- authentication/certification/history semantics
- Market Reference Slice-1 advisory semantics
- Passport/QR/certificate semantics
- CSRF/throttle/collector guard/opaque refs
- zero new provenance/current-state writers.

No Market Reference Slice 2, marketplace/resale, analytics, notifications, SMTP, Stripe activation, backups, staff UI or public-profile/passport redesign.

## Mandatory tests / evidence
Add a focused Collector UI Slice-2 presentation test suite (or extend CollectorExperience cleanly) proving at minimum:
- catalog/detail remain current-owner scoped; previous/non-owner access remains safe
- Collection shell active state remains correct on index/detail and transfer/status child pages
- active private-group browse context and GET filters remain intact
- catalog cards use authorized image routes and never emit storage paths/internal ids
- detail hero renders owner-safe brand/model/ref and truthful current auth/cert/registry/ownership states
- Market Reference appears prominently only when canonical owner-safe current reference exists; absent/voided reference is not fabricated; advisory wording remains
- public Passport action only under existing eligibility
- visibility and private-collection controls retain exact existing route/CSRF/eligibility behavior
- transfer link/action hidden/blocked under the same adverse rules as before
- lost/stolen/recovered confirmation workflow remains intact
- documents remain owner-authorized/public-only
- gallery uses authorized ordinal image routes and selected thumbnail state is accessible
- no sensitive fields/QR token/storage path/staff refs leak into detail HTML
- GET index/detail remains zero provenance/current-state mutation
- ~360px responsive evidence (automated browser if available; otherwise deterministic markup/CSS assertions + documented manual viewport evidence)
- existing CP-2/CP-4/CP-6, item-detail parity/gallery, transfer/status, Market Reference and Collector Experience tests remain green
- full `tests/Feature/Sca` gate passes.

## Delivery discipline
- Branch from exact production `e20e549948ecbf5c967d48a7444275280dafb97c`. If main moved, STOP.
- **No migration.** If schema/new authoritative state seems necessary, STOP and return architecture rationale.
- Do not refactor domain services merely for aesthetics.
- Keep changes narrowly in collector presentation/tests unless a presentation DTO composition change is justified and documented.
- Record changed files, focused/full tests, responsive evidence, and zero-mutation/privacy proof in governance implementation evidence.
- Push candidate only. **Do not merge/deploy. STOP for ChatGPT pre-merge audit.**


<!-- Prior status (pre-merge PASS gate for candidate 0c8628d) retained below for traceability. -->

## ChatGPT R1 re-audit — PASS
Independently verified actual GitHub candidate `0c8628d352f9a0fb843774bff5281bc808a9248c`:
- exact production base `9cf72728248cf3e36d0525de4520d69717dacd5d`
- exactly **1 ahead / 0 behind**
- no migration
- original accepted Slice-1 shell/Home/navigation/privacy/current-owner/image/route boundaries preserved
- R1 submission summary is now derived only from canonical collector-scoped submission status:
  - `draft|submitted|awaiting_item` → **Awaiting receipt by SCA**
  - `received` → **Received & being processed**
  - `cancelled` → total only; never represented as active or completed
- no downstream authentication/payment/claim/return state is invented by the Home projection
- a received frame remains represented as being processed regardless of awaiting-exam / passed-not-certified / certified / failed-auth examples
- cross-collector submissions do not affect the summary
- dashboard GET remains zero-mutation
- accepted reported gate: focused 21 passed; full `tests/Feature/Sca` 1335 passed / 1 skipped / 0 failed.

R1 is CLOSED. No further remediation required before merge.

## Controlled merge + deployment gate
Deploy **only** the exact approved candidate `0c8628d352f9a0fb843774bff5281bc808a9248c`.

1. Merge the approved branch to `main`.
2. Prove the merge tree is candidate-identical (merge commit only; no unexpected file/content delta from the approved candidate).
3. Deploy the resulting exact `main` merge commit using the established production procedure.
4. Confirm migration remains **138**; there is no migration in this slice.
5. Run the focused CollectorExperience/AppPolish tests and the full `tests/Feature/Sca` gate on the deployed/merge tree.
6. Confirm production health, including `/admin/login → 200`, collector guest `/collector` → sign-in, and an authenticated collector Home renders successfully.
7. Verify canonical provenance fingerprint/counts are unchanged from pre-deploy baseline:
   - fingerprint `d15a5cbdfb8df52ba65628b276533cfe`
   - counts `3/3/4/4/5/2/1/1/7`
8. Confirm no schema/provider/infrastructure drift: no Caddy/DNS/OAuth/SMTP/Stripe change.
9. Record merge SHA, deployed SHA, test results, migration, fingerprint/counts and smoke results in governance evidence.

If any gate fails, restore production to the pre-deploy baseline and STOP.

After successful deployment, **STOP for ChatGPT independent post-deployment audit. Do not declare Slice 1 closed and do not begin Slice 2 or another initiative.**


<!-- Prior status (pre-merge FAIL R1 of candidate b69824f) retained below for traceability. -->

## ChatGPT independent audit
Verified actual GitHub candidate:
- exact base `9cf72728248cf3e36d0525de4520d69717dacd5d`
- exactly **1 ahead / 0 behind**
- exactly 7 expected presentation/read-model/test files
- no migration
- authenticated shell/route guard boundaries intact
- guest auth pages remain without authenticated nav
- active nav grouping is coherent for Home/Collection/transfer/status/Submissions/Profile/Account
- dashboard collection data reuses canonical current-owner catalog/stats; catalog itself is bounded to page size 24 before Home slices to 4
- preview uses authorized image/detail routes and no raw storage path
- publication state is collector-scoped
- dashboard is read-only; no observed provenance/current-state writer introduced
- accepted candidate report: focused 17 pass; full SCA 1331 pass / 1 skip / 0 fail.

Do NOT reopen these accepted areas in R1.

## R1 blocker — Home's “In progress” submission count becomes false after physical receipt
`CollectorDashboardService::ACTIVE_SUBMISSION_STATUSES` is:
`['draft', 'submitted', 'awaiting_item']`.

The Home view renders that count under the consumer-facing label **“In progress.”**

But the canonical `SubmissionService` deliberately makes `received` terminal only for the submission-state machine; later External Paid Authentication slices keep the submission status at `received` while the bound item proceeds through authentication, certification, grant/claim, and physical-return handling. Slice 6 explicitly preserves submission status `received` and tracks return separately.

Therefore “terminal in SubmissionService” does NOT mean “authentication work complete” to the collector. A received frame can still be actively under examination / passed-not-certified / certified-pending-grant / claimable / return-pending, while the new Home dashboard reports it as not in progress. Example: one collector submission at `received`, bound item awaiting examination → Home shows Total=1, In progress=0. That is materially misleading.

The promotion required a **truthful meaningful active/pending summary** and prohibited invented provider/payment state.

## Required R1 remediation
Do not solve this by merely adding `received` blindly to a constant without defining the user-facing meaning.

Choose one coherent projection and document it:
1. Prefer a collector-facing **“Needs attention / In progress / Completed”** summary derived from existing submission + bound-item/result/return state, reusing the already-established safe result semantics where practical; OR
2. If Slice 1 should stay intentionally simpler, change the metric/label to something whose semantics are exactly true from the canonical submission status (for example a narrowly named pre-receipt metric), and ensure received work is not presented as completed/inactive by implication.

Whichever approach is chosen:
- no new authoritative state/table/migration
- no payment/provider invention
- collector-scoped only
- no extra PII/internal ids
- no mutation
- keep the dashboard bounded
- preserve all existing domain workflows.

### Mandatory R1 tests
Add focused proof covering at least:
- draft/submitted/awaiting_item semantics
- a `received` submission with bound item **awaiting examination**
- a received item **passed but not certified**
- a received item **certified / claimable or registered-to-you** as applicable to the chosen projection
- failed/inconclusive + return state where relevant to the chosen labels
- cancelled submission
- another collector's submissions never affect counts
- dashboard GET remains zero-mutation.

The assertions must test the **user-visible label/count semantics**, not only a private constant.

Re-run focused Collector Experience/AppPolish and full `tests/Feature/Sca`.

Push remediation candidate only. **Do not merge/deploy. STOP for ChatGPT R1 re-audit.**


<!-- Prior status (Collector UI 2.0 Slice 1 promotion) retained below for traceability. -->

## Architecture audit findings
The collector domain is already broad: account/security, private/public profile + handle/avatar, My Collection, rich item detail/gallery/passport, certification/authentication/ownership/transfer/service histories, private collection groups, public-item visibility, lost/stolen/recovered, transfer, documents, external-auth submissions/payment/claim, and current-owner Market Reference.

The experience layer has not caught up:
- `/collector` is a pure redirect rather than a collector home.
- The shared layout is fundamentally a narrow ~420px form shell; only item detail opts into a wider layout.
- There is no persistent authenticated primary navigation. Discovery relies heavily on contextual text links among Account/Profile/My Collection/Submissions.
- Account currently doubles as a landing/navigation page while also containing password and irreversible privacy controls.
- Profile is long and mixes identity, stats, editing, avatar, publication and handle management in one vertical form.
- Submission list is functional but isolated from a unified collector overview.
- Item detail is already the strongest experience and should be preserved/refined rather than rebuilt.
- Existing route/controller authorization and privacy boundaries are strong; UI work must not weaken them.

## Slice 1 goal
Create a **mobile-first Collector Home + shared authenticated application shell** that makes the already-built product understandable and reachable. Do NOT add new domain capabilities in this slice.

Target information architecture:
- **Home** — new authenticated `/collector` dashboard.
- **Collection** — existing My Collection.
- **Authenticate** — existing submissions area / new-submission entry.
- **Profile** — existing collector profile.
- **Account** — existing security/privacy settings.

Desktop: compact persistent top/side navigation appropriate to the existing SCA visual language.
Mobile: touch-friendly persistent navigation/header with no horizontal overflow; key actions reachable without hunting through text links. Do not introduce a JS framework solely for navigation.

## Home dashboard read model
Build a dedicated, bounded dashboard projection from existing canonical/read services; no new authoritative tables.
Show only truthful collector-scoped information already authorized elsewhere:
- greeting/display identity
- owned-item count, certified count, distinct brands (reuse existing profile stats semantics)
- a small recent/current collection preview with image only through existing authorized image route and links to canonical item detail
- external authentication submission summary: meaningful active/pending states + link to submissions; do not invent payment/provider state
- pending ownership-transfer attention only if existing workflow/read model can expose it safely
- profile/publication state summary + link to Profile
- primary actions: View collection / Submit eyewear.
Do not fabricate an activity feed by querying unrelated audit/provenance tables in this slice.

## Shell/navigation requirements
1. Guest auth pages (login/register/forgot/reset) remain simple and must NOT expose authenticated navigation.
2. Authenticated shell gets consistent nav and active-state semantics across Home, Collection/detail, Submissions, Profile and Account.
3. `GET /collector`: guest behavior remains redirect-to-login; authenticated collector now renders Home rather than redirecting to Collection.
4. Preserve existing route names where possible; add only the minimum home route/controller/view/read-model changes.
5. Account stops acting as the primary navigation hub; keep password/security/privacy behavior intact.
6. Preserve every CSRF/throttle/collector-guard/current-owner/opaque-ref/privacy rule.
7. No staff/admin navigation or Krayin chrome.
8. No public-profile/public-passport redesign in Slice 1.
9. No changes to transfer/status/submission/payment/claim/provenance mutation semantics.
10. No Market Reference expansion, automated pricing, marketplace/resale, notifications, analytics, SMTP, Stripe activation or backup work.

## Responsive/accessibility quality gate
- Design for ~360px mobile through desktop; no horizontal overflow in shell/dashboard.
- Visible keyboard focus; semantic nav; current page indicated beyond color alone; adequate touch targets.
- Preserve readable labels/errors/status messages and form semantics.
- Avoid hiding security/destructive controls behind ambiguous icons.
- Images must have useful alt/fallback behavior and retain current authorization/no-store behavior.
- No raw storage paths/internal IDs/secrets/PII leakage.

## Mandatory tests
Add focused Collector Experience tests proving at minimum:
- guest `/collector` still reaches sign-in safely; authenticated `/collector` renders Home.
- authenticated nav appears on Home/Collection/item/Submissions/Profile/Account; guest auth pages do not receive it.
- active navigation state is correct for child/detail routes.
- dashboard stats are collector-scoped and reuse canonical semantics.
- collection preview cannot leak previous/non-owner items; images use authorized routes.
- submission summary is collector-scoped and truthful.
- dashboard GET causes zero provenance/current-state/domain mutation.
- disabled/pseudonymized/unauthenticated boundary behavior remains fail-closed.
- existing item-detail, collection, profile, submission, transfer/status and auth tests remain green.
- full `tests/Feature/Sca` gate passes.

## Delivery discipline
- Branch from exact production `9cf72728248cf3e36d0525de4520d69717dacd5d`. If main moved, STOP.
- Prefer no migration. If implementation believes schema is required, STOP and return architecture rationale before adding one.
- Keep changes inside collector presentation/read-model/test surfaces unless a narrowly necessary shared presentation helper is justified.
- Record changed files, focused/full test results, screenshots or viewport evidence if available, and zero-domain-mutation proof in a task report.
- Push candidate only. **Do not merge/deploy. STOP for ChatGPT pre-merge audit.**


<!-- Prior status (controlled activation promotion) retained below for traceability. -->

## Audited production architecture
- Collector forgot/reset uses dedicated `sca_collectors` broker, hashed account-bound 60-minute single-use token, active-only eligibility, CSRF and throttle, enumeration-safe generic response, no auto-login or provenance mutation.
- ForgotPasswordController catches mail transport exceptions without exposing account status/PII; intentionally retains token because SMTP failure may occur after provider acceptance.
- Collector reset notification URL origin was hardened to trusted `config('app.url')` rather than request Host.
- `app/config/mail.php` no longer disables SMTP TLS peer verification.
- Docker app loads `app/.env` directly (no injected env_file); app is loopback-only behind existing Caddy.
- Production `MAIL_MAILER=log`, so real delivery remains inactive.
- No SMTP provider credential or verified sender/domain is established by this audit. Do not invent either.
- Public canonical application origin: `https://verify.secondchanceauthenticators.com`. Verify actual effective `APP_URL` before activation; do not assume it matches.

## Provider decision
Use **Postmark Transactional SMTP**, not Broadcast SMTP or API transport. Official Postmark SMTP host `smtp.postmarkapp.com`, port 587 STARTTLS. Prefer a dedicated per-Transactional-stream SMTP Token (access key username, secret key password) rather than account-wide credentials. Postmark must verify the sender domain/signature and DNS DKIM + custom Return-Path; check DMARC alignment. Follow provider-generated DNS values exactly; never fabricate DKIM or credential values.

Proposed sender identity: a dedicated mailbox at `send.secondchanceauthenticators.com` (e.g. `no-reply@send.secondchanceauthenticators.com`) ONLY if verified and accepted by the owner/provider. If the owner chooses a different sender/domain, record that decision before changing DNS. Do not modify MX, existing mail routing, or unrelated DNS.

## One controlled activation work package

### Phase 0 — read-only preflight and external prerequisites
1. Verify production main/deployed SHA `9cf7272...`, migration 138, clean tree, existing reset/mail tests, current effective `APP_URL`, `MAIL_MAILER`, `MAIL_FROM_ADDRESS`, config cache state, PHP SMTP transport availability, egress to Postmark TCP 587, and authoritative DNS control.
2. Identify Postmark account/server/Transactional stream availability, SMTP enabled, verified sender/domain, provider-supplied DKIM/Return-Path DNS, and authorized safe recipient inbox for real test. **Do not print/commit/mail/log secrets or reset tokens.**
3. If provider access, DNS authority, test inbox, or SMTP credentials are missing, **STOP WITH BLOCKED PREREQUISITES** and return a precise owner action list. Do not silently switch to another provider or claim activation.

### Phase 1 — provider/DNS readiness (only with explicit owner authorization)
4. Create/use a dedicated Postmark Transactional stream and scoped SMTP Token; never use broadcast host/stream.
5. Configure ONLY provider-issued DKIM TXT and custom Return-Path CNAME for approved sending domain; verify status in Postmark and validate DNS propagation, SPF/DMARC alignment. Preserve existing DNS/MX and other tenants.
6. Validate trusted `APP_URL` and From identity before real mail. Keep `MAIL_MAILER=log` until prerequisites and test transport are proven.
7. Record sanitized evidence of provider stream status, DNS verification, and SMTP TLS reachability (never credentials).

### Phase 2 — safe isolated delivery proof
8. Use a disposable isolated runtime/config or non-production test account/inbox to prove Postmark SMTP auth and STARTTLS with certificate verification ON, correct sender/recipient, provider acceptance and actual mailbox receipt. No production customer email during setup.
9. Validate delivered headers: DKIM pass, SPF/Return-Path alignment as configured, DMARC pass, trusted HTTPS reset origin; verify no Host-header poisoning. Provider acceptance alone is NOT inbox delivery proof.
10. Exercise a controlled collector password reset end-to-end using an authorized test collector/inbox: active account gets link, single use, expiry, no auto-login; unknown/disabled generic responses and no usable reset; mail failure stays enumeration-safe; no provenance/identity mutation.
11. Ensure logs, screenshots, governance evidence and tests do not contain SMTP tokens, collector emails, reset links, plaintext tokens or personal data.

### Phase 3 — production cutover / rollback
12. Only after Phase 2 PASS and owner-authorized change window, securely set production `MAIL_MAILER=smtp`, `MAIL_HOST=smtp.postmarkapp.com`, `MAIL_PORT=587`, `MAIL_ENCRYPTION=tls`, scoped `MAIL_USERNAME`/`MAIL_PASSWORD`, verified `MAIL_FROM_ADDRESS`/`MAIL_FROM_NAME`, canonical HTTPS `APP_URL`; retain TLS peer verification.
13. Reload/clear config safely and confirm effective transport WITHOUT printing secrets. Do not change application code/schema unless a separately reviewed defect truly requires it.
14. Controlled production delivery smoke only to authorized test inbox; confirm real receipt and one successful test-account reset. Confirm no customer blast.
15. Re-check app health, collector/guest boundary, canonical provenance fingerprint/counts, current-state and integration config. No Caddy/edge/Shopify/Stripe/DB migration changes.
16. On any authentication/TLS/DNS/delivery/reset/security failure, rollback `MAIL_MAILER=log` and restore previous safe mail config, then re-check health and report BLOCKED. Do not leave partially activated SMTP or pretend log delivery is success.

### Evidence and stop
- Run focused existing `TransactionalEmailHardeningTest`, `CollectorPasswordRecoveryTest`, and full `tests/Feature/Sca` before production cutover if runtime permits.
- Record exact deployed SHA/migration, prerequisite states, sanitized provider/DNS/TLS checks, authorized test mailbox receipt and authentication results, reset lifecycle matrix, PRE/POST invariants, config change/rollback evidence.
- Commit governance report `docs/SCA-TRANSACTIONAL-EMAIL-ACTIVATION-RESULT.md` (no secrets).
- **STOP for ChatGPT independent activation audit.** Do not declare email LIVE until independent audit PASS. Do not start backups, Stripe, pricing, resale or other initiative.


<!-- Prior status (pre-merge PASS gate for candidate d880e12) retained below for traceability. -->

## ChatGPT pre-merge audit verdict
**PASS.**

Independent audit of actual GitHub candidate confirms:
- exact production base `b4b51b7bb0244da6e1624c1095239c80cc206bb9`
- candidate exactly 1 commit ahead / 0 behind
- Slice 1 remains scoped to the audited 17 implementation/test files
- expected migration 137→138
- dedicated append-only, non-provenance Market Reference ledger
- record/supersede/void lifecycle
- integer minor-unit range + USD/PHP and basis allowlists
- strict exact calendar-date validation
- immutable UPDATE/DELETE blocking
- same-item predecessor enforcement
- DB lifecycle enforcement against actual current effective event
- DB monotonic append-order enforcement consistent with canonical `(created_at,id)` fold
- equal timestamps valid and deterministically ordered by higher id
- service item-state FOR UPDATE + optimistic token STALE protection
- genuine two-connection production-service concurrency proof
- dedicated ACL/auth/CSRF/throttle + server-derived actor
- staff full audit history
- current-owner-only safe collector projection
- public Passport/profile/collection, certificate snapshot/PDF and QR remain valuation-free
- no automated/AI/external pricing or Shopify-price ingestion
- zero intended provenance/current-state mutation.

R1 and R2 direct proofs are accepted:
- impossible/non-exact dates fail closed; valid leap date accepted; future policy preserved
- raw second-current record rejected
- raw historical predecessor supersede/void rejected
- valid lifecycle rows accepted
- backdated current supersede rejected
- backdated current void rejected
- backdated post-void fresh record rejected
- equal-timestamp successor accepted and proven canonical current
- normal production-service record→supersede→void remains correct.

Reported focused gate: **35 passed**.
Reported full SCA gate: **1320 passed / 1 skipped / 0 failed**.

## Controlled merge/deployment gate
Claude may merge/deploy **only exact approved candidate `d880e128e0713d60e42a2d821206cf663c09be43`**.

1. Reconfirm main/production is still exact baseline `b4b51b7bb0244da6e1624c1095239c80cc206bb9`. If it moved, STOP.
2. Reconfirm candidate is 1 ahead / 0 behind and candidate tree unchanged.
3. Merge with an auditable merge commit. Prove candidate→merge has **zero changed files** / content-identical tree. Any drift = STOP.
4. Run the exact merge-tree full `tests/Feature/Sca` gate before production migration. Any real failure = STOP before migrate. Existing documented unrelated flakes may only be handled under the established fail-before-migrate/rerun policy and must be disclosed.
5. Capture PRE production:
   - migration number 137
   - reproducible provenance fingerprint and canonical counts
   - Market Reference table absent
   - relevant baseline integration/config state.
6. Apply migration 138 once.
7. Verify production schema exactly:
   - `sca_market_reference_events`
   - all CHECK constraints
   - append-only UPDATE/DELETE triggers
   - BEFORE INSERT same-item + lifecycle + monotonic-order trigger
   - self/item FKs and expected indexes.
8. Immediately after deploy, Market Reference ledger must contain **0 rows** unless a real independently authorized staff action occurred. Do not fabricate production Market Reference evidence for smoke testing.
9. Run production-safe route/boundary smoke:
   - app/admin health
   - routes registered
   - unauthenticated mutation fail-closed
   - dedicated ACL/CSRF/throttle already proven by exact merge-tree tests
   - collector/public surfaces remain healthy without creating evidence.
10. Capture POST provenance fingerprint/counts and prove byte/count identity to PRE.
11. Confirm no unexpected changes to service history, ownership/current state, authentication, certification/PDF/snapshot, QR, registry status, claim/transfer, Shopify sale links, collector accounts.
12. Confirm no Caddy/DNS/Shopify OAuth/Stripe/SMTP changes; Stripe remains dormant and mail remains current production configuration.
13. Record exact merge/main/deployed SHA, migration 138, exact merge-tree test results, schema verification, PRE/POST invariants, ledger count, boundary smoke, and integration/config evidence in a governance deployment result document.

**STOP after deployment evidence. Do not declare Slice 1 closed. Do not start automated pricing, public value exposure, resale, or another initiative. Return to ChatGPT for independent post-deployment audit.**

<!-- Prior status (R1 re-audit FAIL R2 of candidate 23c28eb) retained below for traceability. -->

## ChatGPT independent R1 re-audit
Verified actual GitHub candidate:
- exact production base `b4b51b7bb0244da6e1624c1095239c80cc206bb9`
- candidate `23c28ebc78754e82dfc37e082d04ca983dcdc234`
- exactly 1 commit ahead / 0 behind base
- rewritten single candidate commit relative to prior failed SHA is acceptable
- accepted Slice-1 architecture remains intact.

### R1 blocker B — CLOSED
`MarketReferenceService::normAsOfDate()` now:
- requires exact `YYYY-MM-DD`;
- uses strict createFromFormat + exact round-trip;
- rejects impossible/non-exact dates;
- retains future tolerance.

`mr27` directly exercises the production service and proves impossible/non-exact rejection, valid leap date, zero invalid writes, and preserved future rejection.

Do not change this area in R2.

### R1 blocker A — PARTIALLY CLOSED; narrow R2 remains
`trg_mre_bi` now correctly derives the existing stream's current event by `(created_at,id)` and rejects:
- record while a current exists;
- supersede whose predecessor is not the existing current;
- void whose predecessor is not the existing current;
- cross-item predecessors.

The direct-DB tests genuinely prove those normal-order cases.

## R2 blocker — NEW row can be backdated behind the event it supersedes/voids
The canonical fold order is `(created_at,id)`. The BEFORE INSERT trigger validates lifecycle against the stream **before** NEW is inserted, but it does not constrain NEW.created_at relative to the existing last event.

Therefore a raw insert can:
1. have current `e1`;
2. insert a structurally valid `supersede e2 -> e1` with `NEW.created_at < e1.created_at`;
3. pass the trigger because e1 is current before the insert;
4. after insertion, canonical `foldCurrent()` orders e2 before e1, so e1 remains effective even though immutable e2 says it supersedes e1.

The same ordering defect applies to a backdated void. It also allows a fresh record inserted after a void to be backdated before that void, so the trigger accepts it while the fold still ends at the void.

This means the DB still permits immutable lifecycle evidence whose predecessor/action semantics disagree with the canonical fold.

### Required R2 remediation
At the DB insert boundary, guarantee that every newly appended market-reference event sorts after the existing last event for that item under the canonical `(created_at,id)` ordering.

A narrow acceptable implementation is to reject a NEW row whose `created_at` is earlier than the existing last event's `created_at`. Equal timestamps are valid because the auto-increment NEW id sorts after the prior id.

Preserve:
- canonical fold order `(created_at,id)`;
- service-created `now()` timestamps;
- current lifecycle trigger logic;
- append-only semantics;
- all accepted R1 behavior.

Do not redesign the ledger or change the product policy.

### Mandatory R2 direct-DB proof
Add raw DB tests showing:
1. backdated supersede of the actual current event is rejected;
2. backdated void of the actual current event is rejected;
3. after a valid void, a backdated fresh record that would sort before the void is rejected;
4. equal-timestamp valid successor remains accepted and becomes current by higher id;
5. normal service record/supersede/void remains unchanged.

For accepted inserts, assert the canonical `currentReference()` result agrees with the lifecycle action/predecessor.

Re-run focused MarketReference tests including the real two-connection concurrency test and full `tests/Feature/Sca`.

Update `docs/SCA-MARKET-REFERENCE-SLICE1-IMPLEMENTATION.md` with R2 evidence, push a NEW candidate SHA, and STOP.

**DO NOT merge. DO NOT deploy. DO NOT begin another initiative.**

<!-- Prior status (pre-merge FAIL R1 of candidate 26a572a) retained below for traceability. -->

## ChatGPT independent pre-merge audit
Actual GitHub candidate verified:
- exact base `b4b51b7bb0244da6e1624c1095239c80cc206bb9`
- candidate exactly 1 commit ahead / 0 behind
- 17 changed files
- expected migration 137→138
- dedicated append-only market-reference ledger
- record/supersede/void application lifecycle
- integer minor units + bounded USD/PHP and basis allowlists
- item-state FOR UPDATE + event-count/current-id STALE protection
- genuine two-process/two-connection production-service concurrency proof
- dedicated ACL + staff auth/CSRF/throttle
- server-derived actor
- canonical service reader + collector privacy projection
- current-owner-only collector integration
- public Passport/profile/collection exclusion
- certificate snapshot/PDF + QR exclusion
- zero intended provenance/current-state mutation
- append-only UPDATE/DELETE triggers and same-item predecessor trigger.

Those areas are accepted for R1 and should not be redesigned.

## R1 blocker A — immutable DB ledger permits semantically impossible histories
The DB currently enforces row shape and **same-item** predecessor linkage, but not lifecycle validity.

A direct/raw insert can still persist structurally valid but impossible immutable history, for example:
1. `record → record` while the first record is still current;
2. `record(e1) → supersede(e2→e1) → supersede(e3→e1)`, where e3 targets the historical/non-current e1;
3. `void` targeting a historical/non-current same-item event.

The application service correctly rejects these paths, but the canonical reader `foldCurrent()` trusts every persisted row and simply treats any record/supersede as current and any void as clearing current. Therefore one malformed raw row can permanently alter effective Market Reference state even though the ledger is append-only and cannot be repaired.

This conflicts with the promoted invariants:
- at most one effective current per item;
- supersede/void must target the current effective event;
- no supersede/void of historical target;
- malformed raw rows must fail closed at the DB boundary;
- immutable evidence must not permit impossible event histories.

### Required remediation A
Add insert-time DB enforcement (trigger or equivalent DB boundary) that validates the lifecycle against the existing immutable stream for NEW.eyewear_item_id:
- `record` allowed only when the current effective state is null (first ever or after a valid current void);
- `supersede` predecessor must equal the actual current effective event for that item;
- `void` predecessor must equal the actual current effective event for that item;
- preserve same-item predecessor enforcement;
- after a valid void, a fresh record remains allowed.

Keep the production service locking/token logic unchanged. The DB rule is defense-in-depth for raw/malformed rows, not a replacement for service serialization.

Add direct-DB tests proving:
- second record while current exists is rejected;
- supersede of historical same-item predecessor is rejected;
- void of historical same-item predecessor is rejected;
- valid current supersede and valid current void still work;
- fresh record after valid void still works.

## R1 blocker B — canonical service accepts impossible calendar dates
`MarketReferenceService::normAsOfDate()` uses permissive `Carbon::parse()`. Inputs such as an impossible calendar date can normalize to another real date rather than fail, even though the architecture requires invalid dates to fail closed and MarketReferenceService is the canonical writer/validator.

The FormRequest's `date` rule protects the HTTP UI, but direct callers of the production service are part of the domain boundary and current focused tests explicitly exercise the service directly.

### Required remediation B
Use strict YYYY-MM-DD validation in `MarketReferenceService` itself:
- exact format only;
- reject impossible calendar dates rather than normalize them;
- retain the existing future-tolerance policy after strict parsing.

Add service-level tests for at least:
- impossible date such as `2026-02-31` rejected with INVALID and zero write;
- malformed but parseable/non-exact date rejected;
- valid leap/calendar date accepted as appropriate;
- existing future-date rejection preserved.

## R1 scope guard
Do NOT redesign:
- record/supersede/void product policy;
- staff/collector UI;
- amount/currency/basis model;
- ACL/routes;
- owner privacy;
- public exposure policy;
- concurrency mechanism;
- provenance boundaries;
- automated pricing/public value/resale.

Re-run focused MarketReference tests including real concurrency and full `tests/Feature/Sca`. Update `docs/SCA-MARKET-REFERENCE-SLICE1-IMPLEMENTATION.md` with R1 evidence, push a NEW candidate SHA, and **STOP**.

**DO NOT merge. DO NOT deploy. DO NOT begin another initiative.**

<!-- Prior status (pre-merge PASS gate for candidate 2d578feb) retained below for traceability. -->

### ChatGPT pre-merge audit verdict
**PASS.** Actual GitHub candidate `2d578feb5f429d9e7549d968c21fbfc879ba0885` satisfies the promoted Service History Correction & Annotation architecture after R1/R2 remediation.

Verified:
- exactly 1 commit ahead / 0 behind production base `9bc0907...`
- scoped 15-file slice; no unrelated initiative
- migration 136→137 creates dedicated append-only `sca_service_event_corrections`
- original `sca_service_events` remains immutable and untouched
- sparse factual evidence uses explicit per-field change flags
- nullable notes/grade support unambiguous explicit clear via flag=1 + NULL
- non-nullable service_type/occurred_at require a value when flagged
- DB CHECKs now enforce sparse-row self-consistency; contradictory raw rows fail closed
- non-correct rows cannot carry corrected factual payload
- DB cross-item trigger + service exact item/event binding prevent rebinding
- correction ledger UPDATE/DELETE blocked
- deterministic fold applies only flagged fields in `(created_at,id)` order
- selected-but-equal values are omitted; all-NOOP rejects
- staff chronology renders exact changed fields old→new plus actor/time/reason
- item current-state `FOR UPDATE` serialization + correction-count token provide STALE protection
- real two-connection concurrency proof remains present
- terminal void behavior preserved
- dedicated `sca.eyewear.service.correct` ACL, admin auth/CSRF/throttle boundary preserved
- collector path is a privacy projection over the same canonical fold; voided events and staff-only audit data excluded
- public passport remains service-free
- `ServiceService::record()` and `ProjectionService::rebuild()` unchanged
- zero intended ownership/current-state/authentication/certification/QR/status/claim/transfer/Shopify mutation
- R2 raw-DB tests prove unflagged payload rejection, required flagged values, and valid nullable clears
- explicit condition-grade clear-to-NULL is proven through production controller/service
- reported focused result: 42 passed
- reported full SCA result: 1285 passed / 1 skipped / 0 failed.

### Controlled merge/deployment gate
Claude may now merge/deploy **only this exact approved candidate** `2d578feb5f429d9e7549d968c21fbfc879ba0885`.

Before merge/deploy:
1. Reconfirm production/main baseline is still `9bc0907c486688c7acd0d22ad2ee9f5db37d93bb`; if main/production moved, STOP for ChatGPT.
2. Reconfirm approved candidate is exactly 1 ahead / 0 behind baseline and candidate tree is unchanged.
3. Merge with a normal auditable merge commit; after merge, prove candidate→merge tree has **zero changed files**. Any content drift = STOP.
4. Run the exact merge tree full `tests/Feature/Sca` gate before production migration. Known unrelated low-ID document-classification flake may be rerun only under the established policy; any real failure = STOP before migrate.
5. Capture PRE production migration number, provenance fingerprint/counts, service-event count, and confirm correction table absent.
6. Apply migration 137 once. Verify table, all CHECK constraints, append-only triggers, cross-item trigger and indexes exist.
7. Run production-safe health/boundary smoke only; do not fabricate or mutate real service/correction evidence merely to demonstrate the feature.
8. Capture POST provenance fingerprint/counts and service-event count; they must be byte/count identical to PRE. New correction table should contain 0 rows immediately after deploy unless a real authorized staff action occurs independently.
9. Confirm no Caddy/DNS/Shopify OAuth/Stripe/SMTP changes; Stripe remains dormant and mail remains current production configuration.
10. Record exact merge SHA, main SHA, deployed SHA, migration 137, exact merge-tree test result, schema evidence, PRE/POST invariants and health/boundary results in a governance deployment evidence document.

**STOP after deployment evidence. Do not declare the initiative closed. Do not start another initiative. Return to ChatGPT for independent post-deployment audit.**

Updated 2026-10-13.

## Why this is next
Shopify Reconciliation & Operations is CLOSED. ChatGPT audited the live service-history architecture at production `9bc0907`.

The existing service-history foundation is intentionally strong and must be preserved:
- `sca_service_events` is append-only and storage-immutable.
- service recording is staff-only and session-attributed.
- service type and condition observations are validated.
- service events never rewrite authentication grade, certification, ownership, registry status, QR identity, or lifecycle.
- the current owner sees owner-safe service history; non-owners fail closed.
- public Passport does not expose service notes/staff data.

The operational integrity gap is correction: if staff records the wrong service type/date/condition/notes, there is currently no governed way to correct the record. Editing/deleting the immutable event is forbidden and must remain forbidden.

## Initiative
**SCA Service-History Correction & Annotation**

Build an append-only correction/annotation layer over immutable service events.

### Core invariant
**A recorded service event is permanent historical evidence. Correction never edits or deletes it. A correction appends new evidence that explicitly supersedes/corrects presentation of the target event while preserving the original forever. Service-history correction must never mutate ownership, authentication, certification, QR, registry status, claim, Shopify state, or any other provenance domain.**

### Architecture requirements
1. Preserve the existing `sca_service_events` rows and immutability trigger unchanged. No UPDATE/DELETE escape hatch.
2. Add a dedicated append-only service-history correction/annotation ledger, preferably migration **136→137**.
3. Corrections target one exact existing service event and exact eyewear item. The target relationship must be server-validated; cross-item correction must fail closed.
4. Do NOT create a replacement `sca_service_events` row pretending the corrected facts were another real service occurrence. Keep the original service occurrence immutable and attach correction evidence to it.
5. Support a bounded correction snapshot for the displayable service facts:
   - service type
   - occurred_at
   - condition_grade_after
   - notes
   A correction should carry the effective corrected values plus mandatory reason, actor staff ref, and created_at.
6. Prefer **full corrected snapshot per correction row** rather than one row per changed field, because service history is one coherent historical occurrence and reads need deterministic latest-effective presentation.
7. Corrections themselves are append-only. If a correction is wrong, append another correction against the same original service event. Latest valid correction wins for effective presentation; the entire correction chain remains auditable.
8. Add storage-level immutability for correction rows (UPDATE/DELETE rejected).
9. Add storage-level same-item integrity where practical: correction.eyewear_item_id must match the target service event's eyewear_item_id. If MariaDB CHECK cannot enforce cross-table identity, use a BEFORE INSERT trigger plus service validation.
10. Add a dedicated mutation ACL, e.g. `sca.eyewear.service.correct`, separate from ordinary `sca.eyewear.service` recording and `sca.eyewear.view`.
11. Staff correction must use a GET confirmation/review interstitial + POST mutation. The target event must be server-resolved; never accept staff id, item id, or prior values from the client as authoritative evidence.
12. Require a nonblank correction reason, bounded length. Normalize corrected notes safely and preserve nullable semantics.
13. The correction screen must show the immutable original event and the current effective presentation so staff understands what is being corrected.
14. Use optimistic concurrency. The POST must prove the correction chain is still the one the staff reviewed. Prefer expected correction-count or latest-correction opaque/version token; re-check under lock. A concurrent correction must produce safe STALE rejection, never last-write-wins silently.
15. Transaction lock order: lock the canonical item/current-state row first, then resolve/lock the target service event/correction chain as needed. Keep consistent with other SCA correction workflows.
16. Reject a semantic no-op: if submitted effective values equal the current effective presentation, no correction row is appended.
17. Existing service recording remains unchanged and may continue after a corrected historical event.
18. Owner-facing My Collection service history must show the **effective corrected presentation**, not stale original values, while preserving privacy. It may show a simple non-sensitive “Corrected” indicator/date, but must not expose correction reason, staff identity, internal ids, or correction-chain metadata.
19. Staff item detail should show effective service history and a correction affordance to authorized staff. Staff audit view may show original + correction history/reasons/actor refs as appropriate behind staff ACL.
20. Public Passport remains unchanged: no service notes/corrections/reasons/staff data become public.
21. Transfer behavior: service history follows the item as it does today. The new current owner sees effective corrected service history; former owner loses access under existing ownership authorization.
22. Correction does NOT change `condition_grade_after` into an authentication grade or current condition projection. It remains a historical observation only.
23. No hard delete. No “undo” by deleting correction rows. Re-correction is another append.
24. No collector/public mutation route. No Caddy/DNS/edge change.
25. No SMTP/Stripe/Shopify/OAuth changes.

## Suggested schema
Prefer a table such as `sca_service_event_corrections`:
- id BIGINT
- service_event_id FK → `sca_service_events.id` RESTRICT
- eyewear_item_id FK → `sca_eyewear_items.id` RESTRICT
- corrected_service_type VARCHAR(24)
- corrected_condition_grade_after nullable VARCHAR(8)
- corrected_notes nullable TEXT
- corrected_occurred_at timestamp/date consistent with canonical event semantics
- reason bounded text/string
- actor_staff_ref nullable/soft ref
- created_at
Indexes:
- (service_event_id, id)
- (eyewear_item_id, service_event_id, id)
Immutability trigger: reject UPDATE/DELETE.
Insert integrity trigger: target event must exist and belong to eyewear_item_id.
Canonical type/grade constraints should mirror `ServiceService::TYPES/GRADES`.

Do not copy unrelated provenance/current-state data.

## Effective read rule
For each original service event:
- if no correction exists → render original values;
- if corrections exist → render the latest correction row's corrected snapshot;
- original event identity/occurrence remains canonical historical anchor.

Implement the effective read in one domain/read service and reuse it for staff + collector presentation. Avoid duplicate “latest correction” logic in controllers/views.

Queries must be bounded and avoid N+1. Service history per item is expected to be modest, but use a deterministic join/subquery/window/latest-id strategy rather than issuing one correction query per event.

## Staff UX
From item service history:
- existing “Record service” remains.
- authorized staff see “Correct” per service event.
- GET correction screen shows item opaque ref, immutable original, current effective values, prior correction count/history, and mandatory warning that original evidence will remain.
- POST submits corrected snapshot + reason + optimistic concurrency token.
- success returns to item detail with clear “correction appended” message.
- stale/no-op/not-found/cross-item failures are safe and generic; no raw SQL/internal details.

## Mandatory tests
At minimum prove:
1. Original `sca_service_events` row remains byte-identical after correction.
2. Correction appends exactly one immutable correction row.
3. UPDATE and DELETE on correction row fail at DB layer.
4. Direct cross-item correction insert fails at DB layer.
5. invalid corrected service type fails validation + DB constraint.
6. invalid corrected condition grade fails validation + DB constraint.
7. performer/actor is derived from authenticated staff; client spoof ignored.
8. correction requires dedicated ACL; ordinary service-record permission alone cannot correct.
9. GET correction interstitial is read-only and CSRF-safe POST performs mutation.
10. missing item/event and cross-item target fail closed.
11. reason required/bounded.
12. no-op correction rejected with zero new row.
13. first correction changes effective presentation while original stays unchanged.
14. second correction supersedes first for effective presentation; both correction rows remain immutable/auditable.
15. optimistic concurrency: two staff review same chain; first commits; second gets STALE and appends nothing.
16. real two-connection concurrency proof if practical: overlapping corrections cannot both silently win.
17. correction changes zero ownership/current-state/authentication/certification/QR/status/claim/grant/Shopify rows.
18. corrected condition remains observation only; authentication grade unchanged.
19. current owner My Collection sees corrected type/date/condition/notes.
20. owner view leaks no reason/staff/internal/correction ids.
21. former owner loses service history after transfer; new owner sees effective corrected history.
22. public Passport still exposes no service notes/correction/reason/staff data.
23. staff item detail uses effective values and authorized correction link.
24. staff audit view/history can distinguish original and corrections without editing them.
25. service-history reads use bounded queries/no N+1.
26. existing ordinary service-recording tests remain green.
27. existing ownership/transfer/collector/privacy/passport/auth/cert/status/Shopify suites remain green.
28. full `tests/Feature/Sca` green.
29. established 13-table provenance fingerprint procedure remains unchanged by deployment; note that service-event/correction tables are outside that historical fingerprint, so additionally record PRE/POST service-event counts and correction counts at deploy.

## Audit/deployment discipline
- NEW branch from exact production `9bc0907c486688c7acd0d22ad2ee9f5db37d93bb`.
- Expected migration 136→137.
- Do not alter existing service-event immutability.
- Do not touch Caddy/DNS/SMTP/Stripe/Shopify/OAuth.
- Do not merge/deploy.
- Push candidate + governance implementation evidence.
- STOP for ChatGPT pre-merge audit.

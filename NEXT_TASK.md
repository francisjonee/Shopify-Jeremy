# NEXT TASK

**STATUS: CP-1 (Collector Profile — Private Profile Foundation) CANDIDATE pushed, awaiting ChatGPT pre-merge audit — NOT merged / NOT deployed. Deployed baseline unchanged: prod main `f461c17`, migrations 130, Stripe DORMANT.**

Updated 2026-10-08.

## CP-1 — Private Profile Foundation — CANDIDATE awaiting ChatGPT pre-merge audit

Branch `feat/sca-collector-profile-cp1`, base `f461c17b7e0cbd5a5e5f026d5f5000870ef04752`, head **`5eddb141d175b5cbfa7e409a46f44fefd8617d98`**, migrations prod 130 → candidate **131** (one additive table; **prod still 130**). Private authenticated collector profile (behind `collector.auth`; NO public/social surface). New one-to-one SCA-owned table `sca_collector_profiles` (bio≤500 / location≤120 / private avatar_path+avatar_mime server-side-only); `display_name` stays canonical on `sca_collector_accounts` (self-edited, not duplicated); UNIQUE(collector_account_id) + immutability trigger `trg_sca_collector_profiles_bu`; FK RESTRICT. Avatar: narrow server-side allowlist (JPEG/PNG/WebP ≤5MB), server-generated filename, **private `local` disk** (never public/ or /storage), streamed ONLY via an authenticated self-resolving route (nosniff, private/no-store); replace bounds the trail + compensates on failure; remove deletes bytes. Pseudonymization extended: profile row removed ATOMICALLY in the privacy transaction (reachability dies at commit) + avatar bytes deleted post-commit; still fails closed while owning items; idempotent; provenance preserved. Derived stats (owned/certified/distinct-brands) from canonical current ownership, never stored counters; "Collector since" = account created_at. ZERO provenance from any profile/avatar action; public Passport collector-identity contract unchanged. 8 new + 4 modified files. `CollectorProfileTest` **29 passed / 116 assertions (1 skipped: GD-webp)**; full SCA gate **1050 passed / 5432**. Production untouched (prod migr 130, no `sca_collector_profiles`, provenance unchanged, Stripe DORMANT, mail=log). Evidence: `docs/SCA-COLLECTOR-PROFILE-CP1-IMPLEMENTATION.md`. **STOP — do not merge/deploy/activate Stripe/start CP-2 until ChatGPT audits head `5eddb141`.**

---

## Promotion brief (CP-1) — as issued

## Objective

Implement the first slice of the Collector Profile initiative: a **private, authenticated collector profile** that lets the signed-in collector maintain presentation information and see truthful derived collection statistics. This is NOT a public/social profile slice.

The existing provenance/ownership system, public Passport, My Collection detail, Shopify, external-paid-auth, payment, certification, transfer, registry-status and staff workflows are authoritative and must not be redesigned.

## Audited baseline / existing facts

- Canonical collector identity is `sca_collector_accounts`: internal id, opaque `public_ref`, email, password, optional `display_name`, lifecycle status, timestamps.
- `display_name` already exists and is registration/account identity data. CP-1 may provide a self-edit UI for that existing field, but MUST NOT create a duplicate display-name source.
- Collector auth is the independent `collector` guard. Staff auth does not satisfy it.
- Current account page shows display name/email and account/security/privacy actions.
- My Collection already derives current ownership server-side and already exposes owner-safe item/gallery/auth/certification/document/history DTOs.
- Existing collector item images are streamed through authenticated owner-authorized routes; raw storage paths are never emitted and `/storage` is not a public content contract.
- Existing pseudonymization irreversibly removes email/display_name/password/verification while retaining only minimum referential identity/provenance. CP-1 profile PII and avatar MUST participate in that privacy lifecycle.
- Public Passport deliberately exposes no collector identity. Keep that invariant.

## Architecture decision

Add a **one-to-one SCA-owned presentation table** `sca_collector_profiles`, keyed/bound to `collector_account_id` with DB uniqueness and restrictive FK semantics. Keep authentication identity in `sca_collector_accounts`.

CP-1 profile fields:
- `collector_account_id` — server/session derived, UNIQUE, immutable.
- `bio` — nullable short text, max 500 characters.
- `location` — nullable coarse free-text location, max 120 characters. Do NOT collect street address, coordinates, phone, DOB, gender, social accounts, or other unnecessary PII.
- `avatar_path` / `avatar_mime` only if needed for the chosen private storage implementation. Never expose either to HTML/DTO/API.
- timestamps.

Do NOT add a public handle, public-profile flag, per-item visibility, follower/like/comment/message fields, public URL, social graph, favorites, custom collections, marketplace fields, valuation fields, or analytics tables in CP-1.

## Required behavior

1. **Private profile page/edit**
   - Behind `collector.auth`.
   - Target identity always comes from the authenticated collector session; no collector id/ref/email supplied by the request may retarget the write.
   - Show/edit the existing canonical `display_name` plus profile `bio` and `location`.
   - Email may be displayed read-only as account identity; CP-1 does NOT implement email change.
   - Normalize whitespace sensibly; validate lengths server-side.
   - Empty bio/location should persist as NULL rather than meaningless empty strings.
   - Update must be transactional and mutate only allowed profile/display-name fields.

2. **Avatar**
   - Optional. Accept only a narrow image allowlist (JPEG/PNG/WebP) using server-side validation; reject SVG and arbitrary files.
   - Set a conservative size limit (<= 5 MB).
   - Generate the stored filename server-side; never trust the upload filename/path.
   - The avatar must NOT be reachable through a raw user-controlled storage URL. Serve it only through a collector-authenticated route that resolves the current session collector server-side.
   - Response must use the stored/validated MIME, `X-Content-Type-Options: nosniff`, and privacy-appropriate cache headers.
   - Replacing an avatar must not leave an unbounded trail of old files. Deleting/removing avatar is required.
   - DB/file failure handling must not leave the profile pointing at a missing/new partial file. Design the smallest robust compensation/ordering and prove it with tests.

3. **Derived collection statistics**
   On the private profile/account experience show a small truthful summary derived from canonical current ownership, not counters stored on the profile:
   - total currently owned registered frames;
   - currently certified count;
   - distinct known brands count.
   Unknown/null brands must not become a fake brand. Previous-owner items must disappear automatically after transfer. Do not count submissions as owned frames before canonical claim/ownership.

4. **Collector since**
   - May display the existing collector account `created_at` as “Collector since …”.
   - Do not introduce another join-date field.

5. **Privacy / pseudonymization**
   - Extend the existing `CollectorPrivacyService` transaction so an eligible collector's profile row is removed as part of pseudonymization.
   - Avatar bytes must be removed or made irretrievable as part of successful anonymization. Because filesystem deletion is not transactionally rollbackable, choose a fail-closed/compensating ordering that does not allow DB pseudonymization to commit while identifiable profile/avatar remains reachable.
   - Existing rule remains: pseudonymization fails closed while collector currently owns items.
   - Pseudonymization must still preserve provenance exactly and remain idempotent.
   - A pseudonymized/disabled account must never reach profile routes.

6. **No public exposure**
   - No new unauthenticated collector-profile route.
   - Public Passport output must remain byte/field-contract compatible with respect to collector identity: no display name, bio, location, avatar, email, COL ref, internal id.
   - Do not make ownership publicly discoverable.
   - Do not change robots/public indexing behavior as part of CP-1.

7. **UI**
   - Improve the collector account/profile experience coherently rather than bolting fields onto the danger-zone card.
   - Keep Account Security and Danger Zone clearly separated.
   - Add a visible route/link to My Collection and authentication submissions as today.
   - Profile should work on mobile and desktop within the existing standalone SCA collector chrome.
   - CP-1 may widen the private profile page if needed, but do not redesign unrelated collector item-detail pages.

## Data / provenance invariants

CP-1 must create ZERO:
- eyewear items,
- authentications,
- certifications,
- QR identities/lifecycle,
- claims/grants,
- ownership/transfer events,
- registry/status events,
- service events,
- Shopify sale links,
- authentication submissions/payments/returns.

Editing profile or avatar must never change current ownership, certification, Passport resolution, claimability, transfer eligibility, or external-auth workflow state.

## Migration requirements

- Additive migration only from prod level 130.
- New table only unless an audited necessity is discovered; do not alter provenance tables.
- UNIQUE one profile per collector.
- FK to collector account with conservative delete behavior consistent with existing no-hard-delete identity model.
- If DB-level immutability protection for `collector_account_id` is consistent with existing SCA patterns, add it.
- Do not deploy/migrate production during implementation. Candidate only.

## Tests required

Create a focused CP-1 feature suite on `sca_domain_test` with a hard DB-name guard. At minimum prove:

- unauthenticated profile GET/POST/avatar routes rejected;
- staff session does not satisfy collector auth;
- collector sees only own profile;
- request cannot retarget another collector by id/ref/email;
- create/update display_name + bio + location;
- validation boundaries and normalization;
- empty optional values -> NULL;
- email cannot be changed through profile payload;
- avatar valid JPEG/PNG/WebP accepted; SVG/non-image/oversize rejected;
- avatar filename/path is server-generated and never rendered/exposed;
- avatar stream is session-self-only and nosniff/privacy-safe;
- replace/remove avatar cleanup semantics;
- profile edit creates zero provenance/domain mutations;
- stats derive from canonical current ownership;
- certified count is canonical;
- distinct brands correct;
- transfer causes prior owner's stats to drop and recipient's to rise;
- unclaimed external-auth submission does not count;
- collector-since derives from account created_at;
- public Passport contains none of profile/collector PII and remains public as before;
- pseudonymization removes profile data/avatar access and preserves provenance;
- pseudonymization failure while still owning items leaves account/profile/avatar intact;
- pseudonymized/disabled collectors cannot access profile;
- concurrency/replay behavior is safe enough for profile create/update and avatar replace.

Run focused tests and the full `tests/Feature/Sca/` regression gate. Report exact pass/assertion counts.

## Boundaries / forbidden scope

- NO public collector profile yet.
- NO public handle/username.
- NO public collection/per-item visibility.
- NO social features.
- NO marketplace/resale.
- NO valuation.
- NO Stripe activation/test-mode runtime.
- NO SMTP activation.
- NO Shopify changes.
- NO Krayin core/vendor edits.
- NO production deployment.
- NO weakening of public Passport privacy.
- NO direct provenance-table mutation from profile code.

## Deliverables / handoff

Implement on a dedicated branch from exact deployed baseline `f461c17b7e0cbd5a5e5f026d5f5000870ef04752`.

Commit:
- implementation;
- migration;
- focused tests;
- `docs/SCA-COLLECTOR-PROFILE-CP1-IMPLEMENTATION.md` containing schema, routes, privacy/storage decisions, exact changed files, focused/full test results, migration count, and explicit confirmation that Stripe remains dormant and production was untouched.

Update this governance `NEXT_TASK.md` with candidate branch/head SHA, exact base SHA, migration delta, test counts, findings/deferrals, and **STOP for ChatGPT pre-merge audit**.

Do not merge or deploy. Do not start CP-2.

---

## Previous authoritative state

# NEXT TASK

**STATUS: Slices 1–6 CODE DEPLOYED + payment concurrency hardening + Stripe webhook amount/currency hardening (R1) DEPLOYED; Stripe DORMANT; Stripe Test Mode real-provider dry-run pending. External Paid Authentication Intake product slices are CODE-COMPLETE, pending provider testing/activation and final launch validation. STOP for ChatGPT deployment audit of Slice 6.**

Updated 2026-10-08.

## Current deployed baseline (authoritative — single source of truth)

- Deployed implementation `main` = **`f461c17b7e0cbd5a5e5f026d5f5000870ef04752`** (impl repo `francisjonee/francisjonee-sca-platform-private`) — Slice 6 (Exceptions & Returns) merged `--no-ff` + deployed; deployed tree file-identical to audited candidate `5ee1067217a8c2fd8bea96bf3a7062db33856438` (base `7ff176c`). Prior deployed: Stripe R1 `7ff176c`.
- Governance/evidence repo = `francisjonee/Shopify-Jeremy`.
- Prod migrations **130** (129→130: one additive operational table `sca_authentication_returns`, **0 rows**). Provenance DATA byte-identical pre/post (self-consistent deploy FP `35e06328…`; items 3/qr 3/certs 4/auth 4/ownership 5/claims 2/grants 1/sale 1/status 7 — unchanged). Submission/payment/return tables are empty operational tables.
- Public edge LIVE `https://verify.secondchanceauthenticators.com`; `:8080` loopback-only; `SESSION_SECURE_COOKIE=true`; `MAIL_MAILER=log`; `STRIPE_*`/`SHOPIFY_API_SECRET`/provider creds UNSET.

## Slice 6 — Exceptions & Returns — DEPLOYED

`f461c17`, migr 129→130 (table `sca_authentication_returns`). Operational physical-return lifecycle for a frame leaving SCA custody for ANY outcome (failed/inconclusive OR certified): dedicated record with its OWN advance-only machine `return_pending → return_in_transit → returned` (submission stays `received`; submission status machine + CHECK untouched; no registry status overloaded). `ReturnService` sole writer (prepare/markShipped/markReturned; idempotent; fail-closed); eligibility = custody + canonical safe-return point (finalized failed/inconclusive OR certified; passed-not-certified NOT eligible), NEVER ownership/claim. Bound item derived server-side; binding + advance-only enforced at DB (UNIQUE submission_id + eyewear_item_id, immutability + advance-only trigger `trg_sca_auth_returns_bu`). ZERO new provenance; **claim grant never consumed** (collector can still claim before/during/after). Dedicated ACL `sca.eyewear.submission.return`; staff Prepare/Ship/Complete POST on the submission detail; collector safe return card (state/carrier/tracking/dates only — no internal ids/notes); Slice-5 result+claim intact. `SubmissionReturnTest` **36**; full SCA gate **1021 passed / 5306**. Prod data byte-identical, returns table 0 rows, Stripe DORMANT (edge 404 + app unset). Evidence: `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE6-{IMPLEMENTATION,DEPLOY-RESULT}.md`. Deploy-gate note: first attempt aborted on the known `QrReissueTest::rg8` timing flake (set -e aborts before migrate → prod untouched); re-run cleared it. **STOP for ChatGPT deployment audit of `f461c17`.**

### Prior deployed baseline (superseded by Slice 6 `f461c17`)
- `7ff176c4b36d0eba805e296d83326f6d0f998fc1` — Stripe webhook amount/currency hardening (R1), migr 129, provenance-DATA FP `84e6339…`. Prior to that: Slice 5 `8c73e83`.

## External Paid Authentication Intake — slice status

Deployed: **Slice 1** (`6588054`, migr 122→124 — submission domain) · **Slice 2** (`c72530e`, migr 124→125 — staff worklist + custody bridge) · **Slice 3** (`1cf070d`, no migration — collector submission UX + status tracking) · **Slice 4** (`2aedebb`, migr 125→128 — Stripe Checkout CODE, **DORMANT**). Slice 4: SDK-free Stripe-hosted Checkout (Guzzle REST session + Stripe's documented signature verification); 3 tables `sca_settings` (DB-backed $49 fee, configurable) / `sca_authentication_payments` (amount+currency snapshot, status machine) / `sca_stripe_webhook_receipts` (event-id idempotency); collector `submission.pay/return/cancel`; public signed `POST /sca/stripe/webhook`; webhook-driven confirmation advances only `submitted→awaiting_item` (never downgrades), refund preserves history, payment creates ZERO provenance; staff payment summary + manual advance = audited OVERRIDE. **DORMANT: fail-closed at the app (400 w/o secret) AND the edge (external webhook 404, not admitted).** Evidence: `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE{1,2,3,4}-{IMPLEMENTATION,DEPLOY-RESULT}.md`, `docs/SCA-EXTERNAL-PAID-AUTHENTICATION-INTAKE-DISCOVERY.md`. **Capability NOT closed.**

**Slice 5 — DEPLOYED** (`8c73e83`, no migration, stays 129): result + ownership wiring. Collector result derived from the bound item's canonical provenance (states awaiting_examination/not_passed/passed_not_certified/certified_pending_grant/claimable/registered_to_you/unavailable; safe fields only; adverse status gated by canonical `StatusService::ADVERSE_STATUSES`); submission-bound `POST /collector/submissions/{SUB-ref}/claim` resolves item+issued-grant server-side and invokes the canonical `ClaimWorkflow::claimByGrant` (ownership created only by canonical claim completion; no token in request; owner-scoped 404); staff `POST /sca/submission/{id}/grant` delegates to the existing `ExternalClaimGrantService` (gated by existing `sca.eyewear.claim`). Existing bearer-grant + Shopify claim flows untouched; zero parallel provenance. Evidence: `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE5-{IMPLEMENTATION,DEPLOY-RESULT}.md`. Full SCA gate **978 passed**. Stripe stays DORMANT.

**Payment concurrency hardening — DEPLOYED** (`5b30120`, migr 128→129): `active_pending` UNIQUE guard = one pending payment per submission (migration **fails closed** on legacy duplicate-pending + **backfills** existing pending rows before the unique becomes authoritative); `/pay` serialized under a submission row lock; webhook event-id INSERT idempotency gate (concurrent duplicate = clean 200, not a retryable 500). Provenance DATA byte-identical; Stripe stays DORMANT (edge 404 + app 400 w/o secret). Evidence: `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE4-CONCURRENCY-HARDENING-{IMPLEMENTATION,DEPLOY-RESULT}.md`. Full SCA gate **959 passed**.

## Stripe Test Mode — Phase 2 — isolated-runtime DESIGN + R1 hardening CANDIDATE (awaiting audit)

Updated 2026-10-08. **Part 1 (design, not launched):** isolated Test-Mode runtime = a separate PHP process in the `app` container on **`127.0.0.1:8099`** with `DB_DATABASE=sca_domain_test` + ephemeral test Stripe env, fed by the operator's Stripe CLI `stripe listen --forward-to http://127.0.0.1:8099/sca/stripe/webhook`; fail-closed DB preflight (abort unless `DB::connection()->getDatabaseName()==='sca_domain_test'`); never exposed via Caddy; prod `:8080`/`sca_krayin` untouched. **Part 2 (R1 CANDIDATE, NOT merged/deployed):** branch `feat/sca-stripe-webhook-amount-hardening`, base `8c73e83`, head `c0c92816bd5fe376c77ecdc544c88a32a901879a`, **no migration (stays 129)** — webhook verifies Stripe `amount_total`==snapshot `amount_cents` + `currency` (lowercase-normalized) before `succeeded`; missing/mismatch → fail closed (not succeeded, no advance), acknowledged 200 (no retry storm); idempotency/concurrency/refunds unchanged. StripePaymentTest **26**; full SCA gate **985 passed / 5221**. **R1 DEPLOYED** (`7ff176c`, no migration, file-identical to candidate `c0c92816`; evidence `docs/SCA-STRIPE-TEST-MODE-R1-HARDENING-DEPLOY-RESULT.md`). Part-1 isolated runtime remains DESIGN-only (not launched). **NEXT SEPARATE GATE = the real Stripe Test-Mode dry-run** (operator provisions `sk_test_`/`whsec_`, launch `:8099` test runtime + Stripe CLI forwarder) — unpromoted; do not start without explicit promotion + credentials. No credentials present/entered; production UNCHANGED + Stripe DORMANT.

## Stripe Test Mode — Phase 1 (PREPARATION) — inspection done; BLOCKED/STOP for provisioning

Promoted 2026-10-08 for preparation + controlled testing ONLY (no production activation without separate audit). Phase A (read-only inspection) complete; deployed Stripe code is fully exercised by the in-process harness (StripePaymentTest 19 + PaymentGuardMigrationTest 2, faked Stripe + test secret, in `sca_domain_test`). **Phase B BLOCKED / STOP:** no `sk_test_`/`whsec_` test credentials present anywhere (operator must supply securely), and no webhook-reachable isolated environment without a **prohibited** production Caddy change. Safest alternative (operator-gated): operator sets test `STRIPE_ENABLED=true`+`STRIPE_SECRET`+`STRIPE_WEBHOOK_SECRET` in `app/.env` + runs a **Stripe CLI `stripe listen --forward-to http://127.0.0.1:8080/sca/stripe/webhook`** dry-run (no Caddy/DNS change), then reverts. Production UNCHANGED + Stripe DORMANT (`8c73e83`, migr 129, `STRIPE_*` absent, webhook edge 404). Risk R1 noted: consider webhook amount/currency snapshot-match as defense-in-depth. Evidence: `docs/SCA-STRIPE-TEST-MODE-PHASE1-PREPARATION.md`. **STOP for ChatGPT audit + operator provisioning before any activation.**

## Open items (NOT promoted — promote exactly ONE at a time; Claude never starts autonomously)

- **STRIPE ACTIVATION gate (operator-led):** confirm Stripe account/merchant eligibility; set `STRIPE_ENABLED=true` + `STRIPE_SECRET` + `STRIPE_WEBHOOK_SECRET` in `app/.env` (operator enters secrets on the server); register the Stripe dashboard webhook; add Caddy `@`-matcher admission for `POST /sca/stripe/webhook` (mirroring the Shopify webhook edge) + recreate `caddy`; test-mode dry-run first. Do NOT perform without explicit promotion + Jeremy's go.
- **Slice 5** — result/ownership wiring (authentication outcome → on certify, offer/issue the grant to the submitting collector via the existing grant→claim path; result surfaced to the collector).
- **Slice 6** — exceptions/returns (cancel, not-received, wrong-item, counterfeit outcome, disputes, return/lost shipment).
- **Transactional Email / SMTP** — OPEN but PARKED/operator-gated (pre-activation hardening deployed; see `docs/SCA-TRANSACTIONAL-EMAIL-HARDENING-DEPLOY-RESULT.md`). Do not touch without promotion.
- Backlog (`TASK_QUEUE.md`): off-site backup (external) · post-core expansion.

## Most recently CLOSED (do NOT reopen / do NOT start a follow-on without promotion)

- **SCA Shopify Sale / Claim Staff Visibility — CLOSED** (`e4306e99`; read-only; migrations unchanged at the time).
- **SCA Inventory Onboarding / Bulk CSV — CLOSED** (`9760889`).
- **SCA Service / Repair History Staff UX — CLOSED** (zero-code).
- **Shopify Operational Listing SOP — CLOSED** (`1b029fd`).
- **SCA Staff Operational Dashboard / Worklists — CLOSED** (`0f86b4a`).
- **SCA Staff Navigation / Discoverability — CLOSED** (`703fbde`).
- **Production QR/Label Workflow — CLOSED** (`0ca7158`/`4d92ec9`/`30b680f`).
- **SCA Transactional Email pre-activation hardening — DEPLOYED** (`0815ea0`; SMTP activation itself still parked).
- **SCA Shopify Activation — CLOSED** (Phases 0–5).

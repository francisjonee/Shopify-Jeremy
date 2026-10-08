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

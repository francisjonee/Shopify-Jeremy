# NEXT TASK

**STATUS: ACTIVE — SCA SHOPIFY ACTIVATION / PHASE 4 CONTROLLED DEV-STORE DRY-RUN.**

Promoted 2026-10-06 by ChatGPT/operator. This task continues the already-built Shopify integration. **Do not create another Shopify app and do not rebuild the integration.** The operator has confirmed the existing Shopify Dev app **SCA Eyewear Registry** and released version **`sca-shopify-activation-v2`**. The connected Shopify store domain is **`second-chance-eyewear-accessories.myshopify.com`**. Phases 0–3 are complete; Gate C passed and the three required webhooks are live on the existing app. **Only Phase 4 below is now executable. Do not repeat Phases 0–3 and do not begin Phase 5.**

## Objective

Activate the existing deployed SCA Shopify integration against the existing Shopify app/store, using the smallest governed sequence. Configure → verify configured/not-connected → OAuth connect → verify encrypted connection → register/verify required webhooks → controlled dev-store dry-run. Stop immediately on any invariant mismatch.

## Known state / facts to preserve

- Implementation repo: **`francisjonee/francisjonee-sca-platform-private`**.
- Governance repo: **`francisjonee/Shopify-Jeremy`**.
- Existing integration package/routes already deployed; this is **activation, not a software build**.
- Existing Shopify app: **SCA Eyewear Registry**. Do not create a replacement app.
- Existing released Shopify version: **`sca-shopify-activation-v2`**.
- Shopify store domain: **`second-chance-eyewear-accessories.myshopify.com`**.
- Approved scope: **`read_orders` only**. Do not re-add `read_products`.
- API version: **`2026-07`**. Do not bump merely for newness.
- OAuth callback already configured in Shopify as:
  `https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback`
- Edge activation is already complete:
  - permanent exact `POST /sca/shopify/webhook`
  - temporary exact `GET /sca/shopify/oauth/callback`
  - no `/sca/*` wildcard.
- Edge pre-activation proof: unsigned webhook reached Laravel and failed closed 401; invalid callback failed 400; wrong methods/broader `/sca/*` stayed 404.
- Required webhook topics: **`orders/paid`**, **`orders/cancelled`**, **`refunds/create`**.
- Mapping property: **`sca_item_ref`** containing SCA `public_ref`; do not use SKU as identity.
- Pilot policy: SCA Shopify listings are one-of-one, **quantity 1**. Never put `sca_item_ref` on a multi-quantity line during this pilot.
- Refund policy under test: amount-only partial refund with no SCA `refund_line_items` must be a no-op; a returned SCA line revokes eligibility and, after claim, disputes while preserving ownership.
- Existing real provenance/pilot items must not be used for the Shopify dry-run. Use one new dedicated test item/dev-store transaction only.

## Secret-handling hard rule

**Never write, paste, echo, print, commit, log, or copy any Client Secret, webhook secret, OAuth access token, or other credential into this file, Git, task reports, shell history, command output, screenshots, or chat.**

The operator must enter secret values interactively/directly on the server when required. Claude may tell the operator exactly which secret to enter and where, then STOP and wait for the operator. Do not ask the operator to send the secret in chat. Do not use commands that echo secret values back to stdout. Reports may record only whether a secret is SET/UNSET and, if useful, a non-reversible short fingerprint — never the value.

## Phase 0 — re-audit before mutation

Before changing anything:

1. Verify current production/deployed HEAD, origin/main, clean tree, container health, migration count, and existing provenance fingerprint/counts using the established SCA governance procedure.
2. Inspect the deployed Shopify config/routes/services and confirm the exact env keys currently consumed by code. Expected from the prior audit:
   - `SHOPIFY_SHOP_DOMAIN`
   - `SHOPIFY_CLIENT_ID`
   - `SHOPIFY_CLIENT_SECRET`
   - `SHOPIFY_WEBHOOK_SECRET`
   - `SHOPIFY_SCOPES`
   - `SHOPIFY_API_VERSION`
   - `SHOPIFY_LINE_ITEM_REF_PROPERTY`
   - `SHOPIFY_OAUTH_REDIRECT_URI`
   If deployed code differs, **STOP and report; do not guess or add aliases**.
3. Confirm Shopify connection/event tables are still in the expected pre-activation state before mutation. Record counts only, no sensitive payloads.
4. Confirm the exact edge behavior remains as designed and no broad `/sca/*` exposure exists.
5. Confirm no new app/code/schema work is required for activation. If code changes appear necessary, **STOP** and return for review rather than implementing them inside this activation task.

## Phase 1 — safe server configuration

Back up the production `.env` using the established secure server procedure; the backup must remain server-local and must not enter Git.

Set/verify the non-secret values to the deployed code's expected keys:

- `SHOPIFY_SHOP_DOMAIN=second-chance-authenticators.myshopify.com`
- `SHOPIFY_SCOPES=read_orders`
- `SHOPIFY_API_VERSION=2026-07`
- `SHOPIFY_LINE_ITEM_REF_PROPERTY=sca_item_ref`
- `SHOPIFY_OAUTH_REDIRECT_URI=https://verify.secondchanceauthenticators.com/sca/shopify/oauth/callback`

For `SHOPIFY_CLIENT_ID`, `SHOPIFY_CLIENT_SECRET`, and `SHOPIFY_WEBHOOK_SECRET`, do **not** invent or recover values from Git. If they are not already securely present, STOP and instruct the operator to enter the correct values directly on the server. The operator may obtain Client ID/Client Secret from the existing Shopify Dev app. Determine from the deployed integration/Shopify app architecture what value is actually required for `SHOPIFY_WEBHOOK_SECRET`; do not assume Client Secret and webhook secret are interchangeable unless the existing implementation and Shopify configuration explicitly establish that.

After configuration, clear/rebuild Laravel config/cache using the deployment's established safe commands. Do not recreate unrelated services.

### Gate A

Prove, without exposing secrets:
- all required config fields resolve as SET with the exact non-secret values above;
- Shopify diagnostics reports **configured but not connected** (or the exact equivalent state in deployed code);
- connection/token table remains unconnected before OAuth;
- provenance fingerprint/counts and migrations are unchanged;
- public passport, Collector, SCA-038, `/storage`, admin edge policy, Phase-B/`:8080`, and smsrocket co-tenant remain healthy.

If Gate A fails, rollback `.env` from the backup, clear config safely, verify baseline restoration, and STOP.

## Phase 2 — OAuth connect existing app

Use the **existing SCA OAuth install flow**, not Shopify's generic Install App button if that bypasses the application's state/HMAC transaction. Initiate through the existing staff/admin connect route under the staff-IP protected admin surface.

Before initiating, inspect route/controller behavior and state handling so the exact deployed flow is followed. The callback must be the already-approved URL above and the expected shop must be `second-chance-authenticators.myshopify.com`.

Complete OAuth once. Verify:
- callback succeeds through the temporary edge handle;
- OAuth state is single-use and HMAC verification remains enforced;
- exactly the expected shop connection is stored;
- access token is encrypted at rest / not exposed in output;
- granted scope is `read_orders` and no unexpected scope appears;
- diagnostics becomes **connected**;
- no provenance/ownership/certification/QR mutation occurred merely from connecting Shopify.

Do not print the access token or decrypt it for evidence.

### Gate B

Record non-secret connection evidence (shop domain, connected status, timestamps/IDs only where safe, granted scopes) and re-run baseline health/invariant checks. Any unexpected shop/scope/token handling or domain mutation = STOP.

## Phase 3 — webhook registration / verification

Determine whether the existing integration registers webhooks automatically after OAuth or requires a supported explicit registration step. Use the existing implementation; do not add a parallel registration mechanism unless a missing capability is proven, in which case STOP for review.

Required topics only:
- `orders/paid`
- `orders/cancelled`
- `refunds/create`

Destination must be exactly:
`https://verify.secondchanceauthenticators.com/sca/shopify/webhook`

Verify registration against Shopify and, where available, SCA diagnostics. Do not weaken HMAC verification to make tests pass. An unsigned/forged request must continue to fail closed.

### Gate C

Prove all three required topics are registered exactly as intended, no unnecessary topic was added, webhook endpoint still rejects forged/unsigned payloads, and existing SCA/public/co-tenant invariants remain healthy.

## Phase 4 — controlled dev-store dry-run

**Authorization:** GO granted by operator/ChatGPT on 2026-10-06 after Gate C PASS. This is the only executable phase. Use one new dedicated test item/order only. Never touch existing real provenance/pilot items.

### Phase 4A — pre-mutation gate

1. Pull latest governance and deployed implementation state. Confirm Gate C evidence remains true: existing app connected, scope exactly `read_orders`, exactly the three live webhook topics, receiver fail-closed, migrations 120, and co-tenant healthy.
2. Record BEFORE counts/fingerprint for all provenance tables and separately identify all pre-existing item IDs/public_refs so later proof can show they were untouched.
3. Inspect the deployed paid/cancel/refund handlers and `ClaimWorkflow::claim` before mutation. Confirm the exact expected transitions for the test. If the deployed code cannot support the test without code/schema changes, STOP.
4. Create/identify **one new SCA test item only**, unmistakably labeled test data. Do not reuse any existing item. Record its safe internal/public reference in the report. Do not authenticate/certify/claim it beyond what the existing workflow requires for this test.
5. Prepare one dedicated Shopify test product/variant/order path with quantity **1** and line-item property exactly `sca_item_ref=<test public_ref>`. Do not place the property on any other item.

If Shopify UI/operator action is required to create/pay/refund/cancel the order, STOP at that point and give the operator exact minimal UI steps. Do not ask for or expose customer PII or secrets.

### Gate D1 — paid order + idempotency

After the operator pays the dedicated test order:
- prove a real Shopify `orders/paid` delivery was HMAC-accepted;
- record webhook ID/topic/shop/order references only as safe non-PII identifiers;
- prove exactly one receipt and exactly one expected sale-link/eligibility effect for the test item;
- prove mapping occurred by `sca_item_ref`, not SKU;
- prove no pre-existing item changed;
- prove no customer PII was persisted and `shopify_customer_ref` remains null as designed;
- exercise the existing idempotency path safely (prefer replay of the already-recorded delivery only if the implementation has a sanctioned test/replay mechanism that does not fabricate a new Shopify event). A duplicate webhook ID must not duplicate receipts, sale links, eligibility, ownership, or other effects. If safe replay requires secret handling, payload fabrication, or code change, STOP and report rather than improvising.

### Gate D2 — claim through canonical workflow

Use the existing collector/claim path and **`ClaimWorkflow::claim` only**. If human browser action is required, STOP and give the operator the exact steps.

Prove:
- claim completes for the dedicated test item through the canonical workflow;
- ownership is appended exactly once;
- current-state projection resolves to the test collector;
- Shopify sale-link/claim entitlement is retained as designed;
- no parallel/direct owner mutation occurred;
- duplicate/repeated claim cannot create duplicate ownership.

### Gate R2 — mandatory amount-only partial-refund empirical test

This gate is mandatory and must occur **before any returned-line/full refund test**.

Ask the operator to issue a small **amount-only partial refund while keeping the eyewear item**. Do not select/return/refund the SCA line item quantity. After Shopify delivers `refunds/create`:
- inspect the stored/received payload only to the minimum needed and redact/omit customer PII from all evidence;
- prove the SCA item is **absent from `refund_line_items`**;
- expected SCA result: sale eligibility remains valid, ownership remains, registry does **not** become `disputed`, and no adverse status/ownership event is appended;
- prove receipt idempotency and no duplicate effects;
- prove all pre-existing items remain byte/logically unchanged by the test.

**HARD STOP on contradiction:** if Shopify includes the SCA line in `refund_line_items`, eligibility is revoked, registry becomes disputed, ownership changes, or any unexpected mutation occurs, STOP immediately. Do not patch code or continue to a full return.

### Gate R3 — returned/full SCA-line behavior (conditional)

Proceed only after Gate R2 PASS and only if Shopify provides a safe, explicit operator flow using this same dedicated test order/item. Ask the operator before performing the return/refund action.

Expected behavior when the SCA line itself is returned/refunded:
- eligibility is revoked according to the existing handler;
- because the item has already been claimed, registry becomes `disputed` through append-only status/event semantics;
- ownership history is preserved and current ownership is **not erased**;
- duplicate delivery remains idempotent.

If proving this requires new code, schema, fabricated payloads, touching a real item, or another irreversible setup outside this dedicated test fixture, STOP and document it as deferred rather than expanding scope.

### Gate D4 — closeout and contamination check

After the last authorized test action:
- compare BEFORE/AFTER fingerprints/counts and isolate every delta to the dedicated test item/order/receipts/sale-link/claim/status events;
- prove every pre-existing provenance/pilot item is unchanged;
- prove no customer PII was persisted by the Shopify integration;
- verify connection still healthy, granted scope exactly `read_orders`, three webhook subscriptions unchanged, unsigned/forged receiver still fails closed;
- verify public passport/Collector/admin edge/storage/SCA-038/retired :8080 and smsrocket co-tenant remain healthy;
- do not delete provenance history merely to make counts look clean. Test records may remain clearly marked test data unless the existing architecture has a governed non-destructive test-data disposition mechanism.

Write evidence to `docs/SCA-SHOPIFY-ACTIVATION-PHASE4-DRYRUN.md`. Record no secrets, access tokens, HMAC values, callback code/state, or customer PII.

**STOP after Gate D4. Phase 5 is not authorized.**

## Phase 5 — post-activation hardening / edge cleanup decision

After successful OAuth and webhook verification, the OAuth callback edge handle was designed as **temporary**. Do not silently remove it inside an unrelated step. First determine from the deployed reconnect/rotation model whether keeping it is required for future reauthorization. Report the recommendation and exact consequence.

If the previously approved edge design explicitly authorizes removal immediately after successful install and no reconnect path needs public callback availability, remove **only** the exact `GET /sca/shopify/oauth/callback` handle using the same governed Caddy validation/recreate procedure, then prove callback becomes 404 while permanent POST webhook remains reachable/fail-closed. Otherwise leave it and state why.

Never remove the permanent exact webhook handle. Never broaden to `/sca/*`.

## Forbidden scope

Do **not**:
- create another Shopify app or version unless a proven configuration defect requires a reviewed Shopify-side version change;
- build product sync, outbound write-back, SMTP, unmatched-event UI, or multi-quantity support;
- change Passport resolver/presenter/status semantics, QR identity, certification, ownership workflows, ACLs, schema/migrations, CSP, public allowlist, Phase-B networking, DNS, or unrelated Caddy routes;
- touch existing real pilot/provenance items for Shopify testing;
- commit `.env`, credentials, tokens, webhook payload PII, or server backups;
- merge/deploy new application code as part of this activation task. If code must change, STOP and submit a separate candidate/task.

## Required final report / STOP conditions

At each gate, write concise governance evidence under `docs/` and update memory/index according to the established SCA procedure, but never include secrets or PII.

Final report must state:
- deployed/app git identity and whether app code changed (expected: no);
- Shopify app/version/store used;
- config SET/UNSET status without values for secrets;
- OAuth result + granted scope;
- encrypted connection evidence;
- webhook topic registrations;
- dry-run event/eligibility/claim/idempotency results;
- GATE-R2 actual partial-refund payload shape and resulting SCA state;
- full-line return result if performed;
- BEFORE/AFTER provenance fingerprints/counts distinguishing the dedicated test item from pre-existing pilot records;
- edge callback retained/removed and why;
- regressions/health checks;
- rollback actions if any.

**HALT immediately** on wrong shop, unexpected scope, secret exposure, HMAC weakness, unexpected mutation of an existing item, failed idempotency, partial-refund behavior contradicting GATE-R2, need for unreviewed code/schema change, or any regression in SCA-038/privacy/ACL/edge/co-tenant behavior.

**Do not merge/deploy application code. Do not create a new Shopify app. Proceed gate-by-gate and stop for operator input whenever a secret or Shopify UI action is required.**
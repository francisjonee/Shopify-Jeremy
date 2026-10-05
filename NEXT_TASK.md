# NEXT TASK

**STATUS: ACTIVE — SCA SHOPIFY ACTIVATION / EXISTING APP CONNECTION.**

Promoted 2026-10-06 by ChatGPT/operator. This task continues the already-built Shopify integration. **Do not create another Shopify app and do not rebuild the integration.** The operator has confirmed the existing Shopify Dev app **SCA Eyewear Registry** and released version **`sca-shopify-activation-v2`**. The permanent Shopify store domain is **`second-chance-authenticators.myshopify.com`**.

## Objective

Activate the existing deployed SCA Shopify integration against the existing Shopify app/store, using the smallest governed sequence. Configure → verify configured/not-connected → OAuth connect → verify encrypted connection → register/verify required webhooks → controlled dev-store dry-run. Stop immediately on any invariant mismatch.

## Known state / facts to preserve

- Implementation repo: **`francisjonee/francisjonee-sca-platform-private`**.
- Governance repo: **`francisjonee/Shopify-Jeremy`**.
- Existing integration package/routes already deployed; this is **activation, not a software build**.
- Existing Shopify app: **SCA Eyewear Registry**. Do not create a replacement app.
- Existing released Shopify version: **`sca-shopify-activation-v2`**.
- Shopify store domain: **`second-chance-authenticators.myshopify.com`**.
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

This is the first allowed domain mutation in this task and must use **one new dedicated Shopify/SCA test item**, never the existing provenance pilot items.

Before the test, record a fresh baseline and identify the dedicated test item clearly as test data. The Shopify line item must be quantity **1** and carry:
`sca_item_ref=<that test item's public_ref>`

Run the minimum end-to-end sequence needed to prove:

1. `orders/paid` is HMAC-accepted and idempotently received.
2. The event maps by `sca_item_ref` to the intended dedicated SCA item and creates/updates only the expected sale-link/eligibility records.
3. Buyer claim uses the **existing `ClaimWorkflow::claim`** path — no parallel ownership mechanism.
4. Re-delivery/duplicate webhook ID is idempotent and does not duplicate ownership/effects.
5. **GATE-R2 empirical refund test:** perform an amount-only partial refund that keeps the item. Inspect the actual Shopify webhook payload/receipt safely (no customer PII in report) and prove the SCA line is absent from `refund_line_items`; expected SCA result = **no eligibility revocation and no `disputed`**. If Shopify sends the SCA line or SCA becomes disputed, **STOP immediately**; do not continue and do not patch ad hoc.
6. Then, only if the controlled test plan already provides a safe way to do so without affecting real data, prove the returned/full SCA line behavior: eligibility revoked; if already claimed, registry becomes `disputed` while ownership is preserved. If this requires additional irreversible setup beyond the dedicated test item, document it and stop for approval rather than expanding scope.

Throughout the dry-run, verify no customer PII is persisted by the Shopify integration (`shopify_customer_ref` remains null as designed) and no existing pilot item's ownership/status/certification/QR changes.

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
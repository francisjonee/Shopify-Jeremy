# SCA Staff Operations & Collector Experience Audit (read-only)

**Type:** Read-only audit. No application code, schema, config, infrastructure, or production data changed; no deployment; no pilot. Prepared for ChatGPT independent review.
**Baseline audited:** `1c6c1e6cc0167cf1fc1d87f2a12446a219664f55` (repo main; deployed production app code `3b30a0f…`, migration 138).
**Governance promotion:** `14941ed…` superseded — this audit was requested after the rg8 merge.
**Method:** workflow tracing across `app/packages/Sca/*` (Registry/Collector/Claim/Passport/Provenance), Blade views, admin + collector + public routes, and `app/tests/Feature/Sca`. Findings carry exact `file:line` anchors. Verification tags: **[V]** independently re-verified by me against source; **[C]** confirmed-from-code by the tracing pass (anchor given, pending ChatGPT re-verification); **[RT]** needs runtime/human validation.

Severity: **P1** correctness / trust / audit-integrity (address before a real-world pilot) · **P2** usability / pre-pilot polish · **P3** minor / cosmetic / divergence-hazard. Separate buckets: **ON-HOLD** (intentional, not a defect) and **REAL-WORLD-TESTING-ONLY**.

No merge/deploy/code change is proposed here; this is evidence for prioritization.

---

## P1 — correctness / trust / audit-integrity

1. **QR reissue: the mandatory reason is collected then silently discarded (audit-trail gap). [V]**
   The reissue confirm screen requires a Reason (`QrReissueRequest.php:27` `reason` required; `qr-reissue-confirm.blade.php:42-44`), but the controller never passes it on — `QrReissueController.php:70` calls `$this->qr->reissue($item->id, staffRef, expected_active_qr_id)`; `QrService::reissue()` signature (`QrService.php:75`) has no `reason` parameter, and `sca_qr_lifecycle_events` has **no reason column** (migration `..._create_sca_qr_lifecycle_events.php`). So the operator's required justification for rotating a permanent QR identity is never stored — unlike status events, certification corrections, and market-reference, which all persist a reason. `QrReissueTest` asserts the reason is *required* but never that it is *stored*, so the gap is unguarded.

2. **Collector profile advertises a public "Friendly link" (`/u/{handle}`) that does not resolve from the public edge (Phase A). [V]**
   When the profile is published **and** a handle is set, `profile.blade.php:117-118` renders `/u/{handle}` as a clickable, shareable link (`handleUrl` built in `ProfileController.php:78`). But the `/u/*` routes are intentionally **not edge-admitted** in Phase A (`CollectorServiceProvider.php:88-89` — "intentionally NOT yet admitted at the edge … stays edge-blocked until a separate Phase B Caddy change"). A recipient opening the advertised handle link from the public internet gets an edge block, while the permanent `/c/{public_ref}` link works. The UI promises a sharable address that fails externally. (The unpublished/reserved branches at `profile.blade.php:119-123` are correctly worded.)

3. **No collector notification/communication anywhere in the submission lifecycle, against copy that repeatedly promises contact → silent parked states. [C]**
   A grep of `app/packages/Sca` for Mail/Notification/Mailable found exactly one send: the password-reset link (`CollectorAccount.php:47`). Nothing notifies the collector on submission received/advanced, payment, custody, authentication result, grant-issued, or return. Yet collector copy repeatedly promises it: `submissions/show.blade.php:16` "We will be in touch", `:17` "Follow the instructions we provide", `:42` (dormant pay) "we'll be in touch with next steps", `index.blade.php:26`, return-pending `show.blade.php:103`. Combined with the `certified_pending_grant` ("check back shortly", `show.blade.php:67-71`) and the dormant-payment `submitted` state, a collector can sit in a parked state indefinitely with no feedback. Even a future notification would currently only hit the log (`MAIL_MAILER=log`). This is a genuine UX/trust gap distinct from the on-hold mail item.

4. **Irreversible provenance actions (certify, finalize-authentication) have NO confirmation interstitial, while far less consequential actions do. [V/C]**
   - Authentication **finalize** sets `finalized_at` (trigger-immutable) via a single-click plain POST with no confirm (`eyewear/show.blade.php:304`). **[C]**
   - **Certification issue** mints the permanent QR identity and freezes the certificate snapshot (`CertificationService.php:61-88`), POST-only, triggered by single-click forms (`eyewear/show.blade.php:308-311` and `:341-344`), no GET interstitial (`admin-routes.php:163`). **[C]**
   - By contrast every status valve, QR reissue, and ownership/cert/metadata correction requires a GET confirm + typed word, and the **reversible** catalog-image Delete on the *same* page uses a JS `confirm()` (`eyewear/show.blade.php:113`). `DestructiveActionConfirmationTest.php:22-31` documents that the confirmation layer deliberately covers status actions but **not** certify/finalize — so the asymmetry is real, not merely untested. **[V]** (A reversible action is guarded; two irreversible ones are not.)

---

## P2 — usability / pre-pilot polish

5. **Authentication result dropdown defaults to "Passed — authentic" with no empty placeholder. [V]**
   `authentication/create.blade.php:24-26` lists `passed`/`failed`/`inconclusive` with `passed` first and no blank option (the adjacent condition-grade select *does* have a "—" placeholder, `:32`). With no prior `old('result')`, the browser pre-selects the first option, so an operator who sets only a grade and submits silently records a **PASS**. Easy, high-consequence mistake.

6. **Certification failure reason is rendered on a non-default tab. [C]**
   `CertificationController::issue()` flashes `error` and redirects to the item detail (`CertificationController.php:50-52`); `eyewear/show.blade.php` renders `session('error')` only inside the Authentication tab (`:260-262`), but the default-selected tab is Overview (`:185`) and the "Issue certification" button is on the Certification & QR tab (`:341`). A failed issuance (e.g. already-certified / auth-ineligible) lands the operator on Overview with the reason hidden; success flashes globally (`:4-6`).

7. **Inconclusive authentication is presented to the collector identically to a hard failure. [C]**
   `SubmissionController.php:111-112` maps both `failed` and `inconclusive` to the `not_passed` state, and `submissions/show.blade.php:59-61` shows one copy — "did not pass … cannot be added." An inconclusive result (which may warrant re-examination) reads to the collector as a flat rejection with no distinction or next step. (Note: the registry/domain correctly keeps the three results distinct; this is a presentation choice on the collector surface.)

8. **Raw internal error codes/exception strings surface in operator-facing copy. [C]**
   CSV import interpolates the service code verbatim — `InventoryImportController.php:48` → "Could not read the CSV (no_data_rows)." Finalize surfaces the raw exception — `AuthenticationController.php:77` `'Could not finalize: '.$e->getMessage()` (e.g. "SCA: authentication is already finalized"). Inconsistent with `CertificationController.php:60-67`, which maps codes to friendly copy.

9. **Year validation message contradicts the rule. [V]**
   `StoreEyewearItemRequest.php:29` allows `max: date('Y')+1` (next year accepted) but `:41` the message is "Year cannot be in the future." (Same rule in `AcceptCustodyRequest.php:28`.)

10. **Intake field rules are inconsistent and allow blank/garbage permanent items. [V/C]**
    Manual create allows empty brand/model (`StoreEyewearItemRequest.php:21-24` `nullable`; `create.blade.php:28-33` no required marker) **[V]**, while custody acceptance requires them (`AcceptCustodyRequest.php:25-26`) **[C]** — two different rules for the same item type. With no hard-delete route by design (`admin-routes.php:25-26`), a staff member can permanently create a blank/garbage item with no undo. **[C]**

11. **Staff "Make claimable" button can appear for an item the grant service will reject (dead-end). [C]**
    Staff `grant_issuable` (`Registry SubmissionController.php:177`) is computed independently of the real authority `ExternalClaimGrantService::issueForItem()` (which also requires `external_intake` + no completed claim, `ExternalClaimGrantService.php:48-61`). The button (`submissions/show.blade.php:103-105`) can render for an item the service rejects → error redirect (fail-closed, but a UX dead-end).

12. **Custody accept form cannot capture `original_specifications` though the request accepts it. [C]**
    `AcceptCustodyRequest.php:31` / `::authoritative():57` carry `original_specifications`, but `accept.blade.php:40-59` renders no input for it — staff must add it later via metadata correction.

13. **Claim (QR / grant / submission-bound) creates irreversible initial ownership via a single POST with no confirmation. [C]** (`claim/show.blade.php:9`; `submissions/show.blade.php:77-80`.) Lower severity — it is the intended positive action — but it is an irreversible mutation without the confirm step that lost/stolen/recovered use.

14. **Staff "verified payment will advance automatically" copy describes an automation that cannot fire while Stripe is dormant. [C, on-hold-adjacent]** `submissions/show.blade.php:68-69`; `$hasVerifiedPayment` is only true with a succeeded payment row (`SubmissionController.php:150`), which cannot occur dormant, so the manual override is the only live path. The copy still describes a non-functioning automation.

---

## P3 — minor / cosmetic / divergence hazards

15. **Submission `cancelled` state is unreachable; `transition()` is dead code; collectors have no cancel. [V]** `SubmissionService.php:32-36` lists `cancelled` as a target and the DB enum allows it (`..._create_sca_authentication_submissions.php:65`), but nothing writes submission status `cancelled` and no collector/staff cancel route exists (verified: no `->transition(` caller targeting it). Views carry copy/styling for a state that can never occur (`submissions/show.blade.php:18`, `index.blade.php:12`, staff `index.blade.php` pill). A collector who no longer wants a submission has no cancel path.
16. **Adverse-status set duplicated as a literal. [C]** Staff `Registry SubmissionController.php:167` hardcodes `['disputed','lost','stolen','retired','invalidated']` while the collector uses the canonical `StatusService::ADVERSE_STATUSES` (`SubmissionController.php:89`). Equal today (`StatusService.php:29`), divergence hazard tomorrow.
17. **Handle length limits disagree across layers. [C]** view `maxlength=30` (`profile.blade.php:129`), controller coarse `max:60` (`ProfileController.php:176`), helper text "3–30" (`:131`); service is the real authority (3–30) so no functional defect.
18. **Dormant pay-return page is reachable with no payment. [C]** `PaymentController.php:54-73` `payReturn`/`payCancel` render regardless of config; `pay_return.blade.php:9` "Thanks — your payment is being processed" — mitigated by the `:10` disclaimer "This page is not itself a confirmation of payment."
19. **Recovered-confirm interstitial reachable by hand-typed URL on a non-adverse item → POST 409. [C]** `ItemStatusController.php:79-90` authorizes ownership only; not UI-reachable (`collection/show.blade.php:210-221`).
20. **Empty private-group copy mentions filters when none are set. [C]** `collection/index.blade.php:164-169`.
21. **Register form shows no up-front password-requirement hint (min 8). [C]** `register.blade.php:12-15` (errors do surface post-submit).
22. **Staff manual-override advance button renders even when a verified payment exists. [C]** `submissions/show.blade.php:73-77` (redundant; idempotent — rejects if not `submitted`).

---

## ON-HOLD (intentional — NOT defects; confirmed deliberate)

- **Stripe dormant / fail-closed.** `Collector/src/Config/stripe.php:14` default `enabled=false`, no `STRIPE_*` in `app/.env`; guards `StripeCheckoutService.php:34` and `StripeWebhookService.php:33` fail closed; collector pay CTA hidden (`submissions/show.blade.php:33-43`). [C]
- **`MAIL_MAILER=log`.** `app/.env:25`; the only mail path (password reset) and all claim/transfer/grant links are therefore out-of-band or log-only. Self-service reset cannot complete end-to-end until SMTP is enabled. [C]
- **`/u/{handle}` not edge-admitted (Phase A).** `CollectorServiceProvider.php:88-89`. (Drives finding #2's UX impact.) [C]
- **Shopify is LIVE-configured, not dormant — but the config file's comments contradict the populated env. [C]** `app/.env` sets a real `SHOPIFY_SHOP_DOMAIN`, `SHOPIFY_SCOPES=read_orders`, client id/secret, webhook secret and OAuth redirect; yet `shopify.php:45-51` comments still say OAuth redirect is "left null until a publicly trusted HTTPS host exists" and "webhook delivery is deferred." The stale comments should be reconciled with reality; and whether the webhook topics are actually **subscribed** in the Shopify app is external to this code (`WebhookTopics.php:22`) and needs operator confirmation. Not a code defect; a documentation/ops-truth mismatch.
- **Off-site backup/restore not activated** (owner-parked; outside this code).

## REAL-WORLD-TESTING-ONLY (code-correct; needs humans/devices)

- **Printed-QR legibility & scannability** at ~30 mm with 4-module quiet zone / ECC-H, dependent on the operator honoring "Scale 100% / Fit-to-page Off" (`EyewearItemController.php:519-523`; `qr-print-label.blade.php:63`); batch 4-col 44 mm grid on real A4/Letter (`qr-print-labels.blade.php:26-35`). [RT]
- **Custody paper-chain & frame identity**: the permanent `external_intake` item is built from what staff type into the confirm form; that the physical frame matches the submission cannot be code-enforced (`CustodyAcceptanceService.php:66`; `accept.blade.php:19`). [RT]
- **Phone scan → `/p/{token}`** end-to-end; owner passport redirect (`public-routes.php:18-20`; `CollectionController.php:161-170`). [RT]
- **Live Shopify**: a real order carrying the `sca_item_ref` line-item property to exercise `linkPaidLine`/cancel/refund; a live OAuth token for `ShopifyClient::getOrder` to exercise reconcile; real signed webhook deliveries; and confirmation that the topics are subscribed in the Shopify app. [RT]
- **Live Stripe**: real Checkout session + webhook signature (`StripeCheckoutService.php:80-94`, `StripeWebhookService.php:55`). [RT]
- **Email delivery** for reset/claim/transfer links once SMTP is enabled. [RT]
- **Mobile responsiveness**: bottom-tab nav, gallery thumbnail swap, document download on real devices (`Collector layout.blade.php:93-97`; `collection/show.blade.php:86-102`). [RT]

## Operator-awareness note (not a code finding)
`app/.env` holds real-looking `SHOPIFY_CLIENT_SECRET` / `SHOPIFY_WEBHOOK_SECRET` values in the working tree. The file is git-ignored (not tracked, no history) so this is **not** a committed-secret leak, but the live secrets are present on disk — flagged for operator awareness only; values are not reproduced here.

## Clean areas (traced, no defect found)
Custody acceptance core bind (lock + idempotent + forced `external_intake`); grant→claim and all three claim paths (atomic, idempotent, server-resolved tokens, privacy-safe 404s); physical return state machine (forward-only, zero provenance, collector view leaks no reason/ids); public passport resolver + presenter (strict 32-hex gate, constant-shape 404, allowlist output, adverse-dominant + invalidated Option-A, CSP/no-store); Shopify webhook + reconcile (HMAC-first, topic allowlist, order-level atomicity, PII-free, Sale≠ownership); registration/login/forgot enumeration-safety and privacy pseudonymization; index-vs-detail image source consistency (gallery mirrors legacy `image_path`). Exact anchors in the per-area traces.

---

**This is a read-only audit. No code/schema/config/infra/production change was made and none is proposed here. Awaiting ChatGPT independent review and prioritization before any remediation is scoped or authorized. Do not treat any finding as approval to implement.**

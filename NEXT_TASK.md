# NEXT TASK

**STATUS: SHOPIFY RECONCILIATION & OPERATIONS PRE-MERGE RE-AUDIT — PASS / R1 CLOSED. Exact candidate `682bbbc4779cbd688789685506c7f9f4309806e6` is APPROVED for merge/deployment from production base `b9baa341060dda08144b57017ca59776b7062cb2`. GitHub independently confirms candidate is 2 commits ahead / 0 behind the exact deployed base and R1 delta `af2269f→682bbbc` changes exactly 2 files: `ShopifyReconciliationService.php` + `ShopifyReconciliationTest.php`. R1 is closed: authoritative fetch remains before mutation; all order-line convergence now runs inside one outer `DB::transaction`; existing `SaleLinkService` remains the sole domain writer and its nested transactions compose under the outer boundary; any `SaleLinkRejection` or DB failure escapes the closure and rolls back all earlier line mutations; the PII-free run audit is written after/outside rollback. Mandatory proofs now cover (1) valid line then ineligible line => rejected with first line absent and zero provenance mutation, (2) all-valid multi-line commits together and rerun is idempotent, and (3) real DB 1406 after an earlier would-be mutation => whole run rolled back with generic `SHOPIFY_RECONCILE_DB_ERROR`, zero provenance mutation, safe error audit. Reported gates: ShopifyReconciliationTest 21 passed; focused existing Shopify/sale-link/claim suites 113 passed; full `tests/Feature/Sca` 1243 passed / 1 WebP skipped / 0 failed / 6488 assertions. Proceed ONLY with merge/deployment of exact approved candidate, expected migration 135→136. Before/after prove candidate tree identity, run migration + exact merge-tree full gate, reproduce CP-5 13-table provenance fingerprint/count gate, verify receipt columns + reconciliation table and safe initial row state, verify existing Shopify receipt/sale-link counts are not unexpectedly mutated by migration, verify Shopify OAuth scopes unchanged (`read_orders,read_products`), Stripe dormant/mail=log, no Caddy/DNS/SMTP changes, and smoke admin Shopify operations/configuration plus existing public/collector/admin boundaries. Record merge/main/deployed SHA and governance deployment evidence, then STOP for ChatGPT post-deployment audit. Do not start another initiative.**

Updated 2026-10-12.

## Why this is next
CP-6 is CLOSED. ChatGPT audited the live Shopify integration at production `b9baa34`. The ingestion/domain path is already strong: verified HMAC before payload trust, expected-shop enforcement, supported-topic allowlist, DB-backed receipt idempotency, atomic receipt+sale-link processing with retryable 5xx on infrastructure failure, exact SCA-ref mapping, deterministic paid/cancel/refund handling, and zero ownership/collector/claim side effects.

The actual operational gap is reconciliation and staff observability. Today the diagnostics page exposes essentially configuration state + a total receipt count. A verified delivery can be domain-rejected/unmapped and acknowledged 200, but the receipt row remains only `status=received`; staff cannot see safe per-delivery outcomes, identify unresolved/rejected SCA lines, inspect sale-link state, reconcile a known Shopify order/line against the authoritative Shopify API, or safely repair integration drift.

## Initiative
**SCA Shopify Reconciliation & Operations**

Build a staff-only, ACL-separated operational layer over the existing Shopify webhook/sale-link foundation.

### Core invariant
**Shopify commerce evidence may create/update/revoke the Shopify sale-link projection only. Reconciliation MUST NOT create ownership, collector accounts, claims, grants, authentication/certification state, QR state, or any other provenance event. Sale ≠ ownership.**

### Architecture requirements
1. Preserve the existing webhook security/idempotency boundary. Do not weaken HMAC, expected-shop, topic allowlist, atomic retry semantics, or duplicate handling.
2. Extend webhook receipt operational state so a NEW verified receipt records a safe processing summary/outcome after `SaleLinkEventProcessor` runs. Never store raw payload or customer PII. Existing rows must migrate safely.
3. Distinguish at minimum operational outcomes such as processed/actionable, safe no-op/non-SCA, domain-rejected/unmapped, and infrastructure failure semantics. Do not mark a rolled-back infrastructure failure as successfully consumed.
4. Store only bounded non-PII reconciliation/audit metadata needed for operations: receipt/topic/shop/webhook id/digest/timestamps and safe counts/codes. Do not persist customer name/email/address or raw Shopify payload.
5. Add a staff Shopify operations screen, separate from mere configuration diagnostics, showing bounded/paginated recent receipts and sale links with filters for topic/outcome/eligibility and unresolved/rejected conditions. No N+1/materialize-all.
6. Add a dedicated mutation ACL (e.g. `sca.shopify.reconcile`) separate from `sca.shopify.view`. View-only staff cannot trigger API calls that mutate local integration state.
7. Reconciliation targets a **server-resolved existing receipt/sale-link or validated Shopify order/line identifier**; never accept internal DB ids as authoritative bindings and never allow staff to type an arbitrary SCA item ref to force-bind an order line.
8. Extend the host-locked, HTTPS-only, pinned-version `ShopifyClient` with the minimum read-only Admin API operation(s) needed to fetch authoritative order/line state. Reuse OAuth token storage. Preserve no-redirect/token-leak and fail-closed auth/network behavior.
9. Reconciliation must derive the SCA ref only from the authoritative Shopify line-item property configured by SCA, then feed the existing domain service rules. No fuzzy matching by brand/model/SKU/title.
10. Reconciliation must be idempotent and deterministic. Re-running against unchanged Shopify state produces no duplicate sale link and no provenance mutation.
11. Handle at least:
   - paid/valid SCA line missing locally → create the same eligible sale link the verified webhook path would create;
   - already-correct link → no-op;
   - cancelled/refunded authoritative line/order → converge local eligibility to the same terminal state used by webhook processing;
   - malformed/missing/ambiguous SCA property → fail closed with safe operational outcome, no binding;
   - conflicting existing line↔item binding → fail closed; do not silently rebind;
   - owned/ineligible item → fail closed under existing SaleLinkService policy;
   - Shopify auth/network/429/5xx/bad response → retryable/generic operational error; no partial local mutation.
12. Do NOT add an unrestricted “edit sale link” UI. Repairs are evidence-driven from Shopify.
13. If Shopify API shape makes refund/cancel lookup materially different from order lookup, introduce a small normalized authoritative-commerce DTO/service rather than spreading raw Shopify response parsing through controllers.
14. Keep the existing webhook path fast and bounded. Do not perform outbound Shopify API reconciliation synchronously inside webhook receipt handling.
15. All reconciliation writes must be transactional. A failed API fetch causes zero DB mutation; a domain rejection records only safe operational audit state if appropriate, never a partial sale link.
16. Existing claim flow remains unchanged. An eligible sale link may support the existing claim path, but reconciliation itself never claims.
17. No public/collector route. No Caddy/DNS edge change.
18. No Shopify credential/scope expansion unless the current granted/requested scopes are proven insufficient. If scope expansion is actually required, STOP and document it instead of silently changing production OAuth permissions.

## Suggested data shape
Prefer additive migration **135→136**. Exact schema is implementation-dependent after inspection, but favor:
- extending `sca_shopify_webhook_receipts` with bounded processing outcome/count/timestamp fields, and/or
- a dedicated PII-free reconciliation-run table if manual/API reconciliation needs durable audit evidence.
Do not duplicate the sale-link source of truth.

Any operational status enum/check constraint must have an explicit lifecycle and safe migration/backfill for existing `received` rows.

## Staff UX
Under existing admin Shopify area:
- configuration/connectivity summary remains;
- operations/reconciliation view is ACL-protected;
- recent receipt table: time, topic, safe webhook identifier, processing outcome, counts/reason code;
- sale-link table: SCA item opaque ref, Shopify order/line refs, eligibility state, timestamps;
- filters/pagination;
- explicit reconcile action with confirmation for mutation-capable staff;
- result shown as generic/safe outcome;
- no secrets, tokens, raw payload, customer PII, internal numeric ids, SQL errors.

## Mandatory tests
At minimum prove:
1. Existing forged webhook rejection unchanged.
2. Existing duplicate webhook idempotency unchanged.
3. Existing transient infrastructure failure remains retry-safe/receipt rollback semantics unchanged.
4. New successful webhook receipt gets correct safe processing outcome.
5. Ordinary non-SCA order is safe no-op and distinguishable operationally.
6. malformed/missing/ambiguous mapping records safe rejected/unresolved outcome without sale link.
7. receipt/outcome persistence contains no raw payload/customer PII.
8. operations pages require staff auth + view ACL.
9. reconcile action requires separate mutation ACL + CSRF + throttle.
10. ShopifyClient remains expected-host locked, HTTPS, pinned API version, no redirects, no secret leakage.
11. authoritative paid valid line missing locally → reconcile creates exactly one eligible sale link.
12. repeat reconciliation → idempotent no-op.
13. authoritative cancel → converges to cancelled.
14. authoritative refund → converges to revoked_refund.
15. conflicting existing binding → generic fail-closed; original binding unchanged.
16. owned/ineligible item → fail closed; no link/provenance mutation.
17. missing/malformed/ambiguous authoritative SCA property → no binding.
18. auth failure/network/429/5xx/bad JSON → no partial DB mutation; safe error.
19. reconciliation creates zero collector/ownership/claim/grant/auth/cert/QR/status events.
20. no raw Shopify payload/customer PII persisted by reconciliation.
21. view queries are paginated/bounded and no N+1.
22. no public/collector reconciliation routes.
23. existing claim eligibility behavior from sale links remains unchanged.
24. existing Shopify connection/OAuth/webhook/sale-link suites remain green.
25. full `tests/Feature/Sca` green.
26. provenance fingerprint procedure remains unchanged by test/deployment fixtures outside rolled-back disposable DB.

## Audit/deployment discipline
- NEW branch from exact production `b9baa341060dda08144b57017ca59776b7062cb2`.
- Expected migration 135→136 if schema changes.
- Do not touch Caddy/DNS/SMTP/Stripe.
- Do not activate/change Shopify OAuth scopes or credentials.
- Do not merge/deploy.
- Push candidate + governance implementation evidence.
- STOP for ChatGPT pre-merge audit.

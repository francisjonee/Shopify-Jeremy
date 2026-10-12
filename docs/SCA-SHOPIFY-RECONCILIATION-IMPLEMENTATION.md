# SCA Shopify Reconciliation & Operations — CANDIDATE

**Date:** 2026-10-12 · **Status: CANDIDATE — R1 REMEDIATED (order-level reconciliation atomicity), re-pushed. NOT merged / NOT deployed / production untouched (migration 135) / Stripe DORMANT / mail=log / Caddy+DNS+SMTP untouched / Shopify OAuth scopes UNCHANGED. STOP for ChatGPT re-audit.**

- **Impl repo:** `francisjonee/francisjonee-sca-platform-private` · **Governance:** `francisjonee/Shopify-Jeremy`
- **Branch:** `feat/sca-shopify-reconciliation`
- **Base (exact deployed baseline):** `b9baa341060dda08144b57017ca59776b7062cb2` (prod HEAD, migration 135)
- **Candidate head:** `682bbbc4779cbd688789685506c7f9f4309806e6` (R1 remediation of `af2269f`; 2 commits ahead of base)
- **Migrations:** candidate **135 → 136** (one additive migration); **prod stays 135**.

## 0. Pre-merge audit R1 remediation (head `682bbbc`)

**Finding (accepted):** order-level reconciliation atomicity. The prior `reconcileOrder()` processed each SCA
line through `SaleLinkService` in that service's OWN transaction and caught `SaleLinkRejection` per line, so
line 1 could commit while line 2 was rejected — leaving a PARTIAL sale-link repair (and contradicting the UI
"No partial changes" message).

**Fix (2 files, delta from `af2269f`; NO parallel writer, SaleLinkService unchanged):** wrap the entire
order convergence in ONE outer `DB::transaction`. `SaleLinkService` owns its own transaction boundaries, so
each call nests as a **savepoint** within the outer transaction and nothing durably commits until the outer
commits. A `SaleLinkRejection` (conflict/ineligible/malformed/ambiguous/missing) or ANY DB/infrastructure
failure on any line is **no longer caught per-line** — it propagates out of the closure and rolls back the
ENTIRE run (including earlier lines' savepoint work). So **either all eligible SCA-line changes commit
together, or none do**. The PII-free audit row is recorded AFTER (outside) the rolled-back transaction, so a
rejected/failed attempt is still safely audited. The `\Throwable` catch surfaces only a GENERIC code
(`SHOPIFY_RECONCILE_DB_ERROR`) — never raw SQL/exception detail. The webhook HMAC/idempotency/retry/OAuth/
ACL/PII/bounded-query/scope guarantees are unchanged.

**New proofs (ShopifyReconciliationTest):** partial-success rejection (line 1 would link, line 2 ineligible
→ outcome `rejected`, line 1 rolled back to its PRE-run state, line 2 unbound, zero provenance, exactly one
safe `rejected` audit row); all-valid multi-line (both lines commit together, rerun idempotent); infra/DB
failure after an earlier line (forced 1406 under STRICT mode on line 2 → whole run rolls back, line 1 not
created, generic safe `error`, zero provenance, one `error` audit row). Deterministic across repeated runs.

## 1. Core invariant honoured
**Shopify commerce evidence may create/update/revoke the Shopify sale-link projection ONLY. Reconciliation creates NO ownership, collector account, claim, grant, authentication/certification, QR, status, or any other provenance event. Sale ≠ ownership.** The existing webhook security/idempotency boundary (HMAC-before-trust, expected-shop, topic allowlist, DB-backed idempotency, atomic retry) is preserved unchanged. Reconciliation reuses the EXISTING `SaleLinkService` domain rules — no parallel sale-link writer, no fuzzy matching. No Shopify OAuth scope/credential change (proven unnecessary — see §7).

## 2. Changed files (14: 8 new, 6 modified)
**NEW** — migration `2026_10_17_000001_add_shopify_reconciliation.php`; `Models/ReconciliationRun.php`; `Support/AuthoritativeOrder.php`; `Services/ShopifyReconciliationService.php`; `Http/Controllers/OperationsController.php`; `Resources/views/operations.blade.php`; `Resources/views/_pager.blade.php`; `tests/Feature/Sca/ShopifyReconciliationTest.php`.
**MODIFIED** — `Services/ShopifyClient.php` (+read-only `getOrder`); `Services/WebhookAuditRecorder.php` (+`recordOutcome` safe summary); `Http/Controllers/WebhookController.php` (capture processor summary in the same txn); `Config/acl.php` (+`sca.shopify.reconcile`); `Config/menu.php` (+operations entry); `Routes/admin-routes.php` (+operations/reconcile routes).

## 3. Data model (migration 135 → 136, additive, no provenance)
`ALTER sca_shopify_webhook_receipts` ADD (all NULLABLE → existing `received` rows migrate safely; NULL `processing_outcome` = legacy/not-summarized): `processing_outcome` (lifecycle for NEW rows: `processed` | `noop_non_sca` | `rejected_unmapped`), `outcome_code` (first safe domain code), `line_count`, `actionable_count`, `noop_count`, `rejected_count`, `processed_at`; index (topic, processing_outcome). No CHECK constraint (avoids a backfill hazard on legacy rows). Stores NO raw payload / customer PII (the one-way `payload_sha256` digest is unchanged).

`CREATE sca_shopify_reconciliation_runs` (durable PII-free audit): `id`, `actor_user_id` (staff id — internal, not customer PII), `shop_domain`, `shopify_order_id` (authoritative Shopify id, not a DB id), `outcome` (`completed`|`rejected`|`error`|`no_sca_lines`), `outcome_code`, `line_count`, `actionable_count`, `rejected_count`, `created_at`. No customer name/email/address, no raw payload, no token. Does NOT duplicate the sale-link source of truth.

## 4. Webhook receipt processing outcome (preserves the boundary)
`WebhookController` already ran `SaleLinkEventProcessor::process()` inside the receipt transaction and discarded its safe per-line summary. It now passes that summary to `WebhookAuditRecorder::recordOutcome()`, which derives `processing_outcome` + counts + first reason code and updates the NEW receipt row — in the SAME transaction. So an infrastructure failure still rolls back the whole receipt (never recorded as consumed), a domain-rejected/unmapped delivery is a committed receipt marked `rejected_unmapped`, an ordinary non-SCA order is `noop_non_sca`, and a successful SCA delivery is `processed`. HMAC / expected-shop / topic-allowlist / idempotency / 5xx-retry semantics are byte-for-byte unchanged.

## 5. Authoritative read-only reconciliation
`ShopifyClient::getOrder($orderId)` — `GET /admin/api/{pinned}/orders/{id}.json`, same safety contract as `getShop` (host-locked `*.myshopify.com`, HTTPS, pinned version, `allow_redirects=false`, fail-closed, never leaks the token; 401/403 drops the token, 404/429/5xx/bad-shape → distinct safe codes). Uses the already-granted `read_orders` scope.

`AuthoritativeOrder::fromShopify()` isolates all Shopify parsing into a minimal DTO (order id, cancelled, paid, per-line {line id, product/variant id, SCA ref from the configured property, refunded}); no customer PII; the SCA ref is read ONLY from the configured `line_item_ref_property` (identical semantics to the webhook processor).

`ShopifyReconciliationService::reconcileOrder()` fetches the authoritative order (read-only), then per SCA line converges via the EXISTING `SaleLinkService`:
- order cancelled → `cancelLine` (→ cancelled / tombstone);
- line refunded → `revokeLine('revoked_refund')`;
- order paid & line active → `linkPaidLine` (creates one eligible link if missing; `exists` = no-op);
- not paid/cancelled/refunded → `skipped_unpaid` (no binding);
- missing property → `skipped_non_sca`; malformed/ambiguous/conflict/owned/ineligible → `SaleLinkRejection` → fail closed, no partial link.
Idempotent/deterministic (re-run = `exists`/terminal no-op). A failed API fetch precedes all DB writes (zero mutation) and still records a safe `error` audit run; each line convergence is one `SaleLinkService` transaction (rejection throws before any write). Records one PII-free `sca_shopify_reconciliation_runs` row per run.

## 6. Staff operations + ACL
New operations screen `GET /admin/sca/shopify/operations` (ACL `sca.shopify.view`): bounded manual pagination (one extra row detects "more"; no COUNT, no N+1) of recent receipts (time/topic/safe webhook id/outcome/counts/code), sale links (SCA item opaque `public_ref` + Shopify order/line refs + eligibility + timestamps), and reconciliation runs, with topic/outcome/eligibility/unresolved filters (allowlisted). Reconcile action `POST /admin/sca/shopify/reconcile` requires the SEPARATE mutation ACL `sca.shopify.reconcile` + CSRF (web group) + `throttle:20,1`; input is a validated authoritative Shopify order id (digits) — never an internal DB id, never a staff-typed SCA ref; no free "edit sale link" surface. No public/collector route; no Caddy/DNS change. The view renders no token/secret/raw payload/customer PII/internal numeric id/SQL error.

## 7. OAuth scope finding (no expansion)
The required authoritative state (paid/cancelled/refunded per line) is fully available from `GET orders/{id}.json` under the already-granted **`read_orders`** scope — refunds are embedded in the order resource (`refunds[].refund_line_items[]`) and cancellation via `cancelled_at`. No new scope is needed; scopes remain `read_orders,read_products`. No STOP-for-scope condition arose.

## 8. Tests
`ShopifyReconciliationTest` — **21 passed / 275 assertions**: getOrder host-lock/HTTPS/pinned/token-header + bad-id fail-closed (rc10); paid-missing→one eligible link (rc11); idempotent re-run (rc12); cancelled→cancelled (rc13); refund→revoked_refund (rc14); conflicting binding fail-closed, original unchanged (rc15); owned item fail-closed no link (rc16); missing/malformed/ambiguous property → no binding (rc17); API 401/429/5xx/bad-JSON → no partial mutation + safe code (rc18 ×4); zero provenance + no-PII audit columns (rc19/rc20); receipt outcomes processed/noop_non_sca/rejected_unmapped + no raw-payload column (rc4–rc7); operations view auth+view ACL (rc8); reconcile separate mutation ACL + CSRF(web) + throttle (rc9); no public/collector route (rc22); bounded/no-N+1 operations queries (rc21); **R1 order-level atomicity — partial-success rejection rolls back the earlier line, all-valid multi-line commits together + idempotent, infra/DB failure rolls back the whole run (3 new proofs, §0).** Existing `ShopifyConnectionTest`/`ShopifySaleLinkTest`/`ShopifySaleClaimVisibilityTest`/`ShopifyListingRefCopyTest`/`ClaimWorkflowTest` = **113 passed** (unchanged). **Full `tests/Feature/Sca`: exit 0 · 1243 passed · 1 skipped (webp GD env) · 0 failed · 6488 assertions.**

## 9. Production state (verified at restored baseline)
Live tree restored to `main` = `b9baa34` (deployed SHA unchanged), `--no-dev` re-pruned, caches cleared, `/admin/login` loopback → 200.
- Prod `sca_krayin` migrations **135**; `sca_shopify_reconciliation_runs` ABSENT; `sca_shopify_webhook_receipts.processing_outcome` ABSENT (migration applied only to disposable `sca_domain_test`).
- Provenance row-data FP `d15a5cbdfb8df52ba65628b276533cfe`; canonical counts `3/3/4/4/5/2/1/1/7` — unchanged.
- `STRIPE_ENABLED` unset (dormant); `MAIL_MAILER` log; Shopify `scopes` unchanged (`read_orders,read_products`). No Caddy/DNS/SMTP/Stripe change; no OAuth scope/credential change.

**STOP for ChatGPT re-audit of head `682bbbc`.** Do not merge/deploy; no Caddy/DNS; no OAuth scope change; no post-task work.

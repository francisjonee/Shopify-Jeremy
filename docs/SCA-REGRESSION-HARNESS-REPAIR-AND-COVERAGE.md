# SCA — Regression Test-Harness Repair + Document-Feature Coverage (GREEN)

**The 8 pre-existing full-suite failures are resolved and the three document enhancements now have
dedicated tests; the complete `tests/Feature/Sca` suite is GREEN — 1536 tests / 7960 assertions / 0
failures / 0 errors / 1 (pre-existing) skip. All changes are TEST-ONLY; no application code was touched
and no genuine application defect was found.** Candidate branch `feature/sca-test-harness-repair` =
`4bf93dd` (off `a923dfd`, i.e. on top of the 3 document branches). Isolated disposable DB; production
unchanged at `b007606`. 2026-10-30. **STOP for review.**

## Result
- **Before (Phase-1 baseline):** 1525 tests → 5 errors + 3 failures + 1 skip.
- **After:** **1536 tests / 7960 assertions / 0 failures / 0 errors / 1 skip** (the +11 are the new
  document tests). The single skip is the pre-existing image/webp environment skip (also 1 in the
  baseline) — unrelated.

## Root causes & repairs (all TEST-ONLY; app behaviour confirmed correct in every case)
1. **5 concurrency ERRORS** (`CollectorCollectionConcurrencyTest` cc1a/cc1b/cc2,
   `MarketReferenceConcurrencyTest` cc_mr1, `ServiceCorrectionConcurrencyTest` cc_sc1):
   `proc_open(/var/www/html/storage/*.err): No such file or directory`. Root cause = the disposable
   runner mounted the app at `/app`, but the proc_open workers and the worker scripts hardcode the
   production docroot `/var/www/html` (the compose layout they were written for). **Harness fix:** run
   the disposable container mounted at **`/var/www/html`** (compose docroot) — no test-code change for
   the path. Additionally **bumped the worker-wait timeouts 20/20/25 → 45/45/60s** in the three files so
   the real two-process barrier tests stay reliable under shared-host CPU/IO load (a reliability-only
   change — a test that passed in time still passes; no assertion altered). This also eliminated the
   `cc1a` timing slip seen under a concurrently-busy host.
2. **`CollectorAuthTest::c11`** — the app **correctly** denies a collector the staff dashboard (HTTP 302
   → `/admin/login`); the stale assertion expected the masked "Something went wrong" page. Now accepts
   either denial shape and still asserts `Auth::guard('user')` is false (the real invariant). No
   behaviour change.
3. **`ShopifyConnectionTest::s12`** — `products/create` became a **supported** topic with Shopify
   Inventory Sync Phase 1 (it now records + processes a catalog mirror), so it is no longer an
   "unsupported, not recorded" case. The test now uses a genuinely-unsupported topic (`customers/create`)
   → 200 `ignored`, 0 receipts. App contract confirmed correct in `WebhookController` / `WebhookTopics`.
4. **`CertificateDocumentClassificationTest::d9`** and **`CollectorCollectionTest::c21`** — both flaked on
   **bare internal-id substring checks** that coincide with page digits as auto-increment ids shift (the
   order/shared-state dependency): `d9` on media PK `"9"`; `c21` on a collection/item id `== 100`
   colliding with the page's fixed `maxlength="100"`. **Eliminated the dependency without weakening:**
   - `d9` now asserts the download identifier is the OPAQUE `DocumentHandle` (Laravel `Crypt`,
     non-deterministic by design — hence asserted by presence of its structure, not a recomputed value)
     and that no storage path / checksum / QR token / `"subject_id"` is rendered.
   - `c21` now asserts the internal-id FIELD NAMES (`collector_collection_id`, `eyewear_item_id`,
     `collector_account_id`, `"id":`) are absent and that the opaque `public_ref`s are the only
     identifiers rendered.
   Both preserve (and arguably strengthen) the "no internal id leaked / opaque refs only" guarantee and
   are order-independent. These were surfaced, not caused, by the concurrency repair (once those tests
   run fully they shift auto-increment state).

## New coverage (document enhancements)
- **`ProvenanceReportTest`** (6 tests): current owner downloads the PDF (200, `application/pdf`,
  attachment, `%PDF`); non-owner and previous-owner-after-transfer get the shared privacy-safe 404;
  unauthenticated → login; repeated downloads create NO media and mutate NO provenance
  (ownership/cert events unchanged); the report template emits only owner-safe fields and the
  non-appraisal / not-a-value disclaimers, and never the injected sentinels (frame_serial, owner email,
  QR token, storage path, internal id).
- **`CollectorCertificateAvailabilityTest`** (5 tests): owner makes the certificate available (exactly
  one `is_public` certificate media, listed under Documents); no active certification (after revoke) →
  clean error message and NO media; non-owner and previous-owner denied (404); repeated requests are
  idempotent (never duplicate; same media row + same checksum — the immutable document is preserved);
  staff-only (`is_public=0`) documents stay hidden.

## Isolated validation (Phase C)
Disposable `sca_domain_test` created fresh; scoped `sca_test` user proven **denied `sca_krayin`**
(`ERROR 1044`); identity probe all `sca_domain_test`; `--internal` `sca_testnet` with egress blocked
(`curl 1.1.1.1` exit 7); fake Shopify/Stripe creds + `MAIL=array`; app mounted at `/var/www/html`;
migrate + seed on the disposable DB only. A peer session on the host (migrating unrelated apps, confirmed
not using `sca_domain_test`/`kr-mariadb`) was coordinated with via cross-session message. Full suite run
single-process. **Final: 1536 / 7960 / 0 failures / 0 errors / 1 skip.**

## Remaining risks / notes
- The **concurrency tests require the app at `/var/www/html`** (compose docroot) because the worker
  scripts hardcode that path. Any disposable runner must mount there (documented). A future, optional,
  lower-priority hardening could make the worker paths mount-agnostic (`dirname()`-derived) so they run
  at any mount point — not done here to avoid changing shared tests that pass in compose.
- The 1 skip is the pre-existing image/webp environment skip.
- Branch stack is now 4 deep: `ba2da33` ← `63b5808` ← `a923dfd` ← `4bf93dd` (tests). A release should
  consolidate these.

## Changed files (all under `app/tests/`, branch `4bf93dd`)
Modified: `CollectorAuthTest.php`, `ShopifyConnectionTest.php`,
`CertificateDocumentClassificationTest.php`, `CollectorCollectionTest.php`,
`CollectorCollectionConcurrencyTest.php`, `MarketReferenceConcurrencyTest.php`,
`ServiceCorrectionConcurrencyTest.php`. New: `ProvenanceReportTest.php`,
`CollectorCertificateAvailabilityTest.php`. **No application/src change; no migration.**

## Production unchanged
Prod SHA `b007606`, working tree clean; `kr-app` healthy; `/collector/login` and `/admin/login` → 200.
`sca_krayin` fingerprint before == after: migrations **146** / batch **30**; `sca_eyewear_items` **3**,
`sca_certifications` **4**, `sca_qr_identifiers` **3**, `sca_ownership_events` **5**, `sca_media_assets`
**2**. Disposable DB/user/network and the worktree were removed and verified.

## Recommended next action
With the suite GREEN, a consolidated release candidate of the document branches
(`ba2da33`→`63b5808`→`a923dfd`→`4bf93dd`) off production may now be prepared, then a controlled code-only
deployment (no migration) — each **separately authorized**. Secure-claim RC `4bd88d2` remains
DEPLOYMENT-BLOCKED and untouched; the known public-QR claim gap is not approved for launch.

**STOP — test-harness repaired and document-feature coverage added, TEST-ONLY; full `tests/Feature/Sca`
regression GREEN (1536/7960/0 failures/0 errors/1 pre-existing skip) in isolation; no application code
changed and no app defect found; production verified unchanged at `b007606`. Branch
`feature/sca-test-harness-repair` `4bf93dd` pushed. Awaiting review before any RC/deployment.**

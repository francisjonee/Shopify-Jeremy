# SCA-OPTC — Regression Evidence (candidate vs baseline)

**Scope:** Finding 3 of the ChatGPT audit — preserve the complete candidate-vs-baseline failing-test comparison and classify it. **This does NOT declare the full suite PASS.** The stated result is: focused suite PASS; full suite shows **no Option-C-attributable failure**; the residual failures are enumerated, pre-existing environment/fragility artifacts of the minimal ephemeral harness.

**Provenance of the data below:** captured during the initial candidate verification (`7b41e8d`) — the candidate full run and a clean `6022b75` baseline run in the **identical** ephemeral harness (same image `sca-app:krayin-2.2.6`, same container env, fresh DB per run). A confirmatory re-run on the **remediated** runner (per-run unique DBs) is DEFERRED until database tests are authorized (the current task delivers the revised runner + non-destructive `selftest` only). The classification is independent of which disposable DB name is used, so it is unaffected by the runner remediation.

---

## Full-suite failing tests

**Candidate `7b41e8d` full suite — 13 failures:**
1. `Tests\Feature\AuthenticationTest > it can see the dashboard page after login` — TypeError
2. `Tests\Feature\AuthenticationTest > it can logout from the admin panel` — TypeError
3. `Tests\Feature\HelpTest > it shows the help page to an authenticated admin` — TypeError
4. `Tests\Feature\Sca\CertificateDocumentClassificationTest > d9 no internal ids/paths/checksums/tokens rendered`
5. `Tests\Feature\Sca\CollectorCollectionConcurrencyTest > cc1a real transfer wins concurrent add fails cleanly`
6. `Tests\Feature\Sca\CollectorCollectionConcurrencyTest > cc1b add wins real transfer rebuild deletes membership`
7. `Tests\Feature\Sca\CollectorCollectionConcurrencyTest > cc2 real admin correction wins concurrent add fails cleanly`
8. `Tests\Feature\Sca\CollectorHandleTest > h7 handle page matches opaque allowlist and leaks nothing` ← **candidate-only delta**
9. `Tests\Feature\Sca\MarketReferenceConcurrencyTest > cc mr1 two overlapping supersedes one wins other stale`
10. `Tests\Feature\Sca\ServiceCorrectionConcurrencyTest > cc sc1 two overlapping corrections exactly one wins other stale`
11. `Tests\Feature\Sca\TransactionalEmailHardeningTest > h8 single use token and real reset unchanged`
12. `Tests\Feature\Security\AuthenticationHardeningTest > it rate limits repeated failed logins`
13. `Tests\Feature\Security\AuthenticationHardeningTest > it rate limits repeated forgot password requests`

**Clean baseline `6022b75` full suite — 12 failures:** identical to the list above **except #8** (`CollectorHandleTest::h7`), which passed on baseline.

**Set difference:** candidate-only = {`CollectorHandleTest::h7`}; baseline-only = {} (empty). Every other failure is present on both.

---

## Classification (all 13 are pre-existing env/fragility; none Option-C-attributable)

Option C changed only claim/fulfillment/grant code, the shared staff item-detail view, 5 test files, the base `TestCase` guard helper, one additive migration, and the test runner. None of the failing tests exercise that code:

- **#1–#3 admin `AuthenticationTest` / `HelpTest` (TypeError):** admin-panel pages; fail on this minimal harness (no admin seed/config). Not claim/fulfillment/grant.
- **#4 `CertificateDocumentClassificationTest::d9`:** certificate-document rendering assertion, sensitive to the injected dev-preview banner/CSS in this harness. Not Option C.
- **#5–#7, #9, #10 concurrency suites (`CollectorCollectionConcurrency`, `MarketReferenceConcurrency`, `ServiceCorrectionConcurrency`):** real two-connection race tests, timing-sensitive under an ephemeral single-run harness (see the known deadlock/contention note). Not claim/fulfillment/grant.
- **#11 `TransactionalEmailHardeningTest::h8` / #12–#13 `AuthenticationHardeningTest` rate-limit:** depend on the production canonical URL (`https://verify.secondchanceauthenticators.com`) and a real throttle cache store — neither configured in the minimal harness (`APP_URL` defaults to `http://localhost`; cache is `array`). Not Option C.

### The sole delta — `CollectorHandleTest::h7`

h7 asserts that a bare numeric database id (`$item['id']`, `$c->id`) is **not a substring** of the rendered handle-page HTML. This is inherently fragile:

- In the candidate full run the colliding value was `220` — which appears in the injected dev-preview CSS `max-width:220px`.
- Run **in isolation** on a fresh DB, h7 **still fails** — the colliding value is `1` (id of the first row), and `1` appears throughout any HTML page (e.g. `initial-scale=1`).
- On baseline the autoincrement id for that test happened to be a value that was not a coincidental substring, so it passed.

So h7's pass/fail is a function of (a) the autoincrement id value and (b) the dev-preview CSS present in this harness — **not** of any code Option C touches (Option C modifies no collector-handle/public-profile code). The candidate adds test rows (new `FulfillmentReleaseTest`, extra grant tests, rewritten `ClaimWorkflowTest`) that shift the autoincrement id reached by the time h7 runs, which is why the coincidence surfaced on the candidate but not the baseline. It is a pre-existing test-fragility, not a regression.

---

## Verdict

- **Focused Option-C suite:** PASS (68 tests / 333 assertions / 0 failures) on an isolated per-run DB.
- **Full suite:** **not declared PASS.** It carries 13 failures; **0 are attributable to Option C.** 12 are identical to the clean baseline; the 1 delta (`CollectorHandleTest::h7`) is a demonstrated pre-existing numeric-id-substring fragility in code Option C does not touch.
- **Deferred confirmatory step (after DB tests are authorized on the remediated runner):** re-run the full suite on a per-run unique DB and re-diff against baseline to confirm the same classification; optionally note `h7` as a separate pre-existing test-hardening item (out of Option C scope).

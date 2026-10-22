# SCA-OPTC — Authorized Focused-Test Execution Evidence

**Status: the owner-authorized isolated focused run executed and PASSED. Full suite NOT run. Not merged / not deployed / no production migration / no restart / no Shopify/Stripe/SMTP activation.** `main 6022b75` + production `sca_krayin` untouched.

- **Candidate SHA:** `1df81d51827a93cb28e6a21229565f6982b4cfaf` (`feat/sca-optc-secure-claim`), verified in an isolated worktree `/opt/sca-platform-cand-optc` (live app `/opt/sca-platform` stayed at `6022b75`).
- **Command executed (only this):** `scripts/run-optc-tests.sh focused`
- **Date:** 2026-10-22.

## Preflight (all passed before any migration)

1. **SHA + isolated worktree:** HEAD == `1df81d5…` ✓; worktree is `/opt/sca-platform-cand-optc`, not the live app.
2. **New unique disposable DB, not pre-existing:** before the run, `SHOW DATABASES` listed only `sca_krayin` (+ system DBs) — no `sca_optc_test_*` present. The runner creates `sca_optc_test_<rand>` with `CREATE DATABASE` (no `IF NOT EXISTS`, abort on collision).
3. **MariaDB container + server identity + credentials:** container `kr-mariadb`, image `mariadb:10.11` (`mariadb:10.11.18-MariaDB-ubu2204`, id `b36c8e36e041`), on network `sca_internal`; root credentials verified by a read-only query.
4. **Prod/shared excluded:** `assert_disposable()` and `verify_effective()` reject `sca_krayin` AND `sca_domain_test` as targets.
5. **No existing disposable DB deleted:** none existed; the runner registers a DB for cleanup only after it creates it, so it can only drop what it created.
6. **Workers:** the focused set spawns no worker processes (workers exist only in the concurrency tests, which are in the full suite — not run here). The per-run worker wiring is self-test-covered for the later full run.
- Non-destructive `selftest`: **56 passed / 0 failed** (no DB touched) immediately before the run.

## Run evidence

- **Disposable database:** `sca_optc_test_8e70d5c6` (created for this run, dropped on exit).
- **Effective-connection verification (host decision):** `db=sca_optc_test_8e70d5c6 host=kr-mariadb live=sca_optc_test_8e70d5c6`.
- **PHPUnit/Pest override check:** `ok: no DB override in /var/www/html/phpunit.xml`.
- **In-container re-verify (immediately before migrate):** `re-verified in migrate/test container: db=sca_optc_test_8e70d5c6 host=kr-mariadb live=sca_optc_test_8e70d5c6`.
- **Migrations:** applied against the disposable DB (141 `DONE`), including the Option-C additive migration `2026_10_23_000001_add_fulfillment_release_to_sca_eyewear_items … DONE`.
- **Tests:** `vendor/bin/phpunit` over the 5 Option-C files (`ClaimWorkflowTest`, `FulfillmentReleaseTest`, `ExternalClaimTest`, `ShopifySaleClaimVisibilityTest`, `CollectorAuthContextTest`):

```
PHPUnit 11.5.50 by Sebastian Bergmann and contributors.
Runtime:       PHP 8.3.33
Configuration: /var/www/html/phpunit.xml
................................................................. 65 / 68 ( 95%)
...                                                               68 / 68 (100%)
Time: 00:19.071, Memory: 79.00 MB
OK (68 tests, 333 assertions)
```

- **Result:** **68 tests, 333 assertions, 0 failures.** Runner exit 0.
- **Database cleanup:** after the run `SHOW DATABASES LIKE 'sca%'` → only `sca_krayin` (the disposable `sca_optc_test_8e70d5c6` was dropped).
- **Production not targeted:** live app HEAD `6022b75`; loopback `302` (up); `sca_krayin.migrations` unchanged at `max_batch=27, total=140` (no migration ran against production).

## Problems / unresolved

- None in the focused run. The full suite (including the parameterized concurrency tests + workers) and the F3 reproducible baseline re-diff remain **not run** and require separate authorization.

**STOP — focused-test evidence delivered for independent ChatGPT review. Full suite not executed. No merge/deploy/migrate/restart/activation.**

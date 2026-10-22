# SCA-OPTC — Complete Final Test-Safety Preparation

**Status: XML-aware override validation, in-container re-verification, and the full per-run test-DB parameterization are implemented + non-destructively verified; available for independent ChatGPT review. NO focused or full database test was executed.** Not merged / not deployed / no production migration / no restart / no integration activation. No Option C application logic changed. Candidate `feat/sca-optc-secure-claim` advanced **`254d876` → `1df81d5`** (one commit; all files under `app/tests/` or `scripts/`). `main 6022b75` + `sca_krayin` untouched.

## Commit SHA + changed files (`1df81d5`, 16 files)

Modified: `scripts/run-optc-tests.sh`; `app/tests/TestCase.php`; the 7 concurrency tests (`CollectorCollectionConcurrencyTest`, `CollectorHandleConcurrencyTest`, `CollectorProfileConcurrencyTest`, `CollectorPublicItemConcurrencyTest`, `CollectorPublicProfileConcurrencyTest`, `MarketReferenceConcurrencyTest`, `ServiceCorrectionConcurrencyTest`); `EyewearRegistryTest`; `ProvenanceDomainTest`; the 3 workers (`cp6_worker.php`, `mre_worker.php`, `svc_correction_worker.php`).
New: `scripts/assert-no-db-override.php` (XML-aware validator); `app/tests/Support/per_run_db_guard.php` (shared pure per-run rule).

## How each review point was addressed

1. **XML-aware override validation (replaces the regex).** `scripts/assert-no-db-override.php` parses the config with `DOMDocument` and fails closed on any `DB_*` / `DATABASE_URL` `<env>`/`<server>`/`<const>`/`<var>` entry, independent of quote style, attribute order, or multiline formatting; an unparseable file fails closed; an absent file is a no-op. `run_suite` invokes it in-container before migrate.
2. **In-container re-verification immediately before migration.** The migrate/test container now re-boots the **same** Laravel kernel the migrator uses and asserts the EFFECTIVE connection (effective host == `DB_HOST` == `kr-mariadb`; effective name == live `SELECT DATABASE()` == `DB_DATABASE`; never `sca_krayin`/`sca_domain_test`) immediately before `php artisan migrate`, in addition to the host-side gather+decide.
3. **Parameterization finished.** 7 concurrency tests + 2 additional files (`EyewearRegistryTest`, `ProvenanceDomainTest`) + 3 worker scripts no longer hardcode `sca_domain_test` as a target. (`ProvenanceDomainTest`'s raw `information_schema` query now scopes to the effective per-run schema via a bound parameter.)
4. **Secondary connections + workers inherit the exact per-run DB.** Each concurrency test asserts its secondary connection equals the per-run default DB (`!== DB::connection()->getDatabaseName()`); each worker-spawning test passes the exact per-run DB **plus host/port/credentials** (derived from the test's own resolved connection) to the worker; each worker binds `database` from env `DB_DATABASE`.
5. **Fail-closed against `sca_krayin` AND `sca_domain_test` preserved.** New base-`TestCase::perRunDbName()` (concurrency setUp) and the shared `sca_is_per_run_db()` (workers) require a per-run unique `sca_<slug>_test[...]` name and reject both production and the shared DB. The only remaining `sca_domain_test` literals in these files are inside fail-closed reject guards.
6. **Non-destructive demonstrations added** (self-test): `[10]` runs the XML validator against clean / double-quote / single-quote / attribute-order / multiline fixtures (and the real `phpunit.xml`); `[11]` runs the shared per-run rule on valid / `sca_krayin` / `sca_domain_test` / empty inputs — both via php in a throwaway `--network none` container (no DB, no network, no live mount); `[12]` statically verifies the secondary-connection/worker wiring.
7. **Only non-destructive checks were run** (below). No focused/full database test.

## Non-destructive evidence — `selftest`: 56 passed / 0 failed; `bash -n` OK; `php -l` clean on all 16 files

```
[1] assert_disposable rejects protected/malformed targets      (11 PASS)
[2] assert_disposable accepts per-run disposable names          (3 PASS)
[3] provision() source invariants                               (4 PASS)
[4] run_suite gathers EFFECTIVE config, decides before migrate/test (6 PASS)
    incl. XML-aware override validator before migrate; EFFECTIVE re-verify in the migrate/test container
[5] cleanup fatal + status-preserving                           (3 PASS)
[6] drop_db returns real status + guarded                       (2 PASS)
[7] no phase/provision path targets sca_domain_test             (1 PASS)
[8] BEHAVIORAL provision/drop_db/cleanup (mocked db_sql)        (6 PASS)
[9] verify_effective host + schema mismatch rejection           (6 PASS)
[10] XML-AWARE PHPUnit override detection (quote/order/multiline fixtures + real phpunit.xml)  (6 PASS)
[11] shared per-run DB rule — accepts per-run; rejects sca_krayin, sca_domain_test, empty      (5 PASS)
[12] secondary-connection + worker target wiring (static)       (3 PASS)

selftest: 56 passed, 0 failed (no DB touched; XML-override & per-run-guard checks ran php in a
throwaway --network none container — no DB, no network, no live mount)
```

Lint: all 16 changed/new PHP files pass `php -l` in a `--network none`, read-only, no-DB container.

## Unresolved concerns / what remains before database-test authorization

- **Full correctness of the parameterized concurrency tests + workers is not yet proven** — only `php -l`, static wiring, and the pure-rule/XML demonstrations ran (no DB allowed). Confirmation that the 7 concurrency tests and 3 workers actually pass on a per-run unique DB requires the authorized focused/full DB run.
- **F3 reproducible regression confirmation remains deferred.** The prior full-suite comparison (candidate 13 vs baseline 12; sole delta the pre-existing `CollectorHandleTest::h7` numeric-id-substring fragility) has not been re-run on the remediated runner. It is documented, not dismissed, pending the authorized run.
- **`CollectorHandleTest::h7`** is tracked as a separate pre-existing test-hardening item (out of Option C scope).

**STOP — complete test-safety preparation + non-destructive evidence available for independent ChatGPT review before database-test authorization. No merge/deploy/migrate/restart/activate.**

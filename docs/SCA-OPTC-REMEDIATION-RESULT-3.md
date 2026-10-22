# SCA-OPTC — Final Runner Safety Correction + Guard-Conversion Prep

**Status: revised runner + non-destructive safety evidence + mechanical guard conversion available for final ChatGPT review. NO focused or full database test was executed.** Not merged / not deployed / no production migration / no restart / no integration activation. Candidate `feat/sca-optc-secure-claim` advanced **`5766f4e` → `254d876`** (two commits, pushed). `main 6022b75` + `sca_krayin` untouched.

Addresses the independent review of `5766f4e`. Two separate commits (runner/self-test vs test-only conversion; neither touches application logic).

---

## Commit 1 — `d1984aa`: final runner safety (runner only, `scripts/run-optc-tests.sh`, +110/−51)

**F1.1 — effective HOST match.** `run_suite` is now two container runs:
1. **gather** — remove `bootstrap/cache/config.php` (worktree only; the live app is never mounted), boot the **same** Laravel kernel the migrator uses, and print the EFFECTIVE connection's database name, config host, and a live `SELECT DATABASE()` on one sentinel line;
2. **decide on the host** — a pure `verify_effective()` requires the effective **host == kr-mariadb** (the disposable-test DB host) **and** the effective name **and** live `SELECT DATABASE()` **== the uniquely created per-run DB**, and rejects any forbidden/non-disposable effective name — **failing closed (return 3) BEFORE** the second run migrates/tests.

**F1.2 — PHPUnit/Pest cannot override after preflight.** `assert_no_phpunit_db_override()` fails closed if `phpunit.xml` / `phpunit.xml.dist` declare any `DB_*` `<env>`/`<server>` entry that could redirect the connection after the preflight. The candidate's own `phpunit.xml` is clean (asserted in the self-test against the real file).

**F1.3 — self-test coverage for host and database mismatches.** The `selftest` now behaviorally exercises `verify_effective()` with synthetic **HOST mismatch**, **expected-host ≠ kr-mariadb**, **DB-name mismatch**, **forbidden effective DB**, and **live `SELECT DATABASE()` mismatch**; and `assert_no_phpunit_db_override()` with clean / `DB_DATABASE` / `DB_HOST` fixtures plus the real `phpunit.xml`. All host-side, **no DB, no container**.

**F1.4 — safeguards preserved.** Ownership-by-creation (CREATE, no `IF NOT EXISTS`, abort on collision), register-after-create, drop-only-created, fatal cleanup (exit 4) with original-status preservation, and the pure-bash target allowlist (rejects `sca_krayin`/`sca_domain_test`) are unchanged.

### Non-destructive evidence — `selftest`: 46 passed / 0 failed (no DB, no container); `bash -n` OK

```
[1] assert_disposable REJECTS protected / malformed targets      (11 PASS)
[2] assert_disposable ACCEPTS per-run disposable names           (3 PASS)
[3] F1 provision() source invariants                             (4 PASS)
[4] F1 run_suite gathers EFFECTIVE config, then DECIDES before migrate/test
  PASS: config-cache is cleared in-container (no cached redirect)
  PASS: gather boots the real Laravel kernel (effective config)
  PASS: gather runs a live SELECT DATABASE()
  PASS: verify_effective DECIDES before the migrate/test container runs
  PASS: verify_effective precedes migrate
  PASS: PHPUnit/Pest DB-override refusal runs before the test container
[5] F2 cleanup fatal + status-preserving                         (3 PASS)
[6] drop_db returns real status + guarded                        (2 PASS)
[7] no phase/provision path targets sca_domain_test              (1 PASS)
[8] F1/F2 BEHAVIORAL (real provision/drop_db/cleanup, mocked db_sql)
  PASS: collision aborts (exit 3) and issues NO DROP
  PASS: successful create registers exactly the created DB (no drop)
  PASS: failed cleanup is fatal (exit 4) and targets only the created DB
  PASS: existing test-failure status (5) preserved over cleanup failure
  PASS: forbidden name aborts (exit 3) BEFORE any DB operation
  PASS: clean run drops the created DB and exits 0
[9] F1 verify_effective BEHAVIORAL — host + schema mismatch rejection
  PASS: accepts an exact host+schema match
  PASS: rejects effective HOST mismatch
  PASS: rejects expected host that is not kr-mariadb
  PASS: rejects effective DB-name mismatch
  PASS: rejects forbidden effective DB (sca_krayin)
  PASS: rejects live SELECT DATABASE() mismatch
[10] F1 PHPUnit/Pest DB-override refusal
  PASS: accepts a config with NO DB override
  PASS: rejects a DB_DATABASE env override
  PASS: rejects a DB_HOST server override
  PASS: the candidate's real phpunit.xml has no DB override

selftest: 46 passed, 0 failed (NO database or container was touched)
```

---

## Commit 2 — `254d876`: mechanical test-guard conversion (TEST-ONLY, 81 files, +81/−243)

Prepared separately and **not combined with application logic** — all 81 changed files are under `app/tests/`. Mechanically replaces the uniform 3-line inline guard with the fail-closed helper `$this->guardDisposableDb();` (exactly one replacement per file; byte-identical block). The helper accepts `sca_domain_test` and any per-run `sca_*_test` name while still hard-rejecting `sca_krayin`.

**Not converted (left for separate, non-mechanical follow-up — they hardcode `sca_domain_test` beyond a simple guard: named second connections / spawned-worker `DB_DATABASE` / `config()` overrides, which need parameterization, not a guard swap):** the 7 concurrency tests (`CollectorCollectionConcurrency`, `CollectorHandleConcurrency`, `CollectorProfileConcurrency`, `CollectorPublicItemConcurrency`, `CollectorPublicProfileConcurrency`, `MarketReferenceConcurrency`, `ServiceCorrectionConcurrency`) and the 2 `$db`-variant files (`EyewearRegistryTest`, `ProvenanceDomainTest`), plus the 3 `tests/Support/*_worker.php` helper scripts.

**Validation (no DB):** perl replaced exactly 1 block per file; no canonical guard remains outside the 7 excluded concurrency files; `php -l` passes on all 81 (container with `--network none`, read-only mount, no DB).

---

## Deferred (still not authorized; awaits final review + explicit DB-test authorization)

- Focused + full database runs on per-run unique DBs, plus the clean `6022b75` baseline re-diff with fresh logs (F3 reproducible confirmation).
- Non-mechanical parameterization of the 7 concurrency tests + 2 `$db`-variant files + 3 worker scripts to the per-run DB (so the full suite can run on a unique DB).

**STOP — final runner + non-destructive safety evidence + guard-conversion prep available for independent ChatGPT review. No DB test executed. No merge/deploy/migrate/restart/activate.**

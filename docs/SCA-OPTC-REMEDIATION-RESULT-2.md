# SCA-OPTC — Re-Audit Remediation Result (effective-Laravel verify + behavioral self-tests)

**Status: revised runner + non-destructive safety evidence available for ChatGPT review. NO focused or full database test was executed.** Not merged / not deployed / no production migration / no restart / no integration activation. Candidate `feat/sca-optc-secure-claim` advanced **`54c848e` → `5766f4e`** (pushed). `main 6022b75` + `sca_krayin` untouched.

Addresses the ChatGPT re-audit of `54c848e`. Scope was runner + self-test only; **no Option C application logic changed** (1 file: `scripts/run-optc-tests.sh`, +91/−22).

---

## F1 — Effective Laravel connection verification (was: standalone PDO)

The in-container pre-migrate step no longer trusts a standalone PDO over env vars. It now, **before `artisan migrate`**:
1. **Eliminates config-cache contamination** — `rm -f bootstrap/cache/config.php`, so a stale/cached DB config cannot redirect migrations. This touches only the **mounted candidate worktree**; the live app (`/opt/sca-platform/app`) is never mounted and its config cache is never read or mutated.
2. **Reads the EFFECTIVE Laravel connection** — boots the **same** framework kernel `artisan migrate` uses (`bootstrap/app.php` + `Illuminate\Contracts\Console\Kernel::bootstrap()`), then reads the resolved connection's database name + host.
3. **Confirms the live target** — runs `SELECT DATABASE()` **through that Laravel connection**.
4. **Requires an EXACT match** with the uniquely created per-run database, and **fails closed (exit 3)** on any mismatch or on a forbidden effective name (`sca_krayin` / `sca_domain_test`) — before migrate or tests run.

This closes the gap where Laravel's effective (possibly cached) configuration could differ from a raw PDO check.

## F2 — Behavioral self-tests (mocked DB operations; not grep/awk alone)

The `selftest` mode now exercises the **real** `provision()` / `drop_db()` / `cleanup()` against a **mocked `db_sql`** (a recording stub — no docker, no mysql, no real database), proving:
- a name collision (CREATE returns non-zero) **aborts (exit 3) and issues NO DROP**, and does not register the name;
- a successful create **registers exactly the created DB**;
- cleanup **targets only a created/registered DB**;
- a **failed drop is fatal (exit 4)**;
- an **existing test-failure status (5) is preserved** over a cleanup failure (not overwritten by 4);
- a **forbidden name aborts before any DB operation** (the stub is never called).

The static grep/awk source audits are retained as additional checks, no longer the sole evidence.

## F3 — Regression status

`docs/SCA-OPTC-REGRESSION-EVIDENCE.md` keeps the full 13-vs-12 comparison and is reworded to **not** declare full PASS or conclusively dismiss the failures: the current status is "failures present; no Option-C attribution demonstrated, **pending reproducible confirmation**" on the remediated runner once DB tests are authorized.

---

## Non-destructive safety evidence — `selftest`: 35 passed / 0 failed (no DB, no container)

`bash -n` OK. `bash scripts/run-optc-tests.sh selftest`:

```
[1] assert_disposable REJECTS protected / malformed targets        (11 PASS)
[2] assert_disposable ACCEPTS per-run disposable names             (3 PASS)
[3] F1 source invariants (static audit)                            (4 PASS)
[4] F1 run_suite verifies the EFFECTIVE Laravel connection BEFORE migrate
  PASS: config-cache is cleared before migrate (no cached redirect)
  PASS: boots the real Laravel kernel to read EFFECTIVE config before migrate
  PASS: live SELECT DATABASE() check precedes migrate
  PASS: run_suite re-rejects prod/shared on the EFFECTIVE connection
  PASS: run_suite requires exact effective==expected match
[5] F2 cleanup is fatal and status-preserving (static audit)       (3 PASS)
[6] drop_db returns a real status and is guarded                   (2 PASS)
[7] no phase/provision path targets the shared sca_domain_test     (1 PASS)
[8] F1/F2 BEHAVIORAL tests — real provision()/drop_db()/cleanup() with a MOCKED db_sql
  PASS: collision aborts (exit 3) and issues NO DROP
  PASS: successful create registers exactly the created DB (no drop)
  PASS: failed cleanup is fatal (exit 4) and targets only the created DB
  PASS: existing test-failure status (5) preserved over cleanup failure
  PASS: forbidden name aborts (exit 3) BEFORE any DB operation
  PASS: clean run drops the created DB and exits 0

selftest: 35 passed, 0 failed (NO database or container was touched)
```

---

## Deferred (still not authorized; awaits independent review of this runner)

- Focused + full database runs on per-run unique DBs, plus the clean `6022b75` baseline re-diff with fresh logs (F3 confirmation).
- Migrating the remaining ~93 SCA inline `sca_domain_test` setUp guards to `guardDisposableDb()` (needed only for the full run on a unique DB). The 5 Option-C test files already use the helper.

## Change inventory (candidate `5766f4e`)

`scripts/run-optc-tests.sh` only (+91/−22). No application claim/fulfillment/grant logic change; no dependency change.

**STOP — revised runner + non-destructive safety evidence available for independent ChatGPT review. No DB test executed. No merge/deploy/migrate/restart/activate.**

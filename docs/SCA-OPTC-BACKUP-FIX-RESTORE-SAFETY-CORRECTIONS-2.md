# SCA — Restore-Verification Tooling: Final Two Safety Checks

**Scope: isolated tooling correction + non-destructive mocked tests only. NO real database restore, no merge, no deploy, no production migration, no service restart, no backup-configuration change. STOP for independent ChatGPT review.** 2026-10-27.

Follows the conditionally-accepted source review of `b14439c`. Worked in an **isolated git worktree**; the live checkout stayed `main 6022b75`, clean.

## Updated SHA & changed files

- Branch `fix/sca-backup-document-consistency`: `b14439c` → **`95c15d3f5dde1162f6ede442b87a007b87835ccd`** (pushed to `origin` = github-sca-platform).
- **Changed:** `scripts/backup-verify-restore.sh` · `scripts/test-restore-verify-safety.sh`.
- **Untouched:** `backup-run.sh`, `lib-docsnapshot.sh`, `DocumentService.php`, `BackupDocumentAtomicityTest.php`. No application/schema/retention change. Unique per-run DB ownership, collision protection, document-reference verification, and all production safeguards from `b14439c` are preserved.

## Correction 1 — cleanup failures are visible and fatal; success is never reported on incomplete cleanup

- `cleanup_created_dbs()` no longer suppresses errors: the `2>/dev/null || true` on the `REVOKE SELECT` and `DROP DATABASE` calls is removed, so the **underlying mysql error (the original reason) is shown**. Any failure records a human-readable `CLEANUP_ERR` and the function **returns nonzero**.
- A shared `final_cleanup()` EXIT trap now serves both the `selftest` and `verify` modes. It captures the body's own exit status, shreds the work dir, then runs `cleanup_created_dbs`:
  - **If cleanup fails:** prints `FAIL: CLEANUP INCOMPLETE — <reason>; leftover disposable database(s): <name>. Restore is NOT confirmed…` to stderr and **exits nonzero**, even if the body had succeeded. If the body had already failed, it additionally prints `(original failure preserved: body exited N)` so the first reason is not masked.
  - **If cleanup succeeds:** prints the success line **only** when the body also succeeded.
- The success strings (`SELFTEST PASS`, `RESTORE VERIFICATION PASS …`) are no longer echoed inline; they are deferred into `RESULT_MSG` and emitted by `final_cleanup` **only after the disposable database is actually dropped** — so a successful restore can never be reported if cleanup did not complete.

## Correction 2 — application-read is pinned to exactly the disposable restore database

Before reading any table, the `php -r` app-read now asserts **both** identities equal the injected disposable DB name:

```php
$want = (string) getenv("DB_DATABASE");                                  // the name we injected (= TARGET)
$eff  = (string) DB::connection()->getDatabaseName();                    // Laravel's effective connection DB
$live = (string) (DB::selectOne("SELECT DATABASE() AS d")->d ?? "");     // the live session DB
if ($want === "" || $eff !== $want || $live !== $want) {
    fwrite(STDERR, "DB_IDENTITY_MISMATCH want=[".$want."] effective=[".$eff."] live=[".$live."]\n");
    exit(3);
}
```

The shell caller captures stderr and **aborts** unless the output is exactly `items=<n> state=<n>` — so if a stale `.env` or anything else pointed the app at another database (e.g. the live `sca_krayin`), the names differ and the run stops before reading a single table. On match it logs `application read OK, pinned to <TARGET> (…)`.

## Safety-test results (mocked; no real DB) — `scripts/test-restore-verify-safety.sh`

`bash scripts/test-restore-verify-safety.sh scripts/backup-verify-restore.sh` → **35 passed, 0 failed.** `bash -n` clean on both scripts. Coverage:

- **Preserved (T1–T6):** pre-existing-DB collision → no CREATE/DROP; CREATE-race → no DROP; cleanup drops only created DBs; scoped `REVOKE SELECT`, no `REVOKE ALL`; unique per-run names; fail-closed document extraction; nonzero `verify_db_document_refs` stops the run.
- **Correction 1 (T7a–d):** clean cleanup → success printed + exit 0; DROP failure → fatal (exit≠0), success **not** printed, leftover DB named, `CLEANUP INCOMPLETE` reported; body-failure + cleanup-failure → original reason preserved and still fatal; REVOKE failure → fatal + reported.
- **Correction 2 (T8):** identity mismatch → abort with `DB identity mismatch`; identity match → `items=3 state=3` passes.
- **Static asserts:** `final_cleanup` trap used by both modes; no bare `SELFTEST PASS`/`RESTORE VERIFICATION PASS` echoes; cleanup drop failures not suppressed; app-read contains `getDatabaseName()` + `SELECT DATABASE()` + `DB_IDENTITY_MISMATCH` and the `$eff !== $want || $live !== $want` condition; and all `b14439c` safeguards (no DROP-before-CREATE, no `REVOKE ALL`, verifier on restored artifact, `docker exec` not `docker compose exec`) still hold.

## Corrected execution procedure

Unchanged from the `b14439c` procedure (`docs/SCA-OPTC-BACKUP-FIX-268C637-RESTORE-SAFETY-CORRECTIONS.md`) except that the staged branch tip is now **`95c15d3`**. Still: worktree-stage outside `app/` → pre-flight (`MARIADB_DATABASE == sca_krayin`, `kr-mariadb` + `kr-app` running) → `selftest` + `doc-consistency-selftest` + `verify <artifact>` → automatic (now fatal-on-failure) cleanup → `git worktree remove`. A `CLEANUP INCOMPLETE` or `DB identity mismatch` message is a hard stop.

**STOP — corrected tooling (`95c15d3`) + mocked safety tests (35/35) delivered for independent ChatGPT review. No real restore, merge, deploy, migration, service restart, or backup-config change. Await explicit owner authorization before any database restore.**

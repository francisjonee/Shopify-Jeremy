# SCA — Restore-Verification Tooling: Final Safety Corrections

**Scope: isolated tooling correction + non-destructive mocked tests only. NO real database restore, no merge, no deploy, no production migration, no service restart, no backup-configuration change, no integration activated. STOP for independent ChatGPT review before database-restore authorization.** 2026-10-27.

Worked in an **isolated git worktree** of the branch (never the live checkout / bind-mounted `app/`). Live checkout remained `main 6022b75`, clean, throughout.

## Updated SHA & changed files

- Branch `fix/sca-backup-document-consistency`: `268c637` → **`b14439cf819ac25a3dea07dfd8412671d00f009e`** (pushed to `origin` = github-sca-platform).
- **Changed:** `scripts/backup-verify-restore.sh` (+77 / −19).
- **Added:** `scripts/test-restore-verify-safety.sh` (mocked safety tests; no real DB).
- **Untouched (intentionally):** `scripts/backup-run.sh`, `scripts/lib-docsnapshot.sh`, `app/.../DocumentService.php`, `app/tests/.../BackupDocumentAtomicityTest.php`. No application/schema/retention change.

## The ten corrections (each mapped to the implementation)

| # | Requirement | Implementation in `backup-verify-restore.sh` |
|---|---|---|
| 1 | Unique per-run disposable DB names | `RUN_TAG=$(od -An -N6 -tx1 /dev/urandom …)`; `disposable_db_name()` appends it. `verify` → `sca_krayin_restore_verify_<12hex>`, `selftest` → `sca_backup_selftest_<12hex>`. |
| 2 | Never DROP before CREATE; abort if DB exists | `create_disposable_db()` pre-checks `information_schema.schemata` and **dies if present**, then `CREATE DATABASE` **without `IF NOT EXISTS` and without any preceding `DROP`** — a race makes CREATE fail and we abort, nothing dropped. The old `DROP … IF EXISTS; CREATE …` lines are gone. |
| 3 | Register for cleanup only after successful creation | `CREATED_DBS+=("$db")` runs **only after** a successful `CREATE`. |
| 4 | Cleanup deletes only DBs created by this run | `cleanup_created_dbs()` drops exactly the names in `CREATED_DBS`. |
| 5 | selftest/verify/cleanup cannot overwrite/delete any existing DB | Guaranteed by (1)+(2)+(3)+(4) plus `guard_target` (never the live name). |
| 6 | Preserve pre-existing privileges | Grants tracked in `GRANTED_DBS`; cleanup issues a **scoped `REVOKE SELECT ON \`<our-per-run-db>\`.*`** only if we granted it. The old unconditional `REVOKE ALL PRIVILEGES` is removed. |
| 7 | Document extraction fails closed | Removed `2>/dev/null \|\| true`; extraction is now `tar … \|\| die "document extraction failed (incomplete restore)"` in both `verify` and `selftest`. |
| 8 | Nonzero document-reference verification stops the run | `verify_db_document_refs … \|\| rc_refs=$?; [ "$rc_refs" -eq 0 ] \|\| die …` — `die` exits and the `EXIT` trap still runs `cleanup_created_dbs` (safe cleanup). |
| 9 | New verifier runs against the restored real artifact | `verify` mode now sources `lib-docsnapshot.sh` and runs `verify_db_document_refs "${WORK}/db.sql.gz" "${WORK}/docout"` after restore (previously only backup-time + synthetic selftest exercised it). |
| 10 | Stage scripts outside the live checkout where practical | `SCA_ENV_FILE` override lets the scripts source the live `.env` from anywhere; app-read switched from `docker compose exec app` (project/CWD-bound) to `docker exec -i … "${APP_CONTAINER:-kr-app}"` (container-name, location-independent). |

## Safety-test results (mocked; no real DB) — `scripts/test-restore-verify-safety.sh`

Run: `bash scripts/test-restore-verify-safety.sh scripts/backup-verify-restore.sh` → **22 passed, 0 failed.** The tests extract the real helper functions verbatim and drive them with a mock `mysql`, plus functional micro-tests and static asserts:

- **T1 collision (pre-existing DB):** `create_disposable_db` aborts; **no `CREATE`, no `DROP`** issued.
- **T2 CREATE race:** CREATE fails → abort; **no `DROP`** after the failed CREATE.
- **T3 cleanup scope:** drops **exactly** the two created DBs, never a pre-existing name; `REVOKE SELECT` scoped to the one granted per-run DB; **no `REVOKE ALL`**; the ungranted DB is not revoked.
- **T4 uniqueness:** name matches `^…_[0-9a-f]{12}$`; two runs yield distinct names.
- **T5 extraction fail-closed:** a failing `tar -x` aborts (not swallowed).
- **T6 verifier-stop:** a nonzero `verify_db_document_refs` aborts the run (EXIT trap then cleans up).
- **Static:** `|| die` on the verify-mode extraction; no suppressed `documents.tar.gz` extraction; verifier wired into `verify`; `docker exec` (not `docker compose exec`); no `DROP`-before-`CREATE`; no `REVOKE ALL PRIVILEGES`.

`bash -n` clean on both scripts.

## Corrected execution procedure (to run ONLY after explicit owner authorization)

Staged **outside the live checkout** via an isolated worktree; disposable targets only; the live DB, schedule, retention, and `app/` bind-mount are never touched.

```bash
# Step 0 — isolated staging (does NOT alter the live checkout or the bind-mounted app/):
cd /opt/sca-platform
git fetch origin
WT=/opt/sca-platform/.restore-verify.$$    # outside app/ ; or any scratch path
git worktree add --detach "$WT" b14439c
cd "$WT"
export SCA_ENV_FILE=/opt/sca-platform/.env \
       SCA_BACKUP_DIR=/opt/sca-platform/backups \
       SCA_BACKUP_KEY_FILE=/opt/sca-platform/secrets/backup.key \
       SCA_BACKUP_WORK_DIR=/opt/sca-platform/backups/.work

# Step 1 — pre-flight (STOP on any failure):
set -a; . "$SCA_ENV_FILE"; set +a
[ "${MARIADB_DATABASE}" = "sca_krayin" ] || { echo STOP; exit 1; }
docker inspect -f '{{.State.Running}}' kr-mariadb | grep -qx true || { echo "STOP: kr-mariadb"; exit 1; }
docker inspect -f '{{.State.Running}}' kr-app     | grep -qx true || { echo "STOP: kr-app"; exit 1; }

# Step 2 — synthetic proofs (no production data):
scripts/backup-verify-restore.sh selftest
scripts/backup-verify-restore.sh doc-consistency-selftest

# Step 3 — restore the current REAL artifact into a unique disposable DB; the verify mode now itself
#          runs verify_db_document_refs against the restored artifact and stops on any nonzero result:
scripts/backup-verify-restore.sh verify /opt/sca-platform/backups/sca-backup-20261027T021703Z.tar.gz.gpg

# Step 4 — teardown (disposable DBs already auto-dropped by the EXIT trap):
cd /opt/sca-platform && git worktree remove --force "$WT"
```

**Expected evidence (PASS):** `SELFTEST PASS`; `doc-consistency` A–M PASS; then `artifact sha256 verified` · `db component integrity verified against manifest` · `schema restored: tables≈100, triggers≈46, foreign_keys≈129` · `referential integrity OK` · `application read OK (items=3 state=3)` · `document bytes restored intact (4605 file(s))` · `document-reference verification OK …` · `RESTORE VERIFICATION PASS`.

**Stop conditions:** `.env` missing / `MARIADB_DATABASE ≠ sca_krayin`; `kr-mariadb`/`kr-app` not running; disposable DB already exists (create aborts); artifact sha ≠ sidecar; db ≠ manifest; app-read `ERR`; `verify_db_document_refs` rc ≠ 0 (5 non-canonical/count-mismatch · 6 missing file · 8 corrupt); any selftest assertion. On any stop, the `EXIT` trap drops only this run's created DBs and shreds the work dir; live DB/schedule/retention unchanged.

**Rollback/cleanup:** nothing to roll back vs production (read-only against live; restores the existing artifact into a disposable DB). Disposable DBs auto-dropped; if interrupted, they are uniquely named `*_<runtag>` and safe to `DROP DATABASE IF EXISTS` manually; shred `backups/.work`; `git worktree remove` the staging tree.

**STOP — corrected tooling (`b14439c`) + mocked safety tests (22/22) delivered for independent ChatGPT review. No real restore, merge, deploy, migration, service restart, or backup-config change. Await explicit owner authorization before any database restore.**

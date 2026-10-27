# SCA — Controlled Restore-Verification: RESULT

**Authorized, controlled execution of ONE restore-verification sequence** against the existing encrypted backup dated 2026-10-27, using branch commit `95c15d3` in an isolated worktree. Disposable database only. 2026-10-27.

**VERDICT: PASS.** The current production backup restores completely and is document-consistent. Live application, production database, backup schedule, and retention are unchanged. **STOP for independent ChatGPT review.** Nothing merged, deployed, migrated, restarted, or reconfigured; no production DB restore/modification; no backup created/deleted.

## What ran

Branch `fix/sca-backup-document-consistency` `95c15d3` staged via `git worktree` outside the live `app/` checkout. The three authorized synthetic + real operations were run with the live `.env`, backups dir, and key passed by env override (`SCA_ENV_FILE`/`SCA_BACKUP_DIR`/`SCA_BACKUP_KEY_FILE`).

## [2] Pre-flight (all PASS)

- Production identity: `MARIADB_DATABASE=sca_krayin`; containers `kr-mariadb` + `kr-app` running.
- Isolation baseline: `SHOW DATABASES` = only `information_schema, mysql, performance_schema, sca_krayin, sys` (no stray disposable DBs).
- Backup checksum: computed `42e7aadd…875fed` == sidecar == `backup.log` → **MATCH**.
- Key present (`secrets/backup.key`, 0600); disk `/` 317 G free; cron `17 3 * * *` installed; 10 retained artifacts.
- Production baseline fingerprint: `items=3, state=3, owns=5, certs=4, max_migration_batch=27`.

## [3] Synthetic selftests (PASS)

- `selftest`: encrypt → tamper-detection (modified ciphertext rejected) → decrypt → DB restore (rows=2, append-only trigger enforced) → document bytes sha256 match → `SELFTEST PASS`.
- `doc-consistency-selftest`: cases A–M all fail-closed as designed (publication boundary, copy/enumeration/mkdir failures, traversal/non-canonical rejection, deletion-window) → `DOC-CONSISTENCY-SELFTEST PASS`.

## [4–6] Real-artifact restore into a uniquely-named disposable DB (PASS)

Disposable DB `sca_krayin_restore_verify_dfe153bc9551` (created, never dropped-before-created):

- `artifact sha256 verified`
- `decrypted + extracted bundle`
- `db component integrity verified against manifest`
- `schema restored: tables=100, triggers=46, foreign_keys=129`
- `referential integrity OK (no orphan ownership rows)`
- **[6] `application read OK, pinned to sca_krayin_restore_verify_dfe153bc9551 (items=3 state=3)`** — Laravel's effective connection name AND live `SELECT DATABASE()` both equalled the disposable DB before any table read.
- `document bytes restored intact (4605 file(s))`
- **[5] `document-reference verification OK (every DB 'local' doc ref present & canonical in the restored artifact)`** — the new `verify_db_document_refs` ran against the restored dump + restored documents and returned 0. **This clears risk R1: the current production data already satisfies the fail-closed document-reference gate.**
- `RESTORE VERIFICATION PASS (disposable DB 'sca_krayin_restore_verify_dfe153bc9551' dropped)`; exit 0.

## [7] Cleanup verification (PASS)

- `SHOW DATABASES` = only `information_schema, mysql, performance_schema, sca_krayin, sys` — **the disposable DB was dropped; none remain.**
- No `restore_verify`/`backup_selftest` grant remains for the app user (temporary SELECT grant revoked, scoped).
- `backups/.work` staging: **0 entries** (plaintext shredded).
- Isolated worktree removed; `git worktree list` shows only `/opt/sca-platform`; live checkout `main 6022b75`, clean.

## [8] Production unchanged (PASS)

- `sca_krayin` fingerprint after = before: `items=3, state=3, owns=5, certs=4, max_migration_batch=27` (no mutation; 139/140 incident untouched).
- `kr-mariadb` + `kr-app` still running; live app not restarted.
- Cron unchanged (`17 3 * * *`); retention unchanged; 10 artifacts; the 2026-10-27 artifact sha still `42e7aadd…875fed` (no backup created or deleted).

## Procedural note (full transparency)

A first attempt was launched under `bash -x … | grep` for argument tracing; it was stopped mid-restore. Because it had already created its disposable DB and a SIGKILL skipped the EXIT-trap cleanup, it left one orphan DB (`…_bd82b0356333`) + a staging dir. Both were **manually removed and verified gone** (DB dropped, no grant, staging shredded) before the clean authoritative run above. No production object was ever touched by the aborted attempt.

## Bottom line

The 2026-10-27 encrypted backup is **proven restorable and document-consistent** against a disposable database, with the app-read pinned to the disposable DB and the document-reference verifier passing — all isolation and cleanup safeguards held, and production is byte-for-byte unchanged. This satisfies the restore-proof gate (R1) that the backup-DR release recommendation was conditioned on.

**STOP for independent ChatGPT review.**

# SCA — Backup Document-Consistency Fix `268c637`: FINAL VERIFICATION GATE

**Scope: read-only / non-destructive verification only. Nothing merged or deployed; no production backup created or restored; no database migration; no config change; no service restart; no integration activated. STOP for independent ChatGPT review.** 2026-10-26.

**Verdict: PASS — recommend MERGE (code-only) + deploy app+scripts together, gated on a separately-authorized restore-proof against current production data (R1).**

Branch `fix/sca-backup-document-consistency` head **`268c637`**; base = **`6022b75`** (current impl `main`). `git diff 6022b75..268c637` = 5 files, +629/−27. Prod untouched: app `3b30a0f`/migr138, DB `sca_krayin`.

This gate re-executes the earlier read-only review (`docs/SCA-OPTC-BACKUP-FIX-268C637-VERIFICATION.md`) as *active synthetic verification*: the reference-proof function was run against 11 hand-built mysqldump fixtures with no database touched.

---

## Task 1 — `verify_db_document_refs` validated against realistic MariaDB dump formats

Method: 11 synthetic `mysqldump`-shaped fixtures built offline (no DB), each a gzipped dump + a disposable document-source tree, fed to `verify_db_document_refs <db_sql_gz> <docsrc_root>` (copied from the branch; run in the scratchpad). Expected return codes: `0` pass, `5` non-canonical/traversal **or count-mismatch**, `6` missing referenced file, `8` corrupt/unreadable dump.

| # | Fixture (format exercised) | Expect | Got | Result |
|---|---|---|---|---|
| A | zero `local` refs (only `s3` rows present) | 0 | 0 | PASS |
| B | **multi-row extended** INSERT, 2 `local` rows, both files present | 0 | 0 | PASS |
| C | one-row-per-INSERT style, file present | 0 | 0 | PASS |
| D | **escaped values** (`\'`, commas) in a neighbouring column; `local` path present | 0 | 0 | PASS |
| E | **malformed path** — traversal `../../../etc/passwd` | 5 | 5 | PASS |
| F | canonical path but **referenced file missing** on disk | 6 | 6 | PASS |
| G | **corrupt gzip** dump | 8 | 8 | PASS |
| H | `local` row with **NULL / unquoted path** (count-mismatch) | 5 | 5 | PASS |
| I | **mixed disks** — `local` + `s3` rows; `local` present, `s3` ignored | 0 | 0 | PASS |
| J | `sca/generated/...` media path present | 0 | 0 | PASS |
| K | 2 `local` rows, **only one file present** (missing among many) | 6 | 6 | PASS |

**11 passed, 0 failed.** The function parses extended/multi-row inserts, ignores escaped values in other columns, scopes extraction to the `sca_media_assets` table, ignores non-`local` disks, and fails closed on traversal, missing files, and corrupt dumps. (Schema confirmed: column `storage_disk` immediately precedes `storage_path`, so the `'local','<path>'` adjacency the extractor relies on is correct.)

## Task 2 — extraction cannot silently omit a valid local reference

Proven by construction, not assertion. `verify_db_document_refs` counts `'local',` occurrences (`localcount`) and separately extracts quoted paths (`pathcount`); **`localcount != pathcount` → return 5 (fail closed)**. So any `local` row whose path the extractor cannot pull out as a canonical quoted string (NULL, unquoted, or malformed) is a mismatch, never a skipped row:

- Fixture **H** (a `local` row with a NULL/unquoted path) returns 5 — the row is *not* silently dropped.
- Fixture **K** (two `local` rows, one file absent) returns 6 — a missing document among many is detected, not averaged away.
- Every extraction command's exit status is checked via `PIPESTATUS`; only a clean grep "no match" (exit 1) is treated as the legitimate empty case — a read/parse error (≥2) and a corrupt dump (`gzip -t` fail) both fail closed, so "no references found" can never be a disguised read failure.

Combined with `snapshot_documents` (below), extraction is anti-omission on both sides: the DB side proves every dumped `local` ref is present, and the filesystem side fails closed if enumeration or copy drops anything.

## Task 3 — non-destructive syntax checks + synthetic self-tests

- `bash -n` (parse-only, no execution) on all three scripts from the branch: `backup-run.sh` **OK**, `lib-docsnapshot.sh` **OK**, `backup-verify-restore.sh` **OK**.
- `php -l` on `DocumentService.php` (prior round) — no syntax errors.
- The 11-fixture `verify_db_document_refs` run above is the synthetic self-test of the core logic.
- **Not run here (correctly deferred):** `backup-verify-restore.sh selftest` / `verify` create a *disposable database* and restore into it — those are DB operations, out of scope for this read-only gate and folded into the separately-authorized restore procedure (Task 6).

## Task 4 — atomic publication: failure handling + concurrent writes to the same final path

Write path (confirmed in `DocumentService.php`): every document write publishes to a `<final>.part` temp, then `Storage::disk->move($tmp,$final)` = `rename(2)` on the local same-filesystem adapter.

- **Failure handling (fail-closed):** if the `put`/`storeAs` to `.part` fails → delete temp, return false → caller throws (`attachToItem`) / propagates — no DB row, no partial final. If the `move` fails → delete temp, return false → throw. A file at its FINAL (non-`.part`) name is therefore always complete; a reader (including the backup snapshot) can never observe a half-written final file.
- **Concurrent writes to the *same* final path:**
  - `attachToItem` → final name = `bin2hex(random_bytes(20)).<ext>` → **unique per call**; no two concurrent uploads target the same final path, so no shared `.part`.
  - `putGenerated` → `sca/generated/<itemId>/bin2hex(random_bytes(20)).<ext>` → **unique per call**; same.
  - `restoreGeneratedMedia` → publishes to the media row's **fixed recorded `storage_path`**, so its temp `<storage_path>.part` is **shared** across two concurrent restores of the *same* media row. This is the only same-final-path case. In practice it is a rare, admin-serialized certificate-repair that rewrites verified-canonical bytes (same content), so even an interleaving yields a complete rename of correct bytes. **Flagged as minor hardening (not a blocker):** give the temp a per-writer-unique suffix (`.part.<rand>`) if concurrent same-row restores ever become possible.
- **Concurrent backup during a write:** `snapshot_documents` copies only non-`.part` files; because the final name appears only via atomic rename, the snapshot is consistent regardless of in-flight writes — the design intent.

Verdict: failure handling is fail-closed and correct; concurrency is safe for all real write paths, with one benign, serialized same-path case flagged for optional hardening.

## Task 5 — retention behaviour unchanged; no existing artifact deleted

`git diff 6022b75..268c637 -- scripts/backup-run.sh` touching any delete/retention token shows **only**:
- `rm -f "${OUT}.part"` — cleanup of the backup's *own* temp output (the new atomic-write of the artifact itself), plus its explanatory comment.

The retention/prune block is byte-identical to `main`: `RETAIN_DAYS=14`, `RETAIN_MIN=7`, and the `mapfile -t ALL < <(ls -1t … sca-backup-*.tar.gz.gpg)` → keep newest `RETAIN_MIN`, drop those older than `RETAIN_DAYS` loop is unchanged. **No existing backup artifact is deleted or re-globbed by this change.** (No `composer.json/lock`, `config/`, `.env`, `bootstrap/`, or migration change either.)

## Task 6 — safe restore-verification procedure (separately authorized; NOT run here)

To prove the new fail-closed path accepts current production data *before* relying on it:

1. Pick the latest on-host artifact `backups/sca-backup-<UTC>.tar.gz.gpg` (+ verify its `.sha256` sidecar).
2. Run `scripts/backup-verify-restore.sh selftest` (synthetic: encrypt → tamper-detect → restore a synthetic schema+triggers+rows into a disposable DB) — must PASS.
3. Run `scripts/backup-verify-restore.sh verify <artifact>` — decrypts with `secrets/backup.key`, restores the DB dump into a **disposable** database (the script's `guard_target` refuses the live `${MARIADB_DATABASE}`/`sca_krayin`) and the documents into a disposable directory; then runs `verify_db_document_refs` over the restored dump+docs.
4. Capture evidence: table/trigger/FK counts, app read (`items=3 state=3`, consistent with canonical provenance 3/3/4/4/5/2/1/1/7), `localcount==pathcount`, every referenced document present.
5. Drop the disposable DB; shred the staging.

These are DB operations on disposable targets only — **separately owner-authorized, never prod.** This is the gate that catches R1 (below) before a nightly could fail closed.

## Task 7 — rollback procedure if the updated backup fails against existing production data

Failure mode (R1): after deploy, the nightly `backup_document_stage` fails closed because a *pre-existing* prod `local` `storage_path` is non-canonical, or a DB-referenced document is missing on disk (`verify_db_document_refs` → 5/6), or `snapshot_documents` fails on a vanished source.

- **Detect first (preferred):** run the Task 6 restore-proof against current prod data *before* merge/deploy; if current data passes, R1 cannot trigger on existing data.
- **Rollback (if it fails post-deploy):** this fix is **code-only, no migration/schema** — rollback = `git revert` the merge (or controlled checkout of the three backup scripts to their pre-`268c637` / `6022b75` versions) and redeploy. The nightly then resumes the prior (pre-fix) behaviour. **No DB rollback is required** (nothing schema-level changed).
- The `DocumentService.php` atomic-write change is **forward-safe** and may remain even if the scripts are reverted (it only adds write-atomicity to new writes; it does not alter existing files, paths, DB rows, or reads). Reverting it too is harmless but unnecessary.
- Never `reset`/force-push shared `origin/main` backward; revert-forward only.

## Task 8 — exact test results, corrections, final recommendation

- **Test results:** `verify_db_document_refs` 11/11 synthetic fixtures PASS (A–K); `bash -n` clean on all three scripts; retention block byte-identical to main; atomic publication fail-closed and concurrency-safe (one benign serialized same-path case flagged).
- **Corrections required:** none to the fix. One **harness** correction was made during this gate (not a product defect): the first fixture builder mis-escaped single quotes inside a bash `$'…'` ANSI-C string, which corrupted the media INSERT line and produced three false failures; rebuilt with double-quoted SQL (literal `'` safe inside `"…"`) and a `printf`-based INSERT helper → 11/11. The library itself was proven correct by a direct extraction check (matched the line, counted the `'local',` occurrences, extracted the paths) before the harness was rewritten.
- **Optional hardening (non-blocking):** per-writer-unique `.part` suffix for `restoreGeneratedMedia`; housekeeping sweep of orphan `.part` files (R2).
- **Final recommendation: MERGE `268c637` → `main` as a standalone, code-only backup-DR hardening; deploy the `DocumentService.php` app change and the three scripts together; then run the Task 6 restore-proof against current prod data on a disposable DB BEFORE relying on the new nightly.** Releasable independently of Option C (`0f41e2e`) and the 139/140 incident (zero file overlap; no migration). Merging closes backup-release blocker **B5**; off-host durability (B1–B4) and restore-FROM-off-host (B6) remain separate.

### PASS / BLOCKED summary

| Task | Result |
|---|---|
| 1 Realistic dump formats | **PASS** (11/11 fixtures) |
| 2 No silent omission | **PASS** (count-mismatch guard; H & K) |
| 3 Syntax + synthetic self-tests | **PASS** (bash -n ×3; 11-fixture run) |
| 4 Atomic publication + concurrency | **PASS** (fail-closed; one benign serialized same-path case flagged) |
| 5 Retention unchanged / no artifact deleted | **PASS** (only `.part` temp cleanup added) |
| 6 Restore-verification procedure | **PREPARED** (separately authorized; not run) |
| 7 Rollback procedure | **PREPARED** (code-only revert-forward; no DB rollback) |
| 8 Results + recommendation | **PASS → MERGE, gate on restore-proof (R1)** |

**STOP — final verification delivered for independent ChatGPT review. Nothing merged, deployed, migrated, restored, reconfigured, restarted, or activated.**

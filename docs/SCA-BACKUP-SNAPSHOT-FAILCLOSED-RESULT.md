# SCA Backup — Snapshot Copy Fail-Closed Remediation (re-audit)

**Status:** Remediation of the re-audit finding on `c6fc97b` (snapshot copy fail-open), developed and
validated in an **isolated worktree + synthetic environment**. **NOT activated** — live app, backup
scripts, cron, DB and services unchanged. Awaiting ChatGPT independent re-audit. No merge, deploy,
production backup execution/restore, live-DB mutation, migration/rollback, restart, or live-tree checkout.

| | |
|---|---|
| Audit (changes requested) | gov `8ce68d4` (on candidate `c6fc97b`) |
| Candidate branch | `fix/sca-backup-document-consistency` |
| Previous head (audited) | `c6fc97bcc9f07013548d4b522554a340b6d16577` |
| **New candidate head** | **`77e40230524a7456b9d43198ac5351acb0a011aa`** |
| Change vs previous head | **scripts only**, 3 files, +74 / −10 (no app/ delta) |

## 1. The finding (accepted)
In `snapshot_documents()`, `cp -p "$src/$rel" "$dst/$rel" 2>/dev/null || true` discarded every copy
failure and continued. A genuine failure (disk-full, permissions, I/O) on a still-present published file
would omit that document, and because the manifest is derived from the same snapshot its checksum
agreement would not reveal the omission — a fail-open violating backup semantics.

## 2. The fix — explicit copy-outcome handling, fail-closed (`scripts/lib-docsnapshot.sh`)
Each copy outcome is now handled explicitly; nothing is masked:
- **cp succeeds** → the file is included (an immutable final file is complete).
- **cp fails AND the source still exists** → a genuine copy failure: the partial destination byte (if any)
  is removed, the **entire snapshot destination is deleted, and the function returns non-zero (FAIL
  CLOSED)**. `backup-run.sh` already treats a non-zero snapshot as `fail` (no `.gpg` is ever produced), so
  an incomplete snapshot can never be published as a successful backup.
- **cp fails AND the source has genuinely vanished** (`[ -e "$src/$rel" ]` is false) → **documented SKIP
  policy**: the file no longer exists at snapshot time, so the point-in-time snapshot correctly omits it
  (its `sca_media_assets` row, if any, is written only *after* publish, and `backup-run.sh` dumps the DB
  *before* snapshotting documents, so no restored DB row can reference a skipped file).
Additional hardening (no timing heuristic reintroduced):
- `mkdir -p` of each destination subdirectory is **checked** (failure → fail closed, cleaned up).
- A final **inventory check** requires the snapshot to contain **exactly** the number of files
  successfully copied — catching any silent omission structurally.
- `find -type f` matches regular files only; **symlinks** (`-type l`) are excluded and never
  copied/followed.
`backup-run.sh`'s failure message was corrected (it reflects a copy failure, not "source changing").

## 3. Deterministic fault-injection tests (`backup-verify-restore.sh doc-consistency-selftest`)
A `cp` shim placed first on `PATH` (in a subshell with a cleared command hash) fails deterministically for
marked files — no timing or racing process:
- **(D) copy failure while source present → FAIL CLOSED.** `FAILME.pdf` cannot be copied (source left
  intact). The snapshot returns non-zero (rc=5), **leaves no partial destination and retains no copied
  files**, and the still-present source is untouched.
- **(E) source vanished between enumeration and copy → SKIP per policy.** The shim deletes `VANISH.pdf`
  then fails the copy; the snapshot succeeds (rc=0), omits the vanished file, contains exactly the 5
  surviving finals, and those are archived and **restore-verified** (`sha256sum -c`).
Retained from the prior candidate: **(A)** a paused/incomplete `.part` is excluded and 20 finals
restore-verify; **(B)** the atomic-rename publication boundary (nothing exposed at a final name before the
rename, the complete file appears after); **(C)** 8 concurrent in-flight `.part` + 15 finals → exactly 15
archived & restore-verified. Full run: **`DOC-CONSISTENCY-SELFTEST PASS`** (A–E), exit 0; `bash -n` clean.

## 4. App layer unchanged (retained)
This commit is **scripts-only** (`git diff --stat c6fc97b..77e4023` = 3 scripts, no `app/`). The atomic
publication boundary in `DocumentService` (`publishAtomically`: `.part` temp → `Storage::move`/rename for
`putGenerated`, `restoreGeneratedMedia`, `attachToItem`), the `PART_SUFFIX` contract, the PHP
`BackupDocumentAtomicityTest`, and the full `tests/Feature/Sca` result (1409 passed / 1 skipped / 0 failed)
from `c6fc97b` are unchanged and stand (no app delta to re-exercise).

## 5. Safety / isolation
Separate git worktree at a non-mounted path; the host-only shell selftest ran against synthetic/disposable
data; live `kr-app` stayed on `main 6022b75` throughout; the worktree and its copied `.env` were removed;
live loopback `/admin/login` → 200.

## 6. Residual / unchanged
- **Not activated:** app + backup scripts must be deployed together under owner approval; until then the
  nightly runs the unfixed script (interim recovery point = the 2026-10-14T22:06Z restore-verified backup).
- **Off-host replication absent / owner-deferred → production release remains NO-GO.** Phase 2 candidate
  `dae6072` frozen; `main 6022b75` and migrations 139/140 untouched.

**STOP — awaiting ChatGPT independent re-audit of `77e4023`. No production change, backup execution/restore,
merge, deploy, migration, rollback, or DB mutation was performed.**

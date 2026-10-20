# SCA Backup — Vanished-File & Enumeration Fail-Closed (re-audit remediation)

**Status:** Remediation of the two re-audit findings on `77e4023`, developed and validated in an **isolated
worktree + synthetic environment**. **NOT activated** — live app, backup scripts, cron, DB and services
unchanged. Awaiting ChatGPT independent re-audit. No merge, deploy, production backup execution/restore,
live-DB mutation, migration/rollback, restart, or live-tree checkout.

| | |
|---|---|
| Audit (changes requested) | gov `43260e6` (on candidate `77e4023`) |
| Candidate branch | `fix/sca-backup-document-consistency` |
| Previous head (audited) | `77e40230524a7456b9d43198ac5351acb0a011aa` |
| **New candidate head** | **`1a22d8c8da5572232cf2f019f9a2207adf1932b6`** |
| Change vs previous head | **scripts only**, 2 files, +67 / −33 (no app/ delta) |

## 1. Findings (accepted)
1. **Vanished-file SKIP is unsafe.** `backup-run.sh` dumps the DB *before* snapshotting documents. A
   published file deleted *after* the dump would leave a dumped `sca_media_assets` row referencing a file
   the snapshot then skips → a restore with a dangling reference. Write-ordering only covers *creation*,
   not *deletion*. (Prior test E wrongly declared this a success.)
2. **Enumeration failure masked.** `while … done < <( … find … )` does not propagate the process-
   substitution `find` exit status, so a truncated/failed source enumeration could produce a partial
   snapshot that still passes the copied-count check.

## 2. The fix (`scripts/lib-docsnapshot.sh`) — fail closed by default
- **Disappearance → FAIL CLOSED (no skip).** Any `cp` failure — a genuine error (disk-full, permissions,
  I/O) *or* the source having disappeared after enumeration — removes the partial destination and returns
  non-zero. The documented policy states deletion cannot be safely tolerated without a **coordinated
  DB+document point-in-time snapshot** (shared lock/quiescence or a storage snapshot coordinated with the
  DB dump); that is out of scope, so the snapshot fails closed and the backup is retried next cycle. Write
  ordering is **not** relied upon.
- **Enumeration status captured and checked.** `find` now writes the null-delimited list to a temp file
  and its exit status is checked (`if ! ( cd "$src" && find … ) > "$listf"`); a failed/incomplete
  enumeration removes the temp list + destination and fails closed. The process-substitution that silently
  dropped the status is gone.
- **Hardening retained/added:** `mkdir -p` of each destination subdir is checked (fail closed); a final
  inventory check requires **copied == enumerated == files-present**; `find -type f` excludes symlinks;
  `.part` temp files are excluded; `backup-run.sh` treats a non-zero snapshot as `fail` so **no `.gpg`
  artifact is ever produced** from an incomplete snapshot (unchanged, confirmed).

## 3. Deterministic fault-injection tests (`backup-verify-restore.sh doc-consistency-selftest`)
`cp` and `find` shims (first on `PATH`, in a subshell with a cleared command hash) force failures
deterministically — no timing or racing process:
- **(D) copy failure, source present → FAIL CLOSED:** `FAILME.pdf` can't be copied (source intact); the
  snapshot returns non-zero, leaves no partial destination, retains no copied files, source untouched.
- **(E) [revised] disappearance after enumeration → FAIL CLOSED:** the shim deletes `VANISH.pdf` then
  fails the copy; the snapshot now **fails closed** (no partial destination, no dangling-row backup) —
  previously (incorrectly) a success.
- **(F) [new] enumeration failure → FAIL CLOSED:** a `find` shim fails the source enumeration (first arg
  `.`); the snapshot fails closed with no partial snapshot. (The destination defense-`find`, called with
  an absolute path, still uses the real `find`.)
- **(G) [new] destination mkdir failure → FAIL CLOSED:** a file pre-placed where a directory must be
  created makes `mkdir -p` fail; the snapshot fails closed, no partial destination.
Retained: **(A)** paused/incomplete `.part` excluded + 20 finals restore-verified; **(B)** atomic-rename
publication boundary; **(C)** 8 concurrent in-flight `.part` + 15 finals archived & restore-verified.
Full run: **`DOC-CONSISTENCY-SELFTEST PASS` (A–G)**, exit 0; `bash -n` clean.

## 4. App layer unchanged (retained)
Scripts-only commit (`git diff --stat 77e4023..1a22d8c` = 2 scripts, no `app/`). The atomic publication
boundary in `DocumentService` (`publishAtomically` for `putGenerated` / `restoreGeneratedMedia` /
`attachToItem`), the `PART_SUFFIX` contract, the PHP `BackupDocumentAtomicityTest`, and the full
`tests/Feature/Sca` result (1409 passed / 1 skipped / 0 failed) from `c6fc97b` are unchanged and stand.

## 5. Safety / isolation
Separate git worktree at a non-mounted path; host-only shell selftest on synthetic/disposable data; live
`kr-app` stayed on `main 6022b75`; worktree + copied `.env` removed; live loopback `/admin/login` → 200.

## 6. Residual / unchanged
- **Not activated:** app + backup scripts must deploy together under owner approval; interim recovery point
  = the 2026-10-14T22:06Z restore-verified backup.
- A future coordinated DB+document point-in-time snapshot would be needed to *tolerate* (rather than
  fail-closed on) a mid-backup deletion — noted as a possible follow-up, not required for fail-closed
  correctness.
- **Off-host replication absent / owner-deferred → production release remains NO-GO.** Phase 2 candidate
  `dae6072` frozen; `main 6022b75` and migrations 139/140 untouched.

**STOP — awaiting ChatGPT independent re-audit of `1a22d8c`. No production change, backup execution/restore,
merge, deploy, migration, rollback, or DB mutation was performed.**

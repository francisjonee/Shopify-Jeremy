# SCA Backup — Document-Archive Consistency Fix (design + isolated validation)

**Status:** Narrowly-scoped backup-reliability correction developed and validated in an **isolated
worktree + synthetic environment**. **NOT activated on production** — the live backup script and cron are
unchanged. Awaiting ChatGPT independent audit. No merge, deploy, production backup execution/restore,
live-DB mutation, migration/rollback, restart, or live-tree checkout was performed.

| | |
|---|---|
| Audit authorization | gov `bc93b3e` (NO-GO confirmed; backup-safety task) |
| Candidate branch | `fix/sca-backup-document-consistency` (from `main` `6022b75`) |
| **Candidate SHA** | **`4263f28ec38af88489ac1be7c893d2143d9abc56`** |
| Files | +1 new (`scripts/lib-docsnapshot.sh`), 2 edited (`scripts/backup-run.sh`, `scripts/backup-verify-restore.sh`); +126 lines |
| Production impact | none (candidate only; live `scripts/*` and `/etc/cron.d/sca-backup` untouched) |

## 1. Root cause (inspected, read-only)
The 2026-10-15 nightly failed: `tar: sca/generated: file changed as we read it` → `FAIL document archive
failed`. Investigation of the writers:
- Generated certificate PDFs are written by `DocumentService::putGenerated`
  (`app/packages/Sca/Provenance/src/Services/DocumentService.php:159`) to a **unique, random-named** path
  `sca/generated/{itemId}/{40-hex}.{ext}` via `Storage::disk('local')->put(...)`. The local Flysystem
  adapter writes **in place** (not tmp+rename). Existing files are **immutable** (unique names are never
  overwritten; `restoreGeneratedMedia` only rewrites a *missing* file to its recorded checksum). So only
  **brand-new files, while being written, are ever in flight.**
- `backup-run.sh` tarred the **live** tree (`tar -C app/storage/app … sca`) over several minutes and
  computed the integrity manifest by a **separate** `find … sha256sum` pass afterward. A concurrent
  certificate generation during the tar (a) makes tar exit 1 ("file changed as we read it") and could (b)
  capture a partially-written file, and (c) even on a clean tar the separate manifest pass could disagree
  with the archived bytes. **A clean tar exit therefore does not prove a consistent recovery point.**

**Explicitly rejected (per the audit):** suppressing the warning, `--ignore-failed-read`, or treating tar
exit 1 as success — any of these would ship a seemingly-successful but possibly-inconsistent archive.

## 2. The consistency mechanism (implemented)
`scripts/lib-docsnapshot.sh` → `snapshot_documents(src, dst, max_rounds=5, settle=2)`:
1. Bulk-copy the tree (`cp -a`, preserving size + mtime).
2. For **every copied file**, compare its `(size, mtime-with-nanoseconds)` to the **source** file. A match
   proves `cp` captured the file in its final, complete form (an in-flight write leaves the source a
   different size and/or a later mtime than the partial bytes `cp` read).
3. Re-capture any mismatching (in-flight) file and re-verify, in **bounded rounds**. Files that appeared at
   the source *after* the copy are **excluded** (a later point-in-time — the snapshot stays internally
   consistent); files deleted at the source after the copy are **kept** (they were complete when copied).
4. If any file never stabilises within the bounded rounds → **FAIL CLOSED** (non-zero return). The backup
   is never reported successful with a possibly-partial document.

This exploits the immutable-unique-name property and tolerates steady low-rate generation (new files
excluded, only a genuinely in-flight file triggers a cheap re-capture) without quiescing the live app or
requiring a filesystem snapshot — so **no live-app change and no owner-approved live change are needed.**

`scripts/backup-run.sh` now:
- archives the **static snapshot** (`tar -C ${WORK}/docsrc … sca`) — tar can no longer race a live write;
- derives `documents.sha256` from the **same** snapshot — archived bytes ≡ manifest **by construction**, so
  the existing restore-verifier's `sha256sum -c` document check is authoritative (this also closes the
  pre-existing tar-vs-separate-manifest gap);
- fails closed if a consistent snapshot cannot be captured.
The snapshot copy lives under the already-shredded `${WORK}` staging dir (existing EXIT trap `shred -u` +
`rm -rf`), so no plaintext document copy is left behind.

### Failure handling, atomic publication, integrity, restore-verification criteria
- **Failure handling:** unstable source → bounded retries → fail closed via the existing `fail()` (logs
  `FAIL`, exits non-zero); no partial snapshot dir is left.
- **Atomic publication:** unchanged and preserved — the single `.gpg` artifact is still published off-host
  atomically (stage `*.part` → promote) by `lib-offsite.sh`; the local `.gpg` + `.sha256` sidecar are
  written after a complete archive.
- **Integrity checks:** per-component SHA-256 in `MANIFEST.txt` + per-document `documents.sha256`, now
  computed from the archived snapshot.
- **Restore-verification criterion:** a backup is "good" only if `backup-verify-restore.sh` decrypts it,
  matches the DB component to the manifest, restores into a disposable DB, and **every document byte
  matches `documents.sha256`** — which now holds by construction.

## 3. Isolated validation (no DB, no key, no production)
New `scripts/backup-verify-restore.sh doc-consistency-selftest` mode (synthetic data, host-only). Run result:
```
== SCA document-snapshot CONSISTENCY selftest (synthetic, isolated) ==
  naive live-tar under concurrency exited 0 (non-zero = the race this fix removes)
  consistent snapshot archived: 44 files, every archived byte matches the manifest (restore-verifiable)
  perpetually-changing source failed closed (rc=1) with no partial snapshot — no false success
DOC-CONSISTENCY-SELFTEST PASS
```
- **(A) Concurrency → consistent archive:** with a background writer creating new unique files (some
  written in two chunks with a gap, modelling the in-flight race), the snapshot archive extracts and
  `sha256sum -c` matches every file; archive file-count == manifest file-count. Restore-verifiable.
- **(B) Fail-closed:** a source whose file is rewritten continuously (no gap) causes `snapshot_documents`
  to return non-zero and leave no partial snapshot — **no false success.**
- `bash -n` clean on all three scripts. (The naive-tar line is informational — the race is intermittent;
  the real 2026-10-15 nightly failure is the production evidence it occurs.)
NOTE: the full encrypt→restore pipeline was NOT re-run here because it would read the production DB / touch
the live backup store; the document-archiving change is the only delta and is fully covered by the
synthetic selftest, whose `sha256sum -c` is exactly the restore-verifier's document-integrity check.

## 4. Deferred / recommended (NOT implemented — would need separate authorization)
- **Writer-side atomic publish (defense in depth):** change `DocumentService::putGenerated` to write a temp
  file then `rename()` into place, so generated artifacts are published atomically at the source. This is
  an **app-code** change (a deploy to take effect) and is outside this backup-only task; the backup-side
  snapshot already makes the backup consistent without it. Recommend as a small future hardening.
- **Activation:** replacing the live `scripts/*` requires an owner-approved deploy of this candidate; until
  then the nightly continues to run the unfixed script (and may intermittently fail on the tar race, as on
  2026-10-15). A fresh restore-verified backup from 2026-10-14T22:06Z exists as the interim recovery point.

## 5. Residual release blockers (unchanged)
- **Off-host replication absent / owner-deferred** — no off-host recovery point; production release remains
  **NO-GO** regardless of this fix.
- This candidate must be independently audited, then (on approval) merged and deployed so the live cron runs
  the consistent-snapshot script; a post-activation nightly should be confirmed green and restore-verified.

**STOP — awaiting ChatGPT independent audit of `4263f28`. No production backup script change, no backup
execution/restore, no merge/deploy/migration/rollback/DB mutation. Phase 2 remains frozen; production
release remains NO-GO.**

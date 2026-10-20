# SCA Backup — Publication-Boundary Document Consistency (audit remediation)

**Status:** Remediation of the pre-merge audit finding on backup-consistency candidate `4263f28`, developed
and validated in an **isolated worktree + synthetic/ephemeral environment**. **NOT activated** — the live
application, backup scripts, cron, DB and services are unchanged. Awaiting ChatGPT independent re-audit.
No merge, deploy, production backup execution/restore, live-DB mutation, migration/rollback, restart, or
live-tree checkout was performed.

| | |
|---|---|
| Audit (changes requested) | gov `14c990a` (on candidate `4263f28`) |
| Candidate branch | `fix/sca-backup-document-consistency` |
| Previous head (audited) | `4263f28ec38af88489ac1be7c893d2143d9abc56` |
| **New candidate head** | **`c6fc97bcc9f07013548d4b522554a340b6d16577`** |
| Change vs previous head | 4 files, +125 / −88 (1 app service, 2 backup scripts, 1 new test) |
| Production impact | none (candidate only; live `app/`, `scripts/*`, `/etc/cron.d/sca-backup` untouched) |

## 1. The audit finding (accepted)
Matching file **size + mtime does not prove a write has completed** — a writer paused mid-write leaves a
static, partial file that the previous `snapshot_documents` heuristic could wrongly accept. A backup must
not depend on timing to decide completeness. Correct.

## 2. Correctness-first fix — an atomic PUBLICATION BOUNDARY (no timing)
**App (`DocumentService`):** every write to the private document disk now publishes **atomically** via a new
`publishAtomically($disk, $finalPath, $contents)` — bytes are written to a sibling `.part` temp and then
**atomically renamed** onto the final path (`Storage::move` → `rename(2)` on the local, same-filesystem
adapter). Applied to all three writers:
- `putGenerated` (certificate PDFs — the concurrent writer that caused the nightly failure),
- `restoreGeneratedMedia` (staff repair of a missing generated file),
- `attachToItem` (document uploads — `storeAs` to a `.part` then rename).
Consequence (structural, not probabilistic): **a file at its final (non-`.part`) name is ALWAYS complete**,
regardless of writer pauses; the only possibly-incomplete artifact is a `.part`. A new public constant
`DocumentService::PART_SUFFIX = '.part'` is the single declared boundary the backup excludes.

**Backup (`scripts/lib-docsnapshot.sh`):** `snapshot_documents()` now copies **only published (non-`.part`)
files — the size/mtime heuristic is removed entirely**. A copied final file is complete by the publication
boundary (and generated artifacts are immutable), a `.part` is never archived, a file that vanished
between enumeration and copy is skipped (a later state), and a defense-in-depth check fails closed if any
`.part` somehow reaches the snapshot. `backup-run.sh` is unchanged (it already archives this static
snapshot and derives the manifest from it, so archived bytes ≡ manifest).

The two changes form a contract and **must be deployed together** (the backup trusts that incomplete files
exist only at `.part` names, which the app now guarantees). Documented for the eventual authorized deploy.

**All writers to the backed-up `sca` tree assessed:** the private-disk writers are `putGenerated`,
`restoreGeneratedMedia` and `attachToItem` (all now atomic, above). The `public` disk (`sca-catalog`
images) is intentionally **excluded** from the backup (`backup-run.sh` archives only `app/storage/app/sca`),
and catalog/public writes are recovered from source, so they are out of scope. No other code writes under
`app/storage/app/sca`.

**DB-dump ↔ document cross-consistency:** `backup-run.sh` dumps the DB FIRST (`--single-transaction`,
point-in-time) and snapshots the documents SECOND. Because generated artifacts are immutable and only ever
added, every `sca_media_assets` row in the DB dump references a file that was published *before* the dump
and therefore still exists in the later document snapshot — so the restore never has a DB row pointing at a
missing file. The reverse (a file published in the gap between the dump and the snapshot whose row is not in
the dump) yields at worst an unreferenced file in the archive, which restore ignores. Ordering + immutability
thus give a consistent recovery point without quiescing the app.

## 3. Deterministic concurrency tests (the audit's core requirement)
`scripts/backup-verify-restore.sh doc-consistency-selftest` — rewritten to be **deterministic** (no racing
background process); synthetic data; no DB, key, or production:
- **(A) Paused/incomplete file excluded:** a `.part` holding partial bytes, left static (a paused write),
  is EXCLUDED; the 20 complete finals are archived and **every byte restore-verified** (`sha256sum -c`
  against the manifest derived from the same snapshot); the archive contains no `.part`.
- **(B) Publication boundary:** before the rename, nothing is exposed at the final name and the snapshot
  captures nothing; after the atomic rename, the complete file appears. 
- **(C) Many concurrent in-flight writes:** with 8 `.part` temps present alongside 15 complete finals, the
  snapshot archives exactly the 15 finals (all restore-verified) and excludes every `.part`.
New PHP `tests/Feature/Sca/BackupDocumentAtomicityTest`:
- `publishAtomically` exposes only a complete final file (sha matches input) with **no `.part` residue**;
- the excluded-suffix contract (`PART_SUFFIX === '.part'`) is asserted in sync.

**Results** (ephemeral container; connection target verified `TARGET_DB=sca_domain_test`; host-only for the
shell selftest): `DOC-CONSISTENCY-SELFTEST PASS` (A+B+C); `BackupDocumentAtomicityTest` 2 passed; full
`tests/Feature/Sca` **1409 passed / 1 skipped / 0 failed** (the atomic-publish change does not regress
certificate-PDF, document-upload, or restore flows). `bash -n` clean on all scripts; `php -l` clean.

## 4. Safety / isolation
Development used a separate git worktree at a non-mounted path and an ephemeral `sca-app` container on
`sca_internal`; the live `kr-app` bind-mount stayed on `main 6022b75` throughout (the live app never served
candidate code), the connection target was verified before tests, and the worktree (and its copied `.env`)
was removed afterward. Live loopback `/admin/login` → 200.

## 5. Residual / unchanged
- **Not activated:** replacing the live scripts AND deploying the app writer change requires an owner-
  approved deploy (together). Until then the nightly runs the unfixed script and may intermittently fail
  the tar race; interim recovery point = the 2026-10-14T22:06Z restore-verified backup.
- **Off-host replication absent / owner-deferred** → production release remains **NO-GO** irrespective of
  this fix. Phase 2 remains frozen; `main 6022b75` and migrations 139/140 untouched.

**STOP — awaiting ChatGPT independent re-audit of `c6fc97b`. No production change, backup execution/restore,
merge, deploy, migration, rollback, or DB mutation was performed.**

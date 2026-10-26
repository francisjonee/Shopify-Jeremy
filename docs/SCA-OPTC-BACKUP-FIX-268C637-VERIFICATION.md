# SCA — Backup Document-Consistency Fix `268c637`: READ-ONLY Verification

**Scope: read-only diff review only. Nothing merged/deployed; no backup/restore, no config change, no rclone install, no credential/prod change, no migration/restart/activation.** 2026-10-26. Verdict: **PASS — releasable independently; recommend MERGE + deploy (owner-authorized), gated on a restore-proof run.**

Branch `fix/sca-backup-document-consistency` head **`268c637`**; base = **`6022b75`** (merge-base(6022b75, branch) == `6022b75`, so the branch sits directly on current main — `git diff 6022b75..268c637` is the exact, clean net diff). 6 commits: consistent-snapshot → atomic publication boundary → fail-closed snapshot copy → fail-closed vanished-file/enumeration → empty-archive fail-open removed + prove-refs-present → canonical grammar + extraction-status checks.

## 1 & 4. Exact files changed (5; +629 / −27) and deployment risks

| File | ± | Kind |
|---|---|---|
| `app/packages/Sca/Provenance/src/Services/DocumentService.php` | +50/−… | **App** (document write path only) |
| `app/tests/Feature/Sca/BackupDocumentAtomicityTest.php` | +54 | New test |
| `scripts/backup-run.sh` | +70 | Backup script (snapshot + verify integration) |
| `scripts/backup-verify-restore.sh` | +264 | Restore-proof + selftests |
| `scripts/lib-docsnapshot.sh` | +218 | New lib (`snapshot_documents`, `verify_db_document_refs`) |

**No migration, no production schema, no `composer.json/lock`, no `config/`, no `.env`, no `bootstrap/` change. Retention logic unchanged** (the only `rm` added in `backup-run.sh` is `rm -f "${OUT}.part"` — cleanup of the backup's own temp; `SCA_BACKUP_RETAIN_DAYS/MIN` untouched).

Deployment risks (flagged; none a blocker):
- **R1 (primary):** the new `verify_db_document_refs` **fails the backup closed** if any existing `local` `storage_path` in prod is non-canonical or its file is missing. This is the intended safety behavior, but to avoid a nightly suddenly failing, run `backup-verify-restore.sh verify` against current prod data FIRST (restore-proof) to confirm live data passes the new gate.
- **R2:** an interrupted write can leave a `.part` orphan on the private disk (harmless — excluded from both backup snapshot and app reads; optional housekeeping).
- **R3:** atomic rename assumes the local, same-filesystem `local` disk (true today; revisit before any S3 migration).
- **R4:** `DocumentService.php` is an app-code change → a normal app deploy (loopback app); the scripts are a file copy. No service restart required.

## 2. No unexpected application-logic / schema / retention change

The ONLY application change is in `DocumentService.php` and is narrow and intentional: document writes (`attachToItem`, `putGenerated`, `restoreGeneratedMedia`) now publish via a `.part` temp + `Storage::move` (rename) instead of a direct `put`/`storeAs`. The **final storage path layout is identical** (`sca/documents/<itemId>/<name>`, `sca/generated/<itemId>/<name>`), the recorded `storage_path`/checksum/DB rows are unchanged, and document **reads, routes, ACL, controllers, and all Option C logic are untouched**. No behavior change beyond write atomicity. (Verified: no other `app/` file changed.)

## 3. Atomic publication, snapshot consistency, fail-closed — all confirmed

- **Atomic publication:** `DocumentService::publishAtomically($disk,$final,$contents)` writes `<final>.part` then `Storage::move($tmp,$final)` — `rename(2)` on the local same-filesystem adapter, so a file at its FINAL (non-`.part`) name is always complete; on any failure the temp is deleted and nothing is published (returns false → caller throws). All three write paths use it; `PART_SUFFIX='.part'` is excluded by the backup.
- **Snapshot consistency (`snapshot_documents`):** enumerates only PUBLISHED files (`find -type f ! -name '*.part'`) into a temp list so `find`'s exit status is captured — an **enumeration failure fails closed** (no partial set). Each file is `cp -p`'d; a `cp` failure for ANY reason — I/O, permissions, OR the source having DISAPPEARED after enumeration — **fails closed** (the deletion window between DB dump and doc copy is closed, not skipped). A post-copy check fails closed if any `.part` leaked into the destination. Symlinks (`-type l`) are excluded (never copied/followed).
- **Fail-closed reference proof (`verify_db_document_refs`):** validates the gzipped DB dump (`gzip -t` → corrupt dump fails closed, never read as "no references"); extracts every `storage_disk='local'` row's `storage_path` with each extraction command's status checked (only grep "no match"/exit 1 is the legitimate empty case; a read/processing error ≥2 fails closed); validates each path against an anchored, **traversal-free canonical grammar** and rejects a non-canonical/`..`/absolute path BEFORE any filesystem probe (containment by grammar, not by probe); then proves every referenced file is present in the snapshot. Returns 0 only iff every dumped `local` ref is canonical AND present (0 refs ⇒ pass); non-zero on corrupt dump, any read/parse error, non-canonical/traversing path, or any missing file. Only the private `local` disk is in backup scope.

## 5. Independent of Option C and the 139/140 incident — yes

- **Disjoint from Option C:** `268c637` touches `DocumentService.php` + backup scripts + 1 test; Option C (`1df81d5`/`0f41e2e`) touches claim/fulfillment/grant services, controllers, views, ACL, routes, and migration `2026_10_23_000001` — **zero file overlap**. Both branch directly off `6022b75`.
- **No migration → 139/140 untouched:** `268c637` adds no migration and no schema change, so it cannot affect migration history or the batch-27 incident.
- Therefore `268c637` can be merged and deployed **standalone**, in either order relative to Option C, without entangling the 139/140 decision.

## 6. Merge / deployment recommendation (for owner approval — NOT executed)

**Recommend: MERGE `268c637` to `main` as a standalone backup-DR hardening (code-only), then deploy, then prove restore — all owner-authorized, independent of Option C and 139/140.** Sequence:
1. Merge `268c637` → `main` (clean fast-forward/merge off `6022b75`; no migration).
2. Deploy together: the `DocumentService.php` app change + the three backup scripts (so the atomic writer and the consistent-snapshot/verify match).
3. **Gate — restore-proof before relying on it:** run `backup-verify-restore.sh selftest` (synthetic) and `backup-verify-restore.sh verify` against a current artifact (restore to a DISPOSABLE DB) to confirm current prod data passes the new fail-closed `verify_db_document_refs` (catches R1 before a nightly fails). These are DB operations on disposable targets — separately authorized, never prod.
4. This closes blocker **B5** from the backup-release preflight; off-host (B1–B4) and the restore-FROM-off-host proof (B6) remain separate.

## PASS / BLOCKED summary

- [1] Exact diff inspected (5 files, +629/−27, based on 6022b75) — **PASS**.
- [2] No unexpected app-logic / no schema / no retention change — **PASS** (one narrow, intended document-write-atomicity change in `DocumentService.php`; flagged).
- [3] Atomic publication + snapshot consistency + fail-closed verify — **PASS** (all three confirmed).
- [4] Files + deployment risks identified (R1–R4) — **PASS** (R1 = run restore-proof first).
- [5] Releasable independently of Option C and 139/140 — **PASS**.
- [6] Merge/deploy recommendation prepared — **PASS** (merge → deploy → restore-proof gate).

**STOP — read-only verification delivered for independent ChatGPT review. Nothing merged/deployed; no backup/restore/config/rclone/credential/migration/restart/activation.**

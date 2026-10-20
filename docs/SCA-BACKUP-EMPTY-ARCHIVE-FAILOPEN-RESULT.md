# SCA Backup — Empty-Archive Fail-Open & DB→Document Deletion Window (re-audit remediation)

**Status:** Remediation of the two re-audit findings on `1a22d8c` (gov `6202edc`), developed and validated
in an **isolated worktree + synthetic environment**. **NOT activated** — live app, backup scripts, cron,
DB and services unchanged. Awaiting ChatGPT independent re-audit. No merge, deploy, production backup
execution/restore, live-DB mutation, migration/rollback, restart, or live-tree checkout.

| | |
|---|---|
| Audit (changes requested) | gov `6202edc` (on candidate `1a22d8c`) |
| Candidate branch | `fix/sca-backup-document-consistency` |
| Previous head (audited) | `1a22d8c8da5572232cf2f019f9a2207adf1932b6` |
| **New candidate head** | **`0f386266bf34d436b9a61d4271abf26953640163`** |
| Change vs previous head | **scripts only**, 3 files, +238 / −23 (no `app/` delta) |

## 1. Findings (accepted)
1. **Caller-level empty-archive fail-open.** `backup-run.sh` decided whether documents existed with
   `if [ -d "$DOCS_DIR" ] && [ -n "$(find "$DOCS_DIR" -type f -print -quit 2>/dev/null)" ]; then … else
   …empty archive… fi`. The command substitution collapsed a **failed** `find` (permission/I/O, also
   swallowed by `2>/dev/null`) and a **genuinely empty** corpus into the same empty-string result, so an
   enumeration failure (or a tree emptied by deletion) could take the `else` branch and publish a
   **successful empty document archive** while the dumped DB still referenced documents. `snapshot_documents()`
   was never even called in that branch, so its fail-closed enumeration could not help.
2. **DB-dump→document-inventory deletion window.** The DB is dumped first and documents snapshotted
   second. `snapshot_documents()` only fails closed on a file that disappears **after** its own
   enumeration begins; a file already deleted **before** enumeration is simply never enumerated, leaving a
   dumped row that references a file absent from the archive. Write-ordering covers creation, not deletion.

## 2. The fix (`scripts/lib-docsnapshot.sh`, `scripts/backup-run.sh`)
- **Pre-probe removed; one explicitly-checked decision path.** `backup-run.sh` now calls a single shared
  function `backup_document_stage <docs_dir> <work_dir> <db_sql_gz>` (used **verbatim** by the selftest, so
  tests exercise the real decision, not a reimplementation). It performs, each fail-closed: (1) one checked
  snapshot via `snapshot_documents()` (enumeration via temp-list with checked `find` exit, copy, mkdir and
  `copied==enumerated==present` inventory); (2) the reference proof below; (3) archive the static snapshot
  and derive the manifest from the **same** snapshot. ANY inability to establish the inventory fails the
  whole backup. An existing-but-empty tree is represented as empty **only after a successful, complete
  enumeration** — a `find` failure and an empty corpus can no longer be conflated. A non-numeric stage
  result also fails closed.
- **DB→document reference integrity (`verify_db_document_refs`).** Proves every **private-disk** (`local`)
  document reference recorded in the **just-dumped** DB is present as a file in the snapshot, closing the
  deletion window. Mapping verified against `DocumentService` + `config/filesystems.php`: private docs live
  on the `local` disk (root `storage/app`) at `storage_path = sca/{documents|generated}/<id>/<40hex>.<ext>`;
  the snapshot copies `storage/app/sca` → `<docsrc>/sca`, so a row's file is `<docsrc>/<storage_path>`.
  Extraction is **table-scoped** (only `INSERT INTO \`sca_media_assets\` VALUES` lines) and relies on the
  server-generated **safe charset** (no quote/comma/backslash) and on `'local'` appearing **only** as
  `storage_disk`. Fail-closed on: a corrupt dump (`gzip -t`), a decompress or `grep` **read** error
  (gzip/grep exit captured via `PIPESTATUS`), a **parse ambiguity** (a `local` row whose path is not an
  `sca/` path → `localcount != pathcount`), or **any missing referenced file**. Only the private disk is in
  backup scope; references on other disks (e.g. public catalog images) are not required and are ignored.
  The media model is append-only/immutable (store-then-row with compensating cleanup; **no** code path
  DELETEs a committed `sca_media_assets` row or its file — confirmed by source inspection), so normal runs
  always pass; the check guards **out-of-band** removal/corruption and mid-backup deletion.
- **Honest limitation.** This is the auditor's option B ("a reliable check that every dumped database
  document reference exists in the archived snapshot"), **not** a coordinated point-in-time DB/document
  quiescence protocol. It proves no dumped reference is missing from the archive; it does not globally
  freeze the two. Given the append-only model and the now-closed deletion window, this is sufficient for
  **fail-closed correctness** (a would-be dangling-reference backup becomes a retried one). It does not by
  itself change the release verdict: **off-host recovery remains absent → production release NO-GO.**
- **Other runner fail-open paths hardened.** Manifest component checksums are computed into **checked**
  variables (a failed `sha256sum` fails the backup instead of embedding an empty/garbage hash);
  `documents.sha256.txt` copy is checked. The encrypted artifact is published **atomically** to a local
  `*.part` whose checksum is taken before an atomic `rename` to the final name — an interrupted/failed
  encryption can leave only a `*.part` (swept by the cleanup trap; never matched by the
  `sca-backup-*.tar.gz.gpg` retention/restore glob), never a final-named artifact treated as complete. The
  DB-dump pipe, `gzip -t`, dump-header grep, disk-space guard, and off-site publish (stage→promote) were
  already fail-closed and are retained; `set -euo pipefail` is preserved and the fragile extraction uses a
  bounded `set +e` region with explicit status capture.

## 3. Deterministic tests (`backup-verify-restore.sh doc-consistency-selftest`) — synthetic, isolated
Tests **H–K run through the actual decision path** (`backup_document_stage`) with a synthetic gzipped
`db.sql.gz` standing in for the dump (no DB, key, or production):
- **(H) positive end-to-end:** a consistent snapshot whose every `local` reference is present → stage
  **succeeds**, count excludes an in-flight `.part`, a **public-disk** reference to a non-existent file is
  (correctly) not required, and the archive **restore-verifies** (`sha256sum -c`).
- **(I) deletion window:** a dump referencing a `local` file absent from the tree → the reference proof
  finds it missing → the whole stage **fails closed** (rc 12). No dangling-reference backup.
- **(J) enumeration failure in the real path:** a `find` shim fails the source enumeration → stage **fails
  closed** (rc 11) and **no documents archive is produced** (the old probe would have written a valid empty
  one here).
- **(K) genuinely empty tree:** an existing empty root + a dump with zero media rows → stage **succeeds**
  only after a successful complete enumeration (count 0, valid empty archive). The empty-tree
  enumeration-failure case is covered by (J).
Retained: **(A)** paused `.part` excluded + 20 finals restore-verified; **(B)** atomic-rename boundary;
**(C)** 8 concurrent in-flight `.part` + 15 finals restore-verified; **(D)** copy-fail/source-present →
fail closed; **(E)** disappearance after enumeration → fail closed; **(F)** enumeration failure → fail
closed; **(G)** mkdir failure → fail closed. Direct edge checks of `verify_db_document_refs` (corrupt dump
→ fail; non-`sca/` `local` path → fail; consistent → pass) also pass.
Full run: **`DOC-CONSISTENCY-SELFTEST PASS` (A–K)**, exit 0; `offsite-selftest` PASS; `bash -n` clean on all
three scripts (shellcheck not installed on host).

## 4. App layer unchanged (retained)
`git diff --stat 1a22d8c..0f38626` = 3 scripts, **no `app/`**. The atomic publication boundary in
`DocumentService` (`publishAtomically` for `putGenerated` / `restoreGeneratedMedia` / `attachToItem`), the
`PART_SUFFIX` contract, the PHP `BackupDocumentAtomicityTest`, and the full `tests/Feature/Sca` result
(1409 passed / 1 skipped / 0 failed) from `c6fc97b`/`1a22d8c` are byte-identical and stand.

## 5. Safety / isolation
Separate git worktree at a non-mounted path (`/opt/sca-platform-cand-backup`, removed after); host-only
shell selftest on synthetic/disposable data; live `kr-app` stayed on `main 6022b75`; live loopback
`/admin/login` → 200. No throwaway `.env` was committed.

## 6. Residual / unchanged
- **Not activated:** app + backup scripts must deploy together under owner approval; interim recovery point
  = the 2026-10-14T22:06Z restore-verified backup.
- The reference check is a fail-closed integrity proof, **not** a coordinated DB/document point-in-time
  snapshot. A future quiescence/storage-snapshot protocol would be needed to *tolerate* (rather than
  fail-closed on) a mid-backup deletion — noted as a possible follow-up, not required for correctness.
- **Off-host replication absent / owner-deferred → production release remains NO-GO.** Phase 2 candidate
  `dae6072` frozen; `main 6022b75` and migrations 139/140 untouched.

**STOP — awaiting ChatGPT independent re-audit of `0f38626`. No production change, backup execution/restore,
merge, deploy, migration, rollback, or DB mutation was performed.**

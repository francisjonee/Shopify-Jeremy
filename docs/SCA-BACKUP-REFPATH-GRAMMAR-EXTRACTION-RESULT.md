# SCA Backup — Reference-Path Grammar Containment & Extraction-Status Fail-Closed (re-audit remediation)

**Status:** Remediation of the two re-audit findings on `0f38626` (gov `b6ac62e`), developed and validated
in an **isolated worktree + synthetic environment**. **NOT activated** — live app, backup scripts, cron,
DB and services unchanged. Awaiting ChatGPT independent re-audit. No merge, deploy, production backup
execution/restore, live-DB mutation, migration/rollback, restart, or live-tree checkout.

| | |
|---|---|
| Audit (changes requested) | gov `b6ac62e` (on candidate `0f38626`) |
| Candidate branch | `fix/sca-backup-document-consistency` |
| Previous head (audited) | `0f386266bf34d436b9a61d4271abf26953640163` |
| **New candidate head** | **`268c637503883007622c58a94232fcc9d05dfe1f`** |
| Change vs previous head | **scripts only**, 2 files, +102 / −24 (`lib-docsnapshot.sh`, `backup-verify-restore.sh`; `backup-run.sh` unchanged this round) |

## 1. Findings (accepted)
1. **A malformed `storage_path` could escape the snapshot root.** `verify_db_document_refs()` extracted
   paths with `'local','sca/[A-Za-z0-9._/-]+'` — a class that permits `..` segments — and then only tested
   `[ -f "$root/$p" ]`, which **follows traversal**. A dumped local row such as `sca/../../../../etc/passwd`
   could resolve to a regular file **outside** `$root` and be counted "present", so a reference whose
   document is NOT in the archive could pass — contradicting the stated proof and the fail-closed claim.
2. **Second-stage extraction statuses were not checked.** The later `grep "'local',"` and
   `grep "'local','…'" | sed` ran inside a broad `set +e` with their statuses discarded. If both reads
   **errored** before producing output, both count files are empty (`localcount == pathcount == 0`) and the
   verifier returned success despite being unable to establish the inventory.

## 2. The fix (`scripts/lib-docsnapshot.sh`)
- **Canonical-grammar containment gate.** The exact grammar `DocumentService` emits was re-confirmed
  against source: the only private-disk writers are `attachToItem`
  (`storeAs('sca/documents/'.$itemId, bin2hex(random_bytes(20)).'.'.$ext)`) and `putGenerated`
  (`'sca/generated/'.$itemId.'/'.bin2hex(random_bytes(20)).'.'.$ext`); `restoreGeneratedMedia` reuses an
  existing row's path; `$ext ∈ {pdf,jpg,jpeg,png}`. So every legitimate `storage_path` matches
  **`^sca/(documents|generated)/[0-9]+/[0-9a-f]{40}\.(pdf|jpg|jpeg|png)$`** — a fixed, **traversal-free**
  form (no `.`/`..` component, no absolute path). Each extracted `local` path is now validated against this
  grammar **before any filesystem probe**; a non-canonical/traversing/absolute path is **rejected, fail
  closed** (return 5). Defence in depth, independent of the regex: an absolute path or any `.`/`..` path
  component is also rejected explicitly. Containment is therefore established by the grammar, not by the
  `sca/` prefix or the safe-character set. The extractor now captures `'<disk>','<anything-but-quote>'`, so
  a malformed/traversing path is **captured and explicitly rejected** rather than silently dropped.
- **Every extraction-stage status captured and checked.** The local-count `grep` status is captured
  immediately (`gc1=$?`); the path-extraction `grep | sed` statuses are captured together via
  `PIPESTATUS`. Only grep **"no match" (exit 1)** — a genuinely empty / no-local-row table — is permitted;
  a grep/sed **read or processing error** (`>=2`, or non-zero `sed`) cleans the temp files and returns
  non-zero (8). An extraction that produces no output **because it errored** can no longer be mistaken for
  "zero references". The initial `gzip -dc | grep` pipeline already captured both statuses and is retained.
- The `localcount == pathcount` guard (every `local` row yields exactly one path token), the per-file
  presence check, symlink exclusion in the snapshot, and the append-only-model rationale are retained. The
  guarantee remains **option B** (a reference-integrity proof), **not** a coordinated point-in-time
  quiescence protocol — sufficient for fail-closed correctness; it does not by itself change the verdict.

## 3. Deterministic tests (`backup-verify-restore.sh doc-consistency-selftest`) — synthetic, isolated
Added, through the real decision path / verifier:
- **(L) path traversal + near-misses:** a dumped `local` path `sca/../../OUTSIDE/secret.pdf` targeting a
  **real file created outside the snapshot root** → `backup_document_stage` **fails closed** (rc 12) and
  leaves **no `documents.tar.gz`**; the test asserts the escape target exists (so the pre-fix `[ -f ]`
  would have wrongly accepted it). Near-miss non-canonical forms (`…​.exe`, `sca/other/…`, no extension,
  missing id segment, `etc/passwd`) are each rejected by the verifier.
- **(M) extraction-stage read error:** a `grep` shim fails the extraction greps (keyed on `-oaE`, which
  only the extraction uses — the table-isolation grep uses `-a` and the grammar gate uses bash `[[ =~ ]]`),
  producing no output with an error status → **fail closed** (rc 12), **no archive** — proven (trace) to
  reach the extraction only after the isolation grep succeeds, i.e. not a false "0-reference" pass.
Existing **A–K updated to canonical 40-hex storage names** (the grammar is now enforced): **A** paused
`.part` excluded + restore-verify; **B** atomic-rename boundary; **C** concurrent in-flight; **D** copy-fail
/ source present; **E** disappearance after enumeration; **F** source enumeration failure; **G** mkdir
failure; **H** positive end-to-end + other-disk ref ignored + restore-verify; **I** deletion window; **J**
enumeration failure in the real path (no empty archive); **K** genuinely empty tree.
Full run: **`DOC-CONSISTENCY-SELFTEST PASS` (A–M)**, exit 0; `offsite-selftest` PASS; `bash -n` clean on all
three scripts. A separate trace confirmed the verifier **passes** a consistent dump and **fails closed (8)**
only when the extraction grep errors.

## 4. App layer unchanged (retained)
`git diff --stat 0f38626..268c637` = 2 scripts, **no `app/`** (`backup-run.sh` also unchanged this round).
The atomic publication boundary in `DocumentService`, the `PART_SUFFIX` contract, the PHP
`BackupDocumentAtomicityTest`, and the full `tests/Feature/Sca` result (1409 passed / 1 skipped / 0 failed)
from `c6fc97b`/`1a22d8c` are byte-identical and stand.

## 5. Safety / isolation
Separate git worktree at a non-mounted path (`/opt/sca-platform-cand-backup`, removed after); host-only
shell selftest on synthetic/disposable data; live `kr-app` stayed on `main 6022b75`; live loopback
`/admin/login` → 200. No throwaway `.env` was committed.

## 6. Residual / unchanged
- **Not activated:** app + backup scripts must deploy together under owner approval; interim recovery point
  = the 2026-10-14T22:06Z restore-verified backup.
- Reference check is a fail-closed integrity proof, **not** a coordinated DB/document point-in-time
  snapshot (a future quiescence/storage-snapshot protocol remains a possible follow-up, not required for
  fail-closed correctness).
- **Off-host replication absent / owner-deferred → production release remains NO-GO.** Phase 2 candidate
  `dae6072` frozen; `main 6022b75` and migrations 139/140 untouched.

**STOP — awaiting ChatGPT independent re-audit of `268c637`. No production change, backup execution/restore,
merge, deploy, migration, rollback, or DB mutation was performed.**

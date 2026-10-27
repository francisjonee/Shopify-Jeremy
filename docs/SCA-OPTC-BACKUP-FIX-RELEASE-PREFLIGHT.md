# SCA — Backup Fix: Final Release Preflight (READ-ONLY)

**Scope: read-only preflight only. Nothing merged, deployed, restarted, migrated, reconfigured; no backup created. STOP for explicit owner approval before release execution.** 2026-10-27.

**GO/NO-GO: GO to merge + coordinated deploy (owner-executed), code-only, standalone.** The restore-proof (R1) passed on 2026-10-27; the delta is exactly the intended backup-hardening files with no migration/dependency/config change; rollback is a code-only revert with no DB impact.

## [1] SHAs

| Ref | SHA |
|---|---|
| impl `origin/main` = local `main` = working-tree HEAD (clean) | `6022b75c021069bde332b4a10cd5806ae9065aaf` |
| backup-fix branch `fix/sca-backup-document-consistency` (local == origin) | `95c15d3f5dde1162f6ede442b87a007b87835ccd` |
| `merge-base(main, branch)` | `6022b75` ⇒ branch sits **directly on current main**; clean merge; `diff main..branch` == the standalone delta |

Live-code mechanism (unchanged finding): `kr-app` bind-mounts `/opt/sca-platform/app` rw as its docroot, and the working tree is `main 6022b75` — so the live app code already equals `main`. Merging advances main by exactly the delta below, and no other change reaches production.

## [2] Standalone diff contains only the intended backup-hardening changes — CONFIRMED

`git diff --stat 6022b75..95c15d3` = **6 files, +877 / −57**:

| File | Kind |
|---|---|
| `app/packages/Sca/Provenance/src/Services/DocumentService.php` (+50) | **App** — document-write atomicity only (`.part` temp → `Storage::move` rename; final path/DB rows/reads/ACL unchanged) |
| `app/tests/Feature/Sca/BackupDocumentAtomicityTest.php` (+54, new) | Test |
| `scripts/backup-run.sh` | Nightly — consistent snapshot + fail-closed doc-ref verify |
| `scripts/lib-docsnapshot.sh` (+218, new) | `snapshot_documents` + `verify_db_document_refs` |
| `scripts/backup-verify-restore.sh` | Restore-proof + selftests + safety corrections |
| `scripts/test-restore-verify-safety.sh` (+125, new) | Mocked safety tests (no real DB) |

**No migration, no `composer.json/lock`, no `config/`, no `bootstrap/`, no `.env`, and no app logic beyond the single document-write-atomicity change** (verified by name filter). 8 commits (`4263f28`→`95c15d3`). Retention logic in `backup-run.sh` unchanged (only `rm -f "${OUT}.part"` added).

## [3] Recovery & rollback

- **Recovery capability (already proven):** `scripts/backup-verify-restore.sh verify <artifact>` restores to a disposable DB and now also re-proves document-reference consistency — exercised 2026-10-27, PASS (`docs/SCA-OPTC-BACKUP-RESTORE-VERIFICATION-RESULT.md`).
- **Rollback of this release (code-only; NO DB rollback):** the delta introduces **no migration/schema**, so rollback = restore the 6 files to their `6022b75` state and re-advance the live working tree:
  1. On origin: `git revert -m 1 <merge-commit>` (or reset the deploy to the pinned prior SHA `6022b75`), push.
  2. On host: `scripts/deploy-preview.sh` again (it `git reset --hard origin/main`), then the graceful reload below.
  - `DocumentService.php`'s atomic write is **forward-safe** (only adds write atomicity; never alters existing files, paths, DB rows or reads), so it may remain even if the scripts are reverted; no data migration is involved either way.
  - Never `reset`/force-push shared `origin/main` backward — revert-forward only.

## [4] Exact merge + coordinated deployment steps (owner-executed; includes PHP/opcache reload)

```bash
# A. MERGE (git host) — standalone, code-only, no migration
cd /opt/sca-platform && git fetch origin
git checkout main && git merge --no-ff 95c15d3 -m "Merge backup document-consistency + restore-verify hardening (95c15d3)"
git push origin main           # new main = 6022b75 + the 6-file delta only

# B. COORDINATED DEPLOY (host) — advances BOTH app/ (DocumentService.php) and scripts/ (nightly + restore tooling) together
scripts/deploy-preview.sh      # git reset --hard origin/main; composer install (no-op, no dep change);
                               # feature suite vs sca_domain_test; chown 33:33 storage/cache;
                               # `php artisan migrate --force` == NO-OP (this delta adds no migration);
                               # config:clear / route:clear

# C. REQUIRED PHP/opcache reload — deterministic pickup of the changed DocumentService.php (zero-downtime worker reload, NOT a container restart)
docker exec kr-app apachectl -k graceful
```

Notes:
- opcache is `enable=On, validate_timestamps=On, revalidate_freq=2`, so the changed file would refresh within ~2 s anyway; the `apachectl -k graceful` makes it immediate and deterministic and drops no connections.
- The atomic writer (`DocumentService.php`) and the consistent-snapshot/verify (`backup-run.sh` + `lib-docsnapshot.sh`) ship in the **same** `reset --hard`, so they go live together — no window where one is deployed without the other.
- `migrate --force` in the deploy script targets prod `sca_krayin` but is a **no-op** here because the delta introduces no migration (139/140 already batch 27; nothing pending). This is the only prod-DB touch and it changes nothing.

## [5] Post-deployment health checks + first backup validation

Immediately after C:
1. **App serves:** `curl -sS -o /dev/null -w '%{http_code}\n' https://verify.secondchanceauthenticators.com/` → `200`; spot-check a public passport renders (no white error page ⇒ `DocumentService.php` loaded cleanly).
2. **No regression in document reads:** open an existing certificate/passport that streams a stored document → loads (reads use the unchanged final path layout).
3. **First backup validation (the real gate):** the **next nightly** (`backup-run.sh`, 03:17 UTC) now runs the new snapshot + `verify_db_document_refs` stage. Confirm `backups/backup.log` shows `OK … docs=<n>` with no `verify`/snapshot failure. Because R1 was cleared (current prod data passes the fail-closed gate), this should succeed; a failure would log fail-closed and produce **no** artifact → investigate the offending `storage_path`/missing file before relying on it. (Owner may, under separate authorization, run one manual `backup-run.sh` to validate immediately rather than wait for cron — that creates a backup, so it is out of scope here.)
4. **End-to-end restore of the first NEW artifact:** once a post-deploy artifact exists, run `scripts/backup-verify-restore.sh verify <new-artifact>` (disposable DB; see [6] safeguards). Expect `RESTORE VERIFICATION PASS` incl. `document-reference verification OK`.

## [6] Safeguards: never force-kill verification; identifying orphan disposable databases

- **Run the restore-proof correctly:** execute `backup-verify-restore.sh verify …` **plain and in the background** (the real restore exceeds a 120 s foreground limit). **Never** run it under `bash -x | grep` and **never** `kill -9` it mid-run: a SIGKILL skips the `EXIT`-trap `final_cleanup`, orphaning its disposable DB (`sca_krayin_restore_verify_<hex>`) and a multi-GB staging dir. (`create_disposable_db` runs only *after* the ~4.5 GB decrypt/extract, so a stop *before* that leaves nothing; a stop *after* leaves exactly one orphan.) Let it finish — `final_cleanup` drops the disposable DB, revokes the scoped grant, and shreds staging, and refuses to report success if cleanup fails.
- **Identify orphans (read-only):**
  ```bash
  docker exec -e MYSQL_PWD="$PW" kr-mariadb mariadb -uroot -N -B -e \
    "SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'sca\\_krayin\\_restore\\_verify\\_%' OR schema_name LIKE 'sca\\_backup\\_selftest\\_%';"
  docker exec -e MYSQL_PWD="$PW" kr-mariadb mariadb -uroot -N -B -e "SHOW GRANTS FOR '<app_user>'@'%';" | grep -iE 'restore_verify|backup_selftest'
  ls -A backups/.work/
  ```
- **Remove an orphan (only a disposable name; NEVER `sca_krayin`):** `DROP DATABASE IF EXISTS \`<name>\`;` after asserting the name matches `*_restore_verify_<hex>` / `*_backup_selftest_<hex>`; `REVOKE SELECT ON \`<name>\`.* FROM '<app_user>'@'%';`; shred + remove `backups/.work/sca-verify.*` / `sca-selftest.*`.
- **Recommended follow-up hardening (not in this release):** add `trap final_cleanup INT TERM` to the restore script so an interactive Ctrl-C / SIGTERM also triggers cleanup (today the trap is `EXIT`-only; SIGKILL can never be trapped).

## [7] GO / NO-GO

| Dimension | Verdict |
|---|---|
| SHAs confirmed; branch on current main | **GO** |
| Standalone diff = only intended backup-hardening (no migration/dep/config) | **GO** |
| Restore-proof (R1) passed on current prod data | **GO** |
| Rollback defined (code-only, no DB rollback) | **GO** |
| Merge + coordinated deploy incl. opcache reload prepared | **GO** |
| Post-deploy health checks + first-backup validation defined | **GO** |
| Force-kill / orphan-DB safeguards defined | **GO** |
| **Overall** | **GO — merge + deploy on explicit owner approval.** Off-host durability + key escrow (B1–B4) remain a separate open DR item, not a blocker for this code-only backup-consistency release. |

**STOP — read-only release preflight delivered. No merge/deploy/restart/migration/config/backup action taken. Await explicit owner approval before release execution.**

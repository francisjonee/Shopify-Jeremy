# SCA — Backup Fix: Minimal Standalone Deployment Plan (READ-ONLY; commands for review)

**Scope: read-only plan only. The commands below are for owner + ChatGPT review and MUST NOT be executed here. Nothing merged, deployed, reloaded, restarted; no production database or backup configuration changed.** 2026-10-27.

Supersedes the deploy section of `docs/SCA-OPTC-BACKUP-FIX-RELEASE-PREFLIGHT.md`: `scripts/deploy-preview.sh` is **not used** for this release (it does `git reset --hard`, composer install, the feature test suite, `artisan migrate --force`, and may rebuild/recreate containers — all out of scope and unnecessary for a 6-file, zero-migration, zero-dependency change).

## Why a minimal procedure is sufficient (and safe)

- The delta is exactly **6 files** (`git diff --name-only 6022b75..95c15d3`): `DocumentService.php` (+ its test), `backup-run.sh`, `lib-docsnapshot.sh`, `backup-verify-restore.sh`, `test-restore-verify-safety.sh`. **No migration, no `composer.json/lock`, no `config/`, no `bootstrap/`, no `.env`, no Dockerfile/compose.**
- `6022b75` is an ancestor of `95c15d3`, so advancing `main` changes **only those 6 files** on disk.
- The live app is the **bind-mounted working tree** (`/opt/sca-platform/app` → `kr-app:/var/www/html`, rw), so a working-tree file update *is* the app deploy — no image rebuild, no container recreate, no composer, no migration.
- Therefore the deploy is: advance the 6 tracked files in the live checkout + one graceful PHP worker reload. Nothing else.

## [7] Preservation guarantees (explicit)

- **139/140 migration incident:** this procedure runs **no `artisan migrate`** and the delta contains **no migration files**, so the DB migration state (batch 27, incl. 139/140) is untouched.
- **Option C candidate** (`feat/sca-optc-secure-claim` @ `0f41e2e`): never checked out or merged by this procedure; its files are **disjoint** from the 6-file delta (verified: no overlap). It stays unmerged and prod-dormant.
- **All unrelated app files and running services:** the merge touches only the 6 files; `kr-app`, `kr-mariadb`, `sr-*` (production smsrocket), Caddy, cron, and the DB are not restarted, recreated, or modified.

## [6a] Preflight checks (read-only; run first, STOP on any mismatch)

```bash
cd /opt/sca-platform && git fetch origin
# 1. clean tree, on main, at the exact expected base
[ -z "$(git status --porcelain)" ]                      || { echo STOP: working tree not clean; exit 1; }
[ "$(git rev-parse HEAD)" = "6022b75c021069bde332b4a10cd5806ae9065aaf" ] || { echo STOP: HEAD not 6022b75; exit 1; }
[ "$(git rev-parse origin/main)" = "$(git rev-parse HEAD)" ]            || { echo STOP: origin/main moved; exit 1; }
# 2. branch is the reviewed tip and a clean descendant
[ "$(git rev-parse 95c15d3)" = "95c15d3f5dde1162f6ede442b87a007b87835ccd" ] || { echo STOP: branch tip unexpected; exit 1; }
git merge-base --is-ancestor HEAD 95c15d3               || { echo STOP: not a fast-forward; exit 1; }
# 3. the delta is EXACTLY the six files and contains no migration
git diff --name-only 6022b75..95c15d3 | sort | tee /tmp/delta.txt
[ "$(wc -l < /tmp/delta.txt)" -eq 6 ]                   || { echo STOP: delta is not 6 files; exit 1; }
grep -qiE 'migrations?/' /tmp/delta.txt                 && { echo STOP: migration in delta; exit 1; } || true
# 4. containers up (read-only)
docker inspect -f '{{.State.Running}}' kr-app kr-mariadb
# 5. record baseline for post-deploy comparison (read-only)
#    migration batch (expect 27) + provenance counts, via the root creds in .env
```

## [4] Minimal deployment (coordinated 6-file update + controlled opcache reload)

```bash
cd /opt/sca-platform

# A. Advance main by EXACTLY the 6-file delta — a --no-ff merge of the reviewed tip.
#    This updates ONLY the 6 changed files in the live (bind-mounted) working tree and records a
#    merge commit. NO reset --hard, NO checkout of unrelated refs, NO deploy-preview.sh.
git merge --no-ff --no-edit 95c15d3 \
  -m "Merge backup document-consistency + restore-verify hardening (95c15d3) [code-only, no migration]"

# A'. Verify on disk that only the six files changed from the prior state (belt-and-suspenders).
git diff --name-only HEAD@{1} HEAD | sort    # must equal the six paths above

# B. Publish the merge.
git push origin main

# C. Controlled PHP/opcache reload — graceful Apache worker reload (NOT a restart/recreate): finishes
#    in-flight requests, starts new workers, and clears opcache so the new DocumentService.php is used.
docker exec kr-app apachectl -k graceful
```

No chown is required (the 6 files are code/scripts, not app-written `storage/` or `bootstrap/cache/`; reads work as the files' owner). The scripts (`backup-run.sh`, `lib-docsnapshot.sh`, `backup-verify-restore.sh`) are now the on-disk versions the next nightly cron and any manual restore-proof will use — the atomic writer and the consistent-snapshot/verify ship in the same merge, so they go live together.

## [5] Post-deployment health checks

```bash
# App serves and code loaded cleanly (no white error page):
curl -sS -o /dev/null -w '%{http_code}\n' https://verify.secondchanceauthenticators.com/        # expect 200
# A stored-document read still works (unchanged final-path layout): open an existing passport/cert PDF.
# Apache healthy:
docker exec kr-app apachectl configtest        # "Syntax OK"
# Production DB UNCHANGED — migration batch still 27 (confirms NO migration ran); prov counts unchanged:
#   docker exec -e MYSQL_PWD=<root> kr-mariadb mariadb -uroot -N -B sca_krayin -e \
#     "SELECT MAX(batch) FROM migrations;"        # expect 27
# Option C still unmerged on origin; 139/140 untouched.
```
**First backup validation:** the next nightly (`backup-run.sh`, 03:17 UTC) now runs the new snapshot + `verify_db_document_refs` stage — confirm `backups/backup.log` shows `OK … docs=<n>` with no snapshot/verify failure (R1 was cleared on 2026-10-27, so it should pass; a failure logs fail-closed and writes no artifact). Then restore-proof the first NEW artifact with `scripts/backup-verify-restore.sh verify <artifact>` (disposable DB; run plain + in background — see safeguards).

## [6b] Rollback (code-only; NO database rollback)

Primary (clean git history, revert-forward — no `reset --hard`):
```bash
cd /opt/sca-platform
git revert --no-edit -m 1 <merge-commit-sha>    # restores the 6 files to their 6022b75 content + commit
git push origin main
docker exec kr-app apachectl -k graceful
```
Emergency only (no push path; leaves HEAD ahead of on-disk content until reconciled):
```bash
git checkout 6022b75 -- \
  app/packages/Sca/Provenance/src/Services/DocumentService.php \
  app/tests/Feature/Sca/BackupDocumentAtomicityTest.php \
  scripts/backup-run.sh scripts/lib-docsnapshot.sh \
  scripts/backup-verify-restore.sh scripts/test-restore-verify-safety.sh
docker exec kr-app apachectl -k graceful
```
No migration/schema is involved, so **no DB rollback is needed**; `DocumentService.php`'s atomic write is forward-safe. Never `reset`/force-push shared `origin/main` backward.

## [6c] Safe failure-stop procedure

- Any preflight assert fails → **STOP**, change nothing.
- `git merge` reports a conflict or changes more than the 6 files (A' check) → **STOP**: `git merge --abort`; investigate; do not push.
- `git push` rejected (origin advanced) → **STOP**: re-run preflight against the new origin/main; do not force.
- `apachectl -k graceful` returns nonzero → **STOP**: the old workers keep serving; run `apachectl configtest`, fix, retry the graceful reload; **do not restart or recreate the container**.
- Post-deploy health fails (non-200 / error page / document read broken) → execute the rollback above, then graceful reload, then re-check.
- Restore-proof safeguard: run `backup-verify-restore.sh verify` **plain and in the background**; never under `bash -x | grep` and never `kill -9` mid-run (SIGKILL skips the EXIT-trap cleanup → orphan `sca_krayin_restore_verify_<hex>` DB + multi-GB staging). Orphan identification/removal (disposable names only, never `sca_krayin`) per `docs/SCA-OPTC-BACKUP-FIX-RELEASE-PREFLIGHT.md` §6.

## Summary of differences from the rejected `deploy-preview.sh`

| deploy-preview.sh (rejected) | This minimal plan |
|---|---|
| `git reset --hard origin/main` | `git merge --no-ff 95c15d3` (updates only the 6 changed files) |
| `composer install` + `dump-autoload` | none (no dependency change) |
| `php artisan test` vs `sca_domain_test` | none (no DB test) |
| `php artisan migrate --force` | none (no migration; 139/140 preserved) |
| config:clear / route:clear | none (no config/route change) |
| possible Docker rebuild / recreate | none (bind-mount update only) |
| (no explicit opcache reload) | `apachectl -k graceful` (controlled, zero-downtime) |

**STOP — read-only corrected deployment plan delivered for owner + independent ChatGPT review. Commands are for review only and were NOT executed. No merge/deploy/reload/restart/DB/backup-config change.**

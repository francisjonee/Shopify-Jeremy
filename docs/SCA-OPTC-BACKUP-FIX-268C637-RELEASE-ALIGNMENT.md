# SCA — Backup Fix `268c637`: Standalone Release Alignment (READ-ONLY)

**Scope: read-only alignment only. Nothing implemented, cherry-picked, merged, deployed, restored, migrated, or restarted; no production configuration changed. STOP for owner + ChatGPT review.** 2026-10-26.

**GO/NO-GO (headline): Isolability = GO (clean, zero conflicts, exactly 5 files). Deploy execution = CONDITIONAL — gated on (a) restore-proof of the current backup, (b) owner reconciling a stale deployment-record label, (c) opcache/php reload. Until those: NO-GO to deploy.**

---

## Material finding first — the "production = 3b30a0f" premise is STALE

Production `kr-app` (the live app behind `sr-caddy` for verify.secondchanceauthenticators.com) **bind-mounts `/opt/sca-platform/app` → `/var/www/html` read-write** (`docker inspect kr-app`: `bind /opt/sca-platform/app -> /var/www/html (rw=true)`; compose `./app:/var/www/html`). The container's baked image (`sca-app:krayin-2.2.6`, built 2026-10-01) is overridden at that path by the bind mount, so **the live app code is whatever the working tree's `app/` holds.**

- Working tree is checked out at **`main` = `6022b75`** and is **clean** (`git status --porcelain` → 0 entries).
- Spot-check of 8 files changed *after* `3b30a0f` (UX Phase 1, commit `63177b1`): the working tree matches `6022b75` and differs from `3b30a0f` for **all 8** (e.g. `QrService.php`, `SubmissionController.php`, `CertificationController.php`, `AuthenticationController.php`).

⇒ **The live production app CODE is `6022b75`, not `3b30a0f`.** The `3b30a0f/migr138` figure in the memory/records is a stale *deploy-baseline label*; it no longer reflects the bind-mounted code. (The database migration state is a separate axis — the backup fix has **no** migration, so it is unaffected; the 139/140 batch-27 incident is untouched and out of scope here.)

**Consequence for this task (important):** the owner's concern — that a fix based on `6022b75` would drag the `3b30a0f..6022b75` delta (UX Phase 1, auth/cert, QR-reason code) into production — **does not apply**, because that delta is *already live* via the bind mount. Advancing to the merged backup fix therefore introduces **only** the 5-file backup delta. The standalone property is automatic.

(Flagged for separate owner attention, not part of this fix: because code goes live the instant the working tree advances, the `3b30a0f→6022b75` code changes are live without a formal deploy/opcache-clear/migration-verify having necessarily been run for each. Worth a deployment-records reconciliation.)

## [1] SHAs

| Ref | SHA |
|---|---|
| impl GitHub `origin/main` (github-sca-platform) | `6022b75c021069bde332b4a10cd5806ae9065aaf` |
| impl local `main` | `6022b75` (== origin) |
| branch `fix/sca-backup-document-consistency` (local == origin) | `268c637503883007622c58a94232fcc9d05dfe1f` |
| working tree HEAD | `6022b75` on `main`, clean |
| deployed-prod label (records) | `3b30a0f` / migr138 — **stale vs live bind-mount (now 6022b75); see above** |
| gov `origin/main` (Shopify-Jeremy) | `07caa1c` (prior final-gate doc) |

## [8] Commit ancestry

Linear: `3b30a0f` → `bebd181`/`9a7db35` (pilot docs) → `1bc301e`/`1c6c1e6` (rg8 test) → `7848b58`/`0afc68b` (QR reason, migr139) → `d21f087`/`62c5d8b` (auth/cert) → `63177b1`/`73b6c22` (UX Phase 1) → `ee3b014`/`6022b75` (backup staging fix). Confirmed: `3b30a0f` is an ancestor of `6022b75`; `6022b75` is an ancestor of `origin/main` (they are equal).

**`merge-base(origin/main, branch) = 6022b75`** → the branch sits **directly on current main**. Therefore *diff-vs-current-main == diff-vs-original-baseline* — they are the same diff. (Task 2 answered: comparing against current main yields exactly the same 5-file, +629/−27 delta as against the original baseline.)

## [2,3] The five files isolated onto current main (and onto the stale prod label)

`git diff --stat 6022b75..268c637` = exactly **5 files, +629/−27**:

| File | Δ | At 3b30a0f vs 6022b75 | Isolates cleanly? |
|---|---|---|---|
| `app/.../DocumentService.php` | +50/−… | **identical** | yes — applies to either baseline |
| `app/tests/Feature/Sca/BackupDocumentAtomicityTest.php` | +54 (new) | identical (absent before) | yes (test; not deployed to prod) |
| `scripts/lib-docsnapshot.sh` | +218 (new) | identical (absent before) | yes |
| `scripts/backup-run.sh` | +70 | differs 24+/1− | yes — difference is only the already-merged, already-live staging fix `ee3b014` (an ancestor on main) |
| `scripts/backup-verify-restore.sh` | +264 | differs 7+/0− | yes — same (staging `TMPDIR`); ancestor, no conflict |

All five isolate cleanly onto current main (the branch *is* based on it) and, because `DocumentService.php`/`lib-docsnapshot.sh`/the test are byte-identical at `3b30a0f` and `6022b75`, the delta also applies without conflict onto the older label. The two scripts differ between `3b30a0f` and `6022b75` only by the staging fix that is already merged and already live — so there is no divergent content to reconcile.

## [4] Conflicts and unexpected application changes

- **Conflicts: NONE.** Branch merge-base == current main ⇒ a clean fast-forward/merge; no three-way conflict is possible.
- **Unexpected app changes: NONE.** Only `DocumentService.php` (narrow document-write atomicity) + one new test under `app/`. `git diff --name-only 6022b75..268c637` contains **no** `migrations/`, `composer.json/lock`, `config/`, `bootstrap/`, or `.env` change (verified — none).

## [5] Standalone backup-fix release (prepared, NOT executed)

The release is exactly the 5-file delta. Mechanics, given the bind mount:

1. **Merge `268c637` → `main`** (clean; based on `6022b75`). No migration.
2. **App surface — `DocumentService.php`:** because `./app` is a live bind mount, advancing the working-tree checkout to the merged main makes the atomic-write code live. **Must be followed by an opcache/PHP reload** (apache/php-fpm) so the running interpreter picks up the new file.
3. **Script surface — the 3 host scripts:** used by the next `cron` run (`/etc/cron.d/sca-backup`, 03:17 UTC) and by manual `backup-verify-restore.sh`. Not in the container; a host-side file update.
4. Deploy app + scripts **together** so the atomic writer and the consistent-snapshot/verify match. Because the live app is already `6022b75`, this introduces **only** the 5 files — no UX-Phase-1/auth-cert/QR-reason drag.

## [6] Verify the CURRENT encrypted backup via isolated restore BEFORE the stricter checks go live

Before the new fail-closed `verify_db_document_refs`/`snapshot_documents` become the nightly's gate (risk R1: a pre-existing non-canonical `storage_path` or a missing referenced doc would fail the nightly closed), run — separately authorized, disposable targets only:

1. `scripts/backup-verify-restore.sh selftest` (synthetic) — must PASS.
2. `scripts/backup-verify-restore.sh verify <latest backups/sca-backup-*.tar.gz.gpg>` — decrypts with `secrets/backup.key`, restores the DB dump into a **disposable** database (`guard_target` refuses the live `sca_krayin`) + docs into a disposable dir, then runs the new verify over the restored dump+docs.
3. Capture: table/trigger/FK counts, app read (`items=3 state=3`), `localcount==pathcount`, every referenced doc present.
4. If current prod data passes, R1 cannot trigger on existing data; then the stricter nightly is safe to rely on.

## [7] Preservation of schedule, retention, and live DB — confirmed

- **Schedule:** unchanged — `268c637` touches no cron/unit; `/etc/cron.d/sca-backup` (03:17 UTC) stays.
- **Retention:** byte-identical — the only `rm` added to `backup-run.sh` is `rm -f "${OUT}.part"` (its own temp); `RETAIN_DAYS=14`/`RETAIN_MIN=7` and the prune loop are unchanged; **no existing artifact deleted**.
- **Live DB:** untouched — no migration; the restore-proof uses a disposable DB only, never `sca_krayin`.

## GO / NO-GO

| Dimension | Verdict |
|---|---|
| Commit ancestry understood; main vs prod reconciled | **GO** (live code = `6022b75`; `3b30a0f` label stale) |
| 5 files isolate cleanly onto current main | **GO** (branch is based on it; no conflict) |
| Conflicts / unexpected app or schema or dep changes | **GO** (none) |
| Standalone release = only the 5 files | **GO** (inherently, because live = `6022b75`) |
| Schedule / retention / live DB preserved | **GO** (confirmed) |
| **Deploy execution now** | **CONDITIONAL / NO-GO until:** (a) restore-proof of current backup PASSES; (b) owner acknowledges the stale `3b30a0f` label (live code is `6022b75`) and the opcache-reload step; (c) owner authorizes. |

**Required actions before deploy (for owner / ChatGPT):**
1. Reconcile the deployment record: live app code is `6022b75` (bind mount), not `3b30a0f`.
2. Authorize the restore-proof (disposable DB) to clear R1.
3. On deploy, include an opcache/PHP reload for the `DocumentService.php` change.

**STOP — read-only release-alignment delivered for owner + ChatGPT review. Nothing implemented, merged, cherry-picked, deployed, restored, migrated, restarted, or reconfigured.**

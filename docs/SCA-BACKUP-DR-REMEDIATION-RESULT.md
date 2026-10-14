# SCA Backup & Disaster-Recovery Remediation — Result

**Authorization:** governance `6bc0c12c8e08d3177d1f5f729cc6eb3223f12283` (backup & recovery remediation only).
**Scope honored:** NO application deploy, NO production DB migration, NO production restore, NO
provenance mutation, NO unrelated service restart, NO DNS/Caddy change, NO pilot. The only
production access was a read-only, application-consistent `mariadb-dump --single-transaction`
(a consistent snapshot, not a write) and non-mutating `SHOW DATABASES` checks. All restore work
ran against a **disposable** database, never the live DB.

**Impl baseline:** `origin/main == 73b6c22ff0b8397e2d6c7c06ea9cc325d7693732` (unmoved; confirmed before and after).
**Candidate branch (script fix, NOT merged):** `fix/sca-backup-staging-diskbacked` @ **`ee3b0145683796952e1c9000418b514c8cb634a7`** (pushed to `origin`).
**Governance doc corrected:** `docs/SCA-PRODUCTION-RELEASE-READINESS.md` (§3 note, §5, §11).

---

## 1. Independent confirmation of the failure (sub-task 1) — CONFIRMED

Evidence from the live host (`/opt/sca-platform`):

- **`backups/backup.log`** shows every nightly run from **2026-10-09 → 2026-10-14** ending:
  ```
  gzip: stdout: No space left on device
  tar: /tmp/sca-backup.<rand>/documents.tar.gz: Wrote only N of 10240 bytes  (or: Cannot write: Broken pipe)
  tar: Child returned status 1
  FAIL  document archive failed
  ```
- **Root cause (confirmed):** `df -h` → `/tmp` is a **2.9 GB tmpfs (RAM-backed)**; the host has **no swap**.
  `backup-run.sh` staged its working set (`WORK="$(mktemp -d "${TMPDIR:-/tmp}/sca-backup.XXXXXX")"`,
  former line 52) on that tmpfs. The private document corpus `app/storage/app/sca` is now **4.8 GB**
  (`du -sm` = 4877 MB), so the `documents.tar.gz` staging step alone cannot fit in 2.9 GB → tmpfs
  exhaustion. This is **tmpfs/RAM exhaustion, not disk**: root `/` has **343 GB free** (`/dev/sda1 387G, 45G used`).
- **Last usable backup before remediation:** `sca-backup-20261008T011702Z.tar.gz.gpg` (2.93 GB), i.e.
  **6 days stale**. Backup sizes climbed with the corpus (30 KB on Sep 24 → 2.93 GB on Oct 8), which is
  why the failure began only once the corpus crossed the tmpfs ceiling.
- **No stale staging dirs** remained in `/tmp` — the existing `cleanup()` EXIT trap (shred + `rm -rf`)
  does fire on a normal `fail()` exit, so failed runs did not themselves accumulate; the failure was
  purely capacity.
- **Off-host replication unconfigured:** `SCA_BACKUP_REMOTE`/`SCA_OFFSITE_UPLOADER` unset; no rclone/aws
  present → backups are VPS-local only.

## 2. Backup-staging fix (sub-task 2) — DONE (candidate, not merged)

Candidate `ee3b014` on `fix/sca-backup-staging-diskbacked`, **+31 / −1** across only the two
backup-toolchain scripts (no application code, schema, config, or infrastructure touched):

**`scripts/backup-run.sh`**
- Stage on a **disk-backed, access-controlled** workspace instead of `/tmp`:
  `WORK_BASE="${SCA_BACKUP_WORK_DIR:-${BACKUP_DIR}/.work}"`, `mkdir -p` + `chmod 700`. `backups/` is
  already gitignored (`/backups/`), so `.work` is never committed, and it lives on root `/` (343 GB free).
- **Stale-staging sweep:** remove (shred files, then `rm -rf`) any `sca-backup.*` dir older than 12 h,
  to clear a workspace a previously **SIGKILL/OOM-killed** run could leave behind (the EXIT trap cannot
  fire on SIGKILL). `flock` (already present) guarantees no concurrent run, so a >12 h-old dir is dead.
- **Disk-space guardrail:** require free space `>= 2 × corpus + 1 GB` (override `SCA_BACKUP_MIN_FREE_MB`);
  fail fast and clean on a nearly-full disk rather than writing a half-archive.
- Log the non-secret staging path + free/needed MB.

**`scripts/backup-verify-restore.sh`**
- `export TMPDIR="${SCA_BACKUP_WORK_DIR:-${BACKUP_DIR}/.work}"` (created 0700) so the verifier's
  `mktemp` sites (which already honor `TMPDIR`) decrypt/extract a multi-GB real backup on disk, not tmpfs.

**Unchanged:** encryption (GPG AES-256, key from file), DB/doc scope, `flock` serialization,
shred-on-exit cleanup, retention, off-site hook, and the live-DB restore guard (`guard_target`).

**Regression checks before touching live data (all isolated, no production):**
- `bash -n` clean on both scripts.
- `backup-verify-restore.sh offsite-selftest` → **OFFSITE-SELFTEST PASS** (atomic stage→promote proven with a fake uploader).
- `backup-verify-restore.sh selftest` → **SELFTEST PASS** (synthetic encrypt → tamper-reject → decrypt →
  restore schema+trigger+rows into a disposable DB → document bytes round-trip; no plaintext left behind).

## 3. Fresh encrypted backup (sub-task 3) — DONE & integrity-checked

Ran the authorized `backup-run.sh` (fixed) against the live DB (read-only snapshot):

| Field | Value |
|---|---|
| Artifact | `backups/sca-backup-20261014T220630Z.tar.gz.gpg` |
| Size | 4,496,973,939 bytes (4.2 GB) |
| SHA-256 | `fd19be096035c096694e6134a7dde9ac1b9296cdde7afb9f73d81a5c8e1fbae1` |
| Documents captured | 4525 files |
| Staging (new) | `./backups/.work/sca-backup.<rand>` — **disk-backed**; logged `350705MB free, need>=10778MB, docs=4877MB` |
| Encryption | GPG symmetric AES-256, passphrase from key file (never in args/env/log) |
| Off-site | `OFFSITE_DEFERRED` (no remote configured — see §4) |
| Retention | applied (kept newest set; aged artifacts pruned) |

- `sha256sum` of the artifact **matches** its sidecar `.sha256`.
- Staging workspace was **shredded and removed on exit** (verified: `backups/.work/` empty afterward).
- No secrets, personal data, or backup contents were written to logs or world-readable paths.

## 4. Off-host replication (sub-task 4) — **BLOCKED / STOPPED (reported, not completed)**

Per the authorization ("configure off-host replication **only if** a destination and credentials are
already approved and available; otherwise stop and report the blocker"), I checked and found **none**:

- `app/.env` and compose `.env`: **no** `SCA_BACKUP_REMOTE`, `SCA_OFFSITE_UPLOADER`, or any
  `RCLONE_*/AWS_*/S3_*/B2_*` credentials.
- No `rclone` and no `aws` binary installed; no `~/.config/rclone/rclone.conf`.

**No approved off-host destination or credentials exist on this host.** I did **not** invent a provider,
open an account, incur charges, or move backup data anywhere. **This is the residual release blocker.**
→ Owner decision required: provision an approved destination + credentials (then the existing, already
proven atomic `offsite_publish` path can be enabled via `SCA_BACKUP_REMOTE`).

## 5. Isolated restore verification (sub-task 5) — PASS

Ran `backup-verify-restore.sh` against the fresh backup. It restores into a **disposable** database
`sca_krayin_restore_verify` (the built-in `guard_target` **refuses** to target the live DB name
`${MARIADB_DATABASE}`), into a disposable doc dir, then drops the DB and shreds the workspace on exit.

```
artifact sha256 verified
db component integrity verified against manifest
schema restored: tables=100, triggers=46, foreign_keys=129
referential integrity OK (no orphan ownership rows)
application read OK (items=3 state=3)
document bytes restored intact (4525 file(s))
RESTORE VERIFICATION PASS (disposable DB 'sca_krayin_restore_verify' dropped)
```

- `items=3` is consistent with the canonical provenance count (first of `3/3/4/4/5/2/1/1/7`).
- The live database `sca_krayin` was never targeted, altered, or connected to for restore; the app-read
  probe used a temporary SELECT grant on the disposable DB only, revoked on cleanup.

## 6. Release rollback-plan correction (sub-task 6) — DONE (documentation only)

Revised `docs/SCA-PRODUCTION-RELEASE-READINESS.md`:

- **§5 / §11 — rollback by pinned immutable revision, never by resetting shared `origin/main`.**
  Roll back by redeploying a specific prior revision (full SHA / annotated rollback tag, e.g. `62c5d8b`)
  via a controlled checkout into the deploy tree. Explicitly forbids force-pushing/hard-resetting
  `origin/main` backward. Notes that `deploy-preview.sh` as written is forward-only (resets the local
  checkout to `origin/main`), so a rollback needs a dedicated pinned-SHA path or an owner-approved manual
  checkout that does **not** move `origin/main`.
- **Preserve migration 139; never automatically drop audit data.** A code-only rollback keeps 139
  applied (prior code ignores the additive `reason` column). `migrate:rollback` (which drops the reason
  column + CHECK, i.e. QR-lifecycle **audit** data) is removed from the routine path and made an
  exceptional, explicitly owner-authorized step taken only after the current DB is itself backed up.
- **Confirm the deployed revision from trustworthy metadata** (container build commit / `git rev-parse`
  in the deploy tree) before relying on it as a rollback anchor; otherwise label it inferred.
- §3 gained a remediation-status note pointing here.

## 7. Residual blockers & recommendations

1. **Off-host replication — BLOCKER (owner action).** No approved destination/credentials provisioned.
   Release stays **NO-GO** on the off-host criterion until an owner-approved off-host copy exists.
2. **Candidate not merged / not deployed (by design — stop gate).** The staging fix lives only on
   `fix/sca-backup-staging-diskbacked`. The impl working tree has been restored to `main`, so the
   installed `/opt/sca-platform/scripts/backup-run.sh` is still the **unfixed** version. **The automated
   nightly cron backup will therefore continue to FAIL until this candidate is reviewed and the fix is
   in place.** A fresh, restore-verified backup exists **as of 2026-10-14T22:06Z** to cover the gap.
   → Recommend expedited review + merge/deploy of `ee3b014` given the operational criticality.
3. No swap on this host remains a latent risk, but staging no longer uses RAM, so a backup no longer
   pressures the swapless co-tenant.

## 8. GO / NO-GO

**NO-GO (unchanged verdict, one remaining blocker).** Backup *mechanism* is remediated and a fresh backup
is restore-verified, but there is still **no off-host recovery point**. Clear this by provisioning an
approved off-host destination and merging/deploying the staging fix so nightly backups resume.

**STOP — awaiting ChatGPT independent audit. No application merge or deployment performed; no production
migration, provenance mutation, service restart, DNS/Caddy change, or pilot.**

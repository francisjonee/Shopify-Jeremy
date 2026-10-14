# SCA Backup & DR Remediation — Merge Result (code-only; NOT deployed)

**Status:** Controlled code-only merge complete on `main`. Awaiting ChatGPT independent
**post-merge** audit. **No application deployment, no production script installation, no
production DB migration, no live-data mutation, no pilot.** This merge changes only two
backup-toolchain shell scripts in the repository; it does not deploy anything or alter the
running production application, database, or provenance.

| | |
|---|---|
| Governance pre-merge PASS | `2e62508b1f8373af63ba1ad114441f1b4c3aad7e` |
| Approved candidate | `ee3b0145683796952e1c9000418b514c8cb634a7` |
| Baseline (confirmed unmoved immediately pre-merge) | `73b6c22ff0b8397e2d6c7c06ea9cc325d7693732` |
| **MERGE_SHA** | **`6022b75c021069bde332b4a10cd5806ae9065aaf`** |
| **ORIGIN_MAIN** | **`6022b75c021069bde332b4a10cd5806ae9065aaf`** |
| Candidate → merge tree | **byte-identical** (`git diff --quiet ee3b014..6022b75` ⇒ empty) |
| Files changed vs baseline | **exactly 2** backup scripts, +31 / −1 |
| Deployment / prod-script install | **not performed / not authorized** |
| Production migration | none (no migration in this change) |

## Procedure
1. Reconfirmed `origin/main` = local `main` = exact approved baseline `73b6c22` immediately
   before merging (unmoved); candidate `ee3b014` was 1 ahead / 0 behind with merge-base `73b6c22`.
2. `--no-ff` merge of the approved candidate `ee3b014` into `main` → merge commit `6022b75`.
3. Proved candidate → merge content identity: `git diff --quiet ee3b014..6022b75` ⇒ empty (byte-identical tree).
4. Proved the baseline→merge delta is **exactly the two authorized backup scripts**
   (`git diff --name-only 73b6c22..6022b75`):
   - `scripts/backup-run.sh` (+24 / −1)
   - `scripts/backup-verify-restore.sh` (+7 / −0)
5. Pushed `main`: `73b6c22..6022b75`.

## What changed (recap)
Backup/verify staging is relocated off the `/tmp` tmpfs (2.9 GB, RAM-backed, swapless host) to a
disk-backed, 0700 workspace (`backups/.work`, already gitignored), with a stale-staging sweep (for
a SIGKILL/OOM-killed run the EXIT trap cannot clean) and a disk-space guardrail. Encryption
(GPG AES-256, key-from-file), DB/document scope, `flock` serialization, shred-on-exit cleanup,
retention, the off-site hook, and the live-DB restore guard are **unchanged**.

## Deployment / running-host state — explicitly NOT claimed fixed
- **This is a repository merge only.** No deploy ran, no production container was rebuilt, no cron
  entry was (re)installed or modified, and no migration or data change occurred. The running
  production application remains on the previously deployed code `3b30a0f` (migration 138), unchanged.
- Per the merge authorization, **the nightly backup on the running host is NOT asserted fixed merely
  because the code is merged.** Confirming the live nightly job actually runs the corrected script is
  a separate operator verification/deploy step, not performed or claimed here.
- A fresh, restore-verified encrypted backup (`sca-backup-20261014T220630Z.tar.gz.gpg`, produced and
  verified during the remediation task) exists to cover the interim.

## Release posture — unchanged: NO-GO
Off-host replication remains **unconfigured** (no owner-approved destination/credentials). The
production release remains **NO-GO** until an approved off-host recovery point is established. See
`docs/SCA-BACKUP-DR-REMEDIATION-RESULT.md` and the rollback-plan corrections in
`docs/SCA-PRODUCTION-RELEASE-READINESS.md` (§3/§5/§11).

**STOP — awaiting ChatGPT independent post-merge audit of `6022b75`. Do not deploy, install
production scripts, run production migrations, modify production data, change infrastructure,
conduct a pilot, or start another initiative.**

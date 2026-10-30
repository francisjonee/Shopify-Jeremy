# SCA — Off-Server Backup Implementation Plan (read-only planning)

**The hard part is already built: the nightly backup produces one encrypted, application-consistent
artifact and the off-site upload path (`lib-offsite.sh`, provider-independent rclone/aws, atomic
stage→promote) and an isolated restore-proof already exist in code. Off-server backup is therefore a
configuration + credentials + key-escrow task — not new development — gated on a few owner actions.**
Read-only review at prod `6e36aa7`; no infrastructure/production/backup change made. 2026-10-30. **STOP
for review.**

> Written for: the owner (Jeremy) + operator who will provision the off-site account and approve the
> one-time install/config.

## 1. What already exists (reviewed)
- **`scripts/backup-run.sh`** (cron: `backups/backup.cron` → daily **03:17 UTC**, flock-serialized).
  Produces ONE artifact `backups/sca-backup-<UTC>.tar.gz.gpg` (+ `.sha256`) — a single **GPG symmetric
  AES-256** envelope containing:
  - `db.sql.gz` — logical MariaDB dump, `--single-transaction --routines --triggers --events` (InnoDB-
    consistent) of the whole SCA database → **includes every table: certifications, qr_identifiers,
    claims, ownership_events, transfer_events, media_assets metadata, etc.**
  - `documents.tar.gz` — the private SCA document bytes from `app/storage/app/sca` (certificate PDFs,
    inspection media), from a **proven-consistent snapshot** that fails closed if any DB-referenced
    document is missing (closes the dump→snapshot deletion window).
  - `MANIFEST.txt` + `documents.sha256.txt` — **restoration metadata**: `git_commit`, `document_count`,
    per-component SHA-256 (code/config recovered from Git; secrets from escrow).
  - Excludes (by design): Docker images/containers, caches, logs, `vendor/`, build artifacts, the public
    disk, secrets. The passphrase is read from a key **file** (never argv/env/stdout); plaintext work dir
    is shredded on every exit; staging is disk-backed (not the swapless `/tmp` tmpfs) with a free-space
    guardrail; artifact is published atomically (`*.part`→rename).
- **`scripts/lib-offsite.sh`** — `offsite_publish()` already implements provider-independent off-site
  upload (**rclone** any remote, or **aws s3**), publishing the single `.gpg` atomically
  (`<name>.part` → server-side promote), returning 0 / 1 (fail) / 3 (no uploader). Wired into
  `backup-run.sh` step 5: if `SCA_BACKUP_REMOTE` is set it publishes; if unset it logs
  **`OFFSITE_DEFERRED`** (the one external blocker — the current state).
- **Restore proof** (`scripts/backup-verify-restore.sh`, `scripts/test-restore-verify-safety.sh`) —
  fully **isolated**: restores into a DISPOSABLE verify DB + disposable dir, **never** touches the
  production DB / storage / `sr-*`, and refuses to target the live DB name; proves tables + triggers
  survive, referential integrity holds, the app reads the restored state, and document bytes match. A
  `selftest` mode proves the whole pipeline on synthetic data with no provider/credentials.
- **Retention:** local keeps newest `RETAIN_MIN=7`, then drops artifacts older than `RETAIN_DAYS=14`.

## 2. Current state & the gap
- Local backups are healthy: latest `sca-backup-20261030T021703Z.tar.gz.gpg` ≈ **4.3 GB**; **13**
  artifacts on disk ≈ **56 GB**; backups filesystem **284 GB free of 387 GB**. The private media corpus
  is ≈ **4.9 GB** (dominates each artifact; the DB dump is small).
- **Gaps (the two known residuals):**
  1. **No off-server copy** — `SCA_BACKUP_REMOTE` is unset and **no uploader is installed** (`rclone` and
     `aws` are both absent). A host failure currently loses all backups with the server.
  2. **No key escrow** — `secrets/backup.key` exists **only on the server** (mode 600, root). Without it,
     the encrypted off-site artifacts are unrecoverable, so an off-site copy alone is not yet a recovery
     path.

## 3. Smallest reliable off-server solution (recommended)
Reuse the built mechanism — add no code:
1. **Install `rclone`** on the host (single static binary; provider-agnostic — supports Backblaze B2,
   AWS S3, Cloudflare R2, S3-compatible, etc.). Preferred over the AWS CLI for provider flexibility and a
   smaller footprint.
2. **Provision an off-site bucket** with a **dedicated, restricted** application key:
   - create-only / write-only where the provider supports it (so a compromised host key cannot delete or
     read existing backups);
   - enable **object-lock / versioning / lifecycle** on the bucket (ransomware & accidental-delete
     resistance) with the off-site retention you want (e.g. 30 days);
   - **Recommended provider: Backblaze B2** (cheapest, S3-compatible, supports app keys + object lock).
     AWS S3 or Cloudflare R2 are equally compatible.
3. **Configure the rclone remote on the host** with those credentials in rclone's own root-only config
   (`/root/.config/rclone/rclone.conf`, mode 600) — **not** in `.env` and **never** committed to Git.
4. **Set `SCA_BACKUP_REMOTE`** in `app/.env` to the remote path (e.g. `b2remote:sca-backups`). From the
   next nightly run the existing cron auto-publishes off-site (`OFFSITE_DEFERRED` → `OK off-site
   published`). No code change.
5. **Key escrow:** store a copy of `secrets/backup.key` in a separate secure vault **off the server**
   (the owner's password manager / a sealed secret store). Document that recovery needs: the off-site
   `.gpg` + this key + the Git repo. (The key is static; escrow it once.)

## 4. Integrity, retention, monitoring, recovery (step 5)
- **Integrity:** every artifact is GPG-authenticated (AES-256) and embeds per-component SHA-256 in its
  MANIFEST; a local `.sha256` sidecar exists. A successful decrypt already proves integrity. Periodically
  run `backup-verify-restore.sh <artifact>` (isolated) against a recent off-site-downloaded artifact to
  prove end-to-end recoverability.
- **Retention:** local 7-min/14-day (unchanged). Off-site retention is set on the bucket (lifecycle /
  object-lock) — recommend ≥ 30 days; keep it ≥ local so an off-site copy outlives local pruning.
- **Monitoring (automatable, email-free):** a tiny daily check (cron, after 03:17) that greps
  `backups/backup.log` for the day's `OK wrote` **and** `OK off-site published` lines and writes a
  status/heartbeat file (or pings a dead-man's-switch URL such as healthchecks.io). Alerting by email is
  out of scope until a mail provider is configured; a heartbeat/dead-man's-switch needs no mail.
- **Recovery procedure (documented in `docs/RUNBOOK.md` "Disaster recovery"):** on a new host — restore
  code from Git, supply secrets from escrow (incl. `backup.key`), download the newest off-site `.gpg`,
  run the documented restore (decrypt → verify checksums → import DB → restore documents). Permanent QR
  identity + provenance survive unchanged.

## 5. Restoration test WITHOUT touching production (step 6)
Already supported and isolated — no production risk:
- `./scripts/backup-verify-restore.sh [<artifact>]` — decrypts a real backup, restores into a
  **disposable verify DB** + disposable dir, asserts schema/triggers/referential-integrity/app-read/
  document-byte fidelity, then drops the verify DB. It refuses the live DB name and never touches
  `sr-*`/production storage.
- `./scripts/backup-verify-restore.sh selftest` — synthetic round-trip proof, no provider/creds.
- **GOTCHA (from prior ops):** run the verify **plain** (optionally backgrounded) — never under
  `bash -x | grep` or kill it mid-run; a SIGKILL leaves orphaned verify DBs/dirs. Run against a recent
  off-site-downloaded artifact once off-site is live, to prove the off-site copy restores.

## 6. Storage & cost estimate (step 7)
- Per-artifact ≈ **4.3 GB/day** (mostly the ~4.9 GB media corpus; each `.gpg` is a distinct encrypted
  blob, so no cross-day dedup of the encrypted objects).
- Off-site footprint ≈ retention × 4.3 GB: **30 days ≈ 130 GB**, 14 days ≈ 60 GB.
- Indicative monthly cost at 130 GB stored: **Backblaze B2 ≈ $0.80/mo** ($6/TB-mo), **Cloudflare R2 ≈
  $2/mo** (no egress fees), **AWS S3 Standard ≈ $3/mo**. Egress applies only on a real restore (one
  artifact). Costs are negligible; retention length barely moves them.
- **Optional future optimization (not required):** the media corpus is largely immutable, so a separate
  `rclone sync` of `documents` (file-level dedup of unchanged media) plus a small DB-only daily artifact
  would cut daily off-site transfer/storage substantially. The smallest *reliable* solution is full daily
  off-site of the existing single artifact (reuses the built path, nothing new to maintain); the
  optimization can follow if transfer volume matters.

## 7. Owner accounts, credentials, approvals required (step 8)
1. **Off-site object-storage account** (recommend Backblaze B2) — owner creates; owner-owned billing.
2. **A dedicated bucket + restricted application key** (create/write-only; object-lock/versioning +
   lifecycle enabled) — owner provisions; share the key with the operator via a secure channel (never in
   chat/Git).
3. **Approval to install `rclone`** on the shared host (a single binary; low footprint; does not affect
   the live smsrocket stack).
4. **Approval to set `SCA_BACKUP_REMOTE`** in `app/.env` and to write the root-only rclone config.
5. **Key-escrow destination** — owner stores a copy of `secrets/backup.key` in their password manager /
   secure vault.
6. **(Optional) a dead-man's-switch/heartbeat account** (e.g. healthchecks.io free tier) for monitoring.

## 8. What can safely be automated (step 9)
- **Already automated:** the daily backup + (once `SCA_BACKUP_REMOTE` is set) the off-site publish — the
  cron and code paths exist; no new automation is needed for the core off-site copy.
- **Add (small, safe):** the daily log-check/heartbeat monitor (a few lines of cron), and a scheduled
  (e.g. weekly) isolated `backup-verify-restore.sh` run against a downloaded off-site artifact to prove
  recoverability on a cadence.
- **Keep manual/owner-gated:** provisioning the account/bucket/key, installing rclone, setting the env,
  and key escrow (one-time infrastructure + secret actions — out of scope for this read-only plan).

## 9. Safety posture (this task)
Read-only planning only. No production DB change; no backup deletion or retention change; no installation
or infrastructure change; no Shopify API request or store modification; no production deploy/restart; no
email configuration; secure-claim RC `4bd88d2` not deployed. Production unchanged at `6e36aa7`.

**STOP — plan delivered. Off-server backup is a CONFIGURATION + CREDENTIALS + KEY-ESCROW task, not new
development: the encrypted application-consistent backup, the provider-independent atomic off-site upload
(`lib-offsite.sh`, rclone/aws), and the isolated restore-proof already exist. Smallest reliable solution =
install rclone → provision a restricted-key off-site bucket (recommend Backblaze B2, object-lock) →
configure the rclone remote → set `SCA_BACKUP_REMOTE` → escrow `backup.key`; ≈4.3 GB/day (~130 GB at
30-day retention) for roughly $1/mo. Monitoring via a log-check heartbeat; recovery proven with the
existing isolated verify-restore. All install/credential/infra steps are owner-gated and were NOT
performed. No infrastructure or production change made.**

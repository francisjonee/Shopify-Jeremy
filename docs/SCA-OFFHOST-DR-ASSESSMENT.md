# SCA Off-Host Backup & Disaster-Recovery Assessment (planning only)

**Status:** READ-ONLY assessment + recommendation. **Nothing provisioned, installed, configured, uploaded,
merged, deployed, or executed.** No storage account created, no credentials changed, no cron/scripts/`.env`
touched, no production backup/restore, no DB mutation, no service restart. Candidate `268c637` stays
UNMERGED/inactive; production `main 6022b75` and migrations 139/140 untouched; Stripe/mail not activated.
This document is for ChatGPT review + owner decision; implementation is a separate, approved task.

Scope: close the one remaining production-release blocker — **no off-host recovery point** — by choosing a
destination and defining the flow, retention, restore procedure, verification, and an isolated restore test.

---

## 1. Current state (observed read-only on the live host, 2026-10-20)

**Backup engine (deployed on `main 6022b75`):**
- Cron `scripts/backup.cron` → daily **03:17 UTC**, `root`, runs `scripts/backup-run.sh`, appends to
  `backups/backup.log`. (Operator-installed to `/etc/cron.d/sca-backup`; confirmed running.)
- Each run produces ONE encrypted artifact `backups/sca-backup-<UTC>.tar.gz.gpg` (+ `.sha256`): a GPG
  symmetric **AES-256** envelope containing `db.sql.gz` (mariadb-dump `--single-transaction`, routines/
  triggers/events), `documents.tar.gz` (private disk `app/storage/app/sca`), `MANIFEST.txt`
  (per-component SHA-256), and `documents.sha256` (per-document SHA-256).
- Staging is disk-backed (`backups/.work`, the merged tmpfs fix) with a free-space guard + flock + shred
  cleanup. Log shows recent runs **OK**: `2026-10-20T01:25:05Z OK wrote …20261020T011702Z… (4.3G, docs=4605)`.
- **Local retention:** keep newest `SCA_BACKUP_RETAIN_MIN=7`, prune older than `SCA_BACKUP_RETAIN_DAYS=14`.

**Off-host publication (code-ready, NOT enabled):**
- `scripts/lib-offsite.sh::offsite_publish` uploads the single `.gpg` **atomically** (`<name>.part` →
  server-side promote) via **`rclone`** or **`aws s3`**, keyed by `SCA_BACKUP_REMOTE` (+ optional
  `SCA_OFFSITE_UPLOADER`). Unit-proven by `backup-verify-restore.sh offsite-selftest` (PASS).
- `SCA_BACKUP_REMOTE` is **unset** → every night logs `OFFSITE_DEFERRED … retained locally only (NOT
  durable)`. No `rclone`/`aws`/`restic`/`borg` installed. **`rsync` 3.4.1, `ssh`, `sftp`, `gpg` 2.4.8 ARE
  present.**

**Restore proof (exists):** `scripts/backup-verify-restore.sh [<artifact>]` decrypts a real artifact,
verifies component checksums, restores the DB into a **disposable** `${DB}_restore_verify` and documents
into a disposable dir, then asserts: tables+triggers+FKs present, **referential integrity** (no orphan
ownership rows), the Laravel app can **read** the restored state, and **document bytes match** the manifest
SHA-256 — then **drops** the verify DB. `guard_target()` hard-refuses the live DB name. Last known
restore-verified artifact = **2026-10-14T22:06Z** (manual).

**Host facts:** single filesystem `/dev/sda1` 387 G (50 G used, 338 G free); 5.8 GiB RAM, **no swap**;
QEMU/KVM guest (consistent with Hetzner Cloud; owner states Hetzner). Co-tenant `sr-*` (smsrocket) shares
the host. Document corpus `app/storage/app/sca` ≈ **4.9 G**; artifact ≈ **4.3 G** and growing.

## 2. What is stored ONLY on the production VPS (single point of total loss)

| Asset | Location (VPS only) | In Git? | Consequence of VPS/disk loss |
|---|---|---|---|
| Encrypted backup artifacts | `backups/*.tar.gz.gpg` on `/dev/sda1` | No | **All backups lost** |
| **Encryption key** | `secrets/backup.key` (65 B, mode 600) | No (git-ignored) | **All ciphertext undecryptable** |
| App secrets | `.env`, `app/.env` (incl **APP_KEY**) | No | Laravel-encrypted fields (doc handles, Shopify token) unreadable |
| Live DB | `sca_krayin` in `kr-mariadb` (vol `sca_db_data`) | No | Primary data gone |
| Document corpus | `app/storage/app/sca` | No | Primary documents gone |
| Code + compose/Caddy config | two Git repos | **Yes** | Recoverable from Git |

**Critical implication:** copying only the `.gpg` off-host is **insufficient**. Recovery also needs the
**GPG key** and the **app secrets (.env/app.env, APP_KEY)**, which today live only on the VPS. The RUNBOOK
DR section already states these three must be kept off-server; an off-host plan must therefore include a
**separate, out-of-band escrow** of the key + secrets, independent of the ciphertext copy (and NOT in the
same Storage Box the SFTP sub-account can read/delete).

**Recovery artifacts that already exist:** local encrypted dailies (10-05…10-20) + the 10-14 manual
restore-verified one; a documented DR runbook; a proven disposable restore verifier; the atomic
`offsite_publish` path waiting on a destination.

## 3. Off-host options compared (Hetzner-centric)

All options store our **already client-side-encrypted** `.gpg`, so provider at-rest encryption is a bonus,
never a dependency. Prices below are **order-of-magnitude only — verify current Hetzner/B2 pricing before
committing.**

| Option | Transfer (existing tools?) | Isolation / immutability | Geo/provider independence | Rough cost | Notes |
|---|---|---|---|---|---|
| **A. Hetzner Storage Box** (recommended) | SFTP/SSH/rsync **already installed**; rclone `sftp` backend, or restic/borg for dedup | **Sub-accounts** (confine to one subdir) + server-side **snapshots** (not deletable by the SFTP sub-account) | Different Hetzner **location** choosable; same vendor | lowest (~€4/mo ~1 TB tier) | Best fit: cheap, existing tooling, snapshot immutability, sub-account least-privilege |
| **B. Hetzner Object Storage (S3)** | needs `aws`/rclone install; uses existing `aws s3` path | **Object-lock / versioning** (strong immutability); write-only bucket policy | Different Hetzner region; same vendor | ~€6/mo + egress on restore | Strongest immutability; egress cost on restore; long-lived keys to scope |
| **C. Third-party (Backblaze B2 / Wasabi / AWS S3)** | needs rclone/`aws`; uses existing S3 path | Object-lock/versioning | **Cross-provider** (survives a full Hetzner account/billing loss) | B2 ~$6/TB/mo | Best independence; extra vendor/account/billing ops |

**Not off-host (rejected for the total-loss criterion):** a second Hetzner **Cloud Volume** attached to the
same VM or a copy elsewhere on `/dev/sda1` — same failure domain; does not satisfy total-VPS-loss recovery.

## 4. Recommendation

**Primary: Option A — Hetzner Storage Box, reached via rclone's `sftp` remote.**
Rationale: (1) uses tooling already on the host (SSH/SFTP/rsync) and the existing, audited atomic
`offsite_publish` `rclone` path **with no code change** (rclone `sftp` remote looks like any other rclone
remote to `rclone copyto/moveto`); (2) cheapest; (3) **sub-account** confinement + server-side **snapshots**
give least-privilege + immutability against a compromised VPS deleting history; (4) selectable in a
**different Hetzner location** for geo-separation.

**Optional second copy (defense-in-depth, later): Option C — Backblaze B2** for cross-provider
independence (protects against a full Hetzner account/billing loss). `offsite_publish` already abstracts the
uploader; a second destination is a small, additive enhancement — not required to clear the blocker.

**Non-negotiable companion to any option:** an **out-of-band escrow** of `secrets/backup.key`, `.env`,
`app/.env` (APP_KEY), and the Storage-Box SSH key, in a separate secure store (password manager / offline
vault) that the ciphertext destination cannot reach. Without it, the off-host ciphertext is unrecoverable.

## 5. Proposed off-host backup flow (after approval + candidate `268c637` deploy)

1. Nightly `backup-run.sh` builds the local encrypted artifact (unchanged).
2. With `SCA_BACKUP_REMOTE=<rclone-sftp-remote>:sca-backups` set, `offsite_publish` uploads the single
   `.gpg` atomically (`.part` → promote) to the Storage Box subdir. A failed/interrupted upload leaves only
   a `*.part` (cleaned up); a final-named remote object only ever appears complete.
3. **Post-upload integrity check (small candidate addition, to be audited):** after promote, verify the
   remote object against the local `.sha256` (`rclone hashsum sha256` / `rclone check`); a mismatch fails
   the run (no false "durable" claim). Until added, rely on the GPG-embedded manifest + a periodic restore.
4. Local retention unchanged (7 / 14 days).

## 6. Retention policy (off-host)

- **Off-host GFS (tunable to budget/compliance):** keep **14 daily + 8 weekly + 6 monthly** full artifacts.
  Each artifact is a full ~4.3 G object (not incremental), so budget ≈ (14+8+6) × ~4.5 G ≈ **~125 G** with
  headroom → a ~1 TB Storage Box is ample.
- **Immutability:** enable Storage Box **snapshots** (server-side; not deletable by the SFTP sub-account) OR
  Object-Storage object-lock, so a compromised VPS cannot erase history.
- **Dedup alternative (optional):** `restic`/`borg` to the Storage Box would cut storage via dedup + give
  append-only repos, at the cost of changing the model from "single authoritative `.gpg`" to a repo (and a
  new lib-offsite branch). Recommend starting with full-object dailies + snapshots; revisit if cost grows.

## 7. Restore procedure (total server loss) — off-host specifics

The RUNBOOK DR runbook already documents the full flow. Off-host additions:
1. On a fresh host: retrieve the newest `sca-backup-<UTC>.tar.gz.gpg` from the Storage Box (sftp/rclone).
2. Restore the **escrowed** secrets from the separate vault: `secrets/backup.key`, `.env`, `app/.env`.
3. Follow RUNBOOK §"Disaster recovery": clone repo, `docker compose up -d --build`, `chown -R 33:33 app`,
   decrypt + `db-restore.sh` over the fresh empty DB, extract `documents.tar.gz`, `migrate --force`, smoke
   tests, then `backup-verify-restore.sh` against the restored artifact.

## 8. Verification criteria (a backup is "durable" only when ALL hold)

1. The nightly log shows `OK off-site published …` (not `OFFSITE_DEFERRED`).
2. Remote object SHA-256 matches local `.sha256` (post-upload check or periodic `rclone check`).
3. The artifact is built from a **consistency-verified** run (candidate `268c637` deployed: fail-closed
   snapshot + DB→document reference proof).
4. A restore from the **off-host copy** (not the local one) passes `backup-verify-restore.sh` on an isolated
   host within the last **month**.
5. The GPG key + app-secrets escrow is confirmed present and current in the separate vault.

## 9. DB dump + document archive: transfer & verification, and reference-integrity limits

- **Transfer:** both live inside the single `.gpg` (db.sql.gz + documents.tar.gz + MANIFEST + documents.sha256),
  so off-host transfer is **one object** — no multi-object partial-state risk.
- **Verification:** GPG decrypt is authenticated (AES-256) → MANIFEST per-component SHA-256 → documents.sha256
  per-document SHA-256 → disposable restore-proof (schema/triggers/FK/referential integrity/app-read/byte match).
- **Reference-integrity (candidate `268c637`) — honest limits:** the backup proves every DB-referenced
  **private `local`** document is present in the archive (fail-closed), closing the dump→snapshot deletion
  window. It is a **reference-integrity proof, NOT a coordinated point-in-time DB+document snapshot**: the DB
  dump (point-in-time via `--single-transaction`) and the document snapshot are taken **sequentially**, so a
  document created *after* the dump but before the snapshot yields at most a harmless **unreferenced extra
  file** on restore. It verifies **presence + SHA of copied bytes**, not source-side corruption that predates
  the dump. It covers only the **private disk**; public catalog images (`storage/app/public`) are excluded by
  design and recovered from source. A stronger guarantee (app quiescence or an LVM/filesystem snapshot
  coordinated with the dump, or restic/borg for dedup) is a possible future enhancement, not required to
  clear the off-host blocker.

## 10. Safe, isolated restore test (will not touch production)

- **Monthly (lightweight):** on a **throwaway Hetzner Cloud VM** (NOT the production host), install Docker +
  mariadb, pull the newest `.gpg` from the Storage Box, restore into that VM's own DB, run
  `backup-verify-restore.sh <artifact>` + smoke tests, then destroy the VM. This exercises the real
  total-loss path (off-host fetch → cold restore).
- **At minimum (on-host, already safe):** `backup-verify-restore.sh <artifact>` restores into the disposable
  `${DB}_restore_verify` DB; `guard_target()` refuses the live DB name and the verify DB is dropped after —
  it never touches `sca_krayin` or live storage. Use this for frequent rehearsals; use the throwaway-VM test
  to prove off-host fetch + cold recovery.
- **Never** run the destructive `db-restore.sh` against production to "test" it.

## 11. Outstanding owner decisions

1. **Destination:** approve **Hetzner Storage Box** (primary); decide whether to add Backblaze B2 as a
   second cross-provider copy now or later.
2. **Provision** the Storage Box + a least-privilege **sub-account/SSH key** confined to `/sca-backups`,
   with **snapshots** enabled (owner/out-of-band — Claude must not create accounts or credentials).
3. **Escrow:** where to store `secrets/backup.key`, `.env`, `app/.env` (APP_KEY) + the Storage-Box SSH key,
   separate from the ciphertext destination. **(Highest-priority gap.)**
4. **Retention + immutability:** confirm the GFS numbers (§6) and enable snapshots/object-lock.
5. **Host change approval:** install `rclone` (and write `~/.config/rclone/rclone.conf`, mode 600) — a minor
   but real change to the shared host; or approve a small `lib-offsite.sh` `sftp`/`rsync` branch to avoid
   installing rclone.
6. **Deploy order:** merge/deploy consistency candidate `268c637` (separate audited action) so off-host
   artifacts are consistency-guaranteed before being relied on.
7. **Geo-separation:** choose a Storage Box location different from the VM's.

## 12. Exact proposed implementation steps (for a later, owner-approved task — NOT executed here)

1. Owner provisions a Hetzner Storage Box (≥ ~1 TB, different location than the VM); creates a **sub-account**
   limited to `/sca-backups` with an SSH key; enables snapshots.
2. Owner escrows OFF-HOST, separate from the Storage Box: `secrets/backup.key`, `.env`, `app/.env`, and the
   Storage-Box SSH key (password manager / offline). Records the location in governance (not the secrets).
3. VPS (approved maintenance window): install `rclone`; write `~/.config/rclone/rclone.conf` with an `sftp`
   remote (`host`, `user`, `key_file`, `path`), mode 600. No secrets in Git.
4. Set in `.env` (mode 600, not committed): `SCA_BACKUP_REMOTE=sbox:sca-backups` (optionally
   `SCA_OFFSITE_UPLOADER=rclone`).
5. Dry-run: `backup-verify-restore.sh offsite-selftest` (already PASS), then a MANUAL off-hours
   `backup-run.sh` → confirm `OK off-site published …` and the object present + snapshotted on the Storage Box.
6. (Candidate → audit) add a post-upload remote-vs-local SHA check to `lib-offsite.sh`/`backup-run.sh`.
7. Configure off-host retention (rclone prune + Storage Box snapshots) per §6.
8. Schedule the monthly isolated restore test (throwaway VM) + a quarterly full DR rehearsal; record results.
9. Re-assess GO/NO-GO once §8 criteria (1)–(5) all hold.

## 13. GO / NO-GO

**NO-GO (unchanged) on the off-host criterion.** The backup *mechanism* is sound and nightly artifacts are
fresh, but they exist **only on the production VPS**, and the key + app secrets are co-located there. The
blocker clears when: an off-host destination + least-privilege credentials are provisioned; the key + app
secrets are escrowed separately; nightly off-host upload is enabled and verified; and a restore **from the
off-host copy** passes on an isolated host — ideally after consistency candidate `268c637` is deployed.

**STOP — planning assessment only; awaiting ChatGPT review + owner decisions. No provisioning, install,
configuration, upload, merge, deploy, backup/restore, DB mutation, or service change was performed.**

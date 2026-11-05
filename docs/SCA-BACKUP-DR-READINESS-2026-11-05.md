# SCA — Off-Server Backup & Disaster-Recovery Readiness (read-only assessment + plan)

**On-server encrypted backups are healthy and complete; the single remaining gap before production buyer
claiming is durability off the server. The nightly job runs daily (~02:17 UTC), and today's artifact
(`sca-backup-20261105T021702Z.tar.gz.gpg`, 4.58 GB, GPG AES-256, sha256 recorded, docs=4605) completed OK
— it captures a transaction-consistent dump of the whole `sca_krayin` database (so authentication,
certification, QR identities and ownership history are all included) plus the private media corpus, with a
verified doc-reference integrity gate. Retention is 14 days (16 artifacts, 69 GB on a disk with 263 GB
free), and an isolated restore-verification tool exists and last passed on 2026-10-27. BUT every run logs
`OFFSITE_DEFERRED`: no off-server copy exists because no remote is configured and neither uploader (rclone/
aws) is installed, and the decryption material (the backup passphrase `secrets/backup.key` and the Laravel
`APP_KEY`) lives only on the one host and is NOT inside the backups — so a loss of this server today would
mean total, unrecoverable loss of all SCA provenance data. Closing the gap needs no development (the
off-site uploader is already built, provider-independent, atomic): it is owner-gated provisioning —
a Backblaze B2 bucket (~$1/month at this size), a restricted key, and off-server escrow of the two
secrets. This assessment made no changes.** 2026-11-05, prod `e3f73f8b`. **STOP.**

> Written for: the owner (Jeremy) and the external auditor. Read-only; updates the earlier off-site plan
> (gov `780a30f`) with current verified numbers and adds the DR checklist + single-points-of-failure.

## Phase 1 — existing backups (verified)
- **Server health:** prod `e3f73f8b`; `kr-app` + `kr-mariadb` up & healthy. (Host now has 4 GB swap — previously none.)
- **Schedule:** `/etc/cron.d/sca-backup` → `scripts/backup-run.sh` daily `17 3 * * *` (host TZ = UTC+1 ⇒ **02:17 UTC**). Self-serializes via flock; logs without secrets.
- **Most recent successful backup:** `sca-backup-20261105T021702Z.tar.gz.gpg` — **2026-11-05 02:27 UTC, OK**, 4.58 GB, `sha256 9b1a6089…`, docs=4605, `db=sca_krayin`. The prior 14 nights all show `OK` + `DONE`.
- **Coverage (confirmed in `backup-run.sh`):**
  - `db.sql.gz` — `mariadb-dump --single-transaction --routines --triggers --events` of the entire `sca_krayin` DB ⇒ **authentications, certifications, qr_identifiers, qr_lifecycle_events, ownership_events, sale_links, items, collectors, everything**.
  - `documents.tar.gz` — private media from `app/storage/app/sca` (**4605 files**), with a `documents.sha256.txt` manifest and a fail-closed `verify_db_document_refs` gate (every DB-referenced doc must be present).
  - `MANIFEST.txt` — db + docs checksums.
- **Encryption:** GPG `--symmetric --cipher-algo AES256`, passphrase from `secrets/backup.key` (`root:root 600`, 65 bytes). Each artifact has a `.sha256` sidecar; publication is atomic (`*.part` → promote).
- **Retention:** `RETAIN_DAYS=14` (keep newest `RETAIN_MIN`, then drop >14 days). Working — logs show nightly `PRUNE`. Currently **16 artifacts, 69 GB**; disk `/` 387 GB, **263 GB free (33% used)**.
- **Restore procedure:** `scripts/backup-verify-restore.sh` (selftest + restore into a **disposable** DB, refuses the live name, fail-closed doc-ref check). Last **PASS 2026-10-27** (tables 100 / triggers 46 / FK 129, app-read pinned to disposable, 4605 docs intact).

## Phase 2 — off-server storage (BUILT, UNCONFIGURED)
- The uploader is already implemented: `scripts/lib-offsite.sh::offsite_publish` supports **rclone** or **aws s3**, uploads to a `*.part` then promotes server-side (atomic). It is **provider-independent** and needs only configuration.
- **Why it's not durable yet:** `rclone` and `aws` are **both not installed**, and `SCA_BACKUP_REMOTE` is unset → every run logs `OFFSITE_DEFERRED … artifact retained locally only (NOT durable)`.
- **Recommended provider: Backblaze B2** (simplest, cheapest, S3-compatible, native object-lock). No new infrastructure, no subscription beyond pay-as-you-go storage.
- **Sizing (from real artifacts):** ~4.58 GB/artifact, essentially flat (media corpus stable). Off-site at **14-day** retention ≈ **~64 GB**; at a deeper **30-day** retention ≈ **~137 GB**. Each daily `.gpg` is an independent encrypted blob (no cross-day dedup), so cost = retention × 4.58 GB.
- **Estimated cost (B2 @ ~$6/TB-month; verify current pricing):** ~**$0.40/mo** (14-day) to ~**$0.85/mo** (30-day). Egress on restore is rare and within B2's free allowance. **< $1/month.**
- **Exact configuration steps (owner-gated — prepared, not performed):**
  1. **(Owner)** Create a Backblaze B2 account; create a **private** bucket, e.g. `sca-offsite-backups`.
  2. **(Owner)** Enable **Object Lock** (e.g. 30-day compliance/governance) + a **lifecycle rule** for off-site retention (independent of the host's local 14-day prune) — defends against ransomware/accidental deletion.
  3. **(Owner)** Create an **application key scoped to that bucket only**, minimal capabilities — `listBuckets, listFiles, readFiles, writeFiles` but **not** `deleteFiles` (create/write-only posture so a compromised host cannot erase history; combined with object-lock).
  4. **(Claude, on approval)** Install `rclone` on the host (static binary; low-risk) and write a **root-only** `rclone.conf` (`/root/.config/rclone/rclone.conf`, `600`) holding the B2 key — **never** in `app/.env` or git.
  5. **(Claude, on approval)** Set `SCA_BACKUP_REMOTE=<remote>:sca-offsite-backups/sca` (a non-secret path) in `app/.env`; the next nightly then uploads automatically.
  6. **(Claude, on approval)** Backfill: upload the existing recent artifacts once.
  7. **Verify:** download one off-site artifact and run `backup-verify-restore.sh verify` against it (disposable DB).

## Phase 3 — recovery readiness
- **Safe to test without production:** YES — `backup-verify-restore.sh` restores into a uniquely-named disposable DB, asserts it is not the live DB, and shreds/drops afterward. **GOTCHA (operational): run it plain and backgrounded — never under `bash -x | grep` or `kill` mid-run** (SIGKILL skips the EXIT-trap cleanup, orphaning a multi-GB disposable DB + staging).
- **Key recovery if the server is lost — CURRENT GAP:** the artifacts are encrypted with `secrets/backup.key`, and Laravel data may depend on `APP_KEY` (in `app/.env`). **Neither is inside the backup, and both live only on this host.** Without off-server escrow of these two secrets, an off-site `.gpg` copy would be **undecryptable** after a host loss. **Escrow both** (e.g. a password manager / sealed vault held by the owner), separately from the backups.
- **Disaster-recovery checklist (rebuild on a fresh host):**
  1. **App code** — `git clone` the implementation repo (`github-sca-platform`), check out the production SHA (`e3f73f8b`).
  2. **Secrets** — restore `app/.env` (with `APP_KEY`, DB creds, Shopify, Postmark) and the compose `.env` (`MARIADB_ROOT_PASSWORD`) from escrow; restore `secrets/backup.key`.
  3. **Containers** — `docker compose up -d` (`kr-app`, `kr-mariadb`), project `sca`.
  4. **Database** — fetch the latest off-site artifact, verify sha256, decrypt with `backup.key`, restore `db.sql.gz` into `sca_krayin`.
  5. **Private media** — extract `documents.tar.gz` → `app/storage/app/sca`, then `chown -R 33:33 app` (uid 33 = www-data).
  6. **Edge** — re-add the `verify.secondchanceauthenticators.com` route on `sr-caddy` (shared edge) and confirm TLS.
  7. **Validate** — public Passport `/p/{token}` 200; admin login; DB fingerprint matches (items 208 / variant_links 205 / auth 4 / cert 4 / qr 3 / ownership 5 / sale_links 1 / migrations 146).
- **Single points of failure (today):**
  1. **No off-server copy** — all 16 artifacts live only on the production host's disk. Host/disk loss = total provenance loss. *(closes with Phase 2)*
  2. **Decryption secrets co-located & un-escrowed** — `backup.key` + `APP_KEY` only on this host and not in the backup. *(closes with key escrow)*
  3. **Backups on the same disk/host as the live DB** — no isolation from a host-level failure. *(mitigated by off-site)*

## Phase 4 — final report (summary)
- **Backup status:** healthy, daily, encrypted, integrity-checked. **Most recent:** `20261105T021702Z` OK (4.58 GB, docs=4605). **Retention:** 14 days / 16 artifacts / 69 GB (263 GB free). **Encryption:** GPG AES-256, key `600 root`.
- **Off-server requirements:** rclone + a restricted Backblaze B2 key + `SCA_BACKUP_REMOTE`; **~64–137 GB** depending on off-site retention; **< $1/month**.
- **Recovery readiness:** restore tool present and safe (last PASS 2026-10-27); DR checklist above; the key-escrow gap is the critical blocker.
- **Missing owner actions:** (a) create the B2 bucket + object-lock + lifecycle; (b) create the restricted app key; (c) **escrow `backup.key` + `APP_KEY` off-server**; (d) approve installing rclone + setting `SCA_BACKUP_REMOTE`.
- **Exact next step:** owner creates the B2 bucket + restricted key and escrows the two secrets; then, on a one-word go, Claude installs rclone, writes the root-only `rclone.conf`, sets `SCA_BACKUP_REMOTE`, backfills recent artifacts, and verifies a downloaded artifact via the disposable restore test.

## What Claude can configure vs. what needs owner approval
| Action | Who |
|---|---|
| Install `rclone`; write root-only `rclone.conf`; set `SCA_BACKUP_REMOTE`; backfill uploads; run disposable restore-verify | **Claude, on explicit approval** (host change on a shared prod box) |
| Create B2 account/bucket, object-lock, lifecycle, restricted app key | **Owner** |
| Escrow `backup.key` + `APP_KEY` off-server | **Owner** |
| Any purchase / external upload of production data | **Owner** (none done here) |

## Safety posture (this task)
Read-only assessment. No Shopify call; no production DB write; no deployment/migration; no change to the
205 imports; no customer/ownership change; **no backup schedule, retention, key, or secret modified**; no
backup created, deleted, or uploaded; the verify script was **not** run. No encryption keys, DB passwords,
or credentials displayed.

**STOP — On-server encrypted backups are healthy (daily, AES-256, DB + 4605 media files, 14-day/16-artifact
retention, latest `20261105` OK, restore tool PASS 2026-10-27). The gap is durability: `OFFSITE_DEFERRED`
(no remote, no rclone/aws) and the decryption secrets (`backup.key` + `APP_KEY`) live only on this host and
are not in the backup — a host loss today is unrecoverable. No code work remains; the off-site uploader is
built. Next: owner provisions a restricted Backblaze B2 bucket (~$1/mo) + escrows the two secrets, then
Claude installs rclone, sets `SCA_BACKUP_REMOTE`, backfills, and verifies a downloaded artifact. Nothing
changed this task.**

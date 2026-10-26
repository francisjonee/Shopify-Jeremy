# SCA-OPTC — Backup & Release-Safety Preflight (READ-ONLY)

**Scope: read-only inspection only. No backup created/restored, no DB test, no config change, no merge/deploy/migrate/restart/activation, 139/140 untouched.** 2026-10-26. Candidate `0f41e2e` remains UNMERGED; `main 6022b75`, prod `sca_krayin` untouched.

## 1. Existing backup configuration & DR process (observed)

- **Scripts (on `main 6022b75`, `/opt/sca-platform/scripts/`):** `backup-run.sh` (nightly), `lib-offsite.sh` (`offsite_publish`), `backup-verify-restore.sh` (restore proof: `verify` / `selftest` / `offsite-selftest`), `db-backup.sh`, `db-restore.sh`, `backup.cron`.
- **Nightly cron IS installed and HEALTHY:** `/etc/cron.d/sca-backup` present; runs `backup-run.sh` daily at 03:17 UTC. `secrets/backup.key` present (0600). Latest run **today `20261026T021703Z` → `OK wrote … 4.3G` (db=sca_krayin, docs=4605 MB)**; prior days likewise OK. Disk ample: `/` 387G, 322G free (17% used); `backups/` ≈ 39G (retention 14d / min 7 → ~9 artifacts). One encrypted artifact per run: `backups/sca-backup-<UTC>.tar.gz.gpg` (+ `.sha256`).
- **Encryption:** GPG symmetric AES-256 with passphrase file `secrets/backup.key`; the single `.gpg` is the authoritative, self-contained artifact (embeds MANIFEST + per-component SHA-256).
- **Off-site:** every run logs `OFFSITE_DEFERRED  no SCA_BACKUP_REMOTE configured — artifact retained locally only (NOT durable)`. Provider-independent `offsite_publish` (rclone/aws; temp `.part` → server-side promote) is code-ready but inactive.

## 2. Exact remaining blockers for a verified OFF-HOST backup

| # | Blocker | Evidence |
|---|---|---|
| B1 | **No off-host destination** | `SCA_BACKUP_REMOTE` unset in `/opt/sca-platform/.env`; every run logs `OFFSITE_DEFERRED`. |
| B2 | **No uploader installed** | neither `rclone` nor `aws` on the host (`command -v` both absent); `offsite_publish` would return 3 ("no uploader"). |
| B3 | **No off-host credentials/remote config** | no rclone remote, no `SCA_OFFSITE_UPLOADER`, no provider account/creds present. |
| B4 | **Recovery key NOT escrowed off-host** | `secrets/backup.key` (GPG passphrase) AND `app/.env` (`APP_KEY`) live on the SAME single host as the backups — a host loss destroys the backups and their decryption key together; an off-host `.gpg` would be undecryptable after host loss. |
| B5 | **Document-consistency fix UNMERGED** | `fix/sca-backup-document-consistency` head `268c637` (code-audit PASS) is NOT on `main`; its `publishAtomically`/`snapshot_documents`/`verify_db_document_refs` are absent from the running `backup-run.sh`, so the nightly doc snapshot still carries the known deletion-window race (DB↔document consistency not yet guaranteed). |
| B6 | **No recent restore-proof against a real artifact** | `backup-verify-restore.sh verify` exists (restores to a DISPOSABLE DB) but there is no evidence it has been run against a current `.gpg`; restorability is unproven for the live data. |

**On-host nightly backup is healthy (B-none) — but single-host = not durable; B1–B6 are the gap to a VERIFIED OFF-HOST backup.**

## 3. Smallest safe plan (encrypted off-host + restore verification + key handling)

Deploy together, each step owner-authorized; all target disposable/off-host only (never prod):
1. **Destination + uploader (B1–B3):** install `rclone`; configure one remote — recommended **Hetzner Storage Box via `rclone` sftp** (per the prior off-host DR assessment) — set `SCA_OFFSITE_UPLOADER=rclone` and `SCA_BACKUP_REMOTE=<remote>:<path>`. No app/code change; `offsite_publish` already does `.part`→promote. (S3-compatible + `aws` is the documented alternative.)
2. **Recovery-key escrow (B4):** store `secrets/backup.key` AND the `APP_KEY` in a SEPARATE escrow that survives host loss (offline vault / password manager / a different provider), never co-located with the backups. Document the escrow location + who holds it.
3. **Document-consistency (B5):** merge + deploy `268c637` so `snapshot_documents` fail-closes and `verify_db_document_refs` proves every DB-referenced document is present before the backup is considered valid.
4. **Restore verification (B6):** run `backup-verify-restore.sh verify` against a current artifact (restores to a DISPOSABLE DB + disposable doc dir), THEN a restore-**from-off-host** test (download the `.gpg` from the remote → decrypt with the escrowed key → restore to a disposable DB). Capture checksums + row/doc counts as evidence. (These are DB operations — separately authorized, never prod.)

## 4. Missing credentials / configuration / owner decisions

- **Owner decision:** off-host provider (recommended Hetzner Storage Box; alt S3) + account + retention policy off-host.
- **Credentials:** the chosen remote's credentials (sftp key/password, or S3 keys) — provisioned into an rclone remote / env, never committed.
- **Config:** `SCA_BACKUP_REMOTE`, `SCA_OFFSITE_UPLOADER`; install `rclone` on the host.
- **Escrow decision:** where/how `backup.key` + `APP_KEY` are escrowed separately, and who can access them.
- **Merge decision:** authorize merge+deploy of `268c637` (separate from Option C).

## 5. Backup / restore GO-NO-GO checklist (evidence-based)

| Gate | Status | Evidence / needed |
|---|---|---|
| On-host nightly backup produced, encrypted, retained | **PASS** | cron installed; key present; `20261026…OK 4.3G`; 322G free |
| Document-consistency guaranteed in the artifact | **BLOCKED** | `268c637` unmerged (B5) |
| Restore-proof against a real current artifact | **NO-GO** | no recent `verify` run (B6) — run it (disposable DB) |
| Durable OFF-HOST copy exists | **BLOCKED** | `SCA_BACKUP_REMOTE` unset; no rclone/aws; no remote (B1–B3) |
| Recovery key escrowed separately from backups+host | **BLOCKED** | `backup.key`+`APP_KEY` co-located (B4) |
| Restore-FROM-off-host proven | **NO-GO** | depends on off-host + escrow (B4, then B6 off-host) |
| **Overall backup/DR readiness** | **NO-GO** | on-host nightly healthy, but off-host durability + key escrow + doc-consistency + restore-proof outstanding |

## 6. Outstanding test concerns (recorded, unresolved)

- **Rate-limiting (2):** `AuthenticationHardeningTest` admin-login + forgot-password expect 429, got 200 — the throttle does not trip in the ephemeral harness (present on candidate AND clean baseline; not Option-C). Unresolved harness item.
- **QR decoder (1):** `QrPrintLabelTest::ql3` `DECODE_FAILED` — appears to be the known non-deterministic QR-decoder flake (Option C touches no QR code), but **not yet confirmed** via re-run (deliberately not re-run — outside the authorized/ read-only scope). Unresolved-until-reproduced.

## 7. Preserved

- Option C **forward-recovery** strategy stands: deploy app + additive migration together; revert = code-only rollback leaving the additive nullable columns (preserve fulfillment-release attestation); targeted column-drop only if separately authorized + backed up. Unchanged.
- The **139/140 incident is untouched** and remains a separate owner-pending decision; Option C deploy must not bundle a batch-27 rollback.

**STOP — read-only backup/release-safety assessment delivered for owner + ChatGPT review. No backup/restore run, no DB test, no config/merge/deploy/migrate/restart/activation.**

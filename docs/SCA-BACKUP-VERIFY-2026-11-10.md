# SCA — Production backup verification, 2026-11-10 (read-only)

**Result: PASS (local only).** This is the first nightly run with the PR #27 script (production `46da80d`).

- Run `20261110T021701Z`: START 02:17:11Z → OK 02:28:04Z → OFFSITE_DEFERRED → PRUNE → DONE 02:28:04Z. No FAIL or INCOMPLETE.
- Archive `sca-backup-20261110T021701Z.tar.gz.gpg`: 4,577,885,119 bytes (4.3 GiB). GPG symmetric AES-256 (SHA-512 S2K). docs=4605.
- SHA-256 `987eb7df…48f08e16`: recomputed and matches both the `.sha256` file and the log.
- Retention: 16 archives with 16 `.sha256` files, 2026-10-27 → 2026-11-10. `20261026` was pruned as aged (14 days, minimum 7 kept). No staging or `.part` leftovers. Disk: 263 GB free (33% used).
- No backup process running. Containers `kr-app` and `kr-mariadb` up 3 weeks and healthy, `sr-*` up. `/collector/login` returns 200. Git tree clean at `46da80d`.
- Off-site: **nothing uploaded to Backblaze.** `SCA_BACKUP_REMOTE` is not set, rclone and aws are not installed, and the log has 0 `OFFSITE_OK` lines.

Remaining: no off-site copy yet (Backblaze preflight pending operator). `backup.key` and `APP_KEY` are still stored only on this host. Each log line is written twice, as on 2026-11-09 (cosmetic). The `.sha256` file holds a bare hash, so `sha256sum -c` cannot read it. Recoverable locally, with the restore drill not re-run today.

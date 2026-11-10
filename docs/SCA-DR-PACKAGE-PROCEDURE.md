# SCA — Disaster-recovery package: tested procedure (GPG, no new software)

Status: **tested with synthetic files only.** No real secret has been packaged, moved or uploaded.
Tools: `ops/dr/sca-dr-package.sh` (builds the package) and `ops/dr/test-sca-dr-package.sh` (22 synthetic tests, all pass).

## Format

One file, `SCA-DR-<UTC>.tar.gpg`, built from a plain `tar` archive encrypted with GPG.

- **Encryption:** AES-256. The passphrase is stretched with SHA-512 (S2K mode 3, 65,011,712 iterations).
- **Integrity:** OpenPGP integrity-protected packet (SEIPD v1 with MDC). Tampering is detected (tested).
- **Compatibility:** confirmed with `--list-packets`. Readable by GnuPG 2.2 and 2.4, so by Gpg4win 3.x and 4.x.
- **Tools on the server:** gpg 2.4.8 and GNU tar 1.35, both already installed.
- **Inner archive:** ustar format, read by both GNU tar and Python `tarfile`. Members are stored with mode 0600.

| Member | Source | Secret? |
|---|---|---|
| backup.key | `/opt/sca-platform/secrets/backup.key` | yes (read in place) |
| app.env | `/opt/sca-platform/app/.env` | yes (read in place) |
| compose.env | `/opt/sca-platform/.env` | yes (read in place) |
| caddy-sca-site.txt | SCA block from `/opt/smsrocket-stack/Caddyfile` | no (includes the staff IP allowlist) |
| RECOVERY.txt | `docs/SCA-DR-RECOVERY-INSTRUCTIONS.txt` | no |
| PACKAGE-INFO.txt | creation time and production commit | no |
| CHECKSUMS.sha256 | SHA-256 of the six files above | no |

## Exposure controls (tested)

- **Secrets are never copied, staged or written in plaintext.** `tar` reads the three files from their original paths and pipes them straight into `gpg`.
- **Why nothing is staged in `/dev/shm`:** it has 2.9 GB free, but it can be swapped out to `/swapfile`, a 4 GB swap file on disk with 1.3 GB in use. The design needs no protected temporary memory at all.
- **Staging:** only non-secret files go to `/root/.sca-dr-stage.XXXXXX` (mode 0700). That folder is removed on success, failure or Ctrl-C (verified: nothing left behind).
- **Passphrase handling:**
  - Typed at gpg's hidden prompt in loopback mode. It was never echoed in a captured terminal transcript.
  - Never placed in an argument, environment variable, file or log.
  - `--no-symkey-cache` is set, and a throwaway GnuPG home is used and then shut down.
- **No secrets in output:** the script prints only checks, the file size and the SHA-256 of the encrypted file. A test asserts that no secret text appears in the output.
- **Round-trip check:** the script decrypts once more (the passphrase is entered a second time) and hashes every member inside the pipe. It compares those hashes with the originals and writes nothing decrypted to disk. A mistyped passphrase therefore cannot produce a package nobody can open.
- **Caddy extraction fails closed** unless all of these hold:
  - exactly one site, `verify.secondchanceauthenticators.com`
  - balanced braces
  - every `reverse_proxy` targets `kr-app:80`
  - no secret-like or non-SCA words (basic_auth, `{env.`, token, secret, password, smsrocket, relaytask, postal, …)
- **The real Caddyfile passes:** 48 lines, one site, only SCA upstreams. The synthetic tests confirm that an SMSRocket block with a fake hash placed beside the SCA block is excluded.
- **Guards:**
  - The script refuses to run outside an interactive terminal.
  - The test-only passphrase-file mode is refused for `/opt/sca-platform` before any file is read.
  - The script refuses if `APP_KEY` or `MARIADB_ROOT_PASSWORD` is missing, or if `backup.key` is not a single line.
- **Remaining risk (small):** while the script runs, the secrets exist in the memory of the `tar` and `gpg` processes, which could in theory be swapped out. The running app holds the same values in memory all the time.

## Operator steps (production, needs separate authorization)

1. The owner creates the passphrase in the password manager (6+ random words or 24+ random characters). The owner also writes a paper copy for a safe. The passphrase must never be stored in Google Drive or Gmail, or in Google Password Manager, chat or GitHub.
2. The operator logs into the server over SSH as root. Turn off terminal logging and recording.
   ```
   cd /opt/sca-gov && git pull --ff-only && bash ops/dr/test-sca-dr-package.sh   # must end pass=22 fail=0
   bash ops/dr/sca-dr-package.sh                                                 # paste passphrase twice
   ```
   Expected result: four `OK` lines, then `REPORT package=/root/SCA-DR-<UTC>.tar.gpg bytes=… sha256=…`.
3. Send the owner the `sha256=` value through a **different channel** than the file (for example a text message). The hash is not secret.
4. Move the file off the server and deliver it to the owner. Upload to the Drive folder only once that step is authorized.
5. After the owner confirms the Windows check below, delete `/root/SCA-DR-<UTC>.tar.gpg` from the server.

## Owner verification on Windows (no server access needed)

**One-time setup:** install Gpg4win 4.x from https://gpg4win.org. This also installs `gpg.exe` and Kleopatra. Windows 10 and 11 already include `tar.exe`.

1. **The file arrived intact.** In PowerShell:
   `Get-FileHash .\SCA-DR-<UTC>.tar.gpg -Algorithm SHA256`
   The result must equal the hash you received.
2. **It opens, and the contents are complete, without writing anything to disk.** Use **Command Prompt (cmd.exe), not PowerShell**, because Windows PowerShell 5.1 corrupts binary pipes:
   ```
   gpg --no-symkey-cache --decrypt SCA-DR-<UTC>.tar.gpg | tar -tvf -
   ```
   A password window opens. Paste the passphrase. You should see exactly 7 files, each `-rw-------`:
   `backup.key` (about 65 bytes), `app.env` (about 1,300 bytes), `compose.env` (about 267 bytes), `caddy-sca-site.txt`, `RECOVERY.txt`, `PACKAGE-INFO.txt`, `CHECKSUMS.sha256`.
   gpg must **not** print `decryption failed`, `Bad session key` or `WARNING: message was manipulated`.
3. **Optional non-secret check:**
   `gpg --no-symkey-cache --decrypt SCA-DR-<UTC>.tar.gpg | tar -xOf - PACKAGE-INFO.txt`
   This shows the creation date and the production commit.
4. **Don't use Kleopatra's "Decrypt" button for routine checks.** It writes the decrypted `.tar`, including the secrets, to disk. Use it only in a real recovery.
5. Repeat steps 1–2 every 6 months. Rebuild the package whenever `backup.key`, `APP_KEY` or either `.env` file changes.

## Production actions that need separate authorization

| # | Action | Touches |
|---|---|---|
| A | Run `sca-dr-package.sh` on the production server as root (reads the 3 real secret files; writes one encrypted file to `/root`) | production server (read-only plus one new file) |
| B | Copy the encrypted file off the server and deliver it to the owner, with the hash sent separately | file transfer |
| C | Upload it to Google Drive "SCA — Disaster Recovery" | Google Drive |
| D | Delete `/root/SCA-DR-<UTC>.tar.gpg` from the server after the owner confirms | production server |
| E | (Optional, recommended first) Deliver a **synthetic** test package so the owner can rehearse the Windows steps with no real secrets | file transfer, no secrets |

Not needed: no software installs, no configuration changes, no restarts, and no changes to the database, Shopify or Backblaze.

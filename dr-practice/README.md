# SCA disaster-recovery PRACTICE package (synthetic, safe to share)

`SCA-DR-PRACTICE-20261110T143242Z.tar.gpg` is a **rehearsal file**. All 7 files inside are dummies:
there are no real keys, passwords, IP addresses or configuration in it. It was built with the same
script and GPG AES-256 format as the real recovery package (`ops/dr/sca-dr-package.sh`).

- SHA-256: `ac8f5f6a025f6c29482c044d393e5b9db3a0ead0d298d270043f6e55d5b2fbf6`
- Size: 10,315 bytes
- Practice passphrase (dummy, not a secret): `SCA-practice-only-2026-not-a-secret`

## Windows rehearsal

1. **Install Gpg4win** (one time) from https://gpg4win.org. Default options are fine.
2. **Download the file.** On this GitHub page, click the `.tar.gpg` file, then the download button
   ("Download raw file"). Save it to `Downloads`.
3. **Check the checksum.** Open **PowerShell** and run:
   ```
   cd $HOME\Downloads
   Get-FileHash .\SCA-DR-PRACTICE-20261110T143242Z.tar.gpg -Algorithm SHA256
   ```
   The `Hash` must be `AC8F5F6A025F6C29482C044D393E5B9DB3A0EAD0D298D270043F6E55D5B2FBF6`.
   (Windows shows it in capitals; that is the same value.)
4. **List the 7 files without extracting.** Open **Command Prompt** (Start → type `cmd`). Do **not** use
   PowerShell for this step. Run:
   ```
   cd %USERPROFILE%\Downloads
   gpg --no-symkey-cache --decrypt SCA-DR-PRACTICE-20261110T143242Z.tar.gpg | tar -tvf -
   ```
   A password window opens. Paste the practice passphrase above. You should see exactly:

   | File | Size (bytes) |
   |---|---|
   | backup.key | 67 |
   | app.env | 223 |
   | compose.env | 131 |
   | caddy-sca-site.txt | 228 |
   | RECOVERY.txt | 293 |
   | PACKAGE-INFO.txt | 168 |
   | CHECKSUMS.sha256 | 476 |

   Lines like `gpg: AES256.CFB encrypted data` and `gpg: encrypted with 1 passphrase` are normal.
   It must **not** say `decryption failed`, `Bad session key` or `WARNING: message was manipulated`.
   Nothing is written to disk by this step.
5. **Optional: see that a wrong passphrase is refused.** Run the step-4 command again and type
   anything else. gpg must report `decryption failed: Bad session key` and list no files.

If every step matched, you are ready for the real package. With the real package, the checksum will
reach you by a separate message (not GitHub), the passphrase will come from your password manager,
and the file sizes will be: backup.key about 65, app.env about 1,300 and compose.env about 267 bytes.

#!/usr/bin/env bash
# sca-dr-package.sh — build the SCA disaster-recovery package as ONE GPG (AES-256) file.
#
# Secrets are NEVER copied, staged or written in plaintext: tar reads backup.key, app/.env and the
# compose .env straight from their original paths into gpg through a pipe. Only non-secret files
# (Caddy site block, instructions, package info, checksums) are staged, in a 0700 dir, then removed.
# The passphrase is typed at gpg's hidden prompt (never an argument, env var, file or log line).
# A throwaway GnuPG home is used and the passphrase is not cached. After encrypting, the script
# decrypts the file once more (second passphrase entry) and hashes every member IN THE PIPE,
# comparing against the originals; nothing decrypted touches disk.
#
# Usage (as root, interactive SSH terminal, no `script`/tee/logging):
#   bash ops/dr/sca-dr-package.sh
# Output: $OUTDIR/SCA-DR-<UTC>.tar.gpg ; prints only its size and SHA-256.
set -Eeuo pipefail
umask 077
export LC_ALL=C

ROOT=${SCA_DR_ROOT:-/opt/sca-platform}
CADDYFILE=${SCA_DR_CADDYFILE:-/opt/smsrocket-stack/Caddyfile}
INSTR=${SCA_DR_INSTRUCTIONS:-$(cd "$(dirname "$0")/../.." && pwd)/docs/SCA-DR-RECOVERY-INSTRUCTIONS.txt}
OUTDIR=${SCA_DR_OUTDIR:-/root}
PASSFILE=${SCA_DR_TEST_PASSPHRASE_FILE:-}  # TEST ONLY (synthetic files); refused for the real root
readonly DOMAIN="verify.secondchanceauthenticators.com"
readonly MARK='^# SCA-PRODUCTION-CUTOVER Phase 2C'
# package name <- path relative to ROOT (secrets; read in place, never copied)
readonly SECRETS=("secrets/backup.key:backup.key" "app/.env:app.env" ".env:compose.env")
readonly STAGED=(caddy-sca-site.txt RECOVERY.txt PACKAGE-INFO.txt CHECKSUMS.sha256)

STAGE=""; GH=""; PART=""
die() { trap - ERR; printf 'FAILED: %s\nNothing was packaged.\n' "$*" >&2; exit 1; }
trap 'die "unexpected error at line $LINENO"' ERR
cleanup() {
  local rc=$?
  [ -n "$GH" ] && gpgconf --homedir "$GH" --kill all >/dev/null 2>&1 || true
  [ -n "$STAGE" ] && rm -rf "$STAGE"
  [ -n "$PART" ] && [ -e "$PART" ] && rm -f "$PART"
  exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' INT; trap 'exit 143' TERM; trap 'exit 129' HUP
ok() { printf '  OK  %s\n' "$*"; }

# ---- guards
if [ -n "$PASSFILE" ]; then
  case "$ROOT" in /opt/sca-platform|/opt/sca-platform/) die "test passphrase file is never allowed with the real secrets";; esac
else
  [ -t 0 ] && [ -t 2 ] || die "run interactively in a terminal (the passphrase is typed at a hidden prompt)"
fi
for t in tar gpg gpgconf sha256sum awk; do command -v "$t" >/dev/null || die "missing tool: $t"; done

# ---- 1. secrets present and plausible (contents never printed)
for m in "${SECRETS[@]}"; do
  p="$ROOT/${m%%:*}"
  [ -f "$p" ] && [ -r "$p" ] && [ -s "$p" ] || die "missing/empty/unreadable: ${m%%:*}"
done
[ "$(wc -l < "$ROOT/secrets/backup.key")" -le 1 ] || die "backup.key is not a single line"
! grep -q $'\r' "$ROOT/secrets/backup.key" || die "backup.key contains CR characters"
grep -q '^APP_KEY=base64:' "$ROOT/app/.env" || die "app/.env has no base64 APP_KEY"
grep -q '^MARIADB_ROOT_PASSWORD=.' "$ROOT/.env" || die "compose .env has no MARIADB_ROOT_PASSWORD"
[ -s "$INSTR" ] || die "recovery instructions not found: $INSTR"
ok "secret files present (backup.key, app/.env, compose .env) — read in place, not copied"

# ---- 2. stage NON-secret files only
STAGE=$(mktemp -d "$OUTDIR/.sca-dr-stage.XXXXXX")
GH="$STAGE/gnupg"; mkdir -m 700 "$GH"
B="$STAGE/caddy-sca-site.txt"
awk -v m="$MARK" '$0 ~ m {on=1} on {print} on && /^}/ {exit}' "$CADDYFILE" > "$B"
[ -s "$B" ] || die "SCA Caddy block not found (marker missing)"
[ "$(tail -n 1 "$B")" = "}" ] || die "Caddy block does not end with a closing brace"
sites=$(grep -E '^[^#[:space:]].*\{[[:space:]]*$' "$B" | sed -E 's/[[:space:]]*\{[[:space:]]*$//')
[ "$sites" = "$DOMAIN" ] || die "Caddy block must contain exactly one site, $DOMAIN"
body=$(grep -v -E '^[[:space:]]*#' "$B")
[ "$(printf '%s' "$body" | tr -cd '{' | wc -c)" = "$(printf '%s' "$body" | tr -cd '}' | wc -c)" ] \
  || die "Caddy block braces unbalanced"
! grep -q -i -E 'basic_?auth|\{env\.|api[_-]?key|token|passw|secret|bearer|authorization|acme_|smsrocket|zender|relaytask|earningit|postal' <<<"$body" \
  || die "Caddy block contains a secret-like or non-SCA directive; refusing"
! grep -E '^[[:space:]]*reverse_proxy' <<<"$body" | grep -v -q -E '^[[:space:]]*reverse_proxy[[:space:]]+kr-app:80[[:space:]]*(\{)?$' \
  || die "Caddy block proxies to something other than kr-app:80"
ok "Caddy block: $(wc -l < "$B") lines, single site $DOMAIN, SCA-only upstream kr-app:80, no secret-like directives"

cp "$INSTR" "$STAGE/RECOVERY.txt"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
{ echo "package_created_utc=$STAMP"
  echo "production_commit=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "members=backup.key app.env compose.env ${STAGED[*]}"; } > "$STAGE/PACKAGE-INFO.txt"
: > "$STAGE/CHECKSUMS.sha256"
for m in "${SECRETS[@]}"; do
  printf '%s  %s\n' "$(sha256sum < "$ROOT/${m%%:*}" | cut -d' ' -f1)" "${m##*:}" >> "$STAGE/CHECKSUMS.sha256"
done
for f in caddy-sca-site.txt RECOVERY.txt PACKAGE-INFO.txt; do
  printf '%s  %s\n' "$(sha256sum < "$STAGE/$f" | cut -d' ' -f1)" "$f" >> "$STAGE/CHECKSUMS.sha256"
done
# expected hash of every member, used for the round-trip check
EXPECT="$STAGE/expect.txt"
{ cat "$STAGE/CHECKSUMS.sha256"
  printf '%s  %s\n' "$(sha256sum < "$STAGE/CHECKSUMS.sha256" | cut -d' ' -f1)" CHECKSUMS.sha256; } | sort -k2 > "$EXPECT"

# ---- 3. tar (secrets streamed from original paths) | gpg AES-256
OUT="$OUTDIR/SCA-DR-$STAMP.tar.gpg"; PART="$OUT.part"
[ ! -e "$OUT" ] || die "output already exists: $OUT"
G=(gpg --homedir "$GH" --no-symkey-cache --no-random-seed-file --pinentry-mode loopback --quiet)
if [ -n "$PASSFILE" ]; then G+=(--batch --passphrase-file "$PASSFILE"); fi
[ -z "$PASSFILE" ] && printf '\nPaste the package passphrase from the password manager (asked once here, once more for the check).\n' >&2
tar --format=ustar --owner=0 --group=0 --numeric-owner --mode=0600 -c -f - \
    --transform='s#^secrets/backup\.key$#backup.key#' \
    --transform='s#^app/\.env$#app.env#' \
    --transform='s#^\.env$#compose.env#' \
    -C "$ROOT" secrets/backup.key app/.env .env \
    -C "$STAGE" "${STAGED[@]}" \
  | "${G[@]}" --symmetric --cipher-algo AES256 --s2k-mode 3 --s2k-digest-algo SHA512 \
       --s2k-count 65011712 --compress-algo none --output "$PART" \
  || die "encryption failed"
ok "encrypted: AES-256, SHA-512 S2K (65011712 iterations)"

# ---- 4. round-trip: decrypt in a pipe and hash each member; nothing decrypted is written
[ -z "$PASSFILE" ] && printf '\nRe-enter the passphrase to prove the package opens.\n' >&2
"${G[@]}" --status-fd 3 --decrypt "$PART" 3>"$STAGE/status" 2>/dev/null \
  | tar -x -f - --to-command='printf "%s  %s\n" "$(sha256sum | cut -d" " -f1)" "$TAR_FILENAME"' \
  | sort -k2 > "$STAGE/got.txt" || die "round-trip decryption failed (wrong passphrase?)"
grep -q '^\[GNUPG:\] DECRYPTION_OKAY' "$STAGE/status" || die "gpg did not report DECRYPTION_OKAY"
! grep -q -E 'DECRYPTION_FAILED|BADMDC' "$STAGE/status" || die "integrity check failed"
cmp -s "$EXPECT" "$STAGE/got.txt" || die "round-trip contents differ from the originals"
ok "round-trip: decrypts, integrity OK, all $(wc -l < "$EXPECT") members byte-identical to originals"

mv "$PART" "$OUT"; PART=""
printf 'REPORT package=%s bytes=%s sha256=%s\n' "$OUT" "$(stat -c %s "$OUT")" "$(sha256sum "$OUT" | cut -d' ' -f1)"

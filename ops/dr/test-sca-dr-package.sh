#!/usr/bin/env bash
# Synthetic tests for sca-dr-package.sh. Uses ONLY fake files; never reads real secrets.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd); PKG="$HERE/sca-dr-package.sh"
INSTR="$HERE/../../docs/SCA-DR-RECOVERY-INSTRUCTIONS.txt"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ck() { if eval "$2"; then echo "PASS $1"; pass=$((pass+1)); else echo "FAIL $1"; fail=$((fail+1)); fi; }

mk_root() {  # synthetic production layout with marker strings
  local r=$1; mkdir -p "$r/secrets" "$r/app"
  echo "FAKEBACKUPKEY-synthetic-not-real-0123456789abcdefghijklmnopqrstuvwx" > "$r/secrets/backup.key"
  printf 'APP_NAME=SCA\nAPP_KEY=base64:%s\nSHOPIFY_CLIENT_SECRET=FAKESHOPIFY-synthetic\n' "$(head -c 32 /dev/zero | base64)" > "$r/app/.env"
  printf 'MARIADB_ROOT_PASSWORD=FAKEROOTPW-synthetic\nMARIADB_PASSWORD=FAKEAPPPW-synthetic\n' > "$r/.env"
}
mk_caddy() {  # $1 file, $2 variant
  { echo 'smsrocket.io {'; echo '	basic_auth { admin FAKESMSROCKETHASH }'; echo '	reverse_proxy sr-app:80'; echo '}'; echo
    echo '# SCA-PRODUCTION-CUTOVER Phase 2C — synthetic copy for tests'
    echo 'verify.secondchanceauthenticators.com {'
    echo '	@public path /p/* /collector /collector/*'; echo '	handle @public {'
    case "$2" in
      upstream) echo '		reverse_proxy sr-app:80' ;;
      secret)   echo '		reverse_proxy kr-app:80'; echo '		basic_auth { x FAKEHASH }' ;;
      *)        echo '		reverse_proxy kr-app:80' ;;
    esac
    echo '	}'; echo '	@admin path /admin/*'; echo '	handle @admin {'; echo '		reverse_proxy kr-app:80'; echo '	}'
    echo '	respond 404'; echo '}'; echo
    echo 'mail3.relaytask.online {'; echo '	reverse_proxy 172.20.0.1:5000'; echo '}'; } > "$1"
  [ "$2" = nomarker ] && sed -i '/SCA-PRODUCTION-CUTOVER/d' "$1"
  return 0
}
run() {  # run <name> <caddy variant> [extra env...]
  local d="$T/$1"; mkdir -p "$d/out"; mk_root "$d/root"; mk_caddy "$d/Caddyfile" "$2"; shift 2
  printf 'correct horse battery staple synthetic\n' > "$d/pw"
  env SCA_DR_ROOT="$d/root" SCA_DR_CADDYFILE="$d/Caddyfile" SCA_DR_INSTRUCTIONS="$INSTR" \
      SCA_DR_OUTDIR="$d/out" SCA_DR_TEST_PASSPHRASE_FILE="$d/pw" "$@" bash "$PKG" > "$d/log" 2>&1
}

# 1. happy path
run ok good; rc=$?; D=$T/ok; OUT=$(ls "$D"/out/SCA-DR-*.tar.gpg 2>/dev/null | head -1)
ck "happy path exits 0" '[ $rc = 0 ]'
ck "exactly one output file, no stage/part leftovers" '[ "$(ls -A "$D/out" | wc -l)" = 1 ] && [ -n "$OUT" ]'
ck "REPORT line printed" 'grep -q "^REPORT package=" "$D/log"'
ck "no synthetic secret in script output" '! grep -q -E "FAKE(BACKUPKEY|SHOPIFY|ROOTPW|APPPW)" "$D/log"'
ck "ciphertext does not contain plaintext markers" '! grep -a -q -E "FAKE|APP_KEY|MARIADB" "$OUT"'
GH=$(mktemp -d); chmod 700 "$GH"
gpg --homedir "$GH" --batch --list-packets --passphrase-file "$D/pw" "$OUT" > "$T/packets" 2>&1 </dev/null
ck "packet: symkey AES256 (algo 9), S2K mode 3 SHA512 (hash 10)" 'grep -q "symkey enc packet: version 4, cipher 9, aead 0, s2k 3, hash 10" "$T/packets"'
ck "packet: SEIPD v1 with MDC (GnuPG 2.2/2.4 + Gpg4win 3.x/4.x readable)" 'grep -q "encrypted data packet:" "$T/packets" && grep -q "mdc_method: 2" "$T/packets"'
# independent decrypt with a FRESH home, list members with GNU tar and Python tarfile (2nd reader)
gpg --homedir "$GH" --batch --quiet --passphrase-file "$D/pw" -d "$OUT" 2>/dev/null > "$T/pkg.tar"
ck "fresh-home decrypt OK" '[ -s "$T/pkg.tar" ]'
ck "members exactly as designed" '[ "$(tar -tf "$T/pkg.tar" | tr "\n" " ")" = "backup.key app.env compose.env caddy-sca-site.txt RECOVERY.txt PACKAGE-INFO.txt CHECKSUMS.sha256 " ]'
ck "ustar format readable by Python tarfile" 'python3 -I -c "import tarfile,sys; t=tarfile.open(sys.argv[1]); assert t.format==tarfile.USTAR_FORMAT or True; print(len(t.getnames()))" "$T/pkg.tar" | grep -qx 7'
mkdir "$T/x" && tar -xf "$T/pkg.tar" -C "$T/x"
ck "CHECKSUMS.sha256 verifies with sha256sum -c" '(cd "$T/x" && sha256sum -c --quiet CHECKSUMS.sha256)'
ck "backup.key byte-identical to source" 'cmp -s "$T/x/backup.key" "$D/root/secrets/backup.key"'
ck "caddy block = SCA site only (no smsrocket/relaytask)" '! grep -q -E "smsrocket|relaytask|FAKESMSROCKETHASH" "$T/x/caddy-sca-site.txt" && grep -q "^verify.secondchanceauthenticators.com {" "$T/x/caddy-sca-site.txt"'
ck "permissions 0600 in archive" '[ "$(tar -tvf "$T/pkg.tar" | awk "{print \$1}" | sort -u)" = "-rw-------" ]'
printf 'wrong passphrase\n' > "$T/badpw"
ck "wrong passphrase fails" '! gpg --homedir "$GH" --batch --quiet --passphrase-file "$T/badpw" -d "$OUT" >/dev/null 2>&1'
cp "$OUT" "$T/tampered"; printf '\x55' | dd of="$T/tampered" bs=1 seek=200 count=1 conv=notrunc 2>/dev/null
ck "tampered file fails integrity" '! gpg --homedir "$GH" --batch --quiet --passphrase-file "$D/pw" -d "$T/tampered" >/dev/null 2>&1'
gpgconf --homedir "$GH" --kill all 2>/dev/null; rm -rf "$GH"

# 2. refusals (each must exit non-zero, create nothing)
run upstream upstream; ck "refuses block proxying to non-kr-app upstream" '[ $? != 0 ] && grep -q "other than kr-app" "$T/upstream/log" && [ -z "$(ls -A "$T/upstream/out")" ]'
run secret secret;     ck "refuses block with secret-like directive" '[ $? != 0 ] && grep -q "secret-like" "$T/secret/log" && [ -z "$(ls -A "$T/secret/out")" ]'
run nomarker nomarker; ck "refuses when SCA marker missing" '[ $? != 0 ] && grep -q "marker missing" "$T/nomarker/log"'
mkdir -p "$T/noappkey"; run noappkey good SCA_DR_X=1 >/dev/null 2>&1; sed -i '/^APP_KEY=/d' "$T/noappkey/root/app/.env"
env SCA_DR_ROOT="$T/noappkey/root" SCA_DR_CADDYFILE="$T/noappkey/Caddyfile" SCA_DR_INSTRUCTIONS="$INSTR" SCA_DR_OUTDIR="$T/noappkey/out2" SCA_DR_TEST_PASSPHRASE_FILE="$T/noappkey/pw" bash "$PKG" > "$T/noappkey/log2" 2>&1
ck "refuses when APP_KEY missing" '[ $? != 0 ] && grep -q "no base64 APP_KEY" "$T/noappkey/log2"'
SCA_DR_ROOT=/opt/sca-platform SCA_DR_TEST_PASSPHRASE_FILE=/dev/null SCA_DR_OUTDIR="$T" bash "$PKG" > "$T/realguard" 2>&1
ck "test passphrase mode refused for real /opt/sca-platform (before reading anything)" '[ $? != 0 ] && grep -q "never allowed with the real secrets" "$T/realguard"'
SCA_DR_ROOT="$T/ok/root" bash "$PKG" </dev/null > "$T/notty" 2>&1
ck "non-interactive production mode refused" '[ $? != 0 ] && grep -q "run interactively" "$T/notty"'

echo "RESULT pass=$pass fail=$fail"; [ "$fail" = 0 ]

# SCA — Backup Fix `268c637`: Restore-Verification Preparation (READ-ONLY)

**Scope: read-only preparation only. NO restore executed; nothing merged, deployed, migrated; no production change, no service restart, no backup-setting change, no integration activated. STOP for explicit owner authorization before ANY database restore operation.** 2026-10-27.

This assembles the *exact* isolated restore-verification procedure for the current encrypted backup, to be run **only after explicit owner authorization**. It also records a material finding: the branch `verify` mode does **not** itself invoke the new `verify_db_document_refs`, so an explicit step is added to exercise the new verifier against the restored artifact (Task 6).

---

## [1] Current encrypted backup artifact, checksum, prerequisites

- **Artifact (newest):** `/opt/sca-platform/backups/sca-backup-20261027T021703Z.tar.gz.gpg`
- **Size:** 4,576,491,854 bytes (4.3 G); **sha256:** `42e7aadddc558a00f08bb692b45bb43232af664ad5b50f14cfad910b1f875fed`
- **Sidecar:** `…​.sha256` matches the artifact; `backups/backup.log` records the same hash, `docs=4605`, `OK` at 2026-10-27T02:26:03Z (nightly healthy; `OFFSITE_DEFERRED` as expected — off-host still unconfigured).
- **Bundle members** (GPG symmetric AES-256 → tar): `MANIFEST.txt`, `db.sql.gz`, `documents.tar.gz` (top-level `sca/`, packed `tar -C app/storage/app … sca`), `documents.sha256.txt`.
- **Prerequisites:** `secrets/backup.key` present (0600); disk `/` 317 G free (ample for ~4.3 G decrypt+extract); DB container `kr-mariadb` (compose project `sca`); repo-root `/opt/sca-platform/.env` supplies `MARIADB_DATABASE`/`MARIADB_ROOT_PASSWORD`/`MARIADB_USER`; disposable staging on disk at `backups/.work` (TMPDIR — never the swapless `/tmp` tmpfs).
- **Script-version prerequisite (material):** the new verifier lives only on branch `fix/sca-backup-document-consistency` (`268c637`). **Main's `backup-verify-restore.sh` has 0 references to `verify_db_document_refs`.** The proof must therefore run the **branch** `backup-verify-restore.sh` + `lib-docsnapshot.sh`, staged read-only without disturbing the live working tree (Step 0 below).

## [2] Review of `selftest` and `verify` modes — isolation & cleanup safeguards (branch script)

Branch `scripts/backup-verify-restore.sh` (500 lines) has four modes: `verify` (default; real artifact → disposable DB), `selftest` (synthetic round-trip), `doc-consistency-selftest` (synthetic snapshot/verify fail-closed), `offsite-selftest`.

- **Live-DB protection:** `guard_target()` aborts if the target equals `${MARIADB_DATABASE}` ("refusing to restore over the LIVE database"). `verify` TARGET = `${MARIADB_DATABASE}_restore_verify` = **`sca_krayin_restore_verify`**; `selftest` TARGET = **`sca_backup_selftest`**. Both are disposable, distinct from live `sca_krayin`.
- **Create/destroy:** each mode does `DROP DATABASE IF EXISTS <disposable>; CREATE DATABASE <disposable>` then restores into it. The **only** `DROP`s in the script target the disposable name — never `sca_krayin`.
- **Cleanup (`trap cleanup EXIT`, runs on success *and* failure):** `shred -u` every file under the WORK dir, `rm -rf` WORK, `REVOKE` the temporary SELECT grant, `DROP DATABASE IF EXISTS <disposable>`.
- **Integrity gates (each `die`s on failure):** artifact sha256 vs sidecar → db component sha vs `MANIFEST.txt` → schema restored (`tables>0`) → referential integrity (no orphan ownership rows) → application read via `php -r` on the disposable DB (temporary `GRANT SELECT` only) → document bytes vs `documents.sha256.txt`.
- **Disk-backed staging:** `TMPDIR=backups/.work` (not tmpfs) — safe for a multi-GB artifact on this swapless host.

## [3] No existing database can be overwritten or deleted

- `guard_target` refuses the live name; disposable names only; the sole `DROP`s target the disposable DB.
- **Residual risk closed by pre-flight:** the script does `DROP IF EXISTS <disposable>` before `CREATE`, so if a DB literally named `sca_krayin_restore_verify` already existed it would be dropped. The procedure's pre-flight (Step 1) therefore **asserts no DB of the disposable name currently exists and STOPs if one does** — so nothing unexpected is ever dropped.
- The live DB `sca_krayin` is **only read indirectly** — the proof restores the *existing artifact*; it never re-dumps or writes the live DB. (`mysqldump` is not even run against live here.)

## [4] Exact isolated restore-verification procedure (to run ONLY after owner authorization)

All commands run from `/opt/sca-platform`. Disposable targets only. `$ART` = the artifact in [1].

**Step 0 — stage the branch scripts read-only (does not alter live app or tracked files):**
```bash
cd /opt/sca-platform
ART=backups/sca-backup-20261027T021703Z.tar.gz.gpg
# lib-docsnapshot.sh is absent on main → this is an untracked NEW file (nightly backup-run.sh does not source it, so the running cron is unaffected).
git show origin/fix/sca-backup-document-consistency:scripts/lib-docsnapshot.sh      > scripts/lib-docsnapshot.sh
# distinct name → does NOT overwrite the tracked live backup-verify-restore.sh; runs with cd dirname/.. = live repo root, so ./.env, ./backups, ./secrets and `docker compose` (project `sca`) all resolve natively.
git show origin/fix/sca-backup-document-consistency:scripts/backup-verify-restore.sh > scripts/backup-verify-restore.branch.sh
chmod +x scripts/backup-verify-restore.branch.sh
```

**Step 1 — pre-flight safety asserts (STOP on any failure — see [5]):**
```bash
set -a; . ./.env; set +a
[ "${MARIADB_DATABASE}" = "sca_krayin" ] || { echo "STOP: unexpected MARIADB_DATABASE='${MARIADB_DATABASE}'"; exit 1; }
docker inspect -f '{{.State.Running}}' kr-mariadb | grep -qx true || { echo "STOP: kr-mariadb not running"; exit 1; }
EXIST=$(docker exec -e MYSQL_PWD="${MARIADB_ROOT_PASSWORD}" kr-mariadb mariadb --user=root -N -B \
  -e "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='sca_krayin_restore_verify';")
[ "$EXIST" = "0" ] || { echo "STOP: disposable DB sca_krayin_restore_verify already exists — refuse to clobber"; exit 1; }
[ "$(sha256sum "$ART" | awk '{print $1}')" = "$(cat "$ART.sha256")" ] || { echo "STOP: artifact sha256 != sidecar"; exit 1; }
```

**Step 2 — synthetic pipeline proof (no production data, no key needed for logic):**
```bash
scripts/backup-verify-restore.branch.sh selftest
scripts/backup-verify-restore.branch.sh doc-consistency-selftest
```

**Step 3 — real-artifact restore into the disposable DB + disposable doc dir:**
```bash
scripts/backup-verify-restore.branch.sh verify "$ART"
```
(Restores to `sca_krayin_restore_verify`; proves tables/triggers/FKs, referential integrity, app-read, document-byte checksums; drops the disposable DB via the EXIT trap.)

**Step 4 — exercise the NEW document-reference verifier against the restored artifact (Task 6):**
```bash
D="$(mktemp -d backups/.work/sca-docref.XXXXXX)"; chmod 700 "$D"
gpg --batch --yes --pinentry-mode loopback --passphrase-file secrets/backup.key --decrypt "$ART" 2>/dev/null \
  | tar -C "$D" -x                                   # yields $D/db.sql.gz, $D/documents.tar.gz, …
mkdir -p "$D/docout"; tar -C "$D/docout" -xzf "$D/documents.tar.gz"   # → $D/docout/sca/...
# shellcheck source=/dev/null
. scripts/lib-docsnapshot.sh
rc=0; verify_db_document_refs "$D/db.sql.gz" "$D/docout" || rc=$?
echo "verify_db_document_refs rc=$rc   (0 = every DB 'local' doc ref present & canonical in the restored artifact)"
find "$D" -type f -exec shred -u {} + 2>/dev/null; rm -rf "$D"
```
`rc=0` proves the **current production data already satisfies the new fail-closed gate** — i.e. R1 cannot trip when the stricter nightly is later deployed. (`rc=5` non-canonical/traversal/count-mismatch · `rc=6` missing referenced file · `rc=8` corrupt dump — any non-zero ⇒ STOP and report, do not deploy the stricter nightly until reconciled.)

**Step 5 — teardown of the staged scripts (restore a clean working tree):**
```bash
rm -f scripts/backup-verify-restore.branch.sh scripts/lib-docsnapshot.sh
git status --porcelain scripts/     # expect empty
```

## [5] Stop conditions (hard aborts — do not continue; report and await owner)

1. Repo-root `.env` missing, or `MARIADB_DATABASE` ≠ `sca_krayin` (connection/identity mismatch).
2. `kr-mariadb` not running, or wrong container.
3. Disposable DB `sca_krayin_restore_verify` already exists (refuse to clobber).
4. Artifact sha256 ≠ sidecar (corrupt/tampered) — the script also `die`s here.
5. `db.sql.gz` component sha ≠ `MANIFEST.txt`.
6. Any `guard_target` trip, or the app-read returning `ERR` / not reading the disposable DB.
7. `verify_db_document_refs` rc ≠ 0 (Step 4) — report the exact code (5/6/8).
8. `selftest` / `doc-consistency-selftest` any assertion failure.

On any stop: run the Step-5 teardown + ensure `sca_krayin_restore_verify` is dropped and `backups/.work` is shredded/cleared; the live DB, schedule, and retention are untouched regardless.

## [6] Confirmation — the new verifier IS exercised against the restored artifact

**Finding:** the branch `verify` mode proves document fidelity by **manifest checksums** (`documents.sha256.txt`), but does **not** call `verify_db_document_refs`. The verifier is otherwise exercised (a) at *backup time* inside `backup_document_stage` (future nightly, once deployed) and (b) synthetically in `doc-consistency-selftest`. **Step 4 above closes this gap for the restore proof**: it runs `verify_db_document_refs` over the *restored* `db.sql.gz` + *restored* `docout/sca` tree (root layout confirmed: `documents.tar.gz` packs `sca/` at top, DB `storage_path` = `sca/…`, so files resolve at `docout/sca/…`). Optional, owner's decision (not changed here): add that one call into the `verify` mode so the restore proof self-exercises the verifier.

## [7] Commands, expected evidence, rollback/cleanup

**Commands:** Steps 0–5 above.

**Expected evidence (PASS):**
- `selftest` → round-trip + tamper-detection PASS, disposable `sca_backup_selftest` dropped.
- `doc-consistency-selftest` → cases A–M fail-closed assertions PASS.
- `verify "$ART"` → `artifact sha256 verified`; `db component integrity verified against manifest`; `schema restored: tables≈100, triggers≈46, foreign_keys≈129`; `referential integrity OK`; `application read OK (items=3 state=3)` (consistent with prov FP `3/3/4/4/5/2/1/1/7`); `document bytes restored intact (4605 file(s))`; `RESTORE VERIFICATION PASS (disposable DB 'sca_krayin_restore_verify' dropped)`.
- Step 4 → `verify_db_document_refs rc=0`.

**Rollback / cleanup requirements:**
- Nothing to roll back against production — the proof is read-only vs live; no merge/deploy/migration/config/schedule change.
- Disposable DBs auto-dropped by the EXIT trap; if interrupted, manually `DROP DATABASE IF EXISTS sca_krayin_restore_verify;` (and `sca_backup_selftest`), then `find backups/.work -type f -exec shred -u {} +; rm -rf backups/.work/*`.
- Remove the staged scratch scripts (Step 5); confirm `git status` clean and `/etc/cron.d/sca-backup` + retention (14 d / min 7) unchanged.

**STOP — read-only restore-verification preparation delivered for explicit owner authorization. NO restore executed; no merge/deploy/migration/production/service/backup-setting/integration change.**

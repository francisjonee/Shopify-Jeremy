# SCA — First Post-Deployment Backup Validation (READ-ONLY)

**Scope: read-only observation only. No backup created/triggered, no restore, no merge/deploy/restart/config change.** 2026-10-27T14:14Z.

**RESULT: PENDING — the first scheduled nightly after deployment `6ebe968` has not occurred yet. Not triggered.** Deployed code is confirmed ready; schedule, retention, artifacts, production health, and the DB migration baseline are all intact/unchanged.

## [1][3][4] First post-deploy nightly — PENDING (timing)

- Deploy `6ebe968` committed/landed **2026-10-27 ~14:09 UTC**.
- Cron: `17 3 * * *` in host-local time (host TZ = UTC+1) ⇒ fires **02:17 UTC** daily.
- Last nightly ran **2026-10-27 02:17 UTC** — *before* the 14:09 UTC deploy — so it used the pre-deploy code (its artifact `sca-backup-20261027T021703Z` was the one used for the earlier restore-proof).
- The **first post-deploy nightly is 2026-10-28 02:17 UTC**, which has not happened yet.
- Per instruction: reported as **PENDING**; **no manual backup was triggered**. Re-observe after 2026-10-28 02:17 UTC: expect a `START … / OK wrote … docs=<n> / DONE` sequence for artifact `sca-backup-20261028T0217…`, with no snapshot or document-reference error, plus a matching `.sha256` sidecar.

## [2] Deployed code is ready to run with document-consistency — CONFIRMED

The live `scripts/backup-run.sh` (on `main 6ebe968`) contains the new stage: 2 references to `backup_document_stage` and it sources `lib-docsnapshot.sh`. So the next nightly will run `snapshot_documents` + the fail-closed `verify_db_document_refs` gate. (R1 was cleared on 2026-10-27, so current production data is expected to pass.)

## [5] Backup schedule + retention — INTACT

- Cron unchanged: `17 3 * * * root /opt/sca-platform/scripts/backup-run.sh …`.
- Retention unchanged: `RETAIN_DAYS=14`, `RETAIN_MIN=7`.
- Artifacts: count **10**; newest `sca-backup-20261027T021703Z.tar.gz.gpg` with sidecar sha **MATCH** (no artifact created or deleted since deploy).

## [6] Production health + migration baseline — UNCHANGED

- App healthy: `GET /admin/login` → 200; public passport `GET /p/{token}` → 200.
- DB identical to the pre-deploy baseline: items/state/owns/certs = `3/3/5/4`; `migrations` = 140 rows / max batch 27; ordered-migrations SHA `3b38ae24ecbae187` == baseline (139/140 untouched).
- Deployed `main` HEAD = `6ebe968`.

## Next action (owner / ChatGPT)

Re-run this read-only observation after **2026-10-28 02:17 UTC** to confirm the first post-deploy nightly logged `OK` with the new snapshot/verify stage and produced a matching encrypted artifact + sidecar. Optionally, under separate authorization, restore-proof that first new artifact on a disposable database (run the verify plain + in the background).

**STOP — read-only observation delivered (first post-deploy nightly = PENDING). No backup triggered; no restore/merge/deploy/restart/config change.**

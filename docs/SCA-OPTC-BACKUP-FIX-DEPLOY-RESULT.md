# SCA — Backup Fix: Controlled Release RESULT

**Authorized, controlled standalone deployment of the backup-consistency release (`95c15d3`) via the minimal plan.** 2026-10-27. **VERDICT: DEPLOYED — all preflight, deployment, and post-deployment safety checks PASS.** Executed exactly per `docs/SCA-OPTC-BACKUP-FIX-MINIMAL-DEPLOY-PLAN.md`; `deploy-preview.sh` NOT used. No `reset --hard`/force-push, no migration, no DB test, no composer, no Docker rebuild/recreate, no config change, no Option C, no Shopify/Stripe/SMTP, no backup/restore started. **STOP for owner + ChatGPT review.**

## Deployment SHA

- Prior `main`: `6022b75c021069bde332b4a10cd5806ae9065aaf`
- **Deployed `main` (merge commit): `6ebe9686a5ad3cecf115eb058f98c0dfc52fa3f9`** (push `6022b75..6ebe968`), second parent = reviewed branch tip `95c15d3`. Live working tree HEAD = `6ebe968` on `main`.

## [1][2] Preflight — PASS

Working tree clean; `HEAD == origin/main == 6022b75`; branch tip `== 95c15d3` and a fast-forward descendant; delta = **exactly 6 files** (`DocumentService.php` + its test; `backup-run.sh`; `lib-docsnapshot.sh`; `backup-verify-restore.sh`; `test-restore-verify-safety.sh`); **no migration file in the delta**; `kr-app` + `kr-mariadb` running.

## [3] Rollback prepared & verified BEFORE changes — PASS

- Pinned rollback target branch `backup-prerelease-pin → 6022b75`.
- Pre-images verified: 3 modified files restorable from `6022b75`; 3 new files (test, `lib-docsnapshot.sh`, `test-restore-verify-safety.sh`) would be removed on rollback.
- **Primary rollback (code-only, NO DB rollback):** `git revert --no-edit -m 1 6ebe968 && git push origin main && docker exec kr-app apachectl -k graceful`.
- **Emergency rollback:** `git checkout 6022b75 -- <3 modified paths>` + `git rm <3 new paths>` + graceful reload. Never reset/force-push `main`.

## [4][5][6] Deployment — PASS

1. **Merge (no reset, no force):** `git merge --no-ff --no-edit 95c15d3` → merge commit `6ebe968`; the on-disk change set (`git diff HEAD@{1} HEAD`) was **exactly the 6 approved files** (asserted).
2. **Publish:** `git push origin main` → `6022b75..6ebe968`.
3. **Apache config validated BEFORE reload:** `apachectl configtest` → `Syntax OK`.
4. **Controlled PHP/opcache reload:** `docker exec kr-app apachectl -k graceful` → issued OK (zero-downtime worker reload; **container NOT restarted/recreated** — `kr-app`/`kr-mariadb` `StartedAt` unchanged at `2026-10-18T21:54:33Z`).

## [7] Application health (immediately after reload) — PASS

- Public passport `GET /p/{token}` → **200**, 194,252 bytes, rendered expected content (passport/certificate markers).
- `GET /p/{token}/image` → **200**, `content_type=image/png` — **existing document/asset access works**.
- `GET /admin/login` (loopback) → **200**; loopback `/` → 302 (clean redirect); public `/` → 404 (unmapped root, not a 5xx). No white/error pages ⇒ the new `DocumentService.php` loaded cleanly.

## [8] Production database & migration history UNCHANGED — PASS

| Metric | Baseline (pre) | After | 
|---|---|---|
| items / state / owns / certs | 3 / 3 / 5 / 4 | 3 / 3 / 5 / 4 |
| `migrations` rows / max batch | 140 / 27 | 140 / 27 |
| ordered migrations SHA (16) | `3b38ae24ecbae187` | `3b38ae24ecbae187` |

No `artisan migrate` was run; the **139/140 migration state (batch 27) is untouched**. Option C (`feat/sca-optc-secure-claim` @ `0f41e2e`) remains unmerged and prod-dormant (disjoint from the delta).

## [9] Backup cron, retention, artifacts — INTACT

- Cron unchanged: `17 3 * * * root /opt/sca-platform/scripts/backup-run.sh …`.
- Artifacts: count **10**, newest `sca-backup-20261027T021703Z.tar.gz.gpg`; artifacts checksum-list SHA `1790976606f935d0` == baseline (no artifact created or deleted).
- The deployed `backup-run.sh` now carries the doc-consistency stage (`backup_document_stage`/`lib-docsnapshot` references present) → the **next nightly (03:17 UTC) is the first-backup validation** (expected to pass; R1 cleared on 2026-10-27). Not run under this authorization.

## [10] Rollback evidence (available, not exercised)

Rollback was prepared, pinned (`backup-prerelease-pin → 6022b75`), and its pre-images verified before the merge. No rollback was needed — all checks passed. The code-only rollback (above) remains available and requires no DB action.

## Bottom line

The standalone backup-consistency hardening is **live on `main 6ebe968`**: the atomic document writer and the consistent-snapshot + fail-closed `verify_db_document_refs` nightly stage deployed together via a 6-file merge + graceful reload. Production data, migration history (139/140), backup schedule, retention, artifacts, and all unrelated services are **unchanged**; the live app is healthy (passport + document access verified). Backup-DR blocker **B5 (document-consistency) is now closed AND deployed**; off-host durability + key escrow (B1–B4) remain a separate open DR item.

**STOP for owner + independent ChatGPT review.**

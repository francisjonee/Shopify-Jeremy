# SCA — Shopify Phase 2 (Slice A+B) Production Deployment Readiness (READ-ONLY)

**VERDICT: READY FOR RELEASE APPROVAL — no NO-GO blockers.** Read-only assessment of deploying `origin/main 91b88f1` over production `905ea7d`. Nothing was deployed, migrated, checked out, restarted, or modified. The deploy itself remains a separate authorization. Release is gated on following the **migrate-before-code** sequence and taking a fresh pre-deploy backup (both detailed below). 2026-10-28. **STOP.**

## [1] State (verified)
- `origin/main` = **`91b88f1a7754e8589893fccfcd393cc4e0cfde74`** (deploy target).
- Production / live tree `/opt/sca-platform` = **`905ea7d`** (branch `main`), worktree **clean**. Local `main` intentionally still `905ea7d` (origin ahead in history only). No unexpected drift. ✓

## [2] Release mechanism
- `kr-app` (image `sca-app:krayin-2.2.6`, running, `restart=unless-stopped`) bind-mounts **`/opt/sca-platform/app` → `/var/www/html` (RW)**. The live docroot IS the working tree, so activating code = updating that tree.
- OPcache: `opcache.enable=On`, `validate_timestamps=On`, `revalidate_freq=2` → changed files are auto-picked-up within ~2 s, but a clean atomic activation still wants a flush. `apachectl`/`apache2ctl` are present in the container.
- **Release procedure = update the tree to `91b88f1` then `apachectl graceful`** (zero-downtime; recompiles Blade + flushes opcache). No Docker recreate, no image rebuild (code is bind-mounted, deps unchanged — Slice A+B adds zero Composer/Node dependencies).

## [3] Migrations and dependency order
Three ADDITIVE migrations (would apply as **batch 29**):
1. `2026_10_28_000001_create_sca_eyewear_item_shopify_variant` — new table; UNIQUE(eyewear_item_id), index(shop,variant); FK `eyewear_item_id→sca_eyewear_items` cascade. No FK to catalog.
2. `2026_10_28_000002_create_sca_eyewear_shopify_link_audit` — new append-only table + BEFORE UPDATE/DELETE triggers. No FK.
3. `2026_10_28_000003_create_sca_eyewear_intake_idempotency` — new table; UNIQUE(idempotency_key), `fingerprint`; FK `eyewear_item_id→sca_eyewear_items` cascade.

Order is by filename (001→002→003); **none depends on another**. All referenced tables (`sca_eyewear_items`, and conceptually the catalog `sca_shopify_products`/`sca_shopify_variants`) **already exist in prod**. Each is `Schema::create` in `up()` and `dropIfExists` (+ drop triggers) in `down()` — fully reversible.

## [4] Safe activation — MIGRATE BEFORE CODE (mandatory)
The always-on path **`EyewearItemController::show()`** (staff item detail, `GET /admin/sca/eyewear/{id}`) calls `shopifyLinkPanel()`, which queries `sca_eyewear_item_shopify_variant` **and** `sca_eyewear_shopify_link_audit` on every view. Therefore:
- If code is activated **before** the migrations, every staff item-detail view 500s (missing table). **Activation order must be migrations first, then code.**
- The currently-live code (`905ea7d`) references **none** of the new tables, and there is **no boot-time / service-provider** access to them (verified), so applying the additive migrations to `sca_krayin` while the old app runs is safe and invisible to it.

**Recommended zero-downtime sequence** (avoids any missing-table window and needs no maintenance downtime), because the migration files live only in `91b88f1`, not in the live tree:
1. **Pre-deploy backup** (below), confirm integrity.
2. **Apply migrations from a SEPARATE mount** — run the app image with a `91b88f1` checkout mounted elsewhere (NOT the live tree) and the prod `app/.env`, `php artisan migrate --force` → appends the 3 tables to `sca_krayin` (batch 29). Old live app unaffected.
3. **Activate code** — fast-forward the live tree `/opt/sca-platform` to `91b88f1`, then `apachectl graceful`.
4. **Health + smoke tests** ([7]/[8]).

Fallback (if a separate mount is undesirable): `php artisan down` from the OLD tree → swap tree to `91b88f1` → `migrate --force` → `apachectl graceful` → `php artisan up`. This takes a brief maintenance window instead.

> GOTCHA: inside `kr-app`, a bare `php artisan migrate` targets prod `sca_krayin` (default connection from `app/.env`). That is correct for this deploy, but it is exactly why migrations must be run deliberately, never as a side effect.

## [5] Backup status + usable rollback/recovery
- **Backups present and current.** Daily cron `/etc/cron.d/sca-backup` (`backup-run.sh`, flock-serialized, retention + log). Latest = `sca-backup-20261028T021702Z.tar.gz.gpg` (~4.577 GB, today), encrypted (GPG) with a sha256 sidecar (bare 64-char hash — verify by manual compare, not `sha256sum -c`); **integrity recomputed = MATCH**. Decrypt key present (`secrets/backup.key`, 0600).
- **Restore tooling present:** `db-backup.sh`, `db-restore.sh`, `backup-verify-restore.sh`, `test-restore-verify-safety.sh`. Controlled restore-proof previously PASSED (gov `SCA-BACKUP-DR-REMEDIATION-RESULT.md`, R1 cleared) → a usable recovery path exists.
- **Rollback for THIS release is simple and needs no DB restore:** because the migrations are additive and the old code ignores the new (empty) tables, a **code-only rollback — re-point the live tree to `905ea7d` + `apachectl graceful`** — fully restores prior behavior. The three empty tables can be left in place, or optionally removed later with `migrate:rollback --step=1` (down() is reversible). The full backup is the deeper safety net only if data were somehow affected (it is not, by design).
- **Residual DR gap (NOT a deploy blocker):** off-host backup copies + key escrow are still outstanding (backups are on-host only). This matters for host-loss DR, not for a code+additive-migration rollback on an intact host.

## [6] Migration-history compatibility (no repair)
Prod `migrations` table = **142 rows, max batch 28**; the three new migration names are **absent**. Their timestamps (`2026_10_28_*`) are unique and sort after all 142 existing entries, so `migrate` appends them cleanly as **batch 29** without reading, reordering, or modifying any existing row. No history repair is needed or proposed.

## [7] Production steps, health checks, rollback triggers
**Steps:** (1) fresh pre-deploy dump + verify; (2) migrate the 3 additive migrations to `sca_krayin` from a separate `91b88f1` mount; (3) fast-forward live tree → `91b88f1` + `apachectl graceful`; (4) health + smoke.
**Maintenance requirement:** none for the recommended path (migrations are additive and invisible to the running old app; graceful reload is zero-downtime). The fallback path needs a brief `artisan down` window.
**Health checks (post-deploy):**
- `kr-app` loopback `GET /admin/login` → 200 (currently 200).
- Edge `GET /admin/login` → 403 for non-allowlisted IP (expected owner-IP allowlist) / 200 from an allowlisted owner IP.
- A staff item-detail page `GET /admin/sca/eyewear/{id}` → 200 (this is the migrate-before-code canary; it 500s if the tables are missing).
- `migrate:status` shows 000001/000002/000003 = Ran (batch 29); provenance fingerprint unchanged (items/state/ownership/cert/qr/grant + catalog 4565/5330).
**Rollback triggers:** any 5xx on item-detail or create; `migrate` error; provenance fingerprint drift; edge/admin health regression. **Rollback action:** live tree → `905ea7d` + `apachectl graceful` (code-only; no DB rollback required).

## [8] Smoke-test plan (post-deploy, production)
- **Shopify selector:** as a staff user holding `sca.eyewear.shopify.link`, open the intake create form → catalog search returns product title/vendor/variant/SKU/status; archived-product variants show as not linkable; pagination works.
- **Staff permissions (server-side):** a staff user WITHOUT the link ACL gets 403 on `catalog-search`/`link`/`relink`/`unlink` and cannot create-with-link (403, no item); a user WITH it can. (Grant the new ACL to the intended role first — it is fail-closed and ungranted by default.)
- **Intake linking:** create-with-link produces one item + one link + one audit row in a single transaction; double-submit (same token) yields one item; a changed resubmission with the same token returns an explicit conflict (no item); an archived-product selection is rejected with no item.
- **Unchanged behavior (regression spot-check):** public passport `/p/{token}`, authentication/certification/QR/ownership flows, and catalog sync/order webhooks behave exactly as before; provenance counts unchanged; linking never creates authentication/cert/QR/ownership/claim.

## [9] NO-GO conditions (none currently tripped)
- `origin/main` ≠ `91b88f1`, or prod/live ≠ `905ea7d`, or dirty worktree → NO-GO (state drift). *(Currently clear.)*
- Deploy that activates code before migrations (violates [4]) → NO-GO.
- No verified, decryptable, current backup before migrating → NO-GO. *(Currently clear: today's backup integrity MATCH, key present, restore tooling proven.)*
- Any attempt to modify/repair the existing 142-row history, or to run the migrations against a non-prod/ambiguous DB → NO-GO.
- Edge/admin or item-detail health failing pre-deploy → NO-GO. *(Currently `/admin/login` loopback 200.)*

## Summary
Clean linear deploy of an additive, dependency-light change: 3 new tables + code confined to the Sca packages, zero dependency changes, zero existing-table changes, a current+verified backup, a proven restore path, and a trivial code-only rollback. The one hard requirement is ordering — **migrate the three additive migrations before activating the code** — because the staff item-detail view reads two of the new tables on every load.

**READY FOR RELEASE APPROVAL.** No NO-GO blockers. **STOP — read-only; no deployment, migration, checkout, restart, Shopify, or Option-C action taken.** Separate OPEN: Phase-1 first-genuine-`products/*`-webhook verification; and the actual (separately authorized) deploy of `91b88f1` + its three migrations.

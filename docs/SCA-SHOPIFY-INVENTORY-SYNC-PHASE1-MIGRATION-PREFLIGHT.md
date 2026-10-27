# SCA — Shopify Inventory Sync Phase 1: Production Release Preflight (READ-ONLY)

**Scope: read-only preflight only. Nothing merged, deployed, migrated, restarted; no OAuth/scope/webhook/import/production change; Option C and the 139/140 incident untouched (not resolved).** 2026-10-27T15:36Z. **VERDICT: migration scope PROVEN SAFE — not blocked; ready for owner deployment approval.** **STOP for independent ChatGPT review.**

## [1][2][3] Migration preflight — exactly two pending; 139/140 causes no extra migration

Method (read-only, no app boot against prod, no `migrate`): compared the **complete migration-file set on branch `9f05c8a`** (every `*/Migrations/*.php`, 141 files) to the **applied rows in prod `sca_krayin.migrations`** (140 rows).

- **PENDING (on branch, not applied) = EXACTLY the two Shopify catalog migrations:**
  - `2026_10_27_000001_create_sca_shopify_products`
  - `2026_10_27_000002_create_sca_shopify_variants`
  - → a post-merge `artisan migrate --force` runs **only these two** (prod batch 27 → **28**). Both are additive `Schema::create` (no `ALTER`/drop of any existing table).
- **139/140 incident — proven inert (step 3):**
  - `2026_10_20_000001_add_reason_to_sca_qr_lifecycle_events` (migr 139) is **on the branch AND applied** (batch 27) → in neither pending nor orphan set → `migrate` **skips** it.
  - `2026_10_21_000001_add_collector_activity_last_seen` (migr 140) is **applied in prod (batch 27) but has NO file on the branch** → it is a recorded row with no migration file, so `migrate` never attempts it (it only runs files absent from the `migrations` table; it never re-runs or alters a recorded row). It is the single "orphan-applied" entry and is completely inert.
  - Count reconciliation: 141 branch files = 139 shared + 2 pending; 140 applied rows = 139 shared + 1 orphan (140). Consistent.
- **Conclusion:** merging `9f05c8a` and migrating executes **precisely** the two additive Shopify migrations and nothing else; the unresolved 139/140 history does not trigger any further migration. **Migration scope is safe — NOT BLOCKED.**

## [4] Production backup / recovery point

- **Recovery point:** `backups/sca-backup-20261027T021703Z.tar.gz.gpg` — 4,576,491,854 B, sha256 `42e7aadd…875fed`, sidecar **MATCH**. This is a clean snapshot of `sca_krayin` at **batch 27** (the exact pre-migration state), already **restore-proven on 2026-10-27** (gov `016bd1c`, R1 cleared).
- Backup system healthy: 10 retained artifacts, `secrets/backup.key` present, `/` 317 G free, nightly cron `17 3 * * *` installed, and the deployed `backup-run.sh` now carries the doc-consistency stage (`6ebe968`). (The first post-deploy nightly `2026-10-28 02:17Z` has not run yet — not required for this release's recovery point.)
- This recovery point fully predates the two catalog tables, so a worst-case restore returns `sca_krayin` to batch 27 cleanly; re-running `migrate` would recreate the two tables.

## [5] Exact release commands (minimal deployment method; owner-authorized, NOT executed)

```bash
cd /opt/sca-platform && git fetch origin
# Preflight gate (read-only): confirm nothing unexpected is pending.
docker compose exec -T -u 33:33 app php artisan migrate:status | grep 2026_10_27   # both "Pending", nothing else
# A. Merge (no reset / no force): advances main by exactly the 16-file delta.
git merge --no-ff --no-edit 9f05c8a -m "Merge Shopify inventory sync Phase 1 catalog mirror (9f05c8a)"
git diff --name-only HEAD@{1} HEAD    # must equal the 16 files (all under app/packages/Sca/Shopify + app/tests)
git push origin main
# B. Apply ONLY the two additive catalog migrations to prod (batch 27 -> 28; creates 2 empty tables).
docker compose exec -T -u 33:33 app php artisan migrate --force
# C. Controlled, zero-downtime opcache reload for the changed webhook/provider files (not a restart).
docker exec kr-app apachectl -k graceful
```
No composer install, no container rebuild/recreate, no config/scope/webhook/import in the deploy step. Activation (read_products re-consent, webhook registration, import) remains a separate, owner-gated phase; the deployed code is inert until then.

## [6] Rollback plan — preserves both catalog tables and any imported data (NOT `migrate:rollback`)

Rollback is **code-only** and leaves the tables and their data intact:

```bash
cd /opt/sca-platform
git revert --no-edit -m 1 <merge-sha>   # removes the 16-file delta (incl. the 2 migration FILES) from main
git push origin main
# advance the live working tree to the revert, then:
docker exec kr-app apachectl -k graceful
```

- The two tables (`sca_shopify_products`, `sca_shopify_variants`) and any imported catalog rows are **retained**. After the code revert, their migration files are absent while their `migrations` rows (batch 28) and the tables remain — a consistent, inert state **exactly analogous to the existing 140 orphan row**; the old code never references these tables, so keeping them is harmless, and no data is lost.
- **Do NOT use `migrate:rollback`** for this release — it would drop the two tables and destroy any imported catalog data. Removal of the tables (if ever wanted) is a separate, explicit, owner-authorized decision, not part of rollback.
- If a code-side issue needs a data reset instead of a full rollback, the catalog is reproducible by re-running the idempotent import; provenance/ownership are never involved.
- The batch-27 recovery point in [4] remains available as a last resort; it is not needed for this additive, data-preserving rollback. Shared `main` is never reset/force-pushed; 139/140 batch 27 is never rolled back.

## [7] Current main, health, and production fingerprints

- `origin/main` = local `main` = working tree = **`6ebe968`** (clean); branch tip `9f05c8a`.
- `kr-app` running, `kr-mariadb` running, `/admin/login` → **200**.
- `sca_krayin`: items/state/owns/certs = **3 / 3 / 5 / 4**; `migrations` rows **140**; max batch **27**.

## [8] Preflight result

| Check | Result |
|---|---|
| [1][2] Exactly the 2 Shopify migrations pending | **PASS** (proven by branch-files vs applied-rows diff) |
| [3] 139/140 triggers no extra migration | **PASS** (139 applied+skipped; 140 orphan row, no file, inert) |
| [4] Backup recovery point verified | **PASS** (`20261027T021703Z`, checksum match, restore-proven) |
| [5] Minimal release commands prepared | **PASS** |
| [6] Data-preserving rollback (no `migrate:rollback`) | **PASS** |
| [7] main / health / fingerprints confirmed | **PASS** (6ebe968; app 200; 3/3/5/4 batch 27) |
| **Overall** | **NOT BLOCKED — migration scope proven safe; ready for owner deployment approval.** |

**STOP — read-only migration preflight delivered. No merge/deploy/migrate/restart/OAuth/webhook/import/production change; Option C + 139/140 untouched.**

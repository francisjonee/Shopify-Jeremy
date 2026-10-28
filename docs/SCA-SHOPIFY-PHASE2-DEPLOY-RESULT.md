# SCA — Shopify Phase 2 (Slice A+B) Production Deployment RESULT

**Authorized controlled release of `91b88f1a7754e8589893fccfcd393cc4e0cfde74` — DONE and verified.** Code activated and the three additive migrations applied to prod `sca_krayin` (batch 29). Zero existing-data change; container NOT recreated; no Shopify product change, no eyewear/ownership mutation, no Option C, no unrelated migration/history repair. 2026-10-28. **STOP.**

## Prechecks (1–4)
- **SHAs:** origin/main = target `91b88f1`; live/prod was `905ea7d`; worktree clean. ✓
- **Backup intact/readable/recoverable:** latest verified (sha256 MATCH; AES256 GPG decrypt OK; outer tar = MANIFEST.txt/db.sql.gz/documents.tar.gz; inner `db.sql.gz` gzip-OK, DB `sca_krayin`, contains `sca_eyewear_items`). A **fresh pre-deploy backup `sca-backup-20261028T171117Z.tar.gz.gpg`** was taken and integrity-verified (sha256 MATCH; decrypts + lists). Disk 313 G free. ✓
- **Prod DB identity + baseline:** app `DB_DATABASE=sca_krayin`; migrations 142 rows / batch 28; the 3 target migrations + tables absent. ✓
- **Rollback confirmed:** code-only (re-point live tree → `905ea7d` + `apachectl graceful`); no DB rollback needed (migrations additive, old code ignores the new empty tables). ✓

## Release (5–10)
- **[5] Target prepared separately** from the live bind-mount: detached worktree at `91b88f1` in scratchpad, `--no-dev` vendor built, **prod `app/.env` staged** (so migrations ran with the target code + production environment). Live tree untouched during migration.
- **[6/7/8] Migrations — gate then apply.** `migrate:status` (target code vs prod) showed **exactly 3 Pending**, precisely `2026_10_28_000001/000002/000003`, nothing else. `migrate --force` → all three **DONE**. Verified before code activation: 3 new tables exist; audit table carries both append-only triggers (`trg_sca_link_audit_no_update`, `_no_delete`); migrations now 145 rows / **batch 29**; the three rows are batch 29; new tables empty; **provenance fingerprint unchanged**.
- **[9] Code activated** via `git merge --ff-only origin/main` in the live tree → `/opt/sca-platform` HEAD = `91b88f1`; new code on disk (`shopifyLinkPanel` present); `vendor/` (prod `--no-dev`) and gitignored prod `app/.env` intact.
- **[10] Graceful reload:** `view:clear`/`config:clear`/`route:clear` then `apachectl graceful` → OK. Container **not recreated** (same `StartedAt`).

## Post-release verification (11–14)
- **[11] SHA/health/migrations:** live SHA `91b88f1`; loopback `GET /admin/login` → 200; passport root → 302 (healthy); `migrate:status` shows the three as `[29] Ran`.
- **[12] Item-detail canary (read-only):** the new always-on path `EyewearItemController::show()` panel queries against `sca_eyewear_item_shopify_variant` + `sca_eyewear_shopify_link_audit` for a real item (id 1) returned cleanly (link none, 0 audit) — **no missing-table error**. New routes registered: `catalog-search` (GET), `link`/`relink`/`unlink` (POST).
- **[13] Server-side authorization:** all four routes carry `ScaAuthenticate` + `ScaAuthorize:sca.eyewear.shopify.link`; an unauthenticated `POST /admin/sca/shopify/link` → **419** (CSRF/web-group rejected, not open). The create route additionally re-checks the link ACL server-side (proven by the 37/37 regression). *Ungranted by default — operators must grant `sca.eyewear.shopify.link` to the intended staff role before use.*
- **[14] Existing data read-only (unchanged):** items 3 / current_state 3 / **authentications 4** / certifications 4 / qr 3 / ownership 5 / claim_grants 1; catalog products 4565 / variants 5330. The three new tables are **empty** (link 0 / audit 0 / idempotency 0) — live but dormant. Edge `GET /admin/login` → 403 (owner-IP allowlist, expected/unchanged).

## Strict limits honored
No Shopify product change; **no eyewear record created or ownership changed** (feature not exercised with live data); no Option C; no unrelated migration or schema-history repair; no schema rollback; no full regression; no Docker recreate or infra change. Cleanup: deploy worktree (holding the copied prod `.env`) removed; live tree `91b88f1`, clean.

## Deployed state
- **Production code: `91b88f1`** (Phase 2 Slice A+B). Prod `sca_krayin`: **batch 29, 145 migration rows**, three new empty dormant tables. Provenance/eyewear fingerprint unchanged (3/3/4/4/3/5/1; catalog 4565/5330).
- Rollback if needed: `git -C /opt/sca-platform merge/reset` back to `905ea7d` + `apachectl graceful` (code-only; the three empty additive tables may remain, or be dropped later via a separately-approved `migrate:rollback --step=1`).

**STOP — Phase 2 Slice A+B deployed and healthy; production data unchanged. Separate OPEN: the first genuine `products/*` webhook verification on the next normal Shopify product change (unchanged by this release).**

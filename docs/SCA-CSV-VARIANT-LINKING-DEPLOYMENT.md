# SCA — CSV Inventory Variant Linking: Controlled Production Deployment (DONE)

**The tested optional CSV Shopify variant-linking enhancement is DEPLOYED to production. The live SCA
application is now at `a53eff3`; all prechecks and post-deployment checks passed, the database is
unchanged, and no rollback was needed.** Code-only fast-forward, no migration, no container recreate,
zero Shopify contact. 2026-10-30. **STOP.**

## Result
- **Deployed SHA:** `a53eff321580f7338c2192bf0cdb0ef8375bfea7` (was `4faf84d`). Live tree clean.
- **Method:** `git merge --ff-only a53eff3` on the live `main` checkout (local ref only — `origin/main`
  was never pulled), then `php artisan view:clear` + `apachectl -k graceful`. No migration, no Docker
  recreate; `kr-app` stayed `Up` (not restarted).

## Prechecks (all passed)
1. Production `4faf84d`, working tree clean, `kr-app` healthy.
2. RC `a53eff3`, direct parent `4faf84d` (fast-forwardable; `git merge-base --is-ancestor` = yes).
3. Exactly the six approved files differ vs `4faf84d` (controller, service, import form/preview/result
   views, `InventoryImportVariantLinkTest`).
4. No migrations, no schema change, no R0/R0b/R0c, no Option C in the diff.
5. Migration baseline **batch 30 / 146 migrations**; **0 genuinely-pending** migrations
   (`migrate:status` trailing-`Pending` count = 0; a filename containing the word "pending" is marked
   Ran).
6. Recoverable backup verified: latest encrypted artifact
   `backups/sca-backup-20261030T021703Z.tar.gz.gpg` (2026-10-30 03:29 UTC, ~4.58 GB), **sha256 matches**
   its sidecar (`eb57f6d2…bc2a22`), decryption key `secrets/backup.key` present (mode 600). Code rollback
   point recorded: `4faf84d`. (Backup is local-only — the known OFFSITE_DEFERRED residual — but
   recoverable for rollback.)

## Deployment steps executed
7–9. Fast-forwarded the live checkout to `a53eff3`; `app/.env` MD5 unchanged (`3a8c4b06…b92dc` before and
after) and `vendor/` intact — both are git-ignored, so the FF did not touch them.
10. `php artisan view:clear` → "Compiled views cleared successfully."
11. `apachectl -k graceful` → exit 0; `kr-app` still `Up` (in-place reload, no recreate).
12. No migrations run; no containers recreated.

## Post-deployment verification (all passed)
13. Deployed SHA is exactly `a53eff3`.
14. **Health 200:** `/admin/login` → HTTP 200 and `/collector/login` → HTTP 200 via the app loopback;
    public edge `/collector/login` 200, `/collector` 302. (The public edge returns 403 on `/admin/*` by a
    pre-existing IP restriction — the application itself serves 200; no app fault.)
15. Import routes registered with existing ACL middleware intact — `admin.sca.eyewear.import.{form,
    preview,confirm}` each carry `ScaAuthenticate` + `ScaAuthorize:sca.eyewear.create`.
16. Optional `shopify_variant_id` handling present in deployed code (`VARIANT_HEADER`,
    `ACCEPTED_HEADERS`, `resolveVariant`, per-row variant resolution).
17. Existing CSVs without the new column remain supported: `ALLOWED_HEADERS` is still exactly the 8
    intake fields; `ACCEPTED_HEADERS` additionally allows `shopify_variant_id`; `MAX_ROWS` = 500.
18. **Database unchanged (before == after):** migrations 146 / batch 30; `sca_eyewear_items` 3;
    `sca_eyewear_item_shopify_variant` 0; `sca_inventory_imports` 0; `sca_inventory_import_rows` 0;
    `sca_certifications` 4; `sca_qr_identifiers` 3; `sca_ownership_events` 5; `sca_shopify_sale_links` 1;
    `sca_eyewear_shopify_link_audit` 0. No background webhook activity moved any record in the window.
19. Logs: **zero** ERROR/CRITICAL/WARNING entries dated 2026-10-30 (no log lines at all since the
    reload). The only recent error entries are 2026-10-28/29 `route:list --columns` CLI-usage errors,
    pre-existing and unrelated to this deployment.
20. No real CSV was uploaded or processed; the feature was verified by code/route inspection only.

## Rollback
Not needed — every check passed. Documented controlled procedure if required later: on the live tree
restore the six files to `4faf84d` (a backward move to the previous snapshot, **not** a fast-forward) —
`git reset --hard 4faf84d` (or `git checkout 4faf84d -- <the six paths>`) — then `php artisan view:clear`
+ `apachectl -k graceful`. **No database rollback** (no migration was applied; nothing is written until a
staff member confirms an import).

## Safety posture (honored)
Zero live Shopify API requests / storefront modifications / CLI / credential changes; no product,
variant, inventory, order, theme, or webhook modification; no reconciliation or catalog import triggered;
existing background webhook processing untouched. No genuine inventory registration; no
authentication/certification/QR/claim/transfer; no transactional email. Secure-claim RC `4bd88d2` NOT
deployed and untouched (remains RELEASE-PREPARED / DEPLOYMENT-BLOCKED).

**STOP — deployment complete. Live SCA application now at `a53eff3` (code-only fast-forward from
`4faf84d`, no migration, no recreate). All prechecks and post-deploy checks passed; database fingerprint
unchanged; backup `20261030T021703Z` verified recoverable; no deployment errors. Rollback not required.**

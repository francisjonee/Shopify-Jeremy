# SCA — Transfer-Link Copy/Share: Controlled Production Deployment (DONE)

**The view-only transfer-link Copy/Share enhancement is DEPLOYED. The live SCA application is now at
`b007606`; all prechecks and post-deployment checks passed, the database is unchanged, and no rollback
was needed.** Code-only fast-forward, one Blade view, no migration, no container recreate, zero Shopify
contact. 2026-10-30. **STOP.**

## Result
- **Deployed SHA:** `b0076068c60704036da0ca04735dfd1a1537a070` (was `a53eff3`). Live tree clean.
- **Method:** `git merge --ff-only b007606` on the live `main` checkout (local ref only — `origin/main`
  never pulled, secure-claim RC `4bd88d2` never merged), then `php artisan view:clear` + `apachectl -k
  graceful`. No migration; no Docker recreate; `kr-app` stayed `Up` (not restarted).

## Prechecks (all passed)
1. Production `a53eff3`, working tree clean, `kr-app` healthy.
2. RC `b007606`, direct parent `a53eff3`, fast-forwardable (`git merge-base --is-ancestor` = yes).
3. Exactly one changed file:
   `app/packages/Sca/Collector/src/Resources/views/transfer/initiate.blade.php`.
4. No migration / controller / route / service / permission / QR / claim / ownership files in the diff
   (view only).
5. Recoverable backup present: `backups/sca-backup-20261030T021703Z.tar.gz.gpg` (2026-10-30 03:29 UTC,
   ~4.58 GB); rollback point recorded: `a53eff3`.
6. Transfer page CSP compatible: collector pages send **no** `Content-Security-Policy` header (verified
   on the deployed app via loopback), so the inline Copy/Share JS runs; the public passport keeps its
   stricter CSP and has no JS.

## Deployment steps executed
7–10. Fast-forwarded the live checkout to `b007606`; `app/.env` MD5 unchanged (`3a8c4b06…b92dc` before
and after) and `vendor/` intact (both git-ignored, untouched by the FF).
11. `php artisan view:clear` → "Compiled views cleared successfully." (the key step for a Blade change).
12. `apachectl -k graceful` → exit 0; `kr-app` still `Up` (in-place reload, no recreate).
13. No migrations; no container recreate; no infrastructure change.

## Post-deployment verification (all passed)
14. Deployed SHA is exactly `b007606`.
15. Health: `/collector/login` → HTTP 200 and `/admin/login` → HTTP 200 (app loopback).
16. Deployed `transfer/initiate.blade.php` contains the **Copy link** button (`sca-transfer-copy`),
    **conditional native Share** (`navigator.share` guard + call), and the **no-JS fallback**
    (`onclick="this.select()"` read-only input).
17. Transfer routes and auth middleware unchanged: `collector.transfer.show` / `.initiate` / `.cancel`
    (`collector/collection/{ref}/transfer…`) and `collector.transfer.accept.show` / `.accept`
    (`collector/transfer/{token}`) all present, each behind `CollectorAuthenticate`.
18. **Database unchanged (before == after):** migrations **146** / batch **30**; `sca_ownership_events`
    5; `sca_transfer_events` 2; `sca_qr_identifiers` 3; `sca_certifications` 4;
    `sca_external_claim_grants` 1.
19. Logs: **zero** ERROR/CRITICAL and **zero** WARNING entries dated 2026-10-30.
20. No real transfer was initiated/accepted/cancelled; verification was by route/content inspection and
    health checks only.

## Rollback
Not needed — all checks passed. Documented procedure if required later (view-only; a **backward move to
the previous snapshot, not a fast-forward**): on the live tree
`git checkout a53eff3 -- app/packages/Sca/Collector/src/Resources/views/transfer/initiate.blade.php` (or
`git reset --hard a53eff3`), then `php artisan view:clear` + `apachectl -k graceful`. **No database
rollback** (no migration; nothing written).

## Safety posture (honored)
Zero Shopify API requests / store modifications / CLI / credential access; no live transfer, ownership
claim, or eyewear assignment; no production database write; no transactional email configuration; no
R0/R0b/R0c deploy or merge; no unrelated change. Secure-claim RC `4bd88d2` remains DEPLOYMENT-BLOCKED and
untouched.

**STOP — deployment complete. Live SCA application now at `b007606` (code-only fast-forward from
`a53eff3`, one Blade view, no migration, no recreate). All prechecks and post-deploy checks passed;
database fingerprint unchanged; backup `20261030T021703Z` on hand; no deployment errors. Rollback not
required.**

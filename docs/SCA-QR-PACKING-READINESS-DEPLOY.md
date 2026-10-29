# SCA — QR Packing-Readiness: Controlled Production Deployment — RESULT

**Authorized code-only deployment of release `4faf84d` DONE.** Production advanced
`eb137bf905758e7bfa2a9b13a2ce68384340c54f` → `4faf84d49b4a67823aff31ba0dc926bd91110c16` by fast-forward
+ `view:clear` + `apachectl graceful` — **no migration, no Docker recreate, no DB write**. The only
change is the order-assignment QR packing-readiness confirmation message (display-only). ZERO Shopify
API requests / store changes. Provenance, assignment, and migration history unchanged; no rollback
needed. 2026-10-29. **STOP.**

## Prechecks [1–7]
- **[1]** Live `eb137bf`, `main`, clean; loopback 200.
- **[2]** Release `4faf84d`; direct parent **`eb137bf`** (single-commit, clean fast-forward).
- **[3]** Diff vs `eb137bf` = exactly `OrderAssignmentController.php` + `ShopifyOrderItemAssignmentTest.php`.
- **[4]** No migration, model, certification, QR-token, or ownership change (changed-file scan clean).
- **[5]** R0/R0b/R0c + Option C absent (diff scan clean).
- **[6]** Production DB batch **30 / 146**; `migrate:status` **0 truly-pending** (release adds none).
- **[7]** Latest backup `sca-backup-20261029T021703Z.tar.gz.gpg` (4.3 GB) **sha256 verified OK**; rollback
  = restore the previous approved code snapshot `eb137bf` (code-only; no DB rollback).

## Shopify safety — honored
No Shopify API request (not even read-only), no store/product/order/inventory/customer/theme/webhook/
OAuth/credential change, no Shopify CLI, no reconciliation/catalog import. Background webhook processing
untouched. All smoke checks were local SCA health + read-only DB inspection.

## Deployment [8–13]
- **[8][9]** Fetched the exact release SHA and `git merge --ff-only 4faf84d` on the live checkout (branch
  `main`); origin/main was NOT pulled.
- **[10]** `app/vendor` (53 entries) and `app/.env` preserved — SAME before/after.
- **[11]** `php artisan view:clear` → "Compiled views cleared successfully."
- **[12]** `apachectl -k graceful` → rc 0; loopback 200. (opcache `validate_timestamps=On` picks up the
  controller change.)
- **[13]** No migrations run; no Docker recreate.

## Post-deployment [14–20]
- **[14]** Deployed SHA = **`4faf84d49b4a67823aff31ba0dc926bd91110c16`**.
- **[15]** Health: `/admin/login → 200`; `/admin/sca/shopify/order-assign → 302` and
  `/admin/sca/shopify/operations → 302` (auth redirects, not 500).
- **[16]** Updated code present (host tree + as served via the bind-mount): the confirmation line is now
  `$result['qr_available'] ? 'QR ready for packing' : 'no active QR yet …'` (line 97); occurrences of
  "staging — not for print" = **0**.
- **[17]** Routes + ACL intact: `GET order-assign` → `OrderAssignmentController@index`
  (`ScaAuthorize:sca.shopify.view`); `POST .store` → `@assign`
  (`ScaAuthorize:sca.eyewear.shopify.order-assign`).
- **[18]** Migration history + counts unchanged: migrations batch **30 / 146**; items **3** / ownership
  **5** / claims **2** / cert **4** / qr **3** / sale_links **1**; `sca_shopify_order_item_assignments`
  **0 rows**. Shopify catalog products **4575** / variants **5345** / webhook_receipts **1298** — these
  move only with independent background webhook activity, not from this deploy.
- **[19]** Logs: the only two `2026-10-29` ERROR entries are from an earlier operator `php artisan
  route:list --columns=...` verification attempt (15:54; that flag does not exist in this Laravel
  version) — a benign CLI typo, not a web request and not from this deployment's graceful reload. No
  deployment-related errors.
- **[20]** No real assignment was performed to test the message (display-only change verified by code
  inspection + the prior 83/83 disposable-DB regression).
- No Docker recreate: `kr-app`/`kr-mariadb` retain their original uptime (3 weeks / 6 weeks).

## [21–23] Rollback
Not triggered — all critical checks passed. Documented procedure if ever needed: restore the previous
approved code snapshot `eb137bf` on the live checkout (`git reset --hard eb137bf` / checkout), then
`view:clear` + `apachectl graceful`. **No database rollback** (the change is display-only; no schema or
data touched).

## Final state
Live `/opt/sca-platform` = **`4faf84d`**, `main`, clean; loopback 200; containers not recreated.
`sca_krayin`: batch 30 / 146; provenance items 3 / ownership 5 / claims 2 / cert 4 / qr 3; Shopify
sale_links 1; assignment table 0 rows. Live local `main` now points at `4faf84d` (one display-only
commit beyond the prior `eb137bf`); it continues to diverge intentionally from `origin/main` `a397a7e`
(which carries the undeployed R0/R0b/R0c).

**STOP — QR packing-readiness correction is LIVE at `4faf84d` (prod `eb137bf → 4faf84d`, code-only, no
migration, no recreate). Provenance/assignment/Shopify untouched; ZERO Shopify interaction. The order
assignment confirmation now reports packing readiness by ACTIVE QR presence, not the is_production flag.
SEPARATE OPEN: Phase-1 first genuine `products/*` webhook receipt verification.**

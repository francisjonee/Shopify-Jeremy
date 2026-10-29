# SCA — Shopify Order Assignment: Controlled Production Deployment — RESULT

**Authorized controlled deployment of release `eb137bf` DONE.** Production advanced `5bed316` →
`eb137bf905758e7bfa2a9b13a2ce68384340c54f` via migrate-before-code: the one additive assignment-audit
migration applied to `sca_krayin` (batch 30), then the live tree fast-forwarded + `view:clear` +
`apachectl graceful` (NO Docker recreate). The staff Order→Eyewear Assignment feature + Administrator
permission fix + rc21 correction are live; R0/R0b/R0c excluded. **ZERO Shopify API requests (not even a
read-only probe), ZERO Shopify store/credential/webhook changes.** No ownership/cert/QR/claim/assignment
records created. All post-release checks passed; no rollback needed. 2026-10-29. **STOP.**

## Prechecks [1–6]
- **[1]** Live `5bed316`, `main`, clean; loopback 200. Release `eb137bf` (parent chain descends from
  `5bed316`; HEAD was ancestor of release → clean fast-forward).
- **[2]** Release diff vs `5bed316` = the 12 approved files + exactly ONE additive migration
  (`2026_10_31_000001_create_sca_shopify_order_item_assignments`).
- **[3]** No R0/R0b/R0c or Option-C in the diff (scan clean).
- **[4]** Latest backup `sca-backup-20261029T021703Z.tar.gz.gpg` (4.3 GB, ~13h old) — **sha256 verified
  OK**; backup job `DONE`. (Off-host escrow remains the known residual; a verified local backup existed
  and this deploy makes no destructive DB change.)
- **[5]** Migration baseline batch **29 / 145**. Rollback procedure confirmed (below).
- **[6]** No Shopify write operation is needed — the release adds a local table + routes/controller/
  service only; it calls no Shopify API and changes no OAuth/webhook/catalog config.

## Shopify store safety — honored (ZERO live Shopify interaction)
No Shopify products/variants/inventory/orders/customers/themes/checkout/webhooks/OAuth/settings were
touched; no Shopify CLI; no Shopify Admin API request (not even a read-only probe); no credential
change; no reconciliation/import triggered. All smoke tests were local SCA health checks + read-only
DB inspection. Background webhook processing is unchanged. The migration + code add a staff tool that
is inert until used; no order assignment was performed.

## Release procedure [7–14]
- **[7]** Target prepared in an isolated worktree at `eb137bf` (own vendor + a copy of the verified
  production `app/.env`, mode 0600, shredded after) — separate from the live bind-mounted app.
- **[8]** `migrate:status` from the target: **exactly ONE** truly-pending migration
  (`2026_10_31_000001...`, status `Pending`); 144 Ran. (A false "2 pending" from a substring match on
  `add_active_pending_guard` — which is `[17] Ran` — was ruled out by matching on the status column.)
- **[9]** `migrate --force` from the target against `sca_krayin`, BEFORE code activation → applied the
  one migration (309 ms), batch **30**.
- **[10]** Verified on `sca_krayin`: table `sca_shopify_order_item_assignments` exists, **0 rows**, both
  append-only triggers present (`trg_sca_order_assign_no_update` UPDATE, `trg_sca_order_assign_no_delete`
  DELETE); migration recorded at batch 30; migrations now 146/30. No assignment records created.
- **[11]** Activated `eb137bf`: `git merge --ff-only` on the live `/opt/sca-platform` tree.
- **[12]** `app/vendor` (53 entries) and `app/.env` (sha unchanged) preserved — SAME before/after.
- **[13]** `php artisan view:clear` ("Compiled views cleared successfully") + `apachectl -k graceful`
  (rc 0); loopback 200. (opcache `validate_timestamps=On` picks up the changed PHP.)
- **[14]** No Docker recreate — `kr-app`/`kr-mariadb` keep their original uptime (3 weeks / 6 weeks).

## Post-release verification [15–20]
- **[15]** Deployed SHA = **`eb137bf905758e7bfa2a9b13a2ce68384340c54f`**.
- **[16]** Safe health: `/admin/login → 200`; `/admin/sca/shopify/operations → 302` (auth redirect, not
  500); `/admin/sca/shopify/order-assign → 302` (auth redirect, not 500). Unauthenticated redirects occur
  in middleware before any controller/Shopify code runs — no Shopify API touched.
- **[17]** Routes + ACL registered correctly: `GET admin/sca/shopify/order-assign` →
  `OrderAssignmentController@index` gated by `ScaAuthorize:sca.shopify.view`; `POST .../order-assign`
  (`.store`) → `@assign` gated by `ScaAuthorize:sca.eyewear.shopify.order-assign` + `ThrottleRequests:60,1`.
  Operations/reconcile ACLs intact.
- **[18]** No production assignment/ownership/certification/QR/claim records created: assignment table
  **0 rows**; provenance unchanged — items **3** / ownership **5** / claims **2** / cert **4** / qr **3**
  / current_state **3** / auth **4** / external grants **1**.
- **[19]** Shopify data consistent: sale_links **1** (unchanged by deploy); catalog products **4574** /
  variants **5344**, webhook_receipts **1282**, credentials **1** — these move only with ordinary
  background webhook activity, not from this deploy.
- **[20]** Logs: the only two `2026-10-29` ERROR lines are from an operator `php artisan route:list
  --columns=...` verification attempt (that flag does not exist in this Laravel version) — a benign CLI
  typo, NOT a web request and NOT a deployment/application error. No deployment-related errors.

## [21] Rollback
Not triggered — all critical checks passed. Documented procedure if ever needed: `git reset --hard
5bed316` / checkout `5bed316` on the live tree + `view:clear` + `apachectl graceful` (code-only). **Do
NOT roll back the additive migration without separate approval** — it is additive (new table + triggers,
0 rows), so reverting the code needs no DB rollback (the table simply goes unused).

## [22] Final state / production fingerprint
- Live `/opt/sca-platform` = **`eb137bf`**, `main`, clean; loopback 200; containers not recreated.
- `sca_krayin`: migrations **batch 30 / 146**; `sca_shopify_order_item_assignments` present, **0 rows**,
  2 append-only triggers; provenance items 3 / ownership 5 / claims 2 / cert 4 / qr 3 / state 3 / auth 4
  / grants 1; Shopify sale_links 1, products 4574, variants 5344, receipts 1282, credentials 1.
- Target worktree removed; copied prod `.env` shredded.

**STOP — Order→Eyewear Assignment + Administrator permission fix + rc21 correction are LIVE at
`eb137bf` (prod `5bed316 → eb137bf`, batch 30). Feature is inert until staff use it; no Shopify
interaction occurred. R0/R0b/R0c remain undeployed. SEPARATE OPEN: Phase-1 first genuine `products/*`
webhook receipt verification.**

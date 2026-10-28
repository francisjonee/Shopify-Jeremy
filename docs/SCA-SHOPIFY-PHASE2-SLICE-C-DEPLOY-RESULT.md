# SCA — Shopify Phase 2 Slice C Production Deployment RESULT

**Authorized controlled release of `cb8a8c3277f4319bc7c2ebdb8e0238426400bc7a` — DONE and verified.** Read-only linked-product visibility activated by fast-forwarding the live checkout + a graceful reload. **No migration run (Slice C adds none), no schema change, no Docker recreate, no Shopify change, no new records, no Option C.** Production data unchanged. 2026-10-28. **STOP.**

## Prechecks (1–6)
- **[1]** `origin/main` == target **`cb8a8c3`**. ✓
- **[2]** Live checkout was baseline **`91b88f1`**, clean. ✓
- **[3]** Target delta (`91b88f1..cb8a8c3`) = exactly the 4 approved Slice C files (controller, registry view, Shopify link panel, visibility test); **no migration** in the delta. ✓
- **[4]** The Slice A/B tables exist in prod and were empty: `sca_eyewear_item_shopify_variant` / `sca_eyewear_shopify_link_audit` / `sca_eyewear_intake_idempotency` = 0 / 0 / 0. ✓
- **[5]** Latest backup `sca-backup-20261028T171117Z.tar.gz.gpg` integrity **MATCH**; rollback is code-only (ff live tree back to `91b88f1` + graceful; no DB rollback — Slice C adds no migration). ✓
- **[6]** Pre-release health: `kr-app` loopback `/admin/login → 200`; fingerprint items 3 / state 3 / auth 4 / cert 4 / qr 3 / ownership 5 / grants 1, catalog 4565/5330, batch 29 / 145 rows. ✓

## Deploy (7–9)
- **[7]** `git merge --ff-only origin/main` in the live tree → `/opt/sca-platform` HEAD = **`cb8a8c3`**; new code on disk (`pairsLinked` present); `vendor/` and gitignored prod `app/.env` (DB `sca_krayin`) intact.
- **[8]** `view:clear`/`config:clear`/`route:clear` then `apachectl graceful` → OK. Container **not recreated** (same `StartedAt`).
- **[9]** No migration run — confirmed none pending/needed for Slice C.

## Post-deploy (10–15)
- **[10]** Deployed SHA = **`cb8a8c3`** (matches target).
- **[11]** Health: `/admin/login → 200`; `/admin/sca/eyewear → 302` and `/admin/sca/eyewear/1 → 302` (auth redirects, **not 500**) — the item-detail page that runs the new `shopifyLinkPanel()` reads is healthy.
- **[12/13]** Booted read-only probe ran the exact new queries against prod: the registry linked-map query returned 0 rows (no links yet) and the detail panel pair-count (`COUNT`) returned 0 for item 1 — both executed cleanly, read-only, correctly sourced from the link table. (With 0 links in prod today, all indicators resolve to "No Shopify link" / count 0; the counting/indicator logic itself was proven = 2 on the disposable DB, gov `SCA-SHOPIFY-PHASE2-SLICE-C-DB-TEST-RESULT.md`.)
- **[14]** Fingerprint **unchanged** vs pre-deploy: items 3 / state 3 / auth 4 / cert 4 / qr 3 / ownership 5 / grants 1; catalog 4565 / 5330; batch 29 / 145; **link/audit/idempotency records = 0 / 0 / 0 (unchanged)**.
- **[15]** Logs clean: no Laravel error log for today (nothing logged), no recent Apache errors. Edge `/admin/login → 403` (owner-IP allowlist, expected/unchanged).

## No rollback needed
All critical checks passed; no 5xx, no log errors, no fingerprint drift. (If needed, the rollback is `git -C /opt/sca-platform merge/reset` back to `91b88f1` + `apachectl graceful` — code-only, no DB action.)

## Strict limits honored
No production DB migration or schema change; no Shopify product change; **no new eyewear/ownership/authentication/certification/QR/claim records**; no Option C; no Docker recreate or unrelated infra; no full regression.

## Deployed state
- **Production code: `cb8a8c3`** (Slice C read-only visibility over Slice A+B). Prod `sca_krayin` unchanged: batch 29 / 145 rows; link/audit/idempotency tables present and empty; provenance 3/3/4/4/3/5/1, catalog 4565/5330.
- The linked-product visibility (detail panel: product name/vendor/variant/SKU/reference + pair count; archived→inactive / deleted→unavailable from snapshot; registry linked/inactive/unlinked indicator) is now live for authorized staff. It is read-only; the link/relink/unlink controls remain gated by `sca.eyewear.shopify.link` (held by the single Administrator role).

**STOP — Slice C deployed and healthy; production data unchanged. Separate OPEN: the first genuine `products/*` webhook verification on the next normal Shopify product change (unaffected by this release).**

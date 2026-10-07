# SCA Shopify Sale / Claim — Staff Visibility — merge + governed deploy result — **CLOSED**

**Date:** 2026-10-07 · **Status: ✅ DONE — merged `--no-ff` + deployed. No migrations (prod stays 122). Post-deployment verification PASS. Shopify untouched; no real sale manufactured.** Authorized after ChatGPT candidate PASS/APPROVED of head `31b22c594b3d19ceac7693a24918ed08ef1eacde` (gov impl evidence `180e773a6af5d1affa5f8355de68ad82a0ead096`).

## SHAs
- **Base / deployed-from:** `976088944de0fd2883f12a0686fafaa708ce8b9e`
- **Audited candidate head:** `31b22c594b3d19ceac7693a24918ed08ef1eacde` (unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `e4306e999e3a528a8126f9ede85cdc6d1b44eeac`** (`--no-ff` merge of `feat/sca-shopify-sale-claim-visibility`, 1 impl commit)

## Pre-merge gates (fail-closed) — all PASS
candidate head `31b22c59…` unchanged; `origin/main` == merge-base == `9760889…`; tree clean. Merge diff = exactly the 7 expected files (5 modified + 2 new), **zero migrations**.

## Deploy (`scripts/deploy-preview.sh`)
`git reset --hard origin/main` → `e4306e9`; mandatory SCA gate on `sca_domain_test`; `migrate --force` → **no new migrations → migrations remain 122**; memory-capped image rebuild + `docker compose up -d` (sca project only; co-tenant + 80/443 untouched); `--no-dev` prune; `config:clear`+`route:clear`; `kr-app`/`kr-mariadb` healthy; `GET /admin/login → 200`; `Deployed main @ e4306e9`.

**Deploy-gate note:** the first gate run aborted on the **known random-token QR-decode flake** `QrArtifactTest::rg2` (`DECODE_FAILED: estimated dimension: 27`) — 882 passed + that 1 flake. `set -e` aborts the gate **before** migrate/build, so production was untouched by the aborted run. The deploy was re-run unchanged (established procedure); the gate then passed fully and the deploy completed.

## Post-deployment verification — all PASS
| Check | Result |
|---|---|
| deployed SHA == merge SHA | `DEPLOYED_HEAD = e4306e999e3a528a8126f9ede85cdc6d1b44eeac` |
| migrations | **122** (no migration added) |
| provenance data unchanged | counts byte-identical to baseline — items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3 (pre-existing `claims` 2 / `sale_links` 1 from the earlier Shopify dry-run/dispose; `eligible` sale-links **0**) |
| item-detail Sale / claim tab deployed | partial `eyewear/partials/sale-claim.blade.php` present on deployed tree; show() wired |
| no-link renders | gate `v1` PASS ("not linked to a Shopify sale") |
| eligible renders "Sold on Shopify — awaiting collector claim" | gate `v2` PASS + safe fields present |
| claimed renders claimed + only opaque COL-… ownership | gate `v3` PASS (collector email absent) |
| cancelled/refunded terminal history renders | gate `v4` (refund-after-claim, ownership preserved) + `v5` (cancelled tombstone) + `v6` (resale history) PASS |
| no `shopify_customer_ref` / `webhook_idempotency_key` / collector email / internal id / secrets / billing in HTML | gate `v2`/`v3` PASS (explicit absence assertions incl. idempotency-key sentinel) |
| timestamps labelled SCA record/webhook-processing, not Shopify paid dates | gate `v2` PASS ("webhook-processing" present, "paid date" absent) |
| dashboard has "Sold — awaiting claim" | gate `v11` PASS; tile present on deployed view |
| dashboard count == persisted eligible sale-link count | gate `v7` PASS (parity with raw query); live prod eligible = **0** → tile shows 0 |
| "Certified — unclaimed" tile unchanged | gate `v8` PASS (definition/label unchanged; not relabelled) |
| dashboard drill-down uses `sale=awaiting_claim` | tile links to `admin.sca.eyewear.index` `sale=awaiting_claim` |
| Registry filter returns exactly eligible-linked items | gate `v9` PASS (set equality) |
| unknown `sale` values harmless | gate `v10` PASS (ignored, not broadened) |
| existing ACL intact | gate `v11` PASS (unauth→login, no `sca.eyewear.view`→403, with→200; dashboard needs only `sca.eyewear`, not `sca.eyewear.status`) |
| zero sale-link/claim/provenance mutation from viewing | gate `v12` PASS (fingerprint unchanged); live provenance counts unchanged post-verify |
| public passport valid/bogus | `/p/{bogus}` **404** (valid-token invariant covered by gate + prior deploys) |
| `/collector` | **302** |
| unsigned Shopify webhook fail-closed | **401** |
| `/storage` blocked | **404** |
| admin edge protection | `/admin/sca/dashboard` + `/admin/sca/eyewear?sale=awaiting_claim` → **403** (edge staff-IP gate externally) |
| kr-app loopback-only | `:8080` external → **000** (Phase-B preserved) |
| smsrocket co-tenant | **302** |
| Shopify untouched | no Shopify API call / app config / scope / OAuth / webhook change; prod `sca_shopify_sale_links` only READ |

## Regression totals
Deploy gate (clean re-run): **883 passed / 4784 assertions**, exit 0 (871 baseline + 12 new `ShopifySaleClaimVisibilityTest`). First attempt: 882 passed + 1 known flake (QrArtifactTest::rg2), cleared on re-run. Migrations **122**.

---

## SCA Shopify Sale / Claim Staff Visibility — CLOSED

Staff now have **read-only** visibility of the existing Shopify sale→claim state of an SCA frame, with no new subsystem and zero schema:
- **Item-detail "Sale / claim" tab** shows not-linked / sold-awaiting-claim / claimed / refunded-revoked / cancelled, the current active sale link, and a compact history of terminal links — safe non-PII fields only (order/line/product/variant ids, state, SCA record/webhook-processing timestamps explicitly labelled), owner only as opaque `COL-…`. The customer reference and webhook idempotency key are never selected, so never rendered.
- **Dashboard "Sold — awaiting claim" tile** counts strictly `sca_shopify_sale_links.eligibility_state='eligible'` (the precise Shopify-derived worklist), distinct from the unchanged projection-based "Certified — unclaimed" tile, and drills down to the allowlisted `sale=awaiting_claim` Registry filter.
- **Registry `sale=awaiting_claim` filter** returns exactly the items with an active eligible sale link (`whereExists`, pagination/sorting preserved); unknown `sale` values are ignored.

This completes the staff side of the already-live Shopify→claim loop and removes the never-sold vs sold-awaiting-claim conflation. **No second visibility/reconciliation slice.** Read-only; no Shopify API/scope/OAuth/webhook change; no mutation controls; no PII/secrets.

**Outcome: DONE (merged `--no-ff` + deployed, `e4306e9`); provenance verified byte-identical; prod migrations remain 122 (no schema change). SCA Shopify Sale / Claim Staff Visibility is CLOSED.** See `docs/SCA-SHOPIFY-SALE-CLAIM-STAFF-VISIBILITY-{DISCOVERY,IMPLEMENTATION}.md`.

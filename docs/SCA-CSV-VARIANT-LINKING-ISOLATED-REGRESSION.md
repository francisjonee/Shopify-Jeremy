# SCA — CSV Inventory Variant Linking: Isolated Regression Result

**The variant-linking feature is functionally CORRECT and has ZERO side effects on existing behaviour —
every existing and side-effect suite is green, and all feature requirements [18]–[30] are verified. The
only two failures are INCORRECT ASSERTIONS in the new candidate test itself (not an application defect);
the guarantee they meant to check (re-upload never duplicates) is proven to hold.** Per the task's
failure rule, no application code and no candidate code were modified — this reports the cause and the
exact test correction required, and STOPS for review. Isolated disposable DB (`sca_domain_test`),
`--internal` network with egress proven blocked, fake Shopify creds, zero live Shopify requests.
Candidate `feature/sca-csv-variant-link` = `9c1103c` (parent = prod `4faf84d`). 2026-10-30. **STOP.**

## Isolation evidence (mandatory safety)
- **Candidate**: `9c1103c`, parent exactly `4faf84d`; diff is exactly the 6 files built in the prior task.
- **Production**: live tree at `4faf84d`, clean, throughout; `kr-app` `Up (healthy)`; public routes
  `/collector/login` 200, `/collector` 302 (the `/` 404 and `/admin/login` 403 are pre-existing edge
  access rules, unrelated — no prod/edge change was made).
- **Disposable DB**: `sca_domain_test` confirmed absent / 0 connections / no `sca_test` user before
  creation; created fresh with a restricted `sca_test` user (`USAGE` globally + `ALL` on
  `sca_domain_test` only). Proven locked out of production: `USE sca_krayin` → `ERROR 1044 Access
  denied`; `SHOW DATABASES` → only `information_schema`, `sca_domain_test`.
- **Identity probe** (all four agree **exclusively** on `sca_domain_test`): `env(DB_DATABASE)` =
  `getenv(SCA_TEST_DB)` = Laravel connection = `SELECT DATABASE()` = `sca_domain_test`.
- **Network**: temporary `sca_testnet` with `internal=true`; from the test-runner `curl https://1.1.1.1`
  → connect refused (exit 7) and `repo.packagist.org` → DNS resolution failed (exit 6), while
  `kr-mariadb` was reachable. Vendor was built BEFORE, on the default network; all migrate/seed/tests ran
  on the internal network. No Shopify CLI, no reconciliation, no catalog import, no webhook replay.
- Migrate + seed ran against the disposable DB only (candidate migrations incl.
  `sca_eyewear_item_shopify_variant`, `…_link_audit`, `…_intake_idempotency`, `…_order_item_assignments`).

## Suites and results
| Suite(s) | Tests | Assertions | Result |
|---|---:|---:|---|
| **InventoryImportVariantLinkTest** (candidate, step 15) | 15 | 70 | **13 pass / 2 fail** (`vl9`, `vl10`) |
| InventoryImportTest + ShopifyProductLinkTest + ShopifyProductLinkRouteTest + EyewearShopifyIntakeTest + ShopifyLinkVisibilityTest (step 16) | 60 | 268 | **OK** |
| ProvenanceDomainTest + CertificationWorkflowTest + QrArtifactTest + QrLabelsBatchTest + ShopifyOrderItemAssignmentTest (step 17) | 98 | 302 | **OK** |

No warnings, errors, risky, or skipped tests were reported in any run. `QrArtifactTest` (which carries a
known `rg2` QR-decode flake) passed cleanly this run; `ExternalClaimTest` (known shared-DB flake) was not
in scope and was not run.

## The two failures — INCORRECT TEST ASSERTIONS, not an application defect
Both failed identically: *"Failed asserting that 0 is identical to 1"* on the `skipped` count of a
**second** import of the same file.

- `vl9` line 290: `assertSame(1, $second['skipped'])` on a no-acknowledge re-upload.
- `vl10` line 333: `assertSame(1, $r2['skipped'])` on the resume import.

**Root cause (pre-existing, correct behaviour):** `InventoryImportService::duplicateReason()` matches a
row against **existing** `sca_eyewear_items` on `brand + model_name + frame_serial`. After the first
import creates the item, re-uploading the same file re-classifies that row as a duplicate **WARNING**.
With `acknowledgeWarnings = false`, a WARNING row is **excluded from the importable set**, so it is
neither re-created **nor** counted as `skipped` (the durable ledger-skip path is only reached by
importable rows). The tests wrongly expected `skipped = 1` on a no-ack re-upload. This duplicate-WARNING
guard is existing import behaviour, untouched by the variant-linking change.

**The guarantee itself holds — proven empirically** (direct run against the disposable DB, rolled back):

```
preview#1 row=VALID variant=valid → import#1 imported=1 skipped=0 link=linked  → items=1 links=1 audit=1
preview#2 row=WARNING (dup)       → import#2(no-ack) imported=0 skipped=0      → items=1 links=1
                                    import#3(ack)    imported=0 skipped=1       → items=1 links=1 audit=1  (batch identical)
```

So a re-upload **never duplicates** the physical item or the variant link (requirement [27]): without
acknowledgement the duplicate row is simply not re-imported; with acknowledgement it reaches the ledger
and is **skipped**. Both paths leave exactly one item, one link, one audit row.

### Exact test correction required (TEST-ONLY; to be authorized as a separate step, not done here)
- `vl9`: for the no-ack re-upload assert `imported === 0 && skipped === 0` (and still `items === 1`,
  `links === 1`); add a third import with `acknowledgeWarnings = true` asserting `skipped === 1 &&
  imported === 0` to exercise the ledger-skip resume path.
- `vl10`: run the resume import with `acknowledgeWarnings = true` so the already-imported sibling (now a
  duplicate WARNING) is importable and hits the ledger-skip → `skipped === 1` (row 1) and `imported ===
  1` (row 2, previously failed). (Equivalently, assert the no-ack numbers: row 2 `imported === 1`, row 1
  excluded as WARNING with `skipped === 0`.)

No application change is implied; the service already behaves correctly. This mirrors prior test-only
corrections (e.g. the Shopify reconciliation `rc21` correction) handled as a separate disclosed commit.

## Requirement verification [18]–[30]
All GREEN. [18] no column behaves as before — `vl8` + null-stable `content_sha256`. [19] empty cell
unlinked — `vl7`. [20] valid variant → one item + exact link (+ audit, INTAKE-only) — `vl1`. [21] many
items → one variant — `vl2`. [22] malformed / unknown / archived-variant / archived-product / cross-store
fail closed per row — `vl3`/`vl4`/`vl5`/`vl5b`/`vl6` (ambiguous is defensive/unreachable under
`UNIQUE(shop_domain, shopify_variant_id)`). [23] preview never creates inventory/links — `vl3`/`vl4` +
`InventoryImportTest::bi1`. [24] confirm re-checks eligibility (variant archived between preview and
confirm → that row fails and rolls back) — `vl10` first half; ACL re-check — `vl12`/`vl13`. [25] atomic
commit/rollback of item + ledger + link + audit — `vl10` first half + empirical proof. [26] partial
failure preserves valid siblings and resumes safely — `vl10` first half (sibling imported, no orphan, one
ledger row) + empirical resume proof. [27] repeated uploads cannot duplicate — **empirically proven**
(above). [28] batch identity deterministic + compatible — `vl8` (null-stable without the column) +
`vl8b` (variant value changes identity). [29] only staff with `sca.eyewear.shopify.link` can submit a
linking import — `vl12` (blocked) / `vl13` (permitted). [30] imported eyewear uncertified, no
QR/ownership/sale-link — `vl11` (no provenance).

## Side-effect check (step 17)
Provenance, certification, QR (artifact + batch labels), and order-assignment suites: **98/98 pass**. The
variant-linking change (import-time link via the sole writer `ShopifyProductLinkService`, in the per-row
transaction) introduced no regression in any of them.

## Cleanup and production verification (steps 33–35)
- Dropped `sca_domain_test` and `sca_test` (verified absent). Disconnected `kr-mariadb` from `sca_testnet`
  and removed the network (verified gone; `kr-mariadb` back to `sca_internal` only). Removed the isolated
  worktree (verified). Shredded the test password file; removed the probe/proof scripts.
- **Production unchanged**: live tree `4faf84d`, clean; `sca_krayin` migrations = **146**, max batch =
  **30**; `sca_eyewear_items` = **3**, `sca_eyewear_item_shopify_variant` = **0**, `sca_inventory_imports`
  = **0** (identical to the pre-task baseline — the scoped test user could never write `sca_krayin`, and
  root DDL touched only `sca_domain_test`). `kr-app` healthy.

## Remaining issues / next steps
1. **TEST-ONLY correction** of `vl9` / `vl10` assertions (above) — recommended as a separate authorized
   commit; after it, `InventoryImportVariantLinkTest` is expected fully green. **No application code
   change.**
2. On approval: re-confirm the corrected test green in isolation, then proceed to a code-only release
   candidate off production and a controlled deployment (each separately authorized).
3. Secure-claim RC `4bd88d2` remains DEPLOYMENT-BLOCKED and untouched. No email / no Option C.

**STOP — isolated regression complete. Feature CORRECT; existing (60/268) and side-effect (98/302) suites
GREEN; requirements [18]–[30] verified; no-duplicate guarantee [27] empirically proven. The only 2
failures are incorrect `skipped`-count assertions in the new candidate test (`vl9`/`vl10`) — a test-only
defect with the exact correction specified above; no application defect, and no code was modified.
Disposable DB/user/network/worktree removed; production verified unchanged at `4faf84d`.**

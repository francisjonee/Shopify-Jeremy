# SCA — Ownership Transfer Status Clarity: Isolated DB Regression — RESULT

**Authorized single isolated disposable-DB session for candidate `a44103a` (branch
`feat/sca-transfer-status-clarity`). VERDICT: both suites GREEN — 23 tests / 76 assertions /
0 errors / 0 failures / 0 warnings / 0 skips.** The transfer status-clarity improvements are proven
and the existing ownership-transfer protections remain intact. Disposable DB only; dropped +
verified; production `sca_krayin` + SHA `cb8a8c3` unchanged. No merge/deploy, no prod DB change, no
live transfer, no Shopify/email/R0-R0c/Option-C change. 2026-10-29. **STOP.**

## [1] Candidate + isolated worktree
- `origin/feat/sca-transfer-status-clarity` = **`a44103ab0009bfedeef7830f3abedaf2270d6485`** (verified
  on origin). Detached worktree at that SHA in the scratchpad; dev vendor built via the app image
  `sca-app:krayin-2.2.6` (has `gd`/`intl`/`calendar`; `composer:2` lacks them). Live checkout
  `/opt/sca-platform` stayed `main cb8a8c3`, clean — bind-mount never touched.

## [2][3] Fresh disposable DB (literal `sca_domain_test`)
- Re-checked **absent + 0 active connections** immediately before create (and at baseline). Created
  fresh `sca_domain_test` (utf8mb4/unicode_ci). A dedicated session user `sca_test` was granted
  `ALL PRIVILEGES ON sca_domain_test.*` **only** — it held no privilege on `sca_krayin` at all (a
  stronger isolation guarantee than a shared account). Had the DB existed or been in use, the session
  would have stopped.

## [4] Isolation verified (all four sources = `sca_domain_test`, never `sca_krayin`)
```
getenv(DB_DATABASE) = sca_domain_test
SCA_TEST_DB         = sca_domain_test
connection db       = sca_domain_test
SELECT DATABASE()   = sca_domain_test
ISOLATION OK
```

## [5] Migrate + seed (disposable DB only)
- `php artisan migrate --force` → all migrations through batch 30 (incl. the 4 additive R0c
  migrations present on this lineage) applied to `sca_domain_test`.
- `php artisan db:seed --force` → Webkul installer seeders (user/workflow/config) succeeded (web
  routes need the config/channel seed).

## [6] `TransferStatusClarityTest` — **OK (8 tests, 24 assertions)**, 0 err/fail/warn/skip
| Test | Result |
|---|---|
| d1 no-pending shows ordinary transfer link, not banner | ✔ |
| d2 pending shows banner + "awaiting acceptance" + manage action | ✔ |
| d3 invite token (and accept URL) never rendered in item-detail HTML | ✔ |
| m1 generate shows confirmation message | ✔ |
| m2 cancel shows confirmation message | ✔ |
| m3 accept shows confirmation on My Collection | ✔ |
| a1 non-owner cannot see transfer controls or pending banner (404) | ✔ |
| a2 unauthenticated cannot view item detail (→ login) | ✔ |

## [7] `TransferWorkflowTest` — **OK (15 tests, 52 assertions)**, 0 err/fail/warn/skip
All existing ownership-transfer protections confirmed intact: owner-only initiate (t1/t2),
reuse-pending-no-duplicate (t1b), atomic ownership move + My-Collection transition (t3/t4),
append-only history preserved (t5), self-transfer rejected (t6), stale-after-owner-change rejected
(t7), double-accept idempotent → exactly one owner (t8/t14), cancel invalidates invite (t9),
infra-failure propagates leaving no partial transfer (t10), passport stays owner-private after
transfer (t11), unauthenticated/staff cannot use transfer (t12), HTTP accept flow + self-409 (t13).

## [8]–[13] Verification objectives — confirmed
- **[8] Banner only when a valid pending invitation exists:** d1 (none → ordinary link, no banner) +
  d2 (pending → banner). The flag is `TransferWorkflow::pendingInviteToken(...) !== null`, which is
  itself scoped to a `state='pending'` + `expires_at > now()` row.
- **[9] Banner states ownership stays with the current owner until acceptance:** d2 asserts the copy
  "awaiting acceptance by the recipient"; the banner also reads "You remain the registered owner
  until they sign in and accept."
- **[10] Generate / cancel / accept show clear confirmation messages:** m1/m2/m3.
- **[11] Non-owners cannot access private transfer details/controls:** a1 (non-owner detail = 404,
  no banner/controls/token) + TransferWorkflow t2 (non-owner initiate rejected) + t12 (staff/anon).
- **[12] Invitation tokens + acceptance URLs never in the item-detail HTML:** d3 asserts the 32-hex
  token and the `/collector/transfer/<token>` accept URL are both absent from the rendered page
  (the controller passes only a boolean).
- **[13] Expiry / cancellation / replay / self-transfer protections unchanged:** t7 (stale), t9
  (cancel invalidates), t8 (double-accept idempotent / replay), t6 (self-transfer rejected) — all
  pass; no transfer service/workflow code was modified by the candidate.

## [14] Exact totals
- `TransferStatusClarityTest`: **8 tests, 24 assertions, 0 errors, 0 failures, 0 warnings, 0 skipped.**
- `TransferWorkflowTest`: **15 tests, 52 assertions, 0 errors, 0 failures, 0 warnings, 0 skipped.**
- **Combined: 23 tests, 76 assertions, 0/0/0/0.** No failing code was repaired or masked.

## [15] Cleanup verified
`REVOKE ALL` → `DROP USER 'sca_test'@'%'` → `DROP DATABASE sca_domain_test`. Post-checks:
`SHOW DATABASES LIKE 'sca_domain_test'` empty (gone); `mysql.user` count for `sca_test` = 0;
`sca_krayin` still present. Worktree removed; test `.env` shredded + probe file deleted.

## [16] Production unchanged (identical to pre-session baseline)
- Live SHA **`cb8a8c3`**, branch `main`, working tree clean; loopback `/admin/login → 200`.
- `sca_krayin` fingerprint: migrations **batch 29 / 145 rows**; items **3** / ownership_events **5** /
  claims **2** / certifications **4** / qr_identifiers **3** / shopify_sale_links **1**; R0c
  `sca_presale_claim_grants` table **absent (0)** and `sca_shopify_sale_links.order_email` column
  **absent (0)**.

**STOP — candidate `a44103a` passes the authorized isolated regression (23/23); production untouched.
NEXT (separate authorization): code-only merge review of the transfer status-clarity branch (it is a
presentation-only change off main `e644c9c`, no migration). No deploy without separate approval.
SEPARATE OPEN: Phase-1 first genuine `products/*` webhook receipt verification.**

# SCA — pi8 Regression Flake Investigation (RESULT)

**Root cause found and proven; the staff-dashboard change is regression-safe. `CollectorPublicItemTest::pi8_public_html_allowlist` was a pre-existing fragile-assertion TEST DEFECT, not a product regression, not state contamination, and not caused by the staff-dashboard branch. pi8 asserts the public collector-profile HTML does not contain the RAW NUMERIC collector/item id as a bare substring; for a small auto-increment id (1, 2, 3, 4, …) that single digit is unavoidably present in any HTML — reproduced and captured inside the inline CSS hex colour `#1f2937`, px units, and the digits of the legitimately-shown opaque `SCA-`/`PUB-` references. Because rolled-back inserts still advance InnoDB's AUTO_INCREMENT, the id value — and therefore whether its digit collides — depends on how many tests ran before it, so pi8 passed or failed purely by ordering luck. The fix is a smallest, test-only, non-weakening correction: pi8 now forces large, distinctive sentinel ids (900000001 / 900000002) so a genuine id leak would still be caught while the check can no longer collide with incidental short-digit runs; every meaningful privacy assertion (email, opaque public_ref, frame serial, SKU, QR token, storage `catalog/` path) is unchanged. After the fix the complete SCA regression suite is green: 1,612 tests / 8,256 assertions / 0 failures / 0 errors / 1 skip.** Investigated entirely in a disposable, network-isolated sandbox (no production DB access, no outbound network); production unchanged at `6e36aa7`. 2026-11-03. **STOP.**

> Written for: the owner (Jeremy) and the external auditor.

## Investigation (how the cause was proven)
Branch `investigate/pi8-flake` off the staff-dashboard branch `4a33e938`, in an isolated sandbox
(disposable `sca_domain_test` + restricted `sca_test` user, internal-only docker network, worktree app
read-only; proven before testing: internet egress blocked, prod DB → ERROR 1044, identity
`sca_domain_test`).

1. **Reproduced** (Task 1): on a fresh `migrate:fresh --seed` DB, `pi8` run alone **failed** with
   `leak: 2`, then `leak: 3`, then `leak: 4` on successive runs — the "secret" was always a small integer
   equal to the test's collector/item id, and it climbed because each rolled-back run still advanced
   AUTO_INCREMENT. (Run as part of its own 29-test file it had *passed*, because the preceding tests
   pushed the id to a non-colliding multi-digit value; in the full 1,612-test suite it had failed at
   `leak: 364`.)
2. **Located the "contamination"** (Tasks 2–3): not DB rows, application state, auth, or config — it is
   the shared **AUTO_INCREMENT counter**, which `DatabaseTransactions` does not roll back. Any earlier
   test that inserts-and-rolls-back a collector/eyewear row moves the id pi8 receives.
3. **Proved it is incidental, not a real leak** (instrumented dump): with collector_id = item_id = 4, the
   only occurrences of "4" in the body were inside the inline `<style>` hex colour `#1f2937` and inside
   the opaque `SCA-`/`PUB-` references the page is *supposed* to show. The internal numeric id is **never
   rendered as an identifier** (the public profile is keyed entirely by opaque refs + a QR image URL).
4. **Baseline comparison** (Task 4): the preceding dev baseline `bdea6ac` happened to land pi8's id on a
   non-colliding value, so its full run was 0-fail; adding 8 staff-dashboard test methods shifted the
   AUTO_INCREMENT position onto a colliding id. The staff-dashboard change touches only `Sca\Registry`;
   `pi8` exercises the untouched `Sca\Collector` / `Sca\Passport` public profile.
5. **Classification** (Task 5): **pre-existing test defect** (a fragile `assertStringNotContainsString`
   over a bare small integer). Not a genuine application regression; not an environmental artifact in the
   product.

## Fix (Task 6) — test-only, does not weaken any guarantee (Task 7)
`tests/Feature/Sca/CollectorPublicItemTest.php` only. pi8 now creates its collector and item with large
distinctive sentinel ids (`900000001` / `900000002`) via two optional helper parameters (`collector(…,
$id)`, `ownCertified(…, $itemId)`; both default to `null` → auto id for every other caller). The existing
`assertStringNotContainsString((string) $id, $body)` checks are retained and are now **meaningful** (a
9-digit id cannot appear incidentally, so a real leak would be caught) and **collision-free**. The
distinctive-string privacy assertions (collector email, opaque `public_ref`, `FRAME-SERIAL-SECRET`,
`SKU-SECRET`, the 32-hex QR token, and the storage `catalog/` path) are unchanged. No production code,
service, migration, route, security, authorization, privacy, or application behaviour changed.

## Results (Tasks 8–9)
- **Branch / commit:** `investigate/pi8-flake` = `f4509f706ace1a8b088a1aac190fc0bfed6d08a6` (off `4a33e938`); pushed to the implementation origin; **not deployed, not merged**.
- **Changed files:** 1 — `tests/Feature/Sca/CollectorPublicItemTest.php` (test-only).
- **Affected test:** `pi8` alone → OK (11 assertions, all now execute); whole `CollectorPublicItemTest` → 29 tests / 118 assertions / 0 fail.
- **Full SCA regression suite** (`tests/Feature/Sca`): **1,612 tests / 8,256 assertions / 0 failures / 0 errors / 1 skip** (exit 0). (Previously 1 failure = pi8.)
- **Conclusion:** the staff-dashboard change (`4a33e938`) is **genuinely regression-safe** — with this pre-existing test defect corrected, the complete suite passes; the branch introduced no product regression.

## Safety posture (this task)
Read-only against production + a test-only change on a dev branch. No Shopify API request or store
change; no production DB write; no deployment or migration; no inventory import, authentication,
certification, or QR generation; no customer claim or ownership transfer; secure claiming NOT activated;
`origin/main` NOT merged; the 205 imported records untouched. All tests ran in a disposable environment
with no production DB access and no outbound network. Production unchanged at `6e36aa7`; `vendor/` still
`--no-dev`; sandbox and worktree removed.

**STOP — Cause: `pi8` asserted a bare small numeric id is absent from the public-profile HTML, but that
digit is unavoidably present (CSS hex colours, px units, opaque SCA-/PUB- ref digits); AUTO_INCREMENT
(not rolled back) made the id — and the collision — depend on full-suite ordering. Pre-existing test
defect, not a product regression and not caused by the staff-dashboard change (untouched public-profile
code path). Test-only fix: large sentinel ids in pi8 (non-weakening; meaningful privacy checks intact).
Final: full suite 1,612/8,256/0-fail/0-error/1-skip on `investigate/pi8-flake` (`f4509f70`). Dashboard
change confirmed regression-safe. Not deployed/merged; prod `6e36aa7` intact.**

# SCA-COLLECTOR-IMAGE-PRESENTATION — placeholder follow-up (VIEW-ONLY)

**Date:** 2026-10-01 · **Base:** deployed main `4af8a65` (collector item-detail parity).
**Scope:** view-only. **Status:** DONE — merged `--no-ff` + deployed. FINAL PASS/GO authorized candidate `4a3429d`.

## Merge + Deploy result

`MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = 91dfb2a605b7ad1f18fd85591e2a0f839ef932c7`
(reviewed candidate `4a3429d`, base `4af8a65`, 1 commit, 2 files).

**Pre-merge fail-closed gates (all passed):** origin/main == `4af8a65`; feature HEAD == `4a3429d`;
merge-base == `4af8a65` (exactly 1 commit over base, no divergence); on `main`, tree clean; scope = 2
files / +36.

**Deploy (`scripts/deploy-preview.sh`, exit 0):** test gate + `--no-dev` build passed under `set -e`;
**Nothing to migrate — migrations remain 119**; caches cleared; kr-app healthy; `Deployed main @ 91dfb2a`.
(Chowned `storage`/`bootstrap/cache` to uid 33 before deploy to avoid the known root-owned-dir gate
failure.)

**Post-deploy verification (all green):**
- Deployed HEAD == origin/main == merge SHA `91dfb2a`; migrations 119.
- **Live deployed render, owner (collector 1) of the real NULL-image item 3 (`SCA-F1B792AE4745`): 200,
  "No catalog image" placeholder PRESENT, no owner-image `<img>` (correct for NULL image), no
  `image_path`/`image_mime`/`frame_serial` leak.** (Image-present owner-route behavior proven by rg9 on
  this exact commit; non-owner/previous-owner privacy-safe 404 by rg5.)
- SCA-038 over verify.: valid 200 / bogus 404 / malformed 404 (Option-A constant-shape intact).
- `/storage` edge-denied 404; `/collector` auth-gate 302; `:8080` pilot passport 200; smsrocket.io 302.
- sca_edge auto-attached on recreate (172.20.0.3); MariaDB private (sca_internal 172.19.0.3 only);
  Caddyfile sha `0faece7a` unchanged; DOCKER-USER :8080 staff-IP allowlist + default-drop intact.
- Pilot public bind `195.26.255.80:8080` re-applied from `stash@{0}` after the deploy recreate (committed
  compose = loopback), compose restored to committed; kr-app healthy.
- **Zero QR/provenance/domain mutation:** QR is_production 0,0; items image_path NULL/NULL, sku NULL/NULL;
  counts qr=2 / certs=3 / certev=4 / auth=3 / own=4 — identical to baseline.

Stop after merge/deploy verification. No next task.

---

### (push-only record, superseded by the merge above)

## Intent

The collector item-detail left identity panel must *always reserve the image area*. The diagnostic
audit (gov `1dfaf48`, case **(b)**) established that both production items have `image_path = NULL`,
so the collector showed nothing where the image slot should be (no `@else`), while Admin renders a
"No catalog image" placeholder in the same situation. The owner-authorized image rendering path was
proven correct — the only gap was the missing placeholder (presentation only).

## Change

Single view edit — `packages/Sca/Collector/src/Resources/views/collection/show.blade.php`:

- `has_image = true` → the **existing** `<img>` is preserved verbatim, sourced only from the
  owner-authorized `route('collector.collection.image', …)` — never `/storage`, `image_path`, or
  `image_mime`.
- `has_image = false` → a polished **"No catalog image"** placeholder (dashed-border 180px box,
  muted text), visually consistent with the Admin/catalog placeholder.

No service / controller / DTO / schema / route / ACL change. The two-panel + CSS-only-tabs structure
and responsive behavior are untouched. Authorization is unchanged (owner-only `collector.collection.image`).

## Regression

`tests/Feature/Sca/CollectorItemDetailParityTest.php` — new `rg9`:

1. **NULL image →** "No catalog image" placeholder present, and **no** `/collector/collection/{ref}/image`
   `<img>` emitted.
2. **image present →** the owner-authorized `/collector/collection/{ref}/image` URL is rendered and the
   placeholder is **absent**.
3. **privacy/staff-only exclusions intact →** the raw stored path (`sca-catalog`), its disk URL
   (`/storage/sca-catalog`), and the `image_mime` column never appear in the HTML. (A core
   `/storage/configuration/` CSS selector for the CRM logo is unrelated framework output and is
   correctly out of scope.)
4. **zero mutation →** provenance/QR/ownership fingerprint identical before/after viewing with an image set.

## Results

- Focused `CollectorItemDetailParityTest`: **9 passed / 58 assertions** (rg1–rg9).
- Full `tests/Feature/Sca`: **688 passed / 3684 assertions** (687 + rg9).
- `php -l` clean on the modified view.
- Diff: 2 files, +36 lines (view +5, test +31). No other files touched.

## Invariants (to re-confirm at deploy, not changed here)

QR fingerprint `a920dc1c…`, migrations 119, `is_production` 0,0, SCA-038 Option-A public passport,
`/storage` edge-denied, MariaDB private, sca_edge persistence. Both prod items remain `image_path` NULL —
once a catalog image is uploaded via the existing Slice-1 staff catalog-edit, both Admin and Collector
display it automatically (already proven in the audit probe).

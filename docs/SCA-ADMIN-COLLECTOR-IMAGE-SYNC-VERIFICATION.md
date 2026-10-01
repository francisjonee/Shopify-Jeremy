# SCA — Admin → Collector image synchronization verification (READ-BEHAVIOR, net-zero)

**Date:** 2026-10-01 · **Deployed:** `91dfb2a` (collector "No catalog image" placeholder live).
**Subject:** real collector-owned item **3** (`SCA-F1B792AE4745`), owner = collector 1.
**Result:** ✅ PASS at every step. Admin's catalog image is the single source of truth; the Collector
page reflects it automatically with no separate collector field, copy, or sync job. **Zero
QR/provenance/certification/ownership mutation throughout; item 3 and the catalog disk returned to their
exact pre-test baseline.**

## Method

Exercised the **real production code paths** (not DB pokes): the Admin `EyewearItemController::updateCatalog`
controller (the existing Edit-catalog control, `POST admin/sca/eyewear/{id}/catalog`, ACL
`sca.eyewear.catalog`) with genuine `UploadedFile` uploads, and the real HTTP kernel for Admin/Collector
GET renders and the image-stream routes. Provenance fingerprint = md5 of each of
`sca_qr_identifiers / sca_certifications / sca_certification_events / sca_authentications /
sca_ownership_events` (full ordered JSON), captured as baseline and re-checked after every mutating step.

Baseline: item 3 `image_path=NULL, image_mime=NULL, sku=NULL`; PFP
`qr=9e9043cb cert=a4a3afbb certev=fe4c88b8 auth=3b498071 own=36d8eba3`.

## Steps & evidence

**1. Admin upload (image A, md5 `ca5a761…`).** `updateCatalog` → 302; item 3 `image_path=sca-catalog/f15w4…png`,
`image_mime=image/png`; file stored on the `public` disk; stored bytes == A. Admin show renders the
`admin.sca.eyewear.image` `<img>` (no "No catalog image"); Admin image route → 200 `image/png`, bytes == A.
**Collector 1 opening the same item automatically** renders `collector.collection.image` (no placeholder);
`collector.collection.image` → 200 `image/png`, **bytes == A (same source)**. No separate collector upload
performed. No `/storage/sca-catalog`, raw `image_path`, or `image_mime` in the collector HTML. **PFP unchanged.**

**2. Admin replace (image B, md5 `c704da6…`, distinct from A).** `updateCatalog` → 302; `image_path`
changed; the old A file was deleted from disk. **Collector automatically shows B** (collector image route
bytes == B, not A; status 200), detail still renders the owner route with no placeholder. No collector
operation performed. **PFP unchanged.**

**3. Admin remove (`remove_image=1`).** `updateCatalog` → 302; item 3 `image_path=NULL`, `image_mime=NULL`;
the B file was deleted from disk. **Collector automatically returns to "No catalog image"** (placeholder
present, owner image route absent from HTML); `collector.collection.image` → 404. **PFP unchanged.**

**4. Non-owner cannot access the collector image route.** (a) Unauthenticated request to item 3's image
route while an image was present → 302 (login redirect), **no image bytes leaked**. (b) Authenticated
collector 1 requesting an item they do not own (item 1) → **404** (ownership-scoped). (The authenticated
previous-owner/non-owner 404 for the detail page is also covered by regression rg5 and the Slice-3
owner-authorization proof.)

## Single-source-of-truth confirmation

There is exactly one image field — the SCA item's `image_path`/`image_mime`, set only by Admin's catalog
control. The collector read path (`CollectionService::catalogImageForOwnedItem` → `collector.collection.image`)
streams **that same file**, resolved server-side via the owner's item id. No second collector image column,
no copy, no synchronization job exists or was added. `has_image` is derived (`image_path !== null`), so the
collector surface tracks Admin automatically.

## Net-zero / cleanup

Final state: item 3 `image_path=NULL, image_mime=NULL, sku=NULL`; item 1 `image_path=NULL`; **PFP identical
to baseline**; `public` disk `sca-catalog/` = 0 files. Both test uploads (A 126 B, B 170 B) were deleted by
`updateCatalog`'s own replace/remove logic. One **pre-existing** orphan (`sca-catalog/K10lQ…png`, 614,748 B,
mtime 13:54 — a leftover from the earlier SCA-COLLECTOR-IMAGE-PRESENTATION audit probe that nulled
`image_path` without deleting its file) was found unreferenced and removed after confirming 0 item
references, leaving the catalog disk clean. All in-container work ran as uid 33 (no root-owned storage
dirs); impl working tree clean at `91dfb2a`; deployed HEAD unchanged; verify./: 8080/smsrocket healthy.

**Conclusion:** No defect. Admin → Collector image synchronization works exactly as intended with Admin as
the single source of truth. No code change made or required.

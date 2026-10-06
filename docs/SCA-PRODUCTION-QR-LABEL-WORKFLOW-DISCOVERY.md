# SCA Production QR / Label Workflow — Discovery & Plan (PLAN/DISCOVERY ONLY)

**Date:** 2026-10-06 · **Status: READ-ONLY discovery + plan. No code/migration/QR-regeneration/test-data/deploy change performed.** · Deployed app `98ae654`, migrations **120**. For ChatGPT audit.

**Question answered:** can a non-technical Second Chance Eyewear employee open a certified frame and print its permanent SCA QR label/card today, and if not, what is the smallest extension of the existing system that gets them there? **The entire QR identity + rendering + public-passport chain already exists and is production-grade. The only missing piece is an in-app, print-optimized label/card view — everything else is reuse.**

---

## A. End-to-end trace: certified eyewear → QR → passport → generation → staff access → print

| Stage | Status | Where (file:line) |
|---|---|---|
| Certify → mint + activate first QR identity | ✅ EXISTS | `CertificationService.php:81-82` → `QrService::createIdentity($itemId)` then `activate()` |
| Immutable QR identity row | ✅ EXISTS | table `sca_qr_identifiers` (migration `2026_09_14_120006…`): `public_token char(32) UNIQUE` "permanently immutable", `is_production` bool default false, `created_at` only, **no updated_at**; DB trigger `trg_sca_qr_identifiers_no_update` blocks UPDATE |
| Token value | ✅ EXISTS | `Support/Token.php::opaque()` → `bin2hex(random_bytes(16))` = 32-hex CSPRNG, host-independent (no URL/port/sequence baked in) |
| Lifecycle (active/revoked) | ✅ EXISTS | event-sourced in `sca_qr_lifecycle_events`, projected to `sca_item_current_state.active_qr_identifier_id` (no status column on the identity row) |
| Permanent public passport URL | ✅ EXISTS | route `sca.passport.show` = `/p/{token}` (`Passport/.../public-routes.php:18`); QR encodes `config('app.url') + /p/{token}` = `https://verify.secondchanceauthenticators.com/p/{token}` |
| QR image (SVG) generation | ✅ EXISTS | `Registry/.../EyewearItemController.php::qr()` (~365-408): chillerlan `^6.0`, `QRMarkupSVG`, `EccLevel::H`, `quietzoneSize=4`, `svgUseFillAttributes=true` (self-contained, no external CSS). **Single render site.** No caption, no logo composited. |
| Staff download of the SVG | ✅ EXISTS | route `admin.sca.eyewear.qr` (`Registry/.../admin-routes.php:40`), ACL **`sca.eyewear.view`**; returns `image/svg+xml` **attachment** `sca-qr-{public_ref}.svg` (token never in filename), `nosniff`, `no-store` |
| Staff UI entry point | ✅ EXISTS (download link only) | `eyewear/show.blade.php` "Certification & QR" area: token text (labeled "not a URL") :350; **"Download printable QR (SVG)"** link :357; "Reissue QR" link (ACL-gated) :359-363 |
| **In-app print / label / card view** | ❌ **ABSENT** | no print endpoint, no inline on-screen QR preview, no `@media print`, no `window.print()`, no card layout anywhere under `packages/Sca/` (only unrelated `@page` on the certificate PDF) |

**Today's staff reality:** open item → "Certification & QR" → **Download printable QR (SVG)** → a **bare SVG file** lands in Downloads → the employee must open it in some app and print it, at an arbitrary size, with **no human-readable ref, no "scan to verify" caption, no branding, and no size/quiet-zone guarantee** on the page. For a non-technical employee this is a file-handling chore, not a "print this label" button. **That is the gap.**

---

## B. Specific checklist answers

1. **Are QR images generated/rendered?** YES — on demand as a self-contained SVG (ECC-H, 4-module quiet zone, explicit per-module fills). Not stored on disk; regenerated per request from the immutable token. No PNG, no caption, no embedded logo.
2. **Where can staff access them?** The item **show page → "Certification & QR" area → "Download printable QR (SVG)"** link (`admin.sca.eyewear.qr`), behind staff-IP `/admin` + `sca.eyewear.view`. Download only — **no inline preview, no print view**.
3. **Do QR URLs use the permanent SCA domain?** YES — `config('app.url')` = `https://verify.secondchanceauthenticators.com`; the encoded value is `…/p/{token}`. (Config also mentions an "inert" `PUBLIC_QR_BASE_URL` concept that is deliberately NOT used.)
4. **Are QR identifiers immutable/permanent?** YES — `char(32)` unique token, identity row has only identity columns + `created_at`, a DB `BEFORE UPDATE` trigger hard-blocks mutation, lifecycle is append-only/event-sourced. The token carries no host, so it survives domain/infra changes.
5. **Does test vs production QR handling exist?** A **field** exists (`is_production`, default false) but it is **inert**: no code path ever sets it true (every mint is false; reissue carries the prior value forward), and **nothing reads it** to change behavior or labeling. There is no runtime test-vs-production distinction today — it is scaffolding only.
6. **Is there a print/download action?** DOWNLOAD yes (SVG attachment). **PRINT no** — there is no in-app print view or print stylesheet; printing is left to the browser on the downloaded file.
7. **What happens if a QR is lost or physically damaged?** If the tag is merely damaged/lost but the identity is still trusted → **reprint the same SVG** via the download route (pure read of the current active token; mints nothing; same passport). If the tag must be replaced with a new identity (e.g. compromised) → **Reissue** (`QrService::reissue`, ACL `sca.eyewear.qr.reissue`, typed `REISSUE`, FOR-UPDATE optimistic-concurrency guard) mints a NEW token: old token immediately → constant-shape 404, new token → the **same** item/provenance.
8. **Does reprinting preserve the same QR identity?** YES — the download route always reads `sca_item_current_state.active_qr_identifier_id` and re-renders the identical SVG. Reprint never creates a new passport; only the explicit, guarded **Reissue** does.
9. **Do retired/revoked/disputed items behave correctly when their existing QR is scanned?** YES. **Revoked certification / stale (post-reissue) QR / uncertified / malformed token → constant-shape 404** (`PassportResolver` requires active-QR == projected active and a `state='issued'` cert). **Retired / invalidated / lost / stolen / disputed → 200 with a DOMINANT adverse banner** (presenter `registryCopy()` + `ItemStateLabels::registrySeverity`: stolen=danger, invalidated=invalid, lost/disputed=warning, retired=retired), green authenticity demoted to secondary; `recovered` reads as clear in public. This is already shipped and audited.
10. **What minimal staff UI is needed?** A one-click **"Print QR label"** that opens an in-app page showing an **inline QR preview** + the human-readable `public_ref` + a short "Scan to verify authenticity" caption + SCA branding, with a **Print** button and an `@media print` stylesheet that fixes the QR to a physical size with the quiet zone preserved. Nothing else is required — identity, URL, SVG, and adverse-state handling all already exist.
11. **Recommended physical label/card size + accompanying info:** see §E.

---

## C. Reuse assessment — do NOT build another QR subsystem

The existing system is **sufficient** as the identity/render/resolve substrate. The plan below adds **zero** new QR identity logic, **zero** schema, and **one** render site is preserved: the label view must obtain its SVG from the **same** code that backs the download (extract a tiny shared "build active-QR SVG string" method used by both the attachment response and the print view), so there is never a second QR encoder and the printed vector is byte-identical to the downloaded one (exactly as the physical pilot proved for item 1). No new library, no stored images, no new public route, no change to `/p/{token}`.

---

## D. Implementation breakdown (easy → hard) + recommended first slice

### ★ Slice 1 (RECOMMENDED SMALLEST USEFUL FIRST) — in-app Print QR Label view
- New staff GET route (e.g. `admin.sca.eyewear.qr.label`) + a Blade view rendering: **inline SVG preview** (same bytes as the download), the human-readable `public_ref`, a "Scan to verify authenticity" caption, and the SCA logo **beside/below** the QR (never composited into it), with a **Print** button (`window.print()`) and an `@media print` block fixing the QR to a physical size (§E) and hiding chrome. A "Print label" link added to the "Certification & QR" area next to the existing download link.
- **Reuse:** same immutable token, same passport URL, the **same SVG builder** as the download (small shared method; single render site preserved). ACL `sca.eyewear.view` (or a new read-only `sca.eyewear.qr.print`).
- **No schema, no migration, no QR mint/reissue, no `is_production` change, no public route, no resolver change.** View/controller/ACL only.
- **Why first:** it is the entire difference between "download a bare SVG file" and "a non-technical employee clicks Print and gets a correct, scannable, labeled card." Highest value, smallest surface, fully reversible, independently testable (assert the view embeds the active token's SVG byte-identically + prints at the fixed size + shows `public_ref` + no raw token leak).

### Slice 2 (easy-medium) — batch / sheet printing
- A "print labels" action over a filtered list of certified items → one print sheet of N cards (same per-item SVG builder, looped). More UI, still read-only, no schema. Useful once single-label printing is in daily use.

### Slice 3 (medium) — label content/branding polish & label-stock presets
- Multiple preset sizes (sticker vs card), optional domain text line, print-calibration guidance page, optional PDF export of a label sheet. Still reuses the single SVG builder; no identity change.

### Slice 4 (HARD / architectural — only if a real business need appears) — activate `is_production` semantics
- Because the identity row is **immutable (DB trigger)**, `is_production` **cannot be flipped after mint**. A genuine production-vs-staging distinction would require either (a) deciding it at **mint time** (certification / reissue mints `is_production=true`), and/or (b) surfacing/ gating it in UI and resolver. This touches minting, the immutability model, and possibly the resolver. The physical pilot printed successfully with `is_production=0` (the flag gates nothing), so **this is NOT a blocker for production printing** and should be deferred unless a concrete requirement (e.g. "staging tokens must be unprintable") emerges. Document as deferred.

### Not recommended
- Compositing a logo **inside** the QR (center overlay): reduces scan reliability and complicates ECC; keep branding outside the QR. Printer/SDK-specific integrations (Dymo/Zebra) are out of scope for the smallest useful workflow.

---

## E. Recommended physical label/card (from the validated pilot)

- **QR size:** print the QR module area at **≥25 mm**; recommend **~30 mm** square. Print at **100% / no shrink-to-fit**; never rescale in a way that eats the quiet zone.
- **Quiet zone:** the 4-module quiet zone is already baked into the SVG; add a little extra white margin on the card. **Black-on-white, matte** (avoid glossy/low-contrast).
- **Accompanying info (all OUTSIDE the QR):** the human-readable **`public_ref`** (e.g. `SCA-A960A57D3124`); a short caption **"Scan to verify authenticity"**; optionally the plain-text domain `secondchanceauthenticators.com`; **SCA logo/branding** beside or below the QR. Keep the QR the dominant element.
- **Card formats:** a compact **~40–50 mm sticker** (QR + ref + caption) for attaching to the case/presentation card; or a **~54×85 mm card** (credit-card-ish) when more branding/text is wanted. Per existing pilot policy, attach to the **case/card, not the frame itself without the owner's consent**.
- **Lost/damaged handling for staff on the card page:** reprint = same identity (download/print again); only use **Reissue** when the identity itself must change (and the old printed tag then stops verifying).

---

## F. Constraints honored / out of scope
Read-only discovery. No production/Shopify mutation, no migrations, no code changes, no QR regeneration/reissue, no `is_production` change, no test-data mutation, no deployment. The Shopify integration (Phases 0–5, closed) is untouched. Any implementation starts as a separate, reviewed candidate branch after this plan is audited.

**RECOMMENDATION: approve Slice 1 as the first implementation (in-app Print QR Label view, reuse-only, no schema).** See [[sca-pilot-readiness-operator-workflow-audit]], `docs/SCA-PERMANENT-QR-PHYSICAL-PILOT.md`, `docs/SCA-QR-REISSUE-STAFF-UI-IMPLEMENTATION.md`.

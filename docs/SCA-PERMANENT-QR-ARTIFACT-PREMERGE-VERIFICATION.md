# SCA-PERMANENT-QR-ARTIFACT — Final Pre-Merge Verification

**Date:** 2026-09-30 · **Verifier:** independent pre-merge review (read-only; candidate never deployed).
**Candidate:** `c7eb163b85c046794c4d0acb00ada40d8617cd3a` · **Base:** `bd9e3cdd914b6ac657ad54939f9c692e13463006`.

## VERDICT: ❌ **FAIL / NO-GO** — one confirmed defect (DEFECT-003). Do not merge.

The payload, ACL, active-identity binding, zero-mutation, privacy, filename safety and dependency gates all PASS.
**The generated SVG artifact is not self-contained and is unscannable when used as delivered** (downloaded/printed
without an external stylesheet). This is fatal to the artifact's purpose (a physical, scannable eyewear QR tag).

---

## DEFECT-003 — SVG artifact renders as a solid black square (not scannable) without external CSS

**Where:** `EyewearItemController::qr()` — `QROptions([... 'svgUseFillAttributes' => false ...])`.

**What:** With `svgUseFillAttributes=false`, chillerlan's `QRMarkupSVG` emits 16 layered `<path>` elements keyed only by
CSS class (8 `… dark …`, 8 `… light …` incl. `qr-quietzone light`), with **no `fill=` attributes, no `<style>` block,
and no background rect**. Per the SVG spec the initial `fill` is **black**, so with no accompanying stylesheet *every*
path — dark modules, light modules, and the quiet zone alike — renders black. The result is a uniform black square.

**Proof (actual artifact decoded, not a construction comparison):** the artifact for the real active token
`bee93d2b…` (`https://verify.secondchanceauthenticators.com/p/bee93d2bd7933ba643a872c6bf79ac33`) was rasterized with
chillerlan 6.0.1 + GD and decoded with `QRCode::readFromBlob`:

| Rasterization of the actual artifact | Decode result |
|---|---|
| `.dark`→black, `.light`/quiet→white (i.e. *with* correct CSS) | ✅ decodes to **exactly** the canonical URL |
| **default renderer, no CSS** (every path = black, as delivered) | ❌ `could not find enough finder patterns` |

viewBox `0 0 57 57` → 49-module symbol + 2×4 quiet zone; `eccLevel=2` (== `EccLevel::H`). 3249/3249 cells are covered
by a path (1224 dark). The matrix/payload/ECC/quiet-zone are all correct — **only the color rendering is broken.**

**Delivered as an `attachment` (`Content-Disposition: attachment`),** the `.svg` travels with no HTML/CSS, so when it is
opened in a viewer, embedded in an `<img>`, or rasterized for printing a tag, it is the unscannable black square.

**Fix (one line, verified):** set `'svgUseFillAttributes' => true` (chillerlan's default). The SVG then carries
`fill="#000"`/`fill="#fff"` per layer, is self-contained, and — decoded from its own declared fills — round-trips to
exactly the canonical URL. (A `<style>`/`svgDefs` with explicit `.dark{fill:#000}.light{fill:#fff}` + a white background
is an equivalent alternative; `true` is the smallest.)

**Why CI missed it (test blind spot — must also be fixed):** `QrArtifactTest::rg2` proves the payload by decoding a
**separately-rendered PNG** (`QRGdImagePNG`) of `$expected`, and its SVG check (`assertSame($this->svgOf($expected),
$body)`) byte-compares the endpoint SVG to a reference built with the **same** `svgUseFillAttributes=false` — tautological
w.r.t. this defect. **No test rasterizes/decodes the SVG body or asserts self-containment.** The added regression must
rasterize the actual SVG (or assert `fill=` attributes / a `<style>` block are present) and decode it.

---

## Gate-by-gate results

| Gate | Result | Evidence |
|---|---|---|
| Git identity (origin/main==base; local+origin feature==candidate; merge-base==base; exactly 1 commit; clean tree) | ✅ PASS | all equalities hold; `rev-list base..cand = 1` |
| Exact reviewed file scope | ✅ PASS | 7 files only (controller, view, routes, composer.json/lock, test, task-report); no infra/config/bootstrap |
| Route GET-only, item `{id}` identity, `sca.eyewear.view` ACL, no public endpoint | ✅ PASS | `GET {id}/qr` `[0-9]+` `sca.can:sca.eyewear.view`; group wrapped by `web,admin_locale,sca.auth`(=ScaAuthenticate) under admin prefix; `sca.can`=ScaAuthorize; public-routes.php untouched |
| Active-identity binding (older/revoked/stale cannot be selected) | ✅ PASS | token read only via `sca_item_current_state.active_qr_identifier_id` → `sca_qr_identifiers WHERE id=activeQrId`; no item-scoped fallback |
| Decoded payload == exactly `https://verify.…/p/{active_token}` | ✅ PASS (payload) | decode of the actual artifact matrix + PNG cross-check both equal the exact URL; live `config('app.url')`=verify., route path `/p/{token}` |
| ECC H + quiet zone ≥4 (effective config) | ✅ PASS | `eccLevel=2`(H); viewBox 57 = 49 + 2×4 |
| **Self-contained scannable SVG artifact** | ❌ **FAIL** | **DEFECT-003** — default-CSS render is solid black, decode fails |
| Failure behavior — nonexistent item / no active QR / projection→no usable QR / unauthorized; no create/rotate/revoke/update | ✅ PASS | `find`→null→404; null `active_qr_identifier_id`→`''`→404; missing qr row→`(string)null=''`→404; only `->value()` reads, zero writes; ScaAuthenticate→login redirect, ScaAuthorize→403 |
| Response privacy (token only inside QR; no PII/IDs/other tokens) | ✅ PASS | token not in HTML/headers/filename/flash/logs; response = SVG bytes + fixed headers; filename uses `public_ref` only |
| Filename safety / header injection | ✅ PASS | `public_ref` = `SCA-[0-9A-F]{12}` (`Token::publicRef`), char(20), immutable — no quote/CRLF/slash possible |
| Composer / prod compatibility + PHP extensions | ✅ PASS | chillerlan/php-qrcode 6.0.1 in `require` (not dev); needs php ^8.2 + ext-mbstring (+ settings-container 3.3.0 / ext-json) — all present in prod image; no ext-gd needed at runtime (SVG output) |
| SCA-038 valid→200 / bogus→constant-shape 404 | ✅ PASS | live `verify./p/{valid}`→200, `/p/{bogus 32-hex}`→404 |
| Zero production mutation | ✅ PASS | read-only queries + isolated `/tmp` harness; snapshot unchanged: qr=2, life=2, certs=3, auth=3, own=4, is_production=0,0, active proj 1:1/3:2, migrations=118 |
| Pilot on `bd9e3cd`, candidate absent from runtime; Phase-2C HTTPS/edge + :8080 unchanged | ✅ PASS | candidate never deployed; chillerlan absent from app vendor; no `/qr` route live; `verify.` 200/404 + `:8080` 200; kr-app healthy on 195.26.255.80:8080 |

**Focused/full test totals:** not re-run here — reproducing them requires checking the unaudited candidate onto the
shared production-adjacent pilot, and the totals do not bear on the verdict (the suite is green yet misses DEFECT-003,
as shown above). The candidate reports focused 10/38 + full `tests/Feature/Sca` 651/3503.

## Recommendation

Return to the author. Minimal remediation: (1) `svgUseFillAttributes => true` in `EyewearItemController::qr()`;
(2) add a regression that rasterizes/decodes the **actual SVG response body** (or asserts fill/`<style>` self-containment)
so scannability is covered. Re-submit for a fresh pre-merge verification. **Not merged, not deployed, nothing printed.**

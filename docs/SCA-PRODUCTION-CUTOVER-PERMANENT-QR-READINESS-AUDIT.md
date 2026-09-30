# SCA-PRODUCTION-CUTOVER — Permanent QR Readiness Audit (READ-ONLY)

**Date:** 2026-09-30
**Deployed baseline:** `bd9e3cd`; canonical app identity `https://verify.secondchanceauthenticators.com` (Phase A done).
**No production mutation — reads only.** Path from the existing permanent host-independent QR **tokens** to
production-safe printable/scannable **artifacts**.

## 1. Token immutability + host-independence — reconfirmed; NO regeneration

`sca_qr_identifiers`: `public_token char(32) UNIQUE`, `is_production tinyint(1) default 0`, `created_at`, **no
`updated_at`**. The token is a 32-hex opaque value (`Token::opaque()`) — it contains **no host/URL/port**. Immutability
triggers are active and fire on the whole row:
- `trg_sca_qr_identifiers_no_update` (BEFORE UPDATE → `SIGNAL SQLSTATE '45000' 'SCA: qr identity is immutable'`)
- `trg_sca_qr_identifiers_no_delete` (DELETE → `SIGNAL … 'SCA: qr identity cannot be deleted'`)

Host-independence proven: the **same** token resolves on **both** `https://verify.…/p/{token}`→**200** and the pilot
`http://195.26.255.80:8080/p/{token}`→**200** (bogus→404). **The hostname change requires NO token regeneration and
none is permitted** — only the *encoded URL host* changes (to `verify.`); the token is unchanged and permanent.

## 2. `is_production` — reconfirmed as a governance/"safe-to-print" marker only (no behavioral/security effect)

Written once in `QrService::createIdentity($itemId, $isProduction = false)` (default `false`); **read by no
application code** — the only `is_production` grep hit is `ProductionHardeningTest::h5`, which is about the
**app-debug dev-tool gate** (`RealHttpErrorStatus` / `/_ignition` / `/_debugbar`), *not* the QR column. The passport
resolver, presenter, routing, and certification logic never consult it. ⇒ it is **purely a marker** ("staging token,
not yet approved for permanent printing"); it gates nothing at runtime.

## 3. The two pilot rows — safest treatment (do not modify)

| qr_id | item | active for item? | public_token | is_production | created | passport |
|---|---|---|---|---|---|---|
| 1 | item 1 (`SCA-3C35D669ACBE`) | yes (`active_qr_identifier_id=1`) | `bee93d2bd7933ba643a872c6bf79ac33` | 0 | 2026-09-15 | `/p/…`→200 |
| 2 | item 3 (`SCA-F1B792AE4745`) | yes (`active_qr_identifier_id=2`) | `10c739b71d861a1021215ed936205a01` | 0 | 2026-09-24 | `/p/…`→200 |

Both tokens are permanent, immutable, host-independent, each the item's **current active** QR, and both resolve today
to the correct certified passport. They were never physically distributed.

**Safest treatment = ADOPT the existing tokens for production** (print `https://verify.…/p/{token}` for these two
items). **Do NOT issue new QR rows.** A `QrService` reissue would create a new identity **and revoke the current
active QR**, so the old token would then resolve to a constant-shape 404 — churn with no benefit, since the pilot
tokens are unprinted and already correct. The `is_production=0` marker does not prevent this (read by nothing); see §8
for the flag itself.

## 4. Exact URL a physical QR must encode — proven

**`https://verify.secondchanceauthenticators.com/p/{public_token}`** — nothing else. Proven on the deployed runtime:
`route('sca.passport.show', ['token' => <token>])` and `url('/p/'.<token>)` both return
`https://verify.secondchanceauthenticators.com/p/{token}` (Phase A `APP_URL` makes this correct even in CLI/out-of-request
contexts); `/p/{valid}`→200, `/p/{bogus}`→404. The token is host-independent, but the printed URL bakes in the
**permanent** host `verify.…` (never the pilot IP/`:8080`).

## 5. Does a QR artifact generator exist? — NO. Smallest implementation (recommendation, NOT implemented)

No QR-image/artifact generator, route, or view exists (the admin item view explicitly states the QR image/URL is
"DEVELOPMENT/NON-PERMANENT and deferred"). **No QR library is installed** — only `barryvdh/laravel-dompdf` +
`dompdf/dompdf` + `mpdf/mpdf` (for the certificate PDF, which uses dompdf and embeds **no** QR).

**Smallest safe implementation (a future governed code task — do NOT build here):**
- Add a maintained pure-PHP QR library — recommend **`endroid/qr-code`** (SVG + PNG, selectable ECC level,
  configurable margin/quiet zone; SVG needs no GD) — or `bacon/bacon-qr-code`.
- Add **one** admin route/controller under the **existing `sca.eyewear` ACL** (mirroring the existing POST QR-lookup),
  e.g. `GET /admin/.../eyewear/{item}/qr.{svg|png|pdf}`, that: resolves the item's **active** QR `public_token`
  (read-only via `ProjectionService`), builds `route('sca.passport.show', $token)`, and returns the QR artifact. A
  print-ready PDF may reuse the existing dompdf pipeline (embed the QR SVG/PNG data-URI + the human-readable ref).
- **Zero identity impact:** the generator only *reads* `public_token`; it performs no DB write, no token creation, no
  `is_production` change, no reissue. QR identity, certification state, and provenance are untouched.

## 6. Artifact requirements (physical eyewear/authentication tag)

- **Payload:** exactly `https://verify.secondchanceauthenticators.com/p/{public_token}` — no other data encoded.
- **Error correction:** **ECC level H (≈30 %)** — maximum robustness for a small, curved, wear-prone eyewear tag.
- **Formats:** **SVG** primary (vector, sharp at any print size); **PNG** at high DPI (≥600 DPI at the physical size)
  for raster; **PDF** (print-ready tag embedding the SVG/PNG + human-readable ref) optional.
- **Quiet zone:** ≥ **4 modules** margin (QR spec minimum).
- **Minimum module size:** physically ≥ ~0.4–0.5 mm per module for reliable scanning on a small tag (a print-spec
  constraint to validate during the pilot print).
- **Human-readable reference (use existing public identifiers only):** the **`certification_number`**
  (`SCA-CERT-2026-…`) and/or item **`public_ref`** (`SCA-…`) — both already public and printed on the certificate PDF.
- **Safeguards (must be enforced in the generator):** encode/print **only** the public passport URL + a public
  human-readable ref; **never** embed or print the item id, certification id, collector id, certificate token, reset/
  claim/transfer/grant tokens, Shopify ids, or any internal id. The QR `public_token` is the intended public
  identifier (public by design, in the scannable URL); do not additionally print it as separate human-readable text.

## 7. Scanning enters only the SCA-038 resolver — reconfirmed (Option-A + constant-shape)

The QR URL `/p/{token}` routes to `PassportController::show` → `PassportResolver::resolve` (strict 32-hex format gate
**before** any DB access; token must be the item's **active** QR; inactive/stale/revoked/unknown/malformed → `null`).
`null` → one **constant-shape 404** (`passport.not_found`, explicit `Response`, not `abort()`); resolved → a 200 that
renders **only the allowlisted DTO** — never the raw model, the resolving token, owner/staff/contact data, or any
internal id (`PublicPassportHeaders` are applied to both 200 and 404). Verified live: `verify.…/p/{valid}`→200 with
**no** token/internal-id leak in the body; `/p/{bogus}`→404. Scanning a production artifact therefore enters exactly
this read-only public surface and preserves Option-A privacy + constant-shape failure.

## 8. Changing `is_production` on the two immutable rows — technically possible? NO (governance consequence)

`trg_sca_qr_identifiers_no_update` fires **BEFORE UPDATE** and unconditionally `SIGNAL`s SQLSTATE 45000, so
`UPDATE sca_qr_identifiers SET is_production = 1 …` is **blocked** — the flag is immutable in place (the whole row is
immutable by design). **Do not bypass the trigger.** Consequences:
- **Recommended (governance decision):** treat `is_production=0` on the two pilot rows as a **historical marker** and
  print the existing tokens anyway. `is_production` gates nothing (read by no code), the tokens are permanent/working,
  and re-printing them changes no data. The design intent ("only print `is_production=1`") is an advisory that the
  immutability model makes unenforceable in place — so it becomes a **governance sign-off**, not a DB state, for these
  two rows.
- **Alternative (only if governance requires an `is_production=1` row):** issue a **new** QR via `QrService` reissue
  (a governed staff action) — which mints a fresh `is_production=true` identity and **revokes** the current active QR
  (old token → 404). This is a behavioral change and yields a new token to print; justified only to retire an already
  distributed pilot token (not the case here). No schema/trigger change; no in-place flip.

## 9. Safe pilot-print procedure (for the future implementation)

1. Generate the artifact for **one** pilot item's active token via the (to-be-built) generator — encoding
   `https://verify.…/p/{token}`, ECC=H, quiet zone ≥4, human-readable `certification_number`/`public_ref`, no internal
   ids.
2. From an **external device** (phone) over **real public DNS + TLS**, scan the artifact → confirm it opens
   `https://verify.…/p/{token}` with a **publicly-trusted** cert → the **correct** passport (right item, Option-A, no
   leak).
3. Scan/enter a **bogus or altered** token → confirm **constant-shape 404** (no passport, no existence leak).
4. Confirm the printed human-readable ref matches and **no internal id/token** is printed.
5. Only then authorize **physical attachment** — one item first, verified end-to-end, before any batch.

## 10. Before/after (this audit)

`bd9e3cd`, tree CLEAN; `.env` = Phase A (`APP_URL=https://verify.…`, `SCA_PUBLIC_PREVIEW=0`); Caddyfile `0faece7a`;
migrations=118, qr=2, certs=3; QR fp `6bb119ee0b598222bfec58bb80c7a4cb`; both QR rows unchanged. **No QR row/token/
`is_production`/schema/trigger change; no generator built; no artifact printed; nothing attached.**

## Summary / recommendation

Ready to proceed to a **narrowly-scoped generator implementation** (endroid/qr-code + one ACL-gated read-only admin
route producing SVG/PNG/PDF of `https://verify.…/p/{active_token}`, ECC=H, no internal-id leakage), followed by the §9
pilot-print procedure. For the two existing pilot items, **adopt their current tokens** (do not reissue); the
`is_production` flag is immutable and behaviorally inert, so its value for those rows is a **governance sign-off**, not
a technical blocker. `SCA-PRODUCTION-CUTOVER` remains OPEN. Planning only — nothing implemented.

# NEXT TASK

**STATUS: PRE-MERGE VERIFICATION FAILED (2026-09-30) — NO-GO, returned to author. NOT merged/deployed.**
`SCA-PRODUCTION-CUTOVER — Permanent QR Artifact Generator`.

**Verdict:** candidate `c7eb163` FAILS one gate — **DEFECT-003**: the generated SVG uses
`svgUseFillAttributes=false` with no `<style>`/fill attributes, so as delivered (attachment, no external CSS) every
layer renders black → a solid black square → **not scannable** (proven by decoding the actual artifact:
default-CSS render → `could not find enough finder patterns`; correct-CSS render + PNG cross-check → exact canonical
URL). All other gates PASS (git identity, scope, GET-only `sca.eyewear.view` route, active-identity binding, exact
payload, ECC H + quiet zone 4, fail-safe behavior, privacy, `public_ref` filename safety, composer/prod deps, SCA-038
200/404, zero mutation, pilot clean on `bd9e3cd`). **Fix:** `svgUseFillAttributes => true` + a test that
rasterizes/decodes the actual SVG body. Full report: `docs/SCA-PERMANENT-QR-ARTIFACT-PREMERGE-VERIFICATION.md`.
Candidate never deployed; production untouched. **→ Author remediates and re-submits for fresh verification.**

---

_(Original task contract, retained for the re-submission:)_

Promoted 2026-09-30 by ChatGPT. Implements the accepted Permanent QR Readiness Audit
(`docs/SCA-PRODUCTION-CUTOVER-PERMANENT-QR-READINESS-AUDIT.md`). Base = deployed `bd9e3cd`. **PUSH ONLY — no
merge/deploy, no printing/attaching, no other cutover phase.**

## Implementation submitted (2026-09-30) — NOT merged, NOT deployed

- **Impl repo:** `francisjonee/francisjonee-sca-platform-private`, branch **`sca-qr-artifact-generator`**, commit
  **`c7eb163`** (base `bd9e3cd`). Task report: `app/docs/task-reports/SCA-PERMANENT-QR-ARTIFACT.md`.
- **What:** read-only `GET admin/sca/eyewear/{id}/qr` (`admin.sca.eyewear.qr`, existing `sca.eyewear.view` ACL,
  same `{id}` identity as item detail) → downloadable **SVG** QR of the item's **existing active** QR identity.
  Dependency added: **`chillerlan/php-qrcode ^6.0`** (+ `php-settings-container`), verified PHP 8.3 / Laravel 12.
- **Payload** = exactly `https://verify.secondchanceauthenticators.com/p/{public_token}` from
  `config('app.url')` + the `sca.passport.show` route path (no hard-coded host, no `PUBLIC_QR_BASE_URL`); scan enters
  the existing SCA-038 resolver only. Active identity only ⇒ revoked/inactive/absent never printable; fail-safe 404
  creates nothing; raw token only inside the QR modules (never route/filename/headers/logs/flash/body).
  ECC **H**, quiet zone **4** modules. **Zero domain mutation**; `is_production` untouched.
- **Tests:** `tests/Feature/Sca/QrArtifactTest.php` (10) prove every required invariant incl. byte-identical SVG +
  PNG decode round-trip == exact canonical URL. Focused 10/38; **full `tests/Feature/Sca` 651 passed / 3503**.
- **Live preview:** restored to deployed main `bd9e3cd` (vendor `--no-dev`, chillerlan absent, no `/qr` route live);
  pilot `:8080` + public `verify.` edge both serve passports 200 / bogus 404. Nothing merged/deployed/printed.

**→ Awaiting independent pre-merge review. Do not merge, deploy, print/attach, or start another task.**

## Objective

Smallest **read-only** staff/admin capability to generate a **printable QR artifact** for an eyewear item's **existing
active** QR identity — adopting the existing tokens, never regenerating.

## Hard invariants

- Never create/regenerate/rotate/revoke/replace/update/delete a QR identity; never modify `is_production`; never bypass
  the `no_update`/`no_delete` triggers. **Zero domain mutation.**
- **QR payload = exactly `https://verify.secondchanceauthenticators.com/p/{public_token}`**, derived through the app's
  established production URL config (`config('app.url')` + the `sca.passport.show` route path) — **no** new hard-coded
  hostname, **no** reviving the inert `PUBLIC_QR_BASE_URL`.
- Scanning must enter the **existing SCA-038 `/p/{token}` resolver** — no alternate public resolution path.

## Access / security

- Staff-only under the **existing `sca.eyewear` ACL**; operates on the item's **existing active** QR.
- Do **not** expose the raw token in staff HTML, query strings, logs, flash, filenames, or error responses.
- Missing / no-active-QR → **fail safe** (no identity creation).

## Artifact

- Maintained QR library compatible with PHP 8.3 / Laravel 12 — **verify the dependency before selecting it.**
- **SVG** primary (unless constraints show better); **ECC H**; **quiet zone ≥ 4 modules**.
- Encode **only** the passport URL — no internal item/cert/collector/ownership/staff id, no second token.
- If a human-readable ref is shown, use only an already-public identifier (`certification_number` / `public_ref`),
  **outside** the QR payload.

## Tests must prove

Active QR → artifact generated; **decoded payload == exactly** `https://verify.…/p/{existing-token}`; zero DB/domain
mutation; QR identity fingerprint unchanged; `is_production` unchanged; no QR identity created when absent;
revoked/inactive QR cannot become the printable identity; ACL enforcement; no PII/internal-id/other-token leak in the
artifact or response; SCA-038 valid→200 / bogus→constant-shape 404 unchanged; full `tests/Feature/Sca` green.

**Push only; STOP for pre-merge review. Do not merge/deploy, print/attach, activate SMTP, change DNS/Caddy/.env, set
`SESSION_SECURE_COOKIE=true`, retire `:8080`, or start another phase.**

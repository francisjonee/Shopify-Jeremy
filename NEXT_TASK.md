# NEXT TASK

**STATUS: ACTIVE — `SCA-PRODUCTION-CUTOVER — Permanent QR Artifact Generator` (PUSH ONLY).**

Promoted 2026-09-30 by ChatGPT. Implements the accepted Permanent QR Readiness Audit
(`docs/SCA-PRODUCTION-CUTOVER-PERMANENT-QR-READINESS-AUDIT.md`). Base = deployed `bd9e3cd`. **PUSH ONLY — no
merge/deploy, no printing/attaching, no other cutover phase.**

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

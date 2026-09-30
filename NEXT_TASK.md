# NEXT TASK

**STATUS: NONE — ACTIVE = NONE.** `SCA-PRODUCTION-CUTOVER — Permanent QR Artifact Generator` is **DONE**
(merged `--no-ff` + deployed `5e02f3e`, 2026-09-30). No task is promoted; do not start one without authorization.

**`SCA-PRODUCTION-CUTOVER — Permanent QR Artifact Generator` — DONE (merged `--no-ff` + deployed `5e02f3e`).**
Base `bd9e3cd`, reviewed candidate `ddfe424` (chain `c7eb163`→`ddfe424`), MERGE_SHA=ORIGIN_MAIN=DEPLOYED_HEAD=
`5e02f3e8b9b780306b8e11fb13d30247d134ff81`. Deploy gate 651/3504; `Nothing to migrate` (schema unchanged, 118); `--no-dev`
(chillerlan 6.0.1 prod dep present, dev pruned). Deployed-artifact proof: the real deployed SVG for existing active item 1
independently rasterized+decoded → exactly `https://verify.secondchanceauthenticators.com/p/bee93d2bd7933ba643a872c6bf79ac33`;
self-contained (`#000`/`#fff` fills, no `<style>`), ECC H + 4-module quiet zone, filename `sca-qr-SCA-3C35D669ACBE.svg`
(public_ref only), no token in body/headers/filename. SCA-038 200/404; new `/qr` route 403 from non-staff IP (default-deny
intact); sca_edge auto-attached on recreate, MariaDB private; verify.+smsrocket+:8080 healthy; Caddyfile `0faece7a`,
DOCKER-USER 5 rules; **zero QR/domain mutation** (fp `a920dc1c…`, is_production 0,0, counts/projection unchanged). Deploy
note: first gate run aborted on root-owned `storage/` dirs from the verifier's earlier root test runs — fixed by
`chown -R 33:33 storage bootstrap/cache` and re-run (production untouched during the abort). Report:
`docs/SCA-PERMANENT-QR-ARTIFACT-DEPLOY-RESULT.md`. **No QR printed/attached; returned for review.**

**Explicitly NOT done / still deferred:** physical QR printing/attachment, QR regeneration/reissue, is_production
mutation, SMTP activation, :8080 retirement, `SESSION_SECURE_COOKIE` Phase B, further DNS/Caddy. SCA-PRODUCTION-CUTOVER
remains OPEN.

---

_(Task contract + verification history for this task, retained below.)_

Independent re-verification of corrected candidate `ddfe424` (base `bd9e3cd`) — **every gate holds**. Only production
diff from the superseded `c7eb163` is `svgUseFillAttributes false→true`. DEFECT-003 fixed and proven by decoding the
**actual HTTP SVG response body** → exactly `https://verify.secondchanceauthenticators.com/p/{active_token}`;
self-contained (`#000`/`#fff` fills, no `<style>`); ECC H + 4-module quiet zone; discriminator (strengthened regression
FAILS on `c7eb163`, PASSES on `ddfe424`); revoked/missing/unauthorized fail closed with no mutation; privacy intact;
focused 10/39 + full `tests/Feature/Sca` 651/3504; `php -l` clean; `composer check-platform-reqs --no-dev` all success;
SCA-038 200/404 live; zero prod mutation (fp `a920dc1c…`); pilot restored to `bd9e3cd`, generator+dependency absent from
runtime. Full report: `docs/SCA-PERMANENT-QR-ARTIFACT-PREMERGE-VERIFICATION.md`.
**→ Cleared for merge + governed deploy under separate authorization. No further code change required. Do not
merge/deploy/print or start another task without authorization.**

---

_(Verification history for this candidate, retained:)_

**Corrected HEAD `ddfe424`** (on top of `c7eb163`, base `bd9e3cd`, history preserved; branch `sca-qr-artifact-generator`).
One-line production fix `svgUseFillAttributes => true` in `EyewearItemController::qr()` → the downloaded SVG now carries
explicit `#000`/`#fff` fills and is self-contained/scannable with no external CSS. The regression was strengthened:
`QrArtifactTest::decodeSvgArtifact()` independently rasterizes + decodes the **actual HTTP SVG response body** (no longer
a byte-compare to a same-options SVG); `rg2` requires the decode to equal exactly
`https://verify.secondchanceauthenticators.com/p/{active_token}`, `rg6` proves only the active token is encoded.
**Discriminator:** `rg2`+`rg6` FAIL on `c7eb163` (`DECODE_FAILED: could not find enough finder patterns`), PASS on
`ddfe424`. Focused 10/39; full `tests/Feature/Sca` **651/3504**; `php -l` clean. All prior invariants preserved
(SVG/ECC H/≥4 quiet zone, active-QR-only, GET-only `sca.eyewear.view`, fail-safe 404, `public_ref`-only filename, no
plaintext token, is_production untouched, SCA-038 unchanged). Zero prod mutation (fp `a920dc1c…`, counts unchanged);
pilot restored to `bd9e3cd`, candidate absent from runtime. Report:
`app/docs/task-reports/SCA-PERMANENT-QR-ARTIFACT.md`; verification doc: `docs/SCA-PERMANENT-QR-ARTIFACT-PREMERGE-VERIFICATION.md`.
**→ Awaiting fresh pre-merge audit of `ddfe424`. Do not merge/deploy/print or start another task.**

---

_(Earlier verdict on the superseded HEAD, retained:)_

**PRE-MERGE VERIFICATION FAILED (2026-09-30) — NO-GO on `c7eb163`.**

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

# SCA-PERMANENT-QR-PHYSICAL-PILOT — item 1 / SCA-3C35D669ACBE

**Date:** 2026-09-30 · **Status:** ⏳ **IN PROGRESS — print-ready artifact produced & validated; NOT DONE.**
Physical printing/attachment is performed by a human; the pilot is **not PASS** until the actual printed QR is scanned
from a normal phone and confirmed to open the correct passport. Read-only throughout; **zero mutation**.

Scope: exactly ONE existing item — **item 1 / `SCA-3C35D669ACBE`**, using its existing immutable active QR identity.
Item 3 was **not** touched. `is_production` left `0` (immutable; not altered).

## Procedure evidence

1. **Deployed baseline:** `DEPLOYED_HEAD == ORIGIN_MAIN == 5e02f3e8b9b780306b8e11fb13d30247d134ff81`; QR generator route
   `GET admin/sca/eyewear/{id}/qr` (`admin.sca.eyewear.qr`) live.
2. **Item 1 identity (unchanged):** active_qr_identifier_id=`1`, public_token=`bee93d2bd7933ba643a872c6bf79ac33`,
   public_ref=`SCA-3C35D669ACBE`, is_production=`0`.
3. **Before-state snapshot:** QR fp `a920dc1c40e1120606dde94f012286e0`; counts qr=2/life=2/certs=3/certev=4/auth=3/own=4;
   migrations=118; tokens `bee93d2b…`,`10c739b7…`; is_production `0,0`; projection `1:1,3:2`.
4. **Artifact obtained from the deployed generator** for item 1 (read-only; deployed controller invoked for reads
   only — no create/reissue/rotate/revoke/update): HTTP 200, `Content-Type: image/svg+xml; charset=utf-8`,
   `Content-Disposition: attachment; filename="sca-qr-SCA-3C35D669ACBE.svg"`, 58 422 bytes.
5. **Independent decode of the DOWNLOADED SVG file** (verifier-owned isolated chillerlan+GD harness, rasterized as a
   standalone renderer would): decodes to **exactly** `https://verify.secondchanceauthenticators.com/p/bee93d2bd7933ba643a872c6bf79ac33`.
   Self-contained (16 explicit fills `#000`/`#fff`, no `<style>`); viewBox 57 = 49-module symbol + 2×4-module quiet
   zone; token not present as plaintext in body/headers/filename (no `[0-9a-f]{16,}` run in body).
6. **Public destination:** `https://verify.…/p/bee93d2b…` → HTTP 200 over trusted HTTPS (`ssl_verify_result=0`), a
   valid item-1 passport (distinct from item 3's). SCA-038 intact: bogus-32 → 404, malformed → 404.
7. **Print-ready artifact (item 1 only):** `sca-qr-SCA-3C35D669ACBE-print.html` embeds the **exact** `<svg>` element
   **byte-identical** to the delivered artifact (verified by diff) — the QR is **not** re-encoded/redrawn. The
   human-readable ref `SCA-3C35D669ACBE` is placed outside the QR; the baked quiet zone is preserved plus extra margin.

## Non-mutation evidence (after-state == before-state)

QR fp `a920dc1c40e1120606dde94f012286e0` (unchanged); counts qr=2/life=2/certs=3/certev=4/auth=3/own=4; migrations=118;
tokens unchanged; is_production `0,0`; projection `1:1,3:2`. Deployed `5e02f3e`, verify. 200, :8080 200. No QR identity
created/reissued/rotated/revoked/updated; no immutability trigger bypass; no certification/authentication/ownership/
provenance change; no is_production change. Item 3 not prepared/printed. No SMTP / :8080 / SESSION_SECURE_COOKIE / DNS /
Caddy / code changes.

## Deliverables (handed to the operator)

- `/opt/SCA/pilot-artifacts/sca-qr-SCA-3C35D669ACBE.svg` — the exact QR artifact (vector).
- `/opt/SCA/pilot-artifacts/sca-qr-SCA-3C35D669ACBE-print.html` — print-ready page embedding that exact vector at
  30 mm with quiet-zone/sizing/contrast instructions.

## Remaining (human action, then confirm here)

Print the tag at 100% (no shrink), ≥25 mm, quiet zone preserved, black-on-white matte; scan the **physical** print from
a normal phone/mobile connection → must open the correct item-1 passport. **Pilot marked DONE only after the operator
confirms that real scan.** No printing/attachment is claimed here.

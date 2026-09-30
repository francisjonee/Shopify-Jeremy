# SCA-PERMANENT-QR-ARTIFACT — Merge + Governed Production Deploy Result

**Date:** 2026-09-30 · **Status:** ✅ **DONE — merged `--no-ff` + deployed.** Authorized after PASS/GO pre-merge
re-verification of `ddfe424` (gov `88c1135`). No QR printed/attached.

## SHAs

- **Base/deployed-from:** `bd9e3cdd914b6ac657ad54939f9c692e13463006`
- **Reviewed candidate (feature HEAD):** `ddfe424fd8513c32887d1f5db3e1f6d6b4cdf416` (chain `c7eb163`→`ddfe424`, preserved)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `5e02f3e8b9b780306b8e11fb13d30247d134ff81`** (`--no-ff` merge of
  `sca-qr-artifact-generator` into `main`).

## Pre-merge gates (fail-closed) — all PASS

origin/main==base; local+origin feature==`ddfe424`; merge-base==base; 2-commit chain intact (`c7eb163`,`ddfe424`);
reviewed 7-file scope; clean tree.

## Deploy

Ran `scripts/deploy-preview.sh` from `main`.

- **Deploy gotcha encountered + resolved (environmental, not the candidate):** the first run aborted at the mandatory
  test gate (35 failed / 616 passed) — `UnexpectedValueException: FilesystemIterator … storage/framework/testing/disks/
  local/sca: Permission denied`. Root cause: `storage/` held **root-owned** dirs/files left by the verifier's earlier
  test runs (executed as root via `docker compose exec app`), which the uid-33 test gate could not read. The deploy
  `set -e`-aborted **before** migrate/build/recreate, so production was untouched (verified: migrations=118, fp
  unchanged, kr-app not recreated, verify.+:8080 200). Fixed by `chown -R 33:33 storage bootstrap/cache` (+ removing the
  stale root-owned `storage/framework/testing/disks`) and re-running the governed deploy unchanged.
- **Successful run:** test gate **651 passed / 3504 assertions**; `Nothing to migrate` (schema unchanged, migrations
  **118**); image `sca-app:krayin-2.2.6` rebuilt; `composer install --no-dev --optimize-autoloader`; `config:clear` +
  `route:clear`; health `GET /admin/login → 200`; `Deployed main @ 5e02f3e`.
- **Post-deploy pilot bind:** kr-app recreated on the committed loopback bind, then the pilot public bind
  `195.26.255.80:8080` was re-applied from `git stash@{0}` (`docker compose up -d app`) and the tree restored
  (`git checkout -- docker-compose.yml`). **sca_edge auto-attached on recreate** (kr-app → `sca_internal 172.19.0.3` +
  `sca_edge 172.20.0.3`) with no manual `docker network connect`; MariaDB stays `sca_internal`-only, no host port.

## Production gates — all PASS

| Gate | Result |
|---|---|
| DEPLOYED_HEAD == ORIGIN_MAIN == MERGE_SHA | ✅ `5e02f3e` |
| Full `tests/Feature/Sca` gate (incl. QR `rg1–rg10`) | ✅ 651 / 3504 |
| Migrations / schema | ✅ `Nothing to migrate`; migrations 118 (no schema change) |
| Composer production install (`--no-dev`) | ✅ chillerlan 6.0.1 present (prod dep), phpunit/dev pruned |
| `/qr` route live on deployed code | ✅ `GET admin/sca/eyewear/{id}/qr` → `admin.sca.eyewear.qr` |
| **Deployed artifact decode (existing active item 1)** | ✅ real deployed SVG independently rasterized+decoded → **exactly** `https://verify.secondchanceauthenticators.com/p/bee93d2bd7933ba643a872c6bf79ac33` |
| Self-contained artifact | ✅ 16 `fill=` (`#000`/`#fff`), no `<style>`; viewBox 57 = 49 symbol + 2×4 quiet zone; ECC H |
| Privacy | ✅ token not in body/headers/filename; filename `sca-qr-SCA-3C35D669ACBE.svg` (public_ref only); no hex run in body |
| SCA-038 | ✅ verify. `/p/{valid}`→200, bogus-32→404, malformed→404 |
| Security boundaries / default-deny | ✅ `/admin`→403 and new `/admin/sca/eyewear/1/qr`→403 from non-staff IP; `/collector/login`→200; `/`→404 |
| sca_edge persistence + MariaDB private | ✅ auto-attached on recreate; MariaDB `sca_internal`-only, 3306 unpublished |
| verify. + smsrocket + :8080 health | ✅ verify. 200/404, smsrocket 302, :8080 200; kr-app + kr-mariadb healthy |
| Caddyfile / DOCKER-USER unchanged | ✅ Caddyfile `0faece7a…`; DOCKER-USER 5 rules |
| **Zero QR/domain mutation** | ✅ QR fp `a920dc1c40e1120606dde94f012286e0`, tokens `bee93d2b…`/`10c739b7…`, is_production `0,0`, projection `1:1,3:2`, counts qr=2/life=2/certs=3/certev=4/auth=3/own=4 — all unchanged from pre-merge baseline |

The verification was read-only (deployed controller invoked for reads only; no QR created/rotated/revoked/updated).

## NOT done (unchanged scope)

No physical QR printed/attached; no QR regeneration/reissue; is_production untouched; no SMTP; :8080 not retired; no
`SESSION_SECURE_COOKIE` Phase B; no DNS/Caddy change. **Even on PASS: no QR printed/attached — returned for review.**

**Outcome: SCA-PERMANENT-QR-ARTIFACT is DONE (merged `--no-ff` + deployed, `5e02f3e`).**

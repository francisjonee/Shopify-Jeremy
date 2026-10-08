# SCA Collector Profile — CP-5 — Phase B (`/u/*` edge admission) — activation result

**Date:** 2026-10-09 · **Status: ✅ DONE — EDGE-ONLY change. `/u/*` admitted through the existing SCA public edge to `kr-app:80`; external `/u/*` now reaches Laravel (Apache 404) while unrelated unknown paths remain Caddy 404. One-line Caddy matcher delta; only the Caddy container recreated. No application/schema/DNS/Shopify/Stripe/SMTP change. Provenance byte-identical. CP-5 NOT declared closed — STOP for ChatGPT final CP-5 audit.** Authorized after ChatGPT CP-5 Phase-A post-deployment audit **PASS**.

## 1. Scope
Admit the already-deployed `/u/*` namespace (CP-5 Phase A, migration 134, app baseline `0101755`) through the existing `verify.secondchanceauthenticators.com` public edge to the SAME `kr-app:80` upstream used by `/c/*`. The ONLY change is adding `/u/*` to the existing `@public path` matcher. No application code, DB/schema, DNS, Shopify, Stripe, or SMTP change.

## 2. Preflight — all PASS (no drift)
- implementation origin/main == deployed head == `0101755b03352305050b7b7290ad917b588112ff`; migration **134**.
- Live Caddyfile matcher (before): `@public path /p/* /collector /collector/* /c/*` → `handle @public { reverse_proxy kr-app:80 }` (same upstream).
- Backup: `/opt/smsrocket-stack/Caddyfile.bak.pre-cp5-u-edge.20261008T232601Z`.
- External BEFORE (server header): `/u/ada`, `/u/ada/avatar`, `/u/ada/items/SCA-AB12CD34EF56/image` → **404 Caddy**; `/c/PUB-…`(bogus) → **404 Apache**; `/p/…`(bogus) → **404 Apache**; `/collector/login` → **200 Apache**; `/admin/login` → **403 Caddy**; `/totally-unknown-xyz` → **404 Caddy**; external `:8080` → refused; co-tenant `smsrocket.io` → 302.
- Provenance row-data FP `d15a5cbdfb8df52ba65628b276533cfe`; canonical counts `3/3/4/4/5/2/1/1/7`; collectors 3 / private 0 / public-profile 0 / public-item 0 / handle-bearing 0 / tombstone 0.

## 3. Caddy matcher delta (exact)
| | matcher |
|---|---|
| BEFORE (line 19) | `@public path /p/* /collector /collector/* /c/*` |
| AFTER (line 19) | `@public path /p/* /collector /collector/* /c/* /u/*` |

`diff backup → edited` = exactly one changed line (the `/u/*` addition). No other matcher/route/upstream/TLS/header change.

## 4. Validate before activation
`docker run --rm -v /opt/smsrocket-stack/Caddyfile:/etc/caddy/Caddyfile:ro caddy:2 caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile` → **"Valid configuration"** (validated in a throwaway container, no effect on the running edge).

## 5. Activation — Caddy only
`cd /opt/smsrocket-stack && docker compose up -d --force-recreate --no-deps caddy` (ordinary reload is ineffective on the read-only single-file bind mount — established force-recreate procedure). Only the `caddy` service (container `sr-caddy`) was recreated. **kr-app (Up 7 days) and kr-mariadb (Up 3 weeks) were NOT recreated/restarted.**

## 6. External verification — AFTER (server header; syntactically valid bogus values; no fixtures created)
| Request | Result |
|---|---|
| `GET /u/ada` | **404 Apache/2.4.68** — reaches kr-app/Laravel; no `Location` (no redirect) |
| `GET /u/ada/avatar` | **404 Apache/2.4.68**, no redirect |
| `GET /u/ada/items/SCA-AB12CD34EF56/image` | **404 Apache/2.4.68**, no redirect |
| `/u/ada` 404 body | the shared `public.not_found` view, **byte-identical to the `/c/PUB-…` 404 body**; no PUB/COL ref, no internal id, no collector-specific path (`title: Not found`). The only `/storage` token is Krayin's generic favicon path `/storage/configuration/…` (app chrome), present identically on the already-live `/c` 404 page — not an identity leak. |
| `/c/PUB-…`(bogus) | **404 Apache** (unchanged) |
| `/p/…`(bogus) | **404 Apache** (unchanged, identity-free) |
| `/collector/login` | **200 Apache** (unchanged) |
| `/admin/login` | **403 Caddy** (staff-IP restriction unchanged) |
| `/totally-unknown-xyz` (unrelated unknown) | **404 Caddy** (edge catch-all unchanged) |
| external `:8080` | refused/000 (loopback-only, unchanged) |
| co-tenant `smsrocket.io` | **302** (healthy, unchanged) |

BEFORE→AFTER for `/u/*`: **Caddy 404 → Apache/Laravel 404** (edge now admits `/u/*` to kr-app). All other origins unchanged.

## 7. Invariants — all PASS
| Check | Result |
|---|---|
| implementation origin/main == deployed | `0101755b03352305050b7b7290ad917b588112ff` (unchanged) |
| migration | **134** (unchanged) |
| provenance row-data FP (documented procedure) | `d15a5cbdfb8df52ba65628b276533cfe` (unchanged) |
| canonical counts items/qr/certs/auth/ownership/claims/grants/sale/status | `3/3/4/4/5/2/1/1/7` (unchanged) |
| collectors / private / public-profile / public-item / handle-bearing / tombstone | 3 / 0 / 0 / 0 / 0 / 0 |
| `STRIPE_ENABLED` / secret | unset (dormant) |
| `MAIL_MAILER` | log |
| app code / DB schema / DNS / Shopify / SMTP | unchanged |
| Caddy delta | exactly `/u/*` added to `@public` matcher |
| containers recreated | only `caddy` (sr-caddy); kr-app + kr-mariadb untouched |

**Outcome: DONE — `/u/*` edge admission live; external `/u/*` reaches Laravel (Apache 404) with no redirect and no identity leak; unrelated paths remain Caddy 404; provenance byte-identical; only the Caddy matcher changed and only the Caddy container was recreated; app/schema/DNS/Shopify/Stripe/SMTP unchanged.** The CP-5 handle feature is now end-to-end reachable at the edge, but DORMANT (0 handles). **STOP for ChatGPT final CP-5 audit. CP-5 NOT declared closed. CP-6 NOT started.**

## 8. Rollback (if ever needed)
Restore `/opt/smsrocket-stack/Caddyfile` from `Caddyfile.bak.pre-cp5-u-edge.20261008T232601Z` and `docker compose up -d --force-recreate --no-deps caddy`; `/u/*` reverts to Caddy 404 (the app routes remain, harmlessly edge-blocked).

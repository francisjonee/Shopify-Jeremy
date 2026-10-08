# SCA Collector Profile — CP-3 — Phase B (production-edge activation of `/c/*`) — result

**Date:** 2026-10-08 · **Status: ✅ Phase B DONE — edge-only Caddy change admitting `/c/*` to kr-app. External `/c/*` now reaches the CP-3 application 404 (proven by origin headers). NO application/schema/DNS/Stripe/SMTP/Shopify change. Co-tenants healthy. Rollback not used (backup retained). CP-3 NOT declared closed — STOP for ChatGPT final post-edge audit.** Authorized after ChatGPT CP-3 Phase-A post-deploy **PASS** (gov `1c79b81`).

## Baseline (unchanged by this edge-only change)
- Implementation deployed `main` = `3e707582c21e40b97e909c8593987787fd4c33c4` (unchanged pre/post).
- Production migrations **132** (unchanged). `sca_collector_public_profiles` exists, **0 rows** (pre and post).
- Provenance DATA fingerprint `35e063282e004eaabcc9240360ecc0e3` byte-identical pre/post. Collector accounts 3 / private profiles 0 / publication rows 0 (unchanged).
- Stripe `enabled=false`/secret UNSET; `MAIL_MAILER=log` (unchanged). DNS unchanged.

## 1. Preflight — PASS
impl `origin/main == deployed head == 3e70758`; prod migration 132; publication table present, 0 rows; provenance FP `35e06328…`; Stripe dormant; mail log. Pre-change external edge: `/c/PUB-<32hex>` and `/c/PUB-<32hex>/avatar` → 404 served by the **edge catch-all** (`server: Caddy`, plain "Not found", no app markers); `/p/bogustoken` → 404 (app); `/collector/profile` → 302; `/admin/login` → 403. Internal loopback (kr-app direct) `/c/PUB-<32hex>` → 404 rendering the CP-3 "Profile not found" view. Active Caddy site block admitting public SCA routes identified: `verify.secondchanceauthenticators.com` → `@public path /p/* /collector /collector/*` → `handle @public { reverse_proxy kr-app:80 }`.

## 2. Backup + diff
- **Backup (host):** `/opt/smsrocket-stack/Caddyfile.bak.pre-cp3-edge.20261008T191946Z` (timestamped copy of the active config; retained; no secrets).
- **Exact sanitized routing diff** (the entire change — one line in the `verify.secondchanceauthenticators.com` site's `@public` matcher):
```diff
 verify.secondchanceauthenticators.com {
 	# Public SCA surfaces.
-	@public path /p/* /collector /collector/*
+	@public path /p/* /collector /collector/* /c/*
 	handle @public {
 		reverse_proxy kr-app:80
 	}
```
`/c/*` is sent to the SAME `kr-app:80` upstream as `/p/*` and `/collector/*`. No broadening to a generic catch-all; `@admin` IP restriction, `@shopify_*` matchers, the `handle { respond "Not found" 404 }` catch-all, TLS, headers, and the `smsrocket.io` / `mail3.relaytask.online` site blocks are untouched.

## 3. Validate — PASS
Candidate config validated in a throwaway `caddy:2` container: `caddy validate --adapter caddyfile --config <candidate>` → **"Valid configuration"**.

## 4. Activation
The host Caddyfile mount is single-file read-only; per the documented host behaviour a `caddy reload` does not reliably apply a single-file change (it re-adapted the file — the running config's `@public` JSON showed `/c/*` present — but the running server continued serving `/c/*` via the old routing). The **established safe procedure** was therefore used: `docker compose up -d --force-recreate caddy` (recreates ONLY the `caddy`/`sr-caddy` edge container; a brief edge blip for all sites it fronts). **No unrelated application/database service was restarted** (see §6). Rollback (restore the backup + re-recreate) was kept immediately available and was **not needed**.

## 5. External smoke — PASS (no production fixture created)
Origin was distinguished by response headers + body marker (external `/c/*` returns 404 **both** before and after — the real signal is the *origin*: edge catch-all = `server: Caddy`, plain body; CP-3 app = `server: Apache` + Laravel `sca_session` cookie + the `noindex` "Profile not found" HTML view).

| Request | status | origin | marker |
|---|---|---|---|
| `GET /c/PUB-<32hex>` | 404 | **server: Apache** (kr-app), via Caddy | CP-3 "Profile not found" view |
| `GET /c/PUB-<32hex>/avatar` | 404 | **server: Apache** (kr-app) | app avatar 404 (empty body) |
| `GET /unrelated-xyz` (catch-all) | 404 | **server: Caddy** | edge "Not found" (unchanged) |
| `GET /p/bogustoken` (Passport) | 404 | server: Apache (kr-app) | unchanged, identity-free |

The external `/c/*` 404 is now the CP-3 **application** 404 (Apache/Laravel), matching the internal loopback CP-3 view (`<title>Not found</title>` + `Profile not found`), and is distinct from the still-Caddy edge catch-all — proving Caddy forwards `/c/*` to kr-app rather than serving its old catch-all. No internal path/upstream info leaks. Per the gate, no real published collector was created to obtain a 200 (the 200 lifecycle is already proven by the app tests on this identical deployed tree).

### Regression smoke — PASS
`/p/*` Passport unchanged (app-served, identity-free); unauthenticated `/collector/profile` + `/collector/collection` → 302 (collector-auth); `/admin/login` → 403 (edge staff-IP restriction unchanged); unrelated `/unrelated-xyz` → edge catch-all 404 (Caddy, unchanged); `/sca/shopify/webhook` GET → 404 (unchanged); co-tenants `smsrocket.io` → 302 and `mail3.relaytask.online` → 302 (healthy); direct external `:8080` → 000 (loopback-only, unchanged).

## 6. Post-change invariants — PASS
| Check | Result |
|---|---|
| impl deployed head / main | `3e70758` (unchanged) |
| prod migration | **132** (unchanged) |
| publication row count | **0** (unchanged by edge activation) |
| provenance DATA fingerprint | `35e063282e004eaabcc9240360ecc0e3` (byte-identical) |
| items/qr/certs/auth/ownership/claims/grants/sale/status | 3/3/4/4/5/2/1/1/7 (unchanged) |
| collector accounts / private profiles / publication rows | 3 / 0 / 0 (unchanged) |
| containers restarted | **only `sr-caddy`** (Up 2 min); `kr-app` Up 6 days, `kr-mariadb` Up 3 weeks, `sr-mariadb` Up 5 weeks — NOT restarted; no app/container rebuild/redeploy |
| active Caddyfile vs backup | diff = **exactly the one `/c/*` line** |
| `STRIPE_ENABLED` / secret | false / UNSET |
| `MAIL_MAILER` | log |
| DNS / TLS policy | unchanged (Caddy auto-LE for `verify`, untouched) |
| rollback | not used; backup retained |

**Outcome: Phase B DONE — edge admits `/c/*` to kr-app via a single `@public` matcher line; external `/c/*` now reaches the CP-3 application; catch-all, admin, Passport, collector, co-tenant, and `:8080` behaviour all unchanged; app/schema/data/DNS/Stripe/SMTP/Shopify untouched; only the `caddy` edge container was recreated.** **STOP for ChatGPT final CP-3 post-edge audit. CP-3 is NOT declared closed here. CP-4 NOT started.**

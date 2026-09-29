# SCA-PRODUCTION-CUTOVER — Phase 2C (Public DNS + Trusted TLS) — RESULT: **BLOCKED / NOT STARTED**

**Date:** 2026-09-29
**Application baseline:** `c568331` (unchanged). **No changes were made in this task — reads only.**

## Why blocked (STOP at the pre-change revalidation gate)

Phase 2C step 1 assumes pointing `secondchanceauthenticators.com` apex + `www` at `195.26.255.80`. Revalidation of
current public DNS shows the domain **is a LIVE Shopify storefront**, not an unused/parked name:

- **apex** `secondchanceauthenticators.com` → **`23.227.38.32`** (Shopify; PTR `myshopify.com`), **not** `195.26.255.80`.
- **www** → `shops.myshopify.com` / `23.227.38.74` (Shopify), 301→apex.
- Live check (real public DNS, read-only): `https://secondchanceauthenticators.com/` → **HTTP/2 200, `powered-by: Shopify`**,
  Cloudflare, Shopify storefront assets (store image dated 2026-01-22). It is in active commercial use.

This is a **material difference from the plan's assumption**, so per the directive ("if the state differs
materially, STOP") the task stops before any change. Concretely:

1. **DNS is at an external registrar** — there is no registrar access from this host, so the A records cannot be
   created/repointed here.
2. **Repointing the apex would take the live Shopify store offline** — a destructive, customer-facing change that
   requires explicit human authorization and is almost certainly the wrong design.
3. **Public ACME was NOT attempted.** Because the hostname resolves to Shopify, a Let's Encrypt challenge for
   `secondchanceauthenticators.com` would be served by Shopify, not sr-caddy → issuance would fail, and repeated
   attempts risk LE rate limits. `tls internal` was therefore left untouched.

## No changes made — Phase 2B edge remains LIVE and healthy

Verified after the DNS finding (all unchanged from the 2B PASS state):
- Caddyfile `sha256 00f16788…`, SCA vhost still `tls internal`; smsrocket block byte-for-byte intact; smsrocket.io HTTPS **200**.
- `sca_edge` 172.20.0.0/24 (sr-caddy 172.20.0.2 + kr-app 172.20.0.3); `.env` `TRUSTED_PROXIES=172.20.0.0/24`;
  `APP_URL` unchanged (`http://195.26.255.80:8080`).
- SCA vhost SNI-reachable (`/p/{valid}`→200 via `--resolve -k`); `:8080` pilot `/up`→200; DOCKER-USER unchanged;
  MariaDB private; SCA counts + QR identity fp `6bb119ee…` unchanged.

## Recommended path (requires human decision — NOT implemented)

The apex is the company's live Shopify store, so the SCA registry should almost certainly live on a **dedicated
subdomain**, leaving the storefront in place. Proposed:

1. **Human/registrar action:** create an A record for a subdomain — e.g. `verify.` / `registry.` / `app.secondchanceauthenticators.com`
   → `195.26.255.80` (low TTL). Do NOT touch the apex/www Shopify records.
2. **Then a revised Phase 2C:** change the SCA Caddy vhost hostname from the apex to the chosen subdomain, switch that
   vhost to public automatic TLS (Let's Encrypt), and re-run the 2C gates (public trusted cert, internet-facing route
   checks, proxy/security hard gate) against the subdomain. `TRUSTED_PROXIES`, sca_edge, admin allowlist, default-deny,
   `:8080` fallback all carry over unchanged.
3. Application canonical-URL/permanence config (`APP_URL`, `PUBLIC_QR_BASE_URL`, `SESSION_SECURE_COOKIE`,
   `SCA_PUBLIC_PREVIEW`) remains a **separate later gate** after public HTTPS on the subdomain is healthy — and the
   permanent QR destination URL should be decided against that subdomain.

Related: the domain being a live Shopify store also bears on `SHOPIFY-CONNECT-009` (deferred).

## Status

`SCA-PRODUCTION-CUTOVER` remains **OPEN**. Phase 2C **BLOCKED** pending a human DNS decision (subdomain vs. apex).
No rollback was needed (nothing changed). Do NOT proceed to public DNS/TLS or application URL config without that
decision. **ACTIVE = NONE, NEXT_TASK = NONE.**

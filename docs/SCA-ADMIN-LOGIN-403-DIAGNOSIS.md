# SCA — Admin `/admin/login` 403 Forbidden: Diagnosis (READ-ONLY)

**Scope: read-only investigation. No firewall/auth/config/permission/code/service change; no security protection disabled.** 2026-10-27. **Root cause: the sr-caddy edge intentionally restricts `/admin*` to two authorized staff source IPs (default-deny by design) — the external browser's IP is not on that allowlist, so Caddy returns 403. This is working as designed, not a defect.**

## [1][2] Public (edge) vs internal (kr-app) — the 403 is at Caddy

| Request | Result |
|---|---|
| `GET https://verify.secondchanceauthenticators.com/admin/login` (through sr-caddy) | **HTTP/2 403**, `server: Caddy`, `content-type: text/plain`, body `Forbidden` (9 bytes) |
| `GET http://127.0.0.1:8080/admin/login` (direct kr-app, bypasses edge) | **200 OK**, `Server: Apache/2.4.68`, full Krayin "Sign In" page + session cookies |

The 403 is a **Caddy-generated** response (plain text "Forbidden", `server: Caddy`) — Apache/Laravel never see the request. Internally the login page renders normally (200). So the block is purely at the **edge (sr-caddy)**, not Apache, not Laravel/Krayin, not an app ACL.

## [3] Routing rule (from the live Caddyfile `verify.…` block; IPs redacted)

```
@admin path /admin /admin/*
handle @admin {
    @staff remote_ip <two authorized staff IPs — redacted>
    handle @staff { reverse_proxy kr-app:80 }
    respond "Forbidden" 403        # any non-staff source IP → 403
}
```
The site is **default-deny**: only `@public` (`/p/*`, `/collector*`, `/c/*`, `/u/*`), the Shopify webhook (`POST /sca/shopify/webhook`), and the OAuth callback (`GET /sca/shopify/oauth/callback`) are internet-facing; **`/admin*` is limited to two authorized staff IPs**; everything else → 404. The comment block states this explicitly ("`/admin` is limited to the two authorized staff IPs").

## [4] External vs internal traffic

Yes — treated differently **by source IP at the edge**. Caddy sees the real client IP. Requests to `/admin*` from the two allowlisted staff IPs are reverse-proxied to `kr-app`; all other IPs get the edge `respond "Forbidden" 403` before reaching the app. Internal loopback (`127.0.0.1:8080`) and internal health checks bypass Caddy entirely and hit Apache directly, so they see 200. The owner's external browser is on an IP **not** in the two-staff allowlist → 403.

## [5] Effect on the Shopify connection route

- `GET /admin/sca/shopify/connect` (the OAuth initiator) is **under `/admin`** → **403 at the edge** for non-staff IPs (confirmed: public → 403, loopback → 302). So the OAuth flow **cannot be started** from a non-staff IP — this is exactly what blocks the owner.
- `GET /sca/shopify/oauth/callback` (the return leg) is **explicitly allowed for any IP** (path- and method-exact) → confirmed reachable (400 fail-closed on a bare request). The callback is **not** affected; only *initiating* `/connect` is.
- Because the CSRF `state` is stored in the session set during `/connect` and validated on the callback (same `verify.…` domain → same session cookie), the person who opens `/connect` must also complete the Shopify approval in that same browser session.

## [6] Root cause & smallest safe correction

**Root cause:** the edge `@admin` matcher denies `/admin*` to any source IP outside the two authorized staff IPs (intended default-deny security). The owner is browsing from an IP that is not on that allowlist (e.g., a different network, or a staff IP that has since changed). Nothing is broken; the protection is doing its job.

**Smallest safe correction — do NOT weaken the allowlist. In order of preference:**
1. **No change — access `/admin` from an authorized staff IP.** Have an SCA staff member on one of the two allowlisted networks open `https://verify.secondchanceauthenticators.com/admin/login` and then `…/admin/sca/shopify/connect`. From there the connect redirects to Shopify; the **store administrator authenticates and approves on Shopify's own domain** within that same browser session (Shopify is not IP-restricted); the public `/sca/shopify/oauth/callback` completes the flow. This resolves both the login 403 and the OAuth blocker with **zero config change**.
2. **If the operator's current IP must be allowed** (e.g., a staff IP changed): add that **specific** IP to the existing two-IP `remote_ip` allowlist in `/opt/smsrocket-stack/Caddyfile` (scoped, reversible), then reload the edge. ⚠️ Per the host runbook the Caddyfile is a single-file bind mount — a plain `caddy reload` reports "config unchanged"; it requires `docker compose up -d --force-recreate sr-caddy`, which **briefly drops smsrocket.io**, so do it at a quiet hour. This is an **owner-authorized edge-config change**, out of scope for this read-only task.
3. **Do NOT** broaden `@staff` to `0.0.0.0/0` or remove the `@admin` restriction — that would expose the admin login/console to the public internet (a security regression) and is explicitly not recommended.

**Verification aid (owner):** compare the operator's current public IP to the two values in the `@staff remote_ip` line; if it drifted, option 1 (use a staff IP) or option 2 (add the new IP) applies.

**STOP — read-only diagnosis delivered. No firewall/auth/config/permission/code/service change made; no protection disabled. Recommended fix: initiate from an authorized staff IP (no change), or owner-scoped-add the operator IP to the Caddy allowlist + force-recreate sr-caddy at a quiet hour.**

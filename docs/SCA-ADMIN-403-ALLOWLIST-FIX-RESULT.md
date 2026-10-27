# SCA — Restore Admin Access: Caddy Allowlist Change RESULT

**Authorized minimal change executed successfully.** The owner's verified IP `103.200.35.3/32` was added to the Caddy `@staff` admin allowlist via an inode-preserving in-place edit + graceful reload — no container recreate, no service restart, smsrocket uninterrupted, both existing staff IPs preserved, admin still default-deny (not opened to all). 2026-10-27. **STOP.**

## Steps 1–7 (executed)

1. **IP validated:** `103.200.35.3` is a valid **public IPv4** (not private/loopback/reserved/link-local/multicast).
2. **Both existing staff IPs preserved:** pre-change `@staff remote_ip` held **2** IP tokens; post-change holds **3** (append-only; the two existing kept verbatim, values not reproduced — security-sensitive). Cross-checked against the backup: both existing addresses are still present in the live running config.
3. **Added as exact `/32`:** appended ` 103.200.35.3/32` to the single `@staff remote_ip` line.
4. **Backup:** `/opt/smsrocket-stack/Caddyfile.bak.20261027T172637Z` (mode-preserving copy) before any edit.
5. **Validated before applying:** the edited copy passed `caddy validate --adapter caddyfile` → `Valid configuration` (live file untouched until this passed).
6. **In-place edit, inode preserved:** wrote via `cat new > Caddyfile` (not `sed -i`/`mv`); **inode `777641` unchanged** before and after, so the file bind mount into `sr-caddy` is intact and the container sees the new bytes.
7. **Graceful reload, no recreate:** `docker exec sr-caddy caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile` → `using config from file` / `adapted config to JSON`, returned OK. The container was **not** recreated (same `StartedAt 2026-10-18T21:54:33Z`).

## Steps 8–10 (verified)

- **[8] Caddy healthy:** `sr-caddy running=true`, admin API `GET /config/ → 200`, not recreated.
- **[10] Admin route permitted for the owner IP:** the **live running config** (admin API) contains `103.200.35.3/32`; the `@staff` matcher now holds the 2 existing + owner = **3** source IPs (the only other IPv4 in the full config JSON is the admin endpoint `127.0.0.1`). The allowlist is intact — a request from this host (a non-staff IP) to `/admin/login` still returns **403**, confirming admin was **not** opened publicly, and the running config contains **no `0.0.0.0/0`**.
- **[9] smsrocket.io accessible:** `https://smsrocket.io/ → 302` (normal; healthy, not an error). The verify.* public passport `/p/{token} → 200` (unaffected).

## Safety outcome

- Allowlist **not** disabled; both existing authorized IPs **retained**; admin portal **not** exposed publicly (non-staff still 403, no `0.0.0.0/0`).
- No container restart/recreate; smsrocket and the SCA public surfaces were not interrupted (graceful reload).
- Rollback available instantly if ever needed: `cat /opt/smsrocket-stack/Caddyfile.bak.20261027T172637Z > /opt/smsrocket-stack/Caddyfile && docker exec sr-caddy caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile` (inode-preserving).
- No Shopify setting changed.

## Next (owner)

The owner can now reach `https://verify.secondchanceauthenticators.com/admin/login` from `103.200.35.3`. This unblocks **OAuth Step 1** — the scope change is already live (`SHOPIFY_SCOPES=read_orders,read_products`); opening `https://verify.secondchanceauthenticators.com/admin/sca/shopify/connect` from the now-allowlisted IP starts the Shopify approval, after which the stored token should carry `read_products` (then verify scope + a read-only product probe; no import).

**STOP — admin access restored for 103.200.35.3; allowlist default-deny preserved; smsrocket + public surfaces healthy; no recreate/restart; no Shopify change.**

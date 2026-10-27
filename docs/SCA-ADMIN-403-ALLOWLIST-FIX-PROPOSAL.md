# SCA — Add Owner IP to Caddy `/admin` Allowlist: Change Proposal (READ-ONLY)

**Scope: proposal only. No configuration changed, no container recreated, no service restarted/reloaded. The IP allowlist is NOT disabled and admin is NOT opened to all IPs.** 2026-10-27. **STOP for owner approval.**

## [1] Owner's current public IP — secure, owner-controlled capture (NOT guessed)

The edge access log yielded **no** `/admin` 403 line in the recent window (the deny handler doesn't log a harvestable client IP here), so the owner's IP must be obtained by the owner, from the exact device/network they use to reach the admin site:

- Owner runs, from that network: `curl -s https://api.ipify.org` (or opens `https://whatismyipaddress.com`). The value returned is their **egress public IP**.
- Provide that single IP for approval. Do **not** send a password or any secret — only the public IP.
- (Caveat: if the owner is behind a VPN/corporate NAT or a dynamic-IP ISP, the egress IP may differ per session or rotate; see risk [7].)

I did not and will not guess the IP.

## [2] Comparison with existing authorized IPs

The live `@staff remote_ip` line currently allowlists the **two** authorized staff IPs (values intentionally not reproduced here — security-sensitive). On approval, the owner's verified IP will be checked to confirm it is (a) a valid single address, (b) **not already** one of the two, and (c) added as an exact host address (recommend `/32`, not a broad CIDR).

## [3][4] Smallest safe change — append only; both existing IPs preserved

In `/opt/smsrocket-stack/Caddyfile`, the single line inside `verify.secondchanceauthenticators.com { handle @admin { … } }`:

```
-		@staff remote_ip <IP_A> <IP_B>
+		@staff remote_ip <IP_A> <IP_B> <OWNER_VERIFIED_IP>
```

- One token appended; `<IP_A>` and `<IP_B>` (the two existing staff IPs) are kept verbatim. Nothing else in the file changes. The allowlist remains a default-deny allowlist — it is **not** disabled and **not** widened to `0.0.0.0/0`.

## [5] Reload without recreate — YES, zero-downtime is possible here

- The Caddy **admin API is enabled** (no `admin off`; `GET http://localhost:2019/config/` → 200, listening on `127.0.0.1:2019`), so `caddy reload` performs a **graceful, atomic config reload with zero downtime** across all sites — **smsrocket.io is not interrupted** and the container is **not recreated**.
- The CLAUDE.md "must force-recreate" gotcha applies **only** when the edit **replaces the file's inode** (e.g. `sed -i`, an editor's save, or `mv`): the container's file bind mount (`/opt/smsrocket-stack/Caddyfile` → `/etc/caddy/Caddyfile`, inode `777641`) then keeps reading the old inode, so `caddy reload` sees "config unchanged."
- **Avoided by editing in place (inode-preserving):** write the new content over the existing file with shell truncation (`cat new > Caddyfile`) or `cp new Caddyfile` — both keep inode `777641`, so the container immediately sees the new bytes and `caddy reload` picks them up. **Do NOT use `sed -i`, an editor rename, or `mv`.**

## [6] Validate before applying

`caddy validate` is available and works (validated the current config → `Valid configuration`). The edited copy must be validated **before** it is written live.

## [7] Exact apply procedure (owner-authorized; NOT run here) + risk

```bash
OWNER_IP="<OWNER_VERIFIED_IP>"          # from step 1, approved
CF=/opt/smsrocket-stack/Caddyfile
cp -p "$CF" "$CF.bak.$(date -u +%Y%m%dT%H%M%SZ)"          # backup (rollback)
# Build the edited copy by appending ONLY the owner IP to the @staff remote_ip line:
awk -v ip="$OWNER_IP" '/@staff remote_ip/ && $0 !~ ip {print $0" "ip; next} {print}' "$CF" > /tmp/Caddyfile.new
# [6] validate the EDITED copy inside the caddy container before going live:
docker cp /tmp/Caddyfile.new sr-caddy:/tmp/Caddyfile.new
docker exec sr-caddy caddy validate --config /tmp/Caddyfile.new --adapter caddyfile   # expect: Valid configuration
# Apply IN PLACE (preserve inode 777641 — NOT sed -i / mv):
cat /tmp/Caddyfile.new > "$CF"
# Zero-downtime graceful reload (no recreate, smsrocket unaffected):
docker exec sr-caddy caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
# Verify (from the owner's network): /admin/login -> 200; and smsrocket still 200:
#   curl -o /dev/null -w '%{http_code}\n' https://verify.secondchanceauthenticators.com/admin/login
#   curl -o /dev/null -w '%{http_code}\n' https://smsrocket.io/
```

**Service-impact risk:**
- **smsrocket.io:** none expected — `caddy reload` is graceful and atomic; it does not restart the process or drop connections, and the container is not recreated.
- **Config safety:** `caddy validate` gates a syntax error before it goes live; even if a bad config were applied, `caddy reload` rejects an invalid config and keeps the running one. A timestamped backup enables instant rollback (`cat backup > Caddyfile && caddy reload`).
- **Inode caveat (the one real foot-gun):** the edit MUST be in place (`cat >`/`cp`), never `sed -i`/`mv`; otherwise `caddy reload` won't see it and you'd be tempted into the disruptive force-recreate. Procedure above uses `cat >`.
- **Residual (owner awareness):** if the owner's IP is dynamic/VPN/NAT, it may change and need re-adding; consider adding the owner's stable office/VPN egress IP rather than a transient residential IP. Still a `/32` exact host — never a broad range.
- **Fallback only if reload ever reports "unchanged":** `docker compose up -d --force-recreate sr-caddy` (briefly drops smsrocket.io — quiet hour). Not expected with the in-place edit.

**STOP — proposal only. Provide the owner's verified public IP for approval; nothing has been changed, reloaded, recreated, or restarted. The allowlist stays default-deny (both existing IPs preserved; admin not opened to all).**

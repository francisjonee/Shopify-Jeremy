# NEXT TASK

**STATUS:** NONE — no executable task is currently authorized. **ACTIVE = NONE, NEXT_TASK = NONE.**

## Latest: SCA-PRODUCTION-CUTOVER — EDGE PERSISTENCE HARDENING — **DONE (merged + deployed)** 2026-09-30

Merged `--no-ff` (reviewed commit preserved) + deployed to production `main`. **A real governed container recreation
proved automatic `sca_edge` reattachment with NO `docker network connect`** — persistence is now established, so the
prior "reconnect kr-app to `sca_edge` after every deploy" operational step is **no longer required**.

- **Base:** `4095ad506e01458b5131523d4b0b9ca49ed97ac5`
- **Feature:** `97e3d693eda876e4053b84d64d2b09d1121e6563` (branch `sca-edge-persistence`, 1 commit)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `bd9e3cdd914b6ac657ad54939f9c692e13463006`**

`docker-compose.yml`: `app` service `networks: [internal, sca_edge]` + top-level `sca_edge: {external: true}` (literal
existing 172.20.0.0/24 network). `mariadb` unchanged (`internal`-only); no static IP.

**Deploy + decisive persistence proof:** deploy gate focused (implicit) + full `tests/Feature/Sca` **641/3462**;
`migrate → Nothing to migrate` (118); `DEPLOYED_HEAD==ORIGIN_MAIN==MERGE_SHA`. The governed `deploy-preview.sh`
recreated kr-app (log: "Recreated") and Compose **auto-attached** it to `sca_internal`(172.19.0.3) + **`sca_edge`
(172.20.0.3, inside /24)** — no manual connect. Re-establishing the `:8080` public bind recreated kr-app a second time
and it **again** auto-attached `sca_edge` (172.20.0.3).

**All gates:** isolation — kr-mariadb `sca_internal`-only + no host port, sr-caddy on `sca_edge`+smsrocket,
Caddy→kr-app:80 OK. Trusted-proxy runtime — `TRUSTED_PROXIES=172.20.0.0/24` (not broadened); real Caddy peer
`172.20.0.2` → proto/host/client-IP honored, `172.19.x`+public rejected. Functional edge — SCA SNI `/p/valid`→200,
bogus→404 (SCA-038, 2863 B), `/collector/login`→200, `/admin`→403, installer/`/sca/*`/`/up`/root→404; smsrocket.io
healthy (`/`→302→`/admin/login`→200; sr-caddy/sr-app untouched). `:8080` fallback `/up`,`/admin/login`,
`/collector/login`→200, DOCKER-USER byte-identical (2 staff IPs + DROP). Non-mutation — migrations=118, qr=2, certs=3,
QR fp `6bb119ee0b598222bfec58bb80c7a4cb`; MariaDB private. Restoration — clean deployed main `bd9e3cd`, `--no-dev`
(phpunit pruned), no config cache, no probe artifacts, kr-app healthy + dual-homed.

## Authorization state

`SCA-PRODUCTION-CUTOVER` remains **OPEN**; **Phase 2C blocked on client DNS access** (GoDaddy `verify` A record). No
queued item promoted. **SCA-054 must not start.** Nothing is active.

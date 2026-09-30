# NEXT TASK

**STATUS: `SCA-PRODUCTION-CUTOVER — EDGE PERSISTENCE HARDENING` — IMPLEMENTED + PUSHED (push-only). Awaiting ChatGPT
pre-merge audit. NOT merged, NOT deployed; production containers NOT recreated.**

Cutover infrastructure hardening (not SCA-054). Base/deployed `4095ad5`. Feature branch `sca-edge-persistence` on
`github-sca-platform` — **fix `97e3d693eda876e4053b84d64d2b09d1121e6563`**. Implements the audit
`docs/SCA-PRODUCTION-CUTOVER-EDGE-PERSISTENCE-AUDIT.md`.

## What was implemented (push only)

`docker-compose.yml` (impl repo root), **two hunks only** (scope = exactly 1 file):
- `app` service: `networks: [internal]` → `networks: [internal, sca_edge]`.
- top-level: added `sca_edge: {external: true}`.

`mariadb` unchanged (`networks: [internal]` only). **No static IP.** No ports/env/Caddy/deploy-script/application/.env
change. `deploy-preview.sh` untouched (inspection found no material contradiction — it does no docker-network ops).

## Candidate verification (rendered `docker compose config`, read-only; production NOT recreated)

- `docker compose config` **VALID**.
- Rendered `app.networks` = **exactly** `['internal', 'sca_edge']`; `app` has **no** `ipv4_address` (no static IP);
  ports unchanged (`127.0.0.1:8080→80`); no `env_file`/`environment` added.
- Rendered `mariadb.networks` = `['internal']` only; no static IP.
- Top-level `sca_edge` = `{name: sca_edge, external: True}` → resolves to the **literal existing** external network
  `sca_edge`; `internal` → `sca_internal`.
- Changed-file scope = **only `docker-compose.yml`** (no `deploy-preview.sh`, no `app/` code).

## Restoration evidence (pilot exactly as found — no recreate)

Working tree restored to `main 4095ad5` (committed compose has no `sca_edge`; the change lives only on the branch).
Live containers untouched: kr-app on `sca_edge`(172.20.0.3)+`sca_internal`(172.19.0.3), kr-mariadb `sca_internal`-only,
sr-caddy `sca_edge`(172.20.0.2)+smsrocket; kr-app healthy on `195.26.255.80:8080`; Caddy→kr-app:80 OK; SCA SNI `/p`→200,
`/admin`→403; smsrocket 200; `:8080` 200; DOCKER-USER 6; Caddyfile `00f16788`; production counts qr=2/certs=3/
migrations=118; QR fp `6bb119ee0b598222bfec58bb80c7a4cb`.

**PUSH ONLY — stopped for ChatGPT audit; no merge, no deploy, no recreate, no Phase 2C.** The actual recreate/
persistence test (§10 of the audit) belongs to the governed merge/deploy phase. `SCA-PRODUCTION-CUTOVER` remains OPEN;
Phase 2C blocked on client DNS. SCA-054 must not start.

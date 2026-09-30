# NEXT TASK

**STATUS: ACTIVE — `SCA-PRODUCTION-CUTOVER — EDGE PERSISTENCE HARDENING` (PUSH ONLY).**

Promoted 2026-09-30 by ChatGPT. Cutover **infrastructure** hardening (not SCA-054 product development).
Base/deployed `4095ad506e01458b5131523d4b0b9ca49ed97ac5`. Implements only the recommendation in
`docs/SCA-PRODUCTION-CUTOVER-EDGE-PERSISTENCE-AUDIT.md`. **PUSH ONLY — do NOT merge, deploy, recreate production
containers, or execute Phase 2C.**

## Executable contract

1. **Edit only `/opt/sca-platform/docker-compose.yml`** (repo root of the impl repo), preserving its existing
   structure/format:
   - Add `sca_edge` to the **`app` service** networks: `networks: [internal, sca_edge]`.
   - Add a top-level external network declaration `sca_edge: {external: true}` (resolves to the literal existing
     `sca_edge`, 172.20.0.0/24).
   - **`mariadb` stays `networks: [internal]` only.** **No static IP** on any service.
2. **Do NOT modify `deploy-preview.sh`** unless inspection reveals a material contradiction with the accepted audit —
   if so, **STOP** and report rather than expand scope.
3. **Change nothing else:** Caddy/Caddyfile, `TRUSTED_PROXIES`, `.env`, DNS, ACME/TLS, `APP_URL`,
   `PUBLIC_QR_BASE_URL`, `SESSION_SECURE_COOKIE`, `SCA_PUBLIC_PREVIEW`, SMTP, application code, DB/schema/migrations,
   QR identities/`is_production`, provenance/domain data, DOCKER-USER/firewall, the published `:8080` fallback, or
   smsrocket configuration.

## Candidate verification (before returning; do NOT recreate production containers)

- Validate Compose syntax (`docker compose config`); inspect the rendered config.
- Prove the rendered `app` service has **exactly** `internal` + external `sca_edge`.
- Prove the rendered `mariadb` remains `internal`-only.
- Prove `sca_edge` resolves to the **literal** existing external network `sca_edge`.
- Prove no static IP was introduced; no port/environment/Caddy/deploy-script/application change.
- Inspect changed-file scope = exactly `docker-compose.yml` (+ this task's governance/report docs, which live in the
  governance repo, not the impl branch).

## Restoration + evidence

Feature branch from the exact baseline; minimal change; **push only**. Restore the pilot exactly as found and verify
the live manually-connected edge remains healthy: kr-app on `sca_internal`+`sca_edge`, kr-mariadb `sca_internal`-only,
Caddy→kr-app:80, SCA pre-DNS SNI path, smsrocket, `:8080` fallback, DOCKER-USER unchanged, production counts/QR fp
unchanged. Return the feature SHA, exact diff/scope, rendered-Compose evidence, and restoration evidence. **STOP — no
merge/deploy, no Phase 2C.** The actual recreate/persistence test belongs to the governed merge/deploy phase after
audit.

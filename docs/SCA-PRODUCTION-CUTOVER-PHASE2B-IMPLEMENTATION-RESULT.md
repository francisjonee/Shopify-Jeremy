# SCA-PRODUCTION-CUTOVER — Phase 2B Edge/Caddy Pre-DNS Implementation — RESULT: **FAIL (hard gate) + ROLLED BACK**

**Date:** 2026-09-29
**Deployed app baseline:** `d089e7a` (Phase 2A) — **unchanged**; no deploy, no code change, no schema change performed.
**Accepted architecture:** Phase 2B planning report (governance `8703fe6`, `docs/SCA-PRODUCTION-CUTOVER-PHASE2B-EDGE-PLAN.md`).
**Outcome:** the reversible pre-DNS edge path was built and validated, but a **hard verification gate failed** for a
reason that cannot be fixed within Phase 2B's scope (a code defect in the deployed Phase 2A). Per the directive
("if the pin cannot be made effective, report FAIL/rollback rather than claim success"), all Phase 2B mutations were
**rolled back to the audited baseline** and the production co-tenant (smsrocket.io) was preserved.

---

## What was built and validated before the gate failed

- **`sca_edge = 172.20.0.0/24`** created (non-overlapping with 172.17 bridge / 172.18 smsrocket / 172.19 sca_internal);
  connected **only** sr-caddy + kr-app. kr-mariadb stayed `sca_internal`-only (sr-caddy never reached MariaDB).
- **`.env` `TRUSTED_PROXIES=172.20.0.0/24`** appended (0600 www-data; no other key changed).
- **Caddy SCA site** appended with `tls internal` (no public ACME): apex + `www→apex` redirect; default-deny;
  `/p/*` + `/collector/*` → kr-app; `/admin*` limited to `103.225.137.242` / `103.200.35.2`; everything else 404.
  `caddy validate` = **Valid configuration**.
- **sr-caddy `--force-recreate`** in the authorized window; smsrocket.io stayed healthy (http 308 → https 200).
- Pre-DNS `curl --resolve … -k` checks of the edge path returned the expected surfaces; the `:8080` pilot fallback and
  `DOCKER-USER` IP-lock remained operational; zero provenance mutation throughout.

---

## The hard gate that failed (directive §2 / §7)

**Requirement:** the running application must see **exactly** the pinned value `172.20.0.0/24` and **no longer rely on the
transitional RFC1918 default**; `:8080`-path traffic must not be able to manufacture trusted forwarded semantics
"now that TRUSTED_PROXIES is pinned exclusively to 172.20.0.0/24."

**Observed (live spoof discrimination, reproducible):** the *effective* trusted-proxy set at runtime is the **RFC1918
default**, **not** the `/24` pin:

| Ingress (REMOTE_ADDR) | X-Forwarded-Proto/Host honored? | Correct under `/24` pin? | Matches RFC1918 default? |
|---|---|---|---|
| sca_internal peer `172.19.0.4` | **HONORED** | ✗ (should be rejected) | ✓ (`172.16.0.0/12`) |
| sca_edge peer `172.20.0.4` | HONORED | ✓ | ✓ |
| real Caddy edge `172.20.0.3` | HONORED | ✓ | ✓ |
| real `:8080` host `195.26.255.80` (public) | REJECTED | ✓ | ✓ |

The `172.19.x` peer being honored is only possible under the RFC1918 default; a true `/24` pin would reject it.
A container `restart` and a full recreate did **not** change this.

---

## Root cause — a **code defect in deployed Phase 2A (`d089e7a`)**, not a Phase 2B/config issue

`bootstrap/app.php` computes `trustProxies(at: env('TRUSTED_PROXIES', '<RFC1918 default>'))` **inside the
`withMiddleware()` closure**. That closure runs at HTTP-kernel **resolution** (an `afterResolving(Kernel::class)` hook),
which fires **before** `$kernel->handle()` runs the `LoadEnvironmentVariables` bootstrapper. At that moment
`env('TRUSTED_PROXIES')` is **NULL**, so the code falls back to the hardcoded RFC1918 default. The `.env` value only
becomes readable *after* bootstrap — too late for the middleware.

**Proof (web SAPI `apache2handler`, via a throwaway probe on the IP-locked `:8080`, deleted immediately):**

```
PRE-bootstrap  env(TRUSTED_PROXIES)=NULL
AT-kernel-make env(TRUSTED_PROXIES)=NULL   <-- when the trustProxies closure actually reads it
POST-bootstrap env(TRUSTED_PROXIES)='172.20.0.0/24'  (too late for the middleware)
```

**Consequence:** the `.env` `TRUSTED_PROXIES` pin is **inert at runtime**. No container restart/recreate and no Caddy/
network change can make it effective — it requires a **code change**, which is outside Phase 2B's scope. (The same
timing bug would also defeat `config:cache`.)

This is recorded as **DEFECT-002** in `docs/PENDING-DEFECTS.md`.

> **Security note:** this is *not a regression* introduced by this task. `d089e7a` already behaves this way; the Phase 2A
> statement that "Phase 2B pins the Caddy edge CIDR" is simply **not yet effective**. Live exposure is unchanged: the only
> HTTP clients that can reach `kr-app:80` are sr-caddy (intended) and internal non-HTTP containers; the real `:8080`
> ingress (public REMOTE_ADDR) is correctly rejected. But the intended "pinned exclusively to the /24 edge" hardening is
> **absent**, so the gate cannot pass on `d089e7a`.

---

## Rollback to audited baseline (production co-tenant preserved)

- **Caddyfile** restored to baseline `sha256 171f29c16644bfabadbea9ea6289df90a099de9a89596e36ff83b3b4a0714fd7`
  (0 SCA refs; `caddy validate` = Valid).
- **`/opt/smsrocket-stack/docker-compose.yml`** reverted (caddy `networks: [internal]`; external `sca_edge` block removed).
- **sr-caddy `--force-recreate`** → smsrocket.io **recovered** (http 308 → https 200); sr-caddy nets = `smsrocket-stack_internal` only.
- **SCA vhost removed:** `https` with `SNI=secondchanceauthenticators.com` → `000` (TLS rejected; no longer internet-reachable).
- **`app/.env`:** `TRUSTED_PROXIES` line removed (0600 www-data preserved; `APP_URL=http://195.26.255.80:8080`;
  `PUBLIC_QR_BASE_URL` / `SESSION_SECURE_COOKIE` / `SCA_PUBLIC_PREVIEW` absent).
- **`sca_edge`:** kr-app disconnected, network removed; kr-app nets = `sca_internal` only; kr-mariadb `sca_internal` only (no host port).
- **`:8080` pilot fallback intact:** binding `195.26.255.80:8080`; `/up`, `/admin/login`, `/collector/login` all `200`; kr-app healthy.
- **`DOCKER-USER` byte-identical:** RELATED,ESTABLISHED RETURN; ACCEPT `103.225.137.242/32` & `103.200.35.2/32` dport 8080; DROP dport 8080.
- **Zero provenance mutation** (all counts == pre-task baseline): migrations=118, eyewear_items=2, qr=2, certs=3,
  cert_events=4, ownership=4, auths=3, status=6. QR rows unchanged (id1 `bee93d2b…` is_prod=0 created 2026-09-15;
  id2 `10c739b7…` is_prod=0 created 2026-09-24); table has `no_update`+`no_delete` triggers and no `updated_at` column;
  canonical QR fp `MD5(id|token|is_production;…) = 6bb119ee0b598222bfec58bb80c7a4cb`.

---

## Required fix + path forward (needs ChatGPT review / promotion — nothing started)

1. **New governed code slice (recommend "Phase 2A.1 — trusted-proxy env-timing fix", DEFECT-002).** Resolve trusted
   proxies from a value available *after* env load — e.g. read the CIDR list from a **config file** and have
   `trustProxies()` read `config(...)` (also `config:cache`-safe), or set trusted proxies in a bootstrapper/provider
   `boot()` that runs after `LoadEnvironmentVariables`. Add a **runtime** (not just unit) assertion that an untrusted
   RFC1918 peer (e.g. `172.19.x`) is **rejected** while the pinned `/24` edge is **honored**.
2. **Re-attempt Phase 2B** only after the fix is merged + deployed and the runtime pin is proven effective.
3. **Overall `SCA-PRODUCTION-CUTOVER` remains OPEN / BLOCKED.** Do **not** proceed to DNS / public TLS / Phase 2C.

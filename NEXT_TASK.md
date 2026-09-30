# NEXT TASK

**STATUS:** NONE — no executable task is currently authorized. **ACTIVE = NONE, NEXT_TASK = NONE.**

## Latest: SCA-COLLECTOR-PASSWORD-RESET-FAILURE-HARDENING — **DONE (merged + deployed)** 2026-09-30

Merged `--no-ff` (reviewed commits preserved, not squashed) + deployed to production `main`.

- **Base:** `c568331f9eca01cd2eed068f3e0b6af3e9381665`
- **Feature HEAD:** `8324b0e1e8938ee60884c2732cba239b2a603832` (commits `f3e86f2`, `8fdce4d`, `8324b0e`)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `4095ad506e01458b5131523d4b0b9ca49ed97ac5`**
- Report: impl repo `docs/task-reports/SCA-COLLECTOR-PASSWORD-RESET-FAILURE-HARDENING.md`.

`ForgotPasswordController::sendLink` now wraps the `sca_collectors` broker send in `try/catch (\Throwable)`: a
mail-transport failure returns the identical enumeration-safe generic response (no HTTP 500; no exception/email/token/
provider/credential leak to browser), logging only the exception class. **Classification B** (traced Laravel 12.66 +
`symfony/mailer` ^7.2): a Throwable does not prove non-acceptance, so the broker reset token is **retained** on
failure (deleting could invalidate a link the collector received). Validation before the try; all
token/expiry/throttle/single-use/broker-separation/eligibility/no-auto-login/success behavior preserved.

**Deploy verification:** deploy gate focused 20/97 + full `tests/Feature/Sca` **641/3462**; `migrate → Nothing to
migrate` (migrations 118); DEPLOYED_HEAD==ORIGIN_MAIN==MERGE_SHA. Deployed controller contains the try/catch and
**no** `getUser`/`deleteToken`/token-invalidation. Mail config **unchanged** (`MAIL_MAILER=log`,
`no-reply@localhost`) — no SMTP activation. `:8080` fallback (incl `/collector/forgot-password`) all 200; collector
auth healthy; **production counts + QR fp `6bb119ee…` unchanged**; MariaDB private. Phase-2B edge restored after the
deploy recreate (kr-app reconnected to `sca_edge` 172.20.0.3; sr-caddy→kr-app:80 OK; SCA vhost SNI `/p`→200,
`/admin`→403); smsrocket 200; Caddyfile `00f16788`; DOCKER-USER 6 lines; `TRUSTED_PROXIES=172.20.0.0/24` unchanged.
Pilot on public `195.26.255.80:8080`, `--no-dev`, clean tree, no config cache, no probe artifacts. Did not manufacture
a real reset failure/email (relied on the disposable-DB/failing-transport tests).

## Authorization state

`SCA-PRODUCTION-CUTOVER` remains **OPEN**; **Phase 2C blocked on client DNS access** (GoDaddy `verify` A record). No
queued item is promoted. **SCA-054 must not start.** Nothing is active.

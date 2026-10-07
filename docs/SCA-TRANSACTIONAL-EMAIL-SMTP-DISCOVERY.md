# SCA Transactional Email / SMTP — discovery + production-readiness plan (DISCOVERY/PLAN ONLY)

**Date:** 2026-10-07 · **Status: READ-ONLY discovery + production-readiness plan. NO implementation, NO `.env` change, NO DNS change, NO provider provisioned, NO email sent, NO production restart.** Deployed baseline `e4306e999e3a528a8126f9ede85cdc6d1b44eeac`, migrations **122**, `MAIL_MAILER=log`. For ChatGPT audit. NEXT_TASK set to this task (discovery/plan stage).

**Objective:** make SCA able to reliably deliver essential transactional email to collectors — the immediate business-critical case being **collector password reset**, which is fully built but undelivered because production uses `MAIL_MAILER=log`.

**Method:** traced the deployed code (config + Collector package + Provenance notification + routes + tests) with `file:line`, re-verified live production `.env` operational state (config values only; credentials reported SET/UNSET, never printed) and live DNS (read-only `dig`). Builds on and **supersedes with current-baseline facts** `docs/SCA-PRODUCTION-EMAIL-PROVIDER-PLAN.md` (gov, 2026-10-02, baseline `dff2781`/120) and `docs/SCA-PRODUCTION-EMAIL-SMTP-AUDIT.md`.

**Headline:** the collector password-reset flow is **complete, correct, synchronous, enumeration-safe, and transport-failure-hardened**; activating real delivery is a **pure `.env` + provider/DNS exercise with no functional code change** — **except** one security item: the emailed reset-link host is derived from the **request host** (no `URL::forceRootUrl`) and there is **no app-level `TrustHosts` allowlist**. Today that is latent (links only go to the log; `TrustProxies` ignores forwarded-host; kr-app is loopback-only behind Caddy's Host-matched edge), but it becomes a **live host-header-poisoning / account-takeover vector the moment real delivery is switched on**. ⇒ **Recommendation: B — small code hardening + configuration.**

---

## 1. Current mail architecture (deployed)

`config/mail.php`:
- Default mailer `env('MAIL_MAILER','smtp')` (:16). Transports defined: `smtp` (:37), `ses` (:48), `mailgun` (:52), `postmark` (:56), `sendmail` (:60), `log` (:65), `array` (:70), `failover`→[smtp,log] (:74-80).
- `smtp` reads legacy keys: `MAIL_HOST` (default `smtp.mailgun.org`, :39), `MAIL_PORT` (587, :40), **`MAIL_ENCRYPTION`** (tls, :41 — this config uses `MAIL_ENCRYPTION`, **not** `MAIL_SCHEME`), `MAIL_USERNAME` (:42), `MAIL_PASSWORD` (:43). `from.address`=`MAIL_FROM_ADDRESS` (:95), `from.name`=`MAIL_FROM_NAME` (:96).
- `config/services.php`: `postmark.token`=`POSTMARK_TOKEN` (:24); `mailgun.*`=`MAILGUN_DOMAIN/SECRET/ENDPOINT`; `ses.*`=`AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY/AWS_DEFAULT_REGION`. API-driver transports read these; **the API-driver composer packages (`symfony/postmark-mailer`, etc.) are suggest-only / not installed** — so **SMTP transport needs no composer change**, an API driver would.

**Production `.env` operational state** (verified live; values withheld where sensitive):
- `MAIL_MAILER` = **`log`** → nothing is transmitted; messages render to the log channel only.
- `MAIL_FROM_ADDRESS` = SET (a non-domain placeholder, per the prior plan `no-reply@localhost`), `MAIL_FROM_NAME` = **`SCA`** (placeholder).
- `MAIL_HOST`, `MAIL_PORT`, `MAIL_ENCRYPTION`, `MAIL_USERNAME`, `MAIL_PASSWORD` = **absent**; `POSTMARK_TOKEN`/`MAILGUN_*`/`AWS_*` = **UNSET**. (Fail-closed: no transport configured.)
- `APP_URL` = **`https://verify.secondchanceauthenticators.com`**; `QUEUE_CONNECTION` = **`sync`**; `SESSION_SECURE_COOKIE` = `true`; `APP_ENV` = `production`.

## 2. Collector password-reset flow (end-to-end)

Routes (`packages/Sca/Collector/src/Routes/collector-routes.php`, `/collector` prefix, `web` group = session+CSRF, `collector.guest`):
- `GET /collector/forgot-password` → `collector.password.request` → `ForgotPasswordController@show` (:38)
- `POST /collector/forgot-password` → `collector.password.email` → `ForgotPasswordController@sendLink`, `throttle:6,1` (:39)
- `GET /collector/reset-password/{token}` → `collector.password.reset` → `ResetPasswordController@show` (:40)
- `POST /collector/reset-password` → `collector.password.reset.update` → `ResetPasswordController@reset`, `throttle:6,1` (:41)

- **Broker/provider (runtime-registered, not editing Krayin):** `CollectorServiceProvider::register()` (:29-48) adds guard `collector` (session, provider `sca_collectors`), provider `sca_collectors` (eloquent → `Sca\Provenance\Models\CollectorAccount`), and password broker `sca_collectors` → table **`sca_collector_password_resets`**, **expire 60 min**, **throttle 60 s** (:42-47). `config/auth.php` itself only defines the staff `user` broker.
- **Request handler:** `ForgotPasswordController@sendLink` (:32-66) validates+lowercases email (:35), builds credentials `['email'=>…, 'status'=>'active']` (:39) so only active accounts get a link, calls `Password::broker('sca_collectors')->sendResetLink($credentials)` (:42). **Enumeration-safe**: identical generic flash on every outcome (:64-65). **Transport-failure-hardened**: send wrapped in try/catch (:43-62), logs only `exception=>class` privacy-safely (:61), never 500s, token intentionally not deleted on throw (retryable).
- **Notification:** `Sca\Provenance\Notifications\CollectorResetPassword` — `via()`=`['mail']` (:24-27), `toMail()` builds a standard Laravel `MailMessage` (:29-42). Dedicated SCA notification (targets the collector reset route), **uses the Laravel mail abstraction cleanly — no SCA-specific transport assumptions.** Wired via `CollectorAccount::sendPasswordResetNotification($token)` (`CollectorAccount.php`:45-48).
- **Token:** Laravel DatabasePasswordBroker/TokenRepository, table `sca_collector_password_resets`, hashed at rest, email-bound, single-use (deleted on success), 60-min expiry (tests r6/r7/r8).
- **Account lookup:** `CollectorAccount` (table `sca_collector_accounts`, :30), implements `CanResetPasswordContract`, uses `Notifiable`.
- **Reset submit:** `ResetPasswordController@reset` (:34-65) validates token/email/password(confirmed,min8), `Password::broker('sca_collectors')->reset(...)`, closure sets `Hash::make` + `event(PasswordReset)` (:50-55), redirects to `collector.login.show` — **no auto-login**; only the password hash changes (no ownership/identity change, tests r13/r14).

## 3. Reset-URL construction + host-header finding (SECURITY)

`CollectorResetPassword.php`:31-34 builds the link:
```php
$url = url(route('collector.password.reset', ['token'=>$this->token, 'email'=>$notifiable->getEmailForPasswordReset()], false));
```
`route(..., false)` → relative path; `url(...)` prepends the **request root URL**. There is **no `URL::forceRootUrl` / `forceScheme` anywhere** (grep of `app/`, `packages/Sca/`, `bootstrap/`, providers = zero). So the link host is **derived from the incoming request**, not from `APP_URL`. Not a signed URL.

Host-header protections present / absent:
- **`TrustProxies`** (`bootstrap/app.php`:35-40) trusts a header MASK but the proxy LIST comes from `config/trustedproxy.php`:61-68 which **fails safe** — unset/empty/`*`/malformed ⇒ `proxies=null` ⇒ **all `X-Forwarded-*` (incl. `X-Forwarded-Host`) ignored.** So forwarded-host spoofing from an untrusted peer is neutralized. (`TRUSTED_PROXIES` is set to the edge /24.)
- **`TrustHosts` / host allowlist = NONE** (no `trustHosts(...)`, no `config/trustedhosts`, no `app/Http/Middleware`). Nothing in the **app** pins the acceptable `Host`.
- **Edge mitigation (today):** kr-app binds **loopback `127.0.0.1:8080`** only and is reachable solely through `sca-caddy`'s Host-matched site block for `verify.secondchanceauthenticators.com`; an external forged `Host` does not match that block. So in the current topology the Host reaching kr-app is effectively the canonical domain.

**Assessment:** the canonical reset host is guaranteed **only by edge topology**, not by the app. With `MAIL_MAILER=log` the link is written to the log, so the risk is **latent**. The moment real delivery is enabled, a forged `Host` that ever reaches the app (e.g. a future edge change, an added route/path, or any alternate path to kr-app) would be reflected into an emailed reset link → **account takeover**. Best practice is to pin the host in the app before enabling delivery. The existing test `r4` only asserts the URL *contains* `/collector/reset-password/{token}` + `email=` (not the host), so an app-level host pin would **not** break the suite.

**Proposed minimal hardening (implementation stage, if approved — NOT done here):** in a service provider (e.g. a small SCA provider or `AppServiceProvider::boot`) call `URL::forceRootUrl(config('app.url'))` and `URL::forceScheme('https')` so every generated URL (incl. the reset link) is canonical regardless of request host; **and/or** add `$middleware->trustHosts(at: ['verify.secondchanceauthenticators.com'])`. One small, self-contained change + focused tests asserting the emailed link begins with `https://verify.secondchanceauthenticators.com`. No schema, no broker/flow change.

## 4. All SCA mail/notification surfaces

Exhaustive grep (`Mail::`, `Notification::`, `->notify(`, `sendResetLink`, `ShouldQueue`, `Notifiable`, `Mailable`):
- **Collector password reset** — the **only** outbound mail in all of SCA. **Classification (1): implemented but currently undelivered because `MAIL_MAILER=log`.**
- **Claim workflow** — **Classification (2): intentionally manual, no email.** `ClaimWorkflow.php` has zero mail/notify; claim is reached via an opaque grant-token URL (`GrantClaimController` :47, token only in the form action, "never displayed"); views render in-UI only.
- **Transfer workflow** — **Classification (2): intentionally manual, no email.** `TransferWorkflow.php` has zero mail/notify; `TransferController@initiate` shows a copy-to-clipboard one-time invite link (`transfer/initiate.blade.php`:10-12) shared out-of-band.
- **Staff/User** — `Notifiable` trait present (framework default), **no SCA staff mail send.**

**Confirmed:** neither claim nor transfer sends any email today — both only render a shareable link in the UI. **Enabling SMTP alone sends nothing for claim/transfer** (there is no send call to trigger); it only activates password-reset delivery. Automating claim/transfer invites would be separate, deliberate work (post-core; out of this task's scope).

## 5. Sync vs queue

`CollectorResetPassword` does **not** implement `ShouldQueue` (no `ShouldQueue` on any SCA mailable/notification). `QUEUE_CONNECTION=sync`. ⇒ delivery is **fully synchronous on the web request thread; no queue worker required** and `QUEUE_CONNECTION` is irrelevant to this flow. The synchronous send is exactly why the controller has transport-failure hardening. **No queue/worker/retry subsystem is needed for safe password-reset delivery.**

## 6. Code-change necessity

- **Functional delivery:** **no code change** — a pure `.env` switch (`MAIL_MAILER`=smtp + provider creds, or an API driver's token) activates sending; `MAIL_FROM_*` already set; notification sends synchronously and is already transport-hardened.
- **Security:** **one small hardening recommended before real delivery** — pin the reset-link host to `config('app.url')` (§3). This is why the recommendation is **B**, not A.

---

## 7. Recommended provider architecture (Postmark over SMTP)

Per the prior plan (unchanged by current baseline): **Postmark, Transactional message stream, over its SMTP interface** — best-in-class transactional deliverability, trivial Laravel SMTP config, **no composer change**. **Amazon SES over SMTP** is the cost/scale alternative (more ops: sandbox exit, bounce handling). Either is SMTP-only ⇒ no code/dependency change. *(No account created; operator selects/provisions.)*

**Sender identity:** From name **`Second Chance Authenticators`**, From address on a **dedicated sending subdomain** (recommended) rather than the Shopify apex.

## 8. Proposed sending subdomain

**Recommend `send.secondchanceauthenticators.com`** (From e.g. `no-reply@send.secondchanceauthenticators.com`), verified by **domain DKIM** (no real mailbox needed). Rationale:
- Isolates SCA's SPF/DKIM/Return-Path reputation from the **Shopify apex** (live store) and from the **`verify.` app host**.
- Live DNS confirms the apex has **no SPF and no MX**, so there is **nothing to merge or break at the apex** — a fresh subdomain is clean and lowest-risk.
- The existing org `_dmarc` (`p=quarantine; adkim=r; aspf=r`) uses **relaxed alignment**, so **DKIM on the subdomain satisfies the existing DMARC** with no DMARC change.

*(Exact subdomain label can match the provider's convention, e.g. `pm-bounces` host under it; the operator may choose a different label — the structure, not the string, is the recommendation.)*

## 9. DNS requirements (record ROLES only — NO fabricated values)

Live read-only DNS baseline (today): apex `A`→`23.227.38.32` (Shopify, **do not touch**); **no apex MX; no apex SPF TXT**; `_dmarc`=`v=DMARC1; p=quarantine; adkim=r; aspf=r; rua=mailto:dmarc_rua@onsecureserver.net`; `verify.`→`195.26.255.80`; no `send/mail/pm/em/mg` subdomain exists.

To publish **at the DNS host for the chosen sending subdomain** (exact values generated by the provider after domain creation — **do not invent**):
- **DKIM** — provider `TXT`/`CNAME` at `<selector>._domainkey.<sending-subdomain>`. **Required** (gives DMARC alignment under the relaxed policy). *(SES: 3×CNAME.)*
- **Return-Path / bounce** — provider `CNAME` (Postmark: `pm-bounces.<subdomain>` → provider target; SES: a custom MAIL FROM subdomain needing MX + SPF TXT). Recommended so SPF also aligns.
- **SPF** — a single `TXT` `v=spf1 include:<provider> -all` on the **sending subdomain** (Postmark `include:spf.mtasv.net`; SES `include:amazonses.com`). **The apex SPF is not touched** (there is none). One SPF TXT per name — never add a second.
- **DMARC** — **no change** (existing org policy covers the subdomain via relaxed alignment). Optional later: a subdomain-scoped `_dmarc.send` policy or an SCA-monitored `rua` — out of scope.
- **Apex A / Shopify / `verify.` A** — **untouched.** No existing Shopify DNS record is modified. No existing SPF is edited (none exists at apex); if any sender is later found on a name we touch, reconcile all senders first.

**Verification gate (operator):** provider dashboard shows the domain **Verified / DKIM active / Return-Path confirmed**, and public `dig` confirms the records resolve, **before any send**.

## 10. Environment / config requirements (NO secrets)

Target in **`app/.env`** (the container `/var/www/html/.env` Laravel reads; the repo-root `/opt/sca-platform/.env` is compose-only — do NOT use it):
```
MAIL_MAILER=smtp
MAIL_HOST=<provider SMTP host>          # Postmark: smtp.postmarkapp.com
MAIL_PORT=587                           # STARTTLS submission
MAIL_ENCRYPTION=tls                     # this config reads MAIL_ENCRYPTION (not MAIL_SCHEME)
MAIL_USERNAME=<provider SMTP username>  # Postmark: Server API Token (operator-entered)
MAIL_PASSWORD=<provider SMTP password>  # Postmark: same token — SECRET, never printed/committed/logged
MAIL_FROM_ADDRESS=no-reply@send.secondchanceauthenticators.com
MAIL_FROM_NAME="Second Chance Authenticators"
```
- **Secrets entered only by the operator on the server at activation** — never in this doc, git, logs, or chat. Reports record SET/UNSET only.
- **Preserve unchanged:** `APP_URL=https://verify.secondchanceauthenticators.com`, `QUEUE_CONNECTION=sync` (no worker), `SESSION_SECURE_COOKIE=true`, loopback `127.0.0.1:8080`, `SCA_PUBLIC_PREVIEW=0`, `TRUSTED_PROXIES` (edge /24), all broker/reset behavior.
- Apply with `php artisan config:clear` as **uid 33:33** (config is not cached in this deploy path; no container rebuild/recreate needed for an `.env`-only value change). **Back up `app/.env` first** (`app/.env.mail.bak`, mode 0600).
- **Note (not in scope):** `config/mail.php` smtp block ships `verify_peer=>false` (Krayin default) — a latent TLS item flagged for a separate task; do not change here.

## 11. Safe activation sequence (strict order — HALT between stages)

0. **(B) Apply + deploy the host-pin hardening** (§3) via the normal governed candidate→audit→merge→deploy flow, so emailed links are canonical before any real send. *(Separate implementation stage; not this task.)*
1. **Provider + domain:** create server/Transactional stream; add + verify the sending subdomain (domain DKIM, not single-sender mailbox).
2. **DNS auth:** publish provider DKIM + Return-Path (+ subdomain SPF) at the DNS host. *(No DNS performed in this task.)*
3. **Verify DNS:** provider shows Verified/DKIM/Return-Path green **and** public `dig` resolves. Do not proceed until green.
4. **Configure Laravel:** back up `app/.env`; set §10 `MAIL_*` with the real host + operator credentials; preserve everything else.
5. **Reload:** `php artisan config:clear` (uid 33:33); confirm `config('mail.default')=smtp` + `mail.from.address` via read-only tinker (never print the password).
6. **One credential-free, token-free test:** `Mail::raw('SCA SMTP connectivity test '.now(), fn($m)=>$m->to('<operator inbox>')->subject('SCA SMTP connectivity test'))` — creates NO reset token, touches NO account, to an operator inbox only.
7. **Inspect:** confirm receipt + headers **SPF=pass, DKIM=pass, DMARC=pass**, correct From/display-name; cross-check the provider dashboard (message-id/status). Capture only message-id/status/recipient/From — never the credential.
8. **Only then** test real **Forgot Password** against a **throwaway operator-controlled test collector** (seeding/removing it is a separate explicitly-authorized DB-write step); confirm the email arrives with an `https://verify.secondchanceauthenticators.com/collector/reset-password/{token}` link. **Never reset a real collector's password.**

## 12. Delivery test matrix

| # | Check | Pass criterion |
|---|---|---|
| T1 | Config loaded | `config('mail.default')=smtp`; from address/name correct (no secret printed) |
| T2 | Connectivity (`Mail::raw` → operator inbox) | delivered; provider shows Accepted/Delivered |
| T3 | Authentication headers | SPF=pass, DKIM=pass, DMARC=pass |
| T4 | Sender identity | From shows "Second Chance Authenticators" @ sending subdomain |
| T5 | Reset link host (post-hardening) | emailed link begins `https://verify.secondchanceauthenticators.com/collector/reset-password/` |
| T6 | Throwaway-account Forgot Password | email received; token valid; reset succeeds; redirect to collector login; single-use |
| T7 | Enumeration-safety preserved | unknown/disabled email → identical generic flash, no email, no 500 |
| T8 | Throttle | `throttle:6,1` + broker 60 s still enforced |
| T9 | No regression | full `tests/Feature/Sca` green; provenance untouched |

## 13. Rollback plan

Any stage: restore `MAIL_MAILER=log` (and the rest of `app/.env` from the 0600 backup) → `php artisan config:clear` (uid 33:33). Mail returns to log-only; no domain data touched, no migration, no DB write — fully reversible. Published DNS records are harmless to leave (they only authorize the provider) and can be removed separately by the operator. The §3 host-pin hardening, once merged, is a safe permanent improvement (independent of the mailer) and need not be rolled back.

## 14. Recommendation — **B (small code hardening + configuration)**

The password-reset flow is complete, synchronous, enumeration-safe, and transport-hardened; delivery is a pure `.env`/provider/DNS exercise with **no functional code change**. **But** the emailed reset-link host is request-derived with no app-level `TrustHosts` pin — a latent host-header-poisoning vector that becomes live with real delivery. The correct, non-manufactured step is a **single small hardening** (`URL::forceRootUrl(config('app.url'))` + `forceScheme('https')`, and/or `trustHosts([...])`) with focused tests, before switching the mailer on. Everything else is configuration. **Not A**, because enabling delivery without the host pin would ship a real account-takeover surface; **not C**, because the flow itself is complete and safe apart from this one item.

## 15. Operator (Francis) actions required

1. Choose provider (Postmark recommended) and **create the account + Transactional server/stream** (no creds shared with Claude).
2. **Add + verify the sending subdomain** `send.secondchanceauthenticators.com` (domain DKIM).
3. **Publish provider DNS records** (DKIM + Return-Path + subdomain SPF) at the DNS host using the **provider-generated values**; confirm Verified/green. Do not touch apex/Shopify/`verify.` records.
4. At activation, **enter the SMTP credentials directly in `app/.env` on the server** (never share them); run `config:clear` as uid 33:33 (or have Claude do the non-secret edits while the operator supplies the secret values).
5. Provide an **operator-controlled test inbox** and authorize a **throwaway test collector** for the Forgot-Password end-to-end test.
6. Decide whether to apply the §3 host-pin hardening (recommended) before enabling delivery.

## 16. Actions Claude can perform later (post-approval, governed)

- Implement + test the **§3 host-pin hardening** on a candidate branch (zero schema; focused tests), then governed merge/deploy.
- Perform the **non-secret `.env` edits** (`MAIL_MAILER`, `MAIL_HOST`, `MAIL_PORT`, `MAIL_ENCRYPTION`, `MAIL_FROM_*`) and `config:clear` while the operator enters the secret `MAIL_USERNAME`/`MAIL_PASSWORD`, back up `app/.env` first.
- Run the read-only config verification (tinker) and the **credential-free `Mail::raw` connectivity test** to an operator inbox; read provider/headers results (SET/UNSET + message-id only).
- Drive the throwaway-account Forgot-Password test and the §12 matrix; execute the rollback.

## 17. Closure criteria

This task (discovery/plan) is complete when this governance doc is committed and audited. The **capability** is production-ready when: the §3 hardening is deployed; the sending subdomain is verified (DKIM/Return-Path/SPF green); `app/.env` is switched to the provider over SMTP with secrets entered only on the server; the §12 matrix passes (connectivity + SPF/DKIM/DMARC pass + throwaway Forgot-Password delivers a canonical `https://verify.…` link); enumeration-safety + throttle preserved; full SCA suite green; and rollback to `log` is proven. Claim/transfer email automation is explicitly **out of scope** (post-core).

**NEXT_TASK.md set to this task at discovery/plan stage. No implementation, no `.env`/DNS/provider/email/restart change. STOP for ChatGPT audit.**

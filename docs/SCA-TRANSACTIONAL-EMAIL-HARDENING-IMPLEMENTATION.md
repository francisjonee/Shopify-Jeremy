# SCA Transactional Email — pre-activation security hardening — implementation candidate (NOT merged/deployed)

**Date:** 2026-10-07 · **Status: IMPLEMENTED + TESTED + PUSHED on a candidate branch. NOT merged, NOT deployed. Live tree restored to `main`; production byte-identical (`MAIL_MAILER=log`, migrations 122).** For ChatGPT candidate audit. Approved direction: Recommendation **B** (gov discovery `438fe17`).

**Scope:** the two pre-activation security items from the approved discovery. **No SMTP activation, no provider/DNS/`.env` change, no email sent, no migration, no schema, no queue, no Shopify, no claim/transfer email, no secrets.**

## Candidate identity
- **Branch:** `origin/feat/sca-transactional-email-hardening`
- **Base SHA (= deployed `main`, merge-base):** `e4306e999e3a528a8126f9ede85cdc6d1b44eeac`
- **Head SHA:** `e2cce0fd159ace06f6045e86d84527dcac09e007` (1 commit)

## Fix 1 — Canonical reset-URL origin (host-header poisoning)

**Before:** `CollectorResetPassword::toMail()` built the link with `url(route('collector.password.reset', [...], false))`, which prepends the **request root URL**. With no `URL::forceRootUrl` and no app-level `TrustHosts`, a forged/alternate `Host` (or an untrusted forwarded-host) reaching the app would be reflected into the emailed reset link — a host-header **account-takeover** vector once real delivery is enabled.

**After:** the origin is pinned to the **trusted application config**:
```php
$url = rtrim((string) config('app.url'), '/').route('collector.password.reset', [
    'token' => $this->token,
    'email' => $notifiable->getEmailForPasswordReset(),
], false);
```
This reads `config('app.url')` (trusted config, **not** a hard-coded hostname) and the framework's relative `route()`, so the origin is immune to the request host. It is the **same config-driven canonicalization the QR/passport URLs already use** (`rtrim(config('app.url'),'/').route(name, params, false)`), keeping the approach consistent and auditable.

**Design note (why not a boot-time `URL::forceRootUrl`):** a provider `boot()` runs once at framework bootstrap, before any feature test can set `config('app.url')`, so a boot-time pin is **not exercisable by feature tests** (and in the default test env `app.url=http://localhost`, a global force would carry blast-radius risk to the 883-test suite). Reading trusted config at send time is both safer (per-request, zero blast radius) and directly testable with a malicious-Host request. Token/broker/expiry/throttle/collector-lookup/notification wording are **unchanged**.

## Fix 2 — SMTP TLS peer verification

**Root cause:** `config/mail.php` `smtp` block shipped `'verify_peer' => false` (a Krayin/Webkul default). Laravel's `MailManager::createSmtpTransport()` passes the **entire smtp config array as the Symfony DSN options** (`vendor/.../MailManager.php:199-206`), and `EsmtpTransportFactory` (`vendor/symfony/mailer/.../EsmtpTransportFactory.php:47-50`) reads `verify_peer` from the DSN and, when falsy, sets `ssl.verify_peer=false` **and** `ssl.verify_peer_name=false` on the stream — i.e. the override **actively disables TLS certificate/peer verification for all outbound SMTP** (a MITM exposure the moment SMTP is enabled). It is not dead config.

**Fix:** remove the `'verify_peer' => false` line. With the key absent, the factory's condition (`'' !== getOption('verify_peer')` **&&** `!filter_var(getOption('verify_peer', true), FILTER_VALIDATE_BOOL)`) evaluates false, so the insecure branch is not taken and **Symfony's secure default (peer verification enabled) applies.** No other SMTP option changed. A guarding comment forbids reintroducing a falsy value.

## Exact changed files (2 modified, 1 new)
- M `app/config/mail.php` — removed `'verify_peer' => false` from the `smtp` mailer (+ guard comment).
- M `app/packages/Sca/Provenance/src/Notifications/CollectorResetPassword.php` — reset-URL origin pinned to `config('app.url')`.
- A `app/tests/Feature/Sca/TransactionalEmailHardeningTest.php` — 9 focused tests.

**Untouched:** routes, controllers, broker/provider config, `sca_collector_password_resets` token semantics/expiry/throttle, collector lookup, notification contents, ownership/provenance, authentication, ACL, `.env`, Shopify, QR/cert/auth. **No migration.**

## Tests
- **Focused `TransactionalEmailHardeningTest` — 9 passed / 24 assertions:** `h1` malicious `Host` + `X-Forwarded-Host` cannot alter the emitted reset-link origin (starts with the configured canonical host; attacker host absent); `h2` origin is https canonical; `h3` origin tracks `config('app.url')` verbatim (trailing-slash tolerant, no double slash); `h4` smtp config no longer sets a falsy `verify_peer`; `h5` the **built** SMTP transport's stream options do not disable `ssl.verify_peer`/`verify_peer_name`; `h6` enumeration-safety preserved (unknown + disabled → no notification, no error); `h7` active account still gets exactly one reset; `h8` single-use token + real end-to-end reset unchanged (reused token fails, password preserved); `h9` zero provenance/ownership mutation from the reset flow.
- **Full governed gate:** `… -e DB_DATABASE=sca_domain_test … php artisan test tests/Feature/Sca` → **892 passed / 4808 assertions**, exit 0 (883 baseline + 9 new).

## Production-safety verification (post-restore)
- Live tree restored: `git checkout main` + `reset --hard origin/main` → app HEAD **`e4306e999e3a528a8126f9ede85cdc6d1b44eeac`**; vendor re-pruned `--no-dev`; `config:clear`+`route:clear`.
- **Candidate code absent on `main`:** the new test file does not exist on disk; `config/mail.php` on main still has `verify_peer => false`; the notification on main still uses the `url(route(...))` form (i.e. the fixes live only on the candidate branch).
- **Prod unchanged:** `MAIL_MAILER=log`; migrations **122**; provenance counts byte-identical — items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3. No `.env`/DNS/provider/email/restart change.
- **Live HTTP invariants:** `/p/{bogus}` 404 · `/collector` 302 · `/collector/forgot-password` 200 · `/storage/..` 404 · unsigned `/sca/shopify/webhook` 401 · `smsrocket.io` 302.
- **Shopify untouched.**

## Candidate gate
**NOT merged. NOT deployed. No production mutation. `MAIL_MAILER` remains `log`. Shopify untouched.** Awaiting ChatGPT candidate audit of head `e2cce0fd159ace06f6045e86d84527dcac09e007`.

See `docs/SCA-TRANSACTIONAL-EMAIL-SMTP-DISCOVERY.md`.

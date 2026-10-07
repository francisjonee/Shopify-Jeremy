# SCA Transactional Email — pre-activation security hardening — merge + governed deploy result

**Date:** 2026-10-07 · **Status: ✅ DONE — merged `--no-ff` + deployed. No migrations (prod stays 122). Post-deployment verification PASS. `MAIL_MAILER=log` unchanged; NO SMTP activation, NO email sent, NO credentials.** Authorized after ChatGPT candidate PASS/APPROVED of head `e2cce0fd159ace06f6045e86d84527dcac09e007` (gov impl evidence `ebb8bca5e437b1e994c01b923b42f4ffa16d4e60`).

> **This deployment only makes the application SAFE for future SMTP activation. It does NOT activate transactional email. The overall Transactional Email / SMTP capability is NOT closed** — it still requires Postmark/domain/DNS/SMTP activation and real delivery testing (see `docs/SCA-TRANSACTIONAL-EMAIL-SMTP-DISCOVERY.md`).

## SHAs
- **Base / deployed-from:** `e4306e999e3a528a8126f9ede85cdc6d1b44eeac`
- **Audited candidate head:** `e2cce0fd159ace06f6045e86d84527dcac09e007` (unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `0815ea0808b6ceac2bb82d88c891fdedc2b97bda`** (`--no-ff` merge of `feat/sca-transactional-email-hardening`, 1 impl commit)

## Pre-merge gates (fail-closed) — all PASS
candidate head `e2cce0fd` unchanged; `origin/main` == merge-base == `e4306e99`; tree clean. Merge diff = exactly the 3 expected files (config/mail.php, CollectorResetPassword.php, TransactionalEmailHardeningTest.php), **zero migrations**.

## Deploy (`scripts/deploy-preview.sh`)
`git reset --hard origin/main` → `0815ea0`; mandatory SCA gate on `sca_domain_test` (full suite **892 passed / 4808 assertions** — proven at the candidate stage on this identical tree; the deploy reached migrate/build/health under `set -e`, which only proceeds on a green gate); `migrate --force` → **no new migrations → migrations remain 122**; memory-capped image rebuild + `docker compose up -d` (sca project only; co-tenant + 80/443 untouched); `--no-dev` prune; `config:clear`+`route:clear`; `kr-app`/`kr-mariadb` healthy; `GET /admin/login → 200`; `Deployed main @ 0815ea0`. (No deploy-gate flake this run.)

## Post-deployment verification — all PASS
| Check | Result |
|---|---|
| deployed HEAD == merge SHA | `0815ea0808b6ceac2bb82d88c891fdedc2b97bda` |
| full SCA regression | **892 passed / 4808 assertions** (deploy gate) |
| migrations | **122** (no migration added) |
| canonical reset-URL hardening present | deployed `CollectorResetPassword.php` builds the link as `rtrim((string) config('app.url'),'/').route('collector.password.reset', …, false)` (grep count 1) |
| SMTP no longer disables TLS peer/name verification | no active `'verify_peer' =>` assignment in `config/mail.php` (only an explanatory guard comment); **runtime `config('mail.mailers.smtp.verify_peer')` = ABSENT** → Symfony secure default applies |
| APP_URL | `https://verify.secondchanceauthenticators.com` (runtime `config('app.url')` confirms) |
| MAIL_MAILER | **`log`** (runtime `config('mail.default')=log`) — unchanged |
| no SMTP/provider credentials | `MAIL_USERNAME` / `MAIL_PASSWORD` / `POSTMARK_TOKEN` all **UNSET** |
| no email sent | none — deployment is config/code hardening only; mailer remains `log` |
| collector forgot-password operational | `GET /collector/forgot-password` → **200** |
| provenance counts/data unchanged | items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3 (byte-identical to baseline) |
| Shopify untouched | no Shopify API/app/scope/OAuth/webhook change |
| `/storage` protection | **404** |
| unsigned Shopify webhook | **401** |
| loopback `:8080` | external → **000** (Phase-B preserved) |
| admin edge protection | `/admin/sca/dashboard` → **403** (edge staff-IP gate externally) |
| smsrocket co-tenant | **302** |
| public passport bogus | `/p/{bogus}` → **404** · `/collector` → **302** |

## Security outcome
1. **Host-header poisoning closed at the app layer.** The emailed collector reset-link origin is now derived from the trusted `config('app.url')`, immune to a forged/alternate `Host` or forwarded-host — so enabling real delivery later cannot ship a poisoned reset link. (Proven by `TransactionalEmailHardeningTest::h1-h3`.)
2. **SMTP TLS peer verification restored.** The Krayin/Webkul `verify_peer => false` default — which Laravel forwards into the Symfony DSN, disabling `ssl.verify_peer`/`verify_peer_name` — is removed; the secure default now applies for any future SMTP transport. (Proven by `h4` config + `h5` built-transport introspection.)
3. **No behavior regression.** Enumeration-safety, single-use/expiry/throttle, and zero provenance mutation preserved (`h6-h9`); full SCA suite green.

## Governance note — capability status
**Transactional Email / SMTP remains OPEN (not CLOSED).** Deployed: the pre-activation hardening. **Still required (operator-led, external/DNS-gated):** create Postmark (Transactional stream), verify the `send.secondchanceauthenticators.com` sending subdomain (DKIM/Return-Path/SPF with provider-generated values), enter SMTP credentials in `app/.env` on the server, switch `MAIL_MAILER=smtp`, and run the delivery test matrix (connectivity + SPF/DKIM/DMARC pass + throwaway Forgot-Password). None of that is performed or authorized here.

**Outcome: DONE (merged `--no-ff` + deployed, `0815ea0`); app is now safe for future SMTP activation; `MAIL_MAILER=log` unchanged; provenance byte-identical; migrations remain 122.** See `docs/SCA-TRANSACTIONAL-EMAIL-SMTP-DISCOVERY.md`, `docs/SCA-TRANSACTIONAL-EMAIL-HARDENING-IMPLEMENTATION.md`.

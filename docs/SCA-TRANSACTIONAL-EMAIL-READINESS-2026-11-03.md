# SCA — Transactional Email Readiness Check (read-only, 2026-11-03)

**Enabling buyer-claim email verification needs only standard SMTP configuration — no code change: the
secure-claim RC already uses Laravel's mail abstraction and `symfony/mailer` is installed, so SMTP works
config-only. The single real blocker is that there is NO verified sending setup for
`secondchanceauthenticators.com` today: `MAIL=log`, the from-address is the `no-reply@localhost`
placeholder, the apex has NO SPF record, and the domain is not configured as a sending domain in any
mail service on this host. The host does run three SMTP services, but all belong to OTHER tenants
(smsrocket, a Postal relay for `relaytask.online`, a finops mail server) — none is an SCA sender and
none may be assumed reusable. The simplest secure path is a dedicated transactional provider (Postmark)
over SMTP with a verified sender + DKIM/SPF published at the domain's DNS (GoDaddy/Secureserver); an
owner-sanctioned sending domain on the existing on-host Postal server is a viable alternative. All
remaining steps are owner actions (account/credentials, DNS, one controlled test).** Read-only; no
secrets revealed, no config change, no test email, nothing deployed; production unchanged at `6e36aa7`.
Supersedes the 2026-10-29 readiness doc (which was at prod `4faf84d` / RC `4bd88d2`). **STOP.**

> Written for: the owner (Jeremy) and the external auditor reading from GitHub. Baseline: prod
> `6e36aa7`, secure-claim RC `c9a2d7d74efd2b01ee7b6f1ca0a9d99761f2c782`, governance `7dad9cc`.

---

## 1. Current SCA mail configuration (Task 1) — credentials not exposed
From production `app/.env` and `config/mail.php`:
- `MAIL_MAILER=log` — mail is written to the log, **not delivered**.
- `MAIL_FROM_ADDRESS=no-reply@localhost`, `MAIL_FROM_NAME=SCA` — **placeholder sender** (invalid for real delivery).
- No `MAIL_HOST` / `MAIL_PORT` / `MAIL_USERNAME` / `MAIL_PASSWORD` / `MAIL_ENCRYPTION` set.
- `config/mail.php`: default = `env('MAIL_MAILER','smtp')`; the `smtp` mailer reads
  `MAIL_HOST`/`MAIL_PORT`/`MAIL_ENCRYPTION`/`MAIL_USERNAME`/`MAIL_PASSWORD`; `from` reads
  `MAIL_FROM_ADDRESS`/`MAIL_FROM_NAME`. `ses`/`mailgun`/`postmark` mailers are declared but their SDKs
  are not installed (Task 7).

## 2. Can an existing SMTP service / verified domain be reused? (Task 2) — NOT as-is
Three SMTP services run on this shared host; **none is an SCA asset or a verified sender for the SCA
domain**:
| Service | What it is | Reusable for SCA? |
|---|---|---|
| `sr-mail` (`boky/postfix`) | smsrocket.io send-only Postfix relay; `ALLOWED_SENDER_DOMAINS=smsrocket.io` | **No** — restricted to `smsrocket.io`; would fail SPF/DKIM alignment for SCA. |
| `postal-*` (`postalserver/postal:3.3.7`, host network) | Self-hosted Postal server, hostname `mail3.relaytask.online` | **Only if the owner sanctions it** and adds `secondchanceauthenticators.com` as a verified Postal sending domain with its own credentials (cross-tenant decision; not drop-in). |
| `mail-server` (`finops-mail-server`, `relayaccounting_*` nets) | A different project's mail server | **No** — unrelated tenant. |

There is **no existing verified sending domain for `secondchanceauthenticators.com`** and no SCA-owned
mail credentials. (A Postmark DKIM selector noted in an older review no longer resolves.)

## 3. Exact SMTP environment variables (Task 3)
Set in production `app/.env` (Laravel reads `app/.env`, not the compose-root `.env`):
```
MAIL_MAILER=smtp
MAIL_HOST=<provider smtp host>            # e.g. smtp.postmarkapp.com
MAIL_PORT=587                             # 587 (STARTTLS) / 465 (TLS) / 2525
MAIL_ENCRYPTION=tls                       # config/mail.php reads MAIL_ENCRYPTION
MAIL_USERNAME=<provider smtp user/token>  # secret — not shown
MAIL_PASSWORD=<provider smtp pass/token>  # secret — not shown (Postmark: server API token as BOTH user & pass)
MAIL_FROM_ADDRESS=no-reply@secondchanceauthenticators.com
MAIL_FROM_NAME="Second Chance Authenticators"
```
No other keys are required for SMTP. (`APP_URL` is already correct — Task 6.)

## 4. Intended verification sender (Task 4)
- **`no-reply@secondchanceauthenticators.com`** (apex), display name e.g. "Second Chance
  Authenticators". This address **must be a verified sender/signature** on the chosen provider/relay.
- The RC's `CollectorEmailVerification` notification supplies subject/body; it needs only a valid,
  deliverable, DKIM-signed From on the SCA domain so the challenge is not spam-filtered.

## 5. DNS authentication requirements (Task 5) — DNS is at GoDaddy/Secureserver (NOT Namecheap)
Current state of `secondchanceauthenticators.com`:
- **SPF: ABSENT on the apex** → must add (e.g. `v=spf1 include:<provider> ~all`; Postmark: `include:spf.mtasv.net`).
- **DKIM: none for the SCA domain** → publish the provider's DKIM record(s) (Postmark: a
  `<selector>._domainkey`; Postal: the server's DKIM TXT).
- **DMARC: already present** — `v=DMARC1; p=quarantine; adkim=r; aspf=r; rua=…onsecureserver.net`.
  Relaxed alignment; keep it. With `p=quarantine`, correct SPF+DKIM alignment is required or mail is quarantined.
- **Return-Path / bounce**: publish if the provider requires it (Postmark: return-path CNAME; Postal: `psrp` CNAME).
All are DNS changes the owner makes at GoDaddy/Secureserver.

## 6. Application URL & verification link (Task 6) — already correct, no change
- `APP_URL=https://verify.secondchanceauthenticators.com`; `verify.…` resolves to this host (`195.26.255.80`).
- The RC's `CollectorEmailVerification` pins the confirm link to `config('app.url')` (host-header
  hardened) + route `collector.email.verify.confirm`; token single-use, hashed, 60-minute expiry. **No change needed.**

## 7. Does the RC support standard SMTP without code changes? (Task 7) — YES
- `symfony/mailer` + `symfony/mime` are installed → the built-in `smtp` transport works with
  configuration only. The RC (`c9a2d7d…`) adds no mail dependency and changes no mail code.
- `symfony/postmark-mailer` / `symfony/amazon-mailer` / `symfony/mailgun-mailer` are **not** installed, so
  the API `postmark`/`ses`/`mailgun` transports would need a composer dependency. **Use SMTP** to avoid
  any code/dependency change.

## 8. Configuration checklist (Task 8) — all owner-performed, in order
1. **Choose the sender path** (owner): (a) dedicated provider **Postmark** (SMTP), or (b) owner-sanctioned
   sending domain on the existing on-host **Postal** server.
2. **Create the account / sending identity**; add `secondchanceauthenticators.com` as a sending domain;
   add **`no-reply@secondchanceauthenticators.com`** as a verified sender.
3. **Publish DNS** at GoDaddy/Secureserver: SPF (apex), provider DKIM, any return-path/bounce CNAME; keep
   the existing DMARC. Wait until the provider marks the domain verified.
4. **Set the SMTP env vars** (Task 3) in production `app/.env`, `MAIL_FROM_ADDRESS` = the verified sender.
   Keep secrets out of the repo and logs.
5. **Ensure reachability**: `kr-app` is on `sca_internal`/`sca_edge`; confirm it can reach the SMTP
   endpoint (provider host over 587/465/2525 needs outbound egress; an on-host relay is reached via the
   Docker host gateway / a shared network — a wiring step).
6. **Apply without a code deploy**: `php artisan config:clear` (no cached config) so the mailer is picked up.
7. **One controlled smoke test** (owner): send a single verification email to an SCA-owned inbox; confirm
   delivery, DKIM `pass`, SPF `pass`, DMARC alignment, and that the confirm link verifies.
8. Then proceed to the separately-authorized secure-claim RC deployment (unchanged by this task).

## 9. Genuinely missing — credentials / owner actions only (Task 9)
1. A chosen sender path and its **account + SMTP credentials** (none exist for SCA).
2. A **verified sender** `no-reply@secondchanceauthenticators.com`.
3. **DNS records** at GoDaddy/Secureserver: **SPF (missing)** + **DKIM (missing)** (+ return-path if required).
4. **Production `app/.env` MAIL_\*** set to real SMTP + verified from-address.
5. **SMTP reachability** from `kr-app` confirmed.
6. One **controlled delivery test** to an SCA inbox.
No code change, migration, or dependency change is required for SMTP.

## Recommended next action
Owner provisions a **Postmark server (SMTP)** for `secondchanceauthenticators.com` (simplest clean,
isolated sender): verify the `no-reply@` signature, publish SPF + DKIM (+ return-path) at
GoDaddy/Secureserver, set the six `MAIL_*` vars in production `app/.env`, and run one controlled test.
(Alternative: sanction and onboard the SCA domain onto the existing on-host Postal server.) This clears
the first of the two secure-claim deploy gates; the second — separate owner deploy authorization of RC
`c9a2d7d…` — remains.

## Safety posture (this task)
Read-only. No SMTP password/API key/secret revealed; no production configuration change; no test email;
no deployment or migration; no Shopify call; buyer claiming NOT activated. Production unchanged at
`6e36aa7`; MAIL remains `log`. Secure-claim RC `c9a2d7d…` remains undeployed.

**STOP — Email verification is config-only on the RC (SMTP via installed `symfony/mailer`; no code
change). The blocker is the absence of any verified sender for `secondchanceauthenticators.com`: today
`MAIL=log`, from-address is a placeholder, apex SPF is missing, and no sending domain is configured in
any on-host mail service (all three belong to other tenants). Recommended: owner provisions Postmark
(SMTP) with a verified `no-reply@secondchanceauthenticators.com`, publishes SPF+DKIM at
GoDaddy/Secureserver, sets the six MAIL_\* vars in production `app/.env`, runs one controlled test — then
the secure-claim RC can deploy under separate authorization. Read-only; nothing changed; `6e36aa7` intact.**

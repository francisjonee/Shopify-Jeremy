# SCA Transactional Email / Postmark Activation — Phase 0 Preflight Result

**Status:** PHASE 0 COMPLETE — **BLOCKED ON EXTERNAL PREREQUISITES.** No activation performed. Production mail remains `MAIL_MAILER=log` (delivery inactive, unchanged). No code, DNS, config, Caddy, Shopify, Stripe, or schema change was made. STOP for ChatGPT activation audit; owner action required before Phase 1.

| | |
|---|---|
| Governance promotion | `49c9cf2667a8f5f45b67722d293ef2d8e8f7dba2` |
| Production baseline (deployed SHA) | `9cf72728248cf3e36d0525de4520d69717dacd5d` (migration 138) |
| Working tree | `main`, clean, no changes |
| Decision | STOP at Phase 0 (contract step 3): provider access, DNS authority, SMTP credentials, and a safe test inbox are all unavailable |

## Phase 0 read-only findings

### Ready (no action needed)
| Check | Result |
|---|---|
| Deployed SHA / migration | `9cf7272` / migration **138**, clean tree |
| Effective `APP_URL` | `https://verify.secondchanceauthenticators.com` (canonical HTTPS) ✓ |
| `APP_ENV` | `production` |
| `MAIL_MAILER` (effective) | `log` — real delivery inactive (safe) |
| Config cache | not cached — `.env` changes take effect without a code deploy |
| PHP SMTP transport | Symfony `EsmtpTransport` + factory available ✓; `openssl` loaded ✓ |
| Egress to Postmark SMTP | TCP connect to `smtp.postmarkapp.com:587` **CONNECTED (~43ms)** ✓ (read-only; nothing sent) |
| TLS peer verification | not disabled (`config/mail.php` verify_peer default-on) ✓ |
| Existing reset/mail hardening | `TransactionalEmailHardeningTest` + `CollectorPasswordRecoveryTest` present and part of the deployed suite (last full gate 1320 passed); reset architecture unchanged |
| App health | `GET /admin/login` → 200 (loopback) |
| Sending-domain DNS slot | `send.secondchanceauthenticators.com` has **no** A/TXT records; apex has **no MX** — clean to receive Postmark DKIM/Return-Path without disturbing existing routing |
| Existing DMARC | `_dmarc.secondchanceauthenticators.com` = `v=DMARC1; p=quarantine; adkim=r; aspf=r; rua=mailto:dmarc_rua@onsecureserver.net` — relaxed alignment means a verified Postmark DKIM/Return-Path on the send subdomain can achieve DMARC pass |

### BLOCKERS (owner action required — must not be fabricated)
1. **No Postmark account / Transactional stream / SMTP Token.** Production `app/.env` contains only `MAIL_MAILER`, `MAIL_FROM_ADDRESS`, `MAIL_FROM_NAME` keys; no `MAIL_HOST`/`MAIL_PORT`/`MAIL_USERNAME`/`MAIL_PASSWORD`, no `POSTMARK_*`. The effective `smtp.host` is the framework default `smtp.mailgun.org` and SMTP username/password are **unset**. No Postmark credential exists and none may be invented.
2. **No verified sender identity.** `MAIL_FROM_ADDRESS` is empty → falls back to the placeholder `no-reply@localhost`. The proposed `no-reply@send.secondchanceauthenticators.com` is **not** owner-approved or Postmark-verified; no DKIM signature/Return-Path is configured.
3. **DNS authority unavailable / discrepancy.** Authoritative nameservers for `secondchanceauthenticators.com` are `ns55.domaincontrol.com` / `ns56.domaincontrol.com` (**GoDaddy / Secureserver**), and the existing DMARC `rua` points to `onsecureserver.net`. This contradicts the project note that DNS is at Namecheap; the Namecheap connector available in this environment is **not** authoritative for this domain. No GoDaddy/Secureserver DNS credentials are available here, so the required DKIM TXT + Return-Path CNAME cannot be published.
4. **No authorized safe test recipient inbox / test collector.** Phase 2 requires a non-production mailbox the owner authorizes for a real delivery proof and an authorized test collector account for the end-to-end reset lifecycle. Neither is provided.
5. **Sender/domain decision not recorded.** The owner must confirm the sending identity (default proposal `no-reply@send.secondchanceauthenticators.com`) before any DNS change; MX and unrelated DNS must not be modified.

## Precise owner action list (to unblock Phase 1)
1. Provision a **Postmark** account with a **server + Transactional message stream**, enable **SMTP**, and create a **scoped Transactional-stream SMTP Token** (access key = username, secret key = password). Provide it via a secure channel — do not paste it into chat, code, logs, or governance.
2. Confirm the **sending domain/identity** (default proposal `send.secondchanceauthenticators.com`, from `no-reply@send.secondchanceauthenticators.com`), or state an alternative.
3. Confirm **DNS management authority** for `secondchanceauthenticators.com`. It currently resolves to **GoDaddy/Secureserver** nameservers, not Namecheap. Provide the means to publish exactly the **Postmark-generated DKIM TXT and custom Return-Path CNAME** (plus optional SPF if Postmark requires) on the send subdomain. Do not change MX or existing records.
4. Designate an **authorized test inbox** (non-production) and an **authorized test collector account** for the isolated delivery + reset-lifecycle proof.
5. Authorize a **change window** for the eventual Phase 3 production cutover.

## Invariants preserved (nothing changed)
Production stays at `9cf7272` / migration 138; `MAIL_MAILER=log`; no code/DNS/config/Caddy/Shopify-OAuth(`read_orders`)/Stripe(dormant)/schema change. The password-reset broker, token hardening, trusted-`APP_URL` origin, TLS peer verification, and provenance all remain as audited. No secrets, reset tokens, collector emails, or reset links are recorded in this document.

**STOP — Phase 0 BLOCKED. Awaiting ChatGPT activation audit and owner provisioning of the prerequisites above. Phase 1 will not begin, and SMTP will not be activated, until those are supplied. No other initiative started.**

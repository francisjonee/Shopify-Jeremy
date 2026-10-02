# SCA Production Email — provider selection + implementation plan (AUDIT/PLAN ONLY)

**Date:** 2026-10-02 · **Production baseline:** main `dff2781`, migrations **120**.
**Status: AUDIT / PLANNING ONLY — zero changes made. For ChatGPT + operator review before implementation.**
**ACTIVE / NEXT_TASK remain unpromoted. Nothing signed up for, no credentials assumed.**

Goal: move SCA from `MAIL_MAILER=log` to a real transactional-email provider so **Admin and Collector
Forgot/Reset Password** work reliably. This is **system/transactional** mail only — **separate from the
Shopify storefront and Mailchimp marketing**; those stay untouched.

**Hard boundaries honored (verbatim):** no `app/.env` change, no DNS change, no email sent, no provider
account created, no password create/reset, no DB write, no Shopify/Mailchimp change, no Caddy/firewall/Docker
change, public `:8080` stays retired, no QR/cert/auth/ownership/gallery/provenance touch.

Builds on `SCA-PRODUCTION-EMAIL-SMTP-AUDIT.md` (gov `bde2f27`) and `SCA-PRODUCTION-CUTOVER-SMTP-READINESS-AUDIT.md`
(gov `ff0e481`). See [[report-to-github-first]].

---

## 0. Confirmed current state (read-only, this session)

- Mailer = **`log`** (`app/.env MAIL_MAILER=log`); nothing delivered externally.
- From = **placeholder** `no-reply@localhost` / name `SCA`. `QUEUE_CONNECTION=sync`; the reset notifications
  are **not `ShouldQueue`** → synchronous, **no queue worker needed**.
- App URLs = `https://verify.secondchanceauthenticators.com` (reset links HTTPS, Phase-B Secure-cookie safe,
  60-min single-use tokens, enumeration-safe).
- **Mail transports available with zero new dependency:** `config/mail.php` defines `smtp, ses, mailgun,
  postmark, sendmail, log, array, failover`. **`symfony/mailer` (SMTP) is installed; the API-driver packages
  (`symfony/postmark-mailer`, `symfony/mailgun-mailer`, `resend/resend-php`, SES via `aws-sdk`) are only
  composer "suggest" entries — NOT installed.** ⇒ **Using a provider over its SMTP interface needs NO
  composer change** (smallest, safest path). An API driver would add a prod dependency + a governed rebuild.
- `config/services.php` already has `mailgun`/`postmark`/`ses` env-key stubs (unused while on SMTP).
- **DNS baseline (read-only `nslookup`, nothing changed):** apex A → **Shopify 23.227.38.32** (do NOT touch);
  **no apex MX; no apex SPF (`v=spf1`) TXT**; `_dmarc.secondchanceauthenticators.com` =
  `v=DMARC1; p=quarantine; adkim=r; aspf=r; rua=mailto:dmarc_rua@onsecureserver.net` (GoDaddy/Secureserver);
  **no `mail`/`mg`/`pm`/`em` subdomain exists**. Relaxed alignment (`adkim=r/aspf=r`) ⇒ **DKIM aligned to the
  org domain or any subdomain satisfies the existing DMARC.**
- `config/mail.php smtp` block uses legacy keys: `MAIL_HOST`, `MAIL_PORT`, **`MAIL_ENCRYPTION`** (not
  `MAIL_SCHEME`), `MAIL_USERNAME`, `MAIL_PASSWORD`; `from` reads `MAIL_FROM_ADDRESS`/`MAIL_FROM_NAME`.
  (Note: the smtp block ships `verify_peer => false` — a Krayin default; flagged as a latent TLS-hardening
  item, **out of scope** here, do not change without a separate task.)

---

## 1. Provider recommendation

**Recommended: Postmark (transactional), via its SMTP interface.** Rationale against the stated priorities:

| Priority | Postmark | Amazon SES (alt) | Mailgun / Resend / Brevo (alt) |
|---|---|---|---|
| Reliable password-reset delivery | **Best-in-class** transactional reputation; separate Transactional vs Broadcast message streams keep reset mail off any marketing reputation | Very good, but you own bounce/complaint handling + reputation warmup | Good; Mailgun/ Resend fine, Brevo mixes marketing |
| Laravel SMTP compatibility | **Trivial** — SMTP host + token; no composer change | SMTP works (IAM-derived SMTP creds); no composer change | SMTP works; no composer change |
| SPF/DKIM/DMARC support | First-class domain auth (DKIM + custom Return-Path), clear dashboard records | Full (DKIM 3×CNAME + custom MAIL FROM), more manual | Full |
| Cost at low volume | Free dev (100/mo), then ~$15/mo (10k) — **predictable** | **Cheapest at scale** (~$0.10/1k) but sandbox + ops overhead | Mid; Resend has a small free tier |
| Scale later | Easy stream/plan bump | **Best raw scale/cost** | Fine |
| Simple ops/maintenance | **Highest** — minimal moving parts, great deliverability UX | Lowest (sandbox approval, suppression, region) | Medium |

**Verdict:** for low-volume, deliverability-critical **password-reset** mail with minimal ops, **Postmark over
SMTP** is the best fit and the smallest change. **Amazon SES over SMTP** is the recommended alternative if the
operator prioritizes lowest cost at scale and accepts the extra setup (sandbox exit, bounce handling).
**Either choice is SMTP-only → no code/composer change**, keeping the activation a pure `.env` + DNS exercise.

*(No account will be created and no credentials are assumed; the operator selects and provisions the provider.)*

## 2. Sender identity

Proposed: **From name `Second Chance Authenticators`**, **From address `no-reply@secondchanceauthenticators.com`**.

- **Appropriateness:** acceptable, with one decision for the operator. The From **domain must be verified at
  the provider**; the local-part `no-reply` is arbitrary. Under Postmark (and SES), production sending uses
  **domain verification (DKIM)** — so **`no-reply@secondchanceauthenticators.com` does NOT need to exist as a
  real mailbox.** (A real mailbox is only required if you use Postmark's *single Sender Signature* flow, which
  confirms via a click to that address — **not recommended**; verify the domain instead.)
- **Apex vs dedicated sending subdomain — operator decision (recommend subdomain):**
  - **Apex `secondchanceauthenticators.com`** (as proposed) works, BUT the apex is a **live Shopify store** and
    may already be an email sender. If anything already sends *as* `@secondchanceauthenticators.com`, the apex
    SPF must list **all** senders, raising fragility and risking Shopify/Mailchimp alignment.
  - **Dedicated subdomain**, e.g. **`no-reply@send.secondchanceauthenticators.com`** (or the provider's
    convention), **isolates** SCA's SPF/DKIM/Return-Path from the Shopify apex and the `verify.` app host, and
    is still covered by the existing org-level `p=quarantine` DMARC via relaxed alignment. **Recommended for
    cleanliness and zero Shopify/Mailchimp risk.** The displayed From can still read "Second Chance
    Authenticators"; only the domain part differs.
  - **If the apex is chosen:** operator must first confirm (Shopify admin / current DNS) whether Shopify or
    Mailchimp send *as the apex*; if so, the apex SPF must `include:` both the existing sender(s) and the new
    provider. **No SPF edit may remove or break existing Shopify/Mailchimp authentication.**
- **Reply-To:** set a monitored address (e.g. `support@secondchanceauthenticators.com`) only if such a mailbox
  exists; otherwise omit. Bounces go to the provider-managed **Return-Path**, not a human inbox.

## 3. Provider + DNS setup plan (operator performs later; values come from the real account)

**Do NOT invent DNS values.** The exact DKIM selector/key and Return-Path host are generated in the provider
account and must be copied **verbatim** into GoDaddy DNS. This section lists the record *types/roles*.

**At the provider (Postmark example; SES analog noted):**
1. Create a Server with a **Transactional** message stream (SES: create a sending identity).
2. Add and verify the **sending domain** (apex or `send.` subdomain per §2) — **domain verification, not a
   single-sender mailbox**.
3. Obtain the provider-generated **DKIM** record and the **custom Return-Path / bounce** record from the
   account dashboard. Obtain the **SMTP host + credentials** (Postmark: host `smtp.postmarkapp.com`, and the
   **Server API Token is used as BOTH the SMTP username and password**; SES: SMTP endpoint
   `email-smtp.<region>.amazonaws.com` + IAM-derived SMTP username/password — *distinct from AWS access keys*).

**DNS records to publish at GoDaddy for the chosen sending domain (exact values from the provider):**
- **DKIM** — a `TXT` (or `CNAME`, per provider) at the provider's selector host
  (e.g. `<selector>._domainkey.<sending-domain>`). **Required** — this is what gives DMARC alignment under the
  existing relaxed policy. *(SES: 3 × `CNAME`.)*
- **Return-Path / bounce (SPF alignment of MAIL FROM)** — a `CNAME` at the provider's bounce host
  (Postmark: `pm-bounces.<sending-domain>` → provider target; SES: a custom **MAIL FROM** subdomain needing an
  `MX` + an SPF `TXT`). Recommended so SPF *aligns* in addition to DKIM.
- **SPF** — a `TXT` `v=spf1 … -all` on the sending domain that `include:`s the provider
  (Postmark: `include:spf.mtasv.net`; SES: `include:amazonses.com`). If an SPF TXT already exists on that
  exact name, **merge** the include into the single existing record (one SPF TXT per name) — **do not add a
  second** and **do not drop existing Shopify/Mailchimp includes** if the apex is used.
- **DMARC** — **no change required**; the existing apex `p=quarantine; adkim=r; aspf=r` already covers the org
  domain and subdomains, and DKIM alignment will pass. *(Optional later: add an SCA-monitored `rua=` or a
  subdomain `_dmarc.send` policy — out of scope here.)*
- **Apex A / Shopify / Mailchimp / `verify.` A record** — **untouched.**

**Verification gate (operator):** provider dashboard shows the domain **Verified / DKIM active / Return-Path
confirmed** before any send. Independently confirm with public DNS (`dig TXT <selector>._domainkey.<domain>`,
`dig CNAME pm-bounces.<domain>`) that the records resolve.

## 4. Laravel configuration plan (exact `app/.env` `MAIL_*` — NO real values yet)

Target mailer = **smtp** (zero composer change). Edit **`app/.env`** (the container `/var/www/html/.env` —
the file Laravel reads; the repo-root `/opt/sca-platform/.env` is compose-only and must NOT be used for this):

```
MAIL_MAILER=smtp
MAIL_HOST=<provider SMTP host>            # Postmark: smtp.postmarkapp.com | SES: email-smtp.<region>.amazonaws.com
MAIL_PORT=587                             # STARTTLS submission
MAIL_ENCRYPTION=tls                       # legacy key this Krayin config reads (NOT MAIL_SCHEME)
MAIL_USERNAME=<provider SMTP username>    # Postmark: Server API Token | SES: IAM SMTP username — placeholder, entered by operator
MAIL_PASSWORD=<provider SMTP password>    # Postmark: same Server API Token | SES: IAM SMTP password — SECRET, never printed/committed/logged
MAIL_FROM_ADDRESS=no-reply@secondchanceauthenticators.com   # or no-reply@send.secondchanceauthenticators.com per §2
MAIL_FROM_NAME="Second Chance Authenticators"
```

- **Credentials are entered by the operator at activation**, never placed in this doc, git, logs, or chat.
- **Keep `QUEUE_CONNECTION=sync`** — reset notifications are synchronous and not `ShouldQueue`; **no worker**.
- **Preserve unchanged:** `APP_URL=https://verify.secondchanceauthenticators.com`; `SESSION_SECURE_COOKIE=true`
  + `session.domain` unset (Phase B); loopback-only `127.0.0.1:8080`; `SCA_PUBLIC_PREVIEW=0`;
  `TRUSTED_PROXIES=172.20.0.0/24`; all authentication/reset-token behavior and broker config.
- **No code change** (no controller/notification/route/migration edit); this is `.env`-only.
- Apply with `config:clear` (the deploy path uses `config:clear`, not `config:cache`). **No container rebuild
  or recreate** is required for an `.env`-only change read at runtime — but confirm the running container
  re-reads env (a code-only deploy does not recreate kr-app; an `.env` value change is picked up on
  `config:clear` since config is not cached). **Back up `app/.env` first** (e.g. `app/.env.mail.bak`, mode 0600).

## 5. Controlled activation plan (strict order — HALT between stages)

1. **Provider + domain setup** (§3) — create server/stream, add + verify the sending domain.
2. **DNS authentication** — publish provider DKIM + Return-Path (+ merged SPF) at GoDaddy. *(No DNS done in
   this task.)*
3. **Verify DNS** — provider shows Verified/DKIM active/Return-Path confirmed **and** public `dig` confirms the
   records resolve. **Do not proceed until green.**
4. **Configure Laravel mailer** — back up `app/.env`; set the §4 `MAIL_*` with the real SMTP host + operator's
   credentials; keep everything in "preserve unchanged".
5. **Reload config** — `php artisan config:clear` (run as uid 33:33 to avoid root-owned cache files — known
   deploy gotcha). Confirm `config('mail.default')=smtp` and `mail.from.address` correct via a read-only tinker
   (do **not** print the password).
6. **One harmless test email** — send a single `Mail::raw('SCA SMTP connectivity test '.now(), fn($m)=>
   $m->to('<operator-controlled inbox>')->subject('SCA SMTP connectivity test'))` via tinker. **This uses no
   broker, creates NO password-reset token, and modifies NO account.** Not to any real collector/admin.
7. **Inspect delivery** — confirm receipt at the operator inbox; verify headers show **SPF=pass, DKIM=pass,
   DMARC=pass** and correct From/display-name; cross-check the provider dashboard for an Accepted/Delivered
   event + message-id. Capture only message-id/status/recipient/From — **never** the credential.
8. **Only then** test the real **Forgot Password** flow — ideally against a **throwaway test account** the
   operator controls (seeding/removing a test account is a separate, explicitly DB-write-authorized step);
   confirm the reset email arrives with an `https://verify.secondchanceauthenticators.com/…/reset-password/{token}`
   link, Secure-cookie-compatible. **Do not reset a real operator's password.**

**Rollback (any stage):** restore `MAIL_MAILER=log` (and the rest of `app/.env` from the backup) →
`php artisan config:clear` (uid 33:33). Mail returns to log-only; **no domain data touched, no migration, no
DB write, fully reversible.** DNS records, if already published, are harmless to leave (they only authorize
the provider) and can be removed by the operator separately.

---

## 6. Summary & recommendation

- **Provider:** **Postmark over SMTP** (primary) for reliable, low-ops password-reset delivery with no composer
  change; **Amazon SES over SMTP** the cost/scale alternative. SMTP transport → **no code/dependency change**.
- **Sender:** verify the **domain** (no mailbox needed for `no-reply@…`); **recommend a dedicated
  `send.` subdomain** to isolate from Shopify/Mailchimp, apex acceptable only after confirming it isn't already
  an active sender and merging SPF safely.
- **DNS:** publish provider **DKIM** + **Return-Path** (+ merged **SPF**) for the sending domain; **DMARC
  unchanged** (existing `p=quarantine` relaxed covers it via DKIM alignment). **No invented values** — copy
  from the real account.
- **Laravel:** `.env`-only `MAIL_*` switch to `smtp` (exact keys in §4); preserve APP_URL / Phase-B Secure
  cookies / loopback :8080 / reset behavior; `QUEUE_CONNECTION=sync` (no worker).
- **Activation:** strict order in §5; first test is a credential-free, token-free `Mail::raw` to an operator
  inbox proving SPF/DKIM/DMARC pass; real Forgot-Password only after, and only against a throwaway test
  account; full rollback to `log`.

**No GO requested. PLAN ONLY — zero changes. Awaiting ChatGPT + operator review; ACTIVE/NEXT_TASK remain
unpromoted. Nothing implemented; no `.env`/DNS/account/credential/DB/Shopify/Mailchimp/infra change.**

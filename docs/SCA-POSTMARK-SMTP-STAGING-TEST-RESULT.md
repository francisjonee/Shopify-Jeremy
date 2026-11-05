# SCA — Postmark SMTP Staging Test (RESULT, testing only)

**Live transactional email through Postmark SMTP works. In the isolated staging environment (test
integration `ce1f8da`, disposable `sca_domain_test` DB with production barred by grant, mocked Shopify),
the dedicated Postmark SMTP credentials authenticated over STARTTLS on `smtp.postmarkapp.com:587`, and one
authorized non-sensitive test message was sent to Postmark's official sink `test@blackhole.postmarkapp.com`
and accepted by Postmark (SMTP server id `3CF6040F145`, 250/no error). The SCA verification-link and
ownership-claim logic were separately validated with simulated email (array transport) against disposable
accounts — 38/38 tests green. Production and Shopify were not touched: live tree stayed at `e3f73f8b`, the
prod DB fingerprint is unchanged (items 208, sale_links 1, migrations 146, 0 secure-claim tables), and no
Shopify API call was made. The disposable staging environment was securely torn down afterward; no
credentials were displayed, logged, committed, or exposed.** The account remains in Postmark **Test mode**,
so this does not prove delivery to a real external mailbox, and production email settings were NOT changed.
2026-11-05. **STOP.**

> Written for: the owner (Jeremy) and the external auditor. Software testing only; no production email
> configuration was changed.

## Results
| Step | Result |
|---|---|
| SMTP connectivity (TLS/STARTTLS) | ✅ `smtp.postmarkapp.com:587`, valid cert (verify code 0), `250 DSN` |
| SMTP authentication | ✅ dedicated SMTP Access/Secret key (from `/root/postmark-staging.env`) authenticated; AUTH-only probe sent no mail |
| Single authorized send | ✅ to `test@blackhole.postmarkapp.com` only; **accepted** by Postmark, server id `3CF6040F145`, no SMTP error/synchronous bounce |
| Postmark Activity classification | ⚠️ not retrievable here — requires the Postmark dashboard or a Server API token (not provided). The sink always classifies as *Delivered*, which per instruction is NOT treated as proof of real-mailbox delivery. Owner can look up server id `3CF6040F145` in the Postmark Activity UI |
| Verification-link + claim logic (simulated email) | ✅ 38/38: single-use token request/confirm, invalid/expired token fails generically, unverified buyer → no ownership, verified-matching buyer → claim succeeds, public-QR claim retired (410), fulfillment-release ACL enforced, verified-buyer + trusted-order-email gate fail-closed |
| Production / Shopify | ✅ unchanged — tree `e3f73f8b`; prod DB items 208 / sale_links 1 / migrations 146 / 0 secure-claim tables; zero Shopify API calls |

## Environment & isolation
- Staging on test integration `ce1f8da` in a disposable worktree; runner from `sca-app:krayin-2.2.6`, app
  mounted read-only + overlay volumes.
- Disposable DB `sca_domain_test` + restricted user — production `sca_krayin` denied (ERROR 1044);
  Shopify credentials fake and never called.
- Network: internal/no-egress in steady state; outbound egress attached ONLY for the two brief Postmark
  windows (the AUTH probe and the single send), then detached. General egress is open during those windows
  (Docker NAT), but the only outbound initiated was to Postmark; strict network-level Postmark-only egress
  would require host firewalling, which was deliberately not applied to this shared production host.
- Credentials read from the root-only `0600` file at runtime; the AUTH/SMTP debug transcript was
  deliberately NOT printed (it contains the AUTH exchange).

## Cleanup
Runner, disposable DB + user, internal network (prod DB detached), overlay volumes, worktree, and the
temporary DB password file were all removed. `/root/postmark-staging.env` (owner-managed, `root:root 600`)
was retained for future tests; the owner may delete it when finished.

## Remaining before real-world launch (unchanged by this test)
- **Postmark account is in Test mode** → approval/allow-listing needed before sending to real customer
  domains; no SCA-readable mailbox exists yet to confirm true inbox delivery.
- **Production email is still NOT configured** (prod `MAIL=log`); this test changed only the disposable
  staging `.env`. Activating email in production is a separate, owner-authorized step tied to the
  secure-claim release (SPF/DKIM already verified for the sending domain per the owner).
- Secure buyer claiming remains undeployed (this test did not deploy or activate it).

## Safety posture (this task)
One authorized message to the Postmark sink only; no real customer email. No production DB write; no
production email-settings change; no Shopify API request/change; no deployment or migration against
production; secure claiming not activated; credentials never displayed/logged/committed. Production
unchanged at `e3f73f8b`; disposable staging torn down.

**STOP — Postmark SMTP staging test complete: connectivity ✅, authentication ✅, one authorized send to
`test@blackhole.postmarkapp.com` accepted (server id `3CF6040F145`); verification-link + claim logic 38/38
green with simulated email. Activity-level delivery classification needs the Postmark dashboard / a Server
API token (not available here) and the sink's Delivered status is not proof of real delivery. Production
and Shopify unchanged; staging securely cleaned up; account still in Test mode; production email NOT
configured; secure claiming NOT deployed.**

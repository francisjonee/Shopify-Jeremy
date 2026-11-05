# SCA — Real-Inbox Email-Verification Test: Preparation & Recommended Path (read-only)

**The simplest safe way to test actual SCA verification-email delivery on the existing free Postmark
account is to stop trying to receive at the SCA domain (which has no MX and would need a DNS change) and
instead deliver to an inbox the owner already controls. Two owner actions, neither touching DNS,
mailboxes, or Shopify, do this: (A) add that existing inbox as a Postmark Sender Signature — its
confirmation email is itself the first real-inbox delivery proof and makes the address a permitted
recipient while the account is still pending; and (B) submit the one-click Postmark account-approval
request (reviewed in under ~24h on weekdays), after which Postmark can send to any recipient with no
further setup. Receiving at an `@secondchanceauthenticators.com` address is NOT possible without adding an
MX record (the apex currently has none) plus a mailbox/forwarding service — a DNS change that needs
separate authorization; it would not disrupt Shopify, but it is the heaviest option and only needed if an
on-domain recipient is specifically required. This task made no changes: read-only, no email sent, no DNS/
Shopify/production/credential changes.** 2026-11-05. **STOP.**

> Written for: the owner (Jeremy) and the external auditor. Advisory only — recommends owner actions; does
> not perform them.

## 1. Postmark Test-mode / pending-approval recipient restriction (official)
Per Postmark's own article *"How does the account approval process work"* (1084): until the account is
approved, you **"won't be able to send to any email address outside the domains you've added to your
account and verified."** Only the Account Owner can submit the approval request; review completes in
**under 24 hours on weekdays** (a little longer on weekends). The sink `test@blackhole.postmarkapp.com`
is always allowed (and is dropped on receipt — not proof of real delivery).
- So while pending, the **guaranteed** allowed recipients are addresses on the **verified domain**
  (`secondchanceauthenticators.com`). Multiple secondary sources (and the Error-412 guidance) also allow
  **confirmed Sender Signature** addresses as recipients; Postmark's official article mentions only
  verified domains, so treat the Sender-Signature route as highly likely but not officially guaranteed.

## 2. Can an existing external mailbox receive while in Test mode?
Not an arbitrary one (e.g. a plain Gmail) — it's neither on the verified domain nor a confirmed sender, so
it is blocked until approval. **But** an external mailbox the owner controls can be made eligible in one
of two no-DNS ways:
- **Confirm it as a Sender Signature** (Path A) → it becomes an allowed recipient while pending, and the
  confirmation email Postmark sends to it is a live delivery test in itself.
- **Get the account approved** (Path B) → after approval, any external mailbox works.

## 3–4. Receiving at the SCA domain, and the MX / forwarding question
- **Live DNS (read-only):** `secondchanceauthenticators.com` has **no MX** and no apex SPF TXT; the
  Postmark **Return-Path is verified** (`pm-bounces.secondchanceauthenticators.com` → `pm.mtasv.net`), and
  DKIM is verified per the owner. Sending is set up; **receiving is not**.
- **Forwarding without changing MX: not possible.** Inbound mail requires an MX record, and the apex has
  none — any forwarding service (ImprovMX, Cloudflare Email Routing, etc.) requires you to publish its MX
  (and usually an SPF TXT). So "forward without modifying MX" cannot be done.
- **Would adding an apex MX disrupt Shopify? No.** Shopify's order/transactional email is sent from
  Shopify's own infrastructure and does not depend on this domain's inbound MX; the store runs on its
  Shopify/`myshopify.com` domain, and the SCA app lives on the `verify.` subdomain — none use the apex for
  inbound mail. The apex MX is empty today, so there is no existing inbound routing to break, and adding an
  MX is independent of the existing Postmark DKIM/Return-Path CNAMEs. **However, it is still a DNS change
  and requires separate authorization** (and is the heaviest path).

## 5. Minimal configuration for one real-inbox test (already proven; ready to reuse)
No new configuration is required beyond the recipient address — the isolated staging path already
authenticated and sent to the sink successfully (gov `a875554`). For the real-inbox run I will reuse it
exactly: disposable `sca_domain_test` DB (production barred by grant), mocked Shopify, `MAIL=smtp`
→ `smtp.postmarkapp.com:587` STARTTLS, from `no-reply@secondchanceauthenticators.com`, credentials from
the root-only `/root/postmark-staging.env`, egress opened only for the single send. The sole change is the
**recipient** = the approved inbox from Path A or B. I would then send one real `CollectorEmailVerification`
message, confirm receipt, click the verification link, and confirm the claim is gated on
`email_verified_at` — all in staging, no production change.

## Recommended path (simplest, safest, free account)
1. **Do both A and B now — neither touches DNS, mailboxes, or Shopify:**
   - **(A) Immediate, test today:** Postmark → *Sender Signatures* → *Add Sender Signature* → enter an
     inbox the owner already reads → click the confirmation link Postmark emails to it. That arrival is the
     first real-inbox delivery proof, and the address becomes a permitted recipient while pending.
   - **(B) Remove the restriction entirely (~24h):** Postmark → request **account approval** (Account Owner
     only), describing the transactional use (customer email verification for ownership claims). After
     approval, any recipient works with no further setup.
2. Tell me the approved recipient address; I run the one real-inbox verification test in the isolated
   staging environment and report delivery + link + claim-gating.
3. **Only if an `@secondchanceauthenticators.com` recipient is specifically required** (Path C, last
   resort, needs separate DNS authorization): add an apex **MX** + a free forwarder (e.g. Cloudflare Email
   Routing) forwarding `test@secondchanceauthenticators.com` → the owner's inbox, without overwriting the
   existing Postmark CNAMEs. This is the only option that changes DNS.

## Limitations / notes
- Sink `Delivered` is not proof of real-mailbox delivery (confirmed with the owner previously).
- Approval is occasionally rejected (anecdotal); if so, respond to Postmark support with the use case.
- Free Postmark allows a limited number of messages while pending (~100) and the free developer tier is
  low-volume (~100/month — verify current pricing); fine for verification testing, but production
  transactional volume will likely need a paid plan. Separate from this test.
- Production email remains `MAIL=log`; nothing here activates production email or secure claiming.

## Safety posture (this task)
Read-only. No email sent; no Shopify API call or change; no production DB write; no DNS change; no SMTP
credential displayed; no deployment or migration; secure claiming not activated. Production unchanged at
`e3f73f8b`. Only read-only DNS lookups and official-doc review were performed.

**STOP — Recommended: deliver the real-inbox test to an inbox the owner already controls, via (A) adding it
as a confirmed Postmark Sender Signature (immediate, its confirmation email is the delivery proof) and/or
(B) the one-click account-approval request (<~24h, then any recipient). Both avoid DNS, mailboxes, and
Shopify. Receiving at `@secondchanceauthenticators.com` needs an apex MX (none today) + forwarder = a DNS
change requiring separate authorization (would not disrupt Shopify) and is the last resort. Minimal
staging config already proven (gov a875554) — only the recipient changes. No changes made this task.**

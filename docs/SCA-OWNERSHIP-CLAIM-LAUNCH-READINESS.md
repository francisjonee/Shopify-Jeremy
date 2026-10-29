# SCA — Ownership Passport Customer Claim: Launch Readiness (READ-ONLY)

**Question: what remains before a customer who buys from Second Chance Eyewear can scan their QR,
register, and securely claim ownership in SCA?** Short answer: the customer-facing shell (register /
login / My Collection / Passport / transfer) and the staff inventory+assignment workflow are LIVE, and
the secure verified-buyer claim logic (R0/R0b/R0c) is written, tested (77/77), and merged — but it is
**NOT deployed**, it sits on a **divergent branch** from production, and it is **BLOCKED on operational
email delivery**. The currently-deployed claim path is the pre-R0 public-token flow (GAP-1, latent).
Read-only at prod `4faf84d`; no API/DB write/merge/deploy/email change. 2026-10-29. **STOP.**

## The required journey (Jeremy's goal)
Buy at Shopify → scan QR → register/login collector account → **securely** claim ownership (only the
genuine buyer). After claim, owner can transfer to another collector.

## [1] Deployed customer-facing surfaces — COMPLETE (prod `4faf84d`)
- Collector **registration / login** (`/collector/register`, `/collector/login`), **My Collection**
  (`/collector/collection`), item detail, **public Passport** `/p/{token}` (mobile, safe DTO — no PII/
  token/path), and **ownership transfer** (`/collector/collection/{ref}/transfer` + accept) are all
  routed and deployed. 4 collector accounts exist.
- The transfer-status-clarity UX (pending banner + confirmations) is deployed.

## [2] Undeployed secure-claim implementation (R0/R0b/R0c) — CODE COMPLETE, NOT DEPLOYED
- On `origin/main` (`a397a7e`): **R0** retires public-token claiming (`ClaimWorkflow::claim` →
  `PUBLIC_CLAIM_RETIRED`); **R0b** adds the private, fulfillment-release-gated presale grant
  (`sca_presale_claim_grants`); **R0c** adds the verified-buyer gate (claimant's **verified** collector
  email must match the **trusted** Shopify order email) + `sca_collector_email_verifications` +
  `order_email` on sale links. Combined regression previously GREEN (77/77). 4 additive migrations.
- **It is NOT in production.** The live tree (`4faf84d`) contains **none** of the R0c files, and prod
  DB has **none** of the R0c tables/columns.

## [2a] ⚠️ KEY FINDING — the two code lines have DIVERGED (common ancestor `cb8a8c3`)
- `origin/main a397a7e` = R0/R0b/R0c + transfer-status — **but NOT** the order→eyewear assignment,
  Administrator perm-fix, rc21, or QR-copy fix.
- Production line `4faf84d` = transfer-status + order-assignment + perm-fix + rc21 + QR-copy — **but
  NOT** R0/R0b/R0c.
- Verified: `OrderItemAssignmentService` is absent on `origin/main`; `PresaleClaimGrantService` is
  absent on `4faf84d`. So **R0/R0b/R0c must be reconciled onto the deployed prod line** before launch —
  they cannot simply be "deployed" from `origin/main` without also reverting the live order-assignment/
  QR features. This is an outstanding integration task (both lines descend from `cb8a8c3`; the file
  sets are largely disjoint — Claim/Provenance claim-side vs the Shopify package — so a merge is
  expected to be clean but must be re-tested combined).

## [3] Dependencies for a secure claim of a purchased pair
1. An **eligible sale link** binding the purchased order line → the exact physical pair. Produced by the
   deployed **staff order→eyewear assignment** (live) or storefront `sca_item_ref` injection (not
   built). *(Today: 0 eligible sale links in prod — 1 `revoked_refund`.)*
2. **R0** deployed — so the public QR token is NOT a claim credential.
3. **R0b** deployed — private grant gated on staff fulfillment-release.
4. **R0c** deployed — verified-buyer gate.
5. **Email verification delivery** — so the collector can prove control of an email, and it can be
   matched to the trusted order email. *(Today: MAIL=`log`, no provider.)*
6. **order_email** present on the sale link (R0c propagation for new orders + backfill for existing).
7. **ACL** `sca.eyewear.fulfillment.release` granted to the right staff role.
8. The R0/R0b/R0c code reconciled onto the prod line + deployed (migrate-before-code, 4 additive
   migrations).

## [4] Does the DEPLOYED implementation fully support the journey? — NO
- Deployed prod supports register/login/My Collection/Passport/transfer **and** the staff inventory
  pipeline (register → authenticate → certify+QR → print label → link variant → assign order). But the
  **secure verified-buyer claim is not deployed.**
- The only deployed claim path is the **pre-R0 public-token flow**: `ClaimWorkflow::claim(token,
  collector)` → if the item has an *eligible* sale link → `openShopifyClaim` → ownership, with **no
  buyer verification** (GAP-1). It is **latent** today (0 eligible sale links), but the moment a genuine
  sale creates an eligible link, that pair becomes claimable by **any** signed-in collector holding the
  passport token — not necessarily the buyer. **Launching claims on the deployed code as-is would expose
  GAP-1.** R0/R0b/R0c exist precisely to close this and must ship first.

## [5] Email verification + secure alternatives (no weakening)
- R0c's gate requires the claimant to **prove control of an email** that matches the Shopify order's
  **trusted** email (never a customer-typed field). The designed mechanism is a one-time email challenge
  — which needs a working transactional email path.
- **Current status: BLOCKED.** `MAIL_MAILER=log`, `from=no-reply@localhost`, no provider token; DNS is
  at GoDaddy/Secureserver (a Postmark `pm` DKIM selector is already present; **SPF absent**). The app
  already supports the `postmark` mailer (no raw SMTP needed).
- **Secure alternatives that do NOT weaken buyer verification:**
  1. **(Recommended, designed path)** stand up a transactional provider (Postmark / SES / Resend) +
     verified sender `no-reply@secondchanceauthenticators.com` + SPF (confirm DKIM/Return-Path). This
     turns on R0c's automated email challenge.
  2. **Staff-mediated manual identity verification** (human-gated fallback): staff verify the claimant
     against the authoritative Shopify order (e.g. buyer presents the order, staff match the order's
     trusted email/identity) and only then release the private grant **bound to that verified buyer**.
     ⚠️ This must still *bind identity* — a bare staff-handed grant with no identity check is exactly the
     R0b bearer-token security hole that R0c was created to close, so a manual path cannot simply skip
     verification; it moves it to a human. Slower, lower-volume.
  3. **(Future)** Shopify customer-account OAuth as proof-of-purchaser — not built; larger effort.
- Email (option 1) is the shortest secure path; it does not weaken anything.

## [6] Ownership transfer after the initial claim — COMPLETE (deployed)
`TransferWorkflow` (deployed): owner-only initiate, single-use opaque expiring invite, no self-accept,
stale/adverse-status guards, append-only transfer events; plus the deployed transfer-status-clarity UI.
No outstanding work for post-claim transfers.

## [7][8] Prioritized checklist

### ✅ COMPLETE (deployed or code-complete+tested)
- Collector registration / login / account / profile / public profile. *(deployed)*
- My Collection (list + item detail). *(deployed)*
- Public Passport `/p/{token}` — mobile, safety-hardened, PII/token-safe. *(deployed)*
- Ownership transfer after claim + transfer-status UX. *(deployed)*
- Staff inventory pipeline: register → authenticate → certify (mints+activates QR) → print QR label →
  link Shopify variant → **order→eyewear assignment**. *(deployed)*
- Phase-1 Shopify product-webhook catalog sync — verified COMPLETE. *(deployed)*
- R0/R0b/R0c secure verified-buyer claim logic — written, 77/77 combined regression. *(code complete)*

### ⛔ BLOCKED
- **Email verification delivery (THE launch blocker):** no transactional provider / verified sender;
  SPF absent; MAIL=`log`. Until resolved, `email_verified_at` cannot be set in prod → R0c's verified-
  buyer gate is unsatisfiable (fails closed) → **no secure claim is possible**.
- **order_email on sale links:** column exists only on the undeployed R0c line; propagation+backfill
  blocked until R0c deploys.

### 🔲 NOT STARTED (development / deployment / configuration / ops)
- **Reconcile R0/R0b/R0c onto the deployed prod line `4faf84d`** (they currently sit on the divergent
  `origin/main`; a combined branch + re-test is required) — *development/integration*.
- **Deploy R0/R0b/R0c** (migrate-before-code, 4 additive migrations; set `MAIL_MAILER=postmark` + token
  + verified sender; `config:clear` + graceful) — *separately-authorized deploy*.
- **Transactional email provider setup** (provider account, server token, verified sender, SPF + DKIM/
  Return-Path at GoDaddy) — *owner/ops, manual*.
- **Grant the `sca.eyewear.fulfillment.release` ACL** (and the staff order-assign/override ACLs) to the
  appropriate roles — *configuration*.
- **order_email propagation live + backfill run** (near-no-op: 0 eligible legacy rows) — *ops, separately
  authorized*.
- **Real inventory + a genuine paid order** to perform the first real assignment/claim (per the
  eligibility audit, all current eyewear records are test/demo; the one sale link is refunded) —
  *operational*.
- *(Optional, out of SCA code)* storefront `sca_item_ref` injection to auto-create sale links without a
  staff assignment step.

## [9] Shortest safe path to launch
1. **Stand up transactional email** (Postmark recommended — `pm` DKIM selector already present):
   provider account + server token + verified sender `no-reply@secondchanceauthenticators.com` + SPF
   (confirm DKIM/Return-Path) at GoDaddy. *(Clears the launch blocker.)*
2. **Reconcile R0/R0b/R0c onto the prod line** (`4faf84d`): a combined branch off the current prod line
   containing R0/R0b/R0c, then a combined disposable-DB regression (verified-buyer + no-weakening
   checks) GREEN.
3. **Deploy that combined line** under separate authorization: migrate-before-code the 4 additive
   migrations, set `MAIL_MAILER=postmark` + token + verified sender, `config:clear` + graceful (no
   Docker recreate). This also closes GAP-1 (public-token claiming retired).
4. **Grant** `sca.eyewear.fulfillment.release` (+ confirm order-assign/override ACLs) to staff roles;
   enable order_email propagation; run the (near-no-op) backfill.
5. **Controlled end-to-end proof** on a genuine paid order + a real certified pair: staff assign the
   order→pair (variant-linked or manager override) → buyer registers + verifies email → buyer claims →
   exactly one ownership, grant consumed, sale link `claimed`; confirm no non-buyer could claim. Then
   open to customers.

Critical: do **not** launch claims on the current deployed code (GAP-1 public-token path) and do **not**
deploy R0b without R0c (bearer-token hole). The verified-buyer gate (R0c) + email delivery are
non-negotiable for a secure launch.

**STOP — read-only readiness synthesis delivered. The customer shell + staff pipeline + post-claim
transfer are LIVE; the secure claim (R0/R0b/R0c) is code-complete+tested but UNDEPLOYED, on a DIVERGENT
branch, and BLOCKED on operational email delivery. Shortest safe path: email provider → reconcile
R0/R0b/R0c onto the prod line → combined re-test → authorized migrate-before-code deploy (+ ACL/
backfill) → controlled end-to-end proof. No code/DB/Shopify/email/deploy change made.**

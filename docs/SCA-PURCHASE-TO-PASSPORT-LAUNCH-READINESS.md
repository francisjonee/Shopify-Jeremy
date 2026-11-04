# SCA — Shopify Purchase → Customer-Owned Passport: Launch Readiness (read-only)

**Everything from a Shopify purchase up to a physically-labelled, publicly-verifiable QR Passport is
LIVE in production (`e3f73f8b`): catalog mirror, staff order→pair assignment with sale-link
protections, authenticate→certify→QR issuance, QR labels (now with brand/model + fixed-size PDF),
the public Passport, the collector shell + My Collection, and email-free collector-to-collector
ownership transfer. The ONE remaining stage — a BUYER claiming ownership of their purchased pair — is
NOT deployed: the fulfillment-release → private claim link → verified-buyer email gate lives only in the
undeployed secure-claim RC (`f4509f70` / `c9a2d7d`), and its verified-buyer step cannot function until a
transactional-email transport is configured. So the genuine launch blockers are few and specific:
(1) transactional email (SMTP), (2) a separately-authorized deploy of the secure-claim RC
(migrate-before-code, 4 additive migrations), (3) the fulfillment-release ACL grant + order_email
backfill, and (4) the physical operations (per-pair authentication + QR-label printing) plus a first
real paid order/certified pair to exercise end-to-end. Nothing else is missing in code.** Read-only
review; no production change, no Shopify call, no DB write, nothing deployed or activated. 2026-11-04.
**STOP.**

> Written for: the owner (Jeremy) and the external auditor. Baseline: live prod `e3f73f8b`; undeployed
> secure-claim RC `f4509f70` (consolidated) / `c9a2d7d`.

## The complete purchase → ownership workflow
| Stage | What happens | Auto / Staff / Buyer | Status |
|---|---|---|---|
| A. Catalog mirror | Shopify product/variant webhooks sync a read-only catalog mirror (`ProductCatalogService`). | Automatic | **LIVE** |
| A. Inventory intake | Staff CSV-import pairs as UNCERTIFIED items, each atomically variant-linked (the 205 imports). | Staff | **LIVE** |
| B. Sale → SCA item link | A paid Shopify order line is bound to the exact physical pair. Two paths: **(a)** storefront stamps the `sca_item_ref` line property → auto-link on the paid webhook (`SaleLinkEventProcessor`) — INERT today (orders carry no property); **(b)** **staff assignment** (`OrderItemAssignmentService`): staff supply order id + line id + the chosen item's `public_ref`; order facts (paid/cancelled/refunded/line/variant/**order email**) come only from a read-only `getOrder`; match is by `public_ref` ONLY (never variant/SKU/title/customer). | Staff (path b) | **LIVE** |
| C. Authenticate → certify | Staff physically inspect the pair → authenticate (passed + grade) → finalize (typed FINALIZE) → certify (typed ISSUE) → one transaction mints + activates the QR and freezes the certificate snapshot. | Staff + physical | **LIVE** |
| C. QR label | Print the QR label (HTML or the new fixed-size PDF, now showing brand/model + batch #) and affix it. | Staff + physical | **LIVE** |
| C. Public Passport | `/p/{token}` resolves to the PII-free public verification page. | Automatic | **LIVE** |
| D. Release for claim | Staff **fulfillment-release** the `sce_presale` item → issues the buyer's PRIVATE, single-use, time-limited claim link (`FulfillmentReleaseService` + `PresaleClaimGrantService`). | Staff | **NOT DEPLOYED (secure-claim RC)** |
| E. Buyer claim | Buyer scans the QR → public Passport (view-only; public-token claiming retired by R0). To claim they use the PRIVATE link: register/sign in → verify email (single-use link) → claim. **Gate:** the collector's VERIFIED email must match the sale link's TRUSTED Shopify order email (fail-closed). | Buyer | **NOT DEPLOYED (secure-claim RC); needs email** |
| F. My Collection | After a successful claim, the item appears in the buyer's My Collection (image, cert, status). | Automatic | Shell **LIVE**; populated by the undeployed claim |
| G. Resale transfer | Owner initiates a transfer → single-use opaque invite shared out-of-band → recipient signs in + accepts → ownership moves. Append-only history; QR unchanged. | Owner + recipient | **LIVE (email-free)** |

## Task-by-task
1. **Order→inventory association:** live via `OrderItemAssignmentService` (+ `SaleLinkService::linkPaidLine`). Sale ≠ ownership.
2. **Selecting the exact pair:** staff resolve it by the item's unique `public_ref`; a `preview` shows the order's lines (paid/cancelled/refunded, existing `sca_item_ref`, already-linked state) from a read-only `getOrder` before confirming — match is public_ref only, never fuzzy.
3. **Verification / dup / refund / cancel:** order facts come only from the authoritative `getOrder`; eligibility **fails closed** on cancelled / unpaid / refunded-line / unknown-line / unknown-item; `linkPaidLine` enforces one link per (shop, line), never rebinds, and honours refund/cancel (eligibility → not-eligible). Reconciliation (`ShopifyReconciliationService`) is staff-driven, read-only to the store.
4. **Release for verified claiming (RC-only):** staff fulfillment-release (dedicated ACL `sca.eyewear.fulfillment.release`, append-once confirm + POST) issues the buyer's private presale claim link; it creates no ownership itself.
5. **Buyer scan → register → verify → claim (RC-only):** public QR claiming is retired (410); ownership comes only through the private link, gated on a verified buyer email matching the trusted order email. Email verification is a single-use 60-minute link (origin pinned to `APP_URL`).
6. **My Collection after claim:** the collector shell + My Collection are live; a successful claim writes the ownership event that surfaces the item there.
7. **Resale transfer:** live and email-free — owner-only initiate, single-use expiring invite shared out-of-band, recipient accepts after sign-in; strong replay/expiry/self-transfer guards.
8. **Automatic vs staff:** *Automatic* — catalog webhook mirror, sale auto-link IF the storefront stamps `sca_item_ref` (inert today), public Passport, My Collection display, invite expiry. *Staff* — inventory import, order→pair assignment, physical authentication, finalize, certify, QR-label print, fulfillment-release (RC), reconciliation. *Buyer* — register/sign-in, email verify (RC), claim via private link (RC), initiate/accept transfer.
9. **Operational dependencies:** *Authentication* — a qualified staffer physically inspects each pair (the real throughput gate). *QR printing* — a printer + label stock (HTML or the new fixed-size PDF). *Email* — a transactional SMTP transport is REQUIRED for buyer email verification → claiming; issuance and transfer are email-independent. *Backups* — daily encrypted backups present (`/opt/sca-platform/backups`, newest `…20261104…`). *Permissions* — `sca.eyewear.{view, metadata.correct, catalog, authenticate, certify, qr.reissue, shopify.link}` live; `sca.eyewear.fulfillment.release` ships with the RC.
10. **Deployed vs not:** **LIVE (`e3f73f8b`)** — catalog mirror, order→pair assignment + sale links, authenticate→certify→QR + labels (+ identity/PDF), public Passport, collector shell + My Collection, ownership transfer, staff-dashboard safety. **NOT DEPLOYED (RC `f4509f70`/`c9a2d7d`)** — fulfillment-release, presale claim grant, verified-buyer email gate, email verification, and the R0 public-claim retirement. (Verified: the live tree has **zero** fulfillment/claim/email services or routes and **zero** secure-claim tables; they exist only on the RC.)

## Genuine launch blockers (purchase → buyer ownership)
1. **Transactional email (SMTP).** Hard blocker — without delivery the buyer cannot verify their email, so the verified-buyer claim gate is unsatisfiable. (Postmark-via-SMTP preflight done; needs account/token, verified `no-reply@secondchanceauthenticators.com`, SPF+DKIM at GoDaddy. See `SCA-TRANSACTIONAL-EMAIL-READINESS-2026-11-03.md`.)
2. **Secure-claim RC not deployed.** The entire claim path (fulfillment-release → private link → verified-buyer claim, with R0 closing the public-claim GAP-1) is undeployed. Requires separate owner authorization + a migrate-before-code deploy of `f4509f70` (4 additive migrations, batch 31). **Claiming must launch via the RC, not current prod** — current prod still carries the pre-R0 public-token claim path (latent: 0 eligible sale links today), which the RC's R0 retires.
3. **Deploy prerequisites:** grant `sca.eyewear.fulfillment.release` to the issuing staff role; run the idempotent `order_email` backfill (dry-run → `--apply`) for the 1 existing sale link.
4. **Physical operations:** per-pair physical authentication by a qualified staffer (the real throughput gate) and a QR-label printer/stock. No code dependency.
5. **A first real transaction:** a genuine paid Shopify order + a certified physical pair to run the end-to-end once (none exist yet — the 205 imports are uncertified INTAKE; the single sale link is a test/non-eligible row).

**Not blockers (do not build):** variant/SKU/fuzzy sale matching (explicitly excluded — one variant ↔ many pairs is ambiguous and unsafe); Stripe paid-auth checkout (dormant, external-intake only); further UX (already shipped and live).

## Launch checklist (exact next actions, in order)
1. **Email:** provision Postmark (SMTP), verify `no-reply@secondchanceauthenticators.com`, publish SPF + DKIM (+ return-path) at GoDaddy; one controlled test to an SCA inbox.
2. **Deploy secure-claim RC** (owner-authorized, migrate-before-code): backup → apply the 4 additive migrations (batch 31) → fast-forward live to the RC → set `MAIL_MAILER=smtp` + verified sender in `app/.env` → `config:clear`/`view:clear` → graceful reload. (Rollback: code revert + `view:clear` + graceful; migrations are additive, no DB rollback.)
3. **Permissions + data:** grant `sca.eyewear.fulfillment.release`; run `sca:shopify:backfill-sale-link-email --apply`.
4. **Prepare a real pair:** confirm the physical pair → authenticate (passed + grade) → certify → print + affix the QR label.
5. **Associate the sale:** staff-assign the genuine Shopify order line → the chosen pair (captures the trusted order email on the sale link).
6. **Release:** staff fulfillment-release the pair → deliver the private claim link to the buyer.
7. **Buyer claim:** buyer registers → verifies email → opens the private link → claims (verified-buyer gate).
8. **Verify:** item appears in My Collection; public Passport shows certified; then exercise one collector→collector transfer.

## Safety posture (this task)
Read-only. No Shopify API request or store change; no production DB write; no inventory import; no
authentication/certification/QR issuance; no real order assignment; no customer claim or ownership
transfer; no deployment/migration/infrastructure change; secure claiming NOT activated. Production
unchanged at `e3f73f8b`.

**STOP — Purchase→Passport is LIVE through issuance (catalog → staff order→pair assignment → authenticate
→ certify → QR + labels/PDF → public Passport) and resale transfer (email-free); the BUYER-CLAIM stage
(fulfillment-release → private link → verified-buyer email gate) is undeployed in the secure-claim RC and
blocked on transactional email. Genuine blockers: (1) SMTP email, (2) owner-authorized migrate-before-code
deploy of the secure-claim RC `f4509f70` (closes GAP-1 via R0), (3) fulfillment-release ACL + order_email
backfill, (4) physical authentication + QR printing + a first real paid order/certified pair. No code gaps
otherwise. Read-only; prod `e3f73f8b` unchanged.**

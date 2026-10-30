# SCA — Final Essential Feature Gap Review (read-only)

**Every product-level requirement in `PRODUCT_REQUIREMENTS.md` / `ROADMAP.md` is DEPLOYED,
DEVELOPED-NOT-DEPLOYED, or BLOCKED on an owner/ops action — no genuinely-missing, business-essential,
email- and Shopify-independent requirement remains to build. DEVELOPMENT COMPLETE; no code was
changed.** The single highest-priority capability still absent from production is the customer **claim**
flow, which is already developed and deployment-blocked on transactional email (explicitly out of scope
here). Read-only; production unchanged at `b007606`. 2026-10-30. **STOP.**

## Status legend
DEPLOYED · DEVELOPED-NOT-DEPLOYED (built, unmerged/unreleased) · BLOCKED (built, gated on owner/ops) ·
FUTURE/OPTIONAL (expansion, explicitly post-core) · OPS/INFRA (not a product feature).

## Requirement → status matrix
| Requirement (PRODUCT_REQUIREMENTS / ROADMAP) | Status | Evidence / note |
|---|---|---|
| Pre-sale state: authentication, condition grade, registry/provenance, Certification ID, permanent QR, printed QR, ownership `UNCLAIMED` | DEPLOYED | staff intake/auth/certify; batch QR labels; CSV onboarding |
| Shopify ↔ exact physical pair (catalog sync, order-line → pair) | DEPLOYED *(excluded)* | inventory sync Phase 1; order assignment |
| SCA-canonical provenance model | DEPLOYED | SCA owns item/cert/QR/ownership |
| Digital Provenance Record fields (model/brand/year/country/materials/specs/auth/condition/images/cert/ownership/transfer/service/market) | DEPLOYED *(excluded)* | SCA-044 metadata; multi-image gallery; market reference |
| Permanent QR + public passport + state-dependent presentation | DEPLOYED *(excluded: QR/registry)* | `/p/{token}`, adverse-dominant, PII-free; QR domain cutover live |
| Ownership history (append-only) | DEPLOYED *(excluded)* | |
| Ownership transfer (+ pending indicator, Copy/Share link) | DEPLOYED *(excluded)* | |
| Service history | DEPLOYED *(excluded)* | |
| Lost/stolen/recovered registry + public warning | DEPLOYED *(excluded)* | |
| My Collection dashboard + browse/filter + private collections + collector profiles (CP-3..CP-6) | DEPLOYED *(excluded)* | |
| Market Information (advisory) | DEPLOYED *(excluded)* partial | Market Reference + value history; richer MSRP/avg/high/low/last-sale fields are FUTURE, "explicitly not an appraisal" |
| External eyewear flow (submit → pay → authenticate → add) | DEPLOYED (code) | `submission.*` + `submission.pay` (Stripe) routes live; **paid activation = Stripe provider config, dormant (ops gate)**, and listed under Phase 11 expansion |
| Certificates + Insurance/provenance documents (Phase 9 SCA-DOCUMENTS-017) | DEVELOPED-NOT-DEPLOYED *(excluded: documents)* | certificate PDF DEPLOYED; provenance report + resale-wording + on-demand cert availability = 3 stacked branches `ba2da33`←`63b5808`←`a923dfd`, awaiting testing-freeze lift |
| **Customer claim (scan → claim → `REGISTERED`; `SOLD_AWAITING_CLAIM`) — Phase 6 SCA-CLAIM-012** | **BLOCKED** | **R0/R0b/R0c = `4bd88d2`, DEPLOYMENT-BLOCKED on transactional email + separate deploy auth. The single highest-priority capability absent from production; email-gated → out of scope here.** |
| Privacy principle (no PII on public scan) | DEPLOYED | public passport PII-free |
| Shopify App embedded staff conveniences in Shopify Admin | FUTURE/OPTIONAL *(Shopify-dependent → excluded by scope)* | "may eventually"; least-privilege read scopes |
| Transactional email (claim links, notifications) | BLOCKED (ops) | Postmark not configured; MAIL=log. Gates claim. Excluded here |
| Permanent infrastructure migration + durable off-host backup (Phase 10 SCA-PRODUCTION-018) | OPS/INFRA | prod cutover to the Jeremy-controlled domain DONE; off-host backup is a known residual (ops, not a product feature) |
| Expansion: market history/value tracking/resale-marketplace/analytics (Phase 11) | FUTURE/OPTIONAL | explicitly "add value AFTER the core is reliable; must not block the core" |

## Finding
Excluding the areas named in the task (inventory, Shopify sync, QR, order assignment, My Collection,
transfer, service history, registry, market reference, documents), every remaining product requirement
is either **DEPLOYED**, **DEVELOPED-NOT-DEPLOYED** (the document branches), **BLOCKED on an owner/ops
action** (claim ← email; paid external auth ← Stripe), **OPS/INFRA** (Phase 10), or **FUTURE/OPTIONAL**
(Phase 11 expansion, Shopify embedded app).

**There is no genuinely-missing, business-essential requirement that is simultaneously (a) outside the
excluded set, (b) not already developed, (c) not blocked only on email/Shopify/provider config, and
(d) buildable as a smallest-safe feature here.** The product is functionally complete in code.

## The single highest-priority remaining business-essential capability (NOT buildable here)
The **customer claim flow** (buyer scans the printed QR → signs in / registers → claims → ownership
appended → `REGISTERED` → My Collection) is the heart of Jeremy's buyer flow and the one core capability
still not in production. It is **already developed** (secure-claim RC `4bd88d2`, full regression green)
and **deployment-blocked on transactional email** (verified-buyer gate) plus a separate deploy
authorization. This is an **owner/ops gate, not missing code** — and the task explicitly excludes email
configuration and R0/R0b/R0c deployment. So no code is written for it here.

## Remaining non-code gates (owner/ops actions, for visibility — not implemented here)
1. **Transactional email** (Postmark SMTP config-only, or add `symfony/postmark-mailer`) → unblocks the
   claim flow and lifecycle notifications. Highest leverage.
2. **Separate deploy authorization + pre-flight** for secure-claim RC `4bd88d2` (4 additive migrations,
   migrate-before-code; fulfillment-release ACL; order_email backfill).
3. **Owner lifts the testing freeze** → isolated regression → RC → deploy the 3 stacked document
   branches (`ba2da33`←`63b5808`←`a923dfd`) and the earlier CSV/transfer features already live.
4. **Stripe activation** (if/when paid external authentication is prioritised — Phase 11).
5. **Phase 10 ops**: durable off-host backup + eventual permanent-infrastructure migration (QR/provenance
   survive unchanged).

## Conclusion
**DEVELOPMENT COMPLETE** for genuinely-missing, business-essential, email/Shopify-independent product
requirements — none remain. Per the task, no feature was implemented and no code was changed. The path to
launch is now **operational** (stand up transactional email → deploy the claim RC; lift the testing
freeze → regression/deploy the document branches), not further feature development.

## Safety posture (this task)
Read-only. No production change/migration/deploy; no Shopify API or store change; no customer claim or
ownership transfer; no email configuration; no R0/R0b/R0c deployment; no Option C; no tests. Production
unchanged at `b007606`. No new branch; stacked unmerged branches remain `ba2da33` ← `63b5808` ←
`a923dfd`. Secure-claim RC `4bd88d2` DEPLOYMENT-BLOCKED and untouched.

**STOP — final essential-feature gap review complete. Every product requirement is DEPLOYED,
DEVELOPED-NOT-DEPLOYED, BLOCKED on an owner/ops action, OPS/INFRA, or FUTURE/OPTIONAL; no genuinely-
missing, business-essential, email/Shopify-independent requirement remains to build, so DEVELOPMENT
COMPLETE and no code was changed. The single highest-priority remaining capability is the already-built,
email-blocked customer claim flow (`4bd88d2`) — an owner/ops gate, not missing code. Production unchanged
at `b007606`; secure-claim RC `4bd88d2` untouched.**

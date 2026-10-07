# SCA External Paid Authentication Intake — discovery + domain plan (DISCOVERY/DOMAIN PLAN ONLY)

**Date:** 2026-10-07 · **Status: READ-ONLY discovery + domain/workflow design. NO implementation — no migrations, routes, controllers, UI, payment code, Shopify change, tables, statuses, emails, or production config.** Deployed baseline `0815ea0808b6ceac2bb82d88c891fdedc2b97bda`, migrations **122**. For ChatGPT audit. NEXT_TASK set to this task (discovery/plan stage). Transactional Email/SMTP remains OPEN but PARKED/operator-gated — untouched here.

**Objective:** let a collector submit a frame **they already own** (not bought from Second Chance Eyewear) to SCA for **paid authentication**, extending — not duplicating — the existing lifecycle: submission → payment → physical intake → staff authentication → result → certification if genuine → permanent Digital Passport + QR → registered ownership → My Collection → normal provenance/transfer/service lifecycle.

**Method:** two read-only architecture traces at the deployed baseline, every claim `file:line`-grounded (paths under `/opt/sca-platform/app`). Cross-referenced with `docs/SCA-APPLICATION-EXPANSION-AUDIT-047.md` (which classified this as `F1 — DEFERRED/HIGH`: "back half exists; missing customer submission + payment + logistics").

**Headline:** the entire **back half already exists and is origin-neutral** — `external_intake` is a first-class `intake_type` **and** `claim_source` wired end-to-end (item → authenticate → certify → QR → staff grant → collector claim → single ownership event → My Collection), with no SCE/Shopify assumption. The net-new work is a **pre-registry front stage**: collector-initiated **submission**, **payment**, and **physical-custody** tracking, which on success feeds the existing engine. **Classification: B — Medium extension** (new front stage feeding an untouched provenance core), with the explicit caveat that the **payment** and **public-submission** dimensions carry upper-end risk (money, a public surface, logistics) even though no provenance code changes.

---

## 1. Existing reusable architecture (what NOT to rebuild)

| Capability | Status for external paid auth | Evidence (file:line) |
|---|---|---|
| **`external_intake` intake type** | First-class CHECK value on items **and** claims; already the external discriminant | items `…120002_create_sca_eyewear_items.php:18,24`; claims `…120009:31`,`:34-37` |
| **`ItemService::create`** | INTAKE-only, origin-neutral; writes just the item + `sca_item_current_state` (INTAKE/normal); mints NO downstream artifact; `public_ref` system-generated | `Provenance/src/Services/ItemService.php:12-29`; `Token.php:12-15` |
| **AuthenticationService** | Append-only; `result ∈ {passed,failed,inconclusive}`; condition grade A–D on passed; finalize→projection; DB-immutable after finalize | `AuthenticationService.php:22,32-68`; auth migration `120003:15-26`; triggers `120017:37-52` |
| **CertificationService::issue** | Requires a **passed+finalized same-item** auth (app + DB trigger); mints cert + **auto-activates the permanent QR** + captures immutable snapshot | `CertificationService.php:35-97`; `QrService.php:23-123`; triggers `120017:56-96` |
| **Revoke/supersede** | Append-only cert correction; does NOT touch QR | `CertificationCorrectionService.php:53-178` |
| **Ownership** | Append-only `sca_ownership_events` (`claim/transfer_in/transfer_out/admin_correction`), no_update/no_delete triggers; owner via projection | ownership migration `120010:15-30`; `ProjectionService.php:49-61`; triggers `120017:20,31-34` |
| **External claim grant (THE closest analog)** | Staff issue a single-use opaque grant for a **certified external_intake** item (no owner yet); collector consumes it → ownership. No Shopify sale needed | `ExternalClaimGrantService.php:37-139`; grant migration `…120001(0923):29-50` |
| **Claim workflow** | `claimByGrant` → `openExternalClaim` → verify → complete writes the single `claim` ownership event + atomically consumes the grant; idempotent, single-owner-guaranteed | `ClaimWorkflow.php:187-261`; `ClaimService.php:33-43,66-114` |
| **Collector accounts + guard** | Self-service register (COL- ref, **email + optional display_name only**, status active/disabled/pseudonymized), separate `collector` guard, url.intended return | `…120001(0914)_create_sca_collector_accounts.php:13-23`; `RegisterController.php:32-52`; `CollectorServiceProvider.php:29-55` |
| **My Collection** | Owner-only (membership = `current_owner_collector_id`); owner-safe allowlisted fields; opaque-ref detail with ownership authz (null→404); **no pending/in-progress notion** | `CollectionService.php:10-40,439-457` |
| **Transfers** | Collector-driven, append-only ownership pair; adverse-status blocks | `TransferWorkflow.php:35-155`; `TransferService.php:88-103` |
| **Status events + projection** | Append-only; adverse set gates transfer/claim | `StatusService.php:19-130`; `ProjectionService.php:118-148` |
| **Evidence / inspection photos** | `sca_media_assets` supports `subject_type='authentication'` (private by default), via `DocumentService`; condition grade lives on the authentication | media `120015:28-29`; `DocumentService.php:26-123`; `AuthenticationService.php:38` |
| **Staff Registry / item-detail / dashboard** | authenticate/certify/issue-grant screens; index filters incl. `external_intake`; item-detail external-claim block | `EyewearItemController.php:101,348-360`; admin-routes `119-212`; `ExternalClaimLinkController.php:29-88` |
| **Bulk import** | INTAKE-only, allows `external_intake`; reuses `ItemService::create` | `InventoryImportService.php:31-34,260` |

**Lifecycle states the projection actually writes:** `{INTAKE, AUTH_FAILED, AUTHENTICATED, CERTIFIED, REGISTERED}` (`ProjectionService.php:129-148`). `SOLD_AWAITING_CLAIM/TRANSFER_PENDING/RETIRED/INVALIDATED` are CHECK-allowed-but-never-written (vestigial) — **do not** repurpose them silently.

## 2. Gaps (the only net-new dimensions)

Three dimensions have **zero** existing representation anywhere in `packages/Sca/*`:
1. **Collector-initiated submission.** Every item-creation path is staff-only (`EyewearItemController::store`, `InventoryImportService`). There is no collector/public route/controller/service to create an item or request authentication.
2. **Payment.** No payment/checkout/draft-order/Stripe/price/fee/invoice anywhere. Shopify is strictly **inbound read-only** webhooks (`scopes read_orders,read_products`; topics `orders/paid|cancelled`, `refunds/create`) with no outbound order/checkout capability. "Paid" today is only a UI label + the inbound `orders/paid` webhook. (`Shopify/src/Config/shopify.php:37`; `WebhookTopics.php:21-25`)
3. **Physical custody / intake-request lifecycle.** No concept of submission/custody/shipping/received; My Collection is owner-only with no collector-visible in-progress item.

## 3. Provenance boundary — RECOMMEND **Option D** (separate submission entity; create the registry item only at custody acceptance)

Evaluated A–D:
- **A (create item at submission)** / **B (create at payment):** ✗ — `ItemService::create` creates a **permanent** registry object (`public_ref` immutable/UNIQUE, a `sca_item_current_state` row, no hard-delete path, append-only core). Abandoned forms and unpaid/never-received submissions would permanently pollute the provenance registry. Rejected.
- **C (create at physical receipt):** acceptable for provenance, but gives the collector no tracked pre-receipt object and conflates the operational submission with the permanent item.
- **D (separate pre-registry submission entity; create the permanent `eyewear_item` only at the "received & accepted into custody" transition):** ✓ **recommended.** A new **mutable, non-provenance** `sca_authentication_submissions` entity carries the submitter, declared frame info, payment status, and custody/shipping state, and can be abandoned/cancelled/expired **without ever touching provenance**. At custody acceptance, staff invoke the **existing** `ItemService::create(intake_type='external_intake')` and link `submission.eyewear_item_id` → the permanent item; from there the existing authenticate→certify→grant→claim engine runs unchanged.

**Why D is proven by the architecture, not just preferred:** the codebase already separates *eligibility* (grant/sale-link, mutable) from *ownership* (claim, append-only) from the *physical item* (registry). Option D simply adds the missing earliest stage — *submission/custody* (mutable) — in front of that same separation, so the permanent registry object still appears only when a real frame is in hand. This directly satisfies "no abandoned web forms or unpaid submissions in the permanent registry."

## 4. Proposed external-authentication state machine

**Submission entity status (mutable operational state — NEW):**
`draft → payment_pending → paid → awaiting_shipment → in_transit → received → in_authentication → result_ready → completed` with terminal/exception branches. The permanent `eyewear_item` is created at **`received`** (custody acceptance), not before.

Mapping to the existing (untouched) provenance engine, which begins only at/after `received`:
- `received` → staff `ItemService::create(external_intake)` → item at **INTAKE**.
- `in_authentication` → staff `AuthenticationService::recordDraft/finalize` → **AUTHENTICATED** (passed) or **AUTH_FAILED** (failed/inconclusive).
- genuine → `CertificationService::issue` → **CERTIFIED** + QR minted; then grant→claim by the submitting collector → **REGISTERED** + My Collection → `completed`.

**Exception / failure paths (each maps to a submission terminal/branch state; none mutate provenance unless an item already exists):**
| Event | Handling |
|---|---|
| payment abandoned | submission expires from `payment_pending` → `cancelled_unpaid`; no item created |
| payment failed | stays `payment_pending`; retry; no item |
| cancelled before receipt | collector/staff cancel `paid/awaiting_shipment` → `cancelled` (+ **refund policy → Jeremy**) |
| item never received | timeout from `awaiting_shipment/in_transit` → `not_received` (+ refund policy → Jeremy) |
| wrong/unexpected item received | `received_mismatch`; staff decide (return / re-scope) — no auto-create |
| authentication fails | item at AUTH_FAILED; **structurally cannot certify** (DB trigger); submission `result_ready(failed)` → return |
| counterfeit / suspected counterfeit | see §6 — today collapses to `failed`/`inconclusive`→AUTH_FAILED (terminology → Jeremy) |
| insufficient evidence / inconclusive | existing `inconclusive` result → AUTH_FAILED; submission `result_ready(inconclusive)` |
| duplicate frame already registered | detection is weak (only `public_ref` is unique; `frame_serial` advisory/non-unique) → **flag at receipt for staff + Jeremy policy**; never auto-merge |
| damaged during/at intake | operational note on submission; condition grade reflects state; (liability → Jeremy) |
| collector disputes result | append-only record; existing `disputed` registry status exists for post-registration; pre-registration dispute is a submission note (+ policy → Jeremy) |
| return shipment | submission `return_ready → returned` (manual instructions MVP; carrier API is a non-goal) |
| lost shipment (inbound/return) | `lost_in_transit` terminal (+ liability policy → Jeremy) |

*(These are operational/UX states on the submission entity, NOT new provenance lifecycle states. The 5 real projection states stay unchanged.)*

## 5. Ownership semantics

- **Collector account required before submission** — submitter identity = `collector_account_id` on the submission (reuse self-service register + `collector` guard + url.intended).
- **Submitter "claims to own" the physical frame, but SCA registered ownership is established ONLY after successful authentication + certification**, via the **existing** grant→claim path (`ExternalClaimGrantService::issueForItem` → `ClaimWorkflow::claimByGrant` → `ClaimService::complete`, the single owner-creation point, item-locked, single-owner-guaranteed). Recommend the grant be **scoped/offered to the submitting collector** (they are known), but ownership still flows through `ClaimService::complete` — never a direct owner write, never overwriting history.
- **Ownership occurs AFTER successful authentication (not before).** A failed/inconclusive/counterfeit item is never certified → no grant → no ownership → **does not enter My Collection** (which is owner-only). The collector still sees the outcome via the **submission status/result** surface (separate from My Collection).
- **Re-submission / duplicate:** no reliable automated physical key (frame_serial advisory). Recommend: prevent re-submitting an item already `REGISTERED` to the same collector where detectable, and surface a staff "possible duplicate" flag at receipt; final policy → Jeremy. **Never overwrite ownership history** — the append-only ownership model is preserved absolutely.

## 6. Authentication-outcome model

Existing outcomes = **passed / failed / inconclusive** (`120003:26`); failed and inconclusive both derive **AUTH_FAILED**; no `counterfeit`/`suspected` value exists. For a **paid** service the customer pays to learn a verdict, so the business may want to distinguish **suspected counterfeit** from a generic failure on the customer-facing result.
- **Minimum recommendation:** keep the existing 3 values for the MVP (they structurally work: any non-passed outcome blocks certification). Represent "suspected counterfeit" as `inconclusive`/`failed` **plus a staff reason/notes**, surfaced on the result — **no schema change**.
- **If Jeremy requires a distinct customer-facing "counterfeit/suspected counterfeit" verdict:** that is a deliberate extension of the `result` CHECK + `deriveLifecycleState` (small, but it touches a provenance enum) — do it only on explicit business need. **Terminology + whether to distinguish it = Jeremy policy.**

## 7. Payment architecture (discovery only — no implementation, no Shopify scope change)

Constraints: SCA must keep permanent identity **independent of Shopify**; payment must **not create provenance**; must serve customers who never shop at SCE; avoid Shopify scope expansion; need webhook HMAC + idempotency + refund/cancel handling + reconciliation.

| Option | Fit | Notes |
|---|---|---|
| Shopify checkout/product (reuse existing `orders/paid`) | Possible, **zero scope change** | Requires an "Authentication Service" storefront product + a submission-ref line-item property (analogous to `sca_item_ref`), reusing the existing HMAC/idempotent receiver. **Couples to Shopify + SCE storefront**; awkward for non-SCE customers. |
| Shopify draft order | ✗ | Needs `write_draft_orders` → **scope expansion** (disallowed). |
| **Separate provider — Stripe Checkout / Payment Links** | ✓ **recommended** | Keeps SCA identity independent; serves any customer; **hosted checkout so no card data touches SCA** (PCI-light); a Stripe webhook mirrors the proven Shopify HMAC+idempotent-receipt pattern (`WebhookController.php:37-98` is the template); refunds/cancels flip submission payment state only. |
| Other (PayPal/Square) | alt | Same shape as Stripe. |

**Recommendation:** **Stripe hosted Checkout** as primary (independent, non-SCE-friendly, no Shopify coupling), with the **Shopify-product reuse** noted as a lean zero-scope-change alternative if the business wants payment to stay on Shopify for the pilot. **Either way, payment only advances `submission.payment_status`; it never writes an item/cert/QR/ownership.** Provider choice = **Jeremy business decision.** No Shopify scope/app/webhook change is proposed. **Payment can be sequenced LAST** (manual-invoice pilot first) to de-risk the money dimension.

## 8. Collector MVP UX

Landing/"Start authentication" → sign in / create collector account (**required**) → submission form (declared brand/model/serial + justified photos via `DocumentService`) → **service/price acknowledgement** → payment (hosted checkout) → confirmation → **shipping/drop-off instructions** (static text MVP) → **status tracking** (submission state) → **result** (passed → link into My Collection via claim; failed/inconclusive/counterfeit → result + return) → **completed Digital Passport in My Collection**.
- **MVP:** one frame per submission, hosted payment, manual shipping text, status page, result. **Later (non-MVP):** multi-item submissions, saved addresses, rich photo intake, auto claim-link delivery (**needs SMTP — parked**), carrier labels (non-goal).

## 9. Staff MVP UX (reuse, don't rebuild)

One new surface: a **submissions worklist/index** filtered by submission status — tiles/queues for *new paid submissions · awaiting item · received · authentication queue · exceptions · completed/return-ready* (extend the existing `DashboardController` + a submissions index mirroring `EyewearItemController::index`). The **"receive & accept into custody"** staff action is the bridge: it calls the existing `ItemService::create(external_intake)` and links the submission → item. **Everything after that reuses the existing authenticate / certify / QR / issue-grant screens** (`admin-routes.php:119-212`). No second admin system.

## 10. Minimal data model

**NEW (mutable operational — NOT provenance):** `sca_authentication_submissions`
- `id`; `public_ref` (opaque `SUB-…` for collector-facing tracking, system-generated like `Token::publicRef`); `collector_account_id` FK (submitter); `status` (§4 state machine); `payment_status` + `payment_ref` (opaque external id — **never card data**); `eyewear_item_id` **nullable** FK (null until custody acceptance → links to the permanent registry item); collector-**declared** `brand`/`model`/`frame_serial`/`notes` (pre-authentication, **non-authoritative** — staff set authoritative identity on the item at receipt); shipping/return tracking fields (private); timestamps. **Mutable**: abandoned/cancelled/expired without touching provenance.
- **Optional** `sca_submission_status_events` (append-only audit of submission transitions) — recommended for auditability to match the event-sourced house style, but can be deferred for the MVP (mutable `status` + `updated_at` suffices initially).

**REUSED unchanged (no new fields):** `sca_eyewear_items`, `sca_authentications`, `sca_certifications`, `sca_ownership_events`, `sca_status_events`, `sca_qr_identifiers`, `sca_external_claim_grants`, `sca_claims`, `sca_media_assets`, `sca_item_current_state`. **No duplication** of item/auth/cert/ownership/QR data — the submission references the item by FK once created and carries only pre-registry operational data.

**Clear separation:** pre-registry submission/payment/custody = the new **mutable** entity; permanent registry + authentication + certification + ownership = the existing **append-only** core, untouched; the single bridge is `submission.eyewear_item_id`, set once at custody acceptance.

## 11. Security / privacy model

- **IDOR / collector isolation:** submission reachable only by its owning collector via opaque `SUB-` ref + server-side authorization (null→404), mirroring `CollectionService::ownedItemByRef`; staff via ACL.
- **Uploads:** reuse `DocumentService` (ext allowlist pdf/jpg/jpeg/png, **private disk outside docroot**, size cap, SHA-256, server-derived filename); bind inspection photos to `subject_type='authentication'` (schema slot exists).
- **Sensitive shipping/contact data:** lives only on the mutable submission, **collector-private + staff-only, never on the public passport** (public passport already carries zero PII — invariant preserved).
- **Opaque identifiers only:** `SUB-`/`COL-`/cert token/QR token; never internal ids.
- **Payment webhook:** HMAC verify-before-parse + idempotent receipt (clone the Shopify receiver pattern); **payment never creates provenance**; refunds/cancels flip submission state only; replay-safe via a unique webhook/idempotency key.
- **Rate limiting + CSRF:** throttle submission + payment-callback routes (as collector routes already do `throttle:6,1`/`10,1`); web-group CSRF.
- **Staff ACL:** new `sca.eyewear.submission.*` (or reuse `sca.eyewear.create/authenticate/certify/claim`).
- **No arbitrary ownership claims:** ownership remains **only** via the existing post-certification claim path; a submission never asserts ownership; ownership history stays append-only and is never overwritten.

## 12. Business-policy decisions required from Jeremy

Pricing/fee; **refund policy** (failed / counterfeit / cancelled / not-received / lost-in-transit); whether a non-genuine item gets any SCA record vs result-only; **counterfeit/suspected-counterfeit terminology** and whether it is a distinct customer-facing verdict (§6); **payment provider** (Stripe vs Shopify product, §7); duplicate/re-submission policy (§5); shipping responsibility + inbound/return liability; return-shipment policy; whether success auto-offers ownership to the submitter or requires an explicit claim step; data-retention for abandoned submissions; whether collector-declared frame info is authoritative or staff re-enter.

## 13. Implementation risks

- **Payment is the highest-risk dimension** (money, external provider, webhooks, refunds, reconciliation, PCI) — isolate it, use hosted checkout, mirror the proven HMAC/idempotency pattern, and keep it strictly non-provenance; sequence it late (manual-invoice pilot first).
- **A public/customer-facing submission surface** widens the attack surface (uploads, IDOR, rate-limit, spam) — reuse the hardened collector patterns.
- **Abandoned-submission hygiene** — the whole reason for Option D; ensure expiry/cleanup never touches provenance.
- **Must not weaken the append-only core** — all provenance writes stay through existing services; the submission layer never writes item/auth/cert/QR/ownership directly except via `ItemService::create` + the existing claim path.
- **SMTP is parked** — result/claim-link delivery is manual (copy link) for the MVP, exactly as the external-claim-grant flow works today.

## 14. Explicit non-goals (per task §11)

Marketplace/resale; valuation; social profiles; analytics expansion; in-app notification center; marketing email; SMS; automatic claim/transfer email; off-site backup; SMTP activation; AI authentication; shipping-carrier API integration; international tax; **major Shopify scope expansion**; rewriting existing SCA provenance.

## 15. Recommended implementation slices (dependency order; easiest → hardest)

0. **Business-policy + payment-provider decisions** (Jeremy) — a hard prerequisite for slices 4/6. *(no code)*
1. **Submission entity + state machine** — new mutable `sca_authentication_submissions` (+ optional status-events); no payment, no UI. *Foundation.* **MEDIUM.** deps: none.
2. **Staff submissions worklist + "receive & create item" bridge** — index/tiles + the staff action that calls `ItemService::create(external_intake)` and links the submission; then the existing authenticate/certify/QR/grant screens drive it. **MEDIUM.** deps: 1.
3. **Collector submission UX (no payment yet)** — landing, form (+justified uploads), confirmation, status tracking; payment stubbed as manual-invoice. **MEDIUM.** deps: 1 (benefits from 2).
4. **Payment integration** — hosted checkout + HMAC/idempotent webhook flipping `payment_status`; refunds/cancels; reconciliation. **HARD.** deps: 1, 3, policy(0). *Sequence last for the pilot (manual invoice first).* 
5. **Result delivery + ownership wiring** — on certification, offer/issue the grant scoped to the submitting collector; result page; My Collection entry (reuses existing grant/claim). **MEDIUM.** deps: 2 (+ cert engine).
6. **Exception/return handling** — cancel, not-received, wrong-item, counterfeit outcome, disputes, return/lost shipment. **MEDIUM–HARD, policy-heavy.** deps: 1–5, policy(0).

**Dependency summary:** 1 is the base; 2 and 3 build on 1; 5 builds on 2 + the cert engine; 4 builds on 1 + 3 (+ policy) and should be sequenced last for the pilot; 6 builds on all. Payment-last keeps every earlier slice shippable with a manual-invoice pilot, de-risking the money dimension.

## 16. Classification — **B (Medium extension of SCA)**

Not **A** (thin intake layer): the submission + payment + custody front stage is entirely net-new — a new mutable entity, a public collector submission surface, a payment integration with webhooks, and new staff worklists. Not **C** (major new subsystem): the provenance/authentication/certification/QR/ownership engine is **reused unchanged** — `external_intake` is already first-class and the grant→claim ownership path already produces exactly "a collector owns an externally-sourced item after staff certify it." **B — a medium extension that adds a pre-registry stage feeding an untouched core.** Honest caveat: the **payment** and **public-submission** dimensions carry upper-end (C-level) *risk* even though no provenance code changes; and if the business later wants full logistics (carrier/label APIs, international tax, automated returns) that incremental scope tips toward C and is out of this MVP.

**NEXT_TASK.md set to this task at discovery/plan stage. No implementation, no migration, no payment/Shopify/DNS/.env/production change. STOP for ChatGPT audit.**

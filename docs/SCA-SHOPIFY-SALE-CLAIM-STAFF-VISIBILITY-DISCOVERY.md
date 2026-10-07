# SCA Shopify Sale / Claim — Staff Visibility — discovery + plan (DISCOVERY/PLAN ONLY)

**Date:** 2026-10-07 · **Status: READ-ONLY discovery + implementation plan. NO implementation, NO branch, NO schema/migration, NO DB/production/Shopify mutation.** Deployed baseline `976088944de0fd2883f12a0686fafaa708ce8b9e`, migrations **122**, `MAIL_MAILER=log`. For ChatGPT audit. NEXT_TASK set to this task (discovery/plan stage).

**Goal (verbatim intent):** give staff clear, **read-only** visibility into the *existing* Shopify sale→claim state of an SCA frame. This is **NOT** a Shopify integration expansion. Per item, the UI must answer: has the frame been linked to a Shopify sale; current sale-link state; is it eligible / awaiting claim; already claimed; cancelled/refunded/revoked; what **safe** Shopify order reference/date staff can use. For triage: how many sold frames await claim, and can staff click that count to see those exact items.

**Method:** traced the actual deployed code (schema migration + services + controllers + views + ACL), not queue text. Every state/field/query below is grounded in `file:line` at the baseline. **No states invented — only the real persisted/domain states are used.**

---

## 1. Exact `sca_shopify_sale_links` schema (deployed)

Migration `packages/Sca/Provenance/src/Database/Migrations/2026_09_14_120008_create_sca_shopify_sale_links.php`:

| Column | Type / null | Notes (verbatim from migration) |
|---|---|---|
| `id` | bigIncrements PK | L13 |
| `eyewear_item_id` | unsignedBigInteger, NOT NULL | L14; FK → `sca_eyewear_items(id)` ON DELETE RESTRICT (L25); INDEX (L27) |
| `shopify_shop_id` | string(64), NOT NULL | L15 "canonical shop identity (F5)" |
| `shopify_order_id` | string(64), NOT NULL | L16 |
| `shopify_line_item_id` | string(64), NOT NULL | L17 |
| `shopify_product_id` | string(64), NULLABLE | L18 |
| `shopify_variant_id` | string(64), NULLABLE | L19 |
| `shopify_customer_ref` | string(64), NULLABLE | L20 "reference only, not a collector link" — **always written literal null** (SaleLinkService L84, L146); never populated by any code path |
| `eligibility_state` | string(24), NOT NULL | L21; CHECK `chk_sale_eligibility` ∈ {eligible, claimed, revoked_refund, revoked_return, cancelled} (L30) |
| `webhook_idempotency_key` | string(160), UNIQUE | L22 (internal plumbing, e.g. `<shop>:orders/paid:<order>:<line>`) |
| `created_at` / `updated_at` | timestamps nullable | L23; set with `now()` at **webhook-processing** time, **not** Shopify's authoritative `paid_at` — there is no stored order paid/received timestamp |

Additional constraint: **UNIQUE(`shopify_shop_id`, `shopify_line_item_id`)** named `uniq_shop_line` (L26) — store-scoped one-link-per-line.

**Model:** `packages/Sca/Provenance/src/Models/ShopifySaleLink.php` is bare (`$table`, `$guarded=[]`, `$timestamps=true`; **no** relationships/casts/scopes). Production sale/claim code uses `DB::table('sca_shopify_sale_links')` query-builder throughout; the Eloquent model is effectively unused. `EyewearItem` and `Claim` models are likewise bare — **there is no Eloquent relationship** item→sale-link or sale-link→claim; all joins are manual.

---

## 2. Actual persisted states + transition sources (no invented states)

`SaleLinkService` constants: `ACTIVE_STATES = ['eligible','claimed']` (L33); `REVOKED_STATES = ['revoked_refund','revoked_return','cancelled']` (L36).

| State | Written by | Trigger |
|---|---|---|
| `eligible` | `SaleLinkService::linkPaidLine` INSERT (L85) | `orders/paid` webhook, HMAC-verified, idempotent |
| `claimed` | `ClaimService::complete` UPDATE (`ClaimService` L98), guarded: link must currently be `eligible` (L92) **and** same item (L95) | collector claim completion (`claim_source='shopify_sale'`) |
| `revoked_refund` | `CommerceService::refund(id,'revoked_refund')` UPDATE (`CommerceService` L27-28), via `SaleLinkEventProcessor::handleRefund` → `SaleLinkService::revokeLine` (processor L111) | `refunds/create` webhook |
| `cancelled` | `SaleLinkService::cancelLine`: active link → `commerce->refund(id,'cancelled')` (L133); no prior link → inserts a `cancelled` **tombstone** directly (L147); also `handleCancelled` no-ref → `revokeLine(...,'cancelled')` (processor L88) | `orders/cancelled` webhook |
| `revoked_return` | **NEVER written by any code path** | — allowed-but-dead: exists only in the CHECK list (migration L30) and the `REVOKED_STATES` constant (L36); `SaleLinkEventProcessor` L102-103 documents it will not emit it (no returns topic in scope) |

**Actually-persisted set = {eligible, claimed, revoked_refund, cancelled} (4).** CHECK allows 5; `revoked_return` is dead. The UI must present only the 4 real states (and may note `revoked_return` is not currently produced, so it need not be rendered — but a defensive label for it costs nothing).

**Post-claim reversal:** `revokeLine` (L158-170) acts on links in `ACTIVE_STATES` — so a refund **can** revoke an already-`claimed` link to `revoked_refund`. When the item already has an owner, `CommerceService::refund` (L30-40) ALSO inserts a `disputed` `sca_status_events` row + rebuilds projection; **ownership is never deleted** (append-only). So a refunded-after-claim item shows sale-link `revoked_refund` **and** an adverse `disputed` registry status — both surfaces already exist; this panel just makes the sale-link side visible.

---

## 3. Claim ↔ sale-link relationship (how "claimed" is traced)

`sca_claims` (migration `2026_09_14_120009_create_sca_claims.php`) HAS **`source_sale_link_id`** unsignedBigInteger NULLABLE (L17), FK → `sca_shopify_sale_links(id)` ON DELETE RESTRICT (L26).

- `claim_source` string(24) CHECK ∈ {`shopify_sale`,`external_intake`} (L16, L31); `state` CHECK ∈ {pending, verified, completed, rejected} (L19, L32).
- CHECK `chk_claim_source_consistency` (L34-37): `shopify_sale` ⇒ `source_sale_link_id` NOT NULL AND `source_certification_id` NULL; `external_intake` ⇒ the reverse.
- Insert: `ClaimService::openShopifyClaim` (L20-30) sets `claim_source='shopify_sale'`, `source_sale_link_id=$saleLinkId`, `state='pending'`.
- On completion `ClaimService::complete` flips the sale-link to `claimed` (L98) AND writes an `sca_ownership_events` row (event_type `claim`, source_claim_id, collector_account_id=claimant, L101-108). Current owner lives in `sca_item_current_state.current_owner_collector_id`.

**Traversal (manual joins only):** sale-link.id → `sca_claims WHERE source_sale_link_id = <id>` → claim state; completed claim → `sca_ownership_events` → `sca_item_current_state.current_owner_collector_id`. For the panel, **"claimed" is directly readable from the sale-link's own `eligibility_state='claimed'`** — no claim/ownership join is required for the primary signal. The owner identity (if shown) must reuse the existing opaque **`COL-…` `public_ref`** convention (`collectorRef`), never internal collector id/email.

---

## 4. One or many sale-links per item

An item can have **multiple** sale-link rows over its lifetime. UNIQUE is (shop, line_item), **not** per item. `assertEligible` (L209-225) blocks a NEW link only while the item has an ACTIVE link (`eligible`/`claimed`) for a different line, or an owner. After a cancel/refund (link → terminal), the item is eligible again, so a new `eligible` row can be inserted for a resale → historical revoked/cancelled rows accumulate.

**Invariant: at most ONE active (`eligible` or `claimed`) link at a time; potentially MANY historical `revoked_refund`/`cancelled` rows.**

Existing query patterns:
- Current eligible link: `ClaimWorkflow::eligibleSaleLinkId` (`packages/Sca/Claim/src/Services/ClaimWorkflow.php` L289-297) — `->where('eyewear_item_id',$id)->where('eligibility_state','eligible')->value('id')`.
- All rows for an item: `WHERE eyewear_item_id = <id>` (indexed), ordered by `created_at,id`.

**Panel design consequence:** show the **current/active** sale-link prominently (the one `eligible`/`claimed` row, or "none") plus a compact **history** of prior terminal rows — all from one `WHERE eyewear_item_id` query, no new query subsystem.

---

## 5. Safe staff-visible fields vs sensitive (privacy / Shopify boundary)

**Safe to show (non-PII, operator-facing, already stored):** `shopify_order_id`, `shopify_line_item_id`, `shopify_product_id`, `shopify_variant_id`, `eligibility_state`, `created_at`/`updated_at` (**labelled "recorded"/"webhook-processed", not "paid at"** — they are wall-clock processing times, not Shopify's authoritative `paid_at`). `shopify_shop_id` is the store identity (operator's own shop; safe but low-value — optional).

**MUST NOT expose (per verbatim constraint):** Shopify access token, webhook secret, OAuth data, customer private information, billing/payment information. **None of these live in this table.** Specifically:
- `shopify_customer_ref` is **always null** — no customer data exists to show; the panel will not render it.
- `webhook_idempotency_key` is internal plumbing (deterministic string) — **not shown**.
- No access tokens/secrets are in this table (those live in the Shopify connect/config layer, untouched here).
- No `sca_item_ref`/`public_ref` mapping secret — `public_ref` is already shown on the page.

**No Shopify API calls:** every field above is read from existing SCA DB state. The UI will not call any Shopify API to render.

---

## 6. Exact "sold, awaiting claim" query (the un-conflation)

**Definition (domain-exact):** an SCA item with a sale-link currently in `eligibility_state='eligible'` and **not yet claimed** (which `eligible` already guarantees — `claimed` is a distinct state). This is **not** derivable from the lifecycle projection: `sca_item_current_state` only ever persists INTAKE/AUTH_FAILED/AUTHENTICATED/CERTIFIED/REGISTERED; `SOLD_AWAITING_CLAIM` is a CHECK-allowed-but-never-written token (always zero). The signal exists **only** as `sca_shopify_sale_links.eligibility_state='eligible'`.

```sql
-- count of frames sold and awaiting collector claim
SELECT COUNT(*) FROM sca_shopify_sale_links WHERE eligibility_state = 'eligible';

-- the exact items behind that count (drill-down)
SELECT i.*  FROM sca_eyewear_items i
  JOIN sca_shopify_sale_links sl ON sl.eyewear_item_id = i.id
 WHERE sl.eligibility_state = 'eligible';
```

Because at most one active link exists per item, `eligible` rows are 1:1 with distinct awaiting-claim items (no DISTINCT needed, but the drill-down may add it defensively). This **cleanly separates** "certified but never sold" (no `eligible` sale-link) from "sold and awaiting claim" (`eligible` sale-link) — the conflation called out in the task.

**The existing dashboard tile `certified_unclaimed`** (`DashboardController` L34: `lifecycle_state='CERTIFIED' AND current_owner_collector_id IS NULL`, counted over the projection, **never references sale-links**) conflates both. The plan does NOT change that tile's definition (to avoid regressing its audited meaning); it **adds** a distinct, sale-link-derived "Sold — awaiting claim" tile beside it, and (optionally) a short clarifying sub-label on `certified_unclaimed`.

---

## 7. Where the data slots in today (controllers/views)

- **Item detail** `EyewearItemController::show` (L239-351) loads item + `sca_item_current_state` + `currentOwnerRef` (COL-…) + provenance counts + authentications + certification/QR + cert history + services + documents + `$externalClaim` (ONLY `intake_type='external_intake'` — the `external_claim_grants` path, **not** this Shopify sale-link path) + gallery. It **does not query `sca_shopify_sale_links` at all** (grep confirms no reference in the Registry package except `ClaimWorkflow`). So Shopify sale→claim state is **currently invisible to staff on item detail.** View `eyewear/show.blade.php` uses native `x-admin::tabs`: Overview (L185), Authentication (L258), Certification & QR (L326), Documents (L420), History (L460).
- **Dashboard** `DashboardController::index` tiles are pure counts over the projection; the view links each tile to a Registry index filter. No tile joins sale-links.
- **Registry index** `EyewearItemController::index` (L62-154) `leftJoin`s only `sca_item_current_state`; it never joins `sca_shopify_sale_links`. Its `lifecycle` filter allowlist includes the dead `SOLD_AWAITING_CLAIM` value (L40) which yields zero. A real "sold awaiting claim" index filter would require adding a join/exists-subquery on `sca_shopify_sale_links` (`eligibility_state='eligible'`).

---

## 8. Proposed presentation (read-only)

### 8a. Item-detail "Sale / claim status" panel (Option C part 1)
A new read-only block, most naturally a **new "Sale / claim" tab** (or placed in Overview). `show()` adds one query: `DB::table('sca_shopify_sale_links')->where('eyewear_item_id',$id)->orderByDesc('id')->get()` mapped to a safe DTO.

- **Headline (current state):**
  - No rows → **"Not linked to a Shopify sale."**
  - Active `eligible` → **"Sold on Shopify — awaiting collector claim."** (amber)
  - Active `claimed` → **"Sold on Shopify — claimed by collector"** + owner `COL-…` (green). (If a claim row exists, optionally show claim state, but `claimed` suffices.)
  - Latest row terminal (`revoked_refund`/`cancelled`) with no active link → **"Prior Shopify sale cancelled/refunded — no active sale link."** (grey; plus adverse-`disputed` note if the refund post-dated a claim, which the existing registry banner already surfaces).
- **Safe detail rows (current link):** Order `shopify_order_id`, line `shopify_line_item_id`, product/variant (if present), state label, **"Recorded: `created_at`"** / **"Updated: `updated_at`"** (explicitly labelled as webhook-processing time, with a one-line footnote that this is not Shopify's paid-at timestamp).
- **History:** compact list of prior terminal rows (state + order id + recorded date). Owner, if shown, only as `COL-…`.
- **No controls:** no buttons that mutate sale-link/claim state; display only.

### 8b. Dashboard "Sold — awaiting claim" tile + worklist (Option C part 2)
- Add one count tile: `DB::table('sca_shopify_sale_links')->where('eligibility_state','eligible')->count()` → **"Sold — awaiting claim."**
- Tile links to a Registry index filtered to those exact items (drill-down), via a new index filter (§8c). Place beside `certified_unclaimed`; add a one-line sub-label to `certified_unclaimed` ("not yet sold") to make the distinction legible **without changing its count definition**.

### 8c. Registry index filter feasibility
**Feasible, small.** Add an allowlisted filter (e.g. `sale=awaiting_claim`) that adds `whereExists`/join on `sca_shopify_sale_links` (`eligibility_state='eligible'`) to the existing `EyewearItem::query()` in `index`. This reuses the existing filter/sort/pagination machinery — no new controller, no new subsystem. (The dead `SOLD_AWAITING_CLAIM` lifecycle value is left untouched; this new filter is the real signal.) The dashboard tile's drill-down URL targets this filter.

---

## 9. ACL

- **Item-detail panel:** reuse **`sca.eyewear.view`** — the key already gating `show()`, ownership-history, QR read surfaces. Correct for read-only display.
- **Dashboard tile + Registry filter:** the dashboard route's existing gate (`sca.eyewear`) and the index's existing gate apply. A "sold-awaiting-claim" tile is **not adverse**, so it needs **no** `sca.eyewear.status` (that is a status-*mutation* authority and is NOT appropriate for read-only visibility). No new ACL key is introduced.

---

## 10. Zero-mutation / zero-schema guarantees

- **No schema / no migration.** Every required fact is already persisted in `sca_shopify_sale_links` + `sca_claims` + `sca_item_current_state`. Migration count stays **122**. (Discovery explicitly checked whether existing persisted state is insufficient — it is sufficient; the strong zero-schema preference holds.)
- **Read-only.** All new code is SELECT / `DB::table(...)->where(...)->get()/count()` + Blade rendering. **No INSERT/UPDATE/DELETE**, no sale-link/claim mutation controls, no mark-paid/claimed/revoked actions, no reconciliation engine.
- **No Shopify API calls, no scope/webhook/OAuth change, no secret touched.** Shopify connect/config layer untouched.
- **No PII.** `shopify_customer_ref` (always null) and `webhook_idempotency_key` are never rendered; owner shown only as opaque `COL-…`.
- **No production mutation; no dashboard redesign; no analytics; no SMTP/notification work.**
- Provenance FP (recomputed at m=120) must remain `62b2e42fe409b4ec91f3381b35da819e`; migrations 122; co-tenant smsrocket, `/storage` 404, SCA-038 404-shape, Phase-B loopback-:8080 all unchanged (verified at merge/deploy gates if this is later promoted to implementation).

---

## 11. Exact likely-changed files (if later approved for implementation)

**New:** `packages/Sca/Registry/src/Resources/views/eyewear/partials/sale-claim.blade.php` (or a new tab section inside `show.blade.php`); `tests/Feature/Sca/ShopifySaleClaimVisibilityTest.php`.
**Modified (read-only additions):**
- `packages/Sca/Registry/src/Http/Controllers/EyewearItemController.php` — `show()` adds the sale-link SELECT + safe DTO mapping; `index()` adds the allowlisted `sale=awaiting_claim` filter (join/exists).
- `packages/Sca/Registry/src/Resources/views/eyewear/show.blade.php` — new "Sale / claim" tab/section rendering the partial.
- `packages/Sca/Registry/src/Http/Controllers/DashboardController.php` — add the `sold_awaiting_claim` count; (optional) sub-label on `certified_unclaimed`.
- `packages/Sca/Registry/src/Resources/views/dashboard/index.blade.php` — new tile + drill-down link.

**Untouched:** all services (`SaleLinkService`, `CommerceService`, `ClaimService`, `ClaimWorkflow`, `SaleLinkEventProcessor`), all provenance/sale/claim tables + models, ACL definitions, routes (the existing `admin.sca.eyewear.index/show` + `admin.sca.dashboard.index` already exist; only query params added), Shopify layer, QR/cert/auth/ownership/service/media.

---

## 12. Focused test matrix (zero-mutation; `sca_domain_test`)

1. Item with **no** sale-link → panel shows "Not linked to a Shopify sale"; zero sale-link rows read-only.
2. Item with `eligible` link → headline "Sold — awaiting collector claim"; safe fields (order/line/product/variant/state/recorded date) rendered; **no** customer_ref, **no** idempotency_key, **no** token/secret in HTML.
3. Item with `claimed` link → headline claimed + owner shown only as `COL-…` (assert raw collector id/email absent).
4. Item with `revoked_refund` after a claim → panel shows refunded/terminal + (existing) disputed registry banner intact; ownership preserved (assert `sca_ownership_events` unchanged).
5. Item with `cancelled` tombstone (no prior active link) → panel shows cancelled history, no active link.
6. Item with resale history (multiple rows: cancelled → new eligible) → exactly one active link shown + history list of terminal rows.
7. Dashboard "Sold — awaiting claim" count == `COUNT(*) WHERE eligibility_state='eligible'`; distinct from `certified_unclaimed`.
8. Dashboard tile drill-down → Registry index filtered to exactly the `eligible`-link items (set equality).
9. Registry `sale=awaiting_claim` filter returns exactly the awaiting-claim items; unknown filter value ignored (allowlist).
10. ACL: unauthenticated → login; staff without `sca.eyewear.view` → 403 on the panel; dashboard tile respects dashboard gate; no `sca.eyewear.status` required.
11. Whole feature performs **zero** writes (assert provenance/sale/claim/projection row counts + FP unchanged before/after rendering every view).

---

## 13. Closure criteria

Task is DONE when: staff can see, per SCA item, the current Shopify sale→claim state (not-linked / eligible-awaiting-claim / claimed / cancelled / refunded) with only safe non-PII fields; the dashboard shows a distinct "Sold — awaiting claim" count that no longer conflates never-sold with sold-unclaimed; that count drills down to the exact items via a Registry filter; all surfaces are read-only; zero schema/migration; zero Shopify API/scope/webhook/OAuth/secret change; full SCA gate green; provenance FP (m=120) `62b2e42f…` and migrations 122 unchanged post-deploy.

---

## 14. Recommendation — **Option C** (item-detail panel + dashboard tile/worklist)

**Recommend C.** Both halves reuse existing data, queries, controllers, views, filter machinery, and ACLs — **no new subsystem**:
- The **item-detail panel** answers the per-frame questions (is it sold, which state, safe order ref/date) where staff already work an item.
- The **dashboard tile + drill-down + Registry filter** answers the triage questions (how many sold frames await claim; click to see them) and removes the never-sold vs sold-awaiting-claim conflation.

Neither requires schema; both are strictly read-only over `sca_shopify_sale_links`. A alone would leave the triage conflation unfixed; B alone would leave the per-item detail invisible. C is the smallest change that fully satisfies the stated goal while honoring the zero-schema / no-Shopify-API / read-only constraints.

**NEXT_TASK.md set to this task at discovery/plan stage. No implementation performed. STOP for ChatGPT audit.**

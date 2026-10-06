# NEXT TASK

**STATUS: ACTIVE — SHOPIFY OPERATIONAL LISTING SOP. Executable stage: DISCOVERY/PLAN ONLY (DONE, awaiting audit).**

Promoted 2026-10-06. Deployed baseline `0f86b4af90134de6c60664e16aad440a1d111204`, migrations **120**, FP **`62b2e42fe409b4ec91f3381b35da819e`**. **Shopify Activation remains CLOSED — this task must not reopen OAuth/webhook/scope.**

## Objective

The safest practical operational workflow to list/sell a real SCA-certified frame through Shopify while preserving the proven Shopify→SCA sale/claim linkage. Prefer the least-complex solution that safely handles real inventory.

## Current stage — DISCOVERY/PLAN (complete; STOP for audit)

Plan committed at `docs/SCA-SHOPIFY-OPERATIONAL-LISTING-SOP-DISCOVERY.md`. **Do not implement yet.** Verified findings:

- The deployed receiver maps **only** via the Shopify **line-item property `sca_item_ref`** = the SCA **`public_ref`** (`/^SCA-[0-9A-Fa-f]{12}$/`); NOT sku/metafield/variant. Fail-closed per line (missing→safe skip; malformed/ambiguous/unknown/ineligible/conflict codes); idempotent (HMAC 401, record-then-process-only-if-new, unique indexes). **Quantity is not enforced in code** → one-of-one qty-1 is an operational rule (Shopify inventory = 1).
- The property attaches at the **cart/checkout layer** (product add-to-cart form hidden `properties[sca_item_ref]`, value per-product via a metafield; or Storefront API cart attributes). The **Admin "Custom item" dialog can't set it**, and draft-order creation needs `write_draft_orders` (**ungranted — out of scope**). **No SCA code is required for the receiver.**
- The one real risk is getting the **correct** `public_ref` onto the line item (wrong/mistyped ref = most dangerous).

## Recommended scope (for the NEXT executable stage, if approved) — **Option B**

SOP (Shopify-side listing procedure + pilot checklist) **plus one tiny copy-to-clipboard helper** beside `public_ref` on the SCA item-detail page (`show.blade.php`), reusing `sca.eyewear.view`, no schema. Option A (SOP only, zero code) is defensible; automation (Option C) is rejected (needs write scopes / reopens activation; no safety gap A/B can't cover).

## Hard constraints

Do NOT: change Shopify scopes / add `read_products` / create another app / change webhook topics / alter OAuth callback or webhook registration; mutate the completed dry-run order/item; change claim/ownership/provenance semantics; add schema/migrations; build Shopify product creation/sync automation; build bulk inventory onboarding (queue #5). The theme snippet / metafield / inventory settings are Shopify-side operator configuration, not SCA code.

## Stage gate

**Executable stage is DISCOVERY/PLAN ONLY — complete and committed. STOP for ChatGPT audit.** Implementation is a separate stage requiring explicit promotion. Completing the recommended scope (SOP committed + optional copy helper deployed + pilot checklist available) would **CLOSE** Shopify Operational Listing SOP; a live real-inventory sale is operator-gated.

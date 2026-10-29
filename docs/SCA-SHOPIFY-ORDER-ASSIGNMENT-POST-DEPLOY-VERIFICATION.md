# SCA — Order Assignment: Post-Deployment Staff Interface Verification (READ-ONLY)

**Authorized read-only verification of the deployed interface at prod `eb137bf`. VERDICT: the staff
Order→Eyewear Assignment interface and Administrator permission fix are DEPLOYED and operationally
ready; no code/data blockers.** No Shopify API request (no `getOrder`/reconciliation), no Shopify store
change, no DB write, no session created. 2026-10-29. **STOP.**

## [1] Production SHA / health
Live `/opt/sca-platform` = **`eb137bf905758e7bfa2a9b13a2ce68384340c54f`**, `main`, working tree clean;
loopback `/admin/login → 200`.

## [2] Routes, view, permission middleware
`route:list --path=sca/shopify/order-assign`:
- `GET admin/sca/shopify/order-assign` → `OrderAssignmentController@index`, middleware `web` →
  `Locale` → `ScaAuthenticate` → **`ScaAuthorize:sca.shopify.view`**.
- `POST admin/sca/shopify/order-assign` (`.store`) → `OrderAssignmentController@assign`, middleware
  `web` → `Locale` → `ScaAuthenticate` → **`ScaAuthorize:sca.eyewear.shopify.order-assign`** →
  `ThrottleRequests:60,1`.
The view `order-assign.blade.php` is present in the live tree. Unauthenticated GET to both the
order-assign and operations routes returns **302** (redirect to login in the middleware, before any
controller/Shopify code) — not 500.

## [3] Administrator effective access
All five SCA Shopify ACL keys are present in the merged `config('acl')`: `sca.shopify.view`,
`sca.shopify.reconcile`, `sca.eyewear.shopify.link`, **`sca.eyewear.shopify.order-assign`**, and
**`sca.eyewear.shopify.order-assign.override`**. Prod has one role — **Administrator** (`id 1`,
`permission_type=all`, 1 active user). Authorization is resolved via `bouncer()->hasPermission()`
(the `sca.can`/`ScaAuthorize` middleware and the `OrderAssignmentController` override check), which
grants an `all` role every permission — so the Administrator has effective access to both the Shopify
Operations page and the assignment interface (and, being `all`, the manager override). The combined
regression already proved the Administrator renders Operations at 200 (no 500) post-fix.

## [4] Manager-override separately enforced
`sca.eyewear.shopify.order-assign.override` is a DISTINCT ACL key from the assign permission. The
controller checks it independently (`bouncer()->hasPermission('…order-assign.override')`) and the
service refuses a no-variant-link assignment unless that permission is held AND a reason is supplied —
verified in the regression (a custom role holding only `…order-assign` was refused `SCA_ASSIGN_NO_VARIANT_LINK`).
So for a non-Administrator role the override is withheld by default; only an `all`/explicitly-granted
role has it.

## [5] Authenticated page inspection
No pre-existing authenticated staff session was available, and per the task constraint none was created
(no session creation, password reset, or account change). The authenticated render is therefore
verified indirectly: routes + full middleware chain resolve, the unauthenticated GET redirects (302,
not 500), the Blade view is deployed, and `ShopifyOperationsPermissionTest`/`ShopifyOrderItemAssignmentTest`
(passed in the final regression) exercised the authenticated 200 render + access control. **[6]** No
order ID was submitted and no Shopify `getOrder` was triggered.

## [7] Assignment-audit table
`sca_shopify_order_item_assignments` exists and is **empty (0 rows)**; append-only UPDATE/DELETE
triggers were confirmed present at deploy.

## [8] Existing records unchanged
`sca_krayin` fingerprint unchanged from the deploy: eyewear items **3**, ownership events **5**, claims
**2**, certifications **4**, qr_identifiers **3**, external_claim_grants **1**, Shopify sale_links **1**.
`sca_shopify_reconciliation_runs` = **0** (confirms no `getOrder`/reconciliation was invoked by this
verification).

## [9] Logs
No log entries reference the new assignment functionality (`OrderAssignment`/`OrderItemAssignment`/
`order-assign`/`SCA_ASSIGN_*`/`sca_shopify_order_item_assignments`), and no `2026-10-29` ERROR mentions
them. No genuine errors related to the new functionality. (The earlier benign `route:list --columns`
CLI-typo errors are unrelated operator noise, not application errors.)

## [10] Operational readiness + notes
**READY for staff use — no code or data blockers.** The interface is deployed, routed, ACL-gated, and
error-free; the audit table and append-only protections are in place; the Administrator has access.

Operational considerations (NOT code blockers — configuration/workflow):
1. **Role grants:** only the Administrator role currently holds `sca.eyewear.shopify.order-assign`
   (and `…override`), because it is `permission_type=all`. To let non-Administrator staff use the
   feature, grant those ACLs to their custom roles (standard Krayin role configuration) — the manager
   override should be granted only to managers.
2. **Variant-link vs override at use time:** there are **0** Phase-2 item↔variant links in prod, so
   until staff link an item to its Shopify variant (existing Phase-2 link UI), an assignment will
   require the **manager-override + reason** path (the variant-match path needs a variant link). This
   is by design (fail-closed), but worth noting so operators expect to either pre-link variants or use
   a manager for the first assignments.
3. **Inputs at use time:** staff supply the Shopify **order id** (from the Shopify admin) and the
   pair's **public_ref**; the system then does its own authoritative read-only `getOrder` to verify
   paid/line/variant. (No such call was made during this read-only verification.)

**STOP — deployed interface verified operationally ready at `eb137bf`; Administrator access + separate
manager-override confirmed; audit table empty; provenance/Shopify records unchanged; zero Shopify
interaction. Operational notes (role grants; variant-link-vs-override; use-time inputs) are
configuration/workflow, not blockers. SEPARATE OPEN: Phase-1 first genuine `products/*` webhook receipt
verification.**

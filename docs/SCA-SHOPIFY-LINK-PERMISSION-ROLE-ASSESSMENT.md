# SCA — Shopify Linking Permission: Staff Role Assessment (READ-ONLY)

**Read-only review of SCA staff roles vs the `sca.eyewear.shopify.link` permission at prod SHA `91b88f1`. No role, user, permission, code, or config was modified.** 2026-10-28. **Recommendation below; awaiting approval before any grant.**

## [1] Staff roles present
Production `sca_krayin.roles` has **exactly one role**:

| id | name | permission_type | users |
|----|------|-----------------|-------|
| 1 | **Administrator** | `all` | 1 |

There is **no separate "intake", "authenticator", or "cataloguer" role** — all staff activity runs under the single Administrator role, which (`permission_type='all'`) implicitly holds **every** ACL permission.

## [2] Who has `sca.eyewear.create`
The Administrator role holds it — implicitly, via `permission_type='all'`. (No custom/limited role exists that would hold a subset.) So the single staff user already performs eyewear intake under this role.

## [3] Is `sca.eyewear.shopify.link` registered and ungranted?
- **Registered:** YES. `config('acl')` entry `sca.eyewear.shopify.link` — name "Link Eyewear to Shopify Variant", route `admin.sca.shopify.catalog-search`. It is a distinct **leaf** permission among the 25 `sca.*` keys.
- **"Ungranted":** This needs a nuance. A `permission_type='all'` role has **no per-key grant list** — it holds all keys, so the Administrator role **already effectively has** `sca.eyewear.shopify.link`. The deploy note "ungranted by default" applies to *custom* roles; since the only role here is `all`, the permission is **already active for the Administrator and its one user**. There is no custom role from which it is currently withheld.

## [4] Recommended role to receive the permission
**Administrator (role id 1)** — and it already has it. **No grant action is required** for current staff to use Shopify linking; the single admin user can already reach the selector, link/relink/unlink routes, and create-with-link, because the role is `all`.

If, instead, the intent is to confirm the *narrowest* place the capability should live: it belongs with the intake staff who already hold `sca.eyewear.create` — which today is the Administrator. No other role qualifies because none other exists.

## [5] Is a separate role necessary?
**Not necessary for functionality**, and not required now. A separate, least-privilege **custom** role would only be worth creating if/when **non-admin intake staff** are onboarded — e.g. a "Catalog/Intake Clerk" role granted `sca.eyewear` + `sca.eyewear.view` + `sca.eyewear.create` + `sca.eyewear.shopify.link` (and `sca.eyewear.catalog` for SKU/image) but **not** certification/QR/ownership/status powers. Creating such a role is a role-management change (outside this read-only task) and a staffing/ops decision — recommended only when least-privilege separation is actually needed. With a single Administrator user today, it adds no security benefit.

## [6] Scope check — the permission grants nothing unrelated
`sca.eyewear.shopify.link` is a **distinct leaf** key. It gates only the `ProductLinkController` routes (`catalog-search`, `link`, `relink`, `unlink`) and the create-with-link server-side check. It is **separate** from every sensitive capability, each of which is its own key:

| Capability | Separate ACL key (NOT implied by the link perm) |
|---|---|
| Ownership transfer / claim | `sca.eyewear.ownership.correct`, `sca.eyewear.claim` |
| Certification | `sca.eyewear.certify`, `sca.eyewear.certification.correct`, `sca.eyewear.certificate` |
| QR issuance/reissue | `sca.eyewear.qr.reissue` |
| Authentication | `sca.eyewear.authenticate` |
| Status / retire / invalidate | `sca.eyewear.status` |

Granting **only** `sca.eyewear.shopify.link` (on a custom role) confers **none** of these. The link service itself never creates authentication/certificate/QR/ownership/claim records (proven by the 37/37 regression and the deploy-time non-interference checks). The current Administrator user holds those other powers only because its role is `all`, independent of the link key.

## Recommendation (awaiting approval)
- **No grant action needed:** the sole **Administrator** role already carries `sca.eyewear.shopify.link` via `permission_type='all'`; the feature is usable by current staff now.
- **If/when least-privilege is wanted** (non-admin intake staff): create a dedicated custom role with `sca.eyewear` + `sca.eyewear.view` + `sca.eyewear.create` + `sca.eyewear.shopify.link` (+`sca.eyewear.catalog`), explicitly **excluding** certify/QR/ownership/status/authenticate. This is a separate, approval-gated role-management change.

**STOP — read-only assessment complete. No permissions, users, roles, records, code, or config changed. Awaiting approval before any grant or role creation.**

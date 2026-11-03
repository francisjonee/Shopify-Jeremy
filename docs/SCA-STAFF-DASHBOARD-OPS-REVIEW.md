# SCA — Staff Inventory Dashboard & Operational Safety Review (read-only)

**The staff inventory dashboard is operationally sound and safe to begin real-world processing with —
NO P0. The safety-critical invariants all hold: QR label actions are unavailable for uncertified items
(the "Print label" checkbox is hidden for items without an active QR AND the server silently omits
them), the listing has no one-click/destructive or GET-mutating actions, the irreversible
authenticate→finalize→certify chain is behind typed-word interstitials (FINALIZE / ISSUE) with
double-submit guards and ACLs, metadata correction is append-only and unlocked only for uncertified
items, and a Shopify variant link is explicitly disclaimed as "does not authenticate" in its own panel.
Catalog-derived inventory is separated from authenticated eyewear at the data level (the 205 imports
carry 0 authentications, 0 certifications, 0 QR). Two findings matter before high-volume processing,
both presentation-level and both in production: (P1) the certify/finalize confirmation screens show only
the opaque SCA reference + authentication id — no brand/model/serial/photo — so a staffer cannot
visually confirm the physical pair in hand before the irreversible certify step; and (P1) the green
"Shopify ✓" pill on the listing reuses the same green style as the "Certified" pill, so a catalog link
can be misread as proof of authenticity. The smallest high-value fix is to show the item's brand/model/
serial/photo on the certify-confirm (and finalize/authenticate) screens; the close second is to give the
Shopify-link pill a distinct, non-"certified" style.** Read-only review; no DB write, no imports, no
auth/cert/QR, no printing/ownership, no deployment, no Shopify call, no edge change; production unchanged
at `6e36aa7`. 2026-11-03. **STOP.**

> Written for: the owner (Jeremy) + staff who will process physical eyewear, and the external auditor.
> All findings are in PRODUCTION (`6e36aa7`); the dashboard is deployed. No dev-branch-only issues were
> found in scope (the undeployed `feature/sca-qr-label-pdf` branch is out of scope here).

## Special-attention checklist — verdicts
| Requirement | Verdict | Evidence |
|---|---|---|
| The 205 imports are unverified/uncertified | ✅ holds | ids 7–211 → 0 auth / 0 cert / 0 QR (data); render as INTAKE / Normal with no Certified/QR pill |
| Catalog info must never imply authentication | ⚠️ partial | Shopify panel + catalog editor disclaim it; BUT the green "Shopify ✓" pill looks like "Certified" (P1-2) and the always-visible title/brand/model carry no "unverified" qualifier (P2-1) |
| QR label actions must not appear for uncertified items | ✅ holds | checkbox gated `@if ($canView && $item->cs_qr)`; server omits non-QR ids (both UI + server enforced) |
| Staff must identify the correct physical pair before irreversible certification | ❌ gap | certify-confirm / finalize-confirm show only public_ref + auth #id + result + grade — no brand/model/serial/photo (P1-1) |
| Do not confuse a Shopify variant link with authenticity | ⚠️ partial | disclaimed in the panel, but the green ✓ pill on the card equates visually with certification (P1-2) |

## Findings

### P0 — none
No security/privacy/critical-flow blocker. QR-label gating, no-accidental-mutation, typed-confirm
interstitials, append-only metadata, and catalog/authentication data separation all hold.

### P1 — significant (address before high-volume processing) — both PRODUCTION
| # | Route / view | Problem | Operational risk | Smallest fix |
|---|---|---|---|---|
| P1-1 | `…/certify/confirm` (`eyewear/certify-confirm.blade.php`), `…/authentications/{id}/finalize` (`finalize-confirm.blade.php`), `…/authenticate` (`authentication/create.blade.php`) | The irreversible authenticate→finalize→**certify** screens identify the item by **public_ref + authentication #id + result + grade only** — no brand, model, frame serial, or photo. | A staffer certifying a batch cannot visually confirm the frame in hand matches the record before the permanent, QR-minting step → wrong pair certified / wrong QR minted. This is the top pre-launch gap. | Show the item's brand/model/serial + featured photo on the certify-confirm (and finalize/authenticate) screens — presentation-only (fields already loaded). |
| P1-2 | Registry listing card (`eyewear/index.blade.php` ~L224–234, pill CSS L27) | The "**Shopify ✓**" pill reuses the certification green (`sca-pill-cert`). A linked-but-uncertified import shows a green ✓ with **no** "Certified" pill; authentication state is signalled only by pill presence/absence. | A staffer skimming green ✓ can misread a mere catalog link as authenticity — exactly the "variant link ≠ authenticity" risk. | Give the Shopify-link pill a distinct non-green style/label (e.g. neutral "Catalog-linked"); keep green exclusively for Certified. |

### P2 — usability / safety improvements — all PRODUCTION
| # | Route / view | Problem |
|---|---|---|
| P2-1 | listing card + detail left card (`index.blade.php`, `show.blade.php` L38–44, 160–167) | No explicit "Not authenticated / Unverified" indicator; uncertified is signalled only by absence of pills. The always-visible title/SKU/brand/model/serial for an INTAKE item read like an established identity; provenance disclaimers live only inside the Shopify/catalog tabs. (Reinforces P1-2.) |
| P2-2 | `ItemMetadataCorrectionController` + `show.blade.php` | Metadata-correction events are written **append-only** to `sca_item_metadata_events` but surfaced in **no** staff view — unlike Market Reference and Service corrections, which both render an audit-history table. Staff can't review the correction trail. |
| P2-3 | `AuthenticationController::finalize`, `CertificationController::issue` | Finalize/certify POSTs have typed-word + state-advance protection but **no request-level idempotency token** (contrast item-create, which uses one). Double-submit is caught by the state having already advanced (friendly flash), so the real risk is low. |
| P2-4 | listing + auth/cert/metadata views | Accessibility: page/interstitial titles are `<p>` not semantic headings; most filter inputs lack an associated `<label>`/`aria-label` (placeholder-only, except the date inputs); listing cards are `<div>`s (no list/table semantics); error banners lack `role="alert"`/`aria-live`; several typed-confirm labels aren't programmatically bound (no `for`/`id`). The Shopify pill's archived-vs-active nuance lives only in a `title=` tooltip (not exposed to keyboard/screen-reader). |

## What is working well (no change needed)
- **Search/filter/pagination** (`EyewearItemController::index`): 4-field free-text search (public_ref/brand/model/frame_serial) with LIKE wildcards escaped; allowlisted enum filters, cert-number exact subquery, allowlisted sort + asc/desc, `paginate(20)->withQueryString()`. No injection or unbounded-query risk; Shopify enrichment is one bounded query over the current page (no N+1).
- **QR-label gating**: checkbox hidden for non-QR items AND server-side omission + 50-cap; no per-card download on the listing.
- **No accidental mutation from the listing**: every action is GET navigation or a read-only POST (QR lookup, label sheet) with CSRF; no GET-that-mutates; no one-click delete (no item hard-delete route exists).
- **Irreversibility handling**: finalize and certify are GET confirm interstitials → typed-word POST (FINALIZE / ISSUE), with explicit immutability warnings and server-side double-finalize / double-certify / ineligible-source guards; authenticate pre-selects a no-default placeholder so an accidental submit can't record "Passed"; grade is required-iff-passed and prohibited otherwise.
- **Per-tab clarity**: the Authentication tab reads "Not authenticated… a passed authentication is evidence only — it does not issue a certification"; the Certification tab reads "Not certified…"; a revoked-cert item reads "no current valid certification". The Shopify-link panel states plainly that a link "does not authenticate the item, issue a certificate or QR, or assign ownership."
- **Metadata correction**: append-only, typed `CORRECT`, mandatory reason, stale-guard via `expected_event_count`; brand/model editable only while uncertified (`pdfFieldsLocked=false` when no current cert).
- **Error/empty states** are copy-rich and non-leaking; domain exceptions are mapped to safe messages, 404s use a real-status error view.

## Smallest high-value fixes (recommended, in order)
1. **Show the physical-pair identity on the certify/finalize/authenticate screens** (brand + model + frame serial + featured photo), so staff can confirm the frame in hand before the irreversible certify step (P1-1). Presentation-only: the item fields are already available to the controllers; add them to the three blades. Highest safety value for real-world processing.
2. **Distinguish the Shopify-link pill from certification** (non-green style/label, e.g. "Catalog-linked"), and optionally add an explicit "Not authenticated" chip on uncertified cards (P1-2 + P2-1). Presentation-only.
3. (Lower) Surface the metadata-correction audit history in the detail page like Market Reference/Service (P2-2); and the accessibility pass (P2-4).

## Safety posture (this task)
Read-only review. No production DB write; no imports or metadata changes; no authentication/
certification/QR generation; no printing or ownership actions; no deployment/migration; no Shopify API
call; no edge change; secure claiming not activated; the 205 imported records untouched. Production
unchanged at `6e36aa7`.

**STOP — Staff dashboard is operationally safe (NO P0): QR labels unavailable for uncertified (UI +
server), no accidental mutations, typed-confirm + double-action guards, append-only metadata, catalog
link disclaimed, 205 imports = 0 auth/cert/QR. P1 (both prod, presentation): (1) certify/finalize
confirm screens show no brand/model/serial/photo — staff can't visually confirm the physical pair before
the irreversible step; (2) green "Shopify ✓" pill looks like the green "Certified" pill. P2: no explicit
"Not authenticated" indicator; metadata-correction audit history not surfaced; no idempotency token on
finalize/certify; a11y (headings/labels/aria). Smallest high-value fix: add brand/model/serial/photo to
the certify-confirm (and finalize/authenticate) screens. Read-only; nothing changed; prod `6e36aa7`
intact.**

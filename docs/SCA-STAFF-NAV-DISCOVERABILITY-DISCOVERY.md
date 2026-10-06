# SCA Staff Navigation / Discoverability — discovery + plan (PLAN ONLY)

**Date:** 2026-10-06 · **Status: DISCOVERY + PLAN ONLY. No implementation-repo, production, or DB change.** · Deployed baseline `30b680f`, migrations **120**, FP `62b2e42f`. Promoted task; executable stage = DISCOVERY/PLAN ONLY. For ChatGPT audit.

**Goal:** make already-built staff capabilities reachable naturally, without knowing hidden URLs — discoverability only, no new functionality, preserving existing ACLs.

---

## 1. Current navigation structure (as deployed)

**Mechanism:** each SCA package ServiceProvider merges a `Config/menu.php` into Krayin's `menu.admin`; the sidebar renders `menu()->getItems('admin')`. Only Foundation/Registry/Shopify ship a `menu.php`.

**All current SCA top-level sidebar entries (exactly two):**
| Label | Route | menu key | ACL | source |
|---|---|---|---|---|
| SCA Eyewear Registry | `admin.sca.eyewear.index` | `sca-eyewear` | `sca.eyewear` | `Registry/.../Config/menu.php:7-13` |
| SCA Shopify Integration | `admin.sca.shopify.index` | `sca-shopify` | `sca.shopify` | `Shopify/.../Config/menu.php:7-13` |

Foundation's `menu.php` returns `[]` (the old placeholder was removed in SCA-PILOT-HARDENING-025).

**Documented structural constraint (not a defect):** Krayin forces menu keys to be **single-segment** (`Arr::undot`), so a **dotted ACL key** (e.g. `sca.collector.support`, `sca.eyewear.ownership.correct`) can **never** be a menu key. This is exactly why SCA surfaces dotted-ACL capabilities as **in-page, permission-gated buttons** rather than sidebar items (documented in `eyewear/index.blade.php:53-58`). Any plan must respect this — a naive sidebar entry for a dotted-ACL capability cannot be ACL-filtered by Krayin's menu and would either hide from everyone or show to everyone (a link that then 403s). **The established SCA pattern = in-page permission-gated button at the natural staff location.**

---

## 2. Hidden vs reachable staff capabilities (audit)

Every SCA admin capability other than the two sidebar entries is a dotted-ACL capability surfaced as a permission-gated in-page control:
| Capability | ACL | Reached from |
|---|---|---|
| Eyewear registry index | `sca.eyewear` | **Sidebar** |
| Shopify integration | `sca.shopify` | **Sidebar** |
| Collector support (SCA-040) | `sca.collector.support` | **Button on Eyewear index** (`index.blade.php:59-61`) + owner-ref deep-links |
| Adverse/registry-status queue | `sca.eyewear.status` | Button on Eyewear index (`index.blade.php:62-64`) + item detail |
| Status manage (resolve/retire/invalidate/recover) | `sca.eyewear.status` | Status queue + item detail (`show.blade.php:192`) |
| Metadata correction (SCA-046) | `sca.eyewear.metadata.correct` | Item detail (`show.blade.php:161-163`) |
| Certification correction (SCA-038) | `sca.eyewear.certification.correct` | Item detail (`show.blade.php:376-378`) |
| QR reissue | `sca.eyewear.qr.reissue` | Item detail (`show.blade.php:360-362`) |
| Authenticate / certify | `sca.eyewear.authenticate` / `.certify` | Item-detail workflow |
| External claim link | `sca.eyewear.claim` | Item detail (`show.blade.php:211-217`) |
| Service event / documents / certificate PDF / catalog / QR label+batch | various | Item detail |
| Ownership **history** | `sca.eyewear.view` | Item detail **only when `$provenance['ownership'] > 0`** (`show.blade.php:235-236, 479-480`) |
| **Ownership correction** (SCA-035) | `sca.eyewear.ownership.correct` | **Only from the ownership-history page** (`ownership-history.blade.php:11-13`) |

**True raw-URL-only capability found: exactly one** — the ownership-correction (and the ownership-history page itself) for a **zero-ownership item**. Everything else is reachable from the sidebar, the Eyewear-index toolbar, or the item-detail page.

---

## 3. Collector Support (SCA-040) — exact gap

- Route `admin.sca.collector.support.index` / `.show` (`admin-routes.php:145-151`), controller `CollectorSupportController`, views `collector/support-index.blade.php` + `support-show.blade.php`, ACL `sca.collector.support` (`acl.php:92-95`).
- **Reachability: already discoverable** — a permission-gated **"Collector support"** button on the Eyewear Registry index (`index.blade.php:59-61`), plus owner-ref deep-links from item detail and ownership history. It is **not** raw-URL-only.
- **Correct navigation location:** the Eyewear Registry index **is** the SCA staff landing surface (it is the sidebar entry), and the button already lives there following the documented dotted-ACL pattern.
- **Verdict:** this is **optional convenience, not a true navigation gap.** A dedicated sidebar entry is **not recommended** — it fights the single-segment-menu-key/ACL-filter constraint and would risk showing an unauthorized link (route still 403s). The SCA-050/053 "collector-support in no menu / hidden route" note is **already mitigated** by the existing index button. **Smallest safe exposure = the existing button (no change required).** (Optional, if the operator wants a second entry point: add the same `@if(bouncer()->hasPermission('sca.collector.support'))` button to one more natural staff page — marked optional below, not required.)

---

## 4. Ownership Correction (SCA-035) — exact gap (the real one)

- Routes `admin.sca.eyewear.ownership.correct.confirm` (GET interstitial) + `.correct` (POST apply) (`admin-routes.php:69-76`), controller `OwnershipCorrectionController`, view `ownership-correct.blade.php`, dedicated ACL `sca.eyewear.ownership.correct` (`acl.php:73-76`).
- **Current reachability:** Eyewear index → item detail → "view ownership history" → "Correct ownership…". The item-detail → ownership-history link renders **only when `$provenance['ownership'] > 0`** (`show.blade.php:235-236, 479-480`). The "Correct ownership…" link lives on the ownership-history page (`ownership-history.blade.php:11-13`), gated by permission only (shown regardless of ownership state).
- **Confirmed problems (both real):**
  1. **≥2 hops** even in the happy path (item detail → history → correct).
  2. **Zero-ownership dead-end:** for an unowned/unclaimed item `$provenance['ownership'] == 0`, so item detail renders **no** link to ownership history, and therefore **no** path to ownership correction — reachable **only by typing the URL**. This matches the SCA-050 report exactly.
- The item-detail page (`show.blade.php`) contains **no** direct reference to the ownership-correction route today.
- **Correct item-detail action:** add a direct, permission-gated **"Correct ownership…"** link on `show.blade.php`, pointing to the existing `admin.sca.eyewear.ownership.correct.confirm` route, **shown to authorized staff regardless of ownership state** (fixing both the hop-count and the zero-ownership dead-end). The correction confirm/apply controller already enforces all correction rules — this is **navigation only**, no change to the workflow or ownership semantics.
- **Authorization:** gate the link with `bouncer()->hasPermission('sca.eyewear.ownership.correct')` (the existing dedicated ACL). Visibility never grants authorization — the route guard is unchanged and still 403s for anyone without the permission; no permission is broadened.

---

## 5. Does any other capability belong in this task?

**No.** Every other built capability is already reachable (sidebar, Eyewear-index toolbar, or item detail), all permission-gated. The adverse-status queue, corrections, claim links, authenticate/certify, service, documents, QR label/reissue are all surfaced in-page. No additional raw-URL-only staff capability was found. (Expanding into a dashboard/worklists is a **separate** queued item — explicitly out of scope here.)

---

## 6. Recommended complete scope (smallest that closes the gap)

1. **(Required) Ownership-correction item-detail action** — add a permission-gated "Correct ownership…" link to `eyewear/show.blade.php` (in the Provenance box and/or the History tab, beside the existing "view ownership history" link), shown to `sca.eyewear.ownership.correct` holders **regardless of ownership count**, linking to the existing confirm route. Closes the zero-ownership dead-end and the ≥2-hop path.
2. **(Optional, likely no-change) Collector Support** — already discoverable via the index button; recommend **no change**. If the operator explicitly wants a second entry point, add the same permission-gated button to one additional natural page (e.g., alongside the ownership/history context) — still a dotted-ACL in-page button, never a sidebar ACL hack.

**Out of scope / explicitly NOT doing:** new sidebar menu entries for dotted-ACL capabilities; any dashboard/worklists; any change to ownership semantics, the correction workflow, provenance, collector behavior, QR, certification, Shopify, SMTP; schema/migrations; public routes; Caddy/Docker/infra; ACL broadening. No replacement workflows.

## 7. Exact expected files affected
- `packages/Sca/Registry/src/Resources/views/eyewear/show.blade.php` — add the permission-gated "Correct ownership…" link (navigation only).
- *(optional)* one additional view if the operator opts into a second Collector-support entry point — default: none.
- `tests/Feature/Sca/` — a focused test (new `StaffNavigationDiscoverabilityTest` or extension of an existing eyewear-show/ownership test).

**No** controller, route, ACL config, menu.php, schema, or migration file changes are required for the recommended scope.

## 8. ACL / security considerations
- Reuse the existing `sca.eyewear.ownership.correct` ACL; the link is `bouncer()->hasPermission(...)`-gated.
- Navigation visibility must not grant authorization — the `OwnershipCorrectionController` route middleware (`sca.can:sca.eyewear.ownership.correct`) is unchanged; an unauthorized staffer who somehow reaches the URL still gets 403, and the link is simply absent for them.
- No permission is broadened; no ACL key added or changed.

## 9. Tests required
- Item detail shows the "Correct ownership…" link to a staff user **with** `sca.eyewear.ownership.correct` — including for a **zero-ownership** item (the gap case).
- Item detail does **not** show the link to a staff user **without** that permission; and that user still receives **403** on the confirm route (visibility ≠ authorization).
- The link targets the existing `admin.sca.eyewear.ownership.correct.confirm` route for the item.
- Regression: existing ownership/provenance/staff tests (e.g. SCA-033/035 suites) + full `tests/Feature/Sca` stay green; zero provenance mutation; no schema change (migrations 120).

## 10. Does completing this CLOSE Staff Navigation / Discoverability?
**Yes.** The ownership-correction item-detail link closes the single confirmed raw-URL-only gap (incl. the zero-ownership dead-end); Collector Support and every other capability are already discoverable from the sidebar / index toolbar / item detail. After this, there is no built staff capability that requires knowing a hidden URL. Dedicated sidebar entries for dotted-ACL tools and a staff dashboard/worklists are **separate optional** items (the latter already queued), not part of closing discoverability.

**DISCOVERY/PLAN ONLY — no code/deploy/DB/production change performed.** See `TASK_QUEUE.md` (RECONCILED REMAINING WORK #1), `docs/SCA-050-PRODUCT-EXPERIENCE-OPERATIONS-AUDIT.md`, `docs/SCA-053-PILOT-READINESS-AUDIT.md`.

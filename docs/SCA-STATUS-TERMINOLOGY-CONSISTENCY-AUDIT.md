# SCA Status/terminology consistency — readiness / design audit (READ-ONLY, DO NOT IMPLEMENT)

**Date:** 2026-10-02 · **Deployed baseline:** main `f85e8c5`, migrations **120**.
**Status: AUDIT / DESIGN ONLY — zero changes; no DB/projection rebuild; no status/cert/QR/ownership/auth/
gallery mutation; no schema/service/SMTP/infra. For ChatGPT review. ACTIVE / NEXT_TASK remain unpromoted.**

Addresses app-audit P2-1 (cross-surface terminology cluster: [A-F4/F10/F24], [C-F5], [B2], [B3], [B4]).

## 1. Authoritative sources (the independent facts)

Five **independent** facts live in the `sca_item_current_state` projection (one row/item; rebuilt from the
append-only logs). They are separate concepts and must not be collapsed:

| Concept | Authoritative column / source | Meaning (what it may truthfully claim) |
|---|---|---|
| **Ownership** | `current_owner_collector_id` (null = unowned) | a collector currently owns it — **not** a certification claim |
| **Certification (current)** | `current_certification_id` (null = none) | holds an **issued, non-revoked, non-superseded** cert; **revoked ⇒ null ⇒ not certified** |
| **Authentication** | `sca_authentications` (a finalized `passed` row) | SCA physically authenticated it at least once (weaker than "currently certified") |
| **QR** | `active_qr_identifier_id` (null = none) | an active permanent QR identity exists |
| **Registry status** | `registry_status` ∈ normal/lost/stolen/recovered/disputed/retired/invalidated | adverse/administrative condition, orthogonal to ownership & certification |
| **lifecycle_state** (derived) | `ProjectionService::deriveLifecycleState` | **CONFLATES owner+cert** — see §2; an internal workflow label, not a truth source for cert/owner |

The collector surface already models certification independently and correctly via SCA-052
`CollectionService::authenticityDisplay(currentlyCertified, authenticated, everCertified)` → "Authenticated &
Certified" (green ✓) **iff** currently certified, else "Authenticated — no active certification" / "…— not
certified" / "Recorded". **This is the pattern to generalize to all surfaces.**

## 2. The core conflation (confirms app-audit [B4])

`deriveLifecycleState()` returns `REGISTERED` when an owner exists **before** it checks certification:
```
if (owner != null) return 'REGISTERED';     // ← wins first
if (currentCert != null) return 'CERTIFIED';
… AUTHENTICATED | AUTH_FAILED | INTAKE
```
Consequences:
- Once an item is owned it is **always** `REGISTERED`, whether its cert is current OR revoked — the two are
  indistinguishable in `lifecycle_state`. `CERTIFIED` only ever appears for an **unowned**-but-certified item.
- Any surface that reads "certified" from `lifecycle_state` makes a certification claim from the **ownership**
  axis — the wrong source.

## 3. Concrete current misleading / inconsistent UI

1. **Passport over-sources certification from lifecycle.** `PassportPresenter::provenanceSummary('REGISTERED')`
   = **"Certified and registered in the SCA provenance registry"** — asserts *Certified* from `lifecycle_state`
   (an ownership fact). It is truthful today **only** because `PassportResolver` independently requires a
   current issued cert (revoked ⇒ 404), so the page never renders for an uncertified item. The claim is right
   but **sourced from the wrong fact** — fragile and conceptually wrong; a reader/maintainer can't see the
   guarantee.
2. **Two registry-status prose maps disagree** (same `registry_status`, different wording):
   | status | Passport (`PassportPresenter::registryBanner`) | Collector (`CollectionService::registryBanner`) | Admin |
   |---|---|---|---|
   | disputed | "Registry status: under review" | "Under review — a registry dispute is being resolved by SCA" | raw `disputed` |
   | invalidated | "Registry status: invalidated — not verified" | "Invalidated — this SCA record is no longer valid" | raw `invalidated` |
   | recovered | *(no case → "No adverse reports on the SCA registry")* | "Recovered — no active loss report" | raw `recovered` |
   | lost / stolen | "Reported lost" / "Reported stolen" | same | raw `lost`/`stolen` |
   | retired | "Retired from the SCA registry" | same | raw `retired` |
3. **Admin shows raw SCREAMING_SNAKE / raw enums**, and is self-inconsistent: item-detail Overview
   (`eyewear/show.blade.php:181-182`) renders `lifecycle_state` = **"REGISTERED"** and `registry_status` =
   **"normal"** raw, while the index **card** (`index.blade.php:159`) humanizes the same value to
   **"Registered"**, and the lifecycle **filter dropdown** (`:108`) lists raw `INTAKE / AUTHENTICATED /
   CERTIFIED / REGISTERED / AUTH_FAILED / SOLD_AWAITING_CLAIM`. Owner shows as raw **"Collector #<id>"**
   (`:183`) — see app-audit [A-F9].
4. **Collector `statusLabel(lifecycle_state)`** ("Owned & registered" / "Certified" / "Authenticated" /
   "Recorded") overlaps the independent SCA-052 cert badge and inherits the conflation: an owned+current-cert
   item and an owned+revoked-cert item both read **"Owned & registered"** (the cert difference is shown only
   by the separate SCA-052 badge — correct, but `statusLabel` can never say "Certified" once owned).

## 4. Canonical state/label matrix

Legend for the proposed model: compose **independent** badges from the authoritative columns; never a single
lifecycle label on a customer surface.

| Domain concept | Raw value | Authoritative source | Admin now | Collector now | Passport now | **Recommended canonical wording** |
|---|---|---|---|---|---|---|
| Ownership — owned | owner id set | `current_owner_collector_id` | "Collector #42" (raw id) | "Registered to you" (badge) | *(not shown)* | Admin: **"Registered to <COL-ref>"**; Collector: **"Registered to you"**; Passport: owner never shown |
| Ownership — unowned | null | same | "Unclaimed" | n/a | n/a | **"Unclaimed"** (admin) |
| Certification — current | cert id set | `current_certification_id` | (cert tab) | **"Authenticated & Certified"** ✓ (SCA-052) | fixed "Authenticated & Certified" | **"Certified by SCA"** (+ "Authenticated & Certified" when a passed auth also exists) |
| Certification — revoked / none | null | same | (cert tab shows revoked) | "Authenticated — no active certification" / "… not certified" | **page 404s** (resolver) | **"Not currently certified"** (never "Certified") |
| Authentication only | passed+finalized, no current cert | `sca_authentications` | (auth tab) | "Authenticated — not certified" | n/a | **"Authenticated by SCA"** (weaker than Certified; never "Verified/Authentic" alone) |
| normal + certified | lifecycle REGISTERED/CERTIFIED | owner + cert cols | "REGISTERED" raw | "Owned & registered" + ✓ badge | "Certified and registered" | Badges: **Registered · Certified** (· QR active) |
| normal + uncertified (owned, cert revoked) | lifecycle REGISTERED | owner set, cert null | "REGISTERED" raw (looks certified-ish) | "Owned & registered" + "no active certification" | 404 | Badges: **Registered · Not currently certified** |
| lost | registry lost | `registry_status` | raw "lost" | "Reported lost" | "Reported lost" | **"Reported lost"** (all) |
| stolen | registry stolen | same | raw "stolen" | "Reported stolen" | "Reported stolen" | **"Reported stolen"** (all) |
| recovered | registry recovered | same | raw "recovered" | "Recovered — no active loss report" | *(no case → "No adverse reports")* | **"Recovered — no active loss report"** (all; passport add the case) |
| disputed | registry disputed | same | raw "disputed" | "Under review — a registry dispute is being resolved by SCA" | "Registry status: under review" | **"Under review"** (one agreed phrasing all surfaces) |
| retired | registry retired | same | raw "retired" | "Retired from the SCA registry" | "Retired from the SCA registry" | **"Retired from the SCA registry"** (all) |
| invalidated | registry invalidated | same | raw "invalidated" | "Invalidated — this SCA record is no longer valid" | "Registry status: invalidated — not verified" | **"Invalidated — this SCA record is no longer valid"** (one phrasing all) |
| active QR | qr id set | `active_qr_identifier_id` | token shown | (gallery/passport link) | "Active" | **"QR active"** (admin badge); customer surfaces need not label it |
| no active QR / revoked | null | same | — | — | n/a | **"No active QR"** (admin only; passport 404s) |

## 5. What each potentially-misleading term must mean before UI use

- **Registered** = *currently owned by a collector* (ownership axis). **Not** a certification claim. On the
  public passport (no owner shown) use "recorded in the SCA registry", never "registered to you".
- **Certified** = holds a **current issued** certification (`current_certification_id != null`); a revoked or
  superseded-without-successor cert is **not** certified.
- **Authenticated** = a finalized **passed** authentication exists — weaker than Certified. Use "Authenticated
  by SCA".
- **Verified / Authentic** — **avoid as bald claims.** "Verified" is ambiguous (verified what?); "Authentic"
  asserts more than the evidence. Prefer the precise, evidence-bound "Authenticated & Certified by SCA". The
  **public passport must not claim more than a finalized passed authentication + a current issued cert
  support** — which is exactly what the resolver guarantees, so the wording should be *derived from those two
  facts*, not from `lifecycle_state`.
- **Recovered** = a previously lost/stolen item the owner marked found; a *neutral* "no active loss report",
  not a positive quality claim.
- **Invalidated** = staff terminal: the SCA record is no longer valid → "Invalidated — this SCA record is no
  longer valid" / passport "not verified".
- **Retired** = staff terminal: withdrawn from the active registry → "Retired from the SCA registry".

## 6. Design rule applied — separate badges, not one label

Do **not** manufacture one ambiguous lifecycle label. Compose independent badges from the authoritative
columns, e.g. admin item header: **`Registered to COL-… · Certified · QR active · Registry: normal`**;
collector keeps its two-signal model (ownership line + SCA-052 cert/auth badge + registry banner); passport
shows **certification/authentication** (from the cert+auth facts the resolver guarantees) + the **registry
banner** — never a lifecycle-derived "Certified". Keep `lifecycle_state` as an **internal/admin workflow**
label only (humanized: Intake / Authenticated / Auth failed / Certified / Registered), explicitly **not** a
cert/owner truth source on customer surfaces.

## 7. Shared presenter — warranted (narrowly)

**Yes — one SCA-owned label/presenter boundary**, because the SAME domain facts are rendered on Admin +
Collector + Passport and currently drift (two disagreeing registry maps, raw admin enums, lifecycle-sourced
cert claim). Recommend a small `Sca\Provenance\Support\ItemStateLabels` (or a presenter in `Sca\Foundation`)
exposing pure functions over the already-available facts:
- `registryStatus(string): string` — the single canonical registry map (resolves the disagreements; includes
  `recovered`);
- `certification(bool currentlyCertified, bool authenticated, bool everCertified): {label,tone,certified}` —
  generalize SCA-052 `authenticityDisplay` here so all three share it;
- `ownership(...)`, `qr(bool active)`, and `lifecycleAdmin(string)` (humanize for admin workflow only).
Each surface composes these into its own layout (admin dense badges, collector friendly, passport public).
**Scope it to a label map + thin assembler — not an oversized abstraction**; move SCA-052's logic in and have
the collector/passport/admin call it. This satisfies "do not put domain decisions into three Blade files"
without over-engineering.

## 8. Does the projection give each surface enough? — YES. Schema/service change needed? — NO.

Every fact required is already in `sca_item_current_state` (+ `sca_authentications` for the ever-authenticated
flag the collector already reads). **No read-model addition, no schema/migration, and no change to
`deriveLifecycleState` or any projection rebuild is necessary** — this is a pure **presentation/read-model**
correction. (A design note: making `deriveLifecycleState` cert-aware would require rebuilding production
projections — a write — and is **explicitly not recommended**; surfaces simply stop treating `lifecycle_state`
as a cert/owner claim and compose the independent columns instead. This task must not reinterpret history or
rebuild projections.)

## 9. Smallest implementation scope (for a future task)

1. Add the shared `ItemStateLabels` (label map + certification/registry/ownership/qr/lifecycleAdmin helpers);
   fold SCA-052 `authenticityDisplay` into it (collector calls the shared one — behavior identical).
2. **Passport:** replace `provenanceSummary('REGISTERED')`'s "Certified and registered" with wording derived
   from the certification+authentication facts via the shared helper; route `registryBanner` through the
   shared registry map (adds the `recovered` case). No change to the resolver/404 contract.
3. **Collector:** route `registryBanner` + the cert/auth badge through the shared helper (no visible change if
   wording is preserved); optionally retire the lifecycle-derived `statusLabel` in favor of the
   ownership+certification badges so an owned+revoked-cert item reads "Registered · Not currently certified".
4. **Admin:** humanize `lifecycle_state` (card==detail), the filter dropdown, `registry_status`, and
   `intake_type` via the shared helpers; render owner as the `COL-…` ref ([A-F9]); show the independent badges
   (Registered · Certified · QR active · Registry) on the item header.
Scope = one shared support class + presenter wiring + the Blade/controller edits above + tests. **No schema,
no service/domain logic change, no projection rebuild.**

## 10. Regression plan (Admin + Collector + Passport)

- **Shared unit test** (`ItemStateLabelsTest`): every `registry_status` → exact canonical label (one source of
  truth, proving passport==collector==admin agree); certification helper truth table (currentlyCertified /
  authenticated-only / ever-certified-but-revoked / none); no SCREAMING_SNAKE in any returned label.
- **Passport** (`PublicPassportTest` additions): a certified item's page states certification sourced from the
  cert fact (not lifecycle); a `recovered` item shows the canonical recovered banner; a **revoked** cert still
  → constant-shape 404 (SCA-038 unchanged); wording asserts no claim stronger than "Authenticated & Certified".
- **Collector** (`CollectorItemDetailParityTest`/`Collection...`): an **owned + revoked-cert** item shows
  **Registered + Not currently certified** (SCA-052 green ✓ absent); registry banner matches the canonical map.
- **Admin** (`CatalogGridTest`/new): index card label == detail Overview label (both humanized, no
  SCREAMING_SNAKE); registry/intake humanized; owner rendered as `COL-…`.
- All existing SCA-038 (revoked→404) and SCA-052 (green ✓ ⇔ current cert) invariants remain green.

## 11. Explicit conclusion

**No schema, service, domain, or projection change is necessary.** The defect is presentation-level
inconsistency plus a certification claim sourced from the wrong (ownership) fact. The fix is a **shared
read-model label boundary** feeding Admin, Collector and Passport, composing the **independent** authoritative
columns as **separate badges** — never one conflated lifecycle label, and never a passport claim stronger than
the certification/authentication evidence. **Recommendation: GO for a presentation-only consistency task** at
the scope in §9 (push-only → review → governed merge/deploy). **AUDIT ONLY — awaiting ChatGPT review;
ACTIVE/NEXT_TASK remain unpromoted.**

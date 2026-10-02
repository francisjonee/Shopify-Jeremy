# SCA Public Passport — Trust + Safety UX Design Audit (READ-ONLY)

**Date:** 2026-10-02 · **Baseline:** deployed main `a594ea8`, migrations **120**.
**Status: AUDIT / DESIGN ONLY. No code, DB, resolver, status, QR, cert, schema, env, /storage, infra change.
ACTIVE/NEXT remain unpromoted. STOP for ChatGPT / operator review.**

Scope: how the *already-existing* authenticity / certification / QR / registry facts are **communicated** to a
member of the public who scans a permanent SCA QR. This is **not** a lifecycle/backend audit. The core
principle is honored throughout: **authenticity and registry/adverse status are independent facts**, and this
audit proposes **no** change to the underlying state model.

Files traced (all under `packages/Sca/Passport/`, plus the shared label map):
`Http/Controllers/PassportController.php`, `Services/PassportResolver.php`, `Presenters/PassportPresenter.php`,
`Support/PublicAllowlist.php`, `Http/Middleware/PublicPassportHeaders.php`, `Config/passport.php`,
`Routes/public-routes.php`, `Resources/views/passport/{layout,show,not_found}.blade.php`, and
`Sca/Provenance/src/Support/ItemStateLabels.php` + `Services/{StatusService,ProjectionService}.php`.

---

## 1. Current Passport information hierarchy (top → bottom, as deployed)

`passport/layout.blade.php` + `passport/show.blade.php`:

1. **[Preview banner]** — dark-red block "SCA DEVELOPMENT PREVIEW — not the permanent verification address"
   (only when `sca-passport.preview` is truthy; prod `.env` sets `SCA_PUBLIC_PREVIEW=0`, so off in prod).
2. **Brand header** — a 46px dark **text** tile literally reading "SCA" (not the real logo image), then
   "Second Chance Authenticators" / "Provenance & authenticity verification".
3. **Card:**
   - **Big green pill badge** `✓ {authenticity_status}` — i.e. **"✓ Authenticated & Certified"**, centered,
     bold, green (`#dcfce7`/`#166534`). Visually dominant.
   - Gray sub-line `provenance_summary` = "Certified in the SCA provenance registry".
   - **SCA reference** (20px, bold).
   - **Catalog image** (if any), `max-height:240px`.
   - A flat list of equal-weight gray label/value rows: Item, Year, Country of origin, Materials, **Authenticity**
     ("Valid — current certification"), Certification No., Certified (date), Condition, Authenticated (date),
     **SCA identity** ("Active"), and **last: Registry** (the adverse status string).
4. **Footer** — "Second Chance Authenticators — public verification".

The page is **100% server-rendered, no JavaScript** (CSP `default-src 'none'`, no `script-src`), inline styles
only, `img-src 'self' data:`. Any later UI must therefore be **HTML/CSS-only** (consistent with the CSS-only
gallery/tab work).

## 2. State-by-state public behavior matrix (resolver-verified)

The resolver (`PassportResolver::resolve`) renders a **200 only** when the token is well-formed (`^[0-9a-f]{32}$`),
is the item's **current active QR**, the item has a **current issued certification**, and that cert's source
authentication is **passed + finalized**. Registry/adverse status is **never consulted by the resolver** — it is
purely a presented field. `StatusService` + `ProjectionService` confirm status events change **only**
`registry_status`; they never touch `current_certification_id` or `active_qr_identifier_id`. Therefore:

| Scenario (item is certified + active QR unless noted) | HTTP | What the public sees |
|---|---|---|
| normal / clear | **200** | Green badge + Registry "No adverse reports on the SCA registry" |
| **recovered** (resolved loss) | **200** | Green badge + Registry **"No adverse reports"** — resolved loss is **deliberately shown as CLEAR** to the public (privacy rule; owner still sees "Recovered" on their own surface) |
| **lost** | **200** | Green badge **+** Registry "Reported lost" (buried last row) — *tested live: `PublicPassportPilotTest::pp2`* |
| **stolen** | **200** | Green badge **+** Registry "Reported stolen" (buried last row) — *tested live: `pp3`* |
| **disputed / under review** | **200** | Green badge + Registry "Under review" |
| **retired** | **200** | Green badge + Registry "Retired from the SCA registry" — **does NOT fail closed** |
| **invalidated** | **200** | Green badge + Registry **"Invalidated — this SCA record is no longer valid"** — **does NOT fail closed**; green all-clear over a "no longer valid" line |
| revoked / no current certification | **404** | constant-shape "could not be verified" |
| reissued / inactive / stale QR | **404** | constant-shape 404 (old token never resolves after reissue) |
| malformed / bogus token | **404** | constant-shape 404 (format gate before any DB access) |

**Key structural fact:** on *every* 200 page, trust-questions 1–3 (authenticated? currently certified? QR
active?) are **always "yes" by construction** — otherwise it would be a 404. So the **only** variable that
distinguishes a clean item from a reported-stolen or invalidated one is the **single last gray "Registry" row.**

## 3. Exact problems with the current presentation

- **P-1 (safety, high): adverse status is visually subordinate to a constant green badge.** The green
  "✓ Authenticated & Certified" pill is the loudest element on *every* passport, including lost/stolen/disputed/
  retired/invalidated items. The adverse signal is the **last** row in a flat gray list, same weight as "Country
  of origin", typically **below the image and below the fold on a phone**. A scanner's one-glance takeaway is
  "green ✓ = all good," which is false for an adverse item. The live tests (`pp2`/`pp3`) confirm green + adverse
  **co-render** with no prominence difference.
- **P-2 (safety, high): "invalidated" and "retired" render a full green passport.** "Invalidated — this SCA
  record is no longer valid" under a green "Authenticated & Certified" badge is internally contradictory to a lay
  reader. Current policy is **200, not fail-closed** (resolver ignores registry status). Whether these two
  terminal states should fail closed is a **domain/resolver policy decision** (see OP-DECISION-1) — **not** changed
  here.
- **P-3 (clarity): no registry severity signal.** `ItemStateLabels::registryStatus()` returns plain strings with
  **no tone/severity metadata**; the Blade renders them all identically. There is no visual difference between
  "No adverse reports" and "Reported stolen."
- **P-4 (comprehension): a first-time scanner is not told what any of it means.** No explanation of what SCA is,
  what the Passport asserts, what "Authenticated & Certified" does (and does **not**) mean, that it does **not**
  establish current ownership, or what to do if it says Lost/Stolen/Under review.
- **P-5 (trust/consistency): the brand is a text "SCA" tile, not the real SCA logo** used on the admin surface,
  so the public verification page looks less legitimate than the internal one.
- **P-6 (ownership misread): "Authenticity: Valid — current certification" + a confident green badge** can be
  misread by a buyer as "safe to buy / seller is the rightful owner." Authenticity ≠ lawful possession; nothing
  on the page states this.

## 4. Proposed safety hierarchy / wireframe (TEXT — not implemented)

Goal: **an adverse status can never be mistaken for all-clear merely because the item is authentic.** Keep the
authenticity fact truthful and visible, but make the registry state the **top, color-coded, unmissable** element
when it is adverse. Proposed rendering order inside the card:

```
[ preview banner — only if explicitly enabled ]
[ SCA logo + "Second Chance Authenticators — Provenance & authenticity verification" ]

┌───────────────────────────────────────────────┐
│  REGISTRY STATUS BANNER  ← FIRST, full-width,   │   severity-colored:
│  color + icon + HEADLINE + one-sentence body    │     clear   → green  ✓
│  (adverse = red/amber, sticky at top on mobile) │     warning → amber  ⚠ (lost / under review)
│                                                 │     danger  → red    ⛔ (stolen / invalidated)
└───────────────────────────────────────────────┘

✓ Authenticated & Certified          ← authenticity block SECOND, kept positive but
Certified in the SCA provenance registry   visually SMALLER than an adverse banner

SCA reference / image / Item / Year / … / Certification No. / Condition / Authenticated / SCA identity

[ "What this means" trust panel — collapsible <details> (CSS-only, no JS) ]
[ footer ]
```

Rules:
- When registry is **clear/recovered**: the top banner is the **green** authenticity confirmation (essentially
  today's positive experience, just promoted to the top). No scary empty state.
- When registry is **adverse**: a **color-coded warning banner is first and larger than** the authenticity line.
  The authenticity fact stays present and truthful but can no longer be the single dominant signal.
- Severity tiers (presentation-only classification over the existing `registry_status`, **no state-model
  change**): `clear` (normal, recovered→clear) · `warning` (lost, disputed) · `danger` (stolen, invalidated) ·
  `retired` (neutral-strong). Exact tiering of lost-vs-stolen and retired is in §5 / OP-DECISION-2.
- No new private data is needed — the banner is built from the **already-allowlisted** `registry_status` /
  `authenticity_status` plus static copy.

## 5. Proposed exact public wording (for operator/legal approval — see OP-DECISION-2)

Positive / clear (normal, recovered):
- Headline: **"Authenticated & Certified by SCA"**
- Body: "This item matches an authenticated, currently certified record in the SCA provenance registry."

Lost:
- Headline (amber ⚠): **"REPORTED LOST"**
- Body: "This item is authentic and certified, but it has an **active lost-item report** in the SCA registry."

Stolen (strongest):
- Headline (red ⛔): **"REPORTED STOLEN"**
- Body: "This item may be authentic, but it is **currently reported stolen** in the SCA registry. Authenticity
  does **not** mean the current holder is the lawful owner."
- *Deliberately avoids any language implying authenticity = lawful possession.*

Disputed / under review:
- Headline (amber ⚠): **"UNDER REVIEW"**
- Body: "SCA has an **unresolved registry issue** associated with this item. Treat its status as provisional."

Invalidated:
- Headline (red ⛔): **"RECORD INVALIDATED"**
- Body: "SCA has marked this registry record **no longer valid**. Do not rely on this Passport."
- *(If OP-DECISION-1 chooses fail-closed, this renders as a 404 variant instead; see §11.)*

Retired:
- Headline (neutral-strong): **"RETIRED FROM THE SCA REGISTRY"**
- Body: "This item's SCA registry record has been retired. Its past certification remains on record."

"What should I do?" line for stolen/lost/under-review (needs a destination — OP-DECISION-3):
- "If you have information about this item, contact SCA at **[operator-provided channel]**." — requires an
  operator-owned contact URL/address; **no SMTP and no ownership disclosure** implied.

## 6. SCA branding / trust copy recommendation

- **Trust panel** (collapsible `<details>`/`<summary>`, CSS-only — JS is forbidden by CSP): a concise,
  non-marketing "What this Passport means" block answering the six comprehension questions:
  - what SCA is (one line); what the Passport verifies (authenticity + certification record);
  - what "Authenticated & Certified" means; **that it does not establish current ownership or lawful possession**;
  - what the registry status means; what to do on Lost/Stolen/Under review.
  Copy must be plain and factual, not promotional.
- **Logo:** the admin logo is served by `BrandLogoController` at `GET /admin/sca/brand-logo`, which sits **behind
  the staff-IP `/admin*` edge rule** and returns 403 publicly — so it **cannot** be reused on the public passport
  as-is. `/storage` is edge-denied (404) and must **stay** denied. Two CSP-compatible, `/storage`-free options:
  1. **Committed static asset in the Passport package** (e.g. `packages/Sca/Passport/src/Resources/assets/
     sca-logo.svg`), served by a new **public** `GET /p-asset/logo` route in the passport group (same
     `PublicPassportHeaders`, `img-src 'self'`), or
  2. **Inline `data:` URI** in `layout.blade.php` (allowed by `img-src … data:`), zero new route.
  Recommendation: **Option 2 (inline data URI)** for a small SVG — simplest, no route, no cache concerns.
  **OP-DECISION-4:** operator must supply/approve the exact logo asset for public use (brand asset governance).

## 7. Privacy / security analysis

- The public contract is **strict default-deny** (`PublicAllowlist::FIELDS`, asserted by
  `assertOnlyAllowlisted`). Rendered fields are only: `sca_reference` (opaque `public_ref`),
  `certification_number` (display ref, not the security token), authenticity/cert labels + dates, brand/model/
  year/country/materials, condition grade/label + date, `qr_status` shape, `registry_status` label,
  `provenance_summary`, and `image_url` (carrying **only** the same active-QR token already in the page URL).
- **No** collector identity, owner name/email, ownership-event id, DB id, storage path, internal token (other
  than the self-referential active passport token), SKU, frame_serial, notes, or staff info is exposed. The live
  `pp2`/`pp3` tests assert owner email + `Collector #id` + ownership-event prose are **absent** even on adverse
  pages.
- **Every proposed change in §4–§6 uses only already-allowlisted fields + static copy** — it introduces **no new
  private data** and does not require public ownership disclosure. If the implementation adds presenter keys
  (e.g. `registry_severity`, `registry_headline`, `registry_body`, `trust_copy`), they must be **added to the
  allowlist** and are all **derived/static, non-PII** (the allowlist assertion enforces this).
- **SCA-038 constant-shape 404 must remain intact.** The warning redesign touches the **200** branch only; the
  404 page/shape and the resolver are unchanged. (If OP-DECISION-1 later fail-closes invalidated/retired, that is
  a **separate** resolver-policy task with its own review — not this one.)
- Headers/CSP (`PublicPassportHeaders`) stay as-is: `no-store`, `nosniff`, `DENY`, `no-referrer`, `noindex`,
  `default-src 'none'; style-src 'unsafe-inline'; img-src 'self' data:`. **No JS** may be introduced.

## 8. Mobile recommendation (phone scan = primary use case)

- Single-column, `max-width:560px` wrap already suits phones. Keep it.
- **Promote the registry banner above the image** so the status is the first thing seen; on an adverse item the
  warning must be visible **without scrolling past the photo**. Consider `position:sticky;top:0` for the adverse
  banner (CSS-only) so it stays visible while scrolling the detail rows.
- Warning banner: large tap-target-free (no actions), high-contrast color, icon + headline ≥ 18px, body ≥ 14px.
- Image: keep `max-height` capped; ensure the banner is not pushed below it. No horizontal scroll, no JS.
- Trust panel as a collapsed `<details>` so it doesn't bloat the first screen but is one tap away.

## 9. SCA_PUBLIC_PREVIEW recommendation

- Current: `config/passport.php` → `'preview' => env('SCA_PUBLIC_PREVIEW', '1') === '1'` — **default ON**
  (fail-open for the banner). Prod `.env` explicitly sets `SCA_PUBLIC_PREVIEW=0`, so prod is correct **today**,
  but a missing/typo'd var anywhere **defaults to showing the "development preview — not the permanent address"
  banner on a real production passport** — a trust-eroding false statement (security-safe, UX-unsafe).
- **Smallest safe correction (recommended, code-only, NOT implemented):** flip the **default to `'0'`** in
  `config/passport.php` so the banner is **opt-in** (`SCA_PUBLIC_PREVIEW=1` on the preview host only). No `.env`
  change, **no prod behavior change** (prod already sets 0), removes the fail-open. One-line change + update
  `PublicPassportTest::p15` to assert the new default-off behavior.

## 10. Exact implementation scope / files / tests (for a LATER task; not now)

Presentation-only, no schema/migration/resolver/state change:
- `Sca/Provenance/src/Support/ItemStateLabels.php` — add a **pure** `registrySeverity(?string): string`
  (clear|warning|danger|retired) and optional `registryHeadline()/registryBody()` (or keep copy in the presenter).
  No change to existing methods.
- `packages/Sca/Passport/src/Presenters/PassportPresenter.php` — add derived keys (`registry_severity`,
  `registry_headline`, `registry_body`, `trust_copy` flag). All static/derived, non-PII.
- `packages/Sca/Passport/src/Support/PublicAllowlist.php` — allowlist the new derived keys (keeps default-deny).
- `packages/Sca/Passport/src/Resources/views/passport/{layout,show}.blade.php` — promote + color-code the
  registry banner (CSS-only), keep authenticity secondary, add the `<details>` trust panel, logo asset.
- `packages/Sca/Passport/src/Config/passport.php` — preview default `'1'`→`'0'` (§9).
- Logo asset: inline `data:` URI in `layout.blade.php` (Option 2) **or** a committed package asset + a public
  `GET /p-asset/logo` route in `Routes/public-routes.php` (Option 1).
- Tests — extend `PublicPassportTest` / `PublicPassportPilotTest`: for **each** adverse state assert the banner
  **headline + severity class is present and ordered before** the authenticity block; clear/recovered render the
  positive top banner; stolen copy contains the "not lawful owner" sentence; invalidated/retired render per the
  chosen §11 policy; trust panel present; **404 shape unchanged**; preview default-off; **no new private field**
  leaks (re-assert the `pp2`/`pp3` privacy absences).

Estimated shape: ~1 support method, 1 presenter, 1 allowlist, 2 blades, 1 config line, 1 logo asset, test
additions. No controller/route change if the logo uses the inline data-URI option. **No DB, no resolver, no
status, no QR, no cert, no schema, no `.env`, no `/storage`, no Caddy/Docker/firewall/DNS/SMTP.**

## 11. Decisions that require OPERATOR approval (not coding decisions)

- **OP-DECISION-1 — Fail-closed policy for `invalidated` (and `retired`)?** Today both render a full green-badged
  200. Should **invalidated** (and/or **retired**) instead **fail closed to the SCA-038 constant-shape 404**, or
  render a 200 with the strongest danger banner? This is a **domain/resolver policy** decision with real-world
  meaning (does an invalidated record still show *any* passport?). **Do not change the resolver in the
  presentation task.** If fail-closed is chosen, it is a separate, independently-reviewed resolver change.
- **OP-DECISION-2 — Exact adverse wording + severity tiering (legal/liability).** The lost/stolen/under-review/
  invalidated/retired copy in §5, and the stolen "does not mean lawful owner" framing, should be signed off by
  the operator (and legal if applicable) before implementation.
- **OP-DECISION-3 — "What should I do?" destination for Lost/Stolen/Under review.** Requires an operator-owned
  public contact channel (URL/address). Must not imply ownership disclosure and needs no SMTP.
- **OP-DECISION-4 — Public use of the SCA logo + the exact asset.** Operator supplies/approves the brand asset for
  the public passport (brand governance), independent of the admin-only DB logo.
- **OP-DECISION-5 — Reaffirm the "recovered reads as CLEAR to the public" privacy rule.** This is a deliberate,
  existing policy (resolved loss is hidden from the public; owner still sees it). Flagging it so the operator
  explicitly re-approves it as part of the trust pass; no change proposed.

---

**Hard boundary honored:** audit/design only — no code, DB, resolver, status, QR, cert/auth/ownership, schema,
`.env`, `/storage`, Caddy/Docker/firewall/DNS/SMTP changes; no production test data. Commit this governance
document only; ACTIVE/NEXT remain unpromoted. **STOP for ChatGPT / operator review.**

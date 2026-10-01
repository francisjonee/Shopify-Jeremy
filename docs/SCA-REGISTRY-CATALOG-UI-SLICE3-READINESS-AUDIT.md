# SCA-REGISTRY-CATALOG-UI — Slice 3 Readiness / Planning Audit (READ-ONLY)

**Date:** 2026-10-01 · **Deployed baseline:** `fe08ec5` (Slice 1 + Slice 2 DONE).

> **SLICE 3 IMPLEMENTED + PUSHED (push-only) 2026-10-01 — awaiting pre-merge review.** Feature branch
> `sca-registry-catalog-ui-slice3` @ **`2b1a933`**, base `fe08ec5`, **1 commit, 13 files** (no migration). Implements
> this audit with **PUBLIC SKU = NO (locked)**. Collector: `CollectionService` baseQuery +`i.sku`/`i.image_path`,
> summary/detail DTOs +`sku`/`has_image` (path/mime server-side only); new `catalogImageForOwnedItem` + `CollectionImageController`
> + route `GET collector/collection/{ref}/image` (current-owner authz, no-store, privacy-safe 404); views render
> thumbnail+SKU. Passport: `PublicAllowlist` +`image_url` (only new field; **no SKU**); `PassportPresenter` builds
> `image_url` from the item's active-QR token (= the token already in `/p/{token}`) only when an image exists; new
> `PassportController::image` + route `GET /p/{token}/image` (same group → `PublicPassportHeaders`) reusing
> `PassportResolver` → bytes for valid+image, **identical constant-shape 404** for malformed/bogus/revoked/inactive/
> no-image; view renders `<img>` only when present (CSP `img-src 'self'` already allows — no CSP change). No Krayin
> core/vendor edits, no QR/is_production/cert/auth/ownership/transfer/service change, no schema. Tests `CollectorCatalogTest`
> (6; incl. **previous-owner-after-transfer 404** + raw-path non-disclosure) + `PassportCatalogImageTest` (6; incl.
> **public-SKU non-disclosure**, constant-shape failures, byte correctness, SCA-038 unchanged, zero mutation). Focused
> 12/49; full `tests/Feature/Sca` **679 passed / 3626**; `php -l` clean. Live (feature branch) proof: `/p/{valid}` 200
> (no `<img>` for no-image prod items), `/p/{valid}/image` + `/p/{bogus}/image` 404, `/storage` 404. Pilot restored to
> `fe08ec5` — no candidate routes live, prod fp `a920dc1c…` / migrations 119 unchanged, healthy. Report (app repo):
> `docs/task-reports/SCA-REGISTRY-CATALOG-UI-SLICE3.md`. **Not merged/deployed.**

**Planning only — nothing implemented at audit time, no branch, no prod change, no migration.** ACTIVE = NONE / NEXT_TASK = NONE.

Slice 3 surfaces the **catalog image + SKU** (from the Slice-1 columns) on the two customer surfaces: the authenticated
**collector "My Collection"** and the public **SCA-038 passport** — presentation only, reusing existing patterns, with
image delivery through authorized/`/p`-namespaced routes (never `/storage`).

---

## 1. Collector "My Collection"

**Where it renders today.** `Sca\Collector` behind the `collector.auth` guard:
- `GET collector/collection` → `CollectionController::index` → `CollectionService::ownedItems(collectorId)` → list of
  `summary()` DTOs → `collection/index.blade.php`.
- `GET collector/collection/{ref}` → `CollectionController::show` → `ownedItemByRef(collectorId, ref)` (returns a
  `detail()` DTO or **null → privacy-safe 404**) → `collection/show.blade.php`.
- Items are addressed by **opaque `public_ref`** (never an internal id) and authorized **server-side by current
  ownership** (`s.current_owner_collector_id = collectorId`). A non-owner gets the same explicit 404.
- Precedent to mirror for image delivery: `GET collector/collection/{ref}/documents/{handle}` →
  `CollectionDocumentController::download` → `CollectionService::ownerVisibleDocument(...)` (owner-authorized, ref-
  addressed, **no enumeration**, explicit 404). The catalog image route copies this exactly.

**How image + SKU appear (presentation only).**
- `CollectionService::baseQuery()` select adds **`i.sku`** and **`i.image_path`** (`image_path` is used only to derive a
  boolean — never returned to the view). `summary()` + `detail()` DTOs gain **`sku`** (string|null) and **`has_image`**
  (bool = `image_path !== null`). **The raw `image_path`/`image_mime` are never placed in a collector DTO.**
- Views render SKU (`—` when null) and, when `has_image`, `<img src="{{ route('collector.collection.image', ref) }}">`;
  otherwise a placeholder. Mirrors the staff Slice-1 detail + Slice-2 card.
- **Invariant:** these are presentation reads from the existing projection/item. They create no claim/ownership/
  certification/authentication/transfer/service/QR/lifecycle record and change no behavior.

**Collector image route + authorization (no ID-guessing).**
- New: `GET collector/collection/{ref}/image` → `CollectionImageController::show` (new, mirrors
  `CollectionDocumentController`), middleware `collector.auth`, `where('ref','[^/]+')`, name
  `collector.collection.image`.
- New service method `CollectionService::catalogImageForOwnedItem(collectorId, ref): ?array{path,mime}` — returns the
  image **only** when the collector **currently owns** the `ref` item **and** `image_path` is set; **null otherwise**.
- The controller streams the bytes from the public disk (`Storage::disk('public')`) on a hit; on **null** returns the
  **same explicit privacy-safe 404** (`collection.not_found`, not `abort()`). Because the key is an **opaque `public_ref`
  + a current-ownership check**, a collector can never obtain another collector's item image by guessing a ref/id — a
  guess returns the identical 404 (no existence/ownership disclosure). Not tied to passport-eligibility: an owner sees
  their item's image even if its certification was revoked (no public passport).

---

## 2. Public passport (SCA-038)

**Current contract.** `PassportController::show(token)` → `PassportResolver::resolve` (strict 32-hex gate **before** DB;
token must be the item's **active** QR with a **current issued** cert + finalized passed auth; any failure → `null`) →
one **constant-shape 404** (`passport.not_found`, explicit Response) **or** 200 rendering **only** `PassportPresenter`'s
**allowlisted DTO** (`PublicAllowlist::FIELDS`, asserted). The view never receives a raw model or the resolving token.
`PublicPassportHeaders` sets `no-store`, `nosniff`, `noindex`, `Referrer-Policy: no-referrer`, and a strict CSP whose
`img-src 'self' data:` **already permits a same-origin image**.

**Smallest safe addition.**
- **SKU on the public passport — RECOMMEND: NO.** SKU is **catalog/retail metadata**, not authenticity provenance; the
  passport allowlist is deliberately minimal and verification-focused, and the reviewer's own constraint forbids leaking
  "other internal catalog metadata." SKU adds no verification value and stays on the staff + owner surfaces only.
  _(Operator may override: the SKU is also on the public Shopify listing, so exposing it is defensible — but it is not
  recommended and is a separate explicit decision, not part of the minimal Slice 3.)_
- **Catalog image on the public passport — YES** (helps a buyer visually confirm the item). Add **one** allowlisted
  field **`image_url`** to `PublicAllowlist::FIELDS` + `PassportPresenter`: the value is the public image-endpoint URL for
  this passport's token **when `item->image_path` is set, else `null`**. The view renders `<img src="{{ image_url }}">`
  only when non-null. **`image_path`/`image_mime` are NOT added to the allowlist** — only the token-based URL is emitted,
  and that token is the one **already necessarily present in the passport page's own URL** (permitted).

**Public `/p`-namespaced image endpoint (tied to the resolver).**
- New: `GET /p/{token}/image` (i.e. `config('sca-passport.path').'/{token}/image'`), `where('token','[^/]+')`, name
  `sca.passport.image`, in the **same route group as the passport** (so it inherits `PublicPassportHeaders`).
- Handler `PassportController::image(token)` (or a lean `PassportImageController`) calls the **same
  `PassportResolver::resolve($token)`** — so it reuses the exact active-QR + current-cert binding and the strict format
  gate. **Identifier = the opaque QR `public_token`** (same as the passport URL) — never an internal item id.
- **Outcomes (constant shape):**
  - malformed / bogus / unknown / **revoked** / **inactive/stale** token → resolver `null` → **one constant 404**
    (explicit Response, no body leak) — identical for every non-resolving case.
  - resolved but `item->image_path` **null** (missing image) → the **same constant 404**.
  - resolved **and** has image → **200**, streams the bytes with `Content-Type: image_mime`.
  - Net oracle: only "a currently-valid passport token that has a catalog photo" yields 200; **everything else is an
    identical 404**. This adds **no** existence oracle beyond what `/p/{token}` already provides (a valid token already
    returns the 200 passport), and whether a public, already-resolvable item has a catalog photo is not private.
- **No leak:** the response is image bytes only — no filesystem path, no internal item id, no owner data, no token beyond
  the one in the page URL, no other catalog metadata. `image_path`/`image_mime` stay server-side (mime only sets the
  Content-Type header).

---

## 3. Security / data boundary

- **`image_path` / `image_mime` stay server-side only** — REQUIRED and preserved. Neither appears in any public or
  collector DTO/allowlist/HTML; only a derived `has_image` bool, a derived `image_url`, and the streamed bytes are
  exposed. (Audit must assert the raw path string never appears in collector or passport HTML.)
- **`/storage` remains edge-denied** — confirmed live (`verify./storage/*` → 404). Both new routes go through the app on
  **edge-allowed** paths: `/p/*` (public passport) and `/collector/*` (collector area); neither uses a `/storage` URL.
- **Staff `admin.sca.eyewear.image` unchanged** — Slice 3 adds new routes only; the Slice-1 staff route/ACL is untouched.
- **Caching / stale imagery.** The public passport page is already `no-store`. The **public image route must also be
  `no-store`** (reuse `PublicPassportHeaders`, or set `Cache-Control: no-store` + `nosniff` + `noindex`): the image URL is
  keyed by **token** (stable across image replacements, since `updateCatalog` writes a new hashed filename and updates
  `image_path`), so a cacheable response **could serve a stale/removed photo**. `no-store` guarantees a changed or
  **removed** catalog image is never served from cache (removal → `image_path` null → 404 immediately). The collector
  image route should likewise be `no-store` (owner-private surface). Trade-off: no browser/proxy caching of the photo —
  acceptable at pilot scale, and there is no CDN in front of `sr-caddy`. (A future `ETag`/short-max-age optimization is
  possible but out of scope and not needed now.)

---

## 4. Proposed exact scope

**Collector (`Sca\Collector`):**
- `src/Routes/collector-routes.php` — +1 route `collection/{ref}/image` (`collector.auth`).
- `src/Http/Controllers/CollectionImageController.php` — NEW (mirrors `CollectionDocumentController`): owner-authorized
  stream; explicit 404.
- `src/Services/CollectionService.php` — `baseQuery()` +`i.sku`,`i.image_path`; `summary()`/`detail()` +`sku`,`has_image`;
  new `catalogImageForOwnedItem()`.
- `src/Resources/views/collection/index.blade.php` + `collection/show.blade.php` — render SKU + image/placeholder.

**Public passport (`Sca\Passport`):**
- `src/Routes/public-routes.php` — +1 route `/p/{token}/image` (`sca.passport.image`, same group → `PublicPassportHeaders`).
- `src/Http/Controllers/PassportController.php` — +`image(token)` (reuses `PassportResolver`); constant 404 Response.
- `src/Presenters/PassportPresenter.php` — +`image_url` (null unless `image_path` set).
- `src/Support/PublicAllowlist.php` — +`image_url` entry (P).
- `src/Resources/views/passport/show.blade.php` — render `<img>` when `image_url` present.

**Tests (focused, new):**
- `CollectorCatalogTest` — owned item exposes `sku`+`has_image`; collector image route streams for the **owner** (200),
  returns **404 for a non-owner** (ref/id guessing) and for **no image**; null SKU/image render cleanly; **raw
  `image_path` never in collector HTML**; zero provenance mutation.
- `PassportCatalogImageTest` — `image_url` present in the DTO/HTML **only** when the item has an image (allowlist stays
  green); `/p/{token}/image` → 200 for a **valid+image** token, identical **404 for malformed / bogus / revoked /
  inactive / resolved-no-image**; decoded response is the stored bytes; **no path/mime/sku/owner/internal-id leak** in
  the passport HTML or the image response; **SCA-038 `/p/{token}` 200/404 behavior unchanged**; `PublicAllowlist`
  assertion still passes; **zero QR/provenance mutation**; `is_production` unchanged.
- Regression reasoning: certification issue/correct, ownership/transfer, collector collection (incl. SCA-041/048/049),
  QR, and passport resolution all read-only w.r.t. these columns → unaffected; full `tests/Feature/Sca` must stay green.

---

## 5. Architecture / constraints

Reuse the **Slice-1 columns** (`sku`, `image_path`, `image_mime`) — **no new schema** (the audit found none needed). **No
Krayin core/vendor edits.** No QR regeneration/reissue, no `is_production` mutation, no passport-resolver semantics
change (the resolver is reused verbatim), no Shopify/SMTP/Caddy/DNS/firewall/`:8080`/cutover work.

## 6. Risks

- **Token in the passport `<img src>`** — acceptable (the token is already in the page's own URL; reviewer permits
  "the token already necessarily present in the public passport URL"). Alternative (relative `src`) is fragile due to the
  no-trailing-slash passport path; the server-built `image_url` is clearer and safe.
- **Constant-shape discipline** — the image route must return an **identical** 404 for every non-(resolved-with-image)
  case; a test must prove malformed/bogus/revoked/inactive/no-image are indistinguishable.
- **CSP** — the passport CSP already allows `img-src 'self'`; the same-origin `/p/{token}/image` works without a CSP
  change. (Audit must confirm no CSP edit is needed.)
- **Collector-image authorization** — must be ownership-gated (opaque ref + current ownership); a test proves a
  non-owner (and a previous owner after transfer) gets the privacy-safe 404.
- **Stale image** — mitigated by `no-store` (above).

## 7. GO / NO-GO gates

GO only if: `image_path`/`image_mime` never in any HTML/DTO; `/p/{token}/image` constant-404 for malformed/bogus/revoked/
inactive/no-image and 200+bytes only for valid+image; collector image owner-only (non-owner/prev-owner → 404); SKU
excluded from the public passport (unless operator overrides); `PublicAllowlist` assertion green; SCA-038 `/p/{token}`
200/404 unchanged; `/storage` still edge-denied; staff image route unchanged; `no-store` on both new image routes; full
`tests/Feature/Sca` green; zero provenance/QR mutation + `is_production` unchanged; no new schema; no core edits.

## 8. Rollback

Code-only, no schema. Rollback = revert the Slice-3 commit(s) and redeploy the prior main; the Slice-1 columns remain
(already live, nullable, used by staff). No data migration to undo; catalog images on the public disk are inert without
the routes.

## Summary / recommendation

Proceed to a **governed Slice 3 implementation** on the above scope — **image on both surfaces, SKU on the collector
surface only (not the public passport, pending an explicit operator override)**, delivered via owner-authorized
(`/collector/.../image`) and resolver-tied (`/p/{token}/image`) routes with `no-store`, reusing the Slice-1 columns and
the existing resolver/ownership patterns. No schema, no core edits, no provenance/QR/`is_production` change. **ACTIVE =
NONE / NEXT_TASK = NONE — planning only; awaiting ChatGPT review + promotion.** One open operator decision: **SKU on the
public passport (default NO)**.

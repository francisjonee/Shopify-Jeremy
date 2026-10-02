# SCA Status/terminology consistency — implementation (PUSH-ONLY, awaiting pre-merge review)

**Date:** 2026-10-02 · **Base:** deployed main `f85e8c5`, migrations **120**.
**Status: IMPLEMENTED + TESTED + PUSHED. NOT merged, NOT deployed. For independent pre-merge review.**
Audit: gov `b187bf5`. Presentation/read-model correction only.

## Candidate identity
- **Candidate SHA:** `f6015a83c72ece9ae3bf8584788f59abeb72b92d`
- **Branch:** `origin/sca-status-terminology` · **Base / merge-base:** `f85e8c5` (clean, 1 commit)

## File scope (2 new + 8 modified; NO schema/migration, NO deriveLifecycleState change, NO projection
rebuild, NO Krayin core/vendor, NO route/ACL change, NO SMTP/infra)
New: `packages/Sca/Provenance/src/Support/ItemStateLabels.php`, `tests/Feature/Sca/ItemStateLabelsTest.php`.
Modified: `Sca/Passport/.../PassportPresenter.php`, `Sca/Collector/.../CollectionService.php`,
`Sca/Collector/.../views/collection/index.blade.php`, `Sca/Registry/.../views/eyewear/index.blade.php`,
`Sca/Registry/.../views/eyewear/show.blade.php`, `Sca/Registry/.../views/status/queue.blade.php`,
`Sca/Registry/.../views/status/show.blade.php`, `tests/Feature/Sca/StatusAdminTest.php`.
`git diff --stat f85e8c5..f6015a8` touches no Migrations/Webkul/vendor/composer/.env/docker/Caddy, and
`ProjectionService` (deriveLifecycleState) is **not** in the diff.

## Presenter API / label matrix implemented — `Sca\Provenance\Support\ItemStateLabels` (pure, no DB/mutation)
| Method | Input (authoritative fact) | Output |
|---|---|---|
| `registryStatus(?status)` | `registry_status` | lost→"Reported lost"; stolen→"Reported stolen"; recovered→"Recovered — no active loss report"; disputed→"Under review"; retired→"Retired from the SCA registry"; invalidated→"Invalidated — this SCA record is no longer valid"; else→"No adverse reports on the SCA registry" (single canonical map; full form for customer surfaces) |
| `registryShort(?status)` | `registry_status` | compact admin-pill form: Lost / Stolen / Recovered / Under review / Retired / Invalidated / Normal |
| `certification(cur,auth,ever)` | current cert / authenticated / ever-certified | SCA-052 badge: "Authenticated & Certified" (positive,✓) / "Authenticated — no active certification" / "Authenticated — not certified" / "Recorded" |
| `certificationShort(cur)` | current cert only | "Certified" / "Not currently certified" |
| `ownershipSelf()` / `ownershipAdmin(owned)` | ownership | "Registered to you" / "Registered to a collector"\|"Unclaimed" |
| `qr(active)` | `active_qr_identifier_id` | "QR active" / "No active QR" |
| `lifecycleAdmin(?state)` | `lifecycle_state` (internal) | Intake / Authentication failed / Authenticated / Certified / Sold — awaiting claim / Registered / Transfer pending / Retired / Invalidated (admin workflow only) |
| `passportProvenance(cur)` | current cert fact | "Certified in the SCA provenance registry" / "Recorded in the SCA provenance registry" (never from lifecycle_state) |

## Wiring (compose INDEPENDENT facts; never a conflated lifecycle label)
- **Passport** (`PassportPresenter`): `provenance_summary` now derives from `current_certification_id` via
  `passportProvenance` (fixes the fragile `provenanceSummary('REGISTERED')`="Certified and registered" that
  sourced certification from ownership); `registry_status` via the shared map; `authenticity_status` via
  `certification(true,true,true)`. **Public-privacy rule PRESERVED:** `recovered` reads **clear** on the
  public passport (the passport normalizes recovered→clear before the shared map — it must not disclose a
  resolved loss history; the owner still sees "Recovered …"). SCA-038 resolver/404 contract **unchanged**
  (revoked still 404; not made public to show a "not certified" badge). `qr_status` stays "Active".
- **Collector** (`CollectionService`): `authenticityDisplay` now **delegates** to `certification` (identical
  output — SCA-052 preserved); registry via the shared map; detail `status` = `certificationShort` (Certified /
  **Not currently certified** from the cert fact, so an owned+revoked item reads "Registered to you" +
  "Not currently certified"); list `status` = `ownershipSelf`; list adverse badge now uses the canonical
  registry label. Owner privacy intact (no ids/tokens/staff/paths).
- **Admin** (4 blades): index card + lifecycle **filter dropdown labels** + item-detail Overview + status
  queue/detail now use `lifecycleAdmin` + `registryShort` (no raw SCREAMING_SNAKE / raw registry values).
  **Filter option VALUES unchanged** (only labels humanized); all filter/search/sort/QR-lookup behavior
  preserved. The "Collector #<id>" staff-owner identity is deliberately **NOT** touched (separate [A-F9]).
- **Drift removed:** the duplicated Collector/Passport registry prose maps are deleted; one canonical source.

## Tests
- **New `ItemStateLabelsTest` (7/7):** registry canonical map + compact form; certification truth table
  (currently-certified / revoked-but-ever / never / none — never certified without a current cert); ownership
  + QR independent labels; `lifecycleAdmin` humanized with **no SCREAMING_SNAKE**; passport provenance derived
  from the cert fact (never "registered to").
- **Integration:** PublicPassport + PublicPassportPilot (cert wording from cert fact; `recovered` still reads
  clear; revoked still 404), ItemAuthenticityBadge (SCA-052 identical), LostStolen (s18 recovered-clear
  unchanged), StatusAdmin (updated to canonical passport wording "Under review"/"Invalidated"),
  CollectorItemDetailParity, CatalogGrid/Ui, CollectorCatalog, CollectorAuthContext — all green.
- **Full `tests/Feature/Sca`: 760 passed (4211 assertions), exit 0** (baseline `f85e8c5` 753/4155 → +7).
  `php -l` clean on all changed PHP.

## Explicit: no schema/service/domain change
Every label is composed from facts already in `sca_item_current_state` (+ `sca_authentications`). **No
schema/migration; `deriveLifecycleState` unchanged; no projection rebuild; no historical-event reinterpretation.**

## Restoration & no-candidate-live / zero-mutation proof
- Working tree restored to `main` = `f85e8c5`; `composer install --no-dev`; `config:clear`+`route:clear`.
  Code-only on the bind mount → kr-app not recreated; Phase-B loopback intact.
- Candidate **absent on main:** `ItemStateLabels.php` gone; **0** `ItemStateLabels` references in
  `PassportPresenter`/`CollectionService`; blades reverted to the deployed form.
- **Live edge:** `/p/bee93d2b…` 200, `/p/bogus` 404 (SCA-038), `/storage` 404, `/admin/sca/eyewear` 403
  (non-staff), kr-app `127.0.0.1:8080` loopback-only + healthy.
- **Production projection/provenance byte-equivalent (rendering is pure; no mutation run; all tests on the
  disposable `sca_domain_test`):** projection unchanged (item1 `CERTIFIED`/normal/unowned/activeQr1/cert1;
  item3 `REGISTERED`/recovered/owner1/activeQr2/cert3 — values untouched, confirming the audited conflation
  the *presentation* now composes around); QR tokens + is_production unchanged; status_events 6; migrations
  120. Fingerprint `b6ff2aa2…`.

**STOP after push. Not merged/deployed; no next task started. Awaiting independent pre-merge review of
`f6015a8` (base `f85e8c5`).**

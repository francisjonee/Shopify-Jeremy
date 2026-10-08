# SCA Collector Profile — CP-5 — Public Handle / Profile URL — CANDIDATE

**Date:** 2026-10-09 · **Status: CANDIDATE — R1 REMEDIATED (collision/error contract) + clean full gate, re-pushed. NOT merged / NOT deployed / production untouched / Stripe DORMANT / mail=log / Caddy+DNS untouched / `/u/*` edge-blocked. STOP for ChatGPT re-audit.**

- **Impl repo:** `francisjonee/francisjonee-sca-platform-private` · **Governance:** `francisjonee/Shopify-Jeremy`
- **Branch:** `feat/sca-collector-profile-cp5`
- **Base (exact deployed baseline):** `7409a33baecf2ef6bd8c44413a27a9f77fa249f1` (prod HEAD, migration 133)
- **Candidate head:** `2d87c38dadb5af61a630805dc2da3a6e11eb2f02` (R1 remediation of `681bc45`; 2 commits ahead of base)
- **Migrations:** candidate **133 → 134** (one additive migration); **prod stays 133** until deployment.
- **Deployment split:** Phase A = application + migration 134 only; **no Caddy/DNS**; `/u/*` stays edge-blocked. Phase B = separate `/u/*` edge admission after ChatGPT audits Phase A.

---

## 0. Pre-merge audit R1 remediation (head `2d87c38`)

**Finding (accepted):** the handle collision error contract was incomplete. Under a genuine same-handle
race the losing claim could surface a raw `QueryException` as a 500 — `setHandle` only mapped duplicate-key
`1062` to `HandleRejection::UNAVAILABLE`, while a contended write can instead resolve as a lock-wait timeout
(`1205`) or deadlock (`1213`). The concurrency test compounded this by accepting raw `1205/1213` as a valid
terminal outcome.

**Fix (2 files, delta from `681bc45`):**
- `CollectorHandleService` — `setHandle` now wraps its write transaction in bounded retries
  (`MAX_ATTEMPTS = 3`) on InnoDB concurrency errors (Laravel's `causedByConcurrencyError` recognises both
  `1205` and `1213`); a retried attempt re-reads availability under the lock, so once the winner commits the
  loser fails closed via `assertClaimable`. The terminal `catch` maps `1062` **or** a persistent `1205/1213`
  (survived the retries while the winner held the unique-index entry) to the SAME generic
  `HandleRejection::UNAVAILABLE`. No raw `QueryException` can reach the caller. Each attempt is one
  transaction, so a rolled-back attempt leaves **no** handle and **no** tombstone (no partial state).
  `removeHandle` gets the same bounded retry. Helper `isUniqueViolation` → `isHandleContention`
  (`1062/1205/1213`).
- `CollectorHandleConcurrencyTest` `cc1` strengthened: while the racer holds the uncommitted winning write,
  the contended claim's terminal outcome must be exactly `rejection:UNAVAILABLE` (asserted via a classifier
  that distinguishes `raw_sql:<errno>` — a contract violation — from the required `HandleRejection`), must
  write no handle, and must leave **zero** reservation rows (no partial tombstone); then exactly one winner.
  Raw `1205/1213` is no longer accepted as a final result. Deterministic across repeated runs (cc1 ~3.6s =
  the 3 bounded retries resolving to a clean `UNAVAILABLE`).

**Contract now proven:** a same-handle race ends with exactly one winner; the loser gets the generic
`UNAVAILABLE`; no raw `QueryException`/500; no partial handle/tombstone state.

---

## 1. Invariant honoured

**The handle is a MUTABLE ALIAS, never a replacement for identity.** The immutable, high-entropy
`public_ref` (PUB-…) allocated by CP-3 remains the PERMANENT canonical public address; every existing
`/c/{public_ref}` URL keeps working forever while published. CP-5 only adds a friendlier `/u/{handle}`
route that resolves server-side to the SAME publication row / `public_ref` and then reuses the EXISTING
CP-3/CP-4 eligibility + presentation. `public_ref` is never changed (its immutability trigger is left in
place); the handle can be set, changed, or removed. Ownership ≠ publicity; profile publication ≠ item
publication; the handle belongs to the publication identity, not to visibility.

## 2. Changed files (14: 6 new, 8 modified)

**NEW**
- `packages/Sca/Provenance/src/Database/Migrations/2026_10_15_000001_add_handle_to_sca_collector_public_profiles.php`
- `packages/Sca/Provenance/src/Support/HandleNormalizer.php`
- `packages/Sca/Provenance/src/Exceptions/HandleRejection.php`
- `packages/Sca/Provenance/src/Services/CollectorHandleService.php`
- `tests/Feature/Sca/CollectorHandleTest.php`
- `tests/Feature/Sca/CollectorHandleConcurrencyTest.php`

**MODIFIED**
- `packages/Sca/Provenance/src/Models/CollectorPublicProfile.php` (handle_changed_at cast; handle/handle_normalized mass-assignable — only id/collector_account_id/public_ref remain guarded)
- `packages/Sca/Provenance/src/Services/CollectorPrivacyService.php` (pseudonymization tombstones the active handle in the same privacy transaction, before publication deletion)
- `packages/Sca/Collector/src/Http/Controllers/PublicProfileController.php` (shared render/stream helpers + `/u` handle actions resolving to public_ref)
- `packages/Sca/Collector/src/Http/Controllers/ProfileController.php` (private set/change/remove + handle state in the view)
- `packages/Sca/Collector/src/Providers/CollectorServiceProvider.php` (three `/u/*` public routes)
- `packages/Sca/Collector/src/Routes/collector-routes.php` (private POST/DELETE handle routes)
- `packages/Sca/Collector/src/Resources/views/profile.blade.php` (Public handle controls + error-flash block)
- `packages/Sca/Collector/src/Resources/views/public/profile.blade.php` (asset URLs parameterised so a `/u` page uses `/u`-family URLs; `/c` page byte-identical)

## 3. Data model (migration 133 → 134)

`ALTER sca_collector_public_profiles` ADD:
- `handle` VARCHAR(30) NULL — canonical (already-normalized, lowercase) handle for display.
- `handle_normalized` VARCHAR(30) NULL, **UNIQUE** (`uniq_public_profile_handle`) — case-folded key; the
  **ultimate collision authority**. NULLs are exempt and repeat freely (every unclaimed profile keeps
  NULL), so no duplicate-key contention on inserts that set no handle.
- `handle_changed_at` TIMESTAMP NULL — alias-change audit.
- The CP-3 immutability trigger `trg_sca_public_profiles_bu` is **unchanged** (it protects
  collector_account_id + public_ref only; handle columns are mutable by design and deliberately excluded).

`CREATE sca_collector_handle_reservations` (PII-free durable tombstone):
- `id`; `handle_normalized` VARCHAR(30) **UNIQUE** (`uniq_handle_reservation`); `released_at` TIMESTAMP;
  `reusable_after` TIMESTAMP; `timestamps`; index on `reusable_after`.
- **No** collector id, **no** public_ref, **no** FK linkage, **no** handle display text beyond the
  normalized key — nothing that identifies the former owner.

## 4. Normalization + reserved policy (`HandleNormalizer`, single source of truth)

Both mutation and resolution normalize through here, so the stored key, the uniqueness key, and the lookup
key can never diverge (`Ada-Lovelace` set == `/u/ADA-LOVELACE` request).
- **Syntax (v1):** trim; lowercase; ASCII only; 3–30 chars; first AND last char alphanumeric; interior
  `[a-z0-9-]`; NO consecutive hyphens; NO underscores/periods/spaces/slashes/Unicode/URL-escapes. Regex
  `^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$` + explicit `--` rejection. (`Ada-Lovelace`→`ada-lovelace`; `ab`,
  `ada--lovelace`, `-ada`, `ada-`, 31-char all rejected.)
- **Reserved:** a centralized explicit set compared case-insensitively AFTER normalization
  (`admin, administrator, api, app, auth, avatar, billing, c, collector, collection, dashboard, help,
  login, logout, mail, payments, privacy, profile, register, reset, root, sca, secondchance, second-chance,
  secondchanceauthenticators, settings, staff, support, system, u, user, users, verify, webhook, www`)
  plus reserved PREFIXES `pub-`, `col-`, `sca-`, `sub-` (collide with opaque identifier families). Trivially
  extensible; deliberately NOT a profanity/trademark system.

## 5. Service (`CollectorHandleService`, sole writer/resolver)

All three mutations are collector-authenticated self-service only (session collector id; never request
input) and serialize against CP-1 profile writes / CP-3 publish-unpublish / `pseudonymize()` by the SAME
**account-first** lock order: lock `sca_collector_accounts` FOR UPDATE + require `status='active'`, THEN the
publication row.
- `setHandle($cid,$raw)`: normalize+validate (INVALID/RESERVED before any lock); account-first lock;
  publication row lock (must exist → PROFILE_REQUIRED); idempotent no-op if already that normalized handle;
  availability pre-check (no active holder + no unexpired tombstone); **atomic rename** — tombstone the old
  normalized handle for the cooling period, then repoint to the new canonical. A lost race surfaces as the
  DB UNIQUE violation (1062), caught and mapped to the generic UNAVAILABLE.
- `removeHandle($cid)`: account-first; tombstone the old handle; clear handle fields. Idempotent.
- `resolvePublicRefByHandle($raw)`: normalize → look up `handle_normalized` → return `public_ref` **only
  as an identity mapping** (null on malformed/reserved/unknown). It deliberately does NOT re-implement
  eligibility; the caller passes the public_ref to the existing CP-3/CP-4 resolvers, which remain the sole
  authority (published + active + non-blank display_name + ownership + non-adverse). No forked privacy logic.
- `tombstoneOnPseudonymize($cid)`: called inside `CollectorPrivacyService::pseudonymize`'s single
  transaction, under the already-held account lock, BEFORE the publication row is deleted.

**Collision authority = the DB.** `uniq_public_profile_handle` and `uniq_handle_reservation` are the
ultimate arbiters; the application pre-checks are the friendly path. Exactly one writer wins a race; the
loser gets the identical generic "handle isn't available" (no SQL/owner leak, no partial state). RESERVED
and UNAVAILABLE map to the SAME user message so a reserved name, a taken name, and a tombstoned name are
indistinguishable.

**Cooling / reuse (privacy-first v1):** a removed or renamed-away handle is tombstoned for a fixed **90
days** (`COOLING_DAYS`). During cooling NOBODY (including the original owner) may claim it, so an old
`/u/{handle}` link can never silently resolve to a different collector. After expiry anyone may claim it.

## 6. Routes

- **Private** (collector.auth, CSRF via web group, throttle 10/min): `POST /collector/profile/handle`
  (set/change), `DELETE /collector/profile/handle` (remove). Session collector only. **No GET** — there is
  no availability/search/directory endpoint.
- **Public** (`web`): `GET /u/{handle}`, `GET /u/{handle}/avatar`, `GET /u/{handle}/items/{itemRef}/image`.
  Broad `[A-Za-z0-9\-]+` constraint so malformed/unknown/reserved/tombstoned/unpublished handles all flow
  through the same controller and return the identical indistinguishable 404. The handle page renders the
  SAME allowlisted content as `/c`, with avatar/item-image URLs kept in the `/u/{handle}` family so the
  opaque PUB- ref is never emitted into handle HTML. **No redirect** between `/u` and `/c` in either
  direction. **Phase A: `/u/*` is NOT edge-admitted** (stays Caddy-404).

## 7. Semantics summary

- Handle may be claimed while published OR unpublished (requires an existing publication row). Unpublish
  does NOT release the handle; republish restores the same `/u` route. Profile-public eligibility still
  gates 200 on `/u` exactly as on `/c`.
- Rename is one atomic transaction (account lock → publication lock → validate → verify no active/
  tombstoned owner → tombstone old → repoint). Old `/u/old` → immediate 404 (no redirect); `/c/PUB-…`
  unchanged; the old handle never appears on the new page.
- Pseudonymization removes the active handle + tombstones it 90 days in the same privacy transaction,
  before publication deletion; old handle 404s the instant it commits; no handle copied to provenance.
- Presentation/privacy only; **zero provenance** writes.

## 8. Tests

**Focused (stable, repeated green):**
- `CollectorHandleTest` — **49 passed** (incl. DataProviders): default-absent + `/c` unchanged (h1);
  canonicalization + case-insensitive resolve (h2, h2b); 12 invalid-syntax rejects (h3); 12 reserved
  name/prefix rejects (h4); auth/active/publication-required (h5/h5b/h5c); set≠publish + unpublish keeps
  handle + republish restores (h6); `/u` allowlist parity + no PII/opaque leak + `/u`-family asset URLs
  (h7); handle avatar + item-image enforce same eligibility + 404 on unpublish (h8); atomic rename old-404-
  no-redirect + `/c` unchanged + 90d tombstone (h10); old handle absent from new page (h20);
  cross-collector cannot claim tombstoned before expiry (h12); deterministic clock expiry allows reuse
  (h13); removal leaves no route + PUB unchanged (h14); pseudonymization tombstones + all routes 404
  (h15); cannot set/resurrect after pseudonymization (h25); zero provenance (h16); case-variant collision
  (h17); indistinguishable 404s across unknown/malformed/reserved/tombstoned/unpublished (h18); opaque
  avatar/item-image unchanged (h19); private UX controls (h21/h21b); set+remove idempotency (h22); no
  availability/directory endpoint (h24); schema UNIQUE/null/default + tombstone uniqueness (h23).
- `CollectorHandleConcurrencyTest` — **2 passed**, REAL two-connection (non-transactional, self-cleaning):
  `cc1` two collectors claiming the same normalized handle — while the winner holds the UNIQUE-index entry,
  the loser's claim TERMINATES in the generic `UNAVAILABLE` (R1: never a raw `1205/1213`/500), writes no
  handle, leaves no partial tombstone; exactly one winner; `cc2` rename-away leaves no window — a concurrent
  claim of the released handle is UNAVAILABLE both during the in-flight rename and after it commits
  (tombstoned). Hardened so it can never poison the suite (racer transaction always committed/rolled-back in
  a `finally`; tearDown defensively rolls back any open transaction on either connection).

CP-5 focused suite = **51 passed**, stable across repeated isolated runs (cc1 ~3.6s = bounded retries
resolving to a clean `UNAVAILABLE`).

**Full governed regression (`tests/Feature/Sca`) — ONE CLEAN RUN:** `php artisan test tests/Feature/Sca`
→ **exit 0 · 1188 passed · 1 skipped · 0 failed · 6033 assertions · 320.9s** (the 1 skip = the known WebP GD
environment skip). This clean run was obtained once the competing Claude/test-runner session stood down —
the earlier 1205/1213 "deadlock storm" (variable 3–23 failures, all on pre-existing provenance paths
unchanged by CP-5, all passing in isolation) was caused by TWO sessions running the full suite concurrently
against the same `sca_domain_test` (genuine two-connection contention), not by CP-5. A preceding run after a
`migrate:fresh` showed a single unrelated failure (`CertificateDocumentClassificationTest::d9`) caused by
the reset auto-increment making a media PK the tiny value `10`, which `assertDontSee('10')` matched
incidentally in page markup; it passes in isolation and on any non-reset DB (the established gate never
resets), and recurred zero times once IDs advanced — a pre-existing test fragility unrelated to CP-5.

## 9. Production state (verified at restored baseline)

Live tree restored to `main` = `7409a33` (deployed SHA unchanged), `--no-dev` re-pruned, caches cleared.
- Prod `sca_krayin` migrations **133**; `handle`/`handle_normalized`/`handle_changed_at` columns **absent**;
  `sca_collector_handle_reservations` table **absent** (CP-5 migration applied only to the disposable
  `sca_domain_test`).
- **Provenance reconciliation (established procedure, re-run read-only on prod):** canonical counts
  `items/qr/certs/auth/ownership/claims/grants/sale/status = 3/3/4/4/5/2/1/1/7` — **byte-identical to the
  established CP-4 baseline**; zero writes performed against production.
  - **Reporting mismatch documented:** the `532ea48d9c2b93725fb78d99f5d7b0a8` value in the prior candidate
    report was computed with a REDUCED, count-only formula — `MD5(CONCAT_WS('|', <7 counts>))` omitting
    `grants` and `sale` — a different calculation, not the established fingerprint. The established CP-4
    baseline FP `35e063282e004eaabcc9240360ecc0e3` is a composite ROW-DATA fingerprint (per-table
    `GROUP_CONCAT` of row contents across the provenance tables, migration excluded), NOT a count hash: for
    confirmation, `MD5(CONCAT_WS('|', <all 9 counts>))` = `5d37b79bcfad7f3dc2431872ac9ae99d`, which also is
    not `35e06328…`, proving the established FP is row-content-based. The exact composite SQL was produced
    in an earlier (CP-2/CP-3/CP-4) session whose transcript is not retained here, so it could not be
    reproduced byte-for-byte in this session; the authoritative, reproducible data-unchanged invariant is
    the canonical count tuple above, which matches exactly. No data mismatch — a reporting/formula mismatch
    only, now corrected to the established 9-count procedure.
- Collector accounts **3** / public profiles **0** / public items **0**.
- `STRIPE_ENABLED=false`; `MAIL_MAILER=log`.
- Edge: `GET /u/ada` → **404 `server: Caddy`** (edge-blocked — never reaches the app); `/c/*`, `/p/*`,
  `/collector/*` reachable; `/admin/login` loopback → 200. **No Caddy/DNS/Stripe/SMTP/Shopify change.**

## 10. Coordination note

A second Claude session (`sca-cc`) was concurrently assigned the same CP-5 task on the same bind-mounted
working tree and the same `sca_domain_test`; its parallel full-suite runs were the real cause of the
transient 1205/1213 failures observed during the first candidate. It has fully stood down and confirmed
`2d87c38`/`681bc45` are authoritative with nothing of its own to preserve. All further CP-5 work is owned by
this session.

**STOP for ChatGPT re-audit of head `2d87c38`.** Do not merge/deploy/activate the `/u/*` edge, and do not
start CP-6.

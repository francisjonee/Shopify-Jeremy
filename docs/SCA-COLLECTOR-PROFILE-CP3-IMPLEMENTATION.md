# SCA Collector Profile — CP-3 — Public Profile Foundation — CANDIDATE

**Date:** 2026-10-09 · **Status: CANDIDATE pushed, NOT merged / NOT deployed / production untouched / Stripe DORMANT / mail=log. STOP for ChatGPT pre-merge audit.**

- **Branch:** `feat/sca-collector-profile-cp3`
- **Base (exact production baseline):** `a1e1d495d89d82fcfe921789e2b2bc4248874c0d`
- **Candidate head:** `76057cb388726b139345fe4ff7fbe5aeaf4c4360`
- **Impl repo:** `francisjonee/francisjonee-sca-platform-private` · **Governance:** `francisjonee/Shopify-Jeremy`
- **Migrations:** candidate **131 → 132** (one additive table `sca_collector_public_profiles`); **prod stays 131** until deployment.

## Invariant honoured
**Ownership ≠ publicity.** A collector becomes public ONLY by an explicit opt-in recorded in a dedicated publication-state table. No account/profile/avatar/certified-item/ownership/Passport/claim/transfer/collection makes a collector public. CP-3 publishes NO collection or owned items (that is CP-4).

## Changed files (14: 9 new, 5 modified)
NEW: migration `2026_10_13_000001_create_sca_collector_public_profiles.php`; `Models/CollectorPublicProfile.php`; `Exceptions/PublicationRejection.php`; `Services/CollectorPublicProfileService.php`; `Http/Controllers/PublicProfileController.php`; `Resources/views/public/profile.blade.php`; `Resources/views/public/not_found.blade.php`; `tests/Feature/Sca/CollectorPublicProfileTest.php`; `tests/Feature/Sca/CollectorPublicProfileConcurrencyTest.php`.
MODIFIED: `CollectorPrivacyService.php` (pseudonymization integration); `ProfileController.php` (publish/unpublish + publication state in `show`); `collector-routes.php` (private publish/unpublish); `CollectorServiceProvider.php` (public `/c/` routes); `profile.blade.php` ("Public profile" opt-in section).

## Data model (migration 131 → 132)
`sca_collector_public_profiles`: `id`; `collector_account_id` UNIQUE, FK → `sca_collector_accounts` RESTRICT; `public_ref` UNIQUE, server-generated **`PUB-`+32 hex (128-bit)** opaque — NOT the COL- account ref; `is_published` default FALSE; `published_at` nullable; timestamps. Trigger `trg_sca_public_profiles_bu` makes `collector_account_id` + `public_ref` immutable. One row per collector; starts UNPUBLISHED; ref stable across publish/unpublish. Presentation/privacy state only — NOT provenance; no handle/slug, no item ids, no snapshot of presentation content. No provenance table touched.

## Publication lifecycle (`CollectorPublicProfileService` — sole writer/resolver)
Mutation lock order (serializes with CP-1 profile writes AND `CollectorPrivacyService::pseudonymize()`; no inversion): **(1)** `sca_collector_accounts` FOR UPDATE → **(2)** require `status='active'` (else `ProfileLifecycleException`) → **(3)** publication row FOR UPDATE / allocate → **(4)** mutate.
- `publish()` — requires non-blank canonical `display_name` (else `PublicationRejection::DISPLAY_NAME_REQUIRED`); allocates the row + opaque `public_ref` on first publish; sets published + `published_at`; **idempotent** (no ref rotation, no duplicate row); creates NO `sca_collector_profiles` row.
- `unpublish()` — sets `is_published=false`; keeps the row + stable ref (republish restores the SAME ref); idempotent; no-op when no row.
- `resolvePublic()` / `resolvePublicAvatar()` — one fail-closed read (publication `is_published=true` AND account `status='active'`, display_name non-blank); live join to private presentation (nothing snapshotted); return null for every other case.

## Routes / semantics
**Private (behind `collector.auth`, CSRF, throttle 20/min):** `POST /collector/profile/publish`, `DELETE /collector/profile/unpublish` — session collector only (no id/ref from request). The profile page shows a separated "Public profile" section (default private; the public URL is shown ONLY while published).
**Public (UNAUTHENTICATED, `web` group, no auth):** `GET /c/{publicRef}` + `GET /c/{publicRef}/avatar`, addressed only by the opaque `public_ref`; share-by-link, no directory/search, `noindex,nofollow`. Resolves via the published+active resolver; **every** unknown / malformed / unpublished / disabled / pseudonymized / no-avatar case returns the SAME ordinary 404 (indistinguishable — the broad route constraint routes malformed refs through the same controller). Public card renders ONLY: display name, optional avatar, optional bio, optional coarse location, "Collector since Month YYYY", and a privacy/no-endorsement note. The public avatar streams with `X-Content-Type-Options: nosniff` and `Cache-Control: no-store` (so unpublish takes effect immediately; the framework may append `private`); raw path never emitted. The existing private authenticated avatar route is unchanged.

> **Edge note (deployment, out of CP-3 scope):** the production edge currently admits only `/p/*` and `/collector/*`; admitting the new `/c/*` namespace is a Caddy change and is therefore a **separate future deployment step** (CP-3 forbids Caddy/DNS work). The app route + tests exercise `/c/*` directly; public reachability at the edge is deferred to the deployment gate.

## Pseudonymization integration
`CollectorPrivacyService::pseudonymize()` now deletes the publication row atomically in the SAME privacy transaction (lock order account → publication → profile), BEFORE the account is marked pseudonymized — so after commit the public profile + public avatar 404 immediately and no publication can resurrect. It still fails closed while the collector currently owns items (publication + profile left intact), remains idempotent, and mutates no provenance.

## Mandatory tests (all 20 points)
`CollectorPublicProfileTest` — **18 passed**: default-private (p1); auth/staff/self-only + no-retarget (p2); active + non-blank display_name required (p3); opaque ref distinct from account ref + no duplicate/rotate (p4); unpublished route+avatar 404 (p5); allowlisted fields only (p6); no private/collection leakage incl. owned item (p7); public avatar published-only + MIME/nosniff/no-store + no raw path (p8); unpublish closes + republish restores same ref (p9); live edits reflected, no snapshot (p10); disabled account fails closed (p11); pseudonymization removes publication + 404 + zero provenance (p12); owning-item blocks pseudonymization, publication intact (p13); Passport stays identity-free + no profile link (p16); My Collection stays private after publish (p17); zero provenance from publish/unpublish/browse (p18); indistinguishable 404s (p19); UNIQUE + immutability constraints (p20).
`CollectorPublicProfileConcurrencyTest` — **2 passed** (real two-connection, non-transactional): publish serializes on the account lock → one row/ref + replay converges (cc1 / point 15); a publish/unpublish racing a committed pseudonymization fails closed, no resurrection, public route 404 (cc2 / point 14).

CP-1 privacy/profile (`CollectorProfileTest` + `CollectorProfileConcurrencyTest`), My Collection, and Passport regressions retained. Full governed SCA regression: **1105 passed / 5714 assertions, 1 skipped (webp — env GD)**, exit 0. No flake.

## Production state (verified at the restored baseline)
Live tree restored to `main` = `a1e1d49` (deployed SHA unchanged), `--no-dev` re-pruned. Prod `sca_krayin` migrations **131** (CP-3 migration applied only to the disposable test DB); `sca_collector_public_profiles` absent from prod; provenance DATA byte-identical (FP `35e063282e004eaabcc9240360ecc0e3`); collector accounts 3 / profiles 0; `STRIPE_ENABLED=false`, secret UNSET; `MAIL_MAILER=log`. No merge, no deploy, no Stripe/SMTP/Shopify/Caddy/DNS change, no CP-4, no public collection/item visibility, no handle/social/directory.

**STOP for ChatGPT pre-merge audit of head `76057cb`.**

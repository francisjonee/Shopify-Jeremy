# SCA Collector Profile — CP-1 — Private Profile Foundation — CANDIDATE (remediated)

**Date:** 2026-10-08 · **Status: CANDIDATE remediated (audit R1–R4), NOT merged / NOT deployed / production untouched / Stripe DORMANT. STOP for ChatGPT re-audit.**

- **Branch:** `feat/sca-collector-profile-cp1`
- **Base (exact deployed baseline):** `f461c17b7e0cbd5a5e5f026d5f5000870ef04752`
- **Candidate head:** `3c422fe669bc6b14ee8bb476cf6c798cc0a35273` (remediation of prior candidate `5eddb141`)
- **Impl repo:** `francisjonee/francisjonee-sca-platform-private` · **Governance:** `francisjonee/Shopify-Jeremy`
- **Migrations:** prod 130 → candidate **131** (one additive table; prod still 130 — candidate NOT deployed)

## Remediation of the pre-merge audit (R1–R4) — head `3c422fe`

Three files changed from `5eddb141`: `CollectorProfileService.php` (R2 race fix) + `CollectorProfileTest.php` (R1/R3/R4) + new `CollectorProfileConcurrencyTest.php` (R2). No schema/Passport/stats/public-surface change; migration stays 130→131.

- **R1 — avatar DB-failure compensation.** New `av8`: with an existing (old) avatar in place, a **real model-save exception** (`CollectorProfile::saving` throwing) is injected so the DB portion of `setAvatar()` fails AFTER the new bytes are written (production code unchanged — the service stores the file then saves). Proven: the exception propagates; the just-written new file is removed (compensation); the profile still points to the OLD path; the old file remains; exactly one avatar file remains; provenance snapshot byte-identical.
- **R2 — concurrent first-profile creation.** `lockOrNew()` no longer takes a locking read on a MISSING row (that would be an InnoDB gap lock); it reads existence without a lock and locks only an existing row. Concurrent first-creates are made safe by `UNIQUE(collector_account_id)` + a new `withProfile()` wrapper that catches the loser's `1062` and converges it into an update of the now-existing row under a real row lock (UNIQUE + immutability trigger unchanged). New **non-transactional** `CollectorProfileConcurrencyTest`: `cc1` runs a **real two-connection MariaDB race** (a second independent connection inserts+commits the row from inside the `creating` hook of the first request's lock-free create path, `setAvatar`) and proves exactly one correctly-bound row, no surfaced 500, no corruption (racer's bio retained, our avatar applied by the retry); `cc2` proves the sequential replay also yields a single row. **Observed before/after:** without the convergence a lost first-create surfaces a `1062`/HTTP-500; with it the request converges to a single-row update (proven by `cc1`). Note: the ordinary `saveProfile` path additionally serializes two requests on the account `display_name` UPDATE lock, so `1062` there is already avoided — `setAvatar` is the genuine lock-free path the race test exercises.
- **R3 — genuine disabled-account coverage.** New `pa2b`: a `status='disabled'` collector (distinct from pseudonymized) is rejected on profile GET, avatar GET, and a PATCH mutation route, with zero profile mutation and `display_name` unchanged. The prior `ps3` is renamed to `ps3_pseudonymized_collector_cannot_access_profile_routes` (it covers the pseudonymized case).
- **R4 — pseudonymization provenance proof.** `ps1` now establishes real provenance owned by ANOTHER collector, snapshots the provenance surfaces before/after a successful pseudonymization of the target collector (profile + avatar), and asserts them byte-identical — in addition to the existing profile-row/avatar/account effects.

Focused: `CollectorProfileTest` **31 passed / 1 skipped** (webp, GD) + `CollectorProfileConcurrencyTest` **2 passed**. Full governed SCA regression: **1054 passed / 5458 assertions, 1 skipped**, exit 0. Production re-verified untouched (prod `sca_krayin` migr **130**, `sca_collector_profiles` absent, provenance items 3 / certs 4 / ownership 5 unchanged, `STRIPE_ENABLED=false` / secret UNSET, `MAIL_MAILER=log`). **STOP for ChatGPT re-audit of head `3c422fe`.**

---

## Original candidate detail (head `5eddb141`) — unchanged except as remediated above

## Scope delivered
A private, authenticated collector profile (behind the `collector` guard). NOT a public/social profile: no handle, public flag, per-item visibility, social graph, favorites, marketplace, valuation, or analytics. Existing provenance, Passport, My Collection, Shopify, external-paid-auth, payment, certification, transfer, and staff workflows are unchanged.

## Schema
New one-to-one SCA-owned presentation table **`sca_collector_profiles`** (migration `2026_10_12_000001`):
- `collector_account_id` — UNIQUE (`uniq_collector_profile`), FK → `sca_collector_accounts` ON DELETE RESTRICT (consistent with the no-hard-delete identity model), **immutable** under UPDATE via trigger `trg_sca_collector_profiles_bu`.
- `bio` varchar(500) nullable · `location` varchar(120) nullable.
- `avatar_path` / `avatar_mime` — **server-side only**, hidden on the model, never emitted to HTML/DTO/API.
- timestamps.

`display_name` is **not** duplicated — it stays canonical on `sca_collector_accounts` and CP-1 self-edits that existing column.

## Routes (all behind `collector.auth`; no unauthenticated/public profile route)
- `GET  /collector/profile` → `ProfileController@show`
- `PATCH /collector/profile` → `@update` (throttle 20/min) — display_name + bio + location
- `GET  /collector/profile/avatar` → `@avatar` (authenticated self-resolving stream)
- `POST /collector/profile/avatar` → `@uploadAvatar` (throttle 20/min)
- `DELETE /collector/profile/avatar` → `@removeAvatar` (throttle 20/min)

Every action targets the **session** collector id (`Auth::guard('collector')->id()`); no id/ref/email in a payload can retarget a read/write (proved by `pa4`). A staff `user` session does not satisfy the guard (`pa2`). A pseudonymized/disabled account is rejected by `collector.auth` (`ps3`).

## Privacy / storage decisions
- **Avatar on the private `local` disk** (`storage/app/sca/collector-avatars/…`) — never under `public/`, never web-served, never `/storage`. Reachable only through the authenticated self-resolving stream route; response carries the stored MIME, `X-Content-Type-Options: nosniff`, and `Cache-Control: private, no-store`.
- **Server-generated filename** (`{collectorId}-{random}.{ext}`); the upload's own name/path is never trusted or used (`av4`). Narrow allowlist enforced server-side (`mimetypes:image/jpeg,image/png,image/webp` + `mimes` + `max:5120`): SVG / non-image / oversize rejected (`av3`).
- **Replace** stores the new file, repoints the row in a transaction, deletes the old file on success, and compensates (deletes the just-stored new file) if the DB update throws — so a failure never leaves the profile pointing at a missing/partial file or an unbounded trail (`av6`, service `setAvatar`). **Remove** clears the pointer then deletes the bytes (`av7`).
- **Pseudonymization** (`CollectorPrivacyService::pseudonymize`, extended): inside the same transaction it captures the avatar path and **deletes the profile row atomically** with clearing account PII — so the instant pseudonymization commits, the profile row (the only thing that makes the avatar reachable through the authenticated stream) is gone and the avatar is irretrievable via the app. The avatar **bytes are deleted after commit**; a failure there can only leave an unreachable orphan, never reachable identifiable data. Still **fails closed while the collector owns items** (profile + avatar + identity all intact, `ps2`), remains **idempotent** (`ps4`), and preserves provenance exactly (`ps1`).

## Derived statistics / collector-since
`CollectionService::collectionStats` derives, from canonical **current** ownership (`sca_item_current_state`), the counts shown on the profile — never stored counters:
- owned = items the collector currently owns; certified = those with a current certification; brands = distinct **known** brands (null/empty is not a fake brand, case-insensitive).
Transfer automatically drops the prior owner and raises the recipient (`st5`); an unclaimed external-auth submission is not counted (`st6`); null brand not counted (`st3`); certified reads `current_certification_id` independently of owned (`st4`). "Collector since" uses the existing account `created_at` (`cs1`) — no new join-date field.

## Data / provenance invariants
Profile and avatar actions create/mutate **zero** provenance (items/auth/certs/QR/claims/grants/ownership/status/service/Shopify/submissions/payments/returns) — proved byte-for-byte by `zp1` snapshot. Public Passport output exposes none of display_name/bio/location/avatar/email/COL-ref and still resolves publicly (`pp1`); CP-1 adds no Passport code and no robots/indexing change.

## Exact changed files (12: 8 new, 4 modified)
NEW: `Sca/Provenance/.../Migrations/2026_10_12_000001_create_sca_collector_profiles.php`, `Sca/Provenance/src/Models/CollectorProfile.php`, `Sca/Provenance/src/Services/CollectorProfileService.php`, `Sca/Collector/src/Http/Controllers/ProfileController.php`, `Sca/Collector/src/Http/Requests/UpdateProfileRequest.php`, `Sca/Collector/src/Http/Requests/UploadAvatarRequest.php`, `Sca/Collector/src/Resources/views/profile.blade.php`, `tests/Feature/Sca/CollectorProfileTest.php`.
MODIFIED: `Sca/Collector/src/Routes/collector-routes.php` (5 profile routes), `Sca/Provenance/src/Services/CollectorPrivacyService.php` (profile-row + avatar removal), `Sca/Collector/src/Services/CollectionService.php` (`collectionStats`), `Sca/Collector/src/Resources/views/account.blade.php` (link to profile).

## Tests
`CollectorProfileTest` — **29 passed / 116 assertions, 1 skipped** (`av2` webp — GD lacks WebP support in this runtime; JPEG/PNG acceptance + the full allowlist boundary are proven). Covers: unauth rejection, staff-guard isolation, own-only access, no-retarget, create/update, length validation, normalization + empty→NULL, email-immutable-via-payload, avatar accept/reject/stream/self-only/replace/remove/filename-privacy, zero-provenance, stats (owned/certified/brands/null-brand/certified-distinction/transfer/unclaimed), collector-since, Passport privacy, pseudonymization (remove + fail-closed + disabled-access + idempotent), DB uniqueness + binding immutability.

Full governed SCA regression (`tests/Feature/Sca`): **1050 passed / 5432 assertions, 1 skipped**, exit 0 (1021 prior + 29 new).

## Production untouched + Stripe dormant (verified at the restored baseline)
Live tree restored to `main` = `f461c17`, `--no-dev` re-pruned. Prod `sca_krayin` migrations **130** (CP-1 table NOT applied); `sca_collector_profiles` absent from prod; provenance unchanged (items 3 / certs 4 / ownership 5 / returns 0); `STRIPE_ENABLED=false`, `STRIPE_SECRET` UNSET; `MAIL_MAILER=log`. No merge, no deploy, no Stripe/SMTP/Caddy/DNS/Shopify change, no Krayin/vendor edit, no CP-2.

**STOP for ChatGPT pre-merge audit of head `5eddb141`.**

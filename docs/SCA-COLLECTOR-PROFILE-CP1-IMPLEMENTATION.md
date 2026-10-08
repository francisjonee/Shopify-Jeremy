# SCA Collector Profile — CP-1 — Private Profile Foundation — CANDIDATE

**Date:** 2026-10-08 · **Status: CANDIDATE pushed, NOT merged / NOT deployed / production untouched / Stripe DORMANT. STOP for ChatGPT pre-merge audit.**

- **Branch:** `feat/sca-collector-profile-cp1`
- **Base (exact deployed baseline):** `f461c17b7e0cbd5a5e5f026d5f5000870ef04752`
- **Candidate head:** `5eddb141d175b5cbfa7e409a46f44fefd8617d98`
- **Impl repo:** `francisjonee/francisjonee-sca-platform-private` · **Governance:** `francisjonee/Shopify-Jeremy`
- **Migrations:** prod 130 → candidate **131** (one additive table; prod still 130 — candidate NOT deployed)

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

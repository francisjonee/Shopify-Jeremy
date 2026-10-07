# SCA External Paid Authentication Intake — Slice 4 pre-activation Payment Concurrency Hardening — implementation candidate (NOT merged/deployed; Stripe DORMANT)

**Date:** 2026-10-07 · **Status: IMPLEMENTED + TESTED + PUSHED on a candidate branch. NOT merged, NOT deployed, Stripe NOT activated. Live tree restored to `main`; production byte-identical (prod stays 128 — new migration ABSENT).** For ChatGPT candidate audit. Addresses the two concurrency boundaries ChatGPT flagged on the (dormant) Slice-4 payment path.

## Candidate identity
- **Branch:** `origin/feat/sca-payment-concurrency-hardening`
- **Base SHA (= deployed `main`, merge-base):** `2aedebb734eab15cf26f4e8b43c8a8bc441d90d9`
- **Head SHA:** `83225a6071c0ec512ed3e85d6ab4b64c975178ee` (1 commit)
- **Migrations added:** **1** (additive, column + unique index) → prod 128 → **129 at a future deploy** (NOT applied to prod; applied only to `sca_domain_test`).

## Issue 1 — concurrent `/pay` could create two usable Checkout Sessions
**Before:** `createOrReuseSession` did check-pending → create-Stripe-session → insert, with no serialization; two concurrent `/pay` for the same submission could both see no pending payment and both create a session. **Fix (two layers):**
1. **Application serialization:** `createOrReuseSession` now runs inside `DB::transaction` and takes a `lockForUpdate` **row lock on the submission** first, re-validating owner + `submitted` and re-checking the pending payment **under the lock**. A second concurrent request blocks, then reuses the pending payment the first created — it never calls Stripe (no orphan session). Different submissions are unaffected (per-row lock).
2. **DB backstop guard (the provable invariant):** new nullable column `active_pending` = `submission_id` **while pending**, set `NULL` the instant the payment leaves pending (succeeded/failed/expired), with **`UNIQUE(active_pending)`**. This guarantees **at most one pending payment per submission** at the storage layer — many terminal rows per submission are still allowed (NULLs are not unique in MariaDB), so retries over time are fine. Snapshot amount/currency semantics unchanged; the session is still created server-side with the authoritative configured price.

## Issue 2 — concurrent duplicate webhook could return a retryable 500
**Before:** `process()` did a `lockForUpdate()->exists()` pre-check then insert; a concurrent delivery of the same new event could pass the check and then hit the `event_id` UNIQUE on insert, surfacing as a 500. **Fix:** the **UNIQUE event-id INSERT is now the idempotency gate** — `process()` inserts the receipt FIRST (claim), then applies the event; a concurrent/replayed duplicate blocks on the unique key, fails `1062`, is caught, and is returned as **`duplicate` → HTTP 200** (no second apply, no state double-mutation). Only a genuine infrastructure error propagates (controller returns a retryable 5xx). `active_pending` is released to `NULL` on succeeded/failed/expired so a terminal payment never pins the guard.

## Preserved (unchanged)
Amount/currency snapshot; collector isolation (owner-scoped; another collector's ref → 404); webhook-only confirmation (success advances only `submitted → awaiting_item`, never downgrades on late/out-of-order); zero-provenance behavior; the full payment state machine; refund history preservation; staff manual-override distinction. **No existing DB constraint weakened (one added).** **Stripe remains DORMANT** (`STRIPE_ENABLED` false, secrets UNSET; fail-closed at app + edge).

## Exact changed files (1 new, 3 modified)
New: migration `2026_10_10_000001_add_active_pending_guard_to_sca_authentication_payments.php`.
Modified: `Provenance/src/Services/StripeCheckoutService.php` (lockForUpdate serialization + `active_pending` on insert), `Provenance/src/Services/StripeWebhookService.php` (insert-first idempotency gate + 1062→duplicate + release `active_pending` on terminal), `tests/Feature/Sca/StripePaymentTest.php` (+4 concurrency tests). No other package touched; no route/ACL/UI change; no Shopify/MAIL/DNS/Caddy change.

## Tests
- **`StripePaymentTest` — 19 passed / 64 assertions** (15 prior + 4 new concurrency):
  - `c1` — DB guard blocks a **second pending payment** for one submission (`UNIQUE(active_pending)` → 1062): the concurrency invariant, provable directly (not sequential-only).
  - `c2` — under contention (a pending session already exists) a second `createOrReuseSession` **reuses** it, returns the existing session id, creates no second row, and **never calls Stripe** (`Http::assertNothingSent()`).
  - `c3` — a terminal (failed) payment **releases** `active_pending`, so a fresh `/pay` legitimately creates a new session (retry path).
  - `c4` — a concurrent/duplicate webhook (event id already recorded) is a **clean `duplicate` → HTTP 200**, not a 500, with no second mutation and one receipt.
  - (existing p1–p15 remain green: signature valid/invalid/stale, isolation, success/failure/expiry/cancel, replay idempotency, refund history, override distinction, zero provenance.)
- **Full governed gate:** **957 passed / 5080 assertions**, exit 0 (953 Slice-4 baseline + 4).

## Production-safety verification (post-restore)
- Live tree restored to `main` @ **`2aedebb734eab15cf26f4e8b43c8a8bc441d90d9`**; vendor re-pruned `--no-dev`; caches cleared.
- **Candidate code absent on `main`:** `active_pending` column **ABSENT** in prod; `StripeCheckoutService` on main has 0 `lockForUpdate` occurrences (candidate reverted).
- **Prod DB unchanged:** migrations **128**; provenance counts byte-identical (items 3 / certs 4 / ownership 5 …); `config('sca-stripe.enabled')=false`.
- Stripe/MAIL/Shopify/Caddy/DNS untouched; no production mutation, no deploy, Stripe not activated.

## Candidate gate
**NOT merged. NOT deployed. Stripe NOT activated. No production mutation.** Also in governance: `NEXT_TASK.md` cleaned to a single authoritative current-baseline section (stale duplicated baseline/CLOSED blocks removed); the authoritative Slice-4 status is unchanged — **Slices 1–4 CODE DEPLOYED; Stripe DORMANT; capability OPEN.**

---

## Remediation R1 (candidate audit FAIL → fixed) — migration backfill + fail-closed

**Previous candidate head:** `83225a6071c0ec512ed3e85d6ab4b64c975178ee`
**New candidate head:** `8db2e94d2c1b6bce725ce757807b7274071c2b57`

**Blocker (audit):** the guard migration added `active_pending` nullable + `UNIQUE(active_pending)` but did **not** backfill existing `status='pending'` rows. After upgrading a non-empty DB, a pre-existing pending payment would keep `active_pending = NULL`; since multiple NULLs are allowed by the unique index, the "at most one pending payment per submission" invariant would NOT hold for migrated data (a new `/pay` could create a guarded pending alongside an unguarded legacy one). Schema correctness must not depend on today's empty prod table.

**Fix — reworked `up()` (order matters; DDL auto-commits so validation is first):**
1. **FAIL CLOSED FIRST**, before any DDL: if legacy data has more than one `status='pending'` payment for any submission, `throw \RuntimeException` naming the offending submission id(s) — never silently pick one and leave another unguarded.
2. Add the nullable `active_pending` column.
3. **Backfill**: `UPDATE … SET active_pending = submission_id WHERE status='pending'`.
4. Terminal rows stay `NULL`.
5. Add `UNIQUE(active_pending)` only **after** the data is valid + backfilled.
Also: dropped the no-op `use RuntimeException` (the migration is global-namespace → `\RuntimeException`), and corrected the docblock to state accurately that the guard is released on **succeeded/failed/expired** (the only pending→terminal transitions any code performs), that **refunded** is reached only from succeeded (already NULL), and that **cancelled** is a CHECK-allowed status with **no current transition** (verified by grep — no code sets `cancelled`), so it needs no release path.

**Migration-focused test added — `PaymentGuardMigrationTest` (non-transactional, self-restoring; runs the REAL migration `up()` from a simulated pre-129 state, with try/finally that deletes `migtest_` fixtures and restores the 129 schema):**
- `m1` — a single legacy `pending` payment is **backfilled** to `active_pending = submission_id`, a legacy `succeeded` payment stays **NULL**, the UNIQUE index is established, and it is immediately authoritative (a second pending for that submission is rejected, `23000`).
- `m2` — a legacy **duplicate-pending** state makes the migration **FAIL CLOSED** (`RuntimeException` "multiple pending payments…") **before any DDL** — the column and unique index are NOT added.

**Test totals (remediated):** focused `StripePaymentTest` **19** + `PaymentGuardMigrationTest` **2** = 21 payment-area tests; **full SCA gate 959 passed / 5089 assertions** (953 Slice-4 baseline + 4 concurrency + 2 migration).

**Production-safety re-verified:** live tree restored to `main` @ `2aedebb`; candidate code absent (`active_pending` column ABSENT in prod, `PaymentGuardMigrationTest` not on disk); prod migrations **128**; provenance counts byte-identical (items 3 / certs 4 / ownership 5 …); `config('sca-stripe.enabled')=false`; Stripe/MAIL/Shopify/Caddy/DNS untouched.

**Candidate gate:** NOT merged, NOT deployed, Stripe NOT activated, no production mutation. Awaiting ChatGPT **re-audit** of head `8db2e94d2c1b6bce725ce757807b7274071c2b57`.

See `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE4-{IMPLEMENTATION,DEPLOY-RESULT}.md`.

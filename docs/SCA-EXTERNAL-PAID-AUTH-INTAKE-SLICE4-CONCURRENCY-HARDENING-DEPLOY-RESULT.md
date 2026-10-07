# SCA External Paid Authentication Intake — Slice 4 pre-activation Payment Concurrency Hardening — merge + governed deploy result (Stripe DORMANT)

**Date:** 2026-10-07 · **Status: ✅ DONE — merged `--no-ff` + deployed (1 additive migration; prod 128→129). Post-deployment verification PASS. Stripe remains DORMANT. No Stripe credentials/dashboard/Caddy/Shopify/MAIL/DNS change.** Authorized after ChatGPT RE-audit PASS of head `8db2e94d2c1b6bce725ce757807b7274071c2b57` (gov evidence `707fda0413cfc4cd7ee785b4155a233f6713c12b`).

## SHAs
- **Base / deployed-from:** `2aedebb734eab15cf26f4e8b43c8a8bc441d90d9`
- **Audited candidate head:** `8db2e94d2c1b6bce725ce757807b7274071c2b57` (unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `5b30120488d2d7b9975260a142c540ce0f2b843b`**

## Pre-merge gates (fail-closed) — all PASS
candidate head `8db2e94` unchanged; `origin/main` == merge-base == `2aedebb`; tree clean. **Byte-equivalence:** `git diff 8db2e94..mergeSHA` is empty (the merged tree equals the audited candidate; only merge-commit mechanics differ). Exactly 1 additive migration in the diff.

## Pre-migration production safety check — PASS
Before migrating: prod had **0 pending payments** and **no submission with conflicting duplicate pending payments** — so the migration's fail-closed guard had nothing to abort on (verified read-only on prod before merge).

## Deploy (`scripts/deploy-preview.sh`)
`git reset --hard origin/main` → `5b30120`; SCA gate on `sca_domain_test` **959 passed / 5089 assertions** (incl. `StripePaymentTest` 19 + `PaymentGuardMigrationTest` 2); `migrate --force` → the 1 migration ran → **129**; memory-capped rebuild + `docker compose up -d` (sca project only); `--no-dev` prune; caches cleared; healthy; `GET /admin/login → 200`; `Deployed main @ 5b30120`. (No QR flake this run.)

## Migration result (128 → 129) — verified
| Check | Result |
|---|---|
| migration count | **129** |
| `active_pending` column exists | **PRESENT** |
| `uniq_payment_active_pending` unique index | **PRESENT** |
| existing pending rows correctly guarded | prod has **0 pending** rows → 0 guarded (vacuously satisfied); migration backfill path proven by `PaymentGuardMigrationTest::m1` on the gate |
| terminal rows unrestricted/NULL | **0** terminal rows carry a non-NULL `active_pending` |

## Post-deployment verification — all PASS
| Check | Result |
|---|---|
| deployed HEAD == merge SHA | `5b30120488d2d7b9975260a142c540ce0f2b843b` |
| focused Stripe/payment regression | green on the deploy gate — `StripePaymentTest` 19 (signature valid/invalid/stale, isolation, duplicate-reuse, replay idempotency, success/failure/expiry/cancel, late-no-downgrade, refund history, override distinction, zero provenance) **+ 4 concurrency** (`c1` DB guard, `c2` reuse-under-contention, `c3` terminal-releases-guard, `c4` duplicate-clean-200) + `PaymentGuardMigrationTest` 2 (backfill, fail-closed) |
| provenance DATA unchanged | DATA fingerprint (migration count EXCLUDED) **byte-identical** `87247ca349f8747664a3526f9283eade`; counts items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3 |
| operational tables | payments **0**, Stripe receipts **0**, submissions **0** |
| Shopify behavior unchanged | unsigned `POST /sca/shopify/webhook` → **401**; no API/OAuth/scope/webhook change |
| MAIL/SMTP unchanged | `MAIL_MAILER=log` |
| Caddy/DNS unchanged | no change |
| **Stripe DORMANT** | `config('sca-stripe.enabled')=false`; `STRIPE_SECRET`/`STRIPE_WEBHOOK_SECRET` **UNSET**; external `POST /sca/stripe/webhook` → **404** (edge does not admit it); app-level webhook (loopback, no secret) → **400** (fail-closed); no real/test payment initiated |
| `/p/{bogus}` · `/collector` · `/collector/submissions` | **404 · 302 · 302** |
| `/storage/..` · external `:8080` · smsrocket | **404 · 000 · 302** |

## Provenance fingerprint analysis (migration-count vs data mutation)
Composite fingerprint folds migration count, so 128→129 moves it solely as **schema-version movement** (one added column + unique index on an empty table). Computed independently with migration count EXCLUDED, the provenance DATA fingerprint is **unchanged** (`87247ca3…`). No authentication/certification/QR/ownership/claim/Shopify-sale/service/item record changed.

## Boundaries confirmed (NOT approved items untouched)
No Stripe activation; no Stripe credentials; no Stripe dashboard/webhook configuration; no Caddy admission of the Stripe webhook; no Slice 5/6; no SMTP activation; no unrelated work. Only the 1 approved additive migration applied.

**Outcome: DONE (merged `--no-ff` + deployed, `5b30120`); provenance DATA byte-identical; prod migrations 128→129; the one-pending-payment guard is live and authoritative; Stripe remains DORMANT at both the edge (404) and the app (400 without secret).** Slices 1–4 CODE DEPLOYED (with concurrency hardening); Stripe activation is a separate gate (not performed); the overall capability remains OPEN (activation + Slices 5–6 pending). See `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE4-CONCURRENCY-HARDENING-IMPLEMENTATION.md`.

# SCA External Paid Authentication Intake — Slice 6: Exceptions & Returns — DISCOVERY + CANDIDATE

**Date:** 2026-10-08 · **Status: CANDIDATE pushed, NOT merged / NOT deployed / Stripe DORMANT. STOP for ChatGPT audit.**

- **Branch:** `feat/sca-external-paid-auth-slice6`
- **Base (exact deployed baseline):** `7ff176c4b36d0eba805e296d83326f6d0f998fc1`
- **Candidate head:** `5ee1067217a8c2fd8bea96bf3a7062db33856438`
- **Impl repo:** `francisjonee/francisjonee-sca-platform-private` · **Governance:** `francisjonee/Shopify-Jeremy`
- **Migrations:** 129 → **130** (one additive table; prod still at 129 — candidate NOT deployed)

---

## Part 1 — Discovery conclusions (inspected at the exact baseline)

**Submission schema / constraints / triggers** (`2026_10_08_000001`): `sca_authentication_submissions` has `status` CHECK = `draft/submitted/awaiting_item/received/cancelled` and the custody bridge `eyewear_item_id` (UNIQUE `uniq_submission_item`). Trigger `trg_sca_auth_submissions_bu` makes `collector_account_id`/`public_ref` immutable and (post-Slice-2) permits `eyewear_item_id` NULL→value exactly once, then immutable. **The submission status set is terminal at `received`.**

**Status-event ledger** (`2026_10_08_000002`): `sca_submission_status_events`, append-only (`no_update`/`no_delete` SIGNAL triggers), CHECK `to_status` over the same five statuses. OPERATIONAL audit only — never folded by ProjectionService.

**SubmissionService** is the sole writer of the submission + ledger; `TRANSITIONS` is forward-only; `received`/`cancelled` are terminal. **CustodyAcceptanceService** is the sole first-bind path (creates the one `external_intake` item + binds + `received`). Downstream authentication/certification/grant/ownership/registry all run the normal item lifecycle on the bound item; canonical reads are `sca_authentications.result`/`finalized_at`, `sca_item_current_state.current_certification_id/current_owner_collector_id/registry_status`, `ExternalClaimGrantService::currentIssuedToken`, `StatusService::ADVERSE_STATUSES`.

**Stripe payment/refund** (Slice 4 + R1): webhook-driven; refund is recorded as a payment `status=refunded` (history preserved) and never auto-changes submission/provenance. Slice 6 may DISPLAY refund state (via the existing staff payment summary) but builds no refund initiation.

**Staff + collector surfaces:** staff `Sca\Registry\...\SubmissionController` (index/show/accept/advance/grant) gated by `sca.eyewear.submission` (read) + `sca.eyewear.submission.accept` (custody) + `sca.eyewear.claim` (grant); collector `Sca\Collector\...\SubmissionController` (owner-scoped; result + submission-bound claim).

**Existing shipping/address/tracking/return primitive:** **NONE.** A repo-wide search found no carrier/tracking/shipment/return record, address storage, or logistics event anywhere in `packages/Sca`. → A dedicated operational record is justified; there is no accepted primitive to reuse.

**Conclusion / chosen approach:** introduce a dedicated operational **return/shipment record** with its OWN status, rather than extending the submission status machine or overloading a registry status. This keeps the submission machine provenance-neutral and the five-status CHECK + `SubmissionService.TRANSITIONS` **untouched** (zero risk to Slices 1–5), and isolates return logistics in their own table — matching Part 2/Part 4 of the promotion.

---

## Part 2–5 — Domain boundary, lifecycle, record, concurrency

**New table `sca_authentication_returns`** (`2026_10_11_000001`, 129→130):

| Column | Notes |
|---|---|
| `submission_id` | FK → submissions, **UNIQUE** (`uniq_return_submission`) — one return per submission |
| `eyewear_item_id` | FK → eyewear_items, **UNIQUE** (`uniq_return_item`) — the SAME bound item, derived server-side |
| `status` | CHECK `return_pending/return_in_transit/returned`, default `return_pending` |
| `carrier`, `tracking_reference` | staff-entered strings (no carrier API) |
| `reason` | operational return reason/category (NOT an outcome fact) |
| `prepared_by_staff_ref`, `shipped_by_staff_ref`, `returned_by_staff_ref` | soft historical refs (no behavioural FK) |
| `prepared_at`, `shipped_at`, `returned_at` | per-stage audit timestamps |

**DB-level guarantees** (trigger `trg_sca_auth_returns_bu`, BEFORE UPDATE):
- `submission_id` + `eyewear_item_id` **immutable** (custody binding cannot be re-pointed).
- `status` **advance-only**: only `return_pending→return_in_transit` and `return_in_transit→returned`; any reverse/skip SIGNALs. Terminal at `returned`.
- `UNIQUE(submission_id)` is the storage backstop against a concurrent double-prepare creating a second record.

**State machine** (`received` →) `return_pending` → `return_in_transit` → `returned`. The submission stays `received` throughout; return states live ONLY on the return record and NEVER enter the submission ledger (asserted in `p3`).

**`ReturnService`** (sole writer; every mutation `DB::transaction` + `lockForUpdate`):
- `isReturnReady(itemId)` — canonical safe-return point = finalized auth `failed`/`inconclusive` **OR** item certified (`current_certification_id` set). Ownership/claim are NOT prerequisites.
- `prepare` — eligibility under a submission lock: `received` + bound + `isReturnReady`; bound item derived server-side; **idempotent** (existing return of any state returned unchanged, never reset); `forceFill` sets the guarded binding once.
- `markShipped` — `pending→in_transit`, records carrier/tracking; idempotent when already in transit (never overwrites recorded shipment facts); reverse from `returned` fails closed.
- `markReturned` — `in_transit→returned`; idempotent terminal; skip from `pending` fails closed.
- New rejection codes `RETURN_NOT_ELIGIBLE`, `RETURN_NOT_FOUND`, `RETURN_INVALID_TRANSITION`.

**Concurrency** proven: double-prepare → one record (`i1`, `i3` UNIQUE); double-ship/return converge (`i2`); reverse/skip fail closed at service (`s2`,`s3`,`s4`) AND DB (`d3`,`d4`); binding immutable at DB (`d1`,`d2`); cannot inject another submission's item (binding derived server-side + immutable); return cannot create a second eyewear item (`p2`); `returned` cannot re-enter custody (terminal).

---

## Part 6–7 — Staff + collector surfaces

**Staff:** new **dedicated** ACL `sca.eyewear.submission.return` (return logistics authority; distinct from read + from custody-intake — it grants NO provenance authority). Routes (POST-only, consistent with advance/grant): `admin.sca.submission.return.{prepare,ship,complete}`. The submission detail page gains a **Physical return** section showing return state/carrier/tracking/reason/timestamps and the Prepare→Ship(carrier,tracking)→Complete actions, shown only once a frame is in custody and gated by the new permission.

**Collector:** the existing submission page gains a **Returning your frame** card with safe copy per state (preparing / on its way back + carrier+tracking / returned), driven by a collector-safe presenter exposing ONLY state/carrier/tracking/dates — **never** internal ids, staff refs, or the internal return reason (asserted in `k1`). The Slice-5 result + claim action are untouched; a returned certified frame is still claimable (`k4`). No collector-facing return mutation route exists (`k2`); cross-collector return info is privacy-safe 404 (`k3`).

---

## Part 8–9 — Exceptions & critical invariants (all asserted)

- Pre-custody `cancelled`/`submitted` → not return-eligible (`e1`); terminate via the existing submission machine, not this one.
- Failed (`e3`) / inconclusive (`e4`) → return-eligible after finalization; **inconclusive is never silently converted to failed** (distinct canonical result read).
- Passed-but-not-certified → NOT eligible; the safe point for success is **certification** (`e6`). Certified → eligible (`e5`).
- Return requires **no** ownership/claim (`e7`); already-claimed → return proceeds, ownership intact (`c2`); returned-before-claim → collector can still claim later (`c1`).
- Adverse registry status → certified frame still physically returnable, and the return does **not** clear the adverse status (`a1` over lost/stolen/disputed/retired/invalidated).
- Refund: no Stripe refund initiation built (unchanged); existing refund state remains displayable via the staff payment summary.
- **Zero new provenance:** a full return mutates NONE of items/auth/authResult/certs/currentCert/owner/registry/ownership/claims/grantState/qr/sale (`p1` byte-identical snapshot); the **claim grant is never consumed** by a return (`c1`); finalized auth, certification, ownership, registry status, and the submission→item binding all survive.

---

## Part 10 — Tests

`tests/Feature/Sca/SubmissionReturnTest.php` — **36 passed / 79 assertions** (disposable `sca_domain_test`, hard-guarded, rolled back per test): eligibility `e1–e7`; state machine `s1–s4`; idempotency/concurrency `i1–i3`; DB immutability + advance-only `d1–d4`; zero-provenance + status-isolation `p1–p3`; claim independence `c1–c2`; adverse survival `a1`×5; staff ACL/HTTP `h1–h3`; collector UX `k1–k5`.

**Full governed SCA regression: `1021 passed / 5306 assertions`, exit 0** (985 prior + 36 new).

---

## Part 11 — Migration safety

Additive single table; alters/removes nothing; preserves all existing rows (there are none — it is a fresh operational table). Proper indexes + two UNIQUE guards + CHECK + immutability/advance-only trigger. Designed as though real submissions already exist: the binding is derived server-side and immutable, and every state transition is DB-enforced. `down()` drops the trigger then the table. Applied cleanly to `sca_domain_test` (129→130); **prod `sca_krayin` remains at 129** (not deployed).

---

## Part 12 — Stripe DORMANT (verified at the restored baseline)

`:8099` not launched; no `sk_test_`/`whsec_` entered; no Stripe CLI; no Checkout; `STRIPE_ENABLED=false`, `STRIPE_SECRET` UNSET, `STRIPE_WEBHOOK_SECRET` UNSET; external `POST /sca/stripe/webhook` → **404** at the edge. Slice 6 adds no Stripe dependency.

---

## Production verification (live tree restored to `main` = `7ff176c`, `--no-dev` re-pruned)

| Check | Result |
|---|---|
| live bind-mounted tree | `7ff176c4b36d0eba805e296d83326f6d0f998fc1` (baseline) |
| prod DB | `sca_krayin`, migrations **129** |
| `sca_authentication_returns` in prod | **NO** (candidate table not applied to prod) |
| provenance DATA | items 3 / certs 4 / auth 4 / ownership 5 / claims 2 / grants 1 / sale 1 — byte-identical to baseline FP `84e6339…` |
| submissions / payments / receipts | 0 / 0 / 0 |
| Stripe | enabled=false, secret UNSET, whsec UNSET |
| `MAIL_MAILER` | log |
| edge `/p/{bogus}` · `/storage/x` · `GET&POST /sca/stripe/webhook` | 404 · 404 · 404 / 404 |
| edge `/collector` · `/admin/login` | 302 · 403 (staff-IP gate) |
| co-tenant smsrocket.io | 302 (healthy) |

**Outcome:** one substantial Slice-6 candidate on `feat/sca-external-paid-auth-slice6` (head `5ee1067`), full regression green, production untouched, Stripe DORMANT. **STOP for ChatGPT audit — not merged, not deployed.**

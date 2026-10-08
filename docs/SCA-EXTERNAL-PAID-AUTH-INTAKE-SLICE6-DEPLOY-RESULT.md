# SCA External Paid Authentication Intake — Slice 6 (Exceptions & Returns) — merge + governed deploy result

**Date:** 2026-10-08 · **Status: ✅ DONE — merged `--no-ff` + deployed (migration 129→130). Post-deployment verification PASS. Stripe remains DORMANT. No credentials entered; no runtime launched; no real/test payment; no production return/customer data created.** Authorized after ChatGPT Slice-6 candidate PASS of head `5ee1067217a8c2fd8bea96bf3a7062db33856438` (base `7ff176c4b36d0eba805e296d83326f6d0f998fc1`, gov candidate `bed328d`).

## SHAs
- **Approved candidate:** `5ee1067217a8c2fd8bea96bf3a7062db33856438`
- **Base / deployed-from:** `7ff176c4b36d0eba805e296d83326f6d0f998fc1`
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `f461c17b7e0cbd5a5e5f026d5f5000870ef04752`**

## 1. Merge gate — all PASS
candidate head unchanged (`5ee1067`); `origin/main` == audited base `7ff176c`; candidate **1 ahead / 0 behind**; diff = exactly the audited **12-file** Slice-6 scope; **exactly 1 migration** added (`2026_10_11_000001_create_sca_authentication_returns`); no unrelated changes. Merged `--no-ff` (MERGE_SHA `f461c17`). **Merged tree is file-identical to candidate `5ee1067`** (`git diff 5ee1067 f461c17 --` → empty).

## 2. Deploy (`scripts/deploy-preview.sh`)
`git reset --hard origin/main` → `f461c17`; SCA gate on `sca_domain_test` **1021 passed / 5306 assertions**; `migrate --force` → `2026_10_11_000001_create_sca_authentication_returns … DONE` (**129 → 130**); memory-capped rebuild + `docker compose up -d` (sca project only; kr-mariadb Healthy); `--no-dev` prune; caches cleared; `GET /admin/login → 200`; `Deployed main @ f461c17`.

**Deploy-gate flake note:** the first deploy attempt aborted at the test gate on the known pre-existing flake `QrReissueTest::rg8` (rebuilt_at off-by-1s timing; unrelated to Slice 6). `set -e` aborts the gate **before** any migrate/rebuild, so production stayed byte-identical at 129 / no returns table. Re-running the deploy cleared the flake (gate 1021 passed) and completed normally — the documented remedy.

## 3. Candidate → deployed tree comparison
`git diff 5ee1067 f461c17 --` → **IDENTICAL** (zero file differences).

## 4. Migration 129 → 130 + table/constraint/trigger verification (prod `sca_krayin`)
| Element | Result |
|---|---|
| prod migrations | **130** (`create_sca_authentication_returns` ran) |
| `sca_authentication_returns` table | exists |
| FK `submission_id` → `sca_authentication_submissions` | present |
| FK `eyewear_item_id` → `sca_eyewear_items` | present |
| `UNIQUE(submission_id)` (`uniq_return_submission`) | present |
| `UNIQUE(eyewear_item_id)` (`uniq_return_item`) | present |
| status CHECK `chk_return_status` | `status in ('return_pending','return_in_transit','returned')` |
| trigger `trg_sca_auth_returns_bu` | BEFORE UPDATE present |
| **operational return rows** | **0** |

No production return records were manufactured; mutation behaviour is proven by the disposable-DB suite.

## 5. Tests
- Focused `SubmissionReturnTest` **36 / 79** (eligibility e1–e7, state machine s1–s4, idempotency/concurrency i1–i3, DB immutability + advance-only d1–d4, zero-provenance + status isolation p1–p3, claim independence c1–c2, adverse survival a1×5, staff ACL/HTTP h1–h3, collector UX k1–k5).
- Existing Slice 1–5 + grant/claim + authentication/certification + payment + payment-concurrency guard + Stripe R1 suites: green within the regression.
- **Full governed SCA regression: 1021 passed / 5306 assertions**, exit 0 (985 prior + 36 new).

## 6. Production invariants — pre/post (byte-identical) — all PASS
| Check | PRE (129) | POST (130) |
|---|---|---|
| deployed HEAD == merge SHA | — | `f461c17` |
| provenance DATA fingerprint | `35e063282e004eaabcc9240360ecc0e3` | `35e063282e004eaabcc9240360ecc0e3` (byte-identical) |
| items/qr/certs/auth/ownership/claims/grants/sale/status | 3/3/4/4/5/2/1/1/7 | 3/3/4/4/5/2/1/1/7 |
| submissions / payments / receipts | 0 / 0 / 0 | 0 / 0 / 0 |
| return records | (table absent) | **0** |

The return deployment created ZERO new eyewear items, authentications, certifications, QR identities, ownership events, claims, external claim grants, Shopify sale links, submissions, payments, webhook receipts, or return records. Existing provenance/data is byte-identical (only the migration metadata advanced 129→130).

## 7. Stripe DORMANT — verified post-deploy
`config('sca-stripe.enabled') === false`; `STRIPE_SECRET` **UNSET**; `STRIPE_WEBHOOK_SECRET` **UNSET**; external `GET`+`POST /sca/stripe/webhook` → **404**; no Checkout session; no Stripe CLI; `:8099` not launched; no real/test payment.

## 8. Smoke / security — all PASS
| Check | Result |
|---|---|
| `/p/{bogus}` | 404 (constant-shape) |
| `/storage/x` | 404 (denied) |
| `/collector`, `/collector/submissions` | 302 (login redirect) |
| `/admin/login` | 403 (edge staff-IP gate) |
| staff return routes `return/{prepare,ship,complete}` | registered, gated by `sca.eyewear.submission.return` |
| collector return mutation route | **none** (only the GET Stripe `pay/return` redirect exists) |
| bearer claim flow (`admin.sca.eyewear.claimlink`) | present |
| submission-bound claim (`collector.submission.claim`) | present |
| unsigned Shopify webhook | **401** (rejects) |
| external `:8080` | **000** (loopback-only) |
| `MAIL_MAILER` | log |
| Caddy / DNS | unchanged |
| co-tenant smsrocket.io | 302 (healthy) |

**Outcome: DONE (merged `--no-ff` + deployed, `f461c17`); deployed tree file-identical to the audited candidate; prod migrations 129→130 (one additive operational table, 0 rows); provenance DATA byte-identical; Stripe DORMANT at both the edge (404) and the app (fail-closed without secret).** The External Paid Authentication Intake product slices (1–6) are now code-complete; remaining work (provider testing/activation, final launch validation) is tracked separately. **STOP for ChatGPT deployment audit.**

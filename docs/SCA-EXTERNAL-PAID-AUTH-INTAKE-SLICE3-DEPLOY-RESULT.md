# SCA External Paid Authentication Intake — Slice 3 (Collector Submission UX + Status Tracking) — merge + governed deploy result

**Date:** 2026-10-07 · **Status: ✅ DONE — merged `--no-ff` + deployed. NO migration (prod stays 125). Post-deployment verification PASS. No Shopify/MAIL/DNS/payment/Stripe/shipping/co-tenant change.** Authorized after ChatGPT candidate PASS of head `b43391a73a9ea302b3e5751c584a0709c1a78d3a` (gov evidence `c71d073c4cd18c18ce5454ffa2988e3e4acf747f`).

> **Slice 3 only. The overall External Paid Authentication Intake capability is NOT closed** — Slices 4–6 (payment, result/ownership wiring, exceptions/returns) remain. **Slice 4 not started; no payment provider chosen/configured.**

## SHAs
- **Base / deployed-from:** `c72530e59af0eb20bfc24df0d97e6dc0feadc990`
- **Audited candidate head:** `b43391a73a9ea302b3e5751c584a0709c1a78d3a` (unchanged at merge)
- **MERGE_SHA = ORIGIN_MAIN = DEPLOYED_HEAD = `1cf070db8e623a947c0b7c30c79b67299d2508fd`**

## Pre-merge gates (fail-closed) — all PASS
candidate head `b43391a7` unchanged; `origin/main` == merge-base == `c72530e5`; tree clean. Merge diff = the Slice-3 collector controller/request/views + service methods + staff advance; **0 migrations**.

## Migrations before/after
**Before: 125 · After: 125** — **no schema migration** (Slice 3 is UX + service methods over existing tables).

## Deploy (`scripts/deploy-preview.sh`)
`git reset --hard origin/main` → `1cf070d`; SCA gate on `sca_domain_test` **938 passed / 5008 assertions**; `migrate --force` → nothing to migrate (125); memory-capped rebuild + `docker compose up -d` (sca project only); `--no-dev` prune; caches cleared; `kr-app`/`kr-mariadb` healthy; `GET /admin/login → 200`; `Deployed main @ 1cf070d`. (No deploy-gate QR flake this run.)

## Post-deployment verification — all PASS
| Check | Result |
|---|---|
| deployed HEAD == merge SHA | `1cf070db8e623a947c0b7c30c79b67299d2508fd` |
| regression (deploy gate) | **938 passed / 5008 assertions** (925 Slice-2 baseline + 13) |
| migration count | **125** (no change) |
| all `collector.submission.*` routes registered | index/create/store/show/edit/update/review/submit all **OK** |
| routes behind `collector.auth` | all collector submission routes → middleware `web, collector.auth` (+ throttles) |
| create/update/submit throttles | store `throttle:10,1`, update `throttle:20,1`, submit `throttle:10,1` — present as approved |
| account navigation link | "Submit eyewear for authentication →" present on the collector account page |
| collector views/controllers/services present | `Sca\Collector\...\SubmissionController`, `SubmitFrameRequest`, `submissions/{index,form,review,show,not_found}.blade.php`, `SubmissionService` collector methods — all deployed |
| staff advance route/action present | `admin.sca.submission.advance` **OK** |
| staff advance gated by `sca.eyewear.submission.accept` | middleware `… sca.can:sca.eyewear.submission.accept` (no new ACL key) |
| no new public unauthenticated submission route | none — every collector submission route is behind `collector.auth` |
| no payment/Stripe route or semantics | route scan for stripe/payment/checkout = **0** |
| no upload/media infrastructure introduced | route scan for submission photo/image/upload/media = **0**; no `sca_media_assets` change |
| submission tables empty in prod | `sca_authentication_submissions` **0 rows**, `sca_submission_status_events` **0 rows** — no production submission manufactured |
| provenance DATA unchanged | items 3 / qr 3 / certs 4 / auth 4 / ownership 5 / status 7 / gallery 3 |
| MAIL_MAILER | **`log`**; `SHOPIFY_API_SECRET`/`POSTMARK_TOKEN` UNSET |
| `/collector/submissions` (guest) | **302 → login** (route live + guarded) |
| `/p/{bogus}` · `/collector` · `/collector/forgot-password` | **404 · 302 · 200** |
| `/storage/..` · unsigned webhook · `:8080` ext | **404 · 401 · 000** |
| smsrocket co-tenant | **302** |

## Provenance fingerprint verification (no migration → MUST NOT move)
Because Slice 3 has **no migration**, the composite provenance fingerprint (which folds migration count `"m"`) must be **byte-identical** before and after — any movement would be a deployment failure.
- **Pre-merge composite FP (m=125):** `6c926d30e3abf4b4e4decbd3ff6acd9e`
- **Post-deploy composite FP (m=125):** `6c926d30e3abf4b4e4decbd3ff6acd9e`
- **IDENTICAL — zero movement.** No migration-count change, no provenance-data change. (Distinct from Slices 1/2 where an additive migration legitimately moved the composite.)

## Security / regression verification (deploy gate, `sca_domain_test`)
Proven green in the gate: collector A cannot read/edit/review/submit collector B's submission (`u9`, safe 404); protected fields non-injectable on create & update (`u5`); submitted submissions collector read-only (`u7`); collector lifecycle creates zero provenance (`u13`); staff pilot advance creates zero provenance (`u13`); Slice-2 custody behavior intact (`SubmissionStaffWorklistTest` w1–w10 all green within the 938).

## Boundary confirmation
No Shopify/MAIL/DNS/payment/Stripe/SMTP/SMS/shipping/co-tenant change; no migration; no new public route; no payment route/semantics; no upload/media infrastructure. The staff pilot gate (`submitted → awaiting_item`) carries no payment semantics. No real production submission or permanent item created — verification used route/guard/ACL/runtime inspection + the green disposable suite + a byte-identical FP.

**Outcome: DONE (merged `--no-ff` + deployed, `1cf070d`); provenance FP byte-identical (no movement, as required for a no-migration slice); prod migrations remain 125; submission tables empty.** External Paid Authentication Intake **Slice 3 is deployed; the overall capability remains OPEN (Slices 4–6 pending).** See `docs/SCA-EXTERNAL-PAID-AUTH-INTAKE-SLICE3-IMPLEMENTATION.md`, `docs/SCA-EXTERNAL-PAID-AUTHENTICATION-INTAKE-DISCOVERY.md`.

# SCA-OPTC — Release-Readiness Audit (READ-ONLY)

**VERDICT: NO-GO for production deploy now. The candidate CODE is accepted/ready (no Option-C-attributable regression; focused 68/0; full-suite failures all pre-existing env/fragility). NO-GO is on release-dependency/operational gates, not Option C code.** Read-only: no code/merge/deploy/migration/test/restart/activation. Candidate `1df81d5` (`feat/sca-optc-secure-claim`), baseline `6022b75`. 2026-10-22.

---

## 1. CollectorHandleTest::h7 — verified; narrow correction proposed (NOT applied)

**Verified.** `CollectorHandleTest.php:285` loops `foreach ([$ref, $c->email, $c->public_ref, (string)$item['id'], (string)$c->id, 'catalog/'] as $secret) assertStringNotContainsString($secret, $body)`. The two **bare numeric DB ids** (`$item['id']`, `$c->id`) are the fragile elements: the full-run failure was `Not to contain: 220`, and `220` legitimately appears in the dev-preview CSS `max-width:220px`. It also fails in isolation on id `1`. The genuinely sensitive tokens in the loop — the opaque PUB ref (`$ref`), `email`, the COL `public_ref`, and the `catalog/` path — are not the problem. Option C touches no collector-handle/public-profile code; its added test rows merely shift the autoincrement id. **Pre-existing test fragility, not a leak.**

**Proposed narrow correction (do NOT modify yet):** keep the real-exposure assertions (`$ref`, `email`, `public_ref`, `'catalog/'`, asset-URL shape) and replace the two bare-numeric-id substring checks with a **contextual** check that the internal id is not emitted as an identifier — e.g., assert the id does not appear as a URL path segment or structured field (`assertDoesNotMatchRegularExpression('#/(items|collectors?)/'.$id.'\b#', $body)` and not inside `"id":`/`COL-…`), rather than as a bare substring. Net: it then detects actual sensitive-data exposure and is immune to accidental numeric coincidences. **The same correction applies to `CertificateDocumentClassificationTest::d9`** (see §2), which has the identical bare-PK pattern.

## 2. The 7 shared full-suite failures — environment vs defect

| Test | Symptom (evidence) | Class | Minimal isolated-harness correction |
|---|---|---|---|
| `AuthenticationTest::dashboard` | `actingAs(): $user … null given` — `getDefaultAdmin()` returns null (AuthenticationTest.php:11) | ENVIRONMENT (no admin seeded in the fresh disposable DB) | Seed the Krayin default admin (installer/`DatabaseSeeder` admin step or factory) in the disposable DB before the suite |
| `AuthenticationTest::logout` | same null-admin TypeError | ENVIRONMENT | same |
| `HelpTest` | same null-admin TypeError (HelpTest.php:6) | ENVIRONMENT | same |
| `AuthenticationHardeningTest::rate limits failed logins` | expected 429, got 200 | ENVIRONMENT (login throttle/cache not counting under the array cache harness) | Give the harness a cache store the throttle counts against (and confirm throttle middleware active in testing) |
| `AuthenticationHardeningTest::rate limits forgot-password` | expected 429, got 200 | ENVIRONMENT | same |
| `TransactionalEmailHardeningTest::h8` | URL is `http://localhost/...` vs canonical `https://verify.secondchanceauthenticators.com/...` | ENVIRONMENT (`APP_URL` not set to the prod canonical) | Set `APP_URL=https://verify.secondchanceauthenticators.com` in the harness env |
| `CertificateDocumentClassificationTest::d9` | `Not to contain: 10` — bare cert PK `$cid`/`$media->id` (CertificateDocumentClassificationTest.php:207) | TEST FRAGILITY (bare-numeric-PK substring, same root as h7) | Apply the §1 narrow-assertion correction (contextual id check) |

**None is a real application defect.** 6/7 are isolated-harness configuration gaps (admin seed, cache/throttle, `APP_URL`); 1/7 (`d9`) is the same pre-existing numeric-substring test fragility as `h7`. With the four harness/test corrections above, the full suite should reach an unambiguous PASS on the candidate — these corrections are the prerequisite for a **reliable regression verdict**.

## 3. Option C migration vs the 139/140 production mismatch

**Safe to introduce (up) without altering historical records.** Facts (read-only, live `sca_krayin.migrations`): batch 26 = `2026_10_19…market_reference_events`; batch 27 = `2026_10_20…add_reason_to_sca_qr_lifecycle_events` (the "139") + `2026_10_21…add_collector_activity_last_seen` (the "140", the incident). The Option C branch's Provenance migrations end at `2026_10_20…` then `2026_10_23_000001_add_fulfillment_release_to_sca_eyewear_items` (it does **not** carry the `2026_10_21`/"140" file — that is Phase-2-only).

- Laravel keys migrations by **filename** and records each as a row. On an Option C deploy, `php artisan migrate` runs only files **absent from the table** → it runs `2026_10_23_000001` as a **new batch (28)**, appended, leaving the `2026_10_20`/`2026_10_21` (139/140) rows **untouched**. A recorded migration whose file is absent (the orphaned 140 on this branch) is simply **ignored by `migrate` (up)** — no error, no renumber.
- **Rollback of Option C** needs only `2026_10_23_000001::down()` (present) → drops the two nullable columns; it does **not** reach batch 27, so 139/140 are not involved. CLEAN.
- **Caveat (not a blocker for Option C):** the pre-existing 139/140 incident (140 recorded in prod but its file absent on `main`/this branch) remains a **separate, owner-pending** reconciliation. A `migrate:rollback` across batch 27 would fail on the missing 140 `down()` — but Option C deploy is `migrate` (up) only and never triggers that. **Option C deploy must not be bundled with any batch-27 rollback.**

## 4. Final candidate diff contents (vs `6022b75`)

**Only approved Option C functionality + test-safety changes.** Diff touches exclusively `app/packages/Sca/*`, `app/tests/*`, and `scripts/*` — **nothing outside** (no non-Sca package, no `app/config/`, no `app/bootstrap/`, no `composer.json`/`lock`, no `phpunit.xml`). Production code = exactly the 15 Option C files (ClaimWorkflow, ClaimService, ExternalClaimGrantService, FulfillmentReleaseService/Controller/Request/Rejection, migration `2026_10_23_000001`, acl.php, ExternalClaimLinkController, EyewearItemController, admin-routes, 2 views). The 100 changed test files + `scripts/` are the test-safety work (guard conversion to `guardDisposableDb()`, concurrency/worker per-run parameterization, `perRunDbName()`, `per_run_db_guard.php`, the runner + XML validator). ZERO dependency change; one additive nullable migration.

## 5. Production release dependency checklist

| Item | Status | Evidence / action |
|---|---|---|
| Migration reconciliation | **PASS** (Option C) | `2026_10_23_000001` additive/nullable, deploys as a new batch via `migrate` up; 139/140 untouched (§3). The 139/140 incident itself is a separate owner-pending decision — do not bundle with a rollback. |
| Backup / restore readiness | **BLOCKED** | Off-host DR is a residual blocker ([[sca-backup-dr-remediation]]): nightly `.gpg` only on the single VPS, `SCA_BACKUP_REMOTE` unset. Minimum before any prod migration: a verified on-host DB backup + restore test; preferably clear the off-host gate. |
| Rollout order | **PASS (documented)** | Deploy app code + migration **together** — the grant gate reads `fulfillment_released_at`, so the column must exist first. |
| Rollback strategy | **PASS** | Code rollback to the current deployed app; `2026_10_23_000001::down()` drops the 2 nullable columns (no data transform, no 139/140 impact). |
| Permission setup | **DEFERRED (operational)** | New ACL node `sca.eyewear.fulfillment.release` (config, migration-free) must be granted to the intended staff role(s) in prod after deploy. |
| Private claim-card delivery | **DEFERRED (operational; no SMTP)** | MAIL is `log`; Postmark not activated ([[sca-postmark-activation-preflight]]). The grant flow is designed for out-of-band delivery — staff copy the opaque claim URL and hand it to the buyer — so it works without SMTP, but there is no automated email. Define the delivery process. |
| Live QR-to-claim acceptance test | **DEFERRED** | End-to-end on prod/staging (scan QR → read-only passport → release → private grant claim) requires a real frame + printed QR label (pilot-ops gap); cannot be done in this read-only audit. |
| Reliable full-suite regression verdict | **BLOCKED (verdict gate)** | Requires the four §2 harness/test corrections to turn the full suite green unambiguously; until then the verdict rests on the candidate-vs-baseline differential (no Option-C regression). |

## 6. Classification summary (PASS / BLOCKED / DEFERRED)

- **PASS:** Option C code + behavior (focused 68/333/0; no Option-C-attributable regression; candidate fixes 5 baseline concurrency failures); diff scope (Option C + test-safety only, §4); Option C migration up-safety (§3); rollout order; rollback strategy.
- **BLOCKED:** backup/off-host-DR readiness (§5); reliable full-suite PASS verdict pending the four harness/test corrections (§2).
- **DEFERRED:** permission grant for the new ACL; private claim-card delivery process (no SMTP); live QR-to-claim acceptance test; the §1 `h7`/`d9` assertion hardening; the separate 139/140 owner decision.

**GO/NO-GO: NO-GO for production deploy now.** The candidate is code-complete and test-verified with no Option-C regression; release is gated on the BLOCKED items (backup/DR readiness; a clean full-suite verdict via the harness corrections) and the DEFERRED operational items (permission grant, claim-card delivery, live acceptance test). Recommended next steps (each separately authorized): apply the four isolated-harness/test corrections → re-run for a clean verdict; clear backup/off-host-DR; stage the deploy (app+migration) behind permission setup + a claim-card delivery process + a live acceptance test.

**STOP — read-only assessment delivered for owner + ChatGPT review. No code/merge/deploy/migration/test/restart/activation.**

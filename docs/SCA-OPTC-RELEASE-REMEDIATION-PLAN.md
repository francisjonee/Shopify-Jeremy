# SCA-OPTC — Release-Readiness Remediation PLAN (non-production)

**Status: PLAN ONLY. Nothing implemented, no tests run, no merge/deploy/migration/restart/activation.** Production NO-GO confirmed; Option C application logic accepted at candidate level (`1df81d5`). All items below are test-harness / test-assertion / operational-readiness work — **no Option C application logic changes**. 2026-10-22.

Everything is authorized separately before execution. The test/assertion corrections (§1–§2) land on the candidate branch as **test-only commits** (clearly separate from the Option C app diff); §4–§6 are process/ops.

---

## 1. Narrow assertion corrections — `h7` and `d9` (test-only)

**Principle:** keep every genuine sensitive-data check; replace ONLY the fragile bare-numeric-ID substring comparisons with a context-bounded check, so a real leak (an internal id emitted as an identifier) still fails while an accidental numeric coincidence (e.g., `220` in `max-width:220px`) does not.

**File boundary A — `app/tests/Feature/Sca/CollectorHandleTest.php` (~line 285).**
- Keep unchanged: `assertStringNotContainsString` for `$ref` (opaque PUB ref), `$c->email`, `$c->public_ref` (COL ref), `'catalog/'`, and the asset-URL-shape assertions.
- Change ONLY the two bare numeric ids (`(string)$item['id']`, `(string)$c->id`): from a bare substring check to a context-bounded regex that fails only when the id is emitted as an identifier, e.g.
  `$this->assertDoesNotMatchRegularExpression('#[/"\'=:>]\s*'.preg_quote((string)$id, '#').'(?![0-9A-Za-z])#', $body, 'leak: id '.$id);`
  (id preceded by a structural delimiter `/ " ' = : >` and not followed by an alphanumeric — catches `/220`, `"220"`, `:220,`, `>220<`; ignores `220px`).

**File boundary B — `app/tests/Feature/Sca/CertificateDocumentClassificationTest.php` (~line 207).**
- Keep unchanged: `assertDontSee('"subject_id"')`, `assertDontSee($media->storage_path)`, `assertDontSee($media->checksum_sha256)`.
- Change ONLY the two bare PKs (`$media->id`, `$cid`): replace `assertDontSee((string)$pk)` with the same context-bounded `assertDoesNotMatchRegularExpression(...)` form.

**Acceptance criteria (§1):**
- The corrected assertions STILL FAIL if the id appears as a URL path segment (`/items/<id>`), a JSON field (`"id":<id>`), or an HTML attribute (`data-id="<id>"`, `id="<id>"`). (Add a tiny positive control in-review: a crafted body containing `/<id>/` must fail.)
- They PASS against an accidental numeric coincidence (`<id>px`, a year, a count).
- All opaque-ref / email / public_ref / path / checksum / `subject_id` checks are unchanged and still enforced.
- No application/view code changed; no information actually exposed by the views changes.

## 2. Isolated-harness corrections (harness-only; do NOT weaken auth/rate-limiting)

These make the harness representative of production so the suite yields a reliable verdict. **Preferred boundary: the runner `scripts/run-optc-tests.sh` (container env + an idempotent post-migrate seed)** so `phpunit.xml` stays untouched (keeps the XML-override validator clean and avoids changing dev runs). None weakens a security control.

- **(a) Seed the required test admin.** Root cause: `getDefaultAdmin()` = `User::find(1)`; the fresh disposable DB has no users → `null` → `actingAs(null)` TypeError (`AuthenticationTest`×2, `HelpTest`). Fix: after `php artisan migrate`, seed the **canonical Krayin default admin** (user id 1 + its role) idempotently in the disposable DB — either the installer's admin seeder or a minimal fixed insert mirroring it. This is the SAME admin an installed app has; it does not alter auth logic. Boundary: runner in-container migrate phase (or a test bootstrap helper). **Do not** bypass or stub authentication.
- **(b) Test-only throttle/cache store.** Root cause: the login / forgot-password throttle counts via the cache; under `CACHE_STORE=array` the limiter does not accumulate across the requests in these tests (429 never reached → 200). Fix: give the harness a cache store that persists across requests within a run (e.g., `file`), and confirm the throttle middleware is active in `testing` and the limiter key is stable. Boundary: runner container env (`-e CACHE_STORE=file` + a writable cache dir) — NOT a change to the limiter, its thresholds, or the middleware. **Do not** disable, loosen, or mock the throttle.
- **(c) Canonical `APP_URL`.** Root cause: `TransactionalEmailHardeningTest::h8` asserts the reset URL starts with `https://verify.secondchanceauthenticators.com` but the ambient `app.url` in the harness is `http://localhost`. Fix: set `APP_URL=https://verify.secondchanceauthenticators.com` in the runner container env (matches production). Boundary: runner `-e APP_URL=…`. No app code changed.
- **(d) Preserve disposable-DB isolation.** All of the above are env/seed only. The create-not-drop ownership, `verify_effective` host+schema check, the XML-aware override validator, the per-run unique DB naming, and `perRunDbName`/`sca_is_per_run_db` remain untouched.

**Acceptance criteria (§2):**
- `AuthenticationTest`×2 + `HelpTest` pass with a real seeded admin (id 1 present); no auth control bypassed.
- Both `AuthenticationHardeningTest` rate-limit tests observe a real `429` at the configured threshold, AND `it never throttles repeated successful logins` STILL passes (limiter behavior unchanged, just observable).
- `TransactionalEmailHardeningTest::h8` passes with the canonical `APP_URL`.
- `selftest` still 56/0; effective-connection + XML-override checks unchanged; adding `APP_URL`/`CACHE_STORE` does not trip the DB-override validator (it flags only `DB_*`/`DATABASE_URL`).

## 3. Targeted + full-regression verification sequence (to run only when separately authorized)

Order, each via the existing isolated runner on a per-run unique disposable DB:
1. `scripts/run-optc-tests.sh selftest` — non-destructive; expect **56/0**.
2. `scripts/run-optc-tests.sh focused` — the 5 Option-C files; expect **68/333/0** (regression-proof of Option C behavior after the §1 CollectorHandleTest change, which is in the focused set).
3. `scripts/run-optc-tests.sh full` — full suite on a unique DB; **expected after §1+§2:** the 6 environment failures resolved (admin seed, throttle, APP_URL) and `h7`/`d9` resolved by the §1 assertion fix → **0 failures**. Any residual failure is enumerated and investigated before any PASS claim.
4. **Clean baseline re-diff:** `6022b75` in the same harness on an INDEPENDENT disposable DB; confirm the candidate failing-set is a subset of baseline's and that no candidate-only failure remains once `h7`/`d9` are fixed.

**Distinguish:** tests that pass are recorded as PASS; any remaining failure is tagged "requires investigation" with the exact message/line and is NOT dismissed. Full-suite PASS is declared only when failures are 0 OR each residual is proven environmental and non-Option-C with evidence.

## 4. Migration rollback assessment (revised) — do NOT alter history or touch 139/140

- **Why a generic `migrate:rollback` is unsafe here.** `migrate:rollback` is **batch-scoped**, not migration-scoped. After Option C deploys as batch 28, a bare `migrate:rollback` reverts batch 28 (Option C only) — acceptable — but `migrate:rollback --step=2` (or a second invocation) reaches **batch 27 = the 139/140 incident**, whose `2026_10_21…` ("140") `down()` file is **absent** from `main`/the Option C branch → the rollback **errors** (missing class) and, if it proceeded, would drop unrelated incident columns. A generic rollback is therefore brittle and must never be used as the Option C revert.
- **Preserve fulfillment-release audit data.** `fulfillment_released_at` / `fulfillment_released_by` are an append-once staff **attestation** (audit evidence). The Option C migration `down()` DROPS these columns → it would **destroy that audit history**. A blind rollback is lossy.
- **Forward recovery (preferred).** To neutralize Option C in production without data loss, prefer a **code-only rollback** (revert the app to the prior deployed code so the columns become unused/inert) and **leave the additive columns in place** — the audit data is preserved and the columns are harmless (nullable, unread by the reverted code). No DB rollback needed.
- **Separately-authorized targeted rollback (only if columns must be removed).** A single, explicit, reviewed migration that drops ONLY `fulfillment_released_at`/`by` (not a batch rollback), executed **after** exporting/preserving the attestation rows, and scoped so it **never** touches batch 27 (139/140). Owner-authorized and backed by a verified backup (§5).
- **Untouched:** migration history and the 139/140 incident remain as-is; their reconciliation is a separate, owner-pending decision.

## 5. Backup / restore readiness checklist (separate from Option C)

Cross-ref `[[sca-backup-dr-remediation]]` (off-host DR is the residual blocker; `SCA_BACKUP_REMOTE` unset).
- [ ] Take a fresh **pre-deploy** backup of `sca_krayin` (DB dump + the document/evidence store) and record checksums + row counts.
- [ ] **Verify** it: restore into a throwaway disposable DB and run the backup verification (`verify_db_document_refs` / grammar + extraction checks) — capture the restore evidence.
- [ ] **Off-host copy:** push the encrypted backup to the off-host destination (recommended: Hetzner Storage Box via rclone-sftp) with the GPG key + `APP_KEY` escrowed **separately** from the backup host.
- [ ] **Restoration evidence:** demonstrate a restore FROM the off-host copy to a disposable DB (not prod), with matching checksums/row counts.
- [ ] Gate: no production migration until a verified, off-host, restore-tested backup exists.

## 6. Distinct operational gates (kept separate; not part of §1–§5)

- **ACL permission setup** — grant `sca.eyewear.fulfillment.release` to the intended staff role(s) in production (config/role assignment; migration-free).
- **Private claim-card delivery** — define the out-of-band process (MAIL is `log`; Postmark not activated, `[[sca-postmark-activation-preflight]]`): staff copy the opaque grant URL and deliver it to the buyer. No SMTP dependency introduced.
- **Live QR-to-claim acceptance testing** — end-to-end on staging/prod with a real frame + printed QR label (scan → read-only passport → staff release → private grant claim), owner-scheduled (pilot-ops).

---

## GO/NO-GO checklist (all must be GO before a production deploy is proposed)

| # | Gate | Current | GO condition |
|---|---|---|---|
| G1 | Option C code accepted (no regression) | **PASS** | focused 68/0; no Option-C-attributable full-suite failure (already evidenced) |
| G2 | Reliable full-suite verdict | **NO-GO** | after §1+§2, full suite 0 failures (or every residual proven env/non-Option-C) + baseline re-diff clean (§3) |
| G3 | `h7`/`d9` assertion hardening | **NO-GO** | §1 applied + acceptance criteria met (real leak still caught) |
| G4 | Backup/restore + off-host DR | **NO-GO (BLOCKED)** | §5 checklist complete with restore evidence |
| G5 | Migration deploy/rollback plan | **PASS (plan)** | deploy app+migration together (up only, new batch); rollback = code-only/forward-recovery; targeted column drop only if separately authorized + backed up (§4) |
| G6 | ACL permission setup | **DEFERRED** | `sca.eyewear.fulfillment.release` granted to the right role(s) in prod |
| G7 | Private claim-card delivery | **DEFERRED** | out-of-band delivery process defined (no SMTP) |
| G8 | Live QR-to-claim acceptance | **DEFERRED** | end-to-end acceptance passed on staging/prod with a real label |
| G9 | 139/140 incident | **DEFERRED (owner)** | owner decision recorded; Option C deploy not bundled with any batch-27 rollback |

**Overall: NO-GO until G2–G4 clear and G6–G8 are satisfied operationally.** No application-logic change is required for any of the above — Option C code stays as accepted at `1df81d5`.

**STOP — remediation plan delivered for owner + ChatGPT review. No implementation, tests, merge, deploy, migration, restart, or activation.**

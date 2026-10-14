# SCA Production Release Readiness Assessment (read-only)

**Type:** Read-only planning assessment. No deployment, migration, production mutation, service restart, infrastructure change, backup/restore, or pilot performed. Prepared for ChatGPT independent audit before any production decision.
**Currently deployed application:** `3b30a0f24323463c42dda58b476a453f58e49389`, migration **138** (running `kr-app` container; verified via loopback `/admin/login` 200 + `migrate:status`).
**Target `main`:** `73b6c22ff0b8397e2d6c7c06ea9cc325d7693732`, migration **139** after deploy.
**Canonical public edge:** `https://verify.secondchanceauthenticators.com` → `kr-app` loopback `127.0.0.1:8080` (shared host; live co-tenant `smsrocket` owns 80/443; no swap).

> **VERDICT: NO-GO as of this assessment — one BLOCKER.** The code/migration delta is low-risk and test-green, but **the encrypted backup job has FAILED every night since 2026-10-08** (newest usable backup is 6 days stale) due to `/tmp` (a 2.9 GB RAM-backed tmpfs on a swapless host) exhausting during the document-archive step, and **off-site replication is not configured**. A production migration must not run without a fresh, verified, off-host recoverable backup. Remediate the backup first; the release itself is otherwise ready.

---

## 1. Deployed → target difference (complete)

Commits `3b30a0f..73b6c22` (10): the Pilot-Readiness docs merge (docs-only), the rg8 test-reliability merge (test-only, no app code), and three code initiatives — QR Reissue Reason, Authentication & Certification Safeguards, Staff & Collector UX Hardening Phase 1.

**Runtime/app + schema delta (`git diff 3b30a0f..73b6c22 -- app/packages`): 20 files, +373/−40**, comprising:
- **Exactly one migration: `2026_10_20_000001_add_reason_to_sca_qr_lifecycle_events.php`** (migration count 138 → 139).
- QR: `QrService.php`, `QrReissueController.php` (persist operator reason on the `reissued_from` event).
- Auth/Cert: `AuthenticationController.php`, `CertificationController.php`, new `FinalizeAuthenticationRequest.php` / `IssueCertificationRequest.php`, new `finalize-confirm.blade.php` / `certify-confirm.blade.php`, `authentication/create.blade.php`, `eyewear/show.blade.php`, `admin-routes.php` (typed-confirmation interstitials; no-default result).
- UX Phase 1: `StoreEyewearItemRequest.php`, `InventoryImportController.php`, `eyewear/create.blade.php`, `Registry SubmissionController.php`, `Collector SubmissionController.php`, `collector profile.blade.php`, collector + staff `submissions/show.blade.php` (safe error copy, year message, required brand/model on manual intake, inconclusive-vs-failed copy, claim-eligibility control, honest payment copy).

**Dependencies: NO change.** `app/composer.json` and `app/composer.lock` are byte-identical between `3b30a0f` and `73b6c22` — zero package add/remove/upgrade; the deployed vendor tree needs no new dependency. **No `.env`, Docker, Caddy, or config file changed** in the range (the only non-`app/packages|tests` change is the `docs/` pilot-readiness file). **No ACL/permission, route-removal, or public-route change** beyond the two new admin GET confirm routes.

All three code initiatives were independently pre-merge and post-merge audited (QR-reason, Auth/Cert safeguards) or pre-merge audited (UX Phase 1, currently awaiting post-merge audit) and merged content-identical to their approved candidates. Target-tree full gate reported **1407 passed / 1 skipped / 0 failed (7459 assertions)**.

## 2. Migration 139 analysis
`ALTER TABLE sca_qr_lifecycle_events ADD COLUMN reason VARCHAR(500) NULL` + `CHECK chk_qr_reason_only_on_reissue (reason IS NULL OR event_type='reissued_from')`.
- **Additive & forward-only**: adds one nullable column + one CHECK; rewrites no prior migration, backfills nothing, alters no existing row, relaxes no constraint.
- **Compatibility**: every existing `sca_qr_lifecycle_events` row has `reason = NULL` (the column is new), which satisfies the CHECK — safe to apply online with zero data change. Expected online-DDL cost is a single small-table `ALTER`.
- **Rollback**: `down()` drops the CHECK then the column (clean); any reason values captured post-deploy would be lost on rollback (acceptable for an additive audit column).
- **Status now**: on production it is the **sole Pending migration** (`migrate:status`: 138 ran, `2026_10_20_000001` Pending).

## 3. Backup & restore readiness — **BLOCKER**
A real encrypted backup mechanism exists: `scripts/backup-run.sh` (mariadb-dump `--single-transaction` of `sca_krayin` + private SCA documents → one GPG AES-256 `.tar.gz.gpg` + `.sha256`, flock-serialized, retention, `scripts/backup-verify-restore.sh` restore-proof, `scripts/lib-offsite.sh` off-host publish), scheduled by `/etc/cron.d/sca-backup` daily 03:17 UTC. `backups/` holds 15 encrypted artifacts.

**However (verified from `backups/backup.log` + `ls -1t`):**
- **The newest successful encrypted backup is `sca-backup-20261008T011702Z` — 2026-10-08. Today is 2026-10-14. Every run since has FAILED.** The log shows `2026-10-13` and `2026-10-14` runs ending `FAIL document archive failed` with `gzip: stdout: No space left on device` / `tar: … Broken pipe`.
- **Root cause (verified):** `/tmp` is a **2.9 GB tmpfs (RAM-backed)** on a host with **no swap**; `backup-run.sh` builds its working archive under `/tmp`, and the document-archive step exhausts tmpfs (failed-run temp dirs likely accumulate, compounding it). The root filesystem is **not** full (`/`: 45G/387G used, 343G free) — this is specifically tmpfs/RAM exhaustion, not disk.
- `fail()` aborts the whole run before producing a `.gpg`, so **no usable backup exists for 2026-10-09 → 2026-10-14**.
- **Off-site replication is not configured**: `SCA_OFFSITE_UPLOADER` is unset and no offsite/backup keys are present in `app/.env`, so even the Oct-8 artifacts live **only on this VPS**. A VPS loss today loses all SCA provenance.
- **No restore has been verified against a recent backup in this assessment** (running `backup-verify-restore.sh` would exercise restore but is out of this read-only scope).

**Consequence:** there is no fresh, verified, off-host recoverable backup immediately before the proposed migration. Even though migration 139 is additive and low-risk, a production schema change with a 6-day-stale, host-local, currently-broken backup is an unacceptable recovery posture → **release is NO-GO until this is fixed.**

**Remediation update (2026-10-14, see `docs/SCA-BACKUP-DR-REMEDIATION-RESULT.md`):** the staging bug is fixed (staging moved off the `/tmp` tmpfs to a disk-backed, access-controlled workspace, with cleanup, stale-sweep and a disk-space guardrail — authorized backup-remediation work, on a candidate branch pending review), and a **fresh encrypted backup has been generated and restore-verified in an isolated disposable database**. The **residual blocker is off-host replication**: no approved off-host destination or credentials are provisioned, so the fresh backup is still **VPS-local only**. Release remains **NO-GO** until an owner-approved off-host copy exists.

## 4. Deployment procedure (existing)
`scripts/deploy-preview.sh` (established, used for every prior deploy): fetch + hard-reset to `origin/main`; refuse unless `HEAD == origin/main`; install dev deps; **mandatory full `tests/Feature/Sca` gate on the exact merge tree (set -e aborts BEFORE any prod migrate on failure)**; `chown` storage/cache uid 33; `php artisan migrate --force`; memory-capped image rebuild (`--memory=1500m`); `docker compose up -d` (loopback bind preserved; co-tenant + 80/443 untouched); re-install `--no-dev --optimize-autoloader`; `config:clear` + `route:clear`; health curl. This deploys **only** `origin/main` and is the authorized mechanism. Note the documented deploy-gate behavior: the full suite under load can hit the unrelated QR-decode flakes (rg2/rg8) — `set -e` aborts pre-migrate (production safe), re-run per policy.

## 5. Rollback feasibility
- **Code rollback — pinned immutable revision; do NOT reset shared `origin/main`.** Roll back by redeploying a **specific, immutable prior revision** identified by its full commit SHA and captured as an annotated Git tag (e.g. tag `rollback/pre-release-<date>` → `62c5d8b` (pre-UX-Phase1) or the then-deployed revision, once that revision is confirmed from trustworthy metadata — see below). Deploy that pinned revision by checking it out into the deploy tree under a controlled procedure; the container is rebuilt from that pinned tree. **Never force-push or hard-reset the shared `origin/main` branch backward** — that rewrites history shared by every operator, clone and the forward-deploy mechanism, and can orphan the later commits. Note `deploy-preview.sh` as written is a *forward* mechanism (it hard-resets the local deploy checkout to `origin/main` and refuses unless `HEAD == origin/main`); a rollback to a pinned revision therefore requires either a dedicated rollback path that checks out the pinned SHA/tag **without moving `origin/main`**, or an owner-approved manual controlled checkout — it must not be achieved by moving `origin/main`. Low risk — these are additive/presentation changes.
- **DB — preserve migration 139; never automatically drop audit data.** A code-only rollback **keeps migration 139 applied.** Prior-revision code (138-era) does not reference the `reason` column and simply ignores it, so no DB rollback is required for a code rollback and **none is run by default.** The `reason` column holds QR-lifecycle **audit** data; `139 down()` drops the CHECK + column and would discard any reason values captured post-deploy, so `migrate:rollback` is **never** part of a routine code rollback. Dropping it is a separate, explicitly owner-authorized step reserved for a confirmed DB-level problem (see §11), taken only after the current DB — including any captured reason values — has itself been backed up.
- **Deployed-revision confirmation.** Rollback anchors must be confirmed from trustworthy metadata (e.g. the running container's build commit, or `git rev-parse` in the deploy tree) before being relied on; the currently-deployed revision is inferred (§12), not byte-verified, so it must be confirmed or explicitly labelled unverified before use as a rollback target.
- **Precondition**: a fresh, restore-verified, off-host backup (see §3) must exist before the migrate step so that, in a worst case, the DB can be restored. Backup remediation status (staging fix, fresh verified backup, off-host blocker): see `docs/SCA-BACKUP-DR-REMEDIATION-RESULT.md`.

## 6. Production configuration (verified, non-mutating)
Stripe **dormant** (`STRIPE_ENABLED` unset, `STRIPE_SECRET` absent); `MAIL_MAILER=log` (no outbound email — password-reset/claim/transfer links are out-of-band/log-only); `SHOPIFY_SCOPES=read_orders` (webhook-driven, no scope change); `kr-app` loopback-only behind the existing Caddy edge; provenance FP `d15a5cbdfb8df52ba65628b276533cfe`, canonical counts `3/3/4/4/5/2/1/1/7`. None of these change in this release.

## 7. Regression risk by domain (target tree)
All changes are code/presentation + one additive column; no provenance/ownership/certification/QR/claim/registry **writer or state machine** changed. Full target gate green (1407/1/0). Per domain:
- **Authentication**: finalize now requires a typed `FINALIZE` (server-validated) via a read-only confirm GET; result select no longer defaults to Passed; finalize error copy is mapped (no raw exception). The underlying `AuthenticationService::finalize` (exact-item binding, draft-only, lock, immutability) is unchanged. Risk: LOW; a staff UI step is added. Covered by AuthenticationWorkflowTest + AuthCertSafeguardsTest.
- **Certification**: issue now requires a typed `ISSUE` + `authentication_id` via a read-only confirm GET; `CertificationService::issue` (eligibility, QR mint, snapshot) unchanged. Risk: LOW. Covered by CertificationWorkflowTest + AuthCertSafeguardsTest.
- **QR**: `reissue()` gains an optional `?string $reason` stored on the `reissued_from` event under the existing lock/STALE guard; rotation semantics, one-active invariant, and artifact generation unchanged; reason never surfaces publicly. Risk: LOW (additive). Covered by QrReissueTest/QrArtifactTest.
- **Ownership / claim**: no ownership/claim writer changed. The staff "Make claimable" **control visibility** now mirrors the authoritative `ExternalClaimGrantService` eligibility (defense against a dead-end button); the service remains the sole enforcer (no accidental grant). Risk: LOW. Covered by ExternalIntakeResultClaimTest + StaffCollectorUxPhase1Test.
- **Collector privacy**: the collector profile no longer advertises the edge-blocked `/u/{handle}` as a clickable link (a privacy/trust correction); owner-scoping, opaque refs, publication/handle semantics unchanged; no new field exposed. Risk: LOW. Covered by CollectorHandleTest + CollectorUi3Test.
- **Manual intake**: brand+model now required on the manual-create HTTP request **only**; custody/import/service/legacy paths unaffected. Risk: LOW, scoped. Covered by StaffCollectorUxPhase1Test + EyewearRegistryTest.

## 8. Release checklist
1. **Remediate backup (BLOCKER):** fix the `/tmp` tmpfs exhaustion (point `backup-run.sh` working dir at a root-disk path, or clear stale `/tmp/sca-backup.*` dirs and ensure failed-run cleanup), confirm a clean `backup-run.sh` produces a fresh `.gpg` + `.sha256`, and verify a restore with `backup-verify-restore.sh` into a disposable DB.
2. **Off-host copy:** configure `SCA_OFFSITE_UPLOADER` (rclone/aws) + credentials and confirm the fresh backup is replicated off the VPS (or take an explicit, owner-acknowledged off-host copy by hand).
3. Reconfirm `origin/main == 73b6c22` and the running app == `3b30a0f`; capture PRE provenance FP/counts + `migrate:status` (expect 1 pending = 139).
4. Choose a quiet window; confirm the host has adequate free RAM/tmpfs headroom for the rebuild (`--memory=1500m`) without pressuring the swapless co-tenant.
5. Run `deploy-preview.sh`; require the full SCA gate green on the merge tree before it migrates (re-run on a documented QR flake only).
6. Confirm migration 139 applied once (138→139); POST provenance FP/counts unchanged; health 200.
7. Post-release verification (§10).

## 9. Go / No-Go criteria
**GO only if all hold:** (a) a fresh encrypted backup for today exists, restore-verified, AND replicated off-host; (b) `origin/main == 73b6c22`, deployed app == `3b30a0f`, exactly migration 139 pending; (c) full SCA gate green on the merge tree; (d) owner has approved the window. **NO-GO if** any of: backup stale/failing/unverified or host-local-only (**current state**), gate red for a non-flake reason, main moved, or host RAM/tmpfs pressure risks the co-tenant.

## 10. Post-release verification plan
- Migration count 139, 0 pending; `sca_qr_lifecycle_events` has the `reason` column + `chk_qr_reason_only_on_reissue`.
- Provenance FP `d15a5cbd…` / counts `3/3/4/4/5/2/1/1/7` unchanged (no data mutated by a code+additive-column release).
- Health: `/admin/login` 200; public passport `/p/{token}` resolves for a known certified item and `/p/<malformed>` returns the constant 404; guest `/collector` → login.
- Smoke the changed staff flows on a disposable/known item: finalize + certify now require the typed confirmation; a QR reissue stores a reason; manual intake rejects blank brand/model.
- Confirm Stripe dormant, `MAIL_MAILER=log`, `SHOPIFY_SCOPES=read_orders`, no edge/DNS change; co-tenant `sr-*` healthy.

## 11. Rollback procedure
1. If the gate fails pre-migrate: nothing changed — fix forward, no rollback needed.
2. **Code rollback (post-deploy problem):** redeploy the **pinned immutable prior revision** — its full commit SHA / annotated rollback tag (e.g. `62c5d8b`) — via a controlled checkout of that revision into the deploy tree, then rebuild the container. **Do NOT reset or force-push shared `origin/main` to the prior SHA.** Keep migration 139 applied: the prior code ignores the `reason` column, so **no DB rollback is required** for a code rollback, and none is run by default (it holds audit data).
3. **DB rollback (exceptional, owner-authorized only):** only if a DB-level problem is specifically implicated, and only with explicit owner authorization — first take a fresh backup of the current DB (capturing any `reason`/audit values), then run `php artisan migrate:rollback` (drops the reason column + CHECK). This is **never automatic** and is **never** part of a routine code rollback.
4. **Confirm the deployed revision** after any rollback from trustworthy metadata (running container build commit / `git rev-parse` in the deploy tree); if it cannot be byte-verified, label it explicitly as inferred.
4. Catastrophic DB corruption: restore from the verified encrypted backup via `backup-verify-restore.sh`/`db-restore.sh` (depends on §3 being remediated first — currently NOT available fresh).

## 12. Unverified assumptions & blockers
**BLOCKER:** No fresh/verified/off-host recoverable backup — the encrypted backup has failed nightly since 2026-10-08 (tmpfs exhaustion) and off-site is unconfigured. Must be remediated before any migrate.
**Assumptions to verify at deploy time (not independently confirmed here):**
- Host RAM/tmpfs headroom is sufficient for the memory-capped rebuild without pressuring the swapless co-tenant (the backup failure shows tmpfs is already a pressure point).
- `secrets/backup.key` exists and the backup/restore round-trip actually succeeds once space is restored (restore not exercised in this read-only task).
- The deployed running code is exactly `3b30a0f` (inferred from the documented merge history + unchanged provenance FP + loopback health; not a byte-level container audit).
- No other operator/session will move `origin/main` between this assessment and the deploy.
- The UX Phase 1 post-merge audit (currently pending) returns PASS before release is considered.

**STOP — read-only assessment complete; awaiting ChatGPT independent audit. No deployment, migration, production mutation, service restart, infrastructure change, backup/restore, or pilot was performed, and none is authorized by this task.**

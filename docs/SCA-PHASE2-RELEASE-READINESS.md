# SCA Phase 2 — Production Release Readiness Assessment (READ-ONLY)

**Type:** Read-only release-readiness assessment following the Phase 2 code-audit **PASS** (gov `6b0f5b0`).
No merge, deploy, migration, rollback, live-DB mutation, restart, or live-tree checkout was performed.
Prepared for an **OWNER GO/NO-GO decision** and ChatGPT independent audit.

## 0. Verdict
**NO-GO for production release** — the blockers are **operational**, not code. The Phase 2 code correction
has independently PASSED (candidate `dae60728312fa1238bc733eb671540a444dcd807`). Releasing it is gated on a
fresh, restore-verified, **off-host** backup and explicit owner approval; off-host replication is absent /
owner-deferred, so per the standing rule the release is **NO-GO**. A newly-surfaced nightly-backup failure
(tar race, §4) compounds this.

## 1. What "releasing Phase 2" entails
- **Merge** the candidate chain `6022b75 → 4086ee5 → 7272843 → dae6072` (branch `fix/sca-ux-phase2-correction`)
  into `main`. Delta vs `main` `6022b75`: **28 files, +1106 / −60**, containing exactly **one migration file**
  (`2026_10_21_000001_add_collector_activity_last_seen`, = migration 140). (Audited content; a controlled
  `--no-ff` merge proving candidate↔merge identity would precede any deploy — a SEPARATE authorized task.)
- **Deploy** merged `main` via the established `scripts/deploy-preview.sh` (gate → migrate → rebuild →
  health). Live `kr-app` serves `/opt/sca-platform/app` (bind-mount), so the working tree must be on the
  merged `main` for the deploy.
- **No new provider/infra**: Stripe dormant, MAIL=log, SHOPIFY read_orders, loopback+edge — unchanged.

## 2. Migration 139/140 reconciliation (verified read-only)
- Production `sca_krayin.migrations`: `2026_10_20_000001` (139) and `2026_10_21_000001` (140), **both batch 27**.
- The candidate migration 140 filename and schema **exactly match** what is applied on production:
  `activity_last_seen_at timestamp NULL`, index `idx_oe_collector_effective (collector_account_id, effective_at, id)`,
  index `idx_tr_from_collector (from_collector_id, id)`. Migration 139 (reason col + `chk_qr_reason_only_on_reissue`)
  is already on `main`.
- **Both new columns are still empty** (`reason` 0 non-null of 3 rows; `activity_last_seen_at` 0 of 4 collectors).
- **Reconciliation outcome:** on merge+deploy, `php artisan migrate` finds both migrations **already recorded**
  in the table and **skips** them — **no duplicate execution, no rename, no conflict** — provided the filenames
  are left byte-identical (they are; the candidate never renamed/duplicated them). `migrate:status` on the
  merged tree will then show 139 and 140 as Ran with **0 pending**. **No DB action is required to release.**
- Alternative (optional, owner-authorized only): roll production back to migration 138 first (clean — the
  columns are empty, zero data loss) with the candidate checked out so both `down()` resolve. **Not required.**

## 3. Code posture (audit PASS)
Independent re-audit PASS for `dae6072`: CAP+1 probe fixes the `window_capped` off-by-one (exactly-100 not
capped); 99/100/101 regression tests; `unreadCount()` predicates/timestamps align with the feed; four
ownership-acknowledgement paths secure; migration filenames preserved. Claude-run tests: focused 23,
email-hardening 9×3, full `tests/Feature/Sca` 1430/1/0 (not independently executed on host by ChatGPT).
Regression risk is LOW (additive column + presentation/derive-on-read + additive acknowledgement precondition;
no provenance writer/state-machine change).

## 4. Backup & off-host restore readiness — **BLOCKER**
- **tmpfs staging bug: FIXED and live.** The backup-DR fix (disk-backed `backups/.work`) is merged to `main`
  and in effect (the 2026-10-15 nightly logged `STAGING … disk-backed; 347299MB free`). The former
  `No space left on device` failure mode is gone.
- **NEW nightly failure (reliability gap):** the **2026-10-15 01:17 UTC** automated run **FAILED** with
  `tar: sca/generated: file changed as we read it` → `FAIL document archive failed`. The document corpus
  (`app/storage/app/sca/generated`) was modified **concurrently** while `tar` archived it, and the script
  treats tar's non-zero exit as fatal. This is a **concurrent-modification race**, independent of the tmpfs
  fix, and can recur whenever the live app writes a generated artifact (e.g. a certificate PDF) during the
  multi-minute archive. **Result: no fresh *automated* backup for 2026-10-15.**
- **Most recent GOOD backup:** `sca-backup-20261014T220630Z.tar.gz.gpg` (2026-10-14T22:06Z, restore-verified
  during the backup-DR task). It is **VPS-local only**.
- **Off-host replication: ABSENT** — `SCA_BACKUP_REMOTE`/`SCA_OFFSITE_UPLOADER` unset, no `rclone`/`aws`, no
  credentials. Owner-deferred. A VPS loss today would lose **all** SCA provenance.
- **Readiness:** there is **no fresh, restore-verified, off-host** recovery point, and the automated pipeline
  is not currently producing fresh backups. This is the dominant release blocker.

## 5. Release gates (ALL must hold before deploy)
1. **Off-host, restore-verified, fresh backup** taken immediately before migrate — **UNMET** (off-host absent;
   nightly failing). Requires owner-provisioned destination + credentials, and a green nightly (fix the tar race).
2. **Backup pipeline reliability:** a clean `backup-run.sh` run (resolve the `tar … file changed` race — e.g.
   `--ignore-failed-read`/`--warning=no-file-changed`, snapshot/quiesce, or tolerate tar exit 1 on a
   changed-file warning) producing a fresh `.gpg` + `.sha256`, restore-verified via `backup-verify-restore.sh`
   into a disposable DB — **UNMET** (nightly currently fails).
3. **Code/merge integrity:** controlled `--no-ff` merge of `dae6072` into `main`, candidate↔merge byte-identical,
   exactly the audited files; `origin/main` still `6022b75` at merge time; full SCA gate green on the merge tree.
4. **Migration reconciliation confirmed:** `migrate:status` on the merge tree shows 139/140 already Ran, 0
   pending-new (per §2) — **MET in principle** (verified read-only; confirm again at deploy time).
5. **Owner approval** of a quiet deploy window (brief co-tenant-safe rebuild; swapless host) — pending.

## 6. Deploy / verification / rollback decision tree (for the eventual authorized release)
```
PRE-DEPLOY
  ├─ Off-host + restore-verified fresh backup present?   NO  → STOP (NO-GO)
  │                                                        YES → continue
  ├─ origin/main == 6022b75 and candidate audited == dae6072?  NO → STOP (rebase/re-audit)
  └─ Controlled --no-ff merge; prove candidate↔merge identical; full gate green on merge tree.

DEPLOY (scripts/deploy-preview.sh on merged main)
  ├─ Mandatory full tests/Feature/Sca gate (set -e aborts BEFORE migrate on failure → production safe)
  ├─ php artisan migrate --force  → 139/140 already recorded → SKIPPED; expect 0 newly-applied
  ├─ memory-capped rebuild (--memory≈1500m), loopback bind + co-tenant untouched, health curl
  └─ (if gate fails pre-migrate: nothing changed → fix-forward, no rollback)

POST-DEPLOY VERIFY
  ├─ provenance FP/counts unchanged (counts 3/3/4/4/5/2/1/1/7; FP now 3ae1bb41… reflecting the
  │    already-applied all-NULL reason column — see incident assessment)
  ├─ /admin/login + /collector/login 200; public passport resolves; guest /collector → login
  └─ Phase-2 smoke: activity feed renders "Recent activity" (no false truncation at ≤100), unread exact,
       ownership acknowledgement required on all four claim/transfer POSTs.

ROLLBACK (if a post-deploy problem appears)
  ├─ CODE rollback: redeploy the PINNED prior revision 6022b75 via a controlled checkout — do NOT reset/
  │    force-push shared origin/main. Keep migrations 139/140 applied (prior code ignores the additive
  │    columns); NO DB rollback by default; the reason column is QR audit data — never auto-drop.
  └─ DB-level problem (exceptional, owner-authorized only): back up current DB first, then migrate:rollback.
```

## 7. Residual risks
- **No off-host recovery point** (dominant) and **nightly backup currently failing** (tar race) — §4.
- Production carries the accidentally-applied 139/140 (empty, additive); benign and self-reconciling on
  merge, but `migrate:status` on today's `main` omits 140 until the chain merges (file is candidate-only).
- Swapless host; rebuild must stay memory-capped to protect the live co-tenant (smsrocket).
- ChatGPT has not executed tests or inspected the live host independently; live facts are Claude-reported.
- The live site already serves the bind-mounted working tree (`main 6022b75`), so "deploy" here means
  merging Phase 2 into `main`; there is no separate baked image to diverge from.

## 8. OWNER decision — recommendation
**NO-GO** until: (a) an owner-approved **off-host** destination + credentials exist and a **fresh,
restore-verified, off-host** backup is taken immediately before deploy; (b) the nightly backup **tar race**
is resolved so the pipeline reliably produces fresh backups; (c) the controlled merge + full green gate on
the merge tree are completed under owner-approved window. The **code is release-quality** (independent audit
PASS) — the gate is entirely operational (backup/off-host + owner approval), consistent with the standing
rule to declare NO-GO rather than bypass off-host backup.

**STOP — read-only assessment complete; awaiting ChatGPT independent audit and an OWNER GO/NO-GO decision.
No merge, deploy, migration, rollback, production DB mutation, or restart was performed. Production main
`6022b75` and migrations 139/140 remain untouched.**

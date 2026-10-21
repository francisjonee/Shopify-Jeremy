# SCA Phase 2 — Production Migration Incident: Read-Only Reconciliation

**Type:** READ-ONLY, independent evidence collection. **No** `migrate`/`migrate:rollback`/`migrate:fresh`,
**no** DDL/DML, **no** production data/schema change, **no** service restart, live-checkout switch, deploy,
backup/restore, or Stripe/SMTP/pilot activation. Only `SELECT` / `information_schema` queries were run
against the live database; they modify nothing. Candidate `0ba09faf…` remains UNMERGED/NOT DEPLOYED.

**Reconciliation run:** 2026-10-21T15:32:34Z (UTC), on the production host, against database `sca_krayin`.

## Method & redaction
- Impl-repo facts: `git ls-tree` on implementation `main` (`6022b75`) and candidate commits.
- Production facts: `docker exec -e MYSQL_PWD=<root-pw-from-.env, never printed> kr-mariadb mariadb -uroot
  --batch --table sca_krayin -e "<SELECT…>"`. Only the `migrations` table, `information_schema`
  (columns/check_constraints/statistics), and **aggregate COUNTs** were queried. **No row values, no PII,
  no secrets** were selected or recorded; populated-value checks use `COUNT(col)` (non-null count) only.

## 1. Migration identity (implementation repo — INDEPENDENTLY VERIFIED)
- **139** = `2026_10_20_000001_add_reason_to_sca_qr_lifecycle_events.php` — **present on `main`** (QR-reissue
  reason; merged-but, per baseline, the deployed app is 3b30a0f/138 so it was merged-undeployed pre-incident).
- **140** = `2026_10_21_000001_add_collector_activity_last_seen.php` — **ABSENT on `main`**, present only on
  the Phase 2 candidate branches (`dae6072`, `0ba09fa`). It is **candidate-only / orphaned relative to main.**
- **141** = `2026_10_22_000001_add_collector_activity_source_watermarks.php` — candidate-only (not on `main`).

## 2. Production `migrations` table (INDEPENDENTLY VERIFIED, read-only)
```
id   migration                                                  batch
137  2026_10_18_000001_create_sca_service_event_corrections     25
138  2026_10_19_000001_create_sca_market_reference_events       26
139  2026_10_20_000001_add_reason_to_sca_qr_lifecycle_events     27
140  2026_10_21_000001_add_collector_activity_last_seen          27
MAX(batch)=27   COUNT(migrations)=140   batch 27 has exactly 2 rows (138→batch26, i.e. pre-incident HEAD)
```
So production is at migration **140 / batch 27**; the pre-incident state was **138 / batch 26**. Both 139
and 140 landed together in the single batch 27 — consistent with one `migrate` run applying the two then-
pending migrations.

## 3. Schema objects introduced by 139/140 (INDEPENDENTLY VERIFIED to EXIST in prod, read-only)
- `sca_qr_lifecycle_events.reason` — `varchar(500)`, nullable.
- `CONSTRAINT chk_qr_reason_only_on_reissue CHECK (`reason` is null or `event_type` = 'reissued_from')`.
- `sca_collector_accounts.activity_last_seen_at` — `timestamp`, nullable.
- Index `idx_oe_collector_effective` on `sca_ownership_events`.
- Index `idx_tr_from_collector` on `sca_transfer_requests`.
All five objects are additive (one nullable column each, one CHECK, two indexes); none alters or drops an
existing column, and the CHECK permits all existing rows (reason is NULL everywhere — see §4).

## 4. Populated values in the new columns (INDEPENDENTLY VERIFIED, COUNTs only)
- `sca_qr_lifecycle_events`: **3 rows, 0 with `reason` non-null** → no QR audit-reason data exists.
- `sca_collector_accounts`: **4 rows, 0 with `activity_last_seen_at` set** → no activity-watermark data exists.
Dropping either column (a rollback of batch 27) would therefore lose **zero** data.

## 5. Candidate not deployed (INDEPENDENTLY VERIFIED, read-only)
- `sca_collector_accounts` has **0** of the candidate-141 columns
  (`activity_seen_{ownership,transfer,submission}_event_id`).
- `migrations` has **0** rows for `2026_10_22_000001_add_collector_activity_source_watermarks`.
Confirms candidate `0ba09fa` (and the whole Phase 2 unread chain) is **not applied to production**.

## 6. Evidence classification
| Fact | Classification |
|---|---|
| 139/140 filenames + branch presence (main vs candidate) | **Independently verified** (git) |
| migrations rows, batch numbers, 138/batch-26 boundary, batch-27 = exactly 2 | **Independently verified** (read-only SELECT, 15:32:34Z) |
| Columns/CHECK/indexes exist with the stated definitions | **Independently verified** (information_schema) |
| 0 non-null `reason`, 0 `activity_last_seen_at` set | **Independently verified** (COUNT) |
| Candidate 141 columns/migration absent from prod | **Independently verified** |
| **Cause** = accidental `artisan migrate --force` on the default (`sca_krayin`) connection | **Operator/Claude-reported** — the `migrations` table has no timestamp/actor column, so the cause and exact time are **not verifiable from the database** |
| `migrate:rollback` of batch 27 would drop the 2 columns + 2 indexes with zero data loss | **Analysis/inference** (from §3/§4; NOT executed) |
| A rollback run from `main` would FAIL because the 140 class/file is absent there | **Analysis/inference** (from §1 file presence + Laravel rollback semantics; NOT executed) |

## 7. Discrepancies
**None.** Every read-only claim in the prior assessment (`docs/SCA-PHASE2-PROD-MIGRATION-INCIDENT-ASSESSMENT.md`,
gov `3cdda3c`) is independently re-verified at 2026-10-21T15:32:34Z: same migration rows/batches, same schema
objects, same zero populated-value counts. No drift since that assessment.

## 8. Disposition (unchanged; owner decision still pending)
- Production is at **140/batch 27**; new schema is **additive and carries no data** (0/3 reason, 0/4 watermark).
- Deployed app `main 6022b75` is **forward-compatible**: it contains the 139 reason-writer (only sets
  `reason` on `reissued_from`, satisfying the CHECK) and never references 140's column/indexes, which are
  harmlessly ignored.
- **Reconciliation options for the owner (no action taken here):**
  (a) **Leave additive schema** — on a future authorized deploy of the Phase 2 chain, the migrator sees 139
  and 140 already recorded (batch 27) and **skips** them; no duplicate execution, no rename. Preferred;
  requires nothing now.
  (b) **Owner-authorized `migrate:rollback` of batch 27 → restore 138** — clean (zero data loss), but MUST be
  run with a working tree that contains BOTH the 139 and 140 migration files so both `down()` resolve;
  `main` lacks the 140 file, so a rollback from `main` would fail on the missing 140 class. Not required for
  safety.
- **Unresolved questions:** the exact time/actor of the accidental `migrate` is not recoverable from the DB
  (no audit column); if that matters, host shell/cron/CI logs would be the only source. Owner must still
  decide (a) vs (b).

**STOP — read-only reconciliation only; production left untouched. Awaiting ChatGPT review and the owner's
139/140 reconciliation decision. Candidate `0ba09fa` stays unmerged/undeployed; production release NO-GO.**

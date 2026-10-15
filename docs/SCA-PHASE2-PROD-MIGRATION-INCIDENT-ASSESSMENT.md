# SCA Phase 2 — Production-Migration Incident: Read-Only Reconciliation Assessment

**Type:** READ-ONLY incident assessment (gov auth `3cdda3c`). **No `migrate`/`migrate:rollback`/live-DB
mutation, no merge, no deploy.** Only SELECT/SHOW/DESCRIBE queries, read-only HTTP loopback checks, and
test runs against the **disposable** `sca_domain_test` DB were performed. Evidence below is Claude-gathered
on the live host (not independently verified by ChatGPT).

## 1. What happened (recap)
During Phase 2 implementation a `php artisan migrate --force` was run **without** the test-DB override; the
container's default connection is the live `sca_krayin`, so it applied migration **139** (QR-reason) and
candidate-only **140** (activity column + indexes) to production in **batch 27**. Corrective rollback was
attempted and **correctly denied** by the environment as a production action, and **not** bypassed.

## 2. Migration records (production `sca_krayin`, read-only)
```
id   migration                                                  batch
139  2026_10_20_000001_add_reason_to_sca_qr_lifecycle_events     27
140  2026_10_21_000001_add_collector_activity_last_seen          27
MAX(batch)=27   COUNT(migrations)=140
```
Both rows are batch 27; no other migration is in batch 27. (Pre-incident production was batch 26 = migration
138; 139 was merged-but-undeployed, 140 is candidate-only.)

## 3. Resulting schema / constraints / indexes (exactly the candidate definitions)
- `sca_qr_lifecycle_events.reason` — `varchar(500) DEFAULT NULL`; `CONSTRAINT chk_qr_reason_only_on_reissue
  CHECK (reason IS NULL OR event_type = 'reissued_from')`.
- `sca_collector_accounts.activity_last_seen_at` — `timestamp NULL` (nullable).
- `sca_ownership_events` index `idx_oe_collector_effective` = (`collector_account_id`,`effective_at`,`id`).
- `sca_transfer_requests` index `idx_tr_from_collector` = (`from_collector_id`,`id`).
All additive; no column dropped/renamed, no existing constraint relaxed.

## 4. Was any new data written? NO.
- `sca_qr_lifecycle_events`: 3 rows, **0 with `reason` non-null** → no QR audit-reason data exists.
- `sca_collector_accounts`: 4 collectors, **0 with `activity_last_seen_at` set** → no activity watermark data exists.
Both new columns are entirely empty, so dropping them (if ever authorized) would destroy **zero** data.

## 5. Provenance integrity (read-only fingerprint)
Canonical provenance counts `items/qr/certs/auth/ownership/claims/grants/sale/status = 3/3/4/4/5/2/1/1/7` —
**identical to the established baseline**. The composite row-data fingerprint changed from `d15a5cbd…` to
`3ae1bb41853238446f232cdfe66b5b88`; this delta is explained **entirely** by migration 139 adding the
all-NULL `reason` column to a fingerprinted table (`sca_qr_lifecycle_events`), which the fingerprint hashes
column-by-column. No row was added/removed and no pre-existing column value changed (0 non-null reasons);
indexes do not affect the fingerprint. **No provenance data was mutated.** On an authorized deploy of 139 the
new FP `3ae1bb41…` becomes the legitimate baseline; on a rollback to 138 it returns to `d15a5cbd…`.

## 6. Deployed application compatibility
`/opt/sca-platform/app` is **bind-mounted** to the container `/var/www/html`, so the live site serves the
**working tree** (currently restored to `main` `6022b75`). `main` contains the QR-reason code (139) and
never references the 140 activity column/indexes, so it is **forward-compatible** with the DB at batch 27:
the extra nullable column + indexes are ignored; the CHECK is satisfied because the reason writer only sets
`reason` on `reissued_from` events. Read-only loopback: `/admin/login` → 200, `/collector/login` → 200.
(Deployed revision is inferred from the bind-mount working tree; the container has no git to byte-verify.)

## 7. Backup point & recovery constraints
Newest local encrypted backup: `sca-backup-20261014T220630Z.tar.gz.gpg` (~4.2 GB), taken **before** the
incident migration. Because no provenance data changed since (counts/values identical, only additive DDL),
that backup remains data-faithful to current production. A **restore is neither needed nor recommended** for
this incident (no data loss to recover). Note the standing blocker: **off-host replication is still absent**
(backup is VPS-local only) — unchanged by this incident.

## 8. Safe reconciliation plan (preserve data; no duplicate migration execution; no rename)
**Preferred — self-reconciling, do nothing to the live DB now:**
- On the eventual **authorized** Phase 2 merge + deploy, Laravel reads the `migrations` table, sees
  `2026_10_20_000001` and `2026_10_21_000001` already recorded (batch 27), and **skips** them — there is
  **no duplicate execution**. This requires the candidate migration files keep their **exact recorded
  names** (they already do: `2026_10_20_000001…`, `2026_10_21_000001…`). **Do NOT rename, renumber, or
  duplicate** the already-applied migration — that would make Laravel re-run it and fail on the existing
  column/constraint. The additive schema simply persists; `main` code tolerates it (§6).
- Consequence until merge: production is "ahead" of `main` by the (unused, empty) 140 schema, and
  `migrate:status` on `main` omits 140 (its file is candidate-only) — benign.

**Optional — restore the sanctioned pre-Phase-2 state (migration 138), owner-authorized only:**
- With the **candidate branch checked out** in the deploy tree (so both migrations' `down()` resolve), an
  owner-authorized `php artisan migrate:rollback` of batch 27 drops the empty `reason`/`activity_last_seen_at`
  columns + CHECK + indexes — **zero data loss** (§4) — returning production to **138**; then restore `main`.
- **Must NOT:** run `migrate:rollback` from `main` (140's file is absent → `down()` unavailable → partial/
  failed rollback); run `migrate` expecting 140 to re-execute; rename/duplicate the applied migration.

**Recommendation:** the additive schema is safe to leave in place pending the merge decision; a rollback is
optional (cosmetic restoration of the 138 baseline) and, if chosen, must follow the candidate-checked-out
procedure above. Either path is clean because the new columns are empty.

## 9. Full-suite `h8` failure — reproducibility & root cause (NOT a Phase 2 regression)
Evidence (all against `sca_domain_test`, which is confirmed **empty/clean** — 0 collectors/resets/items):

| Configuration | h8 result |
|---|---|
| `TransactionalEmailHardeningTest` isolated (first run of a fresh minute) | **9 passed** |
| Same file, 2nd & 3rd back-to-back runs (same wall-clock minute) | **3 failed — h1, h7, h8** (consistent set) |
| Full suite on `main` (1407 tests) | **0 failed** (h8 passes) |
| Full suite on candidate (1423 tests) ×2 | **h8 fails** (both times) |

**Root cause:** the failing tests (`h1` reset-URL, `h7` single-reset, `h8` single-use-token) all POST to the
collector **forgot/reset-password** routes, which are rate-limited (`throttle:6,1`). The limiter's budget
behaves as **per-minute and shared across test processes** (not reset by the array cache between tests), so
when enough forgot/reset POSTs land in one 60-second window — which happens under dense/repeated or
longer-running suites — later POSTs get **HTTP 429**, the reset never applies, and `Hash::check(new password)`
returns false → "asserting that false is true". This is a **pre-existing test-isolation / rate-limiter flake
in `TransactionalEmailHardeningTest`**, independent of the Phase 2 candidate (which changes no password-reset
code). The full-suite correlation is coincidental timing: the 17 extra Phase 2 tests shift when the email
tests run relative to the minute boundary.
**Recommendation (separate test-hardening candidate, not this task):** clear the rate limiter / flush cache in
these tests' `setUp` (or disable the throttle middleware for them) so they are order/time-independent. It is
**not** a merge blocker for Phase 2 functionality, but the flake should be fixed so the gate is deterministic.

## 10. Activity feed — pagination / unread cap semantics (as implemented in the candidate)
`CollectorActivityService` (`const CAP = 100`):
- Each source query is `->limit(100)`; `collect()` merges the three sources → at most **300** rows before
  sorting/paginating; `feed()` clamps `perPage` to 1–50 and slices the merged set.
- **Consequences / limitations:** (a) `unreadCount()` scans the merged set and **breaks at 100**, and each
  source already only contributes its newest 100 — so the unread count is **capped and can undercount** when
  a source has many unseen events; (b) pagination operates over the ≤300 merged rows, so activity older than
  ~300 total events is **unreachable**, and at the last in-range page `has_more` reads false, which could
  **imply the full history is shown** when it is not.
- **Recommendations (require a new candidate — read-only task makes no code change):** label the surface as
  "recent activity" (not a complete history); keep the badge's existing "9+" display cap (already present)
  and, if a precise count matters, compute unread via bounded `COUNT(...)` queries rather than a capped scan;
  make the pagination copy/`has_more` honest about the cap (e.g., stop offering "Older" with a note) or raise/
  document the bound. None of these affect provenance or the acknowledgement controls.

## 11. Disposition
- Production: additive-only schema at batch 27, **no data written to the new columns**, provenance counts
  unchanged, live site healthy. Safe to leave pending the merge decision; optional owner-authorized rollback
  to 138 is clean (empty columns).
- `h8`/`h1`/`h7`: pre-existing rate-limiter test flake, reproducible under dense execution, **not** a Phase 2
  defect; fix in a separate test-hardening change.
- Activity cap: document/label limitations; address in a follow-up candidate if a fuller history/precise
  count is desired.

**STOP — read-only assessment complete; awaiting ChatGPT independent audit. No merge, production deployment,
migration, rollback, data change, backup/restore, Stripe/mail activation, or pilot was performed. Production
release remains NO-GO; off-host recovery remains owner-deferred. Any code change (Phase 2 reconciliation,
h8 flake fix, activity-cap fix) requires a new candidate and re-audit.**

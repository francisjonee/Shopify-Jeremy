# SCA Staff & Collector UX Phase 2 — Independent Re-Audit Follow-up

**Review date:** 2026-10-21  
**Reviewed candidate:** `dae60728312fa1238bc733eb671540a444dcd807` on `fix/sca-ux-phase2-correction`  
**Production baseline:** `6022b75c021069bde332b4a10cd5806ae9065aaf`  
**Disposition:** **CHANGES REQUESTED — NO MERGE / NO DEPLOY**

## Scope and method

Read-only GitHub review of the candidate's current `CollectorActivityService`, activity migration, prior implementation/correction report, and production migration incident assessment. Commit comparison reports the candidate as 3 commits ahead and 0 behind production baseline, with 27 changed files. I did not execute tests, connect to the production host, query the live database, or perform any production operation. Test outputs and live database observations below remain developer-reported evidence unless explicitly stated as independently verified source facts.

## Findings

### F1 — Unread activity can be silently missed (blocking)

The current service compares event timestamps using strict `>` against `activity_last_seen_at` in both the displayed feed and exact unread COUNT queries:

- ownership events: `effective_at > activity_last_seen_at`;
- accepted transfers: `te.created_at > activity_last_seen_at`;
- submission transitions: `sse.created_at > activity_last_seen_at`.

The watermark is written from `Carbon::now()` into a nullable SQL `timestamp` column without fractional precision specified in the migration. Same-second events can therefore compare equal to the watermark and fail the strict comparison. In addition, ownership activity is ordered and compared using `effective_at`, which represents event effectiveness and can be backdated; it is not necessarily the time the event was recorded. A newly recorded event with an older `effective_at` can remain absent from unread activity.

**Required correction (candidate branch only):**
1. Define and document whether “new” means recorded after the collector marked activity seen, rather than effective date after the watermark.
2. Use a reliable event-recording/monotonic boundary that handles same-second precision and late-recorded/backdated ownership events. Do not silently switch semantics without checking available ledger columns and existing invariants.
3. Add regression tests for same-second event creation and for an ownership event recorded after mark-seen but carrying an earlier `effective_at`; cover feed `is_new` and unread badge/count consistently.
4. Preserve collector scoping, existing authoritative sources, bounded feed behavior, and read-only GET / explicit POST mark-seen separation.
5. Run focused tests and the full SCA feature suite on the verified disposable database, recording exact command, target DB, SHA, and output.

### F2 — Production migration incident remains owner-controlled

The governance incident assessment reports that migrations 139 and 140 were applied to production database `sca_krayin` in batch 27, with additive schema and no observed row-data mutation. It also reports both new columns had no populated values at the time of inspection. These observations were gathered by the implementation operator and have **not been independently verified against the live production host in this audit**.

Do not run `migrate`, `migrate:rollback`, or any database write. The existing incident assessment's preferred path is to preserve the additive schema and retain the exact migration filenames so Laravel can skip already-recorded migrations on a later separately authorized merge/deploy. Before any release decision, obtain fresh, safely redacted, read-only evidence from production for migration records, schema/indexes/constraint, and current null/population counts; compare with the recorded assessment. If direct production read-only access is unavailable, explicitly keep this evidence marked as operator-reported.

### F3 — The candidate's latest truncation correction is present in source

The inspected candidate uses a CAP+1 probe for each source, drops the probe row from display, and marks the window capped only when a source has more than CAP rows. It uses exact COUNT queries for unread counts and labels the UI “Recent activity” with a truncation disclosure. The governance report states boundary tests for 99/100/101 rows and a green full feature suite, but those test results were not independently executed by this audit.

## Safety and release status

- No production host/database access or commands performed by this audit.
- No merge, deployment, migration, rollback, restart, backup/restore, Stripe/mail activation, or pilot authorized.
- Candidate remains unmerged and must stay out of production until F1 is fixed and re-audited, and the production migration incident evidence/reconciliation path is owner-approved.
- Production release remains **NO-GO**. Off-host recovery remains a separate outstanding release gate per the current governance queue.

# SCA Service-History Correction & Annotation — Implementation Evidence (pre-merge, R1)

**Status:** R1 REMEDIATION pushed — awaiting ChatGPT re-audit. NOT merged, NOT deployed.

| | |
|---|---|
| Governance baseline (promotion) | `ffe7ce958a939fd96e03050c3d5345cf77ff7d31` |
| Pre-merge audit (FAIL R1) | `57a12cc3266e3c34b45d01a557546040eaec86ff` |
| Implementation branch | `feat/sca-service-correction` (one commit ahead of base) |
| Exact production base SHA | `9bc0907c486688c7acd0d22ad2ee9f5db37d93bb` (migration 136) |
| Prior candidate (FAILED) | `18aba7c8f464e1ac384561648698373444d07c88` |
| **NEW candidate SHA** | **`57672b05f7163eb1346e869633e84de31cec7f86`** |
| Expected migration | 136 → **137** (`2026_10_18_000001_create_sca_service_event_corrections`) |
| Files changed vs base | 15 (1889 insertions, 28 deletions) |
| Focused tests | `ServiceCorrectionTest` 37 + `ServiceCorrectionConcurrencyTest` 1 → **38 passed** |
| Full `tests/Feature/Sca` | **1281 passed / 1 skipped / 0 failed** |
| Production provenance FP (unchanged) | `d15a5cbdfb8df52ba65628b276533cfe`, counts `3/3/4/4/5/2/1/1/7` |
| Production schema | migration 136, `sca_service_event_corrections` absent, `sca_service_events` 0 |

## R1 merge blocker — resolved

The audit found the factual-correction evidence was a **full four-field snapshot** on every `correct`, so a notes-only correction permanently looked like staff re-attested type, grade and date. This is now genuinely **sparse**.

**Sparse model.** A `correct` row carries four per-field booleans `changes_service_type / changes_condition_grade_after / changes_notes / changes_occurred_at` plus the nullable `corrected_<field>` value columns:
- `changes_<field> = 1` → this correction amended that field to the stored `corrected_<field>` (which **may be NULL = an explicit clear**, unambiguously distinct from "not amended");
- `changes_<field> = 0` → the field is inherited from the prior effective state and is **not** re-attested by this row (`corrected_<field>` is NULL/ignored).
- DB CHECK `chk_svc_corr_correct_nonempty`: a `correct` row must change ≥1 field; `chk_svc_corr_noncorrect_noflags`: annotate/void carry no flags.

**Sparse fold.** `ServiceCorrectionService::fold()` starts from the original event and applies, per `correct` in `(created_at,id)` order, only flagged fields; latest flagged value per field wins. Void terminal; annotations accumulate.

**Explicit per-field intent, UI → request → service.** The confirm screen has a "Change this field" checkbox per field. `ServiceCorrectionRequest` validates a field's value only when its `change_<field>` flag is set (`required_if`), and the controller's `sparseChanges()` builds the change set **only** from checked flags — a merely-posted value never implies a correction. The service then re-validates each selected field and records only those whose normalized value actually **differs** from current effective; a selected-but-equal field is dropped, and if nothing differs the whole request is NOOP.

**Truthful chronology + actor (R1 #6/#8).** `effectiveHistory` builds a running fold so each `correct` chronology entry lists exactly the field(s) it changed with old→new, and now carries `actor_staff_ref`. The confirm screen renders field label + old→new + **actor ("Staff #id")** + reason + time.

**Collector projection unchanged in spirit, hardened.** `collectorHistory` exposes effective values + a non-sensitive "corrected" indicator + collector-visible annotation text only — never field-level audit metadata, staff ref, reason, internal ids, or voided content (asserted, incl. no `changes_` leakage).

## Mandatory R1-test → evidence map

| R1 test | Covered by |
|---|---|
| 1 notes-only stores notes only | sc10 |
| 2 grade-only stores grade only | sc11 |
| 3 explicit clear-to-NULL distinct from unchanged + folds | sc12 |
| 4 sequential sparse corrections to different fields compose | sc13 |
| 5 same-field later wins; prior evidence immutable | sc14 |
| 6 NOOP for selected field equal to current | sc15 |
| 7 mixed selection stores only actually-differing fields | sc16 |
| 8 chronology shows changed fields old→new + actor/time/reason | sc29 |
| 9 real two-connection concurrency proof green | ServiceCorrectionConcurrencyTest::cc_sc1 |
| 10 original byte-identical; zero provenance/current-state mutation | sc24, sc36 |
| 11 collector privacy + public passport green | sc30, sc31, sc33, sc35 |
| 12 full `tests/Feature/Sca` green | 1281 / 1 skip / 0 fail |

Plus the originally-accepted boundaries retained and still tested: dedicated ACL / record-perm cannot correct (sc1, sc2), collector/public denied (sc3), bounded reason (sc4), invalid type/grade/date at validation + DB (sc5, sc21), empty-correct rejected at DB (sc22), cross-item 404 + DB trigger (sc17, sc23), missing 404 (sc18), server actor not spoofable (sc19), append-only correction rows (sc20), annotate default staff-only (sc25), terminal void / no post-void edit (sc26), STALE (sc27), fold void+annotations (sc28), former-owner loses access (sc34), GET read-only + fail-closed NOT_FOUND (sc37).

## Changed files (15)

Added: migration, `ServiceCorrectionService`, `ServiceCorrectionRejection`, `ServiceCorrectionController`, `ServiceCorrectionRequest`, `service-correct.blade.php`, `ServiceCorrectionTest`, `ServiceCorrectionConcurrencyTest`, `tests/Support/svc_correction_worker.php`.
Modified: `acl.php` (+`sca.eyewear.service.correct`), `admin-routes.php` (confirm GET + throttled apply POST), `EyewearItemController::show` (canonical effective reader), `eyewear/show.blade.php` (effective + corrected/void badges + Correct links), `Collector/CollectionService.php` (+`collection/show.blade.php`) (owner-safe history via `collectorHistory`, "(corrected)" + visible notes).

## Production-untouched proof

Live tree restored to `main@9bc0907`, vendor `--no-dev`, `/admin/login → 200` on loopback. Prod DB `sca_krayin`: migration 136 (`…shopify_reconciliation`), `sca_service_event_corrections` absent, `sca_service_events` = 0, 13-table provenance fingerprint `d15a5cbd…` / counts `3/3/4/4/5/2/1/1/7` byte-identical to baseline. All work ran only on the disposable `sca_domain_test` DB (migration rolled back + re-applied there for the new schema).

## Boundaries honored

No Krayin core edits. No Caddy / DNS / Shopify / Stripe / SMTP / OAuth changes. No collector/public mutation route. No `ProjectionService::rebuild()` from correction. `ServiceService::record()` unchanged. No hard delete / unvoid.

**STOP — awaiting ChatGPT re-audit of candidate `57672b05`. Do not merge or deploy.**

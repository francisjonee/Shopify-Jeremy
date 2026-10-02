# SCA Admin registry-status filter labels → canonical ItemStateLabels (PUSH-ONLY)

**Date:** 2026-10-02 · **Base:** deployed main `8d466d1`, migrations **120**.
**Status: IMPLEMENTED + TESTED + PUSHED. NOT merged, NOT deployed. For review.**
Follow-up on the documented residual from SCA-STATUS-TERMINOLOGY-CONSISTENCY (gov `8c06d96`).

## Candidate
- **SHA:** `ef4c3a5f6df5098295fcbfe3ed40805188952063` · **Branch:** `origin/sca-registry-filter-labels`
- **Base / merge-base:** `8d466d1` (clean, 1 commit, exactly 2 files).

## Audit
The Admin registry-status **filter dropdown** (`eyewear/index.blade.php:102`) was the **only** remaining admin
surface independently humanizing registry enums (`{{ ucfirst($rs) }}`). Audit of all admin `ucfirst()`/
`ucwords()` usages confirmed every other occurrence maps a **different** concept — certification `state`
(`ucfirst($currentCert->state)`), authentication `result`, certification-event `event_type`, document `kind`,
service `type` — **none are registry statuses**. So this is the sole remaining occurrence; the smallest
view-only change plus regression suffices. Source list = `EyewearItemController::REGISTRY_STATUSES`
(unchanged); the controller filters on the raw `registry_status` value (unchanged).

## Change (presentation only; 2 files)
- `packages/Sca/Registry/src/Resources/views/eyewear/index.blade.php`: the registry filter option **label**
  `{{ ucfirst($rs) }}` → `{{ \Sca\Provenance\Support\ItemStateLabels::registryShort($rs) }}`. The option
  **VALUE stays `{{ $rs }}`** (raw enum), so `disputed` remains the submitted/filter value and only its
  displayed label becomes **"Under review"**. `REGISTRY_STATUSES` and the controller's registry filter query
  are untouched → filter/query behavior identical.
- `tests/Feature/Sca/CatalogGridTest.php`: `rg11` (disputed/recovered/lost/invalidated options render the
  canonical labels; no `>Disputed</option>`) + `rg12` (`?registry_status=disputed` round-trips — the option is
  `selected` and `value="disputed"` preserved).

**NO** schema/migration/projection/service-domain/status-workflow/routes/ACL/Collector/Passport/QR/gallery/
provenance/SMTP/infra/`deriveLifecycleState` change. `git diff 8d466d1..ef4c3a5` = these 2 files only.

## Tests
- Focused `CatalogGridTest` 12/12 (incl. rg11/rg12). Full `tests/Feature/Sca` **762 passed (4219 assertions),
  exit 0** (baseline `8d466d1` 760/4211 → +2). `php -l` clean; Blade parses.

## Restoration / not-live / zero-mutation proof
- Pilot restored to `main` = `8d466d1` (`--no-dev`, caches cleared). Candidate change **absent** (0
  `registryShort($rs)` refs; `ucfirst($rs)` back at line 102). Live: `/p` 200/404, `/storage` 404,
  `/admin/sca/eyewear` 403 (non-staff), kr-app `127.0.0.1:8080` loopback-only. Prod unchanged (view-only, no
  mutation run): migrations 120, status_events 6, QR tokens `bee93d2b…`/`10c739b7…` intact.

**STOP after push. Not merged/deployed. Awaiting review of `ef4c3a5` (base `8d466d1`).**

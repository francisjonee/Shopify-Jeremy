# SCA-OPTC — Final Test-Only Audit Corrections

**Status: three test-only corrections implemented + non-destructively verified; available for ChatGPT review. NO focused/assert/full/baseline DB test executed. No application logic changed.** Not merged/deployed/migrated/restarted/activated; 139/140 untouched. Candidate `feat/sca-optc-secure-claim` **`1361357` → `5eb8708`** (pushed). `main 6022b75` + `sca_krayin` untouched.

Changed files (3; test files + runner only): `app/tests/Support/id_exposure.php`, `scripts/seed-test-admin.php`, `scripts/run-optc-tests.sh`.

## 1. Context-aware `sca_detect_id_exposure()` (no longer bare-number matching)

Now flags an internal id in four identifier contexts:
- (a) quoted value `"<id>"` (attributes / JSON strings) — unchanged.
- (b) alpha-route URL path `/<route>/<id>` — unchanged.
- **(c) NEW — numeric JSON value under an id-like key:** `"..._id":<id>` / `"id": <id>` (unquoted number; the key must end in `id`, so `"count":5`, `"year":2026`, and CSS never match).
- **(d) NEW — unquoted id-like HTML attribute:** `id=<id>`, `data-id=<id>`, `item-id=<id>`, `item_id=<id>` (the attribute NAME must be `id` / `…-id` / `…_id`, optionally `data-`-prefixed; so `width=800`, `initial-scale=1`, `maxlength=10`, `data-count=5`, `grid=…` do NOT match).

False-positive protection (CSS px, viewport scale, slash dates, dotted versions, ordinary non-id numbers) is preserved. The genuine sensitive-string assertions in `h7`/`d9` (opaque ref, email, public_ref, `catalog/`, `storage_path`, `checksum_sha256`, `"subject_id"`, qr_token) are **unchanged**.

**Extended controls (selftest `[13]`, php in a `--network none` no-DB container):**
- POSITIVE (must be detected): `data-id="4242"`, `/u/ada/items/4242/image`, `"collector_id":"4242"`, `"item_id":4242`, `"id": 4242`, `data-id=4242`, `id=4242`, `item-id=4242`, `item_id=4242`.
- NEGATIVE (must pass): `max-width:4242px`, `initial-scale=1`, `2026/10/26`, `v4.2.42`, `z-index:4242}`, `padding:42 0`, `width=4242 height=4242`, `"count":4242,"year":2026`, `maxlength=4242`, `data-count=4242`, `grid:4242`.
- Result: `CONTROLS-OK`.

## 2. Test-admin seeding is verified (fail closed)

`seed-test-admin.php` now **always** verifies, after seeding (and on the already-present path), that `User::find(1)` exists, is backed by a valid role (`role_id` set and the role row exists); otherwise it aborts (exit 3) with a clear message. No application authentication logic changed (still a disposable-DB-guarded, idempotent seed of the canonical admin; random password; `actingAs` usage).

## 3. Per-run cache isolation

The file cache is mounted as a **tmpfs** over `storage/framework/cache` (`--tmpfs …/storage/framework/cache:uid=0,mode=0777`): the throttle/cache state exists only inside that container run and is discarded on exit, so it can never persist to the worktree or leak between independent runs. The RateLimiter behaviour, middleware, and thresholds are unchanged (the throttle still accumulates within a run so the rate-limit tests remain meaningful).

## Unchanged safeguards

DB lifecycle (create-not-drop, abort-on-collision, register-after-create), effective-connection verification (host decision + in-container re-verify), the XML-aware override validator, per-run unique naming, and cleanup — all unchanged (selftest sections [1]-[12] still green).

## Non-destructive evidence

- `bash -n scripts/run-optc-tests.sh` — OK.
- `scripts/run-optc-tests.sh selftest` — **65 passed / 0 failed** (no DB/network/live mount), including `[13]` extended controls (`CONTROLS-OK`) and `[14]`: tmpfs cache isolation present + seeder fail-closed verification present.
- `php -l` — clean on `id_exposure.php` and `seed-test-admin.php`.
- **No focused/assert/full/baseline DB test executed.**

**STOP — final test-only audit corrections + non-destructive evidence for independent ChatGPT review before database-test authorization. No merge/deploy/migrate/restart/activation; backup/DR + ops readiness remain separate workstreams.**

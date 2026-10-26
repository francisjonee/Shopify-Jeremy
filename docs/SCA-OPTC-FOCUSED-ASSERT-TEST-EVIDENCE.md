# SCA-OPTC — Authorized Focused + Assert Test Evidence

**Status: the owner-authorized `selftest` + `focused` + `assert` phases executed and PASSED on separate per-run disposable databases. Full suite + baseline NOT run (not authorized). Not merged / not deployed / no production migration / no restart / no Shopify/Stripe/SMTP activation / 139-140 untouched.** `main 6022b75` + production `sca_krayin` unchanged.

- **Candidate SHA:** `0f41e2e031802989c2b0611a4d17ce0c30694fd1` (`feat/sca-optc-secure-claim`), isolated worktree `/opt/sca-platform-cand-optc` (live app stayed `6022b75`).
- **Date:** 2026-10-26.

## Preflight (passed)

- Candidate HEAD == `0f41e2e` ✓; isolated non-mounted worktree; live app `6022b75`.
- MariaDB: container `kr-mariadb`, image `mariadb:10.11` (`10.11.18-MariaDB-ubu2204`, hostname `b36c8e36e041`), network `sca_internal`; root creds verified.
- Before the run: only `sca_krayin` present (no `sca_optc*_test_*`) → unique per-run DBs cannot collide with or delete an existing disposable DB.
- Production baseline recorded: `sca_krayin.migrations` = `max_batch=27, total=140`.
- `selftest` (non-destructive, no DB) → **65 passed / 0 failed**.

## Run results (each phase on its OWN separate, uniquely-created disposable DB)

| Phase | Disposable DB (created + dropped) | Connection isolation | Migrations | Tests | Exit |
|---|---|---|---|---|---|
| `focused` | `sca_optc_test_fd9692cc` | host decision + in-container re-verify: `db=sca_optc_test_fd9692cc host=kr-mariadb live=sca_optc_test_fd9692cc`; XML override clean | 141 DONE (incl. `2026_10_23_000001_add_fulfillment_release`); admin seed verified `id=1 active role_id=1 permission_type=all` | **68 tests, 333 assertions, 0 failures** | 0 |
| `assert` | `sca_optcassert_test_b3531254` | host decision + in-container re-verify: `db=sca_optcassert_test_b3531254 host=kr-mariadb live=sca_optcassert_test_b3531254`; XML override clean | 141 DONE (incl. the Option C migration); admin seed verified | **60 tests, 182 assertions, 0 failures** (`CollectorHandleTest` h7 + `CertificateDocumentClassificationTest` d9) | 0 |

- **h7 and d9 now PASS** on a real DB — the context-aware id-exposure assertions, the canonical admin seed, and the per-run file cache together resolve the previous candidate-only `h7` fragility; no genuine sensitive-string check was weakened.
- Each phase created its **own** unique disposable database (requirement 6), proved the effective Laravel connection pointed only at that DB (host `kr-mariadb`, schema == live == the per-run name, never `sca_krayin`/`sca_domain_test`), migrated it, tested, and dropped it.

## Cleanup & production isolation

- After both phases: `SHOW DATABASES LIKE 'sca%'` → **only `sca_krayin`** (both `sca_optc_test_fd9692cc` and `sca_optcassert_test_b3531254` dropped). No residual disposable database.
- **Production unchanged:** live app HEAD `6022b75`; loopback `302` (up); `sca_krayin.migrations` = `max_batch=27, total=140` — identical to the pre-run baseline (no migration or write touched production).

## Not run / not authorized

- Full regression and clean-baseline database tests — **not run** (explicitly not authorized).
- No merge, deploy, production migration, service restart, or Shopify/Stripe/SMTP activation; 139/140 untouched.

**STOP — focused + assert evidence delivered for independent ChatGPT review. Full suite + baseline remain for a separate authorization.**

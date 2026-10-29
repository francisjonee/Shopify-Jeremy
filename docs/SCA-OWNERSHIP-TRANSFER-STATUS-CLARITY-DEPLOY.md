# SCA — Transfer Status Clarity: Controlled Production Deployment — RESULT

**Authorized controlled production deployment of RC `5bed316` DONE. Live production advanced
`cb8a8c3` → `5bed316926575e79e46eaefadf1509c9605a0aa2` by code-only fast-forward + `view:clear` +
`apachectl graceful`.** Transfer-status clarity enhancement is live; R0/R0b/R0c remain absent. No DB
migration/change, no Docker recreate, no Shopify/SMTP/claim/Option-C change. All post-deploy checks
passed; no rollback needed. 2026-10-29. **STOP.**

## Prechecks [1–5]
- **[1]** Live/prod `cb8a8c3`, branch `main`, working tree clean; loopback `/admin/login → 200`. RC
  `origin/release/transfer-status-clarity-prod` = **`5bed316`**, parent **`cb8a8c3`** (one commit
  ahead); HEAD is ancestor of RC → clean fast-forward, no origin/main pull.
- **[2]** RC vs `cb8a8c3` = exactly the 6 approved files (2 controllers + 3 blade views + 1 new test),
  229 insertions / 5 deletions, 1 commit.
- **[3]** No migration files, no R0c service/controller files, no presale/email-verify/fulfillment
  routes in the change.
- **[4]** DB baseline captured (below). Latest backup `sca-backup-20261029T021703Z.tar.gz.gpg`
  (~4.58 GB, ~7h old) **sha256 verified OK**; backup job log `DONE` (offsite-deferred is the known
  residual — local artifact only; acceptable for a no-DB-change, fully code-reversible deploy).
- **[5]** Rollback path confirmed: `cb8a8c3` object present → rollback = fast-forward/checkout the
  live tree back to `cb8a8c3` + `view:clear` + graceful. No DB rollback needed (no migration).

## Deploy [6–9]
- **[6]** `git merge --ff-only 5bed316…` on the live checkout (branch `main`) → working tree advanced
  to **`5bed316`**. origin/main (`a397a7e`) was NOT pulled.
- **[7]** `app/vendor` unchanged (53 entries, same) and `app/.env` unchanged (sha identical) — merge
  touched only the 6 tracked files; working tree clean after.
- **[8]** `php artisan view:clear` → "Compiled views cleared"; `apachectl -k graceful` → exit 0;
  health `200`. opcache `validate_timestamps=On` (freq 2s) re-reads the changed controllers; no
  compiled config/route cache in use (only package-discovery files in `bootstrap/cache`).
- **[9]** No migrations run; no Docker recreate.

## Post-deploy verification [10–15]
- **[10]** Deployed SHA = **`5bed316926575e79e46eaefadf1509c9605a0aa2`** ✓.
- **[11]** Routes: `/collector/login → 200`, `/collector/register → 200`, `/collector/collection →
  302` (auth guard redirect), `/collector/collection/ZZZ → 302` (unauth, not 500), public
  `/p/<token> → 200`.
- **[12]** Transfer-status presentation data path runs against the existing production schema: a
  read-only exercise of `TransferWorkflow::pendingInviteToken` executed cleanly. The one existing
  transfer request is state `accepted` (not pending) → banner correctly hidden for it; the queried
  columns (`invite_token`/`state`/`expires_at`/`from_collector_id`/`eyewear_item_id`) are all present
  in the batch-29 schema (unchanged by R0c). No migration dependency.
- **[13]** R0/R0b/R0c absent from the live app: R0c source files absent
  (`PresaleClaimGrantService`, `CollectorEmailVerificationService`, `PresaleGrantClaimController`);
  `route:list` shows no presale/email-verify/fulfillment routes; no `claimByPresaleGrant` /
  `BUYER_VERIFICATION_REQUIRED` in the deployed source.
- **[14]** Production data fingerprint UNCHANGED vs pre-deploy baseline:
  - migrations **batch 29 / 145**.
  - items **3** / current_state **3** / authentications **4** / certifications **4** / qr **3** /
    ownership_events **5** / claims **2** / external_claim_grants **1** / transfer_requests **1** /
    transfer_events **2** / shopify_sale_links **1**.
  - R0c `sca_presale_claim_grants` + `sca_shopify_sale_links.order_email` +
    `sca_collector_email_verifications` all **absent (0/0/0)**.
- **[15]** Logs: zero ERROR entries dated `2026-10-29` (today), including after generating fresh
  collector-route traffic. The only ERROR in the log is from `2026-10-28 17:38:44` — a one-off
  `tinker --execute` CLI probe from a prior session ("Command line code:5"), unrelated to this
  deploy and not a web request.

## [16] Rollback
Not triggered — all critical checks passed. (If needed: `git merge --ff-only cb8a8c3` is not possible
since cb8a8c3 is behind; rollback = `git reset --hard cb8a8c3` / checkout cb8a8c3 on the live tree +
`view:clear` + `apachectl graceful`; no DB action.)

## [17] Deployed state
- **Live `/opt/sca-platform` working tree + local `main` = `5bed316`** (transfer-status clarity only).
- origin/main remains **`a397a7e`** (merged main with R0/R0b/R0c) — **NOT deployed**; the deployed code
  intentionally diverges from origin/main to exclude the email-gated claiming work.
- Production DB schema unchanged (batch 29); no email configuration; claiming behavior unchanged from
  before (public-QR claim path as it was on `cb8a8c3`; R0 retirement NOT deployed).

**STOP — transfer-status clarity is live at `5bed316`; production data + schema unchanged; R0/R0b/R0c
absent. Do NOT deploy origin/main `a397a7e` (email-gated R0/R0b/R0c) without separate authorization +
operational email delivery. SEPARATE OPEN: Phase-1 first genuine `products/*` webhook receipt
verification.**

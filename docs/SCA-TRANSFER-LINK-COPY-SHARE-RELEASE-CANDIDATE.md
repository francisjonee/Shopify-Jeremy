# SCA — Transfer-Link Copy/Share: Production Release Candidate

**A production-based, view-only release candidate for the one-time transfer-link Copy/Share enhancement
is prepared and pushed. It changes exactly one Blade view, has no migration, and does not touch claim,
ownership, or transfer services — and its inline JS is compatible with the actually-deployed CSP (there
is none on collector pages).** RELEASE-PREPARED — awaiting independent review and a separate deployment
authorization. No production change; no live transfer/claim/DB modification; no Shopify/email. 2026-10-30.
**STOP.**

## SHAs
- **Production (unchanged):** `a53eff321580f7338c2192bf0cdb0ef8375bfea7` (live tree clean, `kr-app`
  healthy).
- **Reviewed development head:** `19c3ca0` (branch `feature/sca-passport-collection-ux`).
- **Release candidate:** **`b0076068c60704036da0ca04735dfd1a1537a070`** on branch
  **`release/sca-transfer-link-copy-share`**, parent = `a53eff3` (single clean commit).

## Scope & byte-identity
- **Exactly one file changed** vs production:
  `app/packages/Sca/Collector/src/Resources/views/transfer/initiate.blade.php`.
- The RC tree is **byte-identical** to the reviewed dev head `19c3ca0` (`git diff --quiet 19c3ca0 <RC>`
  = no difference, verified before and after commit).
- **Zero migrations; no change to claim, ownership, or transfer services/controllers/routes** — the only
  file is a Collector Blade view.

## CSP compatibility (verified against the deployed app)
Collector pages send **no `Content-Security-Policy` header** — confirmed on the live application via both
the app loopback (`http://127.0.0.1:80/collector/login`) and the public edge
(`https://verify.secondchanceauthenticators.com/collector/login`); only `X-Content-Type-Options: nosniff`
and `X-Frame-Options: SAMEORIGIN` are present. So the inline Copy/Share script is CSP-compatible (and the
existing item-gallery inline script on collector pages likewise runs unrestricted). The **public passport**
retains its stricter CSP (`PublicPassportHeaders`: style-src `'unsafe-inline'`, img-src `'self'`, no inline
script) and intentionally has **no** JS added.

## Behaviour review (token safety & graceful degradation)
- **Works with the existing transfer URL:** the script reads the accept URL already rendered in the
  read-only input and, on an explicit click, copies it to the clipboard or opens the native share sheet.
- **No regeneration / transmission / logging / exposure:** the diff contains **no** `fetch` / XHR /
  `sendBeacon` / `console.*` / analytics / form-submit / redirect. The token is never sent to any third
  party, never logged, and never exposed beyond the owner's own transfer page and the owner's deliberate
  copy/share action. It does **not** call `transfer.initiate` or otherwise regenerate the token.
- **No-JS fallback preserved:** the read-only input with tap-to-select (`onclick="this.select()"`)
  remains; with JS off the page still shows and selects the link.
- **Graceful failure handling:** the Share button is injected **only** where `navigator.share` exists;
  `navigator.clipboard.writeText` rejection (or absence) falls back to `select()` + `execCommand('copy')`,
  and if that fails too, an `aria-live` status tells the owner to press Ctrl/Cmd+C on the selected link.

## Verification performed
- Prod `a53eff3` clean/healthy; RC parent = `a53eff3`; single-file diff; byte-identical to `19c3ca0`.
- Blade compiles and the generated PHP passes `php -l` (checked against the production vendor,
  read-only). **No** database-changing test was run and **no** production data was touched.

## Deployment plan (code-only, view-only; for a SEPARATE authorization — NOT executed here)
No migration, so the standard code-only fast-forward applies (live `app/` is a bind-mount; opcache
`validate_timestamps=On`; no Docker recreate):
1. Pre-checks: live tree at `a53eff3`, clean; `kr-app` healthy.
2. On the live tree: `git merge --ff-only b007606` (fast-forward only — refuse if not a clean FF; never
   pull `origin/main`).
3. `php artisan view:clear` (this change is a compiled Blade view — clearing the view cache is the key
   step so the new markup is served).
4. `apachectl -k graceful` (no container recreate; no migration).
5. Post-deploy smoke (read-only): open an owner's transfer page with an active link and confirm the
   **Copy link** button and (on a mobile browser) **Share** appear and the read-only input still selects;
   do **not** initiate, accept, or cancel a live transfer.

## Rollback procedure
View-only, so rollback is a code revert + view-cache clear (a **backward move to the previous snapshot,
not a fast-forward**):
1. On the live tree: `git checkout a53eff3 -- app/packages/Sca/Collector/src/Resources/views/transfer/initiate.blade.php`
   (or `git reset --hard a53eff3` on the deploy branch) to restore the production view.
2. `php artisan view:clear` then `apachectl -k graceful`.
3. **No database rollback** — there is no migration and nothing is written.

## Safety posture (this task)
No production deployment; no live Shopify API request or store modification; no live transfer/claim/DB
modification; no email configuration; no secure-claim RC deployment; no unrelated development. Secure-claim
RC `4bd88d2` remains DEPLOYMENT-BLOCKED and untouched.

**STOP — RC `b007606` on `release/sca-transfer-link-copy-share` (parent prod `a53eff3`), byte-identical to
reviewed `19c3ca0`, exactly one Blade view, no migration, no claim/ownership/transfer service change, CSP-
compatible (no CSP on collector pages), token-safe, with a preserved no-JS fallback and graceful failure
handling. Pushed. Production unchanged at `a53eff3`; release worktree removed. Awaiting independent review
and a separate controlled-deployment authorization.**

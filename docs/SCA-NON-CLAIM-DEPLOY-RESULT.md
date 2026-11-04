# SCA — Non-Claim Production Deployment (RESULT)

**The approved non-claim release is DEPLOYED and healthy. Production fast-forwarded from
`6e36aa7` to `e3f73f8b5f027f14fe61b70faa2cba27e1b4510e` — a code-only, migration-free change delivering
the customer-Passport P2 accessibility/UX polish, QR-label identification + batch numbering, fixed-size
QR-label PDFs, and the staff-dashboard identity/status improvements (plus the pi8 regression-test fix).
All mandatory pre-deployment gates passed, the fast-forward and graceful reload completed cleanly, and
every post-deployment check is green: production HEAD equals the approved SHA, the public Passport serves
the new accessibility markup, the QR-label-PDF routes are registered, the DB fingerprint is byte-for-byte
identical to pre-deployment (no new authentication/certification/QR/claim/ownership records; the 205
imported records and 205 Shopify variant links unchanged), zero database migrations ran, secure buyer
claiming remains undeployed, no Shopify API calls were made, and the application log shows no new errors.
No rollback was required.** 2026-11-04. **STOP — deployment complete; no further releases.**

> Written for: the owner (Jeremy) and the external auditor.

## Final report
- **Previous production SHA:** `6e36aa74a3af4cd17415c4aad996a53a166dd1bf`
- **Deployed SHA:** `e3f73f8b5f027f14fe61b70faa2cba27e1b4510e` (branch `release/non-claim-on-6e36aa7`; a direct 5-commit descendant of prod, 0 behind)
- **Rollback reference (created pre-deploy, verified):** tag `rollback/pre-nonclaim-6e36aa7` and branch `backup/pre-nonclaim-6e36aa7`, both at `6e36aa7`.

### Deployment & application health
- Controlled `git merge --ff-only` on the live `main` → `e3f73f8b` (origin/main NOT pulled/merged); working tree clean after. `php artisan view:clear` (compiled views cleared); `apachectl -k graceful` (exit 0). No `config:clear`, no env change, no container recreate (both `kr-app`/`kr-mariadb` still "Up 2 weeks (healthy)").
- Production HEAD = `e3f73f8b…` (matches approved SHA); `kr-app` loopback HTTP 302 (normal), public edge HTTP 200.

### Pre-deployment gates (all passed)
1. Live checkout == `6e36aa7`. 2. Release SHA exists; `6e36aa7` is its ancestor (5 ahead / 0 behind). 3. Tree clean; containers healthy. 4. Recent backup present (`/opt/sca-platform/backups/sca-backup-20261104T021703Z.tar.gz.gpg`, today). 5. Rollback refs created at `6e36aa7`. 6. Diff `6e36aa7..e3f73f8b` = 27 files, **0 migrations, 0 `Sca\Claim` files, 0 files outside `Sca`+tests, 0 composer/config/Docker/Caddy/.env/CI**. 7. Pre-deploy fingerprint captured.

### Post-deployment verification
| Check | Result |
|---|---|
| 15 Production HEAD == approved SHA | ✅ `e3f73f8b…` |
| 16 App health / routes | ✅ loopback 302; edge 200; `route:list` boots |
| 17 Public Passport | ✅ `/p/{token}` HTTP 200 with the new a11y markup ("SCA record status", `sr-only` headings present) |
| 17 My Collection | ✅ collector routes registered and unchanged (owner-auth) |
| 18 QR-label PDF routes + staff dashboard | ✅ `admin.sca.eyewear.qr.label.pdf` (GET) + `qr.labels.pdf` (POST) registered; dashboard views deployed in the tree |
| 19 Auth / certification / ownership | ✅ intact — counts unchanged; full RC regression was green pre-deploy |
| 20 205 imports + Shopify variant links | ✅ unchanged (items 208, imported 7–211 = 205, variant_links 205, link_audit 205) |
| 21 No new auth/cert/QR/claim/ownership records | ✅ fingerprint identical (auth 4, cert 4, qr 3, ownership 5, sale_links 1) |
| 22 Secure buyer claiming undeployed/inactive | ✅ 0 claim/presale/email-verify routes; 0 secure-claim tables in `sca_krayin` |
| 23 Shopify safety | ✅ no Shopify API call or store change made; `sca_shopify_sale_links` = 1, variant links = 205 (unchanged) |
| 24 Application logs | ✅ no new ERROR/Exception/Fatal entries post-deploy |

### Inventory & database fingerprint comparison (pre == post)
| table | pre | post |
|---|---|---|
| sca_eyewear_items | 208 | 208 |
| sca_eyewear_item_shopify_variant | 205 | 205 |
| sca_eyewear_shopify_link_audit | 205 | 205 |
| sca_authentications | 4 | 4 |
| sca_certifications | 4 | 4 |
| sca_certification_events | 5 | 5 |
| sca_qr_identifiers | 3 | 3 |
| sca_qr_lifecycle_events | 3 | 3 |
| sca_ownership_events | 5 | 5 |
| sca_shopify_sale_links | 1 | 1 |
| imported ids 7–211 | 205 | 205 |
| migrations (rows) | 146 | 146 |
| secure-claim tables | 0 | 0 |

**Identical — no data, schema, or migration change.**

### Shopify safety confirmation
Zero Shopify API requests and zero store modifications were made. The deployment is code-only; the
Shopify catalog mirror, the 205 variant links, and the single sale link are unchanged.

### Warnings / rollback actions
- **No rollback performed** — all checks passed.
- Non-blocking note: several stale developer worktrees from earlier sessions remain registered under the
  session scratchpad (`wt-p2b`, `wt-r0`, `wt-r0b`, `wt-r0c`, `wt-slicec`); they point at old feature
  branches, are separate from the live tree, and did not affect this deployment (can be pruned later).

### Rollback procedure (if ever needed — not used here)
`git -C /opt/sca-platform merge --ff-only`… no — reset: `git -C /opt/sca-platform checkout main && git reset --hard rollback/pre-nonclaim-6e36aa7` (back to `6e36aa7`), then `docker exec kr-app php artisan view:clear` + `docker exec kr-app apachectl -k graceful`. **No DB rollback** (no migration ran).

## Governance
- Release-prep + GO: `87a6a27` (`docs/SCA-NON-CLAIM-RC-RESULT.md`).
- This deployment record: committed to `/opt/sca-gov` (see commit below).

## Safety posture (this task)
Authorized, code-only production deployment limited to the approved non-claim release. No database
migration or write; no Shopify API request or store change; no inventory import; no authentication,
certification, or QR issuance; no customer claim or ownership change; no transactional-email change; no
secure-claim deployment; `origin/main` NOT merged; no container recreate or infrastructure change.

**STOP — Non-claim release DEPLOYED: production `6e36aa7` → `e3f73f8b` (code-only, migration-free). HEAD
matches the approved SHA; app healthy (loopback 302, public Passport 200 with the new a11y); QR-label-PDF
routes + staff-dashboard improvements live; auth/cert/ownership intact; DB fingerprint identical (no new
records; 205 imports + 205 variant links unchanged; 0 migrations ran); secure claiming undeployed (0
claim/email routes, 0 secure-claim tables); no Shopify calls; logs clean; no rollback needed. Rollback
ref `backup/pre-nonclaim-6e36aa7` @ `6e36aa7` retained. No further releases.**

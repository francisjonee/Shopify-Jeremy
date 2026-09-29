# SCA-053 — End-to-End Pilot Readiness Audit — READ-ONLY

**Type:** planning / read-only audit. **No** implementation, branch, schema, migration, mutation, synthetic
production transaction, deploy, defect fix, or SCA-054 promotion. **Target:** deployed `main`
`0e2e151b2023186ce18347c514903dce217c1685` (SCA-052 done; DEFECT-001 fixed). **Method:** an independent
read-only walk of the real staff → first-collector → transfer → next-collector lifecycle (actual routes /
controllers / views / ACLs) plus direct inspection of the deployed operational config.

---

## 1. Verdict

**The digital lifecycle is functionally pilot-ready — there are NO code/workflow blockers.** Every normal
digital pilot operation is completable through the application UI, discoverable via visible links/buttons, with
no raw SQL, SSH, hidden-route knowledge, manual token extraction, or developer intervention required — with the
minor exceptions noted below (all UX-friction, none blocking). The **only material gaps are OPERATIONS /
cutover** items, and every one of them is already captured under the deferred **SCA-PRODUCTION-CUTOVER** bucket
and is downstream of the single external dependency: a **Jeremy-provided permanent HTTPS domain.** No confirmed
functional defects remain (DEFECT-001 is FIXED).

---

## 2. Lifecycle walk (staff → collector → transfer → next collector)

| # | Step | Result | Notes (file evidence) |
|---|---|---|---|
| 1 | Staff intake | WORKS | "New Eyewear Item" on registry index; Registry is a top nav item |
| 2 | Authenticate + finalize + certify | WORKS | fully inline on item detail (record/finalize/"Certify from this authentication") |
| 3 | Certificate PDF generation | WORKS | inline POST "Generate certificate PDF"; then downloadable |
| 4 | QR / public passport | **UX-FRICTION (deferred by design)** | item detail shows only the **raw permanent token** — no scannable/printable QR artifact; explicitly deferred until a Jeremy-controlled production domain (QR permanence). Passport itself is reachable (owner tokenless redirect; staff QR-lookup accepts a pasted token/`/p/` link) |
| 5 | Staff external-intake claim link | WORKS | issued URL shown in a copyable input on item detail |
| 6 | Collector register + login | WORKS | cross-linked; `/collector` root redirect; forgot/reset present (but see Ops SMTP) |
| 7 | Collector claim via link/QR | WORKS | guest→sign-in/register→`redirect()->intended` round-trip preserves the destination |
| 8 | My Collection (cert/docs/048 history/049 history/052 badge/service/status) | WORKS | all surfaced on the item-detail view |
| 9 | Status reporting (lost/stolen/recovered) | WORKS | discoverable buttons; staff-managed states show read-only notice |
| 10 | Collector→collector transfer | WORKS | sender gets a copyable one-time transfer link; recipient accept works incl. login round-trip; self-transfer blocked |
| 11 | Corrections: certification (038), metadata (046) | WORKS | both linked directly on item detail |
| 11 | Correction: ownership (035) | **UX-FRICTION (minor)** | "Correct ownership" is two hops deep (only on the ownership-history page, itself linked only when ownership events > 0) — unlike the sibling corrections which are on the item detail |
| 12 | Service events + adverse-status queue/resolution | WORKS | inline "Record service"; "Adverse queue" on index; confirm interstitials before terminal actions |
| 13 | Registry search/filter/QR-lookup (051) | WORKS | full filter/sort form + POST QR-lookup on the index |
| 13 | Collector support lookup (040) | **UX-FRICTION (hidden route)** | no menu entry and no cross-link anywhere; reachable only by typing `/admin/sca/collectors` |

**Out-of-band tokens:** both the claim link and the transfer link are surfaced to the actor who issues them as
copyable URLs; collectors never need a raw token (passport via server redirect, documents via opaque handle).
No step requires a token/id the UI never shows. **No BLOCKER found.**

---

## 3. Operational readiness (deployed config @ 0e2e151)

**Confirmed good:** `APP_ENV=production`, `APP_DEBUG=false`; MariaDB **private** (3306 unpublished); kr-app bound
to `195.26.255.80:8080` behind a **DOCKER-USER IP-lock** (2 whitelisted pilot source IPs + DROP); governed
main-only deploy (`deploy-preview.sh` with a mandatory test gate); staff Bouncer ACL + collector guard;
**daily encrypted backups** running (cron `/etc/cron.d/sca-backup`; recent GPG + sha256 artifacts present;
restore-proof script exists); public-passport Option-A privacy intact.

**Gaps (all OPERATIONS, all cutover-gated):**
- **No HTTPS / no permanent domain.** Served plain **HTTP** on the temporary IP (`APP_URL=http://195.26.255.80:8080`);
  sr-caddy owns 80/443 for the *unrelated* co-tenant, not SCA. Acceptable for the current **IP-locked controlled
  pilot**, but blocks any public/permanent pilot and, with QR permanence, **blocks printing permanent QR tags**
  (step 4). *Downstream of the Jeremy domain.*
- **SMTP not configured (`MAIL_MAILER=log`).** The SCA-037 collector password-reset email only writes to the log
  → **self-service password recovery is non-functional in production.** In a small controlled pilot this is
  operationally mitigable (staff-assisted resets), but it is a real gap for any scaled pilot. *Cutover-gated.*
- **Off-site backup not configured** (`SCA_OFFSITE_UPLOADER` unset) — backups are on-server only, a single-host
  durability risk. Local encrypted backups + restore rehearsal exist. *Cutover-gated (off-site rehearsal).*
- **Monitoring/alerting minimal** — file logging only (`storage/logs/laravel.log`), no metrics/alerting. LOW.

---

## 4. Classification (BLOCKER / HIGH / MEDIUM / LOW × STAFF / COLLECTOR / OPERATIONS)

**Confirmed functional defects:** none (DEFECT-001 FIXED). **BLOCKERs:** none in the digital lifecycle.

| Sev | Area | Finding | Type |
|---|---|---|---|
| HIGH | OPERATIONS | No permanent HTTPS domain → no printable **permanent QR**, HTTP-only exposure | deferred (cutover; Jeremy domain) |
| HIGH | COLLECTOR/OPS | Password recovery non-functional (`MAIL_MAILER=log`) | deferred (cutover; SMTP) |
| MEDIUM | OPERATIONS | Off-site backup not configured (on-server only) | deferred (cutover) |
| MEDIUM | STAFF | Collector-support tool (040) has no menu/link — hidden route | UX-friction (small, real) |
| LOW | STAFF | Ownership-correction (035) is two hops deep vs sibling corrections | UX-friction (trivial) |
| LOW | COLLECTOR | No self-service certificate generation; no global nav; no in-app notifications | deferred / minor UX |
| LOW | OPERATIONS | No monitoring/alerting beyond file logs | deferred |

The two STAFF UX-friction items are the only findings that touch the directive's "no hidden-route knowledge"
bar; both are reachable today (URL / registry) so neither is a blocker.

---

## 5. Requirements / roadmap re-check (no invented work)

Cross-checked against `docs/PRODUCT_REQUIREMENTS.md`, the SCA-047/050 audits, and `TASK_QUEUE.md`. Every
operational gap above is already scoped under **SCA-PRODUCTION-CUTOVER** (permanent HTTPS/public-QR domain,
DNS/Caddy cutover, SMTP, permanent QR printing, off-site backup rehearsal, temporary-exposure retirement).
Future product features (Insurance Report PDF, Market/value info, Collector profiles, external paid-auth,
marketplace) remain explicitly FUTURE/DEFERRED and are **not** pilot blockers. Nothing new is proposed merely
because it could exist.

---

## 6. Recommended next action (exactly one)

**The application is functionally pilot-ready; recommend PRODUCTION-CUTOVER PREPARATION — not an SCA-054 code
task.** No workflow blocker deserves code: the digital lifecycle is complete and app-completable, DEFECT-001 is
fixed, and the two remaining UX-friction items (collector-support menu link; ownership-correction discoverability)
are small, non-blocking polish. Every *material* remaining gap — printable permanent QR, HTTPS, functional
password recovery (SMTP), off-site backup rehearsal — is downstream of the **single external dependency: a
Jeremy-provided permanent HTTPS domain**, and is already scoped under SCA-PRODUCTION-CUTOVER.

Concretely, the highest-value next step is to **obtain that permanent HTTPS domain from Jeremy and prepare the
governed cutover runbook/pre-flight** (the ordered sequence already sketched in the stack's operating notes:
DNS A-record → `edge` network + Caddyfile reverse-proxy for the SCA domain → set `APP_URL`/`PUBLIC_QR_BASE_URL`
→ configure SMTP → **then** print permanent QR tags → enable off-site backup + rehearse restore → retire the
temporary IP-locked exposure). Until Jeremy provides the domain, SCA-PRODUCTION-CUTOVER stays BLOCKED/DEFERRED.

*Optional, non-blocking:* the collector-support menu link + ownership-correction item-detail link could be
folded into a tiny staff-UX cleanup if ChatGPT ever wants one, but they do not justify a task on their own and
must not gate the pilot.

---

## 7. Governance state (unchanged by this audit)

- Recorded DONE in `TASK_QUEUE.md` (planning convention). **ACTIVE = NONE; NEXT_TASK = NONE.**
- **SCA-054 not promoted / not started.** The §6 recommendation is advisory for ChatGPT.
- **SCA-PRODUCTION-CUTOVER remains BLOCKED/DEFERRED** awaiting the Jeremy-provided permanent HTTPS domain.
- Production and the pilot are exactly as found; this audit made no code, config, container, network, or data
  change (read-only; no synthetic transactions).

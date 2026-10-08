# NEXT TASK

**STATUS: CP-1 (Collector Profile — Private Profile Foundation) MERGED + DEPLOYED (prod main `8d8c359`, migrations 131). Provenance byte-identical; Stripe DORMANT; MAIL_MAILER=log. STOP for ChatGPT post-deployment audit. Do NOT start CP-2.**

Updated 2026-10-09.

## Current deployed baseline (authoritative — single source of truth)
- Deployed implementation `main` = **`8d8c35947d7c405124e0df4f09ff3ef4ee9e6bb8`** (impl repo `francisjonee/francisjonee-sca-platform-private`) — CP-1 merged `--no-ff` + deployed; deployed tree file-identical to audited candidate `cc6d0537ecdb8df3ae5a5242298ab9c562d5d40e` (base `f461c17`). Prior deployed: Slice 6 `f461c17`.
- Governance/evidence repo = `francisjonee/Shopify-Jeremy`.
- Prod migrations **131** (130→131: one additive table `sca_collector_profiles`, **0 rows**). Provenance DATA byte-identical pre/post (FP `35e06328…`; items 3/qr 3/certs 4/auth 4/ownership 5/claims 2/grants 1/sale 1/status 7). Collector accounts 3 (unchanged).
- Public edge LIVE `https://verify.secondchanceauthenticators.com`; `:8080` loopback-only; `SESSION_SECURE_COOKIE=true`; `MAIL_MAILER=log`; `STRIPE_*`/provider creds UNSET.

## CP-1 — Collector Profile (Private Profile Foundation) — DEPLOYED
`8d8c359`, migr 130→131 (`sca_collector_profiles`). Private one-to-one presentation profile (bio/location/private avatar) separate from canonical collector identity; `display_name` canonical on `sca_collector_accounts`; private authenticated avatar stream (narrow allowlist, server-generated filename, `local` disk, nosniff/no-store); canonical current-ownership-derived stats; "Collector since" from account `created_at`; all profile mutations (create/update/avatar/remove) serialized against the privacy lifecycle via shared `assertActiveAccountLocked()` (account→profile lock order, fail-closed `ProfileLifecycleException`); pseudonymization removes the profile row + avatar; ZERO provenance; no public/handle/social surface; public Passport collector-identity contract unchanged. R1–R6 closed. Deploy gate **1058 passed / 5476**; prod data byte-identical, profiles 0; Stripe DORMANT, mail=log. Evidence: `docs/SCA-COLLECTOR-PROFILE-CP1-{IMPLEMENTATION,DEPLOY-RESULT}.md`. **STOP for ChatGPT post-deployment audit of `8d8c359`. CP-2 NOT started.**

### Prior deployed baseline (superseded by CP-1 `8d8c359`)
- `f461c17b7e0cbd5a5e5f026d5f5000870ef04752` — External Paid Auth Intake Slice 6 (Exceptions & Returns), migr 130. Priors: Stripe R1 `7ff176c`, Slice 5 `8c73e83`.

## Approved candidate
Implementation repo: `francisjonee/francisjonee-sca-platform-private`
Branch: `feat/sca-collector-profile-cp1`
Exact deployed base: `f461c17b7e0cbd5a5e5f026d5f5000870ef04752`
Approved candidate: `cc6d0537ecdb8df3ae5a5242298ab9c562d5d40e`
Candidate: 4 commits ahead / 0 behind base.
Migration: production 130 → candidate 131 (one additive `sca_collector_profiles` table).

## Audit verdict
**PASS.** R1–R6 are closed.

Accepted architecture:
- private one-to-one presentation profile separate from canonical collector identity;
- display_name remains canonical on `sca_collector_accounts`;
- private authenticated avatar storage/streaming;
- canonical current-ownership-derived collection statistics;
- Passport remains collector-identity-free;
- pseudonymization removes profile reachability and avatar;
- all profile mutations now use the same account-first lifecycle serialization as privacy;
- no public profile/handle/social scope;
- zero provenance mutation from profile operations.

R6 verified: `removeAvatar()` calls shared `assertActiveAccountLocked()` before touching the profile, uses account→profile lock order, does not create a missing profile, preserves pointer-first/post-commit-byte-delete semantics, and controller handles lifecycle rejection consistently.

Reported focused gate: CollectorProfileTest 33 passed / 1 skipped (environment lacks WebP GD) + CollectorProfileConcurrencyTest 4 passed.
Reported full SCA gate: 1057 passed / 5472 assertions / 1 skipped. Known unrelated `QrReissueTest::rg8` rebuilt_at timing flake occurred once and passed 11/11 isolated; accepted as non-blocking for CP-1.

## NEXT ACTION — merge and controlled deploy CP-1

Claude/operator may now:
1. Reconfirm implementation `main` still equals deployed base `f461c17b7e0cbd5a5e5f026d5f5000870ef04752` or otherwise STOP on drift.
2. Merge exact approved candidate `cc6d0537ecdb8df3ae5a5242298ab9c562d5d40e` into implementation main. No additional feature changes.
3. Deploy that exact merge/main tree through the established production procedure.
4. Run migration 130→131 only. STOP on unexpected migration delta.
5. Run focused CP-1 smoke/verification appropriate to production without destructive privacy/provenance actions.
6. Verify private profile routes/auth boundary, migration/table/trigger, application health, and existing public Passport.
7. Verify provenance fingerprint/counts unchanged from pre-deploy baseline.
8. Verify Stripe remains DORMANT: enabled false and secrets unset; webhook remains unactivated.
9. Verify MAIL_MAILER remains log; no SMTP activation.
10. Run/record the established regression/deployment gate. If `QrReissueTest::rg8` alone hits the known one-second timing flake, isolate/re-run and document; any other regression is a STOP.
11. Record merge SHA, deployed SHA, migration before/after, tests/smoke results, provenance before/after, Stripe/mail state in the CP-1 deployment result/governance.
12. STOP for ChatGPT post-deployment audit. Do NOT start CP-2 yet.

No Stripe, SMTP, Shopify, Caddy/DNS, public-profile, handle, social, marketplace, valuation, or CP-2 work in this deployment.

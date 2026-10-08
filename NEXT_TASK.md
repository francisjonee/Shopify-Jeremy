# NEXT TASK

**STATUS: CP-1 PRE-MERGE AUDIT — PASS. Candidate approved for merge + controlled production deployment. Do not start CP-2 until deployment verification closes CP-1.**

Updated 2026-10-09.

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

# NEXT TASK

**STATUS: CP-1 POST-DEPLOYMENT AUDIT — PASS / CLOSED. Production baseline is `8d8c35947d7c405124e0df4f09ff3ef4ee9e6bb8`, migrations 131. CP-2 may now be planned, but do not implement until a new promoted task is written.**

Updated 2026-10-09.

## Authoritative deployed baseline
- Implementation repo: `francisjonee/francisjonee-sca-platform-private`
- Production/main: `8d8c35947d7c405124e0df4f09ff3ef4ee9e6bb8`
- Approved CP-1 candidate: `cc6d0537ecdb8df3ae5a5242298ab9c562d5d40e`
- GitHub comparison candidate→merge contains **zero file changes**; merge tree is file-identical to audited candidate.
- Production migrations: **131**
- CP-1 deploy evidence: `docs/SCA-COLLECTOR-PROFILE-CP1-DEPLOY-RESULT.md`
- Deploy evidence governance commit: `2f1bf6398adff135a51e82b86ab22ff69d144b17`

## CP-1 closure verdict
**PASS — CP-1 CLOSED.**

Verified deployment record:
- main/merge SHA `8d8c359`;
- migration 130→131 only;
- `sca_collector_profiles` present with UNIQUE collector binding, RESTRICT FK, immutability trigger, zero initial rows;
- deploy gate 1058 passed / 5476 assertions / 1 environment WebP skip;
- CP-1 routes/auth boundary and Passport smoke passed;
- provenance fingerprint remained `35e063282e004eaabcc9240360ecc0e3`;
- provenance counts remained 3/3/4/4/5/2/1/1/7;
- collector accounts remained 3; profile rows 0 immediately post-deploy;
- Stripe remains DORMANT / secrets unset;
- `MAIL_MAILER=log`;
- no Stripe/SMTP/Shopify/Caddy/DNS change;
- CP-2 was not started during deployment.

R1–R6 are closed. No CP-1 remediation remains.

## Next initiative
The next collector-profile roadmap slice is **CP-2 — Rich My Collection Experience**.

Before implementation, ChatGPT must audit the currently deployed My Collection UI/data paths at baseline `8d8c359` and promote one bounded CP-2 task. Do not infer CP-2 scope from old notes and do not start coding until that task is written.

CP-2 architectural intent remains: improve the authenticated collector's collection presentation/navigation using existing canonical provenance and ownership data. It must not silently introduce public profiles, public item visibility, handles, social features, marketplace/valuation, or duplicate provenance state.

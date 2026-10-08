# NEXT TASK

**STATUS: CP-4 FINAL POST-DEPLOY AUDIT — PASS / CLOSED. Public Collection Controls are LIVE. Production app baseline `7409a33baecf2ef6bd8c44413a27a9f77fa249f1`, migrations 133. CP-5 may now be architecture-audited/planned, but do not implement until ChatGPT promotes a new task.**

Updated 2026-10-09.

## CP-4 final closure verdict
**PASS — CP-4 CLOSED.**

### Authoritative production state
- Implementation repo: `francisjonee/francisjonee-sca-platform-private`
- Approved candidate: `2836114ef5dd7b48e16f696c9195d52125725e11`
- Production/main/deployed app: `7409a33baecf2ef6bd8c44413a27a9f77fa249f1`
- Production migrations: **133**
- Deployment evidence: `docs/SCA-COLLECTOR-PROFILE-CP4-DEPLOY-RESULT.md`
- Deployment governance commit: `3d5ca3a57aa0451044036211294d4d967b0fd757`

### Independent final audit findings
ChatGPT independently verified:
- implementation `main == 7409a33...`;
- approved candidate → merge is one merge commit ahead with **zero file differences**;
- deployed tree is therefore file-identical to the exact audited candidate;
- migration 132→133 created only the intended `sca_collector_public_items` presentation table;
- production table exists with 0 rows, default-private visibility, required UNIQUE/FKs/indexes and immutability trigger;
- exact merge-tree test gate: **1137 passed / 5864 assertions / 1 accepted WebP environment skip**, with no rg8 flake in deployment gate;
- CP-4 private visibility routes remain collector-authenticated/throttled;
- nested public image route is unauthenticated at app layer but resolves through centralized eligibility;
- external bogus nested /c image request reaches kr-app/Laravel ordinary 404 through existing CP-3 edge admission;
- unrelated paths remain Caddy catch-all;
- Passport remains reachable and collector-identity-free;
- collector pages remain auth gated;
- admin edge restriction, co-tenant health and external :8080 closure remain intact;
- no CP-5 routes exist;
- provenance DATA fingerprint remains `35e063282e004eaabcc9240360ecc0e3`;
- provenance counts remain 3/3/4/4/5/2/1/1/7;
- collector/private-profile/public-profile/public-item counts remain 3/0/0/0 at deployment verification;
- Stripe remains dormant / secret unset;
- `MAIL_MAILER=log`;
- no Caddy/DNS/Shopify/SMTP changes.

## CP-4 delivered boundary
CP-4 now provides explicit, reversible, per-item public collection controls on top of CP-3:
- ownership alone never publishes an item;
- profile publication alone never publishes an item;
- public item visibility requires explicit collector opt-in plus current canonical ownership and non-adverse registry state;
- transfer/ownership correction resets old-owner visibility;
- recipient never inherits visibility;
- reacquisition remains private until explicit re-opt-in;
- adverse status resets visibility;
- recovery does not auto-republish;
- public list/image reads independently re-check canonical eligibility;
- setVisible serializes against ownership/status mutation on `sca_item_current_state`;
- public collection disclosure is conservative and bounded;
- Passport remains independent of collector identity;
- My Collection remains private and complete.

Core invariant:
**Ownership ≠ publicity. Profile publication ≠ item publication.**

## Next initiative
Collector Profile roadmap next slice: **CP-5 — Public Handle / Profile URL**.

Before implementation, ChatGPT must architecture-audit CP-3's stable opaque `PUB-` identity and CP-4 public collection surface at baseline `7409a33...`.

CP-5 must explicitly decide:
- whether a handle is an alias or replaces the opaque URL;
- normalization/case/canonicalization;
- uniqueness and reserved names;
- rename semantics and old-handle behavior;
- enumeration/discovery implications;
- rate limits;
- account/profile unpublish and pseudonymization behavior;
- whether handles are reusable after rename/privacy deletion and any anti-impersonation hold;
- collision/concurrency behavior;
- interaction with existing stable `PUB-` refs and all nested CP-4 image URLs;
- whether redirects are permitted without leaking prior identity.

Do not infer or implement CP-5 from old roadmap notes.
Do not start CP-5 coding until ChatGPT writes a new promoted task after architecture inspection.

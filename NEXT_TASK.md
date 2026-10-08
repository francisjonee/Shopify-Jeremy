# NEXT TASK

**STATUS: CP-3 FINAL POST-EDGE AUDIT — PASS / CLOSED. Public Profile Foundation is LIVE. Production app baseline `3e707582c21e40b97e909c8593987787fd4c33c4`, migrations 132. CP-4 may now be architecture-audited/planned, but do not implement until ChatGPT promotes a new task.**

Updated 2026-10-09.

## CP-3 final closure verdict
**PASS — CP-3 CLOSED.**

### Authoritative production state
- Implementation repo: `francisjonee/francisjonee-sca-platform-private`
- Production/main/deployed app: `3e707582c21e40b97e909c8593987787fd4c33c4`
- Production migrations: **132**
- Phase-A audited candidate: `8aa8e8014ed2308f362972bb0c445ab1289dfb2f`
- Phase-A candidate→merge: one merge commit, zero file differences
- Phase-A evidence: `docs/SCA-COLLECTOR-PROFILE-CP3-PHASE-A-DEPLOY-RESULT.md`
- Phase-B evidence: `docs/SCA-COLLECTOR-PROFILE-CP3-PHASE-B-EDGE-ACTIVATION.md`
- Phase-B governance commit: `0bff4b43f5964a4dc7a16ba9e848e243b139a128`

### Final audit findings
ChatGPT independently verified:
- implementation `main` remains exact Phase-A deployed SHA `3e707582...`; no post-deploy app drift;
- Phase B made no implementation/schema change;
- active edge change documented as exactly one matcher addition:
  `@public path /p/* /collector /collector/*`
  → `@public path /p/* /collector /collector/* /c/*`;
- /c/* is routed to the same existing `kr-app:80` upstream, not a broad catch-all;
- timestamped pre-change Caddy backup retained;
- candidate Caddy config validated successfully before activation;
- only the edge Caddy container was recreated; app/database containers were not restarted/rebuilt;
- external syntactically-valid bogus public-profile and avatar requests now originate from kr-app/Apache/Laravel, proving /c/* reaches CP-3;
- unrelated unknown paths still originate from the Caddy catch-all, proving routing was not broadly opened;
- Passport remains app-served and collector-identity-free;
- /collector remains authenticated;
- /admin restriction remains intact;
- co-tenants and loopback-only :8080 behavior remain intact;
- migration remains 132;
- publication rows remain 0;
- provenance DATA fingerprint remains `35e063282e004eaabcc9240360ecc0e3`;
- provenance counts remain items/qr/certs/auth/ownership/claims/grants/sale/status = 3/3/4/4/5/2/1/1/7;
- collector/private-profile/publication counts remain 3/0/0;
- Stripe remains dormant / secret unset;
- `MAIL_MAILER=log`;
- DNS/TLS policy, Shopify, SMTP and application code unchanged;
- rollback was not required.

## CP-3 delivered boundary
CP-3 now provides a publicly reachable, explicitly opt-in, share-by-link collector profile foundation:
- ownership does NOT imply publicity;
- dedicated publication state with stable opaque PUB reference;
- minimal allowlisted presentation only;
- public avatar cannot outlive profile eligibility;
- publish/unpublish and pseudonymization use account-first lifecycle serialization;
- pseudonymization removes publication state;
- Passport does not link collector identity;
- My Collection remains private;
- no public collection/items/counts;
- no public directory/search;
- no public handle/custom slug.

## Next initiative
Collector Profile roadmap next slice: **CP-4 — Public Collection Controls**.

Before implementation, ChatGPT must architecture-audit the deployed CP-2 current-owner catalog semantics together with CP-3 publication/privacy lifecycle at baseline `3e707582...`.

The invariant remains:
**Ownership ≠ publicity. Profile publication ≠ item publication.**

CP-4 must define explicit per-item/public-collection visibility semantics and immediate transfer/privacy revocation before any code task is promoted.

Do not infer or implement CP-4 from old roadmap notes.
Do not start CP-4 coding until ChatGPT writes a new promoted task after architecture inspection.

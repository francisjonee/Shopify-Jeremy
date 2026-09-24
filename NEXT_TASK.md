# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-PUBLIC-PASSPORT-PILOT-034

## Title

Validate the existing public SCA passport and permanent QR identity against the live pilot lifecycle

## Implementer

Claude

## Why this task now

SCA-OWNERSHIP-PROVENANCE-033 has been accepted, merged, and deployed. Live pilot testing has now exercised an externally-intaken Ray-Ban PILOT-TEST item through authentication, certification, permanent SCA identity, claim by Collector #1, transfer to Collector #2, ownership-history inspection, and a registry status change to `lost`.

The collector-facing item page correctly warns Collector #2 that the item is reported lost while preserving registered ownership. The next unresolved pilot question is the public side of the same canonical record: when the permanent SCA identity is resolved through the existing public passport, does the public view truthfully show the authentication/certification identity and the current lost warning while preserving owner privacy?

The public passport is not a new feature. `SCA-PUBLIC-PASSPORT-008` is already accepted. This task must inspect and validate that existing implementation rather than build a second passport.

The current server/IP is temporary construction infrastructure. The product requirement remains that the lifetime QR resolves to a Jeremy-controlled SCA domain, not a VPS IP, port, temporary session, or Shopify URL. Therefore this task must not convert `195.26.255.80:8080` into permanent QR identity data merely to make the pilot clickable.

## Authority and safety boundary

This is primarily an **audit and pilot-validation task**. Prefer zero product-code changes if the accepted passport can already be exercised safely.

Do not regenerate or replace the item's permanent identity token. Do not rewrite certification, QR, ownership, status, authentication, or provenance data. Do not change DNS, Caddy, Shopify, firewall policy, production QR configuration, or permanent infrastructure.

A reversible preview-only mechanism may be implemented only if inspection proves the existing public passport cannot be exercised on the temporary pilot without changing canonical permanent identity. Any such mechanism must remain clearly non-permanent and must not persist the temporary host/IP into the canonical QR identity.

## Required Work

1. Pull latest governance `main` and implementation `main`. Confirm implementation `main` includes the accepted/deployed 033 merge and use current implementation as source of truth.
2. Create branch `feat/sca-public-passport-pilot-034` from latest implementation `main`.
3. Before changing code, audit the accepted public passport implementation end to end: public route(s), controller/presenter/service, permanent QR identity/token resolution, certification/authentication projection, registry-status projection, public privacy rules, real-404 behavior, and existing passport tests/task reports.
4. Determine the exact existing public passport route contract, including whether the canonical route is `/p/{token}` or another accepted path. Do not guess it from old documentation.
5. Determine exactly what is stored as the permanent QR identity and exactly how a public URL is constructed. Prove whether the stored identity is host-independent. Do not expose the raw token in the task report or logs beyond what existing safe test fixtures require.
6. Determine why the staff item page currently says the scannable QR image/public URL is DEVELOPMENT/NON-PERMANENT and deferred until a Jeremy-controlled production domain is approved. Confirm whether this is only URL-generation/production-domain gating or whether it prevents the existing passport route itself from resolving on the pilot.
7. Validate the public passport using controlled test data first. Cover at least an authenticated/certified registered item in normal status and the same class of item in `lost` status.
8. For `lost`, the public passport must display a clear warning derived from canonical registry status. It must not claim ownership ended merely because the item is lost. Registered ownership and lost/stolen status are separate concerns.
9. Verify the public passport does not expose collector email, phone, address, account credentials, collector session data, Collector #N internal references, claim/grant tokens, transfer capability/invite tokens, Shopify customer/order identifiers, internal database primary keys, or private documents.
10. Verify the public passport does not expose the staff-only ownership-history chain added by 033. Former/current collector identity must not leak through public provenance presentation.
11. Verify authentication/certification information shown publicly is derived from accepted canonical data and remains consistent after ownership transfer and status changes. Lost status must not alter historical authentication/certification evidence.
12. Verify unknown/invalid/revoked identity behavior is privacy-safe and follows the accepted public-passport contract. Do not weaken token entropy or introduce enumeration/search by public reference.
13. Verify a GET of the public passport creates zero domain mutations: no authentication, certification, QR, ownership, claim, transfer, status, service, document, Shopify, or projection writes.
14. Inspect the live pilot record only after automated behavior is understood. The target pilot record is the Ray-Ban `PILOT-TEST`, SCA public reference `SCA-F1B792AE4745`, currently registered to Collector #2 and reported lost. Do not modify that business record as part of verification.
15. If the existing passport can safely be reached on the temporary pilot by constructing a noncanonical preview URL around the already-stored host-independent token, document the method and use it for pilot verification. Do not persist that IP/port URL as permanent QR data and do not print/treat it as the lifetime production QR.
16. If the existing implementation intentionally refuses all temporary-host resolution and no safe non-mutating preview path exists, STOP implementation and report the exact blocker and smallest proposed reversible preview mechanism. Do not bypass the production-domain safety gate without ChatGPT audit.
17. Only if code changes are genuinely required for safe pilot validation, keep them narrowly scoped to preview/public-passport validation. No redesign, new passport, new QR identity, DNS change, production-domain activation, or unrelated UI work.
18. Add/extend focused automated tests proving at minimum: normal public passport resolution; lost warning; stolen warning if already part of accepted status vocabulary; owner privacy; ownership-history privacy; certification/authentication persistence; invalid token privacy-safe behavior; zero GET mutations; host-independent identity; and no temporary host/IP persisted into permanent identity.
19. Run the focused passport/status/privacy tests plus relevant certification/QR, ownership, transfer, My Collection, status, and mandatory SCA regressions. Run `composer validate`, `composer audit`, PHP lint for changed PHP, and repository secret-safety checks.
20. Create `docs/task-reports/SCA-PUBLIC-PASSPORT-PILOT-034.md` documenting: existing passport route contract; permanent identity semantics; production-domain gate discovered; public fields/privacy boundary; status behavior; no-mutation evidence; whether any code change was necessary; safe pilot-validation method or blocker; tests/checks; changed files; base SHA; final branch SHA; and deferrals.
21. Make logical checkpoint commits only if files actually change. Push `feat/sca-public-passport-pilot-034` if implementation/report changes are committed.
22. STOP for ChatGPT audit. Do not create/merge a PR, deploy, modify DNS/Caddy/firewall/Shopify, activate a production QR domain, regenerate QR identity, or begin SCA-035.

## Acceptance Gate

PASS requires:

- the task proves the existing accepted public passport rather than creating a duplicate;
- the exact public route/token-resolution contract is documented from implementation;
- permanent identity remains host-independent and unchanged;
- no temporary IP/port becomes canonical QR identity;
- a canonical `lost` state produces an appropriate public warning without exposing owner identity;
- public verification remains consistent with authentication/certification and does not mutate provenance;
- staff-only ownership history remains private;
- no collector PII, Collector # reference, credentials, claim/transfer secrets, Shopify internals, private documents, or internal PKs leak;
- invalid identities remain privacy-safe;
- public GETs create zero domain mutations;
- automated regressions and mandatory checks pass;
- the live pilot record is not mutated by validation;
- no DNS, Caddy, firewall, Shopify, production cutover, or permanent QR activation occurs.

## Explicit non-goals

Do not build a second public passport. Do not redesign the QR architecture. Do not generate a new permanent token. Do not bind lifetime QR identity to `195.26.255.80`, port `8080`, or another temporary host. Do not expose ownership history publicly. Do not add public collector profiles. Do not change claim/transfer/status semantics. Do not perform production infrastructure cutover. Do not modify Shopify.

## Completion Rule

When complete, report only:

1. branch and final HEAD SHA (or audit-only base SHA if no code change was required);
2. task report path;
3. exact existing public passport route/token-resolution contract discovered;
4. permanent QR identity semantics and production-domain gate discovered;
5. public fields and privacy boundary;
6. normal + lost/stolen behavior proven;
7. zero-mutation and live-pilot non-mutation evidence;
8. safe pilot URL/validation method, or exact blocker if no safe preview path exists;
9. focused/regression test counts and mandatory checks;
10. confirmation of push if commits were made, and confirmation no PR/merge/deploy/DNS/Caddy/firewall/Shopify/permanent-QR activation occurred.

Then STOP for ChatGPT audit.

# SCA Real-World Pilot Readiness — Governance Evidence Summary (pre-merge)

**Status:** DOCS-ONLY R1-remediated candidate pushed — awaiting ChatGPT independent pre-merge RE-AUDIT AND explicit owner authorization of the physical pilot. NOT merged, NOT deployed. No application code/schema/provider/infrastructure change; no production data mutation; no pilot executed.

| | |
|---|---|
| Governance promotion | `0995dd48b02eab927e29a69846c5e16dac36867a` |
| Pre-merge R1 FAIL (docs remediation only) | `2ec508165ef90710d564aa982f32743b7c0003b7` |
| Production baseline | `3b30a0f24323463c42dda58b476a453f58e49389` (migration 138) |
| Branch | `docs/sca-real-world-pilot-readiness` (1 ahead / 0 behind) |
| **Candidate SHA (R1)** | **`bebd18139f008c29fc78c27bc1f4e27a34869ecb`** (amended single docs commit; supersedes `f78f981`) |
| Changed files | **1** — `docs/SCA-REAL-WORLD-PILOT-READINESS.md`; **no code/schema/config** |
| Migration | none (138 unchanged) |
| Provenance (unchanged) | FP `d15a5cbdfb8df52ba65628b276533cfe`, counts `3/3/4/4/5/2/1/1/7` |

## R1 remediation (docs-only; no code/schema/config change)
ChatGPT R1 (`2ec5081`) FAILed the structurally-sound package for three content issues + source-validation. All fixed in the implementation doc:
1. **Shopify sale→claim separated from staff grant.** Chain A now names the real **Shopify sale→claim** path (`ClaimWorkflow::claim` via `collector/claim/{token}`, which *requires* an eligible Shopify sale-link; authority = verified Shopify commerce evidence) as a distinct row (A7) from the **independent staff-issued grant** fallback (A7-alt, `ClaimWorkflow::claimByGrant` via `collector/claim/grant/{token}`, which consults no sale-link). The doc states explicitly that a manual grant→ownership success does NOT validate the Shopify chain, and that the Shopify chain is **NOT VALIDATED** without a live order.
2. **Per-chain success criteria.** §3.4 now scores three independent chains — (1) core inventory/auth/cert/QR/owner-claim/transfer, (2) external manual **unpaid** submission/custody/auth/return, (3) **optional** Shopify paid-order/reconciliation/claim — each pass/deferred/fail; an optional/unexecuted step is DEFERRED never PASS; the Stripe paid flow is explicitly excluded.
3. **Adverse testing confined to a sacrificial frame.** Lost/stolen negative testing and permanent adverse events are restricted to an owner-designated, consented sacrificial frame (`PILOT-SAC`) — never ordinary saleable/customer inventory — with documented permanent-history consequences (recovery clears current status but never erases the events; certification/ownership events are not erasable "cleanup").
4. **Source-validated + evidence provenance clarified.** All route names/ACL keys/service methods/compensating actions were validated against the deployed source at `3b30a0f`; the ENVIRONMENT-CONFIRMED tier is marked as Claude-reported, not independently re-verified by ChatGPT.

Full package: `docs/SCA-REAL-WORLD-PILOT-READINESS.md` in the implementation repo (R1 candidate `bebd181`). This summary is the governance-side evidence.

## What was produced
1. **Readiness matrix** over the existing deployed architecture — two end-to-end chains plus bounded safety cases, each stage mapped to its literal route name, ACL permission, actor, service method, required physical artifact, irreversible mutation, safe compensating action, and automated-test evidence.
2. **Readiness tiering** separating automated-test coverage from real-world validation: **CODE-COMPLETE** (test-covered on the deployed tree) vs **ENVIRONMENT-CONFIRMED** (live non-mutating health/edge/config checks) vs **NOT-YET-HUMAN-PILOT-VALIDATED**. **Every workflow stage is NOT-YET-HUMAN-PILOT-VALIDATED** — no real person + physical frame has completed a pilot.
3. **Controlled pilot runbook** (2–3 consented frames, distinct minimal-perm staff + collector roles, unique traceable refs, paper custody chain, printed-QR scan on the canonical domain, negative/adverse scenarios, checkpoints, PII-redacted evidence, explicit STOP/GO) — gated on prior owner approval of exact frames/participants/window.
4. **Operator checklists, incident/rollback boundaries, data-handling/privacy, success metrics**, and a **ranked gap register** (blocker/high/medium) separating product defects from environment dependencies and human-process gaps.
5. **QR `rg8` timing-flake analysis** with reproducible root cause and a narrowly scoped **test-only** proposed fix + regression plan — explicitly NOT patched in this task.

## Key findings
- The domain is broad and code-complete: staff intake/authentication/certification, permanent QR/passport, collector claim/ownership/transfer, Shopify sale-links (webhook-driven), external submission/custody/return, status safety, corrections, Market Reference. Deployed-tree gate **1380 pass / 1 skip / 0 fail (7308 assertions)**.
- Live environment (non-mutating checks): loopback `/admin/login` 200; edge live on `https://verify.secondchanceauthenticators.com`; malformed `/p/deadbeef` → constant-shape 404. Stripe dormant, `MAIL_MAILER=log`, `SHOPIFY_SCOPES=read_orders`.
- **rg8 root cause:** `QrService::reissue()` → `ProjectionService::rebuild()` re-stamps `rebuilt_at => now()` on `sca_item_current_state` (second precision); `rg8` includes that recompute timestamp in an `assertSame` equality, so a reissue crossing a whole-second boundary under load fails intermittently. It is a test over-reach on a non-domain timestamp, not a regression. Proposed fix: exclude `rebuilt_at` from the comparison (as `active_qr_identifier_id` already is) and assert domain columns explicitly — separate approved scope. The existing fail-before-migrate deploy policy safely contains it.

## Blockers (both human-process; no code blocker)
1. No human + physical-frame pilot executed — every stage is NOT-YET-HUMAN-PILOT-VALIDATED.
2. Owner approval of the exact frames/participants/change-window not yet given.

HIGH environment dependencies: outbound email is `log` (claim/transfer links delivered manually in a pilot); no live Shopify order reconciled; Stripe dormant (paid auth uses the manual advance gate, which is explicitly not payment). MEDIUM: rg8 test-only flake; RUNBOOK staging language; `/u/{handle}` not edge-admitted; backups not activated.

## Next decision
Owner authorizes (or declines) a controlled physical pilot with specific frames/participants/window per the runbook; separately, the rg8 test-only fix may be scoped. No code, schema, provider, or infrastructure change is requested by this task.

**STOP — awaiting ChatGPT independent pre-merge RE-AUDIT of R1 docs candidate `bebd181` and owner authorization of the physical pilot. Do not merge/deploy/execute the pilot; do not start another initiative.**

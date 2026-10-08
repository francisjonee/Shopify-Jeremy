# NEXT TASK

**STATUS: CP-4 PRE-MERGE AUDIT — FAIL. One concurrency architecture blocker must be remediated. Do not merge/deploy or start CP-5.**

Updated 2026-10-09.

## Audited candidate
Repo: `francisjonee/francisjonee-sca-platform-private`
Branch: `feat/sca-collector-profile-cp4`
Base: `3e707582c21e40b97e909c8593987787fd4c33c4`
Candidate: `e041eea7b9ee67bba21914ad4777d42f0a4f0e0a`
GitHub compare: 1 ahead / 0 behind, exactly 13 intended CP-4 files, one migration 132→133.

## Accepted portions
The core read architecture is accepted:
- dedicated collector+item presentation state;
- default private;
- centralized public read predicate intersects CP-3 publication + active/nonblank profile + explicit visibility + canonical current ownership + non-adverse status;
- conservative public DTO;
- no public item detail/Passport link;
- public image shares eligibility predicate;
- projection-boundary reset covers canonical ownership/status rebuilds;
- privacy cleanup present;
- transfer/correction/adverse/recovery sequential behavior is well covered;
- migration shape is appropriate.

## R1 BLOCKER — real stale-visible race remains; deterministic ordering tests do not prove the required invariant

The promoted task explicitly required real concurrency proof for:
- visibility publish racing ownership transfer;
- visibility publish racing adverse status.

Candidate substitutes sequential “both orderings” tests and claims literal concurrency is infeasible. That claim is not accepted.

### Why the race exists
`CollectorPublicItemService::setVisible()`:
1. locks only the collector account;
2. checks CP-3 publication;
3. reads `sca_item_current_state` for current ownership + non-adverse WITHOUT locking the item/current-state row;
4. later inserts/updates `sca_collector_public_items.is_visible=true`.

Ownership/status writers rebuild/reset visibility in their own transaction through `ProjectionService::rebuild()`.

A valid interleaving can therefore be:

#### Transfer race
T1 visibility:
- locks collector A account;
- reads projection: A still owner, normal → eligible;
- pauses before visibility insert/update.

T2 transfer/correction:
- changes canonical ownership to B;
- rebuilds projection;
- resets currently-existing stale visibility rows;
- commits.

T1:
- resumes and writes/commits A's visibility=true based on the stale eligibility read.

Immediate public read is still safe because centralized predicate sees B as current owner. BUT A now retains a stale visible=true preference.

Later B→A reacquisition rebuild sees A as current owner and, by current reset logic, preserves A's visible row. The item can therefore automatically reappear without a new explicit opt-in, violating:
- old-owner preference must reset private;
- reacquisition remains private until explicit re-opt-in.

#### Adverse race
Same pattern:
T1 reads normal/non-adverse and pauses.
T2 commits adverse status + reset.
T1 then writes visible=true.

Immediate public read is suppressed by adverse predicate, but stale true survives. On later recovery, rebuild sees same owner + non-adverse and preserves the row, so the item can auto-republish after recovery, violating CP-4.

Defense-in-depth public reads prevent an immediate disclosure, but they do NOT satisfy the persistent privacy-state invariant.

## Required remediation
Make visibility publication serialize with canonical ownership/status eligibility so a stale eligibility read cannot write visible=true after an ownership/adverse commit.

Choose the smallest safe lock design after auditing existing lock order. Requirements:
- `setVisible()` must acquire an item/current-state lock that is also mutually exclusive with ownership/status writers BEFORE relying on eligibility;
- re-read canonical current ownership + registry status under that lock;
- preserve consistent global lock ordering and avoid account↔item deadlock with existing workflows;
- if account-first is incompatible with canonical item writers, redesign the CP-4 mutation lock order safely rather than layering an inversion;
- CP-3 publication/account active eligibility must still be authoritative at commit;
- UNIQUE replay/idempotency behavior preserved;
- no provenance mutation by visibility action.

A robust alternative is an ownership/status **epoch binding** stored with the preference (e.g. bind to canonical last ownership/status event identity) and require exact epoch equality at public read, but this is a larger schema/read design. Prefer serialization if it can be proven deadlock-safe.

Do NOT merely add another post-write read/check without locking; that remains TOCTOU.
Do NOT rely only on the public read predicate; reacquisition/recovery resurrection remains the issue.
Do NOT delete the sequential tests; retain them in addition to real race tests.

## Mandatory real concurrency regressions
Use two real DB connections/processes or the established deterministic concurrency harness used elsewhere in SCA. Prove actual overlap, not sequential calls.

### Transfer race
Force visibility transaction to pause after acquiring the chosen synchronization boundary / during eligibility evaluation, then race a real transfer (or vice versa as appropriate to lock design). Prove after both commits:
- canonical owner is B;
- A preference is false/absent;
- A public collection/image cannot resolve item;
- B has no inherited visible preference;
- after B→A reacquisition, A is STILL private until explicit re-opt-in.

Also exercise the inverse start order if the lock design makes it materially distinct.

### Adverse race
Race visibility publication with a real adverse status writer. After both commits:
- canonical status adverse;
- preference false/absent;
- public collection/image cannot resolve;
- after recovery/normalization, item remains private until explicit re-opt-in.

### Deadlock/lock-order proof
Add/document a test or precise code audit demonstrating the chosen lock order is compatible with:
- TransferService;
- OwnershipCorrectionService;
- StatusService writers;
- CP-3 publish/unpublish;
- CollectorPrivacyService;
- CP-4 setPrivate/setVisible.

No unresolved deadlock retry should be considered a PASS.

## Re-run gates
- CollectorPublicItemTest;
- new real concurrency test class if separated;
- CP-3 public profile + concurrency;
- CP-2 My Collection;
- transfer/status/privacy/Passport regressions;
- full `tests/Feature/Sca`.
Report exact pass/assertion/skip counts.

Migration may remain 132→133 if no schema change is required.
Production stays untouched at `3e707582...`, migration 132.
No Caddy/DNS/Stripe/SMTP/Shopify changes.
No CP-5.

Push remediation on SAME CP-4 branch, update implementation evidence, report exact new head + delta from `e041eea...`, and STOP for ChatGPT re-audit.

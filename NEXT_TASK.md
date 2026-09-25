# NEXT TASK

**STATUS:** ACTIVE — implementation pushed for ChatGPT audit (NOT merged, NOT deployed).

`SCA-CERTIFICATION-CORRECTION-038` is promoted and implemented. The feature branch
`sca-certification-correction-038` is pushed to the implementation repo
(`francisjonee/francisjonee-sca-platform-private`) from the accepted base
`df80e4b5a655f59a1337cb1a8792beb6e6d40f54`. It awaits ChatGPT audit; it must not be merged, deployed,
or promoted onward (SCA-039 must not start) until ChatGPT authorizes.

*Prior task `SCA-COLLECTOR-PASSWORD-RECOVERY-037` remains DONE (audited, merged, deployed at `df80e4b`).
Its spec is preserved in `docs/task-reports/SCA-COLLECTOR-PASSWORD-RECOVERY-037.md`.*

## Title

Governed staff certification revoke + re-certification (append-only certification correction)

## Implementer

Claude

## Why this task now

The post-037 read-only application gap audit identified the certification lifecycle as the strongest
remaining registry-integrity gap: `revoked` and `superseded` are already canonical (schema CHECK +
`ProjectionService::currentCertification` fold + `reason` / `successor_certification_id` /
`supersedes_certification_id` columns), yet no writer or staff surface existed, and re-certification was
UI-blocked. A certification issued in error was therefore permanent public-passport evidence correctable
only by direct DB/CLI work — the exact situation SCA-035 closed for the ownership ledger. This task is the
certification-ledger analogue of 035.

## Scope (ratified)

Staff-only, append-only certification correction on the canonical certification-event ledger:

- **Revoke** — the current certification is invalidated with **no replacement**. Append exactly the
  canonical `revoked` evidence with a mandatory reason. Afterward: `currentCertification` is null; the item
  is the same registry item; ownership unchanged; permanent QR identity unchanged; the historical
  certification stays visible to staff; public presentation no longer shows it as valid.
- **Supersede / re-certify** — the previous certification is replaced by a specific new certification,
  issued from a **new** finalized, passed authentication for the same item. Atomically: validate the current
  certification; validate the new authentication; create the successor using existing canonical
  numbering/data rules; append the successor's `issued` evidence; append `superseded` evidence for the
  predecessor with `successor_certification_id`; rebuild the projection; leave exactly one current valid
  certification. Never record a `revoked` event during a supersede — the two meanings are distinct.

## QR policy (ratified)

Certification correction preserves the existing permanent QR identity. Revoke and supersede must NOT
mint/activate/reissue a QR and must NOT record any QR lifecycle event. Same QR identifier, same token, same
active QR before and after both operations.

## Public passport behavior (Option A — accepted)

The SCA-020/034 constant-shape enumeration-safe passport contract is preserved and the resolver/controller
are unchanged. Current valid certification → normal passport. Revoked with no successor → the existing
identical real HTTP 404, indistinguishable from malformed/unknown/inactive/stale/ineligible tokens (no
disclosure of token/item/certification existence, revocation, or reason). Superseded → the same permanent
token resolves the successor current certification; the old certification is not presented as current.

## Guardrails

- Dedicated permission `sca.eyewear.certification.correct` gates both the confirmation GET and the mutation
  POSTs; not the ordinary `sca.eyewear.certify`. Not exposed to collectors.
- Mandatory reason + typed confirmation for each destructive action.
- One transaction locking the item/projection boundary; append-only optimistic stale-state guard; reject
  unknown item / no current certification / wrong-item / unfinalized / failed / reused authentication /
  stale state / malformed reason / unauthorized caller; fail closed, no partial state.
- Certification correction must not modify ownership, current owner, collectors, claims, transfers, item
  identity/metadata, lost/stolen/recovered state, QR identity/token, or unrelated authentication history.
- No certification-ledger schema migration unless inspection proves one necessary (the audit indicates the
  columns already exist); ACL registration through the established mechanism is allowed.

## Non-goals

No item metadata editing; no physical QR replacement/reissue; no collector certification controls; no
certification-event edit/delete; no ownership changes; no redesign of authentication/grading; no
SMTP/domain/DNS/Caddy/Shopify/backup work; no reporting/export; no SCA-039.

## Completion state (recorded)

Implemented on branch `sca-certification-correction-038` (base `df80e4b`); focused suite 21 passed / 99
assertions; full SCA suite 498 passed / 2113 assertions; no schema migration; composer validate/audit clean.
Full evidence in `docs/task-reports/SCA-CERTIFICATION-CORRECTION-038.md`. **Push only — awaiting ChatGPT
audit before any merge/deploy.**

# NEXT TASK

**STATUS:** READY

**TASK_ID:** SCA-ADMIN-OWNERSHIP-CORRECTION-035

## Title

Governed append-only staff ownership correction

## Implementer

Claude

## Why this task now

The read-only application gap audit after SCA-034 confirmed an operational gap: an incorrect or
fraudulent ownership assignment cannot currently be corrected through the application. The canonical
ledger reserves the `admin_correction` ownership event type and `ProjectionService::currentOwner` already
honours it, but **no writer or staff surface exists**, so staff would need direct database intervention to
fix a mis-recorded owner. Production cutover/domain/infrastructure remains intentionally deferred; this is
application-only work.

## Authority and safety boundary

Staff-only, append-only correction. Never update/delete/rewrite an existing ownership event. Reuse the
accepted ownership model and projection as authoritative — do not redesign them. No collector-facing or
public correction capability. No certification/status/QR/transfer/claim semantic change. No public
ownership history. No production-domain, DNS/Caddy/firewall/Shopify work, and no deployment.

## Required Work

1. Pull latest governance `main` and implementation `main`; branch `feat/sca-admin-ownership-correction-035`
   from accepted implementation `main`.
2. Before coding, inspect: canonical ownership schema, `ProjectionService::currentOwner`, claim + transfer
   writers, the 033 ownership-history implementation, existing confirmation patterns (025 typed-confirm),
   the collector account model, and the current ACL architecture.
3. Implement a staff-only ownership-correction workflow that appends an `admin_correction` event.
   Requirements:
   - correct an item to an existing valid collector;
   - correct an item to no current owner **only if** the canonical schema/projection can represent that
     honestly without inventing new semantics;
   - a mandatory human-readable correction reason;
   - explicit typed confirmation before mutation;
   - a dedicated ownership-correction permission unless an already accepted permission explicitly covers
     this authority;
   - destination-collector selection via an application-controlled mechanism — never require typing an
     internal collector DB id;
   - append-only provenance preserving every claim/transfer/prior correction;
   - truthful rendering of the resulting event in the existing 033 Ownership History.
4. **Semantic gate — no-owner:** prove exactly how `admin_correction` with `collector_account_id = NULL`
   is interpreted by the canonical projection. If it is not unambiguous, STOP and report rather than
   borrowing `transfer_out` semantics or silently changing the projection.
5. **Reason storage:** inspect whether the ownership-event schema already has a canonical field for the
   reason. Do not overload an unrelated field. If durable reason provenance requires a schema addition,
   report and implement the smallest appropriate migration within the ownership-ledger boundary only.
6. **Concurrency:** the confirmation POST must verify the ownership state being corrected is still the
   state staff reviewed; a concurrent claim/transfer/correction must not be silently overwritten.
7. Reject a correction that merely reproduces the current ownership state unless explicitly justified with
   tests establishing the intended behaviour; prefer rejecting accidental no-ops.
8. GET/confirmation pages perform zero domain mutations. Unknown items/collectors fail closed. Unauthorized
   staff fail closed. Collector/public routes gain no correction capability. Public passport + collector
   surfaces expose no additional identity.
9. Add focused tests (minimum): owner A → correction → owner B; A's history preserved; correction after a
   claim/transfer chain; rendering in ownership history; correction to no-owner if canonically supported;
   reason persistence/rendering (staff); typed-confirmation failure; invalid collector; unauthorized staff;
   collector/public denial; stale/concurrent rejection; no-op behaviour; zero GET mutation; public-passport
   privacy unchanged.
10. Run focused tests, full SCA suite, `composer validate`, `composer audit`, PHP lint, secret-safety scan.
11. Create `docs/task-reports/SCA-ADMIN-OWNERSHIP-CORRECTION-035.md`.
12. Push the branch and STOP for ChatGPT audit. No PR/merge/deploy.

## Explicit non-goals

No editing/deleting ownership events, no rewriting claim/transfer history, no bulk reassignment, no
collector-facing correction, no certification/status/QR changes, no public ownership history, no
production-domain work, no DNS/Caddy/firewall/Shopify changes, and no deployment.

## Completion Rule

Report: schema semantics discovered; permission used/created; correction transaction/concurrency design;
exact append-only event written; reason storage; collector-selection mechanism; no-owner semantics;
tests/checks; changed files; base SHA and final HEAD. Then STOP for ChatGPT audit.

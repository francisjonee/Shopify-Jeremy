# ADR-0003 — Claude Task Controller

**Status:** ACCEPTED

## Decision

The SCA project will use a small controller on the project VPS to enforce the Architect → Implementer → Audit workflow.

The controller is not an architect and must never invent work. Its only job is to detect an approved `NEXT_TASK.md`, launch Claude Code for that exact task, capture the result, and stop until ChatGPT audits the evidence and updates `NEXT_TASK.md`.

## Required behavior

1. Watch or poll the `main` branch of `francisjonee/Shopify-Jeremy` for `NEXT_TASK.md`.
2. Run only when `STATUS: READY` and a new `TASK_ID`/`RETRY_GENERATION` has not already been dispatched.
3. Create a dedicated task branch. Never push directly to `main`.
4. Launch Claude Code non-interactively with the repository instructions and the exact current task.
5. Claude must execute only the task, produce evidence, commit allowed changes, and open a pull request when the task requires repository changes.
6. Record controller state so the same task is not dispatched twice.
7. After Claude finishes, mark the controller state as `AWAITING_ARCHITECT_AUDIT` and stop dispatching.
8. Resume only when ChatGPT changes `NEXT_TASK.md` to an approved READY task or remediation generation.
9. Never auto-merge a pull request.
10. Never deploy, modify DNS, connect the live Shopify store, rotate credentials, spend money, or perform any production action unless the current task explicitly authorizes that action and the required human approval has already been provided.

## Security

- Run under a non-root service account.
- Secrets must live outside Git and outside the architecture repository.
- Controller logs must redact secrets.
- Use a lock so only one Claude task can run at a time.
- Provide a kill/hold switch.
- Preserve an append-only dispatch/audit log containing task ID, retry generation, start/end time, branch, PR/commit refs, and final state.

## Why

A GitHub task file does not wake Claude by itself. The controller provides the missing execution bridge while keeping ChatGPT as architect/auditor and Claude as implementer.

## Consequence

One manual Claude session is required to bootstrap and prove the controller. After that, approved READY tasks can be picked up by the controller automatically.

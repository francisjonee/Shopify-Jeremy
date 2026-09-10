# SCA-CTRL-002 — Deferred

**Decision:** DEFERRED

The controlled live-dispatch proof is not required before SCA product work continues.

## Reason

The current working process is already reliable for the project's immediate needs:

1. ChatGPT writes the single approved task in `NEXT_TASK.md`.
2. The operator tells Claude to read and execute that task.
3. Claude executes only the current task and stops.
4. Claude returns evidence to ChatGPT for architecture audit.
5. ChatGPT approves, rejects, or issues the next task.

`SCA-CTRL-001` already proved the controller can safely read a task, de-duplicate dispatches, remain non-root, and stop at the audit gate. The remaining `SCA-CTRL-002` work exists only to prove unattended/controller-launched Claude authentication and GitHub PR creation.

Because the operator is already manually starting Claude and Claude is correctly picking up `NEXT_TASK.md`, that automation is optional rather than a blocker to product delivery.

## Status of automatic controller path

- Controller source remains available.
- Dry-run safety and duplicate suppression remain accepted.
- Live controller authentication is not configured.
- Unattended scheduling remains disabled.
- The project may return to `SCA-CTRL-002` later if fully automatic dispatch is desired.

## Product delivery rule

Until automatic dispatch is explicitly resumed, each ChatGPT-issued task will include the exact short instruction for the operator to paste into Claude.

This preserves the Architect → Implementer → Audit workflow without delaying SCA product work.

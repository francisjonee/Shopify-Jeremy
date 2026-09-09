# SCA Architect–Implementer Execution Workflow

This document defines the mandatory delivery loop for Jeremy's Second Chance Authenticators platform.

## Authority

- **Jeremy / Business Owner** provides business goals, requirements, priorities, and production approvals.
- **ChatGPT / Architect + Auditor** converts Jeremy's goals and brainstorming into architecture, acceptance criteria, ADRs, and exactly one implementation task in `NEXT_TASK.md`.
- **Claude / Implementer** executes only the current approved task. Claude does not choose the roadmap, approve its own work, or continue into the next task without a new `NEXT_TASK.md` written after architecture audit.
- **GitHub** is the canonical source of truth for architecture decisions and task state.

## Mandatory Loop

1. Jeremy requirements / brainstorming are discussed.
2. ChatGPT decides the architecture and implementation boundary.
3. ChatGPT writes exactly one current task into `NEXT_TASK.md` with acceptance criteria and prohibited changes.
4. Claude reads the architecture documents and `NEXT_TASK.md`.
5. Claude implements only that task in the implementation repository.
6. Claude stops when the task is complete or blocked.
7. Claude returns evidence: commit SHA(s), changed files, test/build results, runtime evidence, and any blockers required by the task.
8. No additional feature work may begin while the completed task is awaiting architecture audit.
9. ChatGPT audits the evidence against the task and architecture.
10. If accepted, ChatGPT records the completion and replaces `NEXT_TASK.md` with exactly one next approved task.
11. If rejected, ChatGPT increments `RETRY_GENERATION` and writes a remediation task. Claude fixes only the rejected scope and returns evidence again.

## Claude Stop Rule

After returning completion evidence, Claude must stop. A message such as "I can continue with..." is not authorization to continue.

Claude may resume only when `NEXT_TASK.md` contains a new or revised task with `STATUS: READY` written after architecture audit.

## Task Ownership

Only ChatGPT acting as Architect + Auditor should define or replace the implementation task in `NEXT_TASK.md` as part of this workflow.

Claude must not:

- invent the next task;
- expand the current scope because related work appears useful;
- change architecture decisions without an approved ADR;
- self-approve completion;
- deploy to production unless the current task explicitly authorizes production deployment;
- modify Shopify scopes, permanent QR rules, ownership semantics, or system-of-record boundaries unless the current task explicitly authorizes that change.

## Task Format

Every `NEXT_TASK.md` should contain at minimum:

- `STATUS`
- `TASK_ID`
- `RETRY_GENERATION`
- title
- objective
- required inputs
- implementation work
- acceptance criteria
- prohibited changes
- required evidence
- completion rule
- last-completed summary

## Audit Outcomes

### PASS

The implementation satisfies the task and architecture. ChatGPT records the accepted result and issues the next task.

### REJECT / REMEDIATION REQUIRED

The implementation does not satisfy one or more acceptance criteria, violates a prohibited change, lacks sufficient evidence, or conflicts with architecture. ChatGPT issues a narrow remediation task. Claude must not proceed to unrelated work.

### BLOCKED

A required credential, environment, source artifact, business decision, infrastructure dependency, or external access is unavailable. Claude reports the blocker and stops. ChatGPT decides whether to change architecture, request the missing dependency, or issue another task.

## Principle

Jeremy decides what the business needs. ChatGPT decides how that intent becomes controlled architecture and implementation tasks. Claude builds only what has been approved and waits for architecture audit before continuing.
